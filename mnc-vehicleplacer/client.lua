RegisterNetEvent('mnc-vehicleplacer:client:configureVehicle', function(vehicleNetId, raceIndex)
    local race = Config.Placements[raceIndex]
    if not race then
        if Config.Debug then
            print(string.format("Error: No placement config for raceIndex %d", raceIndex))
        end
        return
    end

    local timeout = GetGameTimer() + 15000 -- Extended to 15 seconds for better sync
    local vehicle

    -- Wait for vehicle to exist and be synchronized
    while GetGameTimer() < timeout do
        if NetworkDoesNetworkIdExist(vehicleNetId) then
            vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
            if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
                break
            end
        end
        Wait(100)
    end

    if vehicle and DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        FreezeEntityPosition(vehicle, true) -- Optional: Freeze vehicle to prevent movement
    end
end)

RegisterNetEvent('mnc-vehicleplacer:client:cleanupVehicle', function(raceIndex)
    local race = Config.Placements[raceIndex]
    if race then
    end
end)