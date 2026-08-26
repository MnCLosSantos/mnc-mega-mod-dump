local QBCore = exports['qb-core']:GetCoreObject()


local jobs = {}

local Locations = {}
local locationsReady = false

local function EnsureSchema()
    local ok, err = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `mnc_cardelivery_locations` (
              `id` INT NOT NULL AUTO_INCREMENT,
              `label` VARCHAR(50) NOT NULL,
              `spawn_x` FLOAT NOT NULL,
              `spawn_y` FLOAT NOT NULL,
              `spawn_z` FLOAT NOT NULL,
              `spawn_w` FLOAT NOT NULL,
              `delivery_x` FLOAT NOT NULL,
              `delivery_y` FLOAT NOT NULL,
              `delivery_z` FLOAT NOT NULL,
              `radius` FLOAT NOT NULL DEFAULT 8.0,
              `time_limit` INT NOT NULL DEFAULT 300,
              `vehicles` VARCHAR(255) NOT NULL,
              `created_by` VARCHAR(64) DEFAULT NULL,
              `disabled` TINYINT(1) NOT NULL DEFAULT 0,
              `config_index` INT DEFAULT NULL,
              `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`id`),
              UNIQUE KEY `uniq_config_index` (`config_index`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]])
    end)
    if not ok then
        print('[mnc-cardelivery] Could not auto-create mnc_cardelivery_locations (missing CREATE privilege?). Run install.sql manually. Error: ' .. tostring(err))
    end

    -- Migration for installs from before route editing existed. Safe to run
    -- every start - errors (column/key already exists) are swallowed.
    pcall(function()
        MySQL.query.await('ALTER TABLE `mnc_cardelivery_locations` ADD COLUMN `config_index` INT DEFAULT NULL')
    end)
    pcall(function()
        MySQL.query.await('ALTER TABLE `mnc_cardelivery_locations` ADD UNIQUE KEY `uniq_config_index` (`config_index`)')
    end)

    return ok
end


local function IsDbTrue(v)
    return v == 1 or v == true
end

local function ParseVehiclesCsv(raw)
    local vehicles = {}
    for v in (raw or ''):gmatch('([^,]+)') do
        local trimmed = v:match('^%s*(.-)%s*$')
        if trimmed ~= '' then vehicles[#vehicles + 1] = trimmed end
    end
    return vehicles
end

local function BuildLocationsList()
    local list = {}

    local ok, rows = pcall(function()
        return MySQL.query.await('SELECT * FROM mnc_cardelivery_locations ORDER BY id ASC')
    end)
    if not ok or not rows then
        rows = {}
        print('[mnc-cardelivery] Could not load saved routes from SQL. Continuing with config.lua locations only.')
    end

    -- split into config.lua overrides/deletes (config_index set) and plain
    -- admin-added routes (config_index NULL)
    local overrides, sqlRoutes = {}, {}
    for _, row in ipairs(rows) do
        if row.config_index then
            overrides[row.config_index] = row
        else
            sqlRoutes[#sqlRoutes + 1] = row
        end
    end

    -- 1) config.lua defaults, positions 1..#Config.Locations - always given a
    -- slot (even if disabled) so every other index stays stable.
    for i, cfgLoc in ipairs(Config.Locations) do
        local override = overrides[i]
        if override and IsDbTrue(override.disabled) then
            list[i] = { disabled = true, configIndex = i, dbId = override.id, fromConfig = true }
        elseif override then
            local vehicles = ParseVehiclesCsv(override.vehicles)
            list[i] = {
                spawn = vector4(override.spawn_x, override.spawn_y, override.spawn_z, override.spawn_w),
                delivery = vector3(override.delivery_x, override.delivery_y, override.delivery_z),
                radius = override.radius,
                time = override.time_limit,
                vehicles = #vehicles > 0 and vehicles or cfgLoc.vehicles,
                label = override.label,
                configIndex = i,
                dbId = override.id,
                fromConfig = true,
            }
        else
            list[i] = {
                spawn = cfgLoc.spawn,
                delivery = cfgLoc.delivery,
                radius = cfgLoc.radius,
                time = cfgLoc.time,
                vehicles = cfgLoc.vehicles,
                label = cfgLoc.label,
                configIndex = i,
                fromConfig = true,
            }
        end
    end

    for _, row in ipairs(sqlRoutes) do
        if not IsDbTrue(row.disabled) then
            local vehicles = ParseVehiclesCsv(row.vehicles)
            if #vehicles > 0 then
                list[#list + 1] = {
                    spawn = vector4(row.spawn_x, row.spawn_y, row.spawn_z, row.spawn_w),
                    delivery = vector3(row.delivery_x, row.delivery_y, row.delivery_z),
                    radius = row.radius,
                    time = row.time_limit,
                    vehicles = vehicles,
                    label = row.label,
                    dbId = row.id,
                }
            end
        end
    end

    return list
end

CreateThread(function()
    EnsureSchema()
    Locations = BuildLocationsList()
    locationsReady = true
    TriggerClientEvent('mnc-cardelivery:client:setLocations', -1, Locations)
end)

RegisterNetEvent('mnc-cardelivery:server:requestLocations', function()
    local src = source
    if locationsReady then
        TriggerClientEvent('mnc-cardelivery:client:setLocations', src, Locations)
        return
    end
    CreateThread(function()
        while not locationsReady do Wait(100) end
        TriggerClientEvent('mnc-cardelivery:client:setLocations', src, Locations)
    end)
end)

local function GiveVehicleKeys(src, veh, plate)
    if Config.VehicleKeysSystem == 'qbx' then
        local ok = pcall(function()
            exports[Config.VehicleKeysResourceName]:GiveKeys(src, veh, false)
        end)
        if not ok then
            print(('[mnc-cardelivery] Failed to give keys via %s export, check Config.VehicleKeysSystem'):format(Config.VehicleKeysResourceName))
        end
    else
        -- legacy qbcore-framework/qb-vehiclekeys: temporary ownership without a persistent key item
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
    end
end

local function RemoveVehicleKeys(src, veh, plate)
    if Config.VehicleKeysSystem == 'qbx' then
        local ok = pcall(function()
            exports[Config.VehicleKeysResourceName]:RemoveKeys(src, veh)
        end)
        if not ok then
            print(('[mnc-cardelivery] Failed to remove keys via %s export, check Config.VehicleKeysSystem'):format(Config.VehicleKeysResourceName))
        end
    else
        -- legacy qbcore-framework/qb-vehiclekeys: if your fork uses a different event name
        -- for revoking ownership, change it here to match.
        TriggerClientEvent('vehiclekeys:client:RemoveOwner', src, plate)
    end
end


RegisterNetEvent('mnc-cardelivery:server:requestSpawn', function(locIndex)
    local src = source
    local loc = Locations[locIndex]
    if not loc or loc.disabled or jobs[locIndex] then return end

    -- claim the slot synchronously before any yield below so a second
    -- request (from this or another client) arriving in the same tick
    -- can never slip past this guard and spawn a duplicate.
    jobs[locIndex] = { spawning = true }

    local model = loc.vehicles[math.random(#loc.vehicles)]
    local modelHash = GetHashKey(model)

    local veh = CreateVehicleServerSetter(modelHash, 'automobile', loc.spawn.x, loc.spawn.y, loc.spawn.z, loc.spawn.w)

    local attempts = 0
    while not DoesEntityExist(veh) and attempts < 50 do
        Wait(50)
        attempts = attempts + 1
    end

    if not DoesEntityExist(veh) then
        jobs[locIndex] = nil
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    local plate = ('%s%01d%02d'):format(Config.Mods.PlatePrefix, locIndex % 10, math.random(10, 99))
    SetVehicleNumberPlateText(veh, plate)

    jobs[locIndex] = {
        entity = veh,
        netId = netId,
        plate = plate,
        model = model,
        claimedBy = nil,
        spawning = false,
    }

    TriggerClientEvent('mnc-cardelivery:client:vehicleSpawned', -1, locIndex, netId)
    TriggerClientEvent('mnc-cardelivery:client:applyMods', src, netId)
end)

RegisterNetEvent('mnc-cardelivery:server:requestDespawn', function(locIndex)
    local job = jobs[locIndex]
    if job and not job.claimedBy and job.entity and DoesEntityExist(job.entity) then
        DeleteEntity(job.entity)
        jobs[locIndex] = nil
        TriggerClientEvent('mnc-cardelivery:client:vehicleRemoved', -1, locIndex)
    end
end)

local function CleanupJob(locIndex, deleteVehicle)
    local job = jobs[locIndex]
    if deleteVehicle and job and job.entity and DoesEntityExist(job.entity) then
        DeleteEntity(job.entity)
    end
    jobs[locIndex] = nil
    TriggerClientEvent('mnc-cardelivery:client:vehicleRemoved', -1, locIndex)
end

-- ===================================================================
-- CLAIM (prevents two players getting keys to the same vehicle)
-- ===================================================================
QBCore.Functions.CreateCallback('mnc-cardelivery:server:claimJob', function(source, cb, locIndex)
    local job = jobs[locIndex]
    if not job or job.spawning or job.claimedBy then
        cb(false)
        return
    end
    job.claimedBy = source
    cb(true, job.plate)
end)

RegisterNetEvent('mnc-cardelivery:server:giveKeys', function(locIndex, netId)
    local src = source
    local job = jobs[locIndex]
    if not job or job.claimedBy ~= src then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(veh) then
        GiveVehicleKeys(src, veh, job.plate)
    end
end)

RegisterNetEvent('mnc-cardelivery:server:startDelivery', function(locIndex)
    local src = source
    local job = jobs[locIndex]
    if job and job.claimedBy == src then
        job.startTime = os.time()
    end
end)

RegisterNetEvent('mnc-cardelivery:server:removeKeys', function(locIndex, netId)
    local src = source
    local job = jobs[locIndex]
    if not job or job.claimedBy ~= src then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(veh) then
        RemoveVehicleKeys(src, veh, job.plate)
    end
end)

-- ===================================================================
-- PAYOUT
-- ===================================================================
local function CalculatePayout(vehicleValue, damagePercent, elapsedSeconds, timeLimit)
    local p = Config.Payout

    damagePercent = math.max(0, math.min(Config.MaxDamagePercent, damagePercent or 0))
    local damageFactor = 1 - ((damagePercent / Config.MaxDamagePercent) * p.DamagePenaltyWeight)

    local timeRatio = math.max(0, math.min(1, (elapsedSeconds or timeLimit) / timeLimit))
    local timeFactor = 1 - (timeRatio * p.TimeBonusWeight)

    local payoutPercent = p.BasePercent * damageFactor * timeFactor
    payoutPercent = math.max(p.MinPercent, math.min(p.MaxPercent, payoutPercent))

    return math.floor(vehicleValue * payoutPercent)
end

RegisterNetEvent('mnc-cardelivery:server:completeDelivery', function(locIndex, damagePercent, elapsed)
    local src = source
    local job = jobs[locIndex]
    if not job or job.claimedBy ~= src then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local loc = Locations[locIndex]
    local vehicleData = QBCore.Shared.Vehicles[job.model]
    local vehicleValue = (vehicleData and vehicleData.price) or Config.Payout.DefaultVehicleValue

    local payout = CalculatePayout(vehicleValue, damagePercent, elapsed, loc.time)
    Player.Functions.AddMoney(Config.PayoutAccount, payout, 'mnc-cardelivery-payout')

    TriggerClientEvent('mnc-cardelivery:client:deliveryResult', src, true, payout)
    -- success: the vehicle has served its purpose once it's locked and paid out,
    -- so delete it here and free the location up so a new job can spawn there.
    CleanupJob(locIndex, true)
end)

RegisterNetEvent('mnc-cardelivery:server:failDelivery', function(locIndex, _reason)
    local src = source
    local job = jobs[locIndex]
    if not job or job.claimedBy ~= src then return end

    TriggerClientEvent('mnc-cardelivery:client:deliveryResult', src, false, 0)
    CleanupJob(locIndex, true)
end)

-- release a job if the claiming player disconnects mid-delivery
AddEventHandler('playerDropped', function()
    local src = source
    for locIndex, job in pairs(jobs) do
        if job.claimedBy == src then
            CleanupJob(locIndex, true)
        end
    end
end)

-- ===================================================================
-- ADMIN: ROUTE BUILDER (/cardeliverysetup)
-- ===================================================================
RegisterCommand(Config.Admin.Command, function(source)
    local src = source
    if src == 0 then return end -- ignore console
    if not IsPlayerAceAllowed(src, Config.Admin.AcePermission) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access denied', description = 'You do not have permission to do this.', type = 'error' })
        return
    end
    TriggerClientEvent('mnc-cardelivery:client:openSetupUI', src)
end, false)

RegisterNetEvent('mnc-cardelivery:server:saveLocation', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Admin.AcePermission) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access denied', description = 'You do not have permission to do this.', type = 'error' })
        return
    end
    if type(data) ~= 'table' then return end

    local label = tostring(data.label or ''):sub(1, 50)
    local spawn, delivery = data.spawn, data.delivery
    local radius = tonumber(data.radius)
    local timeLimit = tonumber(data.timeLimit)

    local vehicles = ParseVehiclesCsv(tostring(data.vehicles or ''))
    for i, v in ipairs(vehicles) do vehicles[i] = v:lower() end

    local valid = label ~= '' and type(spawn) == 'table' and type(delivery) == 'table'
        and tonumber(spawn.x) and tonumber(spawn.y) and tonumber(spawn.z) and tonumber(spawn.w)
        and tonumber(delivery.x) and tonumber(delivery.y) and tonumber(delivery.z)
        and radius and radius > 0 and timeLimit and timeLimit > 0 and #vehicles > 0

    if not valid then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Invalid route', description = 'Fill in every field correctly (radius/time limit > 0, at least one vehicle).', type = 'error' })
        return
    end

    local sx, sy, sz, sw = tonumber(spawn.x), tonumber(spawn.y), tonumber(spawn.z), tonumber(spawn.w)
    local dx, dy, dz = tonumber(delivery.x), tonumber(delivery.y), tonumber(delivery.z)
    local vehiclesCsv = table.concat(vehicles, ',')
    local adminName = GetPlayerName(src) or 'unknown'

    local configIndex = tonumber(data.configIndex)
    local dbId = tonumber(data.dbId)

    -- editing (or first-time overriding) one of the config.lua routes
    if configIndex and Locations[configIndex] and Locations[configIndex].fromConfig then
        local loc = Locations[configIndex]

        if loc.dbId then
            MySQL.update.await(
                'UPDATE mnc_cardelivery_locations SET label = ?, spawn_x = ?, spawn_y = ?, spawn_z = ?, spawn_w = ?, delivery_x = ?, delivery_y = ?, delivery_z = ?, radius = ?, time_limit = ?, vehicles = ?, disabled = 0 WHERE id = ?',
                { label, sx, sy, sz, sw, dx, dy, dz, radius, timeLimit, vehiclesCsv, loc.dbId }
            )
        else
            local id = MySQL.insert.await(
                'INSERT INTO mnc_cardelivery_locations (label, spawn_x, spawn_y, spawn_z, spawn_w, delivery_x, delivery_y, delivery_z, radius, time_limit, vehicles, created_by, config_index) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                { label, sx, sy, sz, sw, dx, dy, dz, radius, timeLimit, vehiclesCsv, adminName, configIndex }
            )
            if not id then
                TriggerClientEvent('ox_lib:notify', src, { title = 'Save failed', description = 'Could not write the route to the database.', type = 'error' })
                return
            end
            loc.dbId = id
        end

        loc.spawn = vector4(sx, sy, sz, sw)
        loc.delivery = vector3(dx, dy, dz)
        loc.radius = radius
        loc.time = timeLimit
        loc.vehicles = vehicles
        loc.label = label
        loc.disabled = false

        TriggerClientEvent('mnc-cardelivery:client:setLocations', -1, Locations)
        TriggerClientEvent('ox_lib:notify', src, { title = 'Route updated', description = ('"%s" is now live for every player.'):format(label), type = 'success' })
        return
    end

    -- editing an existing admin-added route
    if dbId then
        local target = nil
        for _, loc in ipairs(Locations) do
            if loc.dbId == dbId and not loc.fromConfig then
                target = loc
                break
            end
        end

        if not target then
            TriggerClientEvent('ox_lib:notify', src, { title = 'Save failed', description = 'That route no longer exists.', type = 'error' })
            return
        end

        MySQL.update.await(
            'UPDATE mnc_cardelivery_locations SET label = ?, spawn_x = ?, spawn_y = ?, spawn_z = ?, spawn_w = ?, delivery_x = ?, delivery_y = ?, delivery_z = ?, radius = ?, time_limit = ?, vehicles = ?, disabled = 0 WHERE id = ?',
            { label, sx, sy, sz, sw, dx, dy, dz, radius, timeLimit, vehiclesCsv, dbId }
        )

        target.spawn = vector4(sx, sy, sz, sw)
        target.delivery = vector3(dx, dy, dz)
        target.radius = radius
        target.time = timeLimit
        target.vehicles = vehicles
        target.label = label
        target.disabled = false

        TriggerClientEvent('mnc-cardelivery:client:setLocations', -1, Locations)
        TriggerClientEvent('ox_lib:notify', src, { title = 'Route updated', description = ('"%s" is now live for every player.'):format(label), type = 'success' })
        return
    end

    -- brand new admin-added route
    local id = MySQL.insert.await(
        'INSERT INTO mnc_cardelivery_locations (label, spawn_x, spawn_y, spawn_z, spawn_w, delivery_x, delivery_y, delivery_z, radius, time_limit, vehicles, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { label, sx, sy, sz, sw, dx, dy, dz, radius, timeLimit, vehiclesCsv, adminName }
    )

    if not id then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Save failed', description = 'Could not write the route to the database.', type = 'error' })
        return
    end

    Locations[#Locations + 1] = {
        spawn = vector4(sx, sy, sz, sw),
        delivery = vector3(dx, dy, dz),
        radius = radius,
        time = timeLimit,
        vehicles = vehicles,
        label = label,
        dbId = id,
    }

    TriggerClientEvent('mnc-cardelivery:client:setLocations', -1, Locations)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Route saved', description = ('"%s" is now live for every player.'):format(label), type = 'success' })
end)

RegisterNetEvent('mnc-cardelivery:server:deleteLocation', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Admin.AcePermission) then return end
    if type(data) ~= 'table' then return end

    local configIndex = tonumber(data.configIndex)
    local dbId = tonumber(data.dbId)

    -- deleting one of the config.lua routes: we can't remove it from the
    -- Lua table, so persist a disabled override row instead.
    if configIndex and Locations[configIndex] and Locations[configIndex].fromConfig then
        local loc = Locations[configIndex]

        if loc.dbId then
            MySQL.update.await('UPDATE mnc_cardelivery_locations SET disabled = 1 WHERE id = ?', { loc.dbId })
        else
            local cfgLoc = Config.Locations[configIndex]
            local id = MySQL.insert.await(
                'INSERT INTO mnc_cardelivery_locations (label, spawn_x, spawn_y, spawn_z, spawn_w, delivery_x, delivery_y, delivery_z, radius, time_limit, vehicles, created_by, config_index, disabled) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)',
                {
                    loc.label or ('Config route ' .. configIndex),
                    cfgLoc.spawn.x, cfgLoc.spawn.y, cfgLoc.spawn.z, cfgLoc.spawn.w,
                    cfgLoc.delivery.x, cfgLoc.delivery.y, cfgLoc.delivery.z,
                    cfgLoc.radius, cfgLoc.time, table.concat(cfgLoc.vehicles, ','),
                    GetPlayerName(src) or 'unknown', configIndex,
                }
            )
            loc.dbId = id
        end

        loc.disabled = true
        TriggerClientEvent('mnc-cardelivery:client:setLocations', -1, Locations)
        TriggerClientEvent('ox_lib:notify', src, { title = 'Route removed', description = 'That route will no longer spawn new deliveries.', type = 'success' })
        return
    end

    if not dbId then return end

    for _, loc in ipairs(Locations) do
        if loc.dbId == dbId and not loc.fromConfig then
            loc.disabled = true
        end
    end

    MySQL.update.await('UPDATE mnc_cardelivery_locations SET disabled = 1 WHERE id = ?', { dbId })
    TriggerClientEvent('mnc-cardelivery:client:setLocations', -1, Locations)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Route removed', description = 'That route will no longer spawn new deliveries.', type = 'success' })
end)


local function DeleteTrackedJobVehicles()
    for locIndex, job in pairs(jobs) do
        if job.entity and DoesEntityExist(job.entity) then
            DeleteEntity(job.entity)
        end
    end
    jobs = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DeleteTrackedJobVehicles()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CreateThread(function()
        Wait(1000) -- let the vehicle pool populate after start

        -- requires OneSync (already a QBCore requirement) to see every vehicle server-side.
        local ok, vehicles = pcall(GetAllVehicles)
        if not ok or not vehicles then return end

        local prefix = Config.Mods.PlatePrefix
        local prefixLen = #prefix
        local removed = 0

        for _, veh in ipairs(vehicles) do
            if DoesEntityExist(veh) then
                local plate = GetVehicleNumberPlateText(veh)
                if plate and plate:sub(1, prefixLen) == prefix then
                    DeleteEntity(veh)
                    removed = removed + 1
                end
            end
        end

        if removed > 0 then
            print(('[mnc-cardelivery] Cleaned up %d leftover delivery vehicle(s) from before the restart.'):format(removed))
        end
    end)
end)