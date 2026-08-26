local QBCore = exports['qb-core']:GetCoreObject()

-- Create mnc_weapon_ui_styles table if it doesn't exist
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `mnc_weapon_ui_styles` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `style` int(11) NOT NULL DEFAULT 1,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function(rowsChanged)
        print("^2[mnc-weaponui]^7 mnc_weapon_ui_styles table checked/created successfully!")
    end)
end)

-- Get player's weapon UI style from database
QBCore.Functions.CreateCallback('mnc-weaponui:getStyle', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        print("[mnc-weaponui] No player found for source: " .. source)
        cb(Config.DefaultStyle)
        return 
    end

    local citizenid = Player.PlayerData and Player.PlayerData.citizenid or Player.citizenid
    if not citizenid then
        print("[mnc-weaponui] Error: Could not get citizenid for source: " .. source)
        cb(Config.DefaultStyle)
        return
    end
    
    MySQL.Async.fetchScalar('SELECT style FROM mnc_weapon_ui_styles WHERE citizenid = ?', {citizenid}, function(result)
        if result then
            print("[mnc-weaponui] Fetched style for citizenid " .. citizenid .. ": " .. result)
            cb(result)
        else
            print("[mnc-weaponui] No style found for citizenid " .. citizenid .. ", inserting default")
            MySQL.Async.insert('INSERT INTO mnc_weapon_ui_styles (citizenid, style) VALUES (?, ?)', {
                citizenid, Config.DefaultStyle
            }, function(insertId)
                cb(Config.DefaultStyle)
            end)
        end
    end)
end)

-- Save player's weapon UI style to database
RegisterNetEvent('mnc-weaponui:saveStyle', function(style)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        print("[mnc-weaponui] No player found for source: " .. src)
        return 
    end

    local citizenid = Player.PlayerData and Player.PlayerData.citizenid or Player.citizenid
    if not citizenid then
        print("[mnc-weaponui] Error: Could not get citizenid for source: " .. src)
        return
    end
    
    print("[mnc-weaponui] Saving style " .. style .. " for citizenid: " .. citizenid)
    MySQL.Async.execute('UPDATE mnc_weapon_ui_styles SET style = ? WHERE citizenid = ?', {
        style, citizenid
    }, function(affectedRows)
        if affectedRows == 0 then
            print("[mnc-weaponui] No rows updated, inserting new style for citizenid: " .. citizenid)
            MySQL.Async.insert('INSERT INTO mnc_weapon_ui_styles (citizenid, style) VALUES (?, ?)', {
                citizenid, style
            })
        end
    end)
end)

print("^2[mnc-weaponUi-V3]^7 Script loaded successfully!")