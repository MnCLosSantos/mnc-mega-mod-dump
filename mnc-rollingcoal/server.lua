-- server.lua
local QBCore = exports['qb-core']:GetCoreObject()
local smokeData     = {}   -- [plate] = { amount, egr_delete, dpf_delete }
local databaseReady = false

-- Helper: check if player has allowed job & sufficient grade
local function HasAllowedJob(player)
    if not Config.RequireJob then
        return true
    end

    local job = player.PlayerData.job.name
    local grade = player.PlayerData.job.grade.level or 0

    local minGrade = Config.AllowedJobs[job]
    if minGrade == nil then
        return false
    end

    return grade >= minGrade
end

-- ===========================
-- Wait for oxmysql, create table, load data
-- ===========================
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
    Wait(2000)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `vehicle_smoke_kits` (
            `plate`        VARCHAR(20)  PRIMARY KEY,
            `smoke_amount` INT          DEFAULT 1,
            `egr_delete`   TINYINT(1)   DEFAULT 0,
            `dpf_delete`   TINYINT(1)   DEFAULT 0,
            `applied_by`   VARCHAR(50)  NOT NULL,
            `applied_at`   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
            `updated_at`   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Add columns if upgrading from older version
    MySQL.query([[ALTER TABLE `vehicle_smoke_kits` ADD COLUMN IF NOT EXISTS `egr_delete` TINYINT(1) DEFAULT 0]])
    MySQL.query([[ALTER TABLE `vehicle_smoke_kits` ADD COLUMN IF NOT EXISTS `dpf_delete` TINYINT(1) DEFAULT 0]])

    LoadSmokeDataFromDatabase()
    -- NOTE: databaseReady is set inside the callback in LoadSmokeDataFromDatabase,
    -- after all rows are populated, to prevent a race condition on script restart.
end)

function LoadSmokeDataFromDatabase()
    MySQL.query('SELECT `plate`, `smoke_amount`, `egr_delete`, `dpf_delete` FROM `vehicle_smoke_kits`', {}, function(results)
        if results then
            for _, row in ipairs(results) do
                smokeData[row.plate] = {
                    amount     = row.smoke_amount,
                    egr_delete = row.egr_delete == 1,
                    dpf_delete = row.dpf_delete == 1
                }
            end
            print('^2[mnc-rollingcoal]^7 Loaded ' .. #results .. ' smoke kit(s) from database.')
        end
        -- Mark DB as ready AFTER data is populated
        databaseReady = true
        print('^2[mnc-rollingcoal]^7 Database ready.')
    end)
end

-- ===========================
-- Callback: return smoke + mod data for a plate
-- Waits for DB to finish loading before responding
-- ===========================
QBCore.Functions.CreateCallback('mnc-rollingcoal:getSmokeData', function(source, cb, plate)
    if not databaseReady then
        local waited = 0
        while not databaseReady and waited < 5000 do
            Wait(100)
            waited = waited + 100
        end
        if Config.Debug then
            print('^3[mnc-rollingcoal]^7 getSmokeData waited ' .. waited .. 'ms for DB (plate=' .. tostring(plate) .. ')')
        end
    end
    cb(smokeData[plate] or nil)
end)

-- ===========================
-- Apply EGR Delete Kit
-- ===========================
RegisterNetEvent('mnc-rollingcoal:applyEgrKit', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'EGR Delete',
            description = 'Only authorized mechanics can install this.',
            type = 'error'
        })
        return
    end

    if not plate or #plate < 1 or #plate > 20 then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'EGR Delete', description = 'Invalid vehicle plate.', type = 'error'
        })
        return
    end

    local item = Player.Functions.GetItemByName(Config.EgrDeleteItem)
    if not item or item.amount < 1 then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'EGR Delete', description = 'You do not have an EGR delete kit.', type = 'error'
        })
        return
    end

    if smokeData[plate] and smokeData[plate].egr_delete then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'EGR Delete', description = 'EGR delete is already installed on this vehicle.', type = 'error'
        })
        return
    end

    Player.Functions.RemoveItem(Config.EgrDeleteItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.EgrDeleteItem], 'remove')

    if not smokeData[plate] then
        smokeData[plate] = { amount = 0, egr_delete = false, dpf_delete = false }
    end
    smokeData[plate].egr_delete = true

    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_smoke_kits` (`plate`, `smoke_amount`, `egr_delete`, `dpf_delete`, `applied_by`)
              VALUES (?, 0, 1, ?, ?)
              ON DUPLICATE KEY UPDATE `egr_delete` = 1, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, smokeData[plate].dpf_delete and 1 or 0, Player.PlayerData.name }
        )
    end

    TriggerClientEvent('mnc-rollingcoal:syncModData', -1, plate, smokeData[plate])

    TriggerClientEvent('mnc-rollingcoal:notify', src, {
        title    = 'EGR Delete',
        description = 'EGR delete kit installed!',
        type     = 'success',
        duration = 5000
    })

    if Config.Debug then
        print('^2[mnc-rollingcoal]^7 EGR delete applied to ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ===========================
-- Apply DPF Delete Kit
-- ===========================
RegisterNetEvent('mnc-rollingcoal:applyDpfKit', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'DPF Delete',
            description = 'Only authorized mechanics can install this.',
            type = 'error'
        })
        return
    end

    if not plate or #plate < 1 or #plate > 20 then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'DPF Delete', description = 'Invalid vehicle plate.', type = 'error'
        })
        return
    end

    local item = Player.Functions.GetItemByName(Config.DpfDeleteItem)
    if not item or item.amount < 1 then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'DPF Delete', description = 'You do not have a DPF delete kit.', type = 'error'
        })
        return
    end

    if smokeData[plate] and smokeData[plate].dpf_delete then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'DPF Delete', description = 'DPF delete is already installed on this vehicle.', type = 'error'
        })
        return
    end

    Player.Functions.RemoveItem(Config.DpfDeleteItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.DpfDeleteItem], 'remove')

    if not smokeData[plate] then
        smokeData[plate] = { amount = 0, egr_delete = false, dpf_delete = false }
    end
    smokeData[plate].dpf_delete = true

    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_smoke_kits` (`plate`, `smoke_amount`, `egr_delete`, `dpf_delete`, `applied_by`)
              VALUES (?, 0, ?, 1, ?)
              ON DUPLICATE KEY UPDATE `dpf_delete` = 1, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, smokeData[plate].egr_delete and 1 or 0, Player.PlayerData.name }
        )
    end

    TriggerClientEvent('mnc-rollingcoal:syncModData', -1, plate, smokeData[plate])

    TriggerClientEvent('mnc-rollingcoal:notify', src, {
        title    = 'DPF Delete',
        description = 'DPF delete kit installed!',
        type     = 'success',
        duration = 5000
    })

    if Config.Debug then
        print('^2[mnc-rollingcoal]^7 DPF delete applied to ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ===========================
-- Apply Smoke Kit (requires EGR + DPF already installed)
-- ===========================
RegisterNetEvent('mnc-rollingcoal:applyKitToVehicle', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'Rolling Coal',
            description = 'Only authorized mechanics can install this.',
            type = 'error'
        })
        return
    end

    local item = Player.Functions.GetItemByName(Config.SmokeKitItem)
    if not item or item.amount < 1 then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'Rolling Coal', description = 'You do not have a smoke kit.', type = 'error'
        })
        return
    end

    if smokeData[plate] and smokeData[plate].amount and smokeData[plate].amount > 0 then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'Rolling Coal', description = 'A smoke kit is already installed on this vehicle.', type = 'error'
        })
        return
    end

    local hasEgr = smokeData[plate] and smokeData[plate].egr_delete
    local hasDpf = smokeData[plate] and smokeData[plate].dpf_delete

    if not hasEgr or not hasDpf then
        local missing = {}
        if not hasEgr then missing[#missing + 1] = 'EGR Delete Kit' end
        if not hasDpf then missing[#missing + 1] = 'DPF Delete Kit' end
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title       = 'Rolling Coal',
            description = 'You must install the following first: ' .. table.concat(missing, ', '),
            type        = 'error',
            duration    = 7000
        })
        return
    end

    if not plate or #plate < 1 or #plate > 20 then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'Rolling Coal', description = 'Invalid vehicle plate.', type = 'error'
        })
        return
    end

    Player.Functions.RemoveItem(Config.SmokeKitItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.SmokeKitItem], 'remove')

    smokeData[plate].amount = 1

    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_smoke_kits` (`plate`, `smoke_amount`, `egr_delete`, `dpf_delete`, `applied_by`)
              VALUES (?, 1, 1, 1, ?)
              ON DUPLICATE KEY UPDATE `smoke_amount` = 1, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, Player.PlayerData.name }
        )
    end

    TriggerClientEvent('mnc-rollingcoal:notify', src, {
        title    = 'Rolling Coal',
        description = 'Smoke kit installed! Use /rollingcoal to adjust the output level.',
        type     = 'success',
        duration = 7000
    })

    if Config.Debug then
        print('^2[mnc-rollingcoal]^7 Smoke kit applied to ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ===========================
-- Set smoke amount (installed kit — requires kit in DB)
-- ===========================
RegisterNetEvent('mnc-rollingcoal:setSmokeAmount', function(plate, amount)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not smokeData[plate] then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'Rolling Coal', description = 'No smoke kit found on this vehicle.', type = 'error'
        })
        return
    end

    if type(amount) ~= 'number' or amount < 0 or amount > Config.MaxSmokeAmount then return end

    smokeData[plate].amount = amount

    if databaseReady then
        MySQL.update(
            'UPDATE `vehicle_smoke_kits` SET `smoke_amount` = ? WHERE `plate` = ?',
            { amount, plate }
        )
    end

    TriggerClientEvent('mnc-rollingcoal:syncSmokeAmount', -1, plate, amount)

    if Config.Debug then
        print('^2[mnc-rollingcoal]^7 ' .. plate .. ' smoke -> ' .. amount .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ===========================
-- Set smoke amount for auto-kit vehicles
-- ===========================
RegisterNetEvent('mnc-rollingcoal:setAutoKitAmount', function(plate, amount)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if type(amount) ~= 'number' or amount < 0 or amount > Config.MaxSmokeAmount then return end

    if not smokeData[plate] then
        smokeData[plate] = { amount = amount, autoKit = true, egr_delete = true, dpf_delete = true }
    else
        smokeData[plate].amount = amount
    end

    if databaseReady then
        MySQL.query(
            [[INSERT INTO `vehicle_smoke_kits` (`plate`, `smoke_amount`, `egr_delete`, `dpf_delete`, `applied_by`)
              VALUES (?, ?, 1, 1, ?)
              ON DUPLICATE KEY UPDATE `smoke_amount` = ?, `updated_at` = CURRENT_TIMESTAMP]],
            { plate, amount, Player.PlayerData.name, amount }
        )
    end

    TriggerClientEvent('mnc-rollingcoal:syncSmokeAmount', -1, plate, amount)

    if Config.Debug then
        print('^2[mnc-rollingcoal]^7 Auto-kit ' .. plate .. ' smoke -> ' .. amount .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ===========================
-- Remove ALL kits from a vehicle (EGR + DPF + smoke kit)
-- Triggered when a mechanic uses the removal_kit item on a vehicle
-- ===========================
RegisterNetEvent('mnc-rollingcoal:removeAllKits', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not HasAllowedJob(Player) then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'Kit Removal',
            description = 'Only authorized mechanics can remove kits.',
            type = 'error'
        })
        return
    end

    if not plate or #plate < 1 or #plate > 20 then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'Kit Removal', description = 'Invalid vehicle plate.', type = 'error'
        })
        return
    end

    -- Verify the player actually has the removal kit item
    local item = Player.Functions.GetItemByName(Config.RemovalKitItem)
    if not item or item.amount < 1 then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'Kit Removal', description = 'You do not have a removal kit.', type = 'error'
        })
        return
    end

    -- Check there is something to remove
    local existing = smokeData[plate]
    if not existing or (not existing.egr_delete and not existing.dpf_delete and (not existing.amount or existing.amount == 0)) then
        TriggerClientEvent('mnc-rollingcoal:notify', src, {
            title = 'Kit Removal', description = 'No kits are installed on this vehicle.', type = 'error'
        })
        return
    end

    -- Track which items to refund before wiping
    local hadEgr   = existing.egr_delete   or false
    local hadDpf   = existing.dpf_delete   or false
    local hadSmoke = existing.amount and existing.amount > 0


    -- Refund removed items if configured
    if Config.RefundOnRemoval then
        if hadSmoke then
            Player.Functions.AddItem(Config.SmokeKitItem, 1)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.SmokeKitItem], 'add')
        end
        if hadEgr then
            Player.Functions.AddItem(Config.EgrDeleteItem, 1)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.EgrDeleteItem], 'add')
        end
        if hadDpf then
            Player.Functions.AddItem(Config.DpfDeleteItem, 1)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.DpfDeleteItem], 'add')
        end
    end

    -- Wipe server-side cache
    smokeData[plate] = nil

    -- Remove from database
    if databaseReady then
        MySQL.query('DELETE FROM `vehicle_smoke_kits` WHERE `plate` = ?', { plate })
    end

    -- Broadcast removal to ALL clients so smoke effects stop everywhere immediately
    TriggerClientEvent('mnc-rollingcoal:syncRemoval', -1, plate)

    -- Build refund/result message
    local removed = {}
    if hadEgr   then removed[#removed + 1] = 'EGR Delete' end
    if hadDpf   then removed[#removed + 1] = 'DPF Delete' end
    if hadSmoke then removed[#removed + 1] = 'Smoke Kit'  end

    local desc = 'Removed: ' .. table.concat(removed, ', ') .. '.'
    if Config.RefundOnRemoval then
        desc = desc .. ' Items returned to your inventory.'
    end

    TriggerClientEvent('mnc-rollingcoal:notify', src, {
        title    = 'Kit Removal',
        description = desc,
        type     = 'success',
        duration = 7000
    })

    if Config.Debug then
        print('^2[mnc-rollingcoal]^7 All kits removed from ' .. plate .. ' by ' .. Player.PlayerData.name)
    end
end)

-- ===========================
-- Usable items
-- ===========================
QBCore.Functions.CreateUseableItem(Config.SmokeKitItem, function(source, item)
    TriggerClientEvent('mnc-rollingcoal:applySmokeKit', source)
end)

QBCore.Functions.CreateUseableItem(Config.EgrDeleteItem, function(source, item)
    TriggerClientEvent('mnc-rollingcoal:applyEgrKit', source)
end)

QBCore.Functions.CreateUseableItem(Config.DpfDeleteItem, function(source, item)
    TriggerClientEvent('mnc-rollingcoal:applyDpfKit', source)
end)

QBCore.Functions.CreateUseableItem(Config.RemovalKitItem, function(source, item)
    TriggerClientEvent('mnc-rollingcoal:applyRemovalKit', source)
end)

print('^2[mnc-rollingcoal]^7 Loaded successfully!')