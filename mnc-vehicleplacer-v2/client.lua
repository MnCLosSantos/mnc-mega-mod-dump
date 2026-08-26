-- ─────────────────────────────────────────────────────────────
--  MNC Vehicle Placer  ·  client.lua  ·  v3.2.0
-- ─────────────────────────────────────────────────────────────

local isUIOpen   = false
local placingKey = nil
local placingVeh = nil
local trackedVehicles = {}  -- [key] = vehicleNetId

-- ─── Vehicle configure / cleanup ─────────────────────────────

RegisterNetEvent('mnc-vehicleplacer:client:configureVehicle', function(vehicleNetId, key)
    -- Register for position tracking
    trackedVehicles[key] = vehicleNetId

    local timeout = GetGameTimer() + 15000
    local vehicle

    while GetGameTimer() < timeout do
        if NetworkDoesNetworkIdExist(vehicleNetId) then
            vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
            if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
                break
            end
        end
        Wait(100)
    end

    if vehicle and DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        FreezeEntityPosition(vehicle, true)
    end
end)

RegisterNetEvent('mnc-vehicleplacer:client:cleanupVehicle', function(key)
    trackedVehicles[key] = nil
end)

CreateThread(function()
    while true do
        Wait(1000)
        for key, netId in pairs(trackedVehicles) do
            if NetworkDoesNetworkIdExist(netId) then
                local veh = NetworkGetEntityFromNetworkId(netId)
                if DoesEntityExist(veh) then
                    local c = GetEntityCoords(veh)
                    TriggerServerEvent('mnc-vehicleplacer:server:reportVehiclePos', key, c.x, c.y, c.z)
                end
            else
                trackedVehicles[key] = nil
            end
        end
    end
end)

-- ─── Notify ───────────────────────────────────────────────────

RegisterNetEvent('mnc-vehicleplacer:client:notify', function(msg, notifType)
    if lib and lib.notify then
        lib.notify({ title = 'Vehicle Placer', description = msg, type = notifType or 'inform' })
    else
        local QBCore = exports['qb-core']:GetCoreObject()
        QBCore.Functions.Notify(msg, notifType or 'primary')
    end
end)

-- ─── Teleport ─────────────────────────────────────────────────

RegisterNetEvent('mnc-vehicleplacer:client:teleportTo', function(x, y, z)
    SetEntityCoords(PlayerPedId(), x, y, z + 1.0, false, false, false, true)
end)

-- ─── Open UI ──────────────────────────────────────────────────

RegisterNetEvent('mnc-vehicleplacer:client:openUI', function(placements)
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = 'open',
        placements = placements,
        imagePaths = Config.ImagePaths,
    })
end)

-- ─── Placement saved callback ─────────────────────────────────

RegisterNetEvent('mnc-vehicleplacer:client:placementSaved', function(id)
    TriggerServerEvent('mnc-vehicleplacer:server:openUI')
end)

-- ─── Placement position confirmed from server ─────────────────

RegisterNetEvent('mnc-vehicleplacer:client:placementPositionUpdated', function(key, x, y, z, heading)
    SendNUIMessage({
        action  = 'placementConfirmed',
        key     = key,
        x       = x, y = y, z = z,
        heading = heading,
    })
end)

-- ─── NUI Callbacks ───────────────────────────────────────────

RegisterNUICallback('close', function(data, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    if placingKey then
        local veh = placingVeh
        if veh and DoesEntityExist(veh) then
            FreezeEntityPosition(veh, true)
            SetEntityCollision(veh, true, true)
        end
        placingKey = nil
        placingVeh = nil
    end
    cb('ok')
end)

RegisterNUICallback('addPlacement', function(data, cb)
    TriggerServerEvent('mnc-vehicleplacer:server:addPlacement', data)
	Wait(10000)
    cb('ok')
end)

RegisterNUICallback('editPlacement', function(data, cb)
    TriggerServerEvent('mnc-vehicleplacer:server:editPlacement', data)
    cb('ok')
end)

RegisterNUICallback('deletePlacement', function(data, cb)
    TriggerServerEvent('mnc-vehicleplacer:server:deletePlacement', data.id)
    cb('ok')
end)

RegisterNUICallback('teleportTo', function(data, cb)
    TriggerServerEvent('mnc-vehicleplacer:server:teleportTo', data.x, data.y, data.z)
    cb('ok')
end)

RegisterNUICallback('useCurrentCoords', function(data, cb)
    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    cb({ x = coords.x, y = coords.y, z = coords.z, heading = heading })
end)

-- ─── Placement Mode: Enter ────────────────────────────────────

RegisterNUICallback('enterPlacementMode', function(data, cb)
    local key = data.key
    if not key then cb({ error = true }) return end
    TriggerServerEvent('mnc-vehicleplacer:server:getVehicleNetId', key)
    cb('ok')
end)

RegisterNetEvent('mnc-vehicleplacer:client:startPlacementMode', function(key, vehicleNetId)
    if not NetworkDoesNetworkIdExist(vehicleNetId) then
        TriggerEvent('mnc-vehicleplacer:client:notify', 'Vehicle not found nearby!', 'error')
        return
    end

    local veh = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(veh) then
        TriggerEvent('mnc-vehicleplacer:client:notify', 'Vehicle entity not found!', 'error')
        return
    end

    placingKey = key
    placingVeh = veh

    NetworkRequestControlOfEntity(veh)
    FreezeEntityPosition(veh, false)
    SetEntityCollision(veh, true, true)

    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, veh, -1)

    SetNuiFocus(false, false)

    if Config.Debug then
        print(('[mnc-vehicleplacer] Placement mode started: key=%s netId=%d'):format(key, vehicleNetId))
    end
end)

-- ─── Placement Mode: Cancel ───────────────────────────────────

RegisterNUICallback('cancelPlacementMode', function(data, cb)
    if placingVeh and DoesEntityExist(placingVeh) then
        local ped = PlayerPedId()
        TaskLeaveVehicle(ped, placingVeh, 0)
        Wait(400)
        FreezeEntityPosition(placingVeh, true)
    end
    placingKey = nil
    placingVeh = nil
    cb('ok')
end)

-- ─── Placement Mode: Confirm ──────────────────────────────────

RegisterNUICallback('confirmPlacement', function(data, cb)
    local key = data.key or placingKey
    local veh = placingVeh

    if not veh or not DoesEntityExist(veh) then
        cb({ error = true })
        return
    end

    local coords  = GetEntityCoords(veh)
    local heading = GetEntityHeading(veh)
    local ped     = PlayerPedId()

    TaskLeaveVehicle(ped, veh, 0)
    Wait(25000)

    FreezeEntityPosition(veh, true)
    SetEntityCollision(veh, true, true)

    SetEntityCoords(ped, coords.x, coords.y, coords.z + 11.5, false, false, false, true)
    SetEntityHeading(ped, heading + 90.0)

    SetNuiFocus(true, true)

    TriggerServerEvent('mnc-vehicleplacer:server:updatePlacementPosition', key, coords.x, coords.y, coords.z, heading)

    placingKey = nil
    placingVeh = nil

    cb({ x = coords.x, y = coords.y, z = coords.z, heading = heading })
end)

-- ─── /vehplacer command ───────────────────────────────────────

RegisterCommand('vehplacer', function()
    TriggerServerEvent('mnc-vehicleplacer:server:openUI')
end, false)

-- ─── ESC to close NUI ─────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen and IsControlJustReleased(0, 200) then
            if placingKey then
                if placingVeh and DoesEntityExist(placingVeh) then
                    local ped = PlayerPedId()
                    TaskLeaveVehicle(ped, placingVeh, 0)
                    Wait(400)
                    FreezeEntityPosition(placingVeh, true)
                end
                placingKey = nil
                placingVeh = nil
            end
            isUIOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'close' })
        end
    end
end)