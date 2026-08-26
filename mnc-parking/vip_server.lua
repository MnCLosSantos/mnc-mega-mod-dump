-- vip_server.lua
-- mnc-parking — VIP parking slot management (server side)
-- Completely standalone — does NOT touch server.lua / cover_server.lua
-- ─────────────────────────────────────────────────────────────────────────────

local QBCore = exports['qb-core']:GetCoreObject()

-- ─── In-memory cache ─────────────────────────────────────────────────────────
-- [citizenid] = { maxSlots = N, expiresAt = ISO-string | nil, cost = N }
local vipCache = {}

-- ─── DB bootstrap ────────────────────────────────────────────────────────────
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end
    Wait(1500)

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mnc_parking_vip` (
            `id`          INT          NOT NULL AUTO_INCREMENT,
            `citizenid`   VARCHAR(50)  NOT NULL,
            `max_slots`   INT          NOT NULL DEFAULT 10,
            `cost`        INT          NOT NULL DEFAULT 0,
            `granted_by`  VARCHAR(50)  NOT NULL DEFAULT 'system',
            `note`        VARCHAR(255) DEFAULT NULL,
            `expires_at`  DATETIME     DEFAULT NULL,
            `granted_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
            `updated_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_citizen` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    -- Pre-load all active VIP rows into cache
    local rows = MySQL.query.await([[
        SELECT `citizenid`, `max_slots`, `cost`
        FROM `mnc_parking_vip`
        WHERE `expires_at` IS NULL OR `expires_at` > NOW()
    ]])
    if rows then
        for _, row in ipairs(rows) do
            vipCache[row.citizenid] = {
                maxSlots = row.max_slots,
                cost     = row.cost,
            }
        end
        print('^2[mnc-parking]^7 VIP: loaded ' .. #rows .. ' VIP record(s).')
    end
end)

-- ─── Public helper (used by server.lua's GetMaxVehiclesOut) ──────────────────
-- Returns the VIP max-slots for a citizenid, or nil if not VIP.
function GetVipMaxSlots(citizenid)
    local entry = vipCache[citizenid]
    if not entry then return nil end
    return entry.maxSlots
end

-- ─── Resolve server ID or citizenid → citizenid + display name ───────────────
-- Accepts: a numeric string like "5" (online server ID) or a raw citizenid.
-- Returns: citizenid (string), displayName (string), errorMsg (string|nil)
local function ResolveToCitizenId(input)
    input = tostring(input or ''):gsub('%s+', '')
    if input == '' then return nil, nil, 'Input is empty.' end

    -- If it looks like a pure number, treat it as a server ID first
    local serverId = tonumber(input)
    if serverId then
        local P = QBCore.Functions.GetPlayer(serverId)
        if P then
            local ci  = P.PlayerData.citizenid
            local inf = P.PlayerData.charinfo or {}
            local name = (((inf.firstname or '') .. ' ' .. (inf.lastname or '')):gsub('^%s*(.-)%s*$', '%1'))
            if name == '' then name = ci end
            return ci, name .. ' (ID ' .. serverId .. ')', nil
        end
        -- Server ID supplied but player not online — fall through and try DB
        -- (unlikely, but handle gracefully)
        return nil, nil, ('No player online with server ID %d.'):format(serverId)
    end

    -- Not a number — treat as citizenid, look up in DB (works offline too)
    local row = MySQL.query.await(
        'SELECT `citizenid`, `charinfo` FROM `players` WHERE `citizenid` = ? LIMIT 1',
        { input })
    if not row or not row[1] then
        return nil, nil, 'No player found for "' .. input .. '".'
    end

    local ci       = row[1].citizenid
    local charInfo = row[1].charinfo
    local name     = ci
    if charInfo then
        local ok, decoded = pcall(json.decode, charInfo)
        if ok and decoded then
            local n = (((decoded.firstname or '') .. ' ' .. (decoded.lastname or '')):gsub('^%s*(.-)%s*$', '%1'))
            if n ~= '' then name = n end
        end
    end
    return ci, name, nil
end

-- ─── Callback: check own VIP status ─────────────────────────────────────────
lib.callback.register('mnc-parking:getVipStatus', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    local citizenid = Player.PlayerData.citizenid

    local row = MySQL.query.await([[
        SELECT `max_slots`, `cost`, `expires_at`, `granted_at`, `note`
        FROM `mnc_parking_vip`
        WHERE `citizenid` = ?
          AND (`expires_at` IS NULL OR `expires_at` > NOW())
        LIMIT 1
    ]], { citizenid })

    if not row or not row[1] then return nil end
    return row[1]
end)

-- ─── Callback: buy VIP (player-initiated via command, cost deducted) ─────────
-- Returns ok (bool), message (string)
lib.callback.register('mnc-parking:buyVip', function(source, targetCitizenId, maxSlots, cost)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false, 'Player not found.' end

    -- Admin-only: only admins may grant VIP to others; everyone may check their own
    if not QBCore.Functions.HasPermission(source, 'admin') then
        return false, 'You do not have permission to grant VIP parking.'
    end

    maxSlots = math.max(1, math.min(tonumber(maxSlots) or 10, 100))
    cost     = math.max(0, tonumber(cost) or 0)

    -- Resolve server ID or citizenid → canonical citizenid + display name
    local resolvedCid, targetName, resolveErr = ResolveToCitizenId(targetCitizenId)
    if resolveErr then return false, resolveErr end

    local adminCitizenId = Player.PlayerData.citizenid

    -- Deduct cost from admin's cash if cost > 0 (grants are usually free from admin panel,
    -- but the field is stored for record-keeping / future player-purchase flow)
    if cost > 0 then
        local cash = Player.PlayerData.money.cash or 0
        if cash < cost then
            return false, ('Insufficient funds. You need $%s.'):format(cost)
        end
        Player.Functions.RemoveMoney('cash', cost, 'mnc-parking-vip-grant')
    end

    MySQL.query.await([[
        INSERT INTO `mnc_parking_vip` (`citizenid`, `max_slots`, `cost`, `granted_by`)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `max_slots`  = VALUES(`max_slots`),
            `cost`       = VALUES(`cost`),
            `granted_by` = VALUES(`granted_by`),
            `expires_at` = NULL,
            `updated_at` = CURRENT_TIMESTAMP
    ]], { resolvedCid, maxSlots, cost, adminCitizenId })

    -- Update cache
    vipCache[resolvedCid] = { maxSlots = maxSlots, cost = cost }

    -- Notify the target if they are online
    local targetSrc = nil
    for _, src in ipairs(GetPlayers()) do
        local P = QBCore.Functions.GetPlayer(tonumber(src))
        if P and P.PlayerData.citizenid == resolvedCid then
            targetSrc = tonumber(src)
            break
        end
    end
    if targetSrc then
        TriggerClientEvent('mnc-parking:notify', targetSrc, {
            title       = 'VIP Parking',
            description = ('Your parking slots have been upgraded to %d!'):format(maxSlots),
            type        = 'success',
            duration    = 8000,
        })
    end

    print(('[mnc-parking] VIP granted: citizenid=%s name=%s slots=%d by=%s')
          :format(resolvedCid, targetName, maxSlots, adminCitizenId))

    return true, ('VIP parking granted to %s — %d slots.'):format(targetName, maxSlots)
end)

-- ─── Callback: revoke VIP ────────────────────────────────────────────────────
lib.callback.register('mnc-parking:revokeVip', function(source, targetCitizenId)
    if not QBCore.Functions.HasPermission(source, 'admin') then
        return false, 'Permission denied.'
    end

    -- targetCitizenId coming from the list panel is always a real cid,
    -- but run through the resolver anyway for safety
    local resolvedCid, _, resolveErr = ResolveToCitizenId(targetCitizenId)
    if resolveErr then return false, resolveErr end

    MySQL.query.await(
        'DELETE FROM `mnc_parking_vip` WHERE `citizenid` = ?',
        { resolvedCid })
    vipCache[resolvedCid] = nil

    -- Notify target if online
    for _, src in ipairs(GetPlayers()) do
        local P = QBCore.Functions.GetPlayer(tonumber(src))
        if P and P.PlayerData.citizenid == resolvedCid then
            TriggerClientEvent('mnc-parking:notify', tonumber(src), {
                title       = 'VIP Parking',
                description = 'Your VIP parking status has been removed.',
                type        = 'warning',
                duration    = 6000,
            })
            break
        end
    end

    return true, 'VIP parking revoked for ' .. resolvedCid
end)

-- ─── Callback: list all VIP records (admin panel) ────────────────────────────
lib.callback.register('mnc-parking:listVip', function(source)
    if not QBCore.Functions.HasPermission(source, 'admin') then return {} end

    local rows = MySQL.query.await([[
        SELECT `citizenid`, `max_slots`, `cost`, `granted_by`, `granted_at`,
               `expires_at`, `note`
        FROM `mnc_parking_vip`
        WHERE `expires_at` IS NULL OR `expires_at` > NOW()
        ORDER BY `granted_at` DESC
        LIMIT 100
    ]])
    return rows or {}
end)

-- ─── Console / in-game admin command: /vipparking ────────────────────────────
-- Usage (in-game, admin only): opens the ox_lib modal on the client side
-- This command just triggers the client to open its UI.
-- Actual granting happens through the mnc-parking:buyVip callback above.
RegisterCommand('parkvip', function(source, args)
    if source == 0 then
        -- Console usage: parkvip <serverID|citizenid> <slots>
        local input = args[1]
        local slots = tonumber(args[2]) or 10
        if not input then
            print('[mnc-parking] Usage: parkvip <serverID|citizenid> <slots>')
            return
        end
        local resolvedCid, displayName, resolveErr = ResolveToCitizenId(input)
        if resolveErr then
            print('[mnc-parking] ' .. resolveErr); return
        end
        MySQL.query.await([[
            INSERT INTO `mnc_parking_vip` (`citizenid`, `max_slots`, `cost`, `granted_by`)
            VALUES (?, ?, 0, 'console')
            ON DUPLICATE KEY UPDATE
                `max_slots`  = VALUES(`max_slots`),
                `granted_by` = 'console',
                `expires_at` = NULL,
                `updated_at` = CURRENT_TIMESTAMP
        ]], { resolvedCid, slots })
        vipCache[resolvedCid] = { maxSlots = slots, cost = 0 }
        print(('[mnc-parking] VIP granted via console: cid=%s name=%s slots=%d')
              :format(resolvedCid, displayName, slots))
        return
    end

    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('mnc-parking:notify', source, {
            title='VIP Parking', description='Permission denied.', type='error' })
        return
    end
    -- Tell the admin client to open the VIP modal
    TriggerClientEvent('mnc-parking:openVipPanel', source)
end, true)