local QBCore = exports['qb-core']:GetCoreObject()

-- Check if player has staff access
local function hasStaffAccess()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.job then
        return false
    end
    if not Config.EnableJobLock then
        return true
    end
    local job = PlayerData.job.name
    local grade = PlayerData.job.grade.level
    if Config.AllowedJobs[job] and grade >= Config.AllowedJobs[job] then
        return true
    end
    return false
end

-- Build exclusion lookup tables for fast checking
local function buildExclusionSets()
    local excludedTypes = {}
    local excludedItems = {}
    for _, t in ipairs(Config.ExcludeTypes or {}) do
        excludedTypes[t] = true
    end
    for _, name in ipairs(Config.ExcludeItems or {}) do
        excludedItems[name] = true
    end
    return excludedTypes, excludedItems
end

-- Fetch item models dynamically from QBCore.Shared.Items
local function fetchItemModels()
    local categorizedItems = {}
    local excludedTypes, excludedItems = buildExclusionSets()

    for itemName, itemData in pairs(QBCore.Shared.Items) do
        -- Skip excluded items and types
        if not excludedItems[itemName] and not excludedTypes[itemData.type] then
            local category = itemData.type or 'misc'

            if not categorizedItems[category] then
                categorizedItems[category] = {}
            end

            -- Resolve image filename from QB item data
            local itemImage = itemName
            if itemData.client and itemData.client.image then
                itemImage = itemData.client.image:gsub("%.png$", ""):gsub("%.jpg$", ""):gsub("%.jpeg$", "")
            elseif itemData.image then
                itemImage = itemData.image:gsub("%.png$", ""):gsub("%.jpg$", ""):gsub("%.jpeg$", "")
            end

            table.insert(categorizedItems[category], {
                name = itemName,
                image = itemImage,
                label = itemData.label or itemName:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end),
                amount = 5000,
                category = category,
            })
        end
    end

    SendNUIMessage({
        type = 'setItemModels',
        models = categorizedItems,
        uiStyle = Config.UIStyles[Config.UIStyle],
        title = "Item Spawner",
        hasStaffAccess = hasStaffAccess()
    })
end

-- Handle spawn submission
RegisterNUICallback('submitSpawn', function(data, cb)
    TriggerServerEvent('mnc-itemspawner:submitSpawn', data.item, data.quantity)
    cb({ status = 'ok' })
end)

-- Handle cart submission
RegisterNUICallback('submitCart', function(data, cb)
    TriggerServerEvent('mnc-itemspawner:submitCart', data.cart)
    cb({ status = 'ok' })
end)

-- Stock update is no longer needed (unlimited stock from shared items),
-- but kept for UI refresh compatibility
RegisterNUICallback('updateStock', function(data, cb)
    fetchItemModels()
    cb({ status = 'ok' })
end)

-- Handle UI opening via command
RegisterCommand(Config.Command, function()
    if not hasStaffAccess() then
        lib.notify({
            title = 'Access Denied',
            description = 'You do not have permission to use this command.',
            type = 'error',
            duration = 5000
        })
        return
    end
    SetNuiFocus(true, true)
    fetchItemModels()
    SendNUIMessage({
        action = "openUI",
        uiStyle = Config.UIStyles[Config.UIStyle],
        title = "Item Spawner",
        hasStaffAccess = hasStaffAccess()
    })
end, false)

-- Close UI
RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    cb({ status = 'closed' })
end)

-- Handle inventory full notification
RegisterNetEvent('mnc-itemspawner:notifyInventoryFull')
AddEventHandler('mnc-itemspawner:notifyInventoryFull', function(itemLabel)
    lib.notify({
        title = 'Inventory Full',
        description = 'You cannot carry any more ' .. itemLabel .. '.',
        type = 'error',
        duration = 5000
    })
end)