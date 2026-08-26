local QBCore = exports['qb-core']:GetCoreObject()
local currentPreviewVehicle = nil
local lastZone = nil -- Track the last zone for proximity UI

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

-- Fetch vehicle models for a specific dealership or all
local function fetchVehicleModels(dealership, isAdmin, zone)
    local vehicleModels = {}
    local categorizedVehicles = {}

    for model, data in pairs(QBShared.Vehicles) do
        if isAdmin or (data.shop and data.shop == dealership) then
            local className = data.category or "Unknown"
            if not categorizedVehicles[className] then
                categorizedVehicles[className] = {}
            end
            table.insert(categorizedVehicles[className], {
                model = model, -- This is the spawncode, now called "Vehicle Model"
                name = data.name,
                price = data.price,
                category = className,
                brand = data.brand or "Unknown", -- Add maker (brand) field
            })
        end
    end

    SendNUIMessage({
        type = 'setVehicleModels',
        models = categorizedVehicles,
        uiStyle = Config.UIStyles[zone and zone.uiStyle or Config.Zones[1].uiStyle],
        title = isAdmin and "All Vehicles Catalog" or (zone and zone.title or Config.Zones[1].title),
        zone = zone and zone.name or nil,
        hasStaffAccess = zone and hasStaffAccess(zone) or false
    })
end

-- Handle pre-order submission
RegisterNUICallback('submitPreOrder', function(data, cb)
    TriggerServerEvent('mnc-vehiclecatalog:submitPreOrder', data.model, data.name, data.notes, data.zone)
    cb({ status = 'ok' })
end)

-- Handle getting orders for staff portal
RegisterNUICallback('getOrders', function(data, cb)
    TriggerServerEvent('mnc-vehiclecatalog:getOrders', data.zone)
    cb({ status = 'ok' })
end)

-- Handle order status updates
RegisterNUICallback('updateOrderStatus', function(data, cb)
    TriggerServerEvent('mnc-vehiclecatalog:updateOrderStatus', data.orderId, data.status)
    cb({ status = 'ok' })
end)

-- Receive orders from server
RegisterNetEvent('mnc-vehiclecatalog:receiveOrders', function(orders)
    SendNUIMessage({
        type = 'setOrders',
        orders = orders
    })
end)

-- Handle zone-based UI opening
local function openCatalogInZone(zone)
    SetNuiFocus(true, true)
    fetchVehicleModels(zone.name, false, zone)
    SendNUIMessage({
        action = "openUI",
        uiStyle = Config.UIStyles[zone.uiStyle],
        title = zone.title,
        zone = zone.name,
        hasStaffAccess = hasStaffAccess(zone)
    })
    -- Ensure focus is maintained
    Citizen.CreateThread(function()
        for i = 1, 3 do
            Citizen.Wait(50)
            SetNuiFocus(true, true)
            print("Focus attempt " .. i .. " for zone: " .. zone.name)
        end
    end)
    print("Opening UI for zone: " .. zone.name)
end

-- Handle proximity UI re-display after closing catalog
RegisterNUICallback('reopenProximityUI', function(data, cb)
    if lastZone then
        for _, zone in ipairs(Config.Zones) do
            if zone.name == lastZone then
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local dist = #(playerCoords - zone.coords)
                if dist <= 5.0 then
                    SendNUIMessage({
                        action = "showProximityUI",
                        uiStyle = Config.UIStyles[zone.uiStyle],
                        title = zone.title
                    })
                    print("Reopening proximity UI for zone: " .. zone.name)
                end
                break
            end
        end
    end
    cb({ status = 'ok' })
end)

-- qb-target integration
if Config.UseTarget then
    for _, zone in ipairs(Config.Zones) do
        if not zone.useAnywhere then
            exports['qb-target']:AddCircleZone(zone.name .. "_catalog", zone.coords, zone.radius, {
                name = zone.name .. "_catalog",
                debugPoly = false,
            }, {
                options = {
                    {
                        label = "Open Vehicle Catalog",
                        icon = "fas fa-car",
                        action = function()
                            openCatalogInZone(zone)
                        end
                    }
                },
                distance = zone.radius
            })
        end
    end
else
    -- Keypress E integration with proximity UI
    Citizen.CreateThread(function()
        local lastKeyPress = 0
        local debounceTime = 200 -- 200ms debounce for responsiveness
        while true do
            Citizen.Wait(0) -- Check every frame
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local inRange = false
            local currentZone = nil

            for _, zone in ipairs(Config.Zones) do
                if not zone.useAnywhere then
                    local dist = #(playerCoords - zone.coords)
                    if dist <= 5.0 then -- Show UI within 5 meters
                        inRange = true
                        currentZone = zone
                        if lastZone ~= zone.name then
                            SendNUIMessage({
                                action = "showProximityUI",
                                uiStyle = Config.UIStyles[zone.uiStyle],
                                title = zone.title
                            })
                            lastZone = zone.name
                            print("Showing proximity UI for zone: " .. zone.name)
                        end
                        if IsControlJustPressed(0, 38) and GetGameTimer() - lastKeyPress > debounceTime then -- E key
                            lastKeyPress = GetGameTimer()
                            openCatalogInZone(zone)
                            SendNUIMessage({ action = "hideProximityUI" })
                            print("E key pressed, opening catalog for zone: " .. zone.name)
                        end
                    end
                end
            end

            if not inRange and lastZone then
                SendNUIMessage({ action = "hideProximityUI" })
                lastZone = nil
                print("Hiding proximity UI, player out of range")
            end
        end
    end)

    -- Client-side E keybind for redundancy
    RegisterKeyMapping('open_catalog', 'Open Vehicle Catalog', 'keyboard', 'E')
    RegisterCommand('open_catalog', function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        for _, zone in ipairs(Config.Zones) do
            if not zone.useAnywhere then
                local dist = #(playerCoords - zone.coords)
                if dist <= 5.0 then
                    openCatalogInZone(zone)
                    SendNUIMessage({ action = "hideProximityUI" })
                    print("Client-side E key triggered for zone: " .. zone.name)
                    break
                end
            end
        end
    end, false)
end

-- Anywhere zone handling
for _, zone in ipairs(Config.Zones) do
    if zone.useAnywhere then
        RegisterCommand(zone.name .. "_catalog", function()
            openCatalogInZone(zone)
        end, false)
    end
end

-- Admin command to show all vehicles
RegisterNetEvent('mnc-vehiclecatalog:openAdminUI', function()
    SetNuiFocus(true, true)
    fetchVehicleModels(nil, true, nil)
    SendNUIMessage({
        action = "openUI",
        uiStyle = Config.UIStyles['style3'], -- Default style for admin
        title = "All Vehicles Catalog",
        zone = nil,
        hasStaffAccess = false
    })
end)

-- Close UI and cleanup
RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    if currentPreviewVehicle and DoesEntityExist(currentPreviewVehicle) then
        DeleteVehicle(currentPreviewVehicle)
        currentPreviewVehicle = nil
    end
    cb({ status = 'closed' })
end)