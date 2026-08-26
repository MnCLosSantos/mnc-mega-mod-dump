local lib = exports.ox_lib
local QBCore = exports['qb-core']:GetCoreObject()
local uiOpen = false


-- Function to get unique values from QB-Core shared vehicles
local function GetVehicleDataLists()
    local vehicles = QBCore.Shared.Vehicles
    local brands, categories, shops = {}, {}, {}
    
    for _, vehicle in pairs(vehicles) do
        if vehicle.brand and vehicle.brand ~= "" then brands[vehicle.brand] = true end
        if vehicle.category then categories[vehicle.category] = true end
        if vehicle.shop then shops[vehicle.shop] = true end
    end
    
    local function toSortedList(tbl)
        local list = {}
        for k in pairs(tbl) do table.insert(list, k) end
        table.sort(list)
        return list
    end

    return {
        brands = toSortedList(brands),
        categories = toSortedList(categories),
        shops = toSortedList(shops),
        types = {"automobile", "bike", "boat", "heli", "plane", "train"}
    }
end

RegisterCommand('vehiclelua', function()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        exports.ox_lib:notify({
            title = 'No Vehicle',
            description = 'You must be in a vehicle to open the editor.',
            type = 'error'
        })
        return
    end

    local veh = GetVehiclePedIsIn(ped, false)
    local vehModel = GetEntityModel(veh)
    local model = GetDisplayNameFromVehicleModel(vehModel):lower()
    local name = GetLabelText(GetDisplayNameFromVehicleModel(vehModel))
    local brand = GetMakeNameFromVehicleModel(vehModel)
    local type = GetVehicleType(veh)
    local class = GetVehicleClass(veh)

    local classNames = {
        [0] = "compacts", [1] = "sedans", [2] = "suvs", [3] = "coupes",
        [4] = "muscle", [5] = "sportsclassics", [6] = "sports", [7] = "super",
        [8] = "motorcycles", [9] = "offroad", [10] = "industrial", [11] = "utility",
        [12] = "vans", [13] = "cycles", [14] = "boats", [15] = "helicopters",
        [16] = "planes", [17] = "service", [18] = "emergency", [19] = "military",
        [20] = "commercial", [21] = "trains"
    }

    local category = classNames[class] or "unknown"

    local data = {
        model = model,
        name = (name ~= "NULL" and name or model),
        brand = (brand ~= "" and brand or "Unknown"),
        price = 0,
        category = category,
        type = type,
        shop = 'pdm'
    }

    local lists = GetVehicleDataLists()

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = data,
        lists = lists
    })
    uiOpen = true
end, false)

-- NUI callbacks
RegisterNUICallback('saveVehicle', function(data, cb)
    TriggerServerEvent('mnc-vehiclelua:saveVehicle', data)
    SetNuiFocus(false, false)
    uiOpen = false
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    uiOpen = false
    cb('ok')
end)

RegisterNUICallback('escape', function(_, cb)
    SetNuiFocus(false, false)
    uiOpen = false
    cb('ok')
end)
