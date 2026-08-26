local QBCore = exports['qb-core']:GetCoreObject()
local aidActive, aidType, aidEnd, aidProp = false, nil, 0, nil
local movementRestricted = false

-- 🧠 Progress bar handler with EMS animation
local function startProgress(label, duration, cb)
    local ped = PlayerPedId()
    local animStarted = false

    -- Start EMS animation
    RequestAnimDict("mini@repair")
    while not HasAnimDictLoaded("mini@repair") do Wait(10) end
    TaskPlayAnim(ped, "mini@repair", "fixing_a_ped", 8.0, -8.0, -1, 49, 0, false, false, false)
    animStarted = true

    if Config.ProgressType == "QB" then
        exports['progressbar']:Progress({
            name = "mnc_crutch_progress",
            duration = duration * 1000,
            label = label,
            useWhileDead = false,
            canCancel = true,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            },
        }, function(cancelled)
            if animStarted then
                ClearPedTasks(ped)
            end
            cb(not cancelled)
        end)
    elseif Config.ProgressType == "circle" then
        local success = lib.progressCircle({
            duration = duration * 1000,
            label = label,
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
        })
        if animStarted then
            ClearPedTasks(ped)
        end
        cb(success)
    else
        local success = lib.progressBar({
            duration = duration * 1000,
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
        })
        if animStarted then
            ClearPedTasks(ped)
        end
        cb(success)
    end
end

-- 🧩 Target setup
CreateThread(function()
    exports['qb-target']:AddGlobalPlayer({
        options = {
            {
                label = 'EMS: Manage Mobility Aid',
                icon = 'fa-solid fa-kit-medical',
                job = Config.EMSJob,
                action = function(entity)
                    local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                    openAidMenu(targetId)
                end
            },
            {
                label = 'EMS: Check Aid Time',
                icon = 'fa-solid fa-clock',
                job = Config.EMSJob,
                canInteract = function()
                    return Config.EMSCanSeeRemaining
                end,
                action = function(entity)
                    local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                    QBCore.Functions.TriggerCallback('mnc-crutch:getRemainingTime', function(timeLeft)
                        if timeLeft and timeLeft > 0 then
                            notify("Player has " .. timeLeft .. " minutes remaining on mobility aid.")
                        else
                            notify("No active mobility aid found.")
                        end
                    end, targetId)
                end
            },
        },
        distance = 2.0
    })
end)

-- 🩺 Menu handler
function openAidMenu(targetId)
    local options = {
        { title = "Give Crutch", event = 'mnc-crutch:applyWithProgress', args = { targetId, 'crutch' } },
        { title = "Give Cane", event = 'mnc-crutch:applyWithProgress', args = { targetId, 'cane' } },
        { title = "Remove Aid", event = 'mnc-crutch:removeWithProgress', args = { targetId } },
    }

    if Config.MenuSystem == 'ox_lib' then
        lib.registerContext({
            id = 'ems_aid_menu',
            title = 'EMS Mobility Aid Menu',
            options = options
        })
        lib.showContext('ems_aid_menu')
    else
        local menu = {}
        for _, v in pairs(options) do
            menu[#menu + 1] = {
                header = v.title,
                params = { event = v.event, args = v.args }
            }
        end
        exports['qb-menu']:openMenu(menu)
    end
end

-- 🩹 Apply with progress
RegisterNetEvent('mnc-crutch:applyWithProgress', function(data)
    local targetId, aid = data[1], data[2]
    local cfg = Config.Aids[aid]
    if not cfg then return end

    startProgress(cfg.progressLabel or "Applying aid...", Config.ProgressDurations.apply, function(success)
        if success then
            TriggerServerEvent('mnc-crutch:applyAid', targetId, aid)
        else
            notify("Cancelled.")
        end
    end)
end)

-- 🩹 Remove with progress
RegisterNetEvent('mnc-crutch:removeWithProgress', function(data)
    local targetId = data[1]
    startProgress("Removing aid...", Config.ProgressDurations.remove, function(success)
        if success then
            TriggerServerEvent('mnc-crutch:removeAid', targetId)
        else
            notify("Cancelled.")
        end
    end)
end)

-- 🧍 Apply aid client-side
RegisterNetEvent('mnc-crutch:applyClientAid', function(type, endTime)
    aidType = type
    aidEnd = endTime
    aidActive = true
    applyAidPropsAndAnim()

    if Config.RestrictMovement then
        restrictMovement(true)
    end

    CreateThread(function()
        while aidActive do
            Wait(1000)
            if os.time() > aidEnd then
                TriggerEvent('mnc-crutch:removeClientAid')
            end
        end
    end)
end)

RegisterNetEvent('mnc-crutch:removeClientAid', function()
    aidActive = false
    aidType = nil
    aidEnd = 0
    clearAid()
    restrictMovement(false)
    notify("Mobility aid removed.")
end)

-- 🧾 Resync after clothing reload
AddEventHandler('qb-clothing:client:reloadOutfit', function()
    TriggerServerEvent('mnc-crutch:requestSync')
end)

-- 🔧 Animation + Prop handling
function applyAidPropsAndAnim()
    clearAid()
    local cfg = Config.Aids[aidType]
    if not cfg then return end

    local ped = PlayerPedId()
    RequestAnimSet(cfg.animDict)
    while not HasAnimSetLoaded(cfg.animDict) do Wait(10) end
    SetPedMovementClipset(ped, cfg.animDict, true)

    if not cfg.prop then return end

    local model = GetHashKey(cfg.prop)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local boneIndex = GetPedBoneIndex(ped, cfg.bone or 57005)
    local prop = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    SetEntityCollision(prop, false, false)
    AttachEntityToEntity(
        prop,
        ped,
        boneIndex,
        cfg.offset.x, cfg.offset.y, cfg.offset.z,
        cfg.rotation.x, cfg.rotation.y, cfg.rotation.z,
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(model)
    aidProp = prop
end

function clearAid()
    local ped = PlayerPedId()
    ResetPedMovementClipset(ped, 0)
    if aidProp and DoesEntityExist(aidProp) then
        DeleteEntity(aidProp)
        aidProp = nil
    end
end

-- 🚷 Movement and combat restriction
function restrictMovement(state)
    movementRestricted = state
    CreateThread(function()
        while movementRestricted do
            Wait(0)
            local ped = PlayerPedId()
            -- Disable sprint and jump
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Jump
            -- Disable melee combat (punching)
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 140, true) -- Light melee
            DisableControlAction(0, 141, true) -- Heavy melee
            DisableControlAction(0, 142, true) -- Alternate melee
            -- Disable weapon usage
            SetPedCanSwitchWeapon(ped, false)
            DisablePlayerFiring(ped, true) -- Prevent firing
            -- Ensure injured animation persists
            if not IsPedUsingScenario(ped, Config.Aids[aidType].animDict) then
                SetPedMovementClipset(ped, Config.Aids[aidType].animDict, true)
            end
        end
        -- Re-enable weapon switching when restrictions are lifted
        if not movementRestricted then
            SetPedCanSwitchWeapon(PlayerPedId(), true)
        end
    end)
end

-- 🔔 Notifications
RegisterNetEvent('mnc-crutch:notify', function(msg)
    notify(msg)
end)

function notify(msg)
    if Config.NotifySystem == "ox_lib" then
        lib.notify({ description = msg, type = 'inform' })
    else
        QBCore.Functions.Notify(msg, 'primary')
    end
end