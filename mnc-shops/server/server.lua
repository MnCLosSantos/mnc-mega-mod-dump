local QBCore = exports['qb-core']:GetCoreObject()
local ox_inventory = GetResourceState('ox_inventory') == 'started' and exports.ox_inventory or nil
local qb_inventory = GetResourceState('qb-inventory') == 'started' and exports['qb-inventory'] or nil

-- Function to check if player can carry item
local function canCarryItem(src, item, quantity)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    local itemData = QBCore.Shared.Items[item]
    if not itemData then return false end

    if ox_inventory and exports.ox_inventory.CanCarryItem then
        return ox_inventory:CanCarryItem(src, item, quantity)
    elseif qb_inventory then
        local weight = itemData.weight or 0
        local totalWeight = weight * quantity
        local playerInventory = Player.PlayerData.items
        local currentWeight = 0
        local itemCount = 0

        for _, invItem in pairs(playerInventory) do
            local invItemData = QBCore.Shared.Items[invItem.name]
            if invItemData then
                currentWeight = currentWeight + (invItemData.weight * invItem.amount)
                itemCount = itemCount + 1
            end
        end

        local maxWeight = Config.MaxWeight or 120000
        local maxSlots = Config.MaxSlots or 41
        local isNewItem = not playerInventory[item]

        return (currentWeight + totalWeight) <= maxWeight and (isNewItem and itemCount < maxSlots or not isNewItem)
    else
        return true
    end
end

-- Restock all shops to initial amounts
local function restockAllShops()
    for _, zone in ipairs(Config.Zones) do
        zone.stock = {}
        if zone.categories then
            for _, category in ipairs(zone.categories) do
                if Config.Products[category] then
                    zone.stock[category] = {}
                    for _, item in ipairs(Config.Products[category]) do
                        zone.stock[category][item.name] = item.amount
                    end
                end
            end
        else
            if Config.Products[zone.name] then
                zone.stock[zone.name] = {}
                for _, item in ipairs(Config.Products[zone.name]) do
                    zone.stock[zone.name][item.name] = item.amount
                end
            end
        end
        -- Notify all clients to update their stock
        TriggerClientEvent('mnc-shops:receiveStock', -1, zone.name, zone.stock[zone.name] or {})
    end
    if Config.Debug then
        print("[MNC-Shops] All shops have been restocked to their initial amounts.")
    end
end

-- Restock all shops when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        restockAllShops()
    end
end)

-- Fetch current stock for a zone
RegisterServerEvent('mnc-shops:fetchStock')
AddEventHandler('mnc-shops:fetchStock', function(zoneName)
    local src = source
    local targetZone = nil
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName or (zone.categories and table.contains(zone.categories, zoneName)) then
            targetZone = zone
            break
        end
    end

    if not targetZone then
        TriggerClientEvent('mnc-shops:notifyInventoryFull', src, nil, "Zone not found")
        return
    end

    -- Initialize zone stock if not exists
    if not targetZone.stock then
        targetZone.stock = {}
        if targetZone.categories then
            for _, category in ipairs(targetZone.categories) do
                if Config.Products[category] then
                    targetZone.stock[category] = {}
                    for _, itemData in ipairs(Config.Products[category]) do
                        targetZone.stock[category][itemData.name] = itemData.amount
                    end
                end
            end
        else
            if Config.Products[zoneName] then
                targetZone.stock[zoneName] = {}
                for _, itemData in ipairs(Config.Products[zoneName]) do
                    targetZone.stock[zoneName][itemData.name] = itemData.amount
                end
            end
        end
    end

    -- Send the stock data back to the client
    TriggerClientEvent('mnc-shops:receiveStock', src, zoneName, targetZone.stock[zoneName] or {})
end)

-- Update stock for a zone
RegisterServerEvent('mnc-shops:updateStock')
AddEventHandler('mnc-shops:updateStock', function(zoneName, item, stockAmount)
    local targetZone = nil
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName or (zone.categories and table.contains(zone.categories, zoneName)) then
            targetZone = zone
            break
        end
    end

    if targetZone and targetZone.stock and targetZone.stock[zoneName] then
        targetZone.stock[zoneName][item] = stockAmount
    end
end)

-- Handle single item purchase
RegisterServerEvent('mnc-shops:submitPurchase')
AddEventHandler('mnc-shops:submitPurchase', function(item, quantity, paymentType, zoneName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Find the zone
    local targetZone = nil
    for _, zone in ipairs(Config.Zones) do
        if zone.name == zoneName or (zone.categories and table.contains(zone.categories, zoneName)) then
            targetZone = zone
            break
        end
    end

    if not targetZone then
        TriggerClientEvent('mnc-shops:notifyInventoryFull', src, item, "Zone not found")
        return
    end

    -- Initialize zone stock if not exists
    if not targetZone.stock then
        targetZone.stock = {}
    end
    if not targetZone.stock[zoneName] then
        targetZone.stock[zoneName] = {}
        if Config.Products[zoneName] then
            for _, itemData in ipairs(Config.Products[zoneName]) do
                targetZone.stock[zoneName][itemData.name] = itemData.amount
            end
        end
    end

    -- Find the item in zone stock
    local itemStock = targetZone.stock[zoneName][item]
    local itemData = nil
    for _, shopItems in pairs(Config.Products) do
        for _, i in ipairs(shopItems) do
            if i.name == item and QBCore.Shared.Items[item] then
                itemData = i
                break
            end
        end
        if itemData then break end
    end

    if not itemData or not itemStock then
        TriggerClientEvent('mnc-shops:notifyInventoryFull', src, item, "Item not found")
        return
    end

    local itemLabel = QBCore.Shared.Items[item].label or item:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end)

    -- Check stock availability
    if itemStock < quantity then
        TriggerClientEvent('mnc-shops:notifyInventoryFull', src, itemLabel, "Insufficient stock for " .. itemLabel)
        return
    end

    -- Check if player can carry the item
    if not canCarryItem(src, item, quantity) then
        TriggerClientEvent('mnc-shops:notifyInventoryFull', src, itemLabel)
        TriggerClientEvent('mnc-shops:restoreStock', src, item, quantity, zoneName) -- Restore stock on client
        return
    end

    local totalPrice = itemData.price * quantity

    -- Check payment availability
    if (paymentType == 'cash' and Player.PlayerData.money.cash < totalPrice) or
       (paymentType == 'bank' and Player.PlayerData.money.bank < totalPrice) then
        TriggerClientEvent('mnc-shops:notifyInventoryFull', src, itemLabel, "Insufficient funds for " .. itemLabel)
        TriggerClientEvent('mnc-shops:restoreStock', src, item, quantity, zoneName) -- Restore stock on client
        return
    end

    -- Attempt to add item to inventory
    local success = false
    if ox_inventory and exports.ox_inventory.AddItem then
        success = ox_inventory:AddItem(src, item, quantity)
    elseif qb_inventory then
        success = Player.Functions.AddItem(item, quantity)
        if success then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Item Purchased',
                description = 'Added ' .. quantity .. 'x ' .. itemLabel .. ' to your inventory.',
                type = 'success',
                duration = 5000
            })
        end
    else
        success = Player.Functions.AddItem(item, quantity)
    end

    if not success then
        TriggerClientEvent('mnc-shops:notifyInventoryFull', src, itemLabel, "Failed to add item to inventory")
        TriggerClientEvent('mnc-shops:restoreStock', src, item, quantity, zoneName) -- Restore stock on client
        return
    end

    -- Deduct payment and update stock only after successful item addition
    if paymentType == 'cash' then
        Player.Functions.RemoveMoney('cash', totalPrice)
    else
        Player.Functions.RemoveMoney('bank', totalPrice)
    end

    -- Update stock
    targetZone.stock[zoneName][item] = targetZone.stock[zoneName][item] - quantity
end)

-- Handle cart purchase
RegisterServerEvent('mnc-shops:submitCart')
AddEventHandler('mnc-shops:submitCart', function(cart, bankPercent)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local totalCost = 0
    local itemsValid = true
    local canCarryAll = true
    local itemDataMap = {}
    local zoneStockMap = {}

    -- Validate items, check stock, calculate total cost, and check inventory
    for _, cartItem in ipairs(cart) do
        -- Find the zone
        local targetZone = nil
        for _, zone in ipairs(Config.Zones) do
            if zone.name == cartItem.zone or (zone.categories and table.contains(zone.categories, cartItem.zone)) then
                targetZone = zone
                break
            end
        end

        if not targetZone then
            local itemLabel = cartItem.item:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end)
            TriggerClientEvent('mnc-shops:notifyInventoryFull', src, itemLabel, "Zone not found")
            -- Restore all cart items to stock
            for _, cItem in ipairs(cart) do
                TriggerClientEvent('mnc-shops:restoreStock', src, cItem.item, cItem.quantity, cItem.zone)
            end
            return
        end

        -- Initialize zone stock if not exists
        if not targetZone.stock then
            targetZone.stock = {}
        end
        if not targetZone.stock[cartItem.zone] then
            targetZone.stock[cartItem.zone] = {}
            if Config.Products[cartItem.zone] then
                for _, itemData in ipairs(Config.Products[cartItem.zone]) do
                    targetZone.stock[cartItem.zone][itemData.name] = itemData.amount
                end
            end
        end

        local itemData = nil
        for _, shopItems in pairs(Config.Products) do
            for _, i in ipairs(shopItems) do
                if i.name == cartItem.item and QBCore.Shared.Items[cartItem.item] then
                    itemData = i
                    break
                end
            end
            if itemData then break end
        end

        if not itemData or not targetZone.stock[cartItem.zone][cartItem.item] then
            itemsValid = false
            local itemLabel = cartItem.item:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end)
            TriggerClientEvent('mnc-shops:notifyInventoryFull', src, itemLabel, "Item not found")
            -- Restore all cart items to stock
            for _, cItem in ipairs(cart) do
                TriggerClientEvent('mnc-shops:restoreStock', src, cItem.item, cItem.quantity, cItem.zone)
            end
            return
        end

        local itemLabel = QBCore.Shared.Items[cartItem.item].label or cartItem.item:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end)
        if targetZone.stock[cartItem.zone][cartItem.item] < cartItem.quantity then
            TriggerClientEvent('mnc-shops:notifyInventoryFull', src, itemLabel, "Insufficient stock for " .. itemLabel)
            -- Restore all cart items to stock
            for _, cItem in ipairs(cart) do
                TriggerClientEvent('mnc-shops:restoreStock', src, cItem.item, cItem.quantity, cItem.zone)
            end
            return
        end

        if not canCarryItem(src, cartItem.item, cartItem.quantity) then
            canCarryAll = false
            TriggerClientEvent('mnc-shops:notifyInventoryFull', src, itemLabel)
            -- Restore all cart items to stock
            for _, cItem in ipairs(cart) do
                TriggerClientEvent('mnc-shops:restoreStock', src, cItem.item, cItem.quantity, cItem.zone)
            end
            return
        end

        totalCost = totalCost + (itemData.price * cartItem.quantity)
        itemDataMap[cartItem.item] = itemData
        zoneStockMap[cartItem.item] = targetZone
    end

    if not itemsValid or not canCarryAll then return end

    -- Check payment availability
    local bankAmount = math.round(totalCost * bankPercent)
    local cashAmount = math.round(totalCost * (1 - bankPercent))
    if not (Player.PlayerData.money.bank >= bankAmount and Player.PlayerData.money.cash >= cashAmount) then
        local itemLabel = cart[1] and (QBCore.Shared.Items[cart[1].item].label or cart[1].item:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end)) or "items"
        TriggerClientEvent('mnc-shops:notifyInventoryFull', src, itemLabel, "Insufficient funds for " .. itemLabel)
        -- Restore all cart items to stock
        for _, cItem in ipairs(cart) do
            TriggerClientEvent('mnc-shops:restoreStock', src, cItem.item, cItem.quantity, cItem.zone)
        end
        return
    end

    -- Attempt to add all items to inventory
    local addedItems = {}
    for _, cartItem in ipairs(cart) do
        local success = false
        if ox_inventory and exports.ox_inventory.AddItem then
            success = ox_inventory:AddItem(src, cartItem.item, cartItem.quantity)
        elseif qb_inventory then
            success = Player.Functions.AddItem(cartItem.item, cartItem.quantity)
            if success then
                local itemLabel = QBCore.Shared.Items[cartItem.item].label or cartItem.item:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end)
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Item Purchased',
                    description = 'Added ' .. cartItem.quantity .. 'x ' .. itemLabel .. ' to your inventory.',
                    type = 'success',
                    duration = 5000
                })
            end
        else
            success = Player.Functions.AddItem(cartItem.item, cartItem.quantity)
        end
        if not success then
            -- Roll back any added items
            for _, addedItem in ipairs(addedItems) do
                if ox_inventory and exports.ox_inventory.RemoveItem then
                    ox_inventory:RemoveItem(src, addedItem.item, addedItem.quantity)
                elseif qb_inventory or not ox_inventory then
                    Player.Functions.RemoveItem(addedItem.item, addedItem.quantity)
                end
            end
            local itemLabel = QBCore.Shared.Items[cartItem.item].label or cartItem.item:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end)
            TriggerClientEvent('mnc-shops:notifyInventoryFull', src, itemLabel, "Failed to add item to inventory")
            -- Restore all cart items to stock
            for _, cItem in ipairs(cart) do
                TriggerClientEvent('mnc-shops:restoreStock', src, cItem.item, cItem.quantity, cItem.zone)
            end
            return
        end
        table.insert(addedItems, { item = cartItem.item, quantity = cartItem.quantity })
    end

    -- Deduct payment and update stock only after all items are added
    Player.Functions.RemoveMoney('bank', bankAmount)
    Player.Functions.RemoveMoney('cash', cashAmount)

    -- Update stock
    for _, cartItem in ipairs(cart) do
        zoneStockMap[cartItem.item].stock[cartItem.zone][cartItem.item] = zoneStockMap[cartItem.item].stock[cartItem.zone][cartItem.item] - cartItem.quantity
    end
end)

-- Helper function to check if a table contains a value
function table.contains(table, element)
    for _, value in ipairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

print("^2[mnc-shops]^7 Script loaded successfully!")