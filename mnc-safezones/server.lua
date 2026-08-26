local QBCore = exports['qb-core']:GetCoreObject()
local SafeZones = {}

-- ─── Helpers ─────────────────────────────────────────────────────────────────
local function SquarePoints(cx, cy, cz, r)
    -- Builds a 4-corner square polygon. Only used to generate fresh seed data
    -- below — existing legacy circle rows are never rewritten.
    return {
        { x = cx - r, y = cy - r, z = cz },
        { x = cx + r, y = cy - r, z = cz },
        { x = cx + r, y = cy + r, z = cz },
        { x = cx - r, y = cy + r, z = cz },
    }
end

-- Runs a schema-altering query and swallows any error. Used for ALTER
-- statements that only make sense on installs that still have the legacy
-- columns (a totally fresh install won't, and that's fine).
local function TrySchemaChange(sql)
    pcall(function() MySQL.query.await(sql) end)
end

-- Depending on the MySQL driver/version, a JSON column may come back already
-- decoded into a Lua table, or as a raw JSON string that still needs
-- json.decode. Handle both so this doesn't break across oxmysql versions.
local function DecodeJsonColumn(raw)
    if type(raw) == 'table' then
        return raw
    elseif type(raw) == 'string' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            return decoded
        end
    end
    return nil
end

-- ─── Database init ─────────────────────────────────────────────────────────────
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
    Wait(2000)

    -- Fresh-install schema: polygon points *and* the old center/radius
    -- columns both exist (nullable) so this table works for either shape.
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mnc_safezones (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            name       VARCHAR(100) NOT NULL,
            points     JSON         NULL,
            center_x   FLOAT        NULL,
            center_y   FLOAT        NULL,
            center_z   FLOAT        NULL,
            radius     FLOAT        NULL,
            height     FLOAT        NOT NULL DEFAULT 20.0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Upgrading from an older install: make sure every column we need exists.
    -- These are no-ops on a fresh install (already created above) and on an
    -- install that's already been upgraded once.
    MySQL.query("ALTER TABLE mnc_safezones ADD COLUMN IF NOT EXISTS points   JSON  NULL AFTER name")
    MySQL.query("ALTER TABLE mnc_safezones ADD COLUMN IF NOT EXISTS height   FLOAT NOT NULL DEFAULT 20.0")
    MySQL.query("ALTER TABLE mnc_safezones ADD COLUMN IF NOT EXISTS center_x FLOAT NULL")
    MySQL.query("ALTER TABLE mnc_safezones ADD COLUMN IF NOT EXISTS center_y FLOAT NULL")
    MySQL.query("ALTER TABLE mnc_safezones ADD COLUMN IF NOT EXISTS center_z FLOAT NULL")
    MySQL.query("ALTER TABLE mnc_safezones ADD COLUMN IF NOT EXISTS radius   FLOAT NULL")

    -- Old (pre-polygon) installs defined center_x/center_y as NOT NULL with no
    -- default, which would reject new polygon-only inserts that don't supply
    -- them. Relax that constraint. Existing legacy row *data* is untouched —
    -- this only changes what's required going forward.
    TrySchemaChange("ALTER TABLE mnc_safezones MODIFY COLUMN center_x FLOAT NULL DEFAULT NULL")
    TrySchemaChange("ALTER TABLE mnc_safezones MODIFY COLUMN center_y FLOAT NULL DEFAULT NULL")
    TrySchemaChange("ALTER TABLE mnc_safezones MODIFY COLUMN center_z FLOAT NULL DEFAULT NULL")
    TrySchemaChange("ALTER TABLE mnc_safezones MODIFY COLUMN radius   FLOAT NULL DEFAULT NULL")

    -- ─── First-run seed data ───────────────────────────────────────────────────
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM mnc_safezones')
    if count == 0 then
        local seeds = {
            { name = 'City Hall', cx = -264.51,  cy = -964.19,   cz = 30.0, r = 80.0 },
            { name = 'Hospital',  cx = 310.8,    cy = -593.31,   cz = 30.0, r = 80.0 },
            { name = 'MRPD',      cx = 448.5,    cy = -988.4,    cz = 30.0, r = 80.0 },
            { name = 'LSIA',      cx = -1037.43, cy = -2736.82,  cz = 30.0, r = 80.0 },
        }
        for _, seed in ipairs(seeds) do
            MySQL.insert.await('INSERT INTO mnc_safezones (name, points, height) VALUES (?,?,?)', {
                seed.name, json.encode(SquarePoints(seed.cx, seed.cy, seed.cz, seed.r)), 20.0
            })
        end
        print("^2[mnc-safezones]^7 Default safe zones inserted")
    end

    LoadSafeZones()
end)

-- ─── Load & broadcast ──────────────────────────────────────────────────────────
-- Every row is either a new-style polygon (has valid `points`) or an old-style
-- circle (has center_x/center_y/center_z/radius, no valid `points`). Both are
-- sent to the client tagged with a `shape` field so it can build the right
-- kind of zone for each — legacy zones are never converted or altered.
function LoadSafeZones()
    local result = MySQL.query.await(
        'SELECT id, name, points, height, center_x, center_y, center_z, radius FROM mnc_safezones ORDER BY id ASC'
    )
    SafeZones = {}
    for _, row in ipairs(result or {}) do
        local decoded = DecodeJsonColumn(row.points)
        local points = {}
        if decoded then
            for _, p in ipairs(decoded) do
                local x, y, z = tonumber(p.x), tonumber(p.y), tonumber(p.z)
                if x and y and z then
                    table.insert(points, { x = x, y = y, z = z })
                end
            end
        end

        if #points >= 3 then
            table.insert(SafeZones, {
                id     = row.id,
                name   = row.name,
                shape  = 'poly',
                points = points,
                height = row.height,
            })
        elseif row.center_x ~= nil and row.center_y ~= nil and row.center_z ~= nil and row.radius ~= nil then
            -- Legacy circle zone from a pre-polygon install — kept exactly as configured.
            table.insert(SafeZones, {
                id       = row.id,
                name     = row.name,
                shape    = 'circle',
                center_x = tonumber(row.center_x),
                center_y = tonumber(row.center_y),
                center_z = tonumber(row.center_z),
                radius   = tonumber(row.radius),
                height   = row.height,
            })
        else
            print(("^1[mnc-safezones]^7 Skipped zone '%s' (id %s) — no valid points or legacy circle data"):format(row.name, row.id))
        end
    end
    TriggerClientEvent('mnc-safezones:receiveSafeZones', -1, SafeZones)
    print(("^2[mnc-safezones]^7 Loaded %d zones"):format(#SafeZones))
end

-- ─── Send zones to a player when they finish loading ──────────────────────────
-- This covers two cases:
--   1. QBCore:Server:PlayerLoaded  – fired by qb-core when the player's
--      character is fully spawned and client-side resources are ready.
--   2. playerSpawned (fallback)    – broader FiveM event, catches edge-cases
--      where the QBCore event fires before mnc-safezones has finished its own
--      DB init (unlikely but safe to have).
--
-- Both handlers simply push the current SafeZones table to that one player.
-- Because SafeZones is populated before any player can realistically join
-- (2 s startup delay + DB query), this will almost always have data.

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = player.PlayerData.source
    TriggerClientEvent('mnc-safezones:receiveSafeZones', src, SafeZones)
end)

-- Belt-and-suspenders: also hook the raw FiveM spawn event so late-joiners
-- or players who bypass the QBCore flow still receive the zone list.
AddEventHandler('playerSpawned', function()
    local src = source
    TriggerClientEvent('mnc-safezones:receiveSafeZones', src, SafeZones)
end)

-- ─── Open menu request ─────────────────────────────────────────────────────────
RegisterNetEvent('mnc-safezones:requestMenu')
AddEventHandler('mnc-safezones:requestMenu', function()
    local src = source
    if QBCore.Functions.HasPermission(src, 'admin') then
        -- Always send fresh zone list before opening
        TriggerClientEvent('mnc-safezones:receiveSafeZones', src, SafeZones)
        TriggerClientEvent('mnc-safezones:openMenu', src)
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access Denied', description = 'Admin only', type = 'error' })
    end
end)

-- ─── Add zone ──────────────────────────────────────────────────────────────────
-- New zones are always created as polygons (points captured from the
-- /safezones panel — on foot or via freecam). Legacy circle zones can still
-- be viewed/deleted from the panel but aren't created through this path.
RegisterNetEvent('mnc-safezones:addSafeZone')
AddEventHandler('mnc-safezones:addSafeZone', function(data)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then return end

    local name   = tostring(data.name or 'Unnamed')
    local height = tonumber(data.height) or Config.DefaultHeightRange or 20.0

    local points = {}
    for _, p in ipairs(data.points or {}) do
        local x, y, z = tonumber(p.x), tonumber(p.y), tonumber(p.z)
        if x and y and z then
            table.insert(points, { x = x, y = y, z = z })
        end
    end

    local minPoints = Config.MinZonePoints or 4
    if #points < minPoints then
        TriggerClientEvent('ox_lib:notify', src, {
            title       = 'Safe Zone',
            description = ('At least %d points are required (got %d)'):format(minPoints, #points),
            type        = 'error'
        })
        return
    end

    MySQL.insert(
        'INSERT INTO mnc_safezones (name, points, height) VALUES (?,?,?)',
        { name, json.encode(points), height },
        function(insertId)
            if insertId then
                local zone = { id = insertId, name = name, shape = 'poly', points = points, height = height }
                table.insert(SafeZones, zone)
                TriggerClientEvent('mnc-safezones:receiveSafeZones', -1, SafeZones)
                TriggerClientEvent('ox_lib:notify', src, { title = 'Safe Zone', description = 'Zone "' .. name .. '" created', type = 'success' })
            end
        end
    )
end)

-- ─── Update (edit) zone ──────────────────────────────────────────────────────
-- Works for both existing polygon zones and legacy circle zones — either way
-- the result is saved as a polygon, since that's what the panel's point
-- tools (capture position, freecam, manual entry) all operate on. Editing a
-- legacy circle effectively upgrades it to a polygon at that point; any
-- legacy zone nobody chooses to edit is left completely untouched.
RegisterNetEvent('mnc-safezones:updateSafeZone')
AddEventHandler('mnc-safezones:updateSafeZone', function(data)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then return end

    local id = tonumber(data.id)
    if not id then return end

    local name   = tostring(data.name or 'Unnamed')
    local height = tonumber(data.height) or Config.DefaultHeightRange or 20.0

    local points = {}
    for _, p in ipairs(data.points or {}) do
        local x, y, z = tonumber(p.x), tonumber(p.y), tonumber(p.z)
        if x and y and z then
            table.insert(points, { x = x, y = y, z = z })
        end
    end

    local minPoints = Config.MinZonePoints or 4
    if #points < minPoints then
        TriggerClientEvent('ox_lib:notify', src, {
            title       = 'Safe Zone',
            description = ('At least %d points are required (got %d)'):format(minPoints, #points),
            type        = 'error'
        })
        return
    end

    MySQL.update(
        'UPDATE mnc_safezones SET name = ?, points = ?, height = ?, center_x = NULL, center_y = NULL, center_z = NULL, radius = NULL WHERE id = ?',
        { name, json.encode(points), height, id },
        function(affected)
            if affected and affected > 0 then
                for i, zone in ipairs(SafeZones) do
                    if zone.id == id then
                        SafeZones[i] = { id = id, name = name, shape = 'poly', points = points, height = height }
                        break
                    end
                end
                TriggerClientEvent('mnc-safezones:receiveSafeZones', -1, SafeZones)
                TriggerClientEvent('ox_lib:notify', src, { title = 'Safe Zone', description = 'Zone "' .. name .. '" updated', type = 'success' })
            else
                TriggerClientEvent('ox_lib:notify', src, { title = 'Safe Zone', description = 'Zone not found', type = 'error' })
            end
        end
    )
end)

-- ─── Remove zone ───────────────────────────────────────────────────────────────
-- Works the same for both legacy circle zones and new polygon zones — deletes
-- by id regardless of which columns the row actually uses.
RegisterNetEvent('mnc-safezones:removeSafeZone')
AddEventHandler('mnc-safezones:removeSafeZone', function(id)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then return end

    id = tonumber(id)
    MySQL.update('DELETE FROM mnc_safezones WHERE id = ?', { id }, function(affected)
        if affected and affected > 0 then
            for i = #SafeZones, 1, -1 do
                if SafeZones[i].id == id then
                    local zoneName = SafeZones[i].name
                    table.remove(SafeZones, i)
                    TriggerClientEvent('mnc-safezones:receiveSafeZones', -1, SafeZones)
                    TriggerClientEvent('ox_lib:notify', src, { title = 'Safe Zone', description = 'Zone "' .. zoneName .. '" removed', type = 'success' })
                    break
                end
            end
        end
    end)
end)

print("^2[mnc-safezones]^7 Script loaded successfully!")