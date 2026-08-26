local config = {
    toggleKey = 20, -- Z key
    notifyDistance = 25.0,
    checkDuration = 30000, -- IDs visible for 20s
    cooldown = 30000 -- 30s cooldown
}

local disPlayerNames = 20
local playerDistances = {}
local showIDs = false
local lastCheck = 0

-- Draw 3D Text
local function DrawText3D(position, text, r, g, b)
    local onScreen, _x, _y = World3dToScreen2d(position.x, position.y, position.z + 1)
    local dist = #(GetGameplayCamCoords() - position)

    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov

    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(r, g, b, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Show IDs
Citizen.CreateThread(function()
    while true do
        if showIDs then
            for _, id in ipairs(GetActivePlayers()) do
                local targetPed = GetPlayerPed(id)
                local targetCoords = GetEntityCoords(targetPed)
                if playerDistances[id] and playerDistances[id] < disPlayerNames then
                    DrawText3D(targetCoords, GetPlayerServerId(id), 255, 255, 255)
                end
            end
            -- Own ID
            local playerCoords = GetEntityCoords(PlayerPedId())
            DrawText3D(playerCoords, GetPlayerServerId(PlayerId()), 255, 255, 255)
        end
        Citizen.Wait(0)
    end
end)

-- Track distances
Citizen.CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        for _, id in ipairs(GetActivePlayers()) do
            local targetPed = GetPlayerPed(id)
            if targetPed ~= PlayerPedId() then
                playerDistances[id] = #(playerCoords - GetEntityCoords(targetPed))
            end
        end
        Wait(1000)
    end
end)

-- Handle keypress
Citizen.CreateThread(function()
    while true do
        if IsControlJustPressed(0, config.toggleKey) then
            local now = GetGameTimer()
            if now - lastCheck < config.cooldown then
                local timeLeft = math.ceil((config.cooldown - (now - lastCheck)) / 1000)
                SendNUIMessage({
                    action = "cooldown",
                    seconds = timeLeft
                })
            else
                lastCheck = now
                showIDs = true

                -- Self UI
                SendNUIMessage({
                    action = "selfCheck",
                    duration = config.checkDuration,
                    cooldown = config.cooldown
                })
                SetNuiFocus(false, false)

                -- Notify nearby players
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                for _, id in ipairs(GetActivePlayers()) do
                    if id ~= PlayerId() then
                        local dist = #(playerCoords - GetEntityCoords(GetPlayerPed(id)))
                        if dist <= config.notifyDistance then
                            TriggerServerEvent("idcheck:notifyPlayer", GetPlayerServerId(id))
                        end
                    end
                end

                -- Reset after duration
                Citizen.CreateThread(function()
                    Wait(config.checkDuration)
                    showIDs = false
                end)
            end
        end
        Citizen.Wait(0)
    end
end)

-- Receive notify (others)
RegisterNetEvent("idcheck:showNotify", function()
    SendNUIMessage({
        action = "otherCheck"
    })
end)
