-- cover_client.lua  (rewrite)
-- ──────────────────────────────────────────────────────────────────────────────
-- Handles: vehicle_tarp item, cover prop spawn/delete, uncover restore.
--
-- Key design principles:
--   • vehicle_tarp can ONLY be used on a parked vehicle  (server validates too).
--   • On reconnect/restart, the client waits up to 15 s for the parked vehicle
--     to appear before attempting to re-spawn or adopt its cover prop.
--   • All prop ownership is tracked by plate, not just netId, so stale netIds
--     from a previous session never accidentally delete the wrong prop.
--   • groundZ is used ONLY to place the prop flush with terrain.
--     vehZ (the vehicle entity origin Z) is saved separately and used to
--     restore the vehicle to the correct height on uncover.
-- ──────────────────────────────────────────────────────────────────────────────

local QBCore    = nil
local ANIM_DICT = 'mini@repair'
local ANIM_CLIP = 'fixing_a_ped'

-- qb-target zone IDs registered by this client: [plate] = netId
local registeredCovers = {}

-- Props spawned/adopted by THIS client: [netId] = entity handle
local myProps = {}

-- ── Init ──────────────────────────────────────────────────────────────────────

CreateThread(function()
    while not QBCore do
        local resource = GetResourceState('qb-core') == 'started' and 'qb-core'
                      or GetResourceState('qbcore')  == 'started' and 'qbcore'
                      or nil
        if resource then
            local ok, obj = pcall(function() return exports[resource]:GetCoreObject() end)
            if ok and obj then QBCore = obj end
        end
        Wait(500)
    end
end)

CreateThread(function()
    while GetResourceState('ox_lib') ~= 'started' do Wait(500) end
    RequestAnimDict(ANIM_DICT)
    while not HasAnimDictLoaded(ANIM_DICT) do Wait(0) end
end)

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function Notify(title, description, ntype, duration)
    lib.notify({ title       = title or 'Cover',
                 description = description,
                 type        = ntype or 'inform',
                 duration    = duration or 5000 })
end

local function NormalisePlate(plate)
    return string.upper((plate or ''):gsub('%s+', ''))
end

-- Returns zone label if pos is inside a no-park zone, otherwise nil.
local function GetNoParkZone(pos)
    for _, zone in ipairs(Config.NoParkZones or {}) do
        if #(vector3(pos.x, pos.y, pos.z) - zone.coords) <= zone.radius then
            return zone.label or 'this area'
        end
    end
    return nil
end

-- Returns the closest visible non-occupied vehicle within interact distance.
local function GetNearestVehicle()
    local ped     = PlayerPedId()
    local pedPos  = GetEntityCoords(ped)
    local best, bestDist = nil, Config.Cover.InteractDistance
    if IsPedInAnyVehicle(ped, false) then return nil end
    for _, v in ipairs(GetGamePool('CVehicle')) do
        if IsEntityVisible(v) then   -- skip already-hidden (covered) vehicles
            local d = #(pedPos - GetEntityCoords(v))
            if d < bestDist then best = v; bestDist = d end
        end
    end
    return best
end

-- Load a model; returns the hash on success or nil after 5 s timeout.
local function LoadModel(model)
    local hash = GetHashKey(model)
    if not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local waited = 0
    while not HasModelLoaded(hash) and waited < 5000 do
        Wait(100); waited = waited + 100
    end
    return HasModelLoaded(hash) and hash or nil
end

-- Cast from above the vehicle to find true terrain Z.
local function GetGroundZ(x, y, z)
    local found, gz = GetGroundZFor_3dCoord(x, y, z + 20.0, false)
    return found and gz or z
end

-- Animated progress bar; returns true when completed, false if cancelled.
local function DoWorkAnim(label, duration)
    return lib.progressBar({
        duration     = duration,
        label        = label,
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = ANIM_DICT, clip = ANIM_CLIP, flag = 1 },
    })
end

-- Spawn a fully networked, frozen object. Returns netId or nil.
local function SpawnProp(model, x, y, z, heading)
    local hash = LoadModel(model)
    if not hash then return nil end
    local obj = CreateObject(hash, x, y, z, true, true, false)
    SetEntityHeading(obj, heading)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(hash)
    NetworkRegisterEntityAsNetworked(obj)
    SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(obj), true)
    SetEntityAsMissionEntity(obj, true, true)
    local netId = NetworkGetNetworkIdFromEntity(obj)
    myProps[netId] = obj
    return netId
end

-- Delete a prop this client owns; tries the cached handle first, then resolves
-- from the netId if the cache is stale.
local function DeleteMyProp(netId)
    if not netId or netId == 0 then return end
    local entity = myProps[netId]
    myProps[netId] = nil

    if not entity then
        if NetworkDoesNetworkIdExist(netId) then
            entity = NetworkGetEntityFromNetworkId(netId)
        end
    end
    if not entity or not DoesEntityExist(entity) then return end

    SetEntityAsMissionEntity(entity, false, false)
    pcall(function() exports['qb-target']:RemoveTargetEntity(entity) end)

    for _ = 1, 5 do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
            Wait(50)
        else
            break
        end
    end

    if Config.Debug and DoesEntityExist(entity) then
        print('[mnc-parking] WARNING: could not delete cover prop entity=' .. entity)
    end
end

-- Choose cover prop model by GTA vehicle class, falling back to config default.
local function GetCoverPropModel(vehicle)
    local class = GetVehicleClass(vehicle)
    local model = Config.Cover.CoverProps and Config.Cover.CoverProps[class]
    if not model or model == '' then
        model = Config.Cover.FallbackCoverProp or 'prop_tarp_wrap_01'
    end
    return model
end

-- ── qb-target zone management ─────────────────────────────────────────────────

-- Register an "Uncover Vehicle" target zone on the prop for this plate.
-- Always removes any stale zone first so re-covering after uncovering works.
local function RegisterCoverTarget(plate, coverNetId)
    if registeredCovers[plate] then
        exports['qb-target']:RemoveZone('mnc_cover_' .. plate)
        registeredCovers[plate] = nil
    end

    CreateThread(function()
        -- Wait until the prop entity is actually live in the world (max 5 s).
        local waited = 0
        while not NetworkDoesNetworkIdExist(coverNetId) and waited < 5000 do
            Wait(200); waited = waited + 200
        end
        if not NetworkDoesNetworkIdExist(coverNetId) then return end
        local obj = NetworkGetEntityFromNetworkId(coverNetId)
        if not DoesEntityExist(obj) then return end

        registeredCovers[plate] = coverNetId
        exports['qb-target']:AddEntityZone('mnc_cover_' .. plate, obj,
            { name = 'mnc_cover_' .. plate, debugPoly = Config.Debug },
            {
                options  = {{ label  = 'Uncover Vehicle',
                              icon   = 'fas fa-eye',
                              action = function()
                                  TriggerEvent('mnc-lift:client:uncoverVehicle', plate)
                              end }},
                distance = Config.Cover.InteractDistance,
            })

        if Config.Debug then
            print('[mnc-parking] Cover target registered for plate=' .. plate)
        end
    end)
end

-- Remove the target zone and forget the registration for this plate.
local function RemoveCoverTarget(plate)
    exports['qb-target']:RemoveZone('mnc_cover_' .. plate)
    registeredCovers[plate] = nil
end

-- ── Wait helpers ──────────────────────────────────────────────────────────────

-- Wait up to maxMs for a vehicle with the given plate to appear in the pool.
-- Returns the entity handle, or nil on timeout.
local function WaitForVehicleByPlate(plate, maxMs)
    local deadline = GetGameTimer() + (maxMs or 10000)
    while GetGameTimer() < deadline do
        for _, v in ipairs(GetGamePool('CVehicle')) do
            if NormalisePlate(GetVehicleNumberPlateText(v)) == plate then
                return v
            end
        end
        Wait(300)
    end
    return nil
end

-- Adopt a networked prop spawned by another client/session.
-- Registers it in myProps so DeleteMyProp can clean it up later.
local function AdoptProp(netId)
    if not netId or netId == 0 then return end
    if myProps[netId] then return end   -- already owned

    local deadline = GetGameTimer() + 5000
    while GetGameTimer() < deadline do
        if NetworkDoesNetworkIdExist(netId) then
            local ent = NetworkGetEntityFromNetworkId(netId)
            if DoesEntityExist(ent) and ent ~= 0 then
                myProps[netId] = ent
                SetEntityAsMissionEntity(ent, true, true)
                return
            end
        end
        Wait(200)
    end
end

-- ── UNCOVER — triggered from qb-target ───────────────────────────────────────

RegisterNetEvent('mnc-lift:client:uncoverVehicle', function(plate)
    local ok, reason = lib.callback.await('mnc-lift:canUncover', false, plate)
    if not ok then Notify('Cover', reason, 'error'); return end

    local ok2 = DoWorkAnim('Uncovering vehicle...', Config.Cover.CoverDuration)
    if not ok2 then Notify('Cover', 'Cancelled.', 'inform'); return end

    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('mnc-lift:uncoverVehicle', plate)
end)

-- ── vehicle_tarp ITEM USE — cover only ───────────────────────────────────────

RegisterNetEvent('mnc-lift:useVehicleTarp', function()
    local vehicle = GetNearestVehicle()
    if not vehicle then
        Notify('Vehicle Cover', 'No vehicle nearby.', 'error'); return
    end

    local vehCoords = GetEntityCoords(vehicle)

    -- No-park zone check
    local zoneName = GetNoParkZone(vehCoords)
    if zoneName then
        Notify('Vehicle Cover',
            ('You cannot cover a vehicle in %s.'):format(zoneName), 'error')
        return
    end

    local plate = NormalisePlate(GetVehicleNumberPlateText(vehicle))

    -- Already covered?
    local isCovered = lib.callback.await('mnc-lift:isCovered', false, plate)
    if isCovered then
        Notify('Vehicle Cover',
            'Already covered. Target the cover prop to uncover.', 'inform')
        return
    end

    -- Server validates ownership, parked status, and item possession.
    local ok, reason = lib.callback.await('mnc-lift:canCover', false, plate)
    if not ok then Notify('Cover', reason, 'error'); return end

    local ok2 = DoWorkAnim('Covering vehicle...', Config.Cover.CoverDuration)
    if not ok2 then Notify('Cover', 'Cancelled.', 'inform'); return end

    ClearPedTasks(PlayerPedId())

    local propModel    = GetCoverPropModel(vehicle)
    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('mnc-lift:coverVehicle', plate, vehicleNetId, propModel)
end)

-- ── SERVER → CLIENT: spawn cover prop ────────────────────────────────────────
-- Sent only to the covering client after the server has consumed the item.

RegisterNetEvent('mnc-lift:spawnCoverProp', function(plate, vehicleNetId, propModel)
    -- Resolve the vehicle entity
    local vehicle = nil
    if vehicleNetId and vehicleNetId ~= 0 then
        local waited = 0
        while not NetworkDoesNetworkIdExist(vehicleNetId) and waited < 3000 do
            Wait(100); waited = waited + 100
        end
        if NetworkDoesNetworkIdExist(vehicleNetId) then
            local e = NetworkGetEntityFromNetworkId(vehicleNetId)
            if DoesEntityExist(e) then vehicle = e end
        end
    end
    if not vehicle then
        for _, v in ipairs(GetGamePool('CVehicle')) do
            if NormalisePlate(GetVehicleNumberPlateText(v)) == plate then
                vehicle = v; break
            end
        end
    end
    if not vehicle then
        TriggerServerEvent('mnc-lift:coverFailed', plate); return
    end

    -- Resolve prop model (fall back if needed)
    local model = (propModel and propModel ~= '') and propModel
                                                  or  GetCoverPropModel(vehicle)
    local hash  = LoadModel(model)
    if not hash then
        local fallback = Config.Cover.FallbackCoverProp or 'prop_tarp_wrap_01'
        hash  = LoadModel(fallback)
        model = fallback
    end
    if not hash then
        TriggerServerEvent('mnc-lift:coverFailed', plate)
        Notify('Cover', 'Cover prop model not found.', 'error'); return
    end

    -- Capture vehicle state BEFORE any hide/freeze changes.
    local vehPos  = GetEntityCoords(vehicle)
    local vehHead = GetEntityHeading(vehicle)
    -- groundZ: only for placing the prop flush to terrain.
    -- vehPos.z: the vehicle entity origin — saved for restore, NOT groundZ.
    local groundZ = GetGroundZ(vehPos.x, vehPos.y, vehPos.z)

    local objNetId = SpawnProp(model, vehPos.x, vehPos.y, groundZ, vehHead)
    if not objNetId then
        TriggerServerEvent('mnc-lift:coverFailed', plate); return
    end

    -- Hide the vehicle AFTER the prop is in the world.
    SetEntityVisible(vehicle, false, false)
    SetEntityCollision(vehicle, false, false)
    FreezeEntityPosition(vehicle, true)

    -- Report to server:
    --   groundZ   → stored as cover_z  (prop placement on reconnect)
    --   vehPos    → stored as cover_x/y/veh_z + heading (vehicle restore)
    TriggerServerEvent('mnc-lift:coverPropSpawned',
        plate, objNetId,
        groundZ,
        vehPos.x, vehPos.y, vehHead, vehPos.z)

    RegisterCoverTarget(plate, objNetId)
    Notify('Cover', 'Vehicle covered. Target the cover prop to uncover.', 'success')
end)

-- ── SERVER → CLIENT: delete cover prop ───────────────────────────────────────
-- Sent to the spawner (or broadcast if spawner offline).
-- Guard: only act if this client owns the netId.

RegisterNetEvent('mnc-lift:deleteMyCoverProp', function(plate, coverNetId)
    if coverNetId and coverNetId ~= 0 and not myProps[coverNetId] then
        -- Another client owns this prop; skip silently.
        if Config.Debug then
            print(('[mnc-parking] deleteMyCoverProp: netId %d not owned by this client '
                   .. '(plate=%s), skipping'):format(coverNetId, tostring(plate)))
        end
        return
    end
    DeleteMyProp(coverNetId)
end)

-- ── SERVER → CLIENT: restore vehicle ─────────────────────────────────────────
-- Broadcast after the cover prop has been deleted.
-- savedX/Y/VehZ/Heading are the coords captured at cover time.

RegisterNetEvent('mnc-lift:restoreVehicle', function(plate, savedX, savedY, savedVehZ, savedHeading)
    RemoveCoverTarget(plate)

    -- Two-frame gap so GTA can settle entity state.
    Wait(0); Wait(0)

    for _, v in ipairs(GetGamePool('CVehicle')) do
        if NormalisePlate(GetVehicleNumberPlateText(v)) == plate then
            if savedX and savedY and savedVehZ then
                SetEntityCoordsNoOffset(v, savedX, savedY, savedVehZ, false, false, false)
            end
            if savedHeading then
                SetEntityHeading(v, savedHeading)
            end
            SetEntityCollision(v, true, true)
            SetEntityVisible(v, true, true)
            FreezeEntityPosition(v, false)
            break
        end
    end

    Notify('Cover', 'Vehicle uncovered.', 'success')
end)

-- ── Reconnect / restart — restore cover state ─────────────────────────────────
-- Triggered by server.lua via mnc-parking:loadParkedVehicles.
-- We wait up to 15 s for each vehicle to appear in the pool before spawning
-- or adopting its prop — this ensures the vehicle entity from the main parking
-- system has time to stream in before we hide it under the cover.

RegisterNetEvent('mnc-parking:loadParkedVehicles', function(allList, ownList, netIdMap)
    CreateThread(function()
        -- Initial settle: vehicles are still being spawned/replicated by server.lua.
        Wait(3000)

        -- ── Step 1: collect all plates from allList in ONE batch callback ────
        -- Also build a plate→vehicleNetId map so we can resolve vehicle entities
        -- directly via netId instead of scanning GetGamePool, which races with
        -- entity release on non-owner clients.
        local plateList     = {}
        local vehNetIdByPlate = {}
        for _, data in ipairs(allList or {}) do
            local p = NormalisePlate(data.plate)
            plateList[#plateList + 1] = p
            if data.vehicleNetId and data.vehicleNetId ~= 0 then
                vehNetIdByPlate[p] = data.vehicleNetId
            end
        end

        if #plateList == 0 then return end

        -- Single round-trip: get covered/not + full state for every plate at once.
        local batchState = lib.callback.await('mnc-lift:getCoverStateBatch', false, plateList)
        if not batchState then return end

        -- ── Step 2: spawn one independent thread per covered plate ────────────
        -- A small stagger (200 ms between threads) prevents all of them from
        -- hammering GTA's entity pool simultaneously, which is what caused the
        -- third (or Nth) vehicle to be missed under load.
        local stagger = 0
        for _, plate in ipairs(plateList) do
            local state = batchState[plate]
            if state and state.covered then
                local capturedPlate  = plate
                local capturedState  = state
                local capturedStagger = stagger   -- capture value now; stagger increments after
                CreateThread(function()
                    if capturedStagger > 0 then Wait(capturedStagger) end

                    local coverNetId = capturedState.netId
                    local savedPos   = {
                        x       = capturedState.x,
                        y       = capturedState.y,
                        vehZ    = capturedState.vehZ,
                        groundZ = capturedState.groundZ,
                        heading = capturedState.heading,
                    }

                    -- Is the prop entity already live in the world?
                    -- IMPORTANT: also confirm the entity is actually an object (type 3),
                    -- not a vehicle that happened to reuse the same netId after a restart.
                    -- A stale prop netId resolving to a freshly-spawned vehicle causes
                    -- RegisterCoverTarget to call AddEntityZone on a vehicle, which
                    -- silently fails in qb-target — the cover appears invisible.
                    local propLive = false
                    if coverNetId and coverNetId ~= 0
                            and NetworkDoesNetworkIdExist(coverNetId) then
                        local ent = NetworkGetEntityFromNetworkId(coverNetId)
                        if DoesEntityExist(ent) and ent ~= 0 then
                            propLive = GetEntityType(ent) == 3   -- 3 = object/prop only
                        end
                    end

                    -- Resolve the vehicle: try the server-supplied netId first
                    -- (fast and reliable), fall back to pool scan only if needed.
                    local function ResolveVehicle(p, maxMs)
                        local nid = vehNetIdByPlate[p]
                        if nid and nid ~= 0 then
                            local deadline2 = GetGameTimer() + math.min(maxMs, 5000)
                            while GetGameTimer() < deadline2 do
                                if NetworkDoesNetworkIdExist(nid) then
                                    local ent = NetworkGetEntityFromNetworkId(nid)
                                    if DoesEntityExist(ent) and ent ~= 0
                                            and GetEntityType(ent) == 2 then  -- 2 = vehicle
                                        return ent
                                    end
                                end
                                Wait(200)
                            end
                        end
                        -- fallback: pool scan
                        return WaitForVehicleByPlate(p, maxMs)
                    end

                    local vehicle = ResolveVehicle(capturedPlate, 15000)

                    if propLive then
                        -- ── Prop is already in the world ──────────────────
                        AdoptProp(coverNetId)
                        TriggerServerEvent('mnc-lift:coverRespawned', capturedPlate, coverNetId)

                        if vehicle then
                            if savedPos.vehZ then
                                SetEntityCoordsNoOffset(vehicle,
                                    savedPos.x, savedPos.y, savedPos.vehZ,
                                    false, false, false)
                            end
                            if savedPos.heading then
                                SetEntityHeading(vehicle, savedPos.heading)
                            end
                            SetEntityVisible(vehicle, false, false)
                            SetEntityCollision(vehicle, false, false)
                            FreezeEntityPosition(vehicle, true)
                        end
                        RegisterCoverTarget(capturedPlate, coverNetId)

                    else
                        -- ── Prop is gone — re-spawn it ────────────────────
                        if not vehicle then
                            if Config.Debug then
                                print('^3[mnc-parking]^7 Reconnect: no vehicle for covered plate='
                                      .. capturedPlate .. ' after 15 s, skipping.')
                            end
                            return
                        end

                        local model = GetCoverPropModel(vehicle)
                        local hash  = LoadModel(model)
                        if not hash then
                            local fallback = Config.Cover.FallbackCoverProp or 'prop_tarp_wrap_01'
                            hash  = LoadModel(fallback)
                            model = fallback
                        end
                        if not hash then
                            if Config.Debug then
                                print('^1[mnc-parking]^7 Reconnect: could not load prop for plate='
                                      .. capturedPlate)
                            end
                            return
                        end

                        local spawnX    = savedPos.x       or GetEntityCoords(vehicle).x
                        local spawnY    = savedPos.y       or GetEntityCoords(vehicle).y
                        local spawnHead = savedPos.heading or GetEntityHeading(vehicle)
                        local spawnZ    = (savedPos.groundZ and savedPos.groundZ ~= 0)
                                          and savedPos.groundZ
                                          or  GetGroundZ(spawnX, spawnY, GetEntityCoords(vehicle).z)

                        if savedPos.vehZ then
                            SetEntityCoordsNoOffset(vehicle,
                                savedPos.x, savedPos.y, savedPos.vehZ, false, false, false)
                            if savedPos.heading then
                                SetEntityHeading(vehicle, savedPos.heading)
                            end
                        end

                        local newNetId = SpawnProp(model, spawnX, spawnY, spawnZ, spawnHead)
                        if newNetId then
                            SetEntityVisible(vehicle, false, false)
                            SetEntityCollision(vehicle, false, false)
                            FreezeEntityPosition(vehicle, true)
                            TriggerServerEvent('mnc-lift:coverRespawned', capturedPlate, newNetId)
                            RegisterCoverTarget(capturedPlate, newNetId)
                        end
                    end
                end)

                stagger = stagger + 200   -- 200 ms between each plate's thread
            end
        end
    end)
end)

-- ── Clean up on recall / untrack ──────────────────────────────────────────────

local function CleanupCover(plate)
    plate = NormalisePlate(plate)
    RemoveCoverTarget(plate)
    -- Note: we do NOT delete the prop here because DoCoverTeardown on the
    -- server side has already sent deleteMyCoverProp / restoreVehicle.
    -- This handler only cleans up the local target zone registration.
end

RegisterNetEvent('mnc-parking:vehicleRecalled',  function(plate) CleanupCover(plate) end)
RegisterNetEvent('mnc-parking:vehicleUntracked', function(plate) CleanupCover(plate) end)

RegisterNetEvent('mnc-lift:useTarpBox', function()
    local vehicle = GetNearestVehicle()
    if not vehicle then
        Notify('Vehicle Cover', 'No vehicle nearby.', 'error')
        return
    end

    local plate = NormalisePlate(GetVehicleNumberPlateText(vehicle))

    -- Check if actually covered
    local isCovered = lib.callback.await('mnc-lift:isCovered', false, plate)
    if not isCovered then
        Notify('Vehicle Cover', 'This vehicle is not covered.', 'error')
        return
    end

    -- Progress bar (same style as uncover)
    local ok = DoWorkAnim('Removing vehicle cover...', Config.Cover.CoverDuration)
    if not ok then
        Notify('Cover', 'Cancelled.', 'inform')
        return
    end

    ClearPedTasks(PlayerPedId())

    -- Trigger server to handle removal
    TriggerServerEvent('mnc-lift:useTarpBox', plate)
end)


if Config.Debug then print('^2[mnc-parking]^7 cover_client.lua loaded.') end