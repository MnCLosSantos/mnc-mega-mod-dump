-- Storage for vehicle images
local QBCore = exports['qb-core']:GetCoreObject()
local vehicleImages = {}
local imageSaveFile = 'vehicle-images.json'
local imageOutputFolder = 'vehicle-images'

Citizen.CreateThread(function()
    -- Load from JSON first
    local data = LoadResourceFile(GetCurrentResourceName(), imageSaveFile)
    if data then
        vehicleImages = json.decode(data) or {}
    end

    print('^2[MNC Vehicle Image Generator]^7 Loaded - ' .. CountTable(vehicleImages) .. ' vehicles in JSON')
end)

function CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- ==================== DOWNLOAD FUNCTION (Defined FIRST) ====================
local function downloadAndSaveImage(model, imageUrl)
    print('^3[MNC]^7 Downloading: ' .. model)

    -- Clean Discord URL
    if imageUrl:find("media%.discordapp%.net") then
        imageUrl = imageUrl:gsub("media%.discordapp%.net", "cdn.discordapp.com")
    end

    -- Force high quality PNG
    if not imageUrl:find("format=") then
        local separator = imageUrl:find("?") and "&" or "?"
        imageUrl = imageUrl .. separator .. "format=png&width=1920&quality=lossless"
    end

    PerformHttpRequest(imageUrl, function(statusCode, imageData, headers)
        if statusCode == 200 and imageData then
            if #imageData < 15000 then
                print('^1[MNC]^7 ❌ Image too small (likely failed): ' .. model .. ' (' .. #imageData .. ' bytes)')
                return
            end

            local filePath = imageOutputFolder .. '/' .. model .. '.png'
            local success = SaveResourceFile(GetCurrentResourceName(), filePath, imageData, #imageData)
            
            if success then
                print('^2[MNC]^7 ✅ SAVED: ' .. filePath .. ' (' .. math.floor(#imageData / 1024) .. ' KB)')
            else
                print('^1[MNC]^7 ❌ Failed to save file to disk: ' .. model)
            end
        else
            print('^1[MNC]^7 ❌ Download failed - Status: ' .. (statusCode or "nil") .. ' for ' .. model)
        end
    end, 'GET', '', {
        ['User-Agent'] = 'FiveM-VehicleImageDownloader/1.0',
        ['Accept'] = 'image/png,image/*,*/*',
        ['Cache-Control'] = 'no-cache'
    })
end

-- Get list of completed vehicles
RegisterNetEvent('mnc-vehicle-image-generator:requestCompletedList')
AddEventHandler('mnc-vehicle-image-generator:requestCompletedList', function()
    local src = source
    
    local completed = {}
    
    for model, _ in pairs(vehicleImages) do
        completed[model] = true
    end

    local folderFiles = GetFolderFileList()
    for _, filename in ipairs(folderFiles) do
        if filename:match("%.png$") then
            local model = filename:gsub("%.png$", "")
            completed[model] = true
        end
    end

    local completedList = {}
    for model, _ in pairs(completed) do
        table.insert(completedList, model)
    end

    TriggerClientEvent('mnc-vehicle-image-generator:receiveCompletedList', src, completedList)
end)

-- Helper to list files
function GetFolderFileList()
    local files = {}
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local folderPath = resourcePath .. '/' .. imageOutputFolder

    local handle = io.popen('dir "' .. folderPath .. '" /b 2>nul || ls "' .. folderPath .. '" 2>/dev/null')
    if handle then
        for filename in handle:lines() do
            if filename:match("%.png$") then
                table.insert(files, filename)
            end
        end
        handle:close()
    end

    return files
end

-- Save image info
RegisterNetEvent('mnc-vehicle-image-generator:saveImage')
AddEventHandler('mnc-vehicle-image-generator:saveImage', function(data)
    if not data or not data.vehicleModel then return end

    vehicleImages[data.vehicleModel] = {
        id = data.vehicleId,
        label = data.vehicleLabel,
        model = data.vehicleModel,
        imageUrl = data.imageUrl,
        localFile = imageOutputFolder .. '/' .. data.vehicleModel .. '.png',
        timestamp = os.time()
    }

    SaveResourceFile(GetCurrentResourceName(), imageSaveFile, json.encode(vehicleImages, {indent = true}), -1)

    TriggerClientEvent('mnc-vehicle-image-generator:imageSaved', source, data.vehicleModel)

    Citizen.Wait(800)
    downloadAndSaveImage(data.vehicleModel, data.imageUrl)
end)

-- Test Webhook
RegisterNetEvent('mnc-vehicle-image-generator:testWebhook')
AddEventHandler('mnc-vehicle-image-generator:testWebhook', function(webhook)
    local src = source
    PerformHttpRequest(webhook, function(statusCode)
        if statusCode == 200 or statusCode == 204 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Webhook Test',
                description = 'Webhook is working correctly!',
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Webhook Test',
                description = 'Webhook test failed (Status: ' .. (statusCode or 'Unknown') .. ')',
                type = 'error'
            })
        end
    end, 'POST', json.encode({
        content = "**MNC Vehicle Image Generator** - Webhook test successful!"
    }), { ['Content-Type'] = 'application/json' })
end)

RegisterNetEvent('mnc-vehicle-image-generator:saveConfig')
AddEventHandler('mnc-vehicle-image-generator:saveConfig', function(cameraSettings)
    print('^2[MNC]^7 Camera settings updated')
end)

-- Exports
exports('GetVehicleImage', function(model) 
    return vehicleImages[model] and vehicleImages[model].imageUrl 
end)

exports('GetAllVehicleImages', function() 
    return vehicleImages 
end)

exports('GetVehicleImageFile', function(model) 
    return vehicleImages[model] and vehicleImages[model].localFile 
end)

-- vehlist Command
QBCore.Commands.Add('vehlist', 'Export all vehicles from vehicles.lua into chunks', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if not QBCore.Functions.HasPermission(src, 'admin') and not QBCore.Functions.HasPermission(src, 'god') then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Permission Denied', description = 'Admin only.', type = 'error' })
        return
    end

    local vehiclesFile = LoadResourceFile('qb-core', 'shared/vehicles.lua')
    if not vehiclesFile then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Could not load qb-core/shared/vehicles.lua', type = 'error' })
        return
    end

    local vehicleModels = {}
    for model in vehiclesFile:gmatch("%['([^']+)'%]%s*=%s*{") do
        table.insert(vehicleModels, model)
    end
    if #vehicleModels == 0 then
        for model in vehiclesFile:gmatch("model%s*=%s*'([^']+)'") do
            table.insert(vehicleModels, model)
        end
    end

    if #vehicleModels == 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'No Vehicles', description = 'No vehicles found.', type = 'error' })
        return
    end

    print("^2[vehlist]^7 Found " .. #vehicleModels .. " vehicles.")

    local chunkSize = 250
    local fileCount = 0

    for i = 1, #vehicleModels, chunkSize do
        fileCount = fileCount + 1
        local chunk = {}
        for j = i, math.min(i + chunkSize - 1, #vehicleModels) do
            table.insert(chunk, vehicleModels[j])
        end

        local content = "Config.VehicleSpawnCodes = {\n"
        for _, model in ipairs(chunk) do
            content = content .. "    '" .. model .. "',\n"
        end
        content = content .. "}\n"

        local filename = "vehlist" .. fileCount .. ".lua"
        SaveResourceFile(GetCurrentResourceName(), filename, content, -1)
        print("^2[vehlist]^7 Created: " .. filename .. " (" .. #chunk .. " vehicles)")
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Success',
        description = fileCount .. ' vehlist files created!',
        type = 'success'
    })
end, 'admin')

print('^2[MNC Vehicle Image Generator Loaded]^7')