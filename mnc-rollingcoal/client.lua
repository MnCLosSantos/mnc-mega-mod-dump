-- client.lua
local QBCore = nil
local smokeCache     = {}   -- [plate] = {amount=N, egr_delete=bool, dpf_delete=bool} | false | nil
local currentVehicle = nil
local activeHandles  = {}   -- [vehicle handle] = {ptfxHandle1, ptfxHandle2, ...}
local smokeStartTime = {}   -- [vehicle handle] = GetGameTimer() when smoke began

-- ===========================
-- QBCore init
-- ===========================
CreateThread(function()
    while not QBCore do
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbcore') == 'started' then
            local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and obj then
                QBCore = obj
                print('^2[mnc-rollingcoal]^7 QBCore loaded.')
            end
        end
        Wait(500)
    end
end)

-- ===========================
-- Pre-load particle dict
-- ===========================
CreateThread(function()
    while GetResourceState('ox_lib') ~= 'started' do Wait(500) end
    RequestNamedPtfxAsset(Config.ParticleDict)
    while not HasNamedPtfxAssetLoaded(Config.ParticleDict) do Wait(0) end
end)

-- ===========================
-- Notify event
-- ===========================
RegisterNetEvent('mnc-rollingcoal:notify', function(data)
    lib.notify({
        title       = data.title or 'Smoke Kit',
        description = data.description,
        type        = data.type or 'inform',
        duration    = data.duration or 5000
    })
end)

-- ===========================
-- Exhaust bone search list
-- ===========================
local boneSearchList = {
    "exhaust", "exhaust_f",
    "exhaust_1","exhaust_2","exhaust_3","exhaust_4",
    "exhaust_5","exhaust_6","exhaust_7","exhaust_8","exhaust_9",
    "roll_exhaust"
}

local function GetExhaustBones(vehicle)
    local found = {}
    for _, name in ipairs(boneSearchList) do
        local idx = GetEntityBoneIndexByName(vehicle, name)
        if idx ~= -1 then
            found[#found + 1] = { idx = idx, name = name }
        end
    end
    if #found == 0 then
        found[1] = { idx = 0, name = "fallback_root" }
    end
    return found
end

-- ===========================
-- Check if a vehicle class is in the auto-kit list
-- ===========================
local autoKitClassSet = {}
for _, cls in ipairs(Config.AutoKitClasses) do
    autoKitClassSet[cls] = true
end

local function IsAutoKitVehicle(vehicle)
    local cls = GetVehicleClass(vehicle)
    return autoKitClassSet[cls] == true
end

-- ===========================
-- Client-side job check
-- ===========================
local function HasAllowedJob()
    if not Config.RequireJob then return true end
    if not QBCore then return false end

    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.job then return false end

    local job   = PlayerData.job.name
    local grade = (PlayerData.job.grade and PlayerData.job.grade.level) or 0

    local minGrade = Config.AllowedJobs[job]
    if minGrade == nil then return false end

    return grade >= minGrade
end

-- ===========================
-- Start looped smoke
-- ===========================
local function StartSmoke(vehicle, amount)
    if activeHandles[vehicle] then return end

    local bones = GetExhaustBones(vehicle)
    if #bones == 0 then return end

    activeHandles[vehicle] = {}
    smokeStartTime[vehicle] = GetGameTimer()

    local scale = Config.BaseScale + (amount - 1) * Config.ScaleStep

    for _, bone in ipairs(bones) do
        UseParticleFxAssetNextCall(Config.ParticleDict)

        local handle = StartParticleFxLoopedOnEntityBone(
            Config.ParticleName,
            vehicle,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            bone.idx,
            scale,
            false, false, false
        )

        if handle > 0 then
            table.insert(activeHandles[vehicle], handle)
        end
    end
end

-- ===========================
-- Stop smoke
-- ===========================
local function StopSmoke(vehicle)
    if not activeHandles[vehicle] then return end

    for _, handle in ipairs(activeHandles[vehicle]) do
        if DoesParticleFxLoopedExist(handle) then
            StopParticleFxLooped(handle, false)
        end
    end

    activeHandles[vehicle] = nil
    smokeStartTime[vehicle] = nil
end

-- ===========================
-- Update scale (brief RPM boost on start)
-- ===========================
local function UpdateScale(vehicle, amount, rpm)
    if not activeHandles[vehicle] then return end

    local elapsed = GetGameTimer() - (smokeStartTime[vehicle] or 0)
    local scale   = Config.BaseScale + (amount - 1) * Config.ScaleStep

    if elapsed <= 25 then
        local rpmFactor = math.max(0.0, rpm - Config.MinRPM)
        scale = scale * (1.0 + rpmFactor * Config.RpmScaleMultiplier)
    end

    scale = math.min(scale, Config.MaxScale)

    for _, handle in ipairs(activeHandles[vehicle]) do
        SetParticleFxLoopedScale(handle, scale)
    end
end

-- ===========================
-- Main smoke thread
-- ===========================
CreateThread(function()
    while true do
        if not QBCore then
            Wait(500)
            goto continue
        end

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
            if currentVehicle then
                StopSmoke(currentVehicle)
                currentVehicle = nil
            end
            Wait(600)
            goto continue
        end

        local plate = string.upper(GetVehicleNumberPlateText(vehicle):gsub("%s+", ""))

        if vehicle ~= currentVehicle then
            if currentVehicle then StopSmoke(currentVehicle) end
            currentVehicle = vehicle
            smokeCache[plate] = nil
        end

        if smokeCache[plate] == nil and IsAutoKitVehicle(vehicle) then
            QBCore.Functions.TriggerCallback('mnc-rollingcoal:getSmokeData', function(data)
                if data and data.amount then
                    smokeCache[plate] = {
                        amount     = data.amount,
                        autoKit    = true,
                        egr_delete = true,
                        dpf_delete = true
                    }
                else
                    smokeCache[plate] = {
                        amount     = Config.AutoKitDefaultAmount,
                        autoKit    = true,
                        egr_delete = true,
                        dpf_delete = true
                    }
                end
            end, plate)
            Wait(150)
            goto continue
        end

        if smokeCache[plate] == nil then
            QBCore.Functions.TriggerCallback('mnc-rollingcoal:getSmokeData', function(data)
                smokeCache[plate] = data or false
            end, plate)
            Wait(150)
            goto continue
        end

        local data = smokeCache[plate]
        if data and data.amount and data.amount > 0 then
            local rpm      = GetVehicleCurrentRpm(vehicle)
            local engineOn = GetIsVehicleEngineRunning(vehicle)

            if not engineOn or rpm <= Config.MinRPM then
                StopSmoke(vehicle)
            else
                StartSmoke(vehicle, data.amount)
                UpdateScale(vehicle, data.amount, rpm)
            end
        else
            StopSmoke(vehicle)
        end

        Wait(Config.SmokeInterval)

        ::continue::
    end
end)

-- ===========================
-- /rollingcoal command
-- ===========================
RegisterCommand('rollingcoal', function()
    if not QBCore then return end

    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        lib.notify({ title = 'Rolling Coal', description = 'You must be the driver of a vehicle.', type = 'error' })
        return
    end

    local plate     = string.upper(GetVehicleNumberPlateText(vehicle):gsub("%s+", ""))
    local isAutoKit = IsAutoKitVehicle(vehicle)

    if isAutoKit then
        local cached = smokeCache[plate] or { amount = Config.AutoKitDefaultAmount, autoKit = true, egr_delete = true, dpf_delete = true }
        smokeCache[plate] = cached
        OpenSmokeMenu(vehicle, plate, cached, true)
        return
    end

    QBCore.Functions.TriggerCallback('mnc-rollingcoal:getSmokeData', function(data)
        if not data then
            lib.notify({ title = 'Rolling Coal', description = 'No smoke kit installed on this vehicle.', type = 'error' })
            return
        end
        if not data.amount or data.amount == 0 then
            local hasEgr = data.egr_delete
            local hasDpf = data.dpf_delete
            if hasEgr and hasDpf then
                lib.notify({ title = 'Rolling Coal', description = 'EGR & DPF deletes installed. You can now install a smoke kit.', type = 'inform' })
            else
                local missing = {}
                if not hasEgr then missing[#missing + 1] = 'EGR Delete Kit' end
                if not hasDpf then missing[#missing + 1] = 'DPF Delete Kit' end
                lib.notify({ title = 'Rolling Coal', description = 'Missing: ' .. table.concat(missing, ', '), type = 'error' })
            end
            return
        end
        OpenSmokeMenu(vehicle, plate, data, false)
    end, plate)
end, false)

-- ===========================
-- Menu
-- ===========================
function OpenSmokeMenu(vehicle, plate, data, isAutoKit)
    local current = data.amount
    local labels  = { [1]='Light', [2]='Mild', [3]='Medium', [4]='Heavy', [5]='Maximum' }
    local options = {}

    options[#options + 1] = {
        title       = 'Smoke Off',
        description = current == 0 and '● Currently active' or 'Disable all smoke output',
        icon        = current == 0 and 'circle-check' or 'circle-xmark',
        iconColor   = current == 0 and '#2ecc71' or '#e74c3c',
        onSelect    = function()
            if isAutoKit then
                smokeCache[plate] = { amount = 0, autoKit = true, egr_delete = true, dpf_delete = true }
            else
                TriggerServerEvent('mnc-rollingcoal:setSmokeAmount', plate, 0)
                smokeCache[plate].amount = 0
            end
            StopSmoke(vehicle)
            lib.notify({ title = 'Rolling Coal', description = 'Smoke disabled.', type = 'inform' })
        end
    }

    for i = 1, Config.MaxSmokeAmount do
        local isSel = current == i
        local lbl   = labels[i] or ('Level ' .. i)
        options[#options + 1] = {
            title       = 'Level ' .. i .. '  —  ' .. lbl,
            description = isSel and '● Currently active' or 'Set smoke to level ' .. i,
            icon        = isSel and 'circle-check' or 'circle',
            iconColor   = isSel and '#2ecc71' or '#95a5a6',
            onSelect    = function()
                if isAutoKit then
                    smokeCache[plate] = { amount = i, autoKit = true, egr_delete = true, dpf_delete = true }
                    TriggerServerEvent('mnc-rollingcoal:setAutoKitAmount', plate, i)
                else
                    TriggerServerEvent('mnc-rollingcoal:setSmokeAmount', plate, i)
                    smokeCache[plate].amount = i
                end
                StopSmoke(vehicle)
                StartSmoke(vehicle, i)
                lib.notify({ title = 'Rolling Coal', description = 'Smoke set to Level ' .. i .. ' — ' .. lbl .. '.', type = 'success' })
            end
        }
    end

    lib.registerContext({ id = 'rollingcoal_menu', title = 'Rolling Coal — Smoke Level', options = options })
    lib.showContext('rollingcoal_menu')
end

-- ===========================
-- Get vehicle player is standing in front of
-- ===========================
local FRONT_RADIUS = 1.0

local function GetVehicleAtFront()
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 then return nil end

    local pedPos = GetEntityCoords(ped)
    local best, bestD = nil, FRONT_RADIUS

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local vehPos = GetEntityCoords(veh)
        local fwd    = GetEntityForwardVector(veh)
        local min, max = GetModelDimensions(GetEntityModel(veh))
        local halfLen  = (max.y - min.y) * 0.5

        local frontPoint = vector3(
            vehPos.x + fwd.x * halfLen,
            vehPos.y + fwd.y * halfLen,
            vehPos.z
        )

        local d = #(pedPos - frontPoint)

        if d <= FRONT_RADIUS then
            local toPlayer = pedPos - vehPos
            local dot = toPlayer.x * fwd.x + toPlayer.y * fwd.y

            if dot > 0.0 and d < bestD then
                best  = veh
                bestD = d
            end
        end
    end

    return best
end

-- ===========================
-- Hood open → progress bar → hood close
-- ===========================
local function DoKitInstall(vehicle, duration, label)
    local ped = PlayerPedId()
    local vehHeading = GetEntityHeading(vehicle)
    SetEntityHeading(ped, vehHeading)

    SetVehicleDoorOpen(vehicle, 4, false, false)
    Wait(600)

    local success = lib.progressBar({
        duration     = duration,
        label        = label,
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = { dict = 'amb@world_human_vehicle_mechanic@male@base', clip = 'base', flag = 1 }
    })

    SetVehicleDoorShut(vehicle, 4, false)
    return success
end

-- ===========================
-- EGR Delete – checks BEFORE animation
-- ===========================
RegisterNetEvent('mnc-rollingcoal:applyEgrKit', function()
    if not HasAllowedJob() then
        lib.notify({ title = 'EGR Delete', description = 'Only authorized mechanics can install this.', type = 'error' })
        return
    end

    local target = GetVehicleAtFront()
    if not target then
        lib.notify({ title = 'EGR Delete', description = 'Stand directly in front of the vehicle (within 1m of headlights).', type = 'error' })
        return
    end

    if IsAutoKitVehicle(target) then
        lib.notify({ title = 'EGR Delete', description = 'This vehicle already has a built-in system.', type = 'error' })
        return
    end

    if DoKitInstall(target, 3000, 'Installing EGR Delete Kit...') then
        local plate = string.upper(GetVehicleNumberPlateText(target):gsub("%s+", ""))
        TriggerServerEvent('mnc-rollingcoal:applyEgrKit', plate)
    else
        lib.notify({ title = 'EGR Delete', description = 'Installation cancelled.', type = 'inform' })
    end
end)

-- ===========================
-- DPF Delete – checks BEFORE animation
-- ===========================
RegisterNetEvent('mnc-rollingcoal:applyDpfKit', function()
    if not HasAllowedJob() then
        lib.notify({ title = 'DPF Delete', description = 'Only authorized mechanics can install this.', type = 'error' })
        return
    end

    local target = GetVehicleAtFront()
    if not target then
        lib.notify({ title = 'DPF Delete', description = 'Stand directly in front of the vehicle (within 1m of headlights).', type = 'error' })
        return
    end

    if IsAutoKitVehicle(target) then
        lib.notify({ title = 'DPF Delete', description = 'This vehicle already has a built-in system.', type = 'error' })
        return
    end

    if DoKitInstall(target, 3000, 'Installing DPF Delete Kit...') then
        local plate = string.upper(GetVehicleNumberPlateText(target):gsub("%s+", ""))
        TriggerServerEvent('mnc-rollingcoal:applyDpfKit', plate)
    else
        lib.notify({ title = 'DPF Delete', description = 'Installation cancelled.', type = 'inform' })
    end
end)

-- ===========================
-- Smoke Kit – full pre-checks BEFORE animation
-- ===========================
RegisterNetEvent('mnc-rollingcoal:applySmokeKit', function()
    if not HasAllowedJob() then
        lib.notify({ title = 'Rolling Coal', description = 'Only authorized mechanics can install this.', type = 'error' })
        return
    end

    local target = GetVehicleAtFront()
    if not target then
        lib.notify({ title = 'Rolling Coal', description = 'Stand directly in front of the vehicle (within 1m of headlights).', type = 'error' })
        return
    end

    if IsAutoKitVehicle(target) then
        lib.notify({ title = 'Rolling Coal', description = 'This vehicle already has a built-in smoke system.', type = 'error' })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(target):gsub("%s+", ""))

    -- Early cache check + fallback fetch
    local data = smokeCache[plate]
    if not data then
        local done = false
        QBCore.Functions.TriggerCallback('mnc-rollingcoal:getSmokeData', function(cbData)
            data = cbData or false
            done = true
        end, plate)

        local timeout = 0
        while not done and timeout < 2000 do
            Wait(100)
            timeout = timeout + 100
        end
    end

    if data then
        local hasEgr = data.egr_delete or false
        local hasDpf = data.dpf_delete or false

        if not hasEgr or not hasDpf then
            local missing = {}
            if not hasEgr then missing[#missing + 1] = 'EGR Delete Kit' end
            if not hasDpf then missing[#missing + 1] = 'DPF Delete Kit' end
            lib.notify({
                title       = 'Rolling Coal',
                description = 'You must install the following first: ' .. table.concat(missing, ', '),
                type        = 'error',
                duration    = 7000
            })
            return
        end
    else
        lib.notify({ title = 'Rolling Coal', description = 'Vehicle data not loaded – try again.', type = 'error' })
        return
    end

    if DoKitInstall(target, 4000, 'Installing Smoke Kit...') then
        TriggerServerEvent('mnc-rollingcoal:applyKitToVehicle', plate)
    else
        lib.notify({ title = 'Rolling Coal', description = 'Installation cancelled.', type = 'inform' })
    end
end)

-- ===========================
-- Removal Kit – strips EGR, DPF, and smoke kit
-- ===========================
RegisterNetEvent('mnc-rollingcoal:applyRemovalKit', function()
    if not HasAllowedJob() then
        lib.notify({ title = 'Kit Removal', description = 'Only authorized mechanics can remove these kits.', type = 'error' })
        return
    end

    local target = GetVehicleAtFront()
    if not target then
        lib.notify({ title = 'Kit Removal', description = 'Stand directly in front of the vehicle (within 1m of headlights).', type = 'error' })
        return
    end

    if IsAutoKitVehicle(target) then
        lib.notify({ title = 'Kit Removal', description = 'Built-in systems cannot be removed from this vehicle class.', type = 'error' })
        return
    end

    local plate = string.upper(GetVehicleNumberPlateText(target):gsub("%s+", ""))

    -- Fetch current state so we can tell the player what will be removed
    local data = smokeCache[plate]
    if data == nil then
        local done = false
        QBCore.Functions.TriggerCallback('mnc-rollingcoal:getSmokeData', function(cbData)
            data = cbData or false
            done = true
        end, plate)
        local timeout = 0
        while not done and timeout < 2000 do
            Wait(100)
            timeout = timeout + 100
        end
    end

    if not data or (not data.egr_delete and not data.dpf_delete and (not data.amount or data.amount == 0)) then
        lib.notify({ title = 'Kit Removal', description = 'No kits are installed on this vehicle.', type = 'error' })
        return
    end

    -- Build a description of what will be removed
    local removing = {}
    if data.egr_delete then removing[#removing + 1] = 'EGR Delete' end
    if data.dpf_delete then removing[#removing + 1] = 'DPF Delete' end
    if data.amount and data.amount > 0 then removing[#removing + 1] = 'Smoke Kit' end

    lib.notify({
        title       = 'Kit Removal',
        description = 'Removing: ' .. table.concat(removing, ', ') .. '...',
        type        = 'inform',
        duration    = 4500
    })

    if DoKitInstall(target, 4000, 'Removing all smoke kits...') then
        TriggerServerEvent('mnc-rollingcoal:removeAllKits', plate)
    else
        lib.notify({ title = 'Kit Removal', description = 'Removal cancelled.', type = 'inform' })
    end
end)

-- ===========================
-- Sync events
-- ===========================
RegisterNetEvent('mnc-rollingcoal:syncSmokeAmount', function(plate, amount)
    if smokeCache[plate] then
        smokeCache[plate].amount = amount
    end

    if currentVehicle then
        local curPlate = string.upper(GetVehicleNumberPlateText(currentVehicle):gsub("%s+", ""))
        if curPlate == plate then
            StopSmoke(currentVehicle)
            if amount > 0 then
                StartSmoke(currentVehicle, amount)
            end
        end
    end
end)

RegisterNetEvent('mnc-rollingcoal:syncModData', function(plate, data)
    if smokeCache[plate] then
        smokeCache[plate].egr_delete = data.egr_delete
        smokeCache[plate].dpf_delete = data.dpf_delete
    else
        smokeCache[plate] = {
            amount     = data.amount or 0,
            egr_delete = data.egr_delete,
            dpf_delete = data.dpf_delete
        }
    end
end)

-- ===========================
-- Sync: all kits removed from a plate
-- Broadcast by server to every client so effects stop immediately
-- ===========================
RegisterNetEvent('mnc-rollingcoal:syncRemoval', function(plate)
    -- Wipe local cache entry so the smoke loop re-evaluates to "no kit"
    smokeCache[plate] = false

    -- If the local player is currently in that vehicle, stop any active smoke
    if currentVehicle then
        local curPlate = string.upper(GetVehicleNumberPlateText(currentVehicle):gsub("%s+", ""))
        if curPlate == plate then
            StopSmoke(currentVehicle)
        end
    end

    -- Also stop smoke on any nearby vehicle with that plate
    -- (covers cases where the local player isn't in the car but has particles running on it)
    for veh, _ in pairs(activeHandles) do
        if DoesEntityExist(veh) then
            local vPlate = string.upper(GetVehicleNumberPlateText(veh):gsub("%s+", ""))
            if vPlate == plate then
                StopSmoke(veh)
            end
        end
    end
end)