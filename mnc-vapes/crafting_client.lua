-- crafting_client.lua  (mnc-vapes)
-- Handles juice crafting UI + portable juice/vape/concentrate tables + vape device crafting UI

local QBCore = exports['qb-core']:GetCoreObject()

-- ─────────────────────────────────────────────────────────────
--  Local helpers
-- ─────────────────────────────────────────────────────────────

local function Notify(msg, typ)
    exports.ox_lib:notify({ description = msg, type = typ or 'inform' })
end

local function DebugPrint(msg)
    if Config.DebugMode then print('[mnc-vapes][CLIENT] ' .. tostring(msg)) end
end

-- ─────────────────────────────────────────────────────────────
--  Progress helper
-- ─────────────────────────────────────────────────────────────

local function ShowProgress(duration, label, canCancel)
    local success = false

    if Config.ProgressType == 'ox_bar' then
        success = exports['ox_lib']:progressBar({
            duration     = duration,
            label        = label,
            useWhileDead = false,
            canCancel    = canCancel or true,
            disable      = { move = true, car = true, combat = true },
        })
    elseif Config.ProgressType == 'ox_circle' then
        success = exports['ox_lib']:progressCircle({
            duration     = duration,
            label        = label,
            position     = 'bottom',
            useWhileDead = false,
            canCancel    = canCancel or true,
            disable      = { move = true, car = true, combat = true },
        })
    elseif Config.ProgressType == 'qb' then
        QBCore.Functions.Progressbar('mnc_vapes_progress', label, duration,
            false, canCancel or true,
            { disableMovement = true, disableCarMovement = true,
              disableMouse = false, disableCombat = true },
            {}, {}, {},
            function() success = true  end,
            function() success = false end
        )
        Wait(duration + 100)
    else
        Wait(duration)
        success = true
    end

    return success
end

-- ─────────────────────────────────────────────────────────────
--  State
-- ─────────────────────────────────────────────────────────────

local craftingStationProps     = {}
local vapeStationProps         = {}
local concentrateStationProps  = {}
local processingTables         = {}

-- ─────────────────────────────────────────────────────────────
--  Static crafting-station props & qb-target zones (juice only)
-- ─────────────────────────────────────────────────────────────

CreateThread(function()
    for i, station in ipairs(Config.CraftingStations) do
        local model = GetHashKey(station.prop or 'prop_table_03')
        RequestModel(model)
        local attempts = 0
        while not HasModelLoaded(model) and attempts < 100 do
            Wait(10); attempts = attempts + 1
        end
        if HasModelLoaded(model) then
            local obj = CreateObject(model,
                station.coords.x, station.coords.y, station.coords.z - 1.0,
                false, false, false)
            if DoesEntityExist(obj) then
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                SetEntityHeading(obj, station.heading or 0.0)
                table.insert(craftingStationProps, obj)
            end
            SetModelAsNoLongerNeeded(model)
        else
            print(('[mnc-vapes] WARNING: Failed to load model "%s" for station #%d')
                :format(station.prop or 'prop_table_03', i))
        end
    end
end)

CreateThread(function()
    for i, station in ipairs(Config.CraftingStations) do
        local jobRestriction = nil
        if station.job and station.job ~= 'none' then
            jobRestriction = { [station.job] = station.minGrade or 0 }
        end
        exports['qb-target']:AddBoxZone(
            'mnc_vape_station_' .. i,
            station.coords,
            1.2, 1.2,
            {
                name      = 'mnc_vape_station_' .. i,
                heading   = station.heading,
                debugPoly = Config.DebugMode,
                minZ      = station.coords.z - 1.0,
                maxZ      = station.coords.z + 1.5,
            },
            {
                options = {
                    {
                        type  = 'client',
                        event = 'mnc-vapes:client:openCraftingMenu',
                        icon  = 'fas fa-flask',
                        label = station.label,
                        job   = jobRestriction,
                    }
                },
                distance = 2.5
            }
        )
    end
end)

-- ─────────────────────────────────────────────────────────────
--  Vape crafting stations (separate job-locked locations)
-- ─────────────────────────────────────────────────────────────

CreateThread(function()
    for i, station in ipairs(Config.VapeCraftingStations) do
        local model = GetHashKey(station.prop or 'prop_table_03')
        RequestModel(model)
        local attempts = 0
        while not HasModelLoaded(model) and attempts < 100 do
            Wait(10); attempts = attempts + 1
        end
        if HasModelLoaded(model) then
            local obj = CreateObject(model,
                station.coords.x, station.coords.y, station.coords.z - 1.0,
                false, false, false)
            if DoesEntityExist(obj) then
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                SetEntityHeading(obj, station.heading or 0.0)
                table.insert(vapeStationProps, obj)
            end
            SetModelAsNoLongerNeeded(model)
        else
            print(('[mnc-vapes] WARNING: Failed to load model "%s" for vape station #%d')
                :format(station.prop or 'prop_table_03', i))
        end
    end
end)

CreateThread(function()
    for i, station in ipairs(Config.VapeCraftingStations) do
        local jobRestriction = nil
        if station.job and station.job ~= 'none' then
            jobRestriction = { [station.job] = station.minGrade or 0 }
        end
        exports['qb-target']:AddBoxZone(
            'mnc_vape_station_vape_' .. i,
            station.coords,
            1.2, 1.2,
            {
                name      = 'mnc_vape_station_vape_' .. i,
                heading   = station.heading,
                debugPoly = Config.DebugMode,
                minZ      = station.coords.z - 1.0,
                maxZ      = station.coords.z + 1.5,
            },
            {
                options = {
                    {
                        type   = 'client',
                        event  = 'mnc-vapes:client:openCraftingMenu',
                        icon   = 'fas fa-tools',
                        label  = station.label,
                        job    = jobRestriction,
                        isVape = true,
                    }
                },
                distance = 2.5
            }
        )
    end
end)

-- ─────────────────────────────────────────────────────────────
--  Concentrate crafting stations
-- ─────────────────────────────────────────────────────────────

CreateThread(function()
    for i, station in ipairs(Config.ConcentrateCraftingStations) do
        local model = GetHashKey(station.prop or 'v_ret_ml_tablea')
        RequestModel(model)
        local attempts = 0
        while not HasModelLoaded(model) and attempts < 100 do
            Wait(10); attempts = attempts + 1
        end
        if HasModelLoaded(model) then
            local obj = CreateObject(model,
                station.coords.x, station.coords.y, station.coords.z - 1.0,
                false, false, false)
            if DoesEntityExist(obj) then
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                SetEntityHeading(obj, station.heading or 0.0)
                table.insert(concentrateStationProps, obj)
            end
            SetModelAsNoLongerNeeded(model)
        else
            print(('[mnc-vapes] WARNING: Failed to load model "%s" for concentrate station #%d')
                :format(station.prop or 'v_ret_ml_tablea', i))
        end
    end
end)

CreateThread(function()
    for i, station in ipairs(Config.ConcentrateCraftingStations) do
        local jobRestriction = nil
        if station.job and station.job ~= 'none' then
            jobRestriction = { [station.job] = station.minGrade or 0 }
        end
        exports['qb-target']:AddBoxZone(
            'mnc_concentrate_station_' .. i,
            station.coords,
            1.2, 1.2,
            {
                name      = 'mnc_concentrate_station_' .. i,
                heading   = station.heading,
                debugPoly = Config.DebugMode,
                minZ      = station.coords.z - 1.0,
                maxZ      = station.coords.z + 1.5,
            },
            {
                options = {
                    {
                        type          = 'client',
                        event         = 'mnc-vapes:client:openCraftingMenu',
                        icon          = 'fas fa-mortar-pestle',
                        label         = station.label,
                        job           = jobRestriction,
                        isConcentrate = true,
                    }
                },
                distance = 2.5
            }
        )
    end
end)

-- ─────────────────────────────────────────────────────────────
-- Portable table — SPAWN helper (supports juice, vape & concentrate tables)
-- ─────────────────────────────────────────────────────────────

local function CreatePortableTable(tableId, coords, heading)
    if processingTables[tableId] then
        print('[mnc-vapes] Table ' .. tableId .. ' already exists, skipping creation')
        return processingTables[tableId].object
    end

    -- ─── Choose correct model based on table type ────────────────────────
    local isVapeTable        = string.find(tableId, '^vape_table_') ~= nil
    local isConcentrateTable = string.find(tableId, '^concentrate_table_') ~= nil

    local modelName
    if isVapeTable then
        modelName = Config.VapeTableProp or 'h4_prop_h4_table_isl_01a'
    elseif isConcentrateTable then
        modelName = Config.ConcentrateTableProp or 'v_ret_ml_tablea'
    else
        modelName = Config.TableProp or 'v_ret_ml_tablea'
    end

    local model = GetHashKey(modelName)

    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end

    if not HasModelLoaded(model) then
        print(('[mnc-vapes] ERROR: Failed to load table model "%s" for %s'):format(modelName, tableId))
        return nil
    end

    local obj = CreateObject(model,
        coords.x, coords.y, coords.z - 1.0,
        false, false, false)

    if not DoesEntityExist(obj) then
        print('[mnc-vapes] ERROR: Failed to create table object for ' .. tableId)
        return nil
    end

    SetEntityHeading(obj, heading or 0.0)
    FreezeEntityPosition(obj, true)
    PlaceObjectOnGroundProperly(obj)
    SetEntityAsMissionEntity(obj, true, true)
    SetModelAsNoLongerNeeded(model)

    processingTables[tableId] = {
        object  = obj,
        coords  = coords,
        tableId = tableId,
    }

    -- ─── qb-target setup ────────────────────────────────────────────────
    local label = isVapeTable and 'Craft Vapes'
        or isConcentrateTable and 'Craft Concentrates'
        or 'Craft Juice'
    local icon = isVapeTable and 'fas fa-tools'
        or isConcentrateTable and 'fas fa-mortar-pestle'
        or 'fas fa-flask'

    exports['qb-target']:AddTargetEntity(obj, {
        options = {
            {
                type    = 'client',
                event   = 'mnc-vapes:client:openCraftingMenu',
                icon    = icon,
                label   = label,
                tableId = tableId,
            },
            {
                type    = 'client',
                event   = 'mnc-vapes:client:pickupTablePrompt',
                icon    = 'fas fa-hand-paper',
                label   = 'Pick Up Table',
                tableId = tableId,
            },
        },
        distance = isVapeTable and (Config.VapeTablePickupDistance or 2.2)
            or isConcentrateTable and (Config.ConcentrateTablePickupDistance or 2.2)
            or (Config.TablePickupDistance or 2.2),
    })

    print(('[mnc-vapes] Created portable table: %s → %s (Entity: %s)'):format(
        tableId, modelName, obj
    ))

    return obj
end

-- ─────────────────────────────────────────────────────────────
--  Aggressive prop removal
-- ─────────────────────────────────────────────────────────────

local function ForceRemoveTableProp(tableId)
    local tableData = processingTables[tableId]
    if not tableData then
        print('[mnc-vapes] Table ' .. tableId .. ' not found in local table')
        return
    end

    local entity = tableData.object
    print('[mnc-vapes] Attempting to remove table ' .. tableId .. ' (Entity: ' .. entity .. ')')

    if DoesEntityExist(entity) then
        pcall(function()
            exports['qb-target']:RemoveTargetEntity(entity)
        end)
    end

    for i = 1, 5 do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
            Wait(50)
        else
            break
        end
    end

    if DoesEntityExist(entity) then
        print('[mnc-vapes] WARNING: Could not delete entity ' .. entity .. ' for table ' .. tableId)
    end

    processingTables[tableId] = nil
end

-- ─────────────────────────────────────────────────────────────
--  PLACE TABLE
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:placeTableNet', function(tableType)
    local ped     = PlayerPedId()
    local coords  = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.5, 0.0)
    local heading = GetEntityHeading(ped)

    RequestAnimDict('anim@narcotics@trash')
    while not HasAnimDictLoaded('anim@narcotics@trash') do Wait(10) end
    TaskPlayAnim(ped, 'anim@narcotics@trash', 'drop_front', 8.0, -8.0, -1, 1, 0, false, false, false)

    local success = ShowProgress(5000, 'Placing table...', true)
    ClearPedTasks(ped)

    if not success then
        Notify('Table placement cancelled.', 'error')
        TriggerServerEvent('mnc-vapes:server:refundTable', tableType)
        return
    end

    TriggerServerEvent('mnc-vapes:server:placeTable', coords, heading, tableType)
end)

-- ─────────────────────────────────────────────────────────────
--  RECEIVE TABLE FROM SERVER
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:createTable', function(tableId, coords, heading)
    CreatePortableTable(tableId, coords, heading)
    Notify('Table placed! Use 3rd eye to interact.', 'success')
end)

-- ─────────────────────────────────────────────────────────────
--  PICKUP TABLE
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:pickupTablePrompt', function(data)
    local tableId   = data and data.tableId
    local tableData = tableId and processingTables[tableId]

    if not tableData then
        Notify('Table not found.', 'error'); return
    end

    local ped = PlayerPedId()

    RequestAnimDict('pickup_object')
    while not HasAnimDictLoaded('pickup_object') do Wait(10) end
    TaskPlayAnim(ped, 'pickup_object', 'pickup_low', 8.0, -8.0, -1, 1, 0, false, false, false)

    local success = ShowProgress(3000, 'Picking up table...', true)
    ClearPedTasks(ped)

    if not success then
        Notify('Pickup cancelled.', 'error'); return
    end

    TriggerServerEvent('mnc-vapes:server:pickupTable', tableId)
end)

-- ─────────────────────────────────────────────────────────────
--  FORCE REMOVE TABLE
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:forceRemoveTable', function(tableId)
    print('[mnc-vapes] Received forceRemoveTable for: ' .. tostring(tableId))
    ForceRemoveTableProp(tableId)
end)

-- ─────────────────────────────────────────────────────────────
--  LOAD EXISTING TABLES ON SPAWN
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:loadTables', function(tables)
    print('[mnc-vapes] Loading ' .. #tables .. ' portable tables...')
    for _, info in ipairs(tables) do
        local coords = vector3(info.x, info.y, info.z)
        CreatePortableTable(info.table_id, coords, info.heading)
    end
    print('[mnc-vapes] Finished loading portable tables')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    print('[mnc-vapes] Player loaded, requesting tables from server...')
    TriggerServerEvent('mnc-vapes:server:requestTables')
end)

CreateThread(function()
    Wait(3000)
    if LocalPlayer.state.isLoggedIn then
        print('[mnc-vapes] Resource started while in-game, requesting tables...')
        TriggerServerEvent('mnc-vapes:server:requestTables')
    end
end)

-- ─────────────────────────────────────────────────────────────
--  Progress bar event
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:startProgress', function(label, duration, animDict, animName)
    local ped = PlayerPedId()

    if animDict and animName then
        RequestAnimDict(animDict)
        local t = 0
        while not HasAnimDictLoaded(animDict) do
            Wait(10); t = t + 10
            if t > 3000 then break end
        end
        if HasAnimDictLoaded(animDict) then
            TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end

    ShowProgress(duration, label, false)

    if animDict then ClearPedTasks(ped) end
end)

-- ─────────────────────────────────────────────────────────────
--  OPEN CRAFTING MENU (routes to juice / vape / concentrate)
-- ─────────────────────────────────────────────────────────────

AddEventHandler('mnc-vapes:client:openCraftingMenu', function(data)
    local tableId            = data and data.tableId
    local isVapeStation      = data.isVape
    local isConcentrateStation = data.isConcentrate
    local isVapeTable        = tableId and string.find(tableId, '^vape_table_')
    local isConcentrateTable = tableId and string.find(tableId, '^concentrate_table_')

    if isVapeStation or isVapeTable then
        TriggerServerEvent('mnc-vapes:server:getCraftableVapeRecipes')
    elseif isConcentrateStation or isConcentrateTable then
        TriggerServerEvent('mnc-vapes:server:getCraftableConcentrateRecipes')
    else
        TriggerServerEvent('mnc-vapes:server:getCraftableRecipes')
    end
end)

-- ─────────────────────────────────────────────────────────────
--  JUICE CRAFTING MENU
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:showCraftingMenu', function(craftableRecipes)
    if not craftableRecipes or #craftableRecipes == 0 then
        Notify('No recipes available.', 'error'); return
    end

    local options = {}
    for _, recipe in ipairs(craftableRecipes) do
        local jCfg   = Config.VapeJuices[recipe.result]
        local label  = jCfg and jCfg.label or recipe.result

        local ingList = {}
        for _, ing in ipairs(recipe.ingredients) do
            table.insert(ingList, string.format('%s x%d', ing.item, ing.amount))
        end
        local ingStr = table.concat(ingList, ', ')

        table.insert(options, {
            title       = label,
            description = (recipe.canCraft and '✅ Ready – ' or '❌ Missing – ') .. ingStr,
            icon        = 'flask-vial',
            disabled    = not recipe.canCraft,
            onSelect    = function()
                local confirmed = exports.ox_lib:alertDialog({
                    header   = 'Craft ' .. label,
                    content  = 'Use: ' .. ingStr .. '?',
                    centered = true,
                    cancel   = true,
                })
                if confirmed == 'confirm' then
                    TriggerServerEvent('mnc-vapes:server:craftJuice', recipe.result)
                end
            end,
        })
    end

    if #options == 0 then Notify('No recipes available.', 'error'); return end

    exports.ox_lib:registerContext({
        id      = 'mnc_crafting_menu',
        title   = '🧪 Juice Lab',
        options = options,
    })
    exports.ox_lib:showContext('mnc_crafting_menu')
end)

-- ─────────────────────────────────────────────────────────────
--  VAPE DEVICE / PARTS CRAFTING MENU
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:showVapeCraftingMenu', function(craftableRecipes)
    if not craftableRecipes or #craftableRecipes == 0 then
        Notify('No vape recipes available.', 'error'); return
    end

    local options = {}
    for _, recipe in ipairs(craftableRecipes) do
        local itemLabel = QBCore.Shared.Items[recipe.result] and QBCore.Shared.Items[recipe.result]["label"] or recipe.result

        local ingList = {}
        for _, ing in ipairs(recipe.ingredients) do
            table.insert(ingList, string.format('%s x%d', ing.item, ing.amount))
        end
        local ingStr = table.concat(ingList, ', ')

        table.insert(options, {
            title       = itemLabel,
            description = (recipe.canCraft and '✅ Ready – ' or '❌ Missing – ') .. ingStr,
            icon        = 'fas fa-tools',
            disabled    = not recipe.canCraft,
            onSelect    = function()
                local confirmed = exports.ox_lib:alertDialog({
                    header   = 'Craft ' .. itemLabel,
                    content  = 'Use: ' .. ingStr .. '?',
                    centered = true,
                    cancel   = true,
                })
                if confirmed == 'confirm' then
                    TriggerServerEvent('mnc-vapes:server:craftVape', recipe.result)
                end
            end,
        })
    end

    if #options == 0 then Notify('No vape recipes available.', 'error'); return end

    exports.ox_lib:registerContext({
        id      = 'mnc_vape_crafting_menu',
        title   = '🔧 Vape Assembly Lab',
        options = options,
    })
    exports.ox_lib:showContext('mnc_vape_crafting_menu')
end)

-- ─────────────────────────────────────────────────────────────
--  CONCENTRATE CRAFTING MENU
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:client:showConcentrateCraftingMenu', function(craftableRecipes)
    if not craftableRecipes or #craftableRecipes == 0 then
        Notify('No concentrate recipes available.', 'error'); return
    end

    local options = {}
    for _, recipe in ipairs(craftableRecipes) do
        local itemLabel = QBCore.Shared.Items[recipe.result] and QBCore.Shared.Items[recipe.result]["label"] or recipe.result

        local ingList = {}
        for _, ing in ipairs(recipe.ingredients) do
            table.insert(ingList, string.format('%s x%d', ing.item, ing.amount))
        end
        local ingStr = table.concat(ingList, ', ')

        table.insert(options, {
            title       = itemLabel,
            description = (recipe.canCraft and '✅ Ready – ' or '❌ Missing – ') .. ingStr,
            icon        = 'mortar-pestle',
            disabled    = not recipe.canCraft,
            onSelect    = function()
                local confirmed = exports.ox_lib:alertDialog({
                    header   = 'Craft ' .. itemLabel,
                    content  = 'Use: ' .. ingStr .. '?',
                    centered = true,
                    cancel   = true,
                })
                if confirmed == 'confirm' then
                    TriggerServerEvent('mnc-vapes:server:craftConcentrate', recipe.result)
                end
            end,
        })
    end

    if #options == 0 then Notify('No concentrate recipes available.', 'error'); return end

    exports.ox_lib:registerContext({
        id      = 'mnc_concentrate_crafting_menu',
        title   = '🧫 Concentrate Lab',
        options = options,
    })
    exports.ox_lib:showContext('mnc_concentrate_crafting_menu')
end)

-- ─────────────────────────────────────────────────────────────
--  Cleanup on resource stop
-- ─────────────────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, obj in ipairs(craftingStationProps) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    craftingStationProps = {}

    for _, obj in ipairs(vapeStationProps) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    vapeStationProps = {}

    for _, obj in ipairs(concentrateStationProps) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    concentrateStationProps = {}

    print('[mnc-vapes] Cleaning up portable tables on resource stop...')
    for tableId, info in pairs(processingTables) do
        if DoesEntityExist(info.object) then
            pcall(function()
                exports['qb-target']:RemoveTargetEntity(info.object)
            end)
            DeleteEntity(info.object)
        end
    end
    processingTables = {}
    print('[mnc-vapes] Cleanup complete')
end)