local QBCore = exports['qb-core']:GetCoreObject()

local hasClaimed = false
local hasHeardSound = false
local soundMarkSent = false
local uiOpen = false
local debugMode = false
local lastDebugPrint = 0

-- Run "/startercardebug" in chat to toggle a live readout in the F8 console
-- of your distance to the selector point and each vehicle spawn, and whether
-- a vehicle is actually detected at each one. If the distance never gets
-- small, you're not standing where config.lua thinks things are. If distance
-- gets small but "vehicle" stays false, the vehicle never spawned server-side.
RegisterCommand('startercardebug', function()
    debugMode = not debugMode
    print(('[mnc-startingcar] debug mode %s'):format(debugMode and 'ON' or 'OFF'))
end, false)

-- ============================================================
--  HELPERS
-- ============================================================

local function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    local camCoords = GetGameplayCamCoords()
    local dist = #(vector3(camCoords.x, camCoords.y, camCoords.z) - vector3(x, y, z))
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.35 * scale, 0.35 * scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(sx, sy)
end

local function RefreshClaimStatus(cb)
    QBCore.Functions.TriggerCallback('mnc-startingcar:server:hasClaimed', function(claimed)
        hasClaimed = claimed
        if cb then cb(claimed) end
    end)
end

local function RefreshSoundStatus(cb)
    QBCore.Functions.TriggerCallback('mnc-startingcar:server:hasHeardSound', function(heard)
        hasHeardSound = heard
        if cb then cb(heard) end
    end)
end

-- Returns the closest vehicle entity near a spot, or 0 if none is parked there.
-- Used to tell whether a slot currently has its showroom vehicle available
-- (it won't while a replacement is respawning after being claimed).
--
-- flags=70 is required here -- passing 0 matches no vehicle class at all, so
-- GetClosestVehicle would always return 0 ("nothing found") even with a car
-- sitting right on top of the coords. That was why every slot showed
-- "unavailable" in the UI even for players who hadn't claimed anything yet.
local function GetVehicleAtCoords(coords, radius)
    return GetClosestVehicle(coords.x, coords.y, coords.z, radius or 3.0, 0, 70)
end

-- ============================================================
--  BLIP -- one, at the selector point
-- ============================================================

CreateThread(function()
    if not Config.Blip.enabled then return end

    local blip = AddBlipForCoord(Config.SelectionPoint.x, Config.SelectionPoint.y, Config.SelectionPoint.z)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blip.label)
    EndTextCommandSetBlipName(blip)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    RefreshClaimStatus()
    RefreshSoundStatus()
end)

CreateThread(function()
    Wait(2000)
    RefreshClaimStatus()
    RefreshSoundStatus()
end)

-- ============================================================
--  MAIN LOOP: selector marker/prompt + debug readout
-- ============================================================

CreateThread(function()
    local selCoords = vector3(Config.SelectionPoint.x, Config.SelectionPoint.y, Config.SelectionPoint.z)

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)

        -- ---- Debug readout ("/startercardebug" to toggle) ----
        if debugMode and GetGameTimer() - lastDebugPrint > 1000 then
            lastDebugPrint = GetGameTimer()
            local selDist = #(pcoords - selCoords)
            print(('[mnc-startingcar debug] selector dist=%.1f hasClaimed=%s hasHeardSound=%s'):format(selDist, tostring(hasClaimed), tostring(hasHeardSound)))
            for i, spawn in ipairs(Config.VehicleSpawns) do
                local sCoords = vector3(spawn.coords.x, spawn.coords.y, spawn.coords.z)
                local dist = #(pcoords - sCoords)
                local veh = GetVehicleAtCoords(spawn.coords, 3.0)
                print(('[mnc-startingcar debug] slot %d (%s) dist=%.1f vehiclePresent=%s'):format(
                    i, spawn.label, dist, tostring(veh ~= 0)))
            end
            sleep = 0
        end

        -- ---- Selector marker + interact prompt ----
        local selDist = #(pcoords - selCoords)

        if selDist <= Config.MarkerDrawDistance then
            sleep = 0

            DrawMarker(
                Config.Marker.type,
                selCoords.x, selCoords.y, selCoords.z - 0.98,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                Config.Marker.size.x, Config.Marker.size.y, Config.Marker.size.z,
                Config.Marker.color.r, Config.Marker.color.g, Config.Marker.color.b, Config.Marker.color.a,
                Config.Marker.bobUpAndDown, Config.Marker.faceCamera, 2, Config.Marker.rotate, nil, nil, false
            )

            if not uiOpen and selDist <= Config.InteractionDistance then
                if hasClaimed then
                    DrawText3D(selCoords.x, selCoords.y, selCoords.z + 1.0, 'You have already claimed your starter vehicle')
                else
                    DrawText3D(selCoords.x, selCoords.y, selCoords.z + 1.0, 'Press [E] to browse starter vehicles')
                    if IsControlJustReleased(0, 38) then -- INPUT_PICKUP / E
                        OpenClaimUI()
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================
--  NUI
-- ============================================================

function OpenClaimUI()
    if uiOpen then return end

    RefreshClaimStatus(function(claimed)
        if claimed then
            QBCore.Functions.Notify('You have already claimed your starter vehicle', 'error')
            return
        end

        -- Plays once, ever, the first time this player opens the browser --
        -- latched immediately so it can never fire twice even if the server
        -- round-trip to persist it hasn't come back yet. Sent as part of the
        -- same 'open' NUI message that also grants NUI focus below, so the
        -- <audio> element in the NUI plays right away (FiveM's NUI is fine
        -- with audio starting as soon as focus is granted -- this is the
        -- same pattern inventories/phones use for their "open" sound).
        local introSound = nil
        if not hasHeardSound and not soundMarkSent then
            soundMarkSent = true
            hasHeardSound = true
            introSound = Config.SoundFile
            TriggerServerEvent('mnc-startingcar:server:markSoundPlayed')
        end

        local vehicles = {}
        for i, spawn in ipairs(Config.VehicleSpawns) do
            vehicles[#vehicles + 1] = {
                slot = i,
                label = spawn.label,
                model = spawn.model,
                available = GetVehicleAtCoords(spawn.coords, 3.0) ~= 0,
            }
        end

        uiOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            vehicles = vehicles,
            introSound = introSound,
            introVolume = Config.IntroSoundVolume,
        })
    end)
end

RegisterNUICallback('closeUI', function(_, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('confirmClaim', function(data, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    TriggerServerEvent('mnc-startingcar:server:claimVehicle', data)
    cb('ok')
end)

RegisterNetEvent('mnc-startingcar:client:claimSuccess', function(vehData)
    hasClaimed = true
    GiveClaimedVehicle(vehData)
end)

RegisterNetEvent('mnc-startingcar:client:claimFailed', function(reason)
    QBCore.Functions.Notify(reason or 'Unable to claim vehicle', 'error')
end)

-- Fired by /resetstartercar and /resetstartersound so an already-connected
-- client's cached flags update immediately, instead of only the database
-- row -- otherwise the old in-memory value sticks around (and nothing
-- appears to happen) until that player reconnects.
RegisterNetEvent('mnc-startingcar:client:claimReset', function()
    hasClaimed = false
end)

RegisterNetEvent('mnc-startingcar:client:soundReset', function()
    hasHeardSound = false
    soundMarkSent = false
end)

-- ============================================================
--  HAND OVER THE ALREADY-SPAWNED VEHICLE
-- ============================================================

function GiveClaimedVehicle(vehData)
    local veh = NetworkGetEntityFromNetworkId(vehData.netId)
    local timeout = 0
    while (not veh or veh == 0 or not DoesEntityExist(veh)) and timeout < 200 do
        Wait(10)
        veh = NetworkGetEntityFromNetworkId(vehData.netId)
        timeout = timeout + 1
    end

    if not veh or veh == 0 or not DoesEntityExist(veh) then
        QBCore.Functions.Notify('Could not locate your vehicle, please contact staff', 'error')
        return
    end

    NetworkRequestControlOfEntity(veh)
    local ctrlTimeout = 0
    while not NetworkHasControlOfEntity(veh) and ctrlTimeout < 50 do
        Wait(10)
        NetworkRequestControlOfEntity(veh)
        ctrlTimeout = ctrlTimeout + 1
    end

    -- Move the car to the configured delivery point (if set) instead of
    -- leaving it parked in the showroom slot, so the replacement vehicle
    -- that spawns back into that slot doesn't end up overlapping it.
    if Config.DeliveryPoint then
        SetEntityCoords(veh, Config.DeliveryPoint.x, Config.DeliveryPoint.y, Config.DeliveryPoint.z, false, false, false, false)
        SetEntityHeading(veh, Config.DeliveryPoint.w)
        SetVehicleOnGroundProperly(veh)
    end

    SetVehicleDoorsLocked(veh, 0)
    SetVehicleFuelLevel(veh, 100.0)

    if Config.FuelSystem == 'legacy' then
        Entity(veh).state:set('fuel', 100.0, true)
    end

    SetVehicleEngineOn(veh, true, true, false)

    if GetResourceState('qb-vehiclekeys') == 'started' then
        TriggerEvent('vehiclekeys:client:SetOwner', vehData.plate)
    end

    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, veh, -1)

    -- Plays exactly once -- triggered only by this one-time claim event --
    -- fired via NUI right as the player is spawned into the vehicle. The
    -- NUI document is still alive even though it's hidden/unfocused at this
    -- point (SetNuiFocus(false) only affects input routing, not whether the
    -- page can still receive postMessage or play audio).
    if vehData.sound then
        SendNUIMessage({ action = 'boughtSound', file = vehData.sound, volume = Config.VehicleSoundVolume })
    end

    QBCore.Functions.Notify(('Congratulations on your new %s! Keys and a full tank are ready to go.'):format(vehData.label), 'success')
end