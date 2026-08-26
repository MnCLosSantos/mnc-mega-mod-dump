-- client.lua — mnc-freecam

local filters = {
    "None",
    "FocusOut",
    "ChopVision",
    "DMT_flight",
    "DrugsMichaelAliensFight",
    "DrugsTrevorClownsFight",
    "HeistCelebPass",
    "HeistCelebPassBW",
    "MP_Bull_tost",
    "SniperOverlay",
    "Rampage",
    "DeathFailMPDark",
    "PPFilter",
    "PPGreen",
    "PPOrange",
    "PPPink",
    "PPPurple",
    "BikerFilter",
    "LostTimeDay",
    "LostTimeNight",
    "InchOrange",
    "InchPurple",
    "DeadlineNeon",
    "MP_Powerplay",
    "Dont_tazeme_bro",
    "DrugsDrivingIn",
    "RaceTurbo",
    "ExplosionJosh3",
    "DefaultFlash",
    "MP_OrbitalCannon",
    "MP_Killstreak",
    "yell_tunnel_nodirect",
}

-- ─────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────
local currentFilterIndex = 1
local cam                = nil
local freeCamActive      = false
local currentFOV         = 90.0
local rollAngle          = 0.0
local helpersVisible     = true

-- DOF
local dofEnabled    = false
local dofNearDist   = 1.0    -- near focus start  (0.1 – 50)
local dofFarDist    = 15.0   -- far focus end     (1.0 – 200)
local dofStrength   = 1.0    -- blur strength     (0.0 – 1.0)

-- Shake
local shakeEnabled   = false
local shakeAmplitude = 0.0   -- 0.0 – 3.0

-- Cinematic bars
local barsEnabled = false
local barsSize    = 0.08     -- fraction of screen height  0.0 – 0.30

-- Timecycle strength
local tcStrength = 1.0       -- 0.0 – 5.0

-- ─────────────────────────────────────────────
-- NUI helpers
-- ─────────────────────────────────────────────
local function nuiSend(data)
    SendNUIMessage(data)
end

local function nuiShow()
    nuiSend({
        type       = "show",
        fov        = currentFOV,
        filter     = filters[currentFilterIndex],
        dofEnabled = dofEnabled,
        dofNear    = dofNearDist,
        dofFar     = dofFarDist,
        dofStr     = dofStrength,
        shake      = shakeAmplitude,
        bars       = barsEnabled and barsSize or 0.0,
        tcStrength = tcStrength,
    })
end

local function nuiHide()
    nuiSend({ type = "hide" })
end

local function nuiUpdate(patch)
    patch.type = "update"
    nuiSend(patch)
end

-- ─────────────────────────────────────────────
-- DOF — correct FiveM natives
-- SetCamUseShallowDofMode / SetCamNearDof / SetCamFarDof / SetCamDofStrength
-- SetUseHiDof must be called every frame while active
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

-- ─────────────────────────────────────────────
-- Shake
-- ─────────────────────────────────────────────
local function applyShake()
    if not cam then return end
    if shakeEnabled and shakeAmplitude > 0.0 then
        ShakeCam(cam, "HAND_SHAKE", shakeAmplitude)
    else
        StopCamShaking(cam, true)
    end
end

-- ─────────────────────────────────────────────
-- Filter cycling
-- ─────────────────────────────────────────────
local function applyFilter(index)
    -- clear previous
    if currentFilterIndex > 1 then
        local prev = filters[currentFilterIndex]
        if prev == "yell_tunnel_nodirect" then
            ClearTimecycleModifier()
        else
            StopScreenEffect(prev)
        end
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
-- Reset all effects on cam close
-- ─────────────────────────────────────────────
local function resetEffects()
    applyFilter(1)
    dofEnabled    = false
    shakeEnabled  = false
    shakeAmplitude = 0.0
    barsEnabled   = false
    if cam then
        SetCamUseShallowDofMode(cam, false)
        SetCamDofStrength(cam, 0.0)
        StopCamShaking(cam, true)
    end
    ClearTimecycleModifier()
    nuiUpdate({
        filter     = "None",
        dofEnabled = false,
        dofNear    = dofNearDist,
        dofFar     = dofFarDist,
        dofStr     = dofStrength,
        shake      = 0.0,
        bars       = 0.0,
        tcStrength = tcStrength,
    })
end

-- ─────────────────────────────────────────────
-- Camera math
-- ─────────────────────────────────────────────
local function GetCamForwardVector()
    local rot = GetCamRot(cam, 2)
    local x = -math.sin(math.rad(rot.z)) * math.abs(math.cos(math.rad(rot.x)))
    local y =  math.cos(math.rad(rot.z)) * math.abs(math.cos(math.rad(rot.x)))
    local z =  math.sin(math.rad(rot.x))
    return vector3(x, y, z)
end

local function GetCamRightVector()
    local fwd = GetCamForwardVector()
    return vector3(-fwd.y, fwd.x, 0.0)
end

-- ─────────────────────────────────────────────
-- Toggle free cam
-- ─────────────────────────────────────────────
local function toggleFreeCam()
    if not freeCamActive then
        freeCamActive = true
        local playerPed = PlayerPedId()

        cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        local pos = GetEntityCoords(playerPed)
        SetCamCoord(cam, pos.x, pos.y, pos.z + 1.0)
        SetCamRot(cam, 0.0, 0.0, 0.0)
        SetCamFov(cam, currentFOV)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, true)

        DisplayHud(false)
        DisplayRadar(false)
        TriggerEvent('es:setMoneyDisplay', 0.0)
        FreezeEntityPosition(playerPed, true)

        nuiShow()
    else
        freeCamActive = false
        resetEffects()

        DestroyCam(cam, false)
        RenderScriptCams(false, false, 0, true, true)
        cam = nil

        rollAngle  = 0.0
        currentFOV = 90.0

        DisplayHud(true)
        DisplayRadar(true)
        TriggerEvent('es:setMoneyDisplay', 1.0)
        FreezeEntityPosition(PlayerPedId(), false)

        nuiHide()
    end
end

-- ─────────────────────────────────────────────
-- Disable player controls while in cam
-- ─────────────────────────────────────────────
local function disablePlayerControls()
    DisableControlAction(0, 30, true)
    DisableControlAction(0, 31, true)
    DisableControlAction(0, 140, true)
    DisableControlAction(0, 141, true)
    DisableControlAction(0, 142, true)
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true)
    DisableControlAction(0, 22, true)
    DisableControlAction(0, 23, true)
    DisableControlAction(0, 75, true)
    DisableControlAction(0, 45, true)
end

-- ─────────────────────────────────────────────
-- Scroll delta: +1 = wheel up, -1 = wheel down
-- ─────────────────────────────────────────────
local function scrollDelta()
    if IsDisabledControlPressed(0, 241) then return  1 end
    if IsDisabledControlPressed(0, 242) then return -1 end
    return 0
end

-- ─────────────────────────────────────────────
-- Activation command
-- ─────────────────────────────────────────────
RegisterCommand(Config.ActivationCommand, function()
    toggleFreeCam()
end, false)

-- ─────────────────────────────────────────────
-- Main thread
-- ─────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if freeCamActive then
            disablePlayerControls()

            -- Call SetUseHiDof every frame when DOF is active (required by the native)
            if dofEnabled then SetUseHiDof() end

            local camPos = GetCamCoord(cam)
            local camRot = GetCamRot(cam, 2)

            -- ── Held modifier keys ──
            -- Z=20  X=73  C=26  G=47  B=29
            local holdZ = IsDisabledControlPressed(0, 20)
            local holdX = IsDisabledControlPressed(0, 73)
            local holdC = IsDisabledControlPressed(0, 26)
            local holdG = IsDisabledControlPressed(0, 47)
            local holdB = IsDisabledControlPressed(0, 29)
            local anyHeld = holdZ or holdX or holdC or holdG or holdB
            local delta   = anyHeld and scrollDelta() or 0

            -- ── DOF near distance  (Hold Z + scroll) ──
            if holdZ and delta ~= 0 then
                dofNearDist = math.max(0.1, math.min(50.0, dofNearDist + delta * 0.2))
                -- keep far ahead of near
                dofFarDist  = math.max(dofNearDist + 1.0, dofFarDist)
                if not dofEnabled then dofEnabled = true end
                applyDOF()
                nuiUpdate({ dofEnabled = dofEnabled, dofNear = dofNearDist, dofFar = dofFarDist })

            -- ── DOF far distance  (Hold X + scroll) ──
            elseif holdX and delta ~= 0 then
                dofFarDist = math.max(dofNearDist + 1.0, math.min(200.0, dofFarDist + delta * 0.5))
                if not dofEnabled then dofEnabled = true end
                applyDOF()
                nuiUpdate({ dofEnabled = dofEnabled, dofFar = dofFarDist })

            -- ── Camera shake  (Hold C + scroll) ──
            elseif holdC and delta ~= 0 then
                shakeAmplitude = math.max(0.0, math.min(3.0, shakeAmplitude + delta * 0.05))
                shakeEnabled   = shakeAmplitude > 0.0
                applyShake()
                nuiUpdate({ shake = shakeAmplitude })

            -- ── Timecycle strength  (Hold G + scroll) ──
            elseif holdG and delta ~= 0 then
                tcStrength = math.max(0.0, math.min(5.0, tcStrength + delta * 0.1))
                SetTimecycleModifierStrength(tcStrength)
                nuiUpdate({ tcStrength = tcStrength })

            -- ── Cinematic bars  (Hold B + scroll) ──
            elseif holdB and delta ~= 0 then
                barsSize    = math.max(0.0, math.min(0.30, barsSize + delta * 0.005))
                barsEnabled = barsSize > 0.0
                nuiUpdate({ bars = barsEnabled and barsSize or 0.0 })

            -- ── FOV  (no hold + scroll) ──
            elseif not anyHeld then
                local fd = scrollDelta()
                if fd ~= 0 then
                    currentFOV = math.max(10.0, math.min(120.0, currentFOV - fd * 2.0))
                    SetCamFov(cam, currentFOV)
                    nuiUpdate({ fov = currentFOV })
                end
            end

            -- ── Toggle DOF on/off  (tap Z alone) ──
            if IsDisabledControlJustPressed(0, 20) and delta == 0 and not holdX and not holdC and not holdG and not holdB then
                dofEnabled = not dofEnabled
                applyDOF()
                nuiUpdate({ dofEnabled = dofEnabled })
            end

            -- ── Toggle bars on/off  (tap B alone, no scroll) ──
            if IsDisabledControlJustPressed(0, 29) and delta == 0 and not holdZ and not holdX and not holdC and not holdG then
                barsEnabled = not barsEnabled
                nuiUpdate({ bars = barsEnabled and barsSize or 0.0 })
            end

            -- ── Position ──
            if IsControlPressed(1, 32) then camPos = camPos + (GetCamForwardVector() * 0.1) end
            if IsControlPressed(1, 33) then camPos = camPos - (GetCamForwardVector() * 0.1) end
            if IsControlPressed(1, 34) then camPos = camPos + (GetCamRightVector()   * 0.1) end
            if IsControlPressed(1, 35) then camPos = camPos - (GetCamRightVector()   * 0.1) end
            if IsControlPressed(1, 44) then camPos = camPos + vector3(0.0, 0.0,  0.1)       end
            if IsControlPressed(1, 38) then camPos = camPos - vector3(0.0, 0.0,  0.1)       end
            SetCamCoord(cam, camPos)

            -- ── Mouse look ──
            local xMag = GetControlNormal(0, 1) * 8.0
            local yMag = GetControlNormal(0, 2) * 8.0
            camRot = vector3(camRot.x - yMag, camRot.y, camRot.z - xMag)

            -- ── Roll ──
            if IsControlPressed(1, 174) then rollAngle = rollAngle - 1.0 end
            if IsControlPressed(1, 175) then rollAngle = rollAngle + 1.0 end
            SetCamRot(cam, camRot.x, rollAngle, camRot.z, 2)

            -- ── Filter cycle ──
            if IsControlJustPressed(1, 172) then cycleFilter(1)  end
            if IsControlJustPressed(1, 173) then cycleFilter(-1) end

            -- ── Toggle HUD ──
            if IsControlJustPressed(1, 177) then
                helpersVisible = not helpersVisible
                if helpersVisible then nuiShow() else nuiHide() end
            end
        end
    end
end)
