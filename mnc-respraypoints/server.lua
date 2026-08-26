local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('mnc-respraypoints:payAndRespray', function(resprayType, colorIndex, location)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        print("[mnc-respraypoints] Player not found for source:", src)
        return
    end

    -- Find the location config to check emergencyOnly
    local cfgLocation = nil
    for _, loc in ipairs(Config.Locations.respray) do
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

    local basePrice = Config.ResprayPrices[resprayType] or 500
    local price = isEmergencyFree and 0 or basePrice

    if Config.Debug then
        print(("[DEBUG] %s requested %s respray (color: %s) at '%s' - price: $%d (emergency free: %s) - bank: $%d"):format(
            Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            resprayType,
            colorIndex,
            location or "unknown",
            price,
            isEmergencyFree and "yes" or "no",
            Player.PlayerData.money.bank or 0
        ))
    end

    -- Check money FIRST before applying
    local bankBalance = Player.PlayerData.money['bank'] or 0

    if price > 0 and bankBalance < price then
        -- NOT ENOUGH MONEY - Tell client to restore original colors
        TriggerClientEvent('mnc-respraypoints:restoreOriginal', src)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Respray Station',
            description = 'Not enough money in bank ($' .. bankBalance .. ' / $' .. price .. ')',
            type = 'error',
            duration = 4000
        })
        if Config.Debug then
            print("[DEBUG] Not enough money - denied, restoring original colors")
        end
        return
    end

    -- Free respray (emergency vehicles)
    if price <= 0 then
        TriggerClientEvent('mnc-respraypoints:applyRespray', src, resprayType, colorIndex)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Respray Station',
            description = resprayType == 'full'
                and 'Vehicle fully resprayed (free)'
                or (resprayType .. ' applied (free)'),
            type = 'success'
        })
        if Config.Debug then
            print("[DEBUG] Free respray granted")
        end
        return
    end

    -- Try to remove money
    local success = Player.Functions.RemoveMoney('bank', price)

    if not success then
        -- Payment failed - restore original
        TriggerClientEvent('mnc-respraypoints:restoreOriginal', src)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Respray Station',
            description = 'Payment failed - try again',
            type = 'error'
        })
        if Config.Debug then
            print("[DEBUG] RemoveMoney failed, restoring original colors")
        end
        return
    end

    -- SUCCESS - Apply the respray
    TriggerClientEvent('mnc-respraypoints:applyRespray', src, resprayType, colorIndex)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Respray Station',
        description = resprayType == 'full'
            and ('Vehicle fully resprayed - $' .. price)
            or (resprayType:gsub("^%l", string.upper) .. ' applied - $' .. price),
        type = 'success'
    })

    if Config.Debug then
        print("[DEBUG] Respray paid & applied successfully - $" .. price .. " removed")
    end
end)

-- Periodic check for mechanics on duty
CreateThread(function()
    while true do
        Wait(Config.DutyCheckInterval * 1000)

        local mechanicCount = 0

        for _, player in pairs(QBCore.Functions.GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(player)
            if Player and Player.PlayerData.job and Player.PlayerData.job.name then
                local jobName = Player.PlayerData.job.name
                local onDuty = Player.PlayerData.job.onduty or false

                if Config.MechanicJobs[jobName] and onDuty then
                    mechanicCount = mechanicCount + 1
                end
            end
        end

        TriggerClientEvent('mnc-respraypoints:updateMechanicDutyStatus', -1, mechanicCount > 0)

        if Config.Debug then
            print(("[mnc-respraypoints DEBUG] Mechanics on duty: %d"):format(mechanicCount))
        end
    end
end)

-- Handle initial status request
RegisterNetEvent('mnc-respraypoints:requestMechanicDutyStatus', function()
    local src = source
    local mechanicCount = 0

    for _, player in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(player)
        if Player and Player.PlayerData.job and Player.PlayerData.job.name then
            local jobName = Player.PlayerData.job.name
            local onDuty = Player.PlayerData.job.onduty or false

            if Config.MechanicJobs[jobName] and onDuty then
                mechanicCount = mechanicCount + 1
            end
        end
    end

    TriggerClientEvent('mnc-respraypoints:updateMechanicDutyStatus', src, mechanicCount > 0)

    if Config.Debug then
        print(("[mnc-respraypoints DEBUG] Sent initial status to source %d - mechanics on duty: %d"):format(src, mechanicCount))
    end
end)

print("^2[mnc-respraypoints]^7 Script loaded successfully!")