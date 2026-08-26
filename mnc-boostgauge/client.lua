local QBCore = exports['qb-core']:GetCoreObject()
local ox_lib = exports.ox_lib

-- Config references
local ui = Config.UI
local needleCfg = Config.Needle
local remapPSI = Config.RemapPSI
local stylesCount = Config.StylesCount

-- State variables
local appliedStyles = {} -- Per-vehicle styles by plate
local appliedBezels = {} -- Per-vehicle bezels by plate
local visible = false
local lastVehicle = 0
local currentPsiMax = 0
local displayedPsi = 0.0
local targetPsi = 0.0
local lastUpdateTime = GetGameTimer()
local rpmHigh = false
local gaugeInitialized = false
local lastRemapCheck = 0
local remapCheckInterval = 15000 -- Check every 15 seconds
local engineWasRunning = false
local needsSweep = false
local maxStyles = stylesCount or 40 -- Adjust to match your total gauge styles
local maxBezels = ui.bezelsCount or 20 -- Adjust to match your total bezel styles
local lastGaugeCheck = 0 -- Cooldown for getInstalledGauges
local gaugeCheckInterval = 1000 -- Check gauges every 1 second
local isPaused = false -- Track pause menu state

-- Lerp helper
local function lerp(a, b, t)
    return a + (b - a) * math.min(1.0, math.max(0.0, t))
end

-- Smooth damp (advanced smoothing with velocity)
local currentVelocity = 0.0
local function smoothDamp(current, target, smoothTime, deltaTime)
    smoothTime = math.max(0.0001, smoothTime)
    local omega = 2.0 / smoothTime
    local x = omega * deltaTime
    local exp = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
    local change = current - target
    local temp = (currentVelocity + omega * change) * deltaTime
    currentVelocity = (currentVelocity - omega * temp) * exp
    return target + (change + temp) * exp
end

-- External visibility flag — controlled by mnc-jobhud (or any resource) via:
--   TriggerEvent('mnc-boostgauge:setVisible', false)  -- hide
--   TriggerEvent('mnc-boostgauge:setVisible', true)   -- show
local MNC_BOOSTGAUGE_VISIBLE = true

-- Push NUI message
-- If MNC_BOOSTGAUGE_VISIBLE is false, any action that would show the gauge
-- is silently suppressed. Hide/non-display actions still pass through so the
-- gauge stays hidden even when the vehicle/turbo state changes.
local function pushNUI(action, data)
    -- Block any show-intent messages when externally hidden
    if not MNC_BOOSTGAUGE_VISIBLE then
        -- Only allow actions that hide or don't affect visibility
        local isShowIntent = (action == 'update' and data and data.visible == true)
                          or (action == 'setVisible' and data and data.visible == true)
                          or (action == 'updateStyle')
                          or (action == 'startSweep')
        if isShowIntent then return end
    end

    if Config.Debug then
        print("pushNUI: Action:", action, "Data:", json.encode(data))
    end
    SendNUIMessage({
        action = action,
        data = data
    })
end

AddEventHandler('mnc-boostgauge:setVisible', function(v)
    if MNC_BOOSTGAUGE_VISIBLE == v then return end
    MNC_BOOSTGAUGE_VISIBLE = v
    if not v then
        -- Force hide immediately
        SendNUIMessage({ action = 'setVisible', data = { visible = false } })
    end
    -- When restoring, the main loop's next tick will re-show naturally via pushNUI
end)

-- Get vehicle remap and turbo
local function getVehicleRemapAsync(networkId, callback)
    if not networkId or networkId == 0 then
        callback(nil)
        return
    end
    QBCore.Functions.TriggerCallback('mnc-performanceparts:getInstalledParts', function(result)
        if Config.Debug then
            print("Remap Callback Result:", json.encode(result))
        end
        if not result or not result.parts then
            callback(nil)
            return
        end
        local remapStage = nil
        local turboPart = nil
        for _, part in ipairs(result.parts) do
            if part:find('remap_') then
                remapStage = part:gsub('remap_', '')
            elseif part:find('turbo_') then
                turboPart = part
            end
        end
        callback({ remap = remapStage, turbo = turboPart })
    end, networkId)
end

-- Helper function to check if vehicle is blacklisted
local function isVehicleBlacklisted(vehicle)
    if not DoesEntityExist(vehicle) then
        return true
    end
    local vehicleClass = GetVehicleClass(vehicle)
    -- Blacklist: Water (14), Helicopters (15), Planes (16)
    local blacklistedClasses = {
        [14] = true, -- Boats
        [15] = true, -- Helicopters
        [16] = true  -- Planes
    }
    return blacklistedClasses[vehicleClass] or false
end

-- Determine max PSI
local function determineMaxPsi(vehicle)
    if not DoesEntityExist(vehicle) then
        return 0
    end
    local hasTurbo = IsToggleModOn(vehicle, 18) or GetVehicleMod(vehicle, 18) ~= -1
    if not hasTurbo then
        return 0
    end
    local networkId = NetworkGetNetworkIdFromEntity(vehicle)
    if networkId == 0 then
        return Config.Mod18StandardPSI or 6.0
    end
    getVehicleRemapAsync(networkId, function(parts)
        if parts and parts.remap and remapPSI[parts.remap] then
            currentPsiMax = remapPSI[parts.remap]
        elseif parts and parts.turbo and Config.TurboPSI[parts.turbo] then
            currentPsiMax = Config.TurboPSI[parts.turbo]
        else
            currentPsiMax = Config.Mod18StandardPSI or 6.0
        end
        if Config.Debug then
            print("Set currentPsiMax:", currentPsiMax, "Remap:", parts and parts.remap or "none", "Turbo:", parts and parts.turbo or "none")
        end
        -- Get current vehicle plate for style and bezel
        local plate = GetVehicleNumberPlateText(vehicle)
        local currentStyle = appliedStyles[plate] or Config.UI.defaultStyle
        local currentBezel = appliedBezels[plate] or Config.UI.defaultBezel
        -- Force NUI update
        pushNUI('update', {
            visible = visible and not isPaused,
            psi = displayedPsi,
            maxPsi = currentPsiMax,
            rpm = GetVehicleCurrentRpm(vehicle),
            style = currentStyle,
            bezel = currentBezel,
            rpmHigh = rpmHigh,
            psiHigh = displayedPsi / currentPsiMax >= 0.85,
            lightsOn = GetVehicleLightsState(vehicle) == 1,
            highBeamsOn = select(2, GetVehicleLightsState(vehicle)) == 1
        })
    end)
    return currentPsiMax > 0 and currentPsiMax or (Config.Mod18StandardPSI or 6.0)
end

-- Force refresh max PSI
local function forceRefreshMaxPsi(vehicle)
    if not DoesEntityExist(vehicle) then
        currentPsiMax = 0
        return
    end
    local hasTurbo = IsToggleModOn(vehicle, 18) or GetVehicleMod(vehicle, 18) ~= -1
    if not hasTurbo then
        currentPsiMax = 0
        return
    end
    local networkId = NetworkGetNetworkIdFromEntity(vehicle)
    if networkId == 0 then
        currentPsiMax = Config.Mod18StandardPSI or 6.0
        return
    end
    getVehicleRemapAsync(networkId, function(parts)
        if parts and parts.remap and remapPSI[parts.remap] then
            currentPsiMax = remapPSI[parts.remap]
        elseif parts and parts.turbo and Config.TurboPSI[parts.turbo] then
            currentPsiMax = Config.TurboPSI[parts.turbo]
        else
            currentPsiMax = Config.Mod18StandardPSI or 6.0
        end
        if Config.Debug then
            print("Force refresh currentPsiMax:", currentPsiMax, "Remap:", parts and parts.remap or "none", "Turbo:", parts and parts.turbo or "none")
        end
        -- Get current vehicle plate for style and bezel
        local plate = GetVehicleNumberPlateText(vehicle)
        local currentStyle = appliedStyles[plate] or Config.UI.defaultStyle
        local currentBezel = appliedBezels[plate] or Config.UI.defaultBezel
        pushNUI('update', {
            visible = visible and not isPaused,
            psi = displayedPsi,
            maxPsi = currentPsiMax,
            rpm = GetVehicleCurrentRpm(vehicle),
            style = currentStyle,
            bezel = currentBezel,
            rpmHigh = rpmHigh,
            psiHigh = displayedPsi / currentPsiMax >= 0.85,
            lightsOn = GetVehicleLightsState(vehicle) == 1,
            highBeamsOn = select(2, GetVehicleLightsState(vehicle)) == 1
        })
    end)
end

-- Calculate boost PSI
local function calculateBoostPsi(vehicle, maxPsi)
    if maxPsi <= 0 then return 0.0 end
    local rpm = GetVehicleCurrentRpm(vehicle)
    rpm = math.max(0.0, math.min(1.2, rpm))
    local throttle = GetVehicleThrottleOffset(vehicle)
    throttle = math.max(0.0, math.min(1.0, throttle))
    local speed = GetEntitySpeed(vehicle)
    local maxSpeed = GetVehicleEstimatedMaxSpeed(vehicle)
    local speedRatio = maxSpeed > 0 and (speed / maxSpeed) or 0
    local rpmFactor = 0.0
    if rpm > 0.2 then
        rpmFactor = math.pow((rpm - 0.2) / 0.8, 1.5)
    end
    local loadFactor = 1.0
    if needleCfg.useEngineLoad then
        local expectedSpeed = rpm * 0.5
        local loadDelta = math.max(0, rpm - speedRatio)
        loadFactor = 1.0 + (loadDelta * 0.5)
    end
    local throttleFactor = throttle * 0.7 + 0.3
    local idleFactor = needleCfg.idleResponse or 0.3
    local baseFactor = lerp(idleFactor, 1.0, rpmFactor)
    local boostPercent = baseFactor * loadFactor * throttleFactor
    boostPercent = math.max(0.0, math.min(1.0, boostPercent))
    if throttle < 0.1 then
        boostPercent = boostPercent * 0.3
    end
    return boostPercent * maxPsi
end

-- Update NUI position and style
local function updateNuiPosition()
    pushNUI('updatePosition', {
        x = ui.x or 0.85, -- Fallback to match client 1
        y = ui.y or 0.75,
        scale = ui.scale or 1.0,
        style = Config.UI.defaultStyle,
        bezel = Config.UI.defaultBezel,
        bezelThickness = ui.bezelThickness or 8,
        showButtons = false
    })
    gaugeInitialized = true
    pushNUI('setVisible', { visible = false })
end

-- Initialize gauge
local function initializeGauge()
    if not gaugeInitialized then
        Wait(100)
        updateNuiPosition()
    end
    visible = true
end

-- Trigger needle sweep animation
local function triggerNeedleSweep()
    pushNUI('startSweep', {})
end

-- Toggle gauge visibility
CreateThread(function()
    if Config.Keybinds and Config.Keybinds.toggleGauge and Config.Keybinds.toggleGauge ~= 0 then
        while true do
            Wait(0)
            if IsControlJustReleased(0, Config.Keybinds.toggleGauge) then
                visible = not visible
                if visible then
                    local ped = PlayerPedId()
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh ~= 0 then
                        local hasTurbo = IsToggleModOn(veh, 18) or GetVehicleMod(veh, 18) ~= -1
                        if hasTurbo and not isVehicleBlacklisted(veh) then
                            initializeGauge()
                            forceRefreshMaxPsi(veh)
                        end
                    end
                else
                    pushNUI('setVisible', { visible = false })
                end
            end
        end
    end
end)

RegisterNetEvent('mnc-performanceparts:client:remapApplied')
AddEventHandler('mnc-performanceparts:client:remapApplied', function()
    Wait(1000) -- Wait for server to update
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        forceRefreshMaxPsi(veh)
    end
end)

-- Main update loop
CreateThread(function()
    pushNUI('setVisible', { visible = false })
    Wait(100)
    pushNUI('setVisible', { visible = false })
    
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local inVehicle = (veh ~= 0)
        
        local currentTime = GetGameTimer()
        local deltaTime = (currentTime - lastUpdateTime) / 1000.0
        lastUpdateTime = currentTime
        
        -- Check if game is paused
        local wasPaused = isPaused
        isPaused = IsPauseMenuActive()
        
        if isPaused then
            if gaugeInitialized and not wasPaused then
                pushNUI('setVisible', { visible = false })
                SetNuiFocus(false, false) -- Ensure NUI focus is released
            end
            Wait(100) -- Check more frequently when paused
        elseif not inVehicle or isVehicleBlacklisted(veh) then
            if gaugeInitialized then
                pushNUI('setVisible', { visible = false })
                SetNuiFocus(false, false) -- Ensure NUI focus is released
            end
            displayedPsi = 0.0
            targetPsi = 0.0
            currentVelocity = 0.0
            currentPsiMax = 0
            lastVehicle = 0
            engineWasRunning = false
            needsSweep = false
            Wait(500)
        else
            local hasTurbo = IsToggleModOn(veh, 18) or GetVehicleMod(veh, 18) ~= -1
            
            if not hasTurbo then
                if gaugeInitialized then
                    pushNUI('setVisible', { visible = false })
                    SetNuiFocus(false, false) -- Release NUI focus
                end
                displayedPsi = 0.0
                targetPsi = 0.0
                currentVelocity = 0.0
                currentPsiMax = 0
                engineWasRunning = false
                needsSweep = false
                Wait(250)
            else
                if not gaugeInitialized then
                    initializeGauge()
                end
                
                local plate = GetVehicleNumberPlateText(veh)
                if plate and (currentTime - lastGaugeCheck) > gaugeCheckInterval then
                    -- Fetch gauges for the current vehicle with cooldown
                    QBCore.Functions.TriggerCallback('mnc-boostgauge:getInstalledGauges', function(gauges)
                        if gauges then
                            appliedStyles[plate] = gauges.style or Config.UI.defaultStyle
                            appliedBezels[plate] = gauges.bezel or Config.UI.defaultBezel
                            if Config.Debug then
                                print("Fetched gauges for plate:", plate, "Style:", appliedStyles[plate], "Bezel:", appliedBezels[plate])
                            end
                            -- Ensure gauge is visible after fetching styles if not paused
                            if not isPaused then
                                pushNUI('setVisible', { visible = true })
                                pushNUI('updateStyle', {
                                    style = appliedStyles[plate],
                                    bezel = appliedBezels[plate]
                                })
                            end
                        end
                    end, plate)
                    lastGaugeCheck = currentTime
                end
                local currentStyle = appliedStyles[plate] or Config.UI.defaultStyle
                local currentBezel = appliedBezels[plate] or Config.UI.defaultBezel
                
                -- Check engine state for sweep animation
                local engineRunning = GetIsVehicleEngineRunning(veh)
                if engineRunning and not engineWasRunning and not needsSweep then
                    needsSweep = true
                    triggerNeedleSweep()
                end
                engineWasRunning = engineRunning
                
                -- Check if vehicle changed or periodic refresh
                if veh ~= lastVehicle then
                    lastVehicle = veh
                    displayedPsi = 0.0
                    targetPsi = 0.0
                    currentVelocity = 0.0
                    currentPsiMax = Config.Mod18StandardPSI or 6.0
                    forceRefreshMaxPsi(veh)
                    lastRemapCheck = currentTime
                    engineWasRunning = false
                    needsSweep = false
                elseif (currentTime - lastRemapCheck) > remapCheckInterval then
                    -- Periodic refresh only if turbo is present
                    forceRefreshMaxPsi(veh)
                    lastRemapCheck = currentTime
                end
                
                -- Calculate target boost PSI
                targetPsi = calculateBoostPsi(veh, currentPsiMax)
                
                -- Smooth the displayed value
                local smoothTime = 1.0 / math.max(1.0, needleCfg.smoothing or 6.0)
                displayedPsi = smoothDamp(displayedPsi, targetPsi, smoothTime, deltaTime)
                
                -- Clamp final value
                displayedPsi = math.max(0.0, math.min(currentPsiMax, displayedPsi))
                
                -- Check if RPM is high for glow effect
                local rpm = GetVehicleCurrentRpm(veh)
                rpmHigh = rpm > 0.85
                
                -- Check if PSI is high for warning
                local psiHigh = (currentPsiMax > 0) and (displayedPsi / currentPsiMax >= 0.85) or false
                
                -- Check vehicle lights state
                local lightsOn, highBeamsOn = GetVehicleLightsState(veh)
                local areLightsOn = lightsOn == 1
                local areHighBeamsOn = highBeamsOn == 1
                
                -- Send update to NUI
                if visible and gaugeInitialized and not isPaused then
                    pushNUI('update', {
                        visible = true,
                        psi = displayedPsi,
                        maxPsi = currentPsiMax,
                        rpm = rpm,
                        style = currentStyle,
                        bezel = currentBezel,
                        rpmHigh = rpmHigh,
                        psiHigh = psiHigh,
                        lightsOn = areLightsOn,
                        highBeamsOn = areHighBeamsOn
                    })
                end
                
                Wait(16) -- ~60 FPS update rate
            end
        end
        
        Wait(0)
    end
end)

RegisterNetEvent('mnc-boostgauge:syncStyleBezel', function(style, bezel)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and style and bezel then
        local plate = GetVehicleNumberPlateText(veh)
        if plate then
            appliedStyles[plate] = style or Config.UI.defaultStyle
            appliedBezels[plate] = bezel or Config.UI.defaultBezel
            if Config.Debug then
                print("Synced plate:", plate, "style:", appliedStyles[plate], "bezel:", appliedBezels[plate])
            end
            if not isPaused then
                pushNUI('setVisible', { visible = true })
                pushNUI('updateStyle', {
                    style = appliedStyles[plate],
                    bezel = appliedBezels[plate]
                })
            end
        end
    else
        if Config.Debug then
            print("syncStyleBezel failed: No vehicle or invalid style/bezel")
        end
    end
end)

-- Command to change style, bezel, or preset
RegisterCommand('bgauge', function(source, args)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    -- Job lock check
    if Config.LockCommandToJobs then
        local PlayerData = QBCore.Functions.GetPlayerData()
        if not PlayerData or not PlayerData.job or not Config.AllowedJobs[PlayerData.job.name] then
            ox_lib:notify({
                title = 'Error',
                description = 'You are not authorized to use this command.',
                type = 'error'
            })
            if Config.Debug then
                print("bgauge command denied: Player job not allowed -", PlayerData.job and PlayerData.job.name or "unknown")
            end
            return
        end
    end

    if not veh or veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
        ox_lib:notify({
            title = 'Error',
            description = 'You must be in the driver seat of a vehicle.',
            type = 'error'
        })
        return
    end
    if isVehicleBlacklisted(veh) then
        ox_lib:notify({
            title = 'Error',
            description = 'Boost gauge cannot be used in this vehicle type.',
            type = 'error'
        })
        return
    end
    local plate = GetVehicleNumberPlateText(veh)
    if not plate then
        ox_lib:notify({
            title = 'Error',
            description = 'Unable to identify vehicle.',
            type = 'error'
        })
        return
    end
    if args[1] and args[1]:lower():sub(1, 6) == 'preset' then
        local presetKey = args[1]:lower()
        if Config.Presets[presetKey] then
            local preset = Config.Presets[presetKey]
            appliedStyles[plate] = preset.style
            appliedBezels[plate] = preset.bezel
            TriggerServerEvent('mnc-boostgauge:saveVehicleGauge', plate, 'style', preset.style, nil, nil)
            TriggerServerEvent('mnc-boostgauge:saveVehicleGauge', plate, 'bezel', preset.bezel, nil, nil)
            if not isPaused then
                pushNUI('setVisible', { visible = true })
                pushNUI('updateStyle', {
                    style = appliedStyles[plate],
                    bezel = appliedBezels[plate]
                })
            end
            ox_lib:notify({
                title = 'Success',
                description = 'Applied preset ' .. preset.label .. ' for vehicle ' .. plate,
                type = 'success'
            })
        else
            ox_lib:notify({
                title = 'Error',
                description = 'Invalid preset! Use preset1 to preset20',
                type = 'error'
            })
        end
        return
    end
    local style = tonumber(args[1])
    local bezel = tonumber(args[2])
    
    if style and style >= 1 and style <= Config.StylesCount then
        appliedStyles[plate] = style
        TriggerServerEvent('mnc-boostgauge:saveVehicleGauge', plate, 'style', style, nil, nil)
    else
        ox_lib:notify({
            title = 'Error',
            description = 'Invalid style! Use 1-' .. Config.StylesCount,
            type = 'error'
        })
        return
    end
    
    if bezel and bezel >= 1 and bezel <= Config.BezelsCount then
        appliedBezels[plate] = bezel
        TriggerServerEvent('mnc-boostgauge:saveVehicleGauge', plate, 'bezel', bezel, nil, nil)
    else
        ox_lib:notify({
            title = 'Error',
            description = 'Invalid bezel! Use 1-' .. Config.BezelsCount,
            type = 'error'
        })
        return
    end
    
    if not isPaused then
        pushNUI('setVisible', { visible = true })
        pushNUI('updateStyle', {
            style = appliedStyles[plate],
            bezel = appliedBezels[plate]
        })
    end
    ox_lib:notify({
        title = 'Success',
        description = 'Gauge style set to ' .. appliedStyles[plate] .. ', bezel set to ' .. appliedBezels[plate] .. ' for vehicle ' .. plate,
        type = 'success'
    })
end, false)

-- Load saved gauges
RegisterNetEvent('mnc-boostgauge:loadGauges', function(gauges)
    appliedStyles = gauges.styles or {}
    appliedBezels = gauges.bezels or {}
    if Config.Debug then
        print("loadGauges: Loaded styles:", json.encode(appliedStyles), "Bezels:", json.encode(appliedBezels))
    end
end)