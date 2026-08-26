local QBCore = exports['qb-core']:GetCoreObject()
local isScratchOpen = false

local function Debug(msg)
    if Config.Debug then
        print('[mnc-scratchcards] ' .. msg)
    end
end

-- NUI Helpers
local function OpenScratchUI()
    isScratchOpen = true
    SetNuiFocus(true, true)
end

local function CloseScratchUI()
    isScratchOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeScratch' })
end

-- Server confirmed → show UI
RegisterNetEvent('mnc-scratchcards:client:showScratch', function(itemName, scratchData)
    if isScratchOpen then return end

    local cfg = Config.ScratchItems[itemName]
    if not cfg then 
        Debug('No config found for item: ' .. tostring(itemName))
        return 
    end

    OpenScratchUI()
    SendNUIMessage({
        type        = 'openScratch',
        itemName    = itemName,
        label       = cfg.label,
        scratchData = scratchData,  -- { won = amount }
        config      = {
            gridSize     = cfg.gridSize,
            scratchColor = cfg.scratchColor,
            background   = cfg.background,
            accent       = cfg.accent,
            revealType   = cfg.revealType,
        }
    })
end)

-- Reward feedback
RegisterNetEvent('mnc-scratchcards:client:giveReward', function(amount)
    if amount and amount > 0 then
        lib.notify({
            title       = 'Scratch Card',
            description = 'You won $' .. amount .. '!',
            type        = 'success',
            duration    = 5500
        })
    else
        lib.notify({
            title       = 'Scratch Card',
            description = 'No win this time...',
            type        = 'error'
        })
    end
end)

-- NUI Callbacks
RegisterNUICallback('closeUI', function(_, cb)
    CloseScratchUI()
    cb('ok')
end)

RegisterNUICallback('scratchFinished', function(data, cb)
    TriggerServerEvent('mnc-scratchcards:server:claimReward', data.itemName, data.won or 0)
    cb('ok')
end)

-- ESC to close
CreateThread(function()
    while true do
        Wait(0)
        if isScratchOpen and IsControlJustPressed(0, 200) then
            CloseScratchUI()
        end
    end
end)

-- Resource cleanup
AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() == res and isScratchOpen then
        SetNuiFocus(false, false)
        isScratchOpen = false
    end
end)

Debug('Client loaded successfully')