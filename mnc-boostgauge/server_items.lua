local QBCore = exports['qb-core']:GetCoreObject()

-- Initialize database table for vehicle gauges
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS vehicle_gauges (
            plate VARCHAR(8) NOT NULL,
            style INT DEFAULT 1,
            bezel INT DEFAULT 1,
            PRIMARY KEY (plate)
        )
    ]], {}, function()
        MySQL.query([[
            SELECT COUNT(*) as cnt FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'vehicle_gauges' AND COLUMN_NAME = 'installed'
        ]], {}, function(result)
            if result and result[1] and result[1].cnt == 0 then
                MySQL.query('ALTER TABLE vehicle_gauges ADD COLUMN installed TINYINT(1) NOT NULL DEFAULT 1', {}, function()
                    print("^2[mnc-boostgauge-removal]^7 Migrated vehicle_gauges table: added 'installed' column")
                end)
            end
        end)
    end)
end)

-- Load vehicle gauge data from database
local function LoadVehicleGaugeData(plate, callback)
    MySQL.query('SELECT style, bezel FROM vehicle_gauges WHERE plate = ?', 
        {plate}, function(result)
        local gaugeData = { style = Config.UI.defaultStyle, bezel = Config.UI.defaultBezel }
        if result[1] then
            gaugeData.style = result[1].style
            gaugeData.bezel = result[1].bezel
        end
        callback(gaugeData)
    end)
end

-- Save vehicle gauge data to database
local function SaveVehicleGaugeData(plate, partType, value)
    if partType == 'preset' then
        local preset = Config.Presets[value]
        if not preset then
            if Config.Debug then
                print("^2[mnc-boostgauge]^7 Invalid preset:", value)
            end
            return
        end
        MySQL.query([[
            INSERT INTO vehicle_gauges (plate, style, bezel)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE
                style = ?,
                bezel = ?
        ]], {
            plate, preset.style, preset.bezel,
            preset.style, preset.bezel
        }, function()
            if Config.Debug then
                print("^2[mnc-boostgauge]^7 Saved preset for plate:", plate, "style:", preset.style, "bezel:", preset.bezel)
            end
        end)
    else
        local field = partType == 'style' and 'style' or 'bezel'
        MySQL.query([[
            INSERT INTO vehicle_gauges (plate, ]] .. field .. [[)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE
                ]] .. field .. [[ = ?
        ]], {
            plate, value,
            value
        }, function()
            if Config.Debug then
                print("^2[mnc-boostgauge]^7 Saved", field, "for plate:", plate, "value:", value)
            end
        end)
    end
end

-- ==============================
-- Register Usable Items
-- ==============================
CreateThread(function()
    for itemName, styleId in pairs(Config.StyleItems) do
        QBCore.Functions.CreateUseableItem(itemName, function(source)
            local Player = QBCore.Functions.GetPlayer(source)
            if Player then
                TriggerClientEvent('mnc-boostgauge:useItem', source, itemName, 'style', styleId)
            end
        end)
    end

    for itemName, bezelId in pairs(Config.BezelItems) do
        QBCore.Functions.CreateUseableItem(itemName, function(source)
            local Player = QBCore.Functions.GetPlayer(source)
            if Player then
                TriggerClientEvent('mnc-boostgauge:useItem', source, itemName, 'bezel', bezelId)
            end
        end)
    end

    for itemName, presetId in pairs(Config.PresetItems) do
        QBCore.Functions.CreateUseableItem(itemName, function(source)
            local Player = QBCore.Functions.GetPlayer(source)
            if Player then
                TriggerClientEvent('mnc-boostgauge:useItem', source, itemName, 'preset', presetId)
            end
        end)
    end
end)

-- ==============================
-- Save Vehicle Gauge
-- ==============================
RegisterNetEvent('mnc-boostgauge:saveVehicleGauge', function(plate, partType, value, replacedItem, itemUsed)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Save to database
    SaveVehicleGaugeData(plate, partType, value)

    -- Remove the used item from player's inventory
    if itemUsed and QBCore.Shared.Items[itemUsed] then
        Player.Functions.RemoveItem(itemUsed, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemUsed], "remove", 1)
    end


    -- Fetch updated gauges to sync with client
    LoadVehicleGaugeData(plate, function(gauges)
        TriggerClientEvent('mnc-boostgauge:syncStyleBezel', src, gauges.style, gauges.bezel)
    end)
end)

-- ==============================
-- Fetch Installed Gauges
-- ==============================
QBCore.Functions.CreateCallback('mnc-boostgauge:getInstalledGauges', function(source, cb, plate)
    LoadVehicleGaugeData(plate, function(gauges)
        if Config.Debug then
            print("getInstalledGauges: Plate:", plate, "Gauges:", json.encode(gauges))
        end
        cb(gauges)
    end)
end)

-- ==============================
-- Load Gauges for Client
-- ==============================
RegisterNetEvent('mnc-boostgauge:loadGauges', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Since we're not storing all gauges in memory, return empty table
    TriggerClientEvent('mnc-boostgauge:loadGauges', src, {})
end)

print("^2[mnc-boostgauge]^7 Script loaded successfully!")