local QBCore = exports['qb-core']:GetCoreObject()

local OverridesByPlate = {}   -- [plate] = { field = value, ... }
local HashToModelName = {}

local isUIOpen = false
local currentPlate = nil
local currentModel = nil
local currentVehicle = nil   -- the actual vehicle the admin was sitting in when they opened the UI

----------------------------------------------------------------------------
-- Plate helpers
----------------------------------------------------------------------------

-- GetVehicleNumberPlateText returns a fixed-width string padded with spaces
-- (e.g. "ABC 123 " for an 8-char plate slot). Trim and uppercase so the same
-- physical plate always resolves to the same key regardless of padding/case.
local function NormalizePlate(plate)
    if not plate or plate == '' then return nil end
    plate = plate:gsub('^%s+', ''):gsub('%s+$', '')
    if plate == '' then return nil end
    return plate:upper()
end

local function GetVehiclePlate(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    return NormalizePlate(GetVehicleNumberPlateText(vehicle))
end

----------------------------------------------------------------------------
-- Applying handling to live vehicles
----------------------------------------------------------------------------

-- Handling edits (especially the CCarHandlingData class fields like
-- fClutchChangeRateScaleUpShift, but in practice the game's physics/visual
-- recalculation for the rest of the handling too) don't reliably take effect
-- on a vehicle until it actually has a full mod kit installed — the same
-- state a vehicle ends up in after running something like /maxmods. Garage
-- scripts spawn vehicles "clean" (no mod kit), which is why the tune sat
-- there doing nothing until mods were forced on manually.
--
-- Only the Performance-tab mod slots are installed here — Engine, Brakes,
-- Transmission, Suspension, and Turbo. Everything cosmetic (bumpers, skirts,
-- spoilers, wheels, livery, xenons, etc.) is deliberately left alone so a
-- tune never changes how the vehicle looks.
local PERFORMANCE_MOD_TYPES = { 11, 12, 13, 15 } -- Engine, Brakes, Transmission, Suspension
local MaxModdedVehicles = {}  -- [handle] = true, so we don't redo this every apply

local function ApplyMaxMods(vehicle)
    if not DoesEntityExist(vehicle) then return end
    if MaxModdedVehicles[vehicle] then return end

    SetVehicleModKit(vehicle, 0)

    for _, modType in ipairs(PERFORMANCE_MOD_TYPES) do
        local numMods = GetNumVehicleMods(vehicle, modType)
        if numMods > 0 then
            SetVehicleMod(vehicle, modType, numMods - 1, false)
        end
    end

    -- Turbo is a toggle mod, not a leveled one, so it isn't covered by the
    -- loop above — but it's still a Performance-tab mod.
    ToggleVehicleMod(vehicle, 18, true) -- turbo

    MaxModdedVehicles[vehicle] = true
end

local function IsMaxPerformanceMods(vehicle)
    if not DoesEntityExist(vehicle) then return false end

    -- Check performance mod levels
    for _, modType in ipairs(PERFORMANCE_MOD_TYPES) do
        local numMods = GetNumVehicleMods(vehicle, modType)
        if numMods > 0 then
            local currentMod = GetVehicleMod(vehicle, modType)
            if currentMod ~= numMods - 1 then
                return false
            end
        end
    end

    -- Check turbo
    if not IsToggleModOn(vehicle, 18) then
        return false
    end

    return true
end

local function ApplyFieldsToVehicle(vehicle, fields)
    if not fields or not DoesEntityExist(vehicle) then return end
    ApplyMaxMods(vehicle)
    for key, value in pairs(fields) do
        local field = Config.FieldLookup[key]
        if field then
            local class = field.class or 'CHandlingData'
            if field.type == 'int' then
                SetVehicleHandlingInt(vehicle, class, key, math.floor(value))
            else
                SetVehicleHandlingFloat(vehicle, class, key, value + 0.0)
            end
        end
    end
end

-- Applies to every currently-spawned vehicle carrying this plate. Normally
-- that's at most one real vehicle, but duplicate plates can exist (players
-- can set matching plates), so we cover all of them rather than assume.
local function ApplyToAllSpawnedOfPlate(plate, fields)
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if GetVehiclePlate(veh) == plate then
            ApplyFieldsToVehicle(veh, fields)
        end
    end
end

local function ApplyAllOverridesToWorld()
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local plate = GetVehiclePlate(veh)
        local fields = plate and OverridesByPlate[plate]
        if fields then ApplyFieldsToVehicle(veh, fields) end
    end
end

AddEventHandler('entityRemoved', function(entity)
    MaxModdedVehicles[entity] = nil
end)

----------------------------------------------------------------------------
-- Instant apply on spawn (garage pulls, /car, etc.)
----------------------------------------------------------------------------

local PatchedVehicles = {}  -- [handle] = plate

-- entityCreated fires the instant a vehicle entity exists client-side —
-- far faster than waiting on the 1s poll below, which is why a garage pull
-- used to sit un-tuned until something else (like /maxmods) happened to
-- touch the vehicle and give the poll a reason to re-check it.
--
-- A freshly created vehicle can still be missing its real plate for a frame
-- or two, and garage/mod scripts often apply their own mods/colours/extras
-- shortly after spawn, which can stomp handling values set too early. So
-- this re-applies a few times over the first few seconds rather than once.
AddEventHandler('entityCreated', function(entity)
    if not DoesEntityExist(entity) then return end
    if GetEntityType(entity) ~= 2 then return end -- 2 = vehicle
    if next(OverridesByPlate) == nil then return end

    CreateThread(function()
        local delays = { 0, 300, 800, 1500, 3000 }
        for _, delay in ipairs(delays) do
            if delay > 0 then Wait(delay) end
            if not DoesEntityExist(entity) then return end

            local plate = GetVehiclePlate(entity)
            local fields = plate and OverridesByPlate[plate]
            if fields then
                ApplyFieldsToVehicle(entity, fields)
                PatchedVehicles[entity] = plate
            end
        end
    end)
end)

----------------------------------------------------------------------------
-- Polling thread (fallback safety net for anything entityCreated missed —
-- vehicles that existed before this resource started, edge cases, etc.)
----------------------------------------------------------------------------

CreateThread(function()
    while true do
        Wait(1000)
        if next(OverridesByPlate) == nil then goto continue end

        for handle, savedPlate in pairs(PatchedVehicles) do
            if not DoesEntityExist(handle) or GetVehiclePlate(handle) ~= savedPlate then
                PatchedVehicles[handle] = nil
            end
        end

        for _, veh in ipairs(GetGamePool('CVehicle')) do
            local plate = GetVehiclePlate(veh)
            local fields = plate and OverridesByPlate[plate]
            if not fields then goto skipveh end
            if PatchedVehicles[veh] == plate then goto skipveh end

            PatchedVehicles[veh] = plate
            local capturedVeh = veh
            local capturedPlate = plate
            CreateThread(function()
                if DoesEntityExist(capturedVeh) then
                    ApplyFieldsToVehicle(capturedVeh, OverridesByPlate[capturedPlate] or fields)
                    ExecuteCommand("maxmods")
				end
                Wait(600)
                if DoesEntityExist(capturedVeh) and GetVehiclePlate(capturedVeh) == capturedPlate then
                    local latest = OverridesByPlate[capturedPlate]
                    if latest then ApplyFieldsToVehicle(capturedVeh, latest) end
                end
            end)
            ::skipveh::
        end
        ::continue::
    end
end)

----------------------------------------------------------------------------
-- Sync events
----------------------------------------------------------------------------

RegisterNetEvent('mnc-handuiPlate:client:syncOverrides', function(data)
    OverridesByPlate = {}
    PatchedVehicles = {}
    for plate, fields in pairs(data or {}) do
        OverridesByPlate[plate] = fields
    end
    ApplyAllOverridesToWorld()
end)

RegisterNetEvent('mnc-handuiPlate:client:overrideUpdated', function(plate, fields)
    OverridesByPlate[plate] = fields
    for handle, savedPlate in pairs(PatchedVehicles) do
        if savedPlate == plate then PatchedVehicles[handle] = nil end
    end
    ApplyToAllSpawnedOfPlate(plate, fields)
end)

RegisterNetEvent('mnc-handuiPlate:client:overrideRemoved', function(plate, originalFields)
    for handle, savedPlate in pairs(PatchedVehicles) do
        if savedPlate == plate then PatchedVehicles[handle] = nil end
    end
    if originalFields and next(originalFields) ~= nil then
        ApplyToAllSpawnedOfPlate(plate, originalFields)
    end
    OverridesByPlate[plate] = nil
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('mnc-handuiPlate:server:requestSync')
end)

----------------------------------------------------------------------------
-- Model name resolution (display only — no longer used as a save key)
----------------------------------------------------------------------------

CreateThread(function()
    for model, _ in pairs(QBCore.Shared.Vehicles) do
        HashToModelName[GetHashKey(model)] = model
    end
end)

local function ResolveModelName(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    if GetEntityArchetypeName then
        local ok, name = pcall(GetEntityArchetypeName, vehicle)
        if ok and name and name ~= '' then return name:lower() end
    end
    local hash = GetEntityModel(vehicle)
    return HashToModelName[hash]
end

local function ReadHandlingValues(vehicle)
    local values = {}
    for key, field in pairs(Config.FieldLookup) do
        local class = field.class or 'CHandlingData'
        if field.type == 'int' then
            values[key] = GetVehicleHandlingInt(vehicle, class, key)
        else
            values[key] = GetVehicleHandlingFloat(vehicle, class, key)
        end
    end
    return values
end

----------------------------------------------------------------------------
-- UI open / close
----------------------------------------------------------------------------

local function CloseUI()
    isUIOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
    currentPlate = nil
    currentModel = nil
    currentVehicle = nil
end

CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen then
            DisableAllControlActions(0)
            EnableControlAction(0, 30, true)
            EnableControlAction(0, 31, true)
            EnableControlAction(0, 1,  true)
            EnableControlAction(0, 2,  true)
            EnableControlAction(0, 245, true)
            EnableControlAction(0, 21,  true)
            EnableControlAction(0, 22,  true)
            EnableControlAction(0, 44,  true)
            EnableControlAction(0, 71,  true)
            EnableControlAction(0, 72,  true)
            EnableControlAction(0, 59,  true)
            EnableControlAction(0, 60,  true)
            EnableControlAction(0, 63,  true)
            EnableControlAction(0, 75,  true)
        end
    end
end)

RegisterCommand(Config.Command, function()
    if isUIOpen then return end

    QBCore.Functions.TriggerCallback('mnc-handuiPlate:server:checkAccess', function(hasAccess)
        if not hasAccess then
            lib.notify({ title = 'Access Denied', description = 'You do not have permission to use the handling editor.', type = 'error' })
            return
        end

        -- Must be sitting in a vehicle
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then
            lib.notify({ title = 'Handling Editor', description = 'You must be sitting in a vehicle to open the handling editor.', type = 'error' })
            return
        end

        -- STRICT CHECK: Vehicle MUST have max performance parts
        if not IsMaxPerformanceMods(veh) then
            lib.notify({ 
                title = 'Handling Editor', 
                description = 'This vehicle must have MAXIMUM performance modifications (Engine, Brakes, Transmission, Suspension & Turbo) before tuning is allowed.', 
                type = 'error' 
            })
            return
        end

        local plate = GetVehiclePlate(veh)
        if not plate then
            lib.notify({ title = 'Handling Editor', description = "Could not read this vehicle's plate.", type = 'error' })
            return
        end

        local modelName = ResolveModelName(veh)
        local vehData = modelName and QBCore.Shared.Vehicles[modelName]
        local label = (vehData and vehData.name) or modelName or 'Unknown Vehicle'

        -- Read live handling values directly from the vehicle
        local liveValues = ReadHandlingValues(veh)

        -- Check for an existing saved override (for the badge / meta info)
        QBCore.Functions.TriggerCallback('mnc-handuiPlate:server:getOverride', function(existing)
            local fields, original, hasOverride, updatedBy, updatedAt

            if existing then
                fields      = existing.data
                original    = existing.original
                hasOverride = true
                updatedBy   = existing.updatedBy
                updatedAt   = existing.updatedAt
            else
                fields      = liveValues
                original    = liveValues
                hasOverride = false
                updatedBy   = nil
                updatedAt   = nil
            end

            currentPlate   = plate
            currentModel   = modelName
            currentVehicle = veh

            isUIOpen = true
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(true)

            SendNUIMessage({
                action      = 'open',
                fieldGroups = Config.HandlingFields,
                presets     = Config.Presets,
                plate       = plate,
                model       = modelName,
                label       = label,
                hasOverride = hasOverride,
                fields      = fields,
                original    = original,
                updatedBy   = updatedBy,
                updatedAt   = updatedAt,
            })
        end, plate)
    end)
end, false)

----------------------------------------------------------------------------
-- NUI callbacks
----------------------------------------------------------------------------

RegisterNUICallback('handui:close', function(_, cb)
    CloseUI()
    cb({})
end)

-- Live slider updates — applied directly to the vehicle the admin is sitting in
RegisterNUICallback('handui:liveUpdate', function(data, cb)
    if currentVehicle and DoesEntityExist(currentVehicle) and data and data.fields then
        ApplyFieldsToVehicle(currentVehicle, data.fields)
    end
    cb({})
end)

RegisterNUICallback('handui:save', function(data, cb)
    if not data or not data.plate or not data.fields then cb({ ok = false }) return end
    TriggerServerEvent('mnc-handuiPlate:server:saveOverride', {
        plate    = data.plate,
        model    = data.model,
        fields   = data.fields,
        original = data.original,
    })
    cb({ ok = true })
end)

RegisterNUICallback('handui:deleteOverride', function(data, cb)
    if not data or not data.plate then cb({ ok = false }) return end
    TriggerServerEvent('mnc-handuiPlate:server:deleteOverride', data.plate)
    cb({ ok = true })
end)

RegisterNUICallback('handui:getOverridesList', function(_, cb)
    QBCore.Functions.TriggerCallback('mnc-handuiPlate:server:getAllOverrides', function(list)
        cb({ list = list })
    end)
end)

RegisterNetEvent('mnc-handuiPlate:client:saveResult', function(success, message)
    if success then
        lib.notify({ title = 'Handling Editor', description = message, type = 'success' })
    else
        lib.notify({ title = 'Handling Editor', description = message, type = 'error' })
    end
    SendNUIMessage({ action = 'saveResult', ok = success, message = message })
end)

----------------------------------------------------------------------------
-- Cleanup
----------------------------------------------------------------------------

AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    if isUIOpen then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end)