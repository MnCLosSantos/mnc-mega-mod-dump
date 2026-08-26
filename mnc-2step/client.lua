-- client.lua  (mnc-2step)
local QBCore      = nil
local kitCache    = {}   -- [plate] = { kit, tier, limiter, rolling, boost } | false | nil
local boostActive = {}   -- [vehicle] = { endTime, multiplier }
local keyHeld     = false
local lastBurst   = {}   -- [vehicle] = GetGameTimer()
local lastRolling = {}   -- [vehicle] = GetGameTimer()
local ptfxLoaded  = false

-- ===========================
-- QBCore init
-- ===========================
CreateThread(function()
    while not QBCore do
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbcore') == 'started' then
            local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and obj then
                QBCore = obj
                if Config.Debug then print('^2[mnc-2step]^7 QBCore loaded.') end
            end
        end
        Wait(500)
    end
end)

-- ===========================
-- Pre-load particle dict
-- ===========================
CreateThread(function()
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(100) end
    ptfxLoaded = true
end)

-- ===========================
-- Notify
-- ===========================
RegisterNetEvent('mnc-2step:notify', function(data)
    lib.notify({
        title       = data.title or '2-Step',
        description = data.description,
        type        = data.type or 'inform',
        duration    = data.duration or 5000
    })
end)

-- ===========================
-- Sync events
-- ===========================
RegisterNetEvent('mnc-2step:syncData', function(plate, data)
    kitCache[plate] = data
end)

-- ===========================
-- NUI sound helper
-- ===========================
local function PlayPopSound(file, delays, volumes)
    SendNUIMessage({
        type    = 'mnc_2step_pop',
        file    = file,
        delays  = delays  or { 0 },
        volumes = volumes or { 1.0 },
    })
end

-- ===========================
-- Particle helper
-- Spawns backfire flames at each exhaust bone using looped handle
-- then immediately stops — this is the only reliable way to get
-- correct bone-relative position AND rotation in FiveM.
-- ===========================
local function SpawnFlames(vehicle, count, scale)
    if not ptfxLoaded then return end

    local boneNames = {
        'exhaust', 'exhaust_f',
        'exhaust_1', 'exhaust_2', 'exhaust_3', 'exhaust_4',
        'exhaust_5', 'exhaust_6', 'exhaust_7', 'exhaust_8', 'exhaust_9',
        'roll_exhaust'
    }

    local bones = {}
    for _, name in ipairs(boneNames) do
        local idx = GetEntityBoneIndexByName(vehicle, name)
        if idx ~= -1 then bones[#bones + 1] = idx end
    end
    if #bones == 0 then bones[1] = 0 end

    -- Each pop burst runs in its own thread so UseParticleFxAssetNextCall
    -- and StartParticleFxLoopedOnEntityBone execute on the same tick.
    for b = 1, #bones do
        local boneIdx = bones[b]
        for i = 1, count do
            CreateThread(function()
                Wait((i - 1) * 35)
                if not DoesEntityExist(vehicle) then return end
                UseParticleFxAssetNextCall('core')
                local handle = StartParticleFxLoopedOnEntityBone(
                    'veh_backfire',
                    vehicle,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    boneIdx,
                    scale,
                    false, false, false
                )
                if handle and handle > 0 then
                    Wait(80)
                    if DoesParticleFxLoopedExist(handle) then
                        StopParticleFxLooped(handle, false)
                    end
                end
            end)
        end
    end
end

-- ===========================
-- Merge per-kit config with global defaults
-- ===========================
local function MergeCfg(kitSection, globalSection)
    if not kitSection then return globalSection end
    local out = {}
    for k, v in pairs(globalSection) do
        out[k] = (kitSection[k] ~= nil) and kitSection[k] or v
    end
    return out
end

-- ===========================
-- Fetch kit data for plate (with cache)
-- ===========================
local function GetKitData(plate, cb)
    if kitCache[plate] ~= nil then
        cb(kitCache[plate] or nil)
        return
    end
    QBCore.Functions.TriggerCallback('mnc-2step:getData', function(data)
        kitCache[plate] = data or false
        cb(data)
    end, plate)
end

-- ===========================
-- 2-Step main loop
-- ===========================
CreateThread(function()
    while true do
        if not QBCore then Wait(500) goto continue end

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        -- Must be driver
        if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
            keyHeld = false
            Wait(500)
            goto continue
        end

        local plate = string.upper(GetVehicleNumberPlateText(vehicle):gsub('%s+', ''))

        -- Ensure kit data is loaded
        if kitCache[plate] == nil then
            QBCore.Functions.TriggerCallback('mnc-2step:getData', function(data)
                kitCache[plate] = data or false
            end, plate)
            Wait(200)
            goto continue
        end

        local kitData = kitCache[plate]
        if not kitData then
            Wait(500)
            goto continue
        end

        -- Silently stop if turbo has been removed
        if not IsToggleModOn(vehicle, 18) then
            Wait(500)
            goto continue
        end

        -- Build merged configs for this kit
        local limCfg  = MergeCfg(kitData.limiter, Config.Limiter)
        local rolCfg  = MergeCfg(kitData.rolling, Config.Rolling)
        local bstCfg  = MergeCfg(kitData.boost,   Config.Boost)

        local rpm     = GetVehicleCurrentRpm(vehicle)
        local speed   = GetEntitySpeed(vehicle)
        local keyDown = IsControlPressed(0, Config.TwoStepKey)

        -- ── Active boost torque ──
        if boostActive[vehicle] then
            local ba = boostActive[vehicle]
            if GetGameTimer() < ba.endTime then
                SetVehicleEngineTorqueMultiplier(vehicle, ba.multiplier)
            else
                SetVehicleEngineTorqueMultiplier(vehicle, 1.0)
                boostActive[vehicle] = nil
            end
        end

        -- ── Key released while moving → launch burst ──
        if keyHeld and not keyDown then
            keyHeld = false

            if speed > (Config.Limiter.speedThreshold or 2.0) and rpm >= rolCfg.rpmThreshold then
                local sfx     = bstCfg.soundFile or Config.DefaultSoundFile
                local delays  = {}
                local volumes = {}
                for i = 1, bstCfg.finalBurst do
                    delays[i]  = (i - 1) * 60
                    volumes[i] = bstCfg.finalVolume
                end
                PlayPopSound(sfx, delays, volumes)
                SpawnFlames(vehicle, bstCfg.finalBurst, bstCfg.finalScale)
            end

            Wait(50)
            goto continue
        end

        -- ── Key held ──
        if keyDown then
            keyHeld = true

            -- RPM must meet minimum threshold — nothing fires at low RPM
            local rpmOk = (rpm >= limCfg.rpmThreshold) or (rpm >= rolCfg.rpmThreshold)
            if not rpmOk then
                Wait(50)
                goto continue
            end

            local now = GetGameTimer()

            -- STATIONARY → Limiter bounce
            if speed <= (Config.Limiter.speedThreshold or 2.0) and rpm >= limCfg.rpmThreshold then
                local last = lastBurst[vehicle] or 0
                if now - last >= limCfg.burstInterval then
                    lastBurst[vehicle] = now

                    local sfx     = limCfg.soundFile or Config.DefaultSoundFile
                    local delays  = {}
                    local volumes = {}
                    for i = 1, limCfg.flameCount do
                        delays[i]  = (i - 1) * 40
                        volumes[i] = limCfg.volumeScale
                    end
                    PlayPopSound(sfx, delays, volumes)
                    SpawnFlames(vehicle, limCfg.flameCount, limCfg.scale)
                    TriggerServerEvent('mnc-2step:broadcastFlames', NetworkGetNetworkIdFromEntity(vehicle), limCfg.flameCount)
                end

            -- ROLLING → Rolling 2-step
            elseif speed > (Config.Limiter.speedThreshold or 2.0) and rpm >= rolCfg.rpmThreshold then
                local last = lastRolling[vehicle] or 0
                if now - last >= rolCfg.burstInterval then
                    lastRolling[vehicle] = now

                    local sfx     = rolCfg.soundFile or Config.DefaultSoundFile
                    local delays  = {}
                    local volumes = {}
                    for i = 1, rolCfg.flameCount do
                        delays[i]  = (i - 1) * 50
                        volumes[i] = rolCfg.volumeScale
                    end
                    PlayPopSound(sfx, delays, volumes)
                    SpawnFlames(vehicle, rolCfg.flameCount, rolCfg.scale)
                    TriggerServerEvent('mnc-2step:broadcastFlames', NetworkGetNetworkIdFromEntity(vehicle), rolCfg.flameCount)
                end
            end

            Wait(30)
            goto continue
        end

        Wait(50)
        ::continue::
    end
end)

-- ===========================
-- Broadcast flames to nearby players
-- ===========================
RegisterNetEvent('mnc-2step:doFlames', function(netId, count)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 then return end
    local localPed = PlayerPedId()
    if GetVehiclePedIsIn(localPed, false) == vehicle then return end
    SpawnFlames(vehicle, count, Config.Limiter.scale)
end)

-- ===========================
-- Client-side job check
-- ===========================
local function HasAllowedJob()
    if not Config.RequireJob then return true end
    if not QBCore then return false end
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.job then return false end
    local job      = PlayerData.job.name
    local grade    = (PlayerData.job.grade and PlayerData.job.grade.level) or 0
    local minGrade = Config.AllowedJobs[job]
    if minGrade == nil then return false end
    return grade >= minGrade
end

-- ===========================
-- GetVehicleAtFront
-- Player must be on foot, within 1m of the front of a nearby vehicle
-- ===========================
local FRONT_RADIUS = 1.0

local function GetVehicleAtFront()
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 then return nil end

    local pedPos = GetEntityCoords(ped)
    local best, bestD = nil, FRONT_RADIUS

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local vehPos = GetEntityCoords(veh)
        local fwd    = GetEntityForwardVector(veh)
        local min, max = GetModelDimensions(GetEntityModel(veh))
        local halfLen  = (max.y - min.y) * 0.5

        local frontPoint = vector3(
            vehPos.x + fwd.x * halfLen,
            vehPos.y + fwd.y * halfLen,
            vehPos.z
        )

        local d = #(pedPos - frontPoint)

        if d <= FRONT_RADIUS then
            local toPlayer = pedPos - vehPos
            local dot = toPlayer.x * fwd.x + toPlayer.y * fwd.y
            if dot > 0.0 and d < bestD then
                best  = veh
                bestD = d
            end
        end
    end

    return best
end

-- ===========================
-- Hood open → mechanic animation → progress bar → hood close
-- ===========================
local function DoKitInstall(vehicle, duration, label)
    local ped = PlayerPedId()
    SetEntityHeading(ped, GetEntityHeading(vehicle))

    SetVehicleDoorOpen(vehicle, 4, false, false)
    Wait(600)

    local success = lib.progressBar({
        duration     = duration,
        label        = label,
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = 'amb@world_human_vehicle_mechanic@male@base', clip = 'base', flag = 1 }
    })

    SetVehicleDoorShut(vehicle, 4, false)
    return success
end

-- ===========================
-- Install handler — shared by all three kits
-- ===========================
local function HandleKitInstall(kitName)
    if not HasAllowedJob() then
        lib.notify({ title = '2-Step', description = 'Only authorized mechanics can install this.', type = 'error' })
        return
    end

    local target = GetVehicleAtFront()
    if not target then
        lib.notify({
            title       = '2-Step',
            description = 'Stand directly in front of the vehicle (within 1m of the headlights).',
            type        = 'error'
        })
        return
    end

    local kitCfg = Config.Kits[kitName]
    if not kitCfg then return end

    -- Require base GTA turbo (mod index 18) before allowing install
    if not IsToggleModOn(target, 18) then
        lib.notify({
            title       = kitCfg.label,
            description = 'This vehicle must have a Turbo installed before fitting a 2-step kit.',
            type        = 'error'
        })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(target):gsub('%s+', ''))

    -- Pre-check kit tier BEFORE running the animation
    local data, done = nil, false
    QBCore.Functions.TriggerCallback('mnc-2step:getData', function(cbData)
        data = cbData
        done = true
    end, plate)

    local waited = 0
    while not done and waited < 2000 do
        Wait(100); waited = waited + 100
    end

    local newTier = Config.KitTier[kitName]
    if data and data.tier and data.tier >= newTier then
        lib.notify({
            title       = kitCfg.label,
            description = 'An equal or higher 2-step kit is already installed on this vehicle.',
            type        = 'error'
        })
        return
    end

    if DoKitInstall(target, 5000, 'Installing ' .. kitCfg.label .. '...') then
        TriggerServerEvent('mnc-2step:applyKit', plate, kitName)
    else
        lib.notify({ title = kitCfg.label, description = 'Installation cancelled.', type = 'inform' })
    end
end

-- ===========================
-- Server triggers these when player uses item from inventory
-- ===========================
RegisterNetEvent('mnc-2step:promptApply', function(kitName)
    HandleKitInstall(kitName)
end)

-- ===========================
-- Removal toolbox
-- ===========================
RegisterNetEvent('mnc-2step:openRemovalToolbox', function()
    if not HasAllowedJob() then
        lib.notify({ title = '2-Step Removal', description = 'Only authorized mechanics can remove this kit.', type = 'error' })
        return
    end

    local target = GetVehicleAtFront()
    if not target then
        lib.notify({
            title       = '2-Step Removal',
            description = 'Stand directly in front of the vehicle (within 1m of the headlights).',
            type        = 'error'
        })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(target):gsub('%s+', ''))

    local data, done = nil, false
    QBCore.Functions.TriggerCallback('mnc-2step:getData', function(cbData)
        data = cbData
        done = true
    end, plate)

    local waited = 0
    while not done and waited < 2000 do
        Wait(100); waited = waited + 100
    end

    if not data then
        lib.notify({
            title       = '2-Step Removal',
            description = 'No 2-step kit is installed on this vehicle.',
            type        = 'error'
        })
        return
    end

    local kitCfg = Config.Kits[data.kit]
    local label  = kitCfg and kitCfg.label or data.kit

    SetEntityHeading(PlayerPedId(), GetEntityHeading(target))
    SetVehicleDoorOpen(target, 4, false, false)
    Wait(600)

    local success = lib.progressBar({
        duration     = 5000,
        label        = 'Removing ' .. label .. '...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = 'amb@world_human_vehicle_mechanic@male@base', clip = 'base', flag = 1 }
    })

    SetVehicleDoorShut(target, 4, false)

    if success then
        TriggerServerEvent('mnc-2step:removeKit', plate)
    else
        lib.notify({ title = '2-Step Removal', description = 'Removal cancelled.', type = 'inform' })
    end
end)