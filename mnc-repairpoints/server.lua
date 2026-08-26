local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('mnc-repairpoints:payAndRepair', function(repairType, location)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        print("[mnc-repairpoints] Player not found for source:", src)
        return 
    end

    -- Find the location config to check emergencyOnly
    local cfgLocation = nil
    for _, loc in ipairs(Config.Locations.repair) do
        if loc.name == location then
            cfgLocation = loc
            break
        end
    end

    local isEmergencyFree = false
    if cfgLocation and cfgLocation.emergencyOnly then
        -- We'll trust client sent correct location name, but in production you could add more validation
        isEmergencyFree = true
    end

    local basePrice = repairType == 'full' and Config.RepairPriceFull or Config.RepairPriceBody
    local price = isEmergencyFree and 0 or basePrice

    if Config.Debug then
        print(("[DEBUG] %s requested %s repair at '%s' - price: $%d (emergency free: %s) - bank: $%d"):format(
            Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            repairType,
            location or "unknown",
            price,
            isEmergencyFree and "yes" or "no",
            Player.PlayerData.money.bank or 0
        ))
    end

    if price <= 0 then
        TriggerClientEvent('mnc-repairpoints:applyRepair', src, repairType)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Repair Shop',
            description = repairType == 'full' 
                and 'Vehicle fully repaired (free)' 
                or 'Body damage repaired (free)',
            type = 'success'
        })
        if Config.Debug then
            print("[DEBUG] Free repair granted")
        end
        return
    end

    local bankBalance = Player.PlayerData.money['bank'] or 0

    if bankBalance < price then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Repair Shop',
            description = 'Not enough money in bank ($' .. bankBalance .. ' / $' .. price .. ')',
            type = 'error'
        })
        if Config.Debug then
            print("[DEBUG] Not enough money - denied")
        end
        return
    end

    local success = Player.Functions.RemoveMoney('bank', price)

    if not success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Repair Shop',
            description = 'Payment failed - try again',
            type = 'error'
        })
        if Config.Debug then
            print("[DEBUG] RemoveMoney failed")
        end
        return
    end

    TriggerClientEvent('mnc-repairpoints:applyRepair', src, repairType)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Repair Shop',
        description = repairType == 'full' 
            and ('Vehicle fully repaired - $' .. price) 
            or ('Body damage repaired - $' .. price),
        type = 'success'
    })

    if Config.Debug then
        print("[DEBUG] Repair paid & applied successfully - $" .. price .. " removed")
    end
end)

-- Periodic check for mechanics on duty (unchanged)
CreateThread(function()
    while true do
        Wait(Config.DutyCheckInterval * 1000)

        local mechanicCount = 0

        for _, player in pairs(QBCore.Functions.GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(player)
            if Player and Player.PlayerData.job and Player.PlayerData.job.name then
                local jobName = Player.PlayerData.job.name
                local onDuty  = Player.PlayerData.job.onduty or false

                if Config.MechanicJobs[jobName] and onDuty then
                    mechanicCount = mechanicCount + 1
                end
            end
        end

        TriggerClientEvent('mnc-repairpoints:updateMechanicDutyStatus', -1, mechanicCount > 0)

        if Config.Debug then
            print(("[mnc-repairpoints DEBUG] Mechanics on duty: %d"):format(mechanicCount))
        end
    end
end)

-- Handle initial status request (unchanged)
RegisterNetEvent('mnc-repairpoints:requestMechanicDutyStatus', function()
    local src = source
    local mechanicCount = 0

    for _, player in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(player)
        if Player and Player.PlayerData.job and Player.PlayerData.job.name then
            local jobName = Player.PlayerData.job.name
            local onDuty  = Player.PlayerData.job.onduty or false

            if Config.MechanicJobs[jobName] and onDuty then
                mechanicCount = mechanicCount + 1
            end
        end
    end

    TriggerClientEvent('mnc-repairpoints:updateMechanicDutyStatus', src, mechanicCount > 0)

    if Config.Debug then
        print(("[mnc-repairpoints DEBUG] Sent initial status to source %d - mechanics on duty: %d"):format(src, mechanicCount))
    end
end)

print("^2[mnc-repairpoints]^7 Script loaded successfully!")