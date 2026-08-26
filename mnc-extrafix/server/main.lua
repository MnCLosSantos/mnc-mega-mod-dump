RegisterNetEvent('mnc-extrafix:server:notifyFix', function(netId)
    local src = source

    -- Tell every client (including the one who sent this) to fix their own
    -- local copy of this vehicle. -1 broadcasts to all connected players.
    TriggerClientEvent('mnc-extrafix:client:applyFix', -1, netId)
end)
