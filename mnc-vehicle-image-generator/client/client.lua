local isUIOpen = false
local isCapturing = false
local currentVehicle = nil
local captureData = {}
local previewVehicle = nil
local previewCamera = nil
local isPreviewMode = false
local completedVehicles = {} -- vehicles already captured (from server JSON)

-- Open UI
RegisterCommand('vehimage', function()
    if not isUIOpen then
        -- First request completed vehicles from server, then open UI
        TriggerServerEvent('mnc-vehicle-image-generator:requestCompletedList')
    end
end, false)

TriggerEvent('chat:addSuggestion', '/vehui', 'Open Vehicle Image Generator UI')

-- Receive completed vehicles list from server then open the UI
RegisterNetEvent('mnc-vehicle-image-generator:receiveCompletedList')
AddEventHandler('mnc-vehicle-image-generator:receiveCompletedList', function(completed)
    completedVehicles = {}
    for _, model in ipairs(completed) do
        completedVehicles[model] = true
    end

    if not isUIOpen then
        isUIOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            vehicles = ConvertSpawnCodesToCategories(),
            completedVehicles = completed,
            webhook = Config.DefaultWebhook,
            chunkSize = Config.ChunkSize or 25,
            cameraSettings = {
                coords = {
                    x = Config.CameraSettings.coords.x,
                    y = Config.CameraSettings.coords.y,
                    z = Config.CameraSettings.coords.z
                },
                heading = Config.CameraSettings.heading,
                cameraOffset = {
                    x = Config.CameraSettings.cameraOffset.x,
                    y = Config.CameraSettings.cameraOffset.y,
                    z = Config.CameraSettings.cameraOffset.z
                },
                cameraRotation = {
                    x = Config.CameraSettings.cameraRotation.x,
                    y = Config.CameraSettings.cameraRotation.y,
                    z = Config.CameraSettings.cameraRotation.z
                },
                fov = Config.CameraSettings.fov
            }
        })
    end
end)

-- Server tells us a vehicle image was saved — update UI
RegisterNetEvent('mnc-vehicle-image-generator:imageSaved')
AddEventHandler('mnc-vehicle-image-generator:imageSaved', function(model)
    completedVehicles[model] = true
    SendNUIMessage({ action = 'markDone', model = model })
end)

function ConvertSpawnCodesToCategories()
    local categories = {}
    if not Config or not Config.VehicleSpawnCodes then
        print("^1[mnc-vehicle-image-generator]^7 ERROR: Config.VehicleSpawnCodes is not defined!")
        return categories
    end

    print("^2[mnc-vehicle-image-generator]^7 Loading " .. #Config.VehicleSpawnCodes .. " vehicles")
    
    for _, spawnCode in ipairs(Config.VehicleSpawnCodes) do
        local label = spawnCode:sub(1,1):upper() .. spawnCode:sub(2)
        table.insert(categories, {
            id = spawnCode,
            label = label,
            model = spawnCode
        })
    end
    return categories
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('testWebhook', function(data, cb)
    TriggerServerEvent('mnc-vehicle-image-generator:testWebhook', data.webhook)
    cb('ok')
end)

RegisterNUICallback('startCapture', function(data, cb)
    if isCapturing then cb('ok') return end
    isCapturing = true
    captureData = {
        webhook = data.webhook,
        vehicles = data.vehicles,
        currentIndex = 1,
        total = #data.vehicles,
        cameraSettings = data.cameraSettings,
        chunkSize = data.chunkSize or Config.ChunkSize or 25,
        chunkStart = 1
    }

    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, false, false)
    SetEntityCollision(playerPed, false, false)

    Citizen.CreateThread(function()
        while isCapturing do
            DisplayRadar(false)
            DisplayHud(false)
            -- Godmode: re-applied every frame so server-side health sync can't override it
            local ped = PlayerPedId()
            SetEntityInvincible(ped, true)
            SetPlayerInvincible(PlayerId(), true)
            -- Weather: all three calls needed to prevent blending back
            SetWeatherTypePersist("EXTRASUNNY")
            SetWeatherTypeNow("EXTRASUNNY")
            SetOverrideWeather("EXTRASUNNY")
            -- Time: lock to 08:00 morning every frame
            NetworkOverrideClockTime(8, 0, 0)
            Citizen.Wait(0)
        end
    end)

    Citizen.CreateThread(function()
        CaptureNextVehicle()
    end)
    cb('ok')
end)

RegisterNUICallback('stopCapture', function(data, cb)
    StopCapture()
    cb('ok')
end)

RegisterNUICallback('resumeCapture', function(data, cb)
    -- Resume after a chunk pause: update index and reset chunkStart so boundary math is fresh
    if not isCapturing then
        isCapturing = true
        captureData.currentIndex = data.nextIndex or captureData.currentIndex
        captureData.chunkStart = captureData.currentIndex  -- CRITICAL: reset so capturedThisChunk starts at 0
        captureData.webhook = data.webhook or captureData.webhook

        local playerPed = PlayerPedId()
        SetEntityVisible(playerPed, false, false)
        SetEntityCollision(playerPed, false, false)

        Citizen.CreateThread(function()
            while isCapturing do
                DisplayRadar(false)
                DisplayHud(false)
                local ped = PlayerPedId()
                SetEntityInvincible(ped, true)
                SetPlayerInvincible(PlayerId(), true)
                SetWeatherTypePersist("EXTRASUNNY")
                SetWeatherTypeNow("EXTRASUNNY")
                SetOverrideWeather("EXTRASUNNY")
                NetworkOverrideClockTime(8, 0, 0)
                Citizen.Wait(0)
            end
        end)

        Citizen.CreateThread(function()
            CaptureNextVehicle()
        end)
    end
    cb('ok')
end)

RegisterNUICallback('startPreview', function(data, cb)
    StartPreviewMode(data.cameraSettings)
    cb('ok')
end)

RegisterNUICallback('updatePreview', function(data, cb)
    if isPreviewMode then
        UpdatePreviewCamera(data.cameraSettings)
    end
    cb('ok')
end)

RegisterNUICallback('stopPreview', function(data, cb)
    StopPreviewMode()
    cb('ok')
end)

RegisterNUICallback('saveConfig', function(data, cb)
    TriggerServerEvent('mnc-vehicle-image-generator:saveConfig', data.cameraSettings)
    cb('ok')
end)

RegisterNUICallback('notify', function(data, cb)
    TriggerEvent('chat:addMessage', {
        color = data.type == 'success' and {16, 185, 129} or {239, 68, 68},
        args = {"MNC Vehicle Capture", data.message}
    })
    cb('ok')
end)

-- ==================== MAIN CAPTURE LOGIC ====================

function CaptureNextVehicle()
    if not isCapturing or captureData.currentIndex > captureData.total then
        if isCapturing then
            SendNUIMessage({ action = 'captureComplete' })
            StopCapture()
        end
        return
    end

    -- Check if we've hit the end of a chunk — pause and wait for UI to resume
    local chunkSize = captureData.chunkSize or 25
    local capturedThisChunk = captureData.currentIndex - captureData.chunkStart
    if capturedThisChunk > 0 and capturedThisChunk % chunkSize == 0 then
        -- Pause: clean up any spawned vehicle, restore player, stop rendering
        if currentVehicle and DoesEntityExist(currentVehicle) then
            SetEntityAsMissionEntity(currentVehicle, false, true)
            DeleteEntity(currentVehicle)
            currentVehicle = nil
        end
        RenderScriptCams(false, false, 0, true, true)
        DisplayRadar(true)
        DisplayHud(true)
        local playerPed = PlayerPedId()
        SetEntityVisible(playerPed, true, false)
        SetEntityCollision(playerPed, true, true)

        isCapturing = false

        SendNUIMessage({
            action = 'chunkComplete',
            nextIndex = captureData.currentIndex,
            total = captureData.total,
            chunksDone = math.floor(capturedThisChunk / chunkSize)
        })
        return
    end

    local vehicle = captureData.vehicles[captureData.currentIndex]
    
    SendNUIMessage({
        action = 'updateProgress',
        current = captureData.currentIndex,
        total = captureData.total,
        vehicleName = vehicle.label
    })

    SpawnAndCaptureVehicle(vehicle)
end

function SpawnAndCaptureVehicle(vehicleData)
    -- Guard: if capture was stopped before this call was reached, bail out immediately
    if not isCapturing or not captureData.currentIndex then return end

    local camSettings = captureData.cameraSettings or Config.CameraSettings
    local coords = vector3(camSettings.coords.x, camSettings.coords.y, camSettings.coords.z)
    local modelHash = GetHashKey(vehicleData.model)

    RequestModel(modelHash)

    -- Timeout after 5 seconds (100 * 50ms) — skip invalid/unloadable models
    local loadAttempts = 0
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(50)
        loadAttempts = loadAttempts + 1
        if loadAttempts >= 100 then
            print('^1[MNC]^7 ⚠️ Model failed to load, skipping: ' .. vehicleData.label)
            if not isCapturing or not captureData.currentIndex then return end
            SendNUIMessage({ action = 'skipVehicle', model = vehicleData.model, label = vehicleData.label })
            captureData.currentIndex = captureData.currentIndex + 1
            Citizen.Wait(300)
            CaptureNextVehicle()
            return
        end
    end

    -- Cleanup old vehicle — unset mission entity first so the engine fully releases it from the entity pool
    if currentVehicle and DoesEntityExist(currentVehicle) then
        SetEntityAsMissionEntity(currentVehicle, false, true)
        DeleteEntity(currentVehicle)
        currentVehicle = nil
        Citizen.Wait(0) -- yield one frame so deletion is processed before spawning next
    end

    currentVehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, camSettings.heading, false, false)

    -- Timeout after 3 seconds (60 * 50ms) — skip if entity never spawns
    local spawnAttempts = 0
    while not DoesEntityExist(currentVehicle) do
        Citizen.Wait(50)
        spawnAttempts = spawnAttempts + 1
        if spawnAttempts >= 60 then
            print('^1[MNC]^7 ⚠️ Entity failed to spawn, skipping: ' .. vehicleData.label)
            if not isCapturing or not captureData.currentIndex then return end
            SendNUIMessage({ action = 'skipVehicle', model = vehicleData.model, label = vehicleData.label })
            captureData.currentIndex = captureData.currentIndex + 1
            Citizen.Wait(300)
            CaptureNextVehicle()
            return
        end
    end

    SetEntityAsMissionEntity(currentVehicle, true, true)
    SetVehicleOnGroundProperly(currentVehicle)
    SetVehicleDoorsLocked(currentVehicle, 2)
    FreezeEntityPosition(currentVehicle, true)
    SetEntityAlpha(currentVehicle, 0, false)

    -- CRITICAL: Release the model from memory immediately after spawning.
    -- Without this every model stays loaded and the asset/model pool fills up ~120 vehicles in.
    SetModelAsNoLongerNeeded(modelHash)

    -- Fade in
    for alpha = 0, 255, 20 do
        SetEntityAlpha(currentVehicle, alpha, false)
        Citizen.Wait(15)
    end
    SetEntityAlpha(currentVehicle, 255, false)

    -- Camera Setup
    local camera = CreateCameraWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        coords.x + camSettings.cameraOffset.x,
        coords.y + camSettings.cameraOffset.y,
        coords.z + camSettings.cameraOffset.z,
        camSettings.cameraRotation.x,
        camSettings.cameraRotation.y,
        camSettings.cameraRotation.z,
        camSettings.fov,
        true, 2
    )

    SetCamActive(camera, true)
    RenderScriptCams(true, false, 0, true, true)

    -- CRITICAL: Give enough time for rendering
    Citizen.Wait(1200)

    exports['screenshot-basic']:requestScreenshotUpload(captureData.webhook, 'files[]', {
        encoding = Config.ScreenshotSettings.encoding,
        quality = Config.ScreenshotSettings.quality
    }, function(data)
        local response = json.decode(data or "{}")
        
        if response and response.attachments and response.attachments[1] then
            local imageUrl = response.attachments[1].proxy_url or response.attachments[1].url
            
            TriggerServerEvent('mnc-vehicle-image-generator:saveImage', {
                vehicleId = vehicleData.id,
                vehicleLabel = vehicleData.label,
                vehicleModel = vehicleData.model,
                imageUrl = imageUrl
            })
            print('^2[MNC]^7 Captured: ' .. vehicleData.label)
        else
            print('^1[MNC]^7 Failed to capture: ' .. vehicleData.label)
        end

        -- Cleanup — stop rendering before destroying cam, unset mission entity before deleting vehicle
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(camera, false)

        if currentVehicle and DoesEntityExist(currentVehicle) then
            SetEntityAsMissionEntity(currentVehicle, false, true)
            DeleteEntity(currentVehicle)
            currentVehicle = nil
        end

        -- Guard: StopCapture or a chunk pause may have fired while the screenshot
        -- callback was in-flight, clearing captureData. Bail out silently if so.
        if not isCapturing or not captureData.currentIndex then return end

        captureData.currentIndex = captureData.currentIndex + 1
        Citizen.Wait(Config.CaptureDelay or 3000)
        CaptureNextVehicle()
    end)
end

function StopCapture()
    isCapturing = false

    if currentVehicle and DoesEntityExist(currentVehicle) then
        SetEntityAsMissionEntity(currentVehicle, false, true)
        DeleteEntity(currentVehicle)
        currentVehicle = nil
    end

    RenderScriptCams(false, false, 0, true, true)
    DisplayRadar(true)
    DisplayHud(true)

    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, true, false)
    SetEntityCollision(playerPed, true, true)

    -- Remove godmode
    SetEntityInvincible(playerPed, false)
    SetPlayerInvincible(PlayerId(), false)

    -- Release weather and time overrides
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    NetworkClearClockTimeOverride()

    captureData = {}
end

-- ==================== PREVIEW MODE ====================

function StartPreviewMode(cameraSettings)
    isPreviewMode = true
    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, false, false)

    local coords = vector3(cameraSettings.coords.x, cameraSettings.coords.y, cameraSettings.coords.z)
    local modelHash = GetHashKey('adder')

    RequestModel(modelHash)

    -- Timeout after 5 seconds — abort preview if model won't load
    local loadAttempts = 0
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(50)
        loadAttempts = loadAttempts + 1
        if loadAttempts >= 100 then
            print('^1[MNC]^7 ⚠️ Preview model failed to load')
            isPreviewMode = false
            SendNUIMessage({ action = 'previewFailed' })
            return
        end
    end

    if previewVehicle and DoesEntityExist(previewVehicle) then DeleteEntity(previewVehicle) end

    previewVehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, cameraSettings.heading, false, false)

    while not DoesEntityExist(previewVehicle) do Citizen.Wait(50) end

    SetEntityAsMissionEntity(previewVehicle, true, true)
    SetVehicleOnGroundProperly(previewVehicle)
    FreezeEntityPosition(previewVehicle, true)

    UpdatePreviewCamera(cameraSettings)
    DisplayRadar(false)
    DisplayHud(false)
end

function UpdatePreviewCamera(cameraSettings)
    if not isPreviewMode then return end

    local coords = vector3(cameraSettings.coords.x, cameraSettings.coords.y, cameraSettings.coords.z)

    if previewCamera then
        DestroyCam(previewCamera, false)
    end

    previewCamera = CreateCameraWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        coords.x + cameraSettings.cameraOffset.x,
        coords.y + cameraSettings.cameraOffset.y,
        coords.z + cameraSettings.cameraOffset.z,
        cameraSettings.cameraRotation.x,
        cameraSettings.cameraRotation.y,
        cameraSettings.cameraRotation.z,
        cameraSettings.fov,
        true, 2
    )

    SetCamActive(previewCamera, true)
    RenderScriptCams(true, false, 0, true, true)

    if previewVehicle and DoesEntityExist(previewVehicle) then
        SetEntityCoords(previewVehicle, coords.x, coords.y, coords.z, false, false, false, true)
        SetEntityHeading(previewVehicle, cameraSettings.heading)
        SetVehicleOnGroundProperly(previewVehicle)
    end
end

function StopPreviewMode()
    isPreviewMode = false

    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteEntity(previewVehicle)
        previewVehicle = nil
    end

    if previewCamera then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(previewCamera, false)
        previewCamera = nil
    end

    DisplayRadar(true)
    DisplayHud(true)

    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, true, false)
end

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        StopCapture()
        StopPreviewMode()
    end
end)