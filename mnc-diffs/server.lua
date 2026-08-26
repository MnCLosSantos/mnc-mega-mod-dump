-- server.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- [plate] = { diff = 'lsd_diff', type = 'lsd', tier = 2, installedAt = timestamp }
local diffData      = {}
local databaseReady = false

-- ===========================
-- Wait for oxmysql, create table, load data
-- ===========================
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
    Wait(2000)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `vehicle_diffs` (
            `plate`        VARCHAR(20)  PRIMARY KEY,
            `diff`         VARCHAR(50)  NOT NULL,
            `type`         VARCHAR(20)  NOT NULL,
            `tier`         INT          DEFAULT 1,
            `installed_by` VARCHAR(50)  NOT NULL,
            `installed_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
            `updated_at`   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    LoadDiffDataFromDatabase()
end)

function LoadDiffDataFromDatabase()
    MySQL.query('SELECT `plate`, `diff`, `type`, `tier` FROM `vehicle_diffs`', {}, function(results)
        if results then
            for _, row in ipairs(results) do
                diffData[row.plate] = {
                    diff = row.diff,
                    type = row.type,
                    tier = row.tier,
                }
            end
            print('^2[mnc-diffs]^7 Loaded ' .. #results .. ' differential(s) from database.')
        end
        databaseReady = true
        print('^2[mnc-diffs]^7 Database ready.')
    end)
end

-- ===========================
-- Callback: return diff data for a plate
-- ===========================
QBCore.Functions.CreateCallback('mnc-diffs:getDiffData', function(source, cb, plate)
    if not databaseReady then
        local waited = 0
        while not databaseReady and waited < 5000 do
            Wait(100)
            waited = waited + 100
        end
        if Config.Debug then
            print('^3[mnc-diffs]^7 getDiffData waited ' .. waited .. 'ms for DB (plate=' .. tostring(plate) .. ')')
        end
    end
    cb(diffData[plate] or nil)
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
-- Apply diff — triggered from client after install animation
-- ===========================
RegisterNetEvent('mnc-diffs:applyDiff', function(plate, diffName)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local diffCfg = Config.Diffs[diffName]
    if not diffCfg then
        TriggerClientEvent('mnc-diffs:notify', src, {
            title = 'Differential', description = 'Unknown differential type.', type = 'error'
        })
        return
    end

    if not plate or #plate < 1 or #plate > 20 then
        TriggerClientEvent('mnc-diffs:notify', src, {
            title = 'Differential', description = 'Invalid vehicle plate.', type = 'error'
        })
        return
    end

    -- Job check
    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-diffs:notify', src, {
            title = diffCfg.label, description = 'You do not have the required job to install this differential.', type = 'error'
        })
        return
    end

    -- Item check
    local item = Player.Functions.GetItemByName(diffCfg.item)
    if not item or item.amount < 1 then
        TriggerClientEvent('mnc-diffs:notify', src, {
            title = diffCfg.label, description = 'You do not have a ' .. diffCfg.label .. '.', type = 'error'
        })
        return
    end

    local newTier = Config.DiffTier[diffName]

    -- Tier check — no downgrades
    if diffData[plate] and diffData[plate].tier >= newTier then
        TriggerClientEvent('mnc-diffs:notify', src, {
            title       = diffCfg.label,
            description = 'This vehicle already has an equal or higher differential installed.',
            type        = 'error'
        })
        return
    end

    -- Consume item
    Player.Functions.RemoveItem(diffCfg.item, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[diffCfg.item], 'remove')

    -- Update memory
    diffData[plate] = {
        diff = diffName,
        type = diffCfg.type,
        tier = newTier,
    }

    -- Persist to DB
    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_diffs` (`plate`, `diff`, `type`, `tier`, `installed_by`)
              VALUES (?, ?, ?, ?, ?)
              ON DUPLICATE KEY UPDATE `diff` = ?, `type` = ?, `tier` = ?, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, diffName, diffCfg.type, newTier, Player.PlayerData.name,
              diffName, diffCfg.type, newTier }
        )
    end

    -- Sync to all clients
    TriggerClientEvent('mnc-diffs:syncDiffData', -1, plate, diffData[plate])

    TriggerClientEvent('mnc-diffs:notify', src, {
        title       = diffCfg.label,
        description = diffCfg.label .. ' installed successfully!',
        type        = 'success',
        duration    = 6000,
    })

    if Config.Debug then
        print('^2[mnc-diffs]^7 ' .. diffName .. ' applied to ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ===========================
-- Remove diff — called when the diff wears out (3hr duration expires)
-- ===========================
RegisterNetEvent('mnc-diffs:removeDiff', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not diffData[plate] then return end

    diffData[plate] = nil

    if databaseReady then
        MySQL.query('DELETE FROM `vehicle_diffs` WHERE `plate` = ?', { plate })
    end

    TriggerClientEvent('mnc-diffs:syncDiffData', -1, plate, nil)

    TriggerClientEvent('mnc-diffs:notify', src, {
        title       = 'Differential',
        description = 'Your differential has worn out and been removed.',
        type        = 'error',
        duration    = 6000,
    })

    if Config.Debug then
        print('^3[mnc-diffs]^7 Differential worn out and removed from plate=' .. plate)
    end
end)

-- ===========================
-- Remove diff 
-- ===========================
RegisterNetEvent('mnc-diffs:removeDiffManual', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-diffs:notify', src, {
            title       = 'Differential Removal',
            description = 'You do not have the required job to remove this differential.',
            type        = 'error',
        })
        return
    end

    local current = diffData[plate]
    if not current then
        TriggerClientEvent('mnc-diffs:notify', src, {
            title       = 'Differential Removal',
            description = 'This vehicle has no differential installed.',
            type        = 'error',
        })
        return
    end

    local diffCfg = Config.Diffs[current.diff]
    if not diffCfg then
        TriggerClientEvent('mnc-diffs:notify', src, {
            title       = 'Differential Removal',
            description = 'Unknown differential type on this vehicle.',
            type        = 'error',
        })
        return
    end

    -- Return the item to the mechanic's inventory
    Player.Functions.AddItem(diffCfg.item, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[diffCfg.item], 'add')

    diffData[plate] = nil

    if databaseReady then
        MySQL.query('DELETE FROM `vehicle_diffs` WHERE `plate` = ?', { plate })
    end

    TriggerClientEvent('mnc-diffs:syncDiffData', -1, plate, nil)

    TriggerClientEvent('mnc-diffs:notify', src, {
        title       = 'Differential Removal',
        description = diffCfg.label .. ' removed and returned to your inventory.',
        type        = 'success',
        duration    = 6000,
    })

    if Config.Debug then
        print('^3[mnc-diffs]^7 ' .. current.diff .. ' manually removed from ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ===========================
-- Usable items
-- ===========================
QBCore.Functions.CreateUseableItem('welded_diff', function(source)
    TriggerClientEvent('mnc-diffs:applyDiff', source, 'welded_diff')
end)

QBCore.Functions.CreateUseableItem('lsd_diff', function(source)
    TriggerClientEvent('mnc-diffs:applyDiff', source, 'lsd_diff')
end)

QBCore.Functions.CreateUseableItem('diff_toolbox', function(source)
    TriggerClientEvent('mnc-diffs:startRemoval', source)
end)

-- ===========================
-- Admin commands — /diffwelded [id]  /difflsd [id]
-- ===========================
local function AdminGiveDiff(src, args, diffName)
    local diffCfg = Config.Diffs[diffName]
    if not diffCfg then return end

    local targetSrc = tonumber(args[1]) or src

    local caller = QBCore.Functions.GetPlayer(src)
    if not caller then return end

    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('mnc-diffs:notify', src, {
            title = 'Differential', description = 'You do not have permission to use this command.', type = 'error'
        })
        return
    end

    local target = QBCore.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('mnc-diffs:notify', src, {
            title = 'Differential', description = 'Player not found (id=' .. tostring(args[1]) .. ').', type = 'error'
        })
        return
    end

    local ped     = GetPlayerPed(targetSrc)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        TriggerClientEvent('mnc-diffs:notify', src, {
            title = 'Differential', description = 'Target player is not in a vehicle.', type = 'error'
        })
        return
    end

    local plate   = string.upper(GetVehicleNumberPlateText(vehicle):gsub('%s+', ''))
    local newTier = Config.DiffTier[diffName]

    diffData[plate] = {
        diff = diffName,
        type = diffCfg.type,
        tier = newTier,
    }

    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_diffs` (`plate`, `diff`, `type`, `tier`, `installed_by`)
              VALUES (?, ?, ?, ?, ?)
              ON DUPLICATE KEY UPDATE `diff` = ?, `type` = ?, `tier` = ?, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, diffName, diffCfg.type, newTier, 'ADMIN:' .. caller.PlayerData.name,
              diffName, diffCfg.type, newTier }
        )
    end

    TriggerClientEvent('mnc-diffs:syncDiffData', -1, plate, diffData[plate])

    TriggerClientEvent('mnc-diffs:notify', src, {
        title       = 'Differential [Admin]',
        description = diffCfg.label .. ' applied to plate ' .. plate .. ' (player ' .. targetSrc .. ').',
        type        = 'success',
        duration    = 5000,
    })

    if targetSrc ~= src then
        TriggerClientEvent('mnc-diffs:notify', targetSrc, {
            title       = 'Differential',
            description = diffCfg.label .. ' has been installed on your vehicle by an admin.',
            type        = 'success',
            duration    = 5000,
        })
    end

    print('^3[mnc-diffs]^7 ADMIN ' .. caller.PlayerData.name .. ' granted ' .. diffName .. ' to plate=' .. plate)
end

RegisterCommand('diffwelded', function(src, args)
    AdminGiveDiff(src, args, 'welded_diff')
end, true)

RegisterCommand('difflsd', function(src, args)
    AdminGiveDiff(src, args, 'lsd_diff')
end, true)

print('^2[mnc-diffs]^7 Loaded successfully!')