-- client.lua - Drift Score HUD (Fixed NUI Focus Issue - CLEAN VERSION)

local QBCore = exports['qb-core']:GetCoreObject()

local currentStyle = Config.DefaultStyle or 1
local styleLoaded = false
local hudInitialized = false
local isDriftEnabled = false
local playerToggles = {}
local totalScore = 0
local currentChainScore = 0
local currentReputation = 0
local currentCoins = 0
local currentMultiplier = Config.PointsMultiplierBase
local lastDriftTime = 0
local currentCombo = ""
local isInVehicle = false
local lastVehicle = nil

-- Advanced combo tracking variables
local driftStartTime = 0
local lastHeading = 0
local headingChanges = {}
local lastThrottle = 0
local wasHandbrakePressed = false
local handbrakeTime = 0
local reverseEntryDetected = false
local lastAngle = 0
local lastVehicleHealth = 0
local lastBodyHealth = 0
local lastVelocityMagnitude = 0

-- Spin out tracking to prevent multiple notifications
local isInSpinOut = false

-- Initialize HUD toggles from config
for field, settings in pairs(Config.HUD) do
    playerToggles[field] = {
        enabled = settings.enabled,
        position = settings.position
    }
end

-- NUI Callbacks - MUST BE REGISTERED EARLY
RegisterNUICallback('closeModal', function(data, cb)
    
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    
    cb('ok')
end)

-- Store purchase from the driftboard's Store tab
RegisterNUICallback('purchaseItem', function(data, cb)
    local itemId = data and data.itemId

    if not itemId then
        cb({ success = false, message = "Invalid item" })
        return
    end

    QBCore.Functions.TriggerCallback('mnc-driftscore:purchaseItem', function(result)
        result = result or { success = false, message = "No response" }

        if result.success then
            if result.reputation then currentReputation = result.reputation end
            if result.coins then currentCoins = result.coins end

            if hudInitialized and styleLoaded then
                SendNUIMessage({
                    action = "currencyUpdate",
                    data = { reputation = currentReputation, coins = currentCoins }
                })
            end
        end

        cb(result)
    end, itemId)
end)

RegisterNUICallback('changeStyle', function(data, cb)
    
    local styleNum = tonumber(data.style)
    if styleNum and Config.Styles[styleNum] then
        currentStyle = styleNum
        TriggerServerEvent('mnc-driftscore:saveStyle', styleNum)
        
        SendNUIMessage({
            action = "showNotification",
            message = "Style: " .. Config.Styles[styleNum].name,
            type = "success",
            style = Config.Styles[styleNum]
        })
        
        SendNUIMessage({
            action = "styleChanged",
            newStyle = styleNum,
            styleName = Config.Styles[styleNum].name
        })
        
        if isDriftEnabled then
            SendNUIMessage({
                action = "update",
                data = {
                    score = math.floor(totalScore + currentChainScore),
                    multiplier = "x" .. string.format("%.1f", currentMultiplier),
                    combo = currentCombo,
                    style = Config.Styles[currentStyle],
                    toggle = playerToggles,
                    reputation = currentReputation,
                    coins = currentCoins
                }
            })
        end
    else
    end
    
    cb('ok')
end)

-- Custom notification function
local function ShowNotification(message, type)
    if not styleLoaded or not hudInitialized then 
        return 
    end
    
    SendNUIMessage({
        action = "showNotification",
        message = message,
        type = type or "success",
        style = Config.Styles[currentStyle]
    })
end

-- Reset current chain (DO NOT reset lastDriftTime here!)
local function ResetChain(reason, updateHud)
    currentChainScore = 0
    currentMultiplier = Config.PointsMultiplierBase
    currentCombo = ""
    driftStartTime = 0
    reverseEntryDetected = false
    headingChanges = {}
    handbrakeTime = 0
    wasHandbrakePressed = false
    lastThrottle = 0
    lastAngle = 0

    if reason and reason ~= "" then
        ShowNotification("Chain Reset: " .. reason, "error")
    end

    if updateHud and hudInitialized and styleLoaded then
        SendNUIMessage({
            action = "update",
            data = {
                score = math.floor(totalScore),
                multiplier = "x" .. string.format("%.1f", currentMultiplier),
                combo = "",
                style = Config.Styles[currentStyle],
                toggle = playerToggles,
                reputation = currentReputation,
                coins = currentCoins
            }
        })
    end
end

-- Push the current running total to the server leaderboard (weekly/monthly/alltime).
-- Safe to call often: the server only ever keeps the highest score per period.
local function SubmitScoreToLeaderboard()
    local minScore = (Config.Leaderboard and Config.Leaderboard.MinScoreToSubmit) or 0
    if totalScore and totalScore >= minScore then
        TriggerServerEvent('mnc-driftscore:submitScore', math.floor(totalScore))
    end
end

-- Bank a SAVED chain (as opposed to one lost to a crash/spin-out reset) into
-- the running total, and let the server award Reputation/Drift Coins for it.
local function BankChain(chainScore)
    if not chainScore or chainScore <= 0 then return end
    totalScore = totalScore + chainScore
    TriggerServerEvent('mnc-driftscore:bankChain', math.floor(chainScore))
end

-- Check if vehicle is drifting
local function isDrifting(vehicle)
    local velocity = GetEntityVelocity(vehicle)
    local speed = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
    if speed < Config.MinDriftSpeed then return false, 0.0, speed end

    local heading = GetEntityHeading(vehicle)
    local velDir = vector3(velocity.x, velocity.y, 0.0)
    local velNorm = math.sqrt(velDir.x^2 + velDir.y^2)
    if velNorm == 0 then return false, 0.0, speed end
    velDir = velDir / velNorm

    local headingRad = math.rad(heading)
    local headingDir = vector3(-math.sin(headingRad), math.cos(headingRad), 0.0)

    local dot = velDir.x * headingDir.x + velDir.y * headingDir.y
    dot = math.max(-1.0, math.min(1.0, dot))
    local angle = math.deg(math.acos(dot))

    return angle > Config.DriftThresholdAngle, angle, speed
end

-- Check for spin-out conditions
local function isSpinOut(vehicle, angle)
    if angle > Config.MaxDriftAngle then return true end
    local rotVel = GetEntityRotationVelocity(vehicle)
    if math.abs(rotVel.z) > Config.SpinOutRotationRate then return true end
    return false
end

-- Get distance to nearest wall/object in front
local function getProximityDistance(vehicle)
    local coords = GetEntityCoords(vehicle)
    local forward = GetEntityForwardVector(vehicle)
    local endCoords = coords + (forward * 10.0)
    
    local rayHandle = StartShapeTestRay(
        coords.x, coords.y, coords.z + 0.5,
        endCoords.x, endCoords.y, endCoords.z + 0.5,
        -1, vehicle, 0
    )
    
    local _, hit, hitCoords = GetShapeTestResult(rayHandle)
    
    if hit == 1 then
        return #(coords - hitCoords)
    end
    return 100.0
end

-- Count nearby drifting players (for tandem bonus)
local function getNearbyDriftingPlayers(playerPos, currentVehicle)
    local nearbyCount = 0
    local players = GetActivePlayers()
    
    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local otherPed = GetPlayerPed(player)
            local otherVehicle = GetVehiclePedIsIn(otherPed, false)
            
            if DoesEntityExist(otherVehicle) and otherVehicle ~= currentVehicle then
                -- Only count if they are the DRIVER (-1 seat)
                if GetPedInVehicleSeat(otherVehicle, -1) == otherPed then
                    local otherPos = GetEntityCoords(otherVehicle)
                    local distance = #(playerPos - otherPos)
                    
                    if distance < 3.0 then
                        local drifting, _, _ = isDrifting(otherVehicle)
                        if drifting then
                            nearbyCount = nearbyCount + 1
                        end
                    end
                end
            end
        end
    end
    
    return nearbyCount
end

-- Track sharp heading changes (for chicane detection)
local function trackHeadingChanges(currentHeading)
    local currentTime = GetGameTimer()
    
    local headingDiff = currentHeading - lastHeading
    if headingDiff > 180 then headingDiff = headingDiff - 360 end
    if headingDiff < -180 then headingDiff = headingDiff + 360 end
    
    if math.abs(headingDiff) > 45 then
        table.insert(headingChanges, currentTime)
    end
    
    for i = #headingChanges, 1, -1 do
        if currentTime - headingChanges[i] > 4000 then
            table.remove(headingChanges, i)
        end
    end
    
    lastHeading = currentHeading
    return #headingChanges
end

-- Update active combos and calculate total multiplier
local function updateCombos(vehicle, angle, speed, chainTime, dist)
    local newMultiplier = Config.PointsMultiplierBase
    local comboNames = {}
    local currentTime = GetGameTimer()
    
    local heading = GetEntityHeading(vehicle)
    local rotVel = GetEntityRotationVelocity(vehicle)
    local throttle = GetVehicleThrottleOffset(vehicle)
    local isHandbrake = GetVehicleHandbrake(vehicle)
    local isReverse = GetEntitySpeedVector(vehicle, true).y < 0
    local playerPos = GetEntityCoords(vehicle)
    local nearbyDrifters = getNearbyDriftingPlayers(playerPos, vehicle)
    local headingChangeCount = trackHeadingChanges(heading)
    
    local throttleDelta = throttle - lastThrottle
    local angleDelta = angle - lastAngle
    
    if isHandbrake and not wasHandbrakePressed then
        handbrakeTime = currentTime
    end
    wasHandbrakePressed = isHandbrake
    
    if isReverse and angle > 45 and angleDelta > 5 then
        reverseEntryDetected = true
    end
    
    for _, combo in ipairs(Config.Combos) do
        local passed = false
        
        if combo.comboType == "angle" then passed = combo.condition(angle)
        elseif combo.comboType == "speed" then passed = combo.condition(speed)
        elseif combo.comboType == "proximity" then passed = combo.condition(dist)
        elseif combo.comboType == "duration" then passed = combo.condition(chainTime)
        elseif combo.comboType == "angle_speed" then passed = combo.condition(angle, speed)
        elseif combo.comboType == "angle_proximity" then passed = combo.condition(angle, dist)
        elseif combo.comboType == "tandem" then passed = combo.condition(nearbyDrifters)
        elseif combo.comboType == "reverse_entry" then passed = combo.condition(reverseEntryDetected, angle)
        elseif combo.comboType == "clutch_kick" then passed = combo.condition(throttleDelta, angleDelta)
        elseif combo.comboType == "chicane" then passed = combo.condition(headingChangeCount, angle)
        elseif combo.comboType == "donut" then passed = combo.condition(math.abs(rotVel.z), speed)
        elseif combo.comboType == "ebrake" then passed = combo.condition(currentTime - handbrakeTime, angleDelta)
        elseif combo.comboType == "link" then passed = combo.condition(chainTime, angle, headingChangeCount)
        end
        
        if passed then
            newMultiplier = newMultiplier + combo.multiplier
            table.insert(comboNames, combo.name)
        end
    end
    
    currentMultiplier = newMultiplier
    currentCombo = table.concat(comboNames, " + ")
    
    lastThrottle = throttle
    lastAngle = angle
end

-- Main HUD update function
local function updateHUD()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local isDriver = vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped

    if isDriver then
        -- ── DRIVER ───────────────────────────────────────────────
        if not isInVehicle or lastVehicle ~= vehicle then
            -- Just entered / switched vehicle
            isInVehicle = true
            lastVehicle = vehicle
            lastVehicleHealth = GetEntityHealth(vehicle)
            lastBodyHealth = GetVehicleBodyHealth(vehicle)
            lastVelocityMagnitude = 0
            
            if isDriftEnabled and hudInitialized then
                SendNUIMessage({ action = "show" })
            end
        end

        local currentHealth = GetEntityHealth(vehicle)
        local currentBodyHealth = GetVehicleBodyHealth(vehicle)
        local velocity = GetEntityVelocity(vehicle)
        local currentVelMag = math.sqrt(velocity.x^2 + velocity.y^2 + velocity.z^2)
        
        -- Crash detection
        local isCrash = false
        if lastVehicleHealth > 0 then
            local healthDiff = math.abs(currentHealth - lastVehicleHealth)
            local bodyDiff = math.abs(currentBodyHealth - lastBodyHealth)
            if healthDiff > 25 or bodyDiff > 30 then isCrash = true end
        end
        if lastVelocityMagnitude > 20 and currentVelMag < (lastVelocityMagnitude * 0.4) then
            isCrash = true
        end
        
        if isCrash then
            ResetChain("Crashed", false)
        end
        
        lastVehicleHealth = currentHealth
        lastBodyHealth = currentBodyHealth
        lastVelocityMagnitude = currentVelMag
        
        local drifting, angle, speed = isDrifting(vehicle)
        local currentTime = GetGameTimer()

        if drifting then
            lastDriftTime = currentTime
            
            if driftStartTime == 0 then
                driftStartTime = currentTime
            end
            
            local dt = GetFrameTime()
            local points = (speed * angle / 100) * dt * 10
            local chainTime = currentTime - driftStartTime
            local dist = getProximityDistance(vehicle)

            local spinning = isSpinOut(vehicle, angle)
            if spinning then
                if not isInSpinOut then
                    ResetChain("Spin Out", false)
                end
                isInSpinOut = true
            else
                if isInSpinOut then
                    isInSpinOut = false
                end
                updateCombos(vehicle, angle, speed, chainTime, dist)
                currentChainScore = currentChainScore + (points * currentMultiplier)
            end

            if hudInitialized and styleLoaded then
                SendNUIMessage({
                    action = "update",
                    data = {
                        score = math.floor(totalScore + currentChainScore),
                        multiplier = "x" .. string.format("%.1f", currentMultiplier),
                        combo = currentCombo,
                        style = Config.Styles[currentStyle],
                        toggle = playerToggles,
                        reputation = currentReputation,
                        coins = currentCoins
                    }
                })
            end
        else
            isInSpinOut = false
            if currentTime - lastDriftTime > Config.ComboTimeout and currentChainScore > 0 then
                local savedChainScore = currentChainScore
                BankChain(savedChainScore)
                ShowNotification("Chain Saved! +" .. math.floor(savedChainScore), "success")
                ResetChain("", true)
                SubmitScoreToLeaderboard()
            end

            if currentTime - lastDriftTime >= Config.InactiveResetTime then
                if totalScore > 0 then
                    ShowNotification("No drift activity for " .. (Config.InactiveResetTime/1000) .. "s - Total Reset", "error")
                    totalScore = 0
                    ResetChain("", true)
                end
            end
        end
    else
        -- ── NOT DRIVER / NO VEHICLE ──────────────────────────────
        if isInVehicle then
            -- Just exited or stopped being driver
            if currentChainScore > 0 then
                local savedChainScore = currentChainScore
                BankChain(savedChainScore)
                ShowNotification("Chain Saved! +" .. math.floor(savedChainScore), "success")
            end
            
            ResetChain("", false)
            SubmitScoreToLeaderboard()
            
            isInVehicle = false
            lastVehicle = nil
            lastVehicleHealth = 0
            lastBodyHealth = 0
            lastVelocityMagnitude = 0
            isInSpinOut = false
            
            if hudInitialized then
                SendNUIMessage({ action = "hide" })
            end
        end
    end
end

-- HUD update thread
CreateThread(function()
    while true do
        Citizen.Wait(120)
        if isDriftEnabled then
            updateHUD()
        end
    end
end)

-- Load saved player style
local function LoadPlayerStyle()
    QBCore.Functions.TriggerCallback('mnc-driftscore:getStyle', function(style)
        if style then
            currentStyle = style
            styleLoaded = true
        else
            currentStyle = Config.DefaultStyle
            styleLoaded = true
        end
    end)
end

-- Load persistent Reputation / Drift Coins
local function LoadPlayerCurrency()
    QBCore.Functions.TriggerCallback('mnc-driftscore:getPlayerCurrency', function(currency)
        currentReputation = (currency and currency.reputation) or 0
        currentCoins = (currency and currency.coins) or 0

        if hudInitialized and styleLoaded then
            SendNUIMessage({
                action = "currencyUpdate",
                data = { reputation = currentReputation, coins = currentCoins }
            })
        end
    end)
end

-- Initialize HUD system
local function InitializeHUD()
    
    LoadPlayerStyle()
    LoadPlayerCurrency()
    
    Citizen.CreateThread(function()
        local attempts = 0
        while not styleLoaded and attempts < 50 do
            Citizen.Wait(100)
            attempts = attempts + 1
        end
        
        if not styleLoaded then
            currentStyle = Config.DefaultStyle
            styleLoaded = true
        end
        
        hudInitialized = true
        lastVehicleHealth = 0
        lastBodyHealth = 0
        lastVelocityMagnitude = 0
        
        SendNUIMessage({ action = "hide" })
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    InitializeHUD()
end)

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    if not hudInitialized then
        InitializeHUD()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    styleLoaded = false
    hudInitialized = false
    isDriftEnabled = false
    SendNUIMessage({ action = "hide" })
end)

-- Server confirms Reputation/Drift Coins earned from a saved chain, or a
-- balance change from a store purchase.
RegisterNetEvent('mnc-driftscore:currencyUpdated', function(payload)
    payload = payload or {}
    currentReputation = payload.reputation or currentReputation
    currentCoins = payload.coins or currentCoins

    if payload.rpEarned and payload.rpEarned > 0 then
        local msg = ("+%d Reputation"):format(payload.rpEarned)
        if payload.coinsEarned and payload.coinsEarned > 0 then
            msg = msg .. (" + %d Drift Coin%s"):format(payload.coinsEarned, payload.coinsEarned == 1 and "" or "s")
        end
        ShowNotification(msg, "success")
    end

    if hudInitialized and styleLoaded then
        SendNUIMessage({
            action = "currencyUpdate",
            data = { reputation = currentReputation, coins = currentCoins }
        })
    end
end)

-- Commands
RegisterCommand("drifthudhelp", function()
    
    SendNUIMessage({
        action = "openHelp",
        styleName = styleLoaded and Config.Styles[currentStyle].name or "Loading...",
        allStyles = Config.Styles,
        currentStyleIndex = currentStyle
    })
    
    Citizen.SetTimeout(100, function()
        SetNuiFocus(true, true)
    end)
end, false)

RegisterCommand("driftscore", function()
    if not styleLoaded or not hudInitialized then
        return
    end

    isDriftEnabled = not isDriftEnabled
    
    if isDriftEnabled then
        ResetChain("", true)
        SendNUIMessage({ action = "show" })
        ShowNotification("Drift Score Enabled", "success")
    else
        if currentChainScore > 0 then
            local savedChainScore = currentChainScore
            BankChain(savedChainScore)
            ShowNotification("Final Chain Saved! +" .. math.floor(savedChainScore), "success")
        end
        ResetChain("UI Closed", false)
        SubmitScoreToLeaderboard()
        SendNUIMessage({ action = "hide" })
        ShowNotification("Drift Score Disabled", "success")
    end
end, false)

RegisterCommand("driftstyle", function(_, args)
    if not styleLoaded or not hudInitialized then
        return
    end

    local styleNum = tonumber(args[1])
    if styleNum and Config.Styles[styleNum] then
        currentStyle = styleNum
        ShowNotification("Style changed to: " .. Config.Styles[styleNum].name, "success")
        TriggerServerEvent('mnc-driftscore:saveStyle', styleNum)
        if isDriftEnabled then
            updateHUD()
        end
    else
    end
end, false)

-- Open the drift score leaderboard (weekly / monthly / all-time / store)
RegisterCommand("driftboard", function()
    QBCore.Functions.TriggerCallback('mnc-driftscore:getLeaderboardData', function(data)
        SendNUIMessage({
            action = "openLeaderboard",
            data = data,
            style = Config.Styles[currentStyle],
            reputation = currentReputation,
            coins = currentCoins,
            store = Config.Store
        })

        Citizen.SetTimeout(100, function()
            SetNuiFocus(true, true)
        end)
    end)
end, false)

RegisterCommand("driftlb", function()
    ExecuteCommand("driftboard")
end, false)

-- Hide HUD elements when pause menu is active
CreateThread(function()
    while true do
        Citizen.Wait(250)
        
        if IsPauseMenuActive() then
            if hudInitialized then
                SendNUIMessage({ action = "hide" })
            end
        else
            -- Only show again if drift HUD is supposed to be visible
            if isDriftEnabled and isInVehicle and hudInitialized then
                SendNUIMessage({ action = "show" })
            end
        end
    end
end)