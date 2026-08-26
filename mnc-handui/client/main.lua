local QBCore = exports['qb-core']:GetCoreObject()

local OverridesByHash = {}   -- [hash] = { field = value, ... }
local HashToModelName = {}

local isUIOpen = false
local currentModel = nil
local currentVehicle = nil   -- the actual vehicle the admin was sitting in when they opened the UI

----------------------------------------------------------------------------
-- Applying handling to live vehicles
----------------------------------------------------------------------------

-- CCarHandlingData fields (fClutchChangeRateScaleUpShift etc.) only exist on
-- a vehicle that has a mod kit attached. Without one the Set call is silently
-- dropped. SetVehicleModKit(veh, 0) attaches the subhandling object without
-- visually changing the vehicle or affecting CHandlingData values.
local function EnsureCarHandlingDataExists(vehicle, fields)
    if not DoesEntityExist(vehicle) then return end
    local needsCar = false
    for key in pairs(fields) do
        local field = Config.FieldLookup[key]
        if field and field.class == 'CCarHandlingData' then
            needsCar = true
            break
        end
    end
    if not needsCar then return end
    local probe = GetVehicleHandlingFloat(vehicle, 'CCarHandlingData', 'fClutchChangeRateScaleUpShift')
    if probe ~= 0.0 then return end
    SetVehicleModKit(vehicle, 0)
end

local function ApplyFieldsToVehicle(vehicle, fields)
    if not fields or not DoesEntityExist(vehicle) then return end
    EnsureCarHandlingDataExists(vehicle, fields)
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

local function ApplyToAllSpawnedOfHash(hash, fields)
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if GetEntityModel(veh) == hash then
            ApplyFieldsToVehicle(veh, fields)
        end
    end
end

local function ApplyAllOverridesToWorld()
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local hash = GetEntityModel(veh)
        local fields = OverridesByHash[hash]
        if fields then ApplyFieldsToVehicle(veh, fields) end
    end
end

----------------------------------------------------------------------------
-- Polling thread
----------------------------------------------------------------------------

local PatchedVehicles = {}  -- [handle] = modelHash

CreateThread(function()
    while true do
        Wait(1000)
        if next(OverridesByHash) == nil then goto continue end

        for handle, savedHash in pairs(PatchedVehicles) do
            if not DoesEntityExist(handle) or GetEntityModel(handle) ~= savedHash then
                PatchedVehicles[handle] = nil
            end
        end

        for _, veh in ipairs(GetGamePool('CVehicle')) do
            local hash = GetEntityModel(veh)
            local fields = OverridesByHash[hash]
            if not fields then goto skipveh end
            if PatchedVehicles[veh] == hash then goto skipveh end

            PatchedVehicles[veh] = hash
            local capturedVeh = veh
            local capturedHash = hash
            CreateThread(function()
                if DoesEntityExist(capturedVeh) then
                    ApplyFieldsToVehicle(capturedVeh, OverridesByHash[capturedHash] or fields)
                end
                Wait(600)
                if DoesEntityExist(capturedVeh) and GetEntityModel(capturedVeh) == capturedHash then
                    local latest = OverridesByHash[capturedHash]
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

RegisterNetEvent('mnc-handui:client:syncOverrides', function(data)
    OverridesByHash = {}
    PatchedVehicles = {}
    for modelName, fields in pairs(data or {}) do
        local hash = GetHashKey(modelName)
        OverridesByHash[hash] = fields
    end
    ApplyAllOverridesToWorld()
end)

RegisterNetEvent('mnc-handui:client:overrideUpdated', function(modelName, fields)
    local hash = GetHashKey(modelName)
    OverridesByHash[hash] = fields
    for handle, savedHash in pairs(PatchedVehicles) do
        if savedHash == hash then PatchedVehicles[handle] = nil end
    end
    ApplyToAllSpawnedOfHash(hash, fields)
end)

RegisterNetEvent('mnc-handui:client:overrideRemoved', function(modelName, originalFields)
    local hash = GetHashKey(modelName)
    for handle, savedHash in pairs(PatchedVehicles) do
        if savedHash == hash then PatchedVehicles[handle] = nil end
    end
    if originalFields and next(originalFields) ~= nil then
        ApplyToAllSpawnedOfHash(hash, originalFields)
    end
    OverridesByHash[hash] = nil
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('mnc-handui:server:requestSync')
end)

----------------------------------------------------------------------------
-- Model name resolution
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

-- Check if vehicle is allowed for tuning based on Config.AllowedClasses
local function IsVehicleTuningAllowed(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    local modelName = ResolveModelName(vehicle)
    if not modelName then return false end

    local allowed = Config.AllowedClasses or {}
    
    -- Check specific model name
    for _, entry in ipairs(allowed) do
        if type(entry) == 'string' and entry:lower() == modelName:lower() then
            return true
        end
    end

    -- Check vehicle class ID (e.g. 18 = emergency)
    local classId = GetVehicleClass(vehicle)
    for _, entry in ipairs(allowed) do
        if type(entry) == 'number' and entry == classId then
            return true
        end
    end

    -- Check QBCore category
    local vehData = QBCore.Shared.Vehicles[modelName]
    if vehData and vehData.category then
        for _, entry in ipairs(allowed) do
            if type(entry) == 'string' and entry:lower() == vehData.category:lower() then
                return true
            end
        end
    end

    return false
end

----------------------------------------------------------------------------
-- UI open / close
----------------------------------------------------------------------------

local function CloseUI()
    isUIOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
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

    QBCore.Functions.TriggerCallback('mnc-handui:server:checkAccess', function(hasAccess)
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

        if not IsVehicleTuningAllowed(veh) then
            lib.notify({ title = 'Handling Editor', description = 'This vehicle class or model is not allowed for tuning.', type = 'error' })
            return
        end

        local modelName = ResolveModelName(veh)
        if not modelName then
            lib.notify({ title = 'Handling Editor', description = "Could not resolve this vehicle's model name.", type = 'error' })
            return
        end

        -- Read live handling values directly from the vehicle
        local liveValues = ReadHandlingValues(veh)

        local vehData = QBCore.Shared.Vehicles[modelName]
        local label = vehData and vehData.name or modelName

        -- Check for an existing saved override (for the badge / meta info)
        QBCore.Functions.TriggerCallback('mnc-handui:server:getOverride', function(existing)
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

            currentModel   = modelName
            currentVehicle = veh

            isUIOpen = true
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(true)

            SendNUIMessage({
                action      = 'open',
                fieldGroups = Config.HandlingFields,
                presets     = Config.Presets,
                model       = modelName,
                label       = label,
                hasOverride = hasOverride,
                fields      = fields,
                original    = original,
                updatedBy   = updatedBy,
                updatedAt   = updatedAt,
            })
        end, modelName)
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
    if not data or not data.model or not data.fields then cb({ ok = false }) return end
    TriggerServerEvent('mnc-handui:server:saveOverride', {
        model    = data.model,
        fields   = data.fields,
        original = data.original,
    })
    cb({ ok = true })
end)

RegisterNUICallback('handui:deleteOverride', function(data, cb)
    if not data or not data.model then cb({ ok = false }) return end
    TriggerServerEvent('mnc-handui:server:deleteOverride', data.model)
    cb({ ok = true })
end)

RegisterNUICallback('handui:getOverridesList', function(_, cb)
    QBCore.Functions.TriggerCallback('mnc-handui:server:getAllOverrides', function(list)
        cb({ list = list })
    end)
end)

RegisterNetEvent('mnc-handui:client:saveResult', function(success, message)
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