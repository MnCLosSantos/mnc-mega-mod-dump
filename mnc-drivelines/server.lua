-- server.lua  (mnc-drivetype)
local QBCore = exports['qb-core']:GetCoreObject()

local drivetypeData = {}   -- [plate] = typeKey
local databaseReady = false

-- ─────────────────────────────────────────────
-- DB init & data load
-- ─────────────────────────────────────────────
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
    Wait(2000)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `vehicle_drivetype` (
            `plate`       VARCHAR(20)  PRIMARY KEY,
            `type_key`    VARCHAR(50)  NOT NULL,
            `applied_by`  VARCHAR(50)  NOT NULL,
            `applied_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
            `updated_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]], {}, function()
        MySQL.query('SELECT `plate`, `type_key` FROM `vehicle_drivetype`', {}, function(results)
            if results then
                for _, row in ipairs(results) do
                    if Config.DriveTypes[row.type_key] then
                        drivetypeData[row.plate] = row.type_key
                    end
                end
                print('^2[mnc-drivetype]^7 Loaded ' .. #results .. ' drive type conversion(s) from database.')
            end
            databaseReady = true
            print('^2[mnc-drivetype]^7 Database ready.')
        end)
    end)
end)

-- ─────────────────────────────────────────────
-- Callback: fetch drive type for a plate
-- ─────────────────────────────────────────────
QBCore.Functions.CreateCallback('mnc-drivetype:getData', function(source, cb, plate)
    if not databaseReady then
        local waited = 0
        while not databaseReady and waited < 5000 do
            Wait(100); waited = waited + 100
        end
    end
    cb(drivetypeData[plate] or nil)
end)

-- ─────────────────────────────────────────────
-- Job check
-- ─────────────────────────────────────────────
local function HasAllowedJob(Player)
    if not Config.RequireJob then return true end
    local job      = Player.PlayerData.job
    local grade    = job and job.grade.level or 0
    local minGrade = Config.AllowedJobs[job and job.name]
    if minGrade == nil then return false end
    return grade >= minGrade
end

-- ─────────────────────────────────────────────
-- Apply drive type conversion
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-drivetype:applyType', function(plate, typeKey)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local typeCfg = Config.DriveTypes[typeKey]
    if not typeCfg then
        TriggerClientEvent('mnc-drivetype:notify', src, { title = 'Drive Type', description = 'Unknown drive type.', type = 'error' })
        return
    end

    if not plate or #plate < 1 or #plate > 20 then
        TriggerClientEvent('mnc-drivetype:notify', src, { title = 'Drive Type', description = 'Invalid plate.', type = 'error' })
        return
    end

    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-drivetype:notify', src, {
            title       = typeCfg.label,
            description = 'You need a mechanic job to perform this conversion.',
            type        = 'error',
        })
        return
    end

    -- Check item
    local item = Player.Functions.GetItemByName(typeCfg.item)
    if not item or item.amount < 1 then
        TriggerClientEvent('mnc-drivetype:notify', src, {
            title       = typeCfg.label,
            description = 'You do not have a ' .. typeCfg.label .. ' conversion kit.',
            type        = 'error',
        })
        return
    end

    -- Already the same type?
    if drivetypeData[plate] == typeKey then
        TriggerClientEvent('mnc-drivetype:notify', src, {
            title       = typeCfg.label,
            description = 'This vehicle is already converted to ' .. typeCfg.label .. '.',
            type        = 'error',
        })
        return
    end

    -- If a different type is already installed, return that item to the player
    local existingKey = drivetypeData[plate]
    if existingKey and Config.DriveTypes[existingKey] then
        local existingItem = Config.DriveTypes[existingKey].item
        Player.Functions.AddItem(existingItem, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[existingItem], 'add')
        if Config.Debug then
            print('^3[mnc-drivetype]^7 Returned ' .. existingItem .. ' to ' .. Player.PlayerData.name .. ' (replaced by ' .. typeKey .. ')')
        end
    end

    -- Consume item
    Player.Functions.RemoveItem(typeCfg.item, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[typeCfg.item], 'remove')

    -- Store
    drivetypeData[plate] = typeKey

    MySQL.prepare(
        [[INSERT INTO `vehicle_drivetype` (`plate`, `type_key`, `applied_by`)
          VALUES (?, ?, ?)
          ON DUPLICATE KEY UPDATE `type_key` = VALUES(`type_key`), `applied_by` = VALUES(`applied_by`), `updated_at` = CURRENT_TIMESTAMP]],
        { plate, typeKey, Player.PlayerData.name },
        function(rowsChanged)
            if Config.Debug then
                print('^2[mnc-drivetype]^7 DB upsert | plate=' .. plate .. ' | type=' .. typeKey .. ' | rows=' .. tostring(rowsChanged))
            end
        end
    )

    -- Sync to all clients so the driver's vehicle updates immediately
    TriggerClientEvent('mnc-drivetype:syncData', -1, plate, typeKey)

    TriggerClientEvent('mnc-drivetype:notify', src, {
        title       = typeCfg.label,
        description = typeCfg.label .. ' conversion complete. ' .. typeCfg.description,
        type        = 'success',
        duration    = 6000,
    })

    if Config.Debug then
        print('^2[mnc-drivetype]^7 ' .. typeKey .. ' applied to ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ─────────────────────────────────────────────
-- Usable items
-- ─────────────────────────────────────────────
for typeKey, typeCfg in pairs(Config.DriveTypes) do
    local key = typeKey   -- capture for closure
    QBCore.Functions.CreateUseableItem(typeCfg.item, function(source)
        TriggerClientEvent('mnc-drivetype:promptApply', source, key)
    end)
end

-- ─────────────────────────────────────────────
-- Callback: get installed type for toolbox
-- ─────────────────────────────────────────────
QBCore.Functions.CreateCallback('mnc-drivetype:getTypeInfo', function(source, cb, plate)
    if not databaseReady then
        local waited = 0
        while not databaseReady and waited < 5000 do
            Wait(100); waited = waited + 100
        end
    end
    local typeKey = drivetypeData[plate]
    if typeKey and Config.DriveTypes[typeKey] then
        cb({ typeKey = typeKey, typeCfg = Config.DriveTypes[typeKey] })
    else
        cb(nil)
    end
end)

-- ─────────────────────────────────────────────
-- Remove drive type (toolbox uninstall)
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-drivetype:removeType', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not plate or #plate < 1 or #plate > 20 then
        TriggerClientEvent('mnc-drivetype:notify', src, { title = 'Driveline Toolbox', description = 'Invalid plate.', type = 'error' })
        return
    end

    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-drivetype:notify', src, {
            title       = 'Driveline Toolbox',
            description = 'You need a mechanic job to remove a drive type conversion.',
            type        = 'error',
        })
        return
    end

    local existingKey = drivetypeData[plate]
    if not existingKey or not Config.DriveTypes[existingKey] then
        TriggerClientEvent('mnc-drivetype:notify', src, {
            title       = 'Driveline Toolbox',
            description = 'This vehicle has no drive type conversion installed.',
            type        = 'error',
        })
        return
    end

    local existingCfg  = Config.DriveTypes[existingKey]
    local existingItem = existingCfg.item

    -- Return the item
    Player.Functions.AddItem(existingItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[existingItem], 'add')

    -- Clear from cache and DB
    drivetypeData[plate] = nil

    MySQL.prepare('DELETE FROM `vehicle_drivetype` WHERE `plate` = ?', { plate }, function(rowsChanged)
        if Config.Debug then
            print('^3[mnc-drivetype]^7 DB delete | plate=' .. plate .. ' | rows=' .. tostring(rowsChanged))
        end
    end)

    -- Broadcast removal (nil typeKey signals clients to clear handling)
    TriggerClientEvent('mnc-drivetype:syncData', -1, plate, nil)

    TriggerClientEvent('mnc-drivetype:notify', src, {
        title       = 'Driveline Toolbox',
        description = existingCfg.label .. ' conversion removed. Kit returned to your inventory.',
        type        = 'success',
        duration    = 6000,
    })

    if Config.Debug then
        print('^3[mnc-drivetype]^7 ' .. existingKey .. ' removed from ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ─────────────────────────────────────────────
-- Toolbox usable item
-- ─────────────────────────────────────────────
QBCore.Functions.CreateUseableItem('driveline_toolbox', function(source)
    TriggerClientEvent('mnc-drivetype:openToolbox', source)
end)

-- ─────────────────────────────────────────────
-- Admin commands
-- ─────────────────────────────────────────────
local function AdminApplyType(src, args, typeKey)
    local typeCfg = Config.DriveTypes[typeKey]
    if not typeCfg then return end

    local caller = QBCore.Functions.GetPlayer(src)
    if not caller then return end

    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('mnc-drivetype:notify', src, { title = 'Drive Type', description = 'No permission.', type = 'error' })
        return
    end

    local targetSrc = tonumber(args[1]) or src
    local target    = QBCore.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('mnc-drivetype:notify', src, { title = 'Drive Type', description = 'Player not found.', type = 'error' })
        return
    end

    local ped     = GetPlayerPed(targetSrc)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        TriggerClientEvent('mnc-drivetype:notify', src, { title = 'Drive Type', description = 'Target is not in a vehicle.', type = 'error' })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(vehicle):gsub('%s+', ''))

    -- Return old item to target player if replacing
    local existingKey = drivetypeData[plate]
    if existingKey and Config.DriveTypes[existingKey] and existingKey ~= typeKey then
        local existingItem = Config.DriveTypes[existingKey].item
        target.Functions.AddItem(existingItem, 1)
        TriggerClientEvent('inventory:client:ItemBox', targetSrc, QBCore.Shared.Items[existingItem], 'add')
    end

    drivetypeData[plate] = typeKey

    MySQL.prepare(
        [[INSERT INTO `vehicle_drivetype` (`plate`, `type_key`, `applied_by`)
          VALUES (?, ?, ?)
          ON DUPLICATE KEY UPDATE `type_key` = VALUES(`type_key`), `applied_by` = VALUES(`applied_by`), `updated_at` = CURRENT_TIMESTAMP]],
        { plate, typeKey, 'ADMIN:' .. caller.PlayerData.name }
    )

    TriggerClientEvent('mnc-drivetype:syncData', -1, plate, typeKey)

    TriggerClientEvent('mnc-drivetype:notify', src, {
        title    = 'Drive Type [Admin]',
        description = typeCfg.label .. ' applied to ' .. plate .. ' (player ' .. targetSrc .. ').',
        type     = 'success', duration = 5000,
    })

    if targetSrc ~= src then
        TriggerClientEvent('mnc-drivetype:notify', targetSrc, {
            title       = 'Drive Type',
            description = typeCfg.label .. ' conversion applied to your vehicle by an admin.',
            type        = 'success', duration = 5000,
        })
    end

    print('^3[mnc-drivetype]^7 ADMIN ' .. caller.PlayerData.name .. ' set ' .. typeKey .. ' on plate=' .. plate)
end

RegisterCommand('drivetypefwd',     function(src, args) AdminApplyType(src, args, 'fwd')           end, true)
RegisterCommand('drivetyperwd',     function(src, args) AdminApplyType(src, args, 'rwd')           end, true)
RegisterCommand('drivetyreawd',     function(src, args) AdminApplyType(src, args, 'awd_5050')      end, true)
RegisterCommand('drivetypehaldex',  function(src, args) AdminApplyType(src, args, 'haldex_6535')   end, true)
RegisterCommand('drivetypeviscous', function(src, args) AdminApplyType(src, args, 'viscous_3565')  end, true)

print('^2[mnc-drivetype]^7 Loaded successfully!')