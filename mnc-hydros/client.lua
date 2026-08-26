-- client.lua
local QBCore         = nil
local hydroCache     = {}    -- [plate] = { hydro, type, tier } | false
local currentVehicle = nil
local hydroStartTime = nil   -- GetGameTimer() when hydro was activated

-- ===========================
-- QBCore init
-- ===========================
CreateThread(function()
    while not QBCore do
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbcore') == 'started' then
            local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and obj then
                QBCore = obj
                print('^2[mnc-hydros]^7 QBCore loaded.')
            end
        end
        Wait(500)
    end
end)

-- Pre-load anim dict
local ANIM_DICT = 'amb@world_human_vehicle_mechanic@male@base'
local ANIM_CLIP = 'base'

CreateThread(function()
    while GetResourceState('ox_lib') ~= 'started' do Wait(500) end
    RequestAnimDict(ANIM_DICT)
    while not HasAnimDictLoaded(ANIM_DICT) do Wait(0) end
    print('^2[mnc-hydros]^7 Anim dict loaded.')
end)

-- ===========================
-- Notify event
-- ===========================
RegisterNetEvent('mnc-hydros:notify', function(data)
    lib.notify({
        title       = data.title or 'Hydraulics',
        description = data.description,
        type        = data.type or 'inform',
        duration    = data.duration or 5000,
    })
end)

-- ===========================
-- Handling helpers
-- ===========================

local originalHandbrake = {}  -- [vehicle] = fHandBrakeForce (stock)

local function CacheOriginalHandling(vehicle)
    if originalHandbrake[vehicle] then return end
    originalHandbrake[vehicle] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fHandBrakeForce')
    if Config.Debug then
        print(string.format('^2[mnc-hydros]^7 Cached fHandBrakeForce=%.3f veh=%d',
            originalHandbrake[vehicle], vehicle))
    end
end

local function ApplyHydro(vehicle, force)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fHandBrakeForce', force)
    if Config.Debug then
        print(string.format('^2[mnc-hydros]^7 Applied fHandBrakeForce=%.3f veh=%d', force, vehicle))
    end
end

local function RestoreHandling(vehicle)
    if not vehicle or vehicle == 0 then return end
    local orig = originalHandbrake[vehicle]
    if orig then
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fHandBrakeForce', orig)
        originalHandbrake[vehicle] = nil
    end
    if Config.Debug then
        print('^3[mnc-hydros]^7 Restored stock fHandBrakeForce for vehicle ' .. vehicle)
    end
end

-- ===========================
-- Main thread — vehicle enter/exit + hydro load + duration timer
-- ===========================
CreateThread(function()
    while true do
        if not QBCore then
            Wait(500)
        else
            local ped     = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)

            -- Not in a vehicle as driver
            if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
                if currentVehicle then
                    RestoreHandling(currentVehicle)
                    currentVehicle = nil
                    hydroStartTime = nil
                end
                Wait(600)
            elseif DoesEntityExist(vehicle) then
                local plateRaw = GetVehicleNumberPlateText(vehicle)
                local plate    = plateRaw and string.upper(plateRaw:gsub('%s+', ''))

                if plate then
                    -- Entered a new vehicle
                    if vehicle ~= currentVehicle then
                        if currentVehicle then RestoreHandling(currentVehicle) end
                        currentVehicle    = vehicle
                        hydroStartTime    = nil
                        hydroCache[plate] = nil

                        if Config.Debug then
                            print('^2[mnc-hydros]^7 Entered vehicle plate=' .. plate)
                        end
                    end

                    -- Fetch hydro data if not yet cached
                    if hydroCache[plate] == nil then
                        hydroCache[plate] = false
                        QBCore.Functions.TriggerCallback('mnc-hydros:getHydroData', function(data)
                            if data and data.type then
                                hydroCache[plate] = data
                                hydroStartTime    = GetGameTimer()
                                CacheOriginalHandling(vehicle)
                                local hydroCfg = Config.Hydros[data.hydro]
                                if hydroCfg then
                                    ApplyHydro(vehicle, hydroCfg.HandbrakeForce)
                                end
                                if Config.Debug then
                                    print('^2[mnc-hydros]^7 Loaded hydro=' .. data.hydro .. ' type=' .. data.type .. ' plate=' .. plate)
                                end
                            else
                                hydroCache[plate] = false
                            end
                        end, plate)
                    end

                    -- Duration / wear-out check
                    local cached = hydroCache[plate]
                    if cached and cached.type and hydroStartTime then
                        local elapsed = GetGameTimer() - hydroStartTime
                        if elapsed >= Config.HydroDurationMs then
                            TriggerServerEvent('mnc-hydros:removeHydro', plate)
                            RestoreHandling(vehicle)
                            hydroCache[plate] = false
                            hydroStartTime    = nil
                            if Config.Debug then
                                print('^3[mnc-hydros]^7 Hydro worn out plate=' .. plate)
                            end
                        end
                    end
                end

                Wait(500)
            else
                Wait(500)
            end
        end
    end
end)

-- ===========================
-- Sync hydro data from server
-- ===========================
RegisterNetEvent('mnc-hydros:syncHydroData', function(plate, data)
    hydroCache[plate] = data

    if currentVehicle then
        local curPlate = string.upper(GetVehicleNumberPlateText(currentVehicle):gsub('%s+', ''))
        if curPlate == plate then
            if data and data.type then
                hydroStartTime = GetGameTimer()
                RestoreHandling(currentVehicle)
                CacheOriginalHandling(currentVehicle)
                local hydroCfg = Config.Hydros[data.hydro]
                if hydroCfg then
                    ApplyHydro(currentVehicle, hydroCfg.HandbrakeForce)
                end
            else
                RestoreHandling(currentVehicle)
                hydroStartTime = nil
            end
        end
    end
end)

-- ===========================
-- Helper: get nearest vehicle within Config.ApplyDistance
-- ===========================
local function GetNearbyVehicle()
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 then return nil end
    local pedPos      = GetEntityCoords(ped)
    local best, bestD = nil, Config.ApplyDistance
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local d = #(pedPos - GetEntityCoords(veh))
        if d < bestD then best = veh; bestD = d end
    end
    return best
end

-- ===========================
-- Job check (client-side early out — server re-validates authoritatively)
-- ===========================
local function HasAllowedJob()
    if not Config.RequireJob then return true end
    if not QBCore then return false end
    local job = QBCore.Functions.GetPlayerData().job
    if not job then return false end
    local minGrade = Config.AllowedJobs[job.name]
    if minGrade == nil then return false end
    return (job.grade.level or 0) >= minGrade
end

-- ===========================
-- Wheel helpers (shared with the per-wheel stages)
-- ===========================
local REAR_WHEELS = {
    { bone = 'wheel_lr', label = 'Rear Left Wheel'  },
    { bone = 'wheel_rr', label = 'Rear Right Wheel' },
}

local function GetWheelWorldPos(vehicle, boneName)
    local boneIdx = GetEntityBoneIndexByName(vehicle, boneName)
    if boneIdx ~= -1 then return GetWorldPositionOfEntityBone(vehicle, boneIdx) end
    return GetEntityCoords(vehicle)
end

-- Wait for [E] near a marker, returns true when pressed, false if aborted flag set
local function WaitForEAtMarker(posGetter, promptText, abortFlag, r, g, b)
    local PROMPT_RADIUS = 1.2
    local pressed = false

    CreateThread(function()
        while not pressed and not abortFlag[1] do
            local pos  = posGetter()
            DrawMarker(1, pos.x, pos.y, pos.z + 0.05,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.35, 0.35, 0.2, r, g, b, 180,
                false, true, 2, false, nil, nil, false)

            local dist = #(GetEntityCoords(PlayerPedId()) - vector3(pos.x, pos.y, pos.z))
            if dist <= PROMPT_RADIUS then
                SetTextComponentFormat('STRING')
                AddTextComponentString(promptText)
                DisplayHelpTextFromStringLabel(0, false, true, -1)
                if IsControlJustPressed(0, 51) then pressed = true end
            end
            Wait(0)
        end
    end)

    while not pressed and not abortFlag[1] do Wait(100) end
    return pressed
end

-- Progress bar at a wheel (faces player toward correct side)
local function DoWheelProgress(vehicle, boneName, label, duration)
    local vehHeading = GetEntityHeading(vehicle)
    local isLeft     = boneName == 'wheel_lr'
    SetEntityHeading(PlayerPedId(), (vehHeading + (isLeft and 90.0 or -90.0)) % 360.0)
    return lib.progressBar({
        duration     = duration,
        label        = label,
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = ANIM_DICT, clip = ANIM_CLIP, flag = 1 },
    })
end

-- ===========================
-- Apply Hydro — triggered by useable item (server → client)
--
-- INSTALL STAGES:
--   1. Get in the driver seat  → interior progress bar (routing the hydraulic line)
--   2. Exit & walk to rear-left wheel  → press [E] → progress bar (connect line)
--   3. Walk to rear-right wheel        → press [E] → progress bar (connect line)
-- ===========================
RegisterNetEvent('mnc-hydros:applyHydro', function(hydroName)
    local hydroCfg = Config.Hydros[hydroName]
    if not hydroCfg then return end

    if not HasAllowedJob() then
        lib.notify({ title = hydroCfg.label, description = 'You must be a mechanic to install this hydraulic.', type = 'error' })
        return
    end

    local target = GetNearbyVehicle()
    if not target then
        lib.notify({ title = hydroCfg.label, description = 'You must be within ' .. Config.ApplyDistance .. 'm of a vehicle.', type = 'error' })
        return
    end

    local plate  = string.upper(GetVehicleNumberPlateText(target):gsub('%s+', ''))
    local cached = hydroCache[plate]

    if cached and cached.tier and cached.tier >= Config.HydroTier[hydroName] then
        lib.notify({ title = hydroCfg.label, description = 'This vehicle already has an equal or higher hydraulic installed.', type = 'error' })
        return
    end

    -- Split install time: 50% interior, 25% per rear wheel
    local interiorTime  = math.floor(hydroCfg.installTime * 0.50)
    local perWheelTime  = math.floor(hydroCfg.installTime * 0.25)

    -- ── STAGE 1: Driver seat ─────────────────────────────────────────────────
    lib.notify({
        title       = hydroCfg.label,
        description = 'Get in the driver seat to start routing the hydraulic line.',
        type        = 'inform',
        duration    = 5000,
    })

    -- Wait until player sits in the driver seat of the target vehicle
    local seated = false
    local seatTimeout = GetGameTimer() + 30000  -- 30s to get in

    while not seated do
        local ped = PlayerPedId()
        if GetVehiclePedIsIn(ped, false) == target and GetPedInVehicleSeat(target, -1) == ped then
            seated = true
        end
        if GetGameTimer() > seatTimeout then
            lib.notify({ title = hydroCfg.label, description = 'Installation cancelled — you didn\'t get in the vehicle in time.', type = 'error' })
            return
        end
        Wait(200)
    end

    -- Interior progress bar (player stays seated)
    local okInterior = lib.progressBar({
        duration     = interiorTime,
        label        = 'Routing hydraulic line — ' .. hydroCfg.label .. ' (1/3)',
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = ANIM_DICT, clip = ANIM_CLIP, flag = 49 },
    })

    if not okInterior then
        lib.notify({ title = hydroCfg.label, description = 'Installation cancelled.', type = 'inform' })
        return
    end

    -- Eject player from vehicle so they can walk to the wheels
    TaskLeaveVehicle(PlayerPedId(), target, 0)
    Wait(1200)

    lib.notify({
        title       = hydroCfg.label,
        description = 'Now walk to each rear wheel to connect the hydraulic line.',
        type        = 'inform',
        duration    = 5000,
    })

    -- ── STAGES 2 & 3: Rear wheels ────────────────────────────────────────────
    local abortFlag = { false }

    for i, wheel in ipairs(REAR_WHEELS) do
        local stageNum = i + 1  -- stage 2 and 3

        local pressed = WaitForEAtMarker(
            function() return GetWheelWorldPos(target, wheel.bone) end,
            ('Press ~INPUT_CONTEXT~ to connect line — %s (%d/3)'):format(wheel.label, stageNum),
            abortFlag,
            255, 165, 0
        )

        if not pressed then
            lib.notify({ title = hydroCfg.label, description = 'Installation cancelled.', type = 'inform' })
            ClearPedTasks(PlayerPedId())
            return
        end

        local ok = DoWheelProgress(
            target,
            wheel.bone,
            ('Connecting line — %s (%d/3)'):format(wheel.label, stageNum),
            perWheelTime
        )

        if not ok then
            lib.notify({ title = hydroCfg.label, description = 'Installation cancelled.', type = 'inform' })
            ClearPedTasks(PlayerPedId())
            return
        end

        if i < #REAR_WHEELS then
            lib.notify({
                title       = hydroCfg.label,
                description = ('Done! Now move to the %s (%d/3).'):format(REAR_WHEELS[i + 1].label, stageNum + 1),
                type        = 'success',
                duration    = 4000,
            })
        end
    end

    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('mnc-hydros:applyHydro', plate, hydroName)
end)

-- ===========================
-- Remove Hydro — triggered by hydro_toolbox item (server → client)
--
-- REMOVAL STAGES (mirrors install in reverse):
--   1. Get in the driver seat  → interior progress bar (disconnect master line)
--   2. Exit & walk to rear-left wheel  → press [E] → progress bar (disconnect line)
--   3. Walk to rear-right wheel        → press [E] → progress bar (disconnect line)
-- ===========================
RegisterNetEvent('mnc-hydros:startRemoval', function()
    if not HasAllowedJob() then
        lib.notify({ title = 'Hydraulics Removal', description = 'You must be a mechanic to remove hydraulics.', type = 'error' })
        return
    end

    local target = GetNearbyVehicle()
    if not target then
        lib.notify({ title = 'Hydraulics Removal', description = 'You must be within ' .. Config.ApplyDistance .. 'm of a vehicle.', type = 'error' })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(target):gsub('%s+', ''))

    -- Check client cache first, then ask server
    local cached = hydroCache[plate]
    if cached == nil then
        local done = false
        QBCore.Functions.TriggerCallback('mnc-hydros:getHydroData', function(data)
            hydroCache[plate] = data or false
            cached = hydroCache[plate]
            done = true
        end, plate)
        local waited = 0
        while not done and waited < 2000 do Wait(100); waited = waited + 100 end
    end

    if not cached or not cached.hydro then
        lib.notify({ title = 'Hydraulics Removal', description = 'This vehicle has no hydraulics installed.', type = 'error' })
        return
    end

    local hydroCfg = Config.Hydros[cached.hydro]
    if not hydroCfg then
        lib.notify({ title = 'Hydraulics Removal', description = 'Unknown hydraulic type on this vehicle.', type = 'error' })
        return
    end

    -- Use same time splits as install
    local interiorTime = math.floor(hydroCfg.installTime * 0.50)
    local perWheelTime = math.floor(hydroCfg.installTime * 0.25)

    -- ── STAGE 1: Driver seat ─────────────────────────────────────────────────
    lib.notify({
        title       = 'Hydraulics Removal',
        description = 'Get in the driver seat to begin disconnecting the master line.',
        type        = 'inform',
        duration    = 5000,
    })

    local seated = false
    local seatTimeout = GetGameTimer() + 30000

    while not seated do
        local ped = PlayerPedId()
        if GetVehiclePedIsIn(ped, false) == target and GetPedInVehicleSeat(target, -1) == ped then
            seated = true
        end
        if GetGameTimer() > seatTimeout then
            lib.notify({ title = 'Hydraulics Removal', description = 'Removal cancelled — you didn\'t get in the vehicle in time.', type = 'error' })
            return
        end
        Wait(200)
    end

    local okInterior = lib.progressBar({
        duration     = interiorTime,
        label        = 'Disconnecting master line — ' .. hydroCfg.label .. ' (1/3)',
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = ANIM_DICT, clip = ANIM_CLIP, flag = 49 },
    })

    if not okInterior then
        lib.notify({ title = 'Hydraulics Removal', description = 'Removal cancelled.', type = 'inform' })
        return
    end

    TaskLeaveVehicle(PlayerPedId(), target, 0)
    Wait(1200)

    lib.notify({
        title       = 'Hydraulics Removal',
        description = 'Now walk to each rear wheel to disconnect the hydraulic lines.',
        type        = 'inform',
        duration    = 5000,
    })

    -- ── STAGES 2 & 3: Rear wheels ────────────────────────────────────────────
    local abortFlag = { false }

    for i, wheel in ipairs(REAR_WHEELS) do
        local stageNum = i + 1

        local pressed = WaitForEAtMarker(
            function() return GetWheelWorldPos(target, wheel.bone) end,
            ('Press ~INPUT_CONTEXT~ to disconnect line — %s (%d/3)'):format(wheel.label, stageNum),
            abortFlag,
            220, 50, 50   -- red markers to distinguish from install
        )

        if not pressed then
            lib.notify({ title = 'Hydraulics Removal', description = 'Removal cancelled.', type = 'inform' })
            ClearPedTasks(PlayerPedId())
            return
        end

        local ok = DoWheelProgress(
            target,
            wheel.bone,
            ('Disconnecting line — %s (%d/3)'):format(wheel.label, stageNum),
            perWheelTime
        )

        if not ok then
            lib.notify({ title = 'Hydraulics Removal', description = 'Removal cancelled.', type = 'inform' })
            ClearPedTasks(PlayerPedId())
            return
        end

        if i < #REAR_WHEELS then
            lib.notify({
                title       = 'Hydraulics Removal',
                description = ('Done! Now move to the %s (%d/3).'):format(REAR_WHEELS[i + 1].label, stageNum + 1),
                type        = 'success',
                duration    = 4000,
            })
        end
    end

    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('mnc-hydros:removeHydroManual', plate)
end)


if Config.Debug then
    print('^2[mnc-hydros]^7 Client loaded.')
end