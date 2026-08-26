-- client/pedspawner.lua
RegisterNetEvent('mnc-rentals:client:configureRentalPed', function(pedNetId, zoneId)
    local zone = Config.Zones[zoneId]
    if not zone or not zone.ped or not zone.ped.animationSet then
        return
    end

    local timeout = GetGameTimer() + 5000
    local ped

    while GetGameTimer() < timeout do
        if NetworkDoesNetworkIdExist(pedNetId) then
            ped = NetworkGetEntityFromNetworkId(pedNetId)
            if ped and DoesEntityExist(ped) then break end
        end
        Wait(100)
    end

    if ped and DoesEntityExist(ped) then
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedFleeAttributes(ped, 0, false)
        SetPedDiesWhenInjured(ped, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetPedCanRagdoll(ped, false)

        local animSet = zone.ped.animationSet
        if animSet and animSet.dict and animSet.anims and #animSet.anims > 0 then
            RequestAnimDict(animSet.dict)
            while not HasAnimDictLoaded(animSet.dict) do Wait(50) end

            local anim = animSet.anims[math.random(1, #animSet.anims)]
            TaskPlayAnim(ped, animSet.dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)

            if Config.Debug then
                print(string.format("[mnc-rentals] Applied animation to rental ped for zone %d: %s", zoneId, zone.name))
            end
        end
    else
        if Config.Debug then
            print(string.format("[mnc-rentals] Error: Rental ped not found for zoneId %d, pedNetId: %d", zoneId, pedNetId))
        end
    end
end)

RegisterNetEvent('mnc-rentals:client:cleanupRentalPed', function(zoneId)
    -- Client-side cleanup not strictly needed, but kept for consistency
    if Config.Debug then
        print(string.format("[mnc-rentals] Cleanup event received for rental ped zone %d", zoneId))
    end
end)