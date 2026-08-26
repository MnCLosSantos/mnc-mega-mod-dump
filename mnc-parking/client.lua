-- client.lua
local QBCore = nil

-- NOTE: these five tables are intentionally NOT `local`. trailer_client.lua
-- (loaded later, per fxmanifest.lua) shares them so trailers parked via the
-- stand-park flow go through the exact same despawn/respawn-aware tracking
-- as normally-driven parked vehicles (see RegisterStandParkedVehicle below).
-- Previously trailer_client.lua kept its own private copies of this state,
-- which meant a stand-parked trailer's move watcher never got re-armed
-- after the server's proximity system despawned + respawned it. Once that
-- happened once in a session, towing the trailer away went completely
-- undetected: no "moved" notify ever fired, the parked slot never cleared,
-- and the next player to walk near the old spot would trigger a fresh
-- respawn there while the towed copy got silently deleted.
parkedVehicles = {}   -- [plate] = { entity, data }
ownPlates      = {}   -- [plate] = true
syncTimers     = {}   -- [plate] = bool
moveWatchers   = {}   -- [plate] = bool
blipHandles    = {}   -- [plate] = blipHandle

local MOVE_THRESHOLD = 10.0

-- ============================================================
-- QBCore init
-- ============================================================
CreateThread(function()
    while not QBCore do
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbcore') == 'started' then
            local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and obj then
                QBCore = obj
                if Config.Debug then print('^2[mnc-parking]^7 QBCore loaded.') end
            end
        end
        Wait(500)
    end
end)

local ANIM_DICT = 'mini@repair'
local ANIM_CLIP = 'fixing_a_ped'
CreateThread(function()
    while GetResourceState('ox_lib') ~= 'started' do Wait(500) end
    RequestAnimDict(ANIM_DICT)
    while not HasAnimDictLoaded(ANIM_DICT) do Wait(0) end
end)

-- ============================================================
-- Helpers
-- ============================================================
local function Notify(title, description, ntype, duration)
    lib.notify({
        title       = title or 'Parking',
        description = description,
        type        = ntype   or 'inform',
        duration    = duration or 5000,
    })
end

local function NormalisePlate(plate)
    return string.upper((plate or ''):gsub('%s+', ''))
end


RegisterNetEvent('mnc-parking:cleanupStrayVehicles', function(plates)
    if not plates or #plates == 0 then return end
    local wanted = {}
    for _, p in ipairs(plates) do wanted[NormalisePlate(p)] = true end

    CreateThread(function()
        for _, v in ipairs(GetGamePool('CVehicle')) do
            if DoesEntityExist(v) then
                local plate = NormalisePlate(GetVehicleNumberPlateText(v))
                if wanted[plate] then
                    if Config.Debug then
                        print('^3[mnc-parking]^7 cleanupStrayVehicles: found stray plate=' ..
                              plate .. ' entity=' .. v)
                    end

                    -- Take control if we don't already have it — required to
                    -- reliably delete a networked entity we didn't spawn.
                    if NetworkGetEntityOwner(v) ~= PlayerId() then
                        NetworkRequestControlOfEntity(v)
                        local waited = 0
                        while not NetworkHasControlOfEntity(v) and waited < 2000 do
                            Wait(50); waited = waited + 50
                        end
                    end

                    if DoesEntityExist(v) then
                        SetEntityAsMissionEntity(v, true, true)
                        DeleteEntity(v)
                        TriggerServerEvent('mnc-parking:strayVehicleRemoved', plate)
                    end
                end
            end
        end
    end)
end)

local function GetVehicleProps(vehicle)
    local props = QBCore.Functions.GetVehicleProperties(vehicle)
    local doorStates = {}
    for i = 0, 5 do
        local angle = GetVehicleDoorAngleRatio(vehicle, i)
        doorStates[tostring(i)] = angle > 0.1 and angle or 0.0
    end
    props._doorStates = doorStates
    return props
end

local function SetVehicleProps(vehicle, props)
    if not props then return end
    local doorStates = props._doorStates
    props._doorStates = nil
    QBCore.Functions.SetVehicleProperties(vehicle, props)
    props._doorStates = doorStates
    if doorStates then
        CreateThread(function()
            Wait(2500)
            if not DoesEntityExist(vehicle) then return end
            for idxStr, angle in pairs(doorStates) do
                local idx = tonumber(idxStr)
                if angle and angle > 0.1 then
                    SetVehicleDoorOpen(vehicle, idx, false, false)
                else
                    SetVehicleDoorShut(vehicle, idx, false)
                end
            end
        end)
    end
end

-- ============================================================
-- Blip helpers
-- ============================================================
local function CreateParkingBlip(plate, coords)
    if not Config.Blip.Enabled then return end
    if blipHandles[plate] then RemoveBlip(blipHandles[plate]) end
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.Blip.Sprite)
    SetBlipScale(blip, Config.Blip.Scale)
    SetBlipColour(blip, Config.Blip.Colour)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Parked: ' .. plate)
    EndTextCommandSetBlipName(blip)
    blipHandles[plate] = blip
end

local function ClearBlip(plate)
    if blipHandles[plate] then
        RemoveBlip(blipHandles[plate])
        blipHandles[plate] = nil
    end
end

-- ============================================================
-- Sync timer / move watcher
-- ============================================================
local function StartSyncTimer(plate)
    if syncTimers[plate] then return end
    syncTimers[plate] = true
    CreateThread(function()
        while syncTimers[plate] do
            Wait(Config.SaveInterval)
            if not syncTimers[plate] then break end
            local entry = parkedVehicles[plate]
            if not entry or not entry.entity or not DoesEntityExist(entry.entity) then
                syncTimers[plate] = nil; break
            end
            local v      = entry.entity
            local coords = GetEntityCoords(v)
            TriggerServerEvent('mnc-parking:updateVehicleState',
                plate,
                { x=coords.x, y=coords.y, z=coords.z },
                GetEntityHeading(v),
                json.encode(GetVehicleProps(v)),
                math.max(0.0, math.min(100.0, GetVehicleFuelLevel(v))),
                GetVehicleEngineHealth(v),
                GetVehicleBodyHealth(v))
        end
    end)
end

local function StopSyncTimer(plate) syncTimers[plate] = nil end

local function StartMoveWatcher(plate, savedCoords)
    if moveWatchers[plate] then return end
    moveWatchers[plate] = true
    CreateThread(function()
        while moveWatchers[plate] do
            Wait(5000)
            if not moveWatchers[plate] then break end
            local entry = parkedVehicles[plate]
            if not entry or not entry.entity or not DoesEntityExist(entry.entity) then
                moveWatchers[plate] = nil; break
            end
            local cur  = GetEntityCoords(entry.entity)
            local dist = #(vector3(cur.x, cur.y, cur.z) -
                           vector3(savedCoords.x, savedCoords.y, savedCoords.z))
            if dist > MOVE_THRESHOLD then
                moveWatchers[plate] = nil
                lib.callback.await('mnc-parking:vehicleMoved', false, plate)
                break
            end
        end
    end)
end

local function StopMoveWatcher(plate) moveWatchers[plate] = nil end

-- ============================================================
-- Register a vehicle that was parked by standing next to it
-- (trailer_client.lua's stand-park flow, e.g. trailers with no
-- seats). Routes it through the exact same tracking as a normally
-- driven parked vehicle so it gets the same despawn/respawn-aware
-- sync timer, move watcher, and blip. This matters because the
-- server's proximity streaming system periodically despawns and
-- respawns ANY parked vehicle (see server.lua's
-- ParkingDespawnDistance / ParkingSpawnDistance sweep), and only a
-- vehicle marked in `ownPlates` gets its watcher re-armed by the
-- spawnVehicle handler after that happens.
-- ============================================================
function RegisterStandParkedVehicle(entity, plate, data)
    plate = NormalisePlate(plate)
    ownPlates[plate]      = true
    parkedVehicles[plate] = { entity = entity, data = data }

    CreateParkingBlip(plate, data.coords)
    StartSyncTimer(plate)
    StartMoveWatcher(plate, data.coords)
end

-- ============================================================
-- Server tells us a parked vehicle is no longer needed nearby
-- (no player close enough) — find it and delete it cleanly.
-- Broadcast to everyone; whichever client actually has it
-- streamed in is the one that will find it and act.
-- ============================================================
RegisterNetEvent('mnc-parking:despawnVehicle', function(plate, netId)
    plate = NormalisePlate(plate)

    CreateThread(function()
        local entity = (netId and netId ~= 0 and NetworkDoesNetworkIdExist(netId))
            and NetworkGetEntityFromNetworkId(netId) or nil

        if not entity or entity == 0 or not DoesEntityExist(entity) then
            for _, v in ipairs(GetGamePool('CVehicle')) do
                if DoesEntityExist(v) and NormalisePlate(GetVehicleNumberPlateText(v)) == plate then
                    entity = v; break
                end
            end
        end
        if not entity or entity == 0 or not DoesEntityExist(entity) then return end

        if NetworkGetEntityOwner(entity) ~= PlayerId() then
            NetworkRequestControlOfEntity(entity)
            local waited = 0
            while not NetworkHasControlOfEntity(entity) and waited < 1500 do
                Wait(50); waited = waited + 50
            end
        end

        if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
            SetEntityAsMissionEntity(entity, true, true)
            DeleteEntity(entity)
            TriggerServerEvent('mnc-parking:vehicleDespawnedAck', plate)
        end
    end)

    StopSyncTimer(plate)
    StopMoveWatcher(plate)
    if parkedVehicles[plate] then parkedVehicles[plate].entity = nil end
end)

-- ============================================================
-- Resolve a netId to a local entity handle, waiting up to
-- maxWait ms for it to replicate to this client.
-- ============================================================
local function ResolveNetId(netId, maxWait)
    maxWait = maxWait or 5000
    local waited = 0
    while waited < maxWait do
        if NetworkDoesNetworkIdExist(netId) then
            local entity = NetworkGetEntityFromNetworkId(netId)
            if DoesEntityExist(entity) and entity ~= 0 then
                return entity
            end
        end
        Wait(100)
        waited = waited + 100
    end
    return nil
end

-- ============================================================
-- Wait until this client is the network owner of an entity,
-- or until maxWait ms elapses. Returns true if we own it.
-- ============================================================
local function WaitForOwnership(entity, maxWait)
    maxWait = maxWait or 5000
    local waited = 0
    while NetworkGetEntityOwner(entity) ~= PlayerId() and waited < maxWait do
        Wait(100)
        waited = waited + 100
    end
    return NetworkGetEntityOwner(entity) == PlayerId()
end

-- ============================================================
-- Core: apply all props/mods/fuel/health to an entity.
-- Caller is responsible for ensuring network ownership first.
-- ============================================================
local function ApplyVehicleData(entity, data)
    local plate = NormalisePlate(data.plate)

    local props
    if type(data.props) == 'string' then
        local ok, decoded = pcall(json.decode, data.props)
        props = (ok and type(decoded) == 'table') and decoded or nil
    elseif type(data.props) == 'table' then
        props = data.props
    end

    local fuel   = math.max(0.0, math.min(100.0,  tonumber(data.fuel)   or 100.0))
    local engine = math.max(0.0, math.min(1000.0, tonumber(data.engine) or 1000.0))
    local body   = math.max(0.0, math.min(1000.0, tonumber(data.body)   or 1000.0))

    -- Plate text is always safe
    SetVehicleNumberPlateText(entity, data.plate)

    if props then SetVehicleProps(entity, props) end
    SetVehicleFuelLevel(entity, fuel)
    SetVehicleEngineHealth(entity, engine)
    SetVehicleBodyHealth(entity, body)

    -- Re-confirm health values next frame (some prop setters reset them)
    Wait(0)
    if DoesEntityExist(entity) then
        SetVehicleFuelLevel(entity, fuel)
        SetVehicleEngineHealth(entity, engine)
        SetVehicleBodyHealth(entity, body)
    end

    if Config.Debug then
        print('^2[mnc-parking]^7 ApplyVehicleData plate=' .. plate ..
              ' entity=' .. entity ..
              ' owner=' .. tostring(NetworkGetEntityOwner(entity)) ..
              ' fuel=' .. fuel .. ' engine=' .. engine .. ' body=' .. body)
    end
end

-- ============================================================
-- Configure a server-spawned vehicle that this player OWNS.
-- Waits for network ownership then applies all props.
-- Also sets up blips, sync timers, move watchers, and keys.
-- ============================================================
local function ConfigureOwnVehicle(entity, data)
    local plate  = NormalisePlate(data.plate)
    local coords = data.coords

    parkedVehicles[plate]        = parkedVehicles[plate] or {}
    parkedVehicles[plate].entity = entity
    parkedVehicles[plate].data   = data

    CreateThread(function()
        local owned = WaitForOwnership(entity, 6000)
        if not DoesEntityExist(entity) then return end

        if owned then
            ApplyVehicleData(entity, data)
        else
            -- Didn't get ownership within 6 s — still set plate text at least
            SetVehicleNumberPlateText(entity, data.plate)
            if Config.Debug then
                print('^3[mnc-parking]^7 Could not get ownership for own plate=' .. plate ..
                      ' — props not applied.')
            end
        end
    end)

    TriggerServerEvent('mnc-parking:giveKeys', plate)
    CreateParkingBlip(plate, coords)
    StartSyncTimer(plate)
    StartMoveWatcher(plate, coords)

    -- Lock
    CreateThread(function()
        Wait(600)
        if not DoesEntityExist(entity) then return end
        SetVehicleDoorsLocked(entity, 2)
        TriggerServerEvent('mnc-parking:lockParkedVehicle', plate,
            NetworkGetNetworkIdFromEntity(entity))
    end)
end

-- ============================================================
-- Register a known own vehicle WITHOUT re-applying props.
-- Used when the server reports netId=-1 (props already applied
-- this session). We still set up blips/sync/watchers.
-- ============================================================
local function RegisterOwnVehicleNoReapply(entity, data)
    local plate  = NormalisePlate(data.plate)
    local coords = data.coords

    parkedVehicles[plate]        = parkedVehicles[plate] or {}
    parkedVehicles[plate].entity = entity
    parkedVehicles[plate].data   = data

    -- Always confirm plate text — cheap and safe from any client
    SetVehicleNumberPlateText(entity, data.plate)

    CreateParkingBlip(plate, coords)
    StartSyncTimer(plate)
    StartMoveWatcher(plate, coords)

    if Config.Debug then
        print('^2[mnc-parking]^7 RegisterNoReapply plate=' .. plate ..
              ' (props already in world)')
    end
end

-- ============================================================
-- Server asks this client to spawn a parked vehicle.
-- Done client-side so addon (client-stream-only) models work.
-- We spawn, apply all props as owner, make it networked,
-- then report the netId back to the server.
-- ============================================================
RegisterNetEvent('mnc-parking:spawnVehicle', function(data)
    local plate   = NormalisePlate(data.plate)
    local coords  = data.coords
    local heading = data.heading or 0.0
    local isOwner = ownPlates[plate]

    if Config.Debug then
        print('^2[mnc-parking]^7 spawnVehicle: plate=' .. plate ..
              ' model=' .. data.model .. ' isOwner=' .. tostring(isOwner))
    end

    CreateThread(function()
        local hash = GetHashKey(data.model)
        if not IsModelValid(hash) then
            print('^1[mnc-parking]^7 spawnVehicle: invalid model=' .. data.model)
            TriggerServerEvent('mnc-parking:vehicleSpawned', plate, 0, false)
            return
        end

        RequestModel(hash)
        local waited = 0
        while not HasModelLoaded(hash) and waited < 10000 do
            Wait(100); waited = waited + 100
        end
        if not HasModelLoaded(hash) then
            print('^1[mnc-parking]^7 spawnVehicle: model load timeout=' .. data.model)
            TriggerServerEvent('mnc-parking:vehicleSpawned', plate, 0, false)
            return
        end

        local entity = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
        SetModelAsNoLongerNeeded(hash)

        if not entity or entity == 0 or not DoesEntityExist(entity) then
            print('^1[mnc-parking]^7 spawnVehicle: CreateVehicle failed for plate=' .. plate)
            TriggerServerEvent('mnc-parking:vehicleSpawned', plate, 0, false)
            return
        end

        -- Make it a persistent networked entity visible to all clients
        NetworkRegisterEntityAsNetworked(entity)
        SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(entity), true)
        SetEntityAsMissionEntity(entity, true, true)

        local netId = NetworkGetNetworkIdFromEntity(entity)

        -- Apply props — we own it so SetVehicleProperties works fully
        ApplyVehicleData(entity, data)

        parkedVehicles[plate]        = parkedVehicles[plate] or {}
        parkedVehicles[plate].entity = entity
        parkedVehicles[plate].data   = data

        if isOwner then
            TriggerServerEvent('mnc-parking:giveKeys', plate)
            CreateParkingBlip(plate, coords)
            StartSyncTimer(plate)
            StartMoveWatcher(plate, coords)
        end

        CreateThread(function()
            Wait(600)
            if DoesEntityExist(entity) then
                SetVehicleDoorsLocked(entity, 2)
                TriggerServerEvent('mnc-parking:lockParkedVehicle', plate, netId)
            end
        end)

        -- Release scripted ownership so entity isn't pinned to this client
        SetEntityAsMissionEntity(entity, false, true)

        TriggerServerEvent('mnc-parking:vehicleSpawned', plate, netId, true)

        if Config.Debug then
            print('^2[mnc-parking]^7 spawnVehicle done: plate=' .. plate .. ' netId=' .. netId)
        end
    end)
end)

-- ============================================================
-- Server pushes:
--   allList   = every parked vehicle (for awareness)
--   ownList   = this player's own parked vehicles
--   netIdMap  = { [plate] = netId  } — own vehicles needing props applied
--               { [plate] = -1     } — own vehicles where props are already done
--
-- We ONLY configure own vehicles.
-- Non-owner vehicles are left entirely alone — the server handles
-- asking someone to apply their props via applyPropsForPlate.
-- ============================================================
RegisterNetEvent('mnc-parking:loadParkedVehicles', function(allList, ownList, netIdMap)
    if not allList then return end
    netIdMap = netIdMap or {}

    for plate, _ in pairs(parkedVehicles) do
        StopSyncTimer(plate)
        StopMoveWatcher(plate)
        ClearBlip(plate)
    end
    parkedVehicles = {}
    ownPlates      = {}

    if ownList then
        for _, data in ipairs(ownList) do
            ownPlates[NormalisePlate(data.plate)] = true
        end
    end

    -- Build lookup: plate → data for own vehicles
    local ownDataByPlate = {}
    for _, data in ipairs(ownList or {}) do
        ownDataByPlate[NormalisePlate(data.plate)] = data
    end

    Wait(500)

    for plate, netId in pairs(netIdMap) do
        plate = NormalisePlate(plate)
        local data = ownDataByPlate[plate]
        if not data then
            if Config.Debug then
                print('^3[mnc-parking]^7 loadParkedVehicles: no data for own plate=' .. plate)
            end
        elseif netId == -1 then
            -- Props already applied — just register blips/sync, no prop application
            CreateThread(function()
                -- We still need the entity handle for sync timer / move watcher.
                -- Find it by searching the game pool for matching plate text.
                -- We don't have the netId here so we scan — this is a one-time
                -- cost on join, not a loop.
                local found = nil
                local deadline = GetGameTimer() + 10000
                while not found and GetGameTimer() < deadline do
                    for _, v in ipairs(GetGamePool('CVehicle')) do
                        if NormalisePlate(GetVehicleNumberPlateText(v)) == plate then
                            found = v
                            break
                        end
                    end
                    if not found then Wait(500) end
                end
                if found then
                    RegisterOwnVehicleNoReapply(found, data)
                else
                    if Config.Debug then
                        print('^3[mnc-parking]^7 Could not find entity for plate=' .. plate ..
                              ' (no-reapply path) — blips/sync not started.')
                    end
                end
            end)
        else
            -- Normal path: resolve netId and apply props as owner
            CreateThread(function()
                local entity = ResolveNetId(netId, 10000)
                if entity then
                    ConfigureOwnVehicle(entity, data)
                else
                    if Config.Debug then
                        print('^1[mnc-parking]^7 Could not resolve netId=' .. netId ..
                              ' for own plate=' .. plate)
                    end
                end
            end)
        end
    end
end)

-- ============================================================
-- Vehicle recalled (server deleted entity, clean up local state)
-- ============================================================
RegisterNetEvent('mnc-parking:vehicleRecalled', function(plate)
    plate = NormalisePlate(plate)
    StopSyncTimer(plate)
    StopMoveWatcher(plate)
    ClearBlip(plate)
    parkedVehicles[plate] = nil
    ownPlates[plate]      = nil
end)

-- ============================================================
-- Vehicle untracked (driven away)
-- ============================================================
RegisterNetEvent('mnc-parking:vehicleUntracked', function(plate)
    plate = NormalisePlate(plate)
    StopSyncTimer(plate)
    StopMoveWatcher(plate)
    ClearBlip(plate)
    parkedVehicles[plate] = nil
    ownPlates[plate]      = nil
end)

-- ============================================================
-- Notify event
-- ============================================================
RegisterNetEvent('mnc-parking:notify', function(data)
    lib.notify({
        title       = data.title or 'Parking',
        description = data.description,
        type        = data.type or 'inform',
        duration    = data.duration or 5000,
    })
end)

-- ============================================================
-- Use parking_lock item
-- ============================================================
RegisterNetEvent('mnc-parking:useItem', function()
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        local pedPos   = GetEntityCoords(ped)
        local bestDist = Config.InteractDistance
        for _, v in ipairs(GetGamePool('CVehicle')) do
            local d = #(pedPos - GetEntityCoords(v))
            if d < bestDist then vehicle = v; bestDist = d end
        end
    end

    if vehicle == 0 then
        Notify('Parking Lock', 'No vehicle nearby to install the lock on.', 'error')
        return
    end

    local plate = NormalisePlate(GetVehicleNumberPlateText(vehicle))

    -- Boats constantly rock/drift on water even when "stationary", which trips
    -- ox_lib's move/car disable checks and auto-cancels the progress bar.
    -- Drop those disables (and the anim, which can look wrong on water) for boats.
    local isBoat = GetVehicleClass(vehicle) == 14
    local disableFlags = isBoat
        and { combat = true }
        or  { car = true, move = true, combat = true }

    local done = lib.progressBar({
        duration     = 4000,
        label        = 'Installing Parking Lock...',
        useWhileDead = false,
        canCancel    = true,
        disable      = disableFlags,
        anim         = not isBoat and { dict = ANIM_DICT, clip = ANIM_CLIP } or nil,
    })

    if done then
        TriggerServerEvent('mnc-parking:installLock', plate)
    else
        Notify('Parking Lock', 'Installation cancelled.', 'error')
    end
end)

-- ============================================================
-- No-Park Zone check
-- Returns the zone label if coords fall inside a restricted zone, else nil.
-- ============================================================
local function GetNoParkZone(pos)
    for _, zone in ipairs(Config.NoParkZones or {}) do
        if #(vector3(pos.x, pos.y, pos.z) - zone.coords) <= zone.radius then
            return zone.label or 'this area'
        end
    end
    return nil
end

-- ============================================================
-- /park command
-- ============================================================
local function ParkCurrentVehicle()
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        if ParkNearbyUnseatableVehicle then
            ParkNearbyUnseatableVehicle()
        else
            Notify('Parking', 'You must be inside a vehicle to park it.', 'error')
        end
        return
    end
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        Notify('Parking', 'You must be the driver to park this vehicle.', 'error'); return
    end

    local plate = NormalisePlate(GetVehicleNumberPlateText(vehicle))
    if parkedVehicles[plate] and parkedVehicles[plate].entity then
        Notify('Parking', 'This vehicle is already in your parked list.', 'error'); return
    end

    -- ── No-park zone check — runs before the confirmation dialog ──────────
    local vehCoords = GetEntityCoords(vehicle)
    local zoneName  = GetNoParkZone(vehCoords)
    if zoneName then
        Notify('Parking', ('You cannot park here — %s is a restricted area.'):format(zoneName), 'error')
        return
    end

    local hash      = GetEntityModel(vehicle)
    local modelName = ''
    for name in pairs(QBCore.Shared.Vehicles or {}) do
        if GetHashKey(name) == hash then modelName = name; break end
    end
    if modelName == '' then
        modelName = string.lower(GetDisplayNameFromVehicleModel(hash))
    end

    local coords  = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)
    local props   = GetVehicleProps(vehicle)
    local fuel    = math.max(0.0, math.min(100.0, GetVehicleFuelLevel(vehicle)))
    local engine  = GetVehicleEngineHealth(vehicle)
    local body    = GetVehicleBodyHealth(vehicle)

    local confirmed = lib.alertDialog({
        header = 'Park Vehicle',
        content = 
            'Park **' .. plate .. '** (' .. modelName .. ') here?\n\n' ..
            '**Fuel:** ' .. math.floor(fuel) .. '%  |  ' ..
            '**Engine:** ' .. math.floor(engine/10) .. '%  |  ' ..
            '**Body:** ' .. math.floor(body/10) .. '%\n\n' ..
            '**IMPORTANT:**\n' ..
            'If you pull this vehicle back out of the ***depot/impound*** later,\n' ..
            '***all modifications / tuning will be wiped / reset***.\n\n' ..
            '**HOW TO KEEP YOUR MODS**:\n\n' ..
            '• Return the vehicle through the ***/parked*** menu option for it to be in ***depot instantly***\n\n' ..
            '• Move from parking place by driving it and wait for the next ***server restart***\n\n' ..
			'• Once either has been done vehicles should be in depot ***(impound)***\n\n' ..
            'Are you sure you want to park it here anyway?',
        centered = true,
        cancel = true,
    })
    if confirmed ~= 'confirm' then return end

    local entityNetId = NetworkGetNetworkIdFromEntity(vehicle)

    local ok, msg, maxSlots = lib.callback.await('mnc-parking:parkVehicle',
        false,
        plate, modelName,
        { x=coords.x, y=coords.y, z=coords.z },
        heading, json.encode(props), fuel, engine, body,
        entityNetId)

    if not ok then
        Notify('Parking', msg, 'error'); return
    end

    ownPlates[plate]      = true
    parkedVehicles[plate] = { entity=vehicle, data={
        plate=plate, model=modelName,
        coords={ x=coords.x, y=coords.y, z=coords.z },
        heading=heading, props=json.encode(props),
        fuel=fuel, engine=engine, body=body,
    }}

    CreateParkingBlip(plate, { x=coords.x, y=coords.y, z=coords.z })
    StartSyncTimer(plate)
    StartMoveWatcher(plate, { x=coords.x, y=coords.y, z=coords.z })
    TriggerServerEvent('mnc-parking:giveKeys', plate)

    local count = 0
    for _ in pairs(ownPlates) do count = count + 1 end
    local displayMax = maxSlots or Config.MaxVehiclesOut
    Notify('Parking', ('Vehicle parked! (%d/%d slots used)'):format(
        count, displayMax), 'success')
end

-- ============================================================
-- Recall vehicle from menu
-- ============================================================
local function RecallVehicle(plate)
    plate = NormalisePlate(plate)
    local ok, msg = lib.callback.await('mnc-parking:recallVehicle', false, plate)
    if not ok then
        Notify('Parking', tostring(msg), 'error'); return
    end
    Notify('Parking', tostring(msg), 'success')
end

-- ============================================================
-- Parked vehicles menu
-- ============================================================
local function OpenParkingMenu()
    local list, maxSlots = lib.callback.await('mnc-parking:getParkedVehicles', false)
    maxSlots = maxSlots or Config.MaxVehiclesOut
    if not list or #list == 0 then
        Notify('Parking', 'You have no parked vehicles.', 'inform'); return
    end

    local options = {}
    for _, data in ipairs(list) do
        local plate  = NormalisePlate(data.plate)
        local label  = (QBCore.Shared.Vehicles
                        and QBCore.Shared.Vehicles[data.model]
                        and QBCore.Shared.Vehicles[data.model].name)
                       or data.model
        local coords = data.coords

        local enginePct = math.floor((data.engine or 1000) / 10)
        local bodyPct   = math.floor((data.body   or 1000) / 10)
        local avg       = math.floor((enginePct + bodyPct) / 2)
        local condition
        if avg >= 90 then condition = 'Excellent'
        elseif avg >= 70 then condition = 'Good'
        elseif avg >= 40 then condition = 'Fair'
        else condition = 'Poor' end

        local p, l, c = plate, label, coords
        options[#options+1] = {
            title       = l .. ' — ' .. p,
            description = ('Condition: %s | Fuel: %d%%'):format(condition, math.floor(data.fuel or 100)),
            icon        = 'car',
            onSelect    = function()
                lib.registerContext({
                    id      = 'mnc_parking_sub_' .. p,
                    title   = l .. ' (' .. p .. ')',
                    options = {
                        {
                            title='Set Waypoint',
                            description='Mark this vehicle on your map.',
                            icon='map-marker-alt',
                            onSelect=function()
                                SetNewWaypoint(c.x, c.y)
                                Notify('Parking', 'Waypoint set.', 'success')
                            end,
                        },
                        {
                            title='Get Keys',
                            description='Re-issue keys for this vehicle.',
                            icon='key',
                            onSelect=function()
                                TriggerServerEvent('mnc-parking:giveKeys', p)
                                Notify('Parking', 'Keys re-issued for '..p..'.', 'success')
                            end,
                        },
                        {
                            title='Recall Vehicle',
                            description='Remove from parked list and send to garage.',
                            icon='trash-alt',
                            onSelect=function() RecallVehicle(p) end,
                        },
                    },
                })
                lib.showContext('mnc_parking_sub_' .. p)
            end,
        }
    end

    local ownCount = 0
    for _ in pairs(ownPlates) do ownCount = ownCount + 1 end

    lib.registerContext({
        id      = 'mnc_parking_menu',
        title   = ('My Parked Vehicles (%d/%d)'):format(ownCount, maxSlots),
        options = options,
    })
    lib.showContext('mnc_parking_menu')
end

-- ============================================================
-- Register commands
-- ============================================================
CreateThread(function()
    while not QBCore do Wait(500) end
    for _, cmd in ipairs(Config.Commands) do
        RegisterCommand(cmd, function() OpenParkingMenu() end, false)
    end
    RegisterCommand('park', function() ParkCurrentVehicle() end, false)
    if Config.Debug then print('^2[mnc-parking]^7 Commands registered.') end
end)

RegisterKeyMapping('park', 'Park Current Vehicle', 'keyboard', '')

-- ============================================================
-- Final save on resource stop
-- ============================================================
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for plate, entry in pairs(parkedVehicles) do
        if ownPlates[plate] and entry.entity and DoesEntityExist(entry.entity) then
            StopMoveWatcher(plate)
            local v      = entry.entity
            local coords = GetEntityCoords(v)
            TriggerServerEvent('mnc-parking:updateVehicleState',
                plate,
                { x=coords.x, y=coords.y, z=coords.z },
                GetEntityHeading(v),
                json.encode(GetVehicleProps(v)),
                math.max(0.0, math.min(100.0, GetVehicleFuelLevel(v))),
                GetVehicleEngineHealth(v),
                GetVehicleBodyHealth(v))
        end
    end
end)

-- ============================================================
-- Use parking_key item — removes a parking lock from a vehicle
-- ============================================================
RegisterNetEvent('mnc-parking:useKeyItem', function()
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        local pedPos   = GetEntityCoords(ped)
        local bestDist = Config.InteractDistance
        for _, v in ipairs(GetGamePool('CVehicle')) do
            local d = #(pedPos - GetEntityCoords(v))
            if d < bestDist then vehicle = v; bestDist = d end
        end
    end

    if vehicle == 0 then
        Notify('Parking Key', 'No vehicle nearby to remove the lock from.', 'error')
        return
    end

    local plate = NormalisePlate(GetVehicleNumberPlateText(vehicle))

    -- Same fix as installLock: boats rock/drift on water even when "stationary",
    -- which trips ox_lib's move/car disable checks and auto-cancels the bar.
    local isBoat = GetVehicleClass(vehicle) == 14
    local disableFlags = isBoat
        and { combat = true }
        or  { car = true, move = true, combat = true }

    local done = lib.progressBar({
        duration     = 4000,
        label        = 'Removing Parking Lock...',
        useWhileDead = false,
        canCancel    = true,
        disable      = disableFlags,
        anim         = not isBoat and { dict = ANIM_DICT, clip = ANIM_CLIP } or nil,
    })

    if done then
        TriggerServerEvent('mnc-parking:removeLock', plate)
    else
        Notify('Parking Key', 'Removal cancelled.', 'error')
    end
end)

RegisterNetEvent('mnc-parking:clearAll', function()
    for plate, _ in pairs(ownPlates) do
        StopSyncTimer(plate)
        StopMoveWatcher(plate)
        ClearBlip(plate)
    end
    parkedVehicles = {}
    ownPlates      = {}
end)

if Config.Debug then print('^2[mnc-parking]^7 Client loaded.') end