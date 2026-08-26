local QBCore = exports['qb-core']:GetCoreObject()

-- Admin command
lib.addCommand(Config.Command, {
    help = 'Opens Vehicle Catalog with All Vehicles',
    restricted = Config.AdminGroups
}, function(source, args, raw)
    TriggerClientEvent('mnc-vehiclecatalog:openAdminUI', source)
end)

print("^2[mnc-vehiclecatalog]^7 Script loaded successfully!")