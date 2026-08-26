local QBCore = exports['qb-core']:GetCoreObject()
local isUIOpen = false

local function DebugPrint(message)
    if Config.Debug then
        print('[VEHICLE-TRANSFER] ' .. message)
    end
end

local function CloseUI()
    DebugPrint('CloseUI called - isUIOpen: ' .. tostring(isUIOpen))
    
    if not isUIOpen then
        DebugPrint('UI already closed, skipping')
        return
    end
    
    SetNuiFocus(false, false)
    isUIOpen = false
    
    SendNUIMessage({
        action = 'forceClose'
    })
    
    DebugPrint('NUI focus released and UI closed')
end

-- ESC key thread to force close UI
CreateThread(function()
    while true do
        if isUIOpen then
            DisableControlAction(0, 322, true)
            
            if IsControlJustPressed(0, 322) then
                DebugPrint('ESC key detected in Lua thread')
                CloseUI()
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Open seller UI
RegisterNetEvent('mnc-transfervehicle:client:openSellerUI', function(sellerData, buyerId, amount)
    if isUIOpen then
        CloseUI()
        Wait(100)
    end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = 'openSellerUI',
        sellerData = sellerData,
        buyerId = buyerId or '',
        amount = amount or ''
    })
    
    DebugPrint('Opened seller UI')
end)

-- Update buyer info in seller UI
RegisterNetEvent('mnc-transfervehicle:client:updateBuyerInfo', function(buyerInfo, amount)
    SendNUIMessage({
        action = 'updateBuyerInfo',
        buyerInfo = buyerInfo,
        amount = amount
    })
end)

-- Open buyer UI for approval
RegisterNetEvent('mnc-transfervehicle:client:openBuyerUI', function(transferData)
    if isUIOpen then
        CloseUI()
        Wait(100)
    end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = 'openBuyerUI',
        transferData = transferData
    })
    
    DebugPrint('Opened buyer UI')
end)

-- View completed document
RegisterNetEvent('mnc-transfervehicle:client:viewDocument', function(documentData)
    if isUIOpen then
        CloseUI()
        Wait(100)
    end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        action = 'viewDocument',
        documentData = documentData
    })
    
    DebugPrint('Viewing document')
end)

-- Show error in UI
RegisterNetEvent('mnc-transfervehicle:client:showError', function(title, message)
    SendNUIMessage({
        action = 'showError',
        title = title,
        message = message
    })
end)

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    DebugPrint('NUI close callback received')
    cb('ok')
    CloseUI()
end)

RegisterNUICallback('getBuyerInfo', function(data, cb)
    DebugPrint('Fetching buyer info')
    cb('ok')
    TriggerServerEvent('mnc-transfervehicle:server:getBuyerInfo', data.buyerId, data.sellerData, data.amount)
end)

RegisterNUICallback('sendToBuyer', function(data, cb)
    DebugPrint('Sending transfer to buyer')
    cb('ok')
    TriggerServerEvent('mnc-transfervehicle:server:sendToBuyer', data.transferData)
    CloseUI()
end)

RegisterNUICallback('acceptTransfer', function(data, cb)
    DebugPrint('Transfer accepted')
    cb('ok')
    TriggerServerEvent('mnc-transfervehicle:server:acceptTransfer', data.documentID, data.signature)
    CloseUI()
end)

RegisterNUICallback('denyTransfer', function(data, cb)
    DebugPrint('Transfer denied')
    cb('ok')
    TriggerServerEvent('mnc-transfervehicle:server:denyTransfer', data.documentID)
    CloseUI()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CloseUI()
    end
end)