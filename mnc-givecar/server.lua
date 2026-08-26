-- mnc-givecar/server.lua
local QBCore = exports['qb-core']:GetCoreObject()

Config = {
    DefaultFuel = 100,
    DefaultEngineHealth = 1000,
    DefaultBodyHealth = 1000,
}

-- Detect installed garage system automatically
local function DetectGarageSystem()
    if GetResourceState('qb-garages') == 'started' then
        return 'qb-garages', 'pillboxgarage'
    elseif GetResourceState('cdn-garage') == 'started' then
        return 'cdn-garage', 'A'
    elseif GetResourceState('jg-advancedgarages') == 'started' then
        return 'jg-advancedgarages', 'pillboxgarage'
    else
        return 'unknown', 'pillboxgarage'
    end
end

local GarageSystem, DefaultGarage = DetectGarageSystem()
print(('[mnc-givecar] Detected garage system: %s (default: %s)'):format(GarageSystem, DefaultGarage))

-- Helper: Generate random 8-char plate
local function GeneratePlate()
    local charset = {}
    for i = 48, 57 do table.insert(charset, string.char(i)) end -- 0-9
    for i = 65, 90 do table.insert(charset, string.char(i)) end -- A-Z
    math.randomseed(GetGameTimer())
    local plate = ''
    for i = 1, 8 do plate = plate .. charset[math.random(1, #charset)] end
    return plate
end

-- Helper: Notify players with ox_lib
local function Notify(src, msg, type)
    if src and src > 0 then
        TriggerClientEvent('ox_lib:notify', src, { description = msg, type = type or 'inform' })
    else
        print(('[mnc-givecar] %s'):format(msg)) -- Log to console for Tebex/server
    end
end

-- Helper: Get citizenid by server ID, supporting offline players
local function GetCitizenIdByServerId(targetId)
    local Player = QBCore.Functions.GetPlayer(targetId)
    if Player then
        return Player.PlayerData.citizenid, Player.PlayerData.license
    end
    -- Query database for offline player
    local result = exports.oxmysql:executeSync("SELECT citizenid, license FROM players WHERE id = ?", { targetId })
    if result and result[1] then
        return result[1].citizenid, result[1].license
    end
    return nil, nil
end

-- Command: Give permanent vehicle (saves to DB)
QBCore.Commands.Add('givecar', 'Give player a car (Admin only, Tebex allowed)', {}, false, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    local model = args[2]

    if not targetId or not model then
        Notify(src, 'Usage: /givecar [id] [model]', 'error')
        return
    end

    -- Permission check (Admins only, but bypass for Tebex/Console)
    if src ~= 0 then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player or not QBCore.Functions.HasPermission(src, 'admin') and not QBCore.Functions.HasPermission(src, 'god') and not IsPlayerAceAllowed(src, 'command') then
            Notify(src, 'You do not have permission to use this command.', 'error')
            return
        end
    end

    local cid, license = GetCitizenIdByServerId(targetId)
    if not cid or not license then
        Notify(src, 'Invalid player ID or player not found', 'error')
        return
    end

    local plate = GeneratePlate()
    local garage = DefaultGarage
    local commandSource = (src == 0) and "Tebex" or "Admin"

    -- Check for mileage column (auto-detect schema)
    local hasMileage = exports.oxmysql:scalarSync("SHOW COLUMNS FROM player_vehicles LIKE 'mileage'")

    local query, params
    if hasMileage then
        query = [[
            INSERT INTO player_vehicles
            (license, citizenid, vehicle, hash, mods, plate, state, depotprice, fuel, engine, body, garage, mileage)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]]
        params = {
            license,
            cid,
            model,
            GetHashKey(model),
            '{}',
            plate,
            1,
            0,
            Config.DefaultFuel,
            Config.DefaultEngineHealth,
            Config.DefaultBodyHealth,
            garage,
            0
        }
    else
        query = [[
            INSERT INTO player_vehicles
            (license, citizenid, vehicle, hash, mods, plate, state, depotprice, fuel, engine, body, garage)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]]
        params = {
            license,
            cid,
            model,
            GetHashKey(model),
            '{}',
            plate,
            1,
            0,
            Config.DefaultFuel,
            Config.DefaultEngineHealth,
            Config.DefaultBodyHealth,
            garage
        }
    end

    local success = exports.oxmysql:insertSync(query, params)
    if success then
        Notify(src, ('Vehicle %s given to player ID %s'):format(model, targetId), 'success')

        local Target = QBCore.Functions.GetPlayer(targetId)
        if Target then
            TriggerClientEvent('ox_lib:notify', targetId, {
                description = ('You received a %s (plate %s) from %s in garage: %s'):format(model, plate, commandSource, garage),
                type = 'success',
                duration = 120000
            })
        end
    else
        Notify(src, 'Failed to insert vehicle into database', 'error')
        print(('[mnc-givecar] Failed to insert vehicle for player ID %s, model %s'):format(targetId, model))
    end
end, false)

print("^2[mnc-givecar]^7 Script loaded successfully!")
