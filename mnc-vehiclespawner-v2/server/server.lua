local QBCore = exports['qb-core']:GetCoreObject()

-- ── Admin command ─────────────────────────────────────────────────────────────
lib.addCommand(Config.Command, {
    help = 'Opens Vehicle Spawner with All Vehicles (Admin)',
}, function(source, args, raw)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {
            title       = 'Access Denied',
            description = 'You do not have permission to use this command.',
            type        = 'error',
        })
        return
    end
    TriggerClientEvent('mnc-vehiclespawner:openUI', source)
end)

-- Plate check — fires back plateFree or plateTaken to the client
RegisterNetEvent('mnc-vehiclespawner:checkPlate', function(plate)
    local src = source
    local cleanPlate = plate:upper():gsub('%s+', '')

    exports['oxmysql']:execute(
        'SELECT plate FROM player_vehicles WHERE plate = ?',
        { cleanPlate },
        function(result)
            if result and #result > 0 then
                TriggerClientEvent('mnc-vehiclespawner:plateTaken', src)
            else
                TriggerClientEvent('mnc-vehiclespawner:plateFree', src)
            end
        end
    )
end)

-- Save vehicle to player_vehicles
RegisterNetEvent('mnc-vehiclespawner:saveVehicle', function(plate, model)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local cleanPlate = plate:upper():gsub('%s+', '')

    exports['oxmysql']:execute(
        'SELECT plate FROM player_vehicles WHERE plate = ?',
        { cleanPlate },
        function(result)
            if result and #result > 0 then
                TriggerClientEvent('mnc-vehiclespawner:plateConflict', src)
                return
            end
            exports['oxmysql']:insert(
                'INSERT INTO player_vehicles (citizenid, vehicle, plate, garage, state) VALUES (?, ?, ?, ?, ?)',
                { citizenid, model, cleanPlate, 'pillboxgarage', 1 },
                function()
                    TriggerClientEvent('mnc-vehiclespawner:vehicleSaved', src)
                end
            )
        end
    )
end)

-- Standalone vehicle mods command (admin only, must be in a vehicle)
-- lib.addCommand(Config.ModsCommand, {
    -- help = 'Opens Vehicle Mods panel on your current vehicle',
    -- restricted = Config.AdminGroups
-- }, function(source, args, raw)
    -- TriggerClientEvent('mnc-vehiclespawner:openStandaloneMods', source)
-- end)

print("^2[mnc-vehiclespawner]^7 Script loaded successfully!")