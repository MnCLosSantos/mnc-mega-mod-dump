-- ============================================================
--  MNC Custom Plate - Server
-- ============================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================================
--  Register usable item
-- ============================================================

QBCore.Functions.CreateUseableItem(Config.Item, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    TriggerClientEvent('mnc-customplate:client:openUI', source, false)
end)

print("[mnc-customplate] Registered usable item: " .. Config.Item)

-- ============================================================
--  Helpers
-- ============================================================

local function IsAdmin(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local perms = QBCore.Functions.GetPermission(source)

    for _, allowed in ipairs(Config.AdminGroups or {}) do
        if perms[allowed] then return true end
    end

    for _, allowed in ipairs(Config.AdminGroups or {}) do
        if IsPlayerAceAllowed(source, 'group.' .. allowed) then return true end
    end

    return false
end

local function HasJobAccess(source)
    if not Config.JobLock then return true end
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    local job = Player.PlayerData.job
    return job.name == Config.JobLock.name and job.grade.level >= Config.JobLock.grade
end

local function HasItem(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    return Player.Functions.GetItemByName(Config.Item) ~= nil
end

local function RemoveItem(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        Player.Functions.RemoveItem(Config.Item, 1)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[Config.Item], 'remove')
    end
end

-- ============================================================
--  Duplicate Plate Check (ignores spacing)
-- ============================================================

local function IsPlateAvailable(plate, cb)
    local target = plate:upper():gsub("%s+", "")

    MySQL.query([[
        SELECT 1
        FROM player_vehicles
        WHERE REPLACE(UPPER(plate), ' ', '') = ?
        LIMIT 1
    ]], { target }, function(result)
        cb(result == nil or #result == 0)
    end)
end

-- ============================================================
--  Net Events
-- ============================================================

RegisterNetEvent('mnc-customplate:server:adminCommand', function()
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('mnc-customplate:client:plateFailed', src, 'You do not have permission to use this command.')
        return
    end
    TriggerClientEvent('mnc-customplate:client:openUI', src, true)
end)

RegisterNetEvent('mnc-customplate:server:applyPlate', function(plateText, themeId, adminMode, currentPlateSent)
    local src = source

    if adminMode and not IsAdmin(src) then
        TriggerClientEvent('mnc-customplate:client:plateFailed', src, 'Permission denied.')
        return
    end

    if not adminMode then
        if not HasItem(src) then
            TriggerClientEvent('mnc-customplate:client:plateFailed', src, 'You do not have a Custom Plate Kit.')
            return
        end
        if not HasJobAccess(src) then
            TriggerClientEvent('mnc-customplate:client:plateFailed', src, 'Your job cannot apply custom plates.')
            return
        end
    end

    if not plateText or type(plateText) ~= 'string' then
        TriggerClientEvent('mnc-customplate:client:plateFailed', src, 'Invalid plate text.')
        return
    end

    -- Normalize for storage
    plateText = plateText:upper():gsub("%s+", " "):match("^%s*(.-)%s*$")

    local cleanLen = #plateText:gsub("%s+", "")
    if cleanLen < Config.MinPlateLength or cleanLen > Config.MaxPlateLength then
        TriggerClientEvent('mnc-customplate:client:plateFailed', src,
            ('Plate must be %d–%d characters (spaces allowed).'):format(Config.MinPlateLength, Config.MaxPlateLength))
        return
    end

    if not plateText:match('^[A-Z0-9 ]+$') then
        TriggerClientEvent('mnc-customplate:client:plateFailed', src, 'Plate contains invalid characters.')
        return
    end

    -- Validate the current plate sent from client
    if not currentPlateSent or type(currentPlateSent) ~= 'string' then
        TriggerClientEvent('mnc-customplate:client:plateFailed', src, 'Could not determine target vehicle.')
        return
    end

    local currentPlate = currentPlateSent:upper():match("^%s*(.-)%s*$")

    if plateText == currentPlate then
        TriggerClientEvent('mnc-customplate:client:plateFailed', src, 'This is already your current plate.')
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        TriggerClientEvent('mnc-customplate:client:plateFailed', src, 'Player data error.')
        return
    end
    local citizenid = Player.PlayerData.citizenid

    IsPlateAvailable(plateText, function(available)
        if not available then
            TriggerClientEvent('mnc-customplate:client:plateFailed', src, 'That plate is already taken!')
            return
        end

        -- Fetch the existing vehicle row so we can re-insert it with the new plate
        MySQL.query(
            'SELECT * FROM player_vehicles WHERE UPPER(REPLACE(plate, \' \', \'\')) = ? AND citizenid = ? LIMIT 1',
            { currentPlate:gsub("%s+", ""), citizenid },
            function(rows)
                if not rows or #rows == 0 then
                    -- Vehicle not in DB (spawned/temp) — just apply visually
                    if not adminMode then RemoveItem(src) end
                    TriggerClientEvent('mnc-customplate:client:plateApplied', src, plateText)
                    print(('[MNC-CustomPlate] %s applied plate %s (vehicle not in DB)'):format(GetPlayerName(src), plateText))
                    return
                end

                local row = rows[1]

                -- Delete old record
                MySQL.query(
                    'DELETE FROM player_vehicles WHERE UPPER(REPLACE(plate, \' \', \'\')) = ? AND citizenid = ? LIMIT 1',
                    { currentPlate:gsub("%s+", ""), citizenid },
                    function()
                        -- Re-insert with new plate, reset state to 1 (in garage) and strip mods
                        -- We intentionally reset mods to '{}' — the player was warned in the UI
                        MySQL.query([[
                            INSERT INTO player_vehicles
                            (license, citizenid, vehicle, hash, mods, plate, fakeplate, state, garage, fuel, engine, body, depotprice, drivingdistance, status, balance, paymentamount, paymentsleft, financetime)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        ]], {
                            row.license,
                            row.citizenid,
                            row.vehicle,
                            row.hash,
                            '{}',                     -- mods wiped (player warned)
                            plateText,                -- new plate
                            row.fakeplate or '',
                            1,                        -- force state = in garage so qb-garages can spawn it
                            row.garage or 'pillboxgarage',
                            row.fuel or 100,
                            row.engine or 1000.0,
                            row.body or 1000.0,
                            row.depotprice or 0,
                            row.drivingdistance or 0,
                            row.status,
                            row.balance or 0,
                            row.paymentamount or 0,
                            row.paymentsleft or 0,
                            row.financetime or 0,
                        }, function(insertResult)
                            if not adminMode then RemoveItem(src) end

                            if insertResult then
                                TriggerClientEvent('mnc-customplate:client:plateApplied', src, plateText)
                                print(('[MNC-CustomPlate] %s changed plate %s → %s (DB re-inserted)'):format(GetPlayerName(src), currentPlate, plateText))
                            else
                                TriggerClientEvent('mnc-customplate:client:plateFailed', src, 'Database error during plate swap. Contact an admin.')
                                print(('[MNC-CustomPlate] ERROR: Failed to re-insert vehicle for %s'):format(GetPlayerName(src)))
                            end
                        end)
                    end
                )
            end
        )
    end)
end)

-- Warning if item missing
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if not QBCore.Shared.Items[Config.Item] then
        print('[MNC-CustomPlate] WARNING: Item "' .. Config.Item .. '" not found in qb-core/shared/items.lua')
    end
end)

print("^2[mnc-customplate]^7 Script loaded successfully!")