local QBCore = exports['qb-core']:GetCoreObject()


MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `mnc_driftzones` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `name` varchar(100) NOT NULL,
            `points` longtext NOT NULL,
            `thickness` float NOT NULL DEFAULT 40,
            `created_by` varchar(50) DEFAULT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function()
        print("^2[mnc-driftzones]^7 mnc_driftzones table checked/created successfully!")
    end)
end)


local function Notify(src, text, ntype)
    TriggerClientEvent('ox_lib:notify', src, {
        description = text,
        type = ntype,
    })
end



local function ParseMetadata(metaRaw)
    if not metaRaw then return {} end
    if type(metaRaw) == 'table' then return metaRaw end
    if type(metaRaw) == 'string' and metaRaw:find('{') then
        local ok, decoded = pcall(json.decode, metaRaw)
        if ok and decoded then return decoded end
    end
    return {}
end

local function HasZonePermission(src)
    -- 1) QBCore's own permission check
    if QBCore.Functions.HasPermission(src, Config.AdminPermission) then
        return true
    end

    -- 2) Fall back to the player's group directly (covers servers where
    --    HasPermission isn't wired up to match Config.AdminPermission)
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local group = Player.PlayerData.group
        if not group or group == '' then
            local meta = ParseMetadata(Player.PlayerData.metadata)
            group = meta.group or meta.permission or meta.role
        end
        if group == Config.AdminPermission or group == 'god' then
            return true
        end
    end

    -- 3) Fall back to ACE permissions, in case access is managed through
    --    principals/ace instead of (or in addition to) QBCore groups
    local aceCommand = Config.AdminAce or 'command.driftzones'
    if IsPlayerAceAllowed(tostring(src), aceCommand) then return true end
    if IsPlayerAceAllowed(tostring(src), 'group.' .. Config.AdminPermission) then return true end

    return false
end


QBCore.Functions.CreateCallback('mnc-driftzones:hasPermission', function(source, cb)
    cb(HasZonePermission(source))
end)



RegisterNetEvent('mnc-driftzones:server:checkAdmin', function()
    local src = source

    if not HasZonePermission(src) then
        Notify(src, 'You do not have permission to do that', 'error')
        return
    end

    TriggerClientEvent('mnc-driftzones:client:openMenu', src)
end)


QBCore.Functions.CreateCallback('mnc-driftzones:getZones', function(source, cb)
    MySQL.Async.fetchAll('SELECT id, name, points, thickness FROM mnc_driftzones', {}, function(rows)
        local zones = {}

        for _, row in ipairs(rows or {}) do
            local ok, points = pcall(json.decode, row.points)
            zones[#zones + 1] = {
                id = row.id,
                name = row.name,
                points = ok and points or {},
                thickness = tonumber(row.thickness) or Config.DefaultThickness,
            }
        end

        cb(zones)
    end)
end)


RegisterNetEvent('mnc-driftzones:server:saveZone', function(name, points, thickness)
    local src = source

    if not HasZonePermission(src) then
        Notify(src, 'You do not have permission to create drift zones', 'error')
        return
    end

    if type(name) ~= 'string' or name:gsub('%s+', '') == '' then
        Notify(src, 'Invalid zone name', 'error')
        return
    end

    if type(points) ~= 'table' or #points < (Config.MinZonePoints or 3) then
        Notify(src, ('A drift zone needs at least %d points'):format(Config.MinZonePoints or 3), 'error')
        return
    end

    -- Basic sanity check on each point's shape
    for _, p in ipairs(points) do
        if type(p) ~= 'table' or type(p.x) ~= 'number' or type(p.y) ~= 'number' or type(p.z) ~= 'number' then
            Notify(src, 'Invalid zone point data', 'error')
            return
        end
    end

    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player and Player.PlayerData.citizenid or nil

    thickness = tonumber(thickness) or Config.DefaultThickness

    MySQL.Async.insert('INSERT INTO mnc_driftzones (name, points, thickness, created_by) VALUES (?, ?, ?, ?)', {
        name, json.encode(points), thickness, citizenid
    }, function(insertId)
        if not insertId then
            Notify(src, 'Failed to save drift zone', 'error')
            return
        end

        local zone = {
            id = insertId,
            name = name,
            points = points,
            thickness = thickness,
        }

        Notify(src, ('Drift zone "%s" saved!'):format(name), 'success')
        TriggerClientEvent('mnc-driftzones:client:zoneAdded', -1, zone)
    end)
end)


local function BroadcastZoneRow(zoneId)
    MySQL.Async.fetchAll('SELECT id, name, points, thickness FROM mnc_driftzones WHERE id = ?', { zoneId }, function(rows)
        local row = rows and rows[1]
        if not row then return end

        local ok, points = pcall(json.decode, row.points)
        TriggerClientEvent('mnc-driftzones:client:zoneAdded', -1, {
            id = row.id,
            name = row.name,
            points = ok and points or {},
            thickness = tonumber(row.thickness) or Config.DefaultThickness,
        })
    end)
end

RegisterNetEvent('mnc-driftzones:server:updateZoneMeta', function(zoneId, name, thickness)
    local src = source

    if not HasZonePermission(src) then
        Notify(src, 'You do not have permission to edit drift zones', 'error')
        return
    end

    zoneId = tonumber(zoneId)
    if not zoneId then return end

    if type(name) ~= 'string' or name:gsub('%s+', '') == '' then
        Notify(src, 'Invalid zone name', 'error')
        return
    end

    thickness = tonumber(thickness) or Config.DefaultThickness

    MySQL.Async.execute('UPDATE mnc_driftzones SET name = ?, thickness = ? WHERE id = ?', {
        name, thickness, zoneId
    }, function(rowsChanged)
        if rowsChanged and rowsChanged > 0 then
            Notify(src, ('Zone "%s" updated'):format(name), 'success')
            BroadcastZoneRow(zoneId)
        else
            Notify(src, 'Zone not found', 'error')
        end
    end)
end)

RegisterNetEvent('mnc-driftzones:server:updateZonePoints', function(zoneId, points)
    local src = source

    if not HasZonePermission(src) then
        Notify(src, 'You do not have permission to edit drift zones', 'error')
        return
    end

    zoneId = tonumber(zoneId)
    if not zoneId then return end

    if type(points) ~= 'table' or #points < (Config.MinZonePoints or 3) then
        Notify(src, ('A drift zone needs at least %d points'):format(Config.MinZonePoints or 3), 'error')
        return
    end

    for _, p in ipairs(points) do
        if type(p) ~= 'table' or type(p.x) ~= 'number' or type(p.y) ~= 'number' or type(p.z) ~= 'number' then
            Notify(src, 'Invalid zone point data', 'error')
            return
        end
    end

    MySQL.Async.execute('UPDATE mnc_driftzones SET points = ? WHERE id = ?', {
        json.encode(points), zoneId
    }, function(rowsChanged)
        if rowsChanged and rowsChanged > 0 then
            Notify(src, 'Zone shape updated', 'success')
            BroadcastZoneRow(zoneId)
        else
            Notify(src, 'Zone not found', 'error')
        end
    end)
end)

RegisterNetEvent('mnc-driftzones:server:deleteZone', function(zoneId)
    local src = source

    if not HasZonePermission(src) then
        Notify(src, 'You do not have permission to delete drift zones', 'error')
        return
    end

    zoneId = tonumber(zoneId)
    if not zoneId then return end

    MySQL.Async.execute('DELETE FROM mnc_driftzones WHERE id = ?', { zoneId }, function(rowsChanged)
        if rowsChanged and rowsChanged > 0 then
            Notify(src, 'Drift zone removed', 'success')
            TriggerClientEvent('mnc-driftzones:client:zoneRemoved', -1, zoneId)
        else
            Notify(src, 'Zone not found', 'error')
        end
    end)
end)

print("^2[mnc-driftzones]^7 Script loaded successfully!")