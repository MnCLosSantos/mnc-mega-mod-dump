-- Full updated client.lua - Simplified stacking with tracking (K key)
local lastAttachTime = 0
local isAttached = false
local attachedEntity = nil
local attachedEntityType = nil -- 'vehicle' | 'prop'
local forkliftEntity = nil
local attachedBoneIndex = -1
local currentAttachOffset = vector3(0.0, 0.0, 0.0)
local currentAttachRotation = vector3(0.0, 0.0, 0.0)

-- Lift-platform mode
local isForkliftAttached = false
local anchorVehicle = nil
local liftedForklift = nil
local forkliftAnchorBone = -1
local currentForkliftOffset = vector3(0.0, 0.0, 0.0)
local currentForkliftRotation = vector3(0.0, 0.0, 0.0)

-- Vehicle Stacking (Simplified tracking)
local isStacked = false
local stackedVehicle = nil
local baseVehicle = nil
local currentStackOffset = vector3(0.0, 0.0, 0.0)
local currentStackRotation = vector3(0.0, 0.0, 0.0)
local stackHoldStart = 0
local lastStackAction = 0
local stackLevelsDetachedThisHold = 0

-- Registry of known stack links: [baseEntity] = topEntity
local stackRegistry = {}

local function ShowNotification(msg, type)
    type = type or 'inform'

    if Config.UseOxLibNotify and exports['ox_lib'] then
        exports.ox_lib:notify({
            title = 'ATTACHMENT',
            description = msg,
            type = type,
            position = 'top-right',
            duration = 15000,
        })
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString(msg)
        DrawNotification(false, false)
    end
end

local ControlLabels = {
    [21] = 'LSHIFT OR UP-ARROW',
    [172] = 'LSHIFT OR UP-ARROW',
    [173] = 'LCTRL OR DOWN-ARROW',
    [174] = 'LEFT',
    [175] = 'RIGHT',
    [38] = 'E',
}

local function GetControlLabel(control)
    return ControlLabels[control] or ('CTRL ' .. control)
end

local nuiVisible = false
local nuiHiddenByUser = false  -- toggled by Backspace

local function IsForkliftModel(model)
    return Config.Forklifts[model] ~= nil
end

local function GetVehicleBelow(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    local coords = GetEntityCoords(vehicle)
    local rayStart = coords + vector3(0.0, 0.0, 2.0)
    local rayEnd = coords - vector3(0.0, 0.0, Config.StackSearchDistance)

    local rayHandle = StartShapeTestRay(rayStart.x, rayStart.y, rayStart.z, rayEnd.x, rayEnd.y, rayEnd.z, 10, vehicle, 7)
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)

    if hit and DoesEntityExist(entityHit) and IsEntityAVehicle(entityHit) and entityHit ~= vehicle then
        return entityHit
    end
    return nil
end

local function GetTowedTrailer(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    -- 1) Native GTA/FiveM trailer hitch (only works for pre-defined
    -- tug/trailer model pairs, e.g. Docktug+Trailer, Phantom+Trailer).
    local ok, hasTrailer, trailer = pcall(GetVehicleTrailerVehicle, vehicle)
    if ok and hasTrailer and trailer and trailer ~= 0 and DoesEntityExist(trailer) then
        return trailer
    end

    -- 2) Generic scripted trailer attachment. Most third-party tow/trailer
    -- resources let any vehicle tow any trailer by calling
    -- AttachEntityToEntity directly instead of using the native hitch
    -- above, so also check whether some vehicle in the world is generically
    -- attached to us and is itself a known stack base. Only bother scanning
    -- if there's actually an active stack somewhere to find.
    if next(stackRegistry) ~= nil then
        for _, veh in ipairs(GetGamePool('CVehicle')) do
            if veh ~= vehicle and DoesEntityExist(veh) and IsEntityAttached(veh) and GetEntityAttachedTo(veh) == vehicle then
                if stackRegistry[veh] ~= nil and DoesEntityExist(stackRegistry[veh]) then
                    return veh
                end
            end
        end
    end

    return nil
end

-- Resolves which vehicle should be treated as the "stack base" for
-- helper-UI and attach/detach control purposes given the vehicle the
-- player is physically sitting in (`seatedVeh`). Normally that's just
-- seatedVeh itself. But when vehicles are stacked onto a trailer's bed,
-- nobody can sit in the trailer to reach the stack controls (trailers
-- have no driver seat), so if seatedVeh is towing that trailer via the
-- game's native trailer hitch, control is handed to the tow vehicle's
-- driver instead.
local function GetStackControlVehicle(seatedVeh)
    if not seatedVeh or not DoesEntityExist(seatedVeh) then return nil end

    if (stackRegistry[seatedVeh] ~= nil and DoesEntityExist(stackRegistry[seatedVeh]))
        or (isStacked and seatedVeh == baseVehicle) then
        return seatedVeh
    end

    local trailer = GetTowedTrailer(seatedVeh)
    if trailer and stackRegistry[trailer] ~= nil and DoesEntityExist(stackRegistry[trailer]) then
        return trailer
    end

    return nil
end

-- A resolved stack base is fine to expose controls for unless it's attached
-- to something other than the vehicle the player is actually sitting in.
-- A directly-driven base vehicle normally isn't attached to anything, but a
-- trailer resolved via GetStackControlVehicle's tow-vehicle branch IS
-- attached (to the tow vehicle) by design -- that's expected and shouldn't
-- disqualify it. Only reject bases attached to some unrelated entity.
local function IsUsableStackBase(base, seatedVeh)
    if not base or not DoesEntityExist(base) then return false end
    if not IsEntityAttached(base) then return true end
    return GetEntityAttachedTo(base) == seatedVeh
end

local function SendHelperState()
    local mode = 'idle'
    if isAttached then
        mode = 'forks'
    elseif isForkliftAttached then
        mode = 'liftplatform'
    end

    local showForklift = false
    local showStack = false

    local ped = PlayerPedId()
    local seatedVeh = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or nil

    if seatedVeh then
        local isFork = IsForkliftModel(GetEntityModel(seatedVeh))
        local isAnchor = isForkliftAttached and seatedVeh == anchorVehicle
        if (isFork or isAnchor) and GetPedInVehicleSeat(seatedVeh, -1) == ped then
            showForklift = true
        end
    end

    if seatedVeh then
        local stackBase = GetStackControlVehicle(seatedVeh)
        if IsUsableStackBase(stackBase, seatedVeh) then
            showStack = true
        end
    end

    local title = 'FORKLIFT CONTROLS'
    if showStack and not showForklift then
        title = 'STACK CONTROLS'
    elseif showForklift and showStack then
        title = 'FORKLIFT & STACK'
    end

    SendNUIMessage({
        action = 'setState',
        mode = mode,
        showForkliftControls = showForklift,
        showStackControls = showStack,
        title = title,
        toggleLabel = GetControlLabel(Config.ToggleControl),
        forkliftAttachLabel = Config.ForkliftLiftKeyLabel,
        liftLabel = GetControlLabel(Config.LiftControl),
        lowerLabel = GetControlLabel(Config.LowerControl),
        stackLabel = Config.StackKeyLabelAttach or 'K',
        detachLabel = Config.StackKeyLabelDetach or 'B',
    })
end

local function SetHelperVisible(visible)
    if not Config.ShowHelperUI then return end
    local effective = visible and not nuiHiddenByUser
    if nuiVisible == effective then return end
    nuiVisible = effective
    SendNUIMessage({ action = 'setVisible', visible = effective })
    if effective then SendHelperState() end
end

local function SafeDetach(entity)
    if not DoesEntityExist(entity) then return end
    DetachEntity(entity, true, true)
    SetEntityVelocity(entity, 0.0, 0.0, 0.0)
    SetEntityAngularVelocity(entity, 0.0, 0.0, 0.0)
end

local function ForceSyncState()
    SendNUIMessage({ action = 'setVisible', visible = nuiVisible })
    if nuiVisible then SendHelperState() end
end

RegisterNUICallback('nuiReady', function(_, cb)
    ForceSyncState()
    cb('ok')
end)

local function CanLiftCategory(forkliftModel, vehicleClass)
    local data = Config.Forklifts[forkliftModel]
    if not data then return false end
    return data.categories[vehicleClass] == true
end

local function GetForksBoneCoords(forklift)
    local boneIndex = GetEntityBoneIndexByName(forklift, Config.ForksBoneName)
    if boneIndex == -1 then return nil, -1 end
    return GetWorldPositionOfEntityBone(forklift, boneIndex), boneIndex
end

local function DebugPrint(msg)
    if Config.Debug then
        print('^5[mnc-forkliftfix]^0 ' .. msg)
    end
end

local function GetHorizontalDistance(a, b)
    return #(vector2(a.x, a.y) - vector2(b.x, b.y))
end

local function FindNearestVehicleToForks(forklift, forksCoords, maxDist)
    maxDist = maxDist or Config.PickupDistance
    local nearestVehicle, nearestDist = nil, maxDist
    local vehicles = GetGamePool('CVehicle')

    for _, veh in ipairs(vehicles) do
        if veh ~= forklift and DoesEntityExist(veh) and not IsEntityAttached(veh) then
            local vehCoords = GetEntityCoords(veh)
            local dist = GetHorizontalDistance(forksCoords, vehCoords)
            if dist < nearestDist then
                nearestVehicle = veh
                nearestDist = dist
            end
        end
    end
    return nearestVehicle
end

local function IsPropLiftable(obj, forklift)
    if not DoesEntityExist(obj) or obj == forklift then return false end
    if IsEntityAttached(obj) then
        local parent = GetEntityAttachedTo(obj)
        if parent and parent ~= 0 and DoesEntityExist(parent) then
            return false
        end
    end
    if IsEntityAPed(obj) or IsEntityAVehicle(obj) then return false end
    return true
end

local function FindNearestPropToForks(forklift, forksCoords, maxDist)
    maxDist = maxDist or Config.PropPickupDistance
    local nearestProp, nearestDist = nil, maxDist
    local objects = GetGamePool('CObject')

    for _, obj in ipairs(objects) do
        if IsPropLiftable(obj, forklift) then
            local objCoords = GetEntityCoords(obj)
            local dist = GetHorizontalDistance(forksCoords, objCoords)
            if dist < nearestDist then
                nearestProp = obj
                nearestDist = dist
            end
        end
    end

    if not nearestProp then
        DebugPrint(('FindNearestPropToForks: no candidate within %.2fm'):format(maxDist))
    end

    return nearestProp
end

local function ReplaceWithNetworkedProp(prop)
    if not DoesEntityExist(prop) then
        DebugPrint('ReplaceWithNetworkedProp: Original prop no longer exists')
        return nil
    end

    local model = GetEntityModel(prop)
    if not IsModelValid(model) then
        DebugPrint('ReplaceWithNetworkedProp: Invalid model')
        return nil
    end

    local coords = GetEntityCoords(prop)
    local heading = GetEntityHeading(prop)
    local rotation = GetEntityRotation(prop, 2)

    RequestModel(model)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not HasModelLoaded(model) then
        DebugPrint('ReplaceWithNetworkedProp: Model failed to load')
        return nil
    end

    local newObj = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(newObj) then
        DebugPrint('ReplaceWithNetworkedProp: CreateObject failed')
        return nil
    end

    SetEntityHeading(newObj, heading)
    SetEntityRotation(newObj, rotation.x, rotation.y, rotation.z, 2, true)
    SetEntityCoordsNoOffset(newObj, coords.x, coords.y, coords.z, false, false, false)

    Wait(50)

    if DoesEntityExist(prop) and prop ~= newObj then
        if not IsEntityAMissionEntity(prop) then
            SetEntityAsMissionEntity(prop, true, true)
        end
        DeleteEntity(prop)
    end

    Wait(0)
    return newObj
end

local function CaptureRelativeTransform(forklift, vehicle, boneIndex)
    local boneCoords = GetWorldPositionOfEntityBone(forklift, boneIndex)
    local vehCoords = GetEntityCoords(vehicle)

    local vehLocal = GetOffsetFromEntityGivenWorldCoords(forklift, vehCoords.x, vehCoords.y, vehCoords.z)
    local boneLocal = GetOffsetFromEntityGivenWorldCoords(forklift, boneCoords.x, boneCoords.y, boneCoords.z)
    local relativeOffset = vehLocal - boneLocal

    local forkliftRot = GetEntityRotation(forklift, 2)
    local vehRot = GetEntityRotation(vehicle, 2)
    local relativeRotation = vehRot - forkliftRot

    return relativeOffset, relativeRotation
end

local function ReapplyAttachOffset()
    if not isAttached or not attachedEntity or not forkliftEntity then return end

    AttachEntityToEntity(
        attachedEntity, forkliftEntity, attachedBoneIndex,
        currentAttachOffset.x, currentAttachOffset.y, currentAttachOffset.z,
        currentAttachRotation.x, currentAttachRotation.y, currentAttachRotation.z,
        false, false, false, false, 2, true
    )
end

local function AttachEntityToForks(forklift, entity, boneIndex, offset, rotation, entityType)
    local forkliftNet = NetworkGetNetworkIdFromEntity(forklift)
    local entityNet = NetworkGetNetworkIdFromEntity(entity)

    TriggerServerEvent('mnc_forkliftfix:attachVehicle', forkliftNet, entityNet, offset, rotation, entityType)

    FreezeEntityPosition(entity, false)

    attachedBoneIndex = boneIndex
    currentAttachOffset = offset
    currentAttachRotation = rotation

    AttachEntityToEntity(
        entity, forklift, boneIndex,
        offset.x, offset.y, offset.z,
        rotation.x, rotation.y, rotation.z,
        false, false, false, false, 2, true
    )

    SetEntityCollision(entity, false, false)

    if entityType == 'vehicle' then
        SetVehicleGravity(entity, false)
        SetVehicleEngineOn(entity, false, true, true)
        SetVehicleUndriveable(entity, true)
    else
        SetEntityHasGravity(entity, false)
        FreezeEntityPosition(entity, false)
        if not IsEntityAMissionEntity(entity) then
            SetEntityAsMissionEntity(entity, true, true)
        end
    end

    attachedEntity = entity
    attachedEntityType = entityType
    forkliftEntity = forklift
    isAttached = true
    lastAttachTime = GetGameTimer()

    if entityType == 'prop' then
        Wait(0)
        ReapplyAttachOffset()
        Wait(30)
        ReapplyAttachOffset()
    end

    SendHelperState()
end

local function DetachVehicleFromForks()
    if forkliftEntity then
        local netId = NetworkGetNetworkIdFromEntity(forkliftEntity)
        TriggerServerEvent('mnc_forkliftfix:detachVehicle', netId)
    end

    if attachedEntity and DoesEntityExist(attachedEntity) then
        SafeDetach(attachedEntity)
        SetEntityCollision(attachedEntity, true, true)

        if attachedEntityType == 'vehicle' then
            SetVehicleGravity(attachedEntity, true)
            SetVehicleUndriveable(attachedEntity, false)
        elseif attachedEntityType == 'prop' then
            SetEntityHasGravity(attachedEntity, true)
            SetEntityAsNoLongerNeeded(attachedEntity)
        end
    end

    attachedEntity = nil
    attachedEntityType = nil
    forkliftEntity = nil
    attachedBoneIndex = -1
    isAttached = false

    SendHelperState()
end

local function LiftVehicle()
    if not isAttached then return end
    local newZ = currentAttachOffset.z + (Config.LiftSpeed * GetFrameTime())
    if newZ > Config.MaxLiftOffset then newZ = Config.MaxLiftOffset end
    currentAttachOffset = vector3(currentAttachOffset.x, currentAttachOffset.y, newZ)
    ReapplyAttachOffset()
end

local function LowerVehicle()
    if not isAttached then return end
    local newZ = currentAttachOffset.z - (Config.LiftSpeed * GetFrameTime())
    if newZ < Config.MinLiftOffset then newZ = Config.MinLiftOffset end
    currentAttachOffset = vector3(currentAttachOffset.x, currentAttachOffset.y, newZ)
    ReapplyAttachOffset()
end

-- ============================================================================
-- LIFT-PLATFORM MODE
-- ============================================================================

local function CaptureForkliftRelativeTransform(vehicle, forklift)
    local boneIndex = GetEntityBoneIndexByName(vehicle, 'chassis')
    if boneIndex == -1 then boneIndex = 0 end

    local boneCoords   = GetWorldPositionOfEntityBone(vehicle, boneIndex)
    local forkliftCoords = GetEntityCoords(forklift)

    local forkliftLocal = GetOffsetFromEntityGivenWorldCoords(vehicle, forkliftCoords.x, forkliftCoords.y, forkliftCoords.z)
    local boneLocal     = GetOffsetFromEntityGivenWorldCoords(vehicle, boneCoords.x, boneCoords.y, boneCoords.z)
    local relativeOffset = forkliftLocal - boneLocal

    local vehicleRot  = GetEntityRotation(vehicle, 2)
    local forkliftRot = GetEntityRotation(forklift, 2)
    local relativeRotation = forkliftRot - vehicleRot

    return relativeOffset, relativeRotation
end

local function AttachForkliftToVehicle(vehicle, forklift, offset, rotation)
    local vehicleNet = NetworkGetNetworkIdFromEntity(vehicle)
    local forkliftNet = NetworkGetNetworkIdFromEntity(forklift)

    TriggerServerEvent('mnc_forkliftfix:attachForklift', vehicleNet, forkliftNet, offset, rotation)

    SetEntityCollision(forklift, false, false)
    FreezeEntityPosition(forklift, false)
    SetVehicleEngineOn(forklift, false, true, true)
    SetVehicleUndriveable(forklift, true)

    forkliftAnchorBone = GetEntityBoneIndexByName(vehicle, 'chassis')
    if forkliftAnchorBone == -1 then forkliftAnchorBone = 0 end

    currentForkliftOffset = offset
    currentForkliftRotation = rotation

    AttachEntityToEntity(
        forklift, vehicle, forkliftAnchorBone,
        offset.x, offset.y, offset.z,
        rotation.x, rotation.y, rotation.z,
        false, false, false, false, 2, true
    )

    anchorVehicle = vehicle
    liftedForklift = forklift
    isForkliftAttached = true

    SendHelperState()
end

local function DetachForkliftFromVehicle()
    if anchorVehicle then
        local netId = NetworkGetNetworkIdFromEntity(anchorVehicle)
        TriggerServerEvent('mnc_forkliftfix:detachForklift', netId)
    end

    if liftedForklift and DoesEntityExist(liftedForklift) then
        SafeDetach(liftedForklift)
        SetEntityCollision(liftedForklift, true, true)
        SetVehicleUndriveable(liftedForklift, false)
        SetVehicleEngineOn(liftedForklift, true, true, true)
    end

    anchorVehicle = nil
    liftedForklift = nil
    forkliftAnchorBone = -1
    isForkliftAttached = false

    SendHelperState()
end

local function ReapplyForkliftOffset()
    if not isForkliftAttached or not liftedForklift or not anchorVehicle then return end

    AttachEntityToEntity(
        liftedForklift, anchorVehicle, forkliftAnchorBone,
        currentForkliftOffset.x, currentForkliftOffset.y, currentForkliftOffset.z,
        currentForkliftRotation.x, currentForkliftRotation.y, currentForkliftRotation.z,
        false, false, false, false, 2, true
    )
end

local function LiftForklift()
    if not isForkliftAttached then return end
    local newZ = currentForkliftOffset.z + (Config.LiftSpeed * GetFrameTime())
    if newZ > Config.ForkliftLiftMaxOffset then newZ = Config.ForkliftLiftMaxOffset end
    currentForkliftOffset = vector3(currentForkliftOffset.x, currentForkliftOffset.y, newZ)
    ReapplyForkliftOffset()
end

local function LowerForklift()
    if not isForkliftAttached then return end
    local newZ = currentForkliftOffset.z - (Config.LiftSpeed * GetFrameTime())
    if newZ < Config.ForkliftLiftMinOffset then newZ = Config.ForkliftLiftMinOffset end
    currentForkliftOffset = vector3(currentForkliftOffset.x, currentForkliftOffset.y, newZ)
    ReapplyForkliftOffset()
end

local function TryToggleLift()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then return end

    local model = GetEntityModel(vehicle)
    if not IsForkliftModel(model) then return end

    if isAttached then
        DetachVehicleFromForks()
        return
    end

    if isForkliftAttached then
        return
    end

    local forksCoords, boneIndex = GetForksBoneCoords(vehicle)
    if not forksCoords then return end

    local target = FindNearestVehicleToForks(vehicle, forksCoords)
    if target then
        local targetClass = GetVehicleClass(target)
        if CanLiftCategory(model, targetClass) then
            local offset, rotation = CaptureRelativeTransform(vehicle, target, boneIndex)
            AttachEntityToForks(vehicle, target, boneIndex, offset, rotation, 'vehicle')
            return
        end
    end

    local prop = FindNearestPropToForks(vehicle, forksCoords)
    if not prop then
        if Config.Debug then
            local fwd = GetEntityForwardVector(vehicle)
            local rayStart = forksCoords
            local rayEnd = forksCoords + (fwd * Config.PropPickupDistance)
            local rayHandle = StartShapeTestRay(rayStart.x, rayStart.y, rayStart.z, rayEnd.x, rayEnd.y, rayEnd.z, 10, vehicle, 7)
            local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
            if hit and entityHit ~= 0 and DoesEntityExist(entityHit) then
                local eModel = GetEntityModel(entityHit)
                local isObj = not (IsEntityAPed(entityHit) or IsEntityAVehicle(entityHit))
                DebugPrint(('Diagnostic: forward ray hit entity=%d model=%d isObject=%s isAttached=%s')
                    :format(entityHit, eModel, tostring(isObj), tostring(IsEntityAttached(entityHit))))
            elseif hit then
                DebugPrint('Diagnostic: forward ray hit something with NO entity handle (entityHit=0)')
            else
                DebugPrint('Diagnostic: forward ray hit nothing within range.')
            end
        end
        return
    end

    local networkedProp = ReplaceWithNetworkedProp(prop)
    if not networkedProp then
        DebugPrint('Failed to spawn networked replacement prop, aborting lift')
        ShowNotification("Can't lift that object right now.", 'error')
        return
    end

    local offset, rotation = CaptureRelativeTransform(vehicle, networkedProp, boneIndex)
    AttachEntityToForks(vehicle, networkedProp, boneIndex, offset, rotation, 'prop')
end

local function TryToggleForkliftLift()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local currentVehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(currentVehicle, -1) ~= ped then return end

    local isDriverOfForklift = IsForkliftModel(GetEntityModel(currentVehicle))
    local isDriverOfAnchor = (isForkliftAttached and currentVehicle == anchorVehicle)

    if not isDriverOfForklift and not isDriverOfAnchor then return end

    if isForkliftAttached then
        DetachForkliftFromVehicle()
        ShowNotification("Forklift detached from platform vehicle.", 'success')
        return
    end

    if not isDriverOfForklift then
        ShowNotification("You must be in the forklift to attach in lift-platform mode.", 'error')
        return
    end

    local model = GetEntityModel(currentVehicle)
    if not IsForkliftModel(model) then return end

    if isAttached then return end

    local forksCoords, boneIndex = GetForksBoneCoords(currentVehicle)
    if not forksCoords then return end

    local target = FindNearestVehicleToForks(currentVehicle, forksCoords, Config.PlatformPickupDistance)
    if not target then
        ShowNotification("No vehicle found nearby for platform lift.", 'error')
        return
    end

    if IsEntityAttached(target) then
        ShowNotification("Cannot attach to an already attached vehicle as platform base.", 'error')
        return
    end

    -- NEW: Restrict which classes can be used as platform base
    local targetClass = GetVehicleClass(target)
    if not Config.PlatformBaseClasses[targetClass] then
        ShowNotification("This vehicle type cannot be used as a lift platform.", 'error')
        return
    end

    local offset, rotation = CaptureForkliftRelativeTransform(target, currentVehicle)
    AttachForkliftToVehicle(target, currentVehicle, offset, rotation)
end

-- ====================== VEHICLE STACKING (TRACKING) ======================

local function CaptureStackRelativeTransform(topVeh, baseVeh)
    local topCoords = GetEntityCoords(topVeh)
    local relativeOffset = GetOffsetFromEntityGivenWorldCoords(baseVeh, topCoords.x, topCoords.y, topCoords.z)

    local baseRot = GetEntityRotation(baseVeh, 2)
    local topRot = GetEntityRotation(topVeh, 2)
    local relativeRot = topRot - baseRot

    return relativeOffset, relativeRot
end

local function GetTopOfStack(startVeh)
    local current = startVeh
    while current and stackRegistry[current] and DoesEntityExist(stackRegistry[current]) do
        current = stackRegistry[current]
    end
    return current
end

-- Walks forward through the registry starting at `topVeh`. If `baseVeh` shows
-- up along that walk, linking baseVeh -> topVeh would close a loop
-- (e.g. A stacked on B, then B stacked back onto A). Without this guard,
-- GetTopOfStack()/GetStackChainAbove() can spin forever the next time they
-- walk the registry, which hangs the client script thread and can crash the
-- game.
local function WouldCreateStackCycle(topVeh, baseVeh)
    local current = topVeh
    local guard = 0
    while current do
        if current == baseVeh then return true end
        current = stackRegistry[current]
        guard = guard + 1
        if guard > 128 then return true end
    end
    return false
end

local function AttachVehicleStack(topVeh, baseVeh)
    if not DoesEntityExist(topVeh) or not DoesEntityExist(baseVeh) then return end

    DebugPrint(('AttachVehicleStack: top=%s base/top=%s'):format(tostring(topVeh), tostring(baseVeh)))
    local offset, rotation = CaptureStackRelativeTransform(topVeh, baseVeh)

    local topNet = NetworkGetNetworkIdFromEntity(topVeh)
    local baseNet = NetworkGetNetworkIdFromEntity(baseVeh)
    DebugPrint(('  nets: topNet=%d baseNet=%d'):format(topNet, baseNet))

    TriggerServerEvent('mnc_forkliftfix:attachStack', topNet, baseNet, offset, rotation)

    AttachEntityToEntity(
        topVeh, baseVeh, 0,
        offset.x, offset.y, offset.z,
        rotation.x, rotation.y, rotation.z,
        false, false, false, false, 2, true
    )

    SetEntityCollision(topVeh, false, false)

    -- topVeh is the vehicle the player is currently seated in and driving.
    -- Leaving it driveable while it is rigidly attached to baseVeh makes the
    -- physics engine fight itself every tick (engine/wheel simulation vs.
    -- the attach constraint), which is what causes the freeze-then-crash on
    -- attach. The forklift-forks attach path already does this correctly;
    -- mirror it here.
    SetVehicleEngineOn(topVeh, false, true, true)
    SetVehicleUndriveable(topVeh, true)

    stackRegistry[baseVeh] = topVeh
    stackedVehicle = topVeh
    baseVehicle = baseVeh
    currentStackOffset = offset
    currentStackRotation = rotation
    isStacked = true

    SendHelperState()
    ShowNotification("Vehicle attached onto base vehicle.", 'success')
end

local function GetStackChainAbove(base)
    local chain = {}
    local current = base
    DebugPrint(('GetStackChainAbove: starting from base=%s'):format(tostring(base)))
    while current do
        local top = stackRegistry[current]
        DebugPrint(('  checking base=%s -> top=%s exists=%s'):format(tostring(current), tostring(top), tostring(top and DoesEntityExist(top))))
        if top and DoesEntityExist(top) then
            table.insert(chain, { top = top, base = current })
            current = top
        else
            break
        end
    end
    DebugPrint(('GetStackChainAbove: built chain with %d levels'):format(#chain))
    return chain
end

local function DetachVehicleStack(levelsToDetach, baseOverride)
    local ped = PlayerPedId()
    local seatedVeh = GetVehiclePedIsIn(ped, false)
    local currentVeh = baseOverride or seatedVeh
    if not currentVeh then return end

    if not IsUsableStackBase(currentVeh, seatedVeh) then
        ShowNotification("Only the base vehicle driver can detach the attached vehicles.", 'error')
        return
    end

    local chain = GetStackChainAbove(currentVeh)
    DebugPrint(('DetachVehicleStack: requested=%d, chain length=%d, currentVeh=%s'):format(levelsToDetach, #chain, tostring(currentVeh)))
    if #chain == 0 then
        ShowNotification("No attached vehicles to detach.", 'error')
        return
    end

    levelsToDetach = math.min(levelsToDetach, #chain)

    -- Detach starting from the link closest to the driver (index 1) and
    -- work outward, instead of peeling the outermost vehicle off first.
    -- chain[1].top is the vehicle sitting directly on currentVeh; anything
    -- above THAT is still riding rigidly attached to it and doesn't need
    -- its own collision. If we detached the outermost vehicle first (the
    -- old behavior), it would regain collision while the vehicle it was
    -- resting on (chain[1].top or deeper) was still attached elsewhere with
    -- collision disabled, so it fell straight through. Detaching base-first
    -- means the vehicle that regains collision at each step is exactly the
    -- one being freed, while whatever is still stacked on top of it stays
    -- attached and rides along safely.
    for i = 1, levelsToDetach do
        local link = chain[i]
        if link then
            local baseNet = NetworkGetNetworkIdFromEntity(link.base)
            local topNet = NetworkGetNetworkIdFromEntity(link.top)
            DebugPrint(('DetachVehicleStack: detaching link base=%s (net=%d) top=%s (net=%d)'):format(
                tostring(link.base), baseNet, tostring(link.top), topNet))
            stackRegistry[link.base] = nil

            if DoesEntityExist(link.top) then
                SafeDetach(link.top)
                SetEntityCollision(link.top, true, true)
                SetVehicleUndriveable(link.top, false)
                SetVehicleEngineOn(link.top, true, true, true)
            end

            TriggerServerEvent('mnc_forkliftfix:detachStack', baseNet, topNet)
            ShowNotification("Vehicle detached from stack.", 'success')
        end
    end

    -- levelsToDetach is always >= 1 here, so chain[1] (currentVeh's own
    -- direct attachment) was always included above: currentVeh no longer
    -- has anything stacked directly on it.
    isStacked = false
    stackedVehicle = nil
    baseVehicle = nil
end

local function TryToggleStack()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local currentVeh = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(currentVeh, -1) ~= ped then return end

    local currentTime = GetGameTimer()

    if IsControlJustPressed(0, Config.StackAttachKey or 311) then
        if currentTime - lastStackAction < 600 then return end

        local base = GetVehicleBelow(currentVeh)
        if not base then
            ShowNotification("No vehicle found to attach to it must be directly below.", 'error')
            return
        end
        if currentVeh == base then
            ShowNotification("Cannot stack a vehicle onto itself.", 'error')
            return
        end

        -- Track to the current top of the stack below
        local actualAttachPoint = GetTopOfStack(base)
        if WouldCreateStackCycle(currentVeh, actualAttachPoint) then
            ShowNotification("Can't stack here — that would create a loop.", 'error')
            return
        end
        AttachVehicleStack(currentVeh, actualAttachPoint)
        lastStackAction = currentTime
        return
    end

    -- Resolve which vehicle the detach controls should act on: the vehicle
    -- the player is sitting in, or (if that vehicle has nothing stacked on
    -- it but is towing a trailer that does) the trailer being towed. This
    -- lets the driver of a tow vehicle detach vehicles stacked on a
    -- trailer they're pulling, since a trailer usually has no seat for
    -- anyone to sit in and reach the controls otherwise.
    local stackBase = GetStackControlVehicle(currentVeh)

    if IsControlPressed(0, Config.StackDetachKey or 29) then
        if not IsUsableStackBase(stackBase, currentVeh) then return end

        local hasTop = stackRegistry[stackBase] ~= nil and DoesEntityExist(stackRegistry[stackBase])
        DebugPrint(('TryToggleStack detach check: currentVeh=%s stackBase=%s hasTop=%s'):format(tostring(currentVeh), tostring(stackBase), tostring(hasTop)))
        if not hasTop then return end

        if stackHoldStart == 0 then
            stackHoldStart = currentTime
            stackLevelsDetachedThisHold = 0
        end

        local holdTime = currentTime - stackHoldStart
        local requiredHold = Config.StackDetachHoldTimePerLevel or 1000

        local levelsEarnedSoFar = math.floor(holdTime / requiredHold)
        local levelsToDetachNow = levelsEarnedSoFar - stackLevelsDetachedThisHold

        if levelsToDetachNow > 0 then
            lastStackAction = currentTime
            DetachVehicleStack(levelsToDetachNow, stackBase)
            stackLevelsDetachedThisHold = levelsEarnedSoFar
        end
    else
        if stackHoldStart > 0 then
            local holdTime = GetGameTimer() - stackHoldStart
            stackHoldStart = 0
            if stackLevelsDetachedThisHold == 0 and holdTime < 300 and IsUsableStackBase(stackBase, currentVeh) then
                if currentTime - lastStackAction >= 600 then
                    lastStackAction = currentTime
                    DetachVehicleStack(1, stackBase)
                end
            end
            stackLevelsDetachedThisHold = 0
        end
    end
end

-- ====================== NETWORK SYNC ======================

RegisterNetEvent('mnc_forkliftfix:syncAttachment')
AddEventHandler('mnc_forkliftfix:syncAttachment', function(forkliftNet, vehicleNet, offset, rotation, entityType)
    local forklift = NetworkGetEntityFromNetworkId(forkliftNet)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNet)
    if not DoesEntityExist(forklift) or not DoesEntityExist(vehicle) then return end

    local boneIndex = GetEntityBoneIndexByName(forklift, Config.ForksBoneName)
    AttachEntityToEntity(vehicle, forklift, boneIndex,
        offset.x, offset.y, offset.z,
        rotation.x, rotation.y, rotation.z,
        false, false, false, false, 2, true)

    SetEntityCollision(vehicle, false, false)

    if entityType == 'vehicle' then
        SetVehicleGravity(vehicle, false)
    else
        SetEntityHasGravity(vehicle, false)
        if not IsEntityAMissionEntity(vehicle) then
            SetEntityAsMissionEntity(vehicle, true, true)
        end
    end
end)

RegisterNetEvent('mnc_forkliftfix:syncDetach')
AddEventHandler('mnc_forkliftfix:syncDetach', function(forkliftNet)
    local forklift = NetworkGetEntityFromNetworkId(forkliftNet)
    if not DoesEntityExist(forklift) then return end

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if GetEntityAttachedTo(veh) == forklift then
            DetachEntity(veh, true, true)
            SetEntityCollision(veh, true, true)
            SetVehicleGravity(veh, true)
        end
    end

    for _, obj in ipairs(GetGamePool('CObject')) do
        if GetEntityAttachedTo(obj) == forklift then
            DetachEntity(obj, true, true)
            SetEntityCollision(obj, true, true)
            SetEntityHasGravity(obj, true)
        end
    end
end)

RegisterNetEvent('mnc_forkliftfix:syncForkliftAttachment')
AddEventHandler('mnc_forkliftfix:syncForkliftAttachment', function(vehicleNet, forkliftNet, offset, rotation)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNet)
    local forklift = NetworkGetEntityFromNetworkId(forkliftNet)
    if not DoesEntityExist(vehicle) or not DoesEntityExist(forklift) then return end

    local bone = GetEntityBoneIndexByName(vehicle, 'chassis')
    if bone == -1 then bone = 0 end

    AttachEntityToEntity(forklift, vehicle, bone,
        offset.x, offset.y, offset.z,
        rotation.x, rotation.y, rotation.z,
        false, false, false, false, 2, true)

    SetEntityCollision(forklift, false, false)
end)

RegisterNetEvent('mnc_forkliftfix:syncForkliftDetach')
AddEventHandler('mnc_forkliftfix:syncForkliftDetach', function(vehicleNet, forkliftNet)
    local forklift = forkliftNet and NetworkGetEntityFromNetworkId(forkliftNet)
    if forklift and DoesEntityExist(forklift) then
        DetachEntity(forklift, true, true)
        SetEntityCollision(forklift, true, true)
        return
    end
end)

RegisterNetEvent('mnc_forkliftfix:syncStackAttachment')
AddEventHandler('mnc_forkliftfix:syncStackAttachment', function(baseNet, topNet, offset, rotation)
    local base = NetworkGetEntityFromNetworkId(baseNet)
    local top = NetworkGetEntityFromNetworkId(topNet)
    DebugPrint(('syncStackAttachment: baseNet=%d topNet=%d baseExists=%s topExists=%s'):format(
        baseNet or -1, topNet or -1, tostring(DoesEntityExist(base)), tostring(DoesEntityExist(top))))
    if not DoesEntityExist(base) or not DoesEntityExist(top) then return end

    AttachEntityToEntity(top, base, 0, offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, false, false, false, false, 2, true)
    SetEntityCollision(top, false, false)
    -- Mirror the local undriveable/engine-off fix for other clients too, in
    -- case someone else is (or later gets into) the driver seat of `top`.
    SetVehicleEngineOn(top, false, true, true)
    SetVehicleUndriveable(top, true)
    stackRegistry[base] = top
    DebugPrint(('  registry updated: base=%s -> top=%s'):format(tostring(base), tostring(top)))
end)

RegisterNetEvent('mnc_forkliftfix:syncStackDetach')
AddEventHandler('mnc_forkliftfix:syncStackDetach', function(baseNet, topNet)
    DebugPrint(('syncStackDetach: baseNet=%d topNet=%d'):format(baseNet or -1, topNet or -1))
    local base = baseNet and NetworkGetEntityFromNetworkId(baseNet)
    local top  = topNet  and NetworkGetEntityFromNetworkId(topNet)

    if base and DoesEntityExist(base) then
        DebugPrint(('  clearing registry for base=%s'):format(tostring(base)))
        stackRegistry[base] = nil
    end

    if top and DoesEntityExist(top) then
        DebugPrint(('  detaching top=%s'):format(tostring(top)))
        SafeDetach(top)
        SetEntityCollision(top, true, true)
        SetVehicleUndriveable(top, false)
        SetVehicleEngineOn(top, true, true, true)
    end
end)

-- ====================== DEBUG ======================

RegisterCommand('dumpstack', function()
    local ped = PlayerPedId()
    local currentVeh = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or nil

    DebugPrint('=== stackRegistry dump ===')
    local count = 0
    for base, top in pairs(stackRegistry) do
        local baseExists = DoesEntityExist(base)
        local topExists  = DoesEntityExist(top)
        local baseNet    = baseExists and NetworkGetNetworkIdFromEntity(base) or -1
        local topNet     = topExists  and NetworkGetNetworkIdFromEntity(top)  or -1
        DebugPrint(('  base entity=%d (net=%d exists=%s) -> top entity=%d (net=%d exists=%s)'):format(
            base, baseNet, tostring(baseExists), top, topNet, tostring(topExists)))
        count = count + 1
    end
    if count == 0 then
        DebugPrint('  (empty)')
    end

    if currentVeh then
        local chain = GetStackChainAbove(currentVeh)
        DebugPrint(('Current vehicle entity=%d — chain has %d level(s)'):format(currentVeh, #chain))
        for idx, link in ipairs(chain) do
            DebugPrint(('  level %d: base=%d -> top=%d'):format(idx, link.base, link.top))
        end
    end
    DebugPrint('=== end dump ===')
end, false)

-- ====================== KEY MAPPINGS ======================

RegisterKeyMapping('mnc_forkliftfix_liftmode', 'Attach Forklift To Vehicle (Lift Platform Mode)', 'keyboard', Config.ForkliftLiftKeyLabel)
RegisterCommand('mnc_forkliftfix_liftmode', function()
    TryToggleForkliftLift()
end, false)

RegisterKeyMapping('mnc_forkliftfix_toggleui', 'Toggle Forklift Helper UI', 'keyboard', 'BACK')
RegisterCommand('mnc_forkliftfix_toggleui', function()
    nuiHiddenByUser = not nuiHiddenByUser
    -- Re-evaluate visibility immediately based on current context
    local ped = PlayerPedId()
    local seatedVeh = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or nil
    local shouldShow = false
    if seatedVeh then
        local model = GetEntityModel(seatedVeh)
        local isFork = IsForkliftModel(model)
        local isAnchor = isForkliftAttached and seatedVeh == anchorVehicle
        local stackBase = GetStackControlVehicle(seatedVeh)
        local isStackBase = IsUsableStackBase(stackBase, seatedVeh)
        if isFork or isAnchor or isStackBase then shouldShow = true end
    end
    -- Force a state transition by resetting nuiVisible so SetHelperVisible fires
    nuiVisible = not (shouldShow and not nuiHiddenByUser)
    SetHelperVisible(shouldShow)
end, false)

-- ====================== MAIN LOOP ======================

CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()
        local seatedVeh = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or nil
        local enteringVeh = GetVehiclePedIsEntering(ped)

        local showUI = false
        local canControlForklift = false
        local canControlStack = false

        if seatedVeh then
            local isDriver = GetPedInVehicleSeat(seatedVeh, -1) == ped
            local model = GetEntityModel(seatedVeh)
            local isFork = IsForkliftModel(model)
            local isAnchor = isForkliftAttached and seatedVeh == anchorVehicle

            local stackBase = GetStackControlVehicle(seatedVeh)
            local isStackBase = IsUsableStackBase(stackBase, seatedVeh)

            if isFork or isAnchor or isStackBase then
                showUI = true
                if isDriver then canControlForklift = true end
            end

            if isDriver then
                canControlStack = true
            end
        elseif enteringVeh ~= 0 and IsForkliftModel(GetEntityModel(enteringVeh)) then
            showUI = true
        end

        SetHelperVisible(showUI)

        if not canControlForklift and stackHoldStart > 0 then
            stackHoldStart = 0
        end

        if canControlForklift then
            -- Only allow E to toggle normal fork lift/attach when NOT in platform mode
            if IsControlJustPressed(0, Config.ToggleControl) then
                if not isForkliftAttached then
                    TryToggleLift()
                end
                -- E does NOTHING when forklift is attached as platform (only O detaches)
            end

            if isAttached then
                if IsControlPressed(0, Config.LiftControl) then
                    LiftVehicle()
                elseif IsControlPressed(0, Config.LowerControl) then
                    LowerVehicle()
                end
            elseif isForkliftAttached then
                if IsControlPressed(0, Config.LiftControl) then
                    LiftForklift()
                elseif IsControlPressed(0, Config.LowerControl) then
                    LowerForklift()
                end
            end
        end

        if canControlStack then
            TryToggleStack()
        end

        if nuiVisible then SendHelperState() end

        -- Safety checks
        if isAttached then
            if not DoesEntityExist(forkliftEntity) or not DoesEntityExist(attachedEntity) then
                DetachVehicleFromForks()
            elseif attachedEntityType == 'prop' and GetGameTimer() - lastAttachTime < 1000 then
                ReapplyAttachOffset()
            end
        end

        if isForkliftAttached then
            if not DoesEntityExist(anchorVehicle) or not DoesEntityExist(liftedForklift) then
                DetachForkliftFromVehicle()
            end
        end

        if isStacked then
            if not DoesEntityExist(stackedVehicle) or not DoesEntityExist(baseVehicle) then
                isStacked = false
                baseVehicle = nil
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if isAttached then DetachVehicleFromForks() end
    if isForkliftAttached then DetachForkliftFromVehicle() end
end)