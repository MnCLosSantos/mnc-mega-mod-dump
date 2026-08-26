-- server/main.lua
local QBCore = exports['qb-core']:GetCoreObject()
local ActiveVehicles = {}

-- ─────────────────────────────────────────────────────────────────────────────
--  DB bootstrap  (runs once on resource start)
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mnc_job_garages` (
            `id`          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `job`         VARCHAR(64)   NOT NULL,
            `label`       VARCHAR(128)  NOT NULL DEFAULT '',
            `spawn_x`     FLOAT         NOT NULL DEFAULT 0,
            `spawn_y`     FLOAT         NOT NULL DEFAULT 0,
            `spawn_z`     FLOAT         NOT NULL DEFAULT 0,
            `spawn_w`     FLOAT         NOT NULL DEFAULT 0,
            `out_x`       FLOAT         NOT NULL DEFAULT 0,
            `out_y`       FLOAT         NOT NULL DEFAULT 0,
            `out_z`       FLOAT         NOT NULL DEFAULT 0,
            `out_w`       FLOAT         NOT NULL DEFAULT 0,
            `zone_enable` TINYINT(1)    NOT NULL DEFAULT 1,
            `is_config`   TINYINT(1)    NOT NULL DEFAULT 0,
            `updated_at`  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_garage_job` (`job`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    -- Add real_job column so multi-garage entries (e.g. garageId="ambulance_2")
    -- can store the actual QBCore job name ("ambulance") for target visibility.
    -- Existing rows default to '' and fall back to the job column at runtime.
    MySQL.query.await([[
        ALTER TABLE `mnc_job_garages`
        ADD COLUMN IF NOT EXISTS `real_job` VARCHAR(64) NOT NULL DEFAULT ''
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mnc_garage_vehicles` (
            `id`            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `job`           VARCHAR(64)   NOT NULL,
            `model`         VARCHAR(64)   NOT NULL,
            `custom_name`   VARCHAR(128)  NOT NULL DEFAULT '',
            `min_grade`     TINYINT       NOT NULL DEFAULT 0,
            `required_role` VARCHAR(64)   DEFAULT NULL,
            `sort_order`    SMALLINT      NOT NULL DEFAULT 0,
            `from_config`   TINYINT(1)    NOT NULL DEFAULT 0,
            `hidden`        TINYINT(1)    NOT NULL DEFAULT 0,
            `unlimited`     TINYINT(1)    NOT NULL DEFAULT 0,
            `performance`   VARCHAR(16)   DEFAULT NULL,
            `color1`        TINYINT UNSIGNED DEFAULT NULL,
            `color2`        TINYINT UNSIGNED DEFAULT NULL,
            `livery`        SMALLINT      DEFAULT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_garage_veh` (`job`, `model`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    -- Add `hidden` column to existing tables that predate this version
    MySQL.query.await([[
        ALTER TABLE `mnc_garage_vehicles`
        ADD COLUMN IF NOT EXISTS `hidden` TINYINT(1) NOT NULL DEFAULT 0
    ]])
    -- Add `unlimited` column to existing tables that predate this version
    MySQL.query.await([[
        ALTER TABLE `mnc_garage_vehicles`
        ADD COLUMN IF NOT EXISTS `unlimited` TINYINT(1) NOT NULL DEFAULT 0
    ]])
    -- Add performance/paint columns to existing tables that predate this version
    MySQL.query.await([[
        ALTER TABLE `mnc_garage_vehicles`
        ADD COLUMN IF NOT EXISTS `performance` VARCHAR(16) DEFAULT NULL
    ]])
    MySQL.query.await([[
        ALTER TABLE `mnc_garage_vehicles`
        ADD COLUMN IF NOT EXISTS `color1` TINYINT UNSIGNED DEFAULT NULL
    ]])
    MySQL.query.await([[
        ALTER TABLE `mnc_garage_vehicles`
        ADD COLUMN IF NOT EXISTS `color2` TINYINT UNSIGNED DEFAULT NULL
    ]])
    MySQL.query.await([[
        ALTER TABLE `mnc_garage_vehicles`
        ADD COLUMN IF NOT EXISTS `livery` SMALLINT DEFAULT NULL
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mnc_garage_roles` (
            `id`        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `job`       VARCHAR(64)   NOT NULL,
            `role_name` VARCHAR(64)   NOT NULL,
            `label`     VARCHAR(128)  NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_role` (`job`, `role_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mnc_garage_player_roles` (
            `id`           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
            `citizenid`    VARCHAR(64)   NOT NULL,
            `job`          VARCHAR(64)   NOT NULL,
            `role_name`    VARCHAR(64)   NOT NULL,
            `assigned_by`  VARCHAR(64)   NOT NULL DEFAULT 'admin',
            `assigned_at`  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_player_role` (`citizenid`, `job`, `role_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    if Config.Debug then print("^2[mnc-jobgarage]^7 Tables ready") end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────────────────────────────────────
local function isAdmin(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    -- ACE-based check (server.cfg: add_ace group.admin ... allow)
    if QBCore.Functions.HasPermission(src, 'admin') then return true end
    if QBCore.Functions.HasPermission(src, 'god')   then return true end
    -- QBCore player-data permission level fallback
    local perm = Player.PlayerData.permission
    if perm == 'admin' or perm == 'god' or perm == 'superadmin' then return true end
    return false
end

-- Returns the player's job grade level (0-based), or -1 if not in a job
local function getPlayerGrade(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return -1 end
    local job = Player.PlayerData.job
    if not job or not job.grade then return -1 end
    return job.grade.level or -1
end

-- Returns the player's current job name
local function getPlayerJob(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end
    local job = Player.PlayerData.job
    return job and job.name or nil
end

local function getPlayerIdentifier(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.charinfo then
        local citizenid = Player.PlayerData.citizenid or "N/A"
        local name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        return citizenid, name
    end
    return "N/A", "N/A"
end

local function getCurrentDate()
    return os.date("%d/%m/%Y")
end

local function getFutureDate(days)
    return os.date("%d/%m/%Y", os.time() + (days * 24 * 60 * 60))
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Build merged location list (Config + DB overrides + DB-only garages)
-- ─────────────────────────────────────────────────────────────────────────────
local function buildMergedLocations()
    -- Load DB garage overrides — keyed by garageId (stored in the `job` column)
    local dbGarages = MySQL.query.await('SELECT * FROM mnc_job_garages') or {}
    local dbByGid = {}
    for _, row in ipairs(dbGarages) do
        dbByGid[row.job] = row   -- row.job IS the garageId
    end

    -- Load DB vehicle overrides / additions — keyed by garageId then model
    local dbVehicles = MySQL.query.await('SELECT * FROM mnc_garage_vehicles') or {}
    local dbVehByGid = {}
    for _, row in ipairs(dbVehicles) do
        if not dbVehByGid[row.job] then dbVehByGid[row.job] = {} end
        dbVehByGid[row.job][row.model] = row
    end

    local merged = {}
    local configGids = {}   -- track garageIds seen in config to find DB-only ones later

    -- Start with config entries, apply DB overrides
    for _, loc in ipairs(Config.Locations or {}) do
        -- garageId defaults to job for single-garage-per-job backwards compat
        local garageId = loc.garageId or loc.job
        local job      = loc.job
        configGids[garageId] = true

        local entry = {
            zoneEnable = loc.zoneEnable,
            job        = job,        -- real QBCore job name (for target visibility)
            garageId   = garageId,   -- unique garage key (for DB/vehicle lookups)
            label      = loc.label or garageId,  -- display label, overridden by DB below
            garage     = {
                spawn = loc.garage.spawn,
                out   = loc.garage.out,
                list  = {},
            },
            _fromConfig = true,
        }

        -- Apply DB garage coord/label overrides if present (matched by garageId)
        if dbByGid[garageId] then
            local db = dbByGid[garageId]
            entry.zoneEnable   = (db.zone_enable == 1 or db.zone_enable == true)
            entry.garage.spawn = vec4(db.spawn_x, db.spawn_y, db.spawn_z, db.spawn_w)
            entry.garage.out   = vec4(db.out_x,   db.out_y,   db.out_z,   db.out_w)
            if db.label and db.label ~= '' then
                entry.label = db.label
            end
        end

        -- Merge config vehicle list — DB row overrides ALL config fields
        for model, vdata in pairs(loc.garage.list or {}) do
            -- If DB says hidden, skip this vehicle entirely
            if dbVehByGid[garageId] and dbVehByGid[garageId][model]
               and (dbVehByGid[garageId][model].hidden == 1 or dbVehByGid[garageId][model].hidden == true) then
                -- do not add to list
            else
                local entry_v = {}
                for k, v in pairs(vdata) do entry_v[k] = v end

                -- Apply ALL DB overrides for this config vehicle
                if dbVehByGid[garageId] and dbVehByGid[garageId][model] then
                    local dbv = dbVehByGid[garageId][model]
                    if dbv.required_role and dbv.required_role ~= '' then
                        entry_v.required_role = dbv.required_role
                    elseif dbv.required_role == '' then
                        entry_v.required_role = nil
                    end
                    if dbv.min_grade then entry_v.grade = dbv.min_grade end
                    if dbv.custom_name and dbv.custom_name ~= '' then entry_v.CustomName = dbv.custom_name end
                    if dbv.sort_order and dbv.sort_order > 0 then entry_v.order = dbv.sort_order end
                    entry_v.unlimited = (dbv.unlimited == 1 or dbv.unlimited == true)
                    if dbv.performance ~= nil and dbv.performance ~= '' then
                        entry_v.performance = dbv.performance
                    elseif dbv.performance == '' then
                        entry_v.performance = nil
                    end
                    if dbv.color1 ~= nil then entry_v.db_color1 = dbv.color1 end
                    if dbv.color2 ~= nil then entry_v.db_color2 = dbv.color2 end
                    if dbv.livery ~= nil then entry_v.livery = dbv.livery end
                end

                entry.garage.list[model] = entry_v
            end
        end

        -- Inject DB-only vehicles for this garageId (from_config = 0)
        if dbVehByGid[garageId] then
            for model, dbv in pairs(dbVehByGid[garageId]) do
                if (dbv.from_config == 0 or dbv.from_config == false)
                   and not entry.garage.list[model]
                   and dbv.hidden ~= 1 and dbv.hidden ~= true then
                    entry.garage.list[model] = {
                        CustomName    = dbv.custom_name ~= '' and dbv.custom_name or model,
                        grade         = dbv.min_grade,
                        required_role = dbv.required_role ~= '' and dbv.required_role or nil,
                        order         = dbv.sort_order,
                        unlimited     = (dbv.unlimited == 1 or dbv.unlimited == true),
                        performance   = (dbv.performance and dbv.performance ~= '') and dbv.performance or nil,
                        db_color1     = dbv.color1,
                        db_color2     = dbv.color2,
                        livery        = dbv.livery,
                    }
                end
            end
        end

        merged[#merged + 1] = entry
    end

    -- Add DB-only garages (garageId not seen in config at all)
    for _, db in ipairs(dbGarages) do
        if not configGids[db.job] then   -- db.job IS the garageId here
            -- real_job stores the actual QBCore job name; falls back to garageId
            -- for rows created before this column existed (empty string default).
            local realJob = (db.real_job and db.real_job ~= '') and db.real_job or db.job
            local entry = {
                zoneEnable = (db.zone_enable == 1 or db.zone_enable == true),
                job        = realJob,    -- real QBCore job for target visibility
                garageId   = db.job,    -- garageId = the `job` column value
                label      = (db.label and db.label ~= '') and db.label or db.job,
                garage     = {
                    spawn = vec4(db.spawn_x, db.spawn_y, db.spawn_z, db.spawn_w),
                    out   = vec4(db.out_x,   db.out_y,   db.out_z,   db.out_w),
                    list  = {},
                },
                _fromConfig = false,
            }
            if dbVehByGid[db.job] then
                for model, dbv in pairs(dbVehByGid[db.job]) do
                    entry.garage.list[model] = {
                        CustomName    = dbv.custom_name ~= '' and dbv.custom_name or model,
                        grade         = dbv.min_grade,
                        required_role = dbv.required_role ~= '' and dbv.required_role or nil,
                        order         = dbv.sort_order,
                        unlimited     = (dbv.unlimited == 1 or dbv.unlimited == true),
                        performance   = (dbv.performance and dbv.performance ~= '') and dbv.performance or nil,
                        db_color1     = dbv.color1,
                        db_color2     = dbv.color2,
                        livery        = dbv.livery,
                    }
                end
            end
            merged[#merged + 1] = entry
        end
    end

    return merged
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Original sync events (preserved exactly)
-- ─────────────────────────────────────────────────────────────────────────────
-- ─────────────────────────────────────────────────────────────────────────────
--  Push merged locations to a player when they load in
-- ─────────────────────────────────────────────────────────────────────────────
local function syncToPlayer(src)
    local merged = buildMergedLocations()
    TriggerClientEvent('mnc-jobgarage:client:syncLocations', src, merged)
end

-- QBCore fires this when a player's character is fully loaded
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if Player and Player.PlayerData then
        syncToPlayer(Player.PlayerData.source)
    end
end)

-- Also handle the net event so clients can request a resync themselves
RegisterNetEvent('mnc-jobgarage:server:requestSync', function()
    syncToPlayer(source)
end)

RegisterNetEvent('mnc-jobgarage:server:syncLocations', function()
    if not Config then
        print("Error: Config not loaded, cannot sync locations")
        return
    end
    local merged = buildMergedLocations()
    TriggerClientEvent('mnc-jobgarage:client:syncLocations', -1, merged)
end)

RegisterNetEvent('mnc-jobgarage:server:syncAddLocations', function(data)
    if not Config then
        print("Error: Config not loaded, cannot add locations")
        return
    end
    local dupe = false
    for _, v in pairs(Config.Locations or {}) do
        if v.garage and v.garage.out == data.garage.out then
            dupe = true
            break
        end
    end
    if not dupe then
        if type(data.garage.list[1]) == "string" then
            local list = {}
            for _, v in pairs(data.garage.list) do list[v] = {} end
            data.garage.list = list
        end
        Config.Locations[#Config.Locations + 1] = { zoneEnable = true, job = data.job, garageId = data.garageId or data.job, garage = data.garage }
        if Config.Debug then
            local coords = { string.format("%.2f", data.garage.out.x), string.format("%.2f", data.garage.out.y), string.format("%.2f", data.garage.out.z), string.format("%.2f", data.garage.out.w or 0.0) }
            print("^5Debug^7: ^2Adding new ^3JobGarage^2 location^7: ^5vec4^7(^6" .. coords[1] .. "^7, ^6" .. coords[2] .. "^7, ^6" .. coords[3] .. "^7, ^6" .. coords[4] .. "^7)")
        end
        local merged = buildMergedLocations()
        TriggerClientEvent("mnc-jobgarage:client:syncLocations", -1, merged)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Vehicle insurance helpers (original, preserved exactly)
-- ─────────────────────────────────────────────────────────────────────────────
local function saveInsuredVehicle(data)
    local color1 = data.color1 or ""
    local color2 = data.color2 or ""
    exports.oxmysql:insert([[
        INSERT INTO insured_vehicles (plate, citizenid, playerName, modTier, isBusiness, startDate, endDate, category, name, color1, color2, insuranceCompany)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            citizenid = ?, playerName = ?, modTier = ?, isBusiness = ?, startDate = ?, endDate = ?, category = ?, name = ?, color1 = ?, color2 = ?, insuranceCompany = ?
    ]], {
        data.plate, data.citizenid, data.playerName, data.modTier, data.isBusiness, data.startDate, data.endDate, data.category, data.name, color1, color2, data.insuranceCompany,
        data.citizenid, data.playerName, data.modTier, data.isBusiness, data.startDate, data.endDate, data.category, data.name, color1, color2, data.insuranceCompany
    })
end

local function saveRegisteredVehicle(data)
    local color1 = data.color1 or ""
    local color2 = data.color2 or ""
    exports.oxmysql:insert([[
        INSERT INTO registered_vehicles (plate, citizenid, playerName, registrationDate, category, name, color1, color2)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            citizenid = ?, playerName = ?, registrationDate = ?, category = ?, name = ?, color1 = ?, color2 = ?
    ]], {
        data.plate, data.citizenid, data.playerName, data.registrationDate, data.category, data.name, color1, color2,
        data.citizenid, data.playerName, data.registrationDate, data.category, data.name, color1, color2
    })
end

local function saveInspectedVehicle(data)
    local color1 = data.color1 or ""
    local color2 = data.color2 or ""
    exports.oxmysql:insert([[
        INSERT INTO inspected_vehicles (plate, citizenid, playerName, inspectionDate, category, name, color1, color2)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            citizenid = ?, playerName = ?, inspectionDate = ?, category = ?, name = ?, color1 = ?, color2 = ?
    ]], {
        data.plate, data.citizenid, data.playerName, data.inspectionDate, data.category, data.name, color1, color2,
        data.citizenid, data.playerName, data.inspectionDate, data.category, data.name, color1, color2
    })
end

local function deleteVehicleDocuments(plate)
    exports.oxmysql:execute('DELETE FROM insured_vehicles WHERE plate = ?',   { plate })
    exports.oxmysql:execute('DELETE FROM registered_vehicles WHERE plate = ?', { plate })
    exports.oxmysql:execute('DELETE FROM inspected_vehicles WHERE plate = ?',  { plate })
    if Config.Debug then print("^5Debug^7: ^2Deleted all documents for plate: ^6" .. plate) end
end

local function autoInsureJobVehicle(src, plate, vehicleName, colors)
    local citizenid, playerName = getPlayerIdentifier(src)
    if citizenid == "N/A" then return end
    local color1 = ""
    local color2 = ""
    if type(colors) == "table" and #colors >= 2 then
        color1 = colors[1] or ""
        color2 = colors[2] or ""
    end
    local category = "compacts"
    saveInspectedVehicle({ plate = plate, citizenid = citizenid, playerName = playerName, inspectionDate = getCurrentDate(), category = category, name = vehicleName or "Job Vehicle", color1 = color1, color2 = color2 })
    saveRegisteredVehicle({ plate = plate, citizenid = citizenid, playerName = playerName, registrationDate = getCurrentDate(), category = category, name = vehicleName or "Job Vehicle", color1 = color1, color2 = color2 })
    saveInsuredVehicle({ plate = plate, citizenid = citizenid, playerName = playerName, modTier = 1, isBusiness = false, startDate = getCurrentDate(), endDate = getFutureDate(30), category = category, name = vehicleName or "Job Vehicle", color1 = color1, color2 = color2, insuranceCompany = "MNC" })
    if Config.Debug then print("^5Debug^7: ^2Auto-insured job vehicle - Plate: ^6" .. plate .. "^7, Owner: ^6" .. playerName) end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Original vehicle tracking events (preserved exactly)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent("mnc-jobgarage:server:addTrunkItems", function(plate, items)
    local src = source
    if exports['qb-inventory'] then
        exports['qb-inventory']:OpenInventory(src, "trunk-" .. plate)
        Wait(100)
        TriggerClientEvent('qb-inventory:client:closeInv', src)
        for _, v in pairs(items) do
            exports['qb-inventory']:AddItem("trunk-" .. plate, v.name, v.amount or 1, nil, v.info)
        end
    else
        print("Error: No inventory system detected (ox_inventory or qb-inventory)")
    end
end)

RegisterNetEvent("mnc-jobgarage:server:trackVehicle", function(netVeh, plate, vehicleName, colors)
    local src = source
    ActiveVehicles[netVeh] = { plate = plate, source = src }
    autoInsureJobVehicle(src, plate, vehicleName, colors)
    if Config.Debug then print("^5Debug^7: ^2Tracking vehicle NetID: ^6" .. netVeh .. "^7, Plate: ^6" .. plate) end
end)

RegisterNetEvent("mnc-jobgarage:server:removeVehicle", function(netVeh)
    local src = source
    if ActiveVehicles[netVeh] then
        local plate = ActiveVehicles[netVeh].plate
        deleteVehicleDocuments(plate)
        ActiveVehicles[netVeh] = nil
        if Config.Debug then print("^5Debug^7: ^2Removed vehicle NetID: ^6" .. netVeh .. "^7, Plate: ^6" .. plate) end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if not Config then return end
        for netVeh, data in pairs(ActiveVehicles) do
            local veh = NetworkGetEntityFromNetworkId(netVeh)
            if DoesEntityExist(veh) then DeleteEntity(veh) end
            if data.plate then deleteVehicleDocuments(data.plate) end
        end
        ActiveVehicles = {}
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Admin NUI  ──  open panel
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('mnc-jobgarage:server:openAdmin', function()
    local src = source
    if not isAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access Denied', type = 'error' })
        return
    end
    TriggerClientEvent('mnc-jobgarage:client:openAdminUI', src)
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Checkout tracking table  (declared here so all callbacks below can access it)
-- ─────────────────────────────────────────────────────────────────────────────
-- CheckedOut[job][model] = { citizenid, playerName, netVeh, plate }
local CheckedOut = {}

-- ─────────────────────────────────────────────────────────────────────────────
--  Admin NUI  ──  fetch all data for the panel
-- ─────────────────────────────────────────────────────────────────────────────
-- Safe coord extractor: works on both vec4 userdata and plain {x,y,z,w} tables
local function safeCoord(v)
    if not v then return { x = 0, y = 0, z = 0, w = 0 } end
    return { x = v.x or 0, y = v.y or 0, z = v.z or 0, w = v.w or 0 }
end

lib.callback.register('mnc-jobgarage:cb:getAdminData', function(src)
    if not isAdmin(src) then return nil end

    local ok, result = pcall(function()

    -- All garages: config ones + DB-only
    -- Keyed by garageId (= garageId field in config, or loc.job when absent,
    -- or the `job` column in mnc_job_garages for DB-only rows).
    local garages = {}
    local configGidSeen = {}   -- garageIds we've seen from config

    -- Batch-load all DB garages up-front (one query, not N)
    local allDbGarages = MySQL.query.await('SELECT * FROM mnc_job_garages') or {}
    local dbGarageByGid = {}
    for _, row in ipairs(allDbGarages) do dbGarageByGid[row.job] = row end  -- row.job IS garageId

    for _, loc in ipairs(Config.Locations or {}) do
        local garageId = loc.garageId or loc.job   -- unique per-garage key
        local job      = loc.job                   -- real QBCore job name
        configGidSeen[garageId] = true
        local dbEntry = dbGarageByGid[garageId]

        local spawnCoord = dbEntry
            and { x = dbEntry.spawn_x, y = dbEntry.spawn_y, z = dbEntry.spawn_z, w = dbEntry.spawn_w }
            or  safeCoord(loc.garage and loc.garage.spawn)

        local outCoord = dbEntry
            and { x = dbEntry.out_x, y = dbEntry.out_y, z = dbEntry.out_z, w = dbEntry.out_w }
            or  safeCoord(loc.garage and loc.garage.out)

        garages[#garages + 1] = {
            job           = job,
            garageId      = garageId,
            label         = (dbEntry and dbEntry.label ~= '' and dbEntry.label) or loc.label or garageId,
            spawn         = spawnCoord,
            out           = outCoord,
            zoneEnable    = dbEntry
                and (dbEntry.zone_enable == 1 or dbEntry.zone_enable == true)
                or (not dbEntry and loc.zoneEnable ~= false),
            fromConfig    = true,
            hasDbOverride = dbEntry ~= nil,
        }
    end

    -- DB-only garages (already loaded above; garageId not in any config entry)
    local dbOnly = {}
    for _, row in ipairs(allDbGarages) do
        if (row.is_config == 0 or row.is_config == false) and not configGidSeen[row.job] then
            dbOnly[#dbOnly + 1] = row
            -- real_job stores the QBCore job name; falls back to garageId for old rows
            local realJob = (row.real_job and row.real_job ~= '') and row.real_job or row.job
            garages[#garages + 1] = {
                job           = realJob,   -- real QBCore job for target visibility
                garageId      = row.job,   -- garageId = DB `job` column
                label         = row.label,
                spawn         = { x = row.spawn_x, y = row.spawn_y, z = row.spawn_z, w = row.spawn_w },
                out           = { x = row.out_x,   y = row.out_y,   z = row.out_z,   w = row.out_w   },
                zoneEnable    = (row.zone_enable == 1 or row.zone_enable == true),
                fromConfig    = false,
                hasDbOverride = true,
            }
        end
    end

    -- All vehicles: single batch query then distribute by garageId
    local allDbVehs = MySQL.query.await('SELECT * FROM mnc_garage_vehicles') or {}
    local dbVehsByGid = {}
    for _, dv in ipairs(allDbVehs) do
        if not dbVehsByGid[dv.job] then dbVehsByGid[dv.job] = {} end
        dbVehsByGid[dv.job][dv.model] = dv   -- dv.job IS garageId
    end

    local allVehicles = {}   -- keyed by garageId
    for _, loc in ipairs(Config.Locations or {}) do
        local garageId = loc.garageId or loc.job
        allVehicles[garageId] = allVehicles[garageId] or {}
        local dbVehByModel = dbVehsByGid[garageId] or {}
        local handled = {}

        for model, vdata in pairs(loc.garage and loc.garage.list or {}) do
            local dbv = dbVehByModel[model]
            -- Resolve performance: DB value wins over config value
            local perf = (dbv and dbv.performance and dbv.performance ~= '') and dbv.performance
                         or (type(vdata.performance) == 'string' and vdata.performance ~= '' and vdata.performance)
                         or nil
            -- Resolve paint: DB explicit value wins; nil = no override
            local c1 = (dbv and dbv.color1 ~= nil) and dbv.color1 or nil
            local c2 = (dbv and dbv.color2 ~= nil) and dbv.color2 or nil
            if c1 == nil and type(vdata.colors) == 'table' then c1 = vdata.colors[1] end
            if c2 == nil and type(vdata.colors) == 'table' then c2 = vdata.colors[2] end
            allVehicles[garageId][#allVehicles[garageId] + 1] = {
                job           = garageId,    -- NUI uses this as the garage key
                model         = model,
                customName    = (dbv and dbv.custom_name ~= '' and dbv.custom_name) or vdata.CustomName or model,
                grade         = (dbv and dbv.min_grade) or vdata.grade or 0,
                required_role = (dbv and dbv.required_role and dbv.required_role ~= '' and dbv.required_role) or nil,
                sortOrder     = (dbv and dbv.sort_order) or vdata.order or 0,
                fromConfig    = true,
                hidden        = (dbv and (dbv.hidden == 1 or dbv.hidden == true)) and true or false,
                unlimited     = (dbv and (dbv.unlimited == 1 or dbv.unlimited == true)) and true or false,
                performance   = perf,
                color1        = c1,
                color2        = c2,
                livery        = (dbv and dbv.livery ~= nil) and dbv.livery or (type(vdata.livery) == 'number' and vdata.livery or nil),
            }
            handled[model] = true
        end

        -- DB-only vehicles for this garageId
        for model, dbv in pairs(dbVehByModel) do
            if not handled[model] then
                allVehicles[garageId][#allVehicles[garageId] + 1] = {
                    job           = garageId,
                    model         = model,
                    customName    = (dbv.custom_name ~= '' and dbv.custom_name) or model,
                    grade         = dbv.min_grade or 0,
                    required_role = (dbv.required_role and dbv.required_role ~= '' and dbv.required_role) or nil,
                    sortOrder     = dbv.sort_order or 0,
                    fromConfig    = false,
                    hidden        = (dbv.hidden == 1 or dbv.hidden == true) and true or false,
                    unlimited     = (dbv.unlimited == 1 or dbv.unlimited == true) and true or false,
                    performance   = (dbv.performance and dbv.performance ~= '') and dbv.performance or nil,
                    color1        = dbv.color1,
                    color2        = dbv.color2,
                    livery        = dbv.livery,
                }
            end
        end

        table.sort(allVehicles[garageId], function(a, b) return (a.sortOrder or 0) < (b.sortOrder or 0) end)
    end

    -- DB-only garages' vehicles
    for _, row in ipairs(dbOnly) do
        local garageId = row.job  -- for DB-only, job IS garageId
        allVehicles[garageId] = allVehicles[garageId] or {}
        for model, dbv in pairs(dbVehsByGid[garageId] or {}) do
            allVehicles[garageId][#allVehicles[garageId] + 1] = {
                job           = garageId,
                model         = model,
                customName    = (dbv.custom_name ~= '' and dbv.custom_name) or model,
                grade         = dbv.min_grade or 0,
                required_role = (dbv.required_role and dbv.required_role ~= '' and dbv.required_role) or nil,
                sortOrder     = dbv.sort_order or 0,
                fromConfig    = false,
                hidden        = (dbv.hidden == 1 or dbv.hidden == true) and true or false,
                unlimited     = (dbv.unlimited == 1 or dbv.unlimited == true) and true or false,
                performance   = (dbv.performance and dbv.performance ~= '') and dbv.performance or nil,
                color1        = dbv.color1,
                color2        = dbv.color2,
                livery        = dbv.livery,
            }
        end
    end

    -- All roles (still keyed by real QBCore job name)
    local rolesRaw = MySQL.query.await('SELECT * FROM mnc_garage_roles ORDER BY job, role_name') or {}
    local roles = {}
    for _, r in ipairs(rolesRaw) do
        roles[#roles + 1] = { id = r.id, job = r.job, roleName = r.role_name, label = r.label }
    end

    -- All player role assignments
    local playerRolesRaw = MySQL.query.await('SELECT * FROM mnc_garage_player_roles ORDER BY job, citizenid') or {}
    local playerRoles = {}
    for _, r in ipairs(playerRolesRaw) do
        playerRoles[#playerRoles + 1] = {
            id         = r.id,
            citizenid  = r.citizenid,
            job        = r.job,
            roleName   = r.role_name,
            assignedBy = r.assigned_by,
            assignedAt = tostring(r.assigned_at),
        }
    end

    -- QBCore jobs list (for role/player-role dropdowns)
    local qbJobs = {}
    for jobName, jobData in pairs(QBCore.Shared.Jobs) do
        qbJobs[#qbJobs + 1] = { name = jobName, label = jobData.label or jobName }
    end
    table.sort(qbJobs, function(a, b) return a.label < b.label end)

    -- Build checked-out snapshot for admin panel (keyed by garageId)
    local coSnap = {}
    for garageId, models in pairs(CheckedOut) do
        coSnap[garageId] = {}
        for model, info in pairs(models) do
            coSnap[garageId][model] = { playerName = info.playerName }
        end
    end

    return { garages = garages, vehicles = allVehicles, roles = roles, playerRoles = playerRoles, jobs = qbJobs, checkedOut = coSnap }

    end) -- end pcall

    if not ok then
        print("^1[mnc-jobgarage]^7 getAdminData ERROR: " .. tostring(result))
        return nil
    end
    return result
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Admin NUI  ──  save / upsert a garage
-- ─────────────────────────────────────────────────────────────────────────────
lib.callback.register('mnc-jobgarage:cb:saveGarage', function(src, data)
    if not isAdmin(src) then return false, 'Permission denied' end

    -- garageId is the unique DB key; falls back to job for old/simple entries
    local garageId = data.garageId or data.job

    -- Determine if this garageId exists in config
    local isConfig = false
    for _, loc in ipairs(Config.Locations or {}) do
        if (loc.garageId or loc.job) == garageId then isConfig = true; break end
    end

    MySQL.query.await([[
        INSERT INTO mnc_job_garages (job, real_job, label, spawn_x, spawn_y, spawn_z, spawn_w, out_x, out_y, out_z, out_w, zone_enable, is_config)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            real_job = VALUES(real_job), label = VALUES(label),
            spawn_x = VALUES(spawn_x), spawn_y = VALUES(spawn_y),
            spawn_z = VALUES(spawn_z), spawn_w = VALUES(spawn_w),
            out_x = VALUES(out_x), out_y = VALUES(out_y), out_z = VALUES(out_z), out_w = VALUES(out_w),
            zone_enable = VALUES(zone_enable)
    ]], {
        garageId, data.job or garageId, data.label or garageId,
        data.spawn.x, data.spawn.y, data.spawn.z, data.spawn.w,
        data.out.x,   data.out.y,   data.out.z,   data.out.w,
        data.zoneEnable and 1 or 0,
        isConfig and 1 or 0,
    })

    -- Re-sync all clients
    local merged = buildMergedLocations()
    TriggerClientEvent('mnc-jobgarage:client:syncLocations', -1, merged)

    if Config.Debug then print("^5Debug^7: ^2Saved garage: ^6" .. garageId .. " ^7(job: ^6" .. (data.job or garageId) .. "^7)") end
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Admin NUI  ──  delete a DB-only garage
-- ─────────────────────────────────────────────────────────────────────────────
lib.callback.register('mnc-jobgarage:cb:deleteGarage', function(src, job)
    if not isAdmin(src) then return false end
    -- Only allow deletion of non-config garages; config ones can only be disabled
    MySQL.query.await('DELETE FROM mnc_job_garages WHERE job = ? AND is_config = 0', { job })
    MySQL.query.await('DELETE FROM mnc_garage_vehicles WHERE job = ?', { job })
    local merged = buildMergedLocations()
    TriggerClientEvent('mnc-jobgarage:client:syncLocations', -1, merged)
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Admin NUI  ──  save a vehicle (add/edit)
-- ─────────────────────────────────────────────────────────────────────────────
lib.callback.register('mnc-jobgarage:cb:saveVehicle', function(src, data)
    if not isAdmin(src) then return false end

    -- data.job is the garageId sent from the NUI vehicle form
    -- Determine if this model is a config vehicle for this garageId
    local fromConfig = false
    for _, loc in ipairs(Config.Locations or {}) do
        if (loc.garageId or loc.job) == data.job and loc.garage and loc.garage.list and loc.garage.list[data.model] then
            fromConfig = true
            break
        end
    end

    -- Normalise performance: only 'max' is valid; anything else = nil (no override)
    local performanceVal = nil
    if data.performance == 'max' then performanceVal = 'max' end

    -- Normalise colors: must be 0-159 integers (full GTA colour palette); nil means no override
    local color1Val = tonumber(data.color1)
    local color2Val = tonumber(data.color2)
    if color1Val then color1Val = math.max(0, math.min(159, math.floor(color1Val))) end
    if color2Val then color2Val = math.max(0, math.min(159, math.floor(color2Val))) end

    -- Normalise livery: non-negative integer or nil
    local liveryVal = tonumber(data.livery)
    if liveryVal then liveryVal = math.max(0, math.floor(liveryVal)) end

    MySQL.query.await([[
        INSERT INTO mnc_garage_vehicles (job, model, custom_name, min_grade, required_role, sort_order, from_config, unlimited, performance, color1, color2, livery)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            custom_name = VALUES(custom_name), min_grade = VALUES(min_grade),
            required_role = VALUES(required_role), sort_order = VALUES(sort_order),
            unlimited = VALUES(unlimited), performance = VALUES(performance),
            color1 = VALUES(color1), color2 = VALUES(color2), livery = VALUES(livery)
    ]], {
        data.job, data.model, data.customName or '', data.grade or 0,
        data.required_role ~= '' and data.required_role or nil,
        data.sortOrder or 0,
        fromConfig and 1 or 0,
        data.unlimited and 1 or 0,
        performanceVal,
        color1Val,
        color2Val,
        liveryVal,
    })

    local merged = buildMergedLocations()
    TriggerClientEvent('mnc-jobgarage:client:syncLocations', -1, merged)

    if Config.Debug then print("^5Debug^7: ^2Saved vehicle " .. data.model .. " for job " .. data.job) end
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Admin NUI  ──  delete / hide a vehicle
--  Config vehicles: upsert a DB row with hidden=1 (suppresses from garage)
--  DB-only vehicles: hard delete
-- ─────────────────────────────────────────────────────────────────────────────
lib.callback.register('mnc-jobgarage:cb:deleteVehicle', function(src, data)
    if not isAdmin(src) then return false end

    -- data.job is garageId
    local fromConfig = false
    for _, loc in ipairs(Config.Locations or {}) do
        if (loc.garageId or loc.job) == data.job and loc.garage and loc.garage.list and loc.garage.list[data.model] then
            fromConfig = true
            break
        end
    end

    if fromConfig then
        -- Upsert a DB row that hides this config vehicle
        MySQL.query.await([[
            INSERT INTO mnc_garage_vehicles (job, model, custom_name, min_grade, sort_order, from_config, hidden)
            VALUES (?, ?, '', 0, 0, 1, 1)
            ON DUPLICATE KEY UPDATE hidden = 1
        ]], { data.job, data.model })
    else
        MySQL.query.await('DELETE FROM mnc_garage_vehicles WHERE job = ? AND model = ?', { data.job, data.model })
    end

    local merged = buildMergedLocations()
    TriggerClientEvent('mnc-jobgarage:client:syncLocations', -1, merged)
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Admin NUI  ──  restore a hidden config vehicle
-- ─────────────────────────────────────────────────────────────────────────────
lib.callback.register('mnc-jobgarage:cb:restoreVehicle', function(src, data)
    if not isAdmin(src) then return false end
    MySQL.query.await('UPDATE mnc_garage_vehicles SET hidden = 0 WHERE job = ? AND model = ?', { data.job, data.model })
    local merged = buildMergedLocations()
    TriggerClientEvent('mnc-jobgarage:client:syncLocations', -1, merged)
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Admin NUI  ──  roles CRUD
-- ─────────────────────────────────────────────────────────────────────────────
lib.callback.register('mnc-jobgarage:cb:saveRole', function(src, data)
    if not isAdmin(src) then return false end
    MySQL.query.await([[
        INSERT INTO mnc_garage_roles (job, role_name, label) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE label = VALUES(label)
    ]], { data.job, data.roleName, data.label })
    return true
end)

lib.callback.register('mnc-jobgarage:cb:deleteRole', function(src, data)
    if not isAdmin(src) then return false end
    MySQL.query.await('DELETE FROM mnc_garage_roles WHERE job = ? AND role_name = ?',        { data.job, data.roleName })
    MySQL.query.await('DELETE FROM mnc_garage_player_roles WHERE job = ? AND role_name = ?', { data.job, data.roleName })
    -- Clear the role from vehicles that referenced it
    MySQL.query.await('UPDATE mnc_garage_vehicles SET required_role = NULL WHERE job = ? AND required_role = ?', { data.job, data.roleName })
    local merged = buildMergedLocations()
    TriggerClientEvent('mnc-jobgarage:client:syncLocations', -1, merged)
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Admin NUI  ──  player role assignment
-- ─────────────────────────────────────────────────────────────────────────────
lib.callback.register('mnc-jobgarage:cb:assignPlayerRole', function(src, data)
    if not isAdmin(src) then return false end
    local _, adminName = getPlayerIdentifier(src)
    MySQL.query.await([[
        INSERT INTO mnc_garage_player_roles (citizenid, job, role_name, assigned_by)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE assigned_by = VALUES(assigned_by), assigned_at = CURRENT_TIMESTAMP
    ]], { data.citizenid, data.job, data.roleName, adminName })
    -- Notify the player if online
    local Players = QBCore.Functions.GetPlayers()
    for _, plrSrc in ipairs(Players) do
        local plr = QBCore.Functions.GetPlayer(plrSrc)
        if plr and plr.PlayerData.citizenid == data.citizenid then
            TriggerClientEvent('mnc-jobgarage:client:rolesUpdated', plrSrc)
        end
    end
    return true
end)

lib.callback.register('mnc-jobgarage:cb:removePlayerRole', function(src, data)
    if not isAdmin(src) then return false end
    MySQL.query.await('DELETE FROM mnc_garage_player_roles WHERE citizenid = ? AND job = ? AND role_name = ?',
        { data.citizenid, data.job, data.roleName })
    local Players = QBCore.Functions.GetPlayers()
    for _, plrSrc in ipairs(Players) do
        local plr = QBCore.Functions.GetPlayer(plrSrc)
        if plr and plr.PlayerData.citizenid == data.citizenid then
            TriggerClientEvent('mnc-jobgarage:client:rolesUpdated', plrSrc)
        end
    end
    return true
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  In-job role assignment  ──  grade 4+ can assign/remove roles for their job
--  Called from the pullout NUI (not the admin panel)
-- ─────────────────────────────────────────────────────────────────────────────
local ROLE_ASSIGN_MIN_GRADE = 4   -- minimum grade to assign roles in-job

lib.callback.register('mnc-jobgarage:cb:jobAssignRole', function(src, data)
    -- data: { citizenid, job, roleName }
    local callerGrade = getPlayerGrade(src)
    local callerJob   = getPlayerJob(src)

    -- Must be at least grade 4 AND in the same job they're assigning for
    if callerGrade < ROLE_ASSIGN_MIN_GRADE then
        return false, 'Insufficient rank'
    end
    if callerJob ~= data.job then
        return false, 'Wrong job'
    end

    -- Verify the role actually exists for this job
    local roleRow = MySQL.query.await(
        'SELECT id FROM mnc_garage_roles WHERE job = ? AND role_name = ?',
        { data.job, data.roleName }
    ) or {}
    if #roleRow == 0 then
        return false, 'Role does not exist'
    end

    local _, callerName = getPlayerIdentifier(src)
    MySQL.query.await([[
        INSERT INTO mnc_garage_player_roles (citizenid, job, role_name, assigned_by)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE assigned_by = VALUES(assigned_by), assigned_at = CURRENT_TIMESTAMP
    ]], { data.citizenid, data.job, data.roleName, callerName })

    -- Notify target if online
    local Players = QBCore.Functions.GetPlayers()
    for _, plrSrc in ipairs(Players) do
        local plr = QBCore.Functions.GetPlayer(plrSrc)
        if plr and plr.PlayerData.citizenid == data.citizenid then
            TriggerClientEvent('mnc-jobgarage:client:rolesUpdated', plrSrc)
        end
    end
    return true
end)

lib.callback.register('mnc-jobgarage:cb:jobRemoveRole', function(src, data)
    -- data: { citizenid, job, roleName }
    local callerGrade = getPlayerGrade(src)
    local callerJob   = getPlayerJob(src)

    if callerGrade < ROLE_ASSIGN_MIN_GRADE then
        return false, 'Insufficient rank'
    end
    if callerJob ~= data.job then
        return false, 'Wrong job'
    end

    MySQL.query.await(
        'DELETE FROM mnc_garage_player_roles WHERE citizenid = ? AND job = ? AND role_name = ?',
        { data.citizenid, data.job, data.roleName }
    )

    local Players = QBCore.Functions.GetPlayers()
    for _, plrSrc in ipairs(Players) do
        local plr = QBCore.Functions.GetPlayer(plrSrc)
        if plr and plr.PlayerData.citizenid == data.citizenid then
            TriggerClientEvent('mnc-jobgarage:client:rolesUpdated', plrSrc)
        end
    end
    return true
end)

-- Fetch roles for the calling player's job (for the pullout role panel)
lib.callback.register('mnc-jobgarage:cb:getJobRolesForPullout', function(src)
    local callerGrade = getPlayerGrade(src)
    local callerJob   = getPlayerJob(src)
    if callerGrade < ROLE_ASSIGN_MIN_GRADE or not callerJob then return nil end

    local roles = MySQL.query.await(
        'SELECT role_name, label FROM mnc_garage_roles WHERE job = ? ORDER BY role_name',
        { callerJob }
    ) or {}

    local assignments = MySQL.query.await(
        'SELECT p.citizenid, p.role_name, p.assigned_by FROM mnc_garage_player_roles p WHERE p.job = ?',
        { callerJob }
    ) or {}

    return { job = callerJob, roles = roles, assignments = assignments }
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Player role fetch  (called client-side when opening garage menu)
-- ─────────────────────────────────────────────────────────────────────────────
lib.callback.register('mnc-jobgarage:cb:getMyRoles', function(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return {} end
    local citizenid = Player.PlayerData.citizenid
    local rows = MySQL.query.await('SELECT job, role_name FROM mnc_garage_player_roles WHERE citizenid = ?', { citizenid }) or {}
    local result = {}
    for _, r in ipairs(rows) do
        if not result[r.job] then result[r.job] = {} end
        result[r.job][r.role_name] = true
    end
    return result
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  NUI → Server bridge  (client relays nuiPost events to server via net events)
-- ─────────────────────────────────────────────────────────────────────────────
-- These are handled via RegisterNUICallback on the CLIENT side (client/main.lua)
-- The actual logic is in lib.callback.register blocks above.
-- Nothing extra needed here — ox_lib callbacks are server-side already.

-- ─────────────────────────────────────────────────────────────────────────────
--  VEHICLE CHECKOUT LOCK
-- ─────────────────────────────────────────────────────────────────────────────
local function isCheckedOut(job, model)
    return CheckedOut[job] and CheckedOut[job][model] ~= nil
end

local function checkoutVehicle(job, model, src, plate, netVeh)
    if not CheckedOut[job] then CheckedOut[job] = {} end
    local citizenid, playerName = getPlayerIdentifier(src)
    CheckedOut[job][model] = { citizenid = citizenid, playerName = playerName, netVeh = netVeh, plate = plate, source = src }
    TriggerClientEvent('mnc-jobgarage:client:checkoutUpdated', -1, job, model, true, playerName)
    if Config.Debug then print("^5Checkout^7: " .. model .. " checked out by " .. playerName) end
end

local function returnVehicle(job, model)
    if CheckedOut[job] then
        local data = CheckedOut[job][model]
        CheckedOut[job][model] = nil
        TriggerClientEvent('mnc-jobgarage:client:checkoutUpdated', -1, job, model, false, nil)
        if Config.Debug and data then print("^5Checkout^7: " .. model .. " returned by " .. (data.playerName or '?')) end
    end
end

-- Expose checked out state to client for pullout UI
lib.callback.register('mnc-jobgarage:cb:getCheckedOut', function(src, job)
    return CheckedOut[job] or {}
end)

-- Called when player pulls vehicle from garage
RegisterNetEvent('mnc-jobgarage:server:checkoutVehicle', function(job, model, plate, netVeh)
    local src = source
    if isCheckedOut(job, model) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Vehicle Unavailable', description = 'That vehicle is already signed out', type = 'error' })
        return
    end
    checkoutVehicle(job, model, src, plate, netVeh)
end)

-- Called when vehicle is returned
RegisterNetEvent('mnc-jobgarage:server:returnVehicle', function(job, model)
    returnVehicle(job, model)
end)

-- Clean up checkout state on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CheckedOut = {}
    end
end)

-- Server-side "sign out for player" from admin NUI
lib.callback.register('mnc-jobgarage:cb:adminSignOutVehicle', function(src, data)
    if not isAdmin(src) then return false end
    -- data: { job, model, targetCitizenId }
    -- Find the target player
    local Players = QBCore.Functions.GetPlayers()
    local targetSrc = nil
    for _, plrSrc in ipairs(Players) do
        local plr = QBCore.Functions.GetPlayer(plrSrc)
        if plr and plr.PlayerData.citizenid == data.targetCitizenId then
            targetSrc = plrSrc
            break
        end
    end
    if not targetSrc then return false, 'Player not online' end
    if isCheckedOut(data.job, data.model) then return false, 'Already checked out' end
    -- Tell the target client to spawn the vehicle
    TriggerClientEvent('mnc-jobgarage:client:adminSpawnVehicle', targetSrc, data.job, data.model)
    return true
end)



-- ─────────────────────────────────────────────────────────────────────────────
--  NUI: getMyId  ──  returns the calling admin's own citizenid
-- ─────────────────────────────────────────────────────────────────────────────
lib.callback.register('mnc-jobgarage:cb:getMyId', function(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return { citizenid = nil } end
    return { citizenid = Player.PlayerData.citizenid }
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  NUI: lookupPlayerId  ──  look up a citizenid from an online server ID
-- ─────────────────────────────────────────────────────────────────────────────
lib.callback.register('mnc-jobgarage:cb:lookupPlayerId', function(src, data)
    -- Allow admins AND grade 4+ players (who use this from the pullout role panel)
    local callerGrade = getPlayerGrade(src)
    if not isAdmin(src) and callerGrade < ROLE_ASSIGN_MIN_GRADE then
        return { citizenid = nil }
    end
    local targetSrc = tonumber(data and data.serverId)
    if not targetSrc then return { citizenid = nil } end
    local Player = QBCore.Functions.GetPlayer(targetSrc)
    if not Player then return { citizenid = nil } end
    local ci = Player.PlayerData.citizenid
    local ci_name = Player.PlayerData.charinfo and
        (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname) or ci
    return { citizenid = ci, name = ci_name }
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  NUI: batchUpdateVehicleOrder  ──  save drag-reorder results
-- ─────────────────────────────────────────────────────────────────────────────
lib.callback.register('mnc-jobgarage:cb:batchUpdateVehicleOrder', function(src, data)
    if not isAdmin(src) then return false end
    -- data.updates = [{ job, model, sortOrder }]

    -- Build config vehicle lookup for from_config flag (keyed by garageId:model)
    local configVehs = {}
    for _, loc in ipairs(Config.Locations or {}) do
        if loc.garage and loc.garage.list then
            local garageId = loc.garageId or loc.job
            for model, _ in pairs(loc.garage.list) do
                configVehs[garageId .. ':' .. model] = true
            end
        end
    end

    for _, u in ipairs(data.updates or {}) do
        local fc = configVehs[u.job .. ':' .. u.model] and 1 or 0
        MySQL.query.await([[
            INSERT INTO mnc_garage_vehicles (job, model, sort_order, custom_name, min_grade, from_config, hidden)
            VALUES (?, ?, ?, '', 0, ?, 0)
            ON DUPLICATE KEY UPDATE sort_order = VALUES(sort_order)
        ]], { u.job, u.model, u.sortOrder, fc })
    end
    local merged = buildMergedLocations()
    TriggerClientEvent('mnc-jobgarage:client:syncLocations', -1, merged)
    return true
end)

print("^2[mnc-jobgarage]^7 Server loaded successfully!")