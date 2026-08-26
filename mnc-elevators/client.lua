local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}

local useOxMenu = Config.MenuType == "ox"
local useOxNotify = Config.NotifyType == "ox"
local useTarget = Config.UseQbTarget
local progressType = Config.ProgressType
local debugMode = Config.DebugMode -- Added debug mode

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
        lib.notify({ title = "Elevator", description = msg, type = type or 'info' })
    else
        QBCore.Functions.Notify(msg, type or 'primary')
    end
end

-- Sounds / Animation / Progress
local function PlayDingSound()
    if Config.PlayDingSound then
        PlaySoundFrontend(-1, Config.DingSound, "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end

local function PlayElevatorAnim()
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
        QBCore.Functions.Progressbar("elevator_move", Config.ProgressLabel, Config.ProgressTime, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableCombat = true,
        }, {}, {}, {}, function()
            callback()
        end)
    end
end

-- Access checks
local function HasJobAccess(floor)
    if not floor.jobs or #floor.jobs == 0 then return true end
    if not PlayerData.job then return false end
    for _, job in ipairs(floor.jobs) do
        if PlayerData.job.name == job then
            return true
        end
    end
    return false
end

local function HasItemAccess(floor)
    if not floor.items or #floor.items == 0 then return true end
    for _, item in ipairs(floor.items) do
        if exports['qb-inventory']:HasItem(item) then
            return true
        end
    end
    return false
end

local function CanAccessFloor(floor)
    local jobAccess = HasJobAccess(floor)
    local itemAccess = HasItemAccess(floor)
    if floor.jobs and #floor.jobs > 0 then
        if debugMode then
            print("[DEBUG] Checking access for floor:", floor.label, "JobAccess:", jobAccess, "ItemAccess:", itemAccess)
        end
        return jobAccess and itemAccess
    end
    if debugMode then
        print("[DEBUG] Checking access for floor:", floor.label, "ItemAccess:", itemAccess)
    end
    return itemAccess
end

-- Teleport
local function TeleportToFloor(floor)
    PlayElevatorAnim()
    ShowProgress(function()
        DoScreenFadeOut(500)
        Wait(500)
        -- Use arrivalCoords if available, otherwise fall back to coords
        local targetCoords = floor.arrivalCoords or floor.coords
        SetEntityCoords(PlayerPedId(), targetCoords.x, targetCoords.y, targetCoords.z)
        SetEntityHeading(PlayerPedId(), targetCoords.w)
        Wait(500)
        DoScreenFadeIn(500)
        PlayDingSound()
        Notify("You arrived at " .. floor.label, "success")
        if debugMode then
            print("[DEBUG] Teleported to floor:", floor.label, "Coords:", json.encode(targetCoords))
        end
    end)
end

-- Menu
local function OpenElevatorMenu(elevatorName)
    local elevator = Config.Elevators[elevatorName]
    if not elevator then
        if debugMode then
            print("[DEBUG] Elevator not found:", elevatorName)
        end
        return
    end

    if useOxMenu then
        local options = {}
        for _, floor in pairs(elevator) do
            if CanAccessFloor(floor) then
                options[#options + 1] = {
                    title = floor.label,
                    icon = 'fa-solid fa-elevator',
                    onSelect = function() TeleportToFloor(floor) end
                }
            else
                options[#options + 1] = {
                    title = floor.label .. " (Locked)",
                    icon = 'fa-solid fa-lock',
                    disabled = true,
                    onSelect = function()
                        local reason = ""
                        if floor.jobs and #floor.jobs > 0 and not HasJobAccess(floor) then
                            reason = "You do not have the required job."
                        elseif floor.items and #floor.items > 0 and not HasItemAccess(floor) then
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
            id = 'mnc_elevator_menu_' .. elevatorName,
            title = 'Elevator - ' .. elevatorName,
            options = options
        })
        lib.showContext('mnc_elevator_menu_' .. elevatorName)
    else
        local menu = {}
        for _, floor in pairs(elevator) do
            if CanAccessFloor(floor) then
                menu[#menu + 1] = {
                    header = floor.label,
                    txt = "Go to " .. floor.label,
                    params = { event = 'mnc-elevators:client:teleport', args = floor }
                }
            else
                menu[#menu + 1] = {
                    header = floor.label .. " (Locked)",
                    txt = "Access Denied",
                    params = {
                        event = 'mnc-elevators:client:notifyAccessDenied',
                        args = { jobs = floor.jobs, items = floor.items }
                    }
                }
            end
        end
        exports['qb-menu']:openMenu(menu)
    end
end

RegisterNetEvent('mnc-elevators:client:teleport', function(floor)
    TeleportToFloor(floor)
end)

RegisterNetEvent('mnc-elevators:client:notifyAccessDenied', function(data)
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

-- Add target zones or E-key prompt
CreateThread(function()
    Wait(1000)
    for name, floors in pairs(Config.Elevators) do
        for _, floor in pairs(floors) do
            local loc = vector3(floor.coords.x, floor.coords.y, floor.coords.z)
            if useTarget then
                exports['qb-target']:AddBoxZone("mnc_elevator_" .. name .. "_" .. floor.label, loc, 1.5, 1.5, {
                    name = "mnc_elevator_" .. name .. "_" .. floor.label,
                    heading = floor.coords.w,
                    debugPoly = debugMode, -- Show zones only in debug mode
                    minZ = floor.coords.z - 1.0,
                    maxZ = floor.coords.z + 2.0,
                }, {
                    options = {
                        {
                            icon = "fa-solid fa-elevator",
                            label = "Use Elevator",
                            action = function()
                                OpenElevatorMenu(name)
                            end,
                        },
                    },
                    distance = 2.0
                })
                if debugMode then
                    print("[DEBUG] Added target zone for elevator:", name, "Floor:", floor.label, "Coords:", json.encode(loc))
                end
            end
        end
    end

    if not useTarget then
        CreateThread(function()
            while true do
                local sleep = 1500
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)

                for name, floors in pairs(Config.Elevators) do
                    for _, floor in pairs(floors) do
                        local dist = #(pos - vector3(floor.coords.x, floor.coords.y, floor.coords.z))
                        if dist < 10.0 then
                            sleep = 0
                            if debugMode then
                                DrawMarker(2, floor.coords.x, floor.coords.y, floor.coords.z - 0.9, 0,0,0,0,0,0,0.3,0.3,0.3,255,255,255,155,false,true,2)
                            end
                            if IsControlJustReleased(0, 38) then
                                OpenElevatorMenu(name)
                            end

                            if useOxMenu then
                                lib.showTextUI("[E] Use Elevator")
                            else
                                QBCore.Functions.DrawText3D(floor.coords.x, floor.coords.y, floor.coords.z + 0.2, "[E] Use Elevator")
                            end
                        end
                    end
                end
                Wait(sleep)
            end
        end)
    end
end)