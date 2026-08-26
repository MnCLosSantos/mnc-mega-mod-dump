-- server.lua
local QBCore = exports['qb-core']:GetCoreObject()

local lockedPlates     = {}   -- [plate] = true
local parkedVehicles   = {}   -- [citizenid][plate] = entry
local allParkedByPlate = {}   -- [plate] = entry
local databaseReady    = false
local recalledPlates   = {}
local impoundedPlates  = {}
local spawnedNetIds    = {}   -- [plate] = netId  (reported by a client)
local propsApplied     = {}   -- [plate] = true   (props confirmed applied)
-- [plate] = true  — a spawn request is in-flight to a client; don't send another
local spawnInFlight    = {}

-- ============================================================
-- Discord VIP helpers
-- ============================================================

--- Returns the Discord snowflake ID for a player, or nil if not linked.
local function GetDiscordId(src)
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        local id = identifier:match('^discord:(.+)$')
        if id then return id end
    end
    return nil
end

--- Returns true if the player's Discord ID appears in Config.VipDiscordIds.
local function IsVipPlayer(src)
    if not Config.VipDiscordIds or #Config.VipDiscordIds == 0 then return false end
    local discordId = GetDiscordId(src)
    if not discordId then return false end
    for _, vid in ipairs(Config.VipDiscordIds) do
        if tostring(vid) == discordId then return true end
    end
    return false
end

local function GetMaxVehiclesOut(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        -- SQL-backed VIP table (managed by vip_server.lua)
        local sqlSlots = GetVipMaxSlots(Player.PlayerData.citizenid)
        if sqlSlots then return sqlSlots end
    end
    -- Legacy Discord-list VIP check (config.lua Config.VipDiscordIds)
    if IsVipPlayer(src) then
        return Config.VipMaxVehiclesOut or Config.MaxVehiclesOut
    end
    return Config.MaxVehiclesOut
end

-- ============================================================
-- Helpers
-- ============================================================
local function NormaliseCoords(c)
    if type(c) ~= 'table' then return nil end
    local x = tonumber(c.x) or tonumber(c[1])
    local y = tonumber(c.y) or tonumber(c[2])
    local z = tonumber(c.z) or tonumber(c[3])
    if not x or not y or not z then return nil end
    return { x = x, y = y, z = z }
end

local function NetIdIsAlive(netId)
    if not netId or netId == 0 then return false end
    local ent = NetworkGetEntityFromNetworkId(netId)
    return ent ~= 0 and DoesEntityExist(ent)
end

local function MapToList(t)
    local list = {}
    for _, v in pairs(t) do list[#list + 1] = v end
    return list
end

-- ============================================================
-- Find nearest online player to coords. Returns source or nil.
-- ============================================================
local function FindNearestPlayer(coords)
    local bestSrc, bestDist = nil, math.huge
    for _, src in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(tonumber(src))
        if ped and ped ~= 0 then
            local pos = GetEntityCoords(ped)
            local d   = #(vector3(pos.x, pos.y, pos.z) -
                          vector3(coords.x, coords.y, coords.z))
            if d < bestDist then bestDist = d; bestSrc = tonumber(src) end
        end
    end
    return bestSrc
end

-- ============================================================
-- Ask a client to spawn a vehicle for us and report the netId.
-- The client calls mnc-parking:vehicleSpawned when done.
-- Times out after 15 s and clears the in-flight flag for retry.
-- ============================================================
local function RequestClientSpawn(entry, preferredSrc)
    local plate = entry.plate
    if spawnedNetIds[plate] and NetIdIsAlive(spawnedNetIds[plate]) then
        return   -- already live
    end
    if spawnInFlight[plate] then return end   -- already asked someone

    local src = preferredSrc or FindNearestPlayer(entry.coords)
    if not src then
        if Config.Debug then
            print('^3[mnc-parking]^7 No players online to spawn plate=' .. plate)
        end
        return
    end

    spawnInFlight[plate] = true
    if Config.Debug then
        print('^2[mnc-parking]^7 Asking src=' .. src .. ' to spawn plate=' .. plate)
    end
    TriggerClientEvent('mnc-parking:spawnVehicle', src, entry)

    -- Timeout: clear flag so next player join can retry
    CreateThread(function()
        Wait(15000)
        if not spawnedNetIds[plate] or not NetIdIsAlive(spawnedNetIds[plate]) then
            spawnInFlight[plate] = nil
            if Config.Debug then
                print('^3[mnc-parking]^7 Spawn timed out for plate=' .. plate)
            end
        end
    end)
end

-- ============================================================
-- Client reports back after spawning a vehicle.
-- payload = { plate, netId, propsAlreadyApplied }
-- ============================================================
RegisterNetEvent('mnc-parking:vehicleSpawned', function(plate, netId, propsAlreadyApplied)
    spawnInFlight[plate] = nil

    if not netId or netId == 0 then
        if Config.Debug then
            print('^1[mnc-parking]^7 vehicleSpawned: client reported failure for plate=' .. plate)
        end
        return
    end

    spawnedNetIds[plate] = netId
    if propsAlreadyApplied then
        propsApplied[plate] = true
    end

    if Config.Debug then
        print('^2[mnc-parking]^7 vehicleSpawned: plate=' .. plate .. ' netId=' .. netId ..
              ' propsApplied=' .. tostring(propsAlreadyApplied))
    end
end)

-- ============================================================
-- Client confirms props were applied (non-owner applicator path)
-- ============================================================
RegisterNetEvent('mnc-parking:propsApplied', function(plate)
    propsApplied[plate] = true
    if Config.Debug then
        print('^2[mnc-parking]^7 Props confirmed for plate=' .. plate)
    end
end)

-- ============================================================
-- Delete our tracked entity for a plate.
-- ============================================================
local function DeleteSpawnedVehicle(plate)
    local netId = spawnedNetIds[plate]
    if netId and NetIdIsAlive(netId) then
        local ent = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(ent) then DeleteEntity(ent) end
    end
    spawnedNetIds[plate]  = nil
    propsApplied[plate]   = nil
    spawnInFlight[plate]  = nil
end

-- ============================================================
-- DB init — load data. Spawning happens when players join,
-- because the model may be addon-only (client-side streams).
-- ============================================================
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
    Wait(2000)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_parking_locks` (
            `plate`        VARCHAR(20) NOT NULL,
            `citizenid`    VARCHAR(50) NOT NULL,
            `installed_at` TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_parked_vehicles` (
            `id`             INT          NOT NULL AUTO_INCREMENT,
            `citizenid`      VARCHAR(50)  NOT NULL,
            `plate`          VARCHAR(20)  NOT NULL,
            `model`          VARCHAR(50)  NOT NULL,
            `origin_garage`  VARCHAR(50)  NOT NULL DEFAULT 'pillboxgarage',
            `coords_x`       FLOAT        NOT NULL DEFAULT 0,
            `coords_y`       FLOAT        NOT NULL DEFAULT 0,
            `coords_z`       FLOAT        NOT NULL DEFAULT 0,
            `heading`        FLOAT        NOT NULL DEFAULT 0,
            `props`          LONGTEXT     DEFAULT NULL,
            `fuel`           FLOAT        DEFAULT 100,
            `engine`         FLOAT        DEFAULT 1000,
            `body`           FLOAT        DEFAULT 1000,
            `parked_at`      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
            `updated_at`     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_citizen_plate` (`citizenid`, `plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query([[
        ALTER TABLE `mnc_parked_vehicles`
        ADD COLUMN IF NOT EXISTS `origin_garage` VARCHAR(50) NOT NULL DEFAULT 'pillboxgarage'
    ]])

    local locks = MySQL.query.await('SELECT `plate` FROM `mnc_parking_locks`', {})
    if locks then
        for _, row in ipairs(locks) do lockedPlates[row.plate] = true end
        print('^2[mnc-parking]^7 Loaded ' .. #locks .. ' parking lock(s).')
    end

    local allRows = MySQL.query.await('SELECT * FROM `mnc_parked_vehicles`', {})
    if allRows and #allRows > 0 then
        for _, row in ipairs(allRows) do
            local entry = {
                plate         = row.plate,
                model         = row.model,
                citizenid     = row.citizenid,
                origin_garage = row.origin_garage or Config.RecallGarage,
                coords        = { x = row.coords_x, y = row.coords_y, z = row.coords_z },
                heading       = row.heading,
                props         = row.props   or '{}',
                fuel          = row.fuel    or 100.0,
                engine        = row.engine  or 1000.0,
                body          = row.body    or 1000.0,
            }
            allParkedByPlate[row.plate] = entry
            if not parkedVehicles[row.citizenid] then
                parkedVehicles[row.citizenid] = {}
            end
            parkedVehicles[row.citizenid][row.plate] = entry

            local garage = (row.origin_garage and row.origin_garage ~= '')
                           and row.origin_garage or Config.RecallGarage
            MySQL.update.await(
                'UPDATE `player_vehicles` SET `state` = 0, `garage` = ? WHERE `plate` = ?',
                { garage, row.plate })
        end
        print('^2[mnc-parking]^7 Loaded ' .. #allRows .. ' parked vehicle(s) from DB.')
    end

    databaseReady = true
    print('^2[mnc-parking]^7 Database ready.')
end)

local function WaitForDB()
    local waited = 0
    while not databaseReady and waited < 10000 do
        Wait(200); waited = waited + 200
    end
end

local function LoadPlayerVehicles(citizenid)
    local rows = MySQL.query.await(
        'SELECT * FROM `mnc_parked_vehicles` WHERE `citizenid` = ?', { citizenid })
    parkedVehicles[citizenid] = {}
    if rows then
        for _, row in ipairs(rows) do
            local entry = {
                plate         = row.plate,
                model         = row.model,
                citizenid     = citizenid,
                origin_garage = row.origin_garage or Config.RecallGarage,
                coords        = { x = row.coords_x, y = row.coords_y, z = row.coords_z },
                heading       = row.heading,
                props         = row.props   or '{}',
                fuel          = row.fuel    or 100.0,
                engine        = row.engine  or 1000.0,
                body          = row.body    or 1000.0,
            }
            parkedVehicles[citizenid][row.plate] = entry
            allParkedByPlate[row.plate]          = entry
        end
        if Config.Debug then
            print('^2[mnc-parking]^7 Loaded ' .. #rows .. ' vehicle(s) for ' .. citizenid)
        end
    end
    return parkedVehicles[citizenid]
end

local function MarkVehicleOut(plate)
    local row = MySQL.query.await(
        'SELECT `garage` FROM `player_vehicles` WHERE `plate` = ? LIMIT 1', { plate })
    local currentGarage = (row and row[1] and row[1].garage and row[1].garage ~= '')
                          and row[1].garage or Config.RecallGarage
    if currentGarage == Config.ImpoundGarage then currentGarage = Config.RecallGarage end
    MySQL.update(
        'UPDATE `player_vehicles` SET `state` = 0, `garage` = ? WHERE `plate` = ?',
        { currentGarage, plate })
    if Config.Debug then
        print('^2[mnc-parking]^7 Marked OUT plate=' .. plate .. ' garage=' .. currentGarage)
    end
    return currentGarage
end

local function RestoreToOriginGarage(plate, originGarage)
    local garage = (originGarage and originGarage ~= '') and originGarage or Config.RecallGarage
    MySQL.update(
        'UPDATE `player_vehicles` SET `state` = 1, `garage` = ? WHERE `plate` = ?',
        { garage, plate })
    if Config.Debug then
        print('^2[mnc-parking]^7 Restored plate=' .. plate .. ' → ' .. garage)
    end
end

-- ============================================================
-- Player loads in.
-- For each of their parked vehicles:
--   • If already spawned and alive → send existing netId.
--     If propsApplied → netId=-1 (no re-apply). Else → real netId (owner applies).
--   • If not spawned yet → ask THIS player's client to spawn it
--     (they own the model, guaranteed to have it streamed).
--     After spawn the client fires vehicleSpawned and we can
--     send loadParkedVehicles with the real netId.
--
-- For other players' vehicles (already in world):
--   • If not yet spawned → ask this player to spawn them too (they may have the model).
--   • If props not yet applied → ask this player to apply them.
-- ============================================================
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src       = Player.PlayerData.source
    local citizenid = Player.PlayerData.citizenid
    WaitForDB()

    LoadPlayerVehicles(citizenid)

    -- Re-enforce state=0 for own vehicles
    for plate, entry in pairs(parkedVehicles[citizenid] or {}) do
        local garage = (entry.origin_garage and entry.origin_garage ~= '')
                       and entry.origin_garage or Config.RecallGarage
        MySQL.update.await(
            'UPDATE `player_vehicles` SET `state` = 0, `garage` = ? WHERE `plate` = ?',
            { garage, plate })

        -- Give keys immediately
        local ok = pcall(function() exports['qb-vehiclekeys']:GiveKeys(src, plate) end)
        if not ok then TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate) end
    end

    -- Ask other players' non-spawned vehicles to be spawned by this client,
    -- but ONLY the ones actually near this player — spawning every parked
    -- vehicle on the map on every login is what causes traffic to vanish
    -- and stops other players spawning vehicles near big parking clusters.
    local srcPed = GetPlayerPed(src)
    if srcPed and srcPed ~= 0 then
        local sc = GetEntityCoords(srcPed)
        for plate, entry in pairs(allParkedByPlate) do
            if not (parkedVehicles[citizenid] and parkedVehicles[citizenid][plate]) then
                if not spawnedNetIds[plate] or not NetIdIsAlive(spawnedNetIds[plate]) then
                    local d = #(vector3(sc.x, sc.y, sc.z) -
                               vector3(entry.coords.x, entry.coords.y, entry.coords.z))
                    if d <= (Config.ParkingSpawnDistance or 100.0) then
                        RequestClientSpawn(entry, src)
                    end
                end
            end
        end
    end

    -- Build ownNetIds for own vehicles.
    -- We may need to wait for spawns the client is currently doing above.
    -- Use a callback so the client triggers load after it confirms spawns.
    -- For own vehicles: ask client to spawn if needed, then load.

    local ownEntries = parkedVehicles[citizenid] or {}
    local pendingSpawns = {}
    for plate, entry in pairs(ownEntries) do
        if not spawnedNetIds[plate] or not NetIdIsAlive(spawnedNetIds[plate]) then
            pendingSpawns[#pendingSpawns + 1] = plate
            spawnInFlight[plate] = nil   -- ensure not blocked
            RequestClientSpawn(entry, src)
        end
    end

    -- Wait for own-vehicle spawns to resolve (up to 12 s)
    if #pendingSpawns > 0 then
        local waited = 0
        while waited < 12000 do
            Wait(200); waited = waited + 200
            local allDone = true
            for _, plate in ipairs(pendingSpawns) do
                if not spawnedNetIds[plate] or not NetIdIsAlive(spawnedNetIds[plate]) then
                    allDone = false; break
                end
            end
            if allDone then break end
        end
    end

    -- Now build the netId map to send to the client
    local ownNetIds = {}
    for plate, entry in pairs(ownEntries) do
        local netId = spawnedNetIds[plate]
        if netId and NetIdIsAlive(netId) then
            if propsApplied[plate] then
                ownNetIds[plate] = -1   -- already applied, no pop
            else
                propsApplied[plate] = true   -- owner will apply
                ownNetIds[plate]    = netId
            end
        end
    end

    -- Attach the live vehicle netId to each entry so cover_client can resolve
    -- entities directly without scanning GetGamePool (which races with entity
    -- release on non-owner clients).
    local allList = {}
    for _, entry in pairs(allParkedByPlate) do
        local e = {}
        for k, v in pairs(entry) do e[k] = v end
        local nid = spawnedNetIds[entry.plate]
        e.vehicleNetId = (nid and NetIdIsAlive(nid)) and nid or nil
        allList[#allList + 1] = e
    end
    local ownList = MapToList(ownEntries)

    Wait(300)
    TriggerClientEvent('mnc-parking:loadParkedVehicles', src, allList, ownList, ownNetIds)
end)

-- ============================================================
-- Callbacks
-- ============================================================
lib.callback.register('mnc-parking:getParkedVehicles', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {}, Config.MaxVehiclesOut end
    WaitForDB()
    local list     = MapToList(LoadPlayerVehicles(Player.PlayerData.citizenid))
    local maxSlots = GetMaxVehiclesOut(source)
    return list, maxSlots
end)

lib.callback.register('mnc-parking:getAllParkedVehicles', function()
    WaitForDB()
    return MapToList(allParkedByPlate)
end)

-- ============================================================
-- Install parking lock
-- ============================================================
RegisterNetEvent('mnc-parking:installLock', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    local owned = MySQL.query.await(
        'SELECT citizenid FROM player_vehicles WHERE plate = ? AND citizenid = ?',
        { plate, citizenid })
    if not owned or #owned == 0 then
        TriggerClientEvent('mnc-parking:notify', src,
            { title='Parking Lock', description='You do not own this vehicle.', type='error' })
        return
    end
    if lockedPlates[plate] then
        TriggerClientEvent('mnc-parking:notify', src,
            { title='Parking Lock', description='A Parking Lock is already installed.', type='error' })
        return
    end
    local lockItem = Player.Functions.GetItemByName(Config.ParkingLockItem)
    if not lockItem or lockItem.amount < 1 then
        TriggerClientEvent('mnc-parking:notify', src,
            { title='Parking Lock', description='You do not have a Parking Lock item.', type='error' })
        return
    end

    Player.Functions.RemoveItem(Config.ParkingLockItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src,
        QBCore.Shared.Items[Config.ParkingLockItem], 'remove')
    lockedPlates[plate] = true
    MySQL.query.await(
        [[INSERT INTO `mnc_parking_locks` (`plate`,`citizenid`)
          VALUES (?,?) ON DUPLICATE KEY UPDATE `citizenid`=?,`installed_at`=CURRENT_TIMESTAMP]],
        { plate, citizenid, citizenid })
    TriggerClientEvent('mnc-parking:notify', src, {
        title='Parking Lock',
        description='Parking Lock installed on '..plate..'. You can now use /park.',
        type='success', duration=6000 })
    if Config.Debug then
        print('^2[mnc-parking]^7 Lock installed plate=' .. plate)
    end
end)

-- ============================================================
-- Park vehicle
-- ============================================================
lib.callback.register('mnc-parking:parkVehicle', function(source, plate, model, coords, heading, props, fuel, engine, body, clientNetId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false, 'Player not found.' end
    local citizenid = Player.PlayerData.citizenid

    local owned = MySQL.query.await(
        'SELECT citizenid FROM player_vehicles WHERE plate = ? AND citizenid = ?',
        { plate, citizenid })
    if not owned or #owned == 0 then return false, 'You do not own this vehicle.' end
    if not lockedPlates[plate] then
        return false, 'No Parking Lock installed. Use the item while next to the vehicle.'
    end

    if not parkedVehicles[citizenid] then parkedVehicles[citizenid] = {} end
    local count   = 0
    for _ in pairs(parkedVehicles[citizenid]) do count = count + 1 end
    local maxSlots = GetMaxVehiclesOut(source)
    if count >= maxSlots then
        return false, ('You can only have %d vehicle(s) parked at a time.'):format(maxSlots)
    end

    fuel    = math.max(0.0, math.min(100.0,  tonumber(fuel)   or 100.0))
    engine  = math.max(0.0, math.min(1000.0, tonumber(engine) or 1000.0))
    body    = math.max(0.0, math.min(1000.0, tonumber(body)   or 1000.0))
    heading = tonumber(heading) or 0.0

    local safeCoords = NormaliseCoords(coords)
    if not safeCoords then return false, 'Invalid coordinates.' end
    coords = safeCoords

    local originGarage = MarkVehicleOut(plate)
    local entry = {
        plate=plate, model=model, citizenid=citizenid,
        origin_garage=originGarage, coords=coords, heading=heading,
        props=props or '{}', fuel=fuel, engine=engine, body=body,
    }
    parkedVehicles[citizenid][plate] = entry
    allParkedByPlate[plate]          = entry

    MySQL.query.await(
        [[INSERT INTO `mnc_parked_vehicles`
            (`citizenid`,`plate`,`model`,`origin_garage`,
             `coords_x`,`coords_y`,`coords_z`,`heading`,
             `props`,`fuel`,`engine`,`body`)
          VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
          ON DUPLICATE KEY UPDATE
            `coords_x`=VALUES(`coords_x`),`coords_y`=VALUES(`coords_y`),
            `coords_z`=VALUES(`coords_z`),`heading`=VALUES(`heading`),
            `props`=VALUES(`props`),`fuel`=VALUES(`fuel`),
            `engine`=VALUES(`engine`),`body`=VALUES(`body`),
            `updated_at`=CURRENT_TIMESTAMP]],
        { citizenid,plate,model,originGarage,
          coords.x,coords.y,coords.z,heading,props,fuel,engine,body })

    local dbRow = MySQL.query.await(
        'SELECT `origin_garage` FROM `mnc_parked_vehicles` WHERE `citizenid`=? AND `plate`=? LIMIT 1',
        { citizenid, plate })
    if dbRow and dbRow[1] and dbRow[1].origin_garage and dbRow[1].origin_garage ~= '' then
        local og = dbRow[1].origin_garage
        entry.origin_garage = og
        parkedVehicles[citizenid][plate].origin_garage = og
        allParkedByPlate[plate].origin_garage          = og
    end

    -- The player's live driven entity IS the parked vehicle.
    -- Props are already correct in world. Register netId and mark done.
    if clientNetId and clientNetId > 0 then
        spawnedNetIds[plate] = clientNetId
        propsApplied[plate]  = true
        spawnInFlight[plate] = nil
        if Config.Debug then
            print('^2[mnc-parking]^7 Parked plate=' .. plate .. ' netId=' .. clientNetId)
        end
    end

    return true, 'Vehicle parked successfully.', maxSlots
end)

-- ============================================================
-- Periodic state sync
-- ============================================================
RegisterNetEvent('mnc-parking:updateVehicleState', function(plate, coords, heading, props, fuel, engine, body)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    if not parkedVehicles[citizenid] or not parkedVehicles[citizenid][plate] then return end

    local entry      = parkedVehicles[citizenid][plate]
    local safeCoords = NormaliseCoords(coords) or entry.coords
    if not safeCoords then return end

    fuel    = math.max(0.0, math.min(100.0,  tonumber(fuel)   or entry.fuel))
    engine  = math.max(0.0, math.min(1000.0, tonumber(engine) or entry.engine))
    body    = math.max(0.0, math.min(1000.0, tonumber(body)   or entry.body))
    heading = tonumber(heading) or entry.heading or 0.0

    entry.coords=safeCoords; entry.heading=heading; entry.props=props or entry.props
    entry.fuel=fuel; entry.engine=engine; entry.body=body
    if allParkedByPlate[plate] then allParkedByPlate[plate] = entry end

    if databaseReady then
        MySQL.update(
            [[UPDATE `mnc_parked_vehicles`
              SET `coords_x`=?,`coords_y`=?,`coords_z`=?,`heading`=?,
                  `props`=?,`fuel`=?,`engine`=?,`body`=?,`updated_at`=CURRENT_TIMESTAMP
              WHERE `citizenid`=? AND `plate`=?]],
            { safeCoords.x,safeCoords.y,safeCoords.z,heading,
              props,fuel,engine,body,citizenid,plate })
    end
end)

-- ============================================================
-- Recall vehicle
-- ============================================================
lib.callback.register('mnc-parking:recallVehicle', function(source, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false, 'Player not found.' end
    local citizenid = Player.PlayerData.citizenid

    if not parkedVehicles[citizenid] or not parkedVehicles[citizenid][plate] then
        return false, 'Vehicle not found in your parked list.'
    end

    local entry        = parkedVehicles[citizenid][plate]
    local originGarage = (entry and entry.origin_garage and entry.origin_garage ~= '')
                         and entry.origin_garage or Config.RecallGarage

    parkedVehicles[citizenid][plate] = nil
    allParkedByPlate[plate]          = nil
    recalledPlates[plate]            = true

    MySQL.query.await(
        'DELETE FROM `mnc_parked_vehicles` WHERE `citizenid`=? AND `plate`=?',
        { citizenid, plate })

    DeleteSpawnedVehicle(plate)
    RestoreToOriginGarage(plate, originGarage)
    TriggerClientEvent('mnc-parking:vehicleRecalled', -1, plate)

    if Config.Debug then
        print('^2[mnc-parking]^7 Recalled plate=' .. plate .. ' → ' .. originGarage)
    end
    return true, 'Vehicle returned to depot.'
end)

-- ============================================================
-- Vehicle moved/driven away
-- ============================================================
lib.callback.register('mnc-parking:vehicleMoved', function(source, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    local citizenid = Player.PlayerData.citizenid
    if not parkedVehicles[citizenid] or not parkedVehicles[citizenid][plate] then return false end

    parkedVehicles[citizenid][plate] = nil
    allParkedByPlate[plate]          = nil
    spawnedNetIds[plate]             = nil
    propsApplied[plate]              = nil
    spawnInFlight[plate]             = nil
    impoundedPlates[plate]           = true

    MySQL.query.await(
        'DELETE FROM `mnc_parked_vehicles` WHERE `citizenid`=? AND `plate`=?',
        { citizenid, plate })

    local depot = Config.ImpoundGarage or Config.RecallGarage
    MySQL.update(
        'UPDATE `player_vehicles` SET `state`=0, `garage`=? WHERE `plate`=?',
        { depot, plate })

    TriggerClientEvent('mnc-parking:vehicleUntracked', -1, plate)
    TriggerClientEvent('mnc-parking:notify', source, {
        title='Parking Spot Cleared',
        description=plate..' was moved. After the next restart it will be at the depot.',
        type='warning', duration=10000 })

    if Config.Debug then
        print('^2[mnc-parking]^7 Moved plate=' .. plate .. ' → depot')
    end
    return true
end)

-- ============================================================
-- Lock broadcast / give keys
-- ============================================================
RegisterNetEvent('mnc-parking:lockParkedVehicle', function(plate, netId)
    TriggerClientEvent('vehiclekeys:client:SetLockStatus', -1, netId, plate, 2)
end)

RegisterNetEvent('mnc-parking:giveKeys', function(plate)
    local src = source
    local ok  = pcall(function() exports['qb-vehiclekeys']:GiveKeys(src, plate) end)
    if not ok then TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate) end
end)

QBCore.Functions.CreateUseableItem(Config.ParkingLockItem, function(source)
    TriggerClientEvent('mnc-parking:useItem', source)
end)

AddEventHandler('playerDropped', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then parkedVehicles[Player.PlayerData.citizenid] = nil end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for plate in pairs(spawnedNetIds) do DeleteSpawnedVehicle(plate) end
    spawnedNetIds = {}

    local platesToRestore = {}
    for plate in pairs(allParkedByPlate) do
        if not impoundedPlates[plate] and not recalledPlates[plate] then
            platesToRestore[#platesToRestore + 1] = plate
        end
    end
    for _, plate in ipairs(platesToRestore) do
        local entry  = allParkedByPlate[plate]
        local garage = (entry and entry.origin_garage and entry.origin_garage ~= '')
                       and entry.origin_garage or Config.RecallGarage
        MySQL.update.await(
            'UPDATE `player_vehicles` SET `state`=1, `garage`=? WHERE `plate`=?',
            { garage, plate })
    end

    local depot = Config.ImpoundGarage or Config.RecallGarage
    for plate in pairs(impoundedPlates) do
        MySQL.update.await(
            'UPDATE `player_vehicles` SET `state`=1, `garage`=? WHERE `plate`=?',
            { depot, plate })
    end

    if Config.Debug then
        print('^2[mnc-parking]^7 onResourceStop: restored ' ..
              #platesToRestore .. ' plate(s).')
    end
end)

-- ============================================================
-- Use parking_key item — removes a parking lock from a vehicle
-- ============================================================
QBCore.Functions.CreateUseableItem(Config.ParkingKeyItem, function(source)
    TriggerClientEvent('mnc-parking:useKeyItem', source)
end)

RegisterNetEvent('mnc-parking:removeLock', function(plate)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid

    plate = string.upper((plate or ''):gsub('%s+', ''))

    -- Ownership check — same pattern as installLock
    local owned = MySQL.query.await(
        'SELECT citizenid FROM player_vehicles WHERE plate = ? AND citizenid = ?',
        { plate, citizenid })
    if not owned or #owned == 0 then
        TriggerClientEvent('mnc-parking:notify', src, {
            title       = 'Parking Key',
            description = 'You do not own this vehicle.',
            type        = 'error',
            duration    = 5000,
        })
        return
    end

    if not lockedPlates[plate] then
        TriggerClientEvent('mnc-parking:notify', src, {
            title       = 'Parking Key',
            description = 'This vehicle does not have a parking lock installed.',
            type        = 'error',
            duration    = 5000,
        })
        return
    end

    -- Check the player actually has the key item
    local keyItem = Player.Functions.GetItemByName(Config.ParkingKeyItem)
    if not keyItem or keyItem.amount < 1 then
        TriggerClientEvent('mnc-parking:notify', src, {
            title       = 'Parking Key',
            description = 'You do not have a Parking Key.',
            type        = 'error',
            duration    = 5000,
        })
        return
    end

    lockedPlates[plate] = nil
    MySQL.query.await('DELETE FROM `mnc_parking_locks` WHERE `plate`=?', { plate })

    Player.Functions.RemoveItem(Config.ParkingKeyItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src,
        QBCore.Shared.Items[Config.ParkingKeyItem], 'remove')

    TriggerClientEvent('mnc-parking:notify', src, {
        title       = 'Parking Key',
        description = 'Parking lock removed from ' .. plate .. '.',
        type        = 'success',
        duration    = 5000,
    })

    if Config.Debug then
        print('^2[mnc-parking]^7 Lock removed from plate=' .. plate ..
              ' by citizenid=' .. citizenid)
    end
end)

RegisterCommand('dropparked', function(source, args, rawCommand)
    -- Allow console (source == 0) or in-game QBCore admins
    if source ~= 0 then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return end
        if not QBCore.Functions.HasPermission(source, 'admin') then
            TriggerClientEvent('mnc-parking:notify', source, {
                title       = 'Parking',
                description = 'You do not have permission to use this command.',
                type        = 'error',
                duration    = 5000,
            })
            return
        end
    end

    local count = 0
    for plate, entry in pairs(allParkedByPlate) do
        local garage = (entry.origin_garage and entry.origin_garage ~= '')
                       and entry.origin_garage or Config.RecallGarage

        -- If this plate has an active cover, tear it down cleanly first
        local c = GetCoverState(plate)
        if c then
            local spawnerSrc = c.spawnerSrc or propSpawners and propSpawners[c.netId]
            if spawnerSrc and GetPlayerName(spawnerSrc) then
                TriggerClientEvent('mnc-lift:deleteMyCoverProp', spawnerSrc, plate, c.netId)
            end
            -- Restore the vehicle visibility after a brief prop-delete delay
            local savedX, savedY, savedVehZ, savedHeading =
                c.coverX, c.coverY, c.coverVehZ, c.coverHeading
            CreateThread(function()
                Wait(200)
                TriggerClientEvent('mnc-lift:restoreVehicle', -1, plate,
                    savedX, savedY, savedVehZ, savedHeading)
            end)
            MySQL.query('DELETE FROM `mnc_cover_state` WHERE `plate`=?', { plate })
        end

        DeleteSpawnedVehicle(plate)
        MySQL.update.await(
            'UPDATE `player_vehicles` SET `state`=1, `garage`=? WHERE `plate`=?',
            { garage, plate })
        count = count + 1
    end

    MySQL.query.await('DELETE FROM `mnc_parked_vehicles`', {})

    parkedVehicles   = {}
    allParkedByPlate = {}
    lockedPlates     = {}
    spawnedNetIds    = {}
    propsApplied     = {}
    spawnInFlight    = {}

    -- Tell every client to clean up blips, sync timers, cover targets, local state
    TriggerClientEvent('mnc-parking:clearAll', -1)

    TriggerClientEvent('mnc-parking:notify', -1, {
        title       = 'Parking',
        description = 'All parked vehicles have been cleared by an admin.',
        type        = 'warning',
        duration    = 8000,
    })

    print('^2[mnc-parking]^7 dropparked: cleared ' .. count .. ' vehicle(s).')
end, true)

-- ============================================================
-- Proximity streaming: parked vehicles only exist in the world
-- while a player is actually near them, and get cleanly deleted
-- (not just forgotten) once nobody is. Without this, spawned
-- parked vehicles are forced to exist forever on every client
-- regardless of distance — large clusters (e.g. a house with 30
-- vehicles outside) permanently eat into the game's local
-- vehicle budget, killing ambient traffic and blocking players
-- from spawning their own vehicles nearby.
--
-- Before (re)spawning, we also ask clients to scan for and delete
-- any stray copy of that plate that might already be sitting in
-- the world under a netId we lost track of — prevents duplicates.
-- ============================================================
Config.ParkingSpawnDistance       = Config.ParkingSpawnDistance       or 100.0  -- spawn once a player is this close
Config.ParkingDespawnDistance     = Config.ParkingDespawnDistance     or 150.0  -- despawn once nobody is within this
Config.ParkingStreamCheckInterval = Config.ParkingStreamCheckInterval or 20000  -- ms between sweeps
Config.VehicleWatchdogStagger     = Config.VehicleWatchdogStagger     or 1500   -- ms between each spawn within a sweep
Config.VehicleWatchdogCleanupWait = Config.VehicleWatchdogCleanupWait or 2500   -- ms given to clients to find/delete strays

-- Broadcast a cleanup request for a batch of plates and wait for it to land
-- before we spawn fresh copies (prevents duplicate vehicles under one plate).
local function CleanupStrayPlates(plates)
    if #plates == 0 then return end
    TriggerClientEvent('mnc-parking:cleanupStrayVehicles', -1, plates)
    Wait(Config.VehicleWatchdogCleanupWait)
end

-- Any previously tracked netId for a plate we just confirmed-removed is
-- definitely gone now — clear it so the next spawn isn't skipped as "alive".
RegisterNetEvent('mnc-parking:strayVehicleRemoved', function(plate)
    plate = string.upper((plate or ''):gsub('%s+', ''))
    if Config.Debug then
        print('^3[mnc-parking]^7 Stray vehicle removed for plate=' .. plate)
    end
    spawnedNetIds[plate] = nil
    propsApplied[plate]  = nil
end)

RegisterNetEvent('mnc-parking:vehicleDespawnedAck', function(plate)
    if Config.Debug then
        print('^2[mnc-parking]^7 Despawn confirmed plate=' .. plate)
    end
end)

local function MinDistanceToAnyPlayer(coords)
    local best = math.huge
    for _, src in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(tonumber(src))
        if ped and ped ~= 0 then
            local pos = GetEntityCoords(ped)
            local d = #(vector3(pos.x, pos.y, pos.z) -
                       vector3(coords.x, coords.y, coords.z))
            if d < best then best = d end
        end
    end
    return best
end

CreateThread(function()
    WaitForDB()
    Wait(20000)  -- let the server settle after boot before the first sweep

    while true do
        Wait(Config.ParkingStreamCheckInterval)

        if #GetPlayers() > 0 then

            -- ── Despawn parked vehicles nobody is near ──────────────────
            for plate, netId in pairs(spawnedNetIds) do
                if not impoundedPlates[plate] and not recalledPlates[plate] then
                    local entry = allParkedByPlate[plate]
                    if entry and NetIdIsAlive(netId) then
                        if MinDistanceToAnyPlayer(entry.coords) > Config.ParkingDespawnDistance then
                            if Config.Debug then
                                print('^3[mnc-parking]^7 Despawning far parked vehicle plate=' .. plate)
                            end
                            TriggerClientEvent('mnc-parking:despawnVehicle', -1, plate, netId)
                            spawnedNetIds[plate] = nil
                            propsApplied[plate]  = nil
                            spawnInFlight[plate] = nil
                        end
                    end
                end
            end

            -- ── Spawn parked vehicles a player has walked up to ─────────
            local toSpawn = {}
            for plate, entry in pairs(allParkedByPlate) do
                if not impoundedPlates[plate] and not recalledPlates[plate] then
                    local netId = spawnedNetIds[plate]
                    if (not netId or not NetIdIsAlive(netId)) and not spawnInFlight[plate] then
                        if MinDistanceToAnyPlayer(entry.coords) <= Config.ParkingSpawnDistance then
                            toSpawn[#toSpawn + 1] = { plate = plate, entry = entry }
                        end
                    end
                end
            end

            if #toSpawn > 0 then
                if Config.Debug then
                    print(('^3[mnc-parking]^7 Streaming: %d parked vehicle(s) now in range, cleaning up strays then spawning.'):format(#toSpawn))
                end

                local platesOnly = {}
                for _, m in ipairs(toSpawn) do platesOnly[#platesOnly + 1] = m.plate end
                CleanupStrayPlates(platesOnly)

                for _, m in ipairs(toSpawn) do
                    RequestClientSpawn(m.entry, nil)  -- nil = pick nearest online player
                    Wait(Config.VehicleWatchdogStagger)
                end
            end
        end
    end
end)

-- ============================================================
-- Manual trigger: /parkrespawn — force an immediate cleanup +
-- respawn sweep (console or admin).
-- ============================================================
RegisterCommand('parkrespawn', function(source)
    if source ~= 0 then
        if not QBCore.Functions.HasPermission(source, 'admin') then
            TriggerClientEvent('mnc-parking:notify', source, {
                title='Parking', description='You do not have permission to use this command.',
                type='error' })
            return
        end
    end

    local missing = {}
    for plate, entry in pairs(allParkedByPlate) do
        if not impoundedPlates[plate] and not recalledPlates[plate] then
            local netId = spawnedNetIds[plate]
            if (not netId or not NetIdIsAlive(netId)) and not spawnInFlight[plate] then
                missing[#missing + 1] = { plate = plate, entry = entry }
            end
        end
    end

    if #missing == 0 then
        print('^2[mnc-parking]^7 parkrespawn: nothing missing.')
        return
    end

    local platesOnly = {}
    for _, m in ipairs(missing) do platesOnly[#platesOnly + 1] = m.plate end
    CleanupStrayPlates(platesOnly)

    for _, m in ipairs(missing) do
        RequestClientSpawn(m.entry, nil)
        Wait(Config.VehicleWatchdogStagger or 1500)
    end

    print(('^2[mnc-parking]^7 parkrespawn: cleaned up + requested %d missing vehicle spawn(s).'):format(#missing))
end, true)

print('^2[mnc-parking]^7 Loaded successfully.')