-- server.lua
local QBCore = exports['qb-core']:GetCoreObject()

local antilagData   = {}
local databaseReady = false

-- ─────────────────────────────────────────────
-- DB init & data load
-- ─────────────────────────────────────────────
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
    Wait(2000)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `vehicle_antilag` (
            `plate`       VARCHAR(20)  PRIMARY KEY,
            `kit`         VARCHAR(50)  NOT NULL,
            `tier`        INT          DEFAULT 1,
            `applied_by`  VARCHAR(50)  NOT NULL,
            `applied_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
            `updated_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query('SELECT `plate`, `kit`, `tier` FROM `vehicle_antilag`', {}, function(results)
        if results then
            for _, row in ipairs(results) do
                local kitCfg = Config.Kits[row.kit]
                if kitCfg then
                    antilagData[row.plate] = {
                        kit           = row.kit,
                        burstInterval = kitCfg.burstInterval,
                        flameCount    = kitCfg.flameCount,
                        scale         = kitCfg.scale,
                        volumeScale   = kitCfg.volumeScale,
                        soundFile     = kitCfg.soundFile,
                        tier          = row.tier,
                    }
                end
            end
            print('^2[mnc-antilag]^7 Loaded ' .. #results .. ' anti-lag kit(s) from database.')
        end
        databaseReady = true
        print('^2[mnc-antilag]^7 Database ready.')
    end)
end)

-- ─────────────────────────────────────────────
-- Callback: fetch data for a plate
-- ─────────────────────────────────────────────
QBCore.Functions.CreateCallback('mnc-antilag:getData', function(source, cb, plate)
    if not databaseReady then
        local waited = 0
        while not databaseReady and waited < 5000 do
            Wait(100); waited = waited + 100
        end
    end
    cb(antilagData[plate] or nil)
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
-- Apply kit (triggered after client animation)
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-antilag:applyKit', function(plate, kitName)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local kitCfg = Config.Kits[kitName]
    if not kitCfg then
        TriggerClientEvent('mnc-antilag:notify', src, { title = 'Anti-Lag', description = 'Unknown kit type.', type = 'error' })
        return
    end

    if not plate or #plate < 1 or #plate > 20 then
        TriggerClientEvent('mnc-antilag:notify', src, { title = 'Anti-Lag', description = 'Invalid vehicle plate.', type = 'error' })
        return
    end

    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-antilag:notify', src, { title = kitCfg.label, description = 'You need a mechanic job to install this kit.', type = 'error' })
        return
    end

    local item = Player.Functions.GetItemByName(kitCfg.item)
    if not item or item.amount < 1 then
        TriggerClientEvent('mnc-antilag:notify', src, { title = kitCfg.label, description = 'You do not have a ' .. kitCfg.label .. '.', type = 'error' })
        return
    end

    local newTier = Config.KitTier[kitName]

    if antilagData[plate] and antilagData[plate].tier >= newTier then
        TriggerClientEvent('mnc-antilag:notify', src, { title = kitCfg.label, description = 'An equal or higher kit is already installed.', type = 'error' })
        return
    end

    Player.Functions.RemoveItem(kitCfg.item, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[kitCfg.item], 'remove')

    antilagData[plate] = {
        kit           = kitName,
        burstInterval = kitCfg.burstInterval,
        flameCount    = kitCfg.flameCount,
        scale         = kitCfg.scale,
        volumeScale   = kitCfg.volumeScale,
        soundFile     = kitCfg.soundFile,
        tier          = newTier,
    }

    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_antilag` (`plate`, `kit`, `tier`, `applied_by`)
              VALUES (?, ?, ?, ?)
              ON DUPLICATE KEY UPDATE `kit` = ?, `tier` = ?, `applied_by` = ?, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, kitName, newTier, 'MECH:' .. Player.PlayerData.name, kitName, newTier, 'MECH:' .. Player.PlayerData.name }
        )
    end

    TriggerClientEvent('mnc-antilag:syncData', -1, plate, antilagData[plate])

    TriggerClientEvent('mnc-antilag:notify', src, {
        title       = kitCfg.label,
        description = 'Anti-lag kit installed on vehicle ' .. plate .. '.',
        type        = 'success',
        duration    = 5000,
    })

    print('^3[mnc-antilag]^7 ' .. kitName .. ' applied to ' .. plate .. ' by ' .. Player.PlayerData.name)
end)

-- ─────────────────────────────────────────────
-- Remove anti-lag kit
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-antilag:removeKit', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-antilag:notify', src, {
            title       = 'Anti-Lag Removal',
            description = 'You need a mechanic job to remove this kit.',
            type        = 'error',
        })
        return
    end

    local current = antilagData[plate]
    if not current then
        TriggerClientEvent('mnc-antilag:notify', src, {
            title       = 'Anti-Lag Removal',
            description = 'This vehicle has no anti-lag kit installed.',
            type        = 'error',
        })
        return
    end

    local kitItem = Config.Kits[current.kit].item
    Player.Functions.AddItem(kitItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[kitItem], 'add')

    antilagData[plate] = nil

    MySQL.prepare('DELETE FROM `vehicle_antilag` WHERE `plate` = ?', { plate }, function(rows)
        if Config.Debug then
            print('^3[mnc-antilag]^7 Removed kit from plate=' .. plate .. ' | rows=' .. tostring(rows))
        end
    end)

    TriggerClientEvent('mnc-antilag:syncData', -1, plate, nil)

    TriggerClientEvent('mnc-antilag:notify', src, {
        title       = 'Anti-Lag Removal',
        description = current.kit .. ' kit removed and returned to inventory.',
        type        = 'success',
        duration    = 6000,
    })

    if Config.Debug then
        print('^3[mnc-antilag]^7 ' .. current.kit .. ' removed from ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ─────────────────────────────────────────────
-- Broadcast flames (for other players)
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-antilag:broadcastFlames', function(netId, count)
    TriggerClientEvent('mnc-antilag:doFlames', -1, netId, count)
end)

-- ─────────────────────────────────────────────
-- Usable items — registered after resource start so QBCore is ready
-- ─────────────────────────────────────────────
AddEventHandler('onServerResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    print('^2[mnc-antilag]^7 Registering useable items...')

    QBCore.Functions.CreateUseableItem('antilag_1', function(source)
        print('^2[mnc-antilag]^7 antilag_1 used by src=' .. source)
        TriggerClientEvent('mnc-antilag:promptApply', source, 'antilag_1')
    end)

    QBCore.Functions.CreateUseableItem('antilag_2', function(source)
        print('^2[mnc-antilag]^7 antilag_2 used by src=' .. source)
        TriggerClientEvent('mnc-antilag:promptApply', source, 'antilag_2')
    end)

    QBCore.Functions.CreateUseableItem('antilag_3', function(source)
        print('^2[mnc-antilag]^7 antilag_3 used by src=' .. source)
        TriggerClientEvent('mnc-antilag:promptApply', source, 'antilag_3')
    end)

    QBCore.Functions.CreateUseableItem('antilag_toolbox', function(source)
        print('^2[mnc-antilag]^7 antilag_toolbox used by src=' .. source)
        TriggerClientEvent('mnc-antilag:openRemovalToolbox', source)
    end)

    print('^2[mnc-antilag]^7 Useable items registered.')
end)

-- ─────────────────────────────────────────────
-- Admin commands
-- ─────────────────────────────────────────────
local function AdminGiveKit(src, args, kitName)
    local kitCfg = Config.Kits[kitName]
    if not kitCfg then return end

    local caller = QBCore.Functions.GetPlayer(src)
    if not caller then return end

    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('mnc-antilag:notify', src, { title = 'Anti-Lag', description = 'No permission.', type = 'error' })
        return
    end

    local targetSrc = tonumber(args[1]) or src
    local target    = QBCore.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('mnc-antilag:notify', src, { title = 'Anti-Lag', description = 'Player not found.', type = 'error' })
        return
    end

    local ped     = GetPlayerPed(targetSrc)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        TriggerClientEvent('mnc-antilag:notify', src, { title = 'Anti-Lag', description = 'Target is not in a vehicle.', type = 'error' })
        return
    end

    local plate   = string.upper(GetVehicleNumberPlateText(vehicle):gsub('%s+', ''))
    local newTier = Config.KitTier[kitName]

    TriggerClientEvent('mnc-antilag:adminCheckTurbo', targetSrc, src, plate, kitName, newTier)
end

RegisterNetEvent('mnc-antilag:adminCommitKit', function(adminSrc, plate, kitName, newTier, hasTurbo)
    local src    = source
    local caller = QBCore.Functions.GetPlayer(adminSrc)
    if not caller then return end

    if not QBCore.Functions.HasPermission(adminSrc, 'admin') then return end

    local kitCfg = Config.Kits[kitName]
    if not kitCfg then return end

    if not hasTurbo then
        TriggerClientEvent('mnc-antilag:notify', adminSrc, {
            title       = 'Anti-Lag [Admin]',
            description = 'Target vehicle does not have a Turbo installed.',
            type        = 'error'
        })
        return
    end

    antilagData[plate] = {
        kit           = kitName,
        burstInterval = kitCfg.burstInterval,
        flameCount    = kitCfg.flameCount,
        scale         = kitCfg.scale,
        volumeScale   = kitCfg.volumeScale,
        soundFile     = kitCfg.soundFile,
        tier          = newTier,
    }

    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_antilag` (`plate`, `kit`, `tier`, `applied_by`)
              VALUES (?, ?, ?, ?)
              ON DUPLICATE KEY UPDATE `kit` = ?, `tier` = ?, `applied_by` = ?, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, kitName, newTier, 'ADMIN:' .. caller.PlayerData.name, kitName, newTier, 'ADMIN:' .. caller.PlayerData.name }
        )
    end

    TriggerClientEvent('mnc-antilag:syncData', -1, plate, antilagData[plate])

    TriggerClientEvent('mnc-antilag:notify', adminSrc, {
        title       = 'Anti-Lag [Admin]',
        description = kitCfg.label .. ' applied to ' .. plate .. ' (player ' .. src .. ').',
        type        = 'success', duration = 5000,
    })

    if src ~= adminSrc then
        TriggerClientEvent('mnc-antilag:notify', src, {
            title       = 'Anti-Lag',
            description = kitCfg.label .. ' has been installed on your vehicle by an admin.',
            type        = 'success', duration = 5000,
        })
    end

    print('^3[mnc-antilag]^7 ADMIN ' .. caller.PlayerData.name .. ' granted ' .. kitName .. ' to plate=' .. plate)
end)

RegisterCommand('antilag1', function(src, args) AdminGiveKit(src, args, 'antilag_1') end, true)
RegisterCommand('antilag2', function(src, args) AdminGiveKit(src, args, 'antilag_2') end, true)
RegisterCommand('antilag3', function(src, args) AdminGiveKit(src, args, 'antilag_3') end, true)

print('^2[mnc-antilag]^7 Loaded successfully!')