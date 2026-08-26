-- client.lua
local QBCore = nil
local engineReady = false
local currentVehicle = nil
local orderedEngine = nil
local isInstalling = false -- Flag to prevent concurrent installations
local currentShop = nil -- Track current shop
local pendingShop = nil -- Store shop data during delivery/installation
local hasEngineCrate = false -- Track crate possession
local deliveryProp = nil -- Track the engine crate prop object
local palletProp = nil -- Track the pallet prop object
local targetPlayerId = nil -- Store target player ID for payment/refunded player
local trackedVehiclePlate = nil -- Track the vehicle by its license plate
local vehicleConfirmed = false -- Flag to track if vehicle selection is confirmed

-- Wait until qb-core and ox_lib are available
CreateThread(function()
    while not QBCore do
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbcore') == 'started' then
            local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and obj then
                QBCore = obj
                if Config.Debug then
                    print("^2[mnc-engineswap]^7 QBCore client loaded successfully.")
                end
            end
        end
        Wait(500)
    end
    while not GetResourceState('ox_lib') or GetResourceState('ox_lib') ~= 'started' do
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Waiting for ox_lib...")
        end
        Wait(500)
    end
    if Config.Debug then
        print("^2[mnc-engineswap]^7 ox_lib ready.")
    end

    -- Create blips for shops
    for _, shop in ipairs(Config.EngineShops) do
        if shop.blip then
            local blipHandle = AddBlipForCoord(shop.location.x, shop.location.y, shop.location.z)
            SetBlipSprite(blipHandle, shop.blip.sprite)
            SetBlipColour(blipHandle, shop.blip.color)
            SetBlipScale(blipHandle, shop.blip.scale or 0.8)
            SetBlipAsShortRange(blipHandle, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(shop.blip.name or shop.title or "Engine Shop")
            EndTextCommandSetBlipName(blipHandle)
        end
    end
end)

-- =====================================================================
-- HELPER FUNCTIONS
-- =====================================================================
local function CheckRequirements(shop)
    local Player = QBCore.Functions.GetPlayerData()
   
    -- Check job requirement for the specific shop
    if shop.jobs and #shop.jobs > 0 then
        local hasRequiredJob = false
        local jobLabels = {}
        for _, job in ipairs(shop.jobs) do
            if Player.job.name == job then
                hasRequiredJob = true
                break
            end
            if QBCore.Shared.Jobs[job] and QBCore.Shared.Jobs[job].label then
                table.insert(jobLabels, QBCore.Shared.Jobs[job].label)
            else
                table.insert(jobLabels, job)
            end
        end
        if not hasRequiredJob then
            lib.notify({
                title = 'Access Denied',
                description = 'You need to be a ' .. table.concat(jobLabels, ' or ') .. ' to use this shop.',
                type = 'error'
            })
            return false
        end
    end
   
    -- Check item requirement
    if Config.RequiredItem and Config.RequiredItem ~= false then
        local hasItem = QBCore.Functions.HasItem(Config.RequiredItem)
        if not hasItem then
            lib.notify({
                title = 'Missing Item',
                description = 'You need a ' .. Config.RequiredItem .. ' to install engines.',
                type = 'error'
            })
            return false
        end
    end
   
    return true
end

local function IsNearVehicleFrontLights(vehicle)
    local ped = PlayerPedId()
    local vehiclePos = GetEntityCoords(vehicle)
    local headlightBone = GetEntityBoneIndexByName(vehicle, "headlight_l") or GetEntityBoneIndexByName(vehicle, "headlight_r")
    local headlightPos = headlightBone ~= -1 and GetWorldPositionOfEntityBone(vehicle, headlightBone) or vehiclePos
    local playerPos = GetEntityCoords(ped)
    local distance = #(playerPos - headlightPos)
    if Config.Debug then
        print("^2[mnc-engineswap]^7 Distance to vehicle headlights: " .. distance)
    end
    return distance < 2.0
end

-- NEW: Function to get the closest vehicle by plate
local function GetVehicleByPlate(plate)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local closestVehicle = GetClosestVehicle(pos, 5.0, 0, 70)
    if closestVehicle and DoesEntityExist(closestVehicle) then
        local vehiclePlate = GetVehicleNumberPlateText(closestVehicle)
        if vehiclePlate == plate then
            return closestVehicle
        end
    end
    return nil
end

-- Function to spawn engine prop at delivery location
local function SpawnDeliveryProp(coords)
    if deliveryProp then
        DeleteObject(deliveryProp)
        deliveryProp = nil
    end
    local propModel = `prop_car_engine_01` -- Example prop, can be changed in config if needed
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do
        Wait(10)
    end
    -- Spawn engine slightly above ground to sit on pallet (pallet will be spawned later)
    local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
    local engineHeightOffset = 0.20 -- Adjust this value to position engine on top of pallet
    deliveryProp = CreateObject(propModel, coords.x, coords.y, groundZ + engineHeightOffset, false, false, false)
    SetEntityHeading(deliveryProp, 0.0)
    SetModelAsNoLongerNeeded(propModel)
    if Config.Debug then
        print("^2[mnc-engineswap]^7 Spawned delivery prop at: " .. json.encode({x = coords.x, y = coords.y, z = groundZ + engineHeightOffset}))
    end
end

-- Function to delete delivery prop
local function DeleteDeliveryProp()
    if deliveryProp and DoesEntityExist(deliveryProp) then
        DeleteObject(deliveryProp)
        deliveryProp = nil
        if Config.Debug then
            print("^2[mnc-engineswap]^7 Delivery prop deleted")
        end
    end
end

-- Function to delete pallet prop
local function DeletePalletProp()
    if palletProp and DoesEntityExist(palletProp) then
        DeleteObject(palletProp)
        palletProp = nil
        if Config.Debug then
            print("^2[mnc-engineswap]^7 Pallet prop deleted")
        end
    end
end

-- NEW: Function to spawn pallet prop
local function SpawnPalletProp(coords)
    if palletProp then
        DeleteObject(palletProp)
        palletProp = nil
    end
    local propModel = `prop_pallet_02a` -- Example pallet prop
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do
        Wait(10)
    end
    local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
	local PalletHeightOffset = -0.85
    palletProp = CreateObject(propModel, coords.x, coords.y, groundZ + PalletHeightOffset, true, true, true)
    SetEntityHeading(palletProp, 0.0)
    SetModelAsNoLongerNeeded(propModel)
    if Config.Debug then
        print("^2[mnc-engineswap]^7 Spawned pallet prop at: " .. json.encode({x = coords.x, y = coords.y, z = groundZ}))
    end
end

-- Function to get handling data from a vehicle model based on audio hash
local function GetHandlingModifiers(audioHash)
    -- Map audio hash to vehicle model (assuming audio hash matches vehicle model name)
    local vehicleModel = GetHashKey(audioHash)
    if not IsModelInCdimage(vehicleModel) or not IsModelAVehicle(vehicleModel) then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Invalid vehicle model for audio hash: " .. audioHash)
        end
        -- Fallback default values
        return {
            fInitialDriveForce = 0.25,
            fInitialDriveMaxFlatVel = 130.0,
            fTractionCurveMax = 2.0
        }
    end
    -- Spawn a temporary vehicle off-screen to extract handling data
    local ped = PlayerPedId()
    local spawnPos = GetOffsetFromEntityInWorldCoords(ped, 0.0, -1000.0, -1000.0) -- Far away to avoid visibility
    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do
        Wait(10)
    end
    local tempVehicle = CreateVehicle(vehicleModel, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, false, false)
    if not DoesEntityExist(tempVehicle) then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Failed to spawn temporary vehicle for model: " .. audioHash)
        end
        SetModelAsNoLongerNeeded(vehicleModel)
        return {
            fInitialDriveForce = 0.25,
            fInitialDriveMaxFlatVel = 130.0,
            fTractionCurveMax = 2.0
        }
    end
    -- Extract handling data
    local handlingData = {
        fInitialDriveForce = GetVehicleHandlingFloat(tempVehicle, "CHandlingData", "fInitialDriveForce"),
        fInitialDriveMaxFlatVel = GetVehicleHandlingFloat(tempVehicle, "CHandlingData", "fInitialDriveMaxFlatVel"),
        fTractionCurveMax = GetVehicleHandlingFloat(tempVehicle, "CHandlingData", "fTractionCurveMax")
    }
    -- Clean up temporary vehicle
    DeleteVehicle(tempVehicle)
    SetModelAsNoLongerNeeded(vehicleModel)
    if Config.Debug then
        print("^2[mnc-engineswap]^7 Retrieved handling for " .. audioHash .. ": " .. json.encode(handlingData))
    end
   
    -- Ensure valid values
    if handlingData.fInitialDriveForce == 0.0 or handlingData.fInitialDriveMaxFlatVel == 0.0 or handlingData.fTractionCurveMax == 0.0 then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Invalid handling data for " .. audioHash .. ", using defaults")
        end
        return {
            fInitialDriveForce = 0.25,
            fInitialDriveMaxFlatVel = 130.0,
            fTractionCurveMax = 2.0
        }
    end
    return handlingData
end

-- Function to apply saved engine to vehicle
local function ApplySavedEngine(vehicle, sound)
    if not DoesEntityExist(vehicle) or GetVehicleEngineHealth(vehicle) <= 0 then
        return false
    end
    SetVehicleEngineOn(vehicle, true, false, true)
    local soundSuccess = pcall(function()
        ForceVehicleEngineAudio(vehicle, sound)
    end)
    local handlingModifiers = GetHandlingModifiers(sound)
    local handlingSuccess = true
    if handlingModifiers then
        handlingSuccess = pcall(function()
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", handlingModifiers.fInitialDriveForce)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", handlingModifiers.fInitialDriveMaxFlatVel)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fTractionCurveMax", handlingModifiers.fTractionCurveMax)
            SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        end)
    else
        handlingSuccess = false
    end
    return soundSuccess and handlingSuccess
end

-- Thread to apply persisted engines
local lastPlate = nil
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, -1) == ped then
                local plate = GetVehicleNumberPlateText(veh)
                if plate and plate ~= lastPlate then
                    lastPlate = plate
                    QBCore.Functions.TriggerCallback('mnc-engineswap:getEngine', function(sound)
                        if sound then
                            if Config.Debug then
                                print("^2[mnc-engineswap]^7 Applying saved engine sound: " .. sound .. " to plate: " .. plate)
                            end
                            ApplySavedEngine(veh, sound)
                        end
                    end, plate)
                end
            else
                lastPlate = nil
            end
        else
            lastPlate = nil
        end
        Wait(1000)
    end
end)

-- NEW: Improved function to check if player is in a vehicle and track its plate
local function CheckPlayerInVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 and DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        if plate and plate ~= "" then
            trackedVehiclePlate = plate
            currentVehicle = vehicle
            if Config.Debug then
                print("^2[mnc-engineswap]^7 Player is in vehicle with plate: " .. plate .. ", vehicle entity: " .. vehicle)
            end
            return true
        else
            if Config.Debug then
                print("^3[mnc-engineswap]^7 Failed to get vehicle plate, vehicle: " .. vehicle)
            end
        end
    else
        if Config.Debug then
            print("^2[mnc-engineswap]^7 Player not in vehicle, GetVehiclePedIsIn returned: " .. vehicle)
        end
    end
    return false
end

-- NEW: Helper function to show vehicle selection prompt
local function ShowVehicleSelectionPrompt(theme)
    lib.showTextUI('[E] - Track Vehicle for Engine Swap', {
        position = 'left-center',
        icon = 'car',
        style = {
            backgroundColor = theme == 'blue' and '#1a73e8' or
                             theme == 'red' and '#d32f2f' or
                             theme == 'green' and '#2e7d32' or
                             theme == 'purple' and '#7b1fa2' or
                             theme == 'orange' and '#f57c00' or '#1a73e8',
            color = '#ffffff',
            borderRadius = '8px',
            padding = '10px'
        }
    })
end

-- NEW: Helper function to show exit vehicle prompt
local function ShowExitVehiclePrompt(theme)
    lib.showTextUI('Please exit the vehicle to install engine', {
        position = 'left-center',
        icon = 'exclamation-triangle',
        style = {
            backgroundColor = theme == 'blue' and '#1a73e8' or
                             theme == 'red' and '#d32f2f' or
                             theme == 'green' and '#2e7d32' or
                             theme == 'purple' and '#7b1fa2' or
                             theme == 'orange' and '#f57c00' or '#1a73e8',
            color = '#ffffff',
            borderRadius = '8px',
            padding = '10px'
        }
    })
end

-- NEW: Helper function to hide text UI
local function HideTextUI()
    lib.hideTextUI()
end

-- =====================================================================
-- OPEN SHOPS
-- =====================================================================
CreateThread(function()
    local textShown = {}
    while true do
        local sleep = 1500
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
       
        for i, shop in ipairs(Config.EngineShops) do
            local dist = #(pos - shop.location)
            if dist < 5.0 then
                sleep = 0
                DrawMarker(36, shop.location.x, shop.location.y, shop.location.z + 1.0, 0, 0, 0, 0, 0, 0, 0.8, 0.8, 0.8, 0, 255, 150, 150, false, false, 2, nil, nil, false)
                if dist < 2.0 then
                    if not textShown[i] then
                        lib.showTextUI('[E] - Open ' .. shop.title, {
                            position = 'left-center',
                            style = {
                                backgroundColor = shop.theme == 'blue' and '#1a73e8' or
                                                 shop.theme == 'red' and '#d32f2f' or
                                                 shop.theme == 'green' and '#2e7d32' or
                                                 shop.theme == 'purple' and '#7b1fa2' or
                                                 shop.theme == 'orange' and '#f57c00' or '#1a73e8',
                                color = '#ffffff',
                                borderRadius = '8px',
                                padding = '10px'
                            }
                        })
                        textShown[i] = true
                    end
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        textShown[i] = false
                        if CheckRequirements(shop) then
                            currentShop = shop
                            TriggerEvent('mnc-engineswap:openShop')
                        end
                    end
                else
                    if textShown[i] then
                        lib.hideTextUI()
                        textShown[i] = false
                    end
                end
            end
        end
        -- Delivery prompt
        if pendingShop and pendingShop.delivery and hasEngineCrate == false and orderedEngine then
            local dist = #(pos - vector3(pendingShop.delivery.x, pendingShop.delivery.y, pendingShop.delivery.z))
            if dist < 15.0 then
                sleep = 0
                local _, groundZ = GetGroundZFor_3dCoord(pendingShop.delivery.x, pendingShop.delivery.y, pendingShop.delivery.z, false)
                DrawMarker(36, pendingShop.delivery.x, pendingShop.delivery.y, groundZ + 1.0, 0, 0, 0, 0, 0, 0, 0.8, 0.8, 0.8, 0, 255, 150, 150, false, false, 2, nil, nil, false)
                if dist < 3.0 then
                    if not textShown['delivery'] then
                        if Config.Debug then
                            print("^2[mnc-engineswap]^7 Showing delivery prompt at: " .. json.encode(pendingShop.delivery))
                        end
                        lib.showTextUI('[E] - Pick up engine crate', {
                            position = 'left-center',
                            style = {
                                backgroundColor = pendingShop.theme == 'blue' and '#1a73e8' or
                                                 pendingShop.theme == 'red' and '#d32f2f' or
                                                 pendingShop.theme == 'green' and '#2e7d32' or
                                                 pendingShop.theme == 'purple' and '#7b1fa2' or
                                                 pendingShop.theme == 'orange' and '#f57c00' or '#1a73e8',
                                color = '#ffffff',
                                borderRadius = '8px',
                                padding = '10px'
                            }
                        })
                        textShown['delivery'] = true
                    end
                    if IsControlJustPressed(0, 38) then
                        if Config.Debug then
                            print("^2[mnc-engineswap]^7 Picking up engine crate")
                        end
                        lib.hideTextUI()
                        textShown['delivery'] = false
                        hasEngineCrate = true
                        DeleteDeliveryProp()
                        DeletePalletProp()
                    end
                elseif textShown['delivery'] then
                    if Config.Debug then
                        print("^2[mnc-engineswap]^7 Hiding delivery prompt, player too far: " .. dist)
                    end
                    lib.hideTextUI()
                    textShown['delivery'] = false
                end
            end
        end
        -- NEW: Install prompt with vehicle tracking by plate (Updated)
        if pendingShop and pendingShop.install and hasEngineCrate then
            local dist = #(pos - vector3(pendingShop.install.x, pendingShop.install.y, pendingShop.install.z))
            if dist < 15.0 then
                sleep = 0
                local _, groundZ = GetGroundZFor_3dCoord(pendingShop.install.x, pendingShop.install.y, pendingShop.install.z, false)
                DrawMarker(36, pendingShop.install.x, pendingShop.install.y, groundZ + 1.0, 0, 0, 0, 0, 0, 0, 0.8, 0.8, 0.8, 0, 255, 150, 150, false, false, 2, nil, nil, false)
               
                -- Reset all text UI states if moving away
                if dist >= 5.0 then -- Increased from 3.0 to 5.0
                    if textShown['vehicle_select'] or textShown['vehicle_error'] or textShown['exit_vehicle'] or textShown['install'] then
                        textShown['vehicle_select'] = false
                        textShown['vehicle_error'] = false
                        textShown['exit_vehicle'] = false
                        textShown['install'] = false
                        HideTextUI()
                        if Config.Debug then
                            print("^2[mnc-engineswap]^7 Hiding all install-related prompts, player too far: " .. dist)
                        end
                    end
                else
                    -- Reset error prompt if player enters vehicle
                    if CheckPlayerInVehicle() then
                        if textShown['vehicle_error'] then
                            textShown['vehicle_error'] = false
                            HideTextUI()
                            if Config.Debug then
                                print("^2[mnc-engineswap]^7 Hiding vehicle error prompt, player entered vehicle")
                            end
                        end
                    end
                    -- Check if vehicle is tracked
                    if not vehicleConfirmed then
                        if CheckPlayerInVehicle() then
                            if not textShown['vehicle_select'] then
                                textShown['vehicle_select'] = true
                                textShown['vehicle_error'] = false -- Ensure error prompt is cleared
                                if Config.Debug then
                                    print("^2[mnc-engineswap]^7 Showing vehicle selection prompt at: " .. json.encode(pendingShop.install) .. ", plate: " .. (trackedVehiclePlate or "none"))
                                end
                                ShowVehicleSelectionPrompt(pendingShop.theme)
                            end
                            if IsControlJustPressed(0, 38) then
                                vehicleConfirmed = true
                                textShown['vehicle_select'] = false
                                HideTextUI()
                                if Config.Debug then
                                    print("^2[mnc-engineswap]^7 Vehicle tracked for engine swap, plate: " .. trackedVehiclePlate)
                                end
                            end
                        else
                            if not textShown['vehicle_error'] and not textShown['vehicle_select'] then
                                textShown['vehicle_error'] = true
                                if Config.Debug then
                                    print("^2[mnc-engineswap]^7 Showing vehicle error prompt at: " .. json.encode(pendingShop.install))
                                end
                                lib.showTextUI('Please enter a vehicle first', {
                                    position = 'left-center',
                                    icon = 'exclamation-triangle',
                                    style = {
                                        backgroundColor = '#d32f2f',
                                        color = '#ffffff',
                                        borderRadius = '8px',
                                        padding = '10px'
                                    }
                                })
                            end
                        end
                    elseif vehicleConfirmed then
                        if IsPedInAnyVehicle(ped, false) then
                            if not textShown['exit_vehicle'] then
                                textShown['exit_vehicle'] = true
                                textShown['install'] = false -- Ensure install prompt is cleared
                                if Config.Debug then
                                    print("^2[mnc-engineswap]^7 Showing exit vehicle prompt at: " .. json.encode(pendingShop.install) .. ", plate: " .. trackedVehiclePlate)
                                end
                                ShowExitVehiclePrompt(pendingShop.theme)
                            end
                        else
                            if not textShown['install'] then
                                textShown['install'] = true
                                textShown['exit_vehicle'] = false -- Ensure exit prompt is cleared
                                if Config.Debug then
                                    print("^2[mnc-engineswap]^7 Showing install prompt at: " .. json.encode(pendingShop.install) .. ", plate: " .. trackedVehiclePlate)
                                end
                                lib.showTextUI('[E] - Install engine', {
                                    position = 'left-center',
                                    style = {
                                        backgroundColor = pendingShop.theme == 'blue' and '#1a73e8' or
                                                         pendingShop.theme == 'red' and '#d32f2f' or
                                                         pendingShop.theme == 'green' and '#2e7d32' or
                                                         pendingShop.theme == 'purple' and '#7b1fa2' or
                                                         pendingShop.theme == 'orange' and '#f57c00' or '#1a73e8',
                                        color = '#ffffff',
                                        borderRadius = '8px',
                                        padding = '10px'
                                    }
                                })
                            end
                            if IsControlJustPressed(0, 38) then
                                if Config.Debug then
                                    print("^2[mnc-engineswap]^7 Install prompt activated, starting engine swap for plate: " .. trackedVehiclePlate)
                                end
                                textShown['install'] = false
                                HideTextUI()
                                StartEngineSwapProcess()
                                hasEngineCrate = false
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- =====================================================================
-- NUI OPEN
-- =====================================================================
RegisterNetEvent('mnc-engineswap:openShop', function()
    if Config.Debug then
        print("^2[mnc-engineswap]^7 Opening shop UI for " .. currentShop.title)
    end
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openShop',
        engines = Config.EngineSounds,
        shopTitle = currentShop.title,
        shopTheme = currentShop.theme
    })
end)

-- NUI CALLBACK: Close shop
RegisterNUICallback('closeShop', function(data, cb)
    if Config.Debug then
        print("^2[mnc-engineswap]^7 Closing shop UI")
    end
    SetNuiFocus(false, false)
    if orderedEngine then
        pendingShop = currentShop -- Preserve shop data for delivery/installation
    end
    currentShop = nil
    DeleteDeliveryProp()
    DeletePalletProp()
    targetPlayerId = nil -- Reset targetPlayerId
    trackedVehiclePlate = nil -- NEW: Reset tracked vehicle plate
    vehicleConfirmed = false -- NEW: Reset vehicle confirmation
    cb('ok')
end)

-- NUI CALLBACK: Order engine
RegisterNUICallback('orderEngine', function(data, cb)
    if Config.Debug then
        print("^2[mnc-engineswap]^7 orderEngine callback triggered with data: " .. json.encode(data))
    end
    SetNuiFocus(false, false)
    local engineData = data.engine
    if not engineData or not engineData.name or not engineData.sound or not engineData.price then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Invalid engine data received: " .. json.encode(engineData))
        end
        lib.notify({
            title = 'Error',
            description = 'Failed to process engine order. Invalid engine data.',
            type = 'error'
        })
        cb('error')
        return
    end
    orderedEngine = engineData
    pendingShop = currentShop -- Store shop data before UI closes
    targetPlayerId = data.targetPlayerId -- Store targetPlayerId
    if Config.Debug then
        print("^2[mnc-engineswap]^7 Triggering payment for engine: " .. engineData.name .. ", sound: " .. engineData.sound .. ", price: " .. engineData.price .. ", targetPlayerId: " .. tostring(targetPlayerId) .. ", pendingShop: " .. json.encode(pendingShop))
    end
    TriggerServerEvent('mnc-engineswap:processPayment', engineData.price, engineData, data.targetPlayerId)
    cb('ok')
end)

-- Fallback to close UI if server response fails
CreateThread(function()
    while true do
        Wait(1000)
        if orderedEngine and GetTimeSinceLastInput(0) > 10000 and not engineReady then
            if Config.Debug then
                print("^3[mnc-engineswap]^7 Fallback: Forcing UI close due to no server response")
            end
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'closeShop' })
            orderedEngine = nil
            pendingShop = nil
            hasEngineCrate = false
            DeleteDeliveryProp()
            DeletePalletProp()
            targetPlayerId = nil -- Reset targetPlayerId
            trackedVehiclePlate = nil -- NEW: Reset tracked vehicle plate
            vehicleConfirmed = false -- NEW: Reset vehicle confirmation
        end
    end
end)

-- Payment success → Start delivery wait
RegisterNetEvent('mnc-engineswap:paymentApproved', function(engineData)
    if not engineData or not engineData.name or not engineData.sound or not engineData.price then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Invalid engineData in paymentApproved: " .. json.encode(engineData))
        end
        lib.notify({
            title = 'Error',
            description = 'Invalid engine data received.',
            type = 'error'
        })
        return
    end
    orderedEngine = engineData
    engineReady = true
    lib.notify({
        title = 'Payment Successful',
        description = 'Payment for ' .. engineData.name .. ' engine (' .. (targetPlayerId and 'Player ' .. targetPlayerId or 'you') .. ') approved. Engine crate will be available in ' .. (Config.EngineDeliveryTime / 1000) .. ' seconds at the delivery point',
        type = 'success'
    })
    if Config.Debug then
        print("^2[mnc-engineswap]^7 Payment approved for engine: " .. engineData.name .. ", pendingShop: " .. json.encode(pendingShop))
    end
    TriggerServerEvent('mnc-engineswap:spawnDelivery')
end)

-- Delivery ready → Show pickup marker
RegisterNetEvent('mnc-engineswap:clientDeliveryReady', function(deliveryVec)
    if not pendingShop then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 No pendingShop data available")
        end
        lib.notify({
            title = 'Error',
            description = 'Shop data missing. Please try ordering again.',
            type = 'error'
        })
        engineReady = false
        orderedEngine = nil
        pendingShop = nil
        hasEngineCrate = false
        DeleteDeliveryProp()
        DeletePalletProp()
        targetPlayerId = nil -- Reset targetPlayerId
        trackedVehiclePlate = nil -- NEW: Reset tracked vehicle plate
        vehicleConfirmed = false -- NEW: Reset vehicle confirmation
        return
    end
    if not deliveryVec or not deliveryVec.x or not deliveryVec.y or not deliveryVec.z then
        if pendingShop and pendingShop.delivery then
            deliveryVec = pendingShop.delivery
            if Config.Debug then
                print("^2[mnc-engineswap]^7 Using pendingShop.delivery: " .. json.encode(deliveryVec))
            end
        else
            lib.notify({
                title = 'Error',
                description = 'No valid delivery coordinates available.',
                type = 'error'
            })
            engineReady = false
            orderedEngine = nil
            pendingShop = nil
            hasEngineCrate = false
            DeleteDeliveryProp()
            DeletePalletProp()
            targetPlayerId = nil -- Reset targetPlayerId
            trackedVehiclePlate = nil -- NEW: Reset tracked vehicle plate
            vehicleConfirmed = false -- NEW: Reset vehicle confirmation
            return
        end
    end
    if Config.Debug then
        print("^2[mnc-engineswap]^7 Delivery ready at coordinates: " .. json.encode(deliveryVec) .. ", hasEngineCrate: " .. tostring(hasEngineCrate) .. ", orderedEngine: " .. tostring(orderedEngine))
    end
   
    -- Spawn the prop at the delivery location
    SpawnDeliveryProp(deliveryVec)
    SpawnPalletProp(pendingShop.delivery)
end)

-- =====================================================================
-- INSTALL PROCESS
-- =====================================================================
function StartEngineSwapProcess()
    if isInstalling then
        lib.notify({
            title = 'Error',
            description = 'An engine installation is already in progress.',
            type = 'error'
        })
        engineReady = false
        orderedEngine = nil
        pendingShop = nil
        isInstalling = false
        DeleteDeliveryProp()
        DeletePalletProp()
        targetPlayerId = nil -- Reset targetPlayerId
        trackedVehiclePlate = nil -- NEW: Reset tracked vehicle plate
        vehicleConfirmed = false -- NEW: Reset vehicle confirmation
        return
    end
    isInstalling = true
    local ped = PlayerPedId()
   
    -- NEW: Check if vehicle is confirmed by plate
    if not vehicleConfirmed or not trackedVehiclePlate then
        lib.notify({
            title = 'Error',
            description = 'No vehicle selected for engine swap.',
            type = 'error'
        })
        engineReady = false
        orderedEngine = nil
        pendingShop = nil
        isInstalling = false
        DeleteDeliveryProp()
        DeletePalletProp()
        targetPlayerId = nil -- Reset targetPlayerId
        trackedVehiclePlate = nil -- NEW: Reset tracked vehicle plate
        vehicleConfirmed = false -- NEW: Reset vehicle confirmation
        return
    end
    -- NEW: Get vehicle by tracked plate
    currentVehicle = GetVehicleByPlate(trackedVehiclePlate)
    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        lib.notify({
            title = 'Error',
            description = 'The selected vehicle (plate: ' .. trackedVehiclePlate .. ') is not nearby.',
            type = 'error'
        })
        engineReady = false
        orderedEngine = nil
        pendingShop = nil
        isInstalling = false
        DeleteDeliveryProp()
        DeletePalletProp()
        targetPlayerId = nil -- Reset targetPlayerId
        trackedVehiclePlate = nil -- NEW: Reset tracked vehicle plate
        vehicleConfirmed = false -- NEW: Reset vehicle confirmation
        return
    end
    -- Check if player is near the front lights
    if not IsNearVehicleFrontLights(currentVehicle) then
        lib.notify({
            title = 'Error',
            description = 'You must be near the vehicle\'s front lights to install the engine.',
            type = 'error'
        })
        engineReady = false
        orderedEngine = nil
        pendingShop = nil
        isInstalling = false
        DeleteDeliveryProp()
        DeletePalletProp()
        targetPlayerId = nil -- Reset targetPlayerId
        trackedVehiclePlate = nil -- NEW: Reset tracked vehicle plate
        vehicleConfirmed = false -- NEW: Reset vehicle confirmation
        return
    end
    -- Open vehicle hood
    SetVehicleDoorOpen(currentVehicle, 4, false, false)
    -- Handle minigame if configured
    if Config.Installation.requireMinigame then
        local difficulties = {
            easy = {'easy', 'easy', 'medium'},
            medium = {'easy', 'medium', 'hard'},
            hard = {'medium', 'hard', 'hard'}
        }
        local selectedDifficulty = difficulties[Config.Installation.minigameMode] or difficulties.easy
        local minigameSuccess = lib.skillCheck(selectedDifficulty, {'w', 'a', 's', 'd'})
        if not minigameSuccess then
            lib.notify({
                title = 'Installation Failed',
                description = 'You failed the engine installation. A refund has been issued.',
                type = 'error'
            })
            TriggerServerEvent('mnc-engineswap:refundPayment', orderedEngine and orderedEngine.price or 0, orderedEngine, targetPlayerId)
            SetVehicleDoorShut(currentVehicle, 4, false)
            ClearPedTasks(ped)
            engineReady = false
            orderedEngine = nil
            pendingShop = nil
            isInstalling = false
            DeleteDeliveryProp()
            DeletePalletProp()
            targetPlayerId = nil -- Reset targetPlayerId
            trackedVehiclePlate = nil -- NEW: Reset tracked vehicle plate
            vehicleConfirmed = false -- NEW: Reset vehicle confirmation
            return
        end
    end
    -- Load animation if needed
    if Config.Installation.useAnimation then
        RequestAnimDict(Config.Installation.animDict)
        while not HasAnimDictLoaded(Config.Installation.animDict) do
            Wait(10)
        end
    end
    -- Calculate duration for each progress segment (one-third of total duration)
    local segmentDuration = math.floor(Config.Installation.progressDuration / 3)
    local progressSuccess = true
    -- Define progress bar/circle configuration
    local progressConfig = {
        useWhileDead = false,
        canCancel = false,
        position = 'bottom',
        anim = Config.Installation.useAnimation and {
            dict = Config.Installation.animDict,
            clip = Config.Installation.animClip,
            flag = 1
        } or nil
    }
    -- Show three-part progress based on config type
    if Config.Installation.progressType == 'circle' then
        if Config.Debug then
            print("^2[mnc-engineswap]^7 Starting three-part progressCircle for engine: " .. (orderedEngine and orderedEngine.name or "unknown"))
        end
        -- Part 1: Removing stock engine
        progressSuccess = lib.progressCircle({
            duration = segmentDuration,
            label = 'Removing stock engine...',
            useWhileDead = progressConfig.useWhileDead,
            canCancel = progressConfig.canCancel,
            position = progressConfig.position,
            anim = progressConfig.anim
        })
        if Config.Debug then
            print("^2[mnc-engineswap]^7 progressCircle (Removing stock engine) result: " .. tostring(progressSuccess))
        end
        if not progressSuccess then goto cleanup end
        -- Part 2: Installing conversion kit
        progressSuccess = lib.progressCircle({
            duration = segmentDuration,
            label = 'Installing conversion kit...',
            useWhileDead = progressConfig.useWhileDead,
            canCancel = progressConfig.canCancel,
            position = progressConfig.position,
            anim = progressConfig.anim
        })
        if Config.Debug then
            print("^2[mnc-engineswap]^7 progressCircle (Installing conversion kit) result: " .. tostring(progressSuccess))
        end
        if not progressSuccess then goto cleanup end
        -- Part 3: Installing chosen engine
        progressSuccess = lib.progressCircle({
            duration = segmentDuration,
            label = 'Installing ' .. (orderedEngine and orderedEngine.name or 'new') .. ' engine...',
            useWhileDead = progressConfig.useWhileDead,
            canCancel = progressConfig.canCancel,
            position = progressConfig.position,
            anim = progressConfig.anim
        })
        if Config.Debug then
            print("^2[mnc-engineswap]^7 progressCircle (Installing " .. (orderedEngine and orderedEngine.name or 'new') .. " engine) result: " .. tostring(progressSuccess))
        end
    else
        if Config.Debug then
            print("^2[mnc-engineswap]^7 Starting three-part progressBar for engine: " .. (orderedEngine and orderedEngine.name or "unknown"))
        end
        -- Part 1: Removing stock engine
        progressSuccess = lib.progressBar({
            duration = segmentDuration,
            label = 'Removing stock engine...',
            useWhileDead = progressConfig.useWhileDead,
            canCancel = progressConfig.canCancel,
            position = progressConfig.position,
            anim = progressConfig.anim
        })
        if Config.Debug then
            print("^2[mnc-engineswap]^7 progressBar (Removing stock engine) result: " .. tostring(progressSuccess))
        end
        if not progressSuccess then goto cleanup end
        -- Part 2: Installing conversion kit
        progressSuccess = lib.progressBar({
            duration = segmentDuration,
            label = 'Installing conversion kit...',
            useWhileDead = progressConfig.useWhileDead,
            canCancel = progressConfig.canCancel,
            position = progressConfig.position,
            anim = progressConfig.anim
        })
        if Config.Debug then
            print("^2[mnc-engineswap]^7 progressBar (Installing conversion kit) result: " .. tostring(progressSuccess))
        end
        if not progressSuccess then goto cleanup end
        -- Part 3: Installing chosen engine
        progressSuccess = lib.progressBar({
            duration = segmentDuration,
            label = 'Installing ' .. (orderedEngine and orderedEngine.name or 'new') .. ' engine...',
            useWhileDead = progressConfig.useWhileDead,
            canCancel = progressConfig.canCancel,
            position = progressConfig.position,
            anim = progressConfig.anim
        })
        if Config.Debug then
            print("^2[mnc-engineswap]^7 progressBar (Installing " .. (orderedEngine and orderedEngine.name or 'new') .. " engine) result: " .. tostring(progressSuccess))
        end
    end

    -- Apply engine sound and handling
    if progressSuccess and orderedEngine and orderedEngine.sound then
        -- Ensure vehicle is valid and engine is on
        if not DoesEntityExist(currentVehicle) or GetVehicleEngineHealth(currentVehicle) <= 0 then
            if Config.Debug then
                print("^3[mnc-engineswap]^7 Invalid vehicle state: EntityExists=" .. tostring(DoesEntityExist(currentVehicle)) .. ", EngineHealth=" .. GetVehicleEngineHealth(currentVehicle))
            end
            lib.notify({
                title = 'Error',
                description = 'Invalid vehicle state. Ensure the vehicle is operational.',
                type = 'error'
            })
            TriggerServerEvent('mnc-engineswap:refundPayment', orderedEngine.price, orderedEngine, targetPlayerId)
        else
            SetVehicleEngineOn(currentVehicle, true, false, true)
            if Config.Debug then
                print("^2[mnc-engineswap]^7 Applying engine sound: " .. orderedEngine.sound .. " to vehicle with plate: " .. trackedVehiclePlate)
            end
            local soundSuccess = pcall(function()
                ForceVehicleEngineAudio(currentVehicle, orderedEngine.sound)
            end)
            -- Apply handling modifiers based on the source vehicle's handling
            local handlingModifiers = GetHandlingModifiers(orderedEngine.sound)
            local handlingSuccess = true
            if handlingModifiers then
                handlingSuccess = pcall(function()
                    SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveForce", handlingModifiers.fInitialDriveForce)
                    SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveMaxFlatVel", handlingModifiers.fInitialDriveMaxFlatVel)
                    SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fTractionCurveMax", handlingModifiers.fTractionCurveMax)
                    -- Notify the game engine of handling changes
                    SetVehicleHasBeenOwnedByPlayer(currentVehicle, true)
                end)
            else
                handlingSuccess = false
                if Config.Debug then
                    print("^3[mnc-engineswap]^7 No handling modifiers found for audio hash: " .. orderedEngine.sound)
                end
            end

            if soundSuccess and handlingSuccess then
                lib.notify({
                    title = 'Engine Installed',
                    description = 'Engine swap complete! ' .. orderedEngine.name .. ' engine installed.',
                    type = 'success'
                })
                TriggerServerEvent('mnc-engineswap:saveEngine', trackedVehiclePlate, orderedEngine.sound)
            else
                if Config.Debug then
                    print("^3[mnc-engineswap]^7 Failed to apply engine: soundSuccess=" .. tostring(soundSuccess) .. ", handlingSuccess=" .. tostring(handlingSuccess))
                end
                lib.notify({
                    title = 'Error',
                    description = 'Failed to install engine. A refund has been issued.',
                    type = 'error'
                })
                TriggerServerEvent('mnc-engineswap:refundPayment', orderedEngine.price, orderedEngine, targetPlayerId)
            end
        end
    else
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Engine sound application skipped: progressSuccess=" .. tostring(progressSuccess) .. ", orderedEngine=" .. tostring(orderedEngine) .. ", sound=" .. tostring(orderedEngine and orderedEngine.sound))
        end
        lib.notify({
            title = 'Engine Installed',
            description = 'Engine swap complete, but sound or handling was not applied.',
            type = 'warning'
        })
        if orderedEngine then
            TriggerServerEvent('mnc-engineswap:refundPayment', orderedEngine.price, orderedEngine, targetPlayerId)
        end
    end

    ::cleanup::
    -- Close hood and clear animation
    SetVehicleDoorShut(currentVehicle, 4, false)
    if Config.Installation.useAnimation then
        ClearPedTasks(ped)
    end
    -- Reset states to allow another swap
    engineReady = false
    orderedEngine = nil
    currentVehicle = nil
    isInstalling = false
    pendingShop = nil
    DeleteDeliveryProp()
    DeletePalletProp()
    targetPlayerId = nil -- Reset targetPlayerId
    trackedVehiclePlate = nil -- NEW: Reset tracked vehicle plate
    vehicleConfirmed = false -- NEW: Reset vehicle confirmation
end

-- Close NUI on ESC
RegisterNUICallback('escape', function(data, cb)
    if Config.Debug then
        print("^2[mnc-engineswap]^7 ESC key pressed, closing NUI")
    end
    SetNuiFocus(false, false)
    if orderedEngine then
        pendingShop = currentShop -- Preserve shop data for delivery/installation
    end
    currentShop = nil
    DeleteDeliveryProp()
    DeletePalletProp()
    targetPlayerId = nil -- Reset targetPlayerId
    trackedVehiclePlate = nil -- NEW: Reset tracked vehicle plate
    vehicleConfirmed = false -- NEW: Reset vehicle confirmation
    cb('ok')
end)