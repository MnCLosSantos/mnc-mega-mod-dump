local QBCore = exports['qb-core']:GetCoreObject()
local ActiveAids = {}

-- Clear all aids on script restart
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for targetId, _ in pairs(ActiveAids) do
            TriggerClientEvent('mnc-crutch:removeClientAid', targetId)
        end
        ActiveAids = {}
    end
end)

RegisterNetEvent('mnc-crutch:applyAid', function(targetId, aidType, duration)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or Player.PlayerData.job.name ~= Config.EMSJob then return end
    if not aidType or not Config.Aids[aidType] then return end

    duration = tonumber(duration) or Config.DefaultDuration[aidType] or 15
    local endTime = os.time() + (duration * 60)
    ActiveAids[targetId] = { aid = aidType, expires = endTime }

    TriggerClientEvent('mnc-crutch:applyClientAid', targetId, aidType, endTime)
    TriggerClientEvent('mnc-crutch:notify', src, "Applied "..aidType.." for "..duration.." minutes.")
end)

RegisterNetEvent('mnc-crutch:removeAid', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or Player.PlayerData.job.name ~= Config.EMSJob then return end

    ActiveAids[targetId] = nil
    TriggerClientEvent('mnc-crutch:removeClientAid', targetId)
    TriggerClientEvent('mnc-crutch:notify', src, "Mobility aid removed from player.")
end)

RegisterNetEvent('mnc-crutch:requestSync', function()
    local src = source
    if ActiveAids[src] then
        TriggerClientEvent('mnc-crutch:applyClientAid', src, ActiveAids[src].aid, ActiveAids[src].expires)
    end
end)

QBCore.Functions.CreateCallback('mnc-crutch:getRemainingTime', function(source, cb, targetId)
    if not Config.EMSCanSeeRemaining then
        cb(0)
        return
    end
    if ActiveAids[targetId] then
        local remaining = ActiveAids[targetId].expires - os.time()
        cb(math.max(0, math.floor(remaining / 60)))
    else
        cb(0)
    end
end)

print("^2[mnc-crutch]^7 Script loaded successfully!")