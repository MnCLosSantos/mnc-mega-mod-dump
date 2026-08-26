-- cover_server.lua  (rewrite)
-- ──────────────────────────────────────────────────────────────────────────────
-- Robust plate-keyed cover state.  All persistence is keyed on the normalised
-- plate string so there is never an ambiguous netId clash between vehicles.
--
-- DB table: mnc_cover_state
--   plate         VARCHAR(20) PK
--   prop_netid    INT         (0 = no prop recorded yet)
--   spawner_src   INT NULL
--   cover_z       FLOAT NULL  — groundZ used to PLACE the prop flush with terrain
--   cover_x       FLOAT NULL  — vehicle origin X at cover time  (restore pos)
--   cover_y       FLOAT NULL  — vehicle origin Y at cover time  (restore pos)
--   cover_veh_z   FLOAT NULL  — vehicle origin Z at cover time  (restore height)
--   cover_heading FLOAT NULL  — vehicle heading at cover time
-- ──────────────────────────────────────────────────────────────────────────────

local QBCore = exports['qb-core']:GetCoreObject()

-- ── In-memory state ───────────────────────────────────────────────────────────
-- coverState[plate] = {
--     netId, spawnerSrc,
--     coverZ, coverX, coverY, coverVehZ, coverHeading
-- }
local coverState = {}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function NormalisePlate(plate)
    return string.upper((plate or ''):gsub('%s+', ''))
end

local function PlayerOwnsVehicle(src, plate)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    local rows = MySQL.query.await(
        'SELECT citizenid FROM player_vehicles WHERE plate=? AND citizenid=?',
        { plate, Player.PlayerData.citizenid })
    return rows and #rows > 0
end

-- Returns true when the plate is currently tracked as parked by this resource.
-- We read from the mnc_parked_vehicles table so we do not need a hard dependency
-- on server.lua's in-memory tables.
local function VehicleIsParked(plate)
    local rows = MySQL.query.await(
        'SELECT plate FROM mnc_parked_vehicles WHERE plate=? LIMIT 1', { plate })
    return rows and #rows > 0
end

local function HasItem(src, item)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    local it = Player.Functions.GetItemByName(item)
    return it and it.amount >= 1
end

local function RemoveItem(src, item, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.RemoveItem(item, amount or 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove')
end

local function GiveItem(src, item, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.AddItem(item, amount or 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add')
end

local function Notify(src, title, desc, ntype, dur)
    TriggerClientEvent('mnc-parking:notify', src,
        { title = title, description = desc,
          type  = ntype or 'inform', duration = dur or 5000 })
end

-- ── Expose cover state to other server-side scripts (e.g. server.lua) ─────────
function GetCoverState(plate)
    return coverState[NormalisePlate(plate)]
end

-- ── DB init & load ────────────────────────────────────────────────────────────
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
    Wait(1200)

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mnc_cover_state` (
            `plate`         VARCHAR(20) NOT NULL,
            `prop_netid`    INT         NOT NULL DEFAULT 0,
            `spawner_src`   INT         DEFAULT NULL,
            `cover_z`       FLOAT       DEFAULT NULL,
            `cover_x`       FLOAT       DEFAULT NULL,
            `cover_y`       FLOAT       DEFAULT NULL,
            `cover_veh_z`   FLOAT       DEFAULT NULL,
            `cover_heading` FLOAT       DEFAULT NULL,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Safe migration guards for existing installs
    local cols = {
        'spawner_src   INT   DEFAULT NULL',
        'cover_z       FLOAT DEFAULT NULL',
        'cover_x       FLOAT DEFAULT NULL',
        'cover_y       FLOAT DEFAULT NULL',
        'cover_veh_z   FLOAT DEFAULT NULL',
        'cover_heading FLOAT DEFAULT NULL',
    }
    for _, col in ipairs(cols) do
        MySQL.query('ALTER TABLE `mnc_cover_state` ADD COLUMN IF NOT EXISTS ' .. col, {})
    end

    -- Load persisted cover states into memory
    local rows = MySQL.query.await('SELECT * FROM `mnc_cover_state`', {})
    if rows then
        for _, row in ipairs(rows) do
            local plate = NormalisePlate(row.plate)
            coverState[plate] = {
                netId        = row.prop_netid  or 0,
                spawnerSrc   = row.spawner_src,
                coverZ       = row.cover_z,
                coverX       = row.cover_x,
                coverY       = row.cover_y,
                coverVehZ    = row.cover_veh_z,
                coverHeading = row.cover_heading,
            }
        end
        print('^2[mnc-parking]^7 Loaded ' .. #rows .. ' cover state(s).')
    end
end)

-- ── DB persistence helpers ────────────────────────────────────────────────────

local function SaveCover(plate)
    local c = coverState[plate]
    if not c then return end
    MySQL.query([[
        INSERT INTO `mnc_cover_state`
            (`plate`,`prop_netid`,`spawner_src`,
             `cover_z`,`cover_x`,`cover_y`,`cover_veh_z`,`cover_heading`)
        VALUES (?,?,?,?,?,?,?,?)
        ON DUPLICATE KEY UPDATE
            `prop_netid`    = VALUES(`prop_netid`),
            `spawner_src`   = VALUES(`spawner_src`),
            `cover_z`       = VALUES(`cover_z`),
            `cover_x`       = VALUES(`cover_x`),
            `cover_y`       = VALUES(`cover_y`),
            `cover_veh_z`   = VALUES(`cover_veh_z`),
            `cover_heading` = VALUES(`cover_heading`)
    ]], { plate, c.netId or 0, c.spawnerSrc,
          c.coverZ, c.coverX, c.coverY, c.coverVehZ, c.coverHeading })
end

local function ClearCover(plate)
    coverState[plate] = nil
    MySQL.query('DELETE FROM `mnc_cover_state` WHERE `plate`=?', { plate })
end

-- ── Internal: tear down a cover prop and restore the vehicle ──────────────────
-- Called from both the uncover event and the recall event.
local function DoCoverTeardown(plate)
    local c = coverState[plate]
    if not c then return end

    local propNetId    = c.netId
    local spawnerSrc   = c.spawnerSrc
    local savedX       = c.coverX
    local savedY       = c.coverY
    local savedVehZ    = c.coverVehZ
    local savedHeading = c.coverHeading

    ClearCover(plate)

    -- Ask the owning client to delete the prop.
    -- If that client is offline, broadcast so any adopter can catch it.
    if spawnerSrc and GetPlayerName(tostring(spawnerSrc)) then
        TriggerClientEvent('mnc-lift:deleteMyCoverProp', spawnerSrc, plate, propNetId)
    else
        TriggerClientEvent('mnc-lift:deleteMyCoverProp', -1, plate, propNetId)
    end

    -- Brief delay so prop deletion propagates before the vehicle is shown again.
    CreateThread(function()
        Wait(300)
        TriggerClientEvent('mnc-lift:restoreVehicle', -1,
            plate, savedX, savedY, savedVehZ, savedHeading)
    end)
end

-- ── Callbacks ─────────────────────────────────────────────────────────────────

lib.callback.register('mnc-lift:canCover', function(src, plate)
    plate = NormalisePlate(plate)

    if not PlayerOwnsVehicle(src, plate) then
        return false, 'You do not own this vehicle.'
    end
    -- Enforce: vehicle must be currently parked
    if not VehicleIsParked(plate) then
        return false, 'You can only cover a parked vehicle.'
    end
    if not HasItem(src, Config.Cover.CoverItem) then
        return false, ('You need a %s.'):format(Config.Cover.CoverItem)
    end
    if coverState[plate] then
        return false, 'Vehicle is already covered.'
    end
    return true, 'ok'
end)

lib.callback.register('mnc-lift:canUncover', function(src, plate)
    plate = NormalisePlate(plate)
    if not PlayerOwnsVehicle(src, plate) then
        return false, 'You do not own this vehicle.'
    end
    if not coverState[plate] then
        return false, 'Vehicle is not covered.'
    end
    return true, 'ok'
end)

lib.callback.register('mnc-lift:isCovered', function(src, plate)
    return coverState[NormalisePlate(plate)] ~= nil
end)

lib.callback.register('mnc-lift:getCoverNetId', function(src, plate)
    local c = coverState[NormalisePlate(plate)]
    return c and (c.netId or 0) or 0
end)

-- Returns position data needed by the client on reconnect/restart.
-- x, y, vehZ   → vehicle origin (used to snap & restore vehicle)
-- groundZ       → terrain Z (used only to re-place the prop)
-- heading       → vehicle heading
lib.callback.register('mnc-lift:getCoverPos', function(src, plate)
    local c = coverState[NormalisePlate(plate)]
    if not c then return nil end
    return {
        x       = c.coverX,
        y       = c.coverY,
        vehZ    = c.coverVehZ,
        groundZ = c.coverZ,
        heading = c.coverHeading,
    }
end)

-- Batch callback — returns full cover state for a list of plates in one
-- round-trip so the client never has to fire 3 sequential callbacks per plate.
-- Returns a table keyed by normalised plate:
--   [plate] = { covered=bool, netId=int, x, y, vehZ, groundZ, heading }
-- Plates that are not covered get { covered = false }.
lib.callback.register('mnc-lift:getCoverStateBatch', function(src, plates)
    local result = {}
    for _, plate in ipairs(plates or {}) do
        local p = NormalisePlate(plate)
        local c = coverState[p]
        if c then
            result[p] = {
                covered = true,
                netId   = c.netId   or 0,
                x       = c.coverX,
                y       = c.coverY,
                vehZ    = c.coverVehZ,
                groundZ = c.coverZ,
                heading = c.coverHeading,
            }
        else
            result[p] = { covered = false }
        end
    end
    return result
end)

-- ── Item registration ─────────────────────────────────────────────────────────

QBCore.Functions.CreateUseableItem(Config.Cover.CoverItem, function(src)
    TriggerClientEvent('mnc-lift:useVehicleTarp', src)
end)

-- ── COVER flow ────────────────────────────────────────────────────────────────
-- Step 1 — client triggers this to begin cover.
RegisterNetEvent('mnc-lift:coverVehicle', function(plate, vehicleNetId, propModel)
    local src = source
    plate = NormalisePlate(plate)

    -- Re-validate on the server before consuming the item
    if not PlayerOwnsVehicle(src, plate) then
        Notify(src, 'Cover', 'You do not own this vehicle.', 'error'); return
    end
    if not VehicleIsParked(plate) then
        Notify(src, 'Cover', 'You can only cover a parked vehicle.', 'error'); return
    end
    if not HasItem(src, Config.Cover.CoverItem) then
        Notify(src, 'Cover', ('You need a %s.'):format(Config.Cover.CoverItem), 'error'); return
    end
    if coverState[plate] then
        Notify(src, 'Cover', 'Vehicle is already covered.', 'error'); return
    end

    RemoveItem(src, Config.Cover.CoverItem, 1)

    -- Ask the client to spawn the prop and report back.
    TriggerClientEvent('mnc-lift:spawnCoverProp', src, plate, vehicleNetId or 0, propModel or '')
end)

-- Step 2 — client reports prop spawned + vehicle coords at cover time.
-- Args: plate, propNetId, groundZ, vehX, vehY, vehHeading, vehZ
RegisterNetEvent('mnc-lift:coverPropSpawned', function(plate, propNetId, groundZ,
                                                        vehX, vehY, vehHeading, vehZ)
    local src = source
    plate = NormalisePlate(plate)

    coverState[plate] = {
        netId        = propNetId,
        spawnerSrc   = src,
        coverZ       = groundZ,    -- terrain Z → prop placement only
        coverX       = vehX,
        coverY       = vehY,
        coverVehZ    = vehZ,       -- vehicle entity origin Z → used for restore
        coverHeading = vehHeading,
    }
    SaveCover(plate)

    if Config.Debug then
        print(('[mnc-parking] coverPropSpawned: plate=%s netId=%d src=%d')
            :format(plate, propNetId, src))
    end
end)

-- Prop spawn failed on client — refund the item.
RegisterNetEvent('mnc-lift:coverFailed', function(plate)
    local src = source
    GiveItem(src, Config.Cover.CoverItem, 1)
    Notify(src, 'Cover', 'Failed to place cover. Item refunded.', 'error')
end)

-- ── UNCOVER flow ──────────────────────────────────────────────────────────────
RegisterNetEvent('mnc-lift:uncoverVehicle', function(plate)
    local src = source
    plate = NormalisePlate(plate)

    if not PlayerOwnsVehicle(src, plate) then
        Notify(src, 'Cover', 'You do not own this vehicle.', 'error'); return
    end
    if not coverState[plate] then
        Notify(src, 'Cover', 'Vehicle is not covered.', 'error'); return
    end

    GiveItem(src, Config.Cover.CoverItem, 1)
    DoCoverTeardown(plate)
end)

-- ── PROP RE-REGISTRATION ──────────────────────────────────────────────────────
-- Client calls this after:
--   (a) re-spawning a dead prop on reconnect (new netId), OR
--   (b) adopting an already-live prop (same netId).
-- Always updates spawnerSrc so the server knows which client currently owns
-- the prop handle, and saves to DB.
RegisterNetEvent('mnc-lift:coverRespawned', function(plate, propNetId)
    local src = source
    plate = NormalisePlate(plate)

    if not coverState[plate] then
        if Config.Debug then
            print(('[mnc-parking] coverRespawned: no state for plate=%s, ignoring'):format(plate))
        end
        return
    end

    local existing = coverState[plate]
    coverState[plate] = {
        netId        = propNetId,
        spawnerSrc   = src,            -- always update to the current owner client
        coverZ       = existing.coverZ,
        coverX       = existing.coverX,
        coverY       = existing.coverY,
        coverVehZ    = existing.coverVehZ,
        coverHeading = existing.coverHeading,
    }
    SaveCover(plate)

    if Config.Debug then
        print(('[mnc-parking] coverRespawned: plate=%s netId=%d src=%d')
            :format(plate, propNetId, src))
    end
end)

-- ── Vehicle recalled — tear down cover cleanly ────────────────────────────────
AddEventHandler('mnc-parking:vehicleRecalled', function(plate)
    plate = NormalisePlate(plate)
    if coverState[plate] then
        DoCoverTeardown(plate)
    end
end)


QBCore.Functions.CreateUseableItem(Config.Cover.CoverRemoveItem, function(src)
    TriggerClientEvent('mnc-lift:useTarpBox', src)
end)

RegisterNetEvent('mnc-lift:useTarpBox', function()
    local src = source
    local plate = nil

    -- Find nearest vehicle (same logic as parking key)
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    local bestDist = Config.Cover.InteractDistance + 5.0
    local bestVehicle = nil

    for _, veh in ipairs(GetAllVehicles()) do
        if DoesEntityExist(veh) then
            local dist = #(pedCoords - GetEntityCoords(veh))
            if dist < bestDist then
                bestDist = dist
                bestVehicle = veh
            end
        end
    end

    if not bestVehicle then
        Notify(src, 'Vehicle Cover', 'No vehicle nearby.', 'error')
        return
    end

    plate = NormalisePlate(GetVehicleNumberPlateText(bestVehicle))

    -- Server validation
    if not PlayerOwnsVehicle(src, plate) then
        Notify(src, 'Vehicle Cover', 'You do not own this vehicle.', 'error')
        return
    end

    if not coverState[plate] then
        Notify(src, 'Vehicle Cover', 'This vehicle is not covered.', 'error')
        return
    end

    -- Consume the box item
    local hasBox = HasItem(src, Config.Cover.CoverRemoveItem)
    if not hasBox then
        Notify(src, 'Vehicle Cover', 'You do not have a Tarp Removal Box.', 'error')
        return
    end

    RemoveItem(src, Config.Cover.CoverRemoveItem, 1)

    -- Actually uncover (same as normal uncover but no tarp refund)
    DoCoverTeardown(plate)

    Notify(src, 'Vehicle Cover', 'Vehicle cover removed using Tarp Box.', 'success')
end)


if Config.Debug then print('^2[mnc-parking]^7 cover_server.lua loaded.') end