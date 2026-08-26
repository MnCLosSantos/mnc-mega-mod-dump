local QBCore = exports['qb-core']:GetCoreObject()

-- Store blip handles for cleanup
local blips = {}
local currentProximityZone = nil
local proximityUIVisible = false
local shopUIOpen = false -- Track if main shop UI is open
local targetZones = {} -- Store target zone IDs for cleanup
local notificationCooldowns = {} -- Track last notification time per zone
local NOTIFICATION_COOLDOWN = 5000 -- Cooldown in milliseconds (5 seconds)

-- Check if player has staff access for a specific zone
local function hasStaffAccess(zone)
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData.job then
        return false
    end
    for _, staffJob in ipairs(zone.staffJobs or {}) do
        if PlayerData.job.name == staffJob then
            return true
        end
    end
    return false
end

-- Check if player has the required item for a zone
local function hasRequiredItem(zone)
    if not zone.requiredItem then
        return true -- No required item, allow access
    end
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData.items then
        return false
    end
    for _, item in pairs(PlayerData.items) do
        if item.name == zone.requiredItem then
            return true
        end
    end
    -- Check notification cooldown for this zone
    local currentTime = GetGameTimer()
    if not notificationCooldowns[zone.name] or (currentTime - notificationCooldowns[zone.name] >= NOTIFICATION_COOLDOWN) then
        notificationCooldowns[zone.name] = currentTime
        lib.notify({
            title = 'Access Denied',
            description = 'You need a ' .. (QBCore.Shared.Items[zone.requiredItem].label or zone.requiredItem) .. ' to access this shop.',
            type = 'error',
            duration = 5000
        })
    end
    return false
end

-- Show proximity UI (only when UseTarget = false)
local function showProximityUI(zone)
    if not proximityUIVisible and not shopUIOpen and not Config.UseTarget then
        -- Only show proximity UI if the player has the required job or no staffJobs are defined
        if zone.staffJobs and not hasStaffAccess(zone) then
            return
        end
        -- Only show proximity UI if the player has the required item
        if not hasRequiredItem(zone) then
            return
        end
        proximityUIVisible = true
        currentProximityZone = zone
        SendNUIMessage({
            action = 'showProximityUI',
            uiStyle = Config.UIStyles[zone.uiStyle] or Config.UIStyles['style1'],
            title = zone.title,
            zoneName = zone.name
        })
    end
end

-- Hide proximity UI
local function hideProximityUI()
    if proximityUIVisible then
        proximityUIVisible = false
        currentProximityZone = nil
        SendNUIMessage({
            action = 'hideProximityUI'
        })
    end
end

-- Fetch item models for a specific shop or all
local function fetchItemModels(shop, isAdmin, zone)
    local categorizedItems = {}

    -- Determine which categories to include
    local categoriesToShow = {}
    if isAdmin then
        -- Admins see all categories
        categoriesToShow = Config.Products
    else
        -- Check if zone has a 'categories' field
        if zone.categories then
            for _, category in ipairs(zone.categories) do
                if Config.Products[category] then
                    categoriesToShow[category] = Config.Products[category]
                end
            end
        else
            -- Fallback to zone.name
            if Config.Products[shop] then
                categoriesToShow[shop] = Config.Products[shop]
            end
        end
    end

    -- Populate categorizedItems with zone-specific stock
    for category, items in pairs(categoriesToShow) do
        if not categorizedItems[category] then
            categorizedItems[category] = {}
        end
        for _, item in ipairs(items) do
            local qbItem = QBCore.Shared.Items[item.name]
            local itemLabel = qbItem and qbItem.label or item.name:gsub("_", " "):gsub("(%l)(%w*)", function(a, b) return a:upper() .. b end)
            -- Use zone-specific stock if available, otherwise use default from Config.Products
            local stockAmount = zone.stock and zone.stock[category] and zone.stock[category][item.name] or item.amount
            -- Resolve image: prefer QBCore item image field, fall back to item name
            local itemImage = item.name
            if qbItem then
                -- QB-Core stores image as item.client.image or item.image depending on version
                if qbItem.client and qbItem.client.image then
                    itemImage = qbItem.client.image:gsub("%.png$", ""):gsub("%.jpg$", ""):gsub("%.jpeg$", "")
                elseif qbItem.image then
                    itemImage = qbItem.image:gsub("%.png$", ""):gsub("%.jpg$", ""):gsub("%.jpeg$", "")
                end
            end
            table.insert(categorizedItems[category], {
                name = item.name,
                image = itemImage,
                label = itemLabel,
                price = item.price,
                amount = stockAmount,
                category = category,
            })
        end
    end

    -- Debug logging
    if Config.Debug then
        print('Sending setItemModels message:', json.encode({
            type = 'setItemModels',
            models = categorizedItems,
            uiStyle = Config.UIStyles[zone and zone.uiStyle] or Config.UIStyles['style1'],
            title = isAdmin and "All Items Catalog" or (zone and zone.title),
            zone = zone and zone.name or nil,
            hasStaffAccess = zone and hasStaffAccess(zone) or false
        }, {indent=true}))
    end

    SendNUIMessage({
        type = 'setItemModels',
        models = categorizedItems,
        uiStyle = Config.UIStyles[zone and zone.uiStyle] or Config.UIStyles['style1'],
        title = isAdmin and "All Items Catalog" or (zone and zone.title),
        zone = zone and zone.name or nil,
        hasStaffAccess = zone and hasStaffAccess(zone) or false
    })
end

-- Handle purchase submission
RegisterNUICallback('submitPurchase', function(data, cb)
    TriggerServerEvent('mnc-shops:submitPurchase', data.item, data.quantity, data.paymentType, data.zone)
    cb({ status = 'ok' })
end)

-- Handle cart submission
RegisterNUICallback('submitCart', function(data, cb)
    TriggerServerEvent('mnc-shops:submitCart', data.cart, data.bankPercent)
    cb({ status = 'ok' })
end)

-- Handle stock update when adding to cart
RegisterNUICallback('updateStock', function(data, cb)
    if not data.zone then
        if Config.Debug then
            print('Error: updateStock called with no zone data:', json.encode(data))
        end
        cb({ status = 'error', message = 'No zone specified' })
        return
    end

    -- Find the corresponding zone
    local targetZone = nil
    for _, zone in ipairs(Config.Zones) do
        if zone.name == data.zone or (zone.categories and table.contains(zone.categories, data.zone)) then
            targetZone = zone
            break
        end
    end

    if not targetZone then
        if Config.Debug then
            print('Error: No zone found for category:', data.zone)
        end
        cb({ status = 'error', message = 'Invalid zone' })
        return
    end

    -- Initialize zone stock if not exists
    if not targetZone.stock then
        targetZone.stock = {}
    end
    if not targetZone.stock[data.zone] then
        targetZone.stock[data.zone] = {}
        -- Initialize stock from Config.Products for this zone
        if Config.Products[data.zone] then
            for _, item in ipairs(Config.Products[data.zone]) do
                targetZone.stock[data.zone][item.name] = item.amount
            end
        end
    end

    -- Update stock in zone
    if targetZone.stock[data.zone][data.item] then
        targetZone.stock[data.zone][data.item] = math.max(0, targetZone.stock[data.zone][data.item] - data.quantity)
    else
        if Config.Debug then
            print('Error: Item not found in zone stock:', data.item, data.zone)
        end
        cb({ status = 'error', message = 'Item not found in zone stock' })
        return
    end

    -- Refresh UI with the correct zone
    fetchItemModels(targetZone.name, false, targetZone)
    cb({ status = 'ok' })
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

-- Receive stock data from server
RegisterNetEvent('mnc-shops:receiveStock')
AddEventHandler('mnc-shops:receiveStock', function(zoneName, stockData)
    -- Find the corresponding zone
    local targetZone = nil
    for _, z in ipairs(Config.Zones) do
        if z.name == zoneName or (z.categories and table.contains(z.categories, zoneName)) then
            targetZone = z
            break
        end
    end

    if targetZone then
        if not targetZone.stock then
            targetZone.stock = {}
        end
        targetZone.stock[zoneName] = stockData
        -- Refresh the UI with the updated stock
        fetchItemModels(targetZone.name, false, targetZone)
    end
end)

-- Restore stock on client side
RegisterNetEvent('mnc-shops:restoreStock')
AddEventHandler('mnc-shops:restoreStock', function(item, quantity, zoneName)
    -- Find the corresponding zone
    local targetZone = nil
    for _, z in ipairs(Config.Zones) do
        if z.name == zoneName or (z.categories and table.contains(z.categories, zoneName)) then
            targetZone = z
            break
        end
    end

    if targetZone then
        if not targetZone.stock then
            targetZone.stock = {}
        end
        if not targetZone.stock[zoneName] then
            targetZone.stock[zoneName] = {}
            -- Initialize stock from Config.Products
            if Config.Products[zoneName] then
                for _, itemData in ipairs(Config.Products[zoneName]) do
                    targetZone.stock[zoneName][itemData.name] = itemData.amount
                end
            end
        end

        if targetZone.stock[zoneName][item] then
            targetZone.stock[zoneName][item] = (targetZone.stock[zoneName][item] or 0) + quantity
        else
            targetZone.stock[zoneName][item] = quantity
        end
        -- Refresh the UI
        fetchItemModels(targetZone.name, false, targetZone)
    end
end)

-- Handle open shop from proximity UI (only when UseTarget = false)
RegisterNUICallback('openShopFromProximity', function(data, cb)
    if currentProximityZone and not shopUIOpen and not Config.UseTarget then
        -- Only open shop if player has the required job or no staffJobs are defined
        if currentProximityZone.staffJobs and not hasStaffAccess(currentProximityZone) then
            cb({ status = 'error', message = 'Unauthorized access' })
            return
        end
        -- Only open shop if player has the required item
        if not hasRequiredItem(currentProximityZone) then
            cb({ status = 'error', message = 'Missing required item' })
            return
        end
        openCatalogInZone(currentProximityZone)
    end
    cb({ status = 'ok' })
end)

-- Create blips for zones
local function createZoneBlips()
    for _, zone in ipairs(Config.Zones) do
        if zone.blip and zone.blip.enabled then
            local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
            SetBlipSprite(blip, zone.blip.sprite or 1)
            SetBlipColour(blip, zone.blip.color or 0)
            SetBlipScale(blip, zone.blip.scale or 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(zone.blip.name or zone.title)
            EndTextCommandSetBlipName(blip)
            table.insert(blips, blip)
        end
    end
end

-- Create qb-target zones
local function createTargetZones()
    if not Config.UseTarget then return end
    
    for i, zone in ipairs(Config.Zones) do
        if not zone.useAnywhere then
            local targetId = "mnc_shop_" .. i
            exports['qb-target']:AddBoxZone(targetId, zone.coords, 2.0, 2.0, {
                name = targetId,
                heading = 0,
                debugPoly = false,
                minZ = zone.coords.z - 1,
                maxZ = zone.coords.z + 2,
            }, {
                options = {
                    {
                        type = "client",
                        event = "mnc-shops:openShop",
                        icon = "fas fa-shopping-bag",
                        label = "Open " .. zone.title,
                        zone = zone,
                        -- Only show the target option if the player has the required job or no staffJobs are defined
                        -- and has the required item
                        canInteract = function()
                            return (not zone.staffJobs or hasStaffAccess(zone)) and hasRequiredItem(zone)
                        end
                    }
                },
                distance = zone.radius or 1.5
            })
            table.insert(targetZones, targetId)
        end
    end
end

-- Remove qb-target zones
local function removeTargetZones()
    for _, targetId in ipairs(targetZones) do
        exports['qb-target']:RemoveZone(targetId)
    end
    targetZones = {}
end

-- Clean up blips and target zones on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, blip in ipairs(blips) do
            RemoveBlip(blip)
        end
        removeTargetZones()
    end
end)

-- Handle zone-based UI opening
function openCatalogInZone(zone)
    -- Only open shop if player has the required job or no staffJobs are defined
    if zone.staffJobs and not hasStaffAccess(zone) then
        local currentTime = GetGameTimer()
        if not notificationCooldowns[zone.name] or (currentTime - notificationCooldowns[zone.name] >= NOTIFICATION_COOLDOWN) then
            notificationCooldowns[zone.name] = currentTime
            lib.notify({
                title = 'Access Denied',
                description = 'You do not have the required job to access this shop.',
                type = 'error',
                duration = 5000
            })
        end
        return
    end
    -- Only open shop if player has the required item
    if not hasRequiredItem(zone) then
        return
    end
    shopUIOpen = true
    hideProximityUI()
    SetNuiFocus(true, true)

    -- Request stock from server for this zone
    TriggerServerEvent('mnc-shops:fetchStock', zone.name)

    -- Debug logging
    if Config.Debug then
        print('Sending openUI message:', json.encode({
            action = "openUI",
            uiStyle = Config.UIStyles[zone.uiStyle] or Config.UIStyles['style1'],
            title = zone.title,
            zone = zone.name,
            categories = zone.categories or {zone.name},
            hasStaffAccess = hasStaffAccess(zone)
        }, {indent=true}))
    end
    SendNUIMessage({
        action = "openUI",
        uiStyle = Config.UIStyles[zone.uiStyle] or Config.UIStyles['style1'],
        title = zone.title,
        zone = zone.name,
        categories = zone.categories or {zone.name},
        hasStaffAccess = hasStaffAccess(zone)
    })
end

-- Event handler for qb-target shop opening
RegisterNetEvent('mnc-shops:openShop')
AddEventHandler('mnc-shops:openShop', function(data)
    if data.zone and not shopUIOpen then
        -- Only open shop if player has the required item
        if not hasRequiredItem(data.zone) then
            return
        end
        openCatalogInZone(data.zone)
    end
end)

-- Main proximity and interaction thread (only when UseTarget = false)
Citizen.CreateThread(function()
    if Config.UseTarget then return end -- Exit thread if using qb-target
    
    while true do
        Citizen.Wait(500)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearestZone = nil
        local nearestDist = 5.0
        
        if not shopUIOpen then
            for _, zone in ipairs(Config.Zones) do
                if not zone.useAnywhere then
                    local dist = #(playerCoords - zone.coords)
                    if dist <= 5.0 and dist < nearestDist then
                        nearestZone = zone
                        nearestDist = dist
                    end
                end
            end
            
            if nearestZone then
                if not currentProximityZone or currentProximityZone.name ~= nearestZone.name then
                    showProximityUI(nearestZone)
                end
            else
                if proximityUIVisible then
                    hideProximityUI()
                end
            end
        else
            if proximityUIVisible then
                hideProximityUI()
            end
        end
    end
end)

-- E key press detection thread (only when UseTarget = false)
Citizen.CreateThread(function()
    if Config.UseTarget then return end -- Exit thread if using qb-target
    
    while true do
        Citizen.Wait(0)
        if proximityUIVisible and IsControlJustPressed(0, 38) and not shopUIOpen then -- E key
            if currentProximityZone then
                -- Only open shop if player has the required item
                if not hasRequiredItem(currentProximityZone) then
                    return
                end
                openCatalogInZone(currentProximityZone)
            end
        end
    end
end)

-- Anywhere zone handling (commands for special zones)
for _, zone in ipairs(Config.Zones) do
    if zone.useAnywhere then
        RegisterCommand(zone.name .. "_shop", function()
            -- Only open shop if player has the required item
            if not hasRequiredItem(zone) then
                return
            end
            openCatalogInZone(zone)
        end, false)
    end
end

-- Close UI
RegisterNUICallback('closeUI', function(_, cb)
    shopUIOpen = false
    SetNuiFocus(false, false)
    cb({ status = 'closed' })

    -- Re-check proximity after a short delay (only if not using qb-target)
    if not Config.UseTarget then
        Citizen.SetTimeout(100, function()
            if not shopUIOpen then
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)

                for _, zone in ipairs(Config.Zones) do
                    if not zone.useAnywhere then
                        local dist = #(playerCoords - zone.coords)
                        if dist <= 5.0 then
                            showProximityUI(zone)
                            break
                        end
                    end
                end
            end
        end)
    end
end)

-- Handle inventory full or other failure notifications
RegisterNetEvent('mnc-shops:notifyInventoryFull')
AddEventHandler('mnc-shops:notifyInventoryFull', function(itemLabel, customMessage)
    lib.notify({
        title = customMessage and 'Purchase Failed' or 'Inventory Full',
        description = customMessage or ('You cannot carry any more ' .. itemLabel .. '.'),
        type = 'error',
        duration = 5000
    })
end)

-- Initialize blips and target zones when resource starts
Citizen.CreateThread(function()
    createZoneBlips()
    if Config.UseTarget then
        createTargetZones()
    end
end)