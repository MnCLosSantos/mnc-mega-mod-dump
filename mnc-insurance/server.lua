QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()

    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `insured_vehicles` (
            `plate` VARCHAR(10) NOT NULL,
            `citizenid` VARCHAR(50) NOT NULL,
            `playerName` VARCHAR(100) NOT NULL,
            `modTier` INT NOT NULL,
            `isBusiness` BOOLEAN NOT NULL,
            `startDate` VARCHAR(10) NOT NULL,
            `endDate` VARCHAR(10) NOT NULL,
            `category` VARCHAR(50) NOT NULL,
            `name` VARCHAR(100) NOT NULL,
            `color1` VARCHAR(50),
            `color2` VARCHAR(50),
            `insuranceCompany` VARCHAR(10),
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `registered_vehicles` (
            `plate` VARCHAR(10) NOT NULL,
            `citizenid` VARCHAR(50) NOT NULL,
            `playerName` VARCHAR(100) NOT NULL,
            `registrationDate` VARCHAR(10) NOT NULL,
            `category` VARCHAR(50) NOT NULL,
            `name` VARCHAR(100) NOT NULL,
            `color1` VARCHAR(50),
            `color2` VARCHAR(50),
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `inspected_vehicles` (
            `plate` VARCHAR(10) NOT NULL,
            `citizenid` VARCHAR(50) NOT NULL,
            `playerName` VARCHAR(100) NOT NULL,
            `inspectionDate` VARCHAR(10) NOT NULL,
            `category` VARCHAR(50) NOT NULL,
            `name` VARCHAR(100) NOT NULL,
            `color1` VARCHAR(50),
            `color2` VARCHAR(50),
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    print("^2[mnc-insurance]^7 Vehicle tables checked/created successfully!")

end)


-- Pricing tables
local categoryPrices = {
    compacts = 1000,
    sedans = 1250,
    suvs = 1500,
    coupes = 1750,
    muscle = 2000,
    sportsclassics = 1100,
    sports = 1800,
    super = 3500,
    motorcycles = 750,
    offroad = 1250,
    industrial = 2250,
    utility = 2125,
    vans = 1000,
    boats = 3250,
    planes = 5750,
    commercial = 3250,
    openwheel = 8500
}

local modTierPrices = {
    [1] = 0,
    [2] = 250,
    [3] = 500,
    [4] = 750,
    [5] = 1000
}

-- Insurance company premiums
local insuranceCompanyPremiums = {
    MNC = 0.10,
    LSIC = 0.15,
    MAZE = 0.20
}

local businessFee = 1450
local fees = 70
local processFee = 125
local registrationFee = 250
local inspectionFee = 350

-- Helper to get player identifier and name with retry
local function getPlayerIdentifier(source)
    local maxAttempts = 10
    local attempt = 1
    local delay = 100 -- ms

    while attempt <= maxAttempts do
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and Player.PlayerData and Player.PlayerData.charinfo then
            local citizenid = Player.PlayerData.citizenid or "N/A"
            local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            return citizenid, playerName or "N/A"
        end
        print('[mnc-insurance] Attempt ' .. attempt .. ': Player data not ready for source ' .. source)
        Citizen.Wait(delay)
        attempt = attempt + 1
    end

    print('[mnc-insurance] Could not fetch player name after ' .. maxAttempts .. ' attempts, using fallback for source ' .. source)
    return "N/A", "N/A"
end

-- Helper to round money
local function roundMoney(n)
    return math.floor(n + 0.5)
end

-- Helper to parse date string (dd/mm/yyyy) to a table
local function parseDate(dateStr)
    if not dateStr or dateStr == "" then return nil end
    local day, month, year = dateStr:match("(%d+)/(%d+)/(%d+)")
    return { day = tonumber(day), month = tonumber(month), year = tonumber(year) }
end

-- Helper to compare dates
local function isInsuranceExpired(endDate)
    if not endDate then return true end

    local currentDate = os.time()
    local endDateTable = parseDate(endDate)
    if not endDateTable then return true end

    local endDateTime = os.time({ day = endDateTable.day, month = endDateTable.month, year = endDateTable.year })
    return currentDate > endDateTime
end

-- Helper to calculate insurance cost with company premium
local function calculateInsuranceCost(categoryCost, modCost, businessCost, fees, processFee, tax, insuranceCompany, isCurrentlyInsured, isExpired)
    local subtotal
    
    if isCurrentlyInsured and not isExpired then
        subtotal = modCost + businessCost + tax
    else
        subtotal = categoryCost + modCost + businessCost + fees + processFee + tax
    end
    
    -- Apply insurance company premium
    local premium = subtotal * (insuranceCompanyPremiums[insuranceCompany] or 0.10)
    local total = subtotal + premium
    
    return roundMoney(total)
end

-- Database helper functions
local function loadVehicleData(plate, tableName, callback)
    exports.oxmysql:fetch('SELECT * FROM ' .. tableName .. ' WHERE plate = ?', { plate }, function(result)
        if result and result[1] then
            callback(result[1])
        else
            callback(nil)
        end
    end)
end

local function saveInsuredVehicle(data)
    -- Handle nil values for color1 and color2
    local color1 = data.color1 or ""
    local color2 = data.color2 or ""
    
    exports.oxmysql:insert([[
        INSERT INTO insured_vehicles (plate, citizenid, playerName, modTier, isBusiness, startDate, endDate, category, name, color1, color2, insuranceCompany)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            citizenid = ?, playerName = ?, modTier = ?, isBusiness = ?, startDate = ?, endDate = ?, category = ?, name = ?, color1 = ?, color2 = ?, insuranceCompany = ?
    ]], {
        data.plate, data.citizenid, data.playerName, data.modTier, data.isBusiness, data.startDate, data.endDate, data.category, data.name, color1, color2, data.insuranceCompany,
        data.citizenid, data.playerName, data.modTier, data.isBusiness, data.startDate, data.endDate, data.category, data.name, color1, color2, data.insuranceCompany
    })
end

local function saveRegisteredVehicle(data)
    -- Handle nil values for color1 and color2
    local color1 = data.color1 or ""
    local color2 = data.color2 or ""
    
    exports.oxmysql:insert([[
        INSERT INTO registered_vehicles (plate, citizenid, playerName, registrationDate, category, name, color1, color2)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            citizenid = ?, playerName = ?, registrationDate = ?, category = ?, name = ?, color1 = ?, color2 = ?
    ]], {
        data.plate, data.citizenid, data.playerName, data.registrationDate, data.category, data.name, color1, color2,
        data.citizenid, data.playerName, data.registrationDate, data.category, data.name, color1, color2
    })
end

local function saveInspectedVehicle(data)
    -- Handle nil values for color1 and color2
    local color1 = data.color1 or ""
    local color2 = data.color2 or ""
    
    exports.oxmysql:insert([[
        INSERT INTO inspected_vehicles (plate, citizenid, playerName, inspectionDate, category, name, color1, color2)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            citizenid = ?, playerName = ?, inspectionDate = ?, category = ?, name = ?, color1 = ?, color2 = ?
    ]], {
        data.plate, data.citizenid, data.playerName, data.inspectionDate, data.category, data.name, color1, color2,
        data.citizenid, data.playerName, data.inspectionDate, data.category, data.name, color1, color2
    })
end

-- Replace the existing processVehicleData function with this updated version
local function processVehicleData(src, vehicleData, isCheck, isRegistration, isInspection, isCheckInspection, isCheckRegistration)
    if not vehicleData then
        TriggerClientEvent('ox_lib:notify', src, { 
            type = 'error', 
            title = isCheckRegistration and 'Check Registration' or isCheckInspection and 'Check Inspection' or isInspection and 'Inspection' or isRegistration and 'Registration' or 'Insurance', 
            description = 'Vehicle data missing.', 
            position = 'top' 
        })
        return nil
    end

    local identifier, playerName = getPlayerIdentifier(src)
    local plate = vehicleData.plate
    local category = vehicleData.category or "compacts"
    
    -- Override for emergency vehicles
    if vehicleData.category == "emergency" then
        playerName = "GOV" -- Set player name to GOV for emergency vehicles
        identifier = "GOV" -- Set citizenid to GOV for consistency
    end

    -- Default values
    local modTier = tonumber(vehicleData.modTier) or 1
    local isBusinessUse = vehicleData.isBusiness and (vehicleData.isBusiness == true or vehicleData.isBusiness == 1) or false
    local insuranceCompany = vehicleData.category == "emergency" and "LosSantosGov" or "MNC" -- Set Los Santos Gov for emergency vehicles
    
    -- Clamp modTier
    if modTier < 1 then modTier = 1 end
    if modTier > 5 then modTier = 5 end

    -- Check inspection status
    local isInspected = vehicleData.category == "emergency" -- Auto-inspect emergency vehicles
    local inspectionDate = os.date("%d/%m/%Y")
    loadVehicleData(plate, 'inspected_vehicles', function(data)
        if data then
            isInspected = true
            if isCheckInspection then
                inspectionDate = data.inspectionDate or inspectionDate
                if vehicleData.category ~= "emergency" then
                    playerName = data.playerName or playerName
                    identifier = data.citizenid or identifier
                end
            end
        end
    end)
    Citizen.Wait(100)

    -- Check registration status
    local isRegistered = vehicleData.category == "emergency" -- Auto-register emergency vehicles
    local registrationDate = os.date("%d/%m/%Y")
    loadVehicleData(plate, 'registered_vehicles', function(data)
        if data then
            isRegistered = true
            if isCheckRegistration then
                registrationDate = data.registrationDate or registrationDate
                if vehicleData.category ~= "emergency" then
                    playerName = data.playerName or playerName
                    identifier = data.citizenid or identifier
                end
            end
        end
    end)
    Citizen.Wait(100)

    -- Check current insurance status
    local existingInsurance = nil
    local isInsured = vehicleData.category == "emergency" -- Auto-insure emergency vehicles
    local isExpired = false
    local startDate = os.date("%d/%m/%Y")
    local endDate = os.date("%d/%m/%Y", os.time() + (30*24*60*60))
    
    loadVehicleData(plate, 'insured_vehicles', function(data)
        existingInsurance = data
    end)
    Citizen.Wait(100)

    if existingInsurance then
        isExpired = isInsuranceExpired(existingInsurance.endDate)
        isInsured = not isExpired or vehicleData.category == "emergency" -- Ensure emergency vehicles stay insured
        insuranceCompany = existingInsurance.insuranceCompany or insuranceCompany
        if isCheck then
            modTier = existingInsurance.modTier or modTier
            isBusinessUse = existingInsurance.isBusiness or isBusinessUse
            startDate = existingInsurance.startDate or startDate
            endDate = existingInsurance.endDate or endDate
            if vehicleData.category ~= "emergency" then
                playerName = existingInsurance.playerName or playerName
                identifier = existingInsurance.citizenid or identifier
            end
        end
    end

    -- Auto-save data for emergency vehicles if not already present
    if vehicleData.category == "emergency" then
        -- Auto-save inspection
        if not isInspected then
            saveInspectedVehicle({
                plate = plate,
                citizenid = identifier,
                playerName = playerName,
                inspectionDate = inspectionDate,
                category = category,
                name = vehicleData.name or "Unknown",
                color1 = vehicleData.color1 or "",
                color2 = vehicleData.color2 or ""
            })
            isInspected = true
        end

        -- Auto-save registration
        if not isRegistered then
            saveRegisteredVehicle({
                plate = plate,
                citizenid = identifier,
                playerName = playerName,
                registrationDate = registrationDate,
                category = category,
                name = vehicleData.name or "Unknown",
                color1 = vehicleData.color1 or "",
                color2 = vehicleData.color2 or ""
            })
            isRegistered = true
        end

        -- Auto-save insurance
        if not existingInsurance then
            saveInsuredVehicle({
                plate = plate,
                citizenid = identifier,
                playerName = playerName,
                modTier = modTier,
                isBusiness = isBusinessUse,
                startDate = startDate,
                endDate = endDate,
                category = category,
                name = vehicleData.name or "Unknown",
                color1 = vehicleData.color1 or "",
                color2 = vehicleData.color2 or "",
                insuranceCompany = "LosSantosGov"
            })
            isInsured = true
            isExpired = false
        end
    end

    -- Calculate costs (skip cost for emergency vehicles)
    local categoryCost = categoryPrices[category] or 1000
    local modCost = modTierPrices[modTier] or 0
    local businessCost = isBusinessUse and businessFee or 0
    local tax = (categoryCost + modCost + businessCost) * 0.05
    local total = 0

    if isRegistration then
        total = vehicleData.category == "emergency" and 0 or registrationFee
    elseif isInspection then
        total = vehicleData.category == "emergency" and 0 or inspectionFee
    elseif vehicleData.category == "emergency" then
        total = 0 -- No cost for emergency vehicle insurance
    else
        total = calculateInsuranceCost(categoryCost, modCost, businessCost, fees, processFee, tax, insuranceCompany, isInsured, isExpired)
    end

    local data = {
        plate = plate,
        citizenid = identifier,
        playerName = playerName,
        modTier = modTier,
        isBusiness = isBusinessUse,
        startDate = startDate,
        endDate = endDate,
        category = category,
        name = vehicleData.name or "Unknown",
        color1 = vehicleData.color1 or "",
        color2 = vehicleData.color2 or "",
        isInsured = isInsured,
        isExpired = isExpired,
        isRegistered = isRegistered,
        isInspected = isInspected,
        registrationDate = registrationDate,
        inspectionDate = inspectionDate,
        total = total,
        insuranceCompany = insuranceCompany
    }

    return data
end

-- Event to validate registration prerequisites
RegisterNetEvent("mnc_insurance:validateRegistration")
AddEventHandler("mnc_insurance:validateRegistration", function(vehicleData)
    local src = source
    local plate = vehicleData.plate
    local isInspected = false

    loadVehicleData(plate, 'inspected_vehicles', function(data)
        if data then
            isInspected = true
        end
        TriggerClientEvent("mnc_insurance:validateRegistrationResult", src, vehicleData, isInspected)
    end)
end)

-- Event to validate insurance prerequisites
RegisterNetEvent("mnc_insurance:validateInsurance")
AddEventHandler("mnc_insurance:validateInsurance", function(vehicleData)
    local src = source
    local plate = vehicleData.plate
    local isInspected = false
    local isRegistered = false

    loadVehicleData(plate, 'inspected_vehicles', function(data)
        if data then
            isInspected = true
        end
        loadVehicleData(plate, 'registered_vehicles', function(data)
            if data then
                isRegistered = true
            end
            if not isInspected then
                TriggerClientEvent("mnc_insurance:validateInsuranceResult", src, vehicleData, false, "Vehicle must be inspected before insuring.")
            elseif not isRegistered then
                TriggerClientEvent("mnc_insurance:validateInsuranceResult", src, vehicleData, false, "Vehicle must be registered before insuring.")
            else
                TriggerClientEvent("mnc_insurance:validateInsuranceResult", src, vehicleData, true)
            end
        end)
    end)
end)

-- Event to get insurance data
RegisterNetEvent("mnc_insurance:getData")
AddEventHandler("mnc_insurance:getData", function(vehicleData)
    local src = source
    local data = processVehicleData(src, vehicleData, true, false, false, false, false)
    if data then
        TriggerClientEvent("mnc_insurance:openUI", src, data)
    end
end)

-- Event to check insurance data
RegisterNetEvent("mnc_insurance:checkData")
AddEventHandler("mnc_insurance:checkData", function(vehicleData)
    local src = source
    local data = processVehicleData(src, vehicleData, true, false, false, false, false)
    if data then
        TriggerClientEvent("mnc_insurance:checkUI", src, data)
    end
end)

-- Event to get registration data
RegisterNetEvent("mnc_insurance:getRegistrationData")
AddEventHandler("mnc_insurance:getRegistrationData", function(vehicleData)
    local src = source
    local data = processVehicleData(src, vehicleData, false, true, false, false, false)
    if data then
        TriggerClientEvent("mnc_insurance:registrationUI", src, data)
    end
end)

-- Event to check registration data
RegisterNetEvent("mnc_insurance:checkRegistrationData")
AddEventHandler("mnc_insurance:checkRegistrationData", function(vehicleData)
    local src = source
    local data = processVehicleData(src, vehicleData, false, false, false, false, true)
    if data then
        TriggerClientEvent("mnc_insurance:checkRegistrationUI", src, data)
    end
end)

-- Event to get inspection data
RegisterNetEvent("mnc_insurance:getInspectionData")
AddEventHandler("mnc_insurance:getInspectionData", function(vehicleData)
    local src = source
    local data = processVehicleData(src, vehicleData, false, false, true, false, false)
    if data then
        TriggerClientEvent("mnc_insurance:inspectionUI", src, data)
    end
end)

-- Event to check inspection data
RegisterNetEvent("mnc_insurance:checkInspectionData")
AddEventHandler("mnc_insurance:checkInspectionData", function(vehicleData)
    local src = source
    local data = processVehicleData(src, vehicleData, false, false, false, true, false)
    if data then
        TriggerClientEvent("mnc_insurance:checkInspectionUI", src, data)
    end
end)

-- Event to handle insurance purchase
RegisterNetEvent("mnc_insurance:purchase")
AddEventHandler("mnc_insurance:purchase", function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Insurance', description = 'Player data not found.', position = 'top' })
        return
    end

    local money = Player.PlayerData.money['bank']
    if money < data.total then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Insurance', description = 'Insufficient funds to purchase insurance.', position = 'top' })
        return
    end

    Player.Functions.RemoveMoney('bank', data.total, 'Insurance Purchase')
    saveInsuredVehicle({
        plate = data.plate,
        citizenid = data.citizenid,
        playerName = data.playerName,
        modTier = data.modTier,
        isBusiness = data.isBusiness,
        startDate = data.startDate,
        endDate = data.endDate,
        category = data.category,
        name = data.name,
        color1 = data.color1 or "",
        color2 = data.color2 or "",
        insuranceCompany = data.insuranceCompany
    })

    TriggerClientEvent('ox_lib:notify', src, { 
        type = 'success', 
        title = 'Insurance', 
        description = 'Insurance purchased successfully for $' .. data.total .. '.', 
        position = 'top' 
    })
end)

-- Event to handle vehicle registration
RegisterNetEvent("mnc_insurance:register")
AddEventHandler("mnc_insurance:register", function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Registration', description = 'Player data not found.', position = 'top' })
        return
    end

    local money = Player.PlayerData.money['bank']
    if money < data.total then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Registration', description = 'Insufficient funds to register vehicle.', position = 'top' })
        return
    end

    Player.Functions.RemoveMoney('bank', data.total, 'Vehicle Registration')
    saveRegisteredVehicle({
        plate = data.plate,
        citizenid = data.citizenid,
        playerName = data.playerName,
        registrationDate = data.registrationDate,
        category = data.category,
        name = data.name,
        color1 = data.color1 or "",
        color2 = data.color2 or ""
    })

    TriggerClientEvent('ox_lib:notify', src, { 
        type = 'success', 
        title = 'Registration', 
        description = 'Vehicle registered successfully for $' .. data.total .. '.', 
        position = 'top' 
    })
end)

-- Event to handle vehicle inspection
RegisterNetEvent("mnc_insurance:inspect")
AddEventHandler("mnc_insurance:inspect", function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Inspection', description = 'Player data not found.', position = 'top' })
        return
    end

    local money = Player.PlayerData.money['bank']
    if money < data.total then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', title = 'Inspection', description = 'Insufficient funds to inspect vehicle.', position = 'top' })
        return
    end

    Player.Functions.RemoveMoney('bank', data.total, 'Vehicle Inspection')
    saveInspectedVehicle({
        plate = data.plate,
        citizenid = data.citizenid,
        playerName = data.playerName,
        inspectionDate = data.inspectionDate,
        category = data.category,
        name = data.name,
        color1 = data.color1 or "",
        color2 = data.color2 or ""
    })

    TriggerClientEvent('ox_lib:notify', src, { 
        type = 'success', 
        title = 'Inspection', 
        description = 'Vehicle inspected successfully for $' .. data.total .. '.', 
        position = 'top' 
    })
end)


-- Replace the existing mnc_insurance:checkVehicleStatus event handler with this updated version
RegisterNetEvent("mnc_insurance:checkVehicleStatus")
AddEventHandler("mnc_insurance:checkVehicleStatus", function(plate, category)
    local src = source
    
    local isInspected = false
    local isRegistered = false
    local isInsured = false
    local isExpired = false
    local playerName = "Unknown"
    local insuranceCompany = "MNC"
    
    -- Handle emergency vehicles (class 18)
    if category == "emergency" then
        isInspected = true
        isRegistered = true
        isInsured = true
        isExpired = false
        playerName = "GOV"
        insuranceCompany = "LosSantosGov"
        
        -- Auto-save records for emergency vehicles if they don't exist
        loadVehicleData(plate, 'inspected_vehicles', function(data)
            if not data then
                saveInspectedVehicle({
                    plate = plate,
                    citizenid = "GOV",
                    playerName = "GOV",
                    inspectionDate = os.date("%d/%m/%Y"),
                    category = category,
                    name = "Emergency Vehicle",
                    color1 = "",
                    color2 = ""
                })
            end
        end)
        Citizen.Wait(50)
        
        loadVehicleData(plate, 'registered_vehicles', function(data)
            if not data then
                saveRegisteredVehicle({
                    plate = plate,
                    citizenid = "GOV",
                    playerName = "GOV",
                    registrationDate = os.date("%d/%m/%Y"),
                    category = category,
                    name = "Emergency Vehicle",
                    color1 = "",
                    color2 = ""
                })
            end
        end)
        Citizen.Wait(50)
        
        loadVehicleData(plate, 'insured_vehicles', function(data)
            if not data then
                saveInsuredVehicle({
                    plate = plate,
                    citizenid = "GOV",
                    playerName = "GOV",
                    modTier = 1,
                    isBusiness = false,
                    startDate = os.date("%d/%m/%Y"),
                    endDate = os.date("%d/%m/%Y", os.time() + (30*24*60*60)),
                    category = category,
                    name = "Emergency Vehicle",
                    color1 = "",
                    color2 = "",
                    insuranceCompany = "LosSantosGov"
                })
            end
        end)
        Citizen.Wait(50)
    else
        -- Check database for non-emergency vehicles
        loadVehicleData(plate, 'inspected_vehicles', function(data)
            if data then
                isInspected = true
                playerName = data.playerName or playerName
            end
        end)
        Citizen.Wait(50)
        
        loadVehicleData(plate, 'registered_vehicles', function(data)
            if data then
                isRegistered = true
                playerName = data.playerName or playerName
            end
        end)
        Citizen.Wait(50)
        
        loadVehicleData(plate, 'insured_vehicles', function(data)
            if data then
                isExpired = isInsuranceExpired(data.endDate)
                isInsured = not isExpired
                playerName = data.playerName or playerName
                insuranceCompany = data.insuranceCompany or insuranceCompany
            end
        end)
        Citizen.Wait(50)
    end
    
    TriggerClientEvent("mnc_insurance:vehicleStatusNotification", src, {
        isInspected = isInspected,
        isRegistered = isRegistered,
        isInsured = isInsured,
        isExpired = isExpired,
        playerName = playerName,
        insuranceCompany = insuranceCompany
    })
end)

print("^2[mnc-insurance]^7 Script loaded successfully!")