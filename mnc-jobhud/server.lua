local QBCore = exports['qb-core']:GetCoreObject()

-- Create mnc_hud_styles table if it doesn't exist
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `mnc_hud_styles` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `style` int(11) NOT NULL DEFAULT 1,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(rowsChanged)
        print("^2[mnc-jobhud]^7 mnc_hud_styles table checked/created successfully!")
    end)
end)

-- Get player's HUD style from database
QBCore.Functions.CreateCallback('mnc-hud:getStyle', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb(Config.DefaultStyle)
        return 
    end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then
        print("[mnc-jobhud] Error: Could not get citizenid from player object")
        cb(Config.DefaultStyle)
        return
    end
    
    MySQL.Async.fetchScalar('SELECT style FROM mnc_hud_styles WHERE citizenid = ?', {citizenid}, function(result)
        if result then
            cb(result)
        else
            -- Insert default style for new player
            MySQL.Async.insert('INSERT INTO mnc_hud_styles (citizenid, style) VALUES (?, ?)', {
                citizenid, Config.DefaultStyle
            }, function(insertId)
                cb(Config.DefaultStyle)
            end)
        end
    end)
end)

-- NEW: Get total player count from server (reliable, no proximity issues)
QBCore.Functions.CreateCallback('mnc-hud:getPlayerCount', function(source, cb)
    local totalPlayers = #QBCore.Functions.GetPlayers()
    cb(totalPlayers)
end)

-- Save player's HUD style to database
RegisterNetEvent('mnc-hud:saveStyle', function(style)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then
        print("[mnc-jobhud] Error: Could not get citizenid from player object")
        return
    end
    
    MySQL.Async.execute('UPDATE mnc_hud_styles SET style = ? WHERE citizenid = ?', {
        style, citizenid
    }, function(affectedRows)
        if affectedRows == 0 then
            -- Insert if update didn't affect any rows (player not in database)
            MySQL.Async.insert('INSERT INTO mnc_hud_styles (citizenid, style) VALUES (?, ?)', {
                citizenid, style
            })
        end
    end)
end)

print("^2[mnc-jobhud]^7 Script loaded successfully!")