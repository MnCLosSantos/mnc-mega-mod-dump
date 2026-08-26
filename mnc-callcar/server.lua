local QBCore = exports['qb-core']:GetCoreObject()

-- Fetch vehicles stored in a garage (state != 0 means garaged in QBCore).
-- state = 0  → vehicle is currently OUT / spawned  (excluded)
-- state = 1  → stored in a garage                  (included)
-- state = 2  → impounded                           (included, player may still want it)
lib.callback.register('mnc-callcar:getPlayerVehicles', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end

    local citizenid = Player.PlayerData.citizenid

    -- Only return vehicles that are NOT currently out (state != 0)
    local vehicles = MySQL.query.await(
        'SELECT plate, vehicle, mods, garage, state, fuel, engine, body FROM player_vehicles WHERE citizenid = ? AND state != 0',
        { citizenid }
    )

    if not vehicles then return {} end

    local formatted = {}
    for _, v in ipairs(vehicles) do
        local modelName = v.vehicle
        local label     = (QBCore.Shared.Vehicles[modelName] and QBCore.Shared.Vehicles[modelName].name) or v.plate

        -- Condition: average of engine + body (each out of 1000, so /10 = percent)
        local enginePct = math.floor((v.engine or 1000) / 10)
        local bodyPct   = math.floor((v.body   or 1000) / 10)
        local avg       = (enginePct + bodyPct) / 2

        local conditionStr
        if avg >= 90 then
            conditionStr = 'Excellent'
        elseif avg >= 70 then
            conditionStr = 'Good'
        elseif avg >= 40 then
            conditionStr = 'Fair'
        else
            conditionStr = 'Poor'
        end

        -- Human-readable garage state label (for display only, we already filtered to garaged)
        local stateLabel = v.state == 2 and 'Impounded' or 'Garaged'

        formatted[#formatted + 1] = {
            plate        = v.plate,
            label        = label,
            model        = modelName,
            garage       = v.garage or 'Unknown',
            state        = v.state,
            stateLabel   = stateLabel,
            condition    = conditionStr,
            conditionAvg = avg,
            fuel         = v.fuel or 100,
            props        = v.mods or '{}',
        }
    end

    return formatted
end)

-- Mark vehicle as out (state = 0) so it cannot be called again while in use.
-- Returns false if the vehicle is already out (duplicate spawn guard).
lib.callback.register('mnc-callcar:markVehicleOut', function(source, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local citizenid = Player.PlayerData.citizenid

    -- Check current state first
    local rows = MySQL.query.await(
        'SELECT state FROM player_vehicles WHERE citizenid = ? AND plate = ?',
        { citizenid, plate }
    )

    if not rows or #rows == 0 then return false end
    if rows[1].state == 0 then
        -- Already out – block the duplicate spawn
        return false
    end

    MySQL.update.await(
        'UPDATE player_vehicles SET state = 0 WHERE citizenid = ? AND plate = ?',
        { citizenid, plate }
    )
    return true
end)

-- Restore vehicle to garaged state (used if delivery fails/times out)
RegisterNetEvent('mnc-callcar:releaseVehicle', function(plate, toState)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local state = toState or 1
    MySQL.update.await(
        'UPDATE player_vehicles SET state = ? WHERE citizenid = ? AND plate = ?',
        { state, citizenid, plate }
    )
end)

-- Calculate cost server-side and charge player
lib.callback.register('mnc-callcar:chargeFee', function(source, fee)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local cash = Player.PlayerData.money['cash'] or 0
    local bank = Player.PlayerData.money['bank'] or 0

    if cash >= fee then
        Player.Functions.RemoveMoney('cash', fee, 'callcar-fee')
        return true
    elseif bank >= fee then
        Player.Functions.RemoveMoney('bank', fee, 'callcar-fee')
        return true
    end

    return false
end)

-- Give keys to player (qb-vehiclekeys export)
RegisterNetEvent('mnc-callcar:giveKeys', function(plate)
    local src = source
    local ok  = pcall(function()
        exports['qb-vehiclekeys']:GiveKeys(src, plate)
    end)
    if not ok then
        -- Fallback: trigger client event directly
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
    end
end)