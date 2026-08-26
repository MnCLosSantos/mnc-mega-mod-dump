local QBCore = exports['qb-core']:GetCoreObject()

-- Store active discounts per location (in-memory cache)
local activeDiscounts = {}
local activeSpecials = {}
local databaseReady = false

-- Wait for oxmysql and initialize database
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do
        Wait(100)
    end

    if Config.Debug then
        print("^3[mnc-pricesheets]^7 Waiting for oxmysql to initialize database connection...")
    end

    -- Small delay to let oxmysql fully connect (common workaround)
    Wait(2000)

    if Config.Debug then
        print("^2[mnc-pricesheets]^7 oxmysql ready - creating tables if needed")
    end

    -- Create discounts table if it doesn't exist
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS pricesheet_discounts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            sheet_index INT NOT NULL,
            category VARCHAR(100) NOT NULL,
            item_index INT NOT NULL,
            discount INT NOT NULL,
            applied_by VARCHAR(50) NOT NULL,
            applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_discount (sheet_index, category, item_index)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Create specials table if it doesn't exist
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS pricesheet_specials (
            id INT AUTO_INCREMENT PRIMARY KEY,
            sheet_index INT NOT NULL,
            name VARCHAR(100) NOT NULL,
            description TEXT,
            original_price DECIMAL(10,2) NOT NULL,
            sale_price DECIMAL(10,2) NOT NULL,
            image VARCHAR(100) NOT NULL,
            applied_by VARCHAR(50) NOT NULL,
            applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Load existing discounts and specials
    LoadDiscountsFromDatabase()
    LoadSpecialsFromDatabase()
    databaseReady = true

    if Config.Debug then
        print("^2[mnc-pricesheets]^7 Database ready and data loaded")
    end
end)

-- Load all discounts from database into memory
function LoadDiscountsFromDatabase()
    MySQL.query('SELECT * FROM pricesheet_discounts', {}, function(results)
        if results and #results > 0 then
            for _, row in ipairs(results) do
                if not activeDiscounts[row.sheet_index] then
                    activeDiscounts[row.sheet_index] = {}
                end
                if not activeDiscounts[row.sheet_index][row.category] then
                    activeDiscounts[row.sheet_index][row.category] = {}
                end
                activeDiscounts[row.sheet_index][row.category][tonumber(row.item_index)] = row.discount
            end
            if Config.Debug then
                print("^2[mnc-pricesheets]^7 Loaded " .. #results .. " discounts from database")
            end
        else
            if Config.Debug then
                print("^2[mnc-pricesheets]^7 No existing discounts found in database")
            end
        end
    end)
end

-- Load all specials from database into memory
function LoadSpecialsFromDatabase()
    MySQL.query('SELECT * FROM pricesheet_specials ORDER BY applied_at DESC', {}, function(results)
        if results and #results > 0 then
            for _, row in ipairs(results) do
                if not activeSpecials[row.sheet_index] then
                    activeSpecials[row.sheet_index] = {}
                end
                table.insert(activeSpecials[row.sheet_index], {
                    id = row.id,
                    name = row.name,
                    description = row.description,
                    originalPrice = tonumber(row.original_price),
                    salePrice = tonumber(row.sale_price),
                    image = row.image
                })
            end
            if Config.Debug then
                print("^2[mnc-pricesheets]^7 Loaded " .. #results .. " specials from database")
            end
        else
            if Config.Debug then
                print("^2[mnc-pricesheets]^7 No existing specials found in database")
            end
        end
    end)
end

-- Check if player can apply discounts
local function CanApplyDiscounts(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local jobName = Player.PlayerData.job.name
    local jobGrade = Player.PlayerData.job.grade.level
    
    if Config.DiscountPermissions[jobName] then
        for _, grade in ipairs(Config.DiscountPermissions[jobName]) do
            if jobGrade >= grade then
                return true
            end
        end
    end
    
    return false
end

-- Get active discounts for a sheet
QBCore.Functions.CreateCallback('mnc-pricesheets:getPersistentData', function(source, cb, sheetIndex)
    if Config.Debug then
        print("^2[mnc-pricesheets SERVER]^7 Callback requested for sheet " .. sheetIndex)
        print("^2[mnc-pricesheets SERVER]^7 Current specials in memory:")
        print(json.encode(activeSpecials[sheetIndex] or {}, {indent = true}))
    end
    
    cb({
        discounts = activeDiscounts[sheetIndex] or {},
        specials = activeSpecials[sheetIndex] or {}
    })
end)

-- Apply discount
RegisterNetEvent('mnc-pricesheets:applyDiscount', function(sheetIndex, category, itemIndex, discount)
    local src = source
    
    if not CanApplyDiscounts(src) then
        if Config.Debug then
            print("^3[mnc-pricesheets]^7 Player " .. src .. " attempted to apply discount without permission")
        end
        return
    end
    
    if discount > Config.MaxDiscountPercent then
        if Config.Debug then
            print("^3[mnc-pricesheets]^7 Player " .. src .. " attempted to apply discount exceeding maximum")
        end
        return
    end
    
    itemIndex = tonumber(itemIndex) + 1  -- Convert from 0-based (client) to 1-based (config/db)
    
    -- Update memory cache
    if not activeDiscounts[sheetIndex] then
        activeDiscounts[sheetIndex] = {}
    end
    
    if not activeDiscounts[sheetIndex][category] then
        activeDiscounts[sheetIndex][category] = {}
    end
    
    activeDiscounts[sheetIndex][category][itemIndex] = discount
    
    -- Save to database
    if databaseReady then
        local Player = QBCore.Functions.GetPlayer(src)
        local appliedBy = Player and Player.PlayerData.name or "Unknown"
        
        MySQL.insert([[
            INSERT INTO pricesheet_discounts (sheet_index, category, item_index, discount, applied_by) 
            VALUES (?, ?, ?, ?, ?) 
            ON DUPLICATE KEY UPDATE discount = ?, applied_by = ?, applied_at = CURRENT_TIMESTAMP
        ]], {
            sheetIndex, category, itemIndex, discount, appliedBy,
            discount, appliedBy
        }, function(insertId)
            if Config.Debug then
                print(("^2[mnc-pricesheets]^7 %s applied %d%% discount to sheet %d, category %s, item %d"):format(
                    appliedBy, discount, sheetIndex, category, itemIndex
                ))
            end
        end)
    else
        if Config.Debug then
            print("^3[mnc-pricesheets]^7 Database not ready, discount saved to memory only")
        end
    end
    
    TriggerClientEvent('mnc-pricesheets:updateDiscounts', -1, sheetIndex, activeDiscounts[sheetIndex])
    TriggerClientEvent('mnc-pricesheets:discountApplied', src)
end)

-- Remove discount
RegisterNetEvent('mnc-pricesheets:removeDiscount', function(sheetIndex, category, itemIndex)
    local src = source
    
    if not CanApplyDiscounts(src) then
        return
    end
    
    itemIndex = tonumber(itemIndex) + 1  -- Convert from 0-based (client) to 1-based (config/db)
    
    if activeDiscounts[sheetIndex] and activeDiscounts[sheetIndex][category] and activeDiscounts[sheetIndex][category][itemIndex] then
        activeDiscounts[sheetIndex][category][itemIndex] = nil
        
        if databaseReady then
            MySQL.query('DELETE FROM pricesheet_discounts WHERE sheet_index = ? AND category = ? AND item_index = ?', {
                sheetIndex, category, itemIndex
            }, function(result)
                if result and (result.affectedRows or 0) > 0 then
                    if Config.Debug then
                        local Player = QBCore.Functions.GetPlayer(src)
                        print(("^2[mnc-pricesheets]^7 %s removed discount from sheet %d, category %s, item %d"):format(
                            Player and Player.PlayerData.name or "Unknown", sheetIndex, category, itemIndex
                        ))
                    end
                end
            end)
        else
            if Config.Debug then
                print("^3[mnc-pricesheets]^7 Database not ready, discount removed from memory only")
            end
        end
        
        TriggerClientEvent('mnc-pricesheets:updateDiscounts', -1, sheetIndex, activeDiscounts[sheetIndex])
        TriggerClientEvent('mnc-pricesheets:discountRemoved', src)
    end
end)

-- Create special
RegisterNetEvent('mnc-pricesheets:createSpecial', function(sheetIndex, name, description, originalPrice, salePrice, image)
    local src = source
    
    if not CanApplyDiscounts(src) then
        return
    end
    
    if databaseReady then
        local Player = QBCore.Functions.GetPlayer(src)
        local appliedBy = Player and Player.PlayerData.name or "Unknown"
        
        MySQL.insert('INSERT INTO pricesheet_specials (sheet_index, name, description, original_price, sale_price, image, applied_by) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            sheetIndex, name, description, originalPrice, salePrice, image, appliedBy
        }, function(insertId)
            if not activeSpecials[sheetIndex] then
                activeSpecials[sheetIndex] = {}
            end
            
            table.insert(activeSpecials[sheetIndex], {
                id = insertId,
                name = name,
                description = description,
                originalPrice = originalPrice,
                salePrice = salePrice,
                image = image
            })
            
            if Config.Debug then
                print(("^2[mnc-pricesheets SERVER]^7 %s created special '%s' (ID: %d) for sheet %d"):format(
                    appliedBy, name, insertId, sheetIndex
                ))
                print("^2[mnc-pricesheets SERVER]^7 Current specials after creation:")
                print(json.encode(activeSpecials[sheetIndex], {indent = true}))
            end
            
            TriggerClientEvent('mnc-pricesheets:updateSpecials', -1, sheetIndex, activeSpecials[sheetIndex])
            TriggerClientEvent('mnc-pricesheets:specialCreated', src)
        end)
    end
end)

-- FIXED: Remove special with proper cache update
RegisterNetEvent('mnc-pricesheets:removeSpecial', function(sheetIndex, specialId)
    local src = source
    
    if not CanApplyDiscounts(src) then
        if Config.Debug then
            print("^3[mnc-pricesheets SERVER]^7 Player " .. src .. " attempted to remove special without permission")
        end
        return
    end
    
    specialId = tonumber(specialId)
    
    if Config.Debug then
        print("^2[mnc-pricesheets SERVER]^7 Removing special ID " .. specialId .. " from sheet " .. sheetIndex)
        print("^2[mnc-pricesheets SERVER]^7 Specials before removal:")
        print(json.encode(activeSpecials[sheetIndex] or {}, {indent = true}))
    end
    
    -- CRITICAL FIX: Update cache first, then delete from database
    -- This ensures the cache is always updated even if DB delete reports 0 rows
    local removed = false
    if activeSpecials[sheetIndex] then
        for i = #activeSpecials[sheetIndex], 1, -1 do
            if activeSpecials[sheetIndex][i].id == specialId then
                table.remove(activeSpecials[sheetIndex], i)
                removed = true
                if Config.Debug then
                    print("^2[mnc-pricesheets SERVER]^7 Removed special from memory cache at index " .. i)
                end
                break
            end
        end
    end
    
    if removed then
        if Config.Debug then
            local Player = QBCore.Functions.GetPlayer(src)
            print(("^2[mnc-pricesheets SERVER]^7 %s removed special ID %d from sheet %d"):format(
                Player and Player.PlayerData.name or "Unknown", specialId, sheetIndex
            ))
            print("^2[mnc-pricesheets SERVER]^7 Specials after removal:")
            print(json.encode(activeSpecials[sheetIndex] or {}, {indent = true}))
        end
        
        -- Delete from database (async, don't wait for result)
        if databaseReady then
            MySQL.query('DELETE FROM pricesheet_specials WHERE id = ? AND sheet_index = ?', {
                specialId, sheetIndex
            })
        end
        
        -- Send updated specials list to all clients immediately
        TriggerClientEvent('mnc-pricesheets:updateSpecials', -1, sheetIndex, activeSpecials[sheetIndex])
        TriggerClientEvent('mnc-pricesheets:specialRemoved', src)
    else
        if Config.Debug then
            print("^3[mnc-pricesheets SERVER]^7 Could not find special ID " .. specialId .. " in memory cache")
        end
    end
end)

print("^2[mnc-pricesheets]^7 Script loaded successfully!")