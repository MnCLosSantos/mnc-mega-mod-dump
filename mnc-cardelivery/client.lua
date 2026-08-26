local QBCore = exports['qb-core']:GetCoreObject()

-- spawnedVehicles[locIndex] = {
--   netId, claimed, hasKeys, promptPlaying, promptDone, plate
-- }
local spawnedVehicles = {}
local activeJob = nil -- set while a delivery is in progress
local pendingKeyGrant = nil
local dropoffPending = nil -- set once the vehicle is parked, waiting on keys-removed -> lock -> payout
local dropoffBlip = nil
local pickupBlips = {} -- pickupBlips[locIndex] = blip handle, one static marker per enabled delivery route (see RefreshPickupBlips below)


local Locations = {}

-- disabling a route while players are online).
local function RefreshPickupBlips()
    for locIndex, blip in pairs(pickupBlips) do
        local loc = Locations[locIndex]
        if not loc or loc.disabled then
            RemoveBlip(blip)
            pickupBlips[locIndex] = nil
        end
    end

    for locIndex, loc in ipairs(Locations) do
        if not loc.disabled and loc.spawn and not pickupBlips[locIndex] then
            local blip = AddBlipForCoord(loc.spawn.x, loc.spawn.y, loc.spawn.z)
            SetBlipSprite(blip, Config.Blips.Pickup.sprite)
            SetBlipColour(blip, Config.Blips.Pickup.color)
            SetBlipScale(blip, Config.Blips.Pickup.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(Config.Blips.Pickup.label)
            EndTextCommandSetBlipName(blip)
            pickupBlips[locIndex] = blip
        end
    end
end

RegisterNetEvent('mnc-cardelivery:client:setLocations', function(list)
    Locations = list or {}
    -- keep the setup UI (if open) showing the current route list
    SendNUIMessage({ action = 'setupLocations', locations = Locations })
    RefreshPickupBlips()
end)

CreateThread(function()
    TriggerServerEvent('mnc-cardelivery:server:requestLocations')
end)


local soundPools = {} -- soundPools[category] = { pool = {remaining indices}, last = lastPlayedIndex }

local function ShuffleIndices(count)
    local pool = {}
    for i = 1, count do pool[i] = i end
    for i = count, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    return pool
end

local function GetNextSoundIndex(category, count)
    if not count or count <= 1 then return 1 end

    local state = soundPools[category]
    if not state then
        state = { pool = {}, last = nil }
        soundPools[category] = state
    end

    if #state.pool == 0 then
        local pool = ShuffleIndices(count)

        if state.last and pool[#pool] == state.last then
            pool[#pool], pool[#pool - 1] = pool[#pool - 1], pool[#pool]
        end
        state.pool = pool
    end

    local idx = table.remove(state.pool)
    state.last = idx
    return idx
end


local function ApplyRandomMods(vehicle)
    if not DoesEntityExist(vehicle) then return end

    SetVehicleModKit(vehicle, 0)

    -- performance mods always maxed
    for _, modType in ipairs(Config.Mods.PerformanceModTypes) do
        local count = GetNumVehicleMods(vehicle, modType)
        if count > 0 then
            SetVehicleMod(vehicle, modType, count - 1, false)
        end
    end
    if Config.Mods.AlwaysTurbo then
        ToggleVehicleMod(vehicle, 18, true)
    end

    -- cosmetic mods randomized
    for _, modType in ipairs(Config.Mods.CosmeticModTypes) do
        local count = GetNumVehicleMods(vehicle, modType)
        if count > 0 and math.random() < Config.Mods.CosmeticChance then
            SetVehicleMod(vehicle, modType, math.random(0, count - 1), false)
        end
    end

    if Config.Mods.RandomizeColor then
        SetVehicleColours(vehicle, math.random(0, 159), math.random(0, 159))
        SetVehicleWindowTint(vehicle, math.random(0, 6))
    end

    if Config.Mods.RandomizePlate then
        SetVehicleNumberPlateText(vehicle, ('%s%03d'):format(Config.Mods.PlatePrefix, math.random(0, 999)))
    end

    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
end

RegisterNetEvent('mnc-cardelivery:client:applyMods', function(netId)
    CreateThread(function()
        local attempts = 0
        while not NetworkDoesEntityExistWithNetworkId(netId) and attempts < 100 do
            Wait(100)
            attempts = attempts + 1
        end
        if NetworkDoesEntityExistWithNetworkId(netId) then
            local veh = NetworkGetEntityFromNetworkId(netId)
            local waitTicks = 0
            while not DoesEntityExist(veh) and waitTicks < 50 do
                Wait(100)
                waitTicks = waitTicks + 1
                veh = NetworkGetEntityFromNetworkId(netId)
            end
            if DoesEntityExist(veh) then
                ApplyRandomMods(veh)
            end
        end
    end)
end)


RegisterNetEvent('mnc-cardelivery:client:vehicleSpawned', function(locIndex, netId)
    spawnedVehicles[locIndex] = {
        netId = netId,
        claimed = false,
        hasKeys = false,
        promptPlaying = false,
        promptDone = false,
    }
end)

RegisterNetEvent('mnc-cardelivery:client:vehicleRemoved', function(locIndex)
    spawnedVehicles[locIndex] = nil
end)

CreateThread(function()
    while true do
        Wait(Config.Streaming.CheckInterval)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for i, loc in ipairs(Locations) do
            if not loc.disabled then
                local dist = #(coords - vector3(loc.spawn.x, loc.spawn.y, loc.spawn.z))
                local state = spawnedVehicles[i]
                if not state and dist <= Config.Streaming.SpawnDistance then
                    TriggerServerEvent('mnc-cardelivery:server:requestSpawn', i)
                elseif state and not state.claimed and dist >= Config.Streaming.DespawnDistance then
                    TriggerServerEvent('mnc-cardelivery:server:requestDespawn', i)
                end
            end
        end
    end
end)


local function StartKeyPrompt(locIndex, state)
    state.promptPlaying = true
    QBCore.Functions.TriggerCallback('mnc-cardelivery:server:claimJob', function(success, plate)
        if not success then
            state.promptPlaying = false
            state.promptDone = true -- somebody else got there first, stop probing this one
            return
        end
        state.claimed = true
        state.plate = plate
        pendingKeyGrant = { locIndex = locIndex, netId = state.netId }
        SendNUIMessage({
            action = 'playSound',
            category = 'prompt',
            index = GetNextSoundIndex('prompt', Config.Sounds.PromptCount),
        })
    end, locIndex)
end

CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            local coords = GetEntityCoords(ped)
            for locIndex, state in pairs(spawnedVehicles) do
                if state and not state.claimed and not state.promptPlaying and not state.promptDone
                    and state.netId and NetworkDoesEntityExistWithNetworkId(state.netId) then
                    local veh = NetworkGetEntityFromNetworkId(state.netId)
                    if DoesEntityExist(veh) then
                        local dist = #(coords - GetEntityCoords(veh))
                        if dist <= Config.PromptDistance then
                            StartKeyPrompt(locIndex, state)
                        end
                    end
                end
            end
        end
    end
end)

RegisterNUICallback('audioEnded', function(data, cb)
    if data.category == 'prompt' and pendingKeyGrant then
        local grant = pendingKeyGrant
        pendingKeyGrant = nil
        TriggerServerEvent('mnc-cardelivery:server:giveKeys', grant.locIndex, grant.netId)
        local state = spawnedVehicles[grant.locIndex]
        if state then
            state.hasKeys = true
            state.promptPlaying = false
        end
    elseif data.category == 'dropoff' and dropoffPending then
        local pending = dropoffPending
        dropoffPending = nil

        TriggerServerEvent('mnc-cardelivery:server:removeKeys', pending.locIndex, pending.netId)
        lib.notify({
            title = 'Delivery',
            description = 'Keys removed. Lock the vehicle to receive payment.',
            type = 'inform',
            duration = 7000,
        })

        -- poll the door lock state (works regardless of which vehicle keys
        -- resource is configured, since locking always goes through this native)
        CreateThread(function()
            while DoesEntityExist(pending.vehicle) do
                Wait(500)
                if GetVehicleDoorLockStatus(pending.vehicle) >= 2 then
                    TriggerServerEvent('mnc-cardelivery:server:completeDelivery', pending.locIndex, pending.damagePercent, pending.elapsed)
                    break
                end
            end
        end)
    end
    cb('ok')
end)


local function CleanupDelivery()
    if dropoffBlip then
        RemoveBlip(dropoffBlip)
        dropoffBlip = nil
    end
    SendNUIMessage({ action = 'hideHUD' })
    activeJob = nil
end


local function StartDropoff(job, damagePercent, elapsed)
    activeJob = nil
    if dropoffBlip then
        RemoveBlip(dropoffBlip)
        dropoffBlip = nil
    end
    SendNUIMessage({ action = 'hideHUD' })
    SendNUIMessage({ action = 'playSound', category = 'dropoff' })


    -- stops the re-trigger.
    local state = spawnedVehicles[job.locIndex]
    if state then
        state.hasKeys = false
    end

    dropoffPending = {
        locIndex = job.locIndex,
        netId = job.netId,
        vehicle = job.vehicle,
        damagePercent = damagePercent,
        elapsed = elapsed,
    }
end

local function BeginDelivery(locIndex, veh, netId)
    local loc = Locations[locIndex]
    local baseBody = GetVehicleBodyHealth(veh)
    local baseEngine = GetVehicleEngineHealth(veh)

    activeJob = {
        locIndex = locIndex,
        vehicle = veh,
        netId = netId,
        startTime = GetGameTimer(),
        timeLimit = loc.time,
        baseBody = baseBody > 0 and baseBody or 1000.0,
        baseEngine = baseEngine > 0 and baseEngine or 1000.0,
        lastBody = baseBody,
        lastEngine = baseEngine,
        lastDamageSound = 0,
    }

    dropoffBlip = AddBlipForCoord(loc.delivery.x, loc.delivery.y, loc.delivery.z)
    SetBlipSprite(dropoffBlip, Config.Blips.Dropoff.sprite)
    SetBlipColour(dropoffBlip, Config.Blips.Dropoff.color)
    SetBlipScale(dropoffBlip, Config.Blips.Dropoff.scale)
    SetBlipAsShortRange(dropoffBlip, false)
    SetBlipRoute(dropoffBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blips.Dropoff.label)
    EndTextCommandSetBlipName(dropoffBlip)

    SendNUIMessage({ action = 'showHUD', timeLimit = loc.time, maxDamagePercent = Config.MaxDamagePercent })
    lib.notify({
        title = 'Delivery Job',
        description = ('Deliver the vehicle within %d minutes. Keep damage under %d%%.'):format(math.ceil(loc.time / 60), Config.MaxDamagePercent),
        type = 'inform',
    })

    TriggerServerEvent('mnc-cardelivery:server:startDelivery', locIndex)

    CreateThread(function()
        while activeJob and activeJob.locIndex == locIndex do
            Wait(Config.DamageCheckInterval)
            local job = activeJob
            if not job then break end
            local vehicle = job.vehicle
            if not DoesEntityExist(vehicle) then
                TriggerServerEvent('mnc-cardelivery:server:failDelivery', job.locIndex, 'vehicle_lost')
                CleanupDelivery()
                break
            end

            -- cap damage at Config.MaxDamagePercent
            local maxLossBody = job.baseBody * (Config.MaxDamagePercent / 100)
            local maxLossEngine = job.baseEngine * (Config.MaxDamagePercent / 100)
            local minBody = job.baseBody - maxLossBody
            local minEngine = job.baseEngine - maxLossEngine

            local body = GetVehicleBodyHealth(vehicle)
            local engine = GetVehicleEngineHealth(vehicle)
            local tank = GetVehiclePetrolTankHealth(vehicle)
            local minTank = 1000.0 - (1000.0 * (Config.MaxDamagePercent / 100))

            local damagedThisTick = (body < job.lastBody - 0.5) or (engine < job.lastEngine - 0.5)

            if body < minBody then
                SetVehicleBodyHealth(vehicle, minBody)
                body = minBody
            end
            if engine < minEngine then
                SetVehicleEngineHealth(vehicle, minEngine)
                engine = minEngine
            end
            if tank < minTank then
                SetVehiclePetrolTankHealth(vehicle, minTank)
            end
            if GetEntityHealth(vehicle) < GetEntityMaxHealth(vehicle) - maxLossBody then
                SetEntityHealth(vehicle, math.floor(GetEntityMaxHealth(vehicle) - maxLossBody))
            end

            if damagedThisTick then
                local now = GetGameTimer()
                if now - job.lastDamageSound > Config.DamageSoundCooldown then
                    job.lastDamageSound = now
                    SendNUIMessage({
                        action = 'playSound',
                        category = 'damage',
                        index = GetNextSoundIndex('damage', Config.Sounds.DamageCount),
                    })
                end
            end

            job.lastBody = body
            job.lastEngine = engine

            -- real damage percent, capped to Config.MaxDamagePercent (used for payout math server-side)
            local damagePercent = 100 - (((body / job.baseBody) + (engine / job.baseEngine)) / 2 * 100)
            damagePercent = math.max(0, math.min(Config.MaxDamagePercent, damagePercent))

            local condition = 100 - ((damagePercent / Config.MaxDamagePercent) * 100)
            condition = math.max(0, math.min(100, condition))

            local elapsed = (GetGameTimer() - job.startTime) / 1000
            local remaining = job.timeLimit - elapsed

            SendNUIMessage({
                action = 'updateHUD',
                condition = condition,
                timeRemaining = math.max(0, remaining),
            })

            if remaining <= 0 then
                TriggerServerEvent('mnc-cardelivery:server:failDelivery', job.locIndex, 'time_expired')
                CleanupDelivery()
                break
            end

            local dCoords = Locations[job.locIndex].delivery
            local pCoords = GetEntityCoords(vehicle)
            local distToDrop = #(pCoords - vector3(dCoords.x, dCoords.y, dCoords.z))
            if distToDrop <= (Locations[job.locIndex].radius or 8.0) then
                StartDropoff(job, damagePercent, elapsed)
                break
            end
        end
    end)
end

-- detect entering a claimed vehicle as the driver
CreateThread(function()
    while true do
        Wait(500)
        if not activeJob then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if GetPedInVehicleSeat(veh, -1) == ped then
                    for locIndex, state in pairs(spawnedVehicles) do
                        if state and state.hasKeys and state.netId
                            and NetworkDoesEntityExistWithNetworkId(state.netId)
                            and NetworkGetEntityFromNetworkId(state.netId) == veh then
                            BeginDelivery(locIndex, veh, state.netId)
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('mnc-cardelivery:client:deliveryResult', function(success, payout)
    local category = success and 'success' or 'fail'
    local count = success and Config.Sounds.SuccessCount or Config.Sounds.FailCount
    SendNUIMessage({ action = 'playSound', category = category, index = GetNextSoundIndex(category, count) })

    if success then
        lib.notify({ title = 'Delivery Job', description = ('Delivery complete! You earned $%d.'):format(payout), type = 'success' })
    else
        lib.notify({ title = 'Delivery Job', description = 'Delivery failed.', type = 'error' })
    end
end)


RegisterNetEvent('mnc-cardelivery:client:openSetupUI', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openSetup', locations = Locations })
end)

RegisterNUICallback('setupUseMyPosition', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    cb({ x = coords.x, y = coords.y, z = coords.z, w = heading })
end)

RegisterNUICallback('setupSaveLocation', function(data, cb)
    TriggerServerEvent('mnc-cardelivery:server:saveLocation', data)
    cb('ok')
end)

RegisterNUICallback('setupDeleteLocation', function(data, cb)
    TriggerServerEvent('mnc-cardelivery:server:deleteLocation', { dbId = data.dbId, configIndex = data.configIndex })
    cb('ok')
end)

RegisterNUICallback('setupClose', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)


local testDrive = nil -- { vehicle, blip, radius, dropCoords, startTime, originalCoords, originalHeading }

local function ParseVehiclesCsvClient(raw)
    local vehicles = {}
    for v in (raw or ''):gmatch('([^,]+)') do
        local trimmed = v:match('^%s*(.-)%s*$')
        if trimmed ~= '' then vehicles[#vehicles + 1] = trimmed end
    end
    return vehicles
end

local function EndTestDrive(cancelled)
    local td = testDrive
    if not td then return end
    testDrive = nil

    if td.blip then RemoveBlip(td.blip) end

    local ped = PlayerPedId()
    if DoesEntityExist(td.vehicle) then
        DeleteEntity(td.vehicle)
    end
    SetEntityCoords(ped, td.originalCoords.x, td.originalCoords.y, td.originalCoords.z, false, false, false, false)
    SetEntityHeading(ped, td.originalHeading)

    SendNUIMessage({ action = 'testDriveHide' })
    SetNuiFocus(true, true)

    local result = nil
    if cancelled then
        lib.notify({ title = 'Test Drive', description = 'Cancelled.', type = 'error' })
    else
        local elapsed = (GetGameTimer() - td.startTime) / 1000
        local rtc = Config.Admin.RouteTimer
        local buffered = elapsed * (1 + ((rtc.BufferPercent or 0) / 100))
        buffered = math.max(rtc.MinTime or 1, buffered)
        local roundTo = rtc.RoundTo or 1
        if roundTo > 0 then
            buffered = math.floor((buffered / roundTo) + 0.5) * roundTo
        end

        result = {
            timeLimit = math.floor(buffered),
            rawElapsed = math.floor(elapsed),
        }

        lib.notify({
            title = 'Test Drive',
            description = ('Drive time %ds -> time limit set to %ds.'):format(result.rawElapsed, result.timeLimit),
            type = 'success',
        })
    end

    SendNUIMessage({
        action = 'testDriveDone',
        cancelled = cancelled,
        result = result,
    })
end

RegisterNUICallback('setupStartTestDrive', function(data, cb)
    if testDrive then
        cb('ok')
        return
    end

    local spawn, delivery = data and data.spawn, data and data.delivery
    local radius = tonumber(data and data.radius)
    local vehicles = ParseVehiclesCsvClient(data and data.vehicles)

    local valid = type(spawn) == 'table' and type(delivery) == 'table'
        and tonumber(spawn.x) and tonumber(spawn.y) and tonumber(spawn.z) and tonumber(spawn.w)
        and tonumber(delivery.x) and tonumber(delivery.y) and tonumber(delivery.z)
        and radius and radius > 0 and #vehicles > 0

    if not valid then
        lib.notify({ title = 'Test Drive', description = 'Fill in spawn, dropoff, radius and at least one vehicle first.', type = 'error' })
        cb('ok')
        return
    end

    local model = vehicles[math.random(#vehicles)]
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 100 do
        Wait(50)
        attempts = attempts + 1
    end
    if not HasModelLoaded(modelHash) then
        lib.notify({ title = 'Test Drive', description = ("Couldn't load vehicle model '%s' - check the spawn name."):format(model), type = 'error' })
        cb('ok')
        return
    end

    local ped = PlayerPedId()
    local originalCoords = GetEntityCoords(ped)
    local originalHeading = GetEntityHeading(ped)

    local sx, sy, sz, sw = tonumber(spawn.x), tonumber(spawn.y), tonumber(spawn.z), tonumber(spawn.w)
    local dx, dy, dz = tonumber(delivery.x), tonumber(delivery.y), tonumber(delivery.z)

    local vehicle = CreateVehicle(modelHash, sx, sy, sz, sw, false, false)
    SetModelAsNoLongerNeeded(modelHash)
    ApplyRandomMods(vehicle)
    SetVehicleOnGroundProperly(vehicle)

    SetEntityCoords(ped, sx, sy, sz, false, false, false, false)
    SetPedIntoVehicle(ped, vehicle, -1)

    SetNuiFocus(false, false)

    local blip = AddBlipForCoord(dx, dy, dz)
    SetBlipSprite(blip, Config.Blips.Dropoff.sprite)
    SetBlipColour(blip, Config.Blips.Dropoff.color)
    SetBlipScale(blip, Config.Blips.Dropoff.scale)
    SetBlipAsShortRange(blip, false)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Test Drive Dropoff')
    EndTextCommandSetBlipName(blip)

    testDrive = {
        vehicle = vehicle,
        blip = blip,
        radius = radius,
        dropCoords = vector3(dx, dy, dz),
        startTime = GetGameTimer(),
        originalCoords = originalCoords,
        originalHeading = originalHeading,
    }

    SendNUIMessage({ action = 'testDriveShow' })
    lib.notify({
        title = 'Test Drive',
        description = ('Deliver the %s to the marker to set the time limit. BACKSPACE to cancel.'):format(model),
        type = 'inform',
        duration = 8000,
    })

    CreateThread(function()
        while testDrive do
            Wait(200)
            local td = testDrive
            if not td then break end
            if not DoesEntityExist(td.vehicle) then
                lib.notify({ title = 'Test Drive', description = 'Vehicle lost - cancelled.', type = 'error' })
                EndTestDrive(true)
                break
            end

            SendNUIMessage({
                action = 'testDriveTick',
                elapsed = (GetGameTimer() - td.startTime) / 1000,
            })

            local dist = #(GetEntityCoords(td.vehicle) - td.dropCoords)
            if dist <= td.radius then
                EndTestDrive(false)
                break
            end
        end
    end)

    cb('ok')
end)

RegisterKeyMapping('cardelivery_testdrive_cancel', 'Car Delivery: cancel test drive', 'keyboard', 'BACK')
RegisterCommand('cardelivery_testdrive_cancel', function()
    if testDrive then
        EndTestDrive(true)
    end
end, false)


local placement = nil -- { target, cam, vehicle, phase, heading }

local DropPlacementVehicle
local RePickUpPlacementVehicle
local ConfirmPlacement
local EndPlacement

local function SetPlacementHint(text)
    SendNUIMessage({ action = 'placementHint', text = text })
end


local function GroundRaycast(x, y, z)
    local rayHandle = StartShapeTestRay(x, y, z + 4.0, x, y, z - 500.0, 1, 0, 0)
    local _, hit, endCoords = GetShapeTestResult(rayHandle)
    if hit == 1 then
        return true, endCoords
    end
    return false, nil
end


local function RotationToDirection(rotation)
    local x = rotation.x * (math.pi / 180.0)
    local z = rotation.z * (math.pi / 180.0)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function GetCamDirections(rot)
    local forward = RotationToDirection(rot)
    local right = RotationToDirection(vector3(0.0, 0.0, rot.z + 90.0))
    return forward, right
end

EndPlacement = function(cancelled, result)
    local p = placement
    if not p then return end
    placement = nil

    if DoesEntityExist(p.vehicle) then
        DeleteEntity(p.vehicle)
    end
    RenderScriptCams(false, false, 0, true, true)
    if p.cam then
        DestroyCam(p.cam, false)
    end

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)

    SendNUIMessage({ action = 'placementHide' })
    SetNuiFocus(true, true)

    if cancelled then
        lib.notify({ title = 'Placement', description = 'Cancelled.', type = 'error' })
    end

    SendNUIMessage({
        action = 'placementDone',
        cancelled = cancelled,
        target = p.target,
        result = result,
    })
end


DropPlacementVehicle = function()
    local p = placement
    if not p or p.phase ~= 'flying' then return end

    local camCoords = GetCamCoord(p.cam)
    local found, groundCoords = GroundRaycast(camCoords.x, camCoords.y, camCoords.z)
    if not found then
        lib.notify({ title = 'Placement', description = "Can't find ground under the camera - fly lower and try again.", type = 'error' })
        return
    end

    SetEntityCoordsNoOffset(p.vehicle, groundCoords.x, groundCoords.y, groundCoords.z + 1.0, false, false, false)
    SetEntityHeading(p.vehicle, p.heading)
    FreezeEntityPosition(p.vehicle, false)
    SetEntityCollision(p.vehicle, true, true)
    SetEntityAlpha(p.vehicle, 255, false)

    local preSettle = GetEntityCoords(p.vehicle)
    SetVehicleOnGroundProperly(p.vehicle)
    Wait(200)
    local settled = GetEntityCoords(p.vehicle)

    if #(settled - preSettle) > 5.0 then
        lib.notify({ title = 'Placement', description = 'That spot moved a lot while settling - double check it before confirming.', type = 'inform' })
    end
    if IsEntityInWater(p.vehicle) then
        lib.notify({ title = 'Placement', description = 'This spot is in water.', type = 'inform' })
    end

    p.phase = 'settled'
    SetPlacementHint('Settled - ENTER to confirm, R to pick it back up, LEFT/RIGHT to rotate, BACKSPACE to cancel.')
end

RePickUpPlacementVehicle = function()
    local p = placement
    if not p or p.phase ~= 'settled' then return end

    FreezeEntityPosition(p.vehicle, true)
    SetEntityCollision(p.vehicle, false, false)
    SetEntityAlpha(p.vehicle, 180, false)
    p.phase = 'flying'
    SetPlacementHint('Flying - ENTER to drop the car here.')
end

ConfirmPlacement = function()
    local p = placement
    if not p or p.phase ~= 'settled' then return end

    local coords = GetEntityCoords(p.vehicle)
    local heading = GetEntityHeading(p.vehicle)
    EndPlacement(false, { x = coords.x, y = coords.y, z = coords.z, w = heading })
end

RegisterNUICallback('setupStartPlacement', function(data, cb)
    local target = data and data.target
    if target ~= 'spawn' and target ~= 'drop' then
        cb('ok')
        return
    end
    if placement then
        cb('ok')
        return
    end

    local ped = PlayerPedId()
    local startCoords = GetEntityCoords(ped)
    local startHeading = GetEntityHeading(ped)

    SetNuiFocus(false, false)

    local modelName = (data.vehicleModel and data.vehicleModel ~= '' and data.vehicleModel) or Config.Admin.Placement.PreviewVehicle
    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 100 do
        Wait(50)
        attempts = attempts + 1
    end
    if not HasModelLoaded(modelHash) then
        -- typed vehicle name didn't load (bad spawn name?) - fall back to the default preview model
        modelHash = GetHashKey(Config.Admin.Placement.PreviewVehicle)
        RequestModel(modelHash)
        attempts = 0
        while not HasModelLoaded(modelHash) and attempts < 100 do
            Wait(50)
            attempts = attempts + 1
        end
    end

    local vehicle = CreateVehicle(modelHash, startCoords.x, startCoords.y, startCoords.z, startHeading, false, false)
    SetEntityAlpha(vehicle, 180, false)
    SetEntityCollision(vehicle, false, false)
    FreezeEntityPosition(vehicle, true)
    SetEntityInvincible(vehicle, true)
    SetModelAsNoLongerNeeded(modelHash)

    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', startCoords.x, startCoords.y, startCoords.z + 30.0, -60.0, 0.0, startHeading, Config.Admin.Placement.CamFov, false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)

    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)

    placement = {
        target = target,
        cam = cam,
        vehicle = vehicle,
        phase = 'flying',
        heading = startHeading,
    }

    SendNUIMessage({ action = 'placementShow' })
    SetPlacementHint('Flying - ENTER to drop the car here.')
    lib.notify({
        title = 'Placement',
        description = 'WASD + mouse to fly, SPACE/CTRL for up/down, SHIFT to move faster, LEFT/RIGHT to rotate. ENTER to drop, BACKSPACE to cancel.',
        type = 'inform',
        duration = 9000,
    })

    cb('ok')
end)

CreateThread(function()
    while true do
        Wait(0)
        local p = placement
        if p then
            DisableAllControlActions(0)
            EnableControlAction(0, 200, true) -- INPUT_FRONTEND_PAUSE (Esc) - always leave an escape hatch

            local lookLR = GetDisabledControlNormal(0, 1)  -- INPUT_LOOK_LR
            local lookUD = GetDisabledControlNormal(0, 2)  -- INPUT_LOOK_UD
            local moveLR = GetDisabledControlNormal(0, 30) -- INPUT_MOVE_LR
            local moveUD = GetDisabledControlNormal(0, 31) -- INPUT_MOVE_UD (forward is negative)
            local fast = IsDisabledControlPressed(0, 21)   -- INPUT_SPRINT (Shift)
            local up = IsDisabledControlPressed(0, 22)     -- INPUT_JUMP (Space)
            local down = IsDisabledControlPressed(0, 36)   -- INPUT_DUCK (Ctrl)
            local rotateLeft = IsDisabledControlPressed(0, 174)  -- INPUT_FRONTEND_LEFT (Left Arrow)
            local rotateRight = IsDisabledControlPressed(0, 175) -- INPUT_FRONTEND_RIGHT (Right Arrow)

            local rot = GetCamRot(p.cam, 2)
            local newRotZ = rot.z - (lookLR * Config.Admin.Placement.LookSensitivity)
            local newRotX = math.max(-89.0, math.min(89.0, rot.x - (lookUD * Config.Admin.Placement.LookSensitivity)))
            SetCamRot(p.cam, newRotX, 0.0, newRotZ, 2)

            local dt = GetFrameTime()
            local speed = Config.Admin.Placement.MoveSpeed * (fast and Config.Admin.Placement.FastMultiplier or 1.0)
            local forward, right = GetCamDirections(vector3(newRotX, 0.0, newRotZ))
            local camCoords = GetCamCoord(p.cam)

            local vertical = 0.0
            if up then vertical = vertical + (speed * dt) end
            if down then vertical = vertical - (speed * dt) end

            local newCoords = camCoords
                + (forward * (-moveUD) * speed * dt)
                + (right * moveLR * speed * dt)
                + vector3(0.0, 0.0, vertical)

            SetCamCoord(p.cam, newCoords.x, newCoords.y, newCoords.z)

            if rotateLeft then
                p.heading = (p.heading - (Config.Admin.Placement.RotateSpeed * dt)) % 360.0
            end
            if rotateRight then
                p.heading = (p.heading + (Config.Admin.Placement.RotateSpeed * dt)) % 360.0
            end

            if p.phase == 'flying' then
                local found, groundCoords = GroundRaycast(newCoords.x, newCoords.y, newCoords.z)
                if found then
                    SetEntityCoordsNoOffset(p.vehicle, groundCoords.x, groundCoords.y, groundCoords.z + 1.0, false, false, false)
                end
                SetEntityHeading(p.vehicle, p.heading)
            elseif rotateLeft or rotateRight then
                -- fine-tuning heading on an already-settled car: keep it grounded
                SetEntityHeading(p.vehicle, p.heading)
                SetVehicleOnGroundProperly(p.vehicle)
            end
        end
    end
end)

RegisterKeyMapping('cardelivery_placement_action', 'Car Delivery Placement: drop / confirm', 'keyboard', 'RETURN')
RegisterCommand('cardelivery_placement_action', function()
    if not placement then return end
    if placement.phase == 'flying' then
        DropPlacementVehicle()
    elseif placement.phase == 'settled' then
        ConfirmPlacement()
    end
end, false)

RegisterKeyMapping('cardelivery_placement_refly', 'Car Delivery Placement: pick the car back up', 'keyboard', 'R')
RegisterCommand('cardelivery_placement_refly', function()
    RePickUpPlacementVehicle()
end, false)

RegisterKeyMapping('cardelivery_placement_cancel', 'Car Delivery Placement: cancel', 'keyboard', 'BACK')
RegisterCommand('cardelivery_placement_cancel', function()
    if placement then
        EndPlacement(true, nil)
    end
end, false)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, blip in pairs(pickupBlips) do
        RemoveBlip(blip)
    end
    pickupBlips = {}
    if activeJob then
        CleanupDelivery()
    end
    if testDrive then
        if DoesEntityExist(testDrive.vehicle) then
            DeleteEntity(testDrive.vehicle)
        end
        testDrive = nil
    end
    if placement then
        if DoesEntityExist(placement.vehicle) then
            DeleteEntity(placement.vehicle)
        end
        placement = nil
    end
    SetNuiFocus(false, false)
end)