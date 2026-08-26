local QBCore = exports['qb-core']:GetCoreObject()
local currentPreviewVehicle = nil
local lastZone = nil

-- ── QBCore admin permission check ─────────────────────────────────────────────
local function isQBAdmin()
    return QBCore.Functions.HasPermission('admin')
end

-- ── Build zone list for admin dealership-swap dropdown ────────────────────────
local function buildZoneList()
    local list = {}
    for _, zone in ipairs(Config.Zones) do
        list[#list + 1] = { name = zone.name, title = zone.title }
    end
    return list
end

-- ── Fetch vehicle models ──────────────────────────────────────────────────────
-- dealership = nil → return all vehicles (admin)
-- dealership = string → return vehicles whose data.shop matches
local function fetchVehicleModels(dealership)
    local categorizedVehicles = {}
    for model, data in pairs(QBShared.Vehicles) do
        if dealership == nil or (data.shop and data.shop == dealership) then
            local className = data.category or 'Unknown'
            if not categorizedVehicles[className] then
                categorizedVehicles[className] = {}
            end
            categorizedVehicles[className][#categorizedVehicles[className] + 1] = {
                model    = model,
                name     = data.name,
                price    = data.price,
                category = className,
                brand    = data.brand or 'Unknown',
                shop     = data.shop or '',
            }
        end
    end
    return categorizedVehicles
end

-- ── Open zone catalog ─────────────────────────────────────────────────────────
local function openZoneCatalog(zone)
    local models = fetchVehicleModels(zone.name)

    SendNUIMessage({
        action        = 'openUI',
        isAdmin       = false,
        models        = models,
        canEditPrices = false,        -- Zone visitors can't edit prices
        zoneName      = zone.name,
        uiStyle       = Config.UIStyles[zone.uiStyle],
        title         = zone.title,
        imagePaths    = Config.ImagePaths,
    })
end

-- ── Open admin catalog ────────────────────────────────────────────────────────
-- dealership = nil → show all; dealership = zone.name → filter to that shop
local function openAdminCatalog(dealership)
    local models = fetchVehicleModels(dealership)
    local title  = 'All Vehicles Catalog'
    if dealership then
        for _, zone in ipairs(Config.Zones) do
            if zone.name == dealership then title = zone.title; break end
        end
    end

    SendNUIMessage({
        action        = 'openUI',
        isAdmin       = true,
        models        = models,
        canEditPrices = true,       -- admins can always edit prices
        zoneName      = dealership, -- may be nil
        uiStyle       = Config.UIStyles['style3'],
        title         = title,
        imagePaths    = Config.ImagePaths,
        zoneList      = buildZoneList(), -- for the swap dropdown
    })
end

-- ── Zone catalog opener (keypress / target) ───────────────────────────────────
local function openCatalogInZone(zone)
    SetNuiFocus(true, true)
    openZoneCatalog(zone)
    Citizen.CreateThread(function()
        for i = 1, 3 do
            Citizen.Wait(50)
            SetNuiFocus(true, true)
        end
    end)
end

-- ── NUI callbacks ─────────────────────────────────────────────────────────────
RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    if currentPreviewVehicle and DoesEntityExist(currentPreviewVehicle) then
        DeleteVehicle(currentPreviewVehicle)
        currentPreviewVehicle = nil
    end
    cb({ status = 'closed' })
end)

-- Dealership swap (admin only)
RegisterNUICallback('updateVehicleShop', function(data, cb)
    local model   = tostring(data.model or ''):gsub('[^%w_]', '')
    local newShop = tostring(data.shop or '')
    local name    = tostring(data.name or model)

    if model == '' then
        cb({ success = false, error = 'Invalid model.' })
        return
    end

    TriggerServerEvent('mnc-vehiclecatalog:updateVehicleShop', model, newShop, name)
    cb({ success = true })
end)

-- Price update — pass zone name so server can scope the permission check
RegisterNUICallback('updateVehiclePrice', function(data, cb)
    local model    = tostring(data.model or ''):gsub('[^%w_]', '')
    local newPrice = tonumber(data.price)
    local name     = tostring(data.name or model)
    local zoneName = tostring(data.zone or '')

    if model == '' or not newPrice or newPrice < 0 then
        cb({ success = false, error = 'Invalid data received.' })
        return
    end

    TriggerServerEvent('mnc-vehiclecatalog:updateVehiclePrice', model, math.floor(newPrice), name, zoneName)
    cb({ success = true })
end)

-- Admin dealership swap
RegisterNUICallback('swapDealership', function(data, cb)
    if not isQBAdmin() then
        cb({ success = false, error = 'Not authorised.' })
        return
    end
    -- nil means "show all"
    local dealer = (data.dealership ~= '' and data.dealership ~= 'all') and data.dealership or nil
    openAdminCatalog(dealer)
    cb({ success = true })
end)

RegisterNUICallback('reopenProximityUI', function(data, cb)
    if lastZone then
        for _, zone in ipairs(Config.Zones) do
            if zone.name == lastZone then
                local dist = #(GetEntityCoords(PlayerPedId()) - zone.coords)
                if dist <= 5.0 then
                    SendNUIMessage({
                        action  = 'showProximityUI',
                        uiStyle = Config.UIStyles[zone.uiStyle],
                        title   = zone.title,
                    })
                end
                break
            end
        end
    end
    cb({ status = 'ok' })
end)

-- ── Pre-order NUI callbacks ───────────────────────────────────────────────────
RegisterNUICallback('submitPreOrder', function(data, cb)
    TriggerServerEvent('mnc-vehiclecatalog:submitPreOrder', data.model, data.name, data.notes, data.zone)
    cb({ status = 'ok' })
end)

RegisterNUICallback('getOrders', function(data, cb)
    TriggerServerEvent('mnc-vehiclecatalog:getOrders', data.zone)
    cb({ status = 'ok' })
end)

RegisterNUICallback('updateOrderStatus', function(data, cb)
    TriggerServerEvent('mnc-vehiclecatalog:updateOrderStatus', data.orderId, data.status)
    cb({ status = 'ok' })
end)

RegisterNetEvent('mnc-vehiclecatalog:receiveOrders', function(orders)
    SendNUIMessage({ type = 'setOrders', orders = orders })
end)

-- ── Target / keypress zone handling ──────────────────────────────────────────
if Config.UseTarget then
    for _, zone in ipairs(Config.Zones) do
        if not zone.useAnywhere then
            exports['qb-target']:AddCircleZone(zone.name .. '_catalog', zone.coords, zone.radius, {
                name      = zone.name .. '_catalog',
                debugPoly = false,
            }, {
                options = {{
                    label  = 'Open Vehicle Catalog',
                    icon   = 'fas fa-car',
                    action = function() openCatalogInZone(zone) end,
                }},
                distance = zone.radius,
            })
        end
    end
else
    Citizen.CreateThread(function()
        local lastKeyPress = 0
        local debounceTime = 200
        while true do
            Citizen.Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local inRange      = false

            for _, zone in ipairs(Config.Zones) do
                if not zone.useAnywhere then
                    local dist = #(playerCoords - zone.coords)
                    if dist <= 5.0 then
                        inRange = true
                        if lastZone ~= zone.name then
                            SendNUIMessage({
                                action  = 'showProximityUI',
                                uiStyle = Config.UIStyles[zone.uiStyle],
                                title   = zone.title,
                            })
                            lastZone = zone.name
                        end
                        if IsControlJustPressed(0, 38) and GetGameTimer() - lastKeyPress > debounceTime then
                            lastKeyPress = GetGameTimer()
                            openCatalogInZone(zone)
                            SendNUIMessage({ action = 'hideProximityUI' })
                        end
                    end
                end
            end

            if not inRange and lastZone then
                SendNUIMessage({ action = 'hideProximityUI' })
                lastZone = nil
            end
        end
    end)

    RegisterKeyMapping('open_catalog', 'Open Vehicle Catalog', 'keyboard', 'E')
    RegisterCommand('open_catalog', function()
        local playerCoords = GetEntityCoords(PlayerPedId())
        for _, zone in ipairs(Config.Zones) do
            if not zone.useAnywhere then
                local dist = #(playerCoords - zone.coords)
                if dist <= 5.0 then
                    openCatalogInZone(zone)
                    SendNUIMessage({ action = 'hideProximityUI' })
                    break
                end
            end
        end
    end, false)
end

-- ── Anywhere zones ────────────────────────────────────────────────────────────
for _, zone in ipairs(Config.Zones) do
    if zone.useAnywhere then
        RegisterCommand(zone.name .. '_catalog', function()
            openCatalogInZone(zone)
        end, false)
    end
end

-- ── Admin UI — opened via server event after QB admin permission verified ──────
RegisterNetEvent('mnc-vehiclecatalog:openAdminUI', function()
    SetNuiFocus(true, true)
    openAdminCatalog(nil)
end)

-- ── Fallback scan relay events ────────────────────────────────────────────────
RegisterNetEvent('mnc-vehiclecatalog:openScanMenu', function(menuData)
    lib.registerContext(menuData)
    lib.showContext(menuData.id)
end)

RegisterNetEvent('mnc-vehiclecatalog:closeScanMenu', function()
    lib.hideContext()
end)

RegisterNetEvent('mnc-vehiclecatalog:requestProgressRefresh', function()
    TriggerServerEvent('mnc-vehiclecatalog:requestProgressRefresh')
end)

RegisterNetEvent('mnc-vehiclecatalog:requestCancel', function()
    TriggerServerEvent('mnc-vehiclecatalog:requestCancel')
end)