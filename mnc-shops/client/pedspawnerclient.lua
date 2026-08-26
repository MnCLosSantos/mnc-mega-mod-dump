-- pedspawnerclient.lua
RegisterNetEvent('mnc-shops:client:configureShopPed', function(pedNetId, zoneIndex)
    local zone = Config.Zones[zoneIndex]
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

        local animSet = zone.ped.animationSet
        if animSet and animSet.dict and animSet.anims and #animSet.anims > 0 then
            RequestAnimDict(animSet.dict)
            while not HasAnimDictLoaded(animSet.dict) do Wait(50) end

            local anim = animSet.anims[math.random(1, #animSet.anims)]
            TaskPlayAnim(ped, animSet.dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
            if Config.Debug then
                print(string.format("Applied animation to ped for zone %d: %s", zoneIndex, zone.name))
            end
        end
    else
        if Config.Debug then
            print(string.format("Error: Ped not found for zoneIndex %d, pedNetId: %d", zoneIndex, pedNetId))
        end
    end
end)

RegisterNetEvent('mnc-shops:client:cleanupShopPed', function(zoneIndex)
    local zone = Config.Zones[zoneIndex]
    if zone then
        -- No additional cleanup needed on client side
    end
end)