local QBCore = exports['qb-core']:GetCoreObject()

-- Debug helper function
local function debugPrint(...)
    if not Config.Debug then return end
    print("[mnc-repairpoints DEBUG]", ...)
end

local function debugNotify(msg)
    if not Config.Debug then return end
    lib.notify({
        title = '[DEBUG] Repair Points',
        description = msg,
        type = 'inform',
        duration = 4000
    })
end

local mechanicsOnDuty = false
local playerJob = { name = 'unemployed', grade = { level = 0 } }

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
RegisterNetEvent('mnc-repairpoints:updateMechanicDutyStatus', function(isAnyMechanicOnDuty)
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
local currentLocationIsEmergencyOnly = false   -- New: track per-location

local function OpenRepairMenu(locationName, isEmergencyOnly)
    currentLocationName = locationName
    currentLocationIsEmergencyOnly = isEmergencyOnly or false

    debugPrint("Opening repair menu at:", locationName, "emergencyOnly:", currentLocationIsEmergencyOnly)
    debugNotify("Repair menu opened")

    local title = locationName or 'Repair Station'

    -- Prices or "Free"
    local fullPriceText  = currentLocationIsEmergencyOnly and 'Free' or ('$' .. Config.RepairPriceFull)
    local bodyPriceText  = currentLocationIsEmergencyOnly and 'Free' or ('$' .. Config.RepairPriceBody)

    local options = {
        {
            title = 'Full Repair',
            description = 'Engine + Body + Dirt - ' .. fullPriceText,
            icon = 'wrench',
            arrow = true,
            onSelect = function()
                debugPrint("Selected: Full Repair")
                local confirmText = currentLocationIsEmergencyOnly 
                    and 'This will fully repair the vehicle for **free**.\n\nProceed?' 
                    or  string.format('This will repair the entire vehicle for $%d.\n\nProceed?', Config.RepairPriceFull)

                local alert = lib.alertDialog({
                    header = 'Confirm Full Repair',
                    content = confirmText,
                    centered = true,
                    cancel = true,
                    labels = {
                        confirm = currentLocationIsEmergencyOnly and 'Repair (Free)' or ('Repair ($' .. Config.RepairPriceFull .. ')'),
                        cancel  = 'Cancel'
                    }
                })

                if alert == 'confirm' then
                    TriggerServerEvent('mnc-repairpoints:payAndRepair', 'full', currentLocationName)
                end
            end,
        },
        {
            title = 'Body Repair Only',
            description = 'Body damage only - ' .. bodyPriceText,
            icon = 'car',
            arrow = true,
            onSelect = function()
                debugPrint("Selected: Body Repair")
                local confirmText = currentLocationIsEmergencyOnly 
                    and 'This will repair visible body damage for **free**.\n\nProceed?' 
                    or  string.format('This will repair only visible body damage for $%d.\n\nProceed?', Config.RepairPriceBody)

                local alert = lib.alertDialog({
                    header = 'Confirm Body Repair',
                    content = confirmText,
                    centered = true,
                    cancel = true,
                    labels = {
                        confirm = currentLocationIsEmergencyOnly and 'Repair (Free)' or ('Repair ($' .. Config.RepairPriceBody .. ')'),
                        cancel  = 'Cancel'
                    }
                })

                if alert == 'confirm' then
                    TriggerServerEvent('mnc-repairpoints:payAndRepair', 'body', currentLocationName)
                end
            end,
        }
    }

    lib.registerContext({
        id    = 'mnc_repairpoints_menu',
        title = title,
        options = options,
        onExit = function()
            debugPrint("Repair menu closed")
            currentLocationName = nil
            currentLocationIsEmergencyOnly = false
        end
    })

    lib.showContext('mnc_repairpoints_menu')
end

RegisterNetEvent('mnc-repairpoints:applyRepair', function(repairType)
    debugPrint("Received applyRepair event → type:", repairType)

    local veh = GetCurrentVehicle()
    if not veh or not DoesEntityExist(veh) then
        debugPrint("No valid vehicle for repair")
        lib.notify({
            title = 'Repair Station',
            description = 'You must be in the driver seat of a vehicle',
            type = 'error',
            duration = 3500
        })
        return
    end

    if repairType == 'full' then
        debugPrint("Applying FULL repair")
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleUndriveable(veh, false)
        SetVehicleEngineOn(veh, true, true, true)
        SetVehicleDirtLevel(veh, 0.0)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehiclePetrolTankHealth(veh, 1000.0)
        for i = 0, 7 do
            FixVehicleWindow(veh, i)
        end
        SetVehicleLights(veh, 0)

    elseif repairType == 'body' then
        debugPrint("Applying BODY repair only")
        SetVehicleDeformationFixed(veh)
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehicleDirtLevel(veh, 0.0)
        for i = 0, 7 do
            FixVehicleWindow(veh, i)
        end
        SetVehicleLights(veh, 0)
    end

    lib.notify({
        title = 'Repair Station',
        description = repairType == 'full' 
            and 'Vehicle fully repaired!' 
            or 'Body damage repaired!',
        type = 'success',
        duration = 4000
    })
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

        for _, loc in ipairs(Config.Locations.repair or {}) do
            local dist = #(coords - vector3(loc.coords.x, loc.coords.y, loc.coords.z))

            local canUseJob = true
            if loc.job then
                if playerJob.name ~= loc.job then
                    canUseJob = false
                elseif loc.minGrade and (playerJob.grade.level or 0) < loc.minGrade then
                    canUseJob = false
                end
            end

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
                        '~r~Mechanic on duty – visit garage!'
                    )
                end
            else
                if canUse and dist < 15.0 then
                    local extra = loc.emergencyOnly and " (Emergency Vehicles Only - Free Repairs)" or ""
                    DrawText3D(
                        loc.coords.x, 
                        loc.coords.y, 
                        loc.coords.z + 1.0, 
                        '[E] Repair Vehicle - ' .. (loc.name or 'Repair Station') .. extra
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
                    OpenRepairMenu(loc.name, loc.emergencyOnly)
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
    TriggerServerEvent('mnc-repairpoints:requestMechanicDutyStatus')
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(500)
    
    if Config.Debug then
        print("^2[mnc-repairpoints] ^0Repair points loaded - " .. #Config.Locations.repair .. " locations active")
        print("^3[mnc-repairpoints] ^0DEBUG MODE ENABLED")
    end
end)