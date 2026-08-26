-- mnc-seizecar/server.lua
local QBCore = exports['qb-core']:GetCoreObject()

Config = {
    SeizeCarJob = { ['police'] = true, ['mechanic'] = false, ['mechanic2'] = false },  -- Add more jobs here if needed
}

local function Notify(src, msg, type)
    if src and src > 0 then
        TriggerClientEvent('ox_lib:notify', src, { description = msg, type = type or 'inform' })
    else
        print(('[mnc-seizecar] ' .. msg))
    end
end

local function GetCitizenIdByServerId(targetId)
    local Player = QBCore.Functions.GetPlayer(targetId)
    if Player then return Player.PlayerData.citizenid end
    local result = exports.oxmysql:executeSync("SELECT citizenid FROM players WHERE id = ?", {targetId})
    return result and result[1] and result[1].citizenid
end

-- ==================== COMMAND REGISTRATIONS ====================

QBCore.Commands.Add('removecar', 'Remove one vehicle (Admin)', {}, false, function(source)
    TriggerClientEvent('mnc-seizecar:client:removecar', source)
end, 'admin')

QBCore.Commands.Add('removeallcars', 'Remove all vehicles from a player (Admin)', {}, false, function(source)
    TriggerClientEvent('mnc-seizecar:client:removeallcars', source)
end, 'admin')

QBCore.Commands.Add('removeallcarsfromserver', 'WIPE all vehicles on server (DANGER)', {}, false, function(source)
    TriggerClientEvent('mnc-seizecar:client:removeallcarsfromserver', source)
end, 'admin')

-- Seize Car Command (Job Restricted + Modal)
QBCore.Commands.Add('seizecar', 'Seize a player\'s vehicle (Police/Allowed Jobs)', {}, false, function(source)
    TriggerClientEvent('mnc-seizecar:client:seizecar', source)
end)

-- ==================== SERVER HANDLERS ====================

RegisterNetEvent('mnc-seizecar:server:removecar', function(targetId, plate)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') and not QBCore.Functions.HasPermission(src, 'god') then 
        return Notify(src, 'No permission', 'error') 
    end

    local cid = GetCitizenIdByServerId(targetId)
    if not cid then return Notify(src, 'Player not found', 'error') end

    local result = exports.oxmysql:executeSync("DELETE FROM player_vehicles WHERE citizenid = ? AND plate = ? LIMIT 1", {cid, plate})
    local deleted = result and result.affectedRows or 0

    if deleted > 0 then
        Notify(src, ('✅ Removed plate **%s** from player %s'):format(plate, targetId), 'success')
    else
        Notify(src, ('Plate **%s** not found'):format(plate), 'error')
    end
end)

RegisterNetEvent('mnc-seizecar:server:removeallcars', function(targetId)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') and not QBCore.Functions.HasPermission(src, 'god') then 
        return Notify(src, 'No permission', 'error') 
    end

    local cid = GetCitizenIdByServerId(targetId)
    if not cid then return Notify(src, 'Player not found', 'error') end

    local result = exports.oxmysql:executeSync("DELETE FROM player_vehicles WHERE citizenid = ?", {cid})
    local count = result and result.affectedRows or 0

    Notify(src, ('✅ Removed **%s** vehicles from player %s'):format(count, targetId), count > 0 and 'success' or 'inform')
end)

RegisterNetEvent('mnc-seizecar:server:removeallcarsfromserver', function()
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') and not QBCore.Functions.HasPermission(src, 'god') then 
        return Notify(src, 'No permission', 'error') 
    end

    local result = exports.oxmysql:executeSync("DELETE FROM player_vehicles")
    local count = result and result.affectedRows or 0

    Notify(src, ('✅ Deleted **%s** vehicles from the entire server'):format(count), 'success')
    print(('^2[mnc-seizecar]^7 Deleted %s vehicles server-wide'):format(count))
end)

-- ==================== SEIZECAR SERVER HANDLER ====================
RegisterNetEvent('mnc-seizecar:server:seizecar', function(targetId, plate)
    local src = source

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Config.SeizeCarJob[Player.PlayerData.job.name] then
        return Notify(src, 'Your job is not allowed to seize vehicles', 'error')
    end

    local cid = GetCitizenIdByServerId(targetId)
    if not cid then 
        return Notify(src, 'Player not found', 'error') 
    end

    local result = exports.oxmysql:executeSync("DELETE FROM player_vehicles WHERE citizenid = ? AND plate = ? LIMIT 1", {cid, plate})
    local deleted = result and result.affectedRows or 0

    if deleted > 0 then
        local officerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        local job = Player.PlayerData.job.name

        Notify(src, ('✅ Seized plate **%s** from player %s'):format(plate, targetId), 'success')

        -- Notify the owner if online
        local Target = QBCore.Functions.GetPlayer(targetId)
        if Target then
            TriggerClientEvent('ox_lib:notify', targetId, {
                description = ('Your vehicle with plate **%s** has been seized by %s (%s)'):format(plate, officerName, job:upper()),
                type = 'error',
                duration = 10000
            })
        end
    else
        Notify(src, ('Plate **%s** not found for player %s'):format(plate, targetId), 'error')
    end
end)

print("^2[mnc-seizecar]^7 Script loaded successfully!")