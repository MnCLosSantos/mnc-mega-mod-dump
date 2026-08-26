-- server.lua
local QBCore = exports['qb-core']:GetCoreObject()

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `mnc_drift_styles` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `style` int(11) NOT NULL DEFAULT 1,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(rowsChanged)
        print("^2[mnc-driftscore]^7 mnc_drift_styles table checked/created successfully!")
    end)

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `mnc_driftscore_leaderboard` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `player_name` varchar(100) NOT NULL DEFAULT 'Unknown',
            `period` enum('weekly','monthly','alltime') NOT NULL,
            `score` int(11) NOT NULL DEFAULT 0,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `citizenid_period` (`citizenid`, `period`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(rowsChanged)
        print("^2[mnc-driftscore]^7 mnc_driftscore_leaderboard table checked/created successfully!")
    end)

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `mnc_driftscore_meta` (
            `meta_key` varchar(50) NOT NULL,
            `meta_value` varchar(100) NOT NULL,
            PRIMARY KEY (`meta_key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(rowsChanged)
        print("^2[mnc-driftscore]^7 mnc_driftscore_meta table checked/created successfully!")
    end)

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `mnc_driftscore_players` (
            `citizenid` varchar(50) NOT NULL,
            `reputation` int(11) NOT NULL DEFAULT 0,
            `coins` int(11) NOT NULL DEFAULT 0,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(rowsChanged)
        print("^2[mnc-driftscore]^7 mnc_driftscore_players table checked/created successfully!")
    end)

    -- Small delay so the tables above exist before we start reading/writing meta rows
    Citizen.SetTimeout(1000, function()
        InitLeaderboardResets()
    end)
end)

QBCore.Functions.CreateCallback('mnc-driftscore:getStyle', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb(Config.DefaultStyle)
        return 
    end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then
        cb(Config.DefaultStyle)
        return
    end
    
    MySQL.Async.fetchScalar('SELECT style FROM mnc_drift_styles WHERE citizenid = ?', {citizenid}, function(result)
        if result then
            cb(result)
        else
            MySQL.Async.insert('INSERT INTO mnc_drift_styles (citizenid, style) VALUES (?, ?)', {
                citizenid, Config.DefaultStyle
            }, function(insertId)
                cb(Config.DefaultStyle)
            end)
        end
    end)
end)

RegisterNetEvent('mnc-driftscore:saveStyle', function(style)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end
    
    MySQL.Async.execute('UPDATE mnc_drift_styles SET style = ? WHERE citizenid = ?', {
        style, citizenid
    }, function(affectedRows)
        if affectedRows == 0 then
            MySQL.Async.insert('INSERT INTO mnc_drift_styles (citizenid, style) VALUES (?, ?)', {
                citizenid, style
            })
        end
    end)
end)

--------------------------------------------------------------------------------
-- LEADERBOARD
--------------------------------------------------------------------------------

local PERIODS = { 'weekly', 'monthly', 'alltime' }

local function GetPlayerDisplayName(Player)
    local charinfo = Player.PlayerData.charinfo or {}
    local name = ((charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then
        name = GetPlayerName(Player.PlayerData.source) or 'Unknown'
    end
    return name
end

-- Player submits a new score (called whenever their running total increases)
RegisterNetEvent('mnc-driftscore:submitScore', function(score)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    score = tonumber(score)
    if not score or score < (Config.Leaderboard.MinScoreToSubmit or 0) then return end
    score = math.floor(score)

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end

    local playerName = GetPlayerDisplayName(Player)

    for _, period in ipairs(PERIODS) do
        MySQL.Async.execute([[
            INSERT INTO mnc_driftscore_leaderboard (citizenid, player_name, period, score)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                score = GREATEST(score, VALUES(score)),
                player_name = VALUES(player_name)
        ]], { citizenid, playerName, period, score })
    end
end)

-- Fetch weekly/monthly/alltime boards + reset countdowns in one round trip
QBCore.Functions.CreateCallback('mnc-driftscore:getLeaderboardData', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player and Player.PlayerData.citizenid or nil

    local result = { weekly = {}, monthly = {}, alltime = {}, resets = {} }

    MySQL.Async.fetchAll('SELECT meta_key, meta_value FROM mnc_driftscore_meta', {}, function(metaRows)
        for _, row in ipairs(metaRows or {}) do
            result.resets[row.meta_key] = tonumber(row.meta_value)
        end

        local remaining = #PERIODS

        for _, period in ipairs(PERIODS) do
            MySQL.Async.fetchAll([[
                SELECT citizenid, player_name, score FROM mnc_driftscore_leaderboard
                WHERE period = ? ORDER BY score DESC LIMIT ?
            ]], { period, Config.Leaderboard.DisplayCount }, function(rows)
                result[period] = rows or {}

                if citizenid then
                    MySQL.Async.fetchAll([[
                        SELECT COUNT(*) + 1 as rank, (
                            SELECT score FROM mnc_driftscore_leaderboard WHERE citizenid = ? AND period = ?
                        ) as score
                        FROM mnc_driftscore_leaderboard
                        WHERE period = ? AND score > (
                            SELECT score FROM mnc_driftscore_leaderboard WHERE citizenid = ? AND period = ?
                        )
                    ]], { citizenid, period, period, citizenid, period }, function(rankRows)
                        local rankRow = rankRows and rankRows[1]
                        if rankRow and rankRow.score ~= nil then
                            result.resets[period .. '_your_rank'] = rankRow.rank
                            result.resets[period .. '_your_score'] = rankRow.score
                        end

                        remaining = remaining - 1
                        if remaining == 0 then
                            cb(result)
                        end
                    end)
                else
                    remaining = remaining - 1
                    if remaining == 0 then
                        cb(result)
                    end
                end
            end)
        end
    end)
end)

--------------------------------------------------------------------------------
-- REPUTATION & DRIFT COINS
--------------------------------------------------------------------------------
-- Persistent per-citizenid currency. Reputation is earned whenever a chain is
-- SAVED (banked, not lost to a crash/spin-out reset): every Config.Reputation
-- .PointsPerRP points of a saved chain earns 1 Reputation. Every
-- Config.Reputation.RPPerCoin Reputation earned also grants 1 Drift Coin,
-- which players can spend in the driftboard Store tab. Neither value is an
-- inventory item - both live purely in the database + UI.

local function GetOrCreatePlayerCurrency(citizenid, cb)
    MySQL.Async.fetchAll('SELECT reputation, coins FROM mnc_driftscore_players WHERE citizenid = ?', {citizenid}, function(rows)
        if rows and rows[1] then
            cb({ reputation = tonumber(rows[1].reputation) or 0, coins = tonumber(rows[1].coins) or 0 })
        else
            MySQL.Async.insert('INSERT INTO mnc_driftscore_players (citizenid, reputation, coins) VALUES (?, 0, 0)', {
                citizenid
            }, function()
                cb({ reputation = 0, coins = 0 })
            end)
        end
    end)
end

QBCore.Functions.CreateCallback('mnc-driftscore:getPlayerCurrency', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not Player.PlayerData.citizenid then
        cb({ reputation = 0, coins = 0 })
        return
    end

    GetOrCreatePlayerCurrency(Player.PlayerData.citizenid, cb)
end)

-- Called when a chain is SAVED client-side (banked into the running total
-- instead of being wiped by a crash/spin-out). Awards Reputation for the
-- chain, and any Drift Coins earned by crossing an RPPerCoin milestone.
RegisterNetEvent('mnc-driftscore:bankChain', function(chainScore)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end

    chainScore = tonumber(chainScore)
    if not chainScore or chainScore <= 0 then return end
    chainScore = math.floor(chainScore)

    local pointsPerRP = (Config.Reputation and Config.Reputation.PointsPerRP) or 100
    local rpPerCoin = (Config.Reputation and Config.Reputation.RPPerCoin) or 10

    local rpEarned = math.floor(chainScore / pointsPerRP)
    if rpEarned <= 0 then return end

    GetOrCreatePlayerCurrency(citizenid, function(currency)
        local oldRP = currency.reputation
        local newRP = oldRP + rpEarned
        local coinsEarned = math.floor(newRP / rpPerCoin) - math.floor(oldRP / rpPerCoin)
        local newCoins = currency.coins + coinsEarned

        MySQL.Async.execute([[
            INSERT INTO mnc_driftscore_players (citizenid, reputation, coins) VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE reputation = VALUES(reputation), coins = VALUES(coins)
        ]], { citizenid, newRP, newCoins }, function()
            TriggerClientEvent('mnc-driftscore:currencyUpdated', src, {
                reputation = newRP,
                coins = newCoins,
                rpEarned = rpEarned,
                coinsEarned = coinsEarned
            })
        end)
    end)
end)

-- Spend Drift Coins on a Config.Store entry (inventory item or bank deposit)
QBCore.Functions.CreateCallback('mnc-driftscore:purchaseItem', function(source, cb, itemId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        cb({ success = false, message = 'Player not found' })
        return
    end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then
        cb({ success = false, message = 'No citizen ID' })
        return
    end

    local storeItem = nil
    for _, entry in ipairs(Config.Store or {}) do
        if entry.id == itemId then
            storeItem = entry
            break
        end
    end

    if not storeItem then
        cb({ success = false, message = 'Item not found' })
        return
    end

    GetOrCreatePlayerCurrency(citizenid, function(currency)
        if currency.coins < (storeItem.price or 0) then
            cb({ success = false, message = 'Not enough Drift Coins', coins = currency.coins, reputation = currency.reputation })
            return
        end

        local newCoins = currency.coins - storeItem.price

        MySQL.Async.execute('UPDATE mnc_driftscore_players SET coins = ? WHERE citizenid = ?', { newCoins, citizenid }, function()
            if storeItem.type == 'item' then
                Player.Functions.AddItem(storeItem.item, storeItem.amount or 1)
            elseif storeItem.type == 'bank' then
                Player.Functions.AddMoney('bank', storeItem.amount or 0, 'drift-store-purchase')
            end

            TriggerClientEvent('QBCore:Notify', src,
                ('Purchased %s for %d Drift Coin%s'):format(storeItem.name or storeItem.id, storeItem.price, storeItem.price == 1 and '' or 's'), 'success')

            cb({ success = true, message = 'Purchase successful', coins = newCoins, reputation = currency.reputation })
        end)
    end)
end)

--------------------------------------------------------------------------------
-- AUTOMATIC WEEKLY / MONTHLY RESET
--------------------------------------------------------------------------------

local function GetMeta(key, cb)
    MySQL.Async.fetchScalar('SELECT meta_value FROM mnc_driftscore_meta WHERE meta_key = ?', {key}, cb)
end

local function SetMeta(key, value)
    MySQL.Async.execute([[
        INSERT INTO mnc_driftscore_meta (meta_key, meta_value) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE meta_value = VALUES(meta_value)
    ]], { key, tostring(value) })
end

-- Next Monday 00:00 (server clock)
local function GetNextWeeklyReset()
    local t = os.date('*t')
    -- os wday: Sunday = 1 ... Saturday = 7. Monday = 2.
    local daysUntilMonday = (2 - t.wday + 7) % 7
    if daysUntilMonday == 0 then daysUntilMonday = 7 end
    local midnightToday = os.time({ year = t.year, month = t.month, day = t.day, hour = 0, min = 0, sec = 0 })
    return midnightToday + (daysUntilMonday * 86400)
end

-- First day of next month, 00:00 (server clock)
local function GetNextMonthlyReset()
    local t = os.date('*t')
    local month = t.month + 1
    local year = t.year
    if month > 12 then
        month = 1
        year = year + 1
    end
    return os.time({ year = year, month = month, day = 1, hour = 0, min = 0, sec = 0 })
end

-- Wipe a period's board once it rolls over (weekly/monthly). No payouts are
-- made here anymore - Reputation/Drift Coins are earned per saved chain
-- instead of leaderboard rank, see the REPUTATION & DRIFT COINS section above.
local function RolloverPeriod(period)
    MySQL.Async.execute('DELETE FROM mnc_driftscore_leaderboard WHERE period = ?', { period })
    print(('^2[mnc-driftscore]^7 %s leaderboard has been reset.'):format(period))
end

function InitLeaderboardResets()
    GetMeta('weekly_reset_at', function(value)
        if not value then
            SetMeta('weekly_reset_at', GetNextWeeklyReset())
        end
    end)

    GetMeta('monthly_reset_at', function(value)
        if not value then
            SetMeta('monthly_reset_at', GetNextMonthlyReset())
        end
    end)

    -- Check periodically whether it's time to roll a board over
    CreateThread(function()
        while true do
            Citizen.Wait(60000) -- check once a minute

            GetMeta('weekly_reset_at', function(value)
                local resetAt = tonumber(value)
                if resetAt and os.time() >= resetAt then
                    RolloverPeriod('weekly')
                    SetMeta('weekly_reset_at', GetNextWeeklyReset())
                end
            end)

            GetMeta('monthly_reset_at', function(value)
                local resetAt = tonumber(value)
                if resetAt and os.time() >= resetAt then
                    RolloverPeriod('monthly')
                    SetMeta('monthly_reset_at', GetNextMonthlyReset())
                end
            end)
        end
    end)
end

print("^2[mnc-driftscore]^7 Script loaded successfully!")