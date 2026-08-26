local QBCore = exports['qb-core']:GetCoreObject()

-- Admin command
lib.addCommand(Config.Command, {
    help = 'Opens Vehicle Spawner with All Vehicles',
    restricted = Config.AdminGroups
}, function(source, args, raw)
    TriggerClientEvent('mnc-vehiclespawner:openUI', source)
end)

print("^2[mnc-vehiclespawner]^7 Script loaded successfully!")