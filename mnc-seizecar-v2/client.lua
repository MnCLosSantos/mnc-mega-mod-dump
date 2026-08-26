-- mnc-seizecar/client.lua

local isReady = false

-- Wait until player is fully in the game
Citizen.CreateThread(function()
    while true do
        if NetworkIsSessionStarted() and LocalPlayer.state then
            isReady = true
            print("^2[mnc-seizecar]^7 Client ready - dialogs enabled")
            break
        end
        Wait(500)
    end
end)

-- ==================== REMOVE SINGLE CAR ====================
RegisterNetEvent('mnc-seizecar:client:removecar', function()
    if not isReady then
        lib.notify({description = 'Still loading... Try again in a few seconds', type = 'error'})
        return
    end

    local input = lib.inputDialog('🗑️ Remove Vehicle', {
        {type = 'number', label = 'Player Server ID', required = true, min = 1},
        {type = 'input',  label = 'Vehicle Plate',    required = true}
    })

    if not input then return end

    local targetId = tonumber(input[1])
    local plate = input[2]:upper():gsub("%s+", "")

    if not targetId or not plate or plate == '' then
        lib.notify({description = 'Invalid input', type = 'error'})
        return
    end

    TriggerServerEvent('mnc-seizecar:server:removecar', targetId, plate)
end)

-- ==================== REMOVE ALL CARS FROM PLAYER ====================
RegisterNetEvent('mnc-seizecar:client:removeallcars', function()
    if not isReady then
        lib.notify({description = 'Still loading... Try again in a few seconds', type = 'error'})
        return
    end

    local input = lib.inputDialog('🗑️ Remove ALL Vehicles', {
        {type = 'number', label = 'Player Server ID', required = true, min = 1}
    })

    if not input then return end

    local targetId = tonumber(input[1])
    if not targetId then
        lib.notify({description = 'Invalid Player ID', type = 'error'})
        return
    end

    local alert = lib.alertDialog({
        header = '⚠️ DANGER ZONE',
        content = ('Delete **ALL** vehicles from player ID **%s**?\n\nThis action is irreversible!'):format(targetId),
        centered = true,
        cancel = true,
        labels = { confirm = 'YES, DELETE ALL', cancel = 'Cancel' }
    })

    if alert ~= 'confirm' then
        lib.notify({description = 'Cancelled', type = 'inform'})
        return
    end

    TriggerServerEvent('mnc-seizecar:server:removeallcars', targetId)
end)

-- ==================== SERVER WIDE WIPE ====================
RegisterNetEvent('mnc-seizecar:client:removeallcarsfromserver', function()
    if not isReady then
        lib.notify({description = 'Still loading... Try again in a few seconds', type = 'error'})
        return
    end

    local input = lib.inputDialog('🚨 FULL SERVER VEHICLE WIPE', {
        {type = 'input', label = 'Type DELETEALL to confirm', required = true},
        {type = 'checkbox', label = 'I understand this will delete EVERY vehicle on the server', required = true}
    })

    if not input or input[1] ~= 'DELETEALL' or not input[2] then
        lib.notify({description = 'Confirmation failed - cancelled', type = 'error'})
        return
    end

    TriggerServerEvent('mnc-seizecar:server:removeallcarsfromserver')
end)

-- ==================== SEIZECAR (Job Restricted) ====================
RegisterNetEvent('mnc-seizecar:client:seizecar', function()
    if not isReady then
        lib.notify({description = 'Still loading... Try again in a few seconds', type = 'error'})
        return
    end

    local input = lib.inputDialog('🚔 Seize Vehicle', {
        {type = 'number', label = 'Player Server ID', required = true, min = 1},
        {type = 'input',  label = 'Vehicle Plate',    required = true}
    })

    if not input then return end

    local targetId = tonumber(input[1])
    local plate = input[2]:upper():gsub("%s+", "")

    if not targetId or not plate or plate == '' then
        lib.notify({description = 'Invalid input', type = 'error'})
        return
    end

    TriggerServerEvent('mnc-seizecar:server:seizecar', targetId, plate)
end)