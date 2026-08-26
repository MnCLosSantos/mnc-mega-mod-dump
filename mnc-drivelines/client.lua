-- client.lua  (mnc-drivetype)
local QBCore = nil

CreateThread(function()
    while not QBCore do
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbcore') == 'started' then
            local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and obj then
                QBCore = obj
                if Config.Debug then print('^2[mnc-drivetype]^7 QBCore loaded.') end
            end
        end
        Wait(500)
    end
end)

-- Anim dict preload
local ANIM_DICT = 'amb@world_human_vehicle_mechanic@male@base'
local ANIM_CLIP = 'base'

CreateThread(function()
    while GetResourceState('ox_lib') ~= 'started' do Wait(500) end
    RequestAnimDict(ANIM_DICT)
    while not HasAnimDictLoaded(ANIM_DICT) do Wait(0) end
    if Config.Debug then print('^2[mnc-drivetype]^7 Anim dict loaded.') end
end)

-- Cache
local driveCache    = {}   -- [plate] = typeKey | false
local stockData     = {}   -- [plate] = { driveBias, tractionFront, tractionRear, wheelPower = { [0]=bool, ... } }
local currentVeh    = 0
local appliedType   = nil

-- Flush handling cache workaround
local MOD_SLOTS = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,15,16,25,27,28,30,33,34,35}

local function FlushHandlingCache(veh)
    local mods = {}
    for _, slot in ipairs(MOD_SLOTS) do
        mods[slot] = GetVehicleMod(veh, slot)
    end
    SetVehicleModKit(veh, 0)
    for _, slot in ipairs(MOD_SLOTS) do
        SetVehicleMod(veh, slot, mods[slot], false)
    end
end

local function SetHandlingParams(veh, params)
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveBiasFront',    params.driveBias)
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionBiasFront', params.tractionFront)
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionBiasRear',  params.tractionRear)
end

local function ApplyDriveType(veh, typeKey, plate)
    if not DoesEntityExist(veh) then return end

    local typeCfg = Config.DriveTypes[typeKey]
    if not typeCfg then
        if Config.Debug then print('[mnc-drivetype] ApplyDriveType: unknown typeKey ' .. tostring(typeKey)) end
        return
    end

    local params = {
        driveBias     = typeCfg.driveBias,
        tractionFront = typeCfg.tractionFront,
        tractionRear  = typeCfg.tractionRear,
    }

    -- Snapshot REAL current values + wheel powers (only once per plate)
    if plate and not stockData[plate] then
        local numWheels = GetVehicleNumberOfWheels(veh)
        local wheelPower = {}
        for i = 0, numWheels - 1 do
            wheelPower[i] = GetVehicleWheelIsPowered(veh, i)
        end

        stockData[plate] = {
            driveBias     = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveBiasFront'),
            tractionFront = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionBiasFront'),
            tractionRear  = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionBiasRear'),
            wheelPower    = wheelPower,
        }

        if Config.Debug then
            print(('[mnc-drivetype] SNAPSHOT taken | plate=%s | drive=%.4f tF=%.4f tR=%.4f wheels=%s')
                :format(plate,
                    stockData[plate].driveBias,
                    stockData[plate].tractionFront,
                    stockData[plate].tractionRear,
                    json.encode(wheelPower)))
        end
    end

    -- Apply handling
    SetHandlingParams(veh, params)
    FlushHandlingCache(veh)
    SetHandlingParams(veh, params)

    -- Apply correct wheel power flags
    local powered = typeCfg.poweredWheels
    local numWheels = GetVehicleNumberOfWheels(veh)
    for i = 0, numWheels - 1 do
        local isPowered = powered[i] or false
        SetVehicleWheelIsPowered(veh, i, isPowered)
    end

    if Config.Debug then
        print(('[mnc-drivetype] applied | type=%s | drive=%.2f tF=%.2f tR=%.2f')
            :format(typeKey, params.driveBias, params.tractionFront, params.tractionRear))
    end
end

local function ResetToStock(veh, plate)
    if not DoesEntityExist(veh) then return end

    local restore = stockData[plate]

    if not restore then
        -- Extremely rare fallback (no snapshot ever taken)
        restore = {
            driveBias     = 0.5,
            tractionFront = 0.50,
            tractionRear  = 0.50,
            wheelPower    = { [0]=true, [1]=true, [2]=true, [3]=true },
        }
        if Config.Debug then
            print('[mnc-drivetype] NO SNAPSHOT EXISTS → using safe neutral fallback | plate=' .. tostring(plate))
        end
    else
        if Config.Debug then
            print('[mnc-drivetype] restoring from snapshot | plate=' .. plate)
        end
    end

    -- Restore handling
    local params = {
        driveBias     = restore.driveBias,
        tractionFront = restore.tractionFront,
        tractionRear  = restore.tractionRear,
    }
    SetHandlingParams(veh, params)
    FlushHandlingCache(veh)
    SetHandlingParams(veh, params)

    -- Restore original wheel power flags
    local numWheels = GetVehicleNumberOfWheels(veh)
    for i = 0, numWheels - 1 do
        local wasPowered = restore.wheelPower[i]
        SetVehicleWheelIsPowered(veh, i, wasPowered ~= nil and wasPowered or true)
    end

    -- Clean up snapshot
    stockData[plate] = nil

    if Config.Debug then
        print(('[mnc-drivetype] stock reset complete | plate=%s'):format(plate))
    end
end

-- Notify
RegisterNetEvent('mnc-drivetype:notify', function(data)
    lib.notify(data)
end)

-- Sync from server
RegisterNetEvent('mnc-drivetype:syncData', function(plate, typeKey)
    driveCache[plate] = typeKey or false

    if currentVeh ~= 0 then
        local vehPlate = string.upper(GetVehicleNumberPlateText(currentVeh):gsub('%s+', ''))
        if vehPlate == plate then
            appliedType = typeKey or false
            if typeKey then
                ApplyDriveType(currentVeh, typeKey, plate)
            else
                ResetToStock(currentVeh, plate)
                if Config.Debug then print('[mnc-drivetype] drive type removed — reset immediately: ' .. plate) end
            end
        end
    end
end)

-- Vehicle entry watcher
CreateThread(function()
    while true do
        if not QBCore then Wait(500) goto continue end

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and veh ~= currentVeh then
            currentVeh  = veh
            appliedType = nil

            local plate  = string.upper(GetVehicleNumberPlateText(veh):gsub('%s+', ''))
            local cached = driveCache[plate]

            if cached then
                appliedType = cached
                ApplyDriveType(veh, cached, plate)
                if Config.Debug then print('[mnc-drivetype] cache hit: ' .. plate .. ' -> ' .. cached) end
            elseif cached == false then
                if Config.Debug then print('[mnc-drivetype] cache: no conversion on ' .. plate) end
            else
                QBCore.Functions.TriggerCallback('mnc-drivetype:getData', function(typeKey)
                    if typeKey and currentVeh == veh then
                        appliedType       = typeKey
                        driveCache[plate] = typeKey
                        ApplyDriveType(veh, typeKey, plate)
                        if Config.Debug then print('[mnc-drivetype] server hit: ' .. plate .. ' -> ' .. typeKey) end
                    else
                        driveCache[plate] = false
                        if Config.Debug then print('[mnc-drivetype] no conversion on: ' .. plate) end
                    end
                end, plate)
            end

        elseif veh == 0 and currentVeh ~= 0 then
            currentVeh  = 0
            appliedType = nil
        end

        Wait(1000)
        ::continue::
    end
end)

-- Anti-burnout enforcer for AWD types (blocks brake-torquing / standing burnouts)
CreateThread(function()
    while true do
        Wait(0)  -- Every frame

        if currentVeh == 0 then goto continue end

        local ped = PlayerPedId()
        if GetVehiclePedIsIn(ped, false) ~= currentVeh then goto continue end

        local plate = string.upper(GetVehicleNumberPlateText(currentVeh):gsub('%s+', ''))
        local typeKey = appliedType or driveCache[plate]

        if not typeKey then goto continue end

        -- Skip FWD/RWD
        if typeKey == 'fwd' or typeKey == 'rwd' then goto continue end

        local speed = GetEntitySpeed(currentVeh)
        if speed > 2.0 then goto continue end  -- Only enforce at near-standstill (tuned lower than 3.0)

        local isBraking  = IsControlPressed(0, 72) or GetControlNormal(0, 72) > 0.1  -- Brake input (S / LT)
        local isThrottle = IsControlPressed(0, 71) or GetControlNormal(0, 71) > 0.1  -- Accel input (W / RT)

        if isBraking and isThrottle then
            -- Block acceleration input while braking → prevents torque against brakes
            DisableControlAction(0, 71, true)  -- Disable accelerate (W / RT)

            -- Optional: Also force burnout off as fallback
            SetVehicleBurnout(currentVeh, false)
        end

        -- Extra safety: force off if somehow in burnout state
        if IsVehicleInBurnout(currentVeh) then
            SetVehicleBurnout(currentVeh, false)
        end

        ::continue::
    end
end)

-- Helpers
local function GetNearbyVehicle()
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 then return nil end

    local pedPos      = GetEntityCoords(ped)
    local best, bestD = nil, Config.ApplyDistance

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local d = #(pedPos - GetEntityCoords(veh))
        if d < bestD then best = veh; bestD = d end
    end
    return best
end

local function HasAllowedJob()
    if not Config.RequireJob then return true end
    if not QBCore then return false end
    local job = QBCore.Functions.GetPlayerData().job
    if not job then return false end
    local minGrade = Config.AllowedJobs[job.name]
    if minGrade == nil then return false end
    return (job.grade.level or 0) >= minGrade
end

local BONE_FALLBACKS = {
    wheel_lr = { 'wheel_lb', 'wheel_lm' },
    wheel_rr = { 'wheel_rb', 'wheel_rm' },
}

local function GetWheelWorldPos(vehicle, boneName)
    local idx = GetEntityBoneIndexByName(vehicle, boneName)
    if idx ~= -1 then return GetWorldPositionOfEntityBone(vehicle, idx) end
    local fallbacks = BONE_FALLBACKS[boneName]
    if fallbacks then
        for _, fb in ipairs(fallbacks) do
            idx = GetEntityBoneIndexByName(vehicle, fb)
            if idx ~= -1 then return GetWorldPositionOfEntityBone(vehicle, idx) end
        end
    end
    return GetEntityCoords(vehicle)
end

local function DoWheelInstall(vehicle, boneName, label, duration)
    local vehHeading = GetEntityHeading(vehicle)
    local isLeft     = boneName == 'wheel_lf' or boneName == 'wheel_lr'
    local heading    = (vehHeading + (isLeft and 90.0 or -90.0)) % 360.0
    SetEntityHeading(PlayerPedId(), heading)

    return lib.progressBar({
        duration     = duration,
        label        = label,
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = ANIM_DICT, clip = ANIM_CLIP, flag = 1 },
    })
end

-- Install prompt
RegisterNetEvent('mnc-drivetype:promptApply', function(typeKey)
    local typeCfg = Config.DriveTypes[typeKey]
    if not typeCfg then return end

    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then
        lib.notify({ title = typeCfg.label, description = 'You must be outside the vehicle to install.', type = 'error' })
        return
    end

    if not HasAllowedJob() then
        lib.notify({ title = typeCfg.label, description = 'You must be a mechanic to perform this conversion.', type = 'error' })
        return
    end

    local target = GetNearbyVehicle()
    if not target then
        lib.notify({ title = typeCfg.label, description = 'No vehicle within ' .. Config.ApplyDistance .. 'm.', type = 'error' })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(target):gsub('%s+', ''))

    if driveCache[plate] == typeKey then
        lib.notify({ title = typeCfg.label, description = 'Vehicle already has this drive type.', type = 'error' })
        return
    end

    local wheels = typeCfg.wheelSet
    if not wheels or #wheels == 0 then return end

    local timePerWheel = math.floor(typeCfg.installTime / #wheels)

    lib.notify({
        title       = typeCfg.label,
        description = ('Starting installation — begin with: %s'):format(wheels[1].label),
        type        = 'inform',
        duration    = 5000,
    })

    local PROMPT_RADIUS = 1.2

    for i, wheel in ipairs(wheels) do
        local ePressed = false
        local aborted  = false

        CreateThread(function()
            while not ePressed and not aborted do
                local pedPos   = GetEntityCoords(PlayerPedId())
                local wheelPos = GetWheelWorldPos(target, wheel.bone)
                local dist     = #(pedPos - vector3(wheelPos.x, wheelPos.y, wheelPos.z))

                DrawMarker(1, wheelPos.x, wheelPos.y, wheelPos.z + 0.05,
                    0.0,0.0,0.0, 0.0,0.0,0.0, 0.3,0.3,0.2,
                    255,165,0,180, false,true,2,false,nil,nil,false)

                if dist <= PROMPT_RADIUS then
                    SetTextComponentFormat('STRING')
                    AddTextComponentString('Press ~INPUT_CONTEXT~ to work on ' .. wheel.label)
                    DisplayHelpTextFromStringLabel(0, false, true, -1)
                    if IsControlJustPressed(0, 51) then ePressed = true end
                end

                if IsControlJustPressed(1, 200) or IsDisabledControlJustPressed(1, 200) then
                    aborted = true
                end

                Wait(0)
            end
        end)

        while not ePressed and not aborted do Wait(100) end

        if aborted then
            lib.notify({ title = typeCfg.label, description = 'Installation cancelled.', type = 'inform' })
            return
        end

        local ok = DoWheelInstall(target, wheel.bone,
            ('Installing %s — %s (%d/%d)'):format(typeCfg.label, wheel.label, i, #wheels),
            timePerWheel)

        if not ok then
            lib.notify({ title = typeCfg.label, description = 'Installation cancelled.', type = 'inform' })
            ClearPedTasks(PlayerPedId())
            return
        end

        if i < #wheels then
            lib.notify({
                title       = typeCfg.label,
                description = ('Wheel done! Next: %s (%d/%d)'):format(wheels[i + 1].label, i + 1, #wheels),
                type        = 'success',
                duration    = 4000,
            })
        end
    end

    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('mnc-drivetype:applyType', plate, typeKey)
end)

-- Toolbox (unchanged except minor wording)
local WHEEL_LABEL_MAP = {
    wheel_lf = 'Front Left',
    wheel_rf = 'Front Right',
    wheel_lr = 'Rear Left',
    wheel_rr = 'Rear Right',
}

local function GetDrivelineMarkerColor(typeKey)
    if typeKey == 'fwd'          then return 0,   120, 255, 200 end
    if typeKey == 'rwd'          then return 255,  60,  60, 200 end
    if typeKey == 'awd_5050'     then return 80,  200,  80, 200 end
    if typeKey == 'haldex_6535'  then return 255, 165,   0, 200 end
    if typeKey == 'viscous_3565' then return 160,  80, 220, 200 end
    return 200, 200, 200, 180
end

RegisterNetEvent('mnc-drivetype:openToolbox', function()
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then
        lib.notify({ title = 'Driveline Toolbox', description = 'You must be outside a vehicle to use the toolbox.', type = 'error' })
        return
    end

    if not HasAllowedJob() then
        lib.notify({ title = 'Driveline Toolbox', description = 'You must be a mechanic to use the driveline toolbox.', type = 'error' })
        return
    end

    local target = GetNearbyVehicle()
    if not target then
        lib.notify({ title = 'Driveline Toolbox', description = 'No vehicle within ' .. Config.ApplyDistance .. 'm.', type = 'error' })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(target):gsub('%s+', ''))

    QBCore.Functions.TriggerCallback('mnc-drivetype:getTypeInfo', function(info)
        if not info then
            lib.notify({ title = 'Driveline Toolbox', description = 'No drive type conversion installed on this vehicle.', type = 'inform', duration = 5000 })
            return
        end

        local typeKey  = info.typeKey
        local typeCfg  = Config.DriveTypes[typeKey] or info.typeCfg
        local wheels   = typeCfg.wheelSet or {}
        local r, g, b, a = GetDrivelineMarkerColor(typeKey)
        local showMarkers = true

        CreateThread(function()
            while showMarkers do
                for _, wheel in ipairs(wheels) do
                    local wp = GetWheelWorldPos(target, wheel.bone)
                    DrawMarker(1, wp.x, wp.y, wp.z + 0.08,
                        0.0,0.0,0.0, 0.0,0.0,0.0, 0.35,0.35,0.25,
                        r,g,b,a, false,true,2,false,nil,nil,false)
                end
                Wait(0)
            end
        end)

        local wheelNames = {}
        for _, w in ipairs(wheels) do
            wheelNames[#wheelNames + 1] = (WHEEL_LABEL_MAP[w.bone] or w.bone)
        end

        local biasInfo = ('Drive bias: %.0f%% front / %.0f%% rear'):format(
            typeCfg.driveBias * 100,
            (1.0 - typeCfg.driveBias) * 100
        )

        lib.registerContext({
            id    = 'mnc_toolbox_menu',
            title = '🔧 Driveline Toolbox — ' .. plate,
            options = {
                {
                    title       = typeCfg.label,
                    description = typeCfg.description .. '\n' .. biasInfo .. '\nDriven wheels: ' .. table.concat(wheelNames, ', '),
                    icon        = 'car',
                    disabled    = true,
                },
                {
                    title       = 'Remove Conversion Kit',
                    description = 'Uninstall and return the kit to your inventory.',
                    icon        = 'wrench',
                    onSelect    = function()
                        showMarkers = false

                        local timePerWheel = math.floor(typeCfg.installTime / #wheels)
                        local PROMPT_RADIUS = 1.2

                        lib.notify({ title = 'Driveline Toolbox', description = ('Starting removal — begin with: %s'):format(wheels[1].label), type = 'inform', duration = 5000 })

                        for i, wheel in ipairs(wheels) do
                            local ePressed = false
                            local aborted  = false

                            CreateThread(function()
                                while not ePressed and not aborted do
                                    local pedPos   = GetEntityCoords(PlayerPedId())
                                    local wheelPos = GetWheelWorldPos(target, wheel.bone)
                                    local dist     = #(pedPos - vector3(wheelPos.x, wheelPos.y, wheelPos.z))

                                    DrawMarker(1, wheelPos.x, wheelPos.y, wheelPos.z + 0.05,
                                        0.0,0.0,0.0, 0.0,0.0,0.0, 0.3,0.3,0.2,
                                        r,g,b,200, false,true,2,false,nil,nil,false)

                                    if dist <= PROMPT_RADIUS then
                                        SetTextComponentFormat('STRING')
                                        AddTextComponentString('Press ~INPUT_CONTEXT~ to remove ' .. wheel.label)
                                        DisplayHelpTextFromStringLabel(0, false, true, -1)
                                        if IsControlJustPressed(0, 51) then ePressed = true end
                                    end

                                    if IsControlJustPressed(1, 200) or IsDisabledControlJustPressed(1, 200) then
                                        aborted = true
                                    end

                                    Wait(0)
                                end
                            end)

                            while not ePressed and not aborted do Wait(100) end

                            if aborted then
                                lib.notify({ title = 'Driveline Toolbox', description = 'Removal cancelled.', type = 'inform' })
                                return
                            end

                            local vehHeading = GetEntityHeading(target)
                            local isLeft     = wheel.bone == 'wheel_lf' or wheel.bone == 'wheel_lr'
                            SetEntityHeading(PlayerPedId(), (vehHeading + (isLeft and 90.0 or -90.0)) % 360.0)

                            local ok = lib.progressBar({
                                duration     = timePerWheel,
                                label        = ('Removing %s — %s (%d/%d)'):format(typeCfg.label, wheel.label, i, #wheels),
                                useWhileDead = false,
                                canCancel    = true,
                                disable      = { move = true, car = true, combat = true },
                                anim         = { dict = ANIM_DICT, clip = ANIM_CLIP, flag = 1 },
                            })

                            if not ok then
                                lib.notify({ title = 'Driveline Toolbox', description = 'Removal cancelled.', type = 'inform' })
                                ClearPedTasks(PlayerPedId())
                                return
                            end

                            if i < #wheels then
                                lib.notify({ title = 'Driveline Toolbox', description = ('Wheel done! Next: %s (%d/%d)'):format(wheels[i + 1].label, i + 1, #wheels), type = 'success', duration = 4000 })
                            end
                        end

                        ClearPedTasks(PlayerPedId())

                        ResetToStock(target, plate)
                        driveCache[plate] = false
                        if currentVeh == target then appliedType = false end

                        TriggerServerEvent('mnc-drivetype:removeType', plate)
                    end,
                },
                {
                    title    = 'Close',
                    icon     = 'xmark',
                    onSelect = function() showMarkers = false end,
                },
            },
        })

        lib.showContext('mnc_toolbox_menu')

        CreateThread(function()
            Wait(200)
            while showMarkers do
                if not IsNuiFocused() then showMarkers = false end
                Wait(50)
            end
        end)
    end, plate)
end)

if Config.Debug then
    print('^2[mnc-drivetype]^7 Client loaded (snapshot + wheel power support).')
end