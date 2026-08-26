local QBCore = exports['qb-core']:GetCoreObject()

local vanStates      = {}
local spawnedProps   = {}
local resolvedCoords = {}
local spawnedBlips   = {}
local targetsReady   = false
local statesReady    = false

local function DebugLog(msg)
    if not Config.Debug then return end
    print(('^3[MNC-DEBUG][CLIENT] %s^7'):format(msg))
end

local function Notify(msg, ntype)
    lib.notify({
        title       = 'Food Vans',
        description = msg,
        type        = ntype or 'inform',
        duration    = 4000,
    })
end

RegisterNetEvent('mnc-foodvans:client:notify', function(msg, ntype)
    Notify(msg, ntype)
end)

local function IsLocalAuthorised(vanId)
    local state = vanStates[vanId]
    if not state or state.purchased ~= 1 then
        DebugLog(('IsLocalAuthorised(%s): No state or not purchased'):format(vanId))
        return false
    end

    local pd = QBCore.Functions.GetPlayerData()
    if not pd or not pd.citizenid then
        DebugLog(('IsLocalAuthorised(%s): No player data'):format(vanId))
        return false
    end

    if state.citizenid == pd.citizenid then return true end

    if state.authorised then
        local ok, list = pcall(json.decode, state.authorised)
        if ok and type(list) == 'table' then
            for _, cid in ipairs(list) do
                if cid == pd.citizenid then return true end
            end
        end
    end

    return false
end

local function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(sx, sy)
    local factor = (#text) / 370
    DrawRect(sx, sy + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
end

local EXISTING_PROP_RADIUS = 10.0

local function FindExistingProp(modelHash, configCoords)
    local cv = vector3(configCoords.x, configCoords.y, configCoords.z)
    local best, bestDist = nil, EXISTING_PROP_RADIUS
    for _, obj in ipairs(GetGamePool('CObject')) do
        if GetEntityModel(obj) == modelHash then
            local dist = #(GetEntityCoords(obj) - cv)
            if dist < bestDist then bestDist = dist; best = obj end
        end
    end
    return best
end

local function RaycastGroundZ(x, y, configZ, maxAttempts)
    maxAttempts = maxAttempts or 20
    local fromZ = configZ + 100.0  -- well above any surface
    local toZ   = configZ - 10.0   -- below the expected surface

    for i = 1, maxAttempts do
        RequestCollisionAtCoord(x, y, configZ)
        -- StartShapeTestRay: from, to, flags, ignored-entity, ignored-type
        local ray = StartShapeTestRay(
            x, y, fromZ,
            x, y, toZ,
            1, 0, 0
        )
        local result, hit, hitCoords, _, _ = GetShapeTestResult(ray)
        if result == 2 then  -- 2 = completed (not pending)
            if hit == 1 then
                DebugLog(('RaycastGroundZ hit at Z=%.3f (attempt %d)'):format(hitCoords.z, i))
                return hitCoords.z
            else
                break
            end
        end
        Wait(200)
    end

    -- Backup: GetGroundZFor_3dCoord (works once geometry is loaded)
    local found, gz = GetGroundZFor_3dCoord(x, y, configZ + 100.0, false)
    if found and gz > -100.0 then
        DebugLog(('RaycastGroundZ fallback GetGroundZ=%.3f'):format(gz))
        return gz
    end

    DebugLog(('RaycastGroundZ gave up, using config Z=%.3f'):format(configZ))
    return configZ
end

local function SpawnProp(model, coords, heading, zOffset)
    zOffset = zOffset or 0.0
    local hash = GetHashKey(model)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 150 do
        Wait(50); t = t + 1
    end
    if not HasModelLoaded(hash) then
        DebugLog('Failed to load model: ' .. model)
        return nil
    end

    -- Spawn high up so the prop doesn't clip through the ground while we find its true Z
    local highZ  = coords.z + 100.0
    local prop   = CreateObject(hash, coords.x, coords.y, highZ, false, false, false)
    if not prop or not DoesEntityExist(prop) then
        DebugLog('Failed to create object')
        SetModelAsNoLongerNeeded(hash)
        return nil
    end

    SetEntityHeading(prop, heading)
    SetEntityCollision(prop, false, false)  -- disable collision while repositioning

    -- Find the ground surface via downward ray, ignoring the prop itself (pass its handle)
    local fromZ = coords.z + 100.0
    local toZ   = coords.z - 10.0
    local surfaceZ = coords.z  -- fallback

    for i = 1, 20 do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        local ray = StartShapeTestRay(
            coords.x, coords.y, fromZ,
            coords.x, coords.y, toZ,
            1, prop, 0  -- flag 1 = static geometry; ignore our own prop entity
        )
        local result, hit, hitCoords = GetShapeTestResult(ray)
        if result == 2 then
            if hit == 1 then
                surfaceZ = hitCoords.z
                DebugLog(('SpawnProp ray hit surface Z=%.3f (attempt %d)'):format(surfaceZ, i))
            else
                DebugLog(('SpawnProp ray miss (attempt %d), using config Z'):format(i))
            end
            break
        end
        Wait(200)
    end

    -- Apply per-model offset to correct for models whose origin isn't at their base
    local finalZ = surfaceZ + zOffset
    SetEntityCoords(prop, coords.x, coords.y, finalZ, false, false, false, false)
    SetEntityCollision(prop, true, true)
    FreezeEntityPosition(prop, true)
    SetModelAsNoLongerNeeded(hash)

    DebugLog(('Spawned prop %s at Z=%.3f (surface=%.3f offset=%.2f)'):format(model, finalZ, surfaceZ, zOffset))
    return prop
end

local function RemoveVanProp(vanId)
    if spawnedProps[vanId] and DoesEntityExist(spawnedProps[vanId]) then
        DeleteEntity(spawnedProps[vanId])
    end
    spawnedProps[vanId] = nil
end

local BLIP_COLOR_ALWAYS = 47   -- yellow
local BLIP_COLOR_OPEN   = 2    -- green

local function MakeBlip(sprite, color, scale, coords, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function RemoveVanBlip(vanId)
    local pair = spawnedBlips[vanId]
    if pair then
        if pair.always and DoesBlipExist(pair.always) then RemoveBlip(pair.always) end
        if pair.open   and DoesBlipExist(pair.open)   then RemoveBlip(pair.open)   end
    end
    spawnedBlips[vanId] = nil
end

local function UpdateVanBlips()
    for _, loc in ipairs(Config.VanLocations) do
        local state = vanStates[loc.id]
        local rc    = resolvedCoords[loc.id]
        if not rc then goto continue end

        local pair = spawnedBlips[loc.id] or {}

        -- Sprite 88: always shown once we have coords
        if not pair.always or not DoesBlipExist(pair.always) then
            pair.always = MakeBlip(88, BLIP_COLOR_ALWAYS, 0.7, rc, loc.label)
        end

        -- Sprite 161: only when purchased AND open
        local shouldShowOpen = state and state.purchased == 1 and state.is_open == 1
        if shouldShowOpen then
            if not pair.open or not DoesBlipExist(pair.open) then
                pair.open = MakeBlip(161, BLIP_COLOR_OPEN, 0.8, rc, loc.label .. ' [OPEN]')
            end
        else
            if pair.open and DoesBlipExist(pair.open) then
                RemoveBlip(pair.open)
                pair.open = nil
            end
        end

        spawnedBlips[loc.id] = pair
        ::continue::
    end
end

local function RemoveAllBlips()
    for id in pairs(spawnedBlips) do
        RemoveVanBlip(id)
    end
    spawnedBlips = {}
end


local function BuildTargetOptions(loc)
    return {
        {
            type        = 'client',
            event       = 'mnc-foodvans:client:promptPurchase',
            icon        = 'fas fa-store',
            label       = 'Purchase Location',
            canInteract = function()
                local s = vanStates[loc.id]
                return not s or s.purchased ~= 1
            end,
            vanId = loc.id,
        },
        {
            type        = 'client',
            event       = 'mnc-foodvans:client:toggleOpen',
            icon        = 'fas fa-door-open',
            label       = 'Open / Close Van',
            canInteract = function() return IsLocalAuthorised(loc.id) end,
            vanId       = loc.id,
        },
        {
            type        = 'client',
            event       = 'mnc-foodvans:client:openCraft',
            icon        = 'fas fa-utensils',
            label       = 'Craft Food',
            canInteract = function()
                local s = vanStates[loc.id]
                return s and s.purchased == 1 and s.is_open == 1 and IsLocalAuthorised(loc.id)
            end,
            vanId = loc.id,
        },
        {
            type        = 'client',
            event       = 'mnc-foodvans:client:openStashReq',
            icon        = 'fas fa-box-open',
            label       = 'Open Storage',
            canInteract = function() return IsLocalAuthorised(loc.id) end,
            vanId       = loc.id,
        },
        {
            type        = 'client',
            event       = 'mnc-foodvans:client:openOrderMenu',
            icon        = 'fas fa-truck',
            label       = 'Order Ingredients',
            canInteract = function() return IsLocalAuthorised(loc.id) end,
            vanId       = loc.id,
        },
        {
            type        = 'client',
            event       = 'mnc-foodvans:client:openManageReq',
            icon        = 'fas fa-users-cog',
            label       = 'Manage Van',
            canInteract = function()
                local s  = vanStates[loc.id]
                local pd = QBCore.Functions.GetPlayerData()
                return s and s.purchased == 1 and pd and pd.citizenid and s.citizenid == pd.citizenid
            end,
            vanId = loc.id,
        },
        {
            type        = 'client',
            event       = 'mnc-foodvans:client:openPayMenu',
            icon        = 'fas fa-money-bill-wave',
            label       = 'Request Payment',
            canInteract = function()
                local s = vanStates[loc.id]
                return s and s.purchased == 1 and s.is_open == 1 and IsLocalAuthorised(loc.id)
            end,
            vanId = loc.id,
        },
    }
end

local function AddVanZone(loc)
    local rc = resolvedCoords[loc.id] or vector3(loc.coords.x, loc.coords.y, loc.coords.z)
    exports['qb-target']:AddBoxZone('mnc_foodvan_' .. loc.id, rc, 1.8, 1.8, {
        name      = 'mnc_foodvan_' .. loc.id,
        heading   = loc.coords.w,
        debugPoly = false,
        minZ      = rc.z - 0.5,
        maxZ      = rc.z + 1.8,
    }, {
        options  = BuildTargetOptions(loc),
        distance = Config.InteractRange,
    })
end

local function RefreshTargets()
    if not targetsReady then
        DebugLog('RefreshTargets skipped - targets not ready')
        return
    end

    DebugLog('RefreshTargets: Removing old zones')
    for _, loc in ipairs(Config.VanLocations) do
        exports['qb-target']:RemoveZone('mnc_foodvan_' .. loc.id)
    end

    Wait(300)

    DebugLog('RefreshTargets: Re-creating zones')
    for _, loc in ipairs(Config.VanLocations) do
        AddVanZone(loc)
    end
    DebugLog('RefreshTargets: Complete')
end

RegisterNetEvent('mnc-foodvans:client:syncStates', function(states)
    if type(states) ~= 'table' then return end
    local normalised = {}
    for k, v in pairs(states) do
        normalised[tonumber(k) or k] = {
            id         = v.id,
            citizenid  = v.citizenid,
            owner_name = v.owner_name,
            purchased  = (v.purchased == true) and 1 or (v.purchased == false) and 0 or v.purchased,
            is_open    = (v.is_open   == true) and 1 or (v.is_open   == false) and 0 or v.is_open,
            authorised = v.authorised,
        }
    end
    vanStates = normalised

    if Config.Debug then
        local summary = {}
        for k, v in pairs(vanStates) do
            summary[#summary + 1] = ('id=%s purchased=%s is_open=%s owner=%s'):format(
                tostring(k), tostring(v.purchased), tostring(v.is_open), tostring(v.citizenid or 'none'))
        end
        DebugLog('syncStates | ' .. (#summary > 0 and table.concat(summary, ' | ') or 'EMPTY'))
    end

    statesReady = true
    UpdateVanBlips()
    if targetsReady then RefreshTargets() end
end)

RegisterNetEvent('mnc-foodvans:client:forceRefresh', function()
    DebugLog('forceRefresh called')
    UpdateVanBlips()
    if targetsReady then RefreshTargets() end
end)


AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(500)
    TriggerServerEvent('mnc-foodvans:server:requestStates')
end)


AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('mnc-foodvans:server:requestStates')
end)


local PROP_LOAD_RADIUS   = 150.0   -- spawn prop when closer than this
local PROP_UNLOAD_RADIUS = 200.0   -- delete prop when farther than this

-- Per-location coroutine handles so we can avoid overlapping spawns
local propSpawning = {}

local function SpawnVanPropNearby(loc)
    if propSpawning[loc.id] then return end   -- already in progress
    propSpawning[loc.id] = true

    CreateThread(function()
        DebugLog(('Proximity spawn starting for van %d'):format(loc.id))
        local configVec = vector3(loc.coords.x, loc.coords.y, loc.coords.z)

        -- Check for a map-placed prop first (avoids a duplicate)
        local modelHash = GetHashKey(loc.prop)
        RequestModel(modelHash)
        local mt = 0
        while not HasModelLoaded(modelHash) and mt < 60 do Wait(50); mt = mt + 1 end
        SetModelAsNoLongerNeeded(modelHash)

        local existing = FindExistingProp(modelHash, loc.coords)
        if existing then
            DebugLog(('Van %d: using existing map prop'):format(loc.id))
            local ec = GetEntityCoords(existing)
            resolvedCoords[loc.id] = ec
            if not targetsReady then
                AddVanZone(loc)
            else
                exports['qb-target']:RemoveZone('mnc_foodvan_' .. loc.id)
                Wait(100)
                AddVanZone(loc)
            end
            UpdateVanBlips()
            propSpawning[loc.id] = nil
            return
        end

        RemoveVanProp(loc.id)
        local prop = SpawnProp(loc.prop, configVec, loc.coords.w, loc.zOffset or 0.0)
        if prop then
            spawnedProps[loc.id] = prop
            local ec = GetEntityCoords(prop)
            resolvedCoords[loc.id] = ec
            DebugLog(('Van %d: prop spawned at Z=%.3f'):format(loc.id, ec.z))
        else
            -- SpawnProp failed — use config coords as fallback so targets still register
            resolvedCoords[loc.id] = configVec
            DebugLog(('Van %d: prop spawn failed, using config coords'):format(loc.id))
        end

        if not targetsReady then
            AddVanZone(loc)
        else
            exports['qb-target']:RemoveZone('mnc_foodvan_' .. loc.id)
            Wait(100)
            AddVanZone(loc)
        end
        UpdateVanBlips()
        propSpawning[loc.id] = nil
    end)
end


CreateThread(function()
    local waited = 0
    while not statesReady and waited < 15000 do
        Wait(100)
        waited = waited + 100
    end
    DebugLog(('Init: statesReady=%s after %dms'):format(tostring(statesReady), waited))

    for _, loc in ipairs(Config.VanLocations) do
        resolvedCoords[loc.id] = vector3(loc.coords.x, loc.coords.y, loc.coords.z)
        AddVanZone(loc)
    end

    targetsReady = true
    UpdateVanBlips()
    DebugLog('Init complete — proximity loop active')
end)

-- Proximity loop: spawn props as player approaches, unload when far away
CreateThread(function()
    while true do
        Wait(1000)
        if not statesReady then goto continue end

        local playerCoords = GetEntityCoords(PlayerPedId())
        for _, loc in ipairs(Config.VanLocations) do
            local configVec = vector3(loc.coords.x, loc.coords.y, loc.coords.z)
            local dist      = #(playerCoords - configVec)

            if dist < PROP_LOAD_RADIUS and not spawnedProps[loc.id] and not propSpawning[loc.id] then
                SpawnVanPropNearby(loc)
            elseif dist > PROP_UNLOAD_RADIUS and spawnedProps[loc.id] then
                DebugLog(('Van %d out of range, unloading prop'):format(loc.id))
                RemoveVanProp(loc.id)
                -- Reset resolvedCoords to config so target zone stays in the right place
                resolvedCoords[loc.id] = configVec
            end
        end

        ::continue::
    end
end)

CreateThread(function()
    while true do
        if not targetsReady then
            Wait(500)
        else
            local coords = GetEntityCoords(PlayerPedId())
            local drawn  = false
            for _, loc in ipairs(Config.VanLocations) do
                local rc = resolvedCoords[loc.id]
                if rc and #(coords - rc) < 10.0 then
                    drawn = true
                    local state = vanStates[loc.id]
                    local text  = (not state or state.purchased ~= 1)
                        and Config.SignBuy:format(loc.price)
                        or  (state.is_open == 1 and Config.SignOpen or Config.SignClosed)
                    DrawText3D(rc.x, rc.y, rc.z + 2.0, text)
                end
            end
            Wait(drawn and 0 or 500)
        end
    end
end)

RegisterNetEvent('mnc-foodvans:client:promptPurchase', function(data)
    DebugLog(('promptPurchase fired | vanId=%s'):format(tostring(data and data.vanId)))
    local loc = nil
    for _, l in ipairs(Config.VanLocations) do
        if l.id == data.vanId then loc = l; break end
    end
    if not loc then return end

    local state = vanStates[data.vanId]
    if state and state.purchased == 1 then
        Notify('This location is already owned.', 'error')
        return
    end

    local alert = lib.alertDialog({
        header  = 'Purchase Van Location',
        content = ('Do you want to purchase **%s** for **$%s**?'):format(loc.label, loc.price),
        centered = true,
        cancel  = true,
    })

    if alert == 'confirm' then
        TriggerServerEvent('mnc-foodvans:server:purchase', data.vanId)
    end
end)


RegisterNetEvent('mnc-foodvans:client:toggleOpen', function(data)
    TriggerServerEvent('mnc-foodvans:server:toggleOpen', data.vanId)
end)


RegisterNetEvent('mnc-foodvans:client:openCraft', function(data)
    if not data.recipes then
        TriggerServerEvent('mnc-foodvans:server:openCraft', data.vanId)
        return
    end

    local options = {}
    for i, recipe in ipairs(data.recipes) do
        local parts = {}
        for _, ing in ipairs(recipe.ingredients) do
            parts[#parts + 1] = ing.amount .. 'x ' .. ing.item
        end

        local ingredientCount = #recipe.ingredients

        options[#options + 1] = {
            title       = recipe.label,
            description = 'Needs: ' .. table.concat(parts, ', '),
            icon        = 'fas fa-utensils',
            onSelect    = function()
                local confirm = lib.alertDialog({
                    header   = 'Craft Item',
                    content  = ('Craft **%s**?'):format(recipe.label),
                    centered = true,
                    cancel   = true,
                })
                if confirm ~= 'confirm' then return end

                local lowerLabel = recipe.label:lower()
                local duration = math.max(ingredientCount * 5200, 9500)

                -- Choose animation
                local animDict, animName
                if lowerLabel:find("burger") or lowerLabel:find("hotdog") or lowerLabel:find("fries") or lowerLabel:find("nuggets") or lowerLabel:find("chicken") then
                    animDict = "amb@prop_human_bbq@male@idle_a"
                    animName = "idle_a"
                elseif lowerLabel:find("coffee") or lowerLabel:find("espresso") or lowerLabel:find("latte") or lowerLabel:find("cappuccino") or lowerLabel:find("mocha") then
                    animDict = "anim@amb@clubhouse@bar@drink@one"
                    animName = "drink_one"
                else
                    animDict = "amb@prop_human_bbq@male@idle_a"
                    animName = "idle_a"
                end

                -- Sound & Particle setup
                local soundId = GetSoundId()  -- Unique sound ID

                local success = lib.progressBar({
                    duration = duration,
                    label    = 'Cooking ' .. recipe.label .. '...',
                    useWhileDead = false,
                    canCancel    = true,
                    disable = {
                        move   = true,
                        car    = true,
                        combat = true,
                    },
                    anim = {
                        dict = animDict,
                        clip = animName,
                        flag = 49,
                    },
                    particles = {
                        {
                            dict   = "core",
                            name   = "ent_amb_smoke_grill",
                            offset = vector3(0.0, 0.0, 1.3),
                            rotation = vector3(0.0, 0.0, 0.0),
                            scale  = 0.8,
                        }
                    }
                })

                -- Stop sound when progress ends
                if soundId then
                    StopSound(soundId)
                    ReleaseSoundId(soundId)
                end

                if success then
                    TriggerServerEvent('mnc-foodvans:server:craft', data.vanId, i)
                else
                    Notify('Crafting cancelled.', 'error')
                end
            end,
        }
    end

    if #options == 0 then
        Notify('No recipes available for this van.', 'error')
        return
    end

    lib.registerContext({
        id      = 'mnc_craft_menu_' .. data.vanId,
        title   = (data.label or 'Van') .. ' — Craft',
        options = options,
    })
    lib.showContext('mnc_craft_menu_' .. data.vanId)
end)

RegisterNetEvent('mnc-foodvans:client:openStashReq', function(data)
    TriggerServerEvent('mnc-foodvans:server:openStash', data.vanId)
end)


RegisterNetEvent('mnc-foodvans:client:openPayMenu', function(data)
    local myId = GetPlayerServerId(PlayerId())

    local input = lib.inputDialog('Request Payment', {
        { type = 'number', label = 'Player Server ID (your ID: ' .. myId .. ')', placeholder = tostring(myId), min = 1, required = true },
        { type = 'number', label = 'Amount ($)', placeholder = 'e.g. 500', min = 1, max = Config.MaxPayment, required = true },
        { type = 'input',  label = 'Reason (optional)', placeholder = 'e.g. Burger combo' },
    })
    if not input then return end

    local targetId = tonumber(input[1])
    local amount   = tonumber(input[2])
    local reason   = (input[3] and input[3] ~= '') and input[3] or 'Food purchase'

    if not targetId or not amount then
        Notify('Invalid input.', 'error')
        return
    end

    TriggerServerEvent('mnc-foodvans:server:requestPayment', data.vanId, targetId, amount, reason)
end)


RegisterNetEvent('mnc-foodvans:client:receiveInvoice', function(invoiceData)
    -- invoiceData = { invoiceId, workerName, amount, reason, isSelf }
    local header  = invoiceData.isSelf and 'Self-Charge' or ('Invoice from ' .. invoiceData.workerName)
    local content = ('**%s** is requesting **$%d**\n\nReason: *%s*'):format(
        invoiceData.workerName, invoiceData.amount, invoiceData.reason)

    local alert = lib.alertDialog({
        header   = header,
        content  = content,
        centered = true,
        cancel   = true,
    })

    local confirmed = (alert == 'confirm')
    TriggerServerEvent('mnc-foodvans:server:respondInvoice', invoiceData.invoiceId, confirmed)
end)


RegisterNetEvent('mnc-foodvans:client:openManageReq', function(data)
    TriggerServerEvent('mnc-foodvans:server:getManageData', data.vanId)
end)

RegisterNetEvent('mnc-foodvans:client:openManage', function(vanId, authorisedList, safeBalance)
    local options = {}

    -- Safe balance display + withdraw (owner only sees this via getManageData auth check)
    local safeLabel = ('💰 Van Safe: $%d'):format(safeBalance or 0)
    options[#options + 1] = {
        title       = safeLabel,
        icon        = 'fas fa-safe',
        description = (safeBalance or 0) > 0 and 'Click to withdraw all funds to your bank' or 'Safe is currently empty',
        disabled    = (safeBalance or 0) <= 0,
        onSelect    = function()
            local confirm = lib.alertDialog({
                header   = 'Withdraw Safe',
                content  = ('Withdraw **$%d** from the van safe to your bank?'):format(safeBalance or 0),
                centered = true,
                cancel   = true,
            })
            if confirm == 'confirm' then
                TriggerServerEvent('mnc-foodvans:server:withdrawSafe', vanId)
            end
        end,
    }

    -- Divider label
    options[#options + 1] = { title = '── Staff Management ──', disabled = true, icon = 'fas fa-users' }

    -- Current staff list with remove buttons
    for _, cid in ipairs(authorisedList) do
        options[#options + 1] = {
            title    = 'Remove: ' .. cid,
            icon     = 'fas fa-user-minus',
            onSelect = function()
                TriggerServerEvent('mnc-foodvans:server:removeAuthorised', vanId, cid)
            end,
        }
    end
    if #authorisedList == 0 then
        options[#options + 1] = { title = 'No staff authorised', disabled = true, icon = 'fas fa-info-circle' }
    end

    options[#options + 1] = {
        title    = 'Add Staff Member',
        icon     = 'fas fa-user-plus',
        onSelect = function()
            local input = lib.inputDialog('Add Staff', {
                { type = 'input', label = 'Citizen ID', placeholder = 'QBX12345', required = true }
            })
            if input and input[1] then
                TriggerServerEvent('mnc-foodvans:server:addAuthorised', vanId, input[1])
            end
        end,
    }

    -- Divider label
    options[#options + 1] = { title = '── Location ──', disabled = true, icon = 'fas fa-map-marker-alt' }

    -- Sell location
    options[#options + 1] = {
        title       = 'Sell Location',
        icon        = 'fas fa-sign',
        description = 'Put this location back up for sale',
        onSelect    = function()
            local confirm = lib.alertDialog({
                header   = 'Sell Location',
                content  = 'Are you sure you want to **sell this location**?\n\nIt will be put back up for sale, all staff will be removed, and any safe balance paid out to your bank.',
                centered = true,
                cancel   = true,
            })
            if confirm == 'confirm' then
                TriggerServerEvent('mnc-foodvans:server:sellLocation', vanId)
            end
        end,
    }

    lib.registerContext({ id = 'mnc_manage_' .. vanId, title = 'Manage Van', options = options })
    lib.showContext('mnc_manage_' .. vanId)
end)

RegisterNetEvent('mnc-foodvans:client:openOrderMenu', function(data)
    local options = {}
    for _, ing in ipairs(Config.OrderableIngredients) do
        options[#options + 1] = {
            title       = ing.label,
            description = ('$%d per batch of %dx'):format(ing.price, ing.amount),
            icon        = 'fas fa-shopping-basket',
            onSelect    = function()
                local input = lib.inputDialog('Order Quantity', {
                    { type = 'number', label = 'Batches', placeholder = '1', min = 1, max = 20, required = true }
                })
                if not input or not input[1] then return end
                local qty   = math.floor(tonumber(input[1]))
                local total = qty * ing.price
                local confirm = lib.alertDialog({
                    header   = 'Confirm Order',
                    content  = ('Order **%dx %s** for **$%d**?'):format(qty * ing.amount, ing.label, total),
                    centered = true,
                    cancel   = true,
                })
                if confirm == 'confirm' then
                    TriggerServerEvent('mnc-foodvans:server:orderIngredients', data.vanId, {{ item = ing.item, qty = qty }})
                end
            end,
        }
    end
    lib.registerContext({ id = 'mnc_order_' .. data.vanId, title = 'Order Ingredients', options = options })
    lib.showContext('mnc_order_' .. data.vanId)
end)


local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 60 do Wait(50); t = t + 1 end
end

RegisterNetEvent('mnc-foodvans:client:spawnDelivery', function(vanId)
    local rc = resolvedCoords[vanId]
    if not rc then return end
    Wait (15000)
    -- Spawn courier 10m away in a fixed direction from the van
    local spawnOffset = vector3(rc.x + 20.0, rc.y, rc.z)
    local hash = GetHashKey(Config.DeliveryPedModel)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 100 do Wait(50); t = t + 1 end
    if not HasModelLoaded(hash) then
        Notify('Delivery ped model failed to load.', 'error')
        return
    end

    local courier = CreatePed(4, hash, spawnOffset.x, spawnOffset.y, spawnOffset.z, 0.0, false, true)
    SetModelAsNoLongerNeeded(hash)
    SetBlockingOfNonTemporaryEvents(courier, true)
    SetPedCanRagdoll(courier, false)

    -- Walk to a point 1.5m in front of the player's ped (the handoff point)
    local playerPed   = PlayerPedId()
    local playerPos   = GetEntityCoords(playerPed)
    local handoffPoint = vector3(playerPos.x, playerPos.y, playerPos.z)

    TaskGoStraightToCoord(courier, handoffPoint.x, handoffPoint.y, handoffPoint.z,
        Config.DeliveryWalkSpeed, -1, 0.0, 0.8)

    CreateThread(function()
        -- Wait for courier to arrive near the player
        local arrived  = false
        local deadline = GetGameTimer() + 40000
        while not arrived and GetGameTimer() < deadline do
            if DoesEntityExist(courier) and
               #(GetEntityCoords(courier) - GetEntityCoords(PlayerPedId())) < 2.0 then
                arrived = true
            end
            Wait(300)
        end

        if not arrived or not DoesEntityExist(courier) then
            if DoesEntityExist(courier) then DeleteEntity(courier) end
            Notify('Delivery courier got lost!', 'error')
            return
        end

        -- Stop movement, face each other
        TaskStandStill(courier, -1)
        local playerFwd = GetEntityForwardVector(PlayerPedId())
        -- Courier faces the player
        local courierAngle = GetHeadingFromVector_2d(-playerFwd.x, -playerFwd.y)
        -- Player faces the courier
        local playerAngle  = GetHeadingFromVector_2d(playerFwd.x, playerFwd.y)
        SetEntityHeading(courier, courierAngle)

        -- Load handoff animations
        local giveDict    = 'mp_common'
        local giveClip    = 'givetake1_a'   -- giver (courier)
        local receiveClip = 'givetake1_b'   -- receiver (player)
        LoadAnimDict(giveDict)

        -- Play both animations simultaneously
        TaskPlayAnim(courier, giveDict, giveClip, 4.0, -4.0, 3000, 0, 0, false, false, false)
        TaskPlayAnim(PlayerPedId(), giveDict, receiveClip, 4.0, -4.0, 3000, 0, 0, false, false, false)
        Wait(2000)
        -- Items arrive in inventory after the handshake animation
        Notify('Delivery complete — ingredients in your inventory!', 'success')

        -- Courier walks back and despawns
        TaskGoStraightToCoord(courier, spawnOffset.x, spawnOffset.y, spawnOffset.z,
            Config.DeliveryWalkSpeed, -1, 0.0, 0.5)
        Wait(15000)
        if DoesEntityExist(courier) then DeleteEntity(courier) end
    end)
end)


-- Build a lookup: prop → list of { label, item, price } using Config.CustomerSalePrices
local function BuildSaleItems()
    local saleItems = {}   -- saleItems[prop] = { {label, item, price}, ... }
    for prop, recipes in pairs(Config.PropRecipes) do
        saleItems[prop] = {}
        for _, recipe in ipairs(recipes) do
            local price = Config.CustomerSalePrices[recipe.result]
            if price and price > 0 then
                saleItems[prop][#saleItems[prop] + 1] = {
                    label = recipe.label,
                    item  = recipe.result,   -- the crafted output item
                    price = price,
                }
            end
        end
    end
    return saleItems
end

local NPC_SALE_ITEMS = BuildSaleItems()

-- Pedestrian model pool for customers
local CUSTOMER_MODELS = {
    'a_f_y_tourist_01', 'a_m_y_tourist_01', 'a_f_m_downtown_01',
    'a_m_m_downtown_01', 'a_f_y_vinewood_01', 'a_m_y_vinewood_01',
    'a_f_y_eastsa_01',  'a_m_y_eastsa_01',   'a_m_m_farmer_01',
}

-- Active NPC customer peds per vanId: { [vanId] = { ped, ... } }
local activeCustomers = {}

local function CleanupCustomers(vanId)
    if activeCustomers[vanId] then
        for _, ped in ipairs(activeCustomers[vanId]) do
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
        activeCustomers[vanId] = nil
    end
end

local function SpawnCustomer(vanId, vanCoords, prop)
    local items = NPC_SALE_ITEMS[prop]
    if not items or #items == 0 then return end

    local modelName = CUSTOMER_MODELS[math.random(#CUSTOMER_MODELS)]
    local hash = GetHashKey(modelName)

    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 60 do
        Wait(50)
        timeout += 1
    end

    if not HasModelLoaded(hash) then
        SetModelAsNoLongerNeeded(hash)
        return
    end

    local playerPos = GetEntityCoords(PlayerPedId())
    local angle = math.random() * math.pi * 2
    local radius = Config.CustomerSpawnRadius or 45.0

    local spawnX = playerPos.x + math.cos(angle) * radius
    local spawnY = playerPos.y + math.sin(angle) * radius
    local spawnZ = playerPos.z + 1.0  -- slight offset to avoid ground issues

    local ped = CreatePed(4, hash, spawnX, spawnY, spawnZ, 0.0, false, true)
    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(ped) then return end

    -- Basic ped setup
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCanRagdoll(ped, false)
    SetEntityInvincible(ped, true)        -- optional: prevent random death
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)

    -- Store ped
    activeCustomers[vanId] = activeCustomers[vanId] or {}
    table.insert(activeCustomers[vanId], ped)

    -- Calculate approach point (1.5m in front of the van)
    local dx = vanCoords.x - spawnX
    local dy = vanCoords.y - spawnY
    local toVanHeading = GetHeadingFromVector_2d(dx, dy)

    local approachX = vanCoords.x + math.cos(math.rad(toVanHeading + 180)) * 1.5
    local approachY = vanCoords.y + math.sin(math.rad(toVanHeading + 180)) * 1.5

    -- Make customer walk to the van
    TaskGoStraightToCoord(ped, approachX, approachY, vanCoords.z, 1.0, -1, 0.0, 0.5)

    CreateThread(function()
        local deadline = GetGameTimer() + 60000
        local arrived = false

        while DoesEntityExist(ped) and GetGameTimer() < deadline and not arrived do
            local pedCoords = GetEntityCoords(ped)
            if #(pedCoords - vector3(vanCoords.x, vanCoords.y, vanCoords.z)) < 2.5 then
                arrived = true
            end
            Wait(400)
        end

        if not DoesEntityExist(ped) then return end

        if arrived then
            -- Face the van
            local pedCoords = GetEntityCoords(ped)
            local facingHeading = GetHeadingFromVector_2d(vanCoords.x - pedCoords.x, vanCoords.y - pedCoords.y)
            SetEntityHeading(ped, facingHeading)

            TaskStandStill(ped, -1)

            -- Play idle animation
            local idleDict = 'amb@world_human_stand_mobile@male@base'
            RequestAnimDict(idleDict)
            timeout = 0
            while not HasAnimDictLoaded(idleDict) and timeout < 50 do
                Wait(10)
                timeout += 1
            end

            if HasAnimDictLoaded(idleDict) then
                TaskPlayAnim(ped, idleDict, 'base', 2.0, -2.0, -1, 1, 0, false, false, false)
            end

            -- === Customer Order ===
            local chosen = items[math.random(#items)]

            local alert = lib.alertDialog({
                header = 'Customer Order',
                content = ('**%s** wants to buy:\n\n**%s** for **$%d**'):format(
                    'Customer', -- you can improve name detection if wanted
                    chosen.label,
                    chosen.price
                ),
                centered = true,
                cancel = true,
                size = 'md'
            })

            local waitTime = 0

            if alert == nil then -- canceled / ESC
                lib.notify({ title = 'Customer', description = 'Customer denied — they walked away disappointed.', type = 'error' })
            else
                -- alert == 'confirm' in ox_lib alertDialog
                local choice = lib.inputDialog('Customer Action', {
                    {type = 'select', label = 'What do you want to do?', options = {
                        {value = 'confirm', label = 'Confirm Sale'},
                        {value = 'wait10',  label = 'Make them wait 10 seconds'},
                        {value = 'wait30',  label = 'Make them wait 30 seconds'},
						{value = 'wait60',  label = 'Make them wait 60 seconds'},
						{value = 'wait120',  label = 'Make them wait 120 seconds'},
                        {value = 'deny',    label = 'Deny Order'},
                    }}
                })

                if choice and choice[1] == 'deny' then
                    lib.notify({ title = 'Customer', description = 'Customer denied — they walked away disappointed.', type = 'error' })
                elseif choice and choice[1] == 'wait10' then
                    waitTime = 10000
                    lib.notify({ title = 'Customer', description = 'Customer will wait 10 seconds...', type = 'inform' })
                elseif choice and choice[1] == 'wait30' then
                    waitTime = 30000
                    lib.notify({ title = 'Customer', description = 'Customer will wait 30 seconds...', type = 'inform' })
				elseif choice and choice[1] == 'wait60' then
                    waitTime = 60000
                    lib.notify({ title = 'Customer', description = 'Customer will wait 60 seconds...', type = 'inform' })
                elseif choice and choice[1] == 'wait120' then
                    waitTime = 120000
                    lib.notify({ title = 'Customer', description = 'Customer will wait 120 seconds...', type = 'inform' })
				elseif choice and choice[1] == 'confirm' then
                    TriggerServerEvent('mnc-foodvans:server:npcSale', vanId, chosen.item, chosen.price)
                end
            end

            -- Handle waiting
            if waitTime > 0 then
                Wait(waitTime)
                if not DoesEntityExist(ped) then return end

                local secondAlert = lib.alertDialog({
                    header = 'Customer Still Waiting',
                    content = ('The customer is still waiting for **%s** ($%d)'):format(chosen.label, chosen.price),
                    centered = true,
                    cancel = true,
                    size = 'md'
                })

                if secondAlert then
                    TriggerServerEvent('mnc-foodvans:server:npcSale', vanId, chosen.item, chosen.price)
                else
                    lib.notify({ title = 'Customer', description = 'Customer got tired of waiting and left.', type = 'error' })
                end
            end
        end

        -- === Walk away and despawn ===
        if DoesEntityExist(ped) then
            ClearPedTasks(ped)
            TaskGoStraightToCoord(ped, spawnX, spawnY, spawnZ, 1.0, -1, 0.0, 0.5)
            Wait(80000) -- give them time to walk a bit
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end

        -- Cleanup from active list
        if activeCustomers[vanId] then
            for i = #activeCustomers[vanId], 1, -1 do
                if activeCustomers[vanId][i] == ped then
                    table.remove(activeCustomers[vanId], i)
                    break
                end
            end
        end
    end)
end


-- Customer spawn loop: runs per open van near the player
local MAX_CUSTOMERS_PER_VAN = 6   -- max simultaneous customers at one stall
local CUSTOMER_SPAWN_INTERVAL = 10  -- seconds between spawn attempts

CreateThread(function()
    while true do
        Wait(CUSTOMER_SPAWN_INTERVAL * 2000)
        if not targetsReady then goto npcContinue end

        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, loc in ipairs(Config.VanLocations) do
            local state = vanStates[loc.id]
            -- Only spawn at open, purchased vans that are nearby (within 2× spawn radius)
            if state and state.purchased == 1 and state.is_open == 1 then
                local rc = resolvedCoords[loc.id]
                local checkRadius = (45.0) * 2
                if rc and #(playerCoords - rc) < checkRadius then
                    local current = activeCustomers[loc.id] and #activeCustomers[loc.id] or 0
                    if current < MAX_CUSTOMERS_PER_VAN then
                        SpawnCustomer(loc.id, rc, loc.prop)
                    end
                end
            else
                -- Van closed or sold — clean up any lingering customers
                if activeCustomers[loc.id] then
                    CleanupCustomers(loc.id)
                end
            end
        end

        ::npcContinue::
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    for vanId in pairs(spawnedProps) do RemoveVanProp(vanId) end
    for vanId in pairs(activeCustomers) do CleanupCustomers(vanId) end
    RemoveAllBlips()
end)