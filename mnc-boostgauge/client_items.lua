local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports['ox_lib']

-- State variables
local appliedStyles = {}
local appliedBezels = {}

-- Helper function to get item name from style or bezel ID
local function GetItemNameFromId(partType, value)
    if partType == 'style' then
        for itemName, styleId in pairs(Config.StyleItems) do
            if styleId == value then
                return itemName
            end
        end
    elseif partType == 'bezel' then
        for itemName, bezelId in pairs(Config.BezelItems) do
            if bezelId == value then
                return itemName
            end
        end
    end
    return nil
end

-- Helper function to get item label from item name
local function GetItemLabel(itemName)
    local item = QBCore.Shared.Items[itemName]
    if item and item.label then
        return item.label
    end
    -- Fallback to formatted item name if label not found
    return itemName:gsub("^%l", string.upper)
end

-- ==============================
-- Apply Style / Bezel / Preset to Vehicle
-- ==============================
local function ApplyPartToVehicle(vehicle, partType, partName, value, replacedStyleItem, replacedBezelItem, itemUsed)
    if not DoesEntityExist(vehicle) then
        if Config.Debug then
            print("ApplyPartToVehicle: Vehicle does not exist")
        end
        return false
    end
    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then
        if Config.Debug then
            print("ApplyPartToVehicle: Unable to get vehicle plate")
        end
        return false
    end

    local itemLabel = GetItemLabel(itemUsed) -- Use itemUsed for label
    local replacedStyleLabel = replacedStyleItem and GetItemLabel(replacedStyleItem) or nil
    local replacedBezelLabel = replacedBezelItem and GetItemLabel(replacedBezelItem) or nil

    if partType == 'style' then
        appliedStyles[plate] = value
        TriggerServerEvent('mnc-boostgauge:saveVehicleGauge', plate, 'style', value, replacedStyleItem, itemUsed)
        lib:notify({ title = 'Boost Gauge', description = ('Applied %s'):format(itemLabel), type = 'success' })
        if replacedStyleItem then
            lib:notify({ title = 'Boost Gauge', description = ('Received %s back'):format(replacedStyleLabel), type = 'inform' })
        end
        TriggerEvent('mnc-boostgauge:syncStyleBezel', value, appliedBezels[plate] or Config.UI.defaultBezel)
        if Config.Debug then
            print("Applied style:", value, "to plate:", plate, "Replaced style item:", replacedStyleItem or "none")
        end
        return true
    elseif partType == 'bezel' then
        appliedBezels[plate] = value
        TriggerServerEvent('mnc-boostgauge:saveVehicleGauge', plate, 'bezel', value, replacedBezelItem, itemUsed)
        lib:notify({ title = 'Boost Gauge', description = ('Applied %s'):format(itemLabel), type = 'success' })
        if replacedBezelItem then
            lib:notify({ title = 'Boost Gauge', description = ('Received %s back'):format(replacedBezelLabel), type = 'inform' })
        end
        TriggerEvent('mnc-boostgauge:syncStyleBezel', appliedStyles[plate] or Config.UI.defaultStyle, value)
        if Config.Debug then
            print("Applied bezel:", value, "to plate:", plate, "Replaced bezel item:", replacedBezelItem or "none")
        end
        return true
    elseif partType == 'preset' then
        local preset = Config.Presets[partName]
        if preset then
            local currentStyle = appliedStyles[plate] or Config.UI.defaultStyle
            local currentBezel = appliedBezels[plate] or Config.UI.defaultBezel
            appliedStyles[plate] = preset.style
            appliedBezels[plate] = preset.bezel
            -- Save both style and bezel to the server
            TriggerServerEvent('mnc-boostgauge:saveVehicleGauge', plate, 'style', preset.style, GetItemNameFromId('style', currentStyle), itemUsed)
            TriggerServerEvent('mnc-boostgauge:saveVehicleGauge', plate, 'bezel', preset.bezel, GetItemNameFromId('bezel', currentBezel), itemUsed)
            lib:notify({ title = 'Boost Gauge', description = ('Applied preset %s (Style: %s, Bezel: %s)'):format(preset.label, GetItemLabel(GetItemNameFromId('style', preset.style)), GetItemLabel(GetItemNameFromId('bezel', preset.bezel))), type = 'success' })
            if replacedStyleItem or replacedBezelItem then
                local returnMsg = 'Received back: '
                if replacedStyleItem then
                    returnMsg = returnMsg .. replacedStyleLabel
                end
                if replacedBezelItem then
                    returnMsg = returnMsg .. (replacedStyleItem and ', ' or '') .. replacedBezelLabel
                end
                lib:notify({ title = 'Boost Gauge', description = returnMsg, type = 'inform' })
            end
            TriggerEvent('mnc-boostgauge:syncStyleBezel', preset.style, preset.bezel)
            if Config.Debug then
                print("Applied preset:", partName, "style:", preset.style, "bezel:", preset.bezel, "to plate:", plate, "Replaced style:", replacedStyleItem or "none", "Replaced bezel:", replacedBezelItem or "none")
            end
            return true
        else
            if Config.Debug then
                print("ApplyPartToVehicle: Invalid preset:", partName)
            end
            lib:notify({ title = 'Boost Gauge', description = 'Invalid preset.', type = 'error' })
            return false
        end
    end
    return false
end

-- ==============================
-- Perform Installation (Minigame or Progress)
-- ==============================
local function PerformInstallation(itemLabel, callback)
    local installConfig = Config.Installation or {}
    local requireMinigame = installConfig.requireMinigame ~= nil and installConfig.requireMinigame or false
    local minigameSuccess = true -- Default to true if no minigame

    -- Step 1: Perform minigame if required
    if requireMinigame then
        local difficulty = installConfig.minigameDifficulty or 2
        local keys = {'w', 'a', 's', 'd'} -- Keys to use in skillcheck
        
        -- Adjust skillcheck based on difficulty
        local skillcheckConfig = {}
        if difficulty == 1 then
            skillcheckConfig = {'easy', 'easy', 'easy'}
        elseif difficulty == 2 then
            skillcheckConfig = {'easy', 'easy', {areaSize = 60, speedMultiplier = 1}}
        elseif difficulty == 3 then
            skillcheckConfig = {'medium', 'medium', {areaSize = 50, speedMultiplier = 1.5}}
        else
            skillcheckConfig = {'easy', 'easy', 'easy'}
        end

        -- Perform skillcheck
        minigameSuccess = lib:skillCheck(skillcheckConfig, keys)

        -- If minigame failed, return immediately
        if not minigameSuccess then
            callback(false)
            return
        end
    end

    -- Step 2: Perform progress bar/circle after minigame success (or if no minigame)
    local duration = installConfig.progressDuration or 5000
    local progressType = installConfig.progressType or 'bar'
    
    local progressConfig = {
        duration = duration,
        label = ('Installing %s...'):format(itemLabel),
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = false, combat = true },
    }

    -- Add animation if configured
    if installConfig.useAnimation then
        progressConfig.anim = {
            dict = installConfig.animDict or 'mini@repair',
            clip = installConfig.animClip or 'fixing_a_ped'
        }
    end

    -- Choose progress type and execute
    local progressSuccess = false
    if progressType == 'circle' then
        progressSuccess = lib:progressCircle(progressConfig)
    else
        progressSuccess = lib:progressBar(progressConfig)
    end

    callback(progressSuccess)
end

-- ==============================
-- Useable Item Logic
-- ==============================
RegisterNetEvent('mnc-boostgauge:useItem', function(itemName, partType, partValue)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local seat = -1

    if not vehicle or vehicle == 0 then
        lib:notify({ title = 'Boost Gauge', description = 'You must be in a vehicle.', type = 'error' })
        if Config.Debug then
            print("useItem: Player not in vehicle")
        end
        return
    end

    if GetPedInVehicleSeat(vehicle, seat) ~= ped then
        lib:notify({ title = 'Boost Gauge', description = 'You must be in the driver seat.', type = 'error' })
        if Config.Debug then
            print("useItem: Player not in driver seat")
        end
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then
        lib:notify({ title = 'Boost Gauge', description = 'Unable to identify vehicle.', type = 'error' })
        if Config.Debug then
            print("useItem: Unable to get vehicle plate")
        end
        return
    end

    -- Check if vehicle has turbo (mod 18) installed
    local hasTurbo = IsToggleModOn(vehicle, 18) or GetVehicleMod(vehicle, 18) ~= -1
    if not hasTurbo then
        lib:notify({ title = 'Boost Gauge', description = 'Vehicle requires a turbo to apply this item.', type = 'error' })
        if Config.Debug then
            print("useItem: Vehicle has no turbo")
        end
        return
    end

    -- Get item label for progress bar
    local itemLabel = GetItemLabel(itemName)

    -- Fetch current gauges from server to ensure sync
    QBCore.Functions.TriggerCallback('mnc-boostgauge:getInstalledGauges', function(gauges)
        if not gauges then
            if Config.Debug then
                print("useItem: Failed to fetch gauges for plate:", plate)
            end
            lib:notify({ title = 'Boost Gauge', description = 'Failed to fetch vehicle gauges.', type = 'error' })
            return
        end

        -- Update local state
        appliedStyles[plate] = gauges.style or Config.UI.defaultStyle
        appliedBezels[plate] = gauges.bezel or Config.UI.defaultBezel

        -- Check if the item matches the currently applied style or bezel
        local replacedStyleItem, replacedBezelItem
        if partType == 'preset' then
            local preset = Config.Presets[partValue]
            if not preset then
                lib:notify({ title = 'Boost Gauge', description = 'Invalid preset.', type = 'error' })
                if Config.Debug then
                    print("useItem: Invalid preset:", partValue)
                end
                return
            end
            local currentStyle = appliedStyles[plate] or Config.UI.defaultStyle
            local currentBezel = appliedBezels[plate] or Config.UI.defaultBezel
            if currentStyle == preset.style and currentBezel == preset.bezel then
                lib:notify({ title = 'Boost Gauge', description = ('Preset %s is already applied.'):format(preset.label), type = 'error' })
                if Config.Debug then
                    print("useItem: Preset already applied -", partValue)
                end
                return
            end
            replacedStyleItem = GetItemNameFromId('style', currentStyle)
            replacedBezelItem = GetItemNameFromId('bezel', currentBezel)
        else
            local currentPartValue = partType == 'style' and appliedStyles[plate] or appliedBezels[plate]
            if currentPartValue == partValue then
                lib:notify({ title = 'Boost Gauge', description = ('%s is already applied.'):format(itemLabel), type = 'error' })
                if Config.Debug then
                    print("useItem: Item already applied -", partType, ":", partValue)
                end
                return
            end
            if partType == 'style' then
                replacedStyleItem = GetItemNameFromId('style', currentPartValue)
            else
                replacedBezelItem = GetItemNameFromId('bezel', currentPartValue)
            end
        end

        -- Perform installation with minigame or progress bar
        PerformInstallation(itemLabel, function(success)
            if success then
                ApplyPartToVehicle(vehicle, partType, partValue, partValue, replacedStyleItem, replacedBezelItem, itemName)
            else
                lib:notify({ title = 'Boost Gauge', description = 'Installation cancelled or failed.', type = 'error' })
                if Config.Debug then
                    print("useItem: Installation cancelled for", itemName)
                end
            end
        end)
    end, plate)
end)

-- ==============================
-- Update Boost Gauge UI
-- ==============================
RegisterNetEvent('mnc-boostgauge:syncStyleBezel', function(style, bezel)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle and style and bezel then
        local plate = GetVehicleNumberPlateText(vehicle)
        if plate then
            appliedStyles[plate] = style
            appliedBezels[plate] = bezel
            SendNUIMessage({
                action = 'updateStyle',
                data = { style = style, bezel = bezel }
            })
            if Config.Debug then
                print("syncStyleBezel: Updated plate:", plate, "style:", style, "bezel:", bezel)
            end
        else
            if Config.Debug then
                print("syncStyleBezel: Failed - No valid plate")
            end
        end
    else
        if Config.Debug then
            print("syncStyleBezel: Failed - Invalid vehicle/style/bezel - Vehicle:", vehicle, "Style:", style, "Bezel:", bezel)
        end
    end
end)

-- ==============================
-- Load Saved Gauges
-- ==============================
RegisterNetEvent('mnc-boostgauge:loadGauges', function(gauges)
    appliedStyles = gauges.styles or {}
    appliedBezels = gauges.bezels or {}
    if Config.Debug then
        print("loadGauges: Loaded styles:", json.encode(appliedStyles), "Bezels:", json.encode(appliedBezels))
    end
end)