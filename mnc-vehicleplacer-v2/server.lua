local QBCore = exports['qb-core']:GetCoreObject()
local spawnedVehicles   = {}
local dormantPlacements = {}  -- [key] = { name, model, spawnCoords }

local SPAWN_RADIUS    = Config.ProximitySpawnRadius   or 150.0

-- ─── DB helpers ───────────────────────────────────────────────

local function EnsureTable()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_vehicle_placements` (
            `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            `name`         VARCHAR(128) NOT NULL,
            `vehicleModel` VARCHAR(64)  NOT NULL,
            `x`            FLOAT        NOT NULL,
            `y`            FLOAT        NOT NULL,
            `z`            FLOAT        NOT NULL,
            `heading`      FLOAT        NOT NULL DEFAULT 0,
            `created_at`   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

local function LoadDBPlacements(cb)
    MySQL.query('SELECT * FROM `mnc_vehicle_placements`', {}, function(rows)
        cb(rows or {})
    end)
end

-- ─── Permission helper ────────────────────────────────────────

local function HasPermission(src)
    for _, g in ipairs(Config.AdminGroups) do
        if QBCore.Functions.HasPermission(src, g) then return true end
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local group = Player.PlayerData.permission or Player.PlayerData.group
        if group then
            for _, g in ipairs(Config.AdminGroups) do
                if group == g then return true end
            end
        end
    end
    if Config.Debug then
        local p = QBCore.Functions.GetPlayer(src)
        print(('[mnc-vehicleplacer] DENIED src=%s | permission=%s | group=%s'):format(
            src,
            tostring(p and p.PlayerData.permission),
            tostring(p and p.PlayerData.group)
        ))
    end
    return false
end


local function SpawnVehicle(key, name, model, spawnVec4)
    if spawnedVehicles[key] then return end

    local hash = GetHashKey(model)
    local attempts = 0
    local maxAttempts = 15

    while attempts < maxAttempts do
        attempts = attempts + 1

        -- Use CreateVehicleServerSetter - better for persistent vehicles
        local veh = CreateVehicleServerSetter(hash, "automobile", 
            spawnVec4.x, spawnVec4.y, spawnVec4.z, spawnVec4.w)

        if not veh or veh == 0 then
            if Config.Debug then
                print(('[mnc-vehicleplacer] CreateVehicleServerSetter failed (attempt %d/%d) key=%s model=%s'):format(attempts, maxAttempts, key, model))
            end
            Wait(200)
            goto continue
        end

        -- Give addon vehicles more time to fully load
        Wait(200 + (attempts * 150))

        if DoesEntityExist(veh) then
            dormantPlacements[key] = nil

            -- Final setup
            FreezeEntityPosition(veh, true)

            spawnedVehicles[key] = {
                vehicleEntity     = veh,
                lastSpawnTime     = GetGameTimer(),
                lastPlayerNearby  = GetGameTimer(),   -- ← ADD THIS LINE
                name              = name,
                model             = model,
                spawnCoords       = spawnVec4,
                adminMoving       = false,
            }

            if Config.Debug then
                print(('[mnc-vehicleplacer] ✅ Successfully spawned key=%s entity=%d model=%s (attempt %d)'):format(key, veh, model, attempts))
            end
            return
        else
            if Config.Debug then
                print(('[mnc-vehicleplacer] ❌ Entity failed (attempt %d/%d) key=%s model=%s entity=%d'):format(attempts, maxAttempts, key, model, veh))
            end
            if DoesEntityExist(veh) then
                DeleteEntity(veh)
            end
        end

        ::continue::
    end

    -- All attempts failed
    if Config.Debug then
        print(('[mnc-vehicleplacer] ❌ All spawn attempts failed key=%s model=%s'):format(key, model))
    end
    dormantPlacements[key] = { name = name, model = model, spawnCoords = spawnVec4 }
end

-- Delete entity but keep placement in dormant for later re-spawn.
local function DespawnVehicle(key)
    local data = spawnedVehicles[key]
    if not data then return end

    if data.vehicleEntity and DoesEntityExist(data.vehicleEntity) then
        DeleteEntity(data.vehicleEntity)
    end

    dormantPlacements[key] = {
        name        = data.name,
        model       = data.model,
        spawnCoords = data.spawnCoords,
    }
    spawnedVehicles[key] = nil
    TriggerClientEvent('mnc-vehicleplacer:client:cleanupVehicle', -1, key)

    if Config.Debug then
        print(('[mnc-vehicleplacer] Despawned → dormant key=%s'):format(key))
    end
end

-- Full removal — no dormant registration (delete / edit / resource stop).
local function CleanupVehicle(key)
    local data = spawnedVehicles[key]
    if not data then
        dormantPlacements[key] = nil
        return
    end

    if data.vehicleEntity and DoesEntityExist(data.vehicleEntity) then
        DeleteEntity(data.vehicleEntity)
    end

    spawnedVehicles[key]   = nil
    dormantPlacements[key] = nil
    TriggerClientEvent('mnc-vehicleplacer:client:cleanupVehicle', -1, key)
end

-- ─── Proximity System (Spawn + Despawn) ───────────────────────

local function RunProximityCheck()
    local players = GetPlayers()
    local playerPositions = {}
    
    -- Cache player positions
    for _, pid in ipairs(players) do
        local ped = GetPlayerPed(pid)
        if DoesEntityExist(ped) then
            table.insert(playerPositions, GetEntityCoords(ped))
        end
    end

    local now = GetGameTimer()

    -- 1. Spawn dormant vehicles when player gets close
    for key, info in pairs(dormantPlacements) do
        if not spawnedVehicles[key] then
            local sc = vector3(info.spawnCoords.x, info.spawnCoords.y, info.spawnCoords.z)
            for _, pos in ipairs(playerPositions) do
                if #(pos - sc) < Config.ProximitySpawnRadius then
                    if Config.Debug then
                        print(('[mnc-vehicleplacer] Activating dormant key=%s'):format(key))
                    end
                    SpawnVehicle(key, info.name, info.model, info.spawnCoords)
                    break
                end
            end
        end
    end

    -- 2. Despawn vehicles when no players are nearby
    for key, data in pairs(spawnedVehicles) do
        if not data.adminMoving then  -- Don't despawn while admin is moving it
            local sc = vector3(data.spawnCoords.x, data.spawnCoords.y, data.spawnCoords.z)
            local nearbyPlayer = false

            for _, pos in ipairs(playerPositions) do
                if #(pos - sc) < Config.ProximityDespawnRadius then
                    nearbyPlayer = true
                    break
                end
            end

            if not nearbyPlayer then
                -- Only despawn after being alone for ~15 seconds (prevents flickering)
                if not data.lastPlayerNearby or (now - data.lastPlayerNearby > 15000) then
                    if Config.Debug then
                        print(('[mnc-vehicleplacer] Despawning inactive key=%s'):format(key))
                    end
                    DespawnVehicle(key)
                end
            else
                data.lastPlayerNearby = now
            end
        end
    end
end

-- ─── Resource start / stop ────────────────────────────────────

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if Config.Debug then print('[mnc-vehicleplacer] Starting...') end

    EnsureTable()
    Wait(10000)

    for i, p in ipairs(Config.Placements) do
        if p.vehicleSpawn and p.vehicleModel then
            dormantPlacements['static_' .. i] = {
                name        = p.name,
                model       = p.vehicleModel,
                spawnCoords = p.vehicleSpawn,
            }
        end
    end

    LoadDBPlacements(function(rows)
        for _, row in ipairs(rows) do
            dormantPlacements['db_' .. row.id] = {
                name        = row.name,
                model       = row.vehicleModel,
                spawnCoords = vector4(row.x, row.y, row.z, row.heading),
            }
        end

        CreateThread(function()
            while true do
                RunProximityCheck()
                Wait(Config.ProximityCheckInterval or 10000)
            end
        end)
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if Config.Debug then print('[mnc-vehicleplacer] Stopping, cleaning up...') end
    for key in pairs(spawnedVehicles) do
        CleanupVehicle(key)
    end
end)

-- ─── NUI / net events ─────────────────────────────────────────

RegisterNetEvent('mnc-vehicleplacer:server:openUI', function()
    local src = source
    if not HasPermission(src) then
        TriggerClientEvent('mnc-vehicleplacer:client:notify', src, 'No permission.', 'error')
        return
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local placements   = {}

    local function buildRow(key, isStatic, id, name, model, x, y, z, heading)
        local dist = #(playerCoords - vector3(x, y, z))
        placements[#placements + 1] = {
            key          = key,
            id           = id,
            isStatic     = isStatic,
            name         = name,
            vehicleModel = model,
            x            = x, y = y, z = z,
            heading      = heading,
            spawned      = spawnedVehicles[key] ~= nil,
            dormant      = dormantPlacements[key] ~= nil,
            distance     = math.floor(dist),
        }
    end

    for i, p in ipairs(Config.Placements) do
        local sv = p.vehicleSpawn
        buildRow('static_'..i, true, i, p.name, p.vehicleModel,
            sv and sv.x or 0, sv and sv.y or 0, sv and sv.z or 0, sv and sv.w or 0)
    end

    LoadDBPlacements(function(rows)
        for _, row in ipairs(rows) do
            buildRow('db_'..row.id, false, row.id, row.name, row.vehicleModel,
                row.x, row.y, row.z, row.heading)
        end
        table.sort(placements, function(a, b) return a.distance < b.distance end)
        TriggerClientEvent('mnc-vehicleplacer:client:openUI', src, placements)
    end)
end)

RegisterNetEvent('mnc-vehicleplacer:server:addPlacement', function(data)
    local src = source
    if not HasPermission(src) then return end
    if not data or not data.name or not data.vehicleModel or
       not data.x or not data.y or not data.z then
        TriggerClientEvent('mnc-vehicleplacer:client:notify', src, 'Invalid placement data.', 'error')
        return
    end
    local heading = tonumber(data.heading) or 0.0
    MySQL.insert(
        'INSERT INTO `mnc_vehicle_placements` (name, vehicleModel, x, y, z, heading) VALUES (?, ?, ?, ?, ?, ?)',
        { data.name, data.vehicleModel, data.x, data.y, data.z, heading },
        function(id)
            if not id then
                TriggerClientEvent('mnc-vehicleplacer:client:notify', src, 'DB insert failed.', 'error')
                return
            end
            local key = 'db_' .. id
            dormantPlacements[key] = {
                name        = data.name,
                model       = data.vehicleModel,
                spawnCoords = vector4(data.x, data.y, data.z, heading),
            }
            TriggerClientEvent('mnc-vehicleplacer:client:notify', src, 'Vehicle placement added!', 'success')
            TriggerClientEvent('mnc-vehicleplacer:client:placementSaved', src, id)
        end
    )
end)

RegisterNetEvent('mnc-vehicleplacer:server:editPlacement', function(data)
    local src = source
    if not HasPermission(src) then return end
    if not data or not data.id then
        TriggerClientEvent('mnc-vehicleplacer:client:notify', src, 'Invalid edit data.', 'error')
        return
    end
    local heading = tonumber(data.heading) or 0.0
    MySQL.update(
        'UPDATE `mnc_vehicle_placements` SET name=?, vehicleModel=?, x=?, y=?, z=?, heading=? WHERE id=?',
        { data.name, data.vehicleModel, data.x, data.y, data.z, heading, data.id },
        function(rows)
            if rows == 0 then
                TriggerClientEvent('mnc-vehicleplacer:client:notify', src, 'Update failed.', 'error')
                return
            end
            local key = 'db_' .. data.id
            CleanupVehicle(key)
            Wait(300)
            dormantPlacements[key] = {
                name        = data.name,
                model       = data.vehicleModel,
                spawnCoords = vector4(data.x, data.y, data.z, heading),
            }
            TriggerClientEvent('mnc-vehicleplacer:client:notify', src, 'Placement updated!', 'success')
            TriggerClientEvent('mnc-vehicleplacer:client:placementSaved', src, data.id)
        end
    )
end)

RegisterNetEvent('mnc-vehicleplacer:server:deletePlacement', function(id)
    local src = source
    if not HasPermission(src) then return end
    id = tonumber(id)
    if not id then return end
    MySQL.update('DELETE FROM `mnc_vehicle_placements` WHERE id=?', { id }, function()
        CleanupVehicle('db_' .. id)
        TriggerClientEvent('mnc-vehicleplacer:client:notify', src, 'Placement deleted.', 'success')
    end)
end)

RegisterNetEvent('mnc-vehicleplacer:server:teleportTo', function(x, y, z)
    local src = source
    if not HasPermission(src) then return end
    TriggerClientEvent('mnc-vehicleplacer:client:teleportTo', src, x, y, z)
end)

RegisterNetEvent('mnc-vehicleplacer:server:getVehicleNetId', function(key)
    local src = source
    if not HasPermission(src) then return end

    if dormantPlacements[key] and not spawnedVehicles[key] then
        local info = dormantPlacements[key]
        SpawnVehicle(key, info.name, info.model, info.spawnCoords)
        Wait(500)
    end

    local data = spawnedVehicles[key]
    if not data or not data.vehicleEntity or not DoesEntityExist(data.vehicleEntity) then
        TriggerClientEvent('mnc-vehicleplacer:client:notify', src, 'Vehicle not spawned.', 'error')
        return
    end

    -- Unfreeze vehicle for admin editing
    FreezeEntityPosition(data.vehicleEntity, false)
    data.adminMoving = true
    
    -- Get network id for the client to interact with
    local netId = NetworkGetNetworkIdFromEntity(data.vehicleEntity)
    TriggerClientEvent('mnc-vehicleplacer:client:startPlacementMode', src, key, netId)
end)

RegisterNetEvent('mnc-vehicleplacer:server:updatePlacementPosition', function(key, x, y, z, heading)
    local src = source
    if not HasPermission(src) then return end

    local data = spawnedVehicles[key]
    if data then
        data.spawnCoords = vector4(x, y, z, heading)
        data.adminMoving = false
        
        -- Move the actual entity
        if data.vehicleEntity and DoesEntityExist(data.vehicleEntity) then
            SetEntityCoords(data.vehicleEntity, x, y, z, false, false, false, false)
            SetEntityHeading(data.vehicleEntity, heading)
            FreezeEntityPosition(data.vehicleEntity, true)
        end
    end

    local id = key:match('^db_(%d+)$')
    if id then
        id = tonumber(id)
        MySQL.update(
            'UPDATE `mnc_vehicle_placements` SET x=?, y=?, z=?, heading=? WHERE id=?',
            { x, y, z, heading, id },
            function(rows)
                if rows and rows > 0 then
                    TriggerClientEvent('mnc-vehicleplacer:client:notify', src, 'Position saved!', 'success')
                end
            end
        )
    else
        TriggerClientEvent('mnc-vehicleplacer:client:notify', src,
            'Position updated (runtime only — update config.lua to make permanent).', 'inform')
    end

    TriggerClientEvent('mnc-vehicleplacer:client:placementPositionUpdated', src, key, x, y, z, heading)

    if Config.Debug then
        print(('[mnc-vehicleplacer] Position updated key=%s %.2f %.2f %.2f h=%.2f'):format(key, x, y, z, heading))
    end
end)

print('^2[mnc-vehicleplacer]^7 Script loaded successfully!')