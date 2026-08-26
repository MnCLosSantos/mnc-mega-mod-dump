-- mnc-jacks/server.lua
-- Session-only car jack + axle stand system
-- No database persistence

local QBCore = exports['qb-core']:GetCoreObject()

-- In-memory session state only
local liftState = {}                    -- [plate] = { left = {...}, right = {...} }
local pendingStandPlacement = {}        -- [src] = { plate, side, standIndex }
local propSpawners = {}                 -- [netId] = src

local function NormalisePlate(plate)
    return string.upper((plate or ''):gsub('%s+', ''))
end

local function GetLift(plate)
    plate = NormalisePlate(plate)
    if not liftState[plate] then
        liftState[plate] = {
            left = {
                stage = 0,
                stands = {},
                spawners = {},
                raised = false,
                raiseZ = 0.0
            },
            right = {
                stage = 0,
                stands = {},
                spawners = {},
                raised = false,
                raiseZ = 0.0
            }
        }
    end
    return liftState[plate]
end

local function Notify(src, title, description, ntype, duration)
    TriggerClientEvent('mnc-jacks:notify', src, {
        title = title or 'Car Jack',
        description = description,
        type = ntype or 'inform',
        duration = duration or 5000
    })
end

-- ====================== CALLBACKS ======================

lib.callback.register('mnc-jacks:canLiftSide', function(src, plate, side)
    plate = NormalisePlate(plate)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false, 'Player not found' end

    -- Check ownership (optional - remove if you don't want ownership check)
    -- local result = MySQL.query.await('SELECT citizenid FROM player_vehicles WHERE plate = ? AND citizenid = ?', 
    --     { plate, Player.PlayerData.citizenid })
    -- if not result or #result == 0 then
    --     return false, 'You do not own this vehicle'
    -- end

    if not Player.Functions.GetItemByName(Config.Lift.CarJackItem) then
        return false, 'You need a car jack to do this'
    end

    local lift = GetLift(plate)
    if lift[side].raised then
        return false, 'This side is already raised'
    end

    return true, 'ok'
end)

lib.callback.register('mnc-jacks:canLowerSide', function(src, plate, side)
    plate = NormalisePlate(plate)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false, 'Player not found' end

    if not Player.Functions.GetItemByName(Config.Lift.CarJackItem) then
        return false, 'You need a car jack'
    end

    local lift = GetLift(plate)
    if not lift[side].raised then
        return false, 'This side is not raised'
    end

    return true, 'ok'
end)

lib.callback.register('mnc-jacks:getLiftState', function(src, plate)
    plate = NormalisePlate(plate)
    local lift = GetLift(plate)
    return {
        left  = { stage = lift.left.stage,  raised = lift.left.raised,  raiseZ = lift.left.raiseZ },
        right = { stage = lift.right.stage, raised = lift.right.raised, raiseZ = lift.right.raiseZ }
    }
end)

lib.callback.register('mnc-jacks:getStandNetIds', function(src, plate, side)
    plate = NormalisePlate(plate)
    local lift = GetLift(plate)
    if not lift[side] or not lift[side].raised then return nil end
    return { lift[side].stands[1], lift[side].stands[2] }
end)

lib.callback.register('mnc-jacks:getStand1NetId', function(src, plate, side)
    plate = NormalisePlate(plate)
    local lift = GetLift(plate)
    return lift[side] and lift[side].stands[1] or nil
end)

-- ====================== ITEM USE ======================

QBCore.Functions.CreateUseableItem(Config.Lift.CarJackItem, function(src)
    TriggerClientEvent('mnc-jacks:useCarJack', src)
end)

QBCore.Functions.CreateUseableItem(Config.Lift.AxleStandItem, function(src)
    local pending = pendingStandPlacement[src]
    if not pending then
        Notify(src, 'Axle Stand', 'No active jack session. Use the car jack first.', 'error')
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Player.Functions.GetItemByName(Config.Lift.AxleStandItem) then
        Notify(src, 'Axle Stand', 'You need an axle stand.', 'error')
        return
    end

    -- Remove item
    Player.Functions.RemoveItem(Config.Lift.AxleStandItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Lift.AxleStandItem], 'remove')

    -- Let client handle placement
    TriggerClientEvent('mnc-jacks:client:activateStand', src)
end)

-- ====================== LIFT EVENTS ======================

RegisterNetEvent('mnc-jacks:startStandPlacement', function(plate, side)
    local src = source
    plate = NormalisePlate(plate)

    local lift = GetLift(plate)
    lift[side].stage = 1
    lift[side].spawners = lift[side].spawners or {}

    pendingStandPlacement[src] = { plate = plate, side = side, standIndex = 1 }
end)

RegisterNetEvent('mnc-jacks:standSpawned', function(plate, side, standIndex, objNetId, stand1NewNetId)
    local src = source
    plate = NormalisePlate(plate)

    local lift = GetLift(plate)

    -- Handle stand 1 replacement when placing stand 2
    if standIndex == 2 and stand1NewNetId and stand1NewNetId ~= 0 then
        local oldNetId1 = lift[side].stands[1]
        if oldNetId1 then propSpawners[oldNetId1] = nil end
        lift[side].stands[1] = stand1NewNetId
        lift[side].spawners[1] = src
        propSpawners[stand1NewNetId] = src
    end

    lift[side].stands[standIndex] = objNetId
    lift[side].spawners[standIndex] = src
    propSpawners[objNetId] = src

    if standIndex < Config.Lift.StandsPerSide then
        lift[side].stage = standIndex
        pendingStandPlacement[src] = { plate = plate, side = side, standIndex = standIndex + 1 }

        Notify(src, 'Axle Stand',
            ('Stand %d/%d placed. Use another axle_stand for the next one.'):format(standIndex, Config.Lift.StandsPerSide),
            'inform', 6000)
    else
        -- Both stands placed → side is now fully raised
        pendingStandPlacement[src] = nil
        lift[side].stage = 3
        lift[side].raised = true

        -- Broadcast to all clients
        TriggerClientEvent('mnc-jacks:raiseVehicle', -1, plate, side,
            lift[side].stands[1], lift[side].stands[2], lift[side].raiseZ or 0)

        Notify(src, 'Car Jack',
            side:sub(1,1):upper() .. side:sub(2) .. ' side secured on stands!',
            'success')
    end
end)

RegisterNetEvent('mnc-jacks:standSpawnFailed', function(plate, side, standIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddItem(Config.Lift.AxleStandItem, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Lift.AxleStandItem], 'add')
    end
    Notify(src, 'Axle Stand', 'Placement failed. Item refunded.', 'error')
end)

RegisterNetEvent('mnc-jacks:raiseDone', function(plate, side, raisedZ)
    plate = NormalisePlate(plate)
    local lift = GetLift(plate)
    if lift[side] then
        lift[side].raiseZ = raisedZ
    end
end)

RegisterNetEvent('mnc-jacks:lowerSide', function(plate, side)
    local src = source
    plate = NormalisePlate(plate)

    local lift = GetLift(plate)
    if not lift[side].raised then
        Notify(src, 'Car Jack', 'This side is not raised.', 'error')
        return
    end

    -- Return stands to player
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddItem(Config.Lift.AxleStandItem, Config.Lift.StandsPerSide)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.Lift.AxleStandItem], 'add')
    end

    -- Delete props (only for the original spawner)
    local spawners = lift[side].spawners or {}
    for i = 1, Config.Lift.StandsPerSide do
        local netId = lift[side].stands[i]
        local spawnerSrc = spawners[i] or propSpawners[netId]
        if netId and netId ~= 0 and spawnerSrc then
            TriggerClientEvent('mnc-jacks:deleteMyStandProps', spawnerSrc, netId, 0)
            propSpawners[netId] = nil
        end
    end

    -- Clear this side
    lift[side] = { stage = 0, stands = {}, spawners = {}, raised = false, raiseZ = 0.0 }

    -- Count remaining raised sides
    local otherSide = side == 'left' and 'right' or 'left'
    local sidesStillRaised = (lift[otherSide] and lift[otherSide].raised) and 1 or 0

    -- Broadcast lowering
    TriggerClientEvent('mnc-jacks:lowerVehicle', -1, plate, sidesStillRaised)

    local msg = side:sub(1,1):upper() .. side:sub(2) .. ' side lowered. Stands returned.'
    if sidesStillRaised > 0 then
        msg = msg .. ' Remove the other side to fully lower the vehicle.'
    end
    Notify(src, 'Car Jack', msg, 'success')
end)

RegisterNetEvent('mnc-jacks:standsRespawned', function(plate, side, netId1, netId2)
    local src = source
    plate = NormalisePlate(plate)
    local lift = GetLift(plate)
    if not lift[side] then return end

    lift[side].stands = { [1] = netId1, [2] = netId2 }
    lift[side].spawners = { [1] = src, [2] = src }
    propSpawners[netId1] = src
    propSpawners[netId2] = src
end)

-- ====================== CLEANUP ======================

RegisterNetEvent('mnc-jacks:cleanup', function(plate)
    plate = NormalisePlate(plate)
    if liftState[plate] then
        for _, side in ipairs({'left', 'right'}) do
            local s = liftState[plate][side]
            if s and s.raised then
                for i = 1, Config.Lift.StandsPerSide do
                    local netId = s.stands[i]
                    if netId and propSpawners[netId] then
                        TriggerClientEvent('mnc-jacks:deleteMyStandProps', propSpawners[netId], netId, 0)
                        propSpawners[netId] = nil
                    end
                end
            end
        end
        liftState[plate] = nil
    end
end)

-- Cleanup on vehicle recall from parking system
RegisterNetEvent('mnc-parking:vehicleRecalled', function(plate)
    TriggerClientEvent('mnc-jacks:cleanup', -1, plate)
end)

AddEventHandler('playerDropped', function()
    pendingStandPlacement[source] = nil
end)

if Config.Debug then
    print('^2[mnc-jacks]^7 server.lua loaded successfully.')
end