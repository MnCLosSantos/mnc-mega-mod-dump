local QBCore = exports['qb-core']:GetCoreObject()

-- Fetch vehicle models from qb-core shared
local function fetchVehicleModels()
    local vehicleModels = {}
    local categorizedVehicles = {}

    for model, data in pairs(QBShared.Vehicles) do
        local className = data.category or "Unknown"
        if not categorizedVehicles[className] then
            categorizedVehicles[className] = {}
        end
        table.insert(categorizedVehicles[className], {
            model = model, -- This is the spawncode
            name = data.name,
            price = data.price,
            category = className,
            brand = data.brand or "Unknown",
        })
    end

    SendNUIMessage({
        type = 'setVehicleModels',
        models = categorizedVehicles,
        uiStyle = Config.UIStyles[Config.UIStyle],
        title = "Vehicle Spawner"
    })
end

RegisterNUICallback("spawnVehicle", function(data, cb)
    local model = data.model
    local color = data.color
    local paintType = data.paintType
    local performance = data.performanceMods
    local randomVisual = data.randomVisualMods

    if not model then return end

    -- Load model
    local hash = joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local ped = PlayerPedId()

    -- If already in a vehicle, delete it
    if IsPedInAnyVehicle(ped, false) then
        local oldVeh = GetVehiclePedIsIn(ped, false)
        TaskLeaveVehicle(ped, oldVeh, 16)
        Wait(500) -- short delay to let ped exit
        DeleteVehicle(oldVeh)
    end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- Get ground Z coord to avoid spawning in air / underground
    local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 5.0, 0)
    if not foundGround then 
        groundZ = coords.z 
    end

    local vehicle = CreateVehicle(hash, coords.x, coords.y, groundZ + 0.5, heading, true, false)

    -- Make sure vehicle is placed properly on the ground
    SetVehicleOnGroundProperly(vehicle)

    -- Warp ped into new vehicle
    if Config.Warp then
        SetPedIntoVehicle(ped, vehicle, -1)
    end
	
    -- Apply basic vehicle settings
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleEngineOn(vehicle, true, true, false)

    -- Handle fuel systems based on config
    local fuelSystems = {
        ['legacy'] = function(veh) exports['LegacyFuel']:SetFuel(veh, 100.0) end,
        ['cdn'] = function(veh) exports['cdn-fuel']:SetFuel(veh, 100.0) end,
        ['ox'] = function(veh) Entity(veh).state.fuel = 100.0 end,
        ['standalone'] = function(veh) SetVehicleFuelLevel(veh, 100.0) end
    }

    -- Handle vehicle keys based on config
    if Config.Keys == 'qb' then
        TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(vehicle))
    elseif Config.Keys == 'qbx' then
        TriggerEvent("qb-vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(vehicle))
    elseif Config.Keys == 'standalone' then
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleEngineOn(vehicle, true, true, false)
    end

    -- Handle fuel systems based on config
    local fuelSystems = {
        ['legacy'] = function(veh) exports['LegacyFuel']:SetFuel(veh, 100.0) end,
        ['cdn'] = function(veh) exports['cdn-fuel']:SetFuel(veh, 100.0) end,
        ['ox'] = function(veh) Entity(veh).state.fuel = 100.0 end,
        ['standalone'] = function(veh) SetVehicleFuelLevel(veh, 100.0) end
    }

    if fuelSystems[Config.Fuel] then
        fuelSystems[Config.Fuel](vehicle)
    else
        print('No valid fuel system configured')
    end

    -- Apply color and paint type if chosen
    if color and paintType then
        local r, g, b = 255, 255, 255
        if color == "red" then r, g, b = 255, 0, 0
        elseif color == "blue" then r, g, b = 0, 0, 255
        elseif color == "green" then r, g, b = 0, 255, 0
        elseif color == "black" then r, g, b = 0, 0, 0
        elseif color == "white" then r, g, b = 255, 255, 255
        elseif color == "yellow" then r, g, b = 255, 255, 0
        elseif color == "orange" then r, g, b = 255, 165, 0
        elseif color == "purple" then r, g, b = 128, 0, 128
        elseif color == "pink" then r, g, b = 255, 105, 180
        elseif color == "gray" then r, g, b = 128, 128, 128
        end

        -- Apply paint type
        SetVehicleModKit(vehicle, 0)
        if paintType == "metallic" then
            SetVehicleMod(vehicle, 0, 0, false) -- Metallic paint
            ClearVehicleCustomPrimaryColour(vehicle)
            ClearVehicleCustomSecondaryColour(vehicle)
            SetVehicleColours(vehicle, 0, 0) -- Reset to default metallic
            SetVehicleCustomPrimaryColour(vehicle, r, g, b)
            SetVehicleCustomSecondaryColour(vehicle, r, g, b)
        elseif paintType == "classic" then
            SetVehicleMod(vehicle, 0, -1, false) -- Default classic paint
            ClearVehicleCustomPrimaryColour(vehicle)
            ClearVehicleCustomSecondaryColour(vehicle)
            SetVehicleColours(vehicle, 0, 0) -- Reset to default classic
            SetVehicleCustomPrimaryColour(vehicle, r, g, b)
            SetVehicleCustomSecondaryColour(vehicle, r, g, b)
        elseif paintType == "matte" then
            SetVehicleMod(vehicle, 0, 2, false) -- Matte paint
            ClearVehicleCustomPrimaryColour(vehicle)
            ClearVehicleCustomSecondaryColour(vehicle)
            SetVehicleColours(vehicle, 12, 12) -- Matte base
            SetVehicleCustomPrimaryColour(vehicle, r, g, b)
            SetVehicleCustomSecondaryColour(vehicle, r, g, b)
        elseif paintType == "pearlescent" then
            SetVehicleMod(vehicle, 0, 1, false) -- Pearlescent paint
            ClearVehicleCustomPrimaryColour(vehicle)
            ClearVehicleCustomSecondaryColour(vehicle)
            SetVehicleColours(vehicle, 4, 4) -- Pearlescent base
            SetVehicleCustomPrimaryColour(vehicle, r, g, b)
            SetVehicleCustomSecondaryColour(vehicle, r, g, b)
            SetVehicleExtraColours(vehicle, r, g, b)
        elseif paintType == "chrome" then
            SetVehicleMod(vehicle, 0, 3, false) -- Chrome paint
            ClearVehicleCustomPrimaryColour(vehicle)
            ClearVehicleCustomSecondaryColour(vehicle)
            SetVehicleColours(vehicle, 120, 120) -- Chrome base
            SetVehicleCustomPrimaryColour(vehicle, r, g, b)
            SetVehicleCustomSecondaryColour(vehicle, r, g, b)
        end
    end

    -- Performance mods (excluding armor)
    if performance then
        SetVehicleModKit(vehicle, 0)
        local performanceMods = {
            [11] = true, -- Engine
            [12] = true, -- Brakes
            [13] = true, -- Transmission
            [15] = true, -- Suspension
            [18] = true, -- Turbo
        }
        for modType = 0, 48 do
            if modType == 16 then
                -- Skip armor
                SetVehicleMod(vehicle, modType, -1, false) -- Reset armor to default
            elseif performanceMods[modType] then
                local max = GetNumVehicleMods(vehicle, modType)
                if max > 0 then
                    SetVehicleMod(vehicle, modType, max - 1, false)
                end
            end
        end
        if performanceMods[18] then
            ToggleVehicleMod(vehicle, 18, true) -- Turbo
        end
    end

    -- Random visual mods
    if randomVisual then
        SetVehicleModKit(vehicle, 0)
        for i = 0, 48 do
            if i ~= 16 and i ~= 11 and i ~= 12 and i ~= 13 and i ~= 15 and i ~= 18 then -- Skip armor and performance mods
                local max = GetNumVehicleMods(vehicle, i)
                if max > 0 then
                    SetVehicleMod(vehicle, i, math.random(-1, max - 1), false) -- Allow -1 to include stock option
                end
            end
        end
    end

    SetModelAsNoLongerNeeded(hash)

    cb("ok")
end)

-- Admin command to show all vehicles
RegisterNetEvent('mnc-vehiclespawner:openUI', function()
    SetNuiFocus(true, true)
    fetchVehicleModels()
    SendNUIMessage({
        action = "openUI",
        uiStyle = Config.UIStyles[Config.UIStyle],
        title = "Vehicle Spawner"
    })
end)

-- Close UI
RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    cb({ status = 'closed' })
end)