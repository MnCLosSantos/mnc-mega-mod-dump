-- client.lua
local QBCore      = nil
local angleCache  = {}   -- [plate] = { kit, angle, tier } | false
local currentVehicle = nil

-- ===========================
-- QBCore init
-- ===========================
CreateThread(function()
    while not QBCore do
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbcore') == 'started' then
            local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and obj then
                QBCore = obj
                print('^2[mnc-anglekit]^7 QBCore loaded.')
            end
        end
        Wait(500)
    end
end)

-- Pre-load the anim dict so ox_lib progressBar never hits a missing-dict error
local ANIM_DICT = 'amb@world_human_vehicle_mechanic@male@base'
local ANIM_CLIP = 'base'

CreateThread(function()
    while GetResourceState('ox_lib') ~= 'started' do Wait(500) end
    RequestAnimDict(ANIM_DICT)
    while not HasAnimDictLoaded(ANIM_DICT) do Wait(0) end
    print('^2[mnc-anglekit]^7 Anim dict loaded: ' .. ANIM_DICT)
end)

-- ===========================
-- Notify event
-- ===========================
RegisterNetEvent('mnc-anglekit:notify', function(data)
    lib.notify({
        title       = data.title or 'Angle Kit',
        description = data.description,
        type        = data.type or 'inform',
        duration    = data.duration or 5000,
    })
end)

-- ===========================
-- Store original fSteeringLock per vehicle so we can cleanly restore it
-- ===========================
local originalLock = {}   -- [vehicle] = float

local function CacheOriginalLock(vehicle)
    if not originalLock[vehicle] then
        originalLock[vehicle] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSteeringLock')
        if Config.Debug then
            print('^2[mnc-anglekit]^7 Cached original fSteeringLock=' .. tostring(originalLock[vehicle]) .. ' for vehicle ' .. vehicle)
        end
    end
end

-- ===========================
-- Apply steering lock via handling data (fSteeringLock is in degrees)
-- ===========================
local function ApplyAngle(vehicle, degrees)
    if not vehicle or vehicle == 0 then return end
    CacheOriginalLock(vehicle)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSteeringLock', degrees * 1.0)
    if Config.Debug then
        print('^2[mnc-anglekit]^7 Applied fSteeringLock=' .. degrees .. '° to vehicle ' .. vehicle)
    end
end

local function RemoveAngle(vehicle)
    if not vehicle or vehicle == 0 then return end
    if originalLock[vehicle] then
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSteeringLock', originalLock[vehicle])
        originalLock[vehicle] = nil
        if Config.Debug then
            print('^3[mnc-anglekit]^7 Restored original fSteeringLock for vehicle ' .. vehicle)
        end
    end
end

-- ===========================
-- Main thread — detect vehicle entry / exit and apply angle
-- ===========================
CreateThread(function()
    while true do
        if not QBCore then
            Wait(500)
            goto continue
        end

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        -- Not in a vehicle (or not driver)
        if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
            if currentVehicle then
                RemoveAngle(currentVehicle)
                currentVehicle = nil
            end
            Wait(600)
            goto continue
        end

        local plate = string.upper(GetVehicleNumberPlateText(vehicle):gsub('%s+', ''))

        -- Just entered a new vehicle
        if vehicle ~= currentVehicle then
            if currentVehicle then RemoveAngle(currentVehicle) end
            currentVehicle = vehicle
            angleCache[plate] = nil   -- force re-fetch

            if Config.Debug then
                print('^2[mnc-anglekit]^7 Entered vehicle plate=' .. plate)
            end
        end

        -- Fetch data if not yet cached
        if angleCache[plate] == nil then
            angleCache[plate] = false   -- mark as pending
            QBCore.Functions.TriggerCallback('mnc-anglekit:getAngleData', function(data)
                if data and data.angle then
                    angleCache[plate] = data
                    ApplyAngle(vehicle, data.angle)
                    if Config.Debug then
                        print('^2[mnc-anglekit]^7 Loaded kit=' .. data.kit .. ' angle=' .. data.angle .. '° for plate=' .. plate)
                    end
                else
                    angleCache[plate] = false  -- no kit on this vehicle
                end
            end, plate)
        end

        Wait(1000)
        ::continue::
    end
end)

-- ===========================
-- Sync angle data change from server (kit install or /angle command)
-- ===========================
RegisterNetEvent('mnc-anglekit:syncAngleData', function(plate, data)
    angleCache[plate] = data

    -- If we're currently driving that vehicle, apply immediately
    if currentVehicle then
        local curPlate = string.upper(GetVehicleNumberPlateText(currentVehicle):gsub('%s+', ''))
        if curPlate == plate then
            if data and data.angle then
                ApplyAngle(currentVehicle, data.angle)
            else
                RemoveAngle(currentVehicle)
            end
        end
    end
end)

-- ===========================
-- Helper: get nearby vehicle (within Config.ApplyDistance) that player is facing
-- ===========================
local function GetNearbyVehicle()
    local ped    = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 then return nil end

    local pedPos = GetEntityCoords(ped)
    local best, bestD = nil, Config.ApplyDistance

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local d = #(pedPos - GetEntityCoords(veh))
        if d < bestD then
            best  = veh
            bestD = d
        end
    end
    return best
end

-- ===========================
-- Job check helper (client-side early out — server enforces authoritatively)
-- ===========================
local function HasAllowedJob()
    if not Config.RequireJob then return true end
    if not QBCore then return false end
    local job   = QBCore.Functions.GetPlayerData().job
    if not job then return false end
    local minGrade = Config.AllowedJobs[job.name]
    if minGrade == nil then return false end
    return (job.grade.level or 0) >= minGrade
end

-- ===========================
-- Wheel definitions — bone name + friendly label
-- ===========================
local WHEELS = {
    { bone = 'wheel_lf', label = 'Front Left Wheel'  },
    { bone = 'wheel_rf', label = 'Front Right Wheel' },
    { bone = 'wheel_lr', label = 'Rear Left Wheel'   },
    { bone = 'wheel_rr', label = 'Rear Right Wheel'  },
}

local function GetWheelWorldPos(vehicle, boneName)
    local boneIdx = GetEntityBoneIndexByName(vehicle, boneName)
    if boneIdx ~= -1 then
        return GetWorldPositionOfEntityBone(vehicle, boneIdx)
    end
    return GetEntityCoords(vehicle)
end

-- ===========================
-- Single-wheel progress bar — player faces 180° away from wheel (into the arch), then crouches
-- ===========================
local function DoWheelInstall(vehicle, boneName, label, duration)
    local ped      = PlayerPedId()
    local wheelPos = GetWheelWorldPos(vehicle, boneName)
    local pedPos   = GetEntityCoords(ped)

    -- Get the vehicle's forward heading and the side the wheel is on
    -- Instead of trig, just use the vehicle's own heading + a fixed offset per wheel side.
    -- wheel_lf / wheel_lr = left side  → face right  (vehHeading + 90)
    -- wheel_rf / wheel_rr = right side → face left   (vehHeading - 90)
    local vehHeading = GetEntityHeading(vehicle)
    local isLeft     = boneName == 'wheel_lf' or boneName == 'wheel_lr'
    local heading    = (vehHeading + (isLeft and 90.0 or -90.0)) % 360.0

    SetEntityHeading(ped, heading)

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
-- Apply Kit — triggered by useable item (server → client)
-- Player walks to each wheel themselves; must press E to begin work at each one.
-- ===========================
RegisterNetEvent('mnc-anglekit:applyKit', function(kitName)
    local kitCfg = Config.Kits[kitName]
    if not kitCfg then return end

    -- 1. Job check
    if not HasAllowedJob() then
        lib.notify({
            title       = kitCfg.label,
            description = 'You must be a mechanic to install this kit.',
            type        = 'error',
        })
        return
    end

    -- 2. Find nearby vehicle
    local target = GetNearbyVehicle()
    if not target then
        lib.notify({
            title       = kitCfg.label,
            description = 'You must be within ' .. Config.ApplyDistance .. 'm of a vehicle.',
            type        = 'error',
        })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(target):gsub('%s+', ''))

    -- 3. Tier check
    local cached = angleCache[plate]
    if cached and cached.tier then
        if cached.tier >= Config.KitTier[kitName] then
            lib.notify({
                title       = kitCfg.label,
                description = 'This vehicle already has an equal or higher angle kit installed.',
                type        = 'error',
            })
            return
        end
    end

    -- 4. Tell player what to do
    lib.notify({
        title       = kitCfg.label,
        description = 'Walk to each wheel and press [E] to install. Starting with: ' .. WHEELS[1].label,
        type        = 'inform',
        duration    = 5000,
    })

    local timePerWheel = math.floor(kitCfg.installTime / #WHEELS)

    -- 5. Per-wheel loop
    for i, wheel in ipairs(WHEELS) do

        local PROMPT_RADIUS = 1.2   -- metres — how close before E prompt appears
        local ePressed      = false
        local aborted       = false

        -- Thread: draw marker + E prompt while player is in range, set ePressed on keypress
        local promptThread = CreateThread(function()
            while not ePressed and not aborted do
                local ped      = PlayerPedId()
                local pedPos   = GetEntityCoords(ped)
                local wheelPos = GetWheelWorldPos(target, wheel.bone)
                local dist     = #(pedPos - vector3(wheelPos.x, wheelPos.y, wheelPos.z))

                -- Draw marker at wheel
                DrawMarker(
                    1,
                    wheelPos.x, wheelPos.y, wheelPos.z + 0.05,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.3, 0.3, 0.2,
                    255, 165, 0, 180,
                    false, true, 2, false, nil, nil, false
                )

                if dist <= PROMPT_RADIUS then
                    -- Draw help text
                    SetTextComponentFormat('STRING')
                    AddTextComponentString('Press ~INPUT_CONTEXT~ to work on ' .. wheel.label)
                    DisplayHelpTextFromStringLabel(0, false, true, -1)

                    -- E key = INPUT_CONTEXT = control index 51
                    if IsControlJustPressed(0, 51) then
                        ePressed = true
                    end
                end

                Wait(0)
            end
        end)

        -- Block until E pressed or aborted
        while not ePressed and not aborted do
            Wait(100)
        end

        if aborted then
            lib.notify({ title = kitCfg.label, description = 'Installation cancelled.', type = 'inform' })
            return
        end

        -- Player pressed E — face toward wheel and run progress bar
        local ok = DoWheelInstall(
            target,
            wheel.bone,
            ('Installing %s — %s (%d/%d)'):format(kitCfg.label, wheel.label, i, #WHEELS),
            timePerWheel
        )

        if not ok then
            lib.notify({ title = kitCfg.label, description = 'Installation cancelled.', type = 'inform' })
            ClearPedTasks(PlayerPedId())
            return
        end

        if i < #WHEELS then
            lib.notify({
                title       = kitCfg.label,
                description = ('Wheel done! Walk to the next one: %s (%d/%d)'):format(WHEELS[i + 1].label, i + 1, #WHEELS),
                type        = 'success',
                duration    = 4000,
            })
        end
    end

    -- 6. All wheels done
    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('mnc-anglekit:applyKit', plate, kitName)
end)

-- ===========================
-- Remove Kit — identical wheel-by-wheel process as install
-- ===========================
RegisterNetEvent('mnc-anglekit:removeKit', function()
    local removerCfg = Config.Remover
    if not removerCfg then return end

    -- 1. Job check
    if not HasAllowedJob() then
        lib.notify({
            title       = removerCfg.label,
            description = 'You must be a mechanic to remove this kit.',
            type        = 'error',
        })
        return
    end

    -- 2. Find nearby vehicle
    local target = GetNearbyVehicle()
    if not target then
        lib.notify({
            title       = removerCfg.label,
            description = 'You must be within ' .. Config.ApplyDistance .. 'm of a vehicle.',
            type        = 'error',
        })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(target):gsub('%s+', ''))

    -- 3. Early client check (server is authoritative)
    local cached = angleCache[plate]
    if cached == false then
        lib.notify({
            title       = removerCfg.label,
            description = 'No angle kit installed on this vehicle.',
            type        = 'error',
        })
        return
    end

    -- 4. Instructions
    lib.notify({
        title       = removerCfg.label,
        description = 'Walk to each wheel and press [E] to remove. Starting with: ' .. WHEELS[1].label,
        type        = 'inform',
        duration    = 5000,
    })

    local timePerWheel = math.floor(removerCfg.removeTime / #WHEELS)

    -- 5. Per-wheel loop (exactly like install)
    for i, wheel in ipairs(WHEELS) do

        local PROMPT_RADIUS = 1.2
        local ePressed      = false
        local aborted       = false

        -- Prompt thread with marker + E
        local promptThread = CreateThread(function()
            while not ePressed and not aborted do
                local ped      = PlayerPedId()
                local pedPos   = GetEntityCoords(ped)
                local wheelPos = GetWheelWorldPos(target, wheel.bone)
                local dist     = #(pedPos - vector3(wheelPos.x, wheelPos.y, wheelPos.z))

                DrawMarker(
                    1,
                    wheelPos.x, wheelPos.y, wheelPos.z + 0.05,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.3, 0.3, 0.2,
                    255, 0, 0, 180,   -- red marker so player knows it's removal
                    false, true, 2, false, nil, nil, false
                )

                if dist <= PROMPT_RADIUS then
                    SetTextComponentFormat('STRING')
                    AddTextComponentString('Press ~INPUT_CONTEXT~ to remove from ' .. wheel.label)
                    DisplayHelpTextFromStringLabel(0, false, true, -1)

                    if IsControlJustPressed(0, 51) then
                        ePressed = true
                    end
                end

                Wait(0)
            end
        end)

        while not ePressed and not aborted do
            Wait(100)
        end

        if aborted then
            lib.notify({ title = removerCfg.label, description = 'Removal cancelled.', type = 'inform' })
            return
        end

        -- Progress bar (re-uses your existing DoWheelInstall)
        local ok = DoWheelInstall(
            target,
            wheel.bone,
            ('Removing %s — %s (%d/%d)'):format(removerCfg.label, wheel.label, i, #WHEELS),
            timePerWheel
        )

        if not ok then
            lib.notify({ title = removerCfg.label, description = 'Removal cancelled.', type = 'inform' })
            ClearPedTasks(PlayerPedId())
            return
        end

        if i < #WHEELS then
            lib.notify({
                title       = removerCfg.label,
                description = ('Wheel done! Walk to the next one: %s (%d/%d)'):format(WHEELS[i + 1].label, i + 1, #WHEELS),
                type        = 'success',
                duration    = 4000,
            })
        end
    end

    -- 6. Finished
    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('mnc-anglekit:removeKit', plate)
end)

-- ===========================
-- /angle command — server pings client to resolve plate, then client fires back
-- ===========================
RegisterNetEvent('mnc-anglekit:requestAngleCommand', function(rawAmount)
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        lib.notify({ title = 'Angle Kit', description = 'You must be driving the vehicle.', type = 'error' })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(vehicle):gsub('%s+', ''))

    -- Quick local check before round-trip
    local cached = angleCache[plate]
    if not cached or not cached.kit then
        lib.notify({ title = 'Angle Kit', description = 'No angle kit on this vehicle.', type = 'error' })
        return
    end

    local kitCfg = Config.Kits[cached.kit]
    if not kitCfg or not kitCfg.canSetAngle then
        lib.notify({
            title       = 'Angle Kit',
            description = 'Upgrade to a Pro Angle Kit to use /angle.',
            type        = 'error',
        })
        return
    end

    if not rawAmount then
        lib.notify({
            title       = 'Angle Kit',
            description = ('Usage: /angle <degrees> (%d–%d)'):format(Config.MinAngle, Config.MaxAngle),
            type        = 'inform',
        })
        return
    end

    TriggerServerEvent('mnc-anglekit:applyAngleCommand', plate, rawAmount)
end)

if Config.Debug then
    print('^2[mnc-anglekit]^7 Client loaded.')
end