local QBCore = exports['qb-core']:GetCoreObject()
local vehicleFile = 'vehiclesaves.lua'

RegisterNetEvent('mnc-vehiclelua:saveVehicle', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Permission check
    if not IsPlayerAceAllowed(src, 'command') and not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Unauthorized',
            description = 'You are not authorized to save vehicles.',
            type = 'error'
        })
        return
    end

    local formatted = string.format([[
    {
        model = '%s',
        name = '%s',
        brand = '%s',
        price = %d,
        category = '%s',
        type = '%s',
        shop = '%s',
    },
    ]],
        data.model, data.name, data.brand, tonumber(data.price) or 0,
        data.category, data.type, data.shop
    )

    local path = ('%s/%s'):format(GetResourcePath(GetCurrentResourceName()), vehicleFile)
    local file = io.open(path, 'a')

    if file then
        file:write('\n' .. formatted)
        file:close()
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Vehicle Saved',
            description = ('Vehicle "%s" added to vehicle.lua!'):format(data.name),
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'File Error',
            description = 'Failed to write to vehicle.lua',
            type = 'error'
        })
    end
end)

print("^2[mnc-vehiclemanager]^7 Script loaded successfully!")
