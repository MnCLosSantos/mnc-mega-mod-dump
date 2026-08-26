local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports['ox_lib']

local function GetItemNameFromId(partType, value)
    if partType == 'style' then
        for itemName, styleId in pairs(Config.StyleItems) do
            if styleId == value then return itemName end
        end
    elseif partType == 'bezel' then
        for itemName, bezelId in pairs(Config.BezelItems) do
            if bezelId == value then return itemName end
        end
    end
    return nil
end

local function GetItemLabel(itemName)
    if not itemName then return nil end
    local item = QBCore.Shared.Items[itemName]
    if item and item.label then return item.label end
    return itemName:gsub("^%l", string.upper)
end

local function PerformRemoval(callback)
    local installConfig = Config.Installation or {}
    local requireMinigame = installConfig.requireMinigame ~= nil and installConfig.requireMinigame or false
    local minigameSuccess = true

    if requireMinigame then
        local difficulty = installConfig.minigameDifficulty or 2
        local keys = {'w', 'a', 's', 'd'}
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

        minigameSuccess = lib:skillCheck(skillcheckConfig, keys)
        if not minigameSuccess then
            callback(false)
            return
        end
    end

    local duration = installConfig.progressDuration or 5000
    local progressType = installConfig.progressType or 'bar'
    local progressConfig = {
        duration = duration,
        label = 'Removing Boost Gauge...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = false, combat = true },
    }
    if installConfig.useAnimation then
        progressConfig.anim = {
            dict = installConfig.animDict or 'mini@repair',
            clip = installConfig.animClip or 'fixing_a_ped'
        }
    end

    local progressSuccess = false
    if progressType == 'circle' then
        progressSuccess = lib:progressCircle(progressConfig)
    else
        progressSuccess = lib:progressBar(progressConfig)
    end
    callback(progressSuccess)
end

RegisterNetEvent('mnc-boostgauge:useRemovalItem', function(itemName)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if not vehicle or vehicle == 0 then
        lib:notify({ title = 'Boost Gauge', description = 'You must be in a vehicle.', type = 'error' })
        if Config.Debug then
            print("useRemovalItem: Player not in vehicle")
        end
        return
    end

    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        lib:notify({ title = 'Boost Gauge', description = 'You must be in the driver seat.', type = 'error' })
        if Config.Debug then
            print("useRemovalItem: Player not in driver seat")
        end
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then
        lib:notify({ title = 'Boost Gauge', description = 'Unable to identify vehicle.', type = 'error' })
        if Config.Debug then
            print("useRemovalItem: Unable to get vehicle plate")
        end
        return
    end

    QBCore.Functions.TriggerCallback('mnc-boostgauge:getInstalledGauges', function(gauges)
        if not gauges then
            lib:notify({ title = 'Boost Gauge', description = 'Failed to fetch vehicle gauges.', type = 'error' })
            if Config.Debug then
                print("useRemovalItem: Failed to fetch gauges for plate:", plate)
            end
            return
        end

        if gauges.installed == false then
            lib:notify({ title = 'Boost Gauge', description = 'This vehicle has no gauge installed.', type = 'error' })
            if Config.Debug then
                print("useRemovalItem: No gauge installed for plate:", plate)
            end
            return
        end

        local styleItem = GetItemNameFromId('style', gauges.style)
        local bezelItem = GetItemNameFromId('bezel', gauges.bezel)

        PerformRemoval(function(success)
            if success then
                TriggerServerEvent('mnc-boostgauge:removeVehicleGauge', plate, styleItem, bezelItem)
                TriggerEvent('mnc-boostgauge:gaugeRemoved', plate)

                lib:notify({ title = 'Boost Gauge', description = 'Gauge removed from vehicle.', type = 'success' })
                if styleItem or bezelItem then
                    local returnMsg = 'Received back: '
                    if styleItem then
                        returnMsg = returnMsg .. GetItemLabel(styleItem)
                    end
                    if bezelItem then
                        returnMsg = returnMsg .. (styleItem and ', ' or '') .. GetItemLabel(bezelItem)
                    end
                    lib:notify({ title = 'Boost Gauge', description = returnMsg, type = 'inform' })
                end

                if Config.Debug then
                    print("useRemovalItem: Removed gauge for plate:", plate, "Returned style:", styleItem or "none", "Returned bezel:", bezelItem or "none")
                end
            else
                lib:notify({ title = 'Boost Gauge', description = 'Removal cancelled or failed.', type = 'error' })
                if Config.Debug then
                    print("useRemovalItem: Removal cancelled for", itemName)
                end
            end
        end)
    end, plate)
end)


local gaugeVisibleNow = true 
local lastCheckedPlate = nil
local lastCheckTime = 0
local checkInterval = 1000 -- ms


RegisterNetEvent('mnc-boostgauge:gaugeRemoved', function(plate)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and plate and GetVehicleNumberPlateText(veh) == plate and gaugeVisibleNow then
        gaugeVisibleNow = false
        TriggerEvent('mnc-boostgauge:setVisible', false)
        if Config.Debug then
            print("gaugeRemoved: Hid gauge immediately for plate:", plate)
        end
    end
end)


CreateThread(function()
    while true do
        Wait(250)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if not veh or veh == 0 then
            if not gaugeVisibleNow then
                gaugeVisibleNow = true
                TriggerEvent('mnc-boostgauge:setVisible', true)
            end
            lastCheckedPlate = nil
        else
            local plate = GetVehicleNumberPlateText(veh)
            local now = GetGameTimer()
            if plate and (plate ~= lastCheckedPlate or (now - lastCheckTime) > checkInterval) then
                lastCheckedPlate = plate
                lastCheckTime = now
                QBCore.Functions.TriggerCallback('mnc-boostgauge:getInstalledGauges', function(gauges)
                    local installed = not gauges or gauges.installed ~= false
                    if installed ~= gaugeVisibleNow then
                        gaugeVisibleNow = installed
                        TriggerEvent('mnc-boostgauge:setVisible', installed)
                        if Config.Debug then
                            print("gauge-removal poll: plate", plate, "installed:", installed)
                        end
                    end
                end, plate)
            end
        end
    end
end)