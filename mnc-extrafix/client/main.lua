local trackedHashes = {}
for _, name in ipairs(Config.TrackedModels) do
    trackedHashes[GetHashKey(name)] = true
end

local extraSignatures = {} -- [netId] = last known extra signature string
local lastFixAt = {}       -- [netId] = GetGameTimer() of last fix

-- Builds a simple signature string of every extra's on/off state so we can
-- detect ANY change without relying on bitwise ops (keeps this portable).
local function GetExtraSignature(veh)
    local sig = {}
    for i = 0, Config.MaxExtraIndex do
        if DoesExtraExist(veh, i) then
            sig[#sig + 1] = IsVehicleExtraTurnedOn(veh, i) and "1" or "0"
        else
            sig[#sig + 1] = "x"
        end
    end
    return table.concat(sig)
end

local function FixVehicle(veh)
    if not DoesEntityExist(veh) then return end

    -- Full fix
    SetVehicleFixed(veh)
    SetVehicleDeformationFixed(veh)
    SetVehicleUndriveable(veh, false)

    -- Full repair
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehiclePetrolTankHealth(veh, 1000.0)
    SetVehicleDirtLevel(veh, 0.0)


end

-- Main polling loop: scans the local vehicle pool for tracked models and
-- detects extra-state changes. This runs independently on every client, so
-- everyone's local render of the trailer gets corrected, not just the one
-- player who toggled the extra.
CreateThread(function()
    while true do
        Wait(Config.PollInterval)

        local pool = GetGamePool('CVehicle')
        for _, veh in ipairs(pool) do
            if DoesEntityExist(veh) then
                local model = GetEntityModel(veh)

                if trackedHashes[model] then
                    local netId = NetworkGetNetworkIdFromEntity(veh)
                    local sig = GetExtraSignature(veh)
                    local prevSig = extraSignatures[netId]

                    if prevSig ~= nil and prevSig ~= sig then
                        local now = GetGameTimer()
                        local last = lastFixAt[netId]

                        if not last or (now - last) > Config.FixCooldown then
                            lastFixAt[netId] = now
                            FixVehicle(veh)

                            -- Let the server know so it can tell every other
                            -- client to fix their own local copy too.
                            TriggerServerEvent('mnc-extrafix:server:notifyFix', netId)
                        end
                    end

                    extraSignatures[netId] = sig
                end
            end
        end
    end
end)

-- Fired by the server when ANY player (including us) detects an extra change
-- on a tracked vehicle. We only act if that vehicle is currently streamed in
-- for us.
RegisterNetEvent('mnc-extrafix:client:applyFix', function(netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh and veh ~= 0 and DoesEntityExist(veh) then
        FixVehicle(veh)
    end
end)

-- Manual fix command, mostly useful for testing.
-- Fixes the closest tracked vehicle within 10m.
RegisterCommand('extrafix', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local pool = GetGamePool('CVehicle')

    local closest, closestDist = nil, 10.0
    for _, veh in ipairs(pool) do
        local model = GetEntityModel(veh)
        if trackedHashes[model] then
            local dist = #(coords - GetEntityCoords(veh))
            if dist < closestDist then
                closest, closestDist = veh, dist
            end
        end
    end

    if closest then
        FixVehicle(closest)
        TriggerServerEvent('mnc-extrafix:server:notifyFix', NetworkGetNetworkIdFromEntity(closest))
    end
end, false)
