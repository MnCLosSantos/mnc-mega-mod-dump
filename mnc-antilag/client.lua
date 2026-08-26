-- client.lua
local QBCore = exports['qb-core']:GetCoreObject()

local currentVeh    = 0
local threadRunning = false
local kitData       = nil


local function randFloat(min, max)
    return min + math.random() * (max - min)
end

local function randInt(min, max)
    return math.random(min, max)
end


local PTFX_ASSET = 'core'
local PTFX_NAME  = 'veh_backfire'

CreateThread(function()
    RequestNamedPtfxAsset(PTFX_ASSET)
    while not HasNamedPtfxAssetLoaded(PTFX_ASSET) do
        Wait(50)
    end
    if Config.Debug then print('[mnc-antilag] particle asset loaded: ' .. PTFX_ASSET) end
end)


local EXHAUST_BONES = {
    'exhaust', 'exhaust_2', 'exhaust_3', 'exhaust_4',
    'exhaust_ml', 'exhaust_mr', 'exhaust_dl', 'exhaust_dr',
}

local function GetExhaustBoneIndices(veh)
    local bones = {}
    for _, name in ipairs(EXHAUST_BONES) do
        local idx = GetEntityBoneIndexByName(veh, name)
        if idx ~= -1 then
            bones[#bones + 1] = idx
        end
    end
    return bones
end


local function SpawnFlameOnBone(veh, boneIdx, scale)
    if not HasNamedPtfxAssetLoaded(PTFX_ASSET) then return end

    local pos    = GetWorldPositionOfEntityBone(veh, boneIdx)
    local offset = GetOffsetFromEntityGivenWorldCoords(veh, pos.x, pos.y, pos.z)

    local boneRot = GetEntityBoneRotation(veh, boneIdx)  -- world space
    local vehRot  = GetEntityRotation(veh, 2)             -- world space
    local relRot  = vector3(
        boneRot.x - vehRot.x,
        boneRot.y - vehRot.y,
        boneRot.z - vehRot.z
    )

    UseParticleFxAssetNextCall(PTFX_ASSET)
    StartParticleFxNonLoopedOnEntity(
        PTFX_NAME,
        veh,
        offset.x, offset.y, offset.z,
        relRot.x, relRot.y, relRot.z,
        scale or 1.0,
        false, false, false
    )
end

-- Fallback for vehicles with no exhaust bones
local function SpawnFlameFallback(veh, scale)
    if not HasNamedPtfxAssetLoaded(PTFX_ASSET) then return end
    UseParticleFxAssetNextCall(PTFX_ASSET)
    StartParticleFxNonLoopedOnEntity(
        PTFX_NAME,
        veh,
        0.0, -2.2, 0.3,
        0.0, 180.0, 0.0,
        scale or 1.0,
        false, false, false
    )
end


RegisterNetEvent('mnc-antilag:notify', function(data)
    lib.notify(data)
end)


RegisterNetEvent('mnc-antilag:syncData', function(plate, data)
    _G['mnc_antilag_cache_' .. plate] = data
    if currentVeh ~= 0 then
        local vehPlate = string.upper(GetVehicleNumberPlateText(currentVeh):gsub('%s+', ''))
        if vehPlate == plate then
            kitData = data
            if not threadRunning then
                StartAntilagLoop(currentVeh)
            end
        end
    end
end)

RegisterNetEvent('mnc-antilag:doFlames', function(netId, count)
    local veh = NetToVeh(netId)
    if not DoesEntityExist(veh) then return end
    if veh == currentVeh then return end

    local boneIndices = GetExhaustBoneIndices(veh)
    local hasBones    = #boneIndices > 0

    CreateThread(function()
        for i = 1, count do
            if not DoesEntityExist(veh) then break end

            local flameScale = randFloat(0.5, 1.0)

            if hasBones then
                for _, boneIdx in ipairs(boneIndices) do
                    SpawnFlameOnBone(veh, boneIdx, flameScale)
                end
            else
                SpawnFlameFallback(veh, flameScale)
            end

            if i < count then Wait(randInt(140, 260)) end
        end
    end)
end)


local function FireBurst(veh, count, volScale, soundFile, ptScale)
    local boneIndices = GetExhaustBoneIndices(veh)
    local hasBones    = #boneIndices > 0

    -- Per-pop timing and volume
    local delays  = { 0 }
    local volumes = { math.min(1.0, volScale * randFloat(0.88, 1.12)) }

    for i = 2, count do
        delays[i]  = delays[i-1] + randInt(140, 260)
        volumes[i] = math.min(1.0, volScale * randFloat(0.88, 1.12))
    end

    if Config.Debug then
        print(('[mnc-antilag] burst | pops=%d | vol=%.3f | bones=%d')
            :format(count, volScale, #boneIndices))
    end

    -- Send audio to NUI
    SendNUIMessage({
        type    = 'mnc_antilag_pop',
        file    = soundFile or Config.DefaultSoundFile,
        volumes = volumes,
        delays  = delays,
    })

    -- Spawn flames in sync with each audio pop.
    -- Flames only run when sound was sent — no silent flashes.
    CreateThread(function()
        for i = 1, count do
            if not DoesEntityExist(veh) or currentVeh ~= veh then break end

            -- Modest scale: 0.5–1.1 keeps flames visible but not cartoonishly large
            local flameScale = (ptScale or 1.0) * randFloat(0.5, 1.1)

            if hasBones then
                for _, boneIdx in ipairs(boneIndices) do
                    SpawnFlameOnBone(veh, boneIdx, flameScale)
                end
            else
                SpawnFlameFallback(veh, flameScale)
            end

            if i < count then
                Wait(delays[i+1] - delays[i])
            end
        end
    end)
end


function StartAntilagLoop(veh)
    if threadRunning then return end
    threadRunning = true

    local baseInterval = kitData.burstInterval
    local baseCount    = kitData.flameCount
    local baseVol      = kitData.volumeScale or Config.MaxVolumeScale or 1.0
    local soundFile    = kitData.soundFile   or Config.DefaultSoundFile
    local ptScale      = kitData.scale       or 1.0

    -- Skip ~55 % of eligible windows — keeps the effect present but not constant
    local skipChance = 0.55

    -- Interval jitter: ±20 % of baseInterval
    local intervalVariance = 0.20

    if Config.Debug then
        print(('[mnc-antilag] loop start | interval=%d | count=%d | vol=%.3f | ptScale=%.2f')
            :format(baseInterval, baseCount, baseVol, ptScale))
    end

    CreateThread(function()
        while currentVeh == veh and DoesEntityExist(veh) do
            local rpm      = GetVehicleCurrentRpm(veh)
            local throttle = GetVehicleThrottleOffset(veh)

            local shouldFire = rpm >= Config.MinRPM
            if Config.LiftOffOnly then
                shouldFire = shouldFire and throttle < 0.1
            end

            if shouldFire and math.random() > skipChance then
                -- Pop count: exactly baseCount, ±1, minimum 1
                local count = math.max(1, baseCount + randInt(-1, 1))

                -- Slight volume boost at higher RPM
                local rpmBoost = 1.0 + (rpm - Config.MinRPM) * 0.20
                local vol      = math.min(1.0, baseVol * rpmBoost)

                -- Always fire sound AND flames together — no silent bursts
                FireBurst(veh, count, vol, soundFile, ptScale)
                TriggerServerEvent('mnc-antilag:broadcastFlames', VehToNet(veh), count)

            elseif Config.Debug then
                print('[mnc-antilag] window skipped')
            end

            -- Jittered wait
            local jitter = baseInterval * intervalVariance
            Wait(math.floor(baseInterval + randFloat(-jitter, jitter)))
        end

        threadRunning = false
        if Config.Debug then print('[mnc-antilag] loop ended') end
    end)
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and veh ~= currentVeh then
            currentVeh = veh
            kitData    = nil

            local plate  = string.upper(GetVehicleNumberPlateText(veh):gsub('%s+', ''))
            local cached = _G['mnc_antilag_cache_' .. plate]

            if cached then
                kitData = cached
                StartAntilagLoop(veh)
                if Config.Debug then print('[mnc-antilag] cache hit: ' .. plate) end
            else
                QBCore.Functions.TriggerCallback('mnc-antilag:getData', function(data)
                    if data and currentVeh == veh then
                        kitData = data
                        _G['mnc_antilag_cache_' .. plate] = data
                        StartAntilagLoop(veh)
                        if Config.Debug then print('[mnc-antilag] server hit: ' .. plate) end
                    else
                        if Config.Debug then print('[mnc-antilag] no kit: ' .. plate) end
                    end
                end, plate)
            end

        elseif veh == 0 and currentVeh ~= 0 then
            currentVeh = 0
            kitData    = nil
        end

        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        local sleep = 250

        if currentVeh ~= 0 and DoesEntityExist(currentVeh) then
            sleep = 0

            local ped = PlayerPedId()
            if GetPedInVehicleSeat(currentVeh, -1) == ped
                and IsControlJustReleased(0, 71)  -- INPUT_VEHICLE_ACCELERATE (W)
            then
                if IsToggleModOn(currentVeh, 18) then  -- 18 = Turbo
                    SendNUIMessage({
                        type    = 'mnc_antilag_pop',
                        file    = Config.BovSoundFile or 'bov_audio.ogg',
                        volumes = { Config.BovVolumeScale or Config.MaxVolumeScale or 1.0 },
                        delays  = { 0 },
                    })
                    if Config.Debug then print('[mnc-antilag] BOV played (turbo, W released)') end
                end
            end
        end

        Wait(sleep)
    end
end)


local function HasAllowedJob()
    if not Config.RequireJob then
        print('[mnc-antilag] job check: RequireJob=false, allowing')
        return true
    end
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.job then
        print('[mnc-antilag] job check: no PlayerData or job')
        return false
    end
    local job      = PlayerData.job.name
    local grade    = (PlayerData.job.grade and PlayerData.job.grade.level) or 0
    local minGrade = Config.AllowedJobs[job]
    print(('[mnc-antilag] job check: job=%s grade=%d minGrade=%s'):format(tostring(job), grade, tostring(minGrade)))
    if minGrade == nil then return false end
    return grade >= minGrade
end

local function GetNearestVehicle()
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 then
        print('[mnc-antilag] GetNearestVehicle: player is IN a vehicle')
        return nil
    end

    local pedPos = GetEntityCoords(ped)
    local best, bestD = nil, 5.0

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local d = #(pedPos - GetEntityCoords(veh))
        if d < bestD then
            best  = veh
            bestD = d
        end
    end

    if best then
        print(('[mnc-antilag] GetNearestVehicle: found veh=%d dist=%.2f'):format(best, bestD))
    else
        print('[mnc-antilag] GetNearestVehicle: no vehicle within 5m')
    end
    return best
end

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


local function HandleKitInstall(kitName)
    print('[mnc-antilag] HandleKitInstall called: ' .. tostring(kitName))

    if not HasAllowedJob() then
        lib.notify({ title = 'Anti-Lag', description = 'Only authorized mechanics can install this.', type = 'error' })
        print('[mnc-antilag] blocked: job check failed')
        return
    end

    local target = GetNearestVehicle()
    if not target then
        lib.notify({
            title       = 'Anti-Lag',
            description = 'No vehicle within 5m. Get closer to the vehicle.',
            type        = 'error'
        })
        return
    end

    local kitCfg = Config.Kits[kitName]
    if not kitCfg then
        print('[mnc-antilag] unknown kit: ' .. tostring(kitName))
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(target):gsub('%s+', ''))
    print('[mnc-antilag] target plate: ' .. plate)

    -- Pre-check tier to avoid wasting animation time
    local data, done = nil, false
    QBCore.Functions.TriggerCallback('mnc-antilag:getData', function(cbData)
        data = cbData
        done = true
    end, plate)

    local waited = 0
    while not done and waited < 3000 do
        Wait(100)
        waited = waited + 100
    end

    if not done then
        print('[mnc-antilag] WARNING: callback timed out after 3s')
    end

    local newTier = Config.KitTier[kitName] or 1
    if data and data.tier and data.tier >= newTier then
        lib.notify({
            title       = kitCfg.label,
            description = 'An equal or higher anti-lag kit is already installed on this vehicle.',
            type        = 'error'
        })
        return
    end

    print('[mnc-antilag] starting install animation...')
    if DoKitInstall(target, 5000, 'Installing ' .. kitCfg.label .. '...') then
        print('[mnc-antilag] animation done, firing server event')
        TriggerServerEvent('mnc-antilag:applyKit', plate, kitName)
    else
        lib.notify({ title = kitCfg.label, description = 'Installation cancelled.', type = 'inform' })
    end
end


RegisterNetEvent('mnc-antilag:promptApply', function(kitName)
    print('[mnc-antilag] promptApply received: ' .. tostring(kitName))
    CreateThread(function()
        HandleKitInstall(kitName)
    end)
end)


RegisterNetEvent('mnc-antilag:adminCheckTurbo', function(adminSrc, plate, kitName, newTier)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    local hasTurbo = false
    if veh ~= 0 then
        hasTurbo = IsToggleModOn(veh, 18)
    end

    TriggerServerEvent('mnc-antilag:adminCommitKit', adminSrc, plate, kitName, newTier, hasTurbo)
end)


local removalActive = false

RegisterNetEvent('mnc-antilag:openRemovalToolbox', function()
    print('[mnc-antilag] openRemovalToolbox received')

    if removalActive then
        lib.notify({ title = 'Anti-Lag Removal', description = 'Already in a removal session.', type = 'error' })
        return
    end

    CreateThread(function()
        if not HasAllowedJob() then
            lib.notify({ title = 'Anti-Lag Removal', description = 'Only authorized mechanics can remove this.', type = 'error' })
            return
        end

        local ped = PlayerPedId()
        if GetVehiclePedIsIn(ped, false) ~= 0 then
            lib.notify({ title = 'Anti-Lag Removal', description = 'You must be on foot to remove a kit.', type = 'error' })
            return
        end

        -- Find nearest vehicle within 10m
        local pedPos = GetEntityCoords(ped)
        local target, bestD = nil, 10.0
        for _, veh in ipairs(GetGamePool('CVehicle')) do
            local d = #(pedPos - GetEntityCoords(veh))
            if d < bestD then target = veh; bestD = d end
        end

        if not target then
            lib.notify({ title = 'Anti-Lag Removal', description = 'No vehicle within 10m.', type = 'error' })
            return
        end

        local plate = string.upper(GetVehicleNumberPlateText(target):gsub('%s+', ''))
        print('[mnc-antilag] removal target plate: ' .. plate)

        -- Check kit is installed
        local data, done = nil, false
        QBCore.Functions.TriggerCallback('mnc-antilag:getData', function(cbData)
            data = cbData; done = true
        end, plate)
        local waited = 0
        while not done and waited < 3000 do Wait(100); waited = waited + 100 end

        if not data then
            lib.notify({ title = 'Anti-Lag Removal', description = 'This vehicle has no anti-lag kit installed.', type = 'error' })
            return
        end

        local kitLabel = (Config.Kits[data.kit] and Config.Kits[data.kit].label) or data.kit

        -- Helper: point 1m beyond the front bumper
        local function GetFrontPoint(veh)
            local vehPos   = GetEntityCoords(veh)
            local fwd      = GetEntityForwardVector(veh)
            local _, bbmax = GetModelDimensions(GetEntityModel(veh))
            local dist     = bbmax.y + 1.0
            return vector3(vehPos.x + fwd.x * dist, vehPos.y + fwd.y * dist, vehPos.z)
        end

        -- Notify player to walk to the marker
        lib.notify({
            title       = 'Anti-Lag Removal',
            description = 'Walk to the marker at the front of the vehicle, then press [E] to remove the ' .. kitLabel .. '.',
            type        = 'inform',
            duration    = 15000,
        })

        removalActive = true
        local pressedE = false

        -- Draw marker + E prompt until player presses E or cancels (walks away)
        CreateThread(function()
            while removalActive do
                local frontPt  = GetFrontPoint(target)
                local playerPt = GetEntityCoords(PlayerPedId())
                local dist     = #(playerPt - frontPt)

                if dist < 1.5 then
                    -- Show E prompt

                    if IsControlJustPressed(0, 38) then  -- E key
                        pressedE = true
                        removalActive = false
                        break
                    end
                else
                end

                Wait(0)
            end
        end)

        -- Wait for E press or timeout (60 seconds)
        local elapsed = 0
        while removalActive and not pressedE and elapsed < 60000 do
            Wait(100)
            elapsed = elapsed + 100
        end

        -- If they walked away / timed out without pressing E
        if not pressedE then
            removalActive = false
            lib.notify({ title = 'Anti-Lag Removal', description = 'Removal cancelled.', type = 'inform' })
            return
        end

        -- ── Mechanic animation ──────────────────────────
        SetEntityHeading(ped, GetEntityHeading(target))
        SetVehicleDoorOpen(target, 4, false, false)
        Wait(600)

        local success = lib.progressBar({
            duration     = 5000,
            label        = 'Removing ' .. kitLabel .. '...',
            useWhileDead = false,
            canCancel    = true,
            disable      = { move = true, car = true, combat = true },
            anim         = { dict = 'amb@world_human_vehicle_mechanic@male@base', clip = 'base', flag = 1 }
        })

        SetVehicleDoorShut(target, 4, false)
        removalActive = false

        if success then
            print('[mnc-antilag] removal complete, notifying server')
            TriggerServerEvent('mnc-antilag:removeKit', plate)
        else
            lib.notify({ title = 'Anti-Lag Removal', description = 'Removal cancelled.', type = 'inform' })
        end
    end)
end)