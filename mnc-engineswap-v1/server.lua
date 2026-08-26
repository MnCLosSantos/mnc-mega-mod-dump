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

RegisterNetEvent('mnc-engineswap:saveEngine', function(plate, sound)
    MySQL.insert('INSERT INTO vehicle_engines (plate, engine_sound) VALUES (?, ?) ON DUPLICATE KEY UPDATE engine_sound = ?', { plate, sound, sound })
end)

QBCore.Functions.CreateCallback('mnc-engineswap:getEngine', function(source, cb, plate)
    MySQL.query('SELECT engine_sound FROM vehicle_engines WHERE plate = ?', { plate }, function(result)
        cb(result[1] and result[1].engine_sound or nil)
    end)
end)

print("^2[mnc-engineswap]^7 Script loaded successfully!")