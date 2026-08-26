local trailerEntity = nil
local isNearTrailer = false
local isTowingVehicle = false
local nuiVisible = false
local nuiHiddenByUser = false
local trailerLoads = {}
local vehicleSlotInfo = {}
local pendingAttachment = nil
local liftState = nil
local positioningState = nil
local pendingUnload = nil
local unloadLowerState = nil

local function ShowNotification(msg, type)
    exports.ox_lib:notify({
        title = 'CAR TRANSPORTER',
        description = msg,
        type = type or 'inform',
        position = 'top-right',
    })
end

local function GetControlLabel(control)
    local labels = {
        [38] = 'E',
        [29] = 'B',
    }
    return labels[control] or tostring(control)
end

local function FindNearestTrailer()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local nearest, minDist = nil, Config.LoadDistance

    for _, veh in ipairs(vehicles) do
        if GetEntityModel(veh) == Config.TrailerModel then
            local vcoords = GetEntityCoords(veh)
            local dist = #(coords - vcoords)
            if dist < minDist then
                nearest = veh
                minDist = dist
            end
        end
    end
    return nearest
end


local function IsVehicleTowingTrailer(vehicle)
    local hasTrailer, trailer = GetVehicleTrailerVehicle(vehicle)
    return hasTrailer and trailer ~= 0 and DoesEntityExist(trailer) and GetEntityModel(trailer) == Config.TrailerModel
end


local function IsDrivingTowingVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return false end

    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or not DoesEntityExist(veh) then return false end
    if GetPedInVehicleSeat(veh, -1) ~= ped then return false end

    return IsVehicleTowingTrailer(veh)
end

-- A separate script binds its own controls to the forklift (E / B / arrow keys) which
-- collide with this script's keybinds, so the entire car transporter UI + logic gets
-- disabled while the player is riding one of Config.ForkliftModels.
local function IsInForklift()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return false end

    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or not DoesEntityExist(veh) then return false end

    local model = GetEntityModel(veh)
    for _, forkliftModel in ipairs(Config.ForkliftModels) do
        if model == forkliftModel then
            return true
        end
    end
    return false
end


local function RegisterSlot(trailerNet, vehicleNet, level, slot)
    trailerLoads[trailerNet] = trailerLoads[trailerNet] or {}
    trailerLoads[trailerNet][level] = trailerLoads[trailerNet][level] or {}
    trailerLoads[trailerNet][level][slot] = vehicleNet
    vehicleSlotInfo[vehicleNet] = { trailerNet = trailerNet, level = level, slot = slot }
end

local function ReleaseSlot(trailerNet, vehicleNet)
    local info = vehicleSlotInfo[vehicleNet]
    if info and trailerLoads[info.trailerNet] and trailerLoads[info.trailerNet][info.level] then
        trailerLoads[info.trailerNet][info.level][info.slot] = nil
    end
    vehicleSlotInfo[vehicleNet] = nil
end

local function GetSlotOccupant(trailerNet, level, slot)
    local levelData = trailerLoads[trailerNet] and trailerLoads[trailerNet][level]
    return levelData and levelData[slot] or nil
end

local function GetAvailableSlot(trailerNet, level)
    for slot = 1, Config.MaxVehiclesPerLevel do
        if not GetSlotOccupant(trailerNet, level, slot) then
            return slot
        end
    end
    return Config.MaxVehiclesPerLevel + 1 -- full
end


local function CanDetachVehicle(trailerNet, level, slot)
    local backSlot = Config.MaxVehiclesPerLevel

    if level == 2 then
        if GetSlotOccupant(trailerNet, 1, backSlot) then
            return false, "Clear the back of the bottom level first"
        end
        return true
    end

    -- Level 1: everything behind this slot (closer to the back) must already be unloaded
    for s = slot + 1, backSlot do
        if GetSlotOccupant(trailerNet, level, s) then
            return false, "Unload the vehicles behind it first"
        end
    end

    return true
end

local function GetNextVehicleToUnload(trailerNet)
    local backSlot = Config.MaxVehiclesPerLevel

    for s = backSlot, 1, -1 do
        local vehicleNet = GetSlotOccupant(trailerNet, 1, s)
        if vehicleNet and CanDetachVehicle(trailerNet, 1, s) then
            return vehicleNet, 1, s
        end
    end

    for s = backSlot, 1, -1 do
        local vehicleNet = GetSlotOccupant(trailerNet, 2, s)
        if vehicleNet and CanDetachVehicle(trailerNet, 2, s) then
            return vehicleNet, 2, s
        end
    end

    return nil
end


local function CaptureRelativeTransform(trailer, vehicle)
    local offset = GetOffsetFromEntityGivenWorldCoords(trailer, GetEntityCoords(vehicle))
    local trailerRot = GetEntityRotation(trailer, 2)
    local vehRot = GetEntityRotation(vehicle, 2)
    local relRot = vehRot - trailerRot
    return offset, relRot
end

-- ===== Attach / detach =====

local function AttachVehicleToTrailer(trailer, vehicle, level, slot, offset, rot)
    local trailerNet = NetworkGetNetworkIdFromEntity(trailer)
    local vehicleNet = NetworkGetNetworkIdFromEntity(vehicle)

    AttachEntityToEntity(vehicle, trailer, 0, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, false, false, false, false, 2, true)
    SetEntityCollision(vehicle, false, false)
    SetVehicleGravity(vehicle, false)

    RegisterSlot(trailerNet, vehicleNet, level, slot)
    TriggerServerEvent('mnc-cartransporter:attachVehicle', trailerNet, vehicleNet, level, slot, offset, rot)

    ShowNotification("Vehicle loaded onto level " .. level, 'success')
end

local function DetachVehicleFromTrailer(trailer, vehicle)
    local trailerNet = NetworkGetNetworkIdFromEntity(trailer)
    local vehicleNet = NetworkGetNetworkIdFromEntity(vehicle)

    if DoesEntityExist(vehicle) then
        if IsEntityAttached(vehicle) then
            DetachEntity(vehicle, true, true)
        end
        SetEntityCollision(vehicle, true, true)
        SetVehicleGravity(vehicle, true)
    end

    ReleaseSlot(trailerNet, vehicleNet)
    TriggerServerEvent('mnc-cartransporter:detachVehicle', trailerNet, vehicleNet)
    ShowNotification("Vehicle unloaded", 'success')
end

-- ===== Lift (move from level 1 up towards level 2) =====

local function UpdateLiftPosition(state, liftOffset)
    local z = state.baseOffset.z + liftOffset
    AttachEntityToEntity(state.vehicle, state.trailer, 0, state.baseOffset.x, state.baseOffset.y, z, state.baseRot.x, state.baseRot.y, state.baseRot.z, false, false, false, false, 2, true)
end

local function ReturnToLevel1(state)
    local slot = GetAvailableSlot(state.trailerNet, 1)
    if slot > Config.MaxVehiclesPerLevel then
        -- Bottom level filled up while this vehicle was mid-lift - fully unload it instead of leaving it stuck.
        DetachVehicleFromTrailer(state.trailer, state.vehicle)
        SendNUIMessage({ action = 'setLiftMode', active = false })
        return
    end

    AttachVehicleToTrailer(state.trailer, state.vehicle, 1, slot, state.baseOffset, state.baseRot)
    SendNUIMessage({ action = 'setLiftMode', active = false })
    ShowNotification("Top level was full - vehicle secured back on the bottom level", 'inform')
end

local function CancelLevelMovement(state)
    DetachVehicleFromTrailer(state.trailer, state.vehicle)
    SendNUIMessage({ action = 'setLiftMode', active = false })
end

-- Lift has reached the top: release it and let the player actually drive it into place.
local function BeginPositioning(state)
    positioningState = {
        trailer = state.trailer,
        trailerNet = state.trailerNet,
        vehicle = state.vehicle,
        vehicleNet = state.vehicleNet,
        slot = state.slot,
        baseOffset = state.baseOffset,
        baseRot = state.baseRot,
    }

    if DoesEntityExist(state.vehicle) then
        if IsEntityAttached(state.vehicle) then
            DetachEntity(state.vehicle, true, true)
        end
        SetEntityCollision(state.vehicle, true, true)
        SetVehicleGravity(state.vehicle, true)
    end

    SendNUIMessage({ action = 'setLiftMode', active = true, stage = 'positioning', progress = 1.0 })
    ShowNotification("Drive into position, then press " .. Config.LoadKeyLabel .. " to secure it", 'inform')
end


local function FinalizePositioning()
    local state = positioningState
    positioningState = nil

    local slot = GetAvailableSlot(state.trailerNet, 2)
    if slot > Config.MaxVehiclesPerLevel then
        ShowNotification("Top level is full", 'error')
        ReturnToLevel1(state)
        return
    end

    local offset, rot = CaptureRelativeTransform(state.trailer, state.vehicle)
    AttachVehicleToTrailer(state.trailer, state.vehicle, 2, slot, offset, rot)

    SendNUIMessage({ action = 'setLiftMode', active = false })
    ShowNotification("Vehicle secured on the top level", 'success')
end

local function StartLiftMode()
    if not pendingAttachment then return end

    if Config.NumLevels < 2 then
        ShowNotification("No level above this one", 'error')
        pendingAttachment = nil
        return
    end

    -- Leaving level 1 for now - free the slot locally, it'll be re-registered wherever it ends up.
    ReleaseSlot(pendingAttachment.trailerNet, pendingAttachment.vehicleNet)

    liftState = {
        trailer = pendingAttachment.trailer,
        trailerNet = pendingAttachment.trailerNet,
        vehicle = pendingAttachment.vehicle,
        vehicleNet = pendingAttachment.vehicleNet,
        slot = pendingAttachment.slot,
        baseOffset = pendingAttachment.baseOffset,
        baseRot = pendingAttachment.baseRot,
        liftOffset = 0.0,
    }
    pendingAttachment = nil

    SendNUIMessage({ action = 'setLiftMode', active = true, stage = 'lifting', progress = 0.0 })
    ShowNotification("Hold UP to lift the vehicle, DOWN to lower it, BACKSPACE to cancel", 'inform')
end

local function FinalizeAttachment()
    pendingAttachment = nil
    ShowNotification("Vehicle secured on the bottom level", 'success')
end

local function CancelPendingAttachment()
    if not pendingAttachment then return end
    DetachVehicleFromTrailer(pendingAttachment.trailer, pendingAttachment.vehicle)
    pendingAttachment = nil
end

local function BeginAttachmentFlow(trailer, vehicle)
    local trailerNet = NetworkGetNetworkIdFromEntity(trailer)
    local vehicleNet = NetworkGetNetworkIdFromEntity(vehicle)

    local slot = GetAvailableSlot(trailerNet, 1)
    if slot > Config.MaxVehiclesPerLevel then
        ShowNotification("Bottom level full! Unload a vehicle first.", 'error')
        return
    end

    local baseOffset, baseRot = CaptureRelativeTransform(trailer, vehicle)

    AttachVehicleToTrailer(trailer, vehicle, 1, slot, baseOffset, baseRot)

    pendingAttachment = {
        trailer = trailer,
        trailerNet = trailerNet,
        vehicle = vehicle,
        vehicleNet = vehicleNet,
        level = 1,
        slot = slot,
        baseOffset = baseOffset,
        baseRot = baseRot,
    }

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'showAttachModal', level = 1, slot = slot, canMoveUp = Config.NumLevels >= 2 })
end

local function TryLoadVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local currentVeh = GetVehiclePedIsIn(ped, false)
    if currentVeh == 0 or not DoesEntityExist(currentVeh) then return end
    if GetPedInVehicleSeat(currentVeh, -1) ~= ped then return end

    if IsVehicleTowingTrailer(currentVeh) then
        ShowNotification("You can't attach the vehicle that's towing the trailer", 'error')
        return
    end

    -- Pressing the load key again while positioning on level 2 secures it in place.
    if positioningState then
        if positioningState.vehicle == currentVeh then
            FinalizePositioning()
        else
            ShowNotification("Finish the current loading action first", 'error')
        end
        return
    end

    if pendingAttachment or liftState or pendingUnload or unloadLowerState then
        ShowNotification("Finish the current loading action first", 'error')
        return
    end

    local vehicleNet = NetworkGetNetworkIdFromEntity(currentVeh)
    if vehicleSlotInfo[vehicleNet] then
        ShowNotification("This vehicle is already on the trailer", 'error')
        return
    end

    local trailer = FindNearestTrailer()
    if not trailer then
        ShowNotification("No trailer nearby", 'error')
        return
    end

    BeginAttachmentFlow(trailer, currentVeh)
end


local function BeginUnloadFlow(trailer, vehicle, level, slot)
    local trailerNet = NetworkGetNetworkIdFromEntity(trailer)
    local vehicleNet = NetworkGetNetworkIdFromEntity(vehicle)

    pendingUnload = {
        trailer = trailer,
        trailerNet = trailerNet,
        vehicle = vehicle,
        vehicleNet = vehicleNet,
        level = level,
        slot = slot,
    }

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'showUnloadModal', level = level, slot = slot })
end

local function CancelPendingUnload()
    pendingUnload = nil
end


local function CancelUnloadLowering(state)
    AttachVehicleToTrailer(state.trailer, state.vehicle, state.level, state.slot, state.baseOffset, state.baseRot)
    SendNUIMessage({ action = 'setLiftMode', active = false })
    ShowNotification("Unload cancelled - vehicle secured back on the top level", 'inform')
end

local function FinalizeUnloadLowering(state)
    if not DoesEntityExist(state.vehicle) then
        SendNUIMessage({ action = 'setLiftMode', active = false })
        ReleaseSlot(state.trailerNet, state.vehicleNet) -- stale record, clean it up
        return
    end

    local backSlot = Config.MaxVehiclesPerLevel
    if GetSlotOccupant(state.trailerNet, 1, backSlot) then
        ShowNotification("Clear the back of the bottom level first", 'error')
        CancelUnloadLowering(state)
        return
    end

    local ped = PlayerPedId()
    SetPedIntoVehicle(ped, state.vehicle, -1)
    DetachVehicleFromTrailer(state.trailer, state.vehicle)
    SendNUIMessage({ action = 'setLiftMode', active = false })
end

local function BeginUnloadLowering(trailer, vehicle, level, slot)
    local trailerNet = NetworkGetNetworkIdFromEntity(trailer)
    local vehicleNet = NetworkGetNetworkIdFromEntity(vehicle)
    local offset, rot = CaptureRelativeTransform(trailer, vehicle)

    -- Leaving level 2 for now - free the slot locally, it'll be re-registered if cancelled.
    ReleaseSlot(trailerNet, vehicleNet)

    unloadLowerState = {
        trailer = trailer,
        trailerNet = trailerNet,
        vehicle = vehicle,
        vehicleNet = vehicleNet,
        level = level,
        slot = slot,
        baseOffset = offset,
        baseRot = rot,
        lowerOffset = 0.0,
    }

    SendNUIMessage({ action = 'setLiftMode', active = true, stage = 'lowering', progress = 0.0 })
    ShowNotification("Hold DOWN to lower, UP to raise back, ENTER when it's at the height you want, BACKSPACE to cancel", 'inform')
end

local function ConfirmUnload()
    local state = pendingUnload
    pendingUnload = nil
    if not state then return end

    if not DoesEntityExist(state.vehicle) then
        ReleaseSlot(state.trailerNet, state.vehicleNet) -- stale record, clean it up
        return
    end

    local backSlot = Config.MaxVehiclesPerLevel
    if GetSlotOccupant(state.trailerNet, 1, backSlot) then
        ShowNotification("Clear the back of the bottom level first", 'error')
        return
    end

    BeginUnloadLowering(state.trailer, state.vehicle, state.level, state.slot)
end

local function TryUnloadVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        ShowNotification("Get in the vehicle that's towing the trailer", 'error')
        return
    end

    local towVeh = GetVehiclePedIsIn(ped, false)
    if towVeh == 0 or not DoesEntityExist(towVeh) then return end

    if GetPedInVehicleSeat(towVeh, -1) ~= ped then
        ShowNotification("You must be driving the towing vehicle to unload", 'error')
        return
    end

    if pendingAttachment or liftState or positioningState or pendingUnload or unloadLowerState then
        ShowNotification("Finish the current loading action first", 'error')
        return
    end

    -- Unload is done from the vehicle towing the trailer, not from the loaded vehicles themselves.
    if not IsVehicleTowingTrailer(towVeh) then
        ShowNotification("Not towing a trailer", 'error')
        return
    end

    local hasTrailer, trailer = GetVehicleTrailerVehicle(towVeh)
    local trailerNet = NetworkGetNetworkIdFromEntity(trailer)
    local vehicleNet, level, slot = GetNextVehicleToUnload(trailerNet)
    if not vehicleNet then
        ShowNotification("Nothing left to unload", 'error')
        return
    end

    local vehicle = NetworkGetEntityFromNetworkId(vehicleNet)
    if not DoesEntityExist(vehicle) then
        ReleaseSlot(trailerNet, vehicleNet) -- stale record, clean it up
        return
    end

    if level == 2 then
        BeginUnloadFlow(trailer, vehicle, level, slot)
        return
    end

    DetachVehicleFromTrailer(trailer, vehicle)
end

-- ===== UI =====

local function SendHelperState()
    SendNUIMessage({
        action = 'setState',
        nearTrailer = true,
        loadLabel = Config.LoadKeyLabel,
        unloadLabel = GetControlLabel(Config.UnloadControl),
        toggleUiLabel = Config.ToggleUIKeyLabel,
        maxPerLevel = Config.MaxVehiclesPerLevel,
        numLevels = Config.NumLevels,
        isTowing = isTowingVehicle,
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


local function CanUseTransporter()
    if pendingAttachment or liftState or positioningState or pendingUnload or unloadLowerState then return true end
    return isNearTrailer or IsDrivingTowingVehicle()
end

RegisterNUICallback('attachModalChoice', function(data, cb)
    local choice = data and data.choice

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideAttachModal' })

    if choice == 'moveUp' then
        StartLiftMode()
    elseif choice == 'cancel' then
        CancelPendingAttachment()
    else
        FinalizeAttachment()
    end

    cb('ok')
end)

RegisterNUICallback('unloadModalChoice', function(data, cb)
    local choice = data and data.choice

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideUnloadModal' })

    if choice == 'unload' then
        ConfirmUnload()
    else
        CancelPendingUnload()
    end

    cb('ok')
end)

-- Main loop - proximity for the HUD + load/unload keys
CreateThread(function()
    while true do
        Wait(0)

        if IsInForklift() then
            -- Fully disabled while in a forklift: a separate script binds the same keys
            -- (E / B / arrow keys) to its own forklift controls.
            SetHelperVisible(false)
            trailerEntity = nil
            isNearTrailer = false
        else
            local trailer = FindNearestTrailer()
            isNearTrailer = trailer ~= nil

            if isNearTrailer then
                SetHelperVisible(true)
                trailerEntity = trailer
            else
                SetHelperVisible(false)
                trailerEntity = nil
            end


            local towing = IsDrivingTowingVehicle()
            if towing ~= isTowingVehicle then
                isTowingVehicle = towing
                if nuiVisible then SendHelperState() end
            end

            if IsControlJustPressed(0, Config.LoadControl) then
                if CanUseTransporter() then
                    TryLoadVehicle()
                end
            end

            if IsControlJustPressed(0, Config.UnloadControl) then
                if CanUseTransporter() then
                    TryUnloadVehicle()
                end
            end
        end
    end
end)

-- Lift / positioning / lowering loop - only ticks fast while one of those is actually in progress
CreateThread(function()
    while true do
        if IsInForklift() then
            -- Same forklift key-conflict guard: freeze any in-progress lift/positioning/lowering
            -- action rather than let the forklift script's controls drive it.
            Wait(250)
        elseif liftState then
            local dt = GetFrameTime()

            if IsControlJustPressed(0, Config.LiftCancelControl) then
                local state = liftState
                liftState = nil
                CancelLevelMovement(state)
            else
                local changed = false
                if IsControlPressed(0, Config.LiftUpControl) then
                    liftState.liftOffset = math.min(Config.MaxLiftOffset, liftState.liftOffset + Config.LiftSpeed * dt)
                    changed = true
                elseif IsControlPressed(0, Config.LiftDownControl) then
                    liftState.liftOffset = math.max(Config.MinLiftOffset, liftState.liftOffset - Config.LiftSpeed * dt)
                    changed = true
                end

                if changed then
                    UpdateLiftPosition(liftState, liftState.liftOffset)
                    local progress = (liftState.liftOffset - Config.MinLiftOffset) / (Config.MaxLiftOffset - Config.MinLiftOffset)
                    SendNUIMessage({ action = 'setLiftMode', active = true, stage = 'lifting', progress = progress })

                    if liftState.liftOffset >= Config.MaxLiftOffset then
                        local state = liftState
                        liftState = nil
                        BeginPositioning(state)
                    end
                end
            end

            Wait(0)
        elseif positioningState then
            if IsControlJustPressed(0, Config.LiftCancelControl) then
                local state = positioningState
                positioningState = nil
                CancelLevelMovement(state)
            end
            Wait(0)
        elseif unloadLowerState then
            local dt = GetFrameTime()

            if IsControlJustPressed(0, Config.LiftCancelControl) then
                local state = unloadLowerState
                unloadLowerState = nil
                CancelUnloadLowering(state)
            elseif IsControlJustPressed(0, Config.LiftConfirmControl) then

                local state = unloadLowerState
                unloadLowerState = nil
                FinalizeUnloadLowering(state)
            else
                local changed = false
                if IsControlPressed(0, Config.LiftDownControl) then
                    unloadLowerState.lowerOffset = math.max(-Config.MaxLiftOffset, unloadLowerState.lowerOffset - Config.LiftSpeed * dt)
                    changed = true
                elseif IsControlPressed(0, Config.LiftUpControl) then
                    unloadLowerState.lowerOffset = math.min(0.0, unloadLowerState.lowerOffset + Config.LiftSpeed * dt)
                    changed = true
                end

                if changed then
                    UpdateLiftPosition(unloadLowerState, unloadLowerState.lowerOffset)
                    local progress = (-unloadLowerState.lowerOffset) / Config.MaxLiftOffset
                    SendNUIMessage({ action = 'setLiftMode', active = true, stage = 'lowering', progress = progress })
                end
            end

            Wait(0)
        else
            Wait(250)
        end
    end
end)

RegisterNetEvent('mnc-cartransporter:syncAttachment')
AddEventHandler('mnc-cartransporter:syncAttachment', function(trailerNet, vehicleNet, level, slot, offset, rotation)
    RegisterSlot(trailerNet, vehicleNet, level, slot)

    local trailer = NetworkGetEntityFromNetworkId(trailerNet)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNet)
    if DoesEntityExist(trailer) and DoesEntityExist(vehicle) then
        AttachEntityToEntity(vehicle, trailer, 0, offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, false, false, false, false, 2, true)
        SetEntityCollision(vehicle, false, false)
        SetVehicleGravity(vehicle, false)
    end
end)

RegisterNetEvent('mnc-cartransporter:syncDetach')
AddEventHandler('mnc-cartransporter:syncDetach', function(trailerNet, vehicleNet)
    ReleaseSlot(trailerNet, vehicleNet)

    local vehicle = NetworkGetEntityFromNetworkId(vehicleNet)
    if DoesEntityExist(vehicle) then
        if IsEntityAttached(vehicle) then
            DetachEntity(vehicle, true, true)
        end
        SetEntityCollision(vehicle, true, true)
        SetVehicleGravity(vehicle, true)
    end
end)


RegisterKeyMapping('mnc_cartransporter_toggleui_v2', 'Toggle Car Transporter UI', 'keyboard', 'H')
RegisterCommand('mnc_cartransporter_toggleui_v2', function()
    nuiHiddenByUser = not nuiHiddenByUser
    SetHelperVisible(isNearTrailer)
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    SetNuiFocus(false, false)
end)