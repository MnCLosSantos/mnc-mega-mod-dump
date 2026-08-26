local QBCore = exports['qb-core']:GetCoreObject()
local isDead = false

-- Check metadata for death state
CreateThread(function()
    while true do
        local playerData = QBCore.Functions.GetPlayerData()
        if playerData and playerData.metadata then
            local dead = playerData.metadata["isdead"] or playerData.metadata["inlaststand"]

            if dead and not isDead then
                isDead = true
                exports['pma-voice']:overrideProximityCheck(function()
                    return false -- block talking
                end)
                print("Muted: player is dead")
            elseif not dead and isDead then
                isDead = false
                exports['pma-voice']:resetProximityCheck()
                print("Unmuted: player revived")
            end
        end
        Wait(1000) -- check every second
    end
end)