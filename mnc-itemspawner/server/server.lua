local QBCore = exports['qb-core']:GetCoreObject()
local ox_inventory = GetResourceState('ox_inventory') == 'started' and exports.ox_inventory or nil
local qb_inventory = GetResourceState('qb-inventory') == 'started' and exports['qb-inventory'] or nil

local function hasStaffAccess(Player)
    if not Player or not Player.PlayerData or not Player.PlayerData.job then 
        return false 
    end
    if not Config.EnableJobLock then 
        return true 
    end
    local job = Player.PlayerData.job.name
    local grade = Player.PlayerData.job.grade.level
    if Config.AllowedJobs[job] and grade >= Config.AllowedJobs[job] then
        return true
    end
    return false
end

-- Function to check if player can carry item
local function canCarryItem(src, item, quantity)
    if ox_inventory and exports.ox_inventory.CanCarryItem then
        return ox_inventory:CanCarryItem(src, item, quantity)
    elseif qb_inventory then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return false end
        local itemData = QBCore.Shared.Items[item]
        if not itemData then return false end
        local weight = itemData.weight or 0
        local totalWeight = weight * quantity
        local playerInventory = Player.PlayerData.items
        local currentWeight = 0
        for _, invItem in pairs(playerInventory) do
            local invItemData = QBCore.Shared.Items[invItem.name]
            if invItemData then
                currentWeight = currentWeight + (invItemData.weight * invItem.amount)
            end
        end
        local maxWeight = Config.MaxWeight or 120000 -- Fallback to default max weight if not set
        return (currentWeight + totalWeight) <= maxWeight
    else
        -- Fallback: assume player can carry if no inventory system is detected
        return true
    end
end

-- Handle spawn
RegisterServerEvent('mnc-itemspawner:submitSpawn')
AddEventHandler('mnc-itemspawner:submitSpawn', function(item, quantity)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Job/Grade access check
    if not hasStaffAccess(Player) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Access Denied',
            description = 'You do not have permission to use the item spawner.',
            type = 'error',
            duration = 5000
        })
        return
    end

    -- Validate item exists in QBCore shared items
    if not QBCore.Shared.Items[item] then 
        return 
    end

    -- Check if player can carry the item
    local itemLabel = QBCore.Shared.Items[item].label or item:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end)
    
    if canCarryItem(src, item, quantity) then
        -- Add item to inventory
        local success = false
        if ox_inventory and exports.ox_inventory.AddItem then
            success = ox_inventory:AddItem(src, item, quantity)
        elseif qb_inventory then
            success = Player.Functions.AddItem(item, quantity)
            if success then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Item Added',
                    description = 'Added ' .. quantity .. 'x ' .. itemLabel .. ' to your inventory.',
                    type = 'success',
                    duration = 5000
                })
            end
        else
            success = Player.Functions.AddItem(item, quantity)
        end

        if not success then
            TriggerClientEvent('mnc-itemspawner:notifyInventoryFull', src, itemLabel)
        end
    else
        -- Inventory full
        TriggerClientEvent('mnc-itemspawner:notifyInventoryFull', src, itemLabel)
    end
end)

-- Handle cart submission
RegisterServerEvent('mnc-itemspawner:submitCart')
AddEventHandler('mnc-itemspawner:submitCart', function(cart)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Job/Grade access check
    if not hasStaffAccess(Player) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Access Denied',
            description = 'You do not have permission to use the item spawner.',
            type = 'error',
            duration = 5000
        })
        return
    end

    if #cart == 0 then return end

    local itemsValid = true
    local canCarryAll = true

    -- First pass: validate items and check weight/space for all
    for _, cartItem in ipairs(cart) do
        if not QBCore.Shared.Items[cartItem.item] then
            itemsValid = false
            break
        end

        if not canCarryItem(src, cartItem.item, cartItem.quantity) then
            canCarryAll = false
            local itemLabel = QBCore.Shared.Items[cartItem.item].label or cartItem.item:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end)
            TriggerClientEvent('mnc-itemspawner:notifyInventoryFull', src, itemLabel)
            break
        end
    end

    if not itemsValid or not canCarryAll then 
        return 
    end

    -- Second pass: add all items
    for _, cartItem in ipairs(cart) do
        local success = false
        local itemLabel = QBCore.Shared.Items[cartItem.item].label or cartItem.item:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end)

        if ox_inventory and exports.ox_inventory.AddItem then
            success = ox_inventory:AddItem(src, cartItem.item, cartItem.quantity)
        elseif qb_inventory then
            success = Player.Functions.AddItem(cartItem.item, cartItem.quantity)
            if success then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Item Added',
                    description = 'Added ' .. cartItem.quantity .. 'x ' .. itemLabel .. ' to your inventory.',
                    type = 'success',
                    duration = 5000
                })
            end
        else
            success = Player.Functions.AddItem(cartItem.item, cartItem.quantity)
        end

        if not success then
            TriggerClientEvent('mnc-itemspawner:notifyInventoryFull', src, itemLabel)
            break  -- Stop adding further items if one fails
        end
    end
end)

print("^2[mnc-itemspawner]^7 Script loaded successfully!")