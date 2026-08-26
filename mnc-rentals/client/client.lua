-- client/client.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Store current zone when opening UI
local currentZoneId = nil
local activeRentals = {} -- Tracks active rentals {plate = {zoneId, endTime, refundAmount, vehicleModel, vehicleName}}

local function openRentalUI(zoneId)
    currentZoneId = zoneId
    local zone = Config.Zones[zoneId]
    if not zone then return end

    local categorizedVehicles = {}
    for _, vehicle in ipairs(zone.vehicles) do
        local category = vehicle.category or "Unknown"
        if not categorizedVehicles[category] then
            categorizedVehicles[category] = {}
        end
        table.insert(categorizedVehicles[category], vehicle)
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'setVehicleModels',
        models = categorizedVehicles,
        uiStyle = Config.UIStyles[zone.style],
        title = zone.name,
        logo = zone.logo
    })
    SendNUIMessage({
        action = "openUI",
        uiStyle = Config.UIStyles[zone.style],
        title = zone.name,
        logo = zone.logo
    })
end

RegisterNUICallback("spawnVehicle", function(data, cb)
    local model = data.model
    local hours = data.hours or 1
    local totalPrice = data.totalPrice or 0
    
    if not model or not currentZoneId then return cb('error') end

    local zone = Config.Zones[currentZoneId]
    local vehicleData = nil
    for _, veh in ipairs(zone.vehicles) do
        if veh.model == model then
            vehicleData = veh
            break
        end
    end
    if not vehicleData then return cb('error') end

    if Config.RequireItem then
        local hasItem = lib.callback.await('mnc-rentals:hasItem', false, Config.RequiredItem)
        if not hasItem then
            lib.notify({title = 'Vehicle Rental', description = 'You need a Drivers License to rent a vehicle!', type = 'error', duration = 5000})
            return cb('no_item')
        end
    end

    local rentalInfo = lib.callback.await('mnc-rentals:processRental', false, totalPrice, hours)
    if not rentalInfo then
        lib.notify({title = 'Vehicle Rental', description = 'You do not have enough money!', type = 'error', duration = 5000})
        return cb('no_money')
    end
    
    if rentalInfo.error == "rental_limit" then
        lib.notify({title = 'Vehicle Rental', description = 'You can only have a maximum of 3 active rentals!', type = 'error', duration = 5000})
        return cb('rental_limit')
    end

    local hash = joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local oldVeh = GetVehiclePedIsIn(ped, false)
        TaskLeaveVehicle(ped, oldVeh, 16)
        Wait(500)
        DeleteVehicle(oldVeh)
    end

    local spawnPos = zone.spawn.xyz
    local spawnHeading = zone.spawn.w
    local foundGround, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 5.0, false)
    if not foundGround then groundZ = spawnPos.z end

    local vehicle = CreateVehicle(hash, spawnPos.x, spawnPos.y, groundZ, spawnHeading, true, false)
    while not DoesEntityExist(vehicle) do Wait(10) end

    local plate = "RENT" .. math.random(1000, 9999)
    SetVehicleNumberPlateText(vehicle, plate)
    local color1, color2 = GetVehicleColours(vehicle)

    if Config.Warp then
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
    end

    -- Keys handling (safe, no export errors)
    TriggerServerEvent('vehiclekeys:server:AcquireVehicleKeys', plate)
    TriggerEvent('vehiclekeys:client:SetOwner', plate)
    TriggerEvent('qb-vehiclekeys:client:AddKeys', plate)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleNeedsToBeHotwired(vehicle, false)

    if Config.Debug then
        print("[mnc-rentals] Keys assigned for plate: " .. plate)
    end

    local fuelSystems = {
        ['legacy'] = function(veh) exports['LegacyFuel']:SetFuel(veh, 100.0) end,
        ['cdn'] = function(veh) exports['cdn-fuel']:SetFuel(veh, 100.0) end,
        ['ox'] = function(veh) Entity(veh).state.fuel = 100.0 end,
        ['standalone'] = function(veh) SetVehicleFuelLevel(veh, 100.0) end
    }
    if fuelSystems[Config.Fuel] then
        fuelSystems[Config.Fuel](vehicle)
    end

    activeRentals[plate] = {
        zoneId = currentZoneId,
        endTime = rentalInfo.endTime,
        refundAmount = rentalInfo.refundAmount,
        vehicleModel = model,
        vehicleName = vehicleData.name
    }

    if Config.GrantTemporaryInsurance then
        TriggerServerEvent('mnc-rentals:grantTemporaryInsurance', plate, vehicleData.category, vehicleData.name, color1, color2, model, rentalInfo.endTime)
    end

    lib.notify({
        title = 'Vehicle Rental',
        description = 'You rented a ' .. vehicleData.name .. ' for ' .. hours .. ' hour(s) ($' .. totalPrice .. '). Return to ANY rental location for a $' .. rentalInfo.refundAmount .. ' refund!',
        type = 'success',
        duration = 8000
    })

    SetModelAsNoLongerNeeded(hash)
    currentZoneId = nil
    cb("ok")
end)

RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    currentZoneId = nil
    cb({ status = 'closed' })
end)

-- Check if the vehicle is a valid active rental
local function isValidRentalVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return false, nil end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local rentalInfo = activeRentals[plate]
    
    if not rentalInfo then
        return false, "This is not a rented vehicle"
    end
    
    local currentTime = lib.callback.await('mnc-rentals:getCurrentTime', false)
    if currentTime > rentalInfo.endTime then
        return false, "Your rental period has expired - no refund available"
    end
    
    return true, rentalInfo
end

-- Return vehicle
local function returnVehicle(vehicle, rentalInfo)
    local plate = GetVehicleNumberPlateText(vehicle)
    
    TriggerServerEvent('mnc-rentals:returnVehicle', plate, rentalInfo.refundAmount)
    activeRentals[plate] = nil
    
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) == vehicle then
        TaskLeaveVehicle(ped, vehicle, 16)
        Wait(1000)
    end
    
    DeleteVehicle(vehicle)
    
    lib.notify({
        title = 'Vehicle Return',
        description = 'Vehicle returned! You received a $' .. rentalInfo.refundAmount .. ' refund.',
        type = 'success',
        duration = 6000
    })
end

-- 3D Text drawing function
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Main proximity loop
CreateThread(function()
    local showingReturnUI = false
    local showingRentalUI = false
    
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local nearZone = false
        local closestZone = nil
        local closestDist = math.huge
        
        -- Find the closest zone first
        for id, zone in pairs(Config.Zones) do
            local distToNpc = #(coords - zone.coords)
            local distToSpawn = #(coords - zone.spawn.xyz)
            local minDist = math.min(distToNpc, distToSpawn)
            
            if minDist < 10.0 and minDist < closestDist then
                closestDist = minDist
                closestZone = {id = id, zone = zone, distToNpc = distToNpc, distToSpawn = distToSpawn}
            end
        end
        
        -- Only interact with the closest zone
        if closestZone then
            nearZone = true
            sleep = 0
            
            local zone = closestZone.zone
            local distToNpc = closestZone.distToNpc
            local distToSpawn = closestZone.distToSpawn
            
            local inVehicle = IsPedInAnyVehicle(ped, false)
            local vehicle = inVehicle and GetVehiclePedIsIn(ped, false)
            
            local canReturn, rentalInfoOrMessage = false, nil
            if inVehicle and vehicle then
                canReturn, rentalInfoOrMessage = isValidRentalVehicle(vehicle)
            end
            
            -- Prioritize return over rental menu
            if distToSpawn < 5.0 and canReturn then
                if not showingReturnUI then
                    lib.showTextUI('**[E]** Return Vehicle  \nGet your refund!', {
                        position = "bottom-center",
                        icon = 'hand-holding-dollar',
                        iconColor = '#00ff00',
                        style = {
                            borderRadius = 8,
                            backgroundColor = '#1a1a1a',
                            color = '#ffffff',
                            fontSize = '18px',
                            fontWeight = 'bold'
                        }
                    })
                    showingReturnUI = true
                end
                
                if IsControlJustPressed(0, 38) then
                    lib.hideTextUI()
                    showingReturnUI = false
                    returnVehicle(vehicle, rentalInfoOrMessage)
                end
            else
                if showingReturnUI then
                    lib.hideTextUI()
                    showingReturnUI = false
                end
                
                if distToNpc < 2.5 and not inVehicle then
                    if not showingRentalUI then
                        lib.showTextUI('**[E]** Open Vehicle Rentals  \nRent a vehicle now!', {
                            position = "bottom-center",
                            icon = 'car-side',
                            iconColor = '#3b82f6',
                            style = {
                                borderRadius = 8,
                                backgroundColor = '#1a1a1a',
                                color = '#ffffff',
                                fontSize = '18px',
                                fontWeight = 'bold'
                            }
                        })
                        showingRentalUI = true
                    end
                    
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        showingRentalUI = false
                        openRentalUI(closestZone.id)
                    end
                else
                    if showingRentalUI then
                        lib.hideTextUI()
                        showingRentalUI = false
                    end
                end
            end
        else
            -- Hide both UIs when not near any zone
            if showingReturnUI then
                lib.hideTextUI()
                showingReturnUI = false
            end
            if showingRentalUI then
                lib.hideTextUI()
                showingRentalUI = false
            end
        end
        
        if not nearZone then
            sleep = 1000
        end
        
        Wait(sleep)
    end
end)

-- Cleanup expired rentals
CreateThread(function()
    while true do
        Wait(60000)
        local currentTime = lib.callback.await('mnc-rentals:getCurrentTime', false)
        for plate, rentalInfo in pairs(activeRentals) do
            if currentTime and currentTime > rentalInfo.endTime then
                activeRentals[plate] = nil
                TriggerServerEvent('mnc-rentals:expireInsurance', plate)
                lib.notify({
                    title = 'Rental Expired',
                    description = 'Your rental for ' .. rentalInfo.vehicleName .. ' has expired.',
                    type = 'inform',
                    duration = 5000
                })
            end
        end
    end
end)

-- Create blips
CreateThread(function()
    for id, zone in pairs(Config.Zones) do
        local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipDisplay(blip, Config.Blip.display)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.name .. ' - ' .. zone.name)
        EndTextCommandSetBlipName(blip)
    end
end)