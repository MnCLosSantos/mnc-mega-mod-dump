-- server/server.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Track active insurances with expiration times
local activeInsurance = {} -- {plate = {endTime = timestamp, citizenid = string}}

-- Database save functions (must be defined first)
local function saveInsuredVehicle(data)
    exports.oxmysql:insert('INSERT INTO insured_vehicles (plate, citizenid, playerName, modTier, isBusiness, startDate, endDate, category, name, color1, color2, insuranceCompany) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        data.plate, data.citizenid, data.playerName, data.modTier, data.isBusiness, data.startDate, data.endDate, data.category, data.name, data.color1 or 0, data.color2 or 0, data.insuranceCompany
    }, function(insertId)
        if Config.Debug then
            if insertId then
                print("^2[mnc-rentals]^7 Insurance inserted successfully for plate: " .. data.plate .. " (ID: " .. insertId .. ")")
            else
                print("^1[mnc-rentals]^7 Failed to insert insurance for plate: " .. data.plate .. " (check table columns or DB error)")
            end
        end
    end)
end

local function saveRegisteredVehicle(data)
    exports.oxmysql:insert('INSERT INTO registered_vehicles (plate, citizenid, playerName, registrationDate, category, name, color1, color2) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        data.plate, data.citizenid, data.playerName, data.registrationDate, data.category, data.name, data.color1 or 0, data.color2 or 0
    }, function(insertId)
        if Config.Debug then
            if insertId then
                print("^2[mnc-rentals]^7 Registration inserted successfully for plate: " .. data.plate .. " (ID: " .. insertId .. ")")
            else
                print("^1[mnc-rentals]^7 Failed to insert registration for plate: " .. data.plate)
            end
        end
    end)
end

local function saveInspectedVehicle(data)
    exports.oxmysql:insert('INSERT INTO inspected_vehicles (plate, citizenid, playerName, inspectionDate, category, name, color1, color2) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        data.plate, data.citizenid, data.playerName, data.inspectionDate, data.category, data.name, data.color1 or 0, data.color2 or 0
    }, function(insertId)
        if Config.Debug then
            if insertId then
                print("^2[mnc-rentals]^7 Inspection inserted successfully for plate: " .. data.plate .. " (ID: " .. insertId .. ")")
            else
                print("^1[mnc-rentals]^7 Failed to insert inspection for plate: " .. data.plate)
            end
        end
    end)
end

-- Database load function
local function loadVehicleData(plate, tableName, cb)
    exports.oxmysql:fetch('SELECT * FROM ' .. tableName .. ' WHERE plate = ?', {plate}, function(result)
        if result and #result > 0 then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end

local function removeInsuredVehicle(plate)
    exports.oxmysql:execute('DELETE FROM insured_vehicles WHERE plate = ?', {plate}, function(result)
        if result and result.affectedRows and result.affectedRows > 0 and Config.Debug then
            print("^3[mnc-rentals]^7 Removed insurance for plate: " .. plate)
        end
    end)
end

local function removeRegisteredVehicle(plate)
    exports.oxmysql:execute('DELETE FROM registered_vehicles WHERE plate = ?', {plate}, function(result)
        if result and result.affectedRows and result.affectedRows > 0 and Config.Debug then
            print("^3[mnc-rentals]^7 Removed registration for plate: " .. plate)
        end
    end)
end

local function removeInspectedVehicle(plate)
    exports.oxmysql:execute('DELETE FROM inspected_vehicles WHERE plate = ?', {plate}, function(result)
        if result and result.affectedRows and result.affectedRows > 0 and Config.Debug then
            print("^3[mnc-rentals]^7 Removed inspection for plate: " .. plate)
        end
    end)
end

-- Count how many active rentals a player has
local function countPlayerRentals(citizenid)
    local count = 0
    for plate, data in pairs(activeInsurance) do
        if data.citizenid == citizenid then
            count = count + 1
        end
    end
    return count
end

-- Get current server timestamp
lib.callback.register('mnc-rentals:getCurrentTime', function(source)
    return os.time()
end)

-- Process rental (check money, calculate times, deduct payment)
lib.callback.register('mnc-rentals:processRental', function(source, price, hours)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Check if player has reached rental limit (3 max)
    local rentalCount = countPlayerRentals(citizenid)
    if rentalCount >= 3 then
        return {error = "rental_limit"}
    end
    
    if Player.PlayerData.money.cash >= price then
        Player.Functions.RemoveMoney('cash', price)
        
        local currentTime = os.time()
        local endTime = currentTime + (hours * 3600) -- hours to seconds
        local refundAmount = math.floor(price * 0.1)
        
        return {
            endTime = endTime,
            refundAmount = refundAmount
        }
    end
    
    return nil
end)

-- Check if player has the required item
lib.callback.register('mnc-rentals:hasItem', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    local count = Player.Functions.GetItemByName(item)
    return count and count.amount > 0
end)

-- Grant temporary insurance, registration & inspection with expiration time
RegisterNetEvent('mnc-rentals:grantTemporaryInsurance', function(plate, category, name, color1, color2, model, endTime)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local currentDate = os.date("%d/%m/%Y")

    -- Extend end date by 2 days to ensure it's in the future even on short rentals
    local adjustedEndTime = endTime + (48 * 3600)  -- Add 48 hours
    local endDate = os.date("%d/%m/%Y", adjustedEndTime)

    -- Store expiration time with citizenid
    activeInsurance[plate] = {
        endTime = endTime,
        citizenid = citizenid
    }

    local insuranceData = {
        plate = plate,
        citizenid = citizenid,
        playerName = playerName,
        modTier = 1,
        isBusiness = false,
        startDate = currentDate,
        endDate = endDate,
        category = category,
        name = name,
        color1 = color1,
        color2 = color2,
        insuranceCompany = 'MNC'
    }

    loadVehicleData(plate, 'insured_vehicles', function(data)
        if not data then
            saveInsuredVehicle(insuranceData)
            if Config.Debug then
                print("^2[mnc-rentals]^7 Temporary INSURANCE granted for plate: " .. plate .. " (ends " .. endDate .. ")")
            end
        else
            if Config.Debug then
                print("^3[mnc-rentals]^7 Insurance already exists for plate: " .. plate)
            end
        end
    end)

    local regData = {
        plate = plate,
        citizenid = citizenid,
        playerName = playerName,
        registrationDate = currentDate,
        category = category,
        name = name,
        color1 = color1,
        color2 = color2
    }

    loadVehicleData(plate, 'registered_vehicles', function(data)
        if not data then
            saveRegisteredVehicle(regData)
            if Config.Debug then
                print("^2[mnc-rentals]^7 Temporary REGISTRATION granted for plate: " .. plate)
            end
        end
    end)

    local inspData = {
        plate = plate,
        citizenid = citizenid,
        playerName = playerName,
        inspectionDate = currentDate,
        category = category,
        name = name,
        color1 = color1,
        color2 = color2
    }

    loadVehicleData(plate, 'inspected_vehicles', function(data)
        if not data then
            saveInspectedVehicle(inspData)
            if Config.Debug then
                print("^2[mnc-rentals]^7 Temporary INSPECTION granted for plate: " .. plate)
            end
        end
    end)
end)

-- Handle vehicle return with refund
RegisterNetEvent('mnc-rentals:returnVehicle', function(plate, refundAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Give refund to bank account
    Player.Functions.AddMoney('bank', refundAmount, 'Vehicle rental refund')
    
    -- Remove insurance records
    removeInsuredVehicle(plate)
    removeRegisteredVehicle(plate)
    removeInspectedVehicle(plate)
    
    -- Remove from active insurance tracking
    activeInsurance[plate] = nil
    
    if Config.Debug then
        print("^2[mnc-rentals]^7 Vehicle returned: " .. plate .. " | Refund: $" .. refundAmount)
    end
end)

-- Expire insurance when rental time is up
RegisterNetEvent('mnc-rentals:expireInsurance', function(plate)
    if activeInsurance[plate] then
        removeInsuredVehicle(plate)
        removeRegisteredVehicle(plate)
        removeInspectedVehicle(plate)
        activeInsurance[plate] = nil
        if Config.Debug then
            print("^3[mnc-rentals]^7 Insurance expired for plate: " .. plate)
        end
    end
end)

-- Periodic cleanup of expired insurances (every 5 minutes)
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        
        local currentTime = os.time()
        for plate, data in pairs(activeInsurance) do
            if currentTime > data.endTime then
                -- Insurance expired, remove from database
                removeInsuredVehicle(plate)
                removeRegisteredVehicle(plate)
                removeInspectedVehicle(plate)
                activeInsurance[plate] = nil
                if Config.Debug then
                    print("^3[mnc-rentals]^7 Auto-cleaned expired insurance for plate: " .. plate)
                end
            end
        end
    end
end)

-- Clean up player's rentals when they disconnect
AddEventHandler('playerDropped', function(reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Find and remove all rental plates belonging to this player
    for plate, data in pairs(activeInsurance) do
        if data.citizenid == citizenid then
            -- Remove insurance for this rental
            removeInsuredVehicle(plate)
            removeRegisteredVehicle(plate)
            removeInspectedVehicle(plate)
            activeInsurance[plate] = nil
            if Config.Debug then
                print("^3[mnc-rentals]^7 Removed rental insurance on disconnect for plate: " .. plate .. " (Player: " .. citizenid .. ")")
            end
        end
    end
end)

print("^2[mnc-rentals]^7 Script loaded successfully!")
