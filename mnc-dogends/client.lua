local QBCore = exports['qb-core']:GetCoreObject()
local searched = {}

local function Notify(msg, type)
    if type == nil then type = 'inform' end
    lib.notify({ description = msg, type = type })
end

-- Minigame before pickup
local function DoMinigame()
    if not Config.Minigame.Enabled then return true end

    local keys = {"w", "a", "s", "d"}
    local success = lib.skillCheck(Config.Minigame.Difficulty, keys)
    
    if not success then
        Notify("You failed the skill check!", "error")
    end
    
    return success
end

-- Progress bar with animation
local function DoProgress(label, duration, animDict, animName, flags)
    flags = flags or 49
    local ped = PlayerPedId()

    local success = lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            disableMovement = true,
            disableCarMovement = true,
            disableCombat = true,
        },
        anim = {
            dict = animDict,
            clip = animName,
            flag = flags
        }
    })

    ClearPedTasks(ped)
    RemoveAnimDict(animDict)
    return success
end

-- Pickup sound
local function PlaySoundFromEntity(entity, soundList)
    if not soundList or #soundList == 0 then return end
    local soundName = soundList[math.random(1, #soundList)]
    local coords = GetEntityCoords(entity)
    local soundId = GetSoundId()
    PlaySoundFromCoord(soundId, soundName, coords.x, coords.y, coords.z, "DLC_HEIST_BIOLAB_PREP_HACK_SOUNDS", false, 0, false)
    SetTimeout(5000, function()
        StopSound(soundId)
        ReleaseSoundId(soundId)
    end)
end

local function CanPickup(entity)
    if searched[entity] then
        Notify("You've already picked this up.", "error")
        return false
    end
    return true
end

local function PickupEntity(entity)
    if not DoesEntityExist(entity) or not CanPickup(entity) then return end

    if not DoMinigame() then return end

    local success = DoProgress(
        "Picking up cigarette butts...",
        Config.SearchTime,
        "mini@repair",
        "fixing_a_ped",
        49
    )

    if success then
        PlaySoundFromEntity(entity, Config.PickupSounds)
        TriggerServerEvent("mnc-dogends:finishPickup")
        searched[entity] = true
        -- DeleteEntity(entity) -- uncomment if you want butts to disappear visually
    end
end

-- Rolling progress (animation plays during bar)
local function StartRollingProcess(method, tobaccoType, filterType, amount)
    local filterLabel = QBCore.Shared.Items[filterType].label or "filters"
    local isMint = filterType == "filter_pack_mint"
    local cigaretteType = isMint and "mint " or ""
    
    local label = string.format("Rolling %d %scigarette%s...", amount, cigaretteType, amount > 1 and "s" or "")
    
    local success = DoProgress(
        label,
        Config.RollTime * amount,
        "anim@amb@business@weed@weed_inspecting_lo_med_hi@",
        "weed_crouch_checkingleaves_idle_01_inspector",
        49
    )

    if success then
        TriggerServerEvent('mnc-dogends:finishRolling', method, tobaccoType, filterType, amount)
    else
        Notify("You cancelled rolling.", "error")
    end
end

-- Amount selection menu
local function OpenAmountMenu(method, tobaccoType, filterType)
    local options = {}
    for i = 1, 10 do
        table.insert(options, {
            title = "Roll " .. i .. " cigarette" .. (i > 1 and "s" or ""),
            description = "Takes " .. (method == "butts" and (Config.RequiredButts * i) or (Config.TobaccoPerRoll * i)) .. (method == "butts" and " butts" or "g"),
            onSelect = function()
                StartRollingProcess(method, tobaccoType, filterType, i)
            end
        })
    end

    lib.registerContext({
        id = 'rolling_amount',
        title = 'How many to roll?',
        options = options
    })
    lib.showContext('rolling_amount')
end

-- Main rolling menu
RegisterNetEvent('mnc-dogends:openRollingMenu', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local menu = {}

    -- Butts option
    local buttsCount = 0
    for _, item in pairs(PlayerData.items or {}) do
        if item.name == Config.PickupItem then
            buttsCount = item.amount
            break
        end
    end

    if buttsCount >= Config.RequiredButts then
        table.insert(menu, {
            title = "Roll using Cigarette Butts",
            description = string.format("Requires %d × %s + papers + filters per cigarette", Config.RequiredButts, QBCore.Shared.Items[Config.PickupItem].label),
            onSelect = function()
                local filterOptions = {}
                for filterName in pairs(Config.FilterPacks) do
                    local remaining = 0
                    for _, it in pairs(PlayerData.items or {}) do
                        if it.name == filterName then
                            remaining = it.info and it.info.remaining_filters or Config.FilterPacks[filterName]
                            break
                        end
                    end
                    if remaining >= 1 then
                        table.insert(filterOptions, {
                            title = QBCore.Shared.Items[filterName].label,
                            description = string.format("Remaining: %d filters", remaining),
                            onSelect = function()
                                OpenAmountMenu("butts", nil, filterName)
                            end
                        })
                    end
                end

                if #filterOptions == 0 then
                    Notify("No filter packs with remaining filters found.", "error")
                    return
                end

                lib.registerContext({
                    id = 'filter_choice_butts',
                    title = 'Choose Filter Pack',
                    options = filterOptions
                })
                lib.showContext('filter_choice_butts')
            end
        })
    end

    -- Tobacco pouch options
    for pouchName, pouchData in pairs(Config.TobaccoPouches) do
        local remainingGrams = 0
        for _, item in pairs(PlayerData.items or {}) do
            if item.name == pouchName then
                remainingGrams = item.info and item.info.remaining_grams or pouchData.grams
                break
            end
        end

        if remainingGrams >= Config.TobaccoPerRoll then
            table.insert(menu, {
                title = "Roll using " .. QBCore.Shared.Items[pouchName].label,
                description = string.format("Remaining: %.1fg (~%d rolls)", remainingGrams, math.floor(remainingGrams / Config.TobaccoPerRoll)),
                onSelect = function()
                    local filterOptions = {}
                    for filterName in pairs(Config.FilterPacks) do
                        local remaining = 0
                        for _, it in pairs(PlayerData.items or {}) do
                            if it.name == filterName then
                                remaining = it.info and it.info.remaining_filters or Config.FilterPacks[filterName]
                                break
                            end
                        end
                        if remaining >= 1 then
                            table.insert(filterOptions, {
                                title = QBCore.Shared.Items[filterName].label,
                                description = string.format("Remaining: %d filters", remaining),
                                onSelect = function()
                                    OpenAmountMenu("tobacco", pouchName, filterName)
                                end
                            })
                        end
                    end

                    if #filterOptions == 0 then
                        Notify("No filter packs with remaining filters found.", "error")
                        return
                    end

                    lib.registerContext({
                        id = 'filter_choice_tobacco_' .. pouchName,
                        title = 'Choose Filter Pack',
                        options = filterOptions
                    })
                    lib.showContext('filter_choice_tobacco_' .. pouchName)
                end
            })
        end
    end

    if #menu == 0 then
        Notify("You don't have enough butts or usable tobacco to roll anything.", "error")
        return
    end

    lib.registerContext({
        id = 'rolling_method',
        title = 'How do you want to roll?',
        options = menu
    })
    lib.showContext('rolling_method')
end)

-- qb-target setup for picking up butts
CreateThread(function()
    exports[Config.Target]:AddTargetModel(Config.PropModels, {
        options = {
            {
                label = "Pick up cigarette butts",
                icon = "fas fa-hand-paper",
                action = function(entity)
                    PickupEntity(entity)
                end
            }
        },
        distance = 2.0
    })
end)

local function PickupLighter(entity)
    if not DoesEntityExist(entity) or not CanPickup(entity) then return end

    if not DoMinigame() then return end

    local success = DoProgress(
        "Picking up lighter...",
        Config.SearchTime,
        "mini@repair",
        "fixing_a_ped",
        49
    )

    if success then
        PlaySoundFromEntity(entity, Config.PickupSounds)
        TriggerServerEvent("mnc-dogends:finishPickupLighter")
        searched[entity] = true
        DeleteEntity(entity) 
    end
end

-- qb-target setup for picking up lighters
CreateThread(function()
    exports[Config.Target]:AddTargetModel(Config.LighterModels, {
        options = {
            {
                label = "Pick up lighter",
                icon = "fas fa-hand-paper",
                action = function(entity)
                    PickupLighter(entity)
                end
            }
        },
        distance = 2.0
    })
end)
