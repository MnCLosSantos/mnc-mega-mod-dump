local Config = {
    -- Milliseconds to wait after spawning before checking.
    -- 300 ms is usually fine; raise to 600/1000 if models load slowly.
    SpawnDelay = 300,

    -- Spawn coords – somewhere flat and quiet. docks or lsia is ideal
    SpawnCoords = vector3(87.99, -2723.12, 6.0),

    -- Bones whose presence means "this vehicle can tow or be towed".
    TowBones = {
        'tow_arm',
        'tow_arm_l',
        'tow_arm_r',
        'attach_female',   -- hitch receiver
        'attach_male',     -- hitch ball
        'tow_bar',
        'hook',
        'hook_l',
        'hook_r',
    },
}

-- ── State ────────────────────────────────────────────────────
local isScanning  = false
local scanResults = {}
local spawnedVeh  = 0

-- ── Helpers ──────────────────────────────────────────────────

local function Notify(msg, msgType, duration)
    lib.notify({
        title       = '🔍 TowFinder',
        description = msg,
        type        = msgType or 'inform',
        duration    = duration or 4000,
        position    = 'top-right',
    })
end

local function DeleteSpawned()
    if spawnedVeh ~= 0 and DoesEntityExist(spawnedVeh) then
        DeleteVehicle(spawnedVeh)
        spawnedVeh = 0
    end
end

-- Load a model with a hard timeout (5 s).
local function LoadModel(hash)
    if not IsModelValid(hash) then return false end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(50)
        timeout = timeout + 1
        if timeout > 100 then return false end  -- 5 s
    end
    return true
end

-- Spawn a vehicle and wait until the entity exists (hard timeout 2 s).
local function SpawnAndWait(hash, x, y, z)
    local veh = CreateVehicle(hash, x, y, z, 0.0, false, true)
    local t   = 0
    while not DoesEntityExist(veh) do
        Wait(50)
        t = t + 1
        if t > 40 then return 0 end  -- 2 s
    end
    return veh
end

-- ── Core Detection ───────────────────────────────────────────
--
-- GetEntityBoneIndexByName returns -1 when a bone does NOT exist.
-- We iterate our list and return on the first hit so it's fast.
--
local function HasTowBone(veh)
    for _, boneName in ipairs(Config.TowBones) do
        if GetEntityBoneIndexByName(veh, boneName) ~= -1 then
            return true, boneName
        end
    end
    return false, nil
end

-- ── Scan ─────────────────────────────────────────────────────

local function RunScan(vehicleList)
    isScanning  = true
    scanResults = {}
    local total = #vehicleList
    local found = 0

    -- Move the player to the spawn zone
    local ped = PlayerPedId()
    SetEntityCoords(ped, Config.SpawnCoords.x, Config.SpawnCoords.y, Config.SpawnCoords.z, false, false, false, false)
    FreezeEntityPosition(ped, true)
    Wait(600)

    Notify(('Starting bone scan of %d vehicles…'):format(total), 'inform', 5000)

    -- Progress circle runs for the estimated duration.
    local estimatedMs = total * (Config.SpawnDelay + 150)
    CreateThread(function()
        lib.progressCircle({
            duration     = estimatedMs,
            label        = 'Scanning tow bones…',
            useWhileDead = false,
            canCancel    = false,
            disable      = { move = true, car = true, combat = true },
        })
    end)

    local sx = Config.SpawnCoords.x + 6.0
    local sy = Config.SpawnCoords.y
    local sz = Config.SpawnCoords.z

    for i, entry in ipairs(vehicleList) do
        if not isScanning then
            Notify('Scan cancelled.', 'error')
            break
        end

        local modelName = entry.model
        local hash      = GetHashKey(modelName)

        -- Notify every 15 vehicles so the screen isn't spammed
        if i == 1 or i % 15 == 0 then
            Notify(('Scanning %d / %d  |  Found: %d'):format(i, total, found), 'inform', 3500)
        end

        if LoadModel(hash) then
            spawnedVeh = SpawnAndWait(hash, sx, sy, sz)

            if spawnedVeh ~= 0 then
                Wait(Config.SpawnDelay)

                local hasTow, boneName = HasTowBone(spawnedVeh)
                if hasTow then
                    found = found + 1
                    table.insert(scanResults, {
                        model = modelName,
                        name  = entry.name,
                        bone  = boneName,
                    })
                end

                DeleteSpawned()
            end

            SetModelAsNoLongerNeeded(hash)
        end

        Wait(30)
    end

    FreezeEntityPosition(ped, false)
    isScanning = false
    DeleteSpawned()

    if #scanResults > 0 then
        Notify(('Scan complete! %d tow-capable vehicles found. Saving…'):format(#scanResults), 'success', 7000)
        TriggerServerEvent('mnc-towfinder:server:SaveResults', scanResults)
    else
        Notify('Scan complete – no tow-capable vehicles found.', 'warning', 6000)
    end

    ShowResultsMenu(scanResults)
end

-- ── Results Menu ─────────────────────────────────────────────

function ShowResultsMenu(results)
    if #results == 0 then return end

    -- Group by bone for the menu too
    local groups = {}
    local order  = {}
    for _, entry in ipairs(results) do
        local bone = entry.bone or 'unknown'
        if not groups[bone] then
            groups[bone] = {}
            table.insert(order, bone)
        end
        table.insert(groups[bone], entry)
    end
    table.sort(order)

    local options = {
        {
            label    = ('✅  %d tow-capable vehicles found'):format(#results),
            disabled = true,
        },
    }

    for _, bone in ipairs(order) do
        local entries = groups[bone]

        -- Bone group header
        table.insert(options, {
            label    = ('── Bone: %s  (%d)'):format(bone, #entries),
            disabled = true,
        })

        for _, entry in ipairs(entries) do
            table.insert(options, {
                label       = entry.name,
                description = ('model: %s  |  bone: %s'):format(entry.model, entry.bone),
                icon        = 'truck',
            })
        end
    end

    lib.registerContext({
        id      = 'mnc_towfinder_results',
        title   = '🔍 TowFinder Results',
        options = options,
    })

    lib.showContext('mnc_towfinder_results')
end

-- ── Start Menu ───────────────────────────────────────────────

local function ShowStartMenu(vehicleList)
    lib.registerContext({
        id    = 'mnc_towfinder_start',
        title = '🔍 MNC TowFinder',
        options = {
            {
                label       = 'Start Bone Scan',
                description = ('Scan %d qb-core vehicles for tow bones'):format(#vehicleList),
                icon        = 'play',
                onSelect    = function()
                    if isScanning then
                        Notify('A scan is already running!', 'error')
                        return
                    end
                    CreateThread(function()
                        RunScan(vehicleList)
                    end)
                end,
            },
            {
                label       = 'Detection method: skeleton bones',
                description = 'Checks tow_arm, attach_female, hook, and related bones',
                icon        = 'bone',
                disabled    = true,
            },
            {
                label    = 'Cancel',
                icon     = 'xmark',
                onSelect = function() end,
            },
        },
    })

    lib.showContext('mnc_towfinder_start')
end

-- ── Net Events ───────────────────────────────────────────────

RegisterNetEvent('mnc-towfinder:client:ReceiveVehicles', function(vehicleList)
    if not vehicleList or #vehicleList == 0 then
        Notify('No vehicles received from server!', 'error')
        return
    end
    Notify(('Loaded %d vehicles – ready to scan.'):format(#vehicleList), 'success', 3000)
    ShowStartMenu(vehicleList)
end)

-- Fired by the server when a non-admin tries to use the command
RegisterNetEvent('mnc-towfinder:client:AccessDenied', function()
    Notify('You do not have permission to use TowFinder.', 'error', 5000)
end)

RegisterNetEvent('mnc-towfinder:client:SaveDone', function(count, success)
    if success then
        Notify(('%d vehicles written to output/tow_vehicles.lua'):format(count), 'success', 8000)
    else
        Notify('File write failed – results dumped to server console.', 'warning', 8000)
    end
end)

-- ── Commands ─────────────────────────────────────────────────
-- Access control is enforced server-side; any player can type the
-- command but non-admins receive an 'AccessDenied' event back.

RegisterCommand('towfinder', function()
    if isScanning then
        Notify('A scan is already in progress!', 'error')
        return
    end
    Notify('Requesting vehicle list…', 'inform', 3000)
    TriggerServerEvent('mnc-towfinder:server:RequestVehicles')
end, false)

RegisterCommand('mnc-towfinder', function()
    ExecuteCommand('towfinder')
end, false)

-- ── Cleanup ───────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    isScanning = false
    DeleteSpawned()
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
    end
end)