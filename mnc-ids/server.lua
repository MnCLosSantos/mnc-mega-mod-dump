RegisterNetEvent("idcheck:notifyPlayer", function(targetId)
    TriggerClientEvent("idcheck:showNotify", targetId)
end)

print("^2[mnc-ids]^7 Script loaded successfully!")