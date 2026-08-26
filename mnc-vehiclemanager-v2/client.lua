-- client.lua
local lib = exports.ox_lib
local QBCore = exports['qb-core']:GetCoreObject()
local uiOpen = false

local function SafeGetVehicleType(modelHash)
    if not modelHash or modelHash == 0 then return "automobile" end
    local success, vehicleType = pcall(GetVehicleType, modelHash)
    return success and vehicleType or "automobile"
end

-- ==============================================================
-- 1. COMPLETE GTA V BRAND MAP (ALL MANUFACTURERS)
-- ==============================================================
-- Keys:   raw string from GetMakeNameFromVehicleModel() (ALL CAPS, no spaces)
-- Values: correct display name (title case + proper umlauts)
local BrandMap = {
    -- Standard brands
    ["ALBANY"]          = "Albany",
    ["ANNIS"]           = "Annis",
    ["BENEFAC"]         = "Benefactor",
    ["BENEFACTOR"]      = "Benefactor",
    ["BRAVADO"]         = "Bravado",
    ["DECLASSE"]        = "Declasse",
    ["DEWBAUCHEE"]      = "Dewbauchee",
    ["DINKA"]           = "Dinka",
    ["EMPEROR"]         = "Emperor",
    ["GROTTI"]          = "Grotti",
    ["KARIN"]           = "Karin",
    ["LAMPADATI"]       = "Lampadati",
    ["MAIBATSU"]        = "Maibatsu",
    ["OBEY"]            = "Obey",
    ["OCELOT"]          = "Ocelot",
    ["PFISTER"]         = "Pfister",
    ["PEGASSI"]         = "Pegassi",
    ["PROGEN"]          = "Progen",
    ["VAPID"]           = "Vapid",
    ["VULCAR"]          = "Vulcar",
    ["WESTERN"]         = "Western",
    ["WESTERNMOTOR"]    = "Western Motorcycle Company",
    ["WESTERNMOTORCYCLE"]= "Western Motorcycle Company",

    -- Special / umlaut brands
    ["UBERMACH"]        = "Übermacht",
    ["UBERMACH2"]       = "Übermacht",
    ["SCHYSTER"]        = "Schyster",
    ["SCHAFTER"]        = "Schäfter",
    ["SCHAFTER2"]       = "Schäfter V12",
    ["SCHAFTER3"]       = "Schäfter LWB",
    ["SCHAFTER4"]       = "Schäfter LWB (armored)",
    ["SCHAFTER5"]       = "Schäfter V12 (armored)",
    ["SCHAFTER6"]       = "Schäfter LWB (armored)",

    -- Other known brands
    ["BOLINGBROKE"]     = "Bolingbroke",
    ["BUCKINGHAM"]      = "Buckingham",
    ["CANIS"]           = "Canis",
    ["CHEBUREK"]        = "Cheburek",
    ["COIL"]            = "Coil",
    ["ENUS"]            = "Enus",
    ["FATHOM"]          = "Fathom",
    ["HVY"]             = "HVY",
    ["IMPONTE"]         = "Imponte",
    ["JOBUILT"]         = "JoBuilt",
    ["LCC"]             = "LCC",
    ["MAMMOTH"]         = "Mammoth",
    ["MTL"]             = "MTL",
    ["NAGASAKI"]        = "Nagasaki",
    ["PRINCIPE"]        = "Principe",
    ["RUNE"]            = "Rune",
    ["SHITZU"]          = "Shitzu",
    ["SPEEDOPHILE"]     = "Speedophile",
    ["STANIER"]         = "Stanley",
    ["STANLEY"]         = "Stanley",
    ["TRUFFADE"]        = "Truffade",
    ["WEENY"]           = "Weeny",
    ["WILLARD"]         = "Willard",
    ["ZIRCONIUM"]       = "Zirconium",

    -- Emergency / Service
    ["BRUTE"]           = "Brute",
    ["DECLASSEPOLICE"]  = "Declasse Police",
    ["POLICE"]          = "Police",
    ["SHERIFF"]         = "Sheriff",
    ["FIRETRUK"]        = "Fire Truck",
    ["LIFEGUARD"]       = "Lifeguard",
    ["PARKRANGER"]      = "Park Ranger",

    -- Boats / Aircraft
    ["SEASHARK"]        = "Seashark",
    ["SPEEDER"]         = "Speeder",
    ["SUBMERSIBLE"]     = "Submersible",
    ["TORO"]            = "Toro",
    ["TUG"]             = "Tug",
    ["BUZZARD"]         = "Buzzard",
    ["FROGGER"]         = "Frogger",
    ["MAVERICK"]        = "Maverick",
    ["SUPERVOLITO"]     = "SuperVolito",
    ["VALKYRIE"]        = "Valkyrie",

    -- Misc / Unknown
    ["UNKNOWN"]         = "Unknown",
    ["NULL"]            = "Unknown",
    [""]                = "Unknown"
}

-- ==============================================================
-- 2. Format raw brand → proper display name
-- ==============================================================
local function FormatBrandName(raw)
    if not raw or raw == "" or raw == "NULL" then return "Unknown" end

    -- 1. Clean & uppercase for lookup
    local key = raw:upper():gsub("%s+", ""):gsub("[^%a]", "")

    -- 2. Use exact map entry if exists
    if BrandMap[key] then
        return BrandMap[key]
    end

    -- 3. Fallback: title-case conversion
    local clean = raw:gsub("[^%a]", ""):lower()
    return clean:gsub("(%l)(%w*)", function(first, rest)
        return first:upper() .. rest
    end)
end

-- ==============================================================
-- 3. Get all vehicle data (in + out of QB-Core)
-- ==============================================================
local function GetVehicleDataLists()
    local vehicles = QBCore.Shared.Vehicles or {}
    local brands, categories, shops = {}, {}, {}
    local vehicleList, unavailableVehicles = {}, {}

    local categoryTypeMap = {motorcycles="bike",boats="boat",helicopters="heli",planes="plane",trains="train"}

    -- Existing QB-Core vehicles
    for _, v in pairs(vehicles) do
        if v.brand and v.brand ~= "" then brands[v.brand] = true end
        if v.category then categories[v.category] = true end
        if v.shop then shops[v.shop] = true end
        table.insert(vehicleList, {
            model = v.model:lower(),
            name = v.name or v.model:lower():gsub("^%l", string.upper),
            brand = v.brand or "Unknown",
            price = v.price or 0,
            category = v.category or "unknown",
            type = v.type or "automobile",
            shop = v.shop or "luxury"
        })
    end

    -- Vehicles NOT in QB-Core
    local allModels = GetAllVehicleModels() or {}
    for _, model in ipairs(allModels) do
        local m = model:lower()
        local hash = GetHashKey(m)
        if hash ~= 0 and IsModelInCdimage(hash) and IsModelAVehicle(hash) then
            local found = false
            for _, v in pairs(vehicles) do
                if v.model and v.model:lower() == m then found = true; break end
            end
            if not found then
                local class = GetVehicleClassFromName(hash)
                local classNames = {
                    [0]="compacts",[1]="sedans",[2]="suvs",[3]="coupes",[4]="muscle",[5]="sportsclassics",
                    [6]="sports",[7]="super",[8]="motorcycles",[9]="offroad",[10]="industrial",[11]="utility",
                    [12]="vans",[13]="cycles",[14]="boats",[15]="helicopters",[16]="planes",[17]="service",
                    [18]="emergency",[19]="military",[20]="commercial",[21]="trains"
                }
                local cat = classNames[class] or "unknown"
                local vt = SafeGetVehicleType(hash)
                if vt == "automobile" or vt == "unknown" then
                    vt = categoryTypeMap[cat] or "automobile"
                end

                local rawBrand = GetMakeNameFromVehicleModel(hash)
                local brand = FormatBrandName(rawBrand)

                table.insert(unavailableVehicles, {
                    model = m,
                    name = m:gsub("^%l", string.upper),
                    brand = brand,
                    category = cat,
                    type = vt,
                    price = 0,
                    shop = "luxury"
                })
            end
        end
    end

    local function toSorted(tbl)
        local t = {}
        for k in pairs(tbl) do table.insert(t, k) end
        table.sort(t)
        return t
    end

    return {
        brands = toSorted(brands),
        categories = toSorted(categories),
        shops = toSorted(shops),
        types = {"automobile","bike","boat","heli","plane","train"},
        vehicles = vehicleList,
        unavailableVehicles = unavailableVehicles
    }
end

-- ==============================================================
-- 4. /vehiclelua command
-- ==============================================================
RegisterCommand('vehiclelua', function()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        exports.ox_lib:notify({title='No Vehicle', description='Enter a vehicle first', type='error'})
        return
    end
    local veh = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(veh) then
        exports.ox_lib:notify({title='Invalid Vehicle', description='Vehicle not valid', type='error'})
        return
    end

    local modelHash = GetEntityModel(veh)
    local model = GetDisplayNameFromVehicleModel(modelHash):lower()
    local name = GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
    local rawBrand = GetMakeNameFromVehicleModel(modelHash)
    local brand = FormatBrandName(rawBrand)
    local vt = SafeGetVehicleType(modelHash)
    local class = GetVehicleClass(veh)
    local classNames = {
        [0]="compacts",[1]="sedans",[2]="suvs",[3]="coupes",[4]="muscle",[5]="sportsclassics",
        [6]="sports",[7]="super",[8]="motorcycles",[9]="offroad",[10]="industrial",[11]="utility",
        [12]="vans",[13]="cycles",[14]="boats",[15]="helicopters",[16]="planes",[17]="service",
        [18]="emergency",[19]="military",[20]="commercial",[21]="trains"
    }
    local cat = classNames[class] or "unknown"

    local data = {
        model = model,
        name = (name ~= "NULL" and name) or model:gsub("^%l", string.upper),
        brand = brand,
        price = 0,
        category = cat,
        type = vt,
        shop = "luxury"
    }

    local lists = GetVehicleDataLists()
    SetNuiFocus(true, true)
    SendNUIMessage({action='open', data=data, lists=lists})
    uiOpen = true
end, false)

-- ==============================================================
-- 6. NUI Callbacks
-- ==============================================================
RegisterNUICallback('saveVehicle', function(data, cb)
    TriggerServerEvent('mnc-vehiclelua:saveVehicle', data)
    SetNuiFocus(false, false)
    uiOpen = false
    cb('ok')
end)

RegisterNUICallback('replaceVehicle', function(data, cb)
    TriggerServerEvent('mnc-vehiclelua:replaceVehicle', data.oldModel, data.newData)
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

RegisterNUICallback('exportChunk', function(data, cb)
    TriggerServerEvent('mnc-vehiclelua:exportChunk', data)
    cb({success = true})
end)