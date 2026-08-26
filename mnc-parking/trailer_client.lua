local QBCore = nil

CreateThread(function()
    while not QBCore do
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbcore') == 'started' then
            local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and obj then QBCore = obj end
        end
        Wait(500)
    end
end)

local function Notify(title, description, ntype, duration)
    lib.notify({
        title       = title or 'Parking',
        description = description,
        type        = ntype   or 'inform',
        duration    = duration or 5000,
    })
end

local function NormalisePlate(plate)
    return string.upper((plate or ''):gsub('%s+', ''))
end

local function GetNoParkZone(pos)
    for _, zone in ipairs(Config.NoParkZones or {}) do
        if #(vector3(pos.x, pos.y, pos.z) - zone.coords) <= zone.radius then
            return zone.label or 'this area'
        end
    end
    return nil
end

local function GetVehicleProps(vehicle)
    local props = QBCore.Functions.GetVehicleProperties(vehicle)
    local doorStates = {}
    for i = 0, 5 do
        local angle = GetVehicleDoorAngleRatio(vehicle, i)
        doorStates[tostring(i)] = angle > 0.1 and angle or 0.0
    end
    props._doorStates = doorStates
    return props
end


local function GetNearbyUnseatableVehicles(maxDist)
    local ped        = PlayerPedId()
    local pedPos      = GetEntityCoords(ped)
    local pedVehicle  = GetVehiclePedIsIn(ped, false)
    local found       = {}

    for _, v in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(v) and v ~= pedVehicle then
            local d = #(pedPos - GetEntityCoords(v))
            if d <= maxDist then
                local seats = GetVehicleModelNumberOfSeats(GetEntityModel(v))
                if seats <= 0 then
                    found[#found + 1] = v
                end
            end
        end
    end
    return found
end


local function ConfirmAndParkVehicle(vehicle, plate, modelName)
    if not DoesEntityExist(vehicle) then return end

    local vehCoords = GetEntityCoords(vehicle)

    local zoneName = GetNoParkZone(vehCoords)
    if zoneName then
        Notify('Parking', ('You cannot park here — %s is a restricted area.'):format(zoneName), 'error')
        return
    end

    local heading = GetEntityHeading(vehicle)
    local props   = GetVehicleProps(vehicle)
    local fuel    = math.max(0.0, math.min(100.0, GetVehicleFuelLevel(vehicle)))
    local engine  = GetVehicleEngineHealth(vehicle)
    local body    = GetVehicleBodyHealth(vehicle)

    local confirmed = lib.alertDialog({
        header  = 'Park Vehicle',
        content =
            'Park **' .. plate .. '** (' .. modelName .. ') here?\n\n' ..
            '**Fuel:** ' .. math.floor(fuel) .. '%  |  ' ..
            '**Engine:** ' .. math.floor(engine / 10) .. '%  |  ' ..
            '**Body:** ' .. math.floor(body / 10) .. '%\n\n' ..
            'Are you sure you want to park it here?',
        centered = true,
        cancel   = true,
    })
    if confirmed ~= 'confirm' then return end

    local entityNetId = NetworkGetNetworkIdFromEntity(vehicle)

    local ok, msg, maxSlots = lib.callback.await('mnc-parking:parkVehicle',
        false,
        plate, modelName,
        { x = vehCoords.x, y = vehCoords.y, z = vehCoords.z },
        heading, json.encode(props), fuel, engine, body,
        entityNetId)

    if not ok then
        Notify('Parking', msg, 'error')
        return
    end

    -- Hand off to client.lua's shared tracking (parkedVehicles/ownPlates/
    -- syncTimers/moveWatchers/blipHandles) so this trailer gets the exact
    -- same despawn/respawn-aware sync timer and move watcher as any
    -- normally parked vehicle. See RegisterStandParkedVehicle in
    -- client.lua for why this matters: previously this file kept its own
    -- separate, one-shot watcher that never got re-armed after the
    -- server's proximity system despawned + respawned the trailer, so a
    -- towed trailer could vanish with no "moved" notify and the parked
    -- slot would never clear.
    RegisterStandParkedVehicle(vehicle, plate, {
        plate   = plate,
        model   = modelName,
        coords  = { x = vehCoords.x, y = vehCoords.y, z = vehCoords.z },
        heading = heading,
        props   = json.encode(props),
        fuel    = fuel,
        engine  = engine,
        body    = body,
    })
    TriggerServerEvent('mnc-parking:giveKeys', plate)

    -- Lock, same as the normal /park flow
    CreateThread(function()
        Wait(600)
        if not DoesEntityExist(vehicle) then return end
        SetVehicleDoorsLocked(vehicle, 2)
        TriggerServerEvent('mnc-parking:lockParkedVehicle', plate, entityNetId)
    end)

    Notify('Parking', 'Vehicle parked in place!', 'success')
end


function ParkNearbyUnseatableVehicle()
    if not (Config.TrailerPark and Config.TrailerPark.Enabled) then
        Notify('Parking', 'You must be inside a vehicle to park it.', 'error')
        return
    end
    if not QBCore then
        Notify('Parking', 'Parking system is still loading, try again in a moment.', 'error')
        return
    end

    local maxDist = Config.TrailerPark.InteractDistance or 10.0
    local nearby  = GetNearbyUnseatableVehicles(maxDist)

    if #nearby == 0 then
        Notify('Parking', 'No nearby vehicle to stand-park. Get closer to it.', 'error')
        return
    end

    -- Filter out anything already in the player's parked list
    local ownList, _ = lib.callback.await('mnc-parking:getParkedVehicles', false)
    local alreadyOwn = {}
    for _, data in ipairs(ownList or {}) do
        alreadyOwn[NormalisePlate(data.plate)] = true
    end

    local options = {}
    for _, v in ipairs(nearby) do
        local plate = NormalisePlate(GetVehicleNumberPlateText(v))
        if not alreadyOwn[plate] then
            local hash      = GetEntityModel(v)
            local modelName = ''
            for name in pairs(QBCore.Shared.Vehicles or {}) do
                if GetHashKey(name) == hash then modelName = name; break end
            end
            if modelName == '' then
                modelName = string.lower(GetDisplayNameFromVehicleModel(hash))
            end
            local label = (QBCore.Shared.Vehicles
                            and QBCore.Shared.Vehicles[modelName]
                            and QBCore.Shared.Vehicles[modelName].name)
                           or modelName

            local capturedVehicle = v
            local capturedPlate   = plate
            local capturedModel   = modelName

            options[#options + 1] = {
                title       = label .. ' — ' .. plate,
                description = 'Park this vehicle where it stands.',
                icon        = 'car',
                onSelect    = function()
                    ConfirmAndParkVehicle(capturedVehicle, capturedPlate, capturedModel)
                end,
            }
        end
    end

    if #options == 0 then
        Notify('Parking', 'All nearby vehicles are already parked.', 'inform')
        return
    end

    lib.registerContext({
        id      = 'mnc_trailer_park_menu',
        title   = 'Park Nearby Vehicle',
        options = options,
    })
    lib.showContext('mnc_trailer_park_menu')
end


if Config.Debug then print('^2[mnc-parking]^7 trailer_client.lua loaded.') end