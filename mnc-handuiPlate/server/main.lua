local QBCore = exports['qb-core']:GetCoreObject()

local PlateOverrides = {}   -- [plate] = { plate, model, data, original, updatedBy, updatedAt }

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

-- Plates are shown to players and can be set to arbitrary text via mod shops,
-- so this is intentionally permissive (letters/digits/spaces) rather than
-- the strict spawn-code pattern mnc-handui uses for model names.
local function NormalizePlate(plate)
    if type(plate) ~= 'string' then return nil end
    plate = plate:gsub('^%s+', ''):gsub('%s+$', ''):upper()
    if plate == '' or #plate > 12 then return nil end
    if not plate:match('^[%w ]+$') then return nil end
    return plate
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
            CREATE TABLE IF NOT EXISTS `mnc_handling_overrides_plate` (
              `plate`         VARCHAR(12)  NOT NULL,
              `model`         VARCHAR(64)  DEFAULT NULL,
              `data`          LONGTEXT     NOT NULL,
              `original_data` LONGTEXT     NOT NULL DEFAULT '',
              `updated_by`    VARCHAR(100) DEFAULT NULL,
              `updated_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
              PRIMARY KEY (`plate`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end)

    if not ok then
        print(('[mnc-handuiPlate] ^1Failed to auto-create mnc_handling_overrides_plate table: %s^0'):format(tostring(err)))
        print('[mnc-handuiPlate] ^1Run sql/install.sql manually, then restart the resource.^0')
    end
end

----------------------------------------------------------------------------
-- DB load / cache
----------------------------------------------------------------------------

local function LoadOverridesFromDB()
    local rows = MySQL.query.await('SELECT * FROM mnc_handling_overrides_plate', {})
    PlateOverrides = {}
    if not rows then return end

    for _, row in ipairs(rows) do
        local ok, data = pcall(json.decode, row.data or '{}')
        if not ok then data = {} end
        local ok2, original = pcall(json.decode, row.original_data or '{}')
        if not ok2 then original = {} end

        PlateOverrides[row.plate] = {
            plate = row.plate,
            model = row.model,
            data = data or {},
            original = original or {},
            updatedBy = row.updated_by,
            updatedAt = row.updated_at,
        }
    end
end

local function BuildPlateTable()
    local t = {}
    for _, entry in pairs(PlateOverrides) do
        t[entry.plate] = entry.data
    end
    return t
end

CreateThread(function()
    EnsureTable()
    LoadOverridesFromDB()
    print(('[mnc-handuiPlate] Loaded %d saved handling override(s) from the database.'):format(CountTable(PlateOverrides)))
    TriggerClientEvent('mnc-handuiPlate:client:syncOverrides', -1, BuildPlateTable())
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if not Player or not Player.PlayerData then return end
    TriggerClientEvent('mnc-handuiPlate:client:syncOverrides', Player.PlayerData.source, BuildPlateTable())
end)

RegisterNetEvent('mnc-handuiPlate:server:requestSync', function()
    local src = source
    TriggerClientEvent('mnc-handuiPlate:client:syncOverrides', src, BuildPlateTable())
end)

----------------------------------------------------------------------------
-- Callbacks
----------------------------------------------------------------------------

QBCore.Functions.CreateCallback('mnc-handuiPlate:server:checkAccess', function(source, cb)
    cb(HasAdminPerm(source))
end)

QBCore.Functions.CreateCallback('mnc-handuiPlate:server:getAllOverrides', function(source, cb)
    if not HasAdminPerm(source) then cb({}) return end

    local list = {}
    for _, entry in pairs(PlateOverrides) do
        list[#list + 1] = {
            plate = entry.plate,
            model = entry.model,
            updatedBy = entry.updatedBy,
            updatedAt = entry.updatedAt,
        }
    end
    table.sort(list, function(a, b) return a.plate < b.plate end)
    cb(list)
end)

QBCore.Functions.CreateCallback('mnc-handuiPlate:server:getOverride', function(source, cb, plate)
    if not HasAdminPerm(source) then cb(nil) return end
    plate = NormalizePlate(plate)
    if not plate then cb(nil) return end

    local entry = PlateOverrides[plate]
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

RegisterNetEvent('mnc-handuiPlate:server:saveOverride', function(payload)
    local src = source

    if not HasAdminPerm(src) then
        TriggerClientEvent('mnc-handuiPlate:client:saveResult', src, false, 'You do not have permission to do that.')
        return
    end

    if type(payload) ~= 'table' then
        TriggerClientEvent('mnc-handuiPlate:client:saveResult', src, false, 'Invalid request.')
        return
    end

    local plate = NormalizePlate(payload.plate)
    if not plate then
        TriggerClientEvent('mnc-handuiPlate:client:saveResult', src, false, "That doesn't look like a valid plate.")
        return
    end

    local cleanData = SanitizeFields(payload.fields)
    if next(cleanData) == nil then
        TriggerClientEvent('mnc-handuiPlate:client:saveResult', src, false, 'No valid handling values were supplied.')
        return
    end

    local existing = PlateOverrides[plate]
    local originalData
    if existing and existing.original and next(existing.original) ~= nil then
        originalData = existing.original
    else
        originalData = SanitizeFields(payload.original)
    end

    -- model is display-only (shown in the saves list), so just trim/cap it
    local modelName = type(payload.model) == 'string' and payload.model:sub(1, 64) or (existing and existing.model)

    local Player = QBCore.Functions.GetPlayer(src)
    local adminName = ('Unknown (%s)'):format(src)
    if Player then
        adminName = ('%s (%s)'):format(GetPlayerName(src) or 'Unknown', Player.PlayerData.citizenid)
    end

    MySQL.update.await([[
        INSERT INTO mnc_handling_overrides_plate (plate, model, data, original_data, updated_by)
        VALUES (:plate, :model, :data, :original_data, :updated_by)
        ON DUPLICATE KEY UPDATE
            model = :model,
            data = :data,
            original_data = :original_data,
            updated_by = :updated_by,
            updated_at = CURRENT_TIMESTAMP
    ]], {
        ['plate'] = plate,
        ['model'] = modelName,
        ['data'] = json.encode(cleanData),
        ['original_data'] = json.encode(originalData),
        ['updated_by'] = adminName,
    })

    LoadOverridesFromDB()

    local entry = PlateOverrides[plate]
    if not entry then
        TriggerClientEvent('mnc-handuiPlate:client:saveResult', src, false, 'Save failed, please try again.')
        return
    end

    TriggerClientEvent('mnc-handuiPlate:client:overrideUpdated', -1, entry.plate, entry.data)
    TriggerClientEvent('mnc-handuiPlate:client:saveResult', src, true, ('Saved handling for plate %s.'):format(plate), entry)
end)

RegisterNetEvent('mnc-handuiPlate:server:deleteOverride', function(rawPlate)
    local src = source

    if not HasAdminPerm(src) then
        TriggerClientEvent('mnc-handuiPlate:client:saveResult', src, false, 'You do not have permission to do that.')
        return
    end

    local plate = NormalizePlate(rawPlate)
    if not plate then return end

    local entry = PlateOverrides[plate]
    if not entry then
        TriggerClientEvent('mnc-handuiPlate:client:saveResult', src, false, 'No saved override exists for that plate.')
        return
    end

    MySQL.update.await('DELETE FROM mnc_handling_overrides_plate WHERE plate = :plate', {
        ['plate'] = plate,
    })

    local original = entry.original

    PlateOverrides[plate] = nil

    TriggerClientEvent('mnc-handuiPlate:client:overrideRemoved', -1, plate, original)
    TriggerClientEvent('mnc-handuiPlate:client:saveResult', src, true, ('Reverted plate %s to default handling.'):format(plate))
end)
