local QBCore = nil
local currentSheet = nil
local activeDiscounts = {} -- Store active discounts per location

-- Wait for QBCore
CreateThread(function()
    while not QBCore do
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbcore') == 'started' then
            local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and obj then
                QBCore = obj
                if Config.Debug then
                    print("^2[mnc-pricesheets]^7 QBCore loaded")
                end
            end
        end
        Wait(500)
    end
    
    while not GetResourceState('ox_lib') or GetResourceState('ox_lib') ~= 'started' do
        if Config.Debug then
            print("^3[mnc-pricesheets]^7 Waiting for ox_lib...")
        end
        Wait(500)
    end
    
    if Config.Debug then
        print("^2[mnc-pricesheets]^7 ox_lib ready")
    end
    
    -- Create blips
    for _, sheet in ipairs(Config.PriceSheets) do
        if sheet.blip and sheet.blip.enabled then
            local blip = AddBlipForCoord(sheet.location.x, sheet.location.y, sheet.location.z)
            SetBlipSprite(blip, sheet.blip.sprite)
            SetBlipColour(blip, sheet.blip.color)
            SetBlipScale(blip, sheet.blip.scale or 0.7)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(sheet.blip.name or sheet.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Check if player has permission for a sheet
local function HasSheetAccess(sheet)
    if not sheet.jobs or #sheet.jobs == 0 then
        return true
    end
    
    local Player = QBCore.Functions.GetPlayerData()
    for _, job in ipairs(sheet.jobs) do
        if Player.job.name == job then
            return true
        end
    end
    
    return false
end

-- Check if player can apply discounts
local function CanApplyDiscounts()
    local Player = QBCore.Functions.GetPlayerData()
    local jobName = Player.job.name
    local jobGrade = Player.job.grade.level
    
    if Config.DiscountPermissions[jobName] then
        for _, grade in ipairs(Config.DiscountPermissions[jobName]) do
            if jobGrade >= grade then
                return true
            end
        end
    end
    
    return false
end

-- Open price sheet
local function OpenPriceSheet(sheetIndex)
    currentSheet = sheetIndex
    local sheet = Config.PriceSheets[sheetIndex]
    
    if not HasSheetAccess(sheet) then
        lib.notify({
            title = 'Access Denied',
            description = 'You do not have access to this price sheet.',
            type = 'error'
        })
        return
    end
    
    SetNuiFocus(true, true)
    
    -- Request active discounts and specials from server
    QBCore.Functions.TriggerCallback('mnc-pricesheets:getPersistentData', function(pdata)
        activeDiscounts[sheetIndex] = pdata.discounts or {}
        
        if Config.Debug then
            print("^2[mnc-pricesheets CLIENT]^7 Received discounts from server:")
            print(json.encode(pdata.discounts, {indent = true}))
        end
        
        -- Combine config specials with dynamic specials
        local allSpecials = {}
        
        -- Add static specials from config
        if sheet.specialOffers then
            for _, s in ipairs(sheet.specialOffers) do
                table.insert(allSpecials, {
                    name = s.name,
                    description = s.description,
                    originalPrice = s.originalPrice,
                    salePrice = s.salePrice,
                    image = s.image,
                    type = 'static'
                })
            end
        end
        
        -- Add dynamic specials from database
        if pdata.specials then
            for _, s in ipairs(pdata.specials) do
                table.insert(allSpecials, {
                    id = s.id,
                    name = s.name,
                    description = s.description,
                    originalPrice = s.originalPrice,
                    salePrice = s.salePrice,
                    image = s.image,
                    type = 'dynamic'
                })
            end
        end
        
        -- Build watermark path if it exists
        local watermarkPath = nil
        if sheet.watermark and sheet.watermark ~= "" then
            watermarkPath = (Config.WatermarkImagePath or "nui://mnc-pricesheets/html/images/") .. sheet.watermark
        end
        
        SendNUIMessage({
            action = 'openSheet',
            sheetName = sheet.name,
            theme = sheet.theme,
            categories = sheet.categories,
            specialOffers = allSpecials,
            canDiscount = CanApplyDiscounts(),
            activeDiscounts = activeDiscounts[sheetIndex] or {},
            imagePath = Config.InventoryImagePath or "nui://qb-inventory/html/images/",
            watermark = watermarkPath
        })
    end, sheetIndex)
end

-- NUI Callbacks
RegisterNUICallback('closeSheet', function(data, cb)
    SetNuiFocus(false, false)
    currentSheet = nil
    cb('ok')
end)

RegisterNUICallback('applyDiscount', function(data, cb)
    if not CanApplyDiscounts() then
        lib.notify({
            title = 'Access Denied',
            description = 'You do not have permission to apply discounts.',
            type = 'error'
        })
        cb('error')
        return
    end
    
    if data.discount > Config.MaxDiscountPercent then
        lib.notify({
            title = 'Invalid Discount',
            description = 'Maximum discount is ' .. Config.MaxDiscountPercent .. '%',
            type = 'error'
        })
        cb('error')
        return
    end
    
    if Config.Debug then
        print(string.format("^2[mnc-pricesheets CLIENT]^7 Applying discount: Sheet=%d, Category=%s, Index=%s, Discount=%d", 
            currentSheet, data.category, tostring(data.itemIndex), data.discount))
    end
    
    TriggerServerEvent('mnc-pricesheets:applyDiscount', currentSheet, data.category, data.itemIndex, data.discount)
    cb('ok')
end)

RegisterNUICallback('removeDiscount', function(data, cb)
    if not CanApplyDiscounts() then
        cb('error')
        return
    end
    
    if Config.Debug then
        print(string.format("^2[mnc-pricesheets CLIENT]^7 Removing discount: Sheet=%d, Category=%s, Index=%s", 
            currentSheet, data.category, tostring(data.itemIndex)))
    end
    
    TriggerServerEvent('mnc-pricesheets:removeDiscount', currentSheet, data.category, data.itemIndex)
    cb('ok')
end)

RegisterNUICallback('createSpecial', function(data, cb)
    if not CanApplyDiscounts() then
        lib.notify({
            title = 'Access Denied',
            description = 'You do not have permission to create specials.',
            type = 'error'
        })
        cb('error')
        return
    end
    
    TriggerServerEvent('mnc-pricesheets:createSpecial', currentSheet, data.name, data.description, data.originalPrice, data.salePrice, data.image)
    cb('ok')
end)

RegisterNUICallback('removeSpecial', function(data, cb)
    if not CanApplyDiscounts() then
        cb('error')
        return
    end
    
    if Config.Debug then
        print(string.format("^2[mnc-pricesheets CLIENT]^7 Removing special: Sheet=%d, ID=%s", 
            currentSheet, tostring(data.specialId)))
    end
    
    TriggerServerEvent('mnc-pricesheets:removeSpecial', currentSheet, data.specialId)
    cb('ok')
end)

-- Server events - UPDATED FOR INSTANT REFRESH
RegisterNetEvent('mnc-pricesheets:updateDiscounts', function(sheetIndex, discounts)
    activeDiscounts[sheetIndex] = discounts or {}
    
    if Config.Debug then
        print("^2[mnc-pricesheets CLIENT]^7 Received discount update for sheet " .. sheetIndex)
        print(json.encode(discounts, {indent = true}))
    end
    
    if currentSheet == sheetIndex then
        SendNUIMessage({
            action = 'updateDiscounts',
            activeDiscounts = discounts or {}
        })
        -- Force full refresh to update discounted items in specials tab
        TriggerEvent('mnc-pricesheets:refreshCurrentSheet')
    end
end)

-- FIXED: Updated to properly refresh the UI when specials are added/removed
RegisterNetEvent('mnc-pricesheets:updateSpecials', function(sheetIndex, specials)
    if Config.Debug then
        print("^2[mnc-pricesheets CLIENT]^7 Received specials update for sheet " .. sheetIndex)
        print("^2[mnc-pricesheets CLIENT]^7 Specials data:")
        print(json.encode(specials, {indent = true}))
    end
    
    if currentSheet == sheetIndex then
        -- Force full refresh to properly update the UI with new specials data
        TriggerEvent('mnc-pricesheets:refreshCurrentSheet')
    end
end)

-- Force full UI refresh when data changes
RegisterNetEvent('mnc-pricesheets:refreshCurrentSheet', function()
    if not currentSheet then return end
    
    if Config.Debug then
        print("^2[mnc-pricesheets CLIENT]^7 Refreshing current sheet " .. currentSheet)
    end
    
    QBCore.Functions.TriggerCallback('mnc-pricesheets:getPersistentData', function(pdata)
        activeDiscounts[currentSheet] = pdata.discounts or {}
        
        local sheet = Config.PriceSheets[currentSheet]
        local allSpecials = {}
        
        -- Re-add static specials from config
        if sheet.specialOffers then
            for _, s in ipairs(sheet.specialOffers) do
                table.insert(allSpecials, {
                    name = s.name,
                    description = s.description,
                    originalPrice = s.originalPrice,
                    salePrice = s.salePrice,
                    image = s.image,
                    type = 'static'
                })
            end
        end
        
        -- Add dynamic specials from server
        if pdata.specials then
            for _, s in ipairs(pdata.specials) do
                table.insert(allSpecials, {
                    id = s.id,
                    name = s.name,
                    description = s.description,
                    originalPrice = s.originalPrice,
                    salePrice = s.salePrice,
                    image = s.image,
                    type = 'dynamic'
                })
            end
        end
        
        if Config.Debug then
            print("^2[mnc-pricesheets CLIENT]^7 Refreshing with " .. #allSpecials .. " total specials")
        end
        
        -- Rebuild watermark
        local watermarkPath = nil
        if sheet.watermark and sheet.watermark ~= "" then
            watermarkPath = (Config.WatermarkImagePath or "nui://mnc-pricesheets/html/images/") .. sheet.watermark
        end
        
        SendNUIMessage({
            action = 'openSheet',
            sheetName = sheet.name,
            theme = sheet.theme,
            categories = sheet.categories,
            specialOffers = allSpecials,
            canDiscount = CanApplyDiscounts(),
            activeDiscounts = activeDiscounts[currentSheet],
            imagePath = Config.InventoryImagePath or "nui://qb-inventory/html/images/",
            watermark = watermarkPath
        })
    end, currentSheet)
end)

RegisterNetEvent('mnc-pricesheets:discountApplied', function()
    lib.notify({
        title = 'Discount Applied',
        description = 'The discount has been applied successfully.',
        type = 'success'
    })
end)

RegisterNetEvent('mnc-pricesheets:discountRemoved', function()
    lib.notify({
        title = 'Discount Removed',
        description = 'The discount has been removed.',
        type = 'success'
    })
end)

RegisterNetEvent('mnc-pricesheets:specialCreated', function()
    lib.notify({
        title = 'Special Created',
        description = 'The special offer has been created successfully.',
        type = 'success'
    })
end)

RegisterNetEvent('mnc-pricesheets:specialRemoved', function()
    lib.notify({
        title = 'Special Removed',
        description = 'The special offer has been removed.',
        type = 'success'
    })
end)

-- Interaction zones
CreateThread(function()
    local textShown = {}
    
    while true do
        local sleep = 1500
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        
        for i, sheet in ipairs(Config.PriceSheets) do
            local dist = #(pos - sheet.location)
            
            if dist < 5.0 then
                sleep = 0
                DrawMarker(36, sheet.location.x, sheet.location.y, sheet.location.z + 1.0, 
                    0, 0, 0, 0, 0, 0, 0.8, 0.8, 0.8, 0, 255, 150, 150, false, false, 2, nil, nil, false)
                
                if dist < 2.0 then
                    if not textShown[i] then
                        lib.showTextUI('[E] - View ' .. sheet.name, {
                            position = 'left-center',
                            style = {
                                backgroundColor = sheet.theme == 'blue' and '#1a73e8' or
                                                 sheet.theme == 'red' and '#d32f2f' or
                                                 sheet.theme == 'green' and '#2e7d32' or
                                                 sheet.theme == 'purple' and '#7b1fa2' or
                                                 sheet.theme == 'orange' and '#f57c00' or '#1a73e8',
                                color = '#ffffff',
                                borderRadius = '8px',
                                padding = '10px'
                            }
                        })
                        textShown[i] = true
                    end
                    
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        textShown[i] = false
                        OpenPriceSheet(i)
                    end
                else
                    if textShown[i] then
                        lib.hideTextUI()
                        textShown[i] = false
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ESC key handling
RegisterNUICallback('escape', function(data, cb)
    SetNuiFocus(false, false)
    currentSheet = nil
    cb('ok')
end)