-- server.lua  (mnc-2step)
local QBCore = exports['qb-core']:GetCoreObject()

local twostepData   = {}
local databaseReady = false

-- ─────────────────────────────────────────────
-- DB init & data load
-- ─────────────────────────────────────────────
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
    Wait(2000)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `vehicle_2step` (
            `plate`       VARCHAR(20)  PRIMARY KEY,
            `kit`         VARCHAR(50)  NOT NULL,
            `tier`        INT          DEFAULT 1,
            `applied_by`  VARCHAR(50)  NOT NULL,
            `applied_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
            `updated_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query('SELECT `plate`, `kit`, `tier` FROM `vehicle_2step`', {}, function(results)
        if results then
            for _, row in ipairs(results) do
                local kitCfg = Config.Kits[row.kit]
                if kitCfg then
                    twostepData[row.plate] = {
                        kit     = row.kit,
                        tier    = row.tier,
                        limiter = kitCfg.limiter,
                        rolling = kitCfg.rolling,
                        boost   = kitCfg.boost,
                    }
                end
            end
            print('^2[mnc-2step]^7 Loaded ' .. #results .. ' 2-step kit(s) from database.')
        end
        databaseReady = true
        print('^2[mnc-2step]^7 Database ready.')
    end)
end)

-- ─────────────────────────────────────────────
-- Callback: fetch data for a plate
-- ─────────────────────────────────────────────
QBCore.Functions.CreateCallback('mnc-2step:getData', function(source, cb, plate)
    if not databaseReady then
        local waited = 0
        while not databaseReady and waited < 5000 do
            Wait(100); waited = waited + 100
        end
    end
    cb(twostepData[plate] or nil)
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
-- Apply kit (triggered from usable item)
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-2step:applyKit', function(plate, kitName)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local kitCfg = Config.Kits[kitName]
    if not kitCfg then
        TriggerClientEvent('mnc-2step:notify', src, { title = '2-Step', description = 'Unknown kit type.', type = 'error' })
        return
    end

    if not plate or #plate < 1 or #plate > 20 then
        TriggerClientEvent('mnc-2step:notify', src, { title = '2-Step', description = 'Invalid vehicle plate.', type = 'error' })
        return
    end

    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-2step:notify', src, { title = kitCfg.label, description = 'You need a mechanic job to install this kit.', type = 'error' })
        return
    end

    local item = Player.Functions.GetItemByName(kitCfg.item)
    if not item or item.amount < 1 then
        TriggerClientEvent('mnc-2step:notify', src, { title = kitCfg.label, description = 'You do not have a ' .. kitCfg.label .. '.', type = 'error' })
        return
    end

    local newTier = Config.KitTier[kitName]

    if twostepData[plate] and twostepData[plate].tier >= newTier then
        TriggerClientEvent('mnc-2step:notify', src, { title = kitCfg.label, description = 'An equal or higher kit is already installed.', type = 'error' })
        return
    end

    Player.Functions.RemoveItem(kitCfg.item, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[kitCfg.item], 'remove')

    twostepData[plate] = {
        kit     = kitName,
        tier    = newTier,
        limiter = kitCfg.limiter,
        rolling = kitCfg.rolling,
        boost   = kitCfg.boost,
    }

    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_2step` (`plate`, `kit`, `tier`, `applied_by`)
              VALUES (?, ?, ?, ?)
              ON DUPLICATE KEY UPDATE `kit` = ?, `tier` = ?, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, kitName, newTier, Player.PlayerData.name, kitName, newTier }
        )
    end

    TriggerClientEvent('mnc-2step:syncData', -1, plate, twostepData[plate])

    TriggerClientEvent('mnc-2step:notify', src, {
        title       = kitCfg.label,
        description = kitCfg.label .. ' installed! Hold RShift to activate.',
        type        = 'success',
        duration    = 6000,
    })

    if Config.Debug then
        print('^2[mnc-2step]^7 ' .. kitName .. ' applied to ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ─────────────────────────────────────────────
-- Remove kit (triggered after client animation)
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-2step:removeKit', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-2step:notify', src, {
            title       = '2-Step Removal',
            description = 'You need a mechanic job to remove this kit.',
            type        = 'error',
        })
        return
    end

    local current = twostepData[plate]
    if not current then
        TriggerClientEvent('mnc-2step:notify', src, {
            title       = '2-Step Removal',
            description = 'This vehicle has no 2-step kit installed.',
            type        = 'error',
        })
        return
    end

    local kitCfg = Config.Kits[current.kit]
    local kitItem = kitCfg and kitCfg.item or current.kit

    Player.Functions.AddItem(kitItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[kitItem], 'add')

    twostepData[plate] = nil

    MySQL.prepare('DELETE FROM `vehicle_2step` WHERE `plate` = ?', { plate }, function(rows)
        if Config.Debug then
            print('^3[mnc-2step]^7 Removed kit from plate=' .. plate .. ' | rows=' .. tostring(rows))
        end
    end)

    TriggerClientEvent('mnc-2step:syncData', -1, plate, nil)

    TriggerClientEvent('mnc-2step:notify', src, {
        title       = '2-Step Removal',
        description = (kitCfg and kitCfg.label or current.kit) .. ' removed and returned to inventory.',
        type        = 'success',
        duration    = 6000,
    })

    if Config.Debug then
        print('^3[mnc-2step]^7 ' .. current.kit .. ' removed from ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ─────────────────────────────────────────────
-- Broadcast flame effects to nearby players
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-2step:broadcastFlames', function(netId, count)
    local src = source
    TriggerClientEvent('mnc-2step:doFlames', -1, netId, count)
end)

-- ─────────────────────────────────────────────
-- Usable items — player uses item from inventory while near vehicle
-- The client handles which vehicle to target (closest / occupied)
-- ─────────────────────────────────────────────
QBCore.Functions.CreateUseableItem('basic_2step', function(source)
    TriggerClientEvent('mnc-2step:promptApply', source, 'basic_2step')
end)

QBCore.Functions.CreateUseableItem('street_2step', function(source)
    TriggerClientEvent('mnc-2step:promptApply', source, 'street_2step')
end)

QBCore.Functions.CreateUseableItem('pro_2step', function(source)
    TriggerClientEvent('mnc-2step:promptApply', source, 'pro_2step')
end)

QBCore.Functions.CreateUseableItem('twostep_toolbox', function(source)
    TriggerClientEvent('mnc-2step:openRemovalToolbox', source)
end)

-- ─────────────────────────────────────────────
-- Client-side item usage handler:
-- player must be sitting in a vehicle (or closest mechanic target)
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-2step:useItem', function(kitName)
    local src = source
    local ped = GetPlayerPed(src)
    local veh = GetVehiclePedIsIn(ped, false)

    if veh == 0 then
        TriggerClientEvent('mnc-2step:notify', src, {
            title       = '2-Step',
            description = 'You must be inside a vehicle to install this kit.',
            type        = 'error',
        })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(veh):gsub('%s+', ''))
    TriggerEvent('mnc-2step:applyKit', plate, kitName) -- re-use the same handler via server event
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
        TriggerClientEvent('mnc-2step:notify', src, { title = '2-Step', description = 'No permission.', type = 'error' })
        return
    end

    local targetSrc = tonumber(args[1]) or src
    local target    = QBCore.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('mnc-2step:notify', src, { title = '2-Step', description = 'Player not found.', type = 'error' })
        return
    end

    local ped     = GetPlayerPed(targetSrc)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        TriggerClientEvent('mnc-2step:notify', src, { title = '2-Step', description = 'Target is not in a vehicle.', type = 'error' })
        return
    end

    local plate   = string.upper(GetVehicleNumberPlateText(vehicle):gsub('%s+', ''))
    local newTier = Config.KitTier[kitName]

    twostepData[plate] = {
        kit     = kitName,
        tier    = newTier,
        limiter = kitCfg.limiter,
        rolling = kitCfg.rolling,
        boost   = kitCfg.boost,
    }

    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_2step` (`plate`, `kit`, `tier`, `applied_by`)
              VALUES (?, ?, ?, ?)
              ON DUPLICATE KEY UPDATE `kit` = ?, `tier` = ?, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, kitName, newTier, 'ADMIN:' .. caller.PlayerData.name, kitName, newTier }
        )
    end

    TriggerClientEvent('mnc-2step:syncData', -1, plate, twostepData[plate])

    TriggerClientEvent('mnc-2step:notify', src, {
        title = '2-Step [Admin]',
        description = kitCfg.label .. ' applied to ' .. plate .. ' (player ' .. targetSrc .. ').',
        type = 'success', duration = 5000,
    })

    if targetSrc ~= src then
        TriggerClientEvent('mnc-2step:notify', targetSrc, {
            title = '2-Step',
            description = kitCfg.label .. ' has been installed on your vehicle by an admin.',
            type = 'success', duration = 5000,
        })
    end

    print('^3[mnc-2step]^7 ADMIN ' .. caller.PlayerData.name .. ' granted ' .. kitName .. ' to plate=' .. plate)
end

RegisterCommand('twostepbasic',  function(src, args) AdminGiveKit(src, args, 'basic_2step')  end, true)
RegisterCommand('twostepstreet', function(src, args) AdminGiveKit(src, args, 'street_2step') end, true)
RegisterCommand('twosteppro',    function(src, args) AdminGiveKit(src, args, 'pro_2step')    end, true)

print('^2[mnc-2step]^7 Loaded successfully!')