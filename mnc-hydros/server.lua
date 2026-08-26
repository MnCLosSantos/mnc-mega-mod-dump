-- server.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- [plate] = { hydro = 'comp_hydro', type = 'comp', tier = 2 }
local hydroData     = {}
local databaseReady = false

-- ===========================
-- Wait for oxmysql, create table, load data
-- ===========================
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
    Wait(2000)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `vehicle_hydros` (
            `plate`        VARCHAR(20)  PRIMARY KEY,
            `hydro`        VARCHAR(50)  NOT NULL,
            `type`         VARCHAR(20)  NOT NULL,
            `tier`         INT          DEFAULT 1,
            `installed_by` VARCHAR(50)  NOT NULL,
            `installed_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
            `updated_at`   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    LoadHydroDataFromDatabase()
end)

function LoadHydroDataFromDatabase()
    MySQL.query('SELECT `plate`, `hydro`, `type`, `tier` FROM `vehicle_hydros`', {}, function(results)
        if results then
            for _, row in ipairs(results) do
                hydroData[row.plate] = {
                    hydro = row.hydro,
                    type  = row.type,
                    tier  = row.tier,
                }
            end
            print('^2[mnc-hydros]^7 Loaded ' .. #results .. ' hydraulic(s) from database.')
        end
        databaseReady = true
        print('^2[mnc-hydros]^7 Database ready.')
    end)
end

-- ===========================
-- Callback: return hydro data for a plate
-- ===========================
QBCore.Functions.CreateCallback('mnc-hydros:getHydroData', function(source, cb, plate)
    if not databaseReady then
        local waited = 0
        while not databaseReady and waited < 5000 do
            Wait(100)
            waited = waited + 100
        end
        if Config.Debug then
            print('^3[mnc-hydros]^7 getHydroData waited ' .. waited .. 'ms for DB (plate=' .. tostring(plate) .. ')')
        end
    end
    cb(hydroData[plate] or nil)
end)

-- ===========================
-- Job check helper
-- ===========================
local function HasAllowedJob(Player)
    if not Config.RequireJob then return true end
    local job      = Player.PlayerData.job
    local grade    = job and job.grade.level or 0
    local minGrade = Config.AllowedJobs[job and job.name]
    if minGrade == nil then return false end
    return grade >= minGrade
end

-- ===========================
-- Apply hydro — triggered from client after install animation
-- ===========================
RegisterNetEvent('mnc-hydros:applyHydro', function(plate, hydroName)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local hydroCfg = Config.Hydros[hydroName]
    if not hydroCfg then
        TriggerClientEvent('mnc-hydros:notify', src, {
            title = 'Hydraulics', description = 'Unknown hydraulic type.', type = 'error'
        })
        return
    end

    if not plate or #plate < 1 or #plate > 20 then
        TriggerClientEvent('mnc-hydros:notify', src, {
            title = 'Hydraulics', description = 'Invalid vehicle plate.', type = 'error'
        })
        return
    end

    -- Job check
    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-hydros:notify', src, {
            title = hydroCfg.label, description = 'You do not have the required job to install this hydraulic.', type = 'error'
        })
        return
    end

    -- Item check
    local item = Player.Functions.GetItemByName(hydroCfg.item)
    if not item or item.amount < 1 then
        TriggerClientEvent('mnc-hydros:notify', src, {
            title = hydroCfg.label, description = 'You do not have ' .. hydroCfg.label .. '.', type = 'error'
        })
        return
    end

    local newTier = Config.HydroTier[hydroName]

    -- Tier check — no downgrades
    if hydroData[plate] and hydroData[plate].tier >= newTier then
        TriggerClientEvent('mnc-hydros:notify', src, {
            title       = hydroCfg.label,
            description = 'This vehicle already has an equal or higher hydraulic installed.',
            type        = 'error'
        })
        return
    end

    -- Consume item
    Player.Functions.RemoveItem(hydroCfg.item, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[hydroCfg.item], 'remove')

    -- Update memory
    hydroData[plate] = {
        hydro = hydroName,
        type  = hydroCfg.type,
        tier  = newTier,
    }

    -- Persist to DB
    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_hydros` (`plate`, `hydro`, `type`, `tier`, `installed_by`)
              VALUES (?, ?, ?, ?, ?)
              ON DUPLICATE KEY UPDATE `hydro` = ?, `type` = ?, `tier` = ?, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, hydroName, hydroCfg.type, newTier, Player.PlayerData.name,
              hydroName, hydroCfg.type, newTier }
        )
    end

    -- Sync to all clients
    TriggerClientEvent('mnc-hydros:syncHydroData', -1, plate, hydroData[plate])

    TriggerClientEvent('mnc-hydros:notify', src, {
        title       = hydroCfg.label,
        description = hydroCfg.label .. ' installed successfully!',
        type        = 'success',
        duration    = 6000,
    })

    if Config.Debug then
        print('^2[mnc-hydros]^7 ' .. hydroName .. ' applied to ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ===========================
-- Remove hydro — called when the hydro wears out (duration expires)
-- ===========================
RegisterNetEvent('mnc-hydros:removeHydro', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not hydroData[plate] then return end

    hydroData[plate] = nil

    if databaseReady then
        MySQL.query('DELETE FROM `vehicle_hydros` WHERE `plate` = ?', { plate })
    end

    TriggerClientEvent('mnc-hydros:syncHydroData', -1, plate, nil)

    TriggerClientEvent('mnc-hydros:notify', src, {
        title       = 'Hydraulics',
        description = 'Your hydraulics have worn out and been removed.',
        type        = 'error',
        duration    = 6000,
    })

    if Config.Debug then
        print('^3[mnc-hydros]^7 Hydraulics worn out and removed from plate=' .. plate)
    end
end)

-- ===========================
-- Usable items
-- ===========================
QBCore.Functions.CreateUseableItem('street_hydro', function(source)
    TriggerClientEvent('mnc-hydros:applyHydro', source, 'street_hydro')
end)

QBCore.Functions.CreateUseableItem('comp_hydro', function(source)
    TriggerClientEvent('mnc-hydros:applyHydro', source, 'comp_hydro')
end)

-- ===========================
-- Manual removal — mechanic uses toolbox item to uninstall
-- ===========================
RegisterNetEvent('mnc-hydros:removeHydroManual', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-hydros:notify', src, {
            title       = 'Hydraulics Removal',
            description = 'You do not have the required job to remove this hydraulic.',
            type        = 'error',
        })
        return
    end

    local current = hydroData[plate]
    if not current then
        TriggerClientEvent('mnc-hydros:notify', src, {
            title       = 'Hydraulics Removal',
            description = 'This vehicle has no hydraulics installed.',
            type        = 'error',
        })
        return
    end

    local hydroCfg = Config.Hydros[current.hydro]
    if not hydroCfg then
        TriggerClientEvent('mnc-hydros:notify', src, {
            title       = 'Hydraulics Removal',
            description = 'Unknown hydraulic type on this vehicle.',
            type        = 'error',
        })
        return
    end

    -- Return the item
    Player.Functions.AddItem(hydroCfg.item, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[hydroCfg.item], 'add')

    hydroData[plate] = nil

    if databaseReady then
        MySQL.query('DELETE FROM `vehicle_hydros` WHERE `plate` = ?', { plate })
    end

    TriggerClientEvent('mnc-hydros:syncHydroData', -1, plate, nil)

    TriggerClientEvent('mnc-hydros:notify', src, {
        title       = 'Hydraulics Removal',
        description = hydroCfg.label .. ' removed and returned to your inventory.',
        type        = 'success',
        duration    = 6000,
    })

    if Config.Debug then
        print('^3[mnc-hydros]^7 ' .. current.hydro .. ' manually removed from ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

QBCore.Functions.CreateUseableItem('hydro_toolbox', function(source)
    TriggerClientEvent('mnc-hydros:startRemoval', source)
end)

-- ===========================
-- Admin commands — /hydrostreet [id]  /hydrocomp [id]
-- ===========================
local function AdminGiveHydro(src, args, hydroName)
    local hydroCfg = Config.Hydros[hydroName]
    if not hydroCfg then return end

    local targetSrc = tonumber(args[1]) or src

    local caller = QBCore.Functions.GetPlayer(src)
    if not caller then return end

    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('mnc-hydros:notify', src, {
            title = 'Hydraulics', description = 'You do not have permission to use this command.', type = 'error'
        })
        return
    end

    local target = QBCore.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('mnc-hydros:notify', src, {
            title = 'Hydraulics', description = 'Player not found (id=' .. tostring(args[1]) .. ').', type = 'error'
        })
        return
    end

    local ped     = GetPlayerPed(targetSrc)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        TriggerClientEvent('mnc-hydros:notify', src, {
            title = 'Hydraulics', description = 'Target player is not in a vehicle.', type = 'error'
        })
        return
    end

    local plate   = string.upper(GetVehicleNumberPlateText(vehicle):gsub('%s+', ''))
    local newTier = Config.HydroTier[hydroName]

    hydroData[plate] = {
        hydro = hydroName,
        type  = hydroCfg.type,
        tier  = newTier,
    }

    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_hydros` (`plate`, `hydro`, `type`, `tier`, `installed_by`)
              VALUES (?, ?, ?, ?, ?)
              ON DUPLICATE KEY UPDATE `hydro` = ?, `type` = ?, `tier` = ?, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, hydroName, hydroCfg.type, newTier, 'ADMIN:' .. caller.PlayerData.name,
              hydroName, hydroCfg.type, newTier }
        )
    end

    TriggerClientEvent('mnc-hydros:syncHydroData', -1, plate, hydroData[plate])

    TriggerClientEvent('mnc-hydros:notify', src, {
        title       = 'Hydraulics [Admin]',
        description = hydroCfg.label .. ' applied to plate ' .. plate .. ' (player ' .. targetSrc .. ').',
        type        = 'success',
        duration    = 5000,
    })

    if targetSrc ~= src then
        TriggerClientEvent('mnc-hydros:notify', targetSrc, {
            title       = 'Hydraulics',
            description = hydroCfg.label .. ' has been installed on your vehicle by an admin.',
            type        = 'success',
            duration    = 5000,
        })
    end

    print('^3[mnc-hydros]^7 ADMIN ' .. caller.PlayerData.name .. ' granted ' .. hydroName .. ' to plate=' .. plate)
end

RegisterCommand('hydrostreet', function(src, args)
    AdminGiveHydro(src, args, 'street_hydro')
end, true)

RegisterCommand('hydrocomp', function(src, args)
    AdminGiveHydro(src, args, 'comp_hydro')
end, true)

print('^2[mnc-hydros]^7 Loaded successfully!')