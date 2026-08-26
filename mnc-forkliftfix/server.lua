local attachedVehicles = {}     -- [forkliftNetId] = { vehicleNetId, offset, rotation, mode }
local forkliftAnchors = {}      -- [vehicleNetId] = { forkliftNetId, offset, rotation }

-- Multi-level stacking: baseNet -> direct top data
local vehicleStacks = {}  -- [baseNetId] = { topNetId, offset, rotation }

RegisterNetEvent('mnc_forkliftfix:attachVehicle')
AddEventHandler('mnc_forkliftfix:attachVehicle', function(forkliftNet, vehicleNet, offset, rotation, entityType)
    local src = source
    local forkliftEnt = NetworkGetEntityFromNetworkId(forkliftNet)
    local vehicleEnt = NetworkGetEntityFromNetworkId(vehicleNet)
    if not DoesEntityExist(forkliftEnt) or not DoesEntityExist(vehicleEnt) then return end

    entityType = entityType or 'vehicle'

    attachedVehicles[forkliftNet] = {
        vehicleNet = vehicleNet,
        offset = offset,
        rotation = rotation,
        mode = 'forks',
        entityType = entityType
    }

    TriggerClientEvent('mnc_forkliftfix:syncAttachment', -1, forkliftNet, vehicleNet, offset, rotation, entityType)
end)

RegisterNetEvent('mnc_forkliftfix:detachVehicle')
AddEventHandler('mnc_forkliftfix:detachVehicle', function(forkliftNet)
    if attachedVehicles[forkliftNet] then
        attachedVehicles[forkliftNet] = nil
        TriggerClientEvent('mnc_forkliftfix:syncDetach', -1, forkliftNet)
    end
end)

RegisterNetEvent('mnc_forkliftfix:attachForklift')
AddEventHandler('mnc_forkliftfix:attachForklift', function(vehicleNet, forkliftNet, offset, rotation)
    local src = source
    local vehicleEnt = NetworkGetEntityFromNetworkId(vehicleNet)
    local forkliftEnt = NetworkGetEntityFromNetworkId(forkliftNet)
    if not DoesEntityExist(vehicleEnt) or not DoesEntityExist(forkliftEnt) then return end

    forkliftAnchors[vehicleNet] = {
        forkliftNet = forkliftNet,
        offset = offset,
        rotation = rotation
    }

    TriggerClientEvent('mnc_forkliftfix:syncForkliftAttachment', -1, vehicleNet, forkliftNet, offset, rotation)
end)

RegisterNetEvent('mnc_forkliftfix:detachForklift')
AddEventHandler('mnc_forkliftfix:detachForklift', function(vehicleNet)
    if forkliftAnchors[vehicleNet] then
        local forkliftNet = forkliftAnchors[vehicleNet].forkliftNet
        forkliftAnchors[vehicleNet] = nil
        TriggerClientEvent('mnc_forkliftfix:syncForkliftDetach', -1, vehicleNet, forkliftNet)
    end
end)

-- ====================== VEHICLE STACKING ======================

RegisterNetEvent('mnc_forkliftfix:attachStack')
AddEventHandler('mnc_forkliftfix:attachStack', function(topNet, baseNet, offset, rotation)
    local src = source
    local topEnt = NetworkGetEntityFromNetworkId(topNet)
    local baseEnt = NetworkGetEntityFromNetworkId(baseNet)

    if not DoesEntityExist(topEnt) or not DoesEntityExist(baseEnt) then return end

    vehicleStacks[baseNet] = {
        topNetId = topNet,
        offset = offset,
        rotation = rotation
    }

    TriggerClientEvent('mnc_forkliftfix:syncStackAttachment', -1, baseNet, topNet, offset, rotation)
end)

RegisterNetEvent('mnc_forkliftfix:detachStack')
AddEventHandler('mnc_forkliftfix:detachStack', function(baseNet)
    if vehicleStacks[baseNet] then
        local topNet = vehicleStacks[baseNet].topNetId
        vehicleStacks[baseNet] = nil
        TriggerClientEvent('mnc_forkliftfix:syncStackDetach', -1, baseNet, topNet)
    end
end)

-- Sync on player join
AddEventHandler('playerJoining', function()
    local src = source
    for baseNet, data in pairs(vehicleStacks) do
        TriggerClientEvent('mnc_forkliftfix:syncStackAttachment', src, baseNet, data.topNetId, data.offset, data.rotation)
    end
    for forkliftNet, data in pairs(attachedVehicles) do
        TriggerClientEvent('mnc_forkliftfix:syncAttachment', src, forkliftNet, data.vehicleNet, data.offset, data.rotation, data.entityType)
    end
    for vehicleNet, data in pairs(forkliftAnchors) do
        TriggerClientEvent('mnc_forkliftfix:syncForkliftAttachment', src, vehicleNet, data.forkliftNet, data.offset, data.rotation)
        -- Note: syncForkliftDetach is only sent on actual detach, not on join
    end
end)