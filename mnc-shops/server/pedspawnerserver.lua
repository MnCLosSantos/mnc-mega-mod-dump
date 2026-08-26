-- pedspawnerserver.lua
-- Table to track spawned peds per shop zone
local spawnedPeds = {}

-- Function to cleanup all existing shop peds
local function CleanupAllShopPeds()
    local allPeds = GetAllPeds()
    
    for zoneIndex, zone in ipairs(Config.Zones) do
        if zone.ped and zone.ped.model and zone.ped.coords then
            local pedCoords = vector3(zone.ped.coords.x, zone.ped.coords.y, zone.ped.coords.z)
            
            -- Clean up peds near spawn point
            for _, ped in ipairs(allPeds) do
                if DoesEntityExist(ped) then
                    local pedEntityCoords = GetEntityCoords(ped)
                    local distance = #(pedEntityCoords - pedCoords)
                    if distance < 5.0 then
                        local model = GetEntityModel(ped)
                        local expectedModel = GetHashKey(zone.ped.model)
                        if model == expectedModel then
                            DeleteEntity(ped)
                            if Config.Debug then
                                print(string.format("Cleaned up orphaned ped for zone %d: %s", zoneIndex, zone.name))
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Function to spawn ped for a shop zone
local function SpawnShopPed(zoneIndex)
    local zone = Config.Zones[zoneIndex]
    if not zone or not zone.ped or not zone.ped.model or not zone.ped.coords then
        if Config.Debug then
            print(string.format("Error: Invalid zone configuration for zoneIndex %d: %s", zoneIndex, json.encode(zone or {})))
        end
        return
    end

    if spawnedPeds[zoneIndex] then
        if Config.Debug then
            print(string.format("Warning: Ped already spawned for zoneIndex %d", zoneIndex))
        end
        return
    end

    local pedHash = GetHashKey(zone.ped.model)
    local pedCoords = zone.ped.coords -- Now a vector4
    local ped = CreatePed(4, pedHash, pedCoords.x, pedCoords.y, pedCoords.z, pedCoords.w, true, true)
    local pedNetId = NetworkGetNetworkIdFromEntity(ped)

    if pedNetId == 0 then
        if Config.Debug then
            print(string.format("Error: Failed to spawn ped for zoneIndex %d, model: %s", zoneIndex, zone.ped.model))
        end
        return
    end

    spawnedPeds[zoneIndex] = {
        pedNetId = pedNetId,
        lastSpawnTime = GetGameTimer()
    }

    if Config.Debug then
        print(string.format("Spawned ped for zoneIndex %d: pedNetId=%d, zone: %s", zoneIndex, pedNetId, zone.name))
    end

    TriggerClientEvent('mnc-shops:client:configureShopPed', -1, pedNetId, zoneIndex)
end

-- Function to cleanup peds for a specific zone
local function CleanupShopPed(zoneIndex)
    if not spawnedPeds[zoneIndex] then return end

    local zone = Config.Zones[zoneIndex]
    local pedCoords = vector3(zone.ped.coords.x, zone.ped.coords.y, zone.ped.coords.z)

    local allPeds = GetAllPeds()
    for _, ped in ipairs(allPeds) do
        if DoesEntityExist(ped) then
            local pedCoordsCurrent = GetEntityCoords(ped)
            local distance = #(pedCoordsCurrent - pedCoords)
            if distance < 5.0 and GetEntityModel(ped) == GetHashKey(zone.ped.model) then
                DeleteEntity(ped)
            end
        end
    end

    spawnedPeds[zoneIndex] = nil
    TriggerClientEvent('mnc-shops:client:cleanupShopPed', -1, zoneIndex)
end

-- Function to check for players and ensure peds
local function CheckPlayerProximityAndConfigure()
    for zoneIndex, entities in pairs(spawnedPeds) do
        local zone = Config.Zones[zoneIndex]
        if zone and zone.ped and zone.ped.coords then
            local pedCoords = vector3(zone.ped.coords.x, zone.ped.coords.y, zone.ped.coords.z)
            local pedFound = false
            local allPeds = GetAllPeds()
            for _, ped in ipairs(allPeds) do
                if DoesEntityExist(ped) then
                    local pedCoordsCurrent = GetEntityCoords(ped)
                    local distance = #(pedCoordsCurrent - pedCoords)
                    if distance < 5.0 and GetEntityModel(ped) == GetHashKey(zone.ped.model) then
                        pedFound = true
                        break
                    end
                end
            end

            if pedFound then
                local players = GetPlayers()
                for _, playerId in ipairs(players) do
                    local playerPed = GetPlayerPed(playerId)
                    local playerCoords = GetEntityCoords(playerPed)
                    local distance = #(playerCoords - pedCoords)
                    if distance < 50.0 then
                        TriggerClientEvent('mnc-shops:client:configureShopPed', playerId, entities.pedNetId, zoneIndex)
                        if Config.Debug then
                            print(string.format("Triggered animation configuration for player %s near zone %d: %s", playerId, zoneIndex, zone.name))
                        end
                    end
                end
            else
                if GetGameTimer() - (entities.lastSpawnTime or 0) > 30000 then
                    if Config.Debug then
                        print(string.format("Ped missing for zone %d, respawning ped", zoneIndex))
                    end
                    CleanupShopPed(zoneIndex)
                    SpawnShopPed(zoneIndex)
                end
            end
        end
    end
end

-- Spawn peds for all shop zones on resource start
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        if Config.Debug then
            print("Starting mnc-shops resource for ped spawner...")
        end

        if Config.Debug then
            print("Cleaning up any existing shop peds...")
        end
        CleanupAllShopPeds()

        Wait(1000)

        if Config.Debug then
            print("Spawning new peds...")
        end
        for zoneIndex, zone in ipairs(Config.Zones) do
            if zone.ped and zone.ped.model and zone.ped.coords then
                if Config.Debug then
                    print(string.format("Attempting to spawn ped for zoneIndex %d: %s", zoneIndex, zone.name))
                end
                SpawnShopPed(zoneIndex)
                Wait(500)
            end
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
            print("Stopping mnc-shops ped spawner, cleaning up peds...")
        end
        for zoneIndex, _ in pairs(spawnedPeds) do
            CleanupShopPed(zoneIndex)
        end
    end
end)