-- server.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- [plate] = { kit = 'pro_angle_kit', angle = 70, tier = 3 }
local angleData     = {}
local databaseReady = false

-- ===========================
-- Wait for oxmysql, create table, load data
-- ===========================
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
    Wait(2000)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `vehicle_angle_kits` (
            `plate`       VARCHAR(20)  PRIMARY KEY,
            `kit`         VARCHAR(50)  NOT NULL,
            `angle`       INT          DEFAULT 40,
            `tier`        INT          DEFAULT 1,
            `applied_by`  VARCHAR(50)  NOT NULL,
            `applied_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
            `updated_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    LoadAngleDataFromDatabase()
end)

function LoadAngleDataFromDatabase()
    MySQL.query('SELECT `plate`, `kit`, `angle`, `tier` FROM `vehicle_angle_kits`', {}, function(results)
        if results then
            for _, row in ipairs(results) do
                angleData[row.plate] = {
                    kit   = row.kit,
                    angle = row.angle,
                    tier  = row.tier,
                }
            end
            print('^2[mnc-anglekit]^7 Loaded ' .. #results .. ' angle kit(s) from database.')
        end
        databaseReady = true
        print('^2[mnc-anglekit]^7 Database ready.')
    end)
end

-- ===========================
-- Callback: return angle data for a plate
-- ===========================
QBCore.Functions.CreateCallback('mnc-anglekit:getAngleData', function(source, cb, plate)
    if not databaseReady then
        local waited = 0
        while not databaseReady and waited < 5000 do
            Wait(100)
            waited = waited + 100
        end
        if Config.Debug then
            print('^3[mnc-anglekit]^7 getAngleData waited ' .. waited .. 'ms for DB (plate=' .. tostring(plate) .. ')')
        end
    end
    cb(angleData[plate] or nil)
end)

-- ===========================
-- Job check helper
-- ===========================
local function HasAllowedJob(Player)
    if not Config.RequireJob then return true end
    local job   = Player.PlayerData.job
    local grade = job and job.grade.level or 0
    local minGrade = Config.AllowedJobs[job and job.name]
    if minGrade == nil then return false end
    return grade >= minGrade
end

-- ===========================
-- Apply any angle kit
-- ===========================
RegisterNetEvent('mnc-anglekit:applyKit', function(plate, kitName)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local kitCfg = Config.Kits[kitName]
    if not kitCfg then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = 'Angle Kit', description = 'Unknown kit type.', type = 'error'
        })
        return
    end

    if not plate or #plate < 1 or #plate > 20 then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = 'Angle Kit', description = 'Invalid vehicle plate.', type = 'error'
        })
        return
    end

    -- Check job restriction
    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = kitCfg.label, description = 'You do not have the required job to install this kit.', type = 'error'
        })
        return
    end

    -- Check player has the item
    local item = Player.Functions.GetItemByName(kitCfg.item)
    if not item or item.amount < 1 then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = kitCfg.label, description = 'You do not have a ' .. kitCfg.label .. '.', type = 'error'
        })
        return
    end

    local newTier = Config.KitTier[kitName]

    -- Prevent downgrade (same or lower tier)
    if angleData[plate] and angleData[plate].tier >= newTier then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = kitCfg.label,
            description = 'This vehicle already has an equal or higher angle kit installed.',
            type = 'error'
        })
        return
    end

    -- Consume item
    Player.Functions.RemoveItem(kitCfg.item, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[kitCfg.item], 'remove')

    -- Update memory
    angleData[plate] = {
        kit   = kitName,
        angle = kitCfg.angle,
        tier  = newTier,
    }

    -- Persist to DB
    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_angle_kits` (`plate`, `kit`, `angle`, `tier`, `applied_by`)
              VALUES (?, ?, ?, ?, ?)
              ON DUPLICATE KEY UPDATE `kit` = ?, `angle` = ?, `tier` = ?, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, kitName, kitCfg.angle, newTier, Player.PlayerData.name,
              kitName, kitCfg.angle, newTier }
        )
    end

    -- Sync to all clients
    TriggerClientEvent('mnc-anglekit:syncAngleData', -1, plate, angleData[plate])

    TriggerClientEvent('mnc-anglekit:notify', src, {
        title       = kitCfg.label,
        description = kitCfg.label .. ' installed! Steering lock set to ' .. kitCfg.angle .. '°.',
        type        = 'success',
        duration    = 6000,
    })

    if Config.Debug then
        print('^2[mnc-anglekit]^7 ' .. kitName .. ' applied to ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ===========================
-- /angle command — pro kit only, custom angle
-- ===========================
RegisterCommand('angle', function(src, args)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local vehicle = GetVehiclePedIsIn(GetPlayerPed(src), false)
    if vehicle == 0 then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = 'Angle Kit', description = 'You must be in a vehicle to use /angle.', type = 'error'
        })
        return
    end

    -- We rely on the client to send the plate — use a callback instead
    -- Actually trigger an event to client to resolve plate then reply
    TriggerClientEvent('mnc-anglekit:requestAngleCommand', src, args[1])
end, false)

-- ===========================
-- Server-side handler when client sends plate + desired angle from /angle command
-- ===========================
RegisterNetEvent('mnc-anglekit:applyAngleCommand', function(plate, amount)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local data = angleData[plate]
    if not data then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = 'Angle Kit', description = 'No angle kit found on this vehicle.', type = 'error'
        })
        return
    end

    local kitCfg = Config.Kits[data.kit]
    if not kitCfg or not kitCfg.canSetAngle then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = 'Angle Kit', description = 'Your current kit does not support the /angle command. Upgrade to a Pro Angle Kit.', type = 'error'
        })
        return
    end

    local num = tonumber(amount)
    if not num or num < Config.MinAngle or num > Config.MaxAngle then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = 'Angle Kit',
            description = ('Invalid angle. Enter a value between %d and %d.'):format(Config.MinAngle, Config.MaxAngle),
            type = 'error'
        })
        return
    end

    num = math.floor(num)
    angleData[plate].angle = num

    if databaseReady then
        MySQL.update(
            'UPDATE `vehicle_angle_kits` SET `angle` = ? WHERE `plate` = ?',
            { num, plate }
        )
    end

    TriggerClientEvent('mnc-anglekit:syncAngleData', -1, plate, angleData[plate])

    TriggerClientEvent('mnc-anglekit:notify', src, {
        title       = 'Angle Kit',
        description = 'Steering lock updated to ' .. num .. '°.',
        type        = 'success',
        duration    = 4000,
    })

    if Config.Debug then
        print('^2[mnc-anglekit]^7 ' .. plate .. ' angle -> ' .. num .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ===========================
-- Usable items
-- ===========================
QBCore.Functions.CreateUseableItem('basic_angle_kit', function(source)
    TriggerClientEvent('mnc-anglekit:applyKit', source, 'basic_angle_kit')
end)

QBCore.Functions.CreateUseableItem('street_angle_kit', function(source)
    TriggerClientEvent('mnc-anglekit:applyKit', source, 'street_angle_kit')
end)

QBCore.Functions.CreateUseableItem('pro_angle_kit', function(source)
    TriggerClientEvent('mnc-anglekit:applyKit', source, 'pro_angle_kit')
end)

-- ===========================
-- Usable item for remover
-- ===========================
QBCore.Functions.CreateUseableItem('angle_kit_remover', function(source)
    TriggerClientEvent('mnc-anglekit:removeKit', source)
end)

-- ===========================
-- Remove angle kit + RETURN the kit to the player
-- ===========================
RegisterNetEvent('mnc-anglekit:removeKit', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local removerCfg = Config.Remover
    if not removerCfg then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = 'Angle Kit Remover', description = 'Remover not configured.', type = 'error'
        })
        return
    end

    if not plate or #plate < 1 or #plate > 20 then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = 'Angle Kit Remover', description = 'Invalid vehicle plate.', type = 'error'
        })
        return
    end

    -- Job check
    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = removerCfg.label, description = 'You do not have the required job to remove kits.', type = 'error'
        })
        return
    end

    -- Check player has the remover item
    local removerItem = Player.Functions.GetItemByName(removerCfg.item)
    if not removerItem or removerItem.amount < 1 then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = removerCfg.label, description = 'You do not have an ' .. removerCfg.label .. '.', type = 'error'
        })
        return
    end

    -- Check if a kit actually exists on the vehicle
    local vehicleData = angleData[plate]
    if not vehicleData or not vehicleData.kit then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = removerCfg.label,
            description = 'No angle kit installed on this vehicle.',
            type = 'error'
        })
        return
    end

    local oldKitName = vehicleData.kit
    local oldKitCfg  = Config.Kits[oldKitName]

    if not oldKitCfg then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = removerCfg.label, description = 'Unknown kit type on vehicle.', type = 'error'
        })
        return
    end

    angleData[plate] = nil
    
    if databaseReady then
        MySQL.query('DELETE FROM `vehicle_angle_kits` WHERE `plate` = ?', { plate })
        if Config.Debug then
            print('^2[mnc-anglekit]^7 Kit removed from database for plate: ' .. plate)
        end
    end

    -- Sync removal to all clients (this removes the effect for everyone)
    TriggerClientEvent('mnc-anglekit:syncAngleData', -1, plate, nil)

    Player.Functions.AddItem(oldKitName, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[oldKitName], 'add')


    -- Success notification
    TriggerClientEvent('mnc-anglekit:notify', src, {
        title       = removerCfg.label,
        description = ('Successfully removed %s and returned it to your inventory!'):format(oldKitCfg.label),
        type        = 'success',
        duration    = 7000,
    })

    if Config.Debug then
        print('^2[mnc-anglekit]^7 Remover used on ' .. plate .. ' by ' .. Player.PlayerData.name .. 
              ' (returned ' .. oldKitName .. ')')
    end
end)

-- ===========================
-- Admin commands — grant kits directly to a player's current vehicle
-- Usage: /anglebasic [id]  /anglestreet [id]  /anglepro [id]
-- If no id given, applies to the invoking player.
-- ===========================
local function AdminGiveKit(src, args, kitName)
    local kitCfg = Config.Kits[kitName]
    if not kitCfg then return end

    -- Resolve target player (defaults to self)
    local targetSrc = tonumber(args[1]) or src

    -- Permission check — only admins can use these commands
    local caller = QBCore.Functions.GetPlayer(src)
    if not caller then return end
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = 'Angle Kit', description = 'You do not have permission to use this command.', type = 'error'
        })
        return
    end

    local target = QBCore.Functions.GetPlayer(targetSrc)
    if not target then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = 'Angle Kit', description = 'Player not found (id=' .. tostring(args[1]) .. ').', type = 'error'
        })
        return
    end

    -- Get the vehicle the target is currently driving
    local ped     = GetPlayerPed(targetSrc)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        TriggerClientEvent('mnc-anglekit:notify', src, {
            title = 'Angle Kit', description = 'Target player is not in a vehicle.', type = 'error'
        })
        return
    end

    local plate   = string.upper(GetVehicleNumberPlateText(vehicle):gsub('%s+', ''))
    local newTier = Config.KitTier[kitName]

    -- Overwrite whatever is on the vehicle (admin bypass of tier check)
    angleData[plate] = {
        kit   = kitName,
        angle = kitCfg.angle,
        tier  = newTier,
    }

    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_angle_kits` (`plate`, `kit`, `angle`, `tier`, `applied_by`)
              VALUES (?, ?, ?, ?, ?)
              ON DUPLICATE KEY UPDATE `kit` = ?, `angle` = ?, `tier` = ?, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, kitName, kitCfg.angle, newTier, 'ADMIN:' .. caller.PlayerData.name,
              kitName, kitCfg.angle, newTier }
        )
    end

    TriggerClientEvent('mnc-anglekit:syncAngleData', -1, plate, angleData[plate])

    -- Notify admin
    TriggerClientEvent('mnc-anglekit:notify', src, {
        title       = 'Angle Kit [Admin]',
        description = kitCfg.label .. ' applied to plate ' .. plate .. ' (player ' .. targetSrc .. ').',
        type        = 'success',
        duration    = 5000,
    })

    -- Notify target (if different from admin)
    if targetSrc ~= src then
        TriggerClientEvent('mnc-anglekit:notify', targetSrc, {
            title       = 'Angle Kit',
            description = kitCfg.label .. ' has been installed on your vehicle by an admin.',
            type        = 'success',
            duration    = 5000,
        })
    end

    print('^3[mnc-anglekit]^7 ADMIN ' .. caller.PlayerData.name .. ' granted ' .. kitName .. ' to plate=' .. plate)
end

RegisterCommand('anglebasic', function(src, args)
    AdminGiveKit(src, args, 'basic_angle_kit')
end, true)   -- true = restricted (only visible to ace-permitted players in F8)

RegisterCommand('anglestreet', function(src, args)
    AdminGiveKit(src, args, 'street_angle_kit')
end, true)

RegisterCommand('anglepro', function(src, args)
    AdminGiveKit(src, args, 'pro_angle_kit')
end, true)

print('^2[mnc-anglekit]^7 Loaded successfully!')