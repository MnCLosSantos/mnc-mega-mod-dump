local trailerLoads = {}

RegisterNetEvent('mnc-cartransporter:attachVehicle')
AddEventHandler('mnc-cartransporter:attachVehicle', function(trailerNet, vehicleNet, level, slot, offset, rotation)
    local trailerEnt = NetworkGetEntityFromNetworkId(trailerNet)
    local vehicleEnt = NetworkGetEntityFromNetworkId(vehicleNet)
    if not DoesEntityExist(trailerEnt) or not DoesEntityExist(vehicleEnt) then return end

    trailerLoads[trailerNet] = trailerLoads[trailerNet] or { vehicles = {} }


    for i = #trailerLoads[trailerNet].vehicles, 1, -1 do
        if trailerLoads[trailerNet].vehicles[i].vehicleNet == vehicleNet then
            table.remove(trailerLoads[trailerNet].vehicles, i)
        end
    end

    table.insert(trailerLoads[trailerNet].vehicles, {
        vehicleNet = vehicleNet,
        level = level,
        slot = slot,
        offset = offset,
        rotation = rotation
    })

    TriggerClientEvent('mnc-cartransporter:syncAttachment', -1, trailerNet, vehicleNet, level, slot, offset, rotation)
end)

RegisterNetEvent('mnc-cartransporter:detachVehicle')
AddEventHandler('mnc-cartransporter:detachVehicle', function(trailerNet, vehicleNet)
    if trailerLoads[trailerNet] then
        for i, v in ipairs(trailerLoads[trailerNet].vehicles) do
            if v.vehicleNet == vehicleNet then
                table.remove(trailerLoads[trailerNet].vehicles, i)
                break
            end
        end
    end
    TriggerClientEvent('mnc-cartransporter:syncDetach', -1, trailerNet, vehicleNet)
end)

-- Sync on join
AddEventHandler('playerJoining', function()
    local src = source
    for trailerNet, data in pairs(trailerLoads) do
        for _, v in ipairs(data.vehicles) do
            TriggerClientEvent('mnc-cartransporter:syncAttachment', src, trailerNet, v.vehicleNet, v.level, v.slot, v.offset, v.rotation)
        end
    end
end)