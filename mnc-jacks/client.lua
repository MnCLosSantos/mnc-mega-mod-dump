local QBCore = exports['qb-core']:GetCoreObject()

local ANIM_DICT_JACK  = 'mini@repair'
local ANIM_CLIP_JACK  = 'fixing_a_ped'
local ANIM_DICT_STAND = 'amb@world_human_vehicle_mechanic@male@base'
local ANIM_CLIP_STAND = 'base'

local JACK_PROP_MODEL  = Config.Lift.JackPropModel
local STAND_PROP_MODEL = 'xs_prop_x18_axel_stand_01a'   -- prop held in hand during stand placement

local activeSession     = nil      -- { plate, side, standIndex }
local jackInProgress    = {}
local registeredStands  = {}
local removalInProgress = {}
local frozenVehicles    = {}       -- [plate] = { entity, z }
local jackFloorProps    = {}       -- [plate_side] = entity
local myProps           = {}       -- [netId] = entity (props spawned by this client)

local freezeGen         = {}       -- [plate] = generation

local JACK_POINTS = {
    left  = { x = -0.6, y = 0.0, z = 0.0 },
    right = { x =  0.6, y = 0.0, z = 0.0 },
}

local PROMPT_RADIUS = 1.6

-- ====================== INIT ======================
CreateThread(function()
    while not QBCore do Wait(500) end

    RequestAnimDict(ANIM_DICT_JACK)
    while not HasAnimDictLoaded(ANIM_DICT_JACK) do Wait(0) end

    RequestAnimDict(ANIM_DICT_STAND)
    while not HasAnimDictLoaded(ANIM_DICT_STAND) do Wait(0) end
end)

local function NormalisePlate(plate)
    return string.upper((plate or ''):gsub('%s+', ''))
end

local function Notify(title, description, ntype, duration)
    lib.notify({
        title = title or 'Car Jack',
        description = description,
        type = ntype or 'inform',
        duration = duration or 5000
    })
end

local function LoadModel(model)
    local hash = GetHashKey(model)
    if not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local waited = 0
    while not HasModelLoaded(hash) and waited < 5000 do
        Wait(100)
        waited = waited + 100
    end
    return HasModelLoaded(hash) and hash or nil
end

local function VehicleLocalToWorld(vehicle, offset)
    local pos  = GetEntityCoords(vehicle)
    local head = GetEntityHeading(vehicle)
    local rad  = math.rad(head)
    local c, s = math.cos(rad), math.sin(rad)
    return vector3(
        pos.x + (offset.x * c - offset.y * s),
        pos.y + (offset.x * s + offset.y * c),
        pos.z + (offset.z or 0.0)
    )
end

local function GetGroundZ(x, y, z)
    local found, gz = GetGroundZFor_3dCoord(x, y, z + 20.0, false)
    return found and gz or z
end

local function DeleteProp(obj)
    if obj and DoesEntityExist(obj) then
        DeleteEntity(obj)
    end
end

-- ====================== FREEZE KEEP-ALIVE ======================
local function StartFreezeKeepAlive(plate, vehicle, targetZ)
    local gen = (freezeGen[plate] or 0) + 1
    freezeGen[plate] = gen
    frozenVehicles[plate] = { entity = vehicle, z = targetZ }

    CreateThread(function()
        while freezeGen[plate] == gen and frozenVehicles[plate] do
            if DoesEntityExist(vehicle) then
                FreezeEntityPosition(vehicle, true)
                local pos = GetEntityCoords(vehicle)
                if math.abs(pos.z - targetZ) > 0.02 then
                    SetEntityCoordsNoOffset(vehicle, pos.x, pos.y, targetZ, false, false, false)
                end
                local rot = GetEntityRotation(vehicle, 2)
                if math.abs(rot.x) > 0.5 or math.abs(rot.y) > 0.5 then
                    SetEntityRotation(vehicle, 0.0, 0.0, rot.z, 2, true)
                end
            end
            Wait(100)
        end
    end)
end

local function StopFreezeKeepAlive(plate)
    freezeGen[plate] = (freezeGen[plate] or 0) + 1
    frozenVehicles[plate] = nil
end

-- ====================== JACK PROP ======================
local function SpawnJackProp(vehicle, side)
    local hash = LoadModel(JACK_PROP_MODEL)
    if not hash then return nil end

    local worldPos = VehicleLocalToWorld(vehicle, JACK_POINTS[side])
    local groundZ  = GetGroundZ(worldPos.x, worldPos.y, worldPos.z)

    local jack = CreateObject(hash, worldPos.x, worldPos.y, groundZ, true, true, false)

    local vehHeading = GetEntityHeading(vehicle)
    SetEntityHeading(jack, (vehHeading + Config.Lift.JackRotation[side]) % 360.0)

    FreezeEntityPosition(jack, true)
    SetEntityCollision(jack, false, false)
    SetModelAsNoLongerNeeded(hash)

    return jack
end

local function RemoveJackFloorProp(plate, side)
    local key = plate .. '_' .. side
    local obj = jackFloorProps[key]
    jackFloorProps[key] = nil
    if obj and DoesEntityExist(obj) then
        DeleteEntity(obj)
    end
end

-- ====================== JACK ANIMATION ======================
local function DoJackAnim(label, duration, side, vehicle, plate)
    local ped = PlayerPedId()
    local vehHead = GetEntityHeading(vehicle)

    local facingHead = (vehHead + (side == 'left' and -90.0 or 90.0)) % 360.0
    SetEntityHeading(ped, facingHead)

    local baseZ = GetEntityCoords(vehicle).z
    local targetZ = baseZ + Config.Lift.RaiseHeight

    FreezeEntityPosition(vehicle, true)
    SetEntityRotation(vehicle, 0.0, 0.0, vehHead, 2, true)

    local jackProp = SpawnJackProp(vehicle, side)
    jackFloorProps[plate .. '_' .. side] = jackProp

    local animRunning = true
    local raiseStartMs = GetGameTimer()

    CreateThread(function()
        while animRunning do
            local elapsed = GetGameTimer() - raiseStartMs
            local fraction = math.min(elapsed / duration, 1.0)
            local cur = GetEntityCoords(vehicle)
            SetEntityCoordsNoOffset(vehicle, cur.x, cur.y, baseZ + Config.Lift.RaiseHeight * fraction, false, false, false)
            Wait(0)
        end
    end)

    local result = lib.progressBar({
        duration     = duration,
        label        = label,
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = ANIM_DICT_JACK, clip = ANIM_CLIP_JACK, flag = 1 },
    })

    animRunning = false

    if result then
        ClearPedTasks(ped)
        SetEntityCoordsNoOffset(vehicle, GetEntityCoords(vehicle).x, GetEntityCoords(vehicle).y, targetZ, false, false, false)
        StartFreezeKeepAlive(plate, vehicle, targetZ)

        activeSession = { plate = plate, side = side, standIndex = 1 }

        TriggerServerEvent('mnc-jacks:raiseDone', plate, side, targetZ)
        TriggerServerEvent('mnc-jacks:startStandPlacement', plate, side)

        Notify('Car Jack', (side:sub(1,1):upper() .. side:sub(2)) .. ' side jacked up!', 'success')
    else
        ClearPedTasks(ped)
        DeleteProp(jackProp)
        local curZ = GetEntityCoords(vehicle).z
        local steps = 20
        for i = 1, steps do
            local frac = 1.0 - (i / steps)
            SetEntityCoordsNoOffset(vehicle, GetEntityCoords(vehicle).x, GetEntityCoords(vehicle).y,
                baseZ + (curZ - baseZ) * frac, false, false, false)
            Wait(20)
        end
        FreezeEntityPosition(vehicle, false)
        StopFreezeKeepAlive(plate)
        Notify('Car Jack', 'Jacking cancelled.', 'error')
    end

    return result
end

-- ====================== STAND ANIMATION ======================
local function DoStandAnim(label, duration, side, vehicle)
    if side and vehicle then
        local h = GetEntityHeading(vehicle)
        SetEntityHeading(PlayerPedId(), (h + (side == 'left' and 90.0 or -90.0)) % 360.0)
    end

    local prop = nil
    local standHash = GetHashKey(STAND_PROP_MODEL)
    if IsModelValid(standHash) then
        RequestModel(standHash)
        local w = 0
        while not HasModelLoaded(standHash) and w < 3000 do Wait(100); w = w + 100 end
        if HasModelLoaded(standHash) then
            local ped = PlayerPedId()
            prop = CreateObject(standHash, 0, 0, 0, true, true, false)
            AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            SetModelAsNoLongerNeeded(standHash)
        end
    end

    local result = lib.progressBar({
        duration     = duration,
        label        = label,
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = ANIM_DICT_STAND, clip = ANIM_CLIP_STAND, flag = 1 },
    })

    if prop and DoesEntityExist(prop) then
        DetachEntity(prop, false, false)
        DeleteEntity(prop)
    end
    return result
end

local function WaitForEPress(worldPos, helpText, r, g, b)
    r = r or 255; g = g or 165; b = b or 0
    local ePressed, aborted = false, false

    CreateThread(function()
        while not ePressed and not aborted do
            local dist = #(GetEntityCoords(PlayerPedId()) - worldPos)
            DrawMarker(1, worldPos.x, worldPos.y, worldPos.z + 0.05, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.2, r, g, b, 200, false, true, 2, false, nil, nil, false)

            if dist <= PROMPT_RADIUS then
                SetTextComponentFormat('STRING')
                AddTextComponentString(helpText)
                DisplayHelpTextFromStringLabel(0, false, true, -1)
                if IsControlJustPressed(0, 51) then ePressed = true end
            end
            if IsControlJustPressed(1, 200) or IsDisabledControlJustPressed(1, 200) then
                aborted = true
            end
            Wait(0)
        end
    end)

    while not ePressed and not aborted do Wait(100) end
    return ePressed, aborted
end

local function SpawnProp(model, x, y, z, heading, noCollision)
    local hash = LoadModel(model)
    if not hash then return nil end

    local obj = CreateObject(hash, x, y, z, true, true, false)
    SetEntityHeading(obj, heading)
    FreezeEntityPosition(obj, true)
    if noCollision then SetEntityCollision(obj, false, false) end
    SetModelAsNoLongerNeeded(hash)

    NetworkRegisterEntityAsNetworked(obj)
    SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(obj), true)
    SetEntityAsMissionEntity(obj, true, true)

    local netId = NetworkGetNetworkIdFromEntity(obj)
    myProps[netId] = obj
    return netId
end

local function DeleteMyProp(netId)
    if not netId or netId == 0 then return end
    local entity = myProps[netId]
    myProps[netId] = nil
    if not entity and NetworkDoesNetworkIdExist(netId) then
        entity = NetworkGetEntityFromNetworkId(netId)
    end
    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, false, false)
        pcall(function() exports['qb-target']:RemoveTargetEntity(entity) end)
        for _ = 1, 5 do
            if DoesEntityExist(entity) then DeleteEntity(entity); Wait(50) else break end
        end
    end
end

-- ====================== STAND TARGETS ======================
local function RegisterStandTargets(plate, side, netId1, netId2)
    local key = plate .. '_' .. side
    if registeredStands[key] then return end
    registeredStands[key] = true

    CreateThread(function()
        local sideLabel = side:sub(1,1):upper() .. side:sub(2)

        local function WaitEnt(netId)
            if not netId or netId == 0 then return nil end
            local waited = 0
            while not NetworkDoesNetworkIdExist(netId) and waited < 5000 do
                Wait(200); waited = waited + 200
            end
            if NetworkDoesNetworkIdExist(netId) then
                local e = NetworkGetEntityFromNetworkId(netId)
                return DoesEntityExist(e) and e or nil
            end
            return nil
        end

        local obj1 = WaitEnt(netId1)
        local obj2 = WaitEnt(netId2)

        local function AddZone(obj, idx)
            if not obj then return end
            local zn = 'mnc_stand_' .. plate .. '_' .. side .. '_' .. idx
            exports['qb-target']:AddEntityZone(zn, obj, { name = zn, debugPoly = Config.Debug }, {
                options = {{
                    label = 'Remove ' .. sideLabel .. ' Stands',
                    icon  = 'fas fa-arrow-down',
                    action = function()
                        TriggerEvent('mnc-jacks:client:removeStands', plate, side)
                    end
                }},
                distance = Config.Lift.InteractDistance,
            })
        end

        AddZone(obj1, 1)
        AddZone(obj2, 2)
    end)
end

-- ====================== STAND PLACEMENT ======================
local function PlaceStand(plate, side, standIndex)
    activeSession = { plate = plate, side = side, standIndex = standIndex }

    local vehicle = nil
    for _, v in ipairs(GetGamePool('CVehicle')) do
        if NormalisePlate(GetVehicleNumberPlateText(v)) == plate then
            vehicle = v; break
        end
    end
    if not vehicle then
        TriggerServerEvent('mnc-jacks:standSpawnFailed', plate, side, standIndex)
        Notify('Axle Stand', 'Could not find the vehicle.', 'error')
        return
    end

    local offsets = Config.Lift.StandOffsets[side][standIndex]
    local vehPos  = GetEntityCoords(vehicle)
    local vehHead = GetEntityHeading(vehicle)
    local rad = math.rad(vehHead)
    local c, sn = math.cos(rad), math.sin(rad)

    local wx = vehPos.x + (offsets.x * c - offsets.y * sn)
    local wy = vehPos.y + (offsets.x * sn + offsets.y * c)
    local wz = GetGroundZ(wx, wy, vehPos.z)

    Notify('Axle Stand', ('Walk to stand %d/%d and press E'):format(standIndex, Config.Lift.StandsPerSide), 'inform', 6000)

    local pressed, aborted = WaitForEPress(vector3(wx, wy, wz),
        ('Press ~INPUT_CONTEXT~ to place axle stand %d/%d'):format(standIndex, Config.Lift.StandsPerSide), 80, 220, 80)

    if aborted or not pressed then
        TriggerServerEvent('mnc-jacks:standSpawnFailed', plate, side, standIndex)
        Notify('Axle Stand', 'Placement cancelled.', 'inform')
        return
    end

    local ok = DoStandAnim(('Placing axle stand %d/%d...'):format(standIndex, Config.Lift.StandsPerSide),
        Config.Lift.StandDuration, side, vehicle)

    if not ok then
        TriggerServerEvent('mnc-jacks:standSpawnFailed', plate, side, standIndex)
        Notify('Axle Stand', 'Placement cancelled.', 'inform')
        return
    end

    local stand1NewNetId = nil
    if standIndex == 2 then
        local stand1OldNetId = lib.callback.await('mnc-jacks:getStand1NetId', false, plate, side)
        if stand1OldNetId and stand1OldNetId ~= 0 then
            DeleteMyProp(stand1OldNetId)
            local off1 = Config.Lift.StandOffsets[side][1]
            local wx1 = vehPos.x + (off1.x * c - off1.y * sn)
            local wy1 = vehPos.y + (off1.x * sn + off1.y * c)
            local wz1 = GetGroundZ(wx1, wy1, vehPos.z)
            stand1NewNetId = SpawnProp(Config.Lift.StandPropModel, wx1, wy1, wz1,
                vehHead + (off1.heading or 0.0), true)
        end
    end

    local propHeading = vehHead + (offsets.heading or 0.0)
    local netId = SpawnProp(Config.Lift.StandPropModel, wx, wy, wz, propHeading, true)

    if not netId then
        TriggerServerEvent('mnc-jacks:standSpawnFailed', plate, side, standIndex)
        Notify('Axle Stand', 'Failed to spawn prop.', 'error')
        return
    end

    if standIndex < Config.Lift.StandsPerSide then
        activeSession = { plate = plate, side = side, standIndex = standIndex + 1 }
    else
        activeSession = nil
    end

    TriggerServerEvent('mnc-jacks:standSpawned', plate, side, standIndex, netId, stand1NewNetId)
end

RegisterNetEvent('mnc-jacks:client:activateStand', function()
    if not activeSession then
        Notify('Axle Stand', 'No active jack session.', 'error')
        return
    end
    PlaceStand(activeSession.plate, activeSession.side, activeSession.standIndex)
end)

-- ====================== CAR JACK ITEM USE ======================
RegisterNetEvent('mnc-jacks:useCarJack', function()
    local vehicle = nil
    local pedPos = GetEntityCoords(PlayerPedId())
    local bestDist = Config.Lift.InteractDistance

    for _, v in ipairs(GetGamePool('CVehicle')) do
        local d = #(pedPos - GetEntityCoords(v))
        if d < bestDist then
            vehicle = v
            bestDist = d
        end
    end

    if not vehicle then
        Notify('Car Jack', 'No vehicle nearby.', 'error')
        return
    end

    local plate = NormalisePlate(GetVehicleNumberPlateText(vehicle))

    local options = {}

    local state = lib.callback.await('mnc-jacks:getLiftState', false, plate)

    if not state.left.raised and state.left.stage == 0 then
        options[#options + 1] = {
            title = 'Lift Left Side',
            description = 'Jack up left side (2 axle stands required)',
            icon = 'arrow-up',
            onSelect = function()
                local ok, reason = lib.callback.await('mnc-jacks:canLiftSide', false, plate, 'left')
                if not ok then Notify('Car Jack', reason, 'error'); return end

                local jackPos = VehicleLocalToWorld(vehicle, JACK_POINTS.left)
                Notify('Car Jack', 'Walk to the left side and press E.', 'inform', 5000)

                local pressed, aborted = WaitForEPress(jackPos, 'Press ~INPUT_CONTEXT~ to jack up left side', 255, 165, 0)
                if aborted or not pressed then return end

                jackInProgress[plate] = true
                local success = DoJackAnim('Jacking up left side...', Config.Lift.JackDuration, 'left', vehicle, plate)
                jackInProgress[plate] = nil
            end
        }
    end

    if not state.right.raised and state.right.stage == 0 then
        options[#options + 1] = {
            title = 'Lift Right Side',
            description = 'Jack up right side (2 axle stands required)',
            icon = 'arrow-up',
            onSelect = function()
                local ok, reason = lib.callback.await('mnc-jacks:canLiftSide', false, plate, 'right')
                if not ok then Notify('Car Jack', reason, 'error'); return end

                local jackPos = VehicleLocalToWorld(vehicle, JACK_POINTS.right)
                Notify('Car Jack', 'Walk to the right side and press E.', 'inform', 5000)

                local pressed, aborted = WaitForEPress(jackPos, 'Press ~INPUT_CONTEXT~ to jack up right side', 255, 165, 0)
                if aborted or not pressed then return end

                jackInProgress[plate] = true
                local success = DoJackAnim('Jacking up right side...', Config.Lift.JackDuration, 'right', vehicle, plate)
                jackInProgress[plate] = nil
            end
        }
    end

    if #options == 0 then
        Notify('Car Jack', 'Both sides are already raised.', 'inform')
        return
    end

    lib.registerContext({ id = 'mnc_jacks_menu', title = 'Car Jacks — ' .. plate, options = options })
    lib.showContext('mnc_jacks_menu')
end)

-- ====================== RAISE / LOWER BROADCAST ======================
RegisterNetEvent('mnc-jacks:raiseVehicle', function(plate, side, stand1NetId, stand2NetId, raisedZ)
    RemoveJackFloorProp(plate, side)

    local vehicle = nil
    for _, v in ipairs(GetGamePool('CVehicle')) do
        if NormalisePlate(GetVehicleNumberPlateText(v)) == plate then
            vehicle = v; break
        end
    end

    if vehicle and raisedZ and raisedZ ~= 0 then
        StopFreezeKeepAlive(plate)
        FreezeEntityPosition(vehicle, true)

        local cur = GetEntityCoords(vehicle)
        if math.abs(cur.z - raisedZ) > 0.02 then
            local currentZ = cur.z
            while currentZ < raisedZ do
                currentZ = math.min(currentZ + 0.005, raisedZ)
                SetEntityCoordsNoOffset(vehicle, cur.x, cur.y, currentZ, false, false, false)
                Wait(20)
            end
        end

        SetEntityCoordsNoOffset(vehicle, cur.x, cur.y, raisedZ, false, false, false)
        SetEntityRotation(vehicle, 0.0, 0.0, GetEntityHeading(vehicle), 2, true)
        StartFreezeKeepAlive(plate, vehicle, raisedZ)
    end

    RegisterStandTargets(plate, side, stand1NetId, stand2NetId)
end)

RegisterNetEvent('mnc-jacks:lowerVehicle', function(plate, sidesStillRaised)
    local vehicle = nil
    for _, v in ipairs(GetGamePool('CVehicle')) do
        if NormalisePlate(GetVehicleNumberPlateText(v)) == plate then vehicle = v; break end
    end
    if not vehicle then return end

    StopFreezeKeepAlive(plate)
    FreezeEntityPosition(vehicle, true)

    local lowerBy = (sidesStillRaised and sidesStillRaised > 0) and (Config.Lift.RaiseHeight * 0.5) or Config.Lift.RaiseHeight
    local startZ = GetEntityCoords(vehicle).z
    local targetZ = startZ - lowerBy

    local groundFound, groundZ = GetGroundZFor_3dCoord(GetEntityCoords(vehicle).x, GetEntityCoords(vehicle).y, startZ, false)
    if groundFound then targetZ = math.max(targetZ, groundZ) end

    local dropped = 0.0
    while dropped < (startZ - targetZ) do
        dropped = math.min(dropped + 0.005, startZ - targetZ)
        local cur = GetEntityCoords(vehicle)
        SetEntityCoordsNoOffset(vehicle, cur.x, cur.y, startZ - dropped, false, false, false)
        Wait(20)
    end

    if sidesStillRaised and sidesStillRaised > 0 then
        StartFreezeKeepAlive(plate, vehicle, targetZ)
        Notify('Car Jack', 'One side lowered. Remove the other side to finish.', 'inform')
    else
        FreezeEntityPosition(vehicle, false)
        Notify('Car Jack', 'Vehicle fully lowered.', 'success')
    end
end)

RegisterNetEvent('mnc-jacks:deleteMyStandProps', function(netId1, netId2)
    DeleteMyProp(netId1)
    DeleteMyProp(netId2)
end)

-- ====================== STAND REMOVAL ======================
RegisterNetEvent('mnc-jacks:client:removeStands', function(plate, side)
    local key = plate .. '_' .. side
    if removalInProgress[key] then return Notify('Axle Stand', 'Removal already in progress.', 'error') end

    local ok, reason = lib.callback.await('mnc-jacks:canLowerSide', false, plate, side)
    if not ok then Notify('Axle Stand', reason, 'error'); return end

    removalInProgress[key] = true

    local vehicle = nil
    for _, v in ipairs(GetGamePool('CVehicle')) do
        if NormalisePlate(GetVehicleNumberPlateText(v)) == plate then vehicle = v; break end
    end
    if not vehicle then
        removalInProgress[key] = nil
        return
    end

    for i = 1, Config.Lift.StandsPerSide do
        local offsets = Config.Lift.StandOffsets[side][i]
        local vehPos  = GetEntityCoords(vehicle)
        local vehHead = GetEntityHeading(vehicle)
        local rad = math.rad(vehHead)
        local c, sn = math.cos(rad), math.sin(rad)

        local wx = vehPos.x + (offsets.x * c - offsets.y * sn)
        local wy = vehPos.y + (offsets.x * sn + offsets.y * c)
        local wz = GetGroundZ(wx, wy, vehPos.z)

        local pressed, aborted = WaitForEPress(vector3(wx, wy, wz),
            ('Press ~INPUT_CONTEXT~ to remove stand %d/%d'):format(i, Config.Lift.StandsPerSide), 255, 80, 80)

        if aborted or not pressed then
            removalInProgress[key] = nil
            Notify('Axle Stand', 'Removal cancelled.', 'inform')
            return
        end

        local ok2 = DoStandAnim(('Removing axle stand %d/%d...'):format(i, Config.Lift.StandsPerSide),
            Config.Lift.StandDuration, side, vehicle)

        if not ok2 then
            removalInProgress[key] = nil
            Notify('Axle Stand', 'Removal cancelled.', 'inform')
            return
        end

        -- Remove target zone immediately for visual feedback
        exports['qb-target']:RemoveZone('mnc_stand_' .. plate .. '_' .. side .. '_' .. i)

        Notify('Axle Stand', ('Stand %d/%d removed'):format(i, Config.Lift.StandsPerSide), 'success', 1800)
    end

    removalInProgress[key] = nil
    registeredStands[key] = nil

    TriggerServerEvent('mnc-jacks:lowerSide', plate, side)
end)

-- ====================== CLEANUP ======================
local function CleanupStands(plate)
    plate = NormalisePlate(plate)
    StopFreezeKeepAlive(plate)
    if activeSession and activeSession.plate == plate then activeSession = nil end

    for _, side in ipairs({'left', 'right'}) do
        local key = plate .. '_' .. side
        exports['qb-target']:RemoveZone('mnc_stand_' .. plate .. '_' .. side .. '_1')
        exports['qb-target']:RemoveZone('mnc_stand_' .. plate .. '_' .. side .. '_2')
        registeredStands[key] = nil
        removalInProgress[key] = nil
        RemoveJackFloorProp(plate, side)
    end
end

RegisterNetEvent('mnc-jacks:cleanup', function(plate)
    CleanupStands(plate)
end)

RegisterNetEvent('mnc-parking:vehicleRecalled', function(plate)
    CleanupStands(plate)
end)

RegisterNetEvent('mnc-parking:vehicleUntracked', function(plate)
    CleanupStands(plate)
end)

if Config.Debug then
    print('^2[mnc-jacks]^7 client.lua loaded successfully.')
end