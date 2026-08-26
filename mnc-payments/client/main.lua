local QBCore = exports['qb-core']:GetCoreObject()
local isOpen = false

-- ─────────────────────────────────────────────
--  Open / close
-- ─────────────────────────────────────────────
local function OpenMenu()
    if isOpen then return end
    QBCore.Functions.TriggerCallback('mnc-payments:getMenuData', function(data)
        if not data then
            lib.notify({ type = 'error', description = 'Failed to load payment data.' })
            return
        end
        isOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', data = data })
    end)
end

local function CloseMenu()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ─────────────────────────────────────────────
--  NUI callbacks
-- ─────────────────────────────────────────────
RegisterNUICallback('close', function(_, cb)
    CloseMenu()
    cb({})
end)

RegisterNUICallback('getNearby', function(_, cb)
    QBCore.Functions.TriggerCallback('mnc-payments:getNearby', function(nearby)
        cb(nearby or {})
    end)
end)

RegisterNUICallback('sendInvoice', function(data, cb)
    TriggerServerEvent('mnc-payments:sendInvoice', data)
    cb({})
end)

RegisterNUICallback('respondInvoice', function(data, cb)
    TriggerServerEvent('mnc-payments:respondInvoice', data)
    cb({})
end)

-- ─────────────────────────────────────────────
--  Server → client events
-- ─────────────────────────────────────────────

-- Refresh menu data while open
RegisterNetEvent('mnc-payments:refreshMenu', function()
    if not isOpen then return end
    QBCore.Functions.TriggerCallback('mnc-payments:getMenuData', function(data)
        if data then
            SendNUIMessage({ action = 'refresh', data = data })
        end
    end)
end)

-- Pop a notification + refresh when a new invoice arrives
RegisterNetEvent('mnc-payments:receiveInvoice', function(invoice)
    lib.notify({
        type        = 'inform',
        title       = 'Invoice Received',
        description = invoice.from_name .. ' (' .. invoice.from_job_label .. ') — ' .. Config.CurrencyLabel .. invoice.amount .. '\n' .. invoice.reason,
        duration    = 8000,
    })
    if isOpen then
        QBCore.Functions.TriggerCallback('mnc-payments:getMenuData', function(data)
            if data then SendNUIMessage({ action = 'refresh', data = data }) end
        end)
    end
end)

-- ─────────────────────────────────────────────
--  Command + keybind (F10)
-- ─────────────────────────────────────────────
RegisterCommand(Config.Command, function()
    if isOpen then
        CloseMenu()
    else
        OpenMenu()
    end
end, false)

RegisterKeyMapping(Config.Command, 'Open Payment Menu', 'keyboard', Config.Keybind)

-- ─────────────────────────────────────────────
--  Item usage — billingtablet
-- ─────────────────────────────────────────────
if Config.Item then
    AddEventHandler('QBCore:Client:ItemBox', function(itemData, itemType)
        -- Unused but kept for compatibility
    end)

    RegisterNetEvent('mnc-payments:client:useItem', function()
        if isOpen then
            CloseMenu()
        else
            OpenMenu()
        end
    end)
end
