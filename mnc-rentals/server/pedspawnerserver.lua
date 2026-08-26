-- server/pedspawner.lua
local spawnedRentalPeds = {} -- Tracks spawned rental clerk peds per zone

-- Cleanup any orphaned rental peds on resource start
local function CleanupAllRentalPeds()
    local allPeds = GetAllPeds()

    for zoneId, zone in pairs(Config.Zones) do
        if zone.ped and zone.ped.model and zone.ped.coords then
            local pedCoords = vector3(zone.ped.coords.x, zone.ped.coords.y, zone.ped.coords.z)

            for _, ped in ipairs(allPeds) do
                if DoesEntityExist(ped) then
                    local pedPos = GetEntityCoords(ped)
                    local dist = #(pedPos - pedCoords)
                    if dist < 5.0 then
                        local model = GetEntityModel(ped)
                        if model == GetHashKey(zone.ped.model) then
                            DeleteEntity(ped)
                            if Config.Debug then
                                print(string.format("[mnc-rentals] Cleaned up orphaned rental ped for zone %d: %s", zoneId, zone.name))
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Spawn rental ped for a specific zone
local function SpawnRentalPed(zoneId)
    local zone = Config.Zones[zoneId]
    if not zone or not zone.ped or not zone.ped.model or not zone.ped.coords then
        if Config.Debug then
            print(string.format("[mnc-rentals] Invalid ped config for zoneId %d", zoneId))
        end
        return
    end

    if spawnedRentalPeds[zoneId] then
        return -- Already spawned
    end

    local modelHash = GetHashKey(zone.ped.model)
    local coords = zone.ped.coords -- Must be vector4(x, y, z, heading)

    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z, coords.w, true, true)
    while not DoesEntityExist(ped) do Wait(10) end

    local netId = NetworkGetNetworkIdFromEntity(ped)
    if netId == 0 then
        if Config.Debug then
            print(string.format("[mnc-rentals] Failed to get netId for rental ped in zone %d", zoneId))
        end
        return
    end

    spawnedRentalPeds[zoneId] = {
        pedNetId = netId,
        lastSpawnTime = GetGameTimer()
    }

    if Config.Debug then
        print(string.format("[mnc-rentals] Spawned rental ped for zone %d (%s) | NetId: %d", zoneId, zone.name, netId))
    end

    TriggerClientEvent('mnc-rentals:client:configureRentalPed', -1, netId, zoneId)
end

-- Cleanup ped for a specific zone
local function CleanupRentalPed(zoneId)
    if not spawnedRentalPeds[zoneId] then return end

    local zone = Config.Zones[zoneId]
    local pedCoords = vector3(zone.ped.coords.x, zone.ped.coords.y, zone.ped.coords.z)

    local allPeds = GetAllPeds()
    for _, ped in ipairs(allPeds) do
        if DoesEntityExist(ped) then
            local pos = GetEntityCoords(ped)
            if #(pos - pedCoords) < 5.0 and GetEntityModel(ped) == GetHashKey(zone.ped.model) then
                DeleteEntity(ped)
            end
        end
    end

    spawnedRentalPeds[zoneId] = nil
    TriggerClientEvent('mnc-rentals:client:cleanupRentalPed', -1, zoneId)
end

-- Periodic check: respawn missing peds and re-trigger animation for nearby players
CreateThread(function()
    while true do
        Wait(60000) -- Every minute

        for zoneId, data in pairs(spawnedRentalPeds) do
            local zone = Config.Zones[zoneId]
            if zone and zone.ped and zone.ped.coords then
                local pedCoords = vector3(zone.ped.coords.x, zone.ped.coords.y, zone.ped.coords.z)
                local pedExists = false

                for _, ped in ipairs(GetAllPeds()) do
                    if DoesEntityExist(ped) then
                        local pos = GetEntityCoords(ped)
                        if #(pos - pedCoords) < 5.0 and GetEntityModel(ped) == GetHashKey(zone.ped.model) then
                            pedExists = true
                            break
                        end
                    end
                end

                if not pedExists then
                    if GetGameTimer() - data.lastSpawnTime > 30000 then
                        if Config.Debug then
                            print(string.format("[mnc-rentals] Rental ped missing in zone %d (%s), respawning...", zoneId, zone.name))
                        end
                        CleanupRentalPed(zoneId)
                        Wait(500)
                        SpawnRentalPed(zoneId)
                    end
                else
                    -- Re-trigger animation for nearby players
                    for _, playerId in ipairs(GetPlayers()) do
                        local playerPed = GetPlayerPed(playerId)
                        local playerPos = GetEntityCoords(playerPed)
                        if #(playerPos - pedCoords) < 50.0 then
                            TriggerClientEvent('mnc-rentals:client:configureRentalPed', playerId, data.pedNetId, zoneId)
                        end
                    end
                end
            end
        end
    end
end)

-- Resource start: cleanup old + spawn all rental peds
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    CleanupAllRentalPeds()
    Wait(1000)

    for zoneId, zone in pairs(Config.Zones) do
        if zone.ped and zone.ped.model and zone.ped.coords then
            SpawnRentalPed(zoneId)
            Wait(300)
        end
    end
end)

-- Resource stop: cleanup all rental peds
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for zoneId, _ in pairs(spawnedRentalPeds) do
        CleanupRentalPed(zoneId)
    end
end)