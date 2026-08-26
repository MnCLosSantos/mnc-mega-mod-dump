-- client.lua
QBCore = exports['qb-core']:GetCoreObject()

local isUIOpen = false
local QBCore = nil
-- Add this near the top with other local variables
local vehicleCheckTimers = {} -- Store timers per vehicle plate
local notifiedPlates = {} -- Track which plates have been notified this session

-- Wait for both QBCore and ox_lib to be available
Citizen.CreateThread(function()
    local maxAttempts = 100 -- Try for 10 seconds
    local attempts = 0
    while not QBCore or not QBCore.Functions do
        if attempts >= maxAttempts then
            print("[mnc-insurance] Failed to initialize QBCore after 10 seconds")
            return
        end
        QBCore = exports['qb-core']:GetCoreObject()
        Citizen.Wait(100)
        attempts = attempts + 1
    end
    print("[mnc-insurance] QBCore initialized successfully")
end)

-- Mappings used client-side to compute category
local gtaClassToCategory = {
    [0] = "compacts",
    [1] = "sedans",
    [2] = "suvs",
    [3] = "coupes",
    [4] = "muscle",
    [5] = "sportsclassics",
    [6] = "sports",
    [7] = "super",
    [8] = "motorcycles",
    [9] = "offroad",
    [10] = "industrial",
    [11] = "utility",
    [12] = "vans",
    [13] = "cycles",
    [14] = "boats",
    [15] = "planes",
    [16] = "planes",
    [17] = "service",
    [18] = "emergency",
    [19] = "military",
    [20] = "commercial",
}

-- Helper function to get the nearest vehicle within a certain radius
local function GetNearestVehicleWithinRadius(radius)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicles = GetGamePool('CVehicle')
    local nearestVehicle = nil
    local minDistance = radius + 1

    for _, vehicle in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle)
        local distance = #(playerCoords - vehCoords)
        if distance <= radius and distance < minDistance then
            minDistance = distance
            nearestVehicle = vehicle
        end
    end
    return nearestVehicle, minDistance
end

-- Helper function to get title based on action type
local function getActionTitle(isCheckMode, isRegistration, isInspection, isCheckInspection, isCheckRegistration)
    if isCheckRegistration then
        return 'Check Registration'
    elseif isCheckInspection then
        return 'Check Inspection'
    elseif isInspection then
        return 'Inspection'
    elseif isRegistration then
        return 'Registration'
    elseif isCheckMode then
        return 'Check Insurance'
    else
        return 'Insurance'
    end
end

-- Function to check vehicle data (used for insurance, registration, and inspection)
function CheckVehicleUI(isCheckMode, isRegistration, isInspection, isCheckInspection, isCheckRegistration)
    local ped = PlayerPedId()
    local vehicle = nil
    local plate, modelHash, modelName, color1, color2, vClass, category
    local actionTitle = getActionTitle(isCheckMode, isRegistration, isInspection, isCheckInspection, isCheckRegistration)

    if (isCheckMode or isCheckInspection or isCheckRegistration) and not IsPedInAnyVehicle(ped, false) then
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 70)
        if vehicle == 0 then
            exports['ox_lib']:notify({
                type = 'error',
                title = actionTitle,
                description = 'No vehicle found nearby.',
                duration = 5000
            })
            return
        end
        plate = GetVehicleNumberPlateText(vehicle)
        modelHash = GetEntityModel(vehicle)
        modelName = GetDisplayNameFromVehicleModel(modelHash)
        color1, color2 = GetVehicleColours(vehicle)
        vClass = GetVehicleClass(vehicle)
        category = gtaClassToCategory[vClass] or "compacts"
    elseif IsPedInAnyVehicle(ped, false) then
        vehicle = GetVehiclePedIsIn(ped, false)
        plate = GetVehicleNumberPlateText(vehicle)
        modelHash = GetEntityModel(vehicle)
        modelName = GetDisplayNameFromVehicleModel(modelHash)
        color1, color2 = GetVehicleColours(vehicle)
        vClass = GetVehicleClass(vehicle)
        category = gtaClassToCategory[vClass] or "compacts"
    else
        exports['ox_lib']:notify({
            type = 'error',
            title = actionTitle,
            description = 'No vehicle found nearby.',
            duration = 5000
        })
        return
    end

    -- Remove local player name fetching; rely on server-side data
    local eventName = isCheckRegistration and "mnc_insurance:checkRegistrationData" or isCheckInspection and "mnc_insurance:checkInspectionData" or isInspection and "mnc_insurance:getInspectionData" or isRegistration and "mnc_insurance:getRegistrationData" or (isCheckMode and "mnc_insurance:checkData" or "mnc_insurance:getData")
    TriggerServerEvent(eventName, {
        plate = plate,
        name = modelName,
        modelHash = modelHash,
        color1 = color1,
        color2 = color2,
        category = category,
        modTier = 1,
        isBusiness = false
        -- playerName is not sent from client; server will fetch it from database
    })
end

-- Register commands
RegisterCommand("insurance", function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if not vehicle or vehicle == 0 then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Insurance',
            description = 'You must be in a vehicle to open the insurance database.',
            duration = 5000
        })
        return
    end
    TriggerServerEvent("mnc_insurance:validateInsurance", {
        plate = GetVehicleNumberPlateText(vehicle),
        name = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
        modelHash = GetEntityModel(vehicle),
        color1 = GetVehicleColours(vehicle),
        color2 = (select(2, GetVehicleColours(vehicle))),
        category = gtaClassToCategory[GetVehicleClass(vehicle)] or "compacts",
        modTier = 1,
        isBusiness = false
    })
end, false)

RegisterCommand("checkinsurance", function()
    local vehicle, distance = GetNearestVehicleWithinRadius(10)
    if not vehicle then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Insurance',
            description = 'No vehicle within 10 meters. Please get closer to a vehicle to open the insurance database.',
            duration = 5000
        })
        return
    end
    CheckVehicleUI(true, false, false, false, false)
end, false)

RegisterCommand("registration", function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if not vehicle or vehicle == 0 then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Registration',
            description = 'You must be in a vehicle to open the registration database.',
            duration = 5000
        })
        return
    end
    TriggerServerEvent("mnc_insurance:validateRegistration", {
        plate = GetVehicleNumberPlateText(vehicle),
        name = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
        modelHash = GetEntityModel(vehicle),
        color1 = GetVehicleColours(vehicle),
        color2 = (select(2, GetVehicleColours(vehicle))),
        category = gtaClassToCategory[GetVehicleClass(vehicle)] or "compacts",
        modTier = 1,
        isBusiness = false
    })
end, false)

RegisterCommand("checkregistration", function()
    local vehicle, distance = GetNearestVehicleWithinRadius(10)
    if not vehicle then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Check Registration',
            description = 'No vehicle within 10 meters. Please get closer to a vehicle to open the registration database.',
            duration = 5000
        })
        return
    end
    CheckVehicleUI(false, true, false, false, true)
end, false)

RegisterCommand("inspection", function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if not vehicle or vehicle == 0 then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Inspection',
            description = 'You must be in a vehicle to open the inspection database.',
            duration = 5000
        })
        return
    end
    CheckVehicleUI(false, false, true, false, false)
end, false)

RegisterCommand("checkinspection", function()
    local vehicle, distance = GetNearestVehicleWithinRadius(10)
    if not vehicle then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Check Inspection',
            description = 'No vehicle within 10 meters. Please get closer to a vehicle to open the inspection database.',
            duration = 5000
        })
        return
    end
    CheckVehicleUI(false, false, true, true, false)
end, false)

RegisterCommand("checkvehdocs", function()
    -- Wait for QBCore to be initialized with a timeout
    local maxAttempts = 50 -- Try for 5 seconds (50 * 100ms)
    local attempts = 0
    while not QBCore or not QBCore.Functions do
        if attempts >= maxAttempts then
            exports['ox_lib']:notify({
                type = 'error',
                title = 'Check Vehicle Documents',
                description = 'System failed to initialize. Please contact an admin.',
                duration = 5000
            })
            return
        end
        QBCore = exports['qb-core']:GetCoreObject()
        Citizen.Wait(100)
        attempts = attempts + 1
    end

    -- Check if player has the required job
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.job then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Check Vehicle Documents',
            description = 'Player data not available. Please try again.',
            duration = 5000
        })
        return
    end

    local job = PlayerData.job.name
    if not (job == "police" or job == "bcso") then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Check Vehicle Documents',
            description = 'You do not have permission to use this command.',
            duration = 5000
        })
        return
    end

    local vehicle, distance = GetNearestVehicleWithinRadius(10)
    if not vehicle then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Check Vehicle Documents',
            description = 'No vehicle within 10 meters. Please get closer to a vehicle to check documents.',
            duration = 5000
        })
        return
    end

    -- Set NUI focus once and keep it open
    SetNuiFocus(true, true)
    isUIOpen = true

    -- Trigger check UIs with increased delays to ensure rendering
    CheckVehicleUI(false, true, false, false, true) -- Check registration
    Citizen.Wait(3500) -- Increased delay to 500ms
    CheckVehicleUI(false, false, true, true, false) -- Check inspection
    Citizen.Wait(3500) -- Increased delay to 500ms
    CheckVehicleUI(true, false, false, false, false) -- Check insurance
end, false)

-- Validation event for registration
RegisterNetEvent("mnc_insurance:validateRegistrationResult")
AddEventHandler("mnc_insurance:validateRegistrationResult", function(data, isValid)
    if not isValid then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Registration',
            description = 'Vehicle must be inspected before registration.',
            duration = 5000
        })
        return
    end
    CheckVehicleUI(false, true, false, false, false)
end)

-- Validation event for insurance
RegisterNetEvent("mnc_insurance:validateInsuranceResult")
AddEventHandler("mnc_insurance:validateInsuranceResult", function(data, isValid, message)
    if not isValid then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Insurance',
            description = message or 'Vehicle must be inspected and registered before insuring.',
            duration = 5000
        })
        return
    end
    CheckVehicleUI(false, false, false, false, false)
end)

-- Open UI event from server
RegisterNetEvent("mnc_insurance:openUI")
AddEventHandler("mnc_insurance:openUI", function(data)
    if isUIOpen then
        SendNUIMessage({ type = "open", payload = data })
        return
    end
    if data.error then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Insurance',
            description = data.error,
            duration = 5000
        })
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "open", payload = data })
    isUIOpen = true
end)

-- Check UI event from server
RegisterNetEvent("mnc_insurance:checkUI")
AddEventHandler("mnc_insurance:checkUI", function(data)
    if isUIOpen then
        SendNUIMessage({ type = "check", payload = data })
        return
    end
    if data.error then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Insurance',
            description = data.error,
            duration = 5000
        })
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "check", payload = data })
    isUIOpen = true
end)

-- Registration UI event from server
RegisterNetEvent("mnc_insurance:registrationUI")
AddEventHandler("mnc_insurance:registrationUI", function(data)
    if isUIOpen then
        SendNUIMessage({ type = "register", payload = data })
        return
    end
    if data.error then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Registration',
            description = data.error,
            duration = 5000
        })
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "register", payload = data })
    isUIOpen = true
end)

-- Check Registration UI event from server
RegisterNetEvent("mnc_insurance:checkRegistrationUI")
AddEventHandler("mnc_insurance:checkRegistrationUI", function(data)
    if isUIOpen then
        SendNUIMessage({ type = "checkRegistration", payload = data })
        return
    end
    if data.error then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Check Registration',
            description = data.error,
            duration = 5000
        })
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "checkRegistration", payload = data })
    isUIOpen = true
end)

-- Inspection UI event from server
RegisterNetEvent("mnc_insurance:inspectionUI")
AddEventHandler("mnc_insurance:inspectionUI", function(data)
    if isUIOpen then
        SendNUIMessage({ type = "inspect", payload = data })
        return
    end
    if data.error then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Inspection',
            description = data.error,
            duration = 5000
        })
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "inspect", payload = data })
    isUIOpen = true
end)

-- Check Inspection UI event from server
RegisterNetEvent("mnc_insurance:checkInspectionUI")
AddEventHandler("mnc_insurance:checkInspectionUI", function(data)
    if isUIOpen then
        SendNUIMessage({ type = "checkInspection", payload = data })
        return
    end
    if data.error then
        exports['ox_lib']:notify({
            type = 'error',
            title = 'Check Inspection',
            description = data.error,
            duration = 5000
        })
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "checkInspection", payload = data })
    isUIOpen = true
end)

-- Close UI callback from NUI
RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    isUIOpen = false
    if cb then cb('ok') end
end)

-- Update callback
RegisterNUICallback("update", function(data, cb)
    TriggerServerEvent("mnc_insurance:updateData", data)
    if cb then cb('ok') end
end)

-- Purchase callback
RegisterNUICallback("purchase", function(data, cb)
    TriggerServerEvent("mnc_insurance:purchase", data)
    if cb then cb('ok') end
end)

-- Register callback
RegisterNUICallback("register", function(data, cb)
    TriggerServerEvent("mnc_insurance:register", data)
    if cb then cb('ok') end
end)

-- Inspect callback
RegisterNUICallback("inspect", function(data, cb)
    TriggerServerEvent("mnc_insurance:inspect", data)
    if cb then cb('ok') end
end)

-- Notify error callback
RegisterNUICallback("notifyError", function(data, cb)
    exports['ox_lib']:notify({
        type = 'error',
        title = data.title or 'Error',
        description = data.message,
        duration = 5000
    })
    if cb then cb('ok') end
end)

-- Allow pressing ESC to close UI
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isUIOpen and IsControlJustReleased(0, 200) then
            SetNuiFocus(false, false)
            isUIOpen = false
            SendNUIMessage({ type = "close" })
        end
    end
end)

local function StartVehicleNotificationTimer(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    local vClass = GetVehicleClass(vehicle)
    local category = gtaClassToCategory[vClass] or "compacts"
    
    -- Check if already notified this session
    if notifiedPlates[plate] then
        return
    end
    
    -- Clear existing timer if any
    if vehicleCheckTimers[plate] then
        vehicleCheckTimers[plate] = nil
    end
    
    -- Initial check right away
    Citizen.CreateThread(function()
        TriggerServerEvent("mnc_insurance:checkVehicleStatus", plate, category)
        
        -- Mark as notified
        notifiedPlates[plate] = true
        
        -- No recurring timer needed since we only notify once per session
    end)
end

-- Add this new thread to detect vehicle entry
Citizen.CreateThread(function()
    local lastVehicle = nil
    while true do
        Citizen.Wait(1000) -- Check every second
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 and vehicle ~= lastVehicle then
            -- Check if player is the driver (seat -1)
            if GetPedInVehicleSeat(vehicle, -1) == ped then
                -- Player is driver of a new vehicle
                StartVehicleNotificationTimer(vehicle)
            end
            lastVehicle = vehicle
        elseif vehicle == 0 then
            lastVehicle = nil
        end
    end
end)

-- Add this new event handler near the bottom with other RegisterNetEvent handlers
RegisterNetEvent("mnc_insurance:vehicleStatusNotification")
AddEventHandler("mnc_insurance:vehicleStatusNotification", function(data)
    local statusParts = {}
    
    if data.isInspected then
        table.insert(statusParts, "✓ Inspected")
    else
        table.insert(statusParts, "✗ Not Inspected")
    end
    
    if data.isRegistered then
        table.insert(statusParts, "✓ Registered")
    else
        table.insert(statusParts, "✗ Not Registered")
    end
    
    if data.isInsured then
        table.insert(statusParts, "✓ Insured")
    elseif data.isExpired then
        table.insert(statusParts, "✗ Insurance Expired")
    else
        table.insert(statusParts, "✗ Not Insured")
    end
    
    local description = table.concat(statusParts, " | ")
    local notificationType = (data.isInspected and data.isRegistered and data.isInsured) and 'success' or 'warning'
    Wait(25000)
    exports['ox_lib']:notify({
        type = notificationType,
        title = 'Make sure your documents are upto date. Use /inspection, /registration, /insurance. To check use /checkinsurance ECT',
        description = description,
        duration = 15000 -- 30 seconds
    })
end)