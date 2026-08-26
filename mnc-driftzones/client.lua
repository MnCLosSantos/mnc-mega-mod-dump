-- client.lua
local QBCore = exports['qb-core']:GetCoreObject()

local activeZones = {}   -- [zoneId] = { obj, blip, name, centroid, thickness, points }
local insideZoneIds = {} -- [zoneId] = zoneName, for zones the player is currently inside
local managementUIOpen = false
local zoneSetupActive = false -- true while freecam is being used to build/edit a zone's shape
local editingZoneId = nil     -- set when we're re-drawing an existing zone's shape
local pendingName = nil
local pendingPoints = {}
local pendingThickness = nil
local freecamActive = false
local freecamCam = nil
local freecamPos = vector3(0.0, 0.0, 0.0)
local freecamRot = vector3(0.0, 0.0, 0.0) -- pitch, roll (unused), yaw
local aimCoord = nil -- vector3 currently under the freecam crosshair, or nil

--------------------------------------------------------------------------------
-- Notifications (ox_lib)
--------------------------------------------------------------------------------

local function Notify(text, ntype, duration)
    lib.notify({
        description = text,
        type = ntype or 'inform',
        duration = duration,
    })
end


local function ToggleDriftScoreHud()
    ExecuteCommand('driftscore')
end


local function PlayZoneSound(sound)
    SendNUIMessage({ action = 'playSound', sound = sound })
end

local function CountInsideZones()
    local count = 0
    for _ in pairs(insideZoneIds) do count = count + 1 end
    return count
end

local function OnZoneEnter(zone)
    local wasEmpty = CountInsideZones() == 0
    insideZoneIds[zone.id] = zone.name

    SendNUIMessage({ action = 'showZonePopup', name = zone.name })
    PlayZoneSound('enter')

    if wasEmpty then
        ToggleDriftScoreHud()
    end
end

local function OnZoneExit(zone)
    insideZoneIds[zone.id] = nil
    PlayZoneSound('exit')

    if CountInsideZones() == 0 then
        SendNUIMessage({ action = 'hideZonePopup' })
        ToggleDriftScoreHud()
    else

        local _, otherName = next(insideZoneIds)
        SendNUIMessage({ action = 'showZonePopup', name = otherName })
    end
end


local function ComputeCentroid(points)
    local sumX, sumY, sumZ = 0.0, 0.0, 0.0
    for _, p in ipairs(points) do
        sumX = sumX + p.x
        sumY = sumY + p.y
        sumZ = sumZ + p.z
    end
    local n = #points
    return vector3(sumX / n, sumY / n, sumZ / n)
end

local function CreateZoneBlip(zone, centroid)
    if not Config.Blip or not Config.Blip.enabled then return nil end

    local blip = AddBlipForCoord(centroid.x, centroid.y, centroid.z)

    SetBlipSprite(blip, Config.Blip.sprite or 396)
    SetBlipColour(blip, Config.Blip.color or 3)
    SetBlipScale(blip, Config.Blip.scale or 0.9)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(zone.name)
    EndTextCommandSetBlipName(blip)

    return blip
end


local function RemoveZoneObject(zoneId)
    local entry = activeZones[zoneId]
    if entry then
        if entry.obj then entry.obj:remove() end
        if entry.blip then RemoveBlip(entry.blip) end
        activeZones[zoneId] = nil
    end
    insideZoneIds[zoneId] = nil
end

local function CreateZoneObject(zone)
    if activeZones[zone.id] then
        RemoveZoneObject(zone.id)
    end

    local points = {}
    for _, p in ipairs(zone.points) do
        points[#points + 1] = vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0)
    end

    if #points < Config.MinZonePoints then return end

    local centroid = ComputeCentroid(points)

    local obj = lib.zones.poly({
        points = points,
        thickness = zone.thickness or Config.DefaultThickness,
        debug = Config.ZoneCheckDebug,
        onEnter = function()
            OnZoneEnter(zone)
        end,
        onExit = function()
            OnZoneExit(zone)
        end,
    })

    activeZones[zone.id] = {
        obj = obj,
        blip = CreateZoneBlip(zone, centroid),
        name = zone.name,
        centroid = centroid,
        thickness = zone.thickness or Config.DefaultThickness,
        points = zone.points, -- raw {x,y,z} array as received from the server
    }
end

local function ClearAllZones()
    for zoneId in pairs(activeZones) do
        RemoveZoneObject(zoneId)
    end
    activeZones = {}
    insideZoneIds = {}
end

local function LoadAllZones()
    QBCore.Functions.TriggerCallback('mnc-driftzones:getZones', function(zones)
        ClearAllZones()
        for _, zone in ipairs(zones or {}) do
            CreateZoneObject(zone)
        end
    end)
end


local function BuildZonesPayload()
    local zones = {}
    for id, entry in pairs(activeZones) do
        zones[#zones + 1] = {
            id = id,
            name = entry.name,
            pointCount = entry.points and #entry.points or 0,
            thickness = entry.thickness,
        }
    end
    table.sort(zones, function(a, b) return a.id < b.id end)
    return zones
end

local function RefreshManagementUI()
    if not managementUIOpen then return end
    SendNUIMessage({ action = 'refreshManagement', zones = BuildZonesPayload() })
end

local function OpenManagementUI()
    managementUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showManagement',
        zones = BuildZonesPayload(),
        defaults = {
            thickness = Config.DefaultThickness,
            minPoints = Config.MinZonePoints,
        },
    })
end

local function CloseManagementUI()
    managementUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideManagement' })
end

RegisterNetEvent('mnc-driftzones:client:zoneAdded', function(zone)
    CreateZoneObject(zone)
    RefreshManagementUI()
end)

RegisterNetEvent('mnc-driftzones:client:zoneRemoved', function(zoneId)
    RemoveZoneObject(zoneId)
    RefreshManagementUI()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    LoadAllZones()
end)



local function Clamp(value, minVal, maxVal)
    return math.min(math.max(value, minVal), maxVal)
end

local function Round1(n)
    return math.floor(n * 10 + 0.5) / 10
end


local function EulerToMatrix(rotX, rotY, rotZ)
    local rx, ry, rz = math.rad(rotX), math.rad(rotY), math.rad(rotZ)
    local sx, sy, sz = math.sin(rx), math.sin(ry), math.sin(rz)
    local cx, cy, cz = math.cos(rx), math.cos(ry), math.cos(rz)

    local right = vector3(cy * cz, cy * sz, -sy)
    local forward = vector3(cz * sx * sy - cx * sz, cx * cz - sx * sy * sz, cy * sx)

    return right, forward
end

local function GetFreecamSpeedMultiplier()
    local fastInput = GetDisabledControlNormal(0, 21) -- Left Shift
    local slowInput = GetDisabledControlNormal(0, 19) -- Left Alt

    local fast = 1.0 + ((Config.Freecam.fastMultiplier - 1.0) * fastInput)
    local slow = 1.0 + ((Config.Freecam.slowMultiplier - 1.0) * slowInput)

    return Config.Freecam.baseSpeed * fast / slow * GetFrameTime() * 60.0
end


local function GetAimCoord(camPos, forward)
    local dist = Config.Freecam.raycastDistance
    local dest = camPos + forward * dist

    local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
    local _, hit, endCoords = GetShapeTestResult(rayHandle)

    if hit == 1 then
        return endCoords
    end

    return dest
end

local function DisableFreecamControlsThisFrame()
    DisableControlAction(0, 1, true)   -- INPUT_LOOK_LR
    DisableControlAction(0, 2, true)   -- INPUT_LOOK_UD
    DisableControlAction(0, 30, true)  -- INPUT_MOVE_LR
    DisableControlAction(0, 31, true)  -- INPUT_MOVE_UD
    DisableControlAction(0, 21, true)  -- INPUT_SPRINT (fast)
    DisableControlAction(0, 19, true)  -- INPUT_CHARACTER_WHEEL (slow/precision)
    DisableControlAction(0, 152, true) -- Q - up
    DisableControlAction(0, 153, true) -- E - down
    DisableControlAction(0, 24, true)  -- LMB - place point
    DisableControlAction(0, 25, true)  -- RMB
    DisableControlAction(0, 37, true)  -- Tab (weapon wheel)
    DisableControlAction(0, 194, true) -- Backspace - undo point
    DisableControlAction(0, 201, true) -- Enter - save zone
    DisableControlAction(0, 200, true) -- Esc - cancel
end

local function StartFreecamSetup()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    freecamPos = coords + vector3(0.0, 0.0, 3.0)
    freecamRot = vector3(-10.0, 0.0, heading)

    freecamCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(freecamCam, freecamPos.x, freecamPos.y, freecamPos.z)
    SetCamRot(freecamCam, freecamRot.x, freecamRot.y, freecamRot.z, 2)
    SetCamFov(freecamCam, Config.Freecam.fov)
    SetCamActive(freecamCam, true)
    RenderScriptCams(true, true, 400, true, true)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)

    freecamActive = true
    SendNUIMessage({ action = 'showCrosshair' })
end

local function StopFreecamSetup()
    if not freecamActive then return end

    local ped = PlayerPedId()

    RenderScriptCams(false, true, 400, true, true)
    if freecamCam then
        DestroyCam(freecamCam, false)
        freecamCam = nil
    end

    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)

    freecamActive = false
    aimCoord = nil
end

local function SendSetupPointsToNUI()
    local points = {}
    for i, p in ipairs(pendingPoints) do
        points[i] = { x = Round1(p.x), y = Round1(p.y), z = Round1(p.z) }
    end
    SendNUIMessage({ action = 'updateSetupPoints', points = points })
end

local function ResetFreecamState()
    zoneSetupActive = false
    editingZoneId = nil

    pendingName = nil
    pendingPoints = {}
    pendingThickness = nil

    SendNUIMessage({ action = 'hideSetupPanel' })
    SendNUIMessage({ action = 'hideCrosshair' })
end

local function AddSetupPoint()
    if not zoneSetupActive then return end

    if not aimCoord then
        Notify('No valid point to add yet', 'error')
        return
    end

    table.insert(pendingPoints, aimCoord)
    SendSetupPointsToNUI()
end

local function RemoveLastSetupPoint()
    if not zoneSetupActive or #pendingPoints == 0 then return end

    table.remove(pendingPoints)
    SendSetupPointsToNUI()
end

local function CancelFreecam()
    if not zoneSetupActive then return end

    StopFreecamSetup()
    ResetFreecamState()
    Notify('Zone setup cancelled', 'error')
    OpenManagementUI()
end

local function FinishFreecamZone()
    if not zoneSetupActive then return end

    if #pendingPoints < Config.MinZonePoints then
        Notify(('Add at least %d points before saving'):format(Config.MinZonePoints), 'error')
        return
    end

    local points = {}
    for _, p in ipairs(pendingPoints) do
        points[#points + 1] = { x = p.x, y = p.y, z = p.z }
    end

    if editingZoneId then
        TriggerServerEvent('mnc-driftzones:server:updateZonePoints', editingZoneId, points)
    else
        TriggerServerEvent('mnc-driftzones:server:saveZone', pendingName, points, pendingThickness)
    end

    StopFreecamSetup()
    ResetFreecamState()
    OpenManagementUI()
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if zoneSetupActive then
        StopFreecamSetup()
        ResetFreecamState()
    end
    if managementUIOpen then CloseManagementUI() end
    ClearAllZones()
    SendNUIMessage({ action = 'hideZonePopup' })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if zoneSetupActive then
        StopFreecamSetup()
    end
end)

CreateThread(function()
    SendNUIMessage({ action = 'setVolume', volume = Config.SoundVolume })
    Wait(2000)
    LoadAllZones()
end)


CreateThread(function()
    while true do
        local waitTime = 500

        if zoneSetupActive then
            waitTime = 0

            DisableFreecamControlsThisFrame()

            local speed = GetFreecamSpeedMultiplier()
            local lookX = GetDisabledControlNormal(0, 1)
            local lookY = GetDisabledControlNormal(0, 2)
            local moveLR = GetDisabledControlNormal(0, 30)
            local moveUD = GetDisabledControlNormal(0, 31)
            local moveUp = GetDisabledControlNormal(0, 152)
            local moveDown = GetDisabledControlNormal(0, 153)

            freecamRot = vector3(
                Clamp(freecamRot.x - lookY * Config.Freecam.lookSensitivityY, -89.0, 89.0),
                0.0,
                (freecamRot.z - lookX * Config.Freecam.lookSensitivityX) % 360.0
            )

            local right, forward = EulerToMatrix(freecamRot.x, freecamRot.y, freecamRot.z)

            freecamPos = freecamPos
                + right * moveLR * speed
                + forward * -moveUD * speed
                + vector3(0.0, 0.0, 1.0) * (moveUp - moveDown) * speed

            SetCamCoord(freecamCam, freecamPos.x, freecamPos.y, freecamPos.z)
            SetCamRot(freecamCam, freecamRot.x, freecamRot.y, freecamRot.z, 2)

            aimCoord = GetAimCoord(freecamPos, forward)

            if IsDisabledControlJustPressed(0, 24) then
                AddSetupPoint()
            elseif IsDisabledControlJustPressed(0, 194) then
                RemoveLastSetupPoint()
            elseif IsDisabledControlJustPressed(0, 201) then
                FinishFreecamZone()
            elseif IsDisabledControlJustPressed(0, 200) then
                CancelFreecam()
            end

            -- Only keep drawing if setup wasn't just ended by one of the keys above
            if zoneSetupActive then
                local c = Config.MarkerColor
                for i, p in ipairs(pendingPoints) do
                    DrawMarker(1, p.x, p.y, p.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 1.0,
                        c.r, c.g, c.b, c.a, false, true, 2, false, nil, nil, false)

                    if i < #pendingPoints then
                        local nextP = pendingPoints[i + 1]
                        DrawLine(p.x, p.y, p.z, nextP.x, nextP.y, nextP.z, c.r, c.g, c.b, 200)
                    end
                end

                if #pendingPoints >= 3 then
                    local first = pendingPoints[1]
                    local last = pendingPoints[#pendingPoints]
                    DrawLine(last.x, last.y, last.z, first.x, first.y, first.z, c.r, c.g, c.b, 120)
                end

                if aimCoord then
                    local ac = Config.AimMarkerColor
                    DrawMarker(1, aimCoord.x, aimCoord.y, aimCoord.z - 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.4, 0.4,
                        ac.r, ac.g, ac.b, ac.a, true, true, 2, false, nil, nil, false)
                end
            end
        end

        Wait(waitTime)
    end
end)


RegisterNUICallback('driftzones:close', function(_, cb)
    CloseManagementUI()
    cb('ok')
end)

RegisterNUICallback('driftzones:createZone', function(data, cb)
    CloseManagementUI()

    pendingName = data.name
    pendingThickness = tonumber(data.thickness) or Config.DefaultThickness
    pendingPoints = {}
    editingZoneId = nil
    zoneSetupActive = true

    StartFreecamSetup()
    SendNUIMessage({ action = 'showSetupPanel', name = pendingName, minPoints = Config.MinZonePoints, editing = false })
    SendSetupPointsToNUI()

    Notify(('Building "%s" - left-click to drop a corner, Backspace to undo, Enter to save, Esc to cancel.'):format(pendingName), 'success', 8000)
    cb('ok')
end)

RegisterNUICallback('driftzones:editZoneInfo', function(data, cb)
    TriggerServerEvent('mnc-driftzones:server:updateZoneMeta', data.zoneId, data.name, tonumber(data.thickness))
    cb('ok')
end)

RegisterNUICallback('driftzones:editZonePoints', function(data, cb)
    local zoneId = tonumber(data.zoneId)
    local entry = zoneId and activeZones[zoneId]

    if not entry then
        Notify('Zone not found', 'error')
        cb('error')
        return
    end

    CloseManagementUI()

    editingZoneId = zoneId
    pendingName = entry.name
    pendingPoints = {}
    for _, p in ipairs(entry.points or {}) do
        pendingPoints[#pendingPoints + 1] = vector3(p.x, p.y, p.z)
    end
    zoneSetupActive = true

    StartFreecamSetup()
    SendNUIMessage({ action = 'showSetupPanel', name = entry.name, minPoints = Config.MinZonePoints, editing = true })
    SendSetupPointsToNUI()

    Notify(('Editing "%s" shape - Backspace/left-click to adjust points, Enter to save, Esc to cancel.'):format(entry.name), 'success', 8000)
    cb('ok')
end)

RegisterNUICallback('driftzones:deleteZone', function(data, cb)
    TriggerServerEvent('mnc-driftzones:server:deleteZone', data.zoneId)
    cb('ok')
end)


RegisterNetEvent('mnc-driftzones:client:openMenu', function()
    if zoneSetupActive then
        Notify('Finish or cancel what you are placing first (Esc)', 'error')
        return
    end

    OpenManagementUI()
end)

RegisterCommand('driftzones', function()
    TriggerServerEvent('mnc-driftzones:server:checkAdmin')
end, false)