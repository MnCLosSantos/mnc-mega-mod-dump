local QBCore = exports['qb-core']:GetCoreObject()

-- Holds spawn data while waiting for server plate check response
local pendingSpawn = nil

-- ── QBCore admin permission check ─────────────────────────────────────────────
local function isQBAdmin()
    return QBCore.Functions.HasPermission('admin')
end

-- Generate a random plate locally
local function generateLocalPlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local t = GetGameTimer() % 10000
    local plate = string.format('%04d', t)
    for i = 1, 4 do
        local idx = math.random(1, #chars)
        plate = plate .. chars:sub(idx, idx)
    end
    return plate:sub(1, 8)
end

-- Fetch vehicle models from qb-core shared
local function fetchVehicleModels()
    local categorizedVehicles = {}
    for model, data in pairs(QBShared.Vehicles) do
        local className = data.category or "Unknown"
        if not categorizedVehicles[className] then
            categorizedVehicles[className] = {}
        end
        table.insert(categorizedVehicles[className], {
            model = model,
            name = data.name,
            price = data.price,
            category = className,
            brand = data.brand or "Unknown",
        })
    end
    SendNUIMessage({
        type = 'setVehicleModels',
        models = categorizedVehicles,
        uiStyle = Config.UIStyles[Config.UIStyle],
        imagePaths = Config.ImagePaths,
        title = "Vehicle Spawner"
    })
end

-- The actual spawn logic, called after plate is confirmed
local function doSpawnVehicle(spawnData)
    local model        = spawnData.model
    local finalPlate   = spawnData.finalPlate
    local performance  = spawnData.performanceMods
    local randomVisual = spawnData.randomVisualMods
    local ownVehicle   = spawnData.ownVehicle
    local colours      = spawnData.colours
    local mods         = spawnData.mods
    local wheelData    = spawnData.wheelData
    local plateStyle   = spawnData.plateStyle

    local hash = joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        local oldVeh = GetVehiclePedIsIn(ped, false)
        TaskLeaveVehicle(ped, oldVeh, 16)
        Wait(500)
        DeleteVehicle(oldVeh)
    end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 5.0, 0)
    if not foundGround then groundZ = coords.z end

    local vehicle = CreateVehicle(hash, coords.x, coords.y, groundZ + 0.5, heading, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNumberPlateText(vehicle, finalPlate)

    if Config.Warp then SetPedIntoVehicle(ped, vehicle, -1) end

    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleEngineOn(vehicle, true, true, false)

    -- Keys
    if Config.Keys == 'qb' then
        TriggerEvent("vehiclekeys:client:SetOwner", finalPlate)
    elseif Config.Keys == 'qbx' then
        TriggerEvent("qb-vehiclekeys:client:SetOwner", finalPlate)
    end

    -- Fuel
    local fuelSystems = {
        ['legacy']     = function(veh) exports['LegacyFuel']:SetFuel(veh, 100.0) end,
        ['cdn']        = function(veh) exports['cdn-fuel']:SetFuel(veh, 100.0) end,
        ['ox']         = function(veh) Entity(veh).state.fuel = 100.0 end,
        ['standalone'] = function(veh) SetVehicleFuelLevel(veh, 100.0) end,
    }
    if fuelSystems[Config.Fuel] then fuelSystems[Config.Fuel](vehicle) end

    -- Colours (paint index based)
    SetVehicleModKit(vehicle, 0)
    if colours then
        if colours.primary ~= nil and colours.primary >= 0 then
            local sec = colours.secondary ~= nil and colours.secondary >= 0 and colours.secondary or colours.primary
            SetVehicleColours(vehicle, colours.primary, sec)
        end
        if colours.pearlescent ~= nil and colours.pearlescent >= 0 and colours.wheel ~= nil and colours.wheel >= 0 then
            SetVehicleExtraColours(vehicle, colours.pearlescent, colours.wheel)
        end
        if colours.interior ~= nil and colours.interior >= 0 then
            local max = GetNumVehicleMods(vehicle, 22)
            if max > 0 and colours.interior < max then SetVehicleMod(vehicle, 22, colours.interior, false) end
        end
        if colours.dashboard ~= nil and colours.dashboard >= 0 then
            local max = GetNumVehicleMods(vehicle, 23)
            if max > 0 and colours.dashboard < max then SetVehicleMod(vehicle, 23, colours.dashboard, false) end
        end
        if colours.livery ~= nil and colours.livery >= 0 then
            local max = GetNumVehicleMods(vehicle, 14)
            if max > 0 and colours.livery < max then SetVehicleMod(vehicle, 14, colours.livery, false) end
        end
        if colours.liveryMod48 ~= nil and colours.liveryMod48 >= 0 then
            local mod48Count = GetNumVehicleMods(vehicle, 48)
            local nativeCount = GetVehicleLiveryCount(vehicle)
            if mod48Count == 0 and nativeCount > 0 then
                SetVehicleLivery(vehicle, colours.liveryMod48)
            elseif mod48Count > 0 and colours.liveryMod48 < mod48Count then
                SetVehicleMod(vehicle, 48, colours.liveryMod48, false)
            end
        end
        if colours.windowTint ~= nil then
            SetVehicleWindowTint(vehicle, colours.windowTint)
        end
    end

    -- Manual mods (from mod dropdowns)
    if mods then
        for modId, modIndex in pairs(mods) do
            local id = tonumber(modId)
            if id and modIndex ~= nil then
                if id == 18 then
                    -- Turbo is a toggle
                    ToggleVehicleMod(vehicle, 18, modIndex == 1)
                else
                    local max = GetNumVehicleMods(vehicle, id)
                    if modIndex == -1 or (max > 0 and modIndex < max) then
                        SetVehicleMod(vehicle, id, modIndex, false)
                    end
                end
            end
        end
    end

    -- Performance mods
    if performance then
        local perfMods = { [11]=true, [12]=true, [13]=true, [15]=true, [16]=true, [18]=true }
        for modType, _ in pairs(perfMods) do
            if modType == 18 then
                ToggleVehicleMod(vehicle, 18, true)
            else
                local max = GetNumVehicleMods(vehicle, modType)
                if max > 0 then SetVehicleMod(vehicle, modType, max - 1, false) end
            end
        end
    end

    -- Random visual mods -- build a shuffled list of eligible slots first
    -- so application order varies every spawn and results are never the same
    if randomVisual then
        local skipMods = { [11]=true, [12]=true, [13]=true, [15]=true, [16]=true, [18]=true }

        local eligibleSlots = {}
        for i = 0, 48 do
            if not skipMods[i] then
                table.insert(eligibleSlots, i)
            end
        end

        -- Fisher-Yates shuffle seeded from game timer + extra entropy
        math.randomseed(GetGameTimer() + math.random(1, 99999))
        for i = #eligibleSlots, 2, -1 do
            local j = math.random(1, i)
            eligibleSlots[i], eligibleSlots[j] = eligibleSlots[j], eligibleSlots[i]
        end

        for _, modType in ipairs(eligibleSlots) do
            local max = GetNumVehicleMods(vehicle, modType)
            if max > 0 then
                SetVehicleMod(vehicle, modType, math.random(-1, max - 1), false)
            end
        end
    end

    SetModelAsNoLongerNeeded(hash)

    -- Plate style
    if plateStyle ~= nil then
        SetVehicleNumberPlateTextIndex(vehicle, plateStyle)
    end

    -- Wheel type, rims, bulletproof tyres, tyre smoke (from Wheels & Tyres tab)
    if wheelData then
        if wheelData.wheelType ~= nil then
            SetVehicleWheelType(vehicle, wheelData.wheelType)
            Wait(50)
        end
        if wheelData.frontWheelIdx ~= nil then
            local maxW = GetNumVehicleMods(vehicle, 23)
            if wheelData.frontWheelIdx == -1 or (maxW > 0 and wheelData.frontWheelIdx < maxW) then
                SetVehicleMod(vehicle, 23, wheelData.frontWheelIdx, false)
            end
        end
        if wheelData.backWheelIdx ~= nil then
            local maxBW = GetNumVehicleMods(vehicle, 24)
            if maxBW > 0 then
                if wheelData.backWheelIdx == -1 or wheelData.backWheelIdx < maxBW then
                    SetVehicleMod(vehicle, 24, wheelData.backWheelIdx, false)
                end
            end
        end
        if wheelData.bulletproofTyres then
            SetVehicleTyresCanBurst(vehicle, false)
        end
        if wheelData.tyreSmoke ~= nil then
            ToggleVehicleMod(vehicle, 20, wheelData.tyreSmoke)
            if wheelData.tyreSmoke and wheelData.smokeColor then
                SetVehicleTyreSmokeColor(vehicle, wheelData.smokeColor.r, wheelData.smokeColor.g, wheelData.smokeColor.b)
            end
        end
    end

    -- Ownership
    if ownVehicle then
        TriggerServerEvent('mnc-vehiclespawner:saveVehicle', finalPlate, model)
    end
end

-- NUI callback: load model briefly to read actual livery mod counts, names, and all mod slot counts
RegisterNUICallback("requestLiveryData", function(data, cb)
    if not data.model then cb("error") return end

    local hash = joaat(data.model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then cb("timeout") return end
    end

    -- Spawn a temporary invisible vehicle off to the side to query its mods
    local coords = GetEntityCoords(PlayerPedId())
    local tempVeh = CreateVehicle(hash, coords.x, coords.y + 100, coords.z, 0.0, false, false)
    SetVehicleModKit(tempVeh, 0)

    -- GTA V has two livery systems:
    --   mod48  – tuning-based liveries (GetNumVehicleMods slot 48), used by most addon/DLC vehicles
    --   native – SetVehicleLivery/GetVehicleLiveryCount, used by base game vehicles (police, taxi, etc.)
    -- If mod48 count > 0 the vehicle uses the mod system; otherwise fall back to native.
    local mod48Count    = GetNumVehicleMods(tempVeh, 48)
    local nativeCount   = GetVehicleLiveryCount(tempVeh)
    local useNative     = (mod48Count == 0 and nativeCount > 0)

    local mod14Names = {}
    local mod48Names = {}

    if useNative then
        for i = 0, nativeCount - 1 do
            local liveryName = GetLiveryName(tempVeh, i)
            local name = ''
            if liveryName and liveryName ~= '' then
                local label = GetLabelText(liveryName)
                if label and label ~= 'NULL' and label ~= '' then
                    name = label
                end
            end
            if name == '' then name = 'Livery ' .. (i + 1) end
            table.insert(mod48Names, name)
        end
    elseif mod48Count > 0 then
        for i = 0, mod48Count - 1 do
            local label = GetModTextLabel(tempVeh, 48, i)
            local name  = (label ~= '' and GetLabelText(label) or '')
            if name == 'NULL' or name == '' then name = 'Livery ' .. (i + 1) end
            table.insert(mod48Names, name)
        end
    end

    -- Collect mod data for all UI slots: { count, names[] }
    -- Performance slots: 11 engine, 12 brakes, 13 transmission, 15 suspension, 16 armor, 18 turbo
    -- Visual slots: all others used by the UI
    local allModSlots = { 0,1,2,3,4,5,6,7,8,9,10,11,12,13,15,16,18,19,21,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,49 }
    local modData = {}
    for _, slotId in ipairs(allModSlots) do
        if slotId == 18 then
            -- Turbo is a toggle mod, not indexed
            modData[tostring(slotId)] = { count = 1, names = { 'Turbo' }, isToggle = true }
        else
            local count = GetNumVehicleMods(tempVeh, slotId)
            if count > 0 then
                local names = {}
                for i = 0, count - 1 do
                    local labelKey = GetModTextLabel(tempVeh, slotId, i)
                    local name = (labelKey ~= '' and GetLabelText(labelKey) or '')
                    if name == 'NULL' or name == '' then
                        name = 'Option ' .. (i + 1)
                    end
                    table.insert(names, name)
                end
                modData[tostring(slotId)] = { count = count, names = names, isToggle = false }
            end
        end
    end

    DeleteVehicle(tempVeh)
    SetModelAsNoLongerNeeded(hash)

    SendNUIMessage({
        action    = 'liveryData',
        mod14     = mod14Names,
        mod48     = mod48Names,
        useNative = useNative,
    })

    SendNUIMessage({
        action = 'modData',
        mods   = modData,
    })

    -- Send vehicle class info for rim UI
    local tempVeh2 = CreateVehicle(hash, coords.x, coords.y + 100, coords.z, 0.0, false, false)
    local vClass = GetVehicleClass(tempVeh2)
    local spawnIsBike = (vClass == 8 or vClass == 13)
    local spawnWheelCount = GetNumVehicleMods(tempVeh2, 23)
    local spawnBackWheelCount = GetNumVehicleMods(tempVeh2, 24)
    DeleteVehicle(tempVeh2)

    SendNUIMessage({
        action         = 'spawnWheelMeta',
        isBike         = spawnIsBike,
        wheelCount     = spawnWheelCount,
        backWheelCount = spawnBackWheelCount,
    })

    cb("ok")
end)

-- NUI callback: stash data and ask server to check plate (always, including auto-generated)
RegisterNUICallback("spawnVehicle", function(data, cb)
    if not data.model then cb("error") return end

    local customPlate = data.customPlate
    local finalPlate

    if customPlate and customPlate ~= '' then
        finalPlate = customPlate:upper():gsub('%s+', ''):sub(1, 8)
    else
        finalPlate = generateLocalPlate()
    end

    -- Always store pending spawn and ask server to validate — no more skipping the check
    pendingSpawn = {
        model            = data.model,
        finalPlate       = finalPlate,
        performanceMods  = data.performanceMods,
        randomVisualMods = data.randomVisualMods,
        ownVehicle       = data.ownVehicle,
        colours          = data.colours,
        mods             = data.mods,
        wheelData        = data.wheelData,
        plateStyle       = data.plateStyle,
        isCustomPlate    = (customPlate and customPlate ~= ''),
    }
    TriggerServerEvent('mnc-vehiclespawner:checkPlate', finalPlate)

    cb("ok")
end)

-- Server responds: plate is free — proceed with spawn
RegisterNetEvent('mnc-vehiclespawner:plateFree', function()
    if not pendingSpawn then return end
    local spawnData = pendingSpawn
    pendingSpawn = nil
    SendNUIMessage({ action = 'spawnSuccess' })
    doSpawnVehicle(spawnData)
end)

-- Server responds: plate is taken
RegisterNetEvent('mnc-vehiclespawner:plateTaken', function()
    if not pendingSpawn then return end

    if pendingSpawn.isCustomPlate then
        -- Custom plate entered by admin — surface the error in the UI
        pendingSpawn = nil
        SendNUIMessage({ action = 'plateTaken' })
    else
        -- Auto-generated plate collided — silently generate a new one and retry
        local newPlate = generateLocalPlate()
        pendingSpawn.finalPlate = newPlate
        TriggerServerEvent('mnc-vehiclespawner:checkPlate', newPlate)
        -- NUI keeps its spinner shown; no message sent
    end
end)

-- Open UI
RegisterNetEvent('mnc-vehiclespawner:openUI', function()
    SetNuiFocus(true, true)
    fetchVehicleModels()
    SendNUIMessage({
        action = "openUI",
        uiStyle = Config.UIStyles[Config.UIStyle],
        title = "Vehicle Spawner"
    })
end)

-- ── Standalone Vehicle Mods UI ─────────────────────────────────────────────
-- Opens the mods+colours panel on the player's CURRENT vehicle (no spawn needed)

local standaloneMods_vehicle = 0  -- handle of the vehicle being edited

local function openStandaloneModsUI()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        lib.notify({
            title = 'Vehicle Mods',
            description = 'You must be inside a vehicle.',
            type = 'error',
            duration = 4000,
        })
        return
    end

    standaloneMods_vehicle = GetVehiclePedIsIn(ped, false)
    SetNuiFocus(true, true)

    -- Kick off the livery/mod data fetch (reuses existing callback)
    local model = GetEntityModel(standaloneMods_vehicle)
    local modelName = ''
    for name, _ in pairs(QBShared.Vehicles) do
        if joaat(name) == model then modelName = name break end
    end

    -- Read current colours from the vehicle so the dropdowns start accurate
    local prim, sec = GetVehicleColours(standaloneMods_vehicle)
    local pearl, wheel = GetVehicleExtraColours(standaloneMods_vehicle)
    local tint = GetVehicleWindowTint(standaloneMods_vehicle)

    SendNUIMessage({
        action    = 'openStandaloneMods',
        uiStyle   = Config.UIStyles[Config.UIStyle],
        modelName = modelName,
        currentColours = {
            primary   = prim,
            secondary = sec,
            pearlescent = pearl,
            wheel     = wheel,
            windowTint = tint,
        },
    })

    -- Request real livery + mod slot data (same path as spawner)
    fetch_StandaloneModData(modelName ~= '' and modelName or tostring(model))
end

function fetch_StandaloneModData(modelOrHash)
    local hash = joaat(modelOrHash)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then return end
    end

    local coords = GetEntityCoords(PlayerPedId())
    local tempVeh = CreateVehicle(hash, coords.x, coords.y + 100, coords.z, 0.0, false, false)
    SetVehicleModKit(tempVeh, 0)

    local mod48Count  = GetNumVehicleMods(tempVeh, 48)
    local nativeCount = GetVehicleLiveryCount(tempVeh)
    local useNative   = (mod48Count == 0 and nativeCount > 0)

    local mod48Names = {}
    if useNative then
        for i = 0, nativeCount - 1 do
            local liveryName = GetLiveryName(tempVeh, i)
            local name = ''
            if liveryName and liveryName ~= '' then
                local label = GetLabelText(liveryName)
                if label and label ~= 'NULL' and label ~= '' then name = label end
            end
            if name == '' then name = 'Livery ' .. (i + 1) end
            table.insert(mod48Names, name)
        end
    elseif mod48Count > 0 then
        for i = 0, mod48Count - 1 do
            local label = GetModTextLabel(tempVeh, 48, i)
            local name  = (label ~= '' and GetLabelText(label) or '')
            if name == 'NULL' or name == '' then name = 'Livery ' .. (i + 1) end
            table.insert(mod48Names, name)
        end
    end

    local allModSlots = { 0,1,2,3,4,5,6,7,8,9,10,11,12,13,15,16,18,19,21,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,49 }
    local modData = {}
    for _, slotId in ipairs(allModSlots) do
        if slotId == 18 then
            modData[tostring(slotId)] = { count = 1, names = { 'Turbo' }, isToggle = true }
        else
            local count = GetNumVehicleMods(tempVeh, slotId)
            if count > 0 then
                local names = {}
                for i = 0, count - 1 do
                    local labelKey = GetModTextLabel(tempVeh, slotId, i)
                    local name = (labelKey ~= '' and GetLabelText(labelKey) or '')
                    if name == 'NULL' or name == '' then name = 'Option ' .. (i + 1) end
                    table.insert(names, name)
                end
                modData[tostring(slotId)] = { count = count, names = names, isToggle = false }
            end
        end
    end

    -- Read current wheel type from the real vehicle (not temp)
    local realVeh = standaloneMods_vehicle
    local wheelType = GetVehicleWheelType(realVeh)
    local frontWheelIdx = GetVehicleMod(realVeh, 23)
    local backWheelIdx  = GetVehicleMod(realVeh, 24)
    local wheelCount    = GetNumVehicleMods(tempVeh, 23)
    local backWheelCount = GetNumVehicleMods(tempVeh, 24)
    local vehClass = GetVehicleClass(realVeh)
    local isBike = (vehClass == 8 or vehClass == 13) -- 8 = Motorcycles, 13 = Cycles
    local xenonEnabled  = IsToggleModOn(realVeh, 22)
    local xenonColor    = GetVehicleXenonLightsColour(realVeh)
    local neonL = IsVehicleNeonLightEnabled(realVeh, 0)
    local neonR = IsVehicleNeonLightEnabled(realVeh, 1)
    local neonF = IsVehicleNeonLightEnabled(realVeh, 2)
    local neonB = IsVehicleNeonLightEnabled(realVeh, 3)
    local nr, ng, nb   = GetVehicleNeonLightsColour(realVeh)
    local smokeR, smokeG, smokeB = GetVehicleTyreSmokeColor(realVeh)
    local plateIndex    = GetVehicleNumberPlateTextIndex(realVeh)
    local tyreSmoke     = IsToggleModOn(realVeh, 20)
    local bulletproofTyres = not GetVehicleTyresCanBurst(realVeh)

    DeleteVehicle(tempVeh)
    SetModelAsNoLongerNeeded(hash)

    SendNUIMessage({
        action    = 'liveryData',
        mod14     = {},
        mod48     = mod48Names,
        useNative = useNative,
    })
    SendNUIMessage({
        action = 'modData',
        mods   = modData,
    })
    SendNUIMessage({
        action = 'standaloneExtraData',
        wheelType        = wheelType,
        frontWheelIdx    = frontWheelIdx,
        backWheelIdx     = backWheelIdx,
        wheelCount       = wheelCount,
        backWheelCount   = backWheelCount,
        isBike           = isBike,
        xenonEnabled     = xenonEnabled,
        xenonColor       = xenonColor,
        neon = { l = neonL, r = neonR, f = neonF, b = neonB },
        neonColor = { r = nr, g = ng, b = nb },
        tyreSmoke        = tyreSmoke,
        smokeColor = { r = smokeR, g = smokeG, b = smokeB },
        bulletproofTyres = bulletproofTyres,
        plateIndex       = plateIndex,
    })
end

-- NUI callback: apply mods/colours to the current vehicle live
RegisterNUICallback('applyVehicleMods', function(data, cb)
    local veh = standaloneMods_vehicle
    if not DoesEntityExist(veh) then cb('no_vehicle') return end

    SetVehicleModKit(veh, 0)

    -- Colours
    local c = data.colours
    if c then
        if c.primary ~= nil and c.primary >= 0 then
            local sec = (c.secondary ~= nil and c.secondary >= 0) and c.secondary or c.primary
            SetVehicleColours(veh, c.primary, sec)
        end
        if c.pearlescent ~= nil and c.pearlescent >= 0 and c.wheel ~= nil and c.wheel >= 0 then
            SetVehicleExtraColours(veh, c.pearlescent, c.wheel)
        end
        if c.windowTint ~= nil then SetVehicleWindowTint(veh, c.windowTint) end
        if c.livery ~= nil and c.livery >= 0 then
            local max = GetNumVehicleMods(veh, 14)
            if max > 0 and c.livery < max then SetVehicleMod(veh, 14, c.livery, false) end
        end
        if c.liveryMod48 ~= nil and c.liveryMod48 >= 0 then
            local mod48Count  = GetNumVehicleMods(veh, 48)
            local nativeCount = GetVehicleLiveryCount(veh)
            if mod48Count == 0 and nativeCount > 0 then
                SetVehicleLivery(veh, c.liveryMod48)
            elseif mod48Count > 0 and c.liveryMod48 < mod48Count then
                SetVehicleMod(veh, 48, c.liveryMod48, false)
            end
        end
    end

    -- Mods
    local m = data.mods
    if m then
        for modId, modIndex in pairs(m) do
            local id = tonumber(modId)
            if id and modIndex ~= nil then
                if id == 18 then
                    ToggleVehicleMod(veh, 18, modIndex == 1)
                else
                    local max = GetNumVehicleMods(veh, id)
                    if modIndex == -1 or (max > 0 and modIndex < max) then
                        SetVehicleMod(veh, id, modIndex, false)
                    end
                end
            end
        end
    end

    -- Wheels
    if data.wheelType ~= nil then
        SetVehicleWheelType(veh, data.wheelType)
        Wait(50)
    end
    if data.frontWheelIdx ~= nil then
        local max = GetNumVehicleMods(veh, 23)
        if data.frontWheelIdx == -1 or (max > 0 and data.frontWheelIdx < max) then
            SetVehicleMod(veh, 23, data.frontWheelIdx, false)
        end
    end
    if data.backWheelIdx ~= nil then
        local max = GetNumVehicleMods(veh, 24)
        if max > 0 then
            if data.backWheelIdx == -1 or data.backWheelIdx < max then
                SetVehicleMod(veh, 24, data.backWheelIdx, false)
            end
        end
    end

    -- Bulletproof tyres
    if data.bulletproofTyres ~= nil then
        SetVehicleTyresCanBurst(veh, not data.bulletproofTyres)
    end

    -- Xenon lights
    if data.xenonEnabled ~= nil then
        ToggleVehicleMod(veh, 22, data.xenonEnabled)
        if data.xenonEnabled and data.xenonColor ~= nil then
            SetVehicleXenonLightsColour(veh, data.xenonColor)
        end
    end

    -- Neons
    if data.neon then
        SetVehicleNeonLightEnabled(veh, 0, data.neon.l)
        SetVehicleNeonLightEnabled(veh, 1, data.neon.r)
        SetVehicleNeonLightEnabled(veh, 2, data.neon.f)
        SetVehicleNeonLightEnabled(veh, 3, data.neon.b)
    end
    if data.neonColor then
        SetVehicleNeonLightsColour(veh, data.neonColor.r, data.neonColor.g, data.neonColor.b)
    end

    -- Tyre smoke
    if data.tyreSmoke ~= nil then
        ToggleVehicleMod(veh, 20, data.tyreSmoke)
        if data.tyreSmoke and data.smokeColor then
            SetVehicleTyreSmokeColor(veh, data.smokeColor.r, data.smokeColor.g, data.smokeColor.b)
        end
    end

    -- Plate style
    if data.plateIndex ~= nil then
        SetVehicleNumberPlateTextIndex(veh, data.plateIndex)
    end

    lib.notify({
        title = 'Vehicle Mods',
        description = 'Mods applied successfully!',
        type = 'success',
        duration = 3000,
    })

    cb('ok')
end)

-- Close standalone mods UI
RegisterNUICallback('closeStandaloneMods', function(_, cb)
    standaloneMods_vehicle = 0
    SetNuiFocus(false, false)
    cb({ status = 'closed' })
end)

-- Server triggers standalone mods UI open
RegisterNetEvent('mnc-vehiclespawner:openStandaloneMods', function()
    openStandaloneModsUI()
end)

-- Close UI
RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    cb({ status = 'closed' })
end)

-- Server saved vehicle successfully
RegisterNetEvent('mnc-vehiclespawner:vehicleSaved', function()
    lib.notify({
        title = 'Vehicle Spawner',
        description = 'Vehicle added to your garage!',
        type = 'success',
        duration = 4000,
    })
end)

-- Plate conflict on save (race condition edge case)
RegisterNetEvent('mnc-vehiclespawner:plateConflict', function()
    lib.notify({
        title = 'Vehicle Spawner',
        description = 'Could not save — plate conflict in garage.',
        type = 'error',
        duration = 5000,
    })
end)