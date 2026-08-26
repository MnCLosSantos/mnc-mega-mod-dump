-- Table to track spawned vehicles per race
local spawnedVehicles = {}

-- Function to clean up all existing vehicles
local function CleanupAllVehicles()
    local allVehicles = GetAllVehicles()
    
    for raceIndex, race in ipairs(Config.Placements) do
        if race.vehicleSpawn and race.vehicleModel then
            local spawnCoords = vector3(race.vehicleSpawn.x, race.vehicleSpawn.y, race.vehicleSpawn.z)
            
            for _, vehicle in ipairs(allVehicles) do
                if DoesEntityExist(vehicle) then
                    local vehicleCoords = GetEntityCoords(vehicle)
                    local distance = #(vehicleCoords - spawnCoords)
                    if distance < 5.0 then
                        local model = GetEntityModel(vehicle)
                        local expectedModel = GetHashKey(race.vehicleModel)
                        if model == expectedModel then
                            DeleteEntity(vehicle)
                            if Config.Debug then
                                print(string.format("Cleaned up orphaned vehicle for race %d: %s", raceIndex, race.name))
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Function to spawn vehicle for a race
local function SpawnRaceVehicle(raceIndex)
    local race = Config.Placements[raceIndex] -- Fixed: Changed 'местное' to 'local'
    if not race or not race.vehicleSpawn or not race.vehicleModel then
        if Config.Debug then
            print(string.format("Error: Invalid race configuration for raceIndex %d: %s", raceIndex, json.encode(race or {})))
        end
        return
    end

    if spawnedVehicles[raceIndex] then
        if Config.Debug then
            print(string.format("Warning: Vehicle already spawned for raceIndex %d", raceIndex))
        end
        return
    end

    local vehicleHash = GetHashKey(race.vehicleModel)
    local spawnCoords = race.vehicleSpawn -- Expected as vector4(x, y, z, w)
    local vehicleNetId = CreateVehicleServerSetter(vehicleHash, 'automobile', spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w)
    
    if vehicleNetId == 0 then
        if Config.Debug then
            print(string.format("Error: Failed to spawn vehicle for raceIndex %d, model: %s", raceIndex, race.vehicleModel))
        end
        return
    end

    -- Store vehicle data
    spawnedVehicles[raceIndex] = {
        vehicleNetId = vehicleNetId,
        lastSpawnTime = GetGameTimer()
    }

    if Config.Debug then
        print(string.format("Spawned vehicle for raceIndex %d: vehicleNetId=%d, race: %s", raceIndex, vehicleNetId, race.name))
    end

    -- Trigger client-side configuration
    TriggerClientEvent('mnc-vehicleplacer:client:configureVehicle', -1, vehicleNetId, raceIndex)
end

-- Function to clean up vehicle for a specific race
local function CleanupRaceVehicle(raceIndex)
    if not spawnedVehicles[raceIndex] then return end

    local race = Config.Placements[raceIndex]
    local spawnCoords = vector3(race.vehicleSpawn.x, race.vehicleSpawn.y, race.vehicleSpawn.z)

    local allVehicles = GetAllVehicles()
    for _, vehicle in ipairs(allVehicles) do
        if DoesEntityExist(vehicle) then
            local vehicleCoords = GetEntityCoords(vehicle)
            local distance = #(vehicleCoords - spawnCoords)
            if distance < 5.0 and GetEntityModel(vehicle) == GetHashKey(race.vehicleModel) then
                DeleteEntity(vehicle)
                if Config.Debug then
                    print(string.format("Cleaned up vehicle for raceIndex %d", raceIndex))
                end
            end
        end
    end

    spawnedVehicles[raceIndex] = nil
    TriggerClientEvent('mnc-vehicleplacer:client:cleanupVehicle', -1, raceIndex)
end

-- Function to check for players and ensure vehicles
local function CheckPlayerProximityAndConfigure()
    for raceIndex, vehicleData in pairs(spawnedVehicles) do
        local race = Config.Placements[raceIndex]
        if race and race.vehicleSpawn then
            local spawnCoords = vector3(race.vehicleSpawn.x, race.vehicleSpawn.y, race.vehicleSpawn.z)
            local vehicleFound = false
            local allVehicles = GetAllVehicles()
            for _, vehicle in ipairs(allVehicles) do
                if DoesEntityExist(vehicle) then
                    local vehicleCoords = GetEntityCoords(vehicle)
                    local distance = #(vehicleCoords - spawnCoords)
                    if distance < 5.0 and GetEntityModel(vehicle) == GetHashKey(race.vehicleModel) then
                        vehicleFound = true
                        break
                    end
                end
            end

            if not vehicleFound and GetGameTimer() - (vehicleData.lastSpawnTime or 0) > 30000 then
                if Config.Debug then
                    print(string.format("Vehicle missing for race %d, respawning vehicle", raceIndex))
                end
                CleanupRaceVehicle(raceIndex)
                SpawnRaceVehicle(raceIndex)
            else
                local players = GetPlayers()
                for _, playerId in ipairs(players) do
                    local playerPed = GetPlayerPed(playerId)
                    local playerCoords = GetEntityCoords(playerPed)
                    local distance = #(playerCoords - spawnCoords)
                    if distance < 50.0 then
                        local vehicle = NetworkGetEntityFromNetworkId(vehicleData.vehicleNetId)
                        if vehicle and DoesEntityExist(vehicle) then
                            TriggerClientEvent('mnc-vehicleplacer:client:configureVehicle', playerId, vehicleData.vehicleNetId, raceIndex)
                            if Config.Debug then
                                print(string.format("Triggered vehicle configuration for player %s near race %d: %s", playerId, raceIndex, race.name))
                            end
                        else
                            if Config.Debug then
                                print(string.format("Vehicle not found for player %s near race %d: %s, vehicleNetId: %d", playerId, raceIndex, race.name, vehicleData.vehicleNetId))
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Spawn vehicles for all races on resource start
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        if Config.Debug then
            print("Starting mnc-vehicleplacer resource...")
        end
        
        if Config.Debug then
            print("Cleaning up any existing vehicles...")
        end
        CleanupAllVehicles()
        
        Wait(1000)
        
        if Config.Debug then
            print("Spawning vehicles...")
        end
        for raceIndex, race in ipairs(Config.Placements) do
            if Config.Debug then
                print(string.format("Attempting to spawn vehicle for raceIndex %d: %s", raceIndex, race.name))
            end
            SpawnRaceVehicle(raceIndex)
            Wait(500)
        end

        CreateThread(function()
            while true do
                CheckPlayerProximityAndConfigure()
                Wait(60000)
            end
        end)
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if Config.Debug then
            print("Stopping mnc-vehicleplacer resource, cleaning up vehicles...")
        end
        for raceIndex, _ in pairs(spawnedVehicles) do
            CleanupRaceVehicle(raceIndex)
        end
    end
end)

print("^2[mnc-vehicleplacer]^7 Script loaded successfully!")