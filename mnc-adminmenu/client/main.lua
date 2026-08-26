local QBCore = exports['qb-core']:GetCoreObject()

local menuOpen = false

-- ─────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────
local function OpenMenu()
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

local function CloseMenu()
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ─────────────────────────────────────────────
--  Commands
-- ─────────────────────────────────────────────

-- /mncadmin — admin only (server checks permission before firing client event)
RegisterCommand('mncadmin', function()
    TriggerServerEvent('mnc-adminmenu:server:checkAdmin')
end, false)

-- /movegarage — all players
RegisterCommand('movegarage', function()
    TriggerServerEvent('mnc-adminmenu:server:openMoveGarage')
end, false)

-- ─────────────────────────────────────────────
--  Server → Client
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-adminmenu:client:open', function(payload)
    -- payload = { mode='admin'|'player', jobs={…}, garages={…} }
    SendNUIMessage({ action = 'setMode',    mode    = payload.mode    or 'admin' })
    SendNUIMessage({ action = 'setJobs',    jobs    = payload.jobs    or {} })
    SendNUIMessage({ action = 'setGarages', garages = payload.garages or {} })
    OpenMenu()
end)

RegisterNetEvent('mnc-adminmenu:client:playerJobs', function(citizenid, jobs)
    SendNUIMessage({ action = 'setPlayerJobs', citizenid = citizenid, jobs = jobs })
end)

RegisterNetEvent('mnc-adminmenu:client:playerMoney', function(citizenid, money)
    SendNUIMessage({ action = 'setPlayerMoney', citizenid = citizenid, money = money })
end)

RegisterNetEvent('mnc-adminmenu:client:playerVehicles', function(citizenid, vehicles)
    SendNUIMessage({ action = 'setPlayerVehicles', citizenid = citizenid, vehicles = vehicles })
end)

RegisterNetEvent('mnc-adminmenu:client:ownVehicles', function(vehicles)
    SendNUIMessage({ action = 'setOwnVehicles', vehicles = vehicles })
end)

RegisterNetEvent('mnc-adminmenu:client:playerInventory', function(citizenid, items)
    SendNUIMessage({ action = 'setPlayerInventory', citizenid = citizenid, items = items })
end)

RegisterNetEvent('mnc-adminmenu:client:syncMultijobUI', function(jobName)
    SendNUIMessage({ action = 'removejob', name = jobName })
end)

-- ─────────────────────────────────────────────
--  NUI Callbacks
-- ─────────────────────────────────────────────
RegisterNUICallback('close', function(_, cb)
    CloseMenu()
    cb('ok')
end)

RegisterNUICallback('setSelfJob', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:setSelfJob', data.job, tonumber(data.grade))
    cb('ok')
end)

RegisterNUICallback('lookupPlayer', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:lookupPlayer', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('removePlayerJob', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:removePlayerJob', data.citizenid, data.job)
    cb('ok')
end)

RegisterNUICallback('removeAllPlayerJobs', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:removeAllPlayerJobs', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('setPlayerJob', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:setPlayerJob', data.citizenid, data.job, tonumber(data.grade))
    cb('ok')
end)

-- Money
RegisterNUICallback('lookupMoney', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:lookupMoney', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('addMoney', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:addMoney', data.citizenid, data.moneytype, tonumber(data.amount))
    cb('ok')
end)

RegisterNUICallback('removeMoney', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:removeMoney', data.citizenid, data.moneytype, tonumber(data.amount))
    cb('ok')
end)

RegisterNUICallback('setMoney', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:setMoney', data.citizenid, data.moneytype, tonumber(data.amount))
    cb('ok')
end)

-- Vehicles (admin)
RegisterNUICallback('lookupVehicles', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:lookupVehicles', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('deleteVehicle', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:deleteVehicle', data.plate)
    cb('ok')
end)

RegisterNUICallback('setVehicleGarage', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:setVehicleGarage', data.plate, data.garage)
    cb('ok')
end)

-- Inventory (admin)
RegisterNUICallback('lookupInventory', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:lookupInventory', data.citizenid)
    cb('ok')
end)

-- Inventory item removal
RegisterNUICallback('removeInventoryItem', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:removeInventoryItem', data.citizenid, data.item, tonumber(data.amount) or 1)
    cb('ok')
end)

-- Player /movegarage
RegisterNUICallback('lookupOwnVehicles', function(_, cb)
    TriggerServerEvent('mnc-adminmenu:server:lookupOwnVehicles')
    cb('ok')
end)

RegisterNUICallback('playerMoveVehicle', function(data, cb)
    TriggerServerEvent('mnc-adminmenu:server:playerMoveVehicle', data.plate, data.garage)
    cb('ok')
end)

-- ─────────────────────────────────────────────
--  ESC to close
-- ─────────────────────────────────────────────
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if menuOpen and IsControlJustReleased(0, 200) then
            CloseMenu()
        end
    end
end)