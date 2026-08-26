-- client.lua (FULL FILE - Simplified marker + visible from 75m)

local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}

local useOxMenu = Config.MenuType == "ox"
local useOxNotify = Config.NotifyType == "ox"
local useTarget = Config.UseQbTarget
local progressType = Config.ProgressType
local debugMode = Config.DebugMode

-- Player data
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    if debugMode then
        print("[DEBUG] Player data loaded:", json.encode(PlayerData))
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
    if debugMode then
        print("[DEBUG] Job updated:", json.encode(job))
    end
end)

-- Notification system
local function Notify(msg, type)
    if useOxNotify then
        lib.notify({ title = "Take a Trip", description = msg, type = type or 'info' })
    else
        QBCore.Functions.Notify(msg, type or 'primary')
    end
end

-- Sounds / Animation / Progress
local function PlayTravelSound()
    if Config.PlayTravelSound then
        PlaySoundFrontend(-1, Config.TravelSound, "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end

local function PlayTravelAnim()
    if not Config.PlayAnim then return end
    local ped = PlayerPedId()
    RequestAnimDict(Config.AnimDict)
    while not HasAnimDictLoaded(Config.AnimDict) do Wait(10) end
    TaskPlayAnim(ped, Config.AnimDict, Config.AnimName, 8.0, -8.0, 1500, 49, 0, false, false, false)
    Wait(1500)
    ClearPedTasks(ped)
end

local function ShowProgress(callback)
    if not Config.UseProgress then return callback() end
    if progressType == "bar" then
        lib.progressBar({
            duration = Config.ProgressTime,
            label = Config.ProgressLabel,
            position = 'bottom',
            canCancel = false,
            disable = { move = true, car = true, combat = true },
        })
        callback()
    elseif progressType == "circle" then
        lib.progressCircle({
            duration = Config.ProgressTime,
            label = Config.ProgressLabel,
            position = 'bottom',
            canCancel = false,
            disable = { move = true, car = true, combat = true },
        })
        callback()
    elseif progressType == "QB" then
        QBCore.Functions.Progressbar("trip_move", Config.ProgressLabel, Config.ProgressTime, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableCombat = true,
        }, {}, {}, {}, function()
            callback()
        end)
    end
end

-- Access checks
local function HasJobAccess(destination)
    if not destination.jobs or #destination.jobs == 0 then return true end
    if not PlayerData.job then return false end
    for _, job in ipairs(destination.jobs) do
        if PlayerData.job.name == job then
            return true
        end
    end
    return false
end

local function HasItemAccess(destination)
    if not destination.items or #destination.items == 0 then return true end
    for _, item in ipairs(destination.items) do
        if exports['qb-inventory']:HasItem(item) then
            return true
        end
    end
    return false
end

local function CanAccessDestination(destination)
    local jobAccess = HasJobAccess(destination)
    local itemAccess = HasItemAccess(destination)
    if destination.jobs and #destination.jobs > 0 then
        if debugMode then
            print("[DEBUG] Checking access for destination:", destination.label, "JobAccess:", jobAccess, "ItemAccess:", itemAccess)
        end
        return jobAccess and itemAccess
    end
    if debugMode then
        print("[DEBUG] Checking access for destination:", destination.label, "ItemAccess:", itemAccess)
    end
    return itemAccess
end

-- Charge system
local ChargePlayer = {}
ChargePlayer.waiting = nil

function ChargePlayer:attempt(destination, callback)
    if not destination.cost or destination.cost <= 0 then
        callback(true)
        return
    end

    self.waiting = callback
    TriggerServerEvent('mnc-takeatrip:server:chargePlayer', destination.cost)
end

RegisterNetEvent('mnc-takeatrip:client:chargeResult', function(success)
    if ChargePlayer.waiting then
        ChargePlayer.waiting(success)
        ChargePlayer.waiting = nil
    end
end)

-- Teleport
local function TeleportToDestination(destination)
    local ped = PlayerPedId()
    local inVehicle = IsPedInAnyVehicle(ped, false)
    local allowVehicle = destination.allowVehicle ~= false

    if inVehicle and not allowVehicle then
        Notify("You cannot take your vehicle to this destination!", "error")
        return
    end

    ChargePlayer:attempt(destination, function(canTravel)
        if not canTravel then
            Notify("You don't have enough money! ($" .. (destination.cost or 0) .. " required)", "error")
            return
        end

        PlayTravelAnim()
        ShowProgress(function()
            DoScreenFadeOut(500)
            Wait(500)

            local targetCoords = destination.arrivalCoords or destination.coords

            if inVehicle and allowVehicle then
                local veh = GetVehiclePedIsIn(ped, false)
                SetEntityCoords(veh, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, true)
                SetEntityHeading(veh, targetCoords.w)
                Wait(100)
                SetPedIntoVehicle(ped, veh, -1)
            else
                SetEntityCoords(ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, true)
                SetEntityHeading(ped, targetCoords.w)
            end

            Wait(500)
            DoScreenFadeIn(500)
            PlayTravelSound()

            if destination.cost and destination.cost > 0 then
                Notify("You arrived at " .. destination.label .. " (-$" .. destination.cost .. ")", "success")
            else
                Notify("You arrived at " .. destination.label, "success")
            end

            if debugMode then
                print("[DEBUG] Teleported to destination:", destination.label, "Coords:", json.encode(targetCoords))
            end
        end)
    end)
end

-- Menu
local function OpenTripMenu(locationName)
    local location = Config.Locations[locationName]
    if not location then
        if debugMode then
            print("[DEBUG] Location not found:", locationName)
        end
        return
    end

    if useOxMenu then
        local options = {}
        for _, dest in pairs(location) do
            if CanAccessDestination(dest) then
                local icon = dest.allowVehicle ~= false and 'fa-solid fa-car' or 'fa-solid fa-person-walking'
                local costText = (dest.cost and dest.cost > 0) and (" | $" .. dest.cost) or " | Free"
                options[#options + 1] = {
                    title = dest.label .. costText .. (dest.allowVehicle ~= false and " (Vehicle OK)" or " (No Vehicle)"),
                    icon = icon,
                    onSelect = function() TeleportToDestination(dest) end
                }
            else
                options[#options + 1] = {
                    title = dest.label .. " (Locked)",
                    icon = 'fa-solid fa-lock',
                    disabled = true,
                    onSelect = function()
                        local reason = ""
                        if dest.jobs and #dest.jobs > 0 and not HasJobAccess(dest) then
                            reason = "You do not have the required job."
                        elseif dest.items and #dest.items > 0 and not HasItemAccess(dest) then
                            reason = "You do not have the required item."
                        else
                            reason = "Access denied."
                        end
                        Notify(reason, "error")
                    end
                }
            end
        end
        lib.registerContext({
            id = 'mnc_takeatrip_menu_' .. locationName,
            title = 'Take a Trip - ' .. locationName,
            options = options
        })
        lib.showContext('mnc_takeatrip_menu_' .. locationName)
    else
        local menu = {}
        for _, dest in pairs(location) do
            local costText = (dest.cost and dest.cost > 0) and ("Cost: $" .. dest.cost) or "Free"
            if CanAccessDestination(dest) then
                menu[#menu + 1] = {
                    header = dest.label .. (dest.allowVehicle ~= false and " (Vehicle OK)" or " (No Vehicle)"),
                    txt = "Travel to " .. dest.label .. " • " .. costText,
                    params = { event = 'mnc-takeatrip:client:teleport', args = dest }
                }
            else
                menu[#menu + 1] = {
                    header = dest.label .. " (Locked)",
                    txt = "Access Denied",
                    params = {
                        event = 'mnc-takeatrip:client:notifyAccessDenied',
                        args = { jobs = dest.jobs, items = dest.items }
                    }
                }
            end
        end
        exports['qb-menu']:openMenu(menu)
    end
end

RegisterNetEvent('mnc-takeatrip:client:teleport', function(destination)
    TeleportToDestination(destination)
end)

RegisterNetEvent('mnc-takeatrip:client:notifyAccessDenied', function(data)
    local reason = ""
    if data.jobs and #data.jobs > 0 and not HasJobAccess({ jobs = data.jobs }) then
        reason = "You do not have the required job."
    elseif data.items and #data.items > 0 and not HasItemAccess({ items = data.items }) then
        reason = "You do not have the required item."
    else
        reason = "Access denied."
    end
    Notify(reason, "error")
end)

-- Blips creation
local function CreateLocationBlip(destination)
    if not destination.blip then return end

    local blipConfig = destination.blip
    local coords = destination.coords

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, blipConfig.sprite or 251)
    SetBlipColour(blip, blipConfig.color or 3)
    SetBlipScale(blip, blipConfig.scale or 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipConfig.name or destination.label)
    EndTextCommandSetBlipName(blip)

    if debugMode then
        print("[DEBUG] Created blip for:", destination.label, "at", json.encode(coords))
    end
end

-- SIMPLE & VISIBLE MARKER - Now seen from up to 75 meters
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        for locationName, destinations in pairs(Config.Locations) do
            for _, dest in pairs(destinations) do
                local markerPos = vector3(dest.coords.x, dest.coords.y, dest.coords.z)
                local dist = #(pos - markerPos)

                if dist < 120.0 then  -- Start rendering a bit before 75m for smooth appearance
                    sleep = 0

                    -- Simple upward-pointing arrow marker (very visible from far away)
                    DrawMarker(
                        1,                                          -- Type: Cylinder (simple pillar)
                        markerPos.x, markerPos.y, markerPos.z - 1.0, -- Position
                        0.0, 0.0, 0.0,                              -- Direction
                        0.0, 0.0, 0.0,                              -- Rotation
                        2.0, 2.0, 5.0,                              -- Scale: 2m wide, 5m tall
                        0, 255, 255, 200,                           -- Bright cyan, semi-transparent
                        true,                                       -- Bob up/down
                        true,                                       -- Face camera
                        2,                                          -- Rotate
                        false, nil, nil, false
                    )
                end
            end
        end

        Wait(sleep)
    end
end)

-- Add target zones + blips
CreateThread(function()
    Wait(1000)

    for locationName, destinations in pairs(Config.Locations) do
        for _, dest in pairs(destinations) do
            local loc = vector3(dest.coords.x, dest.coords.y, dest.coords.z)

            -- Create optional map blip
            CreateLocationBlip(dest)

            if useTarget then
                exports['qb-target']:AddBoxZone("mnc_trip_" .. locationName .. "_" .. dest.label, loc, 1.5, 1.5, {
                    name = "mnc_trip_" .. locationName .. "_" .. dest.label,
                    heading = dest.coords.w,
                    debugPoly = debugMode,
                    minZ = dest.coords.z - 1.0,
                    maxZ = dest.coords.z + 2.0,
                }, {
                    options = {
                        {
                            icon = "fa-solid fa-plane",
                            label = "Take a Trip",
                            action = function()
                                OpenTripMenu(locationName)
                            end,
                        },
                    },
                    distance = 2.0
                })
                if debugMode then
                    print("[DEBUG] Added target zone for:", locationName, dest.label)
                end
            end
        end
    end

    -- E-key fallback
    if not useTarget then
        CreateThread(function()
            while true do
                local sleep = 1500
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)

                for locationName, destinations in pairs(Config.Locations) do
                    for _, dest in pairs(destinations) do
                        local dist = #(pos - vector3(dest.coords.x, dest.coords.y, dest.coords.z))
                        if dist < 30.0 then
                            sleep = 0
                            if IsControlJustReleased(0, 38) then
                                OpenTripMenu(locationName)
                            end

                            if useOxMenu then
                                lib.showTextUI("[E] Take a Trip")
                            else
                                QBCore.Functions.DrawText3D(dest.coords.x, dest.coords.y, dest.coords.z + 0.2, "[E] Take a Trip")
                            end
                        end
                    end
                end
                Wait(sleep)
            end
        end)
    end
end)