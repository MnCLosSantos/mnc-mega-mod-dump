local QBCore = exports['qb-core']:GetCoreObject()

-- Debug helper function
local function debugPrint(...)
    if not Config.Debug then return end
    print("[mnc-respraypoints DEBUG]", ...)
end

local function debugNotify(msg)
    if not Config.Debug then return end
    lib.notify({
        title = '[DEBUG] Respray Points',
        description = msg,
        type = 'inform',
        duration = 4000
    })
end

local mechanicsOnDuty = false
local playerJob = { name = 'unemployed', grade = { level = 0 } }

-- Preview state tracking
local previewActive = false
local originalColors = {}

-- Get initial player job data
CreateThread(function()
    Wait(2000)
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.job then
        playerJob = PlayerData.job
        debugPrint("Initial job loaded:", playerJob.name, "grade:", playerJob.grade.level)
    end
end)

-- Update job when it changes
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    playerJob = job
    debugPrint("Job updated →", job.name, "grade", job.grade.level)
end)

-- Receive mechanic duty status from server
RegisterNetEvent('mnc-respraypoints:updateMechanicDutyStatus', function(isAnyMechanicOnDuty)
    mechanicsOnDuty = isAnyMechanicOnDuty
    
    if Config.Debug then
        debugPrint("Mechanics on duty status updated →", mechanicsOnDuty and "YES (public points hidden)" or "NO (public points visible)")
    end
end)

local function GetCurrentVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        debugPrint("Not in any vehicle")
        return nil
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(veh, -1) ~= ped then
        debugPrint("Not driver seat")
        return nil
    end

    debugPrint("Current vehicle found → netId:", NetworkGetNetworkIdFromEntity(veh))
    return veh
end

local currentLocationName = nil
local currentLocationIsEmergencyOnly = false

-- Save original vehicle colors + livery for preview/restore
local function SaveOriginalColors(vehicle)
    SetVehicleModKit(vehicle, 0)
    local pri, sec = GetVehicleColours(vehicle)
    local pearl, wheel = GetVehicleExtraColours(vehicle)
    local interior = GetVehicleInteriorColour(vehicle)
    local dashboard = GetVehicleDashboardColour(vehicle)
    local livery = GetVehicleLivery(vehicle)
    local mod48 = GetVehicleMod(vehicle, 48)
    
    originalColors = {
        primary = pri,
        secondary = sec,
        pearlescent = pearl,
        wheel = wheel,
        interior = interior,
        dashboard = dashboard,
        livery = livery,
        mod48 = mod48
    }
    
    debugPrint("Original saved → Pri:", pri, "Sec:", sec, "Pearl:", pearl, "Wheel:", wheel, 
               "Int:", interior, "Dash:", dashboard, "Liv:", livery, "Mod48:", mod48)
end

-- Restore original colors + livery
local function RestoreOriginalColors(vehicle)
    if not originalColors.primary then return end
    
    SetVehicleModKit(vehicle, 0)
    SetVehicleColours(vehicle, originalColors.primary, originalColors.secondary)
    SetVehicleExtraColours(vehicle, originalColors.pearlescent, originalColors.wheel)
    SetVehicleInteriorColour(vehicle, originalColors.interior)
    SetVehicleDashboardColour(vehicle, originalColors.dashboard)
    
    -- Restore livery / mod
    if originalColors.mod48 and originalColors.mod48 ~= -1 then
        SetVehicleMod(vehicle, 48, originalColors.mod48, false)
    elseif originalColors.livery and originalColors.livery ~= -1 then
        SetVehicleLivery(vehicle, originalColors.livery)
    else
        SetVehicleLivery(vehicle, -1)
        SetVehicleMod(vehicle, 48, -1, false)
    end
    
    debugPrint("Original colors/livery/mod restored")
end

-- Preview color on vehicle
local function PreviewColor(vehicle, resprayType, colorIndex)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    
    if resprayType == 'primary' then
        local _, sec = GetVehicleColours(vehicle)
        SetVehicleColours(vehicle, colorIndex, sec)
    elseif resprayType == 'secondary' then
        local pri, _ = GetVehicleColours(vehicle)
        SetVehicleColours(vehicle, pri, colorIndex)
    elseif resprayType == 'pearlescent' then
        local _, wheel = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, colorIndex, wheel)
    elseif resprayType == 'wheel' then
        local pearl, _ = GetVehicleExtraColours(vehicle)
        SetVehicleExtraColours(vehicle, pearl, colorIndex)
    elseif resprayType == 'interior' then
        SetVehicleInteriorColour(vehicle, colorIndex)
    elseif resprayType == 'dashboard' then
        SetVehicleDashboardColour(vehicle, colorIndex)
    elseif resprayType == 'full' then
        SetVehicleColours(vehicle, colorIndex, colorIndex)
        SetVehicleExtraColours(vehicle, colorIndex, colorIndex)
        SetVehicleInteriorColour(vehicle, colorIndex)
        SetVehicleDashboardColour(vehicle, colorIndex)
    end
    
    debugPrint("Previewing", resprayType, "with color index:", colorIndex)
end

-- Open livery selection menu with improved detection
local function OpenLiverySelectionMenu(locationName, isEmergencyOnly)
    local veh = GetCurrentVehicle()
    if not veh then
        lib.notify({
            title = 'Respray Station',
            description = 'You must be in the driver seat',
            type = 'error'
        })
        return
    end
    
    SetVehicleModKit(veh, 0)
    
    -- Detect which livery system the vehicle uses
    local modCount = GetNumVehicleMods(veh, 48)
    local nativeCount = GetVehicleLiveryCount(veh)
    local maxLiveries = modCount > 0 and modCount or nativeCount
    local useNativeLivery = (modCount == 0 and nativeCount > 0)
    
    debugPrint("Livery detection → mod48:", modCount, "native:", nativeCount, 
               "using native:", useNativeLivery, "count:", maxLiveries)
    
    if maxLiveries <= 0 then
        lib.notify({
            title = 'Respray Station',
            description = 'This vehicle has no liveries available',
            type = 'error',
            duration = 4000
        })
        return
    end
    
    local price = isEmergencyOnly and 0 or Config.ResprayPrices.livery
    local priceText = isEmergencyOnly and 'Free' or ('$' .. price)
    
    SaveOriginalColors(veh)
    previewActive = true
    
    local options = {}
    
    -- Stock / No Livery
    table.insert(options, {
        title = 'Stock (No Livery)',
        description = 'Remove any active livery',
        icon = 'paintbrush',
        onSelect = function()
            SetVehicleModKit(veh, 0)
            if useNativeLivery then
                SetVehicleLivery(veh, -1)
            else
                SetVehicleMod(veh, 48, -1, false)
            end
            debugPrint("Previewing: Stock (no livery)")
            
            Wait(100)
            
            local alert = lib.alertDialog({
                header = 'Confirm Livery',
                content = ('Remove livery for **' .. priceText .. '**?\n\nProceed?'),
                centered = true,
                cancel = true,
                labels = {
                    confirm = isEmergencyOnly and 'Apply (Free)' or ('Apply ($' .. price .. ')'),
                    cancel = 'Cancel'
                }
            })
            
            if alert == 'confirm' then
                previewActive = false
                TriggerServerEvent('mnc-respraypoints:payAndRespray', 'livery', -1, locationName)
            else
                RestoreOriginalColors(veh)
            end
        end
    })
    
    -- Individual liveries
    for i = 0, maxLiveries - 1 do
        local title = 'Livery ' .. (i + 1)
        
        -- Try to get real name for native liveries (police, ambulance, taxi, etc.)
        if useNativeLivery then
            local liveryName = GetLiveryName(veh, i)
            if liveryName and liveryName ~= '' then
                local label = GetLabelText(liveryName)
                if label and label ~= 'NULL' and label ~= '' then
                    title = label
                end
            end
        end
        
        table.insert(options, {
            title = title,
            description = 'Preview and apply this livery',
            icon = 'paintbrush',
            onSelect = function()
                SetVehicleModKit(veh, 0)
                if useNativeLivery then
                    SetVehicleLivery(veh, i)
                else
                    SetVehicleMod(veh, 48, i, false)
                end
                debugPrint("Previewing livery index:", i, "native:", useNativeLivery)
                
                Wait(100)
                
                local alert = lib.alertDialog({
                    header = 'Confirm Livery',
                    content = ('Apply **' .. title .. '** for **' .. priceText .. '**?\n\nProceed?'),
                    centered = true,
                    cancel = true,
                    labels = {
                        confirm = isEmergencyOnly and 'Apply (Free)' or ('Apply ($' .. price .. ')'),
                        cancel = 'Cancel'
                    }
                })
                
                if alert == 'confirm' then
                    previewActive = false
                    TriggerServerEvent('mnc-respraypoints:payAndRespray', 'livery', i, locationName)
                else
                    RestoreOriginalColors(veh)
                end
            end
        })
    end
    
    table.insert(options, {
        title = '← Back to Menu',
        icon = 'arrow-left',
        onSelect = function()
            RestoreOriginalColors(veh)
            previewActive = false
            OpenResprayMenu(locationName, isEmergencyOnly)
        end
    })
    
    lib.registerContext({
        id = 'livery_selection_menu',
        title = 'Choose Livery (' .. maxLiveries .. ' available)',
        options = options,
        onExit = function()
            if previewActive then
                RestoreOriginalColors(veh)
                previewActive = false
            end
        end
    })
    
    lib.showContext('livery_selection_menu')
end

-- Open color selection menu with preview
local function OpenColorSelectionMenu(resprayType, locationName, isEmergencyOnly)
    local veh = GetCurrentVehicle()
    if not veh then
        lib.notify({
            title = 'Respray Station',
            description = 'You must be in the driver seat',
            type = 'error'
        })
        return
    end
    
    SetVehicleModKit(veh, 0)
    local price = isEmergencyOnly and 0 or (Config.ResprayPrices[resprayType] or Config.ResprayPrices.full)
    local priceText = isEmergencyOnly and 'Free' or ('$' .. price)

    debugPrint("Opening color selection for:", resprayType, "price:", priceText)
    
    SaveOriginalColors(veh)
    previewActive = true

    local options = {}
    for _, col in ipairs(Config.VehicleColors) do
        table.insert(options, {
            title = col.name,
            icon = 'palette',
            onSelect = function()
                debugPrint("Previewing color:", col.name, "index:", col.index)
                
                PreviewColor(veh, resprayType, col.index)
                
                Wait(100)
                
                local alert = lib.alertDialog({
                    header = 'Confirm Respray',
                    content = ('Respray %s to **%s** for **%s**?\n\nProceed?'):format(resprayType, col.name, priceText),
                    centered = true,
                    cancel = true,
                    labels = {
                        confirm = isEmergencyOnly and ('Respray (Free)') or ('Respray ($' .. price .. ')'),
                        cancel = 'Cancel'
                    }
                })
                
                if alert == 'confirm' then
                    previewActive = false
                    TriggerServerEvent('mnc-respraypoints:payAndRespray', resprayType, col.index, locationName)
                else
                    RestoreOriginalColors(veh)
                end
            end
        })
    end
    
    table.insert(options, {
        title = '← Back to Menu',
        icon = 'arrow-left',
        onSelect = function()
            RestoreOriginalColors(veh)
            previewActive = false
            OpenResprayMenu(locationName, isEmergencyOnly)
        end
    })

    lib.registerContext({
        id = 'respray_color_menu_' .. resprayType,
        title = resprayType == 'full' and 'Full Respray – Choose Base Color' or ('Choose ' .. resprayType:gsub("^%l", string.upper) .. ' Color'),
        options = options,
        onExit = function()
            if previewActive then
                RestoreOriginalColors(veh)
                previewActive = false
            end
        end
    })
    lib.showContext('respray_color_menu_' .. resprayType)
end

local function OpenResprayMenu(locationName, isEmergencyOnly)
    currentLocationName = locationName
    currentLocationIsEmergencyOnly = isEmergencyOnly or false

    debugPrint("Opening respray menu at:", locationName, "emergencyOnly:", currentLocationIsEmergencyOnly)
    debugNotify("Respray menu opened")

    local title = locationName or 'Respray Station'

    local fullPriceText = currentLocationIsEmergencyOnly and 'Free' or ('$' .. Config.ResprayPrices.full)

    local options = {
        {
            title = 'Primary Color',
            description = 'Main color – ' .. (currentLocationIsEmergencyOnly and 'Free' or ('$' .. Config.ResprayPrices.primary)),
            icon = 'palette',
            arrow = true,
            onSelect = function()
                debugPrint("Selected: Primary Color")
                OpenColorSelectionMenu('primary', locationName, currentLocationIsEmergencyOnly)
            end
        },
        {
            title = 'Secondary Color',
            description = 'Secondary color – ' .. (currentLocationIsEmergencyOnly and 'Free' or ('$' .. Config.ResprayPrices.secondary)),
            icon = 'palette',
            arrow = true,
            onSelect = function()
                debugPrint("Selected: Secondary Color")
                OpenColorSelectionMenu('secondary', locationName, currentLocationIsEmergencyOnly)
            end
        },
        {
            title = 'Pearlescent',
            description = 'Pearlescent finish – ' .. (currentLocationIsEmergencyOnly and 'Free' or ('$' .. Config.ResprayPrices.pearlescent)),
            icon = 'palette',
            arrow = true,
            onSelect = function()
                debugPrint("Selected: Pearlescent")
                OpenColorSelectionMenu('pearlescent', locationName, currentLocationIsEmergencyOnly)
            end
        },
        {
            title = 'Wheel Color',
            description = 'Wheel color – ' .. (currentLocationIsEmergencyOnly and 'Free' or ('$' .. Config.ResprayPrices.wheel)),
            icon = 'palette',
            arrow = true,
            onSelect = function()
                debugPrint("Selected: Wheel Color")
                OpenColorSelectionMenu('wheel', locationName, currentLocationIsEmergencyOnly)
            end
        },
        {
            title = 'Interior Color',
            description = 'Interior trim color – ' .. (currentLocationIsEmergencyOnly and 'Free' or ('$' .. Config.ResprayPrices.interior)),
            icon = 'couch',
            arrow = true,
            onSelect = function()
                debugPrint("Selected: Interior Color")
                OpenColorSelectionMenu('interior', locationName, currentLocationIsEmergencyOnly)
            end
        },
        {
            title = 'Dashboard Color',
            description = 'Dashboard color – ' .. (currentLocationIsEmergencyOnly and 'Free' or ('$' .. Config.ResprayPrices.dashboard)),
            icon = 'gauge',
            arrow = true,
            onSelect = function()
                debugPrint("Selected: Dashboard Color")
                OpenColorSelectionMenu('dashboard', locationName, currentLocationIsEmergencyOnly)
            end
        },
        {
            title = 'Livery',
            description = 'Apply vehicle livery – ' .. (currentLocationIsEmergencyOnly and 'Free' or ('$' .. Config.ResprayPrices.livery)),
            icon = 'paintbrush',
            arrow = true,
            onSelect = function()
                debugPrint("Selected: Livery")
                OpenLiverySelectionMenu(locationName, currentLocationIsEmergencyOnly)
            end
        },
        {
            title = 'Full Respray',
            description = 'All colors + wheels – ' .. fullPriceText,
            icon = 'paint-roller',
            arrow = true,
            onSelect = function()
                debugPrint("Selected: Full Respray")
                OpenColorSelectionMenu('full', locationName, currentLocationIsEmergencyOnly)
            end
        },
    }

    lib.registerContext({
        id = 'mnc_respray_menu',
        title = title,
        options = options,
        onExit = function()
            debugPrint("Respray menu closed")
            currentLocationName = nil
            currentLocationIsEmergencyOnly = false
        end
    })

    lib.showContext('mnc_respray_menu')
end

RegisterNetEvent('mnc-respraypoints:applyRespray', function(resprayType, colorIndex)
    debugPrint("Received applyRespray event → type:", resprayType, "index:", colorIndex)

    local veh = GetCurrentVehicle()
    if not veh or not DoesEntityExist(veh) then
        debugPrint("No valid vehicle for respray")
        lib.notify({
            title = 'Respray Station',
            description = 'You must be in the driver seat of a vehicle',
            type = 'error',
            duration = 3500
        })
        return
    end

    SetVehicleModKit(veh, 0)

    if resprayType == 'primary' then
        local _, sec = GetVehicleColours(veh)
        SetVehicleColours(veh, colorIndex, sec)
    elseif resprayType == 'secondary' then
        local pri, _ = GetVehicleColours(veh)
        SetVehicleColours(veh, pri, colorIndex)
    elseif resprayType == 'pearlescent' then
        local _, wheel = GetVehicleExtraColours(veh)
        SetVehicleExtraColours(veh, colorIndex, wheel)
    elseif resprayType == 'wheel' then
        local pearl, _ = GetVehicleExtraColours(veh)
        SetVehicleExtraColours(veh, pearl, colorIndex)
    elseif resprayType == 'interior' then
        SetVehicleInteriorColour(veh, colorIndex)
    elseif resprayType == 'dashboard' then
        SetVehicleDashboardColour(veh, colorIndex)
    elseif resprayType == 'livery' then
        local modCount = GetNumVehicleMods(veh, 48)
        local useNative = (modCount == 0)
        if useNative then
            SetVehicleLivery(veh, colorIndex)
        else
            SetVehicleMod(veh, 48, colorIndex, false)
        end
        debugPrint("Applied livery index:", colorIndex, "using native:", useNative)
    elseif resprayType == 'full' then
        SetVehicleColours(veh, colorIndex, colorIndex)
        SetVehicleExtraColours(veh, colorIndex, colorIndex)
        SetVehicleInteriorColour(vehicle, colorIndex)
        SetVehicleDashboardColour(vehicle, colorIndex)
    end

    SetVehicleDirtLevel(veh, 0.0)

    local successMsg = 'Vehicle resprayed!'
    if resprayType == 'full' then
        successMsg = 'Vehicle fully resprayed!'
    elseif resprayType == 'livery' then
        successMsg = 'Livery applied!'
    elseif resprayType == 'interior' then
        successMsg = 'Interior color applied!'
    elseif resprayType == 'dashboard' then
        successMsg = 'Dashboard color applied!'
    else
        successMsg = resprayType:gsub("^%l", string.upper) .. ' color applied!'
    end

    lib.notify({
        title = 'Respray Station',
        description = successMsg,
        type = 'success',
        duration = 4000
    })
end)

-- Restore original when payment fails
RegisterNetEvent('mnc-respraypoints:restoreOriginal', function()
    debugPrint("Server requested restore original colors (insufficient funds or payment failed)")
    
    local veh = GetCurrentVehicle()
    if not veh or not DoesEntityExist(veh) then
        debugPrint("No vehicle to restore")
        return
    end
    
    RestoreOriginalColors(veh)
    previewActive = false
    
    debugPrint("Original colors restored due to payment issue")
end)

-- Main loop
CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()
        if not ped or not DoesEntityExist(ped) then goto continue end

        if not IsPedInAnyVehicle(ped, false) then goto continue end

        local veh = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(veh, -1) ~= ped then goto continue end

        local coords = GetEntityCoords(ped)

        for _, loc in ipairs(Config.Locations.respray or {}) do
            local dist = #(coords - vector3(loc.coords.x, loc.coords.y, loc.coords.z))

            -- Job restriction check
            local canUseJob = true
            if loc.job then
                if playerJob.name ~= loc.job then
                    canUseJob = false
                elseif loc.minGrade and (playerJob.grade.level or 0) < loc.minGrade then
                    canUseJob = false
                end
            end

            -- Class restriction check (emergency only)
            local vehClass = GetVehicleClass(veh)
            local canUseClass = true
            if loc.emergencyOnly then
                canUseClass = (vehClass == 18)
            end

            local canUse = canUseJob and canUseClass

            if mechanicsOnDuty then
                if dist < 15.0 and not loc.job then
                    DrawText3D(
                        loc.coords.x,
                        loc.coords.y,
                        loc.coords.z + 1.0,
                        '~r~Mechanic on duty – visit customs!'
                    )
                end
            else
                if canUse and dist < 15.0 then
                    local extra = loc.emergencyOnly and " (Emergency Vehicles Only - Free Respray)" or ""
                    DrawText3D(
                        loc.coords.x,
                        loc.coords.y,
                        loc.coords.z + 1.0,
                        '[E] Respray Vehicle - ' .. (loc.name or 'Respray Station') .. extra
                    )
                elseif (loc.job or loc.emergencyOnly) and dist < 15.0 then
                    local restrictMsg = "~r~Restricted"
                    if loc.job and not canUseJob then
                        restrictMsg = restrictMsg .. " (" .. (loc.job or '?') .. ")"
                    end
                    if loc.emergencyOnly and not canUseClass then
                        restrictMsg = restrictMsg .. " (Emergency class only)"
                    end
                    DrawText3D(
                        loc.coords.x,
                        loc.coords.y,
                        loc.coords.z + 1.0,
                        restrictMsg
                    )
                end

                if canUse and dist < 5.0 and IsControlJustPressed(0, 38) then
                    debugPrint("E pressed at:", loc.name, "dist:", math.floor(dist), "class:", vehClass)
                    OpenResprayMenu(loc.name, loc.emergencyOnly)
                end
            end
        end

        ::continue::
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)

    local factor = string.len(text) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- Initial status request
CreateThread(function()
    Wait(1500)
    TriggerServerEvent('mnc-respraypoints:requestMechanicDutyStatus')
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(500)
    
    if Config.Debug then
        print("^2[mnc-respraypoints] ^0Respray points loaded - " .. #Config.Locations.respray .. " locations active")
        print("^3[mnc-respraypoints] ^0DEBUG MODE ENABLED")
    end
end)