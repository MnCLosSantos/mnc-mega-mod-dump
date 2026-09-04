local QBCore = exports['qb-core']:GetCoreObject()

local Locations = {}
local startBlips = {}     -- startBlips[locKey] = blip handle
local StockEntities = {}  -- StockEntities[locKey][slotIndex] = { netId, model, entityRequested }
local StockKnown = {}     -- StockKnown[locKey][slotIndex] = { slotIndex, model, label, source } (from server, may be unspawned)

local menuOpen = false
local menuLocKey = nil
local activeRace = nil -- { locKey, raceType, slotIndex, finish, radius, timeLimit, startTime, vehicle }
local finishBlip = nil

local outlinedEntity = nil -- the stock vehicle currently highlighted while its menu row is hovered
local outlinedNetId = nil

local function ClearStockOutline()
    if outlinedEntity and DoesEntityExist(outlinedEntity) then
        SetEntityDrawOutline(outlinedEntity, false)
    end
    outlinedEntity = nil
    outlinedNetId = nil
end

local function SetStockOutline(netId)
    if outlinedNetId == netId then return end -- already showing this one (or already cleared)
    ClearStockOutline()
    if not netId then return end

    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent ~= 0 and DoesEntityExist(ent) then
        SetEntityDrawOutlineColor(255, 215, 0, 255) -- gold - reads as "this is the prize"
        SetEntityDrawOutline(ent, true)
        outlinedEntity = ent
        outlinedNetId = netId
    end
end

-- ===================================================================
-- LOCATIONS / BLIPS
-- ===================================================================
local function RefreshBlips()
    local seen = {}
    for _, loc in ipairs(Locations) do
        -- blip sits on show spot 1 (the lot's display spawn point) - not the race start line -
        -- since that's the spot players actually walk/drive up to to open the menu
        local showSpot = loc.spawns and loc.spawns[1]
        if not loc.disabled and showSpot then
            seen[loc.key] = true
            if not startBlips[loc.key] then
                local blip = AddBlipForCoord(showSpot.x, showSpot.y, showSpot.z)
                SetBlipSprite(blip, Config.Blips.Start.sprite)
                SetBlipColour(blip, Config.Blips.Start.color)
                SetBlipScale(blip, Config.Blips.Start.scale)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(loc.label or Config.Blips.Start.label)
                EndTextCommandSetBlipName(blip)
                startBlips[loc.key] = blip
            end
        end
    end

    for key, blip in pairs(startBlips) do
        if not seen[key] then
            RemoveBlip(blip)
            startBlips[key] = nil
        end
    end
end

local function IndexStock(locKey, list)
    StockKnown[locKey] = {}
    for _, item in ipairs(list or {}) do
        StockKnown[locKey][item.slotIndex] = item
    end
end

RegisterNetEvent('mnc-pinkslips:client:setLocations', function(list, stockMap)
    Locations = list or {}
    for key, stockList in pairs(stockMap or {}) do
        IndexStock(key, stockList)
    end
    RefreshBlips()
    SendNUIMessage({ action = 'setupLocations', locations = Locations }) -- keeps an open builder panel's list live
    if menuOpen and menuLocKey then
        SendNUIMessage({ action = 'updateStock', stock = StockKnown[menuLocKey] and (function()
            local out = {}
            for _, v in pairs(StockKnown[menuLocKey]) do out[#out + 1] = v end
            table.sort(out, function(a, b) return a.slotIndex < b.slotIndex end)
            return out
        end)() or {} })
    end
end)

RegisterNetEvent('mnc-pinkslips:client:setStock', function(locKey, list)
    IndexStock(locKey, list)
    if menuOpen and menuLocKey == locKey then
        SendNUIMessage({ action = 'updateStock', stock = list })
    end
end)

CreateThread(function()
    TriggerServerEvent('mnc-pinkslips:server:requestLocations')
end)

-- ===================================================================
-- STOCK VEHICLE STREAMING  (distance based, mirrors mnc-cardelivery)
-- ===================================================================
CreateThread(function()
    while true do
        Wait(Config.Streaming.CheckInterval)
        local coords = GetEntityCoords(PlayerPedId())

        for _, loc in ipairs(Locations) do
            if not loc.disabled then
                StockEntities[loc.key] = StockEntities[loc.key] or {}
                for i, spawnPoint in ipairs(loc.spawns) do
                    local dist = #(coords - vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z))
                    local hasModel = StockKnown[loc.key] and StockKnown[loc.key][i] ~= nil
                    local known = StockEntities[loc.key][i]

                    if hasModel and not known and dist <= Config.Streaming.SpawnDistance then
                        StockEntities[loc.key][i] = { requested = true }
                        TriggerServerEvent('mnc-pinkslips:server:requestStockSpawn', loc.key, i)
                    elseif known and dist >= Config.Streaming.DespawnDistance then
                        StockEntities[loc.key][i] = nil
                        TriggerServerEvent('mnc-pinkslips:server:requestStockDespawn', loc.key, i)
                    end
                end
            end
        end
    end
end)

local function WaitForNetworkEntity(netId)
    local attempts = 0
    while not NetworkDoesEntityExistWithNetworkId(netId) and attempts < 100 do
        Wait(100)
        attempts = attempts + 1
    end
    if not NetworkDoesEntityExistWithNetworkId(netId) then return 0 end

    local veh = NetworkGetEntityFromNetworkId(netId)
    local waitTicks = 0
    while not DoesEntityExist(veh) and waitTicks < 50 do
        Wait(100)
        waitTicks = waitTicks + 1
        veh = NetworkGetEntityFromNetworkId(netId)
    end
    return DoesEntityExist(veh) and veh or 0
end

RegisterNetEvent('mnc-pinkslips:client:stockSpawned', function(locKey, slotIndex, netId, model)
    StockEntities[locKey] = StockEntities[locKey] or {}
    StockEntities[locKey][slotIndex] = { netId = netId, model = model }

    -- SET_ENTITY_INVINCIBLE is client-only (the server can't call it - that's what was
    -- erroring and, since that error aborted the rest of the server handler, was also why
    -- lot vehicles never got their mods). Every client that streams this vehicle in applies
    -- it locally so it stays protected regardless of who currently owns it on the network.
    CreateThread(function()
        local veh = WaitForNetworkEntity(netId)
        if veh ~= 0 then
            SetEntityInvincible(veh, true)
        end
    end)
end)

RegisterNetEvent('mnc-pinkslips:client:stockDespawned', function(locKey, slotIndex)
    if StockEntities[locKey] then
        StockEntities[locKey][slotIndex] = nil
    end
end)

-- Fully built lot car: every performance bar (Engine/Brakes/Transmission/Suspension) plus Armour
-- is always maxed out on every car of a given model - race fairness means which car you get
-- shouldn't matter, only how you drive it. Everything else varies per car instead: which specific
-- part is installed in each of the 11 cosmetic body-kit slots (Spoiler, Bumpers, Skirt, Exhaust,
-- Frame, Grille, Hood, Fenders, Roof - always SOME aftermarket part, never reverted to bare stock,
-- just not always the same one), plus paint colour and window tint. The server hands down the
-- colour/tint combo to use, and a list of what every other config-sourced show vehicle of the same
-- model at this location already looks like (see mnc-pinkslips:client:seedStockProps below) -
-- colours are picked and reserved server-side (server.lua GenerateDistinctLotColors) so they're
-- guaranteed distinct; cosmetic mod counts are model-specific and only queryable client-side
-- (GetNumVehicleMods), so those are rolled here and rerolled if they'd exactly match a sibling
-- (see ApplyVariedCosmeticMods). If nothing is provided (shouldn't normally happen), this falls
-- back to plain random so a car still gets a full set of mods and a colour.
-- IMPORTANT: this only ever runs on stock that has never been raced for (source = 'config',
-- see the seedStockProps handler below). A vehicle a player lost stays on the exact props
-- captured at the moment they lost it (see applyStockProps / FailRace) and never touches this -
-- it stays exactly how they lost it.
local PERFORMANCE_MOD_TYPES = { 11, 12, 13, 15, 16 } -- Engine, Brakes, Transmission, Suspension, Armour
local COSMETIC_MOD_TYPES = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 } -- Spoiler, Bumpers, Skirt, Exhaust, Frame, Grille, Hood, Fenders, Roof
local COSMETIC_REROLL_ATTEMPTS = 12 -- how many times to reroll cosmetics before just accepting a match (space is large - shouldn't realistically be hit)

local function MaxOutMods(vehicle, modTypes)
    for _, modType in ipairs(modTypes) do
        local count = GetNumVehicleMods(vehicle, modType)
        if count > 0 then SetVehicleMod(vehicle, modType, count - 1, false) end
    end
end

local function RollCosmeticIndices(vehicle)
    local indices = {}
    for _, modType in ipairs(COSMETIC_MOD_TYPES) do
        local count = GetNumVehicleMods(vehicle, modType)
        indices[modType] = count > 0 and math.random(0, count - 1) or -1
    end
    return indices
end

local function CosmeticIndicesMatch(a, b)
    for _, modType in ipairs(COSMETIC_MOD_TYPES) do
        if (a[modType] or -1) ~= (b[modType] or -1) then return false end
    end
    return true
end

-- rolls one specific part per cosmetic slot (never -1/bare stock, so the car still looks built),
-- rerolling the whole set if it exactly matches something in avoidSignatures - the cosmetic
-- signatures of every other config-sourced same-model car already on this lot (server.lua
-- CollectCosmeticAvoidList)
local function ApplyVariedCosmeticMods(vehicle, avoidSignatures)
    local indices = RollCosmeticIndices(vehicle)
    if avoidSignatures and #avoidSignatures > 0 then
        for _ = 1, COSMETIC_REROLL_ATTEMPTS do
            local collides = false
            for _, avoid in ipairs(avoidSignatures) do
                if CosmeticIndicesMatch(indices, avoid) then
                    collides = true
                    break
                end
            end
            if not collides then break end
            indices = RollCosmeticIndices(vehicle)
        end
    end
    for _, modType in ipairs(COSMETIC_MOD_TYPES) do
        local idx = indices[modType]
        if idx >= 0 then SetVehicleMod(vehicle, modType, idx, false) end
    end
end

local function ApplyRandomLotMods(vehicle, colors, cosmeticAvoid)
    if not DoesEntityExist(vehicle) then return end
    SetVehicleModKit(vehicle, 0)
    MaxOutMods(vehicle, PERFORMANCE_MOD_TYPES)
    ApplyVariedCosmeticMods(vehicle, cosmeticAvoid)
    ToggleVehicleMod(vehicle, 18, true) -- turbo
    local color1 = (colors and colors.color1) or math.random(0, 159)
    local color2 = (colors and colors.color2) or math.random(0, 159)
    local windowTint = (colors and colors.windowTint) or math.random(0, 6)
    SetVehicleColours(vehicle, color1, color2)
    SetVehicleWindowTint(vehicle, windowTint)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleFixed(vehicle)
end

RegisterNetEvent('mnc-pinkslips:client:seedStockProps', function(locKey, slotIndex, netId, colors, cosmeticAvoid)
    CreateThread(function()
        local veh = WaitForNetworkEntity(netId)
        if veh == 0 then return end
        ApplyRandomLotMods(veh, colors, cosmeticAvoid)
        Wait(500) -- give the mod natives a beat to settle before reading them back
        local ok, props = pcall(QBCore.Functions.GetVehicleProperties, veh)
        if ok and props then
            TriggerServerEvent('mnc-pinkslips:server:capturedInitialProps', locKey, slotIndex, props)
        else
            -- shouldn't happen, but if it does the slot is left with no props forever unless
            -- something triggers this again - print so it shows up if a winner ends up un-modded
            print(('[mnc-pinkslips] Could not capture properties for %s slot %d after seeding mods (ok=%s)'):format(locKey, slotIndex, tostring(ok)))
        end
    end)
end)

RegisterNetEvent('mnc-pinkslips:client:applyStockProps', function(netId, props)
    CreateThread(function()
        local veh = WaitForNetworkEntity(netId)
        if veh ~= 0 then
            pcall(QBCore.Functions.SetVehicleProperties, veh, props)
        end
    end)
end)

-- ===================================================================
-- MENU  (interact prompt -> race picker)
-- ===================================================================
local function ShowInteractHelp(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function OpenMenu(locKey)
    if menuOpen or activeRace then return end
    menuOpen = true
    menuLocKey = locKey

    QBCore.Functions.TriggerCallback('mnc-pinkslips:server:getMenuData', function(data)
        if not data then
            menuOpen = false
            menuLocKey = nil
            return
        end
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'playSound', category = 'prompt', index = math.random(1, Config.Sounds.PromptCount) })
        SendNUIMessage({ action = 'openMenu', data = data })
    end, locKey)
end

RegisterNUICallback('menuClose', function(_, cb)
    SetNuiFocus(false, false)
    menuOpen = false
    menuLocKey = nil
    ClearStockOutline()
    cb('ok')
end)

-- mouseenter/mouseleave on a stock list row in the NUI -> outline (or clear) the matching
-- parked vehicle in-world so it's obvious which car you'd be racing for
RegisterNUICallback('menuHoverStock', function(data, cb)
    local slotIndex = data and data.slotIndex
    local stock = (slotIndex and menuLocKey) and StockEntities[menuLocKey] and StockEntities[menuLocKey][slotIndex]
    SetStockOutline(stock and stock.netId or nil)
    cb('ok')
end)

CreateThread(function()
    while true do
        local sleep = 750
        if not activeRace and not menuOpen then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if GetPedInVehicleSeat(veh, -1) == ped then
                    local coords = GetEntityCoords(ped)
                    for _, loc in ipairs(Locations) do
                        -- prompt is anchored to show spot 1 too - matches the blip, and is where
                        -- players are actually stood/parked when they'd want to open the menu
                        local showSpot = loc.spawns and loc.spawns[1]
                        if not loc.disabled and showSpot then
                            local dist = #(coords - vector3(showSpot.x, showSpot.y, showSpot.z))
                            if dist <= Config.PromptDistance then
                                sleep = 0
                                ShowInteractHelp(('Press ~INPUT_CONTEXT~ to open %s'):format(loc.label or 'Pinkslips'))
                                if IsControlJustPressed(0, 38) then -- INPUT_CONTEXT (E)
                                    OpenMenu(loc.key)
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ===================================================================
-- RACE
-- ===================================================================
local function CleanupRace()
    if finishBlip then
        RemoveBlip(finishBlip)
        finishBlip = nil
    end
    SendNUIMessage({ action = 'hideRaceHUD' })
    activeRace = nil
end

local function FailRace(reason)
    local race = activeRace
    if not race then return end

    local props = nil
    if race.raceType == 'pinkslip' and DoesEntityExist(race.vehicle) then
        local ok, p = pcall(QBCore.Functions.GetVehicleProperties, race.vehicle)
        if ok then props = p end
    end

    CleanupRace()
    TriggerServerEvent('mnc-pinkslips:server:failRace', props)
end

local function SucceedRace()
    local race = activeRace
    if not race then return end

    local elapsed = (GetGameTimer() - race.startTime) / 1000
    CleanupRace()
    TriggerServerEvent('mnc-pinkslips:server:completeRace', elapsed)
end

local function RaceCountdown(vehicle)
    local ped = PlayerPedId()
    local canFreeze = DoesEntityExist(vehicle)
    if canFreeze then FreezeEntityPosition(vehicle, true) end -- hold exactly on the line while the clock counts down

    SendNUIMessage({ action = 'playSound', category = 'countdown' }) -- one clip covers the whole 3-2-1 - play it once here, not per-number

    local tickMs = Config.RaceCountdownTickMs or 1000
    for i = Config.RaceCountdown, 1, -1 do
        local t = 0
        while t < tickMs do
            DisableControlAction(0, 71, true) -- accel
            DisableControlAction(0, 72, true) -- brake/reverse
            DisableControlAction(0, 59, true) -- steer LR
            DisableControlAction(0, 63, true) -- steer LR (alt)
            DisableControlAction(0, 64, true) -- steer LR (alt)
            SendNUIMessage({ action = 'raceCountdown', value = tostring(i) })
            Wait(0)
            t = t + (GetFrameTime() * 1000)
        end
    end

    if canFreeze then FreezeEntityPosition(vehicle, false) end
    SendNUIMessage({ action = 'raceCountdown', value = 'GO!' })
    SendNUIMessage({ action = 'playSound', category = 'go' })
    Wait(Config.RaceCountdownGoHoldMs or 600)
    SendNUIMessage({ action = 'raceCountdown', value = nil })
end

-- Test the countdown's audio/visual timing without needing a real race - tweak
-- Config.RaceCountdownTickMs / Config.RaceCountdownGoHoldMs and re-run this to dial it in
-- against however long html/sounds/countdown.mp3 actually runs.
RegisterCommand('pinkslips_testcountdown', function()
    if activeRace then return end -- don't stomp a real countdown/race in progress
    CreateThread(function()
        RaceCountdown(0) -- 0 = no vehicle to freeze, this is audio/visual only
    end)
end, false)

-- Every race starts from that location's exact, configured start point/heading - not wherever
-- the player happened to be standing (within the interact prompt's radius) when they opened
-- the menu. The vehicle carries the seated ped with it, so warping the vehicle is enough.
local function WarpToRaceStart(loc, vehicle)
    if not loc or not loc.start or not DoesEntityExist(vehicle) then return end
    local s = loc.start
    SetEntityVelocity(vehicle, 0.0, 0.0, 0.0)
    SetEntityAngularVelocity(vehicle, 0.0, 0.0, 0.0)
    SetEntityCoords(vehicle, s.x, s.y, s.z, false, false, false, false)
    SetEntityHeading(vehicle, s.w)
    SetVehicleOnGroundProperly(vehicle)
end

local function StartRace(locKey, result)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeMenu' })
    menuOpen = false
    menuLocKey = nil
    ClearStockOutline() -- don't leave the lot car glowing behind while the player drives off

    local loc = nil
    for _, l in ipairs(Locations) do
        if l.key == locKey then loc = l break end
    end

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    WarpToRaceStart(loc, vehicle)

    finishBlip = AddBlipForCoord(result.finish.x, result.finish.y, result.finish.z)
    SetBlipSprite(finishBlip, Config.Blips.Finish.sprite)
    SetBlipColour(finishBlip, Config.Blips.Finish.color)
    SetBlipScale(finishBlip, Config.Blips.Finish.scale)
    SetBlipAsShortRange(finishBlip, false)
    SetBlipRoute(finishBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blips.Finish.label)
    EndTextCommandSetBlipName(finishBlip)

    SendNUIMessage({
        action = 'showRaceHUD',
        raceType = result.raceType,
        stakeLabel = result.stakeLabel,
        timeLimit = result.timeLimit,
    })

    lib.notify({
        title = result.raceType == 'pinkslip' and 'Pinkslip Race' or 'Pot Race',
        description = ('Beat the clock to the finish. Racing for: %s'):format(result.stakeLabel),
        type = 'inform',
        duration = 6000,
    })

    activeRace = {
        locKey = locKey,
        raceType = result.raceType,
        slotIndex = result.slotIndex,
        finish = result.finish,
        radius = result.radius,
        timeLimit = result.timeLimit,
        vehicle = vehicle,
    }

    RaceCountdown(vehicle)

    -- countdown may have taken a moment; only actually start the clock now
    if not activeRace then return end
    activeRace.startTime = GetGameTimer()

    CreateThread(function()
        while activeRace and activeRace.locKey == locKey do
            Wait(200)
            local race = activeRace
            if not race then break end

            if not DoesEntityExist(race.vehicle) then
                FailRace('vehicle_lost')
                break
            end

            local vPed = PlayerPedId()
            if GetVehiclePedIsIn(vPed, false) ~= race.vehicle or GetPedInVehicleSeat(race.vehicle, -1) ~= vPed then
                FailRace('left_vehicle')
                break
            end

            local elapsed = (GetGameTimer() - race.startTime) / 1000
            local remaining = race.timeLimit - elapsed

            SendNUIMessage({ action = 'updateRaceHUD', timeRemaining = math.max(0, remaining) })

            if remaining <= 0 then
                FailRace('time_expired')
                break
            end

            local pCoords = GetEntityCoords(race.vehicle)
            local dist = #(pCoords - vector3(race.finish.x, race.finish.y, race.finish.z))
            if dist <= race.radius then
                SucceedRace()
                break
            end
        end
    end)
end

RegisterNUICallback('menuStartRace', function(data, cb)
    local locKey = menuLocKey
    if not locKey then cb('ok') return end

    QBCore.Functions.TriggerCallback('mnc-pinkslips:server:claimRace', function(result)
        if result and result.success then
            SetNuiFocus(false, false)
            StartRace(locKey, result)
        else
            local reasons = {
                already_racing   = 'You are already in a race.',
                invalid_location = 'That location is not available.',
                not_driving      = 'You need to be driving the vehicle you want to race.',
                not_owned        = 'You need to be driving a vehicle you own.',
                wrong_class      = 'That vehicle is the wrong class for this location.',
                no_slip_unlocked = "You haven't unlocked a pinkslip attempt here yet.",
                no_car           = 'That car is no longer available.',
                car_not_ready    = "That car is still getting set up - give it a couple of seconds and try again.",
                no_money         = "You can't afford that buy-in.",
                bad_type         = 'Something went wrong with that request.',
            }
            lib.notify({
                title = 'Pinkslips',
                description = (result and reasons[result.reason]) or 'Could not start that race.',
                type = 'error',
            })
        end
        cb('ok')
    end, locKey, data.raceType, data.slotIndex)
end)

RegisterNetEvent('mnc-pinkslips:client:raceResult', function(success, raceType, payout, vehicleLabel, unlocked)
    if success then
        SendNUIMessage({ action = 'playSound', category = 'win', index = math.random(1, Config.Sounds.WinCount) })
        if raceType == 'pinkslip' then
            local desc = vehicleLabel
                and ('You won $%d and the %s! It has been sent to Pillbox Garage.'):format(payout, vehicleLabel)
                or ('You won $%d! (the vehicle transfer failed - check the server console)'):format(payout)
            lib.notify({ title = 'Pinkslip Won', description = desc, type = 'success', duration = 9000 })
        else
            lib.notify({ title = 'Pot Race Won', description = ('You won $%d.'):format(payout), type = 'success' })
        end
    else
        SendNUIMessage({ action = 'playSound', category = 'lose', index = math.random(1, Config.Sounds.LoseCount) })
        if raceType == 'pinkslip' then
            lib.notify({ title = 'Pinkslip Lost', description = 'You lost the race - and your car.', type = 'error', duration = 8000 })
        else
            lib.notify({ title = 'Pot Race Lost', description = 'You lost the race and your buy-in.', type = 'error' })
        end
    end

    if unlocked then
        CreateThread(function()
            Wait(1200)
            SendNUIMessage({ action = 'playSound', category = 'unlock', index = math.random(1, Config.Sounds.UnlockCount) })
            lib.notify({ title = 'Pinkslips', description = 'A new pinkslip attempt has unlocked at this location!', type = 'success', duration = 8000 })
        end)
    end
end)

RegisterNetEvent('mnc-pinkslips:client:forfeitVehicle', function(plate)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end

    local vplate = (GetVehicleNumberPlateText(veh) or ''):gsub('%s+$', '')
    if vplate ~= plate then return end

    TaskLeaveVehicle(ped, veh, 0)
    CreateThread(function()
        local t = 0
        while IsPedInVehicle(ped, veh, false) and t < 3000 do
            Wait(100)
            t = t + 100
        end
        if DoesEntityExist(veh) then
            SetEntityAsMissionEntity(veh, true, true)
            DeleteEntity(veh)
        end
    end)
end)

RegisterKeyMapping('pinkslips_forfeit', 'Pinkslips: forfeit current race', 'keyboard', 'BACK')
RegisterCommand('pinkslips_forfeit', function()
    if activeRace then
        FailRace('manual_forfeit')
    end
end, false)

-- ===================================================================
-- ADMIN: LOCATION BUILDER  (/setuppinkslips) - mirrors mnc-cardelivery's route builder
-- ===================================================================

-- Builds the "Vehicle class" dropdown options and the "Browse Vehicles" picker's grid, straight
-- from QBCore.Shared.Vehicles - so both always match whatever's actually spawnable/ownable on
-- this server (server-added addon vehicles included) instead of drifting from a hand-maintained
-- config list. Rebuilt fresh every time the builder is opened (admin-only, opened rarely) rather
-- than cached, so a vehicles.lua change on this server is picked up without a resource restart.
local function BuildVehicleCatalog()
    local byClass, classSeen, classes = {}, {}, {}

    for model, data in pairs(QBCore.Shared.Vehicles) do
        local class = data.category or 'other'
        if not classSeen[class] then
            classSeen[class] = true
            classes[#classes + 1] = class
        end
        byClass[class] = byClass[class] or {}
        byClass[class][#byClass[class] + 1] = { model = model, label = data.name or model }
    end

    table.sort(classes)
    for _, list in pairs(byClass) do
        table.sort(list, function(a, b) return a.label:lower() < b.label:lower() end)
    end

    return classes, byClass
end

RegisterNetEvent('mnc-pinkslips:client:openSetupUI', function()
    SetNuiFocus(true, true)
    local classes, byClass = BuildVehicleCatalog()
    SendNUIMessage({
        action           = 'openSetup',
        locations        = Locations,
        minSpawnPoints   = Config.Admin.MinSpawnPoints,
        vehicleClasses   = classes,
        vehiclesByClass  = byClass,
        imageSources     = Config.VehicleImageSources,
        imageSourceOrder = Config.VehicleImageSourceOrder,
    })
end)

RegisterNUICallback('setupUseMyPosition', function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    cb({ x = coords.x, y = coords.y, z = coords.z, w = heading })
end)

RegisterNUICallback('setupSaveLocation', function(data, cb)
    TriggerServerEvent('mnc-pinkslips:server:saveLocation', data)
    cb('ok')
end)

RegisterNUICallback('setupDeleteLocation', function(data, cb)
    TriggerServerEvent('mnc-pinkslips:server:deleteLocation', { dbId = data.dbId, configIndex = data.configIndex })
    cb('ok')
end)

RegisterNUICallback('setupClose', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ---------------------------------------------------------------------
-- Test drive: drive start -> finish once, buffered time becomes the time limit
-- ---------------------------------------------------------------------
local testDrive = nil

local function ParseVehiclesCsvClient(raw)
    local vehicles = {}
    for v in (raw or ''):gmatch('([^,]+)') do
        local trimmed = v:match('^%s*(.-)%s*$')
        if trimmed ~= '' then vehicles[#vehicles + 1] = trimmed end
    end
    return vehicles
end

local function EndTestDrive(cancelled)
    local td = testDrive
    if not td then return end
    testDrive = nil

    if td.blip then RemoveBlip(td.blip) end

    local ped = PlayerPedId()
    if DoesEntityExist(td.vehicle) then
        DeleteEntity(td.vehicle)
    end
    SetEntityCoords(ped, td.originalCoords.x, td.originalCoords.y, td.originalCoords.z, false, false, false, false)
    SetEntityHeading(ped, td.originalHeading)

    SendNUIMessage({ action = 'testDriveHide' })
    SetNuiFocus(true, true)

    local result = nil
    if cancelled then
        lib.notify({ title = 'Test Drive', description = 'Cancelled.', type = 'error' })
    else
        local elapsed = (GetGameTimer() - td.startTime) / 1000
        local rtc = Config.Admin.RouteTimer
        local buffered = elapsed * (1 + ((rtc.BufferPercent or 0) / 100))
        buffered = math.max(rtc.MinTime or 1, buffered)
        local roundTo = rtc.RoundTo or 1
        if roundTo > 0 then
            buffered = math.floor((buffered / roundTo) + 0.5) * roundTo
        end

        result = { timeLimit = math.floor(buffered), rawElapsed = math.floor(elapsed) }

        lib.notify({
            title = 'Test Drive',
            description = ('Drive time %ds -> time limit set to %ds.'):format(result.rawElapsed, result.timeLimit),
            type = 'success',
        })
    end

    SendNUIMessage({ action = 'testDriveDone', cancelled = cancelled, result = result })
end

RegisterNUICallback('setupStartTestDrive', function(data, cb)
    if testDrive then cb('ok') return end

    local start, finish = data and data.start, data and data.finish
    local radius = tonumber(data and data.radius)
    local vehicles = ParseVehiclesCsvClient(data and data.vehicles)

    local valid = type(start) == 'table' and type(finish) == 'table'
        and tonumber(start.x) and tonumber(start.y) and tonumber(start.z) and tonumber(start.w)
        and tonumber(finish.x) and tonumber(finish.y) and tonumber(finish.z)
        and radius and radius > 0 and #vehicles > 0

    if not valid then
        lib.notify({ title = 'Test Drive', description = 'Fill in start, finish, radius and at least one vehicle first.', type = 'error' })
        cb('ok')
        return
    end

    local model = vehicles[math.random(#vehicles)]
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 100 do
        Wait(50)
        attempts = attempts + 1
    end
    if not HasModelLoaded(modelHash) then
        lib.notify({ title = 'Test Drive', description = ("Couldn't load vehicle model '%s' - check the spawn name."):format(model), type = 'error' })
        cb('ok')
        return
    end

    local ped = PlayerPedId()
    local originalCoords = GetEntityCoords(ped)
    local originalHeading = GetEntityHeading(ped)

    local sx, sy, sz, sw = tonumber(start.x), tonumber(start.y), tonumber(start.z), tonumber(start.w)
    local fx, fy, fz = tonumber(finish.x), tonumber(finish.y), tonumber(finish.z)

    local vehicle = CreateVehicle(modelHash, sx, sy, sz, sw, false, false)
    SetModelAsNoLongerNeeded(modelHash)
    ApplyRandomLotMods(vehicle)
    SetVehicleOnGroundProperly(vehicle)

    -- a freshly CreateVehicle'd car has no owner as far as the keys resource is concerned, so
    -- without this the admin gets locked out of their own test-drive vehicle (no ignition) and
    -- can never actually drive it to set the time. Granted locally (no server round trip needed
    -- since it's the same client) via the same event server.lua hands a real pinkslip winner's
    -- keys through (see completeRace) - if your qb-vehiclekeys fork listens for a different
    -- event/export, swap this line to match.
    TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(vehicle))

    SetEntityCoords(ped, sx, sy, sz, false, false, false, false)
    SetPedIntoVehicle(ped, vehicle, -1)

    SetNuiFocus(false, false)

    local blip = AddBlipForCoord(fx, fy, fz)
    SetBlipSprite(blip, Config.Blips.Finish.sprite)
    SetBlipColour(blip, Config.Blips.Finish.color)
    SetBlipScale(blip, Config.Blips.Finish.scale)
    SetBlipAsShortRange(blip, false)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Test Drive Finish')
    EndTextCommandSetBlipName(blip)

    testDrive = {
        vehicle = vehicle,
        blip = blip,
        radius = radius,
        dropCoords = vector3(fx, fy, fz),
        startTime = GetGameTimer(),
        originalCoords = originalCoords,
        originalHeading = originalHeading,
    }

    SendNUIMessage({ action = 'testDriveShow' })
    lib.notify({
        title = 'Test Drive',
        description = ('Drive the %s to the marker to set the time limit. BACKSPACE to cancel.'):format(model),
        type = 'inform',
        duration = 8000,
    })

    CreateThread(function()
        while testDrive do
            Wait(200)
            local td = testDrive
            if not td then break end
            if not DoesEntityExist(td.vehicle) then
                lib.notify({ title = 'Test Drive', description = 'Vehicle lost - cancelled.', type = 'error' })
                EndTestDrive(true)
                break
            end

            SendNUIMessage({ action = 'testDriveTick', elapsed = (GetGameTimer() - td.startTime) / 1000 })

            local dist = #(GetEntityCoords(td.vehicle) - td.dropCoords)
            if dist <= td.radius then
                EndTestDrive(false)
                break
            end
        end
    end)

    cb('ok')
end)

RegisterKeyMapping('pinkslips_testdrive_cancel', 'Pinkslips: cancel test drive', 'keyboard', 'BACK')
RegisterCommand('pinkslips_testdrive_cancel', function()
    if testDrive then
        EndTestDrive(true)
    end
end, false)

-- ---------------------------------------------------------------------
-- Camera placement: target = 'start' | 'finish' | 'spawnpoint' (server doesn't care which -
-- the NUI decides what to do with the returned coords)
-- ---------------------------------------------------------------------
local placement = nil

local DropPlacementVehicle
local RePickUpPlacementVehicle
local ConfirmPlacement
local EndPlacement

local function SetPlacementHint(text)
    SendNUIMessage({ action = 'placementHint', text = text })
end

local function GroundRaycast(x, y, z)
    local rayHandle = StartShapeTestRay(x, y, z + 4.0, x, y, z - 500.0, 1, 0, 0)
    local _, hit, endCoords = GetShapeTestResult(rayHandle)
    if hit == 1 then return true, endCoords end
    return false, nil
end

local function RotationToDirection(rotation)
    local x = rotation.x * (math.pi / 180.0)
    local z = rotation.z * (math.pi / 180.0)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function GetCamDirections(rot)
    local forward = RotationToDirection(rot)
    local right = RotationToDirection(vector3(0.0, 0.0, rot.z + 90.0))
    return forward, right
end

EndPlacement = function(cancelled, result)
    local p = placement
    if not p then return end
    placement = nil

    if DoesEntityExist(p.vehicle) then
        DeleteEntity(p.vehicle)
    end
    RenderScriptCams(false, false, 0, true, true)
    if p.cam then DestroyCam(p.cam, false) end

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)

    SendNUIMessage({ action = 'placementHide' })
    SetNuiFocus(true, true)

    if cancelled then
        lib.notify({ title = 'Placement', description = 'Cancelled.', type = 'error' })
    end

    SendNUIMessage({ action = 'placementDone', cancelled = cancelled, target = p.target, result = result })
end

DropPlacementVehicle = function()
    local p = placement
    if not p or p.phase ~= 'flying' then return end

    local camCoords = GetCamCoord(p.cam)
    local found, groundCoords = GroundRaycast(camCoords.x, camCoords.y, camCoords.z)
    if not found then
        lib.notify({ title = 'Placement', description = "Can't find ground under the camera - fly lower and try again.", type = 'error' })
        return
    end

    SetEntityCoordsNoOffset(p.vehicle, groundCoords.x, groundCoords.y, groundCoords.z + 1.0, false, false, false)
    SetEntityHeading(p.vehicle, p.heading)
    FreezeEntityPosition(p.vehicle, false)
    SetEntityCollision(p.vehicle, true, true)
    SetEntityAlpha(p.vehicle, 255, false)

    local preSettle = GetEntityCoords(p.vehicle)
    SetVehicleOnGroundProperly(p.vehicle)
    Wait(200)
    local settled = GetEntityCoords(p.vehicle)

    if #(settled - preSettle) > 5.0 then
        lib.notify({ title = 'Placement', description = 'That spot moved a lot while settling - double check it before confirming.', type = 'inform' })
    end
    if IsEntityInWater(p.vehicle) then
        lib.notify({ title = 'Placement', description = 'This spot is in water.', type = 'inform' })
    end

    p.phase = 'settled'
    SetPlacementHint('Settled - ENTER to confirm, R to pick it back up, LEFT/RIGHT to rotate, BACKSPACE to cancel.')
end

RePickUpPlacementVehicle = function()
    local p = placement
    if not p or p.phase ~= 'settled' then return end
    FreezeEntityPosition(p.vehicle, true)
    SetEntityCollision(p.vehicle, false, false)
    SetEntityAlpha(p.vehicle, 180, false)
    p.phase = 'flying'
    SetPlacementHint('Flying - ENTER to drop the car here.')
end

ConfirmPlacement = function()
    local p = placement
    if not p or p.phase ~= 'settled' then return end
    local coords = GetEntityCoords(p.vehicle)
    local heading = GetEntityHeading(p.vehicle)
    EndPlacement(false, { x = coords.x, y = coords.y, z = coords.z, w = heading })
end

RegisterNUICallback('setupStartPlacement', function(data, cb)
    local target = data and data.target
    if target ~= 'start' and target ~= 'finish' and target ~= 'spawnpoint' then
        cb('ok')
        return
    end
    if placement then cb('ok') return end

    local ped = PlayerPedId()
    local startCoords = GetEntityCoords(ped)
    local startHeading = GetEntityHeading(ped)

    SetNuiFocus(false, false)

    local modelName = (data.vehicleModel and data.vehicleModel ~= '' and data.vehicleModel) or Config.Admin.Placement.PreviewVehicle
    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 100 do
        Wait(50)
        attempts = attempts + 1
    end
    if not HasModelLoaded(modelHash) then
        modelHash = GetHashKey(Config.Admin.Placement.PreviewVehicle)
        RequestModel(modelHash)
        attempts = 0
        while not HasModelLoaded(modelHash) and attempts < 100 do
            Wait(50)
            attempts = attempts + 1
        end
    end

    local vehicle = CreateVehicle(modelHash, startCoords.x, startCoords.y, startCoords.z, startHeading, false, false)
    SetEntityAlpha(vehicle, 180, false)
    SetEntityCollision(vehicle, false, false)
    FreezeEntityPosition(vehicle, true)
    SetEntityInvincible(vehicle, true)
    SetModelAsNoLongerNeeded(modelHash)

    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', startCoords.x, startCoords.y, startCoords.z + 30.0, -60.0, 0.0, startHeading, Config.Admin.Placement.CamFov, false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, true)

    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)

    placement = { target = target, cam = cam, vehicle = vehicle, phase = 'flying', heading = startHeading }

    SendNUIMessage({ action = 'placementShow' })
    SetPlacementHint('Flying - ENTER to drop the car here.')
    lib.notify({
        title = 'Placement',
        description = 'WASD + mouse to fly, SPACE/CTRL for up/down, SHIFT to move faster, LEFT/RIGHT to rotate. ENTER to drop, BACKSPACE to cancel.',
        type = 'inform',
        duration = 9000,
    })

    cb('ok')
end)

CreateThread(function()
    while true do
        Wait(0)
        local p = placement
        if p then
            DisableAllControlActions(0)
            EnableControlAction(0, 200, true) -- Esc - always leave an escape hatch

            local lookLR = GetDisabledControlNormal(0, 1)
            local lookUD = GetDisabledControlNormal(0, 2)
            local moveLR = GetDisabledControlNormal(0, 30)
            local moveUD = GetDisabledControlNormal(0, 31)
            local fast = IsDisabledControlPressed(0, 21)
            local up = IsDisabledControlPressed(0, 22)
            local down = IsDisabledControlPressed(0, 36)
            local rotateLeft = IsDisabledControlPressed(0, 174)
            local rotateRight = IsDisabledControlPressed(0, 175)

            local rot = GetCamRot(p.cam, 2)
            local newRotZ = rot.z - (lookLR * Config.Admin.Placement.LookSensitivity)
            local newRotX = math.max(-89.0, math.min(89.0, rot.x - (lookUD * Config.Admin.Placement.LookSensitivity)))
            SetCamRot(p.cam, newRotX, 0.0, newRotZ, 2)

            local dt = GetFrameTime()
            local speed = Config.Admin.Placement.MoveSpeed * (fast and Config.Admin.Placement.FastMultiplier or 1.0)
            local forward, right = GetCamDirections(vector3(newRotX, 0.0, newRotZ))
            local camCoords = GetCamCoord(p.cam)

            local vertical = 0.0
            if up then vertical = vertical + (speed * dt) end
            if down then vertical = vertical - (speed * dt) end

            local newCoords = camCoords
                + (forward * (-moveUD) * speed * dt)
                + (right * moveLR * speed * dt)
                + vector3(0.0, 0.0, vertical)

            SetCamCoord(p.cam, newCoords.x, newCoords.y, newCoords.z)

            if rotateLeft then p.heading = (p.heading - (Config.Admin.Placement.RotateSpeed * dt)) % 360.0 end
            if rotateRight then p.heading = (p.heading + (Config.Admin.Placement.RotateSpeed * dt)) % 360.0 end

            if p.phase == 'flying' then
                local found, groundCoords = GroundRaycast(newCoords.x, newCoords.y, newCoords.z)
                if found then
                    SetEntityCoordsNoOffset(p.vehicle, groundCoords.x, groundCoords.y, groundCoords.z + 1.0, false, false, false)
                end
                SetEntityHeading(p.vehicle, p.heading)
            elseif rotateLeft or rotateRight then
                SetEntityHeading(p.vehicle, p.heading)
                SetVehicleOnGroundProperly(p.vehicle)
            end
        end
    end
end)

RegisterKeyMapping('pinkslips_placement_action', 'Pinkslips Placement: drop / confirm', 'keyboard', 'RETURN')
RegisterCommand('pinkslips_placement_action', function()
    if not placement then return end
    if placement.phase == 'flying' then
        DropPlacementVehicle()
    elseif placement.phase == 'settled' then
        ConfirmPlacement()
    end
end, false)

RegisterKeyMapping('pinkslips_placement_refly', 'Pinkslips Placement: pick the car back up', 'keyboard', 'R')
RegisterCommand('pinkslips_placement_refly', function()
    RePickUpPlacementVehicle()
end, false)

RegisterKeyMapping('pinkslips_placement_cancel', 'Pinkslips Placement: cancel', 'keyboard', 'BACK')
RegisterCommand('pinkslips_placement_cancel', function()
    if placement then
        EndPlacement(true, nil)
    end
end, false)

-- ===================================================================
-- CLEANUP
-- ===================================================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for _, blip in pairs(startBlips) do RemoveBlip(blip) end
    startBlips = {}

    if activeRace then CleanupRace() end
    if testDrive then
        if DoesEntityExist(testDrive.vehicle) then DeleteEntity(testDrive.vehicle) end
        testDrive = nil
    end
    if placement then
        if DoesEntityExist(placement.vehicle) then DeleteEntity(placement.vehicle) end
        placement = nil
    end
    SetNuiFocus(false, false)
end)