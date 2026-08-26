local QBCore = exports['qb-core']:GetCoreObject()

local activeVehicles = {}   -- [slotIndex] = { entity, netId, plate, model, label }
local slotLocks = {}        -- [slotIndex] = true while a claim is being processed
local claimsInProgress = {} -- [citizenid] = true while a claim is being processed

-- ============================================================
--  DATABASE: auto-create tables on resource start
--  (kept in sync with sql/install.sql, which is still provided
--  for people who prefer to run migrations manually)
-- ============================================================

local function EnsureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mnc_startingcar_claims` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(50) NOT NULL,
            `vehicle` VARCHAR(60) NOT NULL,
            `plate` VARCHAR(15) NOT NULL,
            `owner_name` VARCHAR(100) DEFAULT NULL,
            `signature_type` VARCHAR(20) DEFAULT NULL,
            `signature_data` LONGTEXT DEFAULT NULL,
            `claimed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `mnc_startingcar_claims_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mnc_startingcar_sound_log` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `citizenid` VARCHAR(50) NOT NULL,
            `heard_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `mnc_startingcar_sound_log_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    print('^2[mnc-startingcar]^7 Database tables verified/created.')
end

local function notify(source, msg, type)
    if source == 0 then
        print(('[mnc-startingcar] %s'):format(msg))
        return
    end
    TriggerClientEvent('QBCore:Notify', source, msg, type)
end

-- Runs first (CreateThread coroutines start in declaration order), well
-- before any player can trigger the callbacks/events further down that
-- query these tables.
CreateThread(function()
    EnsureTables()
end)

-- ============================================================
--  SLOT VEHICLE SPAWNING
-- ============================================================

-- True if `plate` is already sitting on a live showroom vehicle (claimed or
-- not yet claimed -- those aren't in player_vehicles until someone actually
-- claims them) or already belongs to a vehicle owned by any player.
local function isPlateInUse(plate)
    for _, v in pairs(activeVehicles) do
        if v.plate == plate then
            return true
        end
    end

    local existing = MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ?', { plate })
    return existing ~= nil
end

local function generatePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

    for _ = 1, 20 do
        local plate = ''
        for _ = 1, 8 do
            local idx = math.random(1, #chars)
            plate = plate .. chars:sub(idx, idx)
        end

        if not isPlateInUse(plate) then
            return plate
        end
    end

    -- Astronomically unlikely fallback if 20 straight random plates all
    -- collided -- guarantees uniqueness rather than risking a duplicate.
    return ('MNC%06d'):format(GetGameTimer() % 1000000)
end

function SpawnSlotVehicle(index)
    local data = Config.VehicleSpawns[index]
    if not data then return end

    local hash = GetHashKey(data.model)
    local veh = CreateVehicleServerSetter(hash, 'automobile', data.coords.x, data.coords.y, data.coords.z, data.coords.w)

    local timeout = 0
    while not DoesEntityExist(veh) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    -- IMPORTANT: this used to fail completely silently (no print at all) if
    -- the model name was invalid/not streamed or the coords were bad, which
    -- made it look like the whole resource was broken when really just the
    -- vehicle never spawned. Now it always tells you which slot failed.
    if not DoesEntityExist(veh) then
        print(('^1[mnc-startingcar]^7 Slot %d (%s, model "%s") FAILED to spawn -- check that the model name is valid/streamed in on this server, and that the coords in config.lua are correct for this map. hash=%s coords=%.2f, %.2f, %.2f'):format(
            index, data.label, data.model, tostring(hash), data.coords.x, data.coords.y, data.coords.z))
        return
    end

    local plate = generatePlate()
    SetVehicleNumberPlateText(veh, plate)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleDoorsLocked(veh, 1) -- locked until someone claims it


    if Config.FuelSystem == 'legacy' then
        Entity(veh).state:set('fuel', 100.0, true)
    end

    activeVehicles[index] = {
        entity = veh,
        netId = NetworkGetNetworkIdFromEntity(veh),
        plate = plate,
        model = data.model,
        label = data.label,
        sound = data.boughtSound,
    }

    print(('^2[mnc-startingcar]^7 Slot %d (%s) spawned OK, plate %s, at %.2f, %.2f, %.2f'):format(
        index, data.label, plate, data.coords.x, data.coords.y, data.coords.z))
end

local function InitVehicles()
    for i = 1, #Config.VehicleSpawns do
        -- pcall so a single bad model/coords entry (or any future error)
        -- can't silently abort the rest of the spawn loop like it did before.
        local ok, err = pcall(SpawnSlotVehicle, i)
        if not ok then
            print(('^1[mnc-startingcar] Failed to spawn slot %d vehicle: %s^0'):format(i, tostring(err)))
        end
    end
end

CreateThread(function()
    Wait(1000)
    InitVehicles()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, v in pairs(activeVehicles) do
        if v.entity and DoesEntityExist(v.entity) then
            DeleteEntity(v.entity)
        end
    end
end)

-- ============================================================
--  CALLBACK: has this player already claimed a starter vehicle?
--  Backed by the mnc_startingcar_claims SQL table (auto-created above,
--  see also sql/install.sql) so it survives restarts and doubles as the
--  persistent "sound block".
-- ============================================================

QBCore.Functions.CreateCallback('mnc-startingcar:server:hasClaimed', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(true)
        return
    end

    local result = MySQL.scalar.await('SELECT 1 FROM mnc_startingcar_claims WHERE citizenid = ?', {
        Player.PlayerData.citizenid,
    })

    cb(result ~= nil)
end)

-- ============================================================
--  CALLBACK + EVENT: one-time-ever intro sound
--  Backed by mnc_startingcar_sound_log so a player only ever hears it once,
--  even across relogs/restarts, independent of whether they've claimed yet.
-- ============================================================

QBCore.Functions.CreateCallback('mnc-startingcar:server:hasHeardSound', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(true)
        return
    end

    local result = MySQL.scalar.await('SELECT 1 FROM mnc_startingcar_sound_log WHERE citizenid = ?', {
        Player.PlayerData.citizenid,
    })

    cb(result ~= nil)
end)

RegisterNetEvent('mnc-startingcar:server:markSoundPlayed', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    MySQL.query.await('INSERT IGNORE INTO mnc_startingcar_sound_log (citizenid) VALUES (?)', {
        Player.PlayerData.citizenid,
    })
end)

-- ============================================================
--  CLAIM EVENT
-- ============================================================

RegisterNetEvent('mnc-startingcar:server:claimVehicle', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid

    -- Prevent double submits (e.g. spamming the confirm button)
    if claimsInProgress[citizenid] then return end
    claimsInProgress[citizenid] = true

    local function fail(reason)
        claimsInProgress[citizenid] = nil
        TriggerClientEvent('mnc-startingcar:client:claimFailed', src, reason)
    end

    if type(data) ~= 'table' or type(data.slot) ~= 'number' then
        fail('Invalid claim data')
        return
    end

    local slot = data.slot
    local slotData = Config.VehicleSpawns[slot]
    if not slotData then
        fail('Invalid vehicle selection')
        return
    end

    if slotLocks[slot] then
        fail('Someone else is already claiming that vehicle')
        return
    end

    -- Persistent, SQL-backed check -- this is what makes the claim (and the
    -- sound block) survive restarts, not just an in-memory flag.
    local already = MySQL.scalar.await('SELECT 1 FROM mnc_startingcar_claims WHERE citizenid = ?', { citizenid })
    if already then
        fail('You have already claimed your starter vehicle')
        return
    end

    local vehState = activeVehicles[slot]
    if not vehState or not vehState.entity or not DoesEntityExist(vehState.entity) then
        fail('That vehicle is not available right now, try again shortly')
        return
    end

    if type(data.signatureData) ~= 'string' or data.signatureData == '' then
        fail('A signature is required to claim your vehicle')
        return
    end

    local ownerName = data.ownerName
    if type(ownerName) ~= 'string' or ownerName == '' then
        ownerName = QBCore.Shared.SplitStr(GetPlayerName(src), ' ')[1] or 'Owner'
    end

    slotLocks[slot] = true

    local plate = vehState.plate
    local hash = GetHashKey(vehState.model)
    local license = Player.PlayerData.license

    -- Belt-and-suspenders: re-check the plate against player_vehicles right
    -- before inserting, in case another vehicle system claimed the same
    -- plate text after this showroom car was spawned. Re-roll if so, so the
    -- INSERT below (and any UNIQUE constraint on plate) can't fail/collide.
    if isPlateInUse(plate) then
        plate = generatePlate()
        SetVehicleNumberPlateText(vehState.entity, plate)
        vehState.plate = plate
    end

    local insertOk = MySQL.insert.await(
        'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, fuel, engine, body, state, depotprice, drivingdistance) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            license,
            citizenid,
            vehState.model,
            hash,
            '{}',
            plate,
            Config.GarageName,
            100,
            1000.0,
            1000.0,
            0, -- 0 = currently out in the world (already spawned, not sitting in the garage)
            0,
            0,
        }
    )

    if not insertOk then
        slotLocks[slot] = nil
        fail('Something went wrong registering your vehicle, please try again')
        return
    end

    MySQL.insert.await(
        'INSERT INTO mnc_startingcar_claims (citizenid, vehicle, plate, owner_name, signature_type, signature_data) VALUES (?, ?, ?, ?, ?, ?)',
        {
            citizenid,
            vehState.model,
            plate,
            ownerName,
            data.signatureType or 'type',
            data.signatureData,
        }
    )

    SetVehicleDoorsLocked(vehState.entity, 0)

    local claimedNetId = vehState.netId
    local claimedLabel = vehState.label
    local claimedSound = vehState.sound

    -- Free up the slot immediately so it can't be double-claimed, then spawn
    -- a replacement after the configured delay for future new players.
    activeVehicles[slot] = nil

    TriggerClientEvent('mnc-startingcar:client:claimSuccess', src, {
        netId = claimedNetId,
        plate = plate,
        label = claimedLabel,
        sound = claimedSound,
    })

    claimsInProgress[citizenid] = nil
    slotLocks[slot] = nil

    SetTimeout(Config.RespawnDelay or 0, function()
        SpawnSlotVehicle(slot)
    end)
end)

-- ============================================================
--  ADMIN COMMANDS: /resetstartercar and /resetstartersound
--
--  client.lua already listens for 'mnc-startingcar:client:claimReset' and
--  'mnc-startingcar:client:soundReset' (so an already-connected player's
--  cached flags update immediately) and its comments describe these two
--  commands -- but nothing server-side ever actually registered them or
--  triggered those events. That's the missing piece: the intro sound
--  (audio.mp3) is only ever sent once per citizenid, gated by a row in
--  mnc_startingcar_sound_log, and with no working reset command there was
--  no supported way to clear that flag and hear it again. Same story for
--  the claim flag/table.
--
--  Both are `restricted` (the trailing `true`), so an admin must be granted
--  the matching ace permission in server.cfg, e.g.:
--      add_ace group.admin command.resetstartercar allow
--      add_ace group.admin command.resetstartersound allow
--
--  Usage: /resetstartercar [playerId]  (defaults to yourself if omitted)
--         /resetstartersound [playerId]
-- ============================================================


