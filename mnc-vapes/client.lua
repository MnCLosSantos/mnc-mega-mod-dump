-- client.lua  (mnc-vapes)
-- Vape equip, puffing, effects, and vape management menus.
-- Crafting UI and portable table → crafting_client.lua

local QBCore         = exports['qb-core']:GetCoreObject()
local activeVape     = nil   -- { itemName, slot, itemData, vapeConfig }
local vapeProp       = nil
local puffOnCooldown = false
local isVaping       = false

local PUFF_ANIM_DICT = "amb@world_human_smoking_pot@male@idle_a"
local PUFF_ANIM_CLIP = "idle_b"

-- ─────────────────────────────────────────────────────────────
--  Utility
-- ─────────────────────────────────────────────────────────────

local function Notify(msg, typ)
    exports.ox_lib:notify({ description = msg, type = typ or 'inform' })
end

local function DebugPrint(msg)
    if Config.DebugMode then print('[mnc-vapes][CLIENT] ' .. tostring(msg)) end
end

-- ─────────────────────────────────────────────────────────────
--  Animations
-- ─────────────────────────────────────────────────────────────

local function LoadAnim(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local t = 0
        while not HasAnimDictLoaded(dict) do
            Wait(50); t = t + 50
            if t > 1000 then return false end
        end
    end
    return true
end

local function PlayPuffAnim()
    local ped = PlayerPedId()

    DebugPrint('PlayPuffAnim called, ped: ' .. tostring(ped))

    local loaded = LoadAnim(PUFF_ANIM_DICT)
    DebugPrint('Anim loaded: ' .. tostring(loaded))
    if not loaded then return end

    TaskPlayAnim(ped, PUFF_ANIM_DICT, PUFF_ANIM_CLIP, 8.0, -8.0, -1, 49, 0, false, false, false)

    SetTimeout(activeVape and activeVape.vapeConfig.exhaleTime or 3500, function()
        StopAnimTask(ped, PUFF_ANIM_DICT, PUFF_ANIM_CLIP, 1.0)
    end)
end

-- ─────────────────────────────────────────────────────────────
--  Exhale particle + effects
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:playExhaleEffect', function(effects, exhaleTime)
    local ped = PlayerPedId()

    RequestNamedPtfxAsset('core')
    local t = 0
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(50); t = t + 50
        if t > 5000 then return end
    end

    local delay = (exhaleTime or 3500) / 2
    SetTimeout(delay, function()
        UseParticleFxAssetNextCall('core')
        local boneIndex = GetPedBoneIndex(ped, 31086)  -- SKEL_Head is good compromise

        local particle = StartParticleFxLoopedOnPedBone(
            'exp_grd_bzgas_smoke',  -- try also 'ent_amb_smoke_general' or 'core' → 'ent_amb_smoke_cabin'
            ped,
            0.0, 0.5, 0.5,   -- offset: forward (y), slightly up (z)
            0.0, 0.0, 0.0,    -- rotation
            boneIndex,
            1.0,              -- scale — 0.5–1.2 depending how thick you want vape cloud
            false, false, false
        )
        SetTimeout(exhaleTime - delay, function()
            StopParticleFxLooped(particle, false)
            RemoveNamedPtfxAsset('core')
        end)
    end)
    
	Wait(20000)
	
    local player = PlayerId()
    if not effects then return end
    for _, eff in ipairs(effects) do
        if eff.name == 'runningSpeedIncrease' then
            SetRunSprintMultiplierForPlayer(player, 1.3)
            SetTimeout(eff.duration, function() SetRunSprintMultiplierForPlayer(player, 1.0) end)
        elseif eff.name == 'infiniteStamina' then
            local endTime = GetGameTimer() + eff.duration
            CreateThread(function()
                while GetGameTimer() < endTime do RestorePlayerStamina(player, 1.0); Wait(0) end
            end)
        elseif eff.name == 'moreStrength' then
            SetPlayerMeleeWeaponDamageModifier(player, 1.5)
            SetTimeout(eff.duration, function() SetPlayerMeleeWeaponDamageModifier(player, 1.0) end)
        elseif eff.name == 'healthRegen' then
            local endTime = GetGameTimer() + eff.duration
            CreateThread(function()
                while GetGameTimer() < endTime do
                    SetEntityHealth(ped, math.min(GetEntityHealth(ped) + 1, 200))
                    Wait(1000)
                end
            end)
        elseif eff.name == 'foodRegen' then
            TriggerServerEvent('hud:server:RelieveStress', math.random(5, 10))
        elseif eff.name == 'drunkWalk' then
            RequestAnimSet('move_m@drunk@slightlydrunk')
            while not HasAnimSetLoaded('move_m@drunk@slightlydrunk') do Wait(0) end
            SetPedMovementClipset(ped, 'move_m@drunk@slightlydrunk', 1.0)
            SetTimeout(eff.duration, function() ResetPedMovementClipset(ped, 0.0) end)
        elseif eff.name == 'psycoWalk' then
            RequestAnimSet('move_m@hurry_butch@a')
            while not HasAnimSetLoaded('move_m@hurry_butch@a') do Wait(0) end
            SetPedMovementClipset(ped, 'move_m@hurry_butch@a', 1.0)
            SetTimeout(eff.duration, function() ResetPedMovementClipset(ped, 0.0) end)
        elseif eff.name == 'outOfBody' then
            StartScreenEffect('DrugsDrivingOut', eff.duration, false)
        elseif eff.name == 'cameraShake' then
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.5)
            SetTimeout(eff.duration, function() StopGameplayCamShaking(true) end)
        elseif eff.name == 'fogEffect' then
            SetTimecycleModifier('fog')
            SetTimeout(eff.duration, function() ClearTimecycleModifier() end)
        elseif eff.name == 'confusionEffect' then
            StartScreenEffect('DrugsMichaelAliensFight', eff.duration, false)
        elseif eff.name == 'white' then
            SetTimecycleModifier('spectator5')
            SetTimeout(eff.duration, function() ClearTimecycleModifier() end)
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
--  Progress bar (triggered by server)
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:startProgress', function(label, duration, animDict, animClip)
    exports.ox_lib:progressBar({
        duration     = duration,
        label        = label,
        useWhileDead = false,
        canCancel    = false,
        disable      = { move = false, car = false, combat = true },
        anim         = {
            dict = animDict or 'amb@world_human_clipboard@male@idle_a',
            clip = animClip or 'idle_c',
        },
    })
end)

-- ─────────────────────────────────────────────────────────────
--  Vape prop helpers
-- ─────────────────────────────────────────────────────────────

local function AttachVapeProp(propName)
    if vapeProp and DoesEntityExist(vapeProp) then DeleteEntity(vapeProp); vapeProp = nil end
    local ped   = PlayerPedId()
    local model = GetHashKey(propName)
    RequestModel(model)
    local t = 0
    while not HasModelLoaded(model) do
        Wait(50); t = t + 50
        if t > 5000 then DebugPrint('Model timeout: ' .. propName); return end
    end
    local x, y, z = GetEntityCoords(ped)
    vapeProp = CreateObject(model, x, y, z, true, true, false)
    local attachPos = activeVape.vapeConfig.attachPos or {0.13, 0.05, 0.0}
    local attachRot = activeVape.vapeConfig.attachRot or {15.0, 180.0, 20.0}
    AttachEntityToEntity(vapeProp, ped, GetPedBoneIndex(ped, Config.PropBone),
        attachPos[1], attachPos[2], attachPos[3],
        attachRot[1], attachRot[2], attachRot[3],
        true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
end

local function RemoveVapeProp()
    if vapeProp and DoesEntityExist(vapeProp) then DeleteEntity(vapeProp); vapeProp = nil end
    local ped        = PlayerPedId()
    local vapeModels = {}
    for _, v in pairs(Config.Vapes) do vapeModels[GetHashKey(v.prop)] = true end
    for _, obj in ipairs(GetGamePool('CObject')) do
        if vapeModels[GetEntityModel(obj)] and IsEntityAttachedToEntity(obj, ped) then
            DeleteEntity(obj)
        end
    end
end

local function StopVapeThread()
    isVaping = false
    RemoveVapeProp()
    local ped = PlayerPedId()
    StopAnimTask(ped, PUFF_ANIM_DICT, PUFF_ANIM_CLIP, 1.0)
    ClearPedSecondaryTask(ped)
    activeVape = nil
end

-- ─────────────────────────────────────────────────────────────
--  Vape thread  (hold E to puff, G to put away, H for menu)
-- ─────────────────────────────────────────────────────────────

local function StartVapeThread(itemName, slot, itemData, vapeConfig)
    activeVape = { itemName = itemName, slot = slot, itemData = itemData, vapeConfig = vapeConfig }
    AttachVapeProp(vapeConfig.prop)
    Notify('Press [E] to puff · [G] to put away · [H] for menu', 'inform')

    if itemName == 'box_vape' then
        if not itemData.has_coil then
            Notify('No coil installed – use menu (H) to install.', 'error')
        elseif not itemData.tank then
            Notify('No tank installed – install via menu (H).', 'error')
        end
    end

    isVaping = true
    CreateThread(function()
        while isVaping do
            Wait(0)
            if IsControlJustReleased(0, 38) then   -- E
                TriggerEvent('mnc-vapes:client:takePuff')
            end
            if IsControlJustReleased(0, 47) then   -- G
                StopVapeThread()
            end
            if IsControlJustReleased(0, 74) then   -- H
                TriggerServerEvent('mnc-vapes:server:openVapeMenu', activeVape.itemName, activeVape.slot)
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────
--  Take puff
-- ─────────────────────────────────────────────────────────────

AddEventHandler('mnc-vapes:client:takePuff', function()
    if puffOnCooldown or not activeVape then return end
    puffOnCooldown = true
    PlayPuffAnim()
    TriggerServerEvent('mnc-vapes:server:recordPuff', activeVape.itemName, activeVape.slot)
    SetTimeout(Config.PuffCooldown, function() puffOnCooldown = false end)
end)

-- ─────────────────────────────────────────────────────────────
--  Equip vape  (server sends slot too)
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:equipVape', function(itemName, slot, itemData)
    local cfg = Config.Vapes[itemName]
    if not cfg then return end
    if isVaping then StopVapeThread(); Wait(200) end
    StartVapeThread(itemName, slot, itemData, cfg)
end)

-- Metadata update (after puff/charge/fill)
RegisterNetEvent('mnc-vapes:client:updateMetadata', function(newData)
    if activeVape then activeVape.itemData = newData end
end)

-- ─────────────────────────────────────────────────────────────
--  Vape context menu  (server-side sends us the data to display)
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:openVapeMenu', function(itemName, vapeSlot, d)
    local cfg = Config.Vapes[itemName]
    if not cfg then return end

    d = d or {}

    local options  = {}
    local battPct  = math.floor(((d.battery or 0) / cfg.maxBattery) * 100)
    local maxCap   = cfg.tankSize or 0
    if cfg.canChangeTank and d.tank and Config.Tanks[d.tank] then
        maxCap = Config.Tanks[d.tank].size
    end
    local juicePct  = maxCap > 0 and math.floor(((d.juice_ml or 0) / maxCap) * 100) or 0

    -- Coil display
    local coilStatus
    if not cfg.canChangeCoil then
        coilStatus = 'Non-replaceable'
    elseif d.has_coil then
        coilStatus = string.format('%d puffs left', d.coil_puffs or 0)
    else
        coilStatus = 'No coil'
    end

    -- Tank display
    local tankStatus
    if not cfg.canChangeTank then
        tankStatus = string.format('%.0f ml (built-in)', cfg.tankSize or 0)
    elseif d.tank and Config.Tanks[d.tank] then
        tankStatus = Config.Tanks[d.tank].label
    else
        tankStatus = 'No tank'
    end

    -- Flavour in tank
    local flavourLabel = 'Empty'
    if d.flavor and Config.VapeJuices[d.flavor] then
        flavourLabel = Config.VapeJuices[d.flavor].label
    end
    local liquidAmt = string.format('%.1f ml (%d%%) — %s', d.juice_ml or 0, juicePct, flavourLabel)

    table.insert(options, {
        title = '✅ Vape Status',
        description = string.format('Battery: %d%% | Coil: %s | Tank: %s | Liquid: %s',
            battPct, coilStatus, tankStatus, liquidAmt),
        disabled = false,
    })

    table.insert(options, {
        title       = '🧪 Fill with Juice',
        description = 'Pick a juice from your inventory',
        onSelect    = function()
            TriggerServerEvent('mnc-vapes:server:openFillMenu', itemName, vapeSlot)
        end,
    })

    table.insert(options, {
        title       = '🔋 Charge Vape',
        description = 'Requires a vape charger in inventory',
        onSelect    = function()
            TriggerServerEvent('mnc-vapes:server:chargeVape', itemName, vapeSlot)
        end,
    })

    if cfg.canChangeCoil then
        if d.has_coil then
            table.insert(options, {
                title       = '🔩 Remove Coil',
                description = string.format('Puffs remaining: %d', d.coil_puffs or 0),
                onSelect    = function()
                    TriggerServerEvent('mnc-vapes:server:removeCoil', itemName, vapeSlot)
                end,
            })
        else
            table.insert(options, {
                title       = '🔩 Install Coil',
                description = 'Requires vape_coil in inventory',
                onSelect    = function()
                    TriggerServerEvent('mnc-vapes:server:installCoil', itemName, vapeSlot)
                end,
            })
        end

        if d.tank then
            table.insert(options, {
                title    = '🛢️ Remove Tank (' .. d.tank .. ')',
                onSelect = function()
                    TriggerServerEvent('mnc-vapes:server:removeTank', itemName, vapeSlot)
                end,
            })
        else
            table.insert(options, {
                title       = '🛢️ Install Tank',
                description = 'Choose a tank from your inventory',
                onSelect    = function()
                    TriggerServerEvent('mnc-vapes:server:openTankMenu', itemName, vapeSlot)
                end,
            })
        end
    end

    if #options == 0 then Notify('No options available.', 'error'); return end

    exports.ox_lib:registerContext({ id = 'mnc_vape_menu', title = cfg.label .. ' Options', options = options })
    exports.ox_lib:showContext('mnc_vape_menu')
end)

-- ─────────────────────────────────────────────────────────────
--  Fill menu
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:showFillMenu', function(itemName, vapeSlot, availableJuices)
    if not availableJuices or #availableJuices == 0 then
        Notify('No compatible juice in inventory.', 'error'); return
    end

    local options = {}
    for _, j in ipairs(availableJuices) do
        local jCfg = Config.VapeJuices[j.name]
        if jCfg then
            local puffsLeft = math.floor((j.remaining_ml or 0) * Config.PuffsPerMl)
            table.insert(options, {
                title       = jCfg.label,
                description = string.format('%.1f ml remaining  ·  ~%d puffs  [ID: %s]',
                    j.remaining_ml, puffsLeft, string.sub(j.liquidId or '??', 1, 8)),
                onSelect    = function()
                    local ok = exports.ox_lib:alertDialog({
                        header   = 'Fill Vape',
                        content  = 'Fill with ' .. jCfg.label .. '?',
                        centered = true,
                        cancel   = true,
                    })
                    if ok == 'confirm' then
                        TriggerServerEvent('mnc-vapes:server:fillVape', itemName, vapeSlot, j.name, j.slot)
                    end
                end,
            })
        end
    end

    if #options == 0 then Notify('No compatible juice in inventory.', 'error'); return end

    exports.ox_lib:registerContext({ id = 'mnc_fill_menu', title = 'Select Juice', options = options })
    exports.ox_lib:showContext('mnc_fill_menu')
end)

-- ─────────────────────────────────────────────────────────────
--  Tank menu
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:showTankMenu', function(itemName, vapeSlot, availableTanks)
    if not availableTanks or #availableTanks == 0 then
        Notify('No tanks in inventory.', 'error'); return
    end

    local options = {}
    for _, t in ipairs(availableTanks) do
        local tCfg = Config.Tanks[t.name]
        if tCfg then
            table.insert(options, {
                title    = tCfg.label,
                onSelect = function()
                    TriggerServerEvent('mnc-vapes:server:installTank', itemName, vapeSlot, t.name, t.slot)
                end,
            })
        end
    end

    if #options == 0 then Notify('No tanks in inventory.', 'error'); return end

    exports.ox_lib:registerContext({ id = 'mnc_tank_menu', title = 'Select Tank', options = options })
    exports.ox_lib:showContext('mnc_tank_menu')
end)

-- ─────────────────────────────────────────────────────────────
--  Charger menu
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:openChargerMenu', function(vapeList)
    if not vapeList or #vapeList == 0 then
        Notify('No vapes to charge.', 'error'); return
    end

    local options = {}
    for _, v in ipairs(vapeList) do
        local cfg = Config.Vapes[v.name]
        if cfg then
            local battPct = math.floor(((v.data.battery or 0) / cfg.maxBattery) * 100)
            table.insert(options, {
                title       = cfg.label,
                description = string.format('Battery: %d%%  [ID: %s]',
                    battPct, string.sub(v.data.vapeId or '??', 1, 8)),
                onSelect    = function()
                    TriggerServerEvent('mnc-vapes:server:chargeVape', v.name, v.slot)
                end,
            })
        end
    end

    if #options == 0 then Notify('No vapes to charge.', 'error'); return end

    exports.ox_lib:registerContext({ id = 'mnc_charger_menu', title = '🔌 Vape Charger', options = options })
    exports.ox_lib:showContext('mnc_charger_menu')
end)