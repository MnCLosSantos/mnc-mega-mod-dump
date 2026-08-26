local QBCore = exports[Config.CoreName]:GetCoreObject()
local searched = {}

-- Notification handler (client-side only)
local function Notify(msg, type)
    if Config.Notify == "qb" then
        QBCore.Functions.Notify(msg, type)
    elseif Config.Notify == "ox_lib" then
        lib.notify({description = msg, type = type})
    end
end

-- Minigame handler using ox_lib skillCheck
local function DoMinigame(entityType)
    if not Config.Minigame.Enabled then return true end

    local minigameConfig = (entityType == "bin" and Config.Minigame.BinSkip) or Config.Minigame.Scrap
    local keys

    if minigameConfig.Type == "wasd" then
        keys = {"w", "a", "s", "d"}
    elseif minigameConfig.Type == "1234" then
        keys = {"1", "2", "3", "4"}
    elseif minigameConfig.Type == "arrowkeys" then
        keys = {"up", "down", "left", "right"}
    elseif minigameConfig.Type == "qwer" then
        keys = {"q", "w", "e", "r"}
    else
        Notify("Invalid minigame type configured.", "error")
        return false
    end

    local success = lib.skillCheck(minigameConfig.Difficulty, keys)
    if not success then
        Notify("You failed the skill check!", "error")
    end
    return success
end

-- Progress handler
local function DoProgress(label)
    local animation = {
        animDict = "mini@repair",
        anim = "fixing_a_ped",
        flags = 49
    }
    local disable = {
        disableMovement = true,
        disableCarMovement = true,
        disableCombat = true
    }

    local success = false
    local isComplete = false

    if not HasAnimDictLoaded(animation.animDict) then
        RequestAnimDict(animation.animDict)
        local timeout = 1000
        while not HasAnimDictLoaded(animation.animDict) and timeout > 0 do
            Citizen.Wait(10)
            timeout = timeout - 10
        end
        if timeout <= 0 then
            Notify("Failed to load animation.", "error")
            return false
        end
    end

    TaskPlayAnim(PlayerPedId(), animation.animDict, animation.anim, 8.0, -8.0, -1, animation.flags, 0, false, false, false)

    local function DisableControls()
        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 245, true)
    end

    local controlThread = CreateThread(function()
        while not isComplete do
            DisableControls()
            Citizen.Wait(0)
        end
    end)

    if Config.Progress == "qb" then
        QBCore.Functions.Progressbar("searching", label, Config.SearchTime, false, true, disable, animation, {}, {}, function()
            success = true
            isComplete = true
        end, function()
            success = false
            isComplete = true
        end)
        while not isComplete do
            Citizen.Wait(100)
        end
    elseif Config.Progress == "ox_lib_bar" then
        success = lib.progressBar({
            duration = Config.SearchTime,
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = disable,
            anim = animation
        })
        isComplete = true
    elseif Config.Progress == "ox_lib_circle" then
        success = lib.progressCircle({
            duration = Config.SearchTime,
            position = 'bottom',
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = disable,
            anim = animation
        })
        isComplete = true
    end

    TerminateThread(controlThread)
    ClearPedTasks(PlayerPedId())
    RemoveAnimDict(animation.animDict)
    return success
end

-- Determine sound type from prop model
local function GetSoundType(entity)
    local model = GetEntityModel(entity)
    if model == 0 then return "Bin" end
    local archetype = GetEntityArchetypeName(entity)
    if archetype:find("skip") or archetype:find("dumpster") then
        return "Skip"
    elseif archetype:find("bag") then
        return "Bag"
    elseif archetype:find("wreck") then
        return "Scrap"
    else
        return "Bin"
    end
end

-- Play rummage sound
local function PlayRummageSound(entity)
    local soundType = GetSoundType(entity)
    local soundList = Config.RummageSounds[soundType] or Config.RummageSounds.Bin
    local soundName = soundList[math.random(1, #soundList)]
    local coords = GetEntityCoords(entity)
    local soundId = GetSoundId()
    PlaySoundFromCoord(soundId, soundName, coords.x, coords.y, coords.z, "DLC_HEIST_BIOLAB_PREP_HACK_SOUNDS", false, 0, false)
    SetTimeout(Config.SearchTime - 1000, function()
        StopSound(soundId)
        ReleaseSoundId(soundId)
    end)
    return soundId
end

-- Cooldown
local function CanSearch(entity)
    if searched[entity] and (GetGameTimer() - searched[entity]) < Config.Cooldown then
        Notify("You've already searched this recently.", "error")
        return false
    end
    return true
end

-- Needle prick: notification + screen effects + pain anim + sound + health drain
local function ApplyNeedlePrick()
    local ped = PlayerPedId()

    Notify(Config.NeedlePrick.NotifyMessage, Config.NeedlePrick.NotifyType)

    -- Play random needle prick sound
    if Config.NeedleSounds and #Config.NeedleSounds > 0 then
        local needleSound = Config.NeedleSounds[math.random(1, #Config.NeedleSounds)]
        local soundId = GetSoundId()
        PlaySoundFrontend(soundId, needleSound, "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        -- Optional: longer sounds can be stopped later, but most frontend sounds are short
        SetTimeout(4000, function()
            StopSound(soundId)
            ReleaseSoundId(soundId)
        end)
    end

    -- Blood/damage screen effect
    if Config.NeedlePrick.BloodScreenEffect and Config.NeedlePrick.BloodScreenEffect ~= "" then
        StartScreenEffect(Config.NeedlePrick.BloodScreenEffect, Config.NeedlePrick.BloodEffectDuration, false)
    end

    -- Extra camera shake
    if Config.NeedlePrick.ExtraShake then
        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", Config.NeedlePrick.ShakeAmplitude)
        Citizen.CreateThread(function()
            Citizen.Wait(Config.NeedlePrick.ShakeDuration)
            StopGameplayCamShaking(true)
        end)
    end

    -- Player pain reaction animation
    if Config.NeedlePrick.PainAnimDict and Config.NeedlePrick.PainAnimName then
        RequestAnimDict(Config.NeedlePrick.PainAnimDict)
        local timeout = 800
        while not HasAnimDictLoaded(Config.NeedlePrick.PainAnimDict) and timeout > 0 do
            Citizen.Wait(10)
            timeout = timeout - 10
        end

        if HasAnimDictLoaded(Config.NeedlePrick.PainAnimDict) then
            TaskPlayAnim(
                ped,
                Config.NeedlePrick.PainAnimDict,
                Config.NeedlePrick.PainAnimName,
                8.0, -8.0,
                Config.NeedlePrick.PainAnimDuration,
                Config.NeedlePrick.PainAnimFlag,
                0, false, false, false
            )

            Citizen.Wait(Config.NeedlePrick.PainAnimDuration + 300)
            ClearPedSecondaryTask(ped)
            RemoveAnimDict(Config.NeedlePrick.PainAnimDict)
        end
    end

    -- Gradual health drain
    local damagePerTick = math.ceil(Config.NeedlePrick.HealthDrain / Config.NeedlePrick.DrainTicks)
    Citizen.CreateThread(function()
        for i = 1, Config.NeedlePrick.DrainTicks do
            if not IsEntityDead(ped) then
                ApplyDamageToPed(ped, damagePerTick, false)
            end
            Citizen.Wait(Config.NeedlePrick.TickInterval)
        end
    end)
end

-- Main search logic
local function SearchEntity(entity, type)
    if not DoesEntityExist(entity) or not CanSearch(entity) then return end

    if not DoMinigame(type) then return end

    local label = (type == "bin" and "Searching the trash..." or "Searching the scrap...")

    local soundId = PlayRummageSound(entity)
    local success = DoProgress(label)

    if success then
        -- Needle chance — only for bins
        if type == "bin" and Config.NeedlePrick and Config.NeedlePrick.Enabled then
            if math.random(1, 100) <= Config.NeedlePrick.Chance then
                ApplyNeedlePrick()
            end
        end

        TriggerServerEvent("mnc-scrapnbins:finishSearch", type)
        searched[entity] = GetGameTimer()
    else
        StopSound(soundId)
        ReleaseSoundId(soundId)
        ClearPedTasks(PlayerPedId())
    end

    StopSound(soundId)
    ReleaseSoundId(soundId)
end

-- Setup targets
local function SetupTargets()
    local function AddTarget(models, label, type)
        if Config.Target == "qb-target" then
            exports['qb-target']:AddTargetModel(models, {
                options = {
                    {
                        label = label,
                        icon = "fas fa-search",
                        action = function(entity) SearchEntity(entity, type) end
                    }
                },
                distance = 2.0
            })
        elseif Config.Target == "ox_target" then
            exports.ox_target:addModel(models, {
                {
                    name = "mnc_search_"..type,
                    label = label,
                    icon = "fas fa-search",
                    onSelect = function(data) SearchEntity(data.entity, type) end,
                    distance = 2.0
                }
            })
        end
    end

    AddTarget(Config.BinModels, "Search Trash", "bin")
    AddTarget(Config.ScrapModels, "Search Scrap", "scrap")
end

CreateThread(SetupTargets)