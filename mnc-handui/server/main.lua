local QBCore = exports['qb-core']:GetCoreObject()

local ModelOverrides = {}
local ModelOverridesByName = {}

----------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------

local function HasAdminPerm(src)
    if not src or src == 0 then return false end
    local ok = QBCore.Functions.HasPermission(src, Config.AdminPermission)
    return ok and true or false
end

local function CountTable(t)
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
end

local function ClampValue(field, value)
    value = tonumber(value)
    if not value then return nil end
    if field.type == 'int' then
        value = math.floor(value + 0.5)
    end
    if field.min and value < field.min then value = field.min end
    if field.max and value > field.max then value = field.max end
    return value
end

local function SanitizeFields(rawFields)
    local clean = {}
    if type(rawFields) ~= 'table' then return clean end
    for key, value in pairs(rawFields) do
        local field = Config.FieldLookup[key]
        if field then
            local v = ClampValue(field, value)
            if v ~= nil then
                clean[key] = v
            end
        end
    end
    return clean
end

----------------------------------------------------------------------------
-- DB auto-migration
----------------------------------------------------------------------------

local function EnsureTable()
    local ok, err = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `mnc_handling_overrides` (
              `model`         VARCHAR(64)  NOT NULL,
              `data`          LONGTEXT     NOT NULL,
              `original_data` LONGTEXT     NOT NULL DEFAULT '',
              `updated_by`    VARCHAR(100) DEFAULT NULL,
              `updated_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
              PRIMARY KEY (`model`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end)

    if not ok then
        print(('[mnc-handui] ^1Failed to auto-create mnc_handling_overrides table: %s^0'):format(tostring(err)))
        print('[mnc-handui] ^1Run sql/install.sql manually, then restart the resource.^0')
    end
end

----------------------------------------------------------------------------
-- DB load / cache
----------------------------------------------------------------------------

local function LoadOverridesFromDB()
    local rows = MySQL.query.await('SELECT * FROM mnc_handling_overrides', {})
    ModelOverrides = {}
    ModelOverridesByName = {}
    if not rows then return end

    for _, row in ipairs(rows) do
        local hash = GetHashKey(row.model)
        local ok, data = pcall(json.decode, row.data or '{}')
        if not ok then data = {} end
        local ok2, original = pcall(json.decode, row.original_data or '{}')
        if not ok2 then original = {} end

        local entry = {
            model = row.model,
            hash = hash,
            data = data or {},
            original = original or {},
            updatedBy = row.updated_by,
            updatedAt = row.updated_at,
        }

        ModelOverrides[hash] = entry
        ModelOverridesByName[row.model] = entry
    end
end

local function BuildHashTable()
    local t = {}
    for _, entry in pairs(ModelOverridesByName) do
        t[entry.model] = entry.data
    end
    return t
end

CreateThread(function()
    EnsureTable()
    LoadOverridesFromDB()
    print(('[mnc-handui] Loaded %d saved handling override(s) from the database.'):format(CountTable(ModelOverrides)))
    TriggerClientEvent('mnc-handui:client:syncOverrides', -1, BuildHashTable())
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if not Player or not Player.PlayerData then return end
    TriggerClientEvent('mnc-handui:client:syncOverrides', Player.PlayerData.source, BuildHashTable())
end)

RegisterNetEvent('mnc-handui:server:requestSync', function()
    local src = source
    TriggerClientEvent('mnc-handui:client:syncOverrides', src, BuildHashTable())
end)

----------------------------------------------------------------------------
-- Callbacks
----------------------------------------------------------------------------

QBCore.Functions.CreateCallback('mnc-handui:server:checkAccess', function(source, cb)
    cb(HasAdminPerm(source))
end)

QBCore.Functions.CreateCallback('mnc-handui:server:getAllOverrides', function(source, cb)
    if not HasAdminPerm(source) then cb({}) return end

    local list = {}
    for _, entry in pairs(ModelOverridesByName) do
        list[#list + 1] = {
            model = entry.model,
            updatedBy = entry.updatedBy,
            updatedAt = entry.updatedAt,
        }
    end
    table.sort(list, function(a, b) return a.model < b.model end)
    cb(list)
end)

QBCore.Functions.CreateCallback('mnc-handui:server:getOverride', function(source, cb, modelName)
    if not HasAdminPerm(source) then cb(nil) return end
    if type(modelName) ~= 'string' then cb(nil) return end

    local entry = ModelOverridesByName[modelName:lower()]
    if not entry then cb(nil) return end

    cb({
        data = entry.data,
        original = entry.original,
        updatedBy = entry.updatedBy,
        updatedAt = entry.updatedAt,
    })
end)

----------------------------------------------------------------------------
-- Save / Delete
----------------------------------------------------------------------------

RegisterNetEvent('mnc-handui:server:saveOverride', function(payload)
    local src = source

    if not HasAdminPerm(src) then
        TriggerClientEvent('mnc-handui:client:saveResult', src, false, 'You do not have permission to do that.')
        return
    end

    if type(payload) ~= 'table' or type(payload.model) ~= 'string' then
        TriggerClientEvent('mnc-handui:client:saveResult', src, false, 'Invalid request.')
        return
    end

    local modelName = payload.model:lower():gsub('%s+', '')

    if modelName == '' or #modelName > 64 or not modelName:match('^[%a][%w_]*$') then
        TriggerClientEvent('mnc-handui:client:saveResult', src, false, "That doesn't look like a valid vehicle spawn code.")
        return
    end

    local cleanData = SanitizeFields(payload.fields)
    if next(cleanData) == nil then
        TriggerClientEvent('mnc-handui:client:saveResult', src, false, 'No valid handling values were supplied.')
        return
    end

    local existing = ModelOverridesByName[modelName]
    local originalData
    if existing and existing.original and next(existing.original) ~= nil then
        originalData = existing.original
    else
        originalData = SanitizeFields(payload.original)
    end

    local Player = QBCore.Functions.GetPlayer(src)
    local adminName = ('Unknown (%s)'):format(src)
    if Player then
        adminName = ('%s (%s)'):format(GetPlayerName(src) or 'Unknown', Player.PlayerData.citizenid)
    end

    MySQL.update.await([[
        INSERT INTO mnc_handling_overrides (model, data, original_data, updated_by)
        VALUES (:model, :data, :original_data, :updated_by)
        ON DUPLICATE KEY UPDATE
            data = :data,
            original_data = :original_data,
            updated_by = :updated_by,
            updated_at = CURRENT_TIMESTAMP
    ]], {
        ['model'] = modelName,
        ['data'] = json.encode(cleanData),
        ['original_data'] = json.encode(originalData),
        ['updated_by'] = adminName,
    })

    LoadOverridesFromDB()

    local entry = ModelOverridesByName[modelName]
    if not entry then
        TriggerClientEvent('mnc-handui:client:saveResult', src, false, 'Save failed, please try again.')
        return
    end

    local label = (QBCore.Shared.Vehicles[modelName] and QBCore.Shared.Vehicles[modelName].name) or modelName

    TriggerClientEvent('mnc-handui:client:overrideUpdated', -1, entry.model, entry.data)
    TriggerClientEvent('mnc-handui:client:saveResult', src, true, ('Saved handling for %s.'):format(label), entry)
end)

RegisterNetEvent('mnc-handui:server:deleteOverride', function(modelName)
    local src = source

    if not HasAdminPerm(src) then
        TriggerClientEvent('mnc-handui:client:saveResult', src, false, 'You do not have permission to do that.')
        return
    end

    if type(modelName) ~= 'string' then return end
    modelName = modelName:lower()

    local entry = ModelOverridesByName[modelName]
    if not entry then
        TriggerClientEvent('mnc-handui:client:saveResult', src, false, 'No saved override exists for that model.')
        return
    end

    MySQL.update.await('DELETE FROM mnc_handling_overrides WHERE model = :model', {
        ['model'] = modelName,
    })

    local hash = entry.hash
    local original = entry.original
    local model = entry.model

    ModelOverrides[hash] = nil
    ModelOverridesByName[modelName] = nil

    TriggerClientEvent('mnc-handui:client:overrideRemoved', -1, model, original)
    TriggerClientEvent('mnc-handui:client:saveResult', src, true, ('Reverted %s to default handling.'):format(modelName))
end)