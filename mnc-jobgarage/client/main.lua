-- client/main.lua
local QBCore = exports['qb-core']:GetCoreObject()
local Targets, Parking, Locations, currentVeh = {}, {}, {}, { out = false, current = nil, name = nil, model = nil, job = nil }
local myRoles = {}   -- { [job] = { [roleName] = true } }  fetched from server

-- ─────────────────────────────────────────────────────────────────────────────
--  Fetch this player's roles from the server
-- ─────────────────────────────────────────────────────────────────────────────
local function fetchMyRoles()
    myRoles = lib.callback.await('mnc-jobgarage:cb:getMyRoles', false) or {}
end

-- On initial resource start, wait for QBCore to have the player ready then fetch.
-- The extra Wait is a safety net — the event hooks below are the reliable path.
CreateThread(function()
    Wait(2000)
    -- Request the merged location data (with required_role, unlimited etc.) from server
    TriggerServerEvent('mnc-jobgarage:server:requestSync')
    fetchMyRoles()
end)

-- Re-fetch whenever the player fully loads (first join OR respawn after DC).
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(500)   -- brief yield so QBCore player data is committed
    TriggerServerEvent('mnc-jobgarage:server:requestSync')
    fetchMyRoles()
end)

-- Re-fetch whenever the player changes job (job change affects which roles apply).
AddEventHandler('QBCore:Client:OnJobUpdate', function()
    fetchMyRoles()
end)

-- Re-fetch when the server explicitly tells us our roles changed (assignment/removal).
RegisterNetEvent('mnc-jobgarage:client:rolesUpdated', function()
    fetchMyRoles()
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Apply Performance Upgrades (original, preserved exactly)
-- ─────────────────────────────────────────────────────────────────────────────
local function applyPerformance(veh, perf)
    if not DoesEntityExist(veh) then
        if Config.Debug then print("Error: applyPerformance - Vehicle does not exist") end
        return
    end
    SetVehicleModKit(veh, 0)
    if perf == "max" then
        for _, i in ipairs({11, 12, 13, 15}) do
            SetVehicleMod(veh, i, GetNumVehicleMods(veh, i) - 1 or 0, false)
        end
        ToggleVehicleMod(veh, 18, true)
    elseif type(perf) == "table" then
        SetVehicleMod(veh, 11, perf[1] - 1 or 0, false)
        SetVehicleMod(veh, 12, perf[2] - 1 or 0, false)
        SetVehicleMod(veh, 13, perf[3] - 1 or 0, false)
        SetVehicleMod(veh, 15, perf[4] - 1 or 0, false)
        ToggleVehicleMod(veh, 18, perf[5] or false)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Apply Visual Upgrades (original, preserved exactly)
-- ─────────────────────────────────────────────────────────────────────────────
local function applyVisualUpgrades(veh, visualUpgrades)
    if not DoesEntityExist(veh) then
        if Config.Debug then print("Error: applyVisualUpgrades - Vehicle does not exist") end
        return
    end
    if not visualUpgrades or type(visualUpgrades) ~= "table" then
        if Config.Debug then print("Error: applyVisualUpgrades - Invalid visualUpgrades table") end
        return
    end
    SetVehicleModKit(veh, 0)
    local modMapping = {
        spoiler = 0, frontBumper = 1, rearBumper = 2, sideSkirt = 3, exhaust = 4, frame = 5,
        grille = 6, hood = 7, fender = 8, rightFender = 9, roof = 10, brakes = 12, horn = 14,
        wheels = 23, wheelType = 24, rearWheels = 25, plateHolder = 26, vanityPlates = 27,
        trimDesign = 28, ornaments = 29, dashboard = 30, dialDesign = 31, seats = 32,
        steeringWheel = 33, shifterLeavers = 34, plaques = 35, speakers = 36, trunk = 37,
        hydraulics = 38, engineBlock = 39, airFilter = 40, struts = 41, archCover = 42,
        aerials = 43, trim = 44, tank = 45, doorSpeaker = 46, livery = 48, xenon = 22
    }
    for modType, modIndex in pairs(visualUpgrades) do
        if modType == "neon" then
            if type(modIndex) == "table" and modIndex.enabled then
                ToggleVehicleMod(veh, 17, true)
                if modIndex.color and type(modIndex.color) == "table" and #modIndex.color == 3 then
                    SetVehicleNeonLightsColour(veh, modIndex.color[1], modIndex.color[2], modIndex.color[3])
                end
                SetVehicleNeonLightEnabled(veh, 0, modIndex.layout ~= 1 and modIndex.layout ~= 0)
                SetVehicleNeonLightEnabled(veh, 1, modIndex.layout ~= 0 and modIndex.layout ~= 2)
                SetVehicleNeonLightEnabled(veh, 2, true)
                SetVehicleNeonLightEnabled(veh, 3, true)
            else
                ToggleVehicleMod(veh, 17, false)
            end
        elseif modType == "wheelType" then
            SetVehicleWheelType(veh, modIndex)
        else
            local modId = modMapping[modType]
            if modId then
                if modIndex >= 0 and GetNumVehicleMods(veh, modId) > modIndex then
                    SetVehicleMod(veh, modId, modIndex, false)
                end
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Helper functions (original, preserved exactly)
-- ─────────────────────────────────────────────────────────────────────────────
local function makeProp(data, freeze, ground)
    local propModel = GetHashKey(data.prop or "prop_parkingpay")
    local prop = CreateObject(propModel, data.coords.x, data.coords.y, data.coords.z - 1.0, false, false, false)
    SetEntityHeading(prop, data.coords.w or 0.0)
    if freeze then FreezeEntityPosition(prop, true) end
    if ground then PlaceObjectOnGroundProperly(prop) end
    return prop
end

local function removeTargets()
    for k, target in pairs(Targets) do
        if Config.Target == "qb" then
            exports['qb-target']:RemoveTargetEntity(target.entity, k)
        elseif Config.Target == "ox" then
            exports.ox_target:removeTargetEntity(target.entity, k)
        end
        Targets[k] = nil
    end
    for i = 1, #Parking do
        if DoesEntityExist(Parking[i]) then
            DeleteEntity(Parking[i])
        end
    end
    Parking = {}
end

local function makeTargets()
    removeTargets()
    for i, loc in pairs(Config.Locations or {}) do
        if loc.zoneEnable and loc.garage then
            -- garageId is the unique per-garage identifier (defaults to job for
            -- single-garage-per-job setups — fully backwards compatible).
            local garageId = loc.garageId or loc.job
            -- realJob is the actual QBCore job name used for target visibility.
            -- For multi-garage setups garageId differs from job (e.g. "ambulance_2"
            -- vs "ambulance"), so we must pass the real job to qb-target/ox-target
            -- or it won't show the target to players of that job.
            local realJob  = loc.job
            local out = loc.garage.out
            local prop = makeProp({ prop = "prop_parkingpay", coords = vec4(out.x, out.y, out.z, out.w) }, true, false)
            Parking[#Parking + 1] = prop
            local targetName = "JobGarage: " .. garageId
            Targets[targetName] = { entity = prop }
            local jobLabel = loc.label or loc.garageId or loc.job or "Job Garage"
            if Config.Target == "ox" then
                exports.ox_target:addTargetEntity(prop, {
                    options = {
                        {
                            name = targetName,
                            icon = "fas fa-clipboard",
                            label = "Access " .. jobLabel .. " Garage",
                            job = realJob,
                            onSelect = function()
                                TriggerEvent("mnc-jobgarage:client:Garage:Menu", {
                                    job      = realJob,
                                    garageId = garageId,
                                    spawncoords  = loc.garage.spawn,
                                    list         = loc.garage.list,
                                    prop         = prop,
                                    returncoords = loc.garage.out
                                })
                            end,
                            distance = 2.0
                        }
                    }
                })
            elseif Config.Target == "qb" then
                exports['qb-target']:AddTargetEntity(prop, {
                    options = {
                        {
                            type = "client",
                            icon = "fas fa-clipboard",
                            label = "Access " .. jobLabel .. " Garage",
                            job = realJob,
                            action = function()
                                TriggerEvent("mnc-jobgarage:client:Garage:Menu", {
                                    job      = realJob,
                                    garageId = garageId,
                                    spawncoords  = loc.garage.spawn,
                                    list         = loc.garage.list,
                                    prop         = prop,
                                    returncoords = loc.garage.out
                                })
                            end
                        }
                    },
                    distance = 2.0
                })
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Initialize Targets (original)
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    if not Config then
        print("Error: Config not loaded, cannot initialize targets")
        return
    end
    makeTargets()
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Sync Locations (original, now uses merged data from server)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mnc-jobgarage:client:syncLocations', function(locations)
    -- Ensure every location has a garageId (server may have stripped it or it was
    -- added via DB where garageId == the stored "job" key already).
    for _, loc in pairs(locations or {}) do
        if not loc.garageId then
            loc.garageId = loc.job
        end
    end
    Locations = locations
    -- Patch Config.Locations so makeTargets/legacy code works with the latest data
    Config.Locations = locations
    makeTargets()
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Garage Menu  ──  role-aware vehicle filtering (extends original)
-- ─────────────────────────────────────────────────────────────────────────────
-- Class icons reused for the NUI vehicle grid (font-awesome keys, see html/app.js)
local CLASS_ICON_KEYS = {
    [8]  = "motorcycle",
    [9]  = "truck-monster",
    [10] = "truck-front",
    [11] = "truck-front",
    [12] = "truck-front",
    [13] = "bicycle",
    [14] = "ship",
    [15] = "helicopter",
    [16] = "plane",
    [18] = "kit-medical"
}

-- Keep the original list table around so the NUI can hand back the exact
-- spawnName it picked, and we can look up its full config to spawn it.
local pulloutCtx = nil

RegisterNetEvent("mnc-jobgarage:client:Garage:Menu", function(data)
    local playerJob   = QBCore.Functions.GetPlayerData().job
    local jobLabel    = playerJob and playerJob.label or "Job"
    local playerGrade = playerJob and playerJob.grade and playerJob.grade.level or 0

    -- garageId is the unique per-garage key (defaults to job for legacy compatibility)
    local garageId = data.garageId or data.job
    pulloutCtx = { job = data.job, garageId = garageId, spawncoords = data.spawncoords, returncoords = data.returncoords, list = data.list }

    local vehicleIsOut = currentVeh.out and DoesEntityExist(currentVeh.current)

    if not vehicleIsOut then
        local sorted = {}
        local jobRoles = myRoles[data.job] or {}

        for spawnName, v in pairs(data.list or {}) do
            local gradeOk = false
            local roleOk  = true

            -- Grade check (original logic)
            if not v.grade and not v.rank then
                gradeOk = true
            elseif v.grade and playerJob.grade and playerJob.grade.level >= v.grade then
                gradeOk = true
            elseif v.rank then
                for _, rank in pairs(v.rank) do
                    if rank == (playerJob.grade and playerJob.grade.level or -1) then
                        gradeOk = true
                        break
                    end
                end
            end

            -- Role check (new)
            if v.required_role and v.required_role ~= '' then
                roleOk = jobRoles[v.required_role] == true
            end

            if gradeOk and roleOk then
                table.insert(sorted, {
                    spawnName = spawnName,
                    data      = v,
                    order     = v.order or 9999
                })
            end
        end

        table.sort(sorted, function(a, b) return a.order < b.order end)

        if #sorted == 0 then
            if Config.Notify == "qb" then
                QBCore.Functions.Notify("No vehicles available for your rank", "error")
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Garage', description = 'No vehicles available for your rank', type = 'error' })
            end
            pulloutCtx = nil
            return
        end

        local vehicleList = {}
        for _, entry in ipairs(sorted) do
            local spawnName = entry.spawnName
            local v = entry.data
            local spawnHash = GetHashKey(spawnName)
            local vehicleName = v.CustomName or GetDisplayNameFromVehicleModel(spawnHash) or ("Unknown (" .. spawnName .. ")")

            vehicleList[#vehicleList + 1] = {
                model         = spawnName,
                name          = vehicleName,
                grade         = v.grade,
                iconKey       = CLASS_ICON_KEYS[GetVehicleClassFromName(spawnHash)] or "car",
                maxPerf       = v.performance == "max",
                livery        = v.livery ~= nil,
                bulletproof   = v.bulletproof == true,
                order         = v.order or 9999,
                required_role = v.required_role or nil,
                unlimited     = v.unlimited == true,
            }
        end

        SendNUIMessage({
            action      = 'openPullout',
            isOut       = false,
            job         = data.job,
            garageId    = garageId,
            jobLabel    = jobLabel,
            playerGrade = playerGrade,
            vehicles    = vehicleList,
        })
    else
        SendNUIMessage({
            action         = 'openPullout',
            isOut          = true,
            job            = data.job,
            garageId       = garageId,
            jobLabel       = jobLabel,
            playerGrade    = playerGrade,
            currentVehName = currentVeh.name,
        })
    end

    SetNuiFocus(true, true)
end)

RegisterNUICallback('pulloutClose', function(_, cb)
    SetNuiFocus(false, false)
    pulloutCtx = nil
    cb('ok')
end)

RegisterNUICallback('pulloutSpawn', function(payload, cb)
    SetNuiFocus(false, false)
    if pulloutCtx and payload and payload.model and pulloutCtx.list and pulloutCtx.list[payload.model] then
        TriggerEvent("mnc-jobgarage:client:SpawnList", {
            spawnName   = payload.model,
            spawncoords = pulloutCtx.spawncoords,
            garageId    = pulloutCtx.garageId,
            list        = pulloutCtx.list[payload.model]
        })
    end
    pulloutCtx = nil
    cb('ok')
end)

RegisterNUICallback('pulloutReturn', function(_, cb)
    SetNuiFocus(false, false)
    if pulloutCtx then
        TriggerEvent("mnc-jobgarage:client:RemSpawn", { returncoords = pulloutCtx.returncoords })
    end
    pulloutCtx = nil
    cb('ok')
end)

RegisterNUICallback('pulloutBlip', function(_, cb)
    SetNuiFocus(false, false)
    TriggerEvent("mnc-jobgarage:client:Garage:Blip")
    pulloutCtx = nil
    cb('ok')
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Spawn Vehicle (original, preserved exactly)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent("mnc-jobgarage:client:SpawnList", function(data)
    local spawnName   = data.spawnName
    local spawncoords = data.spawncoords
    local list        = data.list or {}

    -- Convert to vector3 for QBCore.Functions.SpawnVehicle (it needs the coords arg)
    local spawnPos = vector3(
        (spawncoords and spawncoords.x) or 0.0,
        (spawncoords and spawncoords.y) or 0.0,
        (spawncoords and spawncoords.z) or 0.0
    )

    -- Spawn the vehicle client-side (no server setter) so we own the entity
    -- from creation and retain network control throughout. This avoids the
    -- QBCore.Functions.SpawnVehicle post-callback colour reset problem.
    CreateThread(function()
        local modelHash = GetHashKey(spawnName)
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do Wait(100) end

        local veh = CreateVehicle(modelHash, spawnPos.x, spawnPos.y, spawnPos.z, spawncoords.w, true, false)
        SetEntityAsMissionEntity(veh, true, true)
        SetModelAsNoLongerNeeded(modelHash)

        currentVeh.current = veh

        local desiredPlate
        if list.plate then
            desiredPlate = list.plate
        else
            desiredPlate = "JOB" .. math.random(1000, 9999)
        end

        desiredPlate = desiredPlate:upper():gsub("[^%w]", ""):sub(1, 8)
        local fullPlate = desiredPlate
        while #fullPlate < 8 do fullPlate = fullPlate .. " " end
        SetVehicleNumberPlateText(veh, fullPlate)
        local cleanPlate = fullPlate:gsub("%s+", "")

        -- We created this vehicle so we already have network control
        Wait(200)

        SetVehicleDoorsLocked(veh, 1)
        SetVehicleDoorsLockedForAllPlayers(veh, false)
        TriggerEvent("vehiclekeys:client:SetOwner", cleanPlate)
        SetEntityHeading(veh, spawncoords.w)

        -- ── Step 1: everything that calls SetVehicleModKit(0) first ──────────────
        -- SetVehicleModKit resets paint to factory default, so ALL modkit-touching
        -- calls must happen BEFORE colours are applied.

        -- Livery (calls SetVehicleModKit internally)
        if list.livery ~= nil then
            SetVehicleModKit(veh, 0)
            local liverySet = false
            local liveryCount = GetVehicleLiveryCount(veh)
            if liveryCount and liveryCount > 0 then
                SetVehicleLivery(veh, list.livery)
                liverySet = true
            end
            if not liverySet then
                local modCount = GetNumVehicleMods(veh, 48)
                if modCount and modCount > 0 and list.livery < modCount then
                    SetVehicleMod(veh, 48, list.livery, false)
                end
            end
        end

        -- Performance mods (applyPerformance calls SetVehicleModKit internally)
        if list.bulletproof then SetVehicleTyresCanBurst(veh, false) end

        -- Resolve colours up-front so the delayed thread can use them.
        -- Support both array format { c1, c2 } and named format { c1 = x, c2 = y }
        -- from the NUI/admin panel, then coerce to number to guard against
        -- boolean coercion from MySQL TINYINT or JSON deserialisation.
        local _cfgColors = (type(list.colors) == "table") and list.colors or nil
        local fin_c1 = (_cfgColors and (_cfgColors.c1 ~= nil and _cfgColors.c1 or _cfgColors[1])) or nil
        local fin_c2 = (_cfgColors and (_cfgColors.c2 ~= nil and _cfgColors.c2 or _cfgColors[2])) or nil
        if list.db_color1 ~= nil then fin_c1 = list.db_color1 end
        if list.db_color2 ~= nil then fin_c2 = list.db_color2 end
        -- tonumber() coercion: converts boolean false (TINYINT/JSON ghost) to nil,
        -- and ensures valid colour indices are always passed as integers to the native.
        if fin_c1 ~= nil then fin_c1 = tonumber(fin_c1) end
        if fin_c2 ~= nil then fin_c2 = tonumber(fin_c2) end
        local wantColours = (fin_c1 ~= nil or fin_c2 ~= nil)
        if wantColours then fin_c1 = fin_c1 or 0; fin_c2 = fin_c2 or 0 end
        if Config.Debug then
            print("[jobgarage] colour resolve: fin_c1=" .. tostring(fin_c1) .. " fin_c2=" .. tostring(fin_c2) .. " raw=" .. json.encode(list.colors or {}))
        end

        if list.performance then
            applyPerformance(veh, list.performance)
            local capturedVeh = veh
            CreateThread(function()
                Wait(1500)
                if DoesEntityExist(capturedVeh) then
                    if list.performance == 'max' then
                        applyPerformance(capturedVeh, 'max')
                    end
                    -- Apply colours HERE, after the final SetVehicleModKit call,
                    -- so nothing can reset them afterwards.
                    if wantColours then
                        SetVehicleColours(capturedVeh, fin_c1, fin_c2)
                    end
                end
            end)
        end

        -- Visual upgrades (applyVisualUpgrades calls SetVehicleModKit internally)
        if list.visualUpgrades then applyVisualUpgrades(veh, list.visualUpgrades) end

        -- Extras (no modkit, safe anytime)
        if list.extras then
            for extra, enabled in pairs(list.extras) do
                SetVehicleExtra(veh, tonumber(extra), enabled == false)
            end
        end

        -- ── Step 2: colours ─────────────────────────────────────────────────────
        -- Apply immediately at spawn. The delayed performance thread above will
        -- re-apply after its SetVehicleModKit call at 1500ms.
        if wantColours then
            SetVehicleColours(veh, fin_c1, fin_c2)
        end

        if list.windowTint then
            local maxRetries = 3
            local tintApplied = false
            for i = 1, maxRetries do
                SetVehicleWindowTint(veh, list.windowTint)
                Wait(500)
                if GetVehicleWindowTint(veh) == list.windowTint then
                    tintApplied = true
                    break
                end
            end
            if not tintApplied then
                if Config.Notify == "qb" then
                    QBCore.Functions.Notify("Error: Failed to apply window tint", "error")
                elseif Config.Notify == "ox" then
                    lib.notify({ title = 'Error', description = 'Failed to apply window tint', type = 'error' })
                end
            end
        end

        if list.trunkItems then
            Wait(500)
            TriggerServerEvent("mnc-jobgarage:server:addTrunkItems", cleanPlate, list.trunkItems)
        end

        SetPedIntoVehicle(PlayerPedId(), veh, -1)

        if Config.Fuel and exports[Config.Fuel] then
            exports[Config.Fuel]:SetFuel(veh, 100.0)
        else
            SetVehicleFuelLevel(veh, 90.0)
        end

        SetVehicleEngineOn(veh, true, true)
        currentVeh.out  = true
        currentVeh.name = list.CustomName or GetDisplayNameFromVehicleModel(GetHashKey(spawnName))

        if Config.Notify == "qb" then
            QBCore.Functions.Notify("Vehicle Spawned: " .. currentVeh.name .. " [" .. cleanPlate .. "]", "success")
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Vehicle Spawned', description = currentVeh.name .. ' [' .. cleanPlate .. ']', type = 'success' })
        end

        local netVeh = NetworkGetNetworkIdFromEntity(veh)
        local colorsTable = wantColours and { fin_c1 or 0, fin_c2 or 0 } or nil
        TriggerServerEvent("mnc-jobgarage:server:trackVehicle", netVeh, cleanPlate, currentVeh.name, colorsTable)

        -- Checkout lock: mark this vehicle as signed out for this garage.
        -- We use garageId (not raw job) so two garages for the same job have
        -- independent checkout states. Unlimited vehicles skip the lock.
        currentVeh.model     = spawnName
        currentVeh.job       = data.garageId or (pulloutCtx and pulloutCtx.garageId) or (pulloutCtx and pulloutCtx.job) or nil
        currentVeh.unlimited = pulloutCtx and pulloutCtx.list and pulloutCtx.list[spawnName] and pulloutCtx.list[spawnName].unlimited == true or false
        if currentVeh.job and currentVeh.model and not currentVeh.unlimited then
            TriggerServerEvent("mnc-jobgarage:server:checkoutVehicle", currentVeh.job, currentVeh.model, cleanPlate, netVeh)
        end

        CreateThread(function()
            for i = 1, 5 do
                Wait(2000)
                if DoesEntityExist(veh) and list.windowTint then
                    SetVehicleWindowTint(veh, list.windowTint)
                else
                    break
                end
            end
            Wait(1000)
            if DoesEntityExist(veh) and list.windowTint then
                local currentTint = GetVehicleWindowTint(veh)
                if currentTint ~= list.windowTint then
                    if Config.Notify == "qb" then
                        QBCore.Functions.Notify("Error: Window tint not applied correctly", "error")
                    elseif Config.Notify == "ox" then
                        lib.notify({ title = 'Error', description = 'Window tint not applied correctly', type = 'error' })
                    end
                end
                local anyWindowIntact = false
                for i = 0, 7 do if IsVehicleWindowIntact(veh, i) then anyWindowIntact = true end end
                if not anyWindowIntact then
                    if Config.Notify == "qb" then
                        QBCore.Functions.Notify("Warning: Vehicle has no intact windows, tint may not be visible", "warning")
                    elseif Config.Notify == "ox" then
                        lib.notify({ title = 'Warning', description = 'Vehicle has no intact windows, tint may not be visible', type = 'warning' })
                    end
                end
            end
        end)
    end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Remove Vehicle (original, preserved exactly)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent("mnc-jobgarage:client:RemSpawn", function(data)
    if not currentVeh.current or not DoesEntityExist(currentVeh.current) then
        if Config.Notify == "qb" then
            QBCore.Functions.Notify("Error: No vehicle to return", "error")
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Error', description = 'No vehicle to return', type = 'error' })
        end
        return
    end

    if Config.ReturnDistanceCheck then
        local returnRadius = Config.ReturnRadius or 15.0
        local vehPos  = GetEntityCoords(currentVeh.current)
        local returnPos = vector3(data.returncoords.x, data.returncoords.y, data.returncoords.z)
        if #(vehPos - returnPos) > returnRadius then
            if Config.Notify == "qb" then
                QBCore.Functions.Notify("Error: Vehicle must be within " .. returnRadius .. " meters of the garage", "error")
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Error', description = 'Vehicle must be within ' .. returnRadius .. ' meters of the garage', type = 'error' })
            end
            return
        end
    end

    local netVeh = NetworkGetNetworkIdFromEntity(currentVeh.current)
    TriggerServerEvent("mnc-jobgarage:server:removeVehicle", netVeh)

    if Config.CarDespawn then
        SetVehicleEngineHealth(currentVeh.current, 200.0)
        SetVehicleBodyHealth(currentVeh.current, 200.0)
        for i = 0, 7 do SmashVehicleWindow(currentVeh.current, i) Wait(150) end
        PopOutVehicleWindscreen(currentVeh.current)
        for i = 0, 5 do SetVehicleTyreBurst(currentVeh.current, i, true, 0) Wait(150) end
        for i = 0, 5 do SetVehicleDoorBroken(currentVeh.current, i, false) Wait(150) end
        Wait(800)
    end
    DeleteVehicle(currentVeh.current)

    -- Checkout lock: release vehicle so others can take it
    if currentVeh.job and currentVeh.model and not currentVeh.unlimited then
        TriggerServerEvent("mnc-jobgarage:server:returnVehicle", currentVeh.job, currentVeh.model)
    end

    currentVeh = { out = false, current = nil, name = nil, model = nil, job = nil, unlimited = false }

    if Config.Notify == "qb" then
        QBCore.Functions.Notify("Vehicle Returned", "success")
    elseif Config.Notify == "ox" then
        lib.notify({ title = 'Vehicle Returned', type = 'success' })
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Vehicle Blip (original, preserved exactly)
-- ─────────────────────────────────────────────────────────────────────────────
local markerOn  = false
local garageBlip = nil

RegisterNetEvent("mnc-jobgarage:client:Garage:Blip", function()
    if not currentVeh.current or not DoesEntityExist(currentVeh.current) then
        if Config.Notify == "qb" then
            QBCore.Functions.Notify("Error: No vehicle to mark", "error")
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Error', description = 'No vehicle to mark', type = 'error' })
        end
        return
    end

    if markerOn then
        markerOn = false
        if DoesBlipExist(garageBlip) then
            RemoveBlip(garageBlip)
            garageBlip = nil
            if Config.Notify == "qb" then
                QBCore.Functions.Notify("Blip Removed", "success")
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Blip Removed', type = 'success' })
            end
        end
    else
        markerOn = true
        garageBlip = AddBlipForEntity(currentVeh.current)
        SetBlipSprite(garageBlip, 85)
        SetBlipColour(garageBlip, 8)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Job Vehicle")
        EndTextCommandSetBlipName(garageBlip)
        SetBlipRoute(garageBlip, true)
        SetBlipRouteColour(garageBlip, 3)

        if Config.Notify == "qb" then
            QBCore.Functions.Notify("Blip Created: Vehicle location marked on map", "success")
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Blip Created', description = 'Vehicle location marked on map', type = 'success' })
        end

        CreateThread(function()
            while markerOn do
                local time = 5000
                if DoesEntityExist(currentVeh.current) then
                    local carLoc    = GetEntityCoords(currentVeh.current)
                    local playerLoc = GetEntityCoords(PlayerPedId())
                    local dist = #(carLoc - playerLoc)
                    if dist <= 30.0 and dist > 1.5 then
                        time = 1000
                    elseif dist <= 1.5 then
                        RemoveBlip(garageBlip)
                        garageBlip = nil
                        markerOn = false
                        if Config.Notify == "qb" then
                            QBCore.Functions.Notify("Blip Removed: Vehicle is nearby", "success")
                        elseif Config.Notify == "ox" then
                            lib.notify({ title = 'Blip Removed', description = 'Vehicle is nearby', type = 'success' })
                        end
                    end
                else
                    RemoveBlip(garageBlip)
                    garageBlip = nil
                    markerOn = false
                    if Config.Notify == "qb" then
                        QBCore.Functions.Notify("Blip Removed: Vehicle no longer exists", "error")
                    elseif Config.Notify == "ox" then
                        lib.notify({ title = 'Blip Removed', description = 'Vehicle no longer exists', type = 'error' })
                    end
                end
                Wait(time)
            end
        end)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  /printmyveh command (original, preserved exactly)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterCommand('printmyveh', function()
    local ped = PlayerPedId()
    if not ped or not DoesEntityExist(ped) then return end
    if not IsPedInAnyVehicle(ped, false) then
        local msg = "You must be in a vehicle to use this command!"
        if Config.Notify == "qb" then QBCore.Functions.Notify(msg, "error")
        elseif Config.Notify == "ox" then lib.notify({ title = 'Error', description = msg, type = 'error' })
        else print("[printmyveh] " .. msg) end
        return
    end
    local veh = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(veh) or not IsVehicleDriveable(veh, false) then
        print("[printmyveh] ERROR: Vehicle entity not valid") return
    end
    local model = GetEntityModel(veh)
    local modelName = GetDisplayNameFromVehicleModel(model) or "Unknown"
    if modelName == "CARNOTFOUND" or modelName == "" then
        modelName = "Custom_" .. string.format("%x", model):upper()
    end
    local plate = GetVehicleNumberPlateText(veh) or "UNKNOWN"
    plate = plate:gsub("^%s*(.-)%s*$", "%1")
    local primary, secondary = GetVehicleColours(veh)
    primary = primary or 0; secondary = secondary or 0
    local windowTint = GetVehicleWindowTint(veh)
    if windowTint == -1 or windowTint == 0 then windowTint = nil end
    local livery = GetVehicleLivery(veh)
    if livery == 0 then livery = nil end
    local extras = {}; local hasExtras = false
    for i = 1, 14 do
        if DoesExtraExist(veh, i) then
            extras[tostring(i)] = not IsVehicleExtraTurnedOn(veh, i)
            hasExtras = true
        end
    end
    if not hasExtras then extras = nil end
    local perf = {}
    perf.engine       = GetVehicleMod(veh, 11) + 1
    perf.brakes       = GetVehicleMod(veh, 12) + 1
    perf.transmission = GetVehicleMod(veh, 13) + 1
    perf.suspension   = GetVehicleMod(veh, 15) + 1
    perf.turbo        = IsToggleModOn(veh, 18)
    local maxPerf = true
    for _, modType in ipairs({11,12,13,15}) do
        if GetVehicleMod(veh, modType) + 1 < GetNumVehicleMods(veh, modType) then maxPerf = false break end
    end
    if maxPerf and perf.turbo then perf = "max"
    else perf = {perf.engine, perf.brakes, perf.transmission, perf.suspension, perf.turbo} end
    local visual = {}
    local interestingMods = { spoiler=0, frontBumper=1, rearBumper=2, sideSkirt=3, exhaust=4, hood=7, fender=8, rightFender=9, roof=10, wheels=23, wheelType=24, xenon=22 }
    for name, modType in pairs(interestingMods) do
        local index = GetVehicleMod(veh, modType)
        if index >= 0 then visual[name] = index end
    end
    if IsToggleModOn(veh, 17) then
        local r, g, b = GetVehicleNeonLightsColour(veh)
        local layout = 0
        for i = 0, 3 do if IsVehicleNeonLightEnabled(veh, i) then layout = layout + (2 ^ i) end end
        if layout > 0 then visual.neon = { enabled = true, color = {r, g, b}, layout = layout } end
    end
    local config = { CustomName = modelName .. " (Generated)", colors = (primary ~= 0 or secondary ~= 0) and {primary, secondary} or nil, windowTint = windowTint, livery = livery, extras = extras, performance = perf, visualUpgrades = next(visual) ~= nil and visual or nil }
    print(string.rep("=", 60))
    print(" Ready-to-paste vehicle configuration")
    print(string.rep("-", 60))
    print(("Model: %-20s | Plate: %s"):format(modelName, plate))
    print(" ")
    local modelKey = modelName:lower():gsub("[^%w]", "_")
    print("[\"" .. modelKey .. "\"] = {")
    if config.CustomName then print("    CustomName = \"" .. config.CustomName:gsub("\"", "\\\"") .. "\",") end
    if config.colors then print("    colors = {" .. config.colors[1] .. ", " .. config.colors[2] .. "},") end
    if config.windowTint then print("    windowTint = " .. config.windowTint .. ",") end
    if config.livery then print("    livery = " .. config.livery .. ",") end
    if config.extras then
        print("    extras = {")
        for k, v in pairs(config.extras) do print("        [" .. k .. "] = " .. tostring(v) .. ",") end
        print("    },")
    end
    if type(config.performance) == "string" then print("    performance = \"max\",")
    elseif type(config.performance) == "table" then print("    performance = { " .. table.concat(config.performance, ", ") .. " },") end
    if config.visualUpgrades then
        print("    visualUpgrades = {")
        for k, v in pairs(config.visualUpgrades) do
            if type(v) == "table" then
                print("        " .. k .. " = { enabled = true, color = {" .. table.concat(v.color, ", ") .. "}, layout = " .. (v.layout or 0) .. " },")
            else print("        " .. k .. " = " .. v .. ",") end
        end
        print("    },")
    end
    print("},")
    print(" ")
    print("Tip: You can change the model key and CustomName as needed.")
    print(string.rep("=", 60))
    local successMsg = "Vehicle config printed to F8 console!"
    if Config.Notify == "qb" then QBCore.Functions.Notify(successMsg, "success")
    elseif Config.Notify == "ox" then lib.notify({ title = 'Success', description = successMsg, type = 'success' }) end
end, false)

-- ─────────────────────────────────────────────────────────────────────────────
--  Setup Mode  ──  walk to a spot, press a key, get an exact vec4
--  Captures two points in sequence: the "Out" (target prop / interaction) point,
--  then the "Spawn" point — matching Config.Locations[i].garage.{out, spawn}.
-- ─────────────────────────────────────────────────────────────────────────────
local setupMode = { active = false, step = nil, out = nil, spawn = nil }

local function round2(n)
    return math.floor((n * 100) + 0.5) / 100
end

local function setupVec(ped)
    local c = GetEntityCoords(ped)
    return { x = round2(c.x), y = round2(c.y), z = round2(c.z), w = round2(GetEntityHeading(ped)) }
end

local function setupSendHud()
    SendNUIMessage({ action = 'setupHud', step = setupMode.step, coords = setupVec(PlayerPedId()) })
end

local function startSetupMode()
    if setupMode.active then return end
    setupMode.active = true
    setupMode.step   = 'out'
    setupMode.out    = nil
    setupMode.spawn  = nil

    SendNUIMessage({ action = 'setupOpen' })

    CreateThread(function()
        while setupMode.active do
            setupSendHud()
            Wait(100)
        end
    end)
end

local function cancelSetupMode()
    if not setupMode.active then return end
    setupMode.active = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setupClose' })
end

local function confirmSetupPoint()
    if not setupMode.active then return end
    local vec = setupVec(PlayerPedId())

    if setupMode.step == 'out' then
        setupMode.out  = vec
        setupMode.step = 'spawn'
        SendNUIMessage({ action = 'setupCaptured', which = 'out', vec = vec })

    elseif setupMode.step == 'spawn' then
        setupMode.spawn  = vec
        setupMode.step   = 'done'
        setupMode.active = false -- stops the HUD-update thread; NUI keeps the result panel open
        SendNUIMessage({ action = 'setupDone', out = setupMode.out, spawn = setupMode.spawn })
        SetNuiFocus(true, true) -- player needs the mouse to click Apply / Copy / Close now
    end
end

-- Quick-access command. Restricted (3rd arg = true) so it requires the
-- "command.garagesetup" ACE permission — grant it in server.cfg, e.g.:
--   add_ace group.admin command.garagesetup allow
RegisterCommand('garagesetup', function()
    startSetupMode()
end, true)

-- Default keybinds — players can rebind these under Settings > Key Bindings > FiveM
RegisterKeyMapping('garagesetup_confirm', 'Job Garage Setup: Confirm Point', 'keyboard', 'RETURN')
RegisterCommand('garagesetup_confirm', function()
    if setupMode.active then confirmSetupPoint() end
end, false)

RegisterKeyMapping('garagesetup_cancel', 'Job Garage Setup: Cancel Setup Mode', 'keyboard', 'BACK')
RegisterCommand('garagesetup_cancel', function()
    if setupMode.active then cancelSetupMode() end
end, false)

-- Launched from the "Setup Mode" button inside the Admin UI's Garages tab —
-- already gated by whatever permission check guards opening that panel.
RegisterNUICallback('startSetup', function(_, cb)
    SetNuiFocus(false, false)
    startSetupMode()
    cb('ok')
end)

RegisterNUICallback('setupClose', function(_, cb)
    cancelSetupMode()
    cb('ok')
end)

RegisterNUICallback('setupApply', function(data, cb)
    setupMode = { active = false, step = nil, out = nil, spawn = nil }
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openGarageFormWithCoords', out = data and data.out, spawn = data and data.spawn })
    cb('ok')
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Admin UI  ──  open NUI panel
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mnc-jobgarage:client:openAdminUI', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end)

RegisterCommand('jobgarageadmin', function()
    TriggerServerEvent('mnc-jobgarage:server:openAdmin')
end, false)

RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ── NUI → server lib.callback bridge ─────────────────────────────
-- Each nuiPost action maps to a server-side lib.callback

RegisterNUICallback('getAdminData', function(_, cb)
    local result = lib.callback.await('mnc-jobgarage:cb:getAdminData', false)
    cb(result or {})
end)

RegisterNUICallback('saveGarage', function(data, cb)
    local ok = lib.callback.await('mnc-jobgarage:cb:saveGarage', false, data)
    cb(ok)
end)

RegisterNUICallback('deleteGarage', function(data, cb)
    local ok = lib.callback.await('mnc-jobgarage:cb:deleteGarage', false, data.job)
    cb(ok)
end)

RegisterNUICallback('saveVehicle', function(data, cb)
    local ok = lib.callback.await('mnc-jobgarage:cb:saveVehicle', false, data)
    cb(ok)
end)

RegisterNUICallback('deleteVehicle', function(data, cb)
    local ok = lib.callback.await('mnc-jobgarage:cb:deleteVehicle', false, data)
    cb(ok)
end)

RegisterNUICallback('restoreVehicle', function(data, cb)
    local ok = lib.callback.await('mnc-jobgarage:cb:restoreVehicle', false, data)
    cb(ok)
end)

RegisterNUICallback('saveRole', function(data, cb)
    local ok = lib.callback.await('mnc-jobgarage:cb:saveRole', false, data)
    cb(ok)
end)

RegisterNUICallback('deleteRole', function(data, cb)
    local ok = lib.callback.await('mnc-jobgarage:cb:deleteRole', false, data)
    cb(ok)
end)

RegisterNUICallback('assignPlayerRole', function(data, cb)
    local ok = lib.callback.await('mnc-jobgarage:cb:assignPlayerRole', false, data)
    cb(ok)
end)

RegisterNUICallback('removePlayerRole', function(data, cb)
    local ok = lib.callback.await('mnc-jobgarage:cb:removePlayerRole', false, data)
    cb(ok)
end)


-- ─────────────────────────────────────────────────────────────────────────────
--  NUI callbacks: getMyId, lookupPlayerId, batchUpdateVehicleOrder
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNUICallback('getMyId', function(_, cb)
    local result = lib.callback.await('mnc-jobgarage:cb:getMyId', false)
    cb(result or {})
end)

RegisterNUICallback('lookupPlayerId', function(data, cb)
    local result = lib.callback.await('mnc-jobgarage:cb:lookupPlayerId', false, data)
    cb(result or {})
end)

RegisterNUICallback('batchUpdateVehicleOrder', function(data, cb)
    local result = lib.callback.await('mnc-jobgarage:cb:batchUpdateVehicleOrder', false, data)
    cb(result)
end)

-- Returns the number of liveries a model has (0 = none / no liveries available).
-- Called by the NUI vehicle form when the model field changes so the livery input
-- can show the valid range or "none available" to the admin.
RegisterNUICallback('getLiveryCount', function(data, cb)
    if not data or not data.model or data.model == '' then
        cb({ count = 0, liveries = {} })
        return
    end
    local hash = GetHashKey(data.model)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) do
        Wait(100)
        t = t + 1
        if t > 30 then cb({ count = 0, liveries = {} }) return end  -- 3 s timeout
    end

    -- Spawn a local (non-networked) ghost vehicle well above the player
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local ghost = CreateVehicle(hash, pos.x, pos.y, pos.z + 120.0, 0.0, false, true)
    SetEntityVisible(ghost, false, false)
    FreezeEntityPosition(ghost, true)
    SetEntityCollision(ghost, false, false)

    -- SetVehicleModKit is required before GetVehicleLiveryCount returns a
    -- meaningful value on base-game vehicles; without it the native returns -1.
    SetVehicleModKit(ghost, 0)
    Wait(0)  -- yield one frame so the mod kit attaches

    -- GTA has two livery systems:
    --   1. GetVehicleLiveryCount  / SetVehicleLivery   (older vehicles, e.g. police)
    --   2. GetNumVehicleMods(veh, 48)                  (newer vehicles using the mod slot)
    -- We check both and use whichever gives a positive result.
    local liveryCount  = GetVehicleLiveryCount(ghost)
    local modCount     = GetNumVehicleMods(ghost, 48)  -- mod slot 48 = livery

    local useModSlot = false
    local count = 0

    if liveryCount and liveryCount > 0 then
        count = liveryCount
    elseif modCount and modCount > 0 then
        count = modCount
        useModSlot = true
    end

    -- Build livery name list
    local liveries = {}
    if count > 0 then
        for i = 0, count - 1 do
            local gxtLabel
            if useModSlot then
                gxtLabel = GetModTextLabel(ghost, 48, i)
            else
                gxtLabel = GetLiveryName(ghost, i)
            end
            local name = (gxtLabel and gxtLabel ~= '' and gxtLabel ~= 'NULL')
                and GetLabelText(gxtLabel)
                or ('Livery ' .. i)
            -- GetLabelText returns '~' on failure (no label found)
            if name == '~' or name == '' then name = 'Livery ' .. i end
            liveries[#liveries + 1] = { index = i, name = name }
        end
    end

    DeleteVehicle(ghost)
    SetModelAsNoLongerNeeded(hash)
    cb({ count = count, liveries = liveries })
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  In-job role management (grade 4+) — from pullout NUI
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNUICallback('getJobRolesForPullout', function(_, cb)
    local result = lib.callback.await('mnc-jobgarage:cb:getJobRolesForPullout', false)
    cb(result or {})
end)

RegisterNUICallback('jobAssignRole', function(data, cb)
    local ok = lib.callback.await('mnc-jobgarage:cb:jobAssignRole', false, data)
    cb(ok)
end)

RegisterNUICallback('jobRemoveRole', function(data, cb)
    local ok = lib.callback.await('mnc-jobgarage:cb:jobRemoveRole', false, data)
    cb(ok)
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Checkout lock: live update from server → forward to NUI
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mnc-jobgarage:client:checkoutUpdated', function(job, model, isOut, playerName)
    SendNUIMessage({
        action     = 'checkoutUpdated',
        job        = job,
        model      = model,
        isOut      = isOut,
        playerName = playerName,
    })
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Cleanup on Resource Stop (original, preserved exactly)
-- ─────────────────────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        removeTargets()
        if setupMode.active then
            setupMode.active = false
        end
        if currentVeh.out and DoesEntityExist(currentVeh.current) then
            local netVeh = NetworkGetNetworkIdFromEntity(currentVeh.current)
            TriggerServerEvent("mnc-jobgarage:server:removeVehicle", netVeh)
            if currentVeh.job and currentVeh.model and not currentVeh.unlimited then
                TriggerServerEvent("mnc-jobgarage:server:returnVehicle", currentVeh.job, currentVeh.model)
            end
            DeleteVehicle(currentVeh.current)
            currentVeh = { out = false, current = nil, name = nil, model = nil, job = nil, unlimited = false }
        end
        if DoesBlipExist(garageBlip) then
            RemoveBlip(garageBlip)
            garageBlip = nil
            markerOn = false
        end
    end
end)