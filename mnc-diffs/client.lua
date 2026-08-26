-- client.lua
local QBCore         = nil
local diffCache      = {}    -- [plate] = { diff, type, tier } | false
local currentVehicle = nil
local diffStartTime  = nil   -- GetGameTimer() when diff was activated

-- LSD engagement state
local lsdActive = {}  -- [vehicle] = bool

-- ===========================
-- QBCore init
-- ===========================
CreateThread(function()
    while not QBCore do
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbcore') == 'started' then
            local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and obj then
                QBCore = obj
                print('^2[mnc-diffs]^7 QBCore loaded.')
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
    print('^2[mnc-diffs]^7 Anim dict loaded.')
end)

-- ===========================
-- Notify event
-- ===========================
RegisterNetEvent('mnc-diffs:notify', function(data)
    lib.notify({
        title       = data.title or 'Differential',
        description = data.description,
        type        = data.type or 'inform',
        duration    = data.duration or 5000,
    })
end)

-- ===========================
-- Handling helpers
-- ===========================

local originalHandling = {}  -- [vehicle] = { fTractionCurveMin, fTractionLossMult }

local function CacheOriginalHandling(vehicle)
    if originalHandling[vehicle] then return end
    originalHandling[vehicle] = {
        fTractionCurveMin = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin'),
        fTractionLossMult = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionLossMult'),
    }
    if Config.Debug then
        print(string.format('^2[mnc-diffs]^7 Cached handling veh=%d curveMin=%.3f lossMult=%.3f',
            vehicle,
            originalHandling[vehicle].fTractionCurveMin,
            originalHandling[vehicle].fTractionLossMult))
    end
end

-- Apply computed traction values to the vehicle
local function ApplyHandling(vehicle, curveMin, lossMult)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin', curveMin)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionLossMult', lossMult)
end

-- Restore vehicle to stock handling and clear cache
local function RestoreHandling(vehicle)
    if not vehicle or vehicle == 0 then return end
    local orig = originalHandling[vehicle]
    if orig then
        ApplyHandling(vehicle, orig.fTractionCurveMin, orig.fTractionLossMult)
        originalHandling[vehicle] = nil
    end
    lsdActive[vehicle] = nil
    if Config.Debug then
        print('^3[mnc-diffs]^7 Restored stock handling for vehicle ' .. vehicle)
    end
end

-- Restore to stock WITHOUT clearing the cache (used by LSD unlock)
local function RestoreHandlingKeepCache(vehicle)
    if not vehicle or vehicle == 0 then return end
    local orig = originalHandling[vehicle]
    if orig then
        ApplyHandling(vehicle, orig.fTractionCurveMin, orig.fTractionLossMult)
    end
end

local function ComputeHandling(orig, diffCfg, rpm)
    if rpm <= diffCfg.SpinRpm then
        return orig.fTractionCurveMin, orig.fTractionLossMult
    end
    -- t = 0 at SpinRpm, t = 1 at full RPM
    local t = math.min((rpm - diffCfg.SpinRpm) / (1.0 - diffCfg.SpinRpm), 1.0)
    local curveMin = orig.fTractionCurveMin  + t * (diffCfg.TractionMin    - orig.fTractionCurveMin)
    local lossMult = orig.fTractionLossMult  + t * (diffCfg.SpinLossMult   - orig.fTractionLossMult)
    return curveMin, lossMult
end

-- ===========================
-- Main thread — vehicle enter/exit + diff load + duration timer
-- ===========================
CreateThread(function()
    while true do
        if not QBCore then
            Wait(500)
            goto continue
        end

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        -- Not in a vehicle as driver
        if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
            if currentVehicle then
                RestoreHandling(currentVehicle)
                currentVehicle = nil
                diffStartTime  = nil
            end
            Wait(600)
            goto continue
        end

        if not DoesEntityExist(vehicle) then goto continue end
        local plateRaw2 = GetVehicleNumberPlateText(vehicle)
        if not plateRaw2 then goto continue end
        local plate = string.upper(plateRaw2:gsub('%s+', ''))

        -- Entered a new vehicle
        if vehicle ~= currentVehicle then
            if currentVehicle then RestoreHandling(currentVehicle) end
            currentVehicle   = vehicle
            diffStartTime    = nil
            diffCache[plate] = nil

            if Config.Debug then
                print('^2[mnc-diffs]^7 Entered vehicle plate=' .. plate)
            end
        end

        -- Fetch diff data if not yet cached
        if diffCache[plate] == nil then
            diffCache[plate] = false
            QBCore.Functions.TriggerCallback('mnc-diffs:getDiffData', function(data)
                if data and data.type then
                    diffCache[plate] = data
                    diffStartTime    = GetGameTimer()
                    CacheOriginalHandling(vehicle)
                    if Config.Debug then
                        print('^2[mnc-diffs]^7 Loaded diff=' .. data.diff .. ' type=' .. data.type .. ' plate=' .. plate)
                    end
                else
                    diffCache[plate] = false
                end
            end, plate)
        end

        -- Duration / wear-out check
        local cached = diffCache[plate]
        if cached and cached.type and diffStartTime then
            local elapsed = GetGameTimer() - diffStartTime
            if elapsed >= Config.DiffDurationMs then
                TriggerServerEvent('mnc-diffs:removeDiff', plate)
                RestoreHandling(vehicle)
                diffCache[plate] = false
                diffStartTime    = nil
                lib.notify({
                    title       = 'Differential',
                    description = 'Your differential has worn out after extended use.',
                    type        = 'error',
                    duration    = 6000,
                })
            end
        end

        Wait(1000)
        ::continue::
    end
end)

-- ===========================
-- Diff physics thread — 50ms tick
-- ===========================
CreateThread(function()
    while true do
        Wait(50)

        if not currentVehicle or currentVehicle == 0 then goto diff_continue end
        if not DoesEntityExist(currentVehicle) then
            currentVehicle = nil
            goto diff_continue
        end

        local plateRaw = GetVehicleNumberPlateText(currentVehicle)
        if not plateRaw then goto diff_continue end

        local orig = originalHandling[currentVehicle]
        if not orig then goto diff_continue end

        local plate   = string.upper(plateRaw:gsub('%s+', ''))
        local cached  = diffCache[plate]
        if not cached or not cached.type then goto diff_continue end

        local diffCfg = Config.Diffs[cached.diff]
        if not diffCfg then goto diff_continue end

        local rpm  = GetVehicleCurrentRpm(currentVehicle)
        local gear = GetVehicleCurrentGear(currentVehicle)

        -- ── Gear cutoff ────────────────────────────────────────────────────
        local cutoff = diffCfg.GearSpinCutoff or 0
        if cutoff > 0 and gear >= cutoff then
            RestoreHandlingKeepCache(currentVehicle)
            lsdActive[currentVehicle] = false
            goto diff_continue
        end

        -- ── Welded — always active, scales with RPM ────────────────────────
        if cached.type == 'welded' then
            local curveMin, lossMult = ComputeHandling(orig, diffCfg, rpm)
            ApplyHandling(currentVehicle, curveMin, lossMult)

            if Config.Debug then
                print(string.format('^2[mnc-diffs]^7 WELDED rpm=%.2f gear=%d curveMin=%.3f lossMult=%.2f',
                    rpm, gear, curveMin, lossMult))
            end

        -- ── LSD — locks above LsdLockRpm, releases below LsdUnlockRpm ──────
        elseif cached.type == 'lsd' then
            local engaged = lsdActive[currentVehicle] or false

            if not engaged then
                if rpm >= diffCfg.LsdLockRpm then
                    lsdActive[currentVehicle] = true
                    engaged = true
                    if Config.Debug then
                        print(string.format('^2[mnc-diffs]^7 LSD LOCKED rpm=%.2f gear=%d', rpm, gear))
                    end
                end
            else
                if rpm < diffCfg.LsdUnlockRpm then
                    lsdActive[currentVehicle] = false
                    RestoreHandlingKeepCache(currentVehicle)
                    if Config.Debug then
                        print(string.format('^3[mnc-diffs]^7 LSD UNLOCKED rpm=%.2f gear=%d', rpm, gear))
                    end
                    goto diff_continue
                end
            end

            if engaged then
                local curveMin, lossMult = ComputeHandling(orig, diffCfg, rpm)
                ApplyHandling(currentVehicle, curveMin, lossMult)

                if Config.Debug then
                    print(string.format('^2[mnc-diffs]^7 LSD ACTIVE rpm=%.2f gear=%d curveMin=%.3f lossMult=%.2f',
                        rpm, gear, curveMin, lossMult))
                end
            end
        end

        ::diff_continue::
    end
end)

-- ===========================
-- Sync diff data from server
-- ===========================
RegisterNetEvent('mnc-diffs:syncDiffData', function(plate, data)
    diffCache[plate] = data

    if currentVehicle then
        local curPlate = string.upper(GetVehicleNumberPlateText(currentVehicle):gsub('%s+', ''))
        if curPlate == plate then
            if data and data.type then
                diffStartTime = GetGameTimer()
                lsdActive[currentVehicle] = false
                RestoreHandling(currentVehicle)
                CacheOriginalHandling(currentVehicle)
            else
                RestoreHandling(currentVehicle)
                diffStartTime = nil
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
-- Wheel definitions for install animation (rear axle only)
-- ===========================
local WHEELS = {
    { bone = 'wheel_lr', label = 'Rear Left Wheel'  },
    { bone = 'wheel_rr', label = 'Rear Right Wheel' },
}

local function GetWheelWorldPos(vehicle, boneName)
    local boneIdx = GetEntityBoneIndexByName(vehicle, boneName)
    if boneIdx ~= -1 then return GetWorldPositionOfEntityBone(vehicle, boneIdx) end
    return GetEntityCoords(vehicle)
end

local function DoWheelInstall(vehicle, boneName, label, duration)
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
-- Apply Diff — triggered by useable item (server → client)
-- ===========================
RegisterNetEvent('mnc-diffs:applyDiff', function(diffName)
    local diffCfg = Config.Diffs[diffName]
    if not diffCfg then return end

    if not HasAllowedJob() then
        lib.notify({ title = diffCfg.label, description = 'You must be a mechanic to install this differential.', type = 'error' })
        return
    end

    local target = GetNearbyVehicle()
    if not target then
        lib.notify({ title = diffCfg.label, description = 'You must be within ' .. Config.ApplyDistance .. 'm of a vehicle.', type = 'error' })
        return
    end

    local plate  = string.upper(GetVehicleNumberPlateText(target):gsub('%s+', ''))
    local cached = diffCache[plate]

    if cached and cached.tier and cached.tier >= Config.DiffTier[diffName] then
        lib.notify({ title = diffCfg.label, description = 'This vehicle already has an equal or higher differential installed.', type = 'error' })
        return
    end

    lib.notify({
        title       = diffCfg.label,
        description = 'Walk to each rear wheel and press [E] to install. Starting with: ' .. WHEELS[1].label,
        type        = 'inform',
        duration    = 5000,
    })

    local timePerWheel = math.floor(diffCfg.installTime / #WHEELS)

    for i, wheel in ipairs(WHEELS) do
        local PROMPT_RADIUS = 1.2
        local ePressed      = false
        local aborted       = false

        CreateThread(function()
            while not ePressed and not aborted do
                local wheelPos = GetWheelWorldPos(target, wheel.bone)
                local dist     = #(GetEntityCoords(PlayerPedId()) - vector3(wheelPos.x, wheelPos.y, wheelPos.z))

                DrawMarker(1, wheelPos.x, wheelPos.y, wheelPos.z + 0.05,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.3, 0.3, 0.2, 30, 144, 255, 180,
                    false, true, 2, false, nil, nil, false)

                if dist <= PROMPT_RADIUS then
                    SetTextComponentFormat('STRING')
                    AddTextComponentString('Press ~INPUT_CONTEXT~ to work on ' .. wheel.label)
                    DisplayHelpTextFromStringLabel(0, false, true, -1)
                    if IsControlJustPressed(0, 51) then ePressed = true end
                end
                Wait(0)
            end
        end)

        while not ePressed and not aborted do Wait(100) end

        if aborted then
            lib.notify({ title = diffCfg.label, description = 'Installation cancelled.', type = 'inform' })
            return
        end

        local ok = DoWheelInstall(target, wheel.bone,
            ('Installing %s — %s (%d/%d)'):format(diffCfg.label, wheel.label, i, #WHEELS),
            timePerWheel)

        if not ok then
            lib.notify({ title = diffCfg.label, description = 'Installation cancelled.', type = 'inform' })
            ClearPedTasks(PlayerPedId())
            return
        end

        if i < #WHEELS then
            lib.notify({
                title       = diffCfg.label,
                description = ('Wheel done! Move to the next one: %s (%d/%d)'):format(WHEELS[i + 1].label, i + 1, #WHEELS),
                type        = 'success',
                duration    = 4000,
            })
        end
    end

    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('mnc-diffs:applyDiff', plate, diffName)
end)

-- ================================================
-- REMOVAL STAGES (mirrors install exactly):
-- ================================================
RegisterNetEvent('mnc-diffs:startRemoval', function()
    if not HasAllowedJob() then
        lib.notify({ title = 'Differential Removal', description = 'You must be a mechanic to remove a differential.', type = 'error' })
        return
    end

    local target = GetNearbyVehicle()
    if not target then
        lib.notify({ title = 'Differential Removal', description = 'You must be within ' .. Config.ApplyDistance .. 'm of a vehicle.', type = 'error' })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(target):gsub('%s+', ''))

    -- Check cache, fetch from server if not yet known
    local cached = diffCache[plate]
    if cached == nil then
        local done = false
        QBCore.Functions.TriggerCallback('mnc-diffs:getDiffData', function(data)
            diffCache[plate] = data or false
            cached = diffCache[plate]
            done   = true
        end, plate)
        local waited = 0
        while not done and waited < 2000 do Wait(100); waited = waited + 100 end
    end

    if not cached or not cached.diff then
        lib.notify({ title = 'Differential Removal', description = 'This vehicle has no differential installed.', type = 'error' })
        return
    end

    local diffCfg = Config.Diffs[cached.diff]
    if not diffCfg then
        lib.notify({ title = 'Differential Removal', description = 'Unknown differential type on this vehicle.', type = 'error' })
        return
    end

    lib.notify({
        title       = 'Differential Removal',
        description = 'Walk to each rear wheel and press [E] to remove. Starting with: ' .. WHEELS[1].label,
        type        = 'inform',
        duration    = 5000,
    })

    local timePerWheel = math.floor(diffCfg.installTime / #WHEELS)

    for i, wheel in ipairs(WHEELS) do
        local PROMPT_RADIUS = 1.2
        local ePressed      = false
        local aborted       = false

        CreateThread(function()
            while not ePressed and not aborted do
                local wheelPos = GetWheelWorldPos(target, wheel.bone)
                local dist     = #(GetEntityCoords(PlayerPedId()) - vector3(wheelPos.x, wheelPos.y, wheelPos.z))

                -- Red markers to visually distinguish removal from install (blue)
                DrawMarker(1, wheelPos.x, wheelPos.y, wheelPos.z + 0.05,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.3, 0.3, 0.2, 220, 50, 50, 180,
                    false, true, 2, false, nil, nil, false)

                if dist <= PROMPT_RADIUS then
                    SetTextComponentFormat('STRING')
                    AddTextComponentString('Press ~INPUT_CONTEXT~ to remove from ' .. wheel.label)
                    DisplayHelpTextFromStringLabel(0, false, true, -1)
                    if IsControlJustPressed(0, 51) then ePressed = true end
                end
                Wait(0)
            end
        end)

        while not ePressed and not aborted do Wait(100) end

        if aborted then
            lib.notify({ title = 'Differential Removal', description = 'Removal cancelled.', type = 'inform' })
            return
        end

        local ok = DoWheelInstall(target, wheel.bone,
            ('Removing %s — %s (%d/%d)'):format(diffCfg.label, wheel.label, i, #WHEELS),
            timePerWheel)

        if not ok then
            lib.notify({ title = 'Differential Removal', description = 'Removal cancelled.', type = 'inform' })
            ClearPedTasks(PlayerPedId())
            return
        end

        if i < #WHEELS then
            lib.notify({
                title       = 'Differential Removal',
                description = ('Done! Move to the next wheel: %s (%d/%d)'):format(WHEELS[i + 1].label, i + 1, #WHEELS),
                type        = 'success',
                duration    = 4000,
            })
        end
    end

    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('mnc-diffs:removeDiffManual', plate)
end)

if Config.Debug then
    print('^2[mnc-diffs]^7 Client loaded.')
end