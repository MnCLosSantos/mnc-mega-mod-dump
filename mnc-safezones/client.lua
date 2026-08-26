local QBCore = exports['qb-core']:GetCoreObject()

local SafeZones      = {}
local ActiveZones    = {}
local InSafeZone     = false
local CurrentZoneName = nil

-- Forward declarations: the NUI callbacks below need to call into the
-- freecam functions, which are implemented further down the file for
-- readability. Declaring the locals here lets both sides share them.
local StartFreecam, StopFreecam

-- ─── Always read live from QBCore – never cache job data ──────────────────────
-- Caching PlayerData.job leads to stale data after job changes.
-- QBCore.Functions.GetPlayerData() is cheap and always accurate.
local function GetJob()
    local pd = QBCore.Functions.GetPlayerData()
    return pd and pd.job
end

local function IsExempt()
    local job = GetJob()
    if not job then return false end
    for _, exemptJob in ipairs(Config.ExemptJobs) do
        if job.name == exemptJob then return true end
    end
    return false
end

-- ─── External visibility flag ─────────────────────────────────────────────────
-- Controlled by mnc-jobhud via:
--   TriggerEvent('mnc-safezones:setVisible', false)  -- hide HUD
--   TriggerEvent('mnc-safezones:setVisible', true)   -- restore HUD
local MNC_SAFEZONES_VISIBLE = true

AddEventHandler('mnc-safezones:setVisible', function(v)
    if MNC_SAFEZONES_VISIBLE == v then return end
    MNC_SAFEZONES_VISIBLE = v
    if not v then
        SendNUIMessage({ action = 'hideZoneHUD' })
    else
        -- Restore: re-show HUD if player is currently inside a zone
        if InSafeZone and CurrentZoneName then
            SendNUIMessage({
                action = 'showZoneHUD',
                name   = CurrentZoneName,
                exempt = IsExempt(),
            })
        end
    end
end)

-- ─── NUI HUD: show/hide zone indicator ────────────────────────────────────────
local function ShowZoneHUD(zoneName, exempt)
    if not MNC_SAFEZONES_VISIBLE then return end  -- suppressed by mnc-jobhud
    SendNUIMessage({
        action  = 'showZoneHUD',
        name    = zoneName,
        exempt  = exempt,
    })
end

local function HideZoneHUD()
    SendNUIMessage({ action = 'hideZoneHUD' })
end

-- ─── Zone management ──────────────────────────────────────────────────────────
-- Builds the shared onEnter/onExit callbacks for a given zone. Both shapes
-- (legacy circle and new polygon) use identical enter/exit behaviour.
local function MakeZoneCallbacks(zone)
    local function onEnter()
        InSafeZone      = true
        CurrentZoneName = zone.name
        ShowZoneHUD(zone.name, IsExempt())
    end
    local function onExit()
        InSafeZone      = false
        CurrentZoneName = nil
        HideZoneHUD()
        -- Always restore on exit regardless of exempt status
        local ped = PlayerPedId()
        SetPedCanSwitchWeapon(ped, true)
        SetPlayerCanDoDriveBy(PlayerId(), true)
    end
    return onEnter, onExit
end

local function DestroyAllZones()
    for _, handle in pairs(ActiveZones) do
        if handle and handle.remove then handle:remove() end
    end
    ActiveZones     = {}
    InSafeZone      = false
    CurrentZoneName = nil
    HideZoneHUD()
end

local function BuildZones(zones)
    DestroyAllZones()

    for _, zone in ipairs(zones) do
        local handle
        local onEnter, onExit = MakeZoneCallbacks(zone)

        if zone.shape == 'poly' and zone.points and #zone.points >= 3 then
            local pts = {}
            for _, p in ipairs(zone.points) do
                table.insert(pts, vector3(p.x, p.y, p.z))
            end

            -- ─── Polygon zone: straight-edge boundary through the captured points ──
            handle = lib.zones.poly({
                points    = pts,
                thickness = zone.height or Config.DefaultHeightRange,
                debug     = Config.Debug,
                onEnter   = onEnter,
                onExit    = onExit,
            })
        elseif zone.shape == 'circle' and zone.center_x and zone.center_y and zone.center_z and zone.radius then
            -- ─── Legacy circle zone from a pre-polygon install — unchanged behaviour ──
            handle = lib.zones.sphere({
                coords  = vector3(zone.center_x, zone.center_y, zone.center_z),
                radius  = zone.radius,
                debug   = Config.Debug,
                onEnter = onEnter,
                onExit  = onExit,
            })
        end

        if handle then
            ActiveZones[zone.id] = handle
        end
    end
end

-- ─── Keep HUD in sync if job changes while inside a zone ─────────────────────
AddEventHandler('QBCore:Client:OnJobUpdate', function()
    if InSafeZone and CurrentZoneName then
        ShowZoneHUD(CurrentZoneName, IsExempt())
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    if InSafeZone and CurrentZoneName then
        ShowZoneHUD(CurrentZoneName, IsExempt())
    end
end)

-- ─── Receive zones from server ────────────────────────────────────────────────
-- Fires on resource start, on player join, and after every add/remove — this
-- is the single source of truth for "the zone list changed". Every time it
-- fires we rebuild the in-world colliders AND push the fresh list straight
-- into the NUI, so an already-open admin panel updates live instead of only
-- refreshing the next time it's opened.
RegisterNetEvent('mnc-safezones:receiveSafeZones', function(zones)
    SafeZones = zones or {}
    BuildZones(SafeZones)
    SendNUIMessage({ action = 'updateZoneList', zones = SafeZones })
end)

-- ─── Pending points (in-progress zone being marked out) ───────────────────────
-- Admins capture points one at a time — either by clicking "Capture My
-- Position" in the panel, or by flying around with the "Start Freecam"
-- button. This list is client-authoritative; the NUI panel only ever
-- displays whatever it's sent and round-trips add/remove requests back here.
local PendingPoints = {}

local function SyncPendingPoints()
    SendNUIMessage({ action = 'setPendingPoints', points = PendingPoints })
end

-- Captures the player's current on-foot position as the next point of the
-- zone being marked out. Triggered by the "Capture My Position" NUI button.
local function CapturePlayerPosition()
    local coords = GetEntityCoords(PlayerPedId())
    table.insert(PendingPoints, {
        x = math.floor(coords.x * 100) / 100,
        y = math.floor(coords.y * 100) / 100,
        z = math.floor(coords.z * 100) / 100,
    })
    SyncPendingPoints()
    lib.notify({
        title       = 'Safe Zone',
        description = ('Point %d captured: %.1f, %.1f, %.1f'):format(#PendingPoints, coords.x, coords.y, coords.z),
        type        = 'success'
    })
end

-- Approximates a legacy circle zone as a 4-corner square, purely so editing
-- one has a sensible starting shape to adjust from — mirrors the server's
-- own seed/migration logic. The circle itself is never touched unless the
-- admin explicitly saves the edit.
local function CircleToSquarePoints(cx, cy, cz, r)
    return {
        { x = cx - r, y = cy - r, z = cz },
        { x = cx + r, y = cy - r, z = cz },
        { x = cx + r, y = cy + r, z = cz },
        { x = cx - r, y = cy + r, z = cz },
    }
end

-- ─── Open NUI menu ────────────────────────────────────────────────────────────
RegisterNetEvent('mnc-safezones:openMenu', function()
    SendNUIMessage({
        action        = 'openMenu',
        zones         = SafeZones,
        pendingPoints = PendingPoints,
        minPoints     = Config.MinZonePoints,
    })
    SetNuiFocus(true, true)
end)

-- ─── Disable combat thread ────────────────────────────────────────────────────
-- Wait(0) MUST be first so DisableControlAction runs every single frame.
-- Checking the condition after the wait means we always yield first,
-- then immediately apply disables before the game processes input.
CreateThread(function()
    while true do
        Wait(0)
        if InSafeZone and not IsExempt() then
            local ped = PlayerPedId()

            -- Shoot / attack (foot)
            DisableControlAction(0, 24,  true) -- Attack
            DisableControlAction(0, 25,  true) -- Aim
            DisableControlAction(0, 47,  true) -- Attack 2
            DisableControlAction(0, 58,  true) -- Sniper zoom / attack
            DisableControlAction(0, 22,  true) -- Jump (prevents throw-grenade)
            DisableControlAction(0, 26,  true) -- Look behind (prevents aim lock)

            -- Melee
            DisableControlAction(0, 263, true) -- Melee attack 1
            DisableControlAction(0, 264, true) -- Melee attack 2
            DisableControlAction(0, 140, true) -- Melee attack light
            DisableControlAction(0, 141, true) -- Melee attack heavy
            DisableControlAction(0, 142, true) -- Melee attack alternate

            -- Vehicle shoot / drive-by
            DisableControlAction(0, 68,  true) -- Vehicle attack (aim)
            DisableControlAction(0, 69,  true) -- Vehicle attack 2
            DisableControlAction(0, 70,  true) -- Vehicle attack alternate
            DisableControlAction(0, 91,  true) -- Vehicle passenger attack
            DisableControlAction(0, 92,  true) -- Vehicle passenger aim
            DisableControlAction(0, 114, true) -- Vehicle fly attack

            -- Weapon selection / throwing
            DisableControlAction(0, 37,  true) -- Select weapon (stops switching to throwables)

            SetPedCanSwitchWeapon(ped, false)
            SetPlayerCanDoDriveBy(PlayerId(), false)

            -- Hard-remove any current weapon aim state each frame
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= GetHashKey('WEAPON_UNARMED') then
                SetPedCurrentWeaponVisible(ped, false, true, true, true)
            end
        end
    end
end)

-- ─── NUI Callbacks ────────────────────────────────────────────────────────────
RegisterNUICallback('addZone', function(data, cb)
    TriggerServerEvent('mnc-safezones:addSafeZone', {
        name   = data.name,
        height = data.height,
        points = data.points,
    })
    -- Optimistically clear pending points; the server will broadcast the
    -- authoritative zone list once the insert succeeds.
    PendingPoints = {}
    SyncPendingPoints()
    cb('ok')
end)

RegisterNUICallback('addPendingPoint', function(data, cb)
    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    if x and y and z then
        table.insert(PendingPoints, { x = x, y = y, z = z })
        SyncPendingPoints()
    end
    cb('ok')
end)

RegisterNUICallback('removePendingPoint', function(data, cb)
    -- NUI sends a 0-based array index; Lua tables are 1-based.
    local index = tonumber(data.index)
    if index and PendingPoints[index + 1] then
        table.remove(PendingPoints, index + 1)
        SyncPendingPoints()
    end
    cb('ok')
end)

RegisterNUICallback('clearPendingPoints', function(_, cb)
    PendingPoints = {}
    SyncPendingPoints()
    cb('ok')
end)

RegisterNUICallback('capturePosition', function(_, cb)
    CapturePlayerPosition()
    cb('ok')
end)

RegisterNUICallback('startFreecam', function(_, cb)
    -- Hand control back to the game (mouse/keyboard) and hide the panel so
    -- it doesn't sit on screen while flying around; StopFreecam() (triggered
    -- by Esc in-world) brings the panel back with the freshly captured points.
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideMenuForFreecam' })
    StartFreecam()
    cb('ok')
end)

RegisterNUICallback('removeZone', function(data, cb)
    TriggerServerEvent('mnc-safezones:removeSafeZone', data.id)
    cb('ok')
end)

-- Loads an existing zone's boundary into PendingPoints so it can be adjusted
-- with the same tools used to create one (capture position, freecam, manual
-- entry) before saving. Works for legacy circle zones too — they're seeded
-- with an approximated square starting shape.
RegisterNUICallback('editZone', function(data, cb)
    local id = tonumber(data.id)
    local target = nil
    for _, zone in ipairs(SafeZones) do
        if zone.id == id then
            target = zone
            break
        end
    end

    if not target then
        cb('ok')
        return
    end

    PendingPoints = {}
    if target.shape == 'poly' and target.points then
        for _, p in ipairs(target.points) do
            table.insert(PendingPoints, { x = p.x, y = p.y, z = p.z })
        end
    elseif target.shape == 'circle' then
        PendingPoints = CircleToSquarePoints(target.center_x, target.center_y, target.center_z, target.radius)
    end

    SendNUIMessage({
        action         = 'editZone',
        id             = target.id,
        name           = target.name,
        height         = target.height,
        points         = PendingPoints,
        isLegacyCircle = (target.shape == 'circle'),
    })

    cb('ok')
end)

-- Saves changes to an existing zone (always as a polygon — see the server
-- handler for why legacy circles get upgraded on edit).
RegisterNUICallback('saveZoneEdit', function(data, cb)
    TriggerServerEvent('mnc-safezones:updateSafeZone', {
        id     = data.id,
        name   = data.name,
        height = data.height,
        points = data.points,
    })
    PendingPoints = {}
    SyncPendingPoints()
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ─── Commands ─────────────────────────────────────────────────────────────────
-- /safezones is the *only* command this resource needs — it opens the admin
-- panel, and every other action (capturing points, freecam, clearing,
-- creating/deleting zones) is done from buttons inside that one UI.
RegisterCommand('safezones', function()
    TriggerServerEvent('mnc-safezones:requestMenu')
end, false)

-- ════════════════════════════════════════════════════════════════════════════
-- ─── Freecam point placement (triggered by the panel's "Start Freecam" button) ─
-- ════════════════════════════════════════════════════════════════════════════
-- Lets an admin detach the camera and fly around to mark out a zone boundary
-- from the air/rooftops/anywhere hard to reach on foot, without having to
-- physically stand at each corner. Every placed point still just lands in the
-- same PendingPoints list used by "Capture My Position", so the two are
-- interchangeable.

local FreecamActive = false
local FreecamHandle  = nil
local FreecamSpeed   = Config.FreecamSpeed or 1.5

-- Converts a camera rotation (degrees) into a forward-facing unit vector.
local function RotationToDirection(rotation)
    local rx = math.rad(rotation.x)
    local rz = math.rad(rotation.z)
    local num = math.abs(math.cos(rx))
    return vector3(
        -math.sin(rz) * num,
        math.cos(rz) * num,
        math.sin(rx)
    )
end

-- Draws 2D text pinned to a 3D world position (screen-space projection).
local function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(sx, sy)
    end
end

StartFreecam = function()
    if FreecamActive then return end

    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local camRot  = GetGameplayCamRot(2)

    FreecamHandle = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        coords.x, coords.y, coords.z + 1.5,
        camRot.x, 0.0, camRot.z,
        GetGameplayCamFov(), false, 0)

    SetCamActive(FreecamHandle, true)
    RenderScriptCams(true, false, 0, true, true)

    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    DisplayRadar(false)

    FreecamActive = true

    SendNUIMessage({
        action = 'showFreecamLegend',
        points = #PendingPoints,
    })

    lib.notify({
        title       = 'Safe Zone',
        description = 'Freecam enabled — see the on-screen control legend',
        type        = 'inform'
    })
end

StopFreecam = function()
    if not FreecamActive then return end
    FreecamActive = false

    local ped = PlayerPedId()
    RenderScriptCams(false, true, 500, true, true)
    if FreecamHandle then
        DestroyCam(FreecamHandle, false)
        FreecamHandle = nil
    end

    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    DisplayRadar(true)

    SendNUIMessage({ action = 'hideFreecamLegend' })

    -- Bring the admin panel back automatically with whatever points were
    -- captured while flying around — no command needed to reopen it.
    SendNUIMessage({
        action        = 'reopenMenu',
        zones         = SafeZones,
        pendingPoints = PendingPoints,
        minPoints     = Config.MinZonePoints,
    })
    SetNuiFocus(true, true)
end

-- Safety net: never leave the player frozen/invisible if the resource is
-- stopped/restarted while freecam happens to be active.
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if FreecamActive then StopFreecam() end
end)

-- ─── Freecam input / movement thread ──────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(0)
        if FreecamActive and FreecamHandle then
            -- Block pause menu and attack/aim while flying. Both pause-menu
            -- controls are disabled: 200 (Esc) is what we read below to exit
            -- freecam, but 199 is the game's other pause-menu binding and can
            -- still pop the menu (with its Map tab) open on its own if left
            -- enabled — e.g. a controller's Start button, or a remapped key.
            DisableControlAction(0, 199, true) -- Pause menu (alternate)
            DisableControlAction(0, 200, true) -- Pause menu (Esc) — read via IsDisabledControlJustPressed below
            DisableControlAction(0, 24,  true) -- Attack
            DisableControlAction(0, 25,  true) -- Aim

            local dt = GetFrameTime()

            -- ── Look (mouse) ────────────────────────────────────────────────
            local lookLR = GetControlNormal(0, 1) -- INPUT_LOOK_LR
            local lookUD = GetControlNormal(0, 2) -- INPUT_LOOK_UD
            local sensitivity = Config.FreecamLookSensitivity or 200.0

            local rot = GetCamRot(FreecamHandle, 2)
            local newRotZ = rot.z - (lookLR * sensitivity * dt)
            local newRotX = math.max(-89.5, math.min(89.5, rot.x - (lookUD * sensitivity * dt)))
            SetCamRot(FreecamHandle, newRotX, 0.0, newRotZ, 2)

            -- ── Movement (WASD relative to look direction, Space/Ctrl vertical) ──
            local moveLR = GetControlNormal(0, 30) -- A/D strafe axis
            local moveUD = GetControlNormal(0, 31) -- W/S forward/back axis

            local boost = IsControlPressed(0, 21) and (Config.FreecamBoostMultiplier or 3.0) or 1.0
            local moveAmount = FreecamSpeed * boost * dt * 10.0

            local forward = RotationToDirection(vector3(newRotX, 0.0, newRotZ))
            local right   = vector3(forward.y, -forward.x, 0.0)

            local camCoord = GetCamCoord(FreecamHandle)
            local newCoord = camCoord
                - (forward * moveUD * moveAmount)
                + (right   * moveLR * moveAmount)

            if IsControlPressed(0, 22) then -- Space = ascend
                newCoord = newCoord + vector3(0.0, 0.0, moveAmount)
            end
            if IsControlPressed(0, 36) then -- Left Ctrl = descend
                newCoord = newCoord - vector3(0.0, 0.0, moveAmount)
            end

            SetCamCoord(FreecamHandle, newCoord.x, newCoord.y, newCoord.z)

            -- ── Preview point: out in front of the camera, not on top of it ──
            -- A marker drawn exactly at the camera's own position is
            -- invisible (the camera is inside it). Projecting it out in
            -- front makes it visible, and this exact spot is also where "E"
            -- places the point, so what you see is what you get.
            local previewDist = Config.FreecamPreviewDistance or 2.5
            local previewCoord = newCoord + (forward * previewDist)

            DrawMarker(1, previewCoord.x, previewCoord.y, previewCoord.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35, 0.35, 0.5, 245, 166, 35, 200, true, true, 2, false, nil, nil, false)
            DrawText3D(previewCoord.x, previewCoord.y, previewCoord.z + 0.35, 'E: place point')

            -- ── Place point (E) ─────────────────────────────────────────────
            if IsControlJustPressed(0, 38) then
                table.insert(PendingPoints, {
                    x = math.floor(previewCoord.x * 100) / 100,
                    y = math.floor(previewCoord.y * 100) / 100,
                    z = math.floor(previewCoord.z * 100) / 100,
                })
                SyncPendingPoints()
                SendNUIMessage({ action = 'updateFreecamPointCount', points = #PendingPoints })
                lib.notify({
                    title       = 'Safe Zone',
                    description = ('Point %d captured'):format(#PendingPoints),
                    type        = 'success'
                })
            end

            -- ── Undo last point (Backspace) ─────────────────────────────────
            if IsControlJustPressed(0, 194) and #PendingPoints > 0 then
                table.remove(PendingPoints)
                SyncPendingPoints()
                SendNUIMessage({ action = 'updateFreecamPointCount', points = #PendingPoints })
                lib.notify({
                    title       = 'Safe Zone',
                    description = 'Last point removed',
                    type        = 'inform'
                })
            end

            -- ── Exit freecam (Esc) ──────────────────────────────────────────
            -- Esc (control 200) is disabled above to stop it opening the pause
            -- menu, which means it must be read with IsDisabledControlJustPressed
            -- instead of IsControlJustPressed — the "enabled" variant doesn't
            -- see a press on a control that's been disabled this frame.
            if IsDisabledControlJustPressed(0, 200) then
                StopFreecam()

                -- Keep both pause-menu controls suppressed until Esc is
                -- physically released. FreecamActive is already false at this
                -- point, so on the very next tick this whole block is skipped
                -- and 199/200 stop being disabled — if the key is still held
                -- down at that moment, that same press falls through as a
                -- fresh, undisabled input and pops the pause menu (and its
                -- Map tab) open right as freecam closes. Holding the disable
                -- here until release closes that gap.
                while IsDisabledControlPressed(0, 200) do
                    DisableControlAction(0, 199, true)
                    DisableControlAction(0, 200, true)
                    Wait(0)
                end
            end
        end
    end
end)

-- ─── World-space markers for confirmed pending points ─────────────────────────
-- Shown any time there are pending points, not just during freecam, so an
-- admin can also see them while walking around after using "Capture My
-- Position" in the panel. The freecam preview marker (where the *next* point
-- will land) is handled separately, above, since it needs the same
-- forward-vector math as freecam movement.
CreateThread(function()
    while true do
        Wait(0)
        local count = #PendingPoints
        if count > 0 then
            for i, p in ipairs(PendingPoints) do
                DrawMarker(1, p.x, p.y, p.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 1.0, 0, 220, 130, 180, false, true, 2, false, nil, nil, false)
                DrawText3D(p.x, p.y, p.z + 0.3, ('#%d'):format(i))

                if i < count then
                    local nextP = PendingPoints[i + 1]
                    DrawLine(p.x, p.y, p.z, nextP.x, nextP.y, nextP.z, 0, 220, 130, 200)
                elseif count >= 3 then
                    local firstP = PendingPoints[1]
                    DrawLine(p.x, p.y, p.z, firstP.x, firstP.y, firstP.z, 0, 220, 130, 120)
                end
            end
        else
            Wait(250) -- nothing to draw; back off to save perf
        end
    end
end)