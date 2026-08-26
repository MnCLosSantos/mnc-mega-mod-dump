-- @mnc-engineswap/server.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Ensure ox_lib is ready (optional but keeps your original behavior)
CreateThread(function()
    while GetResourceState('ox_lib') ~= 'started' do
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Waiting for ox_lib to start...")
        end
        Wait(500)
    end
    if Config.Debug then
        print("^2[mnc-engineswap]^7 ox_lib is ready.")
    end
end)

-- Database table creation (safe & delayed until MySQL is ready)
CreateThread(function()
    while not MySQL do Wait(100) end
    MySQL.ready(function()
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS vehicle_engines (
                plate VARCHAR(8) NOT NULL,
                engine_sound VARCHAR(50) NOT NULL,
                PRIMARY KEY (plate)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]])
        if Config.Debug then
            print("^2[mnc-engineswap]^7 Database table 'vehicle_engines' checked/created.")
        end
    end)
end)

-- Server-side string trim helper
function string.trim(s)
    if not s then return "" end
    return s:match("^%s*(.-)%s*$")
end

-- =====================================================================
-- ENGINE PAYMENT SYSTEM
-- =====================================================================
RegisterNetEvent('mnc-engineswap:processPayment', function(price, engineData, targetPlayerId)
    local src = source
    local targetSrc = targetPlayerId or src -- Use targetPlayerId if provided, else fall back to src
    if Config.Debug then
        print("^2[mnc-engineswap]^7 Processing payment for player " .. targetSrc .. " (requested by " .. src .. ") with engineData: " .. json.encode(engineData) .. ", received price: " .. tostring(price))
    end
   
    if not engineData or not engineData.name or not engineData.sound or not engineData.price then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Invalid engine data received: " .. json.encode(engineData))
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Invalid engine data or price.',
            type = 'error'
        })
        return
    end

    -- Validate price matches config
    local validPrice = false
    local configPrice = nil
    for _, category in ipairs(Config.EngineSounds) do
        for _, engine in ipairs(category.engines) do
            if engine.sound == engineData.sound then
                configPrice = engine.price
                if engine.price == price then
                    validPrice = true
                    break
                end
            end
        end
        if validPrice then break end
    end

    if not validPrice then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Invalid price for engine: " .. (engineData.sound or "unknown") .. ", received price: " .. tostring(price) .. ", expected price: " .. tostring(configPrice or "not found"))
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Invalid engine price. Expected $' .. tostring(configPrice or "unknown") .. '.',
            type = 'error'
        })
        return
    end

    local Player = QBCore.Functions.GetPlayer(targetSrc)
    if not Player then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Player not found for source " .. targetSrc)
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Player with ID ' .. targetSrc .. ' not found.',
            type = 'error'
        })
        return
    end

    -- Check if player has sufficient funds
    local bankBalance = Player.PlayerData.money.bank or 0
    if bankBalance < price then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Payment failed for player " .. targetSrc .. ": insufficient funds. Required: $" .. price .. ", Available: $" .. bankBalance)
            print(("^3[mnc-engineswap]^7 Player %s failed to purchase engine - insufficient funds. Required: $%s, Available: $%s"):format(Player.PlayerData.name, price, bankBalance))
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Payment Failed',
            description = 'Player ' .. targetSrc .. ' needs $' .. price .. ' in their bank account. They have $' .. bankBalance .. '.',
            type = 'error'
        })
        return
    end

    if Player.Functions.RemoveMoney('bank', price, 'engine-swap') then
        if Config.Debug then
            print("^2[mnc-engineswap]^7 Payment successful for engine: " .. engineData.name .. ", triggering paymentApproved for player " .. src)
            print(("^2[mnc-engineswap]^7 Player %s purchased %s engine for $%s"):format(Player.PlayerData.name, engineData.name, price))
        end
        TriggerClientEvent('mnc-engineswap:paymentApproved', src, engineData) -- Notify the requesting player
        if targetSrc ~= src then
            TriggerClientEvent('ox_lib:notify', targetSrc, {
                title = 'Engine Purchase',
                description = 'You were charged $' .. price .. ' for a ' .. engineData.name .. ' engine swap by Player ' .. src .. '.',
                type = 'inform'
            })
        end
    else
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Payment failed for player " .. targetSrc .. ": unable to remove funds")
            print(("^3[mnc-engineswap]^7 Player %s failed to purchase engine - unable to remove funds"):format(Player.PlayerData.name))
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Payment Failed',
            description = 'Failed to process payment for Player ' .. targetSrc .. '. Please try again.',
            type = 'error'
        })
    end
end)

-- =====================================================================
-- ENGINE DELIVERY TRIGGER
-- =====================================================================
RegisterNetEvent('mnc-engineswap:spawnDelivery', function()
    local src = source
   
    if Config.Debug then
        print(("^2[mnc-engineswap]^7 Preparing delivery for player %s, waiting %s ms"):format(src, Config.EngineDeliveryTime))
    end
   
    -- Apply delivery delay
    Wait(Config.EngineDeliveryTime)
   
    if Config.Debug then
        print(("^2[mnc-engineswap]^7 Spawning delivery for player %s after delay"):format(src))
    end
   
    -- Client will use pendingShop.delivery, so no coordinates needed here
    TriggerClientEvent('mnc-engineswap:clientDeliveryReady', src, nil)
end)

local ADMIN_GROUP = 'admin' -- Change to match your server's admin group
 
local function IsAdmin(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    -- QBCore stores the permission group on the player data object
    local group = QBCore.Functions.GetPermission(src)
    return group == ADMIN_GROUP or group == 'god' or IsPlayerAceAllowed(src, 'command.adminengineswap')
end
 
-- =====================================================================
-- /adminengineswap COMMAND
-- Opens the engine selection menu on the calling admin's screen
-- =====================================================================
RegisterCommand('engineswap', function(src, args, rawCommand)
    if src == 0 then
        -- Console call — not applicable for a UI command
        print('[mnc-engineswap] /adminengineswap cannot be used from the server console.')
        return
    end
 
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Access Denied',
            description = 'You do not have permission to use this command.',
            type = 'error'
        })
        if Config.Debug then
            print(("^3[mnc-engineswap]^7 Player %s attempted /adminengineswap without permission."):format(src))
        end
        return
    end
 
    if Config.Debug then
        local Player = QBCore.Functions.GetPlayer(src)
        print(("^2[mnc-engineswap]^7 Admin %s (%s) opened the admin engine swap menu."):format(
            Player and Player.PlayerData.name or 'Unknown', src
        ))
    end
 
    TriggerClientEvent('mnc-engineswap:openAdminMenu', src)
end, false) -- false = not restricted by ace (we do our own check above)

-- =====================================================================
-- ENGINE REFUND SYSTEM
-- =====================================================================
RegisterNetEvent('mnc-engineswap:refundPayment', function(price, engineData, targetPlayerId)
    local src = source
    local targetSrc = targetPlayerId or src -- Use targetPlayerId if provided, else fall back to src
    if Config.Debug then
        print("^2[mnc-engineswap]^7 Processing refund for player " .. targetSrc .. " with engineData: " .. json.encode(engineData))
    end
   
    if not engineData or not engineData.name or not engineData.sound or not engineData.price then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Invalid engine data for refund: " .. json.encode(engineData))
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Invalid refund data.',
            type = 'error'
        })
        return
    end

    -- Validate price matches config
    local validPrice = false
    local configPrice = nil
    for _, category in ipairs(Config.EngineSounds) do
        for _, engine in ipairs(category.engines) do
            if engine.sound == engineData.sound then
                configPrice = engine.price
                if engine.price == price then
                    validPrice = true
                    break
                end
            end
        end
        if validPrice then break end
    end

    if not validPrice then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Invalid price for refund: " .. (engineData.sound or "unknown") .. ", received price: " .. tostring(price) .. ", expected price: " .. tostring(configPrice or "not found"))
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Invalid refund price. Expected $' .. tostring(configPrice or "unknown") .. '.',
            type = 'error'
        })
        return
    end

    local Player = QBCore.Functions.GetPlayer(targetSrc)
    if not Player then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Player not found for source " .. targetSrc .. " during refund")
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Player with ID ' .. targetSrc .. ' not found for refund.',
            type = 'error'
        })
        return
    end

    if Player.Functions.AddMoney('bank', price, 'engine-swap-refunded') then
        if Config.Debug then
            print(("^2[mnc-engineswap]^7 Player %s refunded $%s for failed %s engine installation"):format(Player.PlayerData.name, price, engineData.name))
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Refund Success',
            description = ('Refunded $%s to Player %s for failed %s engine installation.'):format(price, targetSrc, engineData.name),
            type = 'success'
        })
        if targetSrc ~= src then
            TriggerClientEvent('ox_lib:notify', targetSrc, {
                title = 'Refund Received',
                description = ('You were refunded $%s for a failed %s engine installation.'):format(price, engineData.name),
                type = 'success'
            })
        end
    else
        if Config.Debug then
            print("^3[mnc-engineswap]^7 Failed to refund player " .. targetSrc .. " for engine: " .. (engineData.name or "unknown"))
            print(("^3[mnc-engineswap]^7 Failed to refund player %s for engine %s"):format(Player.PlayerData.name, engineData.name))
        end
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Refund Failed',
            description = 'Failed to process refund for Player ' .. targetSrc .. '. Please contact an admin.',
            type = 'error'
        })
    end
end)

-- =====================================================================
-- ENGINE SAVE
-- =====================================================================
RegisterNetEvent('mnc-engineswap:saveEngine', function(plate, sound)
    local src = source
    if not plate or not sound or plate == "" then
        print("^1[mnc-engineswap]^7 saveEngine: Invalid data - Plate: " .. tostring(plate) .. " | Sound: " .. tostring(sound) .. " | Source: " .. src)
        return
    end

    plate = plate:match("^%s*(.-)%s*$")
    plate = string.upper(plate)

    print("^2[mnc-engineswap]^7 Attempting to save | Plate: " .. plate .. " | Sound: " .. sound .. " | Source: " .. src)

    local success = MySQL.insert.await('INSERT INTO vehicle_engines (plate, engine_sound) VALUES (?, ?) ON DUPLICATE KEY UPDATE engine_sound = ?', 
        { plate, sound, sound })

    if success then
        print("^2[mnc-engineswap]^7 Engine SAVED successfully | Plate: " .. plate .. " | Sound: " .. sound)
    else
        print("^1[mnc-engineswap]^7 Failed to save engine to DB")
    end
end)

-- =====================================================================
-- ENGINE SOUND BROADCAST
-- Tells every connected client to apply the new engine sound to the
-- vehicle identified by plate, so bystanders hear the change too.
-- =====================================================================
RegisterNetEvent('mnc-engineswap:broadcastEngineSound', function(plate, sound)
    local src = source
    if not plate or not sound or plate == "" or sound == "" then
        if Config.Debug then
            print("^3[mnc-engineswap]^7 broadcastEngineSound: invalid data from " .. src)
        end
        return
    end
    plate = string.upper(string.trim(plate))
    if Config.Debug then
        print(("^2[mnc-engineswap]^7 Broadcasting engine sound '%s' for plate '%s' (requested by %s)"):format(sound, plate, src))
    end
    -- Broadcast to ALL clients (including the installer — their ApplySavedEngine
    -- call already handled them locally, but a duplicate ForceVehicleEngineAudio
    -- is harmless and keeps the logic unified).
    TriggerClientEvent('mnc-engineswap:applyEngineSound', -1, plate, sound)
end)

QBCore.Functions.CreateCallback('mnc-engineswap:getEngine', function(source, cb, plate)
    MySQL.query('SELECT engine_sound FROM vehicle_engines WHERE plate = ?', { plate }, function(result)
        cb(result[1] and result[1].engine_sound or nil)
    end)
end)

-- =====================================================================
-- VEHICLE MODEL SOUND META SYSTEM
-- =====================================================================

-- Ensure the model sound meta table exists
CreateThread(function()
    while not MySQL do Wait(100) end
    MySQL.ready(function()
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS vehicle_model_sounds (
                model VARCHAR(64) NOT NULL,
                engine_sound VARCHAR(50) NOT NULL,
                PRIMARY KEY (model)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]])
        if Config.Debug then
            print("^2[mnc-engineswap]^7 Database table 'vehicle_model_sounds' checked/created.")
        end
    end)
end)

-- Save or update a model's default sound
RegisterNetEvent('mnc-engineswap:saveModelSound', function(model, sound)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access Denied', description = 'No permission.', type = 'error' })
        return
    end
    MySQL.insert(
        'INSERT INTO vehicle_model_sounds (model, engine_sound) VALUES (?, ?) ON DUPLICATE KEY UPDATE engine_sound = ?',
        { model, sound, sound }
    )
    if Config.Debug then
        print(("^2[mnc-engineswap]^7 Model sound saved: %s -> %s (by player %s)"):format(model, sound, src))
    end
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Model Sound Set',
        description = ('Default sound for model **%s** set to **%s**.'):format(model, sound),
        type = 'success'
    })
end)

-- Delete a model's default sound override
RegisterNetEvent('mnc-engineswap:deleteModelSound', function(model)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access Denied', description = 'No permission.', type = 'error' })
        return
    end
    MySQL.query('DELETE FROM vehicle_model_sounds WHERE model = ?', { model })
    if Config.Debug then
        print(("^2[mnc-engineswap]^7 Model sound removed for: %s (by player %s)"):format(model, src))
    end
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Model Sound Removed',
        description = ('Default sound override for **%s** has been cleared.'):format(model),
        type = 'inform'
    })
end)

-- Callback: get a model's default sound (used by client on vehicle enter)
QBCore.Functions.CreateCallback('mnc-engineswap:getModelSound', function(source, cb, model)
    MySQL.query('SELECT engine_sound FROM vehicle_model_sounds WHERE model = ?', { model }, function(result)
        cb(result[1] and result[1].engine_sound or nil)
    end)
end)

-- Callback: get all saved model sounds (used by admin menu to list/manage them)
QBCore.Functions.CreateCallback('mnc-engineswap:getAllModelSounds', function(source, cb)
    MySQL.query('SELECT model, engine_sound FROM vehicle_model_sounds ORDER BY model ASC', {}, function(result)
        cb(result or {})
    end)
end)

-- /vehsoundmeta command — opens the admin model-sound menu on the caller's client
RegisterCommand('vehsoundmeta', function(src, args, rawCommand)
    if src == 0 then
        print('[mnc-engineswap] /vehsoundmeta cannot be used from the server console.')
        return
    end

    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Access Denied',
            description = 'You do not have permission to use this command.',
            type = 'error'
        })
        if Config.Debug then
            print(("^3[mnc-engineswap]^7 Player %s attempted /vehsoundmeta without permission."):format(src))
        end
        return
    end

    if Config.Debug then
        local Player = QBCore.Functions.GetPlayer(src)
        print(("^2[mnc-engineswap]^7 Admin %s (%s) opened /vehsoundmeta."):format(
            Player and Player.PlayerData.name or 'Unknown', src
        ))
    end

    TriggerClientEvent('mnc-engineswap:openVehSoundMetaMenu', src)
end, false)

print("^2[mnc-engineswap]^7 Script loaded successfully!")