local QBCore = exports['qb-core']:GetCoreObject()

local function LoadGaugeData(plate, callback)
    MySQL.query('SELECT style, bezel, installed FROM vehicle_gauges WHERE plate = ?',
        {plate}, function(result)
        local data = { style = Config.UI.defaultStyle, bezel = Config.UI.defaultBezel, installed = true }
        if result[1] then
            data.style = result[1].style
            data.bezel = result[1].bezel
            data.installed = not (result[1].installed == 0 or result[1].installed == false)
        end
        callback(data)
    end)
end


QBCore.Functions.CreateCallback('mnc-boostgauge:getInstalledGauges', function(source, cb, plate)
    LoadGaugeData(plate, function(gauges)
        if Config.Debug then
            print("[gauge-removal] getInstalledGauges:", plate, json.encode(gauges))
        end
        cb(gauges)
    end)
end)

RegisterNetEvent('mnc-boostgauge:saveVehicleGauge', function(plate)
    if not plate then return end
    MySQL.query('UPDATE vehicle_gauges SET installed = 1 WHERE plate = ?', { plate })
end)

-- ==============================
-- Register the removal tool as a usable, reusable item
-- ==============================
CreateThread(function()
    if Config.RemovalItem then
        QBCore.Functions.CreateUseableItem(Config.RemovalItem, function(source)
            local Player = QBCore.Functions.GetPlayer(source)
            if Player then
                TriggerClientEvent('mnc-boostgauge:useRemovalItem', source, Config.RemovalItem)
            end
        end)
    end
end)

RegisterNetEvent('mnc-boostgauge:removeVehicleGauge', function(plate, styleItem, bezelItem)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    MySQL.query([[
        INSERT INTO vehicle_gauges (plate, style, bezel, installed)
        VALUES (?, ?, ?, 0)
        ON DUPLICATE KEY UPDATE installed = 0
    ]], {plate, Config.UI.defaultStyle, Config.UI.defaultBezel}, function()
        if Config.Debug then
            print("[gauge-removal] Removed gauge for plate:", plate)
        end
    end)

    if styleItem and QBCore.Shared.Items[styleItem] then
        Player.Functions.AddItem(styleItem, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[styleItem], "add", 1)
    end

    if bezelItem and QBCore.Shared.Items[bezelItem] then
        Player.Functions.AddItem(bezelItem, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[bezelItem], "add", 1)
    end

    TriggerClientEvent('mnc-boostgauge:gaugeRemoved', src, plate)
end)