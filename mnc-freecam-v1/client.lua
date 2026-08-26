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

local currentFilterIndex = 1  -- starts at "None"
local cam               = nil
local freeCamActive     = false
local currentFOV        = 90.0
local rollAngle         = 0.0
local helpersVisible    = true

-- ─────────────────────────────────────────────
-- NUI helpers
-- ─────────────────────────────────────────────
local function nuiShow()
    SendNUIMessage({
        type   = "show",
        fov    = currentFOV,
        filter = filters[currentFilterIndex],
    })
end

local function nuiHide()
    SendNUIMessage({ type = "hide" })
end

local function nuiUpdateFov()
    SendNUIMessage({ type = "updateFov", fov = currentFOV })
end

local function nuiUpdateFilter()
    SendNUIMessage({ type = "updateFilter", filter = filters[currentFilterIndex] })
end

-- ─────────────────────────────────────────────
-- Filter cycling
-- ─────────────────────────────────────────────
local function applyFilter(index)
    -- clear previous
    if currentFilterIndex > 1 then
        StopScreenEffect(filters[currentFilterIndex])
    end
    ClearTimecycleModifier()

    currentFilterIndex = index

    if currentFilterIndex > 1 then
        local name = filters[currentFilterIndex]
        -- timecycle modifier vs screen effect — try both approaches
        if name == "yell_tunnel_nodirect" then
            SetTimecycleModifier(name)
        else
            StartScreenEffect(name, 0, true)
        end
    end
end

local function cycleFilter()
    local nextIndex = (currentFilterIndex % #filters) + 1
    applyFilter(nextIndex)
    nuiUpdateFilter()
end

-- ─────────────────────────────────────────────
-- Camera math helpers
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

        -- Clear any active filter
        applyFilter(1)
        nuiUpdateFilter()

        DestroyCam(cam, false)
        RenderScriptCams(false, false, 0, true, true)
        cam = nil

        rollAngle = 0.0
        currentFOV = 90.0

        DisplayHud(true)
        DisplayRadar(true)
        TriggerEvent('es:setMoneyDisplay', 1.0)

        FreezeEntityPosition(PlayerPedId(), false)

        nuiHide()
    end
end

-- ─────────────────────────────────────────────
-- Disable movement controls while in cam
-- ─────────────────────────────────────────────
local function disablePlayerControls()
    DisableControlAction(0, 30, true)  -- Move Left/Right
    DisableControlAction(0, 31, true)  -- Move Up/Down
    DisableControlAction(0, 140, true) -- Melee Light
    DisableControlAction(0, 141, true) -- Melee Heavy
    DisableControlAction(0, 142, true) -- Melee Alt
    DisableControlAction(0, 24, true)  -- Attack
    DisableControlAction(0, 25, true)  -- Aim
    DisableControlAction(0, 22, true)  -- Jump
    DisableControlAction(0, 23, true)  -- Enter Vehicle
    DisableControlAction(0, 75, true)  -- Exit Vehicle
    DisableControlAction(0, 45, true)  -- Reload
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

            local camPos = GetCamCoord(cam)
            local camRot = GetCamRot(cam, 2)

            -- ── Position controls ──
            if IsControlPressed(1, 32) then  -- W
                camPos = camPos + (GetCamForwardVector() * 0.1)
            end
            if IsControlPressed(1, 33) then  -- S
                camPos = camPos - (GetCamForwardVector() * 0.1)
            end
            if IsControlPressed(1, 34) then  -- A  (strafe left)
                camPos = camPos + (GetCamRightVector() * 0.1)
            end
            if IsControlPressed(1, 35) then  -- D  (strafe right)
                camPos = camPos - (GetCamRightVector() * 0.1)
            end
            if IsControlPressed(1, 44) then  -- Q  (up)
                camPos = camPos + vector3(0.0, 0.0, 0.1)
            end
            if IsControlPressed(1, 38) then  -- E  (down)
                camPos = camPos - vector3(0.0, 0.0, 0.1)
            end

            SetCamCoord(cam, camPos)

            -- ── Mouse look ──
            local xMag = GetControlNormal(0, 1) * 8.0
            local yMag = GetControlNormal(0, 2) * 8.0
            camRot = vector3(camRot.x - yMag, camRot.y, camRot.z - xMag)

            -- ── Roll (arrow keys) ──
            if IsControlPressed(1, 174) then rollAngle = rollAngle - 1.0 end  -- ◄
            if IsControlPressed(1, 175) then rollAngle = rollAngle + 1.0 end  -- ►

            SetCamRot(cam, camRot.x, rollAngle, camRot.z, 2)

            -- ── Zoom — mouse scroll wheel ──
            -- Control 241 = Mouse Wheel Up  (scroll in)
            -- Control 242 = Mouse Wheel Down (scroll out)
            local fovChanged = false
            if IsDisabledControlPressed(0, 241) or IsControlPressed(1, 16) then
                currentFOV = math.max(30.0, currentFOV - 2.0)
                fovChanged = true
            end
            if IsDisabledControlPressed(0, 242) or IsControlPressed(1, 17) then
                currentFOV = math.min(120.0, currentFOV + 2.0)
                fovChanged = true
            end
            if fovChanged then
                SetCamFov(cam, currentFOV)
                nuiUpdateFov()
            end

            -- ── Filter cycle (Up / Down arrow) ──
            if IsControlJustPressed(1, 172) then  -- Arrow Up
                cycleFilter()
            end
            if IsControlJustPressed(1, 173) then  -- Arrow Down (reverse)
                local prevIndex = ((currentFilterIndex - 2) % #filters) + 1
                applyFilter(prevIndex)
                nuiUpdateFilter()
            end

            -- ── Toggle HUD panel (Backspace) ──
            if IsControlJustPressed(1, 177) then  -- Backspace
                helpersVisible = not helpersVisible
                if helpersVisible then
                    nuiShow()
                else
                    nuiHide()
                end
            end
        end
    end
end)
