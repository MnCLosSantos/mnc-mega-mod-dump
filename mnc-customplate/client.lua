-- ============================================================
--  MNC Custom Plate - Client
-- ============================================================

local isUIOpen   = false
local isApplying = false
local adminMode  = false

-- ============================================================
--  Notify helper
-- ============================================================

local function Notify(msg, ntype, duration)
    lib.notify({
        title       = 'Custom Plate',
        description = msg,
        type        = ntype or 'inform',
        duration    = duration or 4000,
    })
end

-- ============================================================
--  Vehicle helper — finds closest vehicle within range
-- ============================================================

local PLATE_USE_RANGE = 5.0   -- metres

local function GetClosestVehicle()
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- If already inside a vehicle, use that
    local currentVeh = GetVehiclePedIsIn(ped, false)
    if currentVeh ~= 0 then
        return currentVeh
    end

    local closest, closestDist = nil, PLATE_USE_RANGE

    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        local dist = #(coords - GetEntityCoords(veh))
        if dist < closestDist then
            closestDist = dist
            closest     = veh
        end
    end

    return closest
end

-- ============================================================
--  Open NUI
-- ============================================================

local function OpenUI(isAdmin)
    if isUIOpen or isApplying then return end

    adminMode = isAdmin or false
    isUIOpen  = true

    SetNuiFocus(true, true)

    SendNUIMessage({
        action    = 'openUI',
        themes    = Config.PlateThemes,
        state     = Config.PlateState,
        maxLen    = Config.MaxPlateLength,
        minLen    = Config.MinPlateLength,
        adminMode = adminMode,
    })
end

-- ============================================================
--  Apply plate
-- ============================================================

local function ApplyPlate(plateText, themeId)
    local veh = GetClosestVehicle()
    if not veh and not adminMode then
        Notify('No vehicle found nearby. Get closer to a vehicle and try again.', 'error')
        isApplying = false
        return
    end

    if isApplying then return end
    isApplying = true

    local ped = PlayerPedId()

    lib.requestAnimDict(Config.AnimDict)

    TaskPlayAnim(ped, Config.AnimDict, Config.AnimName, 8.0, -8.0, -1, 49, 0, false, false, false)

    local success = lib.progressBar({
        duration     = Config.ProgressDuration,
        label        = 'Applying custom plate...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { car = true, move = true, combat = true },
        anim         = { dict = Config.AnimDict, clip = Config.AnimName },
    })

    StopAnimTask(ped, Config.AnimDict, Config.AnimName, 1.0)
    ClearPedTasks(ped)

    if not success then
        isApplying = false
        Notify('Plate application cancelled.', 'error')
        return
    end

    TriggerServerEvent('mnc-customplate:server:applyPlate', plateText, themeId, adminMode, GetVehicleNumberPlateText(veh))
end

-- ============================================================
--  NUI Callbacks
-- ============================================================

RegisterNUICallback('closeUI', function(_, cb)
    isUIOpen  = false
    adminMode = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('applyPlate', function(data, cb)
    -- Release NUI focus immediately so the player doesn't have to press ESC
    isUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
    -- Now start the progress bar
    ApplyPlate(data.plate, data.theme)
end)

-- ============================================================
--  Server → Client events
-- ============================================================

RegisterNetEvent('mnc-customplate:client:plateApplied', function(plateText)
    isApplying = false
    local veh = GetClosestVehicle()
    if veh then
        SetVehicleNumberPlateText(veh, plateText)
    end
    Notify('Plate ' .. plateText .. ' applied successfully!', 'success')
end)

RegisterNetEvent('mnc-customplate:client:plateFailed', function(reason)
    isApplying = false
    Notify(reason, 'error')
end)

RegisterNetEvent('mnc-customplate:client:openUI', function(isAdmin)
    OpenUI(isAdmin)
end)

-- ============================================================
--  Admin command
-- ============================================================

if Config.AdminCommand then
    RegisterCommand(Config.AdminCommandName, function()
        TriggerServerEvent('mnc-customplate:server:adminCommand')
    end, false)

    TriggerEvent('chat:addSuggestion', '/' .. Config.AdminCommandName, 'Apply a custom plate to your vehicle (admin only)')
end