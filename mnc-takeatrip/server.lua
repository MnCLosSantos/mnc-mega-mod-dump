-- server.lua

local QBCore = exports['qb-core']:GetCoreObject()

-- Fixed: The callback must be triggered on the client using TriggerClientEvent
RegisterNetEvent('mnc-takeatrip:server:chargePlayer', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        TriggerClientEvent('mnc-takeatrip:client:chargeResult', src, false)
        return
    end

    local success = false

    if Player.PlayerData.money.cash >= amount then
        Player.Functions.RemoveMoney('cash', amount)
        success = true
    elseif Player.PlayerData.money.bank >= amount then
        Player.Functions.RemoveMoney('bank', amount)
        success = true
    end

    TriggerClientEvent('mnc-takeatrip:client:chargeResult', src, success)
end)

print("^2[mnc-takeatrip]^7 Script loaded successfully!")