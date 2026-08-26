-- client.lua — mnc-freecam-v3

-- ─────────────────────────────────────────────
-- Screen filters
-- ─────────────────────────────────────────────
local filters = {
    "None","FocusOut","ChopVision","DMT_flight","DrugsMichaelAliensFight",
    "DrugsTrevorClownsFight","HeistCelebPass","HeistCelebPassBW","MP_Bull_tost",
    "SniperOverlay","Rampage","DeathFailMPDark","PPFilter","PPGreen","PPOrange",
    "PPPink","PPPurple","BikerFilter","LostTimeDay","LostTimeNight","InchOrange",
    "InchPurple","DeadlineNeon","MP_Powerplay","Dont_tazeme_bro","DrugsDrivingIn",
    "RaceTurbo","ExplosionJosh3","DefaultFlash","MP_OrbitalCannon","MP_Killstreak",
    "yell_tunnel_nodirect",
}

-- ─────────────────────────────────────────────
-- Freecam state
-- ─────────────────────────────────────────────
local currentFilterIndex = 1
local cam                = nil
local freeCamActive      = false
local currentFOV         = 90.0
local rollAngle          = 0.0
local helpersVisible     = true
local pedHidden          = false

local dofEnabled    = false
local dofNearDist   = 1.0
local dofFarDist    = 15.0
local dofStrength   = 1.0

local shakeEnabled   = false
local shakeAmplitude = 0.0

local barsEnabled = false
local barsSize    = 0.08

local tcStrength = 1.0

-- ─────────────────────────────────────────────
-- Wheel turn state
-- ─────────────────────────────────────────────
local wheelAngle    = 0.0
local WHEEL_MAX     = 60.0
local WHEEL_STEP    = 1.0

-- ─────────────────────────────────────────────
-- Cinematic state
-- ─────────────────────────────────────────────
local cinematicOpen    = false
local cinematicSetup   = false
local setupType        = 'world'
local setupVehicle     = nil

local keyframes        = {}
local sequences        = {}
local activeSequence   = nil

local playbackActive   = false
local playbackMode     = 'once'
local playbackIndex    = 1
local playbackDir      = 1
local playbackCam      = nil
local globalDuration   = 3.0

-- ─────────────────────────────────────────────
-- Camera switcher state
-- ─────────────────────────────────────────────
local camSwitcherOpen  = false
local activeCamMode    = 'freecam'

-- /camsets standalone mode — cam switcher active without freecam open
local camSetsActive    = false

-- Scripted cam used during capture mode when NOT in freecam
local captureCam       = nil

-- Scripted cam used for vehicle-cam positioning in standalone /camsets mode
local camSetsCam       = nil

local VEHICLE_CAM_MODES = {
    { id = 0,           label = 'Bumper Cam',   cycleHiddenDefault = false },
    { id = 1,           label = 'Close Follow', cycleHiddenDefault = false },
    { id = 2,           label = 'Far Follow',   cycleHiddenDefault = false },
    { id = 3,           label = 'Wide Follow',  cycleHiddenDefault = false },
    { id = 'cinematic', label = 'Cinematic',    cycleHiddenDefault = true  },
    { id = 4,           label = 'Driver View',  cycleHiddenDefault = false },
    { id = 5,           label = 'Side Left',    cycleHiddenDefault = false },
    { id = 6,           label = 'Side Right',   cycleHiddenDefault = false },
    { id = 7,           label = 'Overhead',     cycleHiddenDefault = false },
}

-- ─────────────────────────────────────────────
-- Per-citizen cam flags + custom cams (SQL-backed, loaded on open)
-- _camFlags[camId] = { cycleHidden, hidePeds, autoHeadTrack }
-- _customCams      = { {id=N, label=''}, ... }
-- _flagsLoaded     = false until server delivers receiveCamFlags
-- ─────────────────────────────────────────────
local _camFlags   = {}   -- [camId string] = { cycleHidden, hidePeds, autoHeadTrack }
local _customCams = {}   -- { {id=N, label=''}, ... }

-- Write-through: persist one cam's flag block to server
local function saveCamFlag(camId)
    local f = _camFlags[camId] or {}
    TriggerServerEvent('mnc-freecam:saveCamFlag', {
        cam_id          = camId,
        cycle_hidden    = f.cycleHidden    or false,
        hide_peds       = f.hidePeds       or false,
        auto_head_track = f.autoHeadTrack  or false,
    })
end

local function isCycleHidden(camId, defaultHidden)
    local f = _camFlags[tostring(camId)]
    if f and f.cycleHiddenSet then return f.cycleHidden end
    return defaultHidden or false
end

local function setCycleHidden(camId, hidden)
    camId = tostring(camId)
    if not _camFlags[camId] then _camFlags[camId] = {} end
    _camFlags[camId].cycleHidden    = hidden
    _camFlags[camId].cycleHiddenSet = true
    saveCamFlag(camId)
end

local function isHidePeds(camId)
    local f = _camFlags[tostring(camId)]
    return f and f.hidePeds or false
end

local function setHidePeds(camId, hide)
    camId = tostring(camId)
    if not _camFlags[camId] then _camFlags[camId] = {} end
    _camFlags[camId].hidePeds = hide
    saveCamFlag(camId)
end

local function isAutoHeadTrack(camId)
    if camId == 'vehicle_4' then return true end
    local f = _camFlags[tostring(camId)]
    return f and f.autoHeadTrack or false
end

local function setAutoHeadTrack(camId, enabled)
    if camId == 'vehicle_4' then return end
    camId = tostring(camId)
    if not _camFlags[camId] then _camFlags[camId] = {} end
    _camFlags[camId].autoHeadTrack = enabled
    saveCamFlag(camId)
end

-- ─────────────────────────────────────────────
-- Per-model cam overrides (any cam with model_allowed enabled)
-- keyed by [mode_id][model_hash]
-- ─────────────────────────────────────────────
local _modelOffsetOverrides = {}   -- [modeId][hash] = {lx,ly,lz,init_pitch,init_yaw,init_roll,init_fov,model_name}

local function getModelCfg(modeId, modelHash)
    local byMode = _modelOffsetOverrides[tonumber(modeId)]
    if not byMode then return nil end
    return byMode[tonumber(modelHash)]
end

-- Apply ped hiding based on current cam
local _pedsHidden = false
local function applyPedHiding(camId)
    local wantHide = isHidePeds(tostring(camId))
    if wantHide == _pedsHidden then return end
    _pedsHidden = wantHide
    SetEntityVisible(PlayerPedId(), not wantHide, false)
end

local function restorePedVisibility()
    if not _pedsHidden then return end
    _pedsHidden = false
    SetEntityVisible(PlayerPedId(), true, false)
end

-- ─────────────────────────────────────────────
-- Head tracking state
-- headTrackEnabled: camera yaw smoothly follows vehicle steering angle
-- HEAD_TRACK_SCALE: multiplier on steering degrees — keep low for subtle feel
-- HEAD_TRACK_LERP:  per-frame lerp fraction — lower = smoother but slower to respond
-- ─────────────────────────────────────────────
local headTrackEnabled          = false
local _headTrackBeforeDriverCam = nil   -- saved state when driver cam auto-enables head tracking
local HEAD_TRACK_SCALE  = 0.6    -- real steer ~±35° × 0.6 → ~±21° yaw at full lock (subtle follow)
local HEAD_TRACK_LERP   = 0.08   -- fraction per frame toward target (0.08 ≈ smooth ~12-frame lag at 60fps)

-- ─────────────────────────────────────────────
-- Preset manager state (SQL-backed per citizenid)
-- _presets[slot] = { name, slot, fov, roll, ... }
-- ─────────────────────────────────────────────
local presetPanelOpen = false
local _presets        = {}   -- [slot] = preset table (nil if empty)

-- ─────────────────────────────────────────────
-- Key flags
-- ─────────────────────────────────────────────
local _rollLeft     = false
local _rollRight    = false
local _filterPrev   = false
local _filterNext   = false
local _camCycleNext = false

local _zPressedAt     = nil
local _dofToggleFired = false

-- ─────────────────────────────────────────────
-- NUI helpers
-- ─────────────────────────────────────────────
local function nuiSend(data)    SendNUIMessage(data) end
local function nuiUpdate(patch) patch.type = "update"; nuiSend(patch) end

local function nuiShow()
    nuiSend({
        type          = "show",
        fov           = currentFOV,
        filter        = filters[currentFilterIndex],
        dofEnabled    = dofEnabled,
        dofNear       = dofNearDist,
        dofFar        = dofFarDist,
        shake         = shakeAmplitude,
        bars          = barsEnabled and barsSize or 0.0,
        tcStrength    = tcStrength,
        wheelAngle    = wheelAngle,
        headTrack     = headTrackEnabled,
    })
end

local function nuiHide()
    nuiSend({ type = "hide" })
end

local function nuiCinematicOpen(seqList)
    nuiSend({ type = "cinematicOpen", sequences = seqList or sequences })
end

local function nuiCinematicClose()
    nuiSend({ type = "cinematicClose" })
end

-- ─────────────────────────────────────────────
-- Camera switcher NUI helpers
-- ─────────────────────────────────────────────
local function buildCamList()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local list = {}
    if DoesEntityExist(veh) then
        for _, entry in ipairs(VEHICLE_CAM_MODES) do
            local camId = 'vehicle_' .. tostring(entry.id)
            list[#list + 1] = {
                id            = camId,
                label         = entry.label,
                numericId     = type(entry.id) == 'number' and entry.id or nil,
                cycleHidden   = isCycleHidden(camId, entry.cycleHiddenDefault),
                hidePeds      = isHidePeds(camId),
                autoHeadTrack = isAutoHeadTrack(camId),
                custom        = false,
            }
        end
        for _, c in ipairs(_customCams) do
            local camId = 'vehicle_' .. tostring(c.id)
            list[#list + 1] = {
                id            = camId,
                label         = c.label,
                numericId     = c.id,
                cycleHidden   = isCycleHidden(camId, true),
                hidePeds      = isHidePeds(camId),
                autoHeadTrack = isAutoHeadTrack(camId),
                custom        = true,
            }
        end
    end
    list[#list + 1] = {
        id            = 'freecam',
        label         = 'Free Camera',
        numericId     = nil,
        cycleHidden   = isCycleHidden('freecam', true),
        hidePeds      = false,
        autoHeadTrack = false,
        custom        = false,
    }
    return list
end

local function nuiCamSwitcherOpen(standalone)
    nuiSend({
        type       = 'camSwitcherOpen',
        cameras    = buildCamList(),
        active     = activeCamMode,
        standalone = standalone or false,
        headTrack  = headTrackEnabled,
    })
end

local function nuiCamSwitcherClose()
    nuiSend({ type = 'camSwitcherClose' })
end

-- ─────────────────────────────────────────────
-- Preset in-RAM helpers
-- ─────────────────────────────────────────────
local function getAllPresets()
    local out = {}
    for slot = 1, 20 do
        if _presets[slot] then out[#out + 1] = _presets[slot] end
    end
    return out
end

local function findFreeSlot()
    for i = 1, 20 do
        if not _presets[i] then return i end
    end
    return nil
end

local function nuiPresetPanelOpen()  nuiSend({ type = 'presetPanelOpen',  presets = getAllPresets() }) end
local function nuiPresetPanelClose() nuiSend({ type = 'presetPanelClose' }) end

local function nuiUpdateKeyframes()  nuiSend({ type = "updateKeyframes", keyframes = keyframes }) end
local function nuiUpdateSequences()  nuiSend({ type = "updateSequences", sequences = sequences }) end

-- ─────────────────────────────────────────────
-- Notification helper
-- ─────────────────────────────────────────────
local function notify(ntype, msg)
    if lib and lib.notify then
        lib.notify({ title = 'FreeCam', description = msg, type = ntype })
    else
        TriggerEvent('chat:addMessage', { color = {255,200,0}, args = {'FreeCam', msg} })
    end
end

-- ─────────────────────────────────────────────
-- DOF / Shake / Filter
-- ─────────────────────────────────────────────
local function applyDOF()
    if not cam then return end
    if dofEnabled then
        SetCamUseShallowDofMode(cam, true)
        SetCamNearDof(cam, dofNearDist)
        SetCamFarDof(cam, dofFarDist)
        SetCamDofStrength(cam, dofStrength)
    else
        SetCamUseShallowDofMode(cam, false)
        SetCamDofStrength(cam, 0.0)
    end
end

local function applyShake(targetCam)
    local c = targetCam or cam
    if not c then return end
    if shakeEnabled and shakeAmplitude > 0.0 then
        ShakeCam(c, "HAND_SHAKE", shakeAmplitude)
    else
        StopCamShaking(c, true)
    end
end

local function applyFilter(index)
    if currentFilterIndex > 1 then
        local prev = filters[currentFilterIndex]
        if prev == "yell_tunnel_nodirect" then ClearTimecycleModifier()
        else StopScreenEffect(prev) end
    end
    currentFilterIndex = index
    if currentFilterIndex > 1 then
        local name = filters[currentFilterIndex]
        if name == "yell_tunnel_nodirect" then
            SetTimecycleModifier(name)
            SetTimecycleModifierStrength(tcStrength)
        else
            StartScreenEffect(name, 0, true)
        end
    end
end

local function cycleFilter(dir)
    local next = ((currentFilterIndex - 1 + dir) % #filters) + 1
    applyFilter(next)
    nuiUpdate({ filter = filters[currentFilterIndex] })
end

-- ─────────────────────────────────────────────
-- Wheel turn
-- ─────────────────────────────────────────────
local function resetWheelAngle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if DoesEntityExist(veh) then SetVehicleSteeringAngle(veh, 0.0) end
    wheelAngle = 0.0
    nuiUpdate({ wheelAngle = 0.0 })
end

local function isPlayerStationary()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(veh) then return false end
    return GetEntitySpeed(veh) < 0.5
end

-- ─────────────────────────────────────────────
-- Ped visibility
-- ─────────────────────────────────────────────
local function setPedVisible(visible)
    local ped = PlayerPedId()
    SetEntityVisible(ped, visible, false)
    pedHidden = not visible
    nuiUpdate({ pedHidden = pedHidden })
end

local function restorePed()
    if pedHidden then
        SetEntityVisible(PlayerPedId(), true, false)
        pedHidden = false
        nuiUpdate({ pedHidden = false })
    end
end

-- ─────────────────────────────────────────────
-- Reset effects
-- ─────────────────────────────────────────────
local function resetEffects()
    applyFilter(1)
    dofEnabled = false; shakeEnabled = false; shakeAmplitude = 0.0; barsEnabled = false
    if cam then
        SetCamUseShallowDofMode(cam, false)
        SetCamDofStrength(cam, 0.0)
        StopCamShaking(cam, true)
    end
    ClearTimecycleModifier()
    nuiUpdate({ filter="None", dofEnabled=false, dofNear=dofNearDist, dofFar=dofFarDist, shake=0.0, bars=0.0, tcStrength=tcStrength })
end

-- ─────────────────────────────────────────────
-- Camera math
-- ─────────────────────────────────────────────
-- Returns current flying cam (freecam or captureCam)
local function getActiveCam()
    return cam or captureCam
end

local function GetCamForwardVector()
    local c = getActiveCam()
    if not c then return vector3(0,1,0) end
    local rot = GetCamRot(c, 2)
    return vector3(
        -math.sin(math.rad(rot.z)) * math.abs(math.cos(math.rad(rot.x))),
         math.cos(math.rad(rot.z)) * math.abs(math.cos(math.rad(rot.x))),
         math.sin(math.rad(rot.x))
    )
end

local function GetCamRightVector()
    local fwd = GetCamForwardVector()
    return vector3(-fwd.y, fwd.x, 0.0)
end

-- ─────────────────────────────────────────────
-- Easing
-- ─────────────────────────────────────────────
local function easeInOut(t)
    return t < 0.5 and (4*t*t*t) or (1 - (-2*t+2)^3 / 2)
end

-- ─────────────────────────────────────────────
-- Playback
-- ─────────────────────────────────────────────
local function stopPlayback()
    if not playbackActive then return end
    playbackActive = false
    if DoesEntityExist(playbackCam) then DestroyCam(playbackCam, false) end
    playbackCam = nil
    if freeCamActive and cam then
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)
    end
    cinematicOpen = true
    TriggerServerEvent('mnc-freecam:loadMySequences')
    nuiCinematicOpen()
    SetNuiFocus(true, true)
    nuiShow()
    nuiUpdate({ playbackActive = false })
end

local function startPlayback(kframes, mode, veh)
    if #kframes < 2 then notify('error', 'Need at least 2 keyframes to play.'); return end
    if playbackActive then stopPlayback() end

    playbackActive = true
    playbackMode   = mode or 'once'
    playbackIndex  = 1
    playbackDir    = 1
    setupVehicle   = veh

    cinematicOpen = false
    nuiCinematicClose()
    SetNuiFocus(false, false)
    nuiHide()

    playbackCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamActive(playbackCam, true)
    RenderScriptCams(true, false, 0, true, true)
    nuiUpdate({ playbackActive = true, playbackMode = playbackMode })

    Citizen.CreateThread(function()
        local kf0 = kframes[1]
        local initPx, initPy, initPz = kf0.pos.x, kf0.pos.y, kf0.pos.z
        if veh and DoesEntityExist(veh) then
            local vp0 = GetEntityCoords(veh)
            local vr0 = GetEntityRotation(veh, 2)
            local h0  = math.rad(vr0.z)
            local c0, s0 = math.cos(h0), math.sin(h0)
            initPx = vp0.x + c0 * kf0.pos.x - s0 * kf0.pos.y
            initPy = vp0.y + s0 * kf0.pos.x + c0 * kf0.pos.y
            initPz = vp0.z + kf0.pos.z
        end
        SetCamCoord(playbackCam, initPx, initPy, initPz)
        SetCamRot(playbackCam, kf0.rot.x, kf0.rot.y, kf0.rot.z, 2)
        SetCamFov(playbackCam, kf0.fov or currentFOV)
        RequestCollisionAtCoord(initPx, initPy, initPz)
        local waitStart = GetGameTimer()
        while playbackActive and (GetGameTimer() - waitStart) < 4000 do
            if (GetGameTimer() - waitStart) % 500 < 16 then
                RequestCollisionAtCoord(initPx, initPy, initPz)
            end
            Citizen.Wait(0)
        end
        if not playbackActive then return end

        while playbackActive do
            local fromIdx = playbackIndex
            local toIdx   = playbackIndex + playbackDir
            if toIdx < 1 or toIdx > #kframes then
                if playbackMode == 'loop' then
                    playbackIndex = 1; toIdx = 2
                elseif playbackMode == 'pingpong' then
                    playbackDir = -playbackDir
                    toIdx = playbackIndex + playbackDir
                    if toIdx < 1 or toIdx > #kframes then stopPlayback(); break end
                else
                    stopPlayback(); break
                end
            end
            local kfFrom = kframes[fromIdx]
            local kfTo   = kframes[toIdx]
            local dur    = kfFrom.duration or globalDuration
            local steps  = math.max(1, math.floor(dur * 60))
            for i = 0, steps do
                if not playbackActive then break end
                local t  = i / steps
                local et = easeInOut(t)
                local px = kfFrom.pos.x + (kfTo.pos.x - kfFrom.pos.x) * et
                local py = kfFrom.pos.y + (kfTo.pos.y - kfFrom.pos.y) * et
                local pz = kfFrom.pos.z + (kfTo.pos.z - kfFrom.pos.z) * et
                local rx = kfFrom.rot.x + (kfTo.rot.x - kfFrom.rot.x) * et
                local ry = kfFrom.rot.y + (kfTo.rot.y - kfFrom.rot.y) * et
                local rz = kfFrom.rot.z + (kfTo.rot.z - kfFrom.rot.z) * et
                local fv = (kfFrom.fov or currentFOV) + ((kfTo.fov or currentFOV) - (kfFrom.fov or currentFOV)) * et
                if setupVehicle and DoesEntityExist(setupVehicle) then
                    local vehPosCur = GetEntityCoords(setupVehicle)
                    local vehRotCur = GetEntityRotation(setupVehicle, 2)
                    local headingRad = math.rad(vehRotCur.z)
                    local cosH = math.cos(headingRad); local sinH = math.sin(headingRad)
                    local wx = cosH * px - sinH * py; local wy = sinH * px + cosH * py
                    px = vehPosCur.x + wx; py = vehPosCur.y + wy; pz = vehPosCur.z + pz
                    rz = rz + vehRotCur.z
                end
                SetCamCoord(playbackCam, px, py, pz)
                SetCamRot(playbackCam, rx, ry, rz, 2)
                SetCamFov(playbackCam, fv)
                Citizen.Wait(0)
            end
            if playbackActive then playbackIndex = playbackIndex + playbackDir end
        end
    end)
end

-- ─────────────────────────────────────────────
-- Keyframe capture
-- ─────────────────────────────────────────────
local function captureKeyframe()
    if not cam then notify('error', 'No freecam active.'); return end
    local pos = GetCamCoord(cam)
    local rot = GetCamRot(cam, 2)
    local localPos, localRot
    if cinematicSetup and setupType == 'vehicle' and setupVehicle and DoesEntityExist(setupVehicle) then
        local vehPos = GetEntityCoords(setupVehicle)
        local vehRot = GetEntityRotation(setupVehicle, 2)
        local vehHeadingRad = math.rad(vehRot.z)
        local dx = pos.x - vehPos.x; local dy = pos.y - vehPos.y; local dz = pos.z - vehPos.z
        local cosH = math.cos(-vehHeadingRad); local sinH = math.sin(-vehHeadingRad)
        localPos = { x = cosH * dx - sinH * dy, y = sinH * dx + cosH * dy, z = dz }
        localRot = { x = rot.x, y = rot.y, z = rot.z - vehRot.z }
    else
        localPos = { x = pos.x, y = pos.y, z = pos.z }
        localRot = { x = rot.x, y = rot.y, z = rot.z }
    end
    local kf = { pos = localPos, rot = localRot, fov = currentFOV, duration = globalDuration, label = 'Frame ' .. (#keyframes + 1) }
    keyframes[#keyframes + 1] = kf
    nuiUpdateKeyframes()
    notify('success', 'Keyframe ' .. #keyframes .. ' captured')
end

local function removeKeyframe(idx)
    if keyframes[idx] then table.remove(keyframes, idx); nuiUpdateKeyframes() end
end

-- ─────────────────────────────────────────────
-- Toggle freecam
-- ─────────────────────────────────────────────
local function toggleFreeCam()
    if not freeCamActive then
        freeCamActive = true
        local ped = PlayerPedId()
        cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        local pos = GetEntityCoords(ped)
        SetCamCoord(cam, pos.x, pos.y, pos.z + 1.0)
        SetCamRot(cam, 0.0, 0.0, 0.0)
        SetCamFov(cam, currentFOV)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)
        DisplayHud(false); DisplayRadar(false)
        TriggerEvent('es:setMoneyDisplay', 0.0)
        FreezeEntityPosition(ped, true)
        -- Load offsets from DB — this is the authoritative source on every freecam open
        TriggerServerEvent('mnc-freecam:loadCamOffsets')
        TriggerServerEvent('mnc-freecam:loadModelOffsets')
        TriggerServerEvent('mnc-freecam:loadCamFlags')
        TriggerServerEvent('mnc-freecam:loadCustomCams')
        TriggerServerEvent('mnc-freecam:loadPresets')
        nuiShow()
    else
        if playbackActive   then stopPlayback() end
        if cinematicOpen    then cinematicOpen = false; nuiCinematicClose(); SetNuiFocus(false, false) end
        if cinematicSetup   then cinematicSetup = false; setupVehicle = nil; nuiSend({ type = 'setupModeActive', active = false }) end
        if camSwitcherOpen  then camSwitcherOpen = false; nuiCamSwitcherClose() end
        if presetPanelOpen  then presetPanelOpen = false; nuiPresetPanelClose() end
        if activeCamMode ~= 'freecam' then SetCinematicModeActive(false); activeCamMode = 'freecam' end
        _vehCamMode = nil; _camEditMode = false; _camEditModeId = nil
        _headTrackBeforeDriverCam = nil
        _camCaptureMode = false; _camCaptureVeh = nil
        if captureCam then DestroyCam(captureCam, false); captureCam = nil end
        _pendingCamMode = nil; _pendingCamFrames = 0
        freeCamActive = false
        restorePedVisibility()
        resetEffects(); resetWheelAngle(); restorePed()
        DestroyCam(cam, false)
        RenderScriptCams(false, false, 0, true, true)
        cam = nil
        rollAngle = 0.0; currentFOV = 90.0
        DisplayHud(true); DisplayRadar(true)
        TriggerEvent('es:setMoneyDisplay', 1.0)
        FreezeEntityPosition(PlayerPedId(), false)
        helpersVisible = true   -- always reset so next open shows panels fresh
        nuiHide()
        nuiSend({ type = "resetBars" })
    end
end

-- ─────────────────────────────────────────────
-- Toggle cinematic panel
-- ─────────────────────────────────────────────
local function toggleCinematicPanel()
    if not freeCamActive then return end
    cinematicOpen = not cinematicOpen
    if cinematicOpen then
        TriggerServerEvent('mnc-freecam:loadMySequences')
        nuiCinematicOpen()
        SetNuiFocus(true, true)
    else
        nuiCinematicClose()
        SetNuiFocus(false, false)
    end
end

-- ─────────────────────────────────────────────
-- Camera mode config
-- ─────────────────────────────────────────────
local CAM_MODE_OFFSETS = {
    [0] = { lx= 0.0,   ly=  2.5,  lz= 0.6,  initPitch= -5,  initYaw=0, initRoll=0, pitchClamp=25,  yawClamp=60  },
    [1] = { lx= 0.0,   ly= -4.0,  lz= 1.5,  initPitch= -8,  initYaw=0, initRoll=0, pitchClamp=30,  yawClamp=120 },
    [2] = { lx= 0.0,   ly= -9.0,  lz= 2.5,  initPitch=-10,  initYaw=0, initRoll=0, pitchClamp=30,  yawClamp=120 },
    [3] = { lx= 0.0,   ly=-14.0,  lz= 3.5,  initPitch=-12,  initYaw=0, initRoll=0, pitchClamp=30,  yawClamp=120 },
    [4] = { lx=-0.35,  ly=  0.25, lz= 0.65, initPitch= -2,  initYaw=0, initRoll=0, pitchClamp=40,  yawClamp=120 },
    [5] = { lx=-2.5,   ly= -1.0,  lz= 1.0,  initPitch= -5,  initYaw=0, initRoll=0, pitchClamp=30,  yawClamp=90  },
    [6] = { lx= 2.5,   ly= -1.0,  lz= 1.0,  initPitch= -5,  initYaw=0, initRoll=0, pitchClamp=30,  yawClamp=90  },
    [7] = { lx= 0.0,   ly= -1.0,  lz= 6.0,  initPitch=-80,  initYaw=0, initRoll=0, pitchClamp=15,  yawClamp=180 },
}

local _vehCamMode  = nil
local _vehCamYaw   = 0.0
local _vehCamPitch = 0.0
local _vehCamRoll  = 0.0

-- Per-player DB-loaded overrides: keyed by numeric mode_id
-- Loaded from server on freecam open AND on camsets open
-- NEVER cleared by the capture flow — only updated when DB confirm arrives
local _camOffsetOverrides = {}

local function getCamCfg(viewMode)
    local base = CAM_MODE_OFFSETS[viewMode]
    if not base then return nil end
    -- Per-model override takes priority when present for this cam+vehicle
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if DoesEntityExist(veh) then
        local mc = getModelCfg(viewMode, GetEntityModel(veh))
        if mc then
            return {
                lx           = mc.lx,
                ly           = mc.ly,
                lz           = mc.lz,
                initPitch    = mc.init_pitch,
                initYaw      = mc.init_yaw   or 0.0,
                initRoll     = mc.init_roll  or 0.0,
                initFov      = mc.init_fov   or 70.0,
                modelAllowed = true,
                pitchClamp   = base.pitchClamp,
                yawClamp     = base.yawClamp,
            }
        end
    end
    local ov = _camOffsetOverrides[viewMode]
    if ov then
        return {
            lx           = ov.lx,
            ly           = ov.ly,
            lz           = ov.lz,
            initPitch    = ov.init_pitch,
            initYaw      = ov.init_yaw    or 0.0,
            initRoll     = ov.init_roll   or 0.0,
            initFov      = ov.init_fov    or 70.0,
            modelAllowed = ov.model_allowed or false,
            pitchClamp   = base.pitchClamp,
            yawClamp     = base.yawClamp,
        }
    end
    return base
end

-- Cam edit / capture state
local _camEditMode    = false
local _camEditModeId  = nil
local _camCaptureMode = false   -- true while player is flying to position a cam
local _camCaptureVeh  = nil     -- vehicle entity locked at capture start

local _pendingCamMode   = nil
local _pendingCamFrames = 0

local function applyCamMode(modeId)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    -- Helper: get the active scripted cam (freecam or standalone camsets cam)
    local function getScriptedCam()
        return cam or camSetsCam
    end

    -- Standalone: ensure we have a scripted cam entity for vehicle cams
    local function ensureCamSetsCam()
        if camSetsActive and not freeCamActive then
            if not camSetsCam then
                camSetsCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                SetCamFov(camSetsCam, 70.0)
            end
            return camSetsCam
        end
        return nil
    end

    -- Auto head-track: driver cam (4) always enables it; other cams use their KVP autoHeadTrack flag.
    -- Leaving any auto-headtrack cam always disables head tracking.
    local DRIVER_CAM_ID = 4
    local leavingDriverCam = (_vehCamMode == DRIVER_CAM_ID)
    local enteringDriverCam = (modeId == 'vehicle_' .. DRIVER_CAM_ID)

    -- Disable head tracking whenever leaving a vehicle cam (restored per entering cam below)
    if _vehCamMode ~= nil and modeId ~= ('vehicle_' .. tostring(_vehCamMode)) then
        headTrackEnabled = false
        _headTrackBeforeDriverCam = nil
        _vehCamYaw = 0.0
        nuiUpdate({ headTrack = false })
    end

    -- Restore ped visibility when switching away from a cam that had hidePeds
    if _vehCamMode ~= nil then
        restorePedVisibility()
    end

    if modeId == 'freecam' then
        SetCinematicModeActive(false)
        activeCamMode = 'freecam'
        _vehCamMode   = nil
        _pendingCamMode = nil; _pendingCamFrames = 0
        -- Tear down standalone cam if switching back to freecam slot
        if camSetsCam then
            DestroyCam(camSetsCam, false); camSetsCam = nil
            RenderScriptCams(false, false, 0, true, true)
        end
        if cam then
            SetCamActive(cam, true)
            RenderScriptCams(true, false, 0, true, true)
        end

    elseif modeId == 'vehicle_cinematic' then
        if not DoesEntityExist(veh) then notify('error', 'Not in a vehicle.'); return end
        activeCamMode = modeId
        _vehCamMode   = nil
        -- Tear down standalone cam
        if camSetsCam then DestroyCam(camSetsCam, false); camSetsCam = nil end
        if cam then SetCamActive(cam, false) end
        RenderScriptCams(false, false, 0, true, true)
        _pendingCamMode = 'cinematic'; _pendingCamFrames = 5

    elseif modeId:sub(1, 8) == 'vehicle_' then
        if not DoesEntityExist(veh) then notify('error', 'Not in a vehicle.'); return end
        SetCinematicModeActive(false)
        local viewMode = tonumber(modeId:sub(9)) or 0
        local cfg = getCamCfg(viewMode)
        if not cfg then notify('error', 'Unknown cam mode.'); return end

        -- For driver cam: check if there's a per-model override, use it if so
        if viewMode == 4 then
            local modelHash = GetEntityModel(veh)
            local mc = getModelCfg(modelHash)
            if mc then
                cfg = {
                    lx         = mc.lx,
                    ly         = mc.ly,
                    lz         = mc.lz,
                    initPitch  = mc.init_pitch,
                    initYaw    = mc.init_yaw  or 0.0,
                    initRoll   = mc.init_roll or 0.0,
                    pitchClamp = cfg.pitchClamp,
                    yawClamp   = cfg.yawClamp,
                }
            end
        end

        activeCamMode = modeId
        _vehCamMode   = viewMode
        _vehCamYaw    = 0.0
        _vehCamPitch  = cfg.initPitch
        _vehCamRoll   = cfg.initRoll or 0.0
        _pendingCamMode = nil; _pendingCamFrames = 0
        local sc = ensureCamSetsCam() or cam
        if sc then
            SetCamFov(sc, cfg.initFov or 70.0)
            SetCamActive(sc, true)
            RenderScriptCams(true, false, 0, true, true)
        end

        -- Auto head tracking for this cam
        if isAutoHeadTrack(modeId) then
            headTrackEnabled = true
            nuiUpdate({ headTrack = true })
        end

        -- Per-cam ped hiding
        applyPedHiding(modeId)
    end

    nuiSend({ type = 'activeCamChanged', id = activeCamMode })
end

-- ─────────────────────────────────────────────
-- Snap cam behind vehicle (shared by cinematic setup and cam capture)
-- Works on the provided cam entity, not global cam
-- ─────────────────────────────────────────────
local function snapCamBehindVehicle(camEntity, veh)
    if not DoesEntityExist(veh) or not camEntity then return end
    local vehPos     = GetEntityCoords(veh)
    local vehRot     = GetEntityRotation(veh, 2)
    local headingRad = math.rad(vehRot.z)
    local minDim, maxDim = GetModelDimensions(GetEntityModel(veh))
    local halfLen    = math.abs(maxDim.y - minDim.y) * 0.5
    local halfH      = math.abs(maxDim.z - minDim.z) * 0.5
    local orbitDist  = math.max(halfLen * 2.2, 5.0)
    local fwdX       = -math.sin(headingRad)
    local fwdY       =  math.cos(headingRad)
    local startX     = vehPos.x - fwdX * orbitDist
    local startY     = vehPos.y - fwdY * orbitDist
    local startZ     = vehPos.z + halfH + 1.2
    local dx = vehPos.x - startX; local dy = vehPos.y - startY; local dz = vehPos.z - startZ
    local dist  = math.sqrt(dx*dx + dy*dy + dz*dz)
    local pitch = math.deg(math.asin(dz / math.max(dist, 0.001)))
    local yaw   = math.deg(math.atan(dx, dy)) * -1
    SetCamCoord(camEntity, startX, startY, startZ)
    SetCamRot(camEntity, pitch, 0.0, yaw, 2)
end

-- ─────────────────────────────────────────────
-- Cam switcher toggle
-- ─────────────────────────────────────────────
local function toggleCamSwitcher(standalone)
    if standalone then
        if camSwitcherOpen then
            camSwitcherOpen = false
            nuiCamSwitcherClose()
            SetNuiFocus(false, false)
        else
            camSwitcherOpen = true
            nuiCamSwitcherOpen(true)
            SetNuiFocus(true, true)
        end
        return
    end
    if not freeCamActive then return end
    if cinematicOpen or presetPanelOpen then return end
    camSwitcherOpen = not camSwitcherOpen
    if camSwitcherOpen then
        nuiCamSwitcherOpen(false)
        SetNuiFocus(true, true)
    else
        nuiCamSwitcherClose()
        SetNuiFocus(false, false)
    end
end

-- ─────────────────────────────────────────────
-- Cycle camera modes (C key)
-- ─────────────────────────────────────────────
local function cycleCamMode()
    if not freeCamActive and not camSetsActive then return end
    local list    = buildCamList()
    local visible = {}
    for _, entry in ipairs(list) do
        if not entry.cycleHidden then visible[#visible + 1] = entry end
    end
    if #visible < 1 then notify('info', 'No cameras in cycle — enable some in the switcher'); return end
    local curIdx = 0
    for i, entry in ipairs(visible) do
        if entry.id == activeCamMode then curIdx = i; break end
    end
    local nextEntry = visible[(curIdx % #visible) + 1]
    applyCamMode(nextEntry.id)
    notify('info', 'Camera: ' .. nextEntry.label)
end

-- ─────────────────────────────────────────────
-- Preset panel toggle
-- ─────────────────────────────────────────────
local function togglePresetPanel()
    if not freeCamActive then return end
    if cinematicOpen or camSwitcherOpen then return end
    presetPanelOpen = not presetPanelOpen
    if presetPanelOpen then
        nuiPresetPanelOpen(); SetNuiFocus(true, true)
    else
        nuiPresetPanelClose(); SetNuiFocus(false, false)
    end
end

-- ─────────────────────────────────────────────
-- Disable controls in freecam
-- ─────────────────────────────────────────────
local function disablePlayerControls()
    DisableControlAction(0, 30, true); DisableControlAction(0, 31, true)
    DisableControlAction(0, 140, true); DisableControlAction(0, 141, true)
    DisableControlAction(0, 142, true); DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true); DisableControlAction(0, 22, true)
    DisableControlAction(0, 23, true); DisableControlAction(0, 75, true)
    DisableControlAction(0, 45, true)
    DisableControlAction(0, 200, true)
    DisableControlAction(0, 172, true); DisableControlAction(0, 173, true)
    DisableControlAction(0, 174, true); DisableControlAction(0, 175, true)
    DisableControlAction(0, 10,  true); DisableControlAction(0, 11,  true)
end

-- ─────────────────────────────────────────────
-- Scroll delta
-- ─────────────────────────────────────────────
local function scrollDelta()
    if IsDisabledControlPressed(0, 241) then return  1 end
    if IsDisabledControlPressed(0, 242) then return -1 end
    return 0
end

-- ─────────────────────────────────────────────
-- Commands
-- ─────────────────────────────────────────────
RegisterCommand(Config.ActivationCommand, function()
    toggleFreeCam()
    TriggerEvent('mnc-freecam:setHideUIs', freeCamActive)
end, false)

RegisterCommand('cinematics', function()
    if freeCamActive then toggleCinematicPanel() end
end, false)

local _editSetupActive = false

RegisterCommand('freecam_cinematic', function()
    if not freeCamActive then return end
    if cinematicSetup then
        cinematicSetup = false
        nuiSend({ type = 'setupModeActive', active = false })
        nuiUpdate({ setupMode = false })
        if _editSetupActive then
            _editSetupActive = false
            cinematicOpen = true
            SetNuiFocus(true, true)
        else
            cinematicOpen = true
            TriggerServerEvent('mnc-freecam:loadMySequences')
            nuiCinematicOpen()
            SetNuiFocus(true, true)
        end
    elseif not cinematicOpen then
        toggleCinematicPanel()
    end
end, false)
RegisterKeyMapping('freecam_cinematic', 'FreeCam: Open Cinematic Editor / Complete Setup', 'keyboard', 'i')

RegisterCommand('freecam_roll_left', function()
    if freeCamActive and not cinematicOpen then _rollLeft = true end
end, false)
RegisterKeyMapping('freecam_roll_left', 'FreeCam: Roll Left', 'keyboard', 'LBRACKET')

RegisterCommand('freecam_roll_right', function()
    if freeCamActive and not cinematicOpen then _rollRight = true end
end, false)
RegisterKeyMapping('freecam_roll_right', 'FreeCam: Roll Right', 'keyboard', 'RBRACKET')

RegisterCommand('freecam_filter_prev', function()
    if freeCamActive and not cinematicOpen then _filterPrev = true end
end, false)
RegisterKeyMapping('freecam_filter_prev', 'FreeCam: Previous Filter', 'keyboard', 'COMMA')

RegisterCommand('freecam_filter_next', function()
    if freeCamActive and not cinematicOpen then _filterNext = true end
end, false)
RegisterKeyMapping('freecam_filter_next', 'FreeCam: Next Filter', 'keyboard', 'PERIOD')

-- K key — capture keyframe (cinematic setup) OR confirm cam position capture
RegisterCommand('freecam_capture', function()
    if _camCaptureMode then
        -- Capture mode: take current position of whichever cam is active and convert to offset
        nuiSend({ type = 'camCaptureReady' })
    elseif freeCamActive and cinematicSetup then
        captureKeyframe()
    end
end, false)
RegisterKeyMapping('freecam_capture', 'FreeCam: Capture Keyframe / Camera Position', 'keyboard', 'k')

RegisterCommand('importcinematic', function(_, args)
    if not args[1] then notify('error', 'Usage: /importcinematic CODE-WORD-N-WORD'); return end
    local code = table.concat(args, ' '):upper():gsub('%s+', '-')
    TriggerServerEvent('mnc-freecam:importByCode', code)
end, false)

-- /camsets — standalone cam switcher
RegisterCommand('camsets', function()
    if freeCamActive then
        toggleCamSwitcher(false); return
    end
    camSetsActive = not camSetsActive
    if camSetsActive then
        -- Load DB offsets so custom positions apply immediately
        TriggerServerEvent('mnc-freecam:loadCamOffsets')
        TriggerServerEvent('mnc-freecam:loadModelOffsets')
        TriggerServerEvent('mnc-freecam:loadCamFlags')
        TriggerServerEvent('mnc-freecam:loadCustomCams')
        camSwitcherOpen = true
        nuiCamSwitcherOpen(true)
        SetNuiFocus(true, true)
        notify('info', 'Camera Sets active — C to cycle, /camsets to close')
    else
        camSwitcherOpen = false
        nuiCamSwitcherClose()
        SetNuiFocus(false, false)
        restorePedVisibility()
        if activeCamMode ~= 'freecam' then
            SetCinematicModeActive(false)
            activeCamMode = 'freecam'
            _vehCamMode   = nil
        end
        if camSetsCam then
            DestroyCam(camSetsCam, false); camSetsCam = nil
            RenderScriptCams(false, false, 0, true, true)
        end
        if captureCam then
            DestroyCam(captureCam, false); captureCam = nil
            RenderScriptCams(false, false, 0, true, true)
        end
        _camCaptureMode = false; _camCaptureVeh = nil
        notify('info', 'Camera Sets closed')
    end
end, false)

-- ─────────────────────────────────────────────
-- NUI Callbacks — Cinematic
-- ─────────────────────────────────────────────
RegisterNUICallback('saveSequence', function(data, cb)
    if data.editKeyframes ~= nil then
        data.keyframes = data.editKeyframes; data.editKeyframes = nil
    else
        data.keyframes = keyframes
    end
    -- id=0 means new sequence from NUI; nil tells server to INSERT not UPDATE
    if not data.id or data.id == 0 then data.id = nil end
    TriggerServerEvent('mnc-freecam:saveSequence', data)
    cb('ok')
end)

RegisterNUICallback('deleteSequence', function(data, cb)
    TriggerServerEvent('mnc-freecam:deleteSequence', data.id); cb('ok')
end)

RegisterNUICallback('loadSequence', function(data, cb)
    TriggerServerEvent('mnc-freecam:loadSequence', data.id); cb('ok')
end)

RegisterNUICallback('startSetup', function(data, cb)
    cinematicSetup = true; setupType = data.setupType or 'world'; keyframes = {}
    if setupType == 'vehicle' then
        local ped = PlayerPedId(); local veh = GetVehiclePedIsIn(ped, false)
        setupVehicle = DoesEntityExist(veh) and veh or nil
        if not setupVehicle then
            notify('error', 'You must be in a vehicle for vehicle cinematics.')
            cinematicSetup = false; cb('no_vehicle'); return
        end
        if cam then snapCamBehindVehicle(cam, setupVehicle); rollAngle = 0.0 end
    else
        setupVehicle = nil
    end
    cinematicOpen = false; nuiCinematicClose(); SetNuiFocus(false, false)
    nuiSend({ type = 'setupModeActive', active = true, hint = 'Press I to complete setup' })
    nuiUpdate({ setupMode = true, setupType = setupType })
    cb('ok')
end)

RegisterNUICallback('stopSetup', function(_, cb)
    cinematicSetup = false
    nuiSend({ type = 'setupModeActive', active = false }); nuiUpdate({ setupMode = false })
    cinematicOpen = true
    TriggerServerEvent('mnc-freecam:loadMySequences'); nuiCinematicOpen(); SetNuiFocus(true, true)
    cb('ok')
end)

RegisterNUICallback('startEditSetup', function(data, cb)
    cinematicSetup = true; setupType = data.setupType or 'world'; keyframes = {}
    if setupType == 'vehicle' then
        local ped = PlayerPedId(); local veh = GetVehiclePedIsIn(ped, false)
        setupVehicle = DoesEntityExist(veh) and veh or nil
        if not setupVehicle then
            notify('error', 'You must be in a vehicle for vehicle cinematics.')
            cinematicSetup = false; cb('no_vehicle'); return
        end
        if cam then snapCamBehindVehicle(cam, setupVehicle); rollAngle = 0.0 end
    else
        setupVehicle = nil
    end
    _editSetupActive = true; cinematicOpen = false; nuiCinematicClose(); SetNuiFocus(false, false)
    nuiSend({ type = 'setupModeActive', active = true, hint = 'Press I to complete setup' })
    nuiUpdate({ setupMode = true, setupType = setupType })
    cb('ok')
end)

RegisterNUICallback('stopEditSetup', function(_, cb)
    cinematicSetup = false; _editSetupActive = false
    nuiSend({ type = 'setupModeActive', active = false }); nuiUpdate({ setupMode = false })
    cinematicOpen = true; SetNuiFocus(true, true)
    cb('ok')
end)

RegisterNUICallback('clearEditKeyframes', function(_, cb)
    keyframes = {}; nuiUpdateKeyframes(); cb('ok')
end)

RegisterNUICallback('playSequence', function(data, cb)
    -- Sanitise keyframes from NUI round-trip: fov/duration may be nil for sequences
    -- saved before those fields existed, or may arrive as JSON null after DB→NUI→Lua.
    local raw = data.keyframes or keyframes
    local kf  = {}
    for _, f in ipairs(raw) do
        kf[#kf + 1] = {
            pos      = { x = tonumber(f.pos and f.pos.x) or 0.0, y = tonumber(f.pos and f.pos.y) or 0.0, z = tonumber(f.pos and f.pos.z) or 0.0 },
            rot      = { x = tonumber(f.rot and f.rot.x) or 0.0, y = tonumber(f.rot and f.rot.y) or 0.0, z = tonumber(f.rot and f.rot.z) or 0.0 },
            fov      = tonumber(f.fov)      or currentFOV,
            duration = tonumber(f.duration) or globalDuration,
            label    = f.label or '',
        }
    end
    local mode = data.playbackMode or 'once'
    local veh  = nil
    if data.seqType == 'vehicle' then
        if setupVehicle and DoesEntityExist(setupVehicle) then
            veh = setupVehicle
        else
            local ped = PlayerPedId(); local curVeh = GetVehiclePedIsIn(ped, false)
            if DoesEntityExist(curVeh) then veh = curVeh; setupVehicle = curVeh
            else notify('error', 'Get back in the vehicle before playing.'); cb('no_vehicle'); return end
        end
    end
    startPlayback(kf, mode, veh); cb('ok')
end)

RegisterNUICallback('stopPlayback',           function(_, cb) stopPlayback(); cb('ok') end)
RegisterNUICallback('captureKeyframe',        function(_, cb) captureKeyframe(); cb('ok') end)
RegisterNUICallback('removeKeyframe',         function(data, cb) removeKeyframe(data.index); cb('ok') end)
RegisterNUICallback('updateKeyframeDuration', function(data, cb)
    if keyframes[data.index] then keyframes[data.index].duration = data.duration end; cb('ok')
end)
RegisterNUICallback('setGlobalDuration',  function(data, cb) globalDuration = data.duration; cb('ok') end)
RegisterNUICallback('setPlaybackMode',    function(data, cb) playbackMode   = data.mode;     cb('ok') end)
RegisterNUICallback('importCode',         function(data, cb)
    TriggerServerEvent('mnc-freecam:importByCode', data.code:upper()); cb('ok')
end)
RegisterNUICallback('closeCinematic', function(_, cb)
    cinematicOpen = false; nuiCinematicClose(); SetNuiFocus(false, false); cb('ok')
end)

-- Toggle ped
RegisterCommand('freecam_hide_ped', function()
    if freeCamActive then setPedVisible(pedHidden) end
end, false)
RegisterKeyMapping('freecam_hide_ped', 'FreeCam: Toggle Hide Ped', 'keyboard', 'h')

-- Cam switcher keys
RegisterCommand('freecam_cam_switcher_v2', function()
    if freeCamActive then toggleCamSwitcher(false)
    elseif camSetsActive then toggleCamSwitcher(true) end
end, false)
RegisterKeyMapping('freecam_cam_switcher_v2', 'FreeCam: Open Camera Switcher', 'keyboard', 'SLASH')

RegisterCommand('freecam_cam_cycle', function()
    local panelsOpen = cinematicOpen or camSwitcherOpen or presetPanelOpen
    if (freeCamActive or camSetsActive) and not panelsOpen then _camCycleNext = true end
end, false)
RegisterKeyMapping('freecam_cam_cycle', 'FreeCam: Cycle Camera Mode', 'keyboard', 'c')

RegisterCommand('freecam_preset_mgr_v2', function()
    if freeCamActive then togglePresetPanel() end
end, false)
RegisterKeyMapping('freecam_preset_mgr_v2', 'FreeCam: Open Preset Manager', 'keyboard', 'o')

-- ─────────────────────────────────────────────
-- NUI Callbacks — Cam switcher
-- ─────────────────────────────────────────────
RegisterNUICallback('selectCamera', function(data, cb)
    applyCamMode(data.id)
    -- Always close the switcher and release NUI focus after selection
    -- so the C key can cycle cameras without the UI intercepting keypresses
    camSwitcherOpen = false
    nuiCamSwitcherClose()
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closeCamSwitcher', function(_, cb)
    camSwitcherOpen = false; nuiCamSwitcherClose(); SetNuiFocus(false, false); cb('ok')
end)

-- Hide the cam switcher UI but keep camsets active (so C key works)
RegisterNUICallback('hideCamSwitcherUI', function(_, cb)
    camSwitcherOpen = false
    nuiCamSwitcherClose()
    SetNuiFocus(false, false)
    notify('info', 'UI hidden — C to cycle · /camsets to open again')
    cb('ok')
end)

-- ─────────────────────────────────────────────
-- NUI Callbacks — Presets
-- ─────────────────────────────────────────────
RegisterNUICallback('savePreset', function(data, cb)
    if not cam then cb('no_cam'); return end
    local slot = data.slot or findFreeSlot()
    if not slot then cb('full'); return end
    local pos = GetCamCoord(cam)
    local rot = GetCamRot(cam, 2)
    local preset = {
        name=data.name or ('Preset '..slot), slot=slot, fov=currentFOV, roll=rollAngle,
        filter=currentFilterIndex, dofEnabled=dofEnabled, dofNear=dofNearDist,
        dofFar=dofFarDist, dofStrength=dofStrength, shakeEnabled=shakeEnabled,
        shakeAmp=shakeAmplitude, barsEnabled=barsEnabled, barsSize=barsSize, tcStrength=tcStrength,
    }
    -- Update in RAM
    _presets[slot] = preset
    -- Persist to server
    TriggerServerEvent('mnc-freecam:savePreset', { slot = slot, name = preset.name, data = json.encode(preset) })
    notify('success', 'Preset saved to slot ' .. slot)
    nuiSend({ type = 'presetSaved', slot = slot, presets = getAllPresets() }); cb('ok')
end)

RegisterNUICallback('loadPreset', function(data, cb)
    local preset = _presets[tonumber(data.slot)]
    if not preset then cb('not_found'); return end
    if not freeCamActive then cb('no_cam'); return end
    if preset.fov and cam then currentFOV = preset.fov; SetCamFov(cam, currentFOV) end
    if preset.filter then applyFilter(preset.filter) end
    rollAngle=preset.roll or 0.0; dofEnabled=preset.dofEnabled or false
    dofNearDist=preset.dofNear or 1.0; dofFarDist=preset.dofFar or 15.0
    dofStrength=preset.dofStrength or 1.0; applyDOF()
    shakeEnabled=preset.shakeEnabled or false; shakeAmplitude=preset.shakeAmp or 0.0; applyShake()
    barsEnabled=preset.barsEnabled or false; barsSize=preset.barsSize or 0.08
    tcStrength=preset.tcStrength or 1.0; SetTimecycleModifierStrength(tcStrength)
    nuiShow(); notify('success', 'Preset loaded: ' .. (preset.name or ''))
    presetPanelOpen = false; nuiPresetPanelClose(); SetNuiFocus(false, false); cb('ok')
end)

RegisterNUICallback('deletePreset', function(data, cb)
    local slot = tonumber(data.slot)
    _presets[slot] = nil
    TriggerServerEvent('mnc-freecam:deletePreset', { slot = slot })
    nuiSend({ type = 'presetDeleted', slot = slot, presets = getAllPresets() }); cb('ok')
end)

RegisterNUICallback('closePresetPanel', function(_, cb)
    presetPanelOpen = false; nuiPresetPanelClose(); SetNuiFocus(false, false); cb('ok')
end)

-- ─────────────────────────────────────────────
-- NUI Callbacks — Cam offset editor
-- ─────────────────────────────────────────────
RegisterNUICallback('openCamEdit', function(data, cb)
    local modeId = tonumber(data.mode_id)
    local cfg = getCamCfg(modeId)
    if not cfg then cb('no_cfg'); return end
    camSwitcherOpen = false
    _camEditMode    = true
    _camEditModeId  = modeId
    nuiSend({
        type          = 'camEditOpen',
        mode_id       = modeId,
        label         = data.label or ('Camera ' .. tostring(modeId)),
        lx            = cfg.lx,
        ly            = cfg.ly,
        lz            = cfg.lz,
        init_pitch    = cfg.initPitch,
        init_yaw      = cfg.initYaw      or 0.0,
        init_roll     = cfg.initRoll     or 0.0,
        init_fov      = cfg.initFov      or 70.0,
        model_allowed = cfg.modelAllowed or (modeId == 4),
        is_driver     = (modeId == 4),
    })
    cb('ok')
    Citizen.SetTimeout(0, function() SetNuiFocus(true, true) end)
end)

RegisterNUICallback('previewCamOffset', function(data, cb)
    local modeId = tonumber(data.mode_id)
    if not modeId then cb('bad'); return end
    -- Live preview in RAM — NOT yet saved to DB
    _camOffsetOverrides[modeId] = {
        lx            = tonumber(data.lx)           or 0.0,
        ly            = tonumber(data.ly)           or 0.0,
        lz            = tonumber(data.lz)           or 0.0,
        init_pitch    = tonumber(data.init_pitch)   or 0.0,
        init_yaw      = tonumber(data.init_yaw)     or 0.0,
        init_roll     = tonumber(data.init_roll)    or 0.0,
        init_fov      = tonumber(data.init_fov)     or 70.0,
        model_allowed = data.model_allowed          or false,
    }
    if _vehCamMode == modeId then
        _vehCamPitch = _camOffsetOverrides[modeId].init_pitch
        -- Apply FOV live
        local sc = cam or camSetsCam
        if sc then SetCamFov(sc, _camOffsetOverrides[modeId].init_fov) end
    end
    cb('ok')
end)

-- Save to DB — server writes row and fires back camOffsetSaved to confirm
RegisterNUICallback('saveCamOffset', function(data, cb)
    local modeId  = tonumber(data.mode_id)
    local lx      = tonumber(data.lx)           or 0.0
    local ly      = tonumber(data.ly)           or 0.0
    local lz      = tonumber(data.lz)           or 0.0
    local pitch   = tonumber(data.init_pitch)   or 0.0
    local yaw     = tonumber(data.init_yaw)     or 0.0
    local roll    = tonumber(data.init_roll)    or 0.0
    local fov     = tonumber(data.init_fov)     or 70.0
    local ma      = data.model_allowed          or false
    -- Optimistically update RAM so the cam responds immediately
    _camOffsetOverrides[modeId] = {
        lx=lx, ly=ly, lz=lz,
        init_pitch=pitch, init_yaw=yaw, init_roll=roll,
        init_fov=fov, model_allowed=ma,
    }
    if _vehCamMode == modeId then
        _vehCamPitch = pitch
        local sc = cam or camSetsCam
        if sc then SetCamFov(sc, fov) end
    end
    TriggerServerEvent('mnc-freecam:saveCamOffset', {
        mode_id = modeId, lx = lx, ly = ly, lz = lz,
        init_pitch = pitch, init_yaw = yaw, init_roll = roll,
        init_fov = fov, model_allowed = ma,
    })
    cb('ok')
end)

RegisterNUICallback('resetCamOffset', function(data, cb)
    local modeId = tonumber(data.mode_id)
    _camOffsetOverrides[modeId] = nil
    TriggerServerEvent('mnc-freecam:resetCamOffset', modeId); cb('ok')
end)

-- ─────────────────────────────────────────────
-- Cam capture — fly to position then K to lock it
-- Works in both freecam (uses existing cam) and camsets standalone (spawns captureCam)
-- ─────────────────────────────────────────────
RegisterNUICallback('startCamCapture', function(data, cb)
    local modeId = tonumber(data.mode_id)
    if not modeId then cb('bad'); return end

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(veh) then
        notify('error', 'Must be in a vehicle to capture camera position.'); cb('no_veh'); return
    end

    _camCaptureMode = true
    _camEditModeId  = modeId
    _camCaptureVeh  = veh

    if freeCamActive and cam then
        -- Freecam already has a scripted cam — just reuse it
        -- Switch back to freecam mode so we can fly
        activeCamMode = 'freecam'; _vehCamMode = nil
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)
        snapCamBehindVehicle(cam, veh)
        rollAngle = 0.0
    else
        -- Standalone /camsets: spawn a temporary scripted cam so the player can fly
        if captureCam then DestroyCam(captureCam, false); captureCam = nil end
        captureCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        -- Start behind vehicle
        snapCamBehindVehicle(captureCam, veh)
        SetCamFov(captureCam, 70.0)
        SetCamActive(captureCam, true)
        RenderScriptCams(true, false, 0, true, true)
    end

    nuiSend({ type = 'camCaptureStart', mode_id = modeId })
    SetNuiFocus(false, false)
    notify('info', 'Fly to the camera position, press K to capture')
    cb('ok')
end)

-- Convert current fly-cam position → vehicle-local offset, save to DB
local function doConfirmCamCapture(modeId)
    if not modeId then return end
    -- Whichever cam we're using for capture
    local activeFlyingCam = freeCamActive and cam or captureCam
    if not activeFlyingCam then return end

    local veh = _camCaptureVeh
    if not DoesEntityExist(veh) then
        notify('error', 'Vehicle entity lost — cannot capture.'); return
    end

    local worldPos = GetCamCoord(activeFlyingCam)
    local worldRot = GetCamRot(activeFlyingCam, 2)
    local vehPos   = GetEntityCoords(veh)
    local vehRot   = GetEntityRotation(veh, 2)
    local hRad     = math.rad(vehRot.z)

    -- World → vehicle local
    local dx = worldPos.x - vehPos.x
    local dy = worldPos.y - vehPos.y
    local dz = worldPos.z - vehPos.z
    local cosH = math.cos(-hRad)
    local sinH = math.sin(-hRad)
    local lx = cosH * dx - sinH * dy
    local ly = sinH * dx + cosH * dy
    local lz = dz
    local initPitch = worldRot.x
    local initYaw   = worldRot.z - vehRot.z   -- yaw offset relative to vehicle heading
    local initRoll  = worldRot.y

    -- Clamp — lz upper bound raised to 15 so overhead/elevated cams are captured correctly
    local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
    lx = clamp(lx, -8, 8); ly = clamp(ly, -20, 20); lz = clamp(lz, -3, 15)
    initPitch = clamp(initPitch, -89,  89)
    initYaw   = clamp(initYaw,  -180, 180)
    initRoll  = clamp(initRoll,  -89,  89)

    -- Apply to RAM immediately
    _camOffsetOverrides[modeId] = {
        lx=lx, ly=ly, lz=lz,
        init_pitch=initPitch, init_yaw=initYaw, init_roll=initRoll,
        init_fov=_camOffsetOverrides[modeId] and _camOffsetOverrides[modeId].init_fov or 70.0,
        model_allowed=_camOffsetOverrides[modeId] and _camOffsetOverrides[modeId].model_allowed or false,
    }
    if _vehCamMode == modeId then _vehCamPitch = initPitch end

    -- Save to DB
    TriggerServerEvent('mnc-freecam:saveCamOffset', {
        mode_id = modeId, lx = lx, ly = ly, lz = lz,
        init_pitch = initPitch, init_yaw = initYaw, init_roll = initRoll,
        init_fov = _camOffsetOverrides[modeId].init_fov,
        model_allowed = _camOffsetOverrides[modeId].model_allowed,
    })

    _camCaptureMode = false
    _camCaptureVeh  = nil

    -- Tear down captureCam if we spawned one
    if captureCam then
        DestroyCam(captureCam, false); captureCam = nil
        RenderScriptCams(false, false, 0, true, true)
    end

    -- Restore vehicle cam mode so the new offset is live immediately.
    -- startCamCapture cleared _vehCamMode to allow flying; restore it now
    -- so whichever loop is active (freecam or standalone camsets) picks up the new offset.
    activeCamMode = 'vehicle_' .. tostring(modeId)
    _vehCamMode   = modeId
    _vehCamPitch  = initPitch
    _vehCamYaw    = 0.0

    if freeCamActive and cam then
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)
    elseif camSetsActive then
        -- Recreate the scripted cam the standalone loop drives
        if camSetsCam then DestroyCam(camSetsCam, false) end
        camSetsCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamFov(camSetsCam, 70.0)
        SetCamActive(camSetsCam, true)
        RenderScriptCams(true, false, 0, true, true)
    end

    -- Tell NUI: update sliders + reopen edit panel
    nuiSend({
        type       = 'camCaptureConfirmed',
        mode_id    = modeId,
        lx         = lx, ly = ly, lz = lz,
        init_pitch = initPitch, init_yaw = initYaw, init_roll = initRoll,
        init_fov   = _camOffsetOverrides[modeId].init_fov or 70.0,
    })
    Citizen.SetTimeout(0, function() SetNuiFocus(true, true) end)
end

RegisterNUICallback('confirmCamCapture', function(data, cb)
    doConfirmCamCapture(tonumber(data.mode_id) or _camEditModeId); cb('ok')
end)

local function cancelCamCapture()
    _camCaptureMode = false
    _camCaptureVeh  = nil
    if captureCam then
        DestroyCam(captureCam, false); captureCam = nil
        RenderScriptCams(false, false, 0, true, true)
    end
    nuiSend({ type = 'camCaptureCancel' })
    Citizen.SetTimeout(0, function() SetNuiFocus(true, true) end)
end

RegisterNUICallback('cancelCamCapture', function(_, cb) cancelCamCapture(); cb('ok') end)

RegisterNUICallback('closeCamEdit', function(_, cb)
    _camEditMode    = false
    _camEditModeId  = nil
    _camCaptureMode = false
    if captureCam then
        DestroyCam(captureCam, false); captureCam = nil
        RenderScriptCams(false, false, 0, true, true)
    end
    nuiSend({ type = 'camEditClose' })
    Citizen.SetTimeout(50, function()
        if (freeCamActive or camSetsActive) and not cinematicOpen and not presetPanelOpen then
            camSwitcherOpen = true
            nuiCamSwitcherOpen(camSetsActive and not freeCamActive)
            SetNuiFocus(true, true)
        else
            SetNuiFocus(false, false)
        end
    end)
    cb('ok')
end)

RegisterNUICallback('setCamCycleHidden', function(data, cb)
    setCycleHidden(data.id, data.hidden)
    if camSwitcherOpen then nuiCamSwitcherOpen(camSetsActive and not freeCamActive) end
    cb('ok')
end)

RegisterNUICallback('addCustomCam', function(data, cb)
    local newId = tonumber(data.id)
    if not newId then cb('bad_id'); return end
    local label = tostring(data.label or ('Camera ' .. newId)):sub(1, 40)
    for _, e in ipairs(VEHICLE_CAM_MODES) do
        if e.id == newId then cb('duplicate'); return end
    end
    for _, c in ipairs(_customCams) do
        if c.id == newId then cb('duplicate'); return end
    end
    _customCams[#_customCams + 1] = { id = newId, label = label }
    TriggerServerEvent('mnc-freecam:saveCustomCam', { cam_id = newId, label = label })
    if not CAM_MODE_OFFSETS[newId] then
        CAM_MODE_OFFSETS[newId] = { lx=0.0, ly=-6.0, lz=1.5, initPitch=-8, pitchClamp=30, yawClamp=120 }
    end
    nuiSend({ type = 'addCustomCamResult', ok = true, cameras = buildCamList() }); cb('ok')
end)

RegisterNUICallback('deleteCustomCam', function(data, cb)
    local delId = tonumber(data.id)
    for i, c in ipairs(_customCams) do
        if c.id == delId then table.remove(_customCams, i); break end
    end
    TriggerServerEvent('mnc-freecam:deleteCustomCam', { cam_id = delId })
    nuiSend({ type = 'addCustomCamResult', ok = true, cameras = buildCamList() }); cb('ok')
end)

-- Head tracking toggle — driver cam (4) always has it on; other cams allow free toggle
RegisterNUICallback('setHeadTrack', function(data, cb)
    if _vehCamMode == 4 then cb('ok'); return end  -- driver cam: always on, not togglable via NUI
    headTrackEnabled = data.enabled or false
    if not headTrackEnabled then _vehCamYaw = 0.0 end
    nuiUpdate({ headTrack = headTrackEnabled }); cb('ok')
end)

-- ─────────────────────────────────────────────
-- Server → Client: cam offsets
-- Called after save AND on freecam/camsets open
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-freecam:receiveCamOffsets', function(rows)
    _camOffsetOverrides = {}
    for _, row in ipairs(rows) do
        local modeKey = tonumber(row.mode_id)
        if modeKey then
            _camOffsetOverrides[modeKey] = {
                lx            = tonumber(row.lx)           or 0.0,
                ly            = tonumber(row.ly)           or 0.0,
                lz            = tonumber(row.lz)           or 0.0,
                init_pitch    = tonumber(row.init_pitch)   or 0.0,
                init_yaw      = tonumber(row.init_yaw)     or 0.0,
                init_roll     = tonumber(row.init_roll)    or 0.0,
                init_fov      = tonumber(row.init_fov)     or 70.0,
                model_allowed = (row.model_allowed == true or row.model_allowed == 1),
            }
        end
    end
    if _vehCamMode ~= nil then
        local cfg = getCamCfg(_vehCamMode)
        if cfg then _vehCamPitch = cfg.initPitch end
    end
end)

RegisterNetEvent('mnc-freecam:camOffsetSaved', function(data)
    _camOffsetOverrides[data.mode_id] = {
        lx            = data.lx,
        ly            = data.ly,
        lz            = data.lz,
        init_pitch    = data.init_pitch,
        init_yaw      = data.init_yaw      or 0.0,
        init_roll     = data.init_roll     or 0.0,
        init_fov      = data.init_fov      or 70.0,
        model_allowed = data.model_allowed or false,
    }
    nuiSend({ type = 'camOffsetSaved', mode_id = data.mode_id })
end)

RegisterNetEvent('mnc-freecam:camOffsetReset', function(modeId)
    _camOffsetOverrides[modeId] = nil
    nuiSend({ type = 'camOffsetReset', mode_id = modeId })
end)

-- ─────────────────────────────────────────────
-- Server → Client: cam flags (cycle-hidden, hide-peds, auto-head-track)
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-freecam:receiveCamFlags', function(rows)
    -- Preserve cycleHiddenDefault until server overrides it per cam
    -- Only set cycleHiddenSet=true for cams that have a DB row
    for _, row in ipairs(rows) do
        local camId = tostring(row.cam_id)
        _camFlags[camId] = {
            cycleHidden    = (row.cycle_hidden    == true or row.cycle_hidden    == 1),
            cycleHiddenSet = true,
            hidePeds       = (row.hide_peds       == true or row.hide_peds       == 1),
            autoHeadTrack  = (row.auto_head_track == true or row.auto_head_track == 1),
        }
    end
    -- Refresh cam switcher if open
    if camSwitcherOpen then nuiCamSwitcherOpen(camSetsActive and not freeCamActive) end
end)

-- ─────────────────────────────────────────────
-- Server → Client: custom cams
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-freecam:receiveCustomCams', function(rows)
    _customCams = {}
    for _, row in ipairs(rows) do
        local id = tonumber(row.cam_id)
        if id then
            _customCams[#_customCams + 1] = { id = id, label = tostring(row.label or '') }
            -- Back-fill CAM_MODE_OFFSETS so getCamCfg works for custom cams
            if not CAM_MODE_OFFSETS[id] then
                CAM_MODE_OFFSETS[id] = { lx=0.0, ly=-6.0, lz=1.5, initPitch=-8, pitchClamp=30, yawClamp=120 }
            end
        end
    end
    -- Refresh cam switcher if open
    if camSwitcherOpen then nuiCamSwitcherOpen(camSetsActive and not freeCamActive) end
end)

-- ─────────────────────────────────────────────
-- Server → Client: presets
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-freecam:receivePresets', function(rows)
    _presets = {}
    for _, row in ipairs(rows) do
        local slot = tonumber(row.slot)
        if slot then
            local ok, parsed = pcall(json.decode, row.data or '{}')
            if ok and parsed then
                parsed.slot = slot
                parsed.name = parsed.name or row.name or ('Preset ' .. slot)
                _presets[slot] = parsed
            end
        end
    end
    -- Refresh panel if open
    if presetPanelOpen then nuiPresetPanelOpen() end
end)

RegisterNetEvent('mnc-freecam:presetSaved', function(data)
    -- Server confirmed write — nothing extra needed, RAM is already updated
end)

RegisterNetEvent('mnc-freecam:presetDeleted', function(data)
    -- Server confirmed delete — RAM already cleared
end)

-- ─────────────────────────────────────────────
-- Per-model driver cam offsets
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-freecam:receiveModelOffsets', function(rows)
    _modelOffsetOverrides = {}
    for _, row in ipairs(rows) do
        local modeId = tonumber(row.mode_id) or 4
        local hash   = tonumber(row.model_hash)
        if hash then
            if not _modelOffsetOverrides[modeId] then _modelOffsetOverrides[modeId] = {} end
            _modelOffsetOverrides[modeId][hash] = {
                lx         = tonumber(row.lx)         or 0.0,
                ly         = tonumber(row.ly)         or 0.0,
                lz         = tonumber(row.lz)         or 0.0,
                init_pitch = tonumber(row.init_pitch) or 0.0,
                init_yaw   = tonumber(row.init_yaw)   or 0.0,
                init_roll  = tonumber(row.init_roll)  or 0.0,
                init_fov   = tonumber(row.init_fov)   or 70.0,
                model_name = tostring(row.model_name  or ''),
            }
        end
    end
    -- Build list for NUI: group by mode_id
    local list = {}
    for modeId, byHash in pairs(_modelOffsetOverrides) do
        for hash, mc in pairs(byHash) do
            list[#list + 1] = { mode_id = modeId, model_hash = hash, model_name = mc.model_name }
        end
    end
    nuiSend({ type = 'modelOffsetList', list = list })
end)

RegisterNetEvent('mnc-freecam:modelOffsetSaved', function(data)
    local modeId = tonumber(data.mode_id) or 4
    local hash   = tonumber(data.model_hash)
    if not _modelOffsetOverrides[modeId] then _modelOffsetOverrides[modeId] = {} end
    _modelOffsetOverrides[modeId][hash] = {
        lx=data.lx, ly=data.ly, lz=data.lz,
        init_pitch=data.init_pitch, init_yaw=data.init_yaw, init_roll=data.init_roll,
        init_fov=data.init_fov or 70.0,
        model_name=data.model_name,
    }
    local list = {}
    for mid, byHash in pairs(_modelOffsetOverrides) do
        for h, mc in pairs(byHash) do
            list[#list + 1] = { mode_id = mid, model_hash = h, model_name = mc.model_name }
        end
    end
    nuiSend({ type = 'modelOffsetList', list = list })
end)

RegisterNetEvent('mnc-freecam:modelOffsetDeleted', function(data)
    local modeId = tonumber(data.mode_id) or 4
    local hash   = tonumber(data.model_hash)
    if _modelOffsetOverrides[modeId] then
        _modelOffsetOverrides[modeId][hash] = nil
    end
    local list = {}
    for mid, byHash in pairs(_modelOffsetOverrides) do
        for h, mc in pairs(byHash) do
            list[#list + 1] = { mode_id = mid, model_hash = h, model_name = mc.model_name }
        end
    end
    nuiSend({ type = 'modelOffsetList', list = list })
end)

-- Save current cam position as a model preset for the vehicle the player is in
RegisterNUICallback('saveModelOffset', function(data, cb)
    local modeId = tonumber(data.mode_id) or _camEditModeId
    if not modeId then cb('no_mode'); return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(veh) then cb('no_veh'); return end
    local hash = GetEntityModel(veh)
    local name = GetDisplayNameFromVehicleModel(hash):lower()
    -- Prefer live model override for this cam if one exists, then generic cam override, then hardcoded default
    local mc = getModelCfg(modeId, hash)
    local ov = mc or _camOffsetOverrides[modeId] or CAM_MODE_OFFSETS[modeId] or CAM_MODE_OFFSETS[4]
    TriggerServerEvent('mnc-freecam:saveModelOffset', {
        mode_id    = modeId,
        model_hash = hash,
        model_name = name,
        lx         = ov.lx,
        ly         = ov.ly,
        lz         = ov.lz,
        init_pitch = ov.init_pitch or ov.initPitch or 0.0,
        init_yaw   = ov.init_yaw   or ov.initYaw   or 0.0,
        init_roll  = ov.init_roll  or ov.initRoll  or 0.0,
        init_fov   = ov.init_fov   or ov.initFov   or 70.0,
    })
    cb('ok')
end)

RegisterNUICallback('deleteModelOffset', function(data, cb)
    TriggerServerEvent('mnc-freecam:deleteModelOffset', { mode_id = data.mode_id, model_hash = data.model_hash }); cb('ok')
end)

-- Per-cam hide peds toggle
RegisterNUICallback('setCamHidePeds', function(data, cb)
    setHidePeds(data.id, data.hidden)
    -- If this cam is currently active, apply immediately
    if activeCamMode == data.id then
        applyPedHiding(data.id)
    end
    cb('ok')
end)

-- Per-cam auto head tracking toggle (not for driver cam — it's always on)
RegisterNUICallback('setCamAutoHeadTrack', function(data, cb)
    if data.id == 'vehicle_4' then cb('ok'); return end
    setAutoHeadTrack(data.id, data.enabled)
    cb('ok')
end)

-- ─────────────────────────────────────────────
-- Exit / reset UI
-- ─────────────────────────────────────────────
RegisterNUICallback('exitFreecam', function(_, cb)
    if freeCamActive then toggleFreeCam(); TriggerEvent('mnc-freecam:setHideUIs', false) end
    if camSetsActive then
        camSetsActive = false; camSwitcherOpen = false
        nuiCamSwitcherClose(); SetNuiFocus(false, false)
        restorePedVisibility()
        if activeCamMode ~= 'freecam' then
            SetCinematicModeActive(false); activeCamMode = 'freecam'; _vehCamMode = nil
        end
        if camSetsCam then DestroyCam(camSetsCam, false); camSetsCam = nil; RenderScriptCams(false, false, 0, true, true) end
        if captureCam then DestroyCam(captureCam, false); captureCam = nil; RenderScriptCams(false, false, 0, true, true) end
        _camCaptureMode = false; _camCaptureVeh = nil
    end
    cb('ok')
end)

RegisterNUICallback('resetUI', function(_, cb)
    if not freeCamActive then cb('ok'); return end
    nuiShow()
    if cinematicOpen then TriggerServerEvent('mnc-freecam:loadMySequences'); nuiCinematicOpen() end
    cb('ok')
end)

-- ─────────────────────────────────────────────
-- Server → Client: sequences
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-freecam:notify', function(ntype, msg) notify(ntype, msg) end)

RegisterNetEvent('mnc-freecam:receiveSequences', function(rows)
    sequences = rows; nuiUpdateSequences()
end)

RegisterNetEvent('mnc-freecam:receiveSequence', function(row)
    activeSequence = row; keyframes = row.keyframes or {}
    globalDuration = row.default_duration or 3.0; playbackMode = row.playback_mode or 'once'
    nuiSend({ type='loadedSequence', sequence=row, keyframes=keyframes, globalDuration=globalDuration, playbackMode=playbackMode })
end)

RegisterNetEvent('mnc-freecam:sequenceSaved', function(data)
    notify('success', 'Sequence saved — share code: ' .. data.share_code)
    nuiSend({ type = 'sequenceSaved', id = data.id, share_code = data.share_code })
    TriggerServerEvent('mnc-freecam:loadMySequences')
end)

RegisterNetEvent('mnc-freecam:sequenceDeleted', function(seqId)
    notify('success', 'Sequence deleted.')
    for i, s in ipairs(sequences) do
        if s.id == seqId then table.remove(sequences, i); break end
    end
    nuiUpdateSequences()
end)

RegisterNetEvent('mnc-freecam:sequenceImported', function(data)
    notify('success', 'Imported: ' .. data.name)
    TriggerServerEvent('mnc-freecam:loadMySequences')
end)

-- ─────────────────────────────────────────────
-- Main thread
-- ─────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        -- ── Camera cycle (works in both freecam and camsets) ──
        if _camCycleNext then cycleCamMode(); _camCycleNext = false end

        -- ═══════════════════════════════════════
        -- CAMSETS STANDALONE — scripted captureCam movement
        -- ═══════════════════════════════════════
        if camSetsActive and not freeCamActive and _camCaptureMode and captureCam then
            -- Disable some controls so arrow keys / PgUp etc. work
            DisableControlAction(0, 172, true); DisableControlAction(0, 173, true)
            DisableControlAction(0, 174, true); DisableControlAction(0, 175, true)
            DisableControlAction(0, 10,  true); DisableControlAction(0, 11,  true)
            DisableControlAction(0, 200, true)

            local camPos = GetCamCoord(captureCam)
            local camRot = GetCamRot(captureCam, 2)
            -- Forward vector using captureCam
            local rot = camRot
            local fwd = vector3(
                -math.sin(math.rad(rot.z)) * math.abs(math.cos(math.rad(rot.x))),
                 math.cos(math.rad(rot.z)) * math.abs(math.cos(math.rad(rot.x))),
                 math.sin(math.rad(rot.x))
            )
            local rgt = vector3(-fwd.y, fwd.x, 0.0)
            if IsDisabledControlPressed(0, 172) then camPos = camPos + fwd * 0.1 end
            if IsDisabledControlPressed(0, 173) then camPos = camPos - fwd * 0.1 end
            if IsDisabledControlPressed(0, 175) then camPos = camPos - rgt * 0.1 end
            if IsDisabledControlPressed(0, 174) then camPos = camPos + rgt * 0.1 end
            if IsDisabledControlPressed(0, 10)  then camPos = camPos + vector3(0,0, 0.1) end
            if IsDisabledControlPressed(0, 11)  then camPos = camPos - vector3(0,0, 0.1) end
            SetCamCoord(captureCam, camPos)
            local xMag = GetControlNormal(0, 1) * 60.0
            local yMag = GetControlNormal(0, 2) * 60.0
            camRot = vector3(camRot.x - yMag, camRot.y, camRot.z - xMag)
            SetCamRot(captureCam, camRot.x, 0.0, camRot.z, 2)

            -- ESC cancels
            if IsDisabledControlJustPressed(0, 200) then cancelCamCapture() end
        end

        -- ═══════════════════════════════════════
        -- FREECAM ACTIVE
        -- ═══════════════════════════════════════
        if freeCamActive then
            disablePlayerControls()
            if dofEnabled then SetUseHiDof() end

            -- ── Wheel turn (N/M) when stationary ──
            if isPlayerStationary() then
                local ped = PlayerPedId()
                local veh = GetVehiclePedIsIn(ped, false)
                if DoesEntityExist(veh) then
                    if IsDisabledControlPressed(0, 249) then
                        wheelAngle = math.max(-WHEEL_MAX, wheelAngle - WHEEL_STEP)
                        nuiUpdate({ wheelAngle = wheelAngle })
                    end
                    if IsDisabledControlPressed(0, 244) then
                        wheelAngle = math.min(WHEEL_MAX, wheelAngle + WHEEL_STEP)
                        nuiUpdate({ wheelAngle = wheelAngle })
                    end
                    SetVehicleSteeringAngle(veh, wheelAngle)
                end
            end

            -- ── Hold modifier + scroll ──
            local holdZ = IsDisabledControlPressed(0, 20)
            local holdX = IsDisabledControlPressed(0, 73)
            local holdQ = IsDisabledControlPressed(0, 44)
            local holdG = IsDisabledControlPressed(0, 47)
            local holdB = IsDisabledControlPressed(0, 29)
            local anyHeld = holdZ or holdX or holdQ or holdG or holdB
            local delta   = anyHeld and scrollDelta() or 0
            local inVehCam = (activeCamMode ~= 'freecam' and activeCamMode ~= 'vehicle_cinematic')

            if holdZ and delta ~= 0 then
                dofNearDist = math.max(0.1, math.min(50.0, dofNearDist + delta*0.2))
                dofFarDist  = math.max(dofNearDist+1.0, dofFarDist)
                if not dofEnabled then dofEnabled = true end
                applyDOF(); nuiUpdate({ dofEnabled=dofEnabled, dofNear=dofNearDist, dofFar=dofFarDist })
            elseif holdX and delta ~= 0 then
                dofFarDist = math.max(dofNearDist+1.0, math.min(200.0, dofFarDist+delta*0.5))
                if not dofEnabled then dofEnabled = true end
                applyDOF(); nuiUpdate({ dofEnabled=dofEnabled, dofFar=dofFarDist })
            elseif holdQ and delta ~= 0 then
                shakeAmplitude = math.max(0.0, math.min(3.0, shakeAmplitude+delta*0.05))
                shakeEnabled   = shakeAmplitude > 0.0
                applyShake(); nuiUpdate({ shake=shakeAmplitude })
            elseif holdG and delta ~= 0 then
                tcStrength = math.max(0.0, math.min(5.0, tcStrength+delta*0.1))
                SetTimecycleModifierStrength(tcStrength); nuiUpdate({ tcStrength=tcStrength })
            elseif holdB and delta ~= 0 then
                barsSize    = math.max(0.0, math.min(0.30, barsSize+delta*0.005))
                barsEnabled = barsSize > 0.0
                nuiUpdate({ bars=barsEnabled and barsSize or 0.0 })
            elseif not anyHeld then
                local fd = scrollDelta()
                if fd ~= 0 and not inVehCam then
                    currentFOV = math.max(10.0, math.min(120.0, currentFOV - fd*2.0))
                    SetCamFov(cam, currentFOV); nuiUpdate({ fov=currentFOV })
                end
            end

            -- ── DOF toggle: Z held 3s ──
            if IsDisabledControlJustPressed(0, 20) then _zPressedAt = GetGameTimer(); _dofToggleFired = false end
            if IsDisabledControlPressed(0, 20) then
                if not _dofToggleFired and _zPressedAt and (GetGameTimer()-_zPressedAt) >= 3000 then
                    if delta == 0 then dofEnabled = not dofEnabled; applyDOF(); nuiUpdate({ dofEnabled=dofEnabled }) end
                    _dofToggleFired = true
                end
            else
                _zPressedAt = nil; _dofToggleFired = false
            end

            -- ── Tap B = toggle bars ──
            if IsDisabledControlJustPressed(0,29) and delta==0 and not holdZ and not holdX and not holdQ and not holdG then
                barsEnabled = not barsEnabled
                nuiUpdate({ bars=barsEnabled and barsSize or 0.0 })
            end

            -- ────────────────────────────────────
            -- FREE CAM FLIGHT (activeCamMode == 'freecam', not in capture mode)
            -- ────────────────────────────────────
            if not playbackActive and activeCamMode == 'freecam' and not _camCaptureMode then
                local camPos = GetCamCoord(cam)
                local camRot = GetCamRot(cam, 2)
                if IsDisabledControlPressed(0,172) then camPos = camPos + GetCamForwardVector()*0.1 end
                if IsDisabledControlPressed(0,173) then camPos = camPos - GetCamForwardVector()*0.1 end
                if IsDisabledControlPressed(0,175) then camPos = camPos - GetCamRightVector()*0.1 end
                if IsDisabledControlPressed(0,174) then camPos = camPos + GetCamRightVector()*0.1 end
                if IsDisabledControlPressed(0,10)  then camPos = camPos + vector3(0,0, 0.1) end
                if IsDisabledControlPressed(0,11)  then camPos = camPos - vector3(0,0, 0.1) end
                SetCamCoord(cam, camPos)
                local xMag = GetControlNormal(0,1)*60.0
                local yMag = GetControlNormal(0,2)*60.0
                camRot = vector3(camRot.x - yMag, camRot.y, camRot.z - xMag)
                if _rollLeft  then rollAngle = rollAngle - 1.0; _rollLeft  = false end
                if _rollRight then rollAngle = rollAngle + 1.0; _rollRight = false end
                SetCamRot(cam, camRot.x, rollAngle, camRot.z, 2)

            -- ────────────────────────────────────
            -- CAM CAPTURE FLIGHT (freecam is in capture mode — fly freely, no mouse look restriction)
            -- ────────────────────────────────────
            elseif not playbackActive and _camCaptureMode and cam then
                local camPos = GetCamCoord(cam)
                local camRot = GetCamRot(cam, 2)
                if IsDisabledControlPressed(0,172) then camPos = camPos + GetCamForwardVector()*0.1 end
                if IsDisabledControlPressed(0,173) then camPos = camPos - GetCamForwardVector()*0.1 end
                if IsDisabledControlPressed(0,175) then camPos = camPos - GetCamRightVector()*0.1 end
                if IsDisabledControlPressed(0,174) then camPos = camPos + GetCamRightVector()*0.1 end
                if IsDisabledControlPressed(0,10)  then camPos = camPos + vector3(0,0, 0.1) end
                if IsDisabledControlPressed(0,11)  then camPos = camPos - vector3(0,0, 0.1) end
                SetCamCoord(cam, camPos)
                local xMag = GetControlNormal(0,1)*60.0
                local yMag = GetControlNormal(0,2)*60.0
                camRot = vector3(camRot.x - yMag, camRot.y, camRot.z - xMag)
                SetCamRot(cam, camRot.x, 0.0, camRot.z, 2)
            end

            -- ────────────────────────────────────
            -- VEHICLE CAM: per-frame scripted positioning
            -- Mouse look is BLOCKED here — input only comes from head tracking or is zeroed
            -- ────────────────────────────────────
            if not playbackActive and _vehCamMode ~= nil and cam then
                -- Consume mouse inputs so they cannot affect the camera or game state
                DisableControlAction(0, 1, true)  -- LookLeftRight
                DisableControlAction(0, 2, true)  -- LookUpDown
                local ped = PlayerPedId()
                local veh = GetVehiclePedIsIn(ped, false)
                if DoesEntityExist(veh) then
                    local cfg = getCamCfg(_vehCamMode)
                    if cfg then
                        -- Mouse look is intentionally NEVER read here.
                        -- Head tracking uses GetVehicleSteeringAngle × HEAD_TRACK_SCALE; otherwise yaw eases back to 0.
                        if headTrackEnabled then
                            -- Lerp smoothly toward target yaw — no snapping
                            local rawSteer = GetVehicleSteeringAngle(veh)   -- degrees, typically ±35–70
                            local targetYaw = rawSteer * HEAD_TRACK_SCALE
                            _vehCamYaw = _vehCamYaw + (targetYaw - _vehCamYaw) * HEAD_TRACK_LERP
                            _vehCamPitch = cfg.initPitch
                        else
                            -- Gradually return to centre so it doesn't snap
                            _vehCamYaw   = _vehCamYaw * 0.85
                            _vehCamPitch = cfg.initPitch
                        end

                        local vehPos = GetEntityCoords(veh)
                        local vehRot = GetEntityRotation(veh, 2)
                        local heading = math.rad(vehRot.z)
                        local cosH = math.cos(heading); local sinH = math.sin(heading)
                        local wx = cosH * cfg.lx - sinH * cfg.ly
                        local wy = sinH * cfg.lx + cosH * cfg.ly
                        SetCamCoord(cam, vector3(vehPos.x+wx, vehPos.y+wy, vehPos.z+cfg.lz))
                        SetCamRot(cam, _vehCamPitch, cfg.initRoll or 0.0, vehRot.z + _vehCamYaw + (cfg.initYaw or 0.0), 2)
                    end
                end
            end

            -- ── Filter cycle ──
            if _filterPrev then cycleFilter(-1); _filterPrev = false end
            if _filterNext then cycleFilter(1);  _filterNext = false end

            -- ── Pending cinematic mode ──
            if _pendingCamMode == 'cinematic' and _pendingCamFrames > 0 then
                SetCinematicModeActive(true)
                _pendingCamFrames = _pendingCamFrames - 1
                if _pendingCamFrames <= 0 then _pendingCamMode = nil end
            end

            -- ── ESC ──
            if IsDisabledControlJustPressed(0, 200) then
                if _camCaptureMode then
                    cancelCamCapture()
                elseif cinematicOpen then
                    cinematicOpen = false; nuiCinematicClose(); SetNuiFocus(false, false)
                elseif camSwitcherOpen then
                    camSwitcherOpen = false; nuiCamSwitcherClose(); SetNuiFocus(false, false)
                elseif presetPanelOpen then
                    presetPanelOpen = false; nuiPresetPanelClose(); SetNuiFocus(false, false)
                elseif freeCamActive then
                    toggleFreeCam()
                    TriggerEvent('mnc-freecam:setHideUIs', false)
                end
            end

            -- ── Backspace — toggle HUD panels ──
            if IsControlJustPressed(1, 177) then
                helpersVisible = not helpersVisible
                if helpersVisible then nuiShow() else nuiHide() end
            end
        end

        -- ═══════════════════════════════════════
        -- CAMSETS STANDALONE — vehicle cam positioning (no freecam, uses camSetsCam)
        -- ═══════════════════════════════════════
        if camSetsActive and not freeCamActive and _vehCamMode ~= nil and camSetsCam then
            DisableControlAction(0, 1, true)  -- LookLeftRight
            DisableControlAction(0, 2, true)  -- LookUpDown
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if DoesEntityExist(veh) then
                local cfg = getCamCfg(_vehCamMode)
                if cfg then
                    if headTrackEnabled then
                        local rawSteer = GetVehicleSteeringAngle(veh)
                        local targetYaw = rawSteer * HEAD_TRACK_SCALE
                        _vehCamYaw = _vehCamYaw + (targetYaw - _vehCamYaw) * HEAD_TRACK_LERP
                        _vehCamPitch = cfg.initPitch
                    else
                        _vehCamYaw   = _vehCamYaw * 0.85
                        _vehCamPitch = cfg.initPitch
                    end
                    local vehPos = GetEntityCoords(veh)
                    local vehRot = GetEntityRotation(veh, 2)
                    local heading = math.rad(vehRot.z)
                    local cosH = math.cos(heading); local sinH = math.sin(heading)
                    local wx = cosH * cfg.lx - sinH * cfg.ly
                    local wy = sinH * cfg.lx + cosH * cfg.ly
                    SetCamCoord(camSetsCam, vector3(vehPos.x+wx, vehPos.y+wy, vehPos.z+cfg.lz))
                    SetCamRot(camSetsCam, _vehCamPitch, cfg.initRoll or 0.0, vehRot.z + _vehCamYaw + (cfg.initYaw or 0.0), 2)
                end
            else
                -- Left the vehicle — shut down camsets entirely
                SetCinematicModeActive(false)
                activeCamMode = 'freecam'
                _vehCamMode   = nil
                headTrackEnabled = false
                _vehCamYaw = 0.0
                DestroyCam(camSetsCam, false); camSetsCam = nil
                RenderScriptCams(false, false, 0, true, true)
                restorePedVisibility()
                SetEntityVisible(PlayerPedId(), true, false)
                camSetsActive   = false
                camSwitcherOpen = false
                nuiCamSwitcherClose()
                SetNuiFocus(false, false)
                notify('info', 'Camera Sets closed — exited vehicle')
            end
        end
    end
end)