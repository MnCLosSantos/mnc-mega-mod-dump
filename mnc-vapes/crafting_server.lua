-- crafting_server.lua  (mnc-vapes)
-- Handles all juice crafting AND vape device crafting AND concentrate crafting server-side logic.
-- Generalized to support juice_table, vape_table, and concentrate_table via tableId prefix

local QBCore = exports['qb-core']:GetCoreObject()

-- ─────────────────────────────────────────────────────────────
--  In-memory table registry  { [tableId] = { ownerId, x, y, z, heading } }
-- ─────────────────────────────────────────────────────────────

local activeTables = {}

-- ─────────────────────────────────────────────────────────────
--  DB helpers
-- ─────────────────────────────────────────────────────────────

local function SaveTableToDB(tableId, citizenId, coords, heading)
    exports.oxmysql:execute(
        [[INSERT INTO mnc_vapes_tables (table_id, citizen_id, x, y, z, heading)
          VALUES (?, ?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE x = ?, y = ?, z = ?, heading = ?]],
        { tableId, citizenId,
          coords.x, coords.y, coords.z, heading,
          coords.x, coords.y, coords.z, heading }
    )
end

local function RemoveTableFromDB(tableId)
    exports.oxmysql:execute(
        'DELETE FROM mnc_vapes_tables WHERE table_id = ?',
        { tableId }
    )
end

local function GetPlayerTableCount(src, tableType)
    local citizenId = _G.MncVapes.GetCitizenId(src)
    if not citizenId then return 0 end
    local prefix = tableType == 'vape' and 'vape_table_'
        or tableType == 'concentrate' and 'concentrate_table_'
        or 'juice_table_'
    local count = 0
    for tid, _ in pairs(activeTables) do
        if string.find(tid, '^' .. prefix .. citizenId) then
            count = count + 1
        end
    end
    return count
end

local function LoadTablesFromDB(cb)
    exports.oxmysql:fetch(
        'SELECT * FROM mnc_vapes_tables',
        {},
        function(rows) cb(rows or {}) end
    )
end

-- ─────────────────────────────────────────────────────────────
--  PLACE TABLE  (client requests after animation)
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:placeTable', function(coords, heading, tableType)
    local src = source
    local P   = _G.MncVapes.GetPlayer(src)
    if not P then return end

    local itemName = tableType == 'vape' and 'vape_table'
        or tableType == 'concentrate' and 'concentrate_table'
        or 'juice_table'

    local item = P.Functions.GetItemByName(itemName)
    if not item or item.amount < 1 then
        _G.MncVapes.Notify(src, 'You don\'t have a ' .. itemName .. '.', 'error')
        return
    end

    P.Functions.RemoveItem(itemName, 1)
    TriggerClientEvent('inventory:client:ItemBox', src,
        QBCore.Shared.Items[itemName], 'remove')

    local citizenId = _G.MncVapes.GetCitizenId(src)
    local prefix    = tableType == 'vape' and 'vape_table_'
        or tableType == 'concentrate' and 'concentrate_table_'
        or 'juice_table_'
    local tableId   = prefix .. citizenId .. '_' .. os.time()

    activeTables[tableId] = {
        ownerId = src,
        x       = coords.x,
        y       = coords.y,
        z       = coords.z,
        heading = heading,
    }

    SaveTableToDB(tableId, citizenId, coords, heading)

    TriggerClientEvent('mnc-vapes:client:createTable', -1, tableId, coords, heading)

    local count     = GetPlayerTableCount(src, tableType)
    local typeLabel = tableType == 'vape' and 'vape'
        or tableType == 'concentrate' and 'concentrate'
        or 'juice'
    _G.MncVapes.Notify(src, 'Table placed successfully. You have ' .. count .. ' ' .. typeLabel .. ' tables placed.', 'success')

    _G.MncVapes.DebugPrint('[mnc-vapes] Table placed: ' .. tableId .. ' by src ' .. src)
end)

-- ─────────────────────────────────────────────────────────────
--  REFUND TABLE  (placement was cancelled client-side)
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:refundTable', function(tableType)
    local src = source
    local P   = _G.MncVapes.GetPlayer(src)
    if not P then return end
    local itemName = tableType == 'vape' and 'vape_table'
        or tableType == 'concentrate' and 'concentrate_table'
        or 'juice_table'
    P.Functions.AddItem(itemName, 1)
end)

-- ─────────────────────────────────────────────────────────────
--  PICKUP TABLE
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:pickupTable', function(tableId)
    local src = source
    local P   = _G.MncVapes.GetPlayer(src)
    if not P then return end

    if not tableId then
        P.Functions.AddItem('juice_table', 1)
        return
    end

    local tbl = activeTables[tableId]
    if not tbl then
        _G.MncVapes.Notify(src, 'Table not found on server.', 'error')
        return
    end

    local itemName = string.find(tableId, '^vape_table_') and 'vape_table'
        or string.find(tableId, '^concentrate_table_') and 'concentrate_table'
        or 'juice_table'

    P.Functions.AddItem(itemName, 1)
    TriggerClientEvent('inventory:client:ItemBox', src,
        QBCore.Shared.Items[itemName], 'add')

    activeTables[tableId] = nil
    RemoveTableFromDB(tableId)

    TriggerClientEvent('mnc-vapes:client:forceRemoveTable', -1, tableId)

    local tableType = string.find(tableId, '^vape_table_') and 'vape'
        or string.find(tableId, '^concentrate_table_') and 'concentrate'
        or 'juice'
    local count     = GetPlayerTableCount(src, tableType)
    local typeLabel = tableType
    local remainingMsg = (count > 0) and (count .. ' ' .. typeLabel .. ' tables placed.') or 'no ' .. typeLabel .. ' tables placed.'
    _G.MncVapes.Notify(src, 'Table picked up. You have ' .. remainingMsg, 'success')

    _G.MncVapes.DebugPrint('[mnc-vapes] Table picked up: ' .. tableId .. ' by src ' .. src)
end)

-- ─────────────────────────────────────────────────────────────
--  REQUEST TABLES  (client asks for all active tables on load)
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:requestTables', function()
    local src = source
    local tableList = {}
    for tableId, info in pairs(activeTables) do
        table.insert(tableList, {
            table_id = tableId,
            x        = info.x,
            y        = info.y,
            z        = info.z,
            heading  = info.heading,
        })
    end
    TriggerClientEvent('mnc-vapes:client:loadTables', src, tableList)
end)

-- ─────────────────────────────────────────────────────────────
--  Load persisted tables from DB on resource start
-- ─────────────────────────────────────────────────────────────

CreateThread(function()
    Wait(1000)

    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `mnc_vapes_tables` (
            `table_id`   VARCHAR(64)  NOT NULL,
            `citizen_id` VARCHAR(50)  NOT NULL,
            `x`          FLOAT        NOT NULL,
            `y`          FLOAT        NOT NULL,
            `z`          FLOAT        NOT NULL,
            `heading`    FLOAT        NOT NULL DEFAULT 0.0,
            PRIMARY KEY (`table_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    Wait(200)

    LoadTablesFromDB(function(rows)
        for _, row in ipairs(rows) do
            activeTables[row.table_id] = {
                ownerId = nil,
                x       = row.x,
                y       = row.y,
                z       = row.z,
                heading = row.heading,
            }
        end
        print(('[mnc-vapes] Loaded %d portable tables from DB'):format(#rows))
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  Useable items — portable tables
-- ─────────────────────────────────────────────────────────────

QBCore.Functions.CreateUseableItem('juice_table', function(src, item)
    TriggerClientEvent('mnc-vapes:client:placeTableNet', src, 'juice')
end)

QBCore.Functions.CreateUseableItem('vape_table', function(src, item)
    TriggerClientEvent('mnc-vapes:client:placeTableNet', src, 'vape')
end)

QBCore.Functions.CreateUseableItem('concentrate_table', function(src, item)
    TriggerClientEvent('mnc-vapes:client:placeTableNet', src, 'concentrate')
end)

-- ─────────────────────────────────────────────────────────────
--  JUICE CRAFTING
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:getCraftableRecipes', function()
    local src = source
    local P   = _G.MncVapes.GetPlayer(src)
    if not P then return end

    local results = {}
    for _, recipe in ipairs(Config.CraftingRecipes) do
        local canCraft = true
        for _, ing in ipairs(recipe.ingredients) do
            local item = P.Functions.GetItemByName(ing.item)
            if not item or item.amount < ing.amount then
                canCraft = false; break
            end
        end
        table.insert(results, {
            result      = recipe.result,
            ingredients = recipe.ingredients,
            canCraft    = canCraft,
        })
    end

    TriggerClientEvent('mnc-vapes:client:showCraftingMenu', src, results)
end)

RegisterNetEvent('mnc-vapes:server:craftJuice', function(resultItem)
    local src = source
    local P   = _G.MncVapes.GetPlayer(src)
    if not P then return end

    local recipe = nil
    for _, r in ipairs(Config.CraftingRecipes) do
        if r.result == resultItem then recipe = r; break end
    end
    if not recipe then
        _G.MncVapes.Notify(src, 'Recipe not found.', 'error'); return
    end

    for _, ing in ipairs(recipe.ingredients) do
        local item = P.Functions.GetItemByName(ing.item)
        if not item or item.amount < ing.amount then
            _G.MncVapes.Notify(src, 'Missing: ' .. ing.item, 'error'); return
        end
    end

    TriggerClientEvent('mnc-vapes:client:startProgress', src,
        'Crafting juice...', recipe.time or 10000,
        'amb@prop_human_parking_meter@male@idle_a', 'idle_a')

    SetTimeout(recipe.time or 10000, function()
        local P2 = _G.MncVapes.GetPlayer(src)
        if not P2 then return end

        for _, ing in ipairs(recipe.ingredients) do
            local item = P2.Functions.GetItemByName(ing.item)
            if not item or item.amount < ing.amount then
                _G.MncVapes.Notify(src, 'Items moved during crafting!', 'error'); return
            end
        end

        for _, ing in ipairs(recipe.ingredients) do
            P2.Functions.RemoveItem(ing.item, ing.amount)
        end

        local jCfg    = Config.VapeJuices[resultItem]
        local newUUID = _G.MncVapes.GenerateId()
        P2.Functions.AddItem(resultItem, recipe.amount or 1, false, { liquid_id = newUUID })
        TriggerClientEvent('qb-inventory:client:ItemBox', src,
            QBCore.Shared.Items[resultItem], 'add')

        SetTimeout(300, function()
            local P3 = _G.MncVapes.GetPlayer(src)
            if not P3 then return end
            local newSlot = nil
            for _, it in pairs(P3.PlayerData.items) do
                if it and it.info and type(it.info) == 'table' and it.info.liquid_id == newUUID then
                    newSlot = it.slot; break
                end
            end
            if newSlot then
                _G.MncVapes.GetJuiceData(src, newSlot, function(jd)
                    if jd then
                        _G.MncVapes.PushDesc(src, newSlot,
                            _G.MncVapes.FormatJuiceDesc(jd.itemName, jd.remaining_ml))
                    end
                end)
            end
        end)

        _G.MncVapes.Notify(src,
            string.format('Crafted %dx %s!',
                recipe.amount or 1, jCfg and jCfg.label or resultItem),
            'success')
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  VAPE DEVICE CRAFTING
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:getCraftableVapeRecipes', function()
    local src = source
    local P   = _G.MncVapes.GetPlayer(src)
    if not P then return end

    local results = {}
    for _, recipe in ipairs(Config.VapeCraftingRecipes) do
        local canCraft = true
        for _, ing in ipairs(recipe.ingredients) do
            local item = P.Functions.GetItemByName(ing.item)
            if not item or item.amount < ing.amount then
                canCraft = false; break
            end
        end
        table.insert(results, {
            result      = recipe.result,
            ingredients = recipe.ingredients,
            canCraft    = canCraft,
        })
    end

    TriggerClientEvent('mnc-vapes:client:showVapeCraftingMenu', src, results)
end)

RegisterNetEvent('mnc-vapes:server:craftVape', function(resultItem)
    local src = source
    local P   = _G.MncVapes.GetPlayer(src)
    if not P then return end

    local recipe = nil
    for _, r in ipairs(Config.VapeCraftingRecipes) do
        if r.result == resultItem then recipe = r; break end
    end
    if not recipe then
        _G.MncVapes.Notify(src, 'Recipe not found.', 'error'); return
    end

    for _, ing in ipairs(recipe.ingredients) do
        local item = P.Functions.GetItemByName(ing.item)
        if not item or item.amount < ing.amount then
            _G.MncVapes.Notify(src, 'Missing: ' .. ing.item, 'error'); return
        end
    end

    TriggerClientEvent('mnc-vapes:client:startProgress', src,
        'Assembling vape...', recipe.time or 15000,
        'amb@prop_human_parking_meter@male@idle_a', 'idle_a')

    SetTimeout(recipe.time or 15000, function()
        local P2 = _G.MncVapes.GetPlayer(src)
        if not P2 then return end

        for _, ing in ipairs(recipe.ingredients) do
            local item = P2.Functions.GetItemByName(ing.item)
            if not item or item.amount < ing.amount then
                _G.MncVapes.Notify(src, 'Items moved during crafting!', 'error'); return
            end
        end

        for _, ing in ipairs(recipe.ingredients) do
            P2.Functions.RemoveItem(ing.item, ing.amount)
        end

        local vCfg    = Config.Vapes[resultItem]
        local newUUID = _G.MncVapes.GenerateId()
        P2.Functions.AddItem(resultItem, recipe.amount or 1, false, { vape_id = newUUID })
        TriggerClientEvent('qb-inventory:client:ItemBox', src,
            QBCore.Shared.Items[resultItem], 'add')

        SetTimeout(300, function()
            local P3 = _G.MncVapes.GetPlayer(src)
            if not P3 then return end
            local newSlot = nil
            for _, it in pairs(P3.PlayerData.items) do
                if it and it.info and type(it.info) == 'table' and it.info.vape_id == newUUID then
                    newSlot = it.slot; break
                end
            end
            if newSlot then
                _G.MncVapes.GetVapeData(src, newSlot, function(vd)
                    if vd then
                        _G.MncVapes.PushDesc(src, newSlot,
                            _G.MncVapes.FormatVapeDesc(vd.itemName, vd))
                    end
                end)
            end
        end)

        _G.MncVapes.Notify(src,
            string.format('Crafted %dx %s!',
                recipe.amount or 1, vCfg and vCfg.label or resultItem),
            'success')
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  CONCENTRATE CRAFTING
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:getCraftableConcentrateRecipes', function()
    local src = source
    local P   = _G.MncVapes.GetPlayer(src)
    if not P then return end

    local results = {}
    for _, recipe in ipairs(Config.ConcentrateCraftingRecipes) do
        local canCraft = true
        for _, ing in ipairs(recipe.ingredients) do
            local item = P.Functions.GetItemByName(ing.item)
            if not item or item.amount < ing.amount then
                canCraft = false; break
            end
        end
        table.insert(results, {
            result      = recipe.result,
            ingredients = recipe.ingredients,
            canCraft    = canCraft,
        })
    end

    TriggerClientEvent('mnc-vapes:client:showConcentrateCraftingMenu', src, results)
end)

RegisterNetEvent('mnc-vapes:server:craftConcentrate', function(resultItem)
    local src = source
    local P   = _G.MncVapes.GetPlayer(src)
    if not P then return end

    local recipe = nil
    for _, r in ipairs(Config.ConcentrateCraftingRecipes) do
        if r.result == resultItem then recipe = r; break end
    end
    if not recipe then
        _G.MncVapes.Notify(src, 'Recipe not found.', 'error'); return
    end

    for _, ing in ipairs(recipe.ingredients) do
        local item = P.Functions.GetItemByName(ing.item)
        if not item or item.amount < ing.amount then
            _G.MncVapes.Notify(src, 'Missing: ' .. ing.item, 'error'); return
        end
    end

    TriggerClientEvent('mnc-vapes:client:startProgress', src,
        'Crafting concentrate...', recipe.time or 12000,
        'amb@prop_human_parking_meter@male@idle_a', 'idle_a')

    SetTimeout(recipe.time or 12000, function()
        local P2 = _G.MncVapes.GetPlayer(src)
        if not P2 then return end

        for _, ing in ipairs(recipe.ingredients) do
            local item = P2.Functions.GetItemByName(ing.item)
            if not item or item.amount < ing.amount then
                _G.MncVapes.Notify(src, 'Items moved during crafting!', 'error'); return
            end
        end

        for _, ing in ipairs(recipe.ingredients) do
            P2.Functions.RemoveItem(ing.item, ing.amount)
        end

        local itemLabel = QBCore.Shared.Items[resultItem] and QBCore.Shared.Items[resultItem]['label'] or resultItem
        P2.Functions.AddItem(resultItem, recipe.amount or 1)
        TriggerClientEvent('qb-inventory:client:ItemBox', src,
            QBCore.Shared.Items[resultItem], 'add')

        _G.MncVapes.Notify(src,
            string.format('Crafted %dx %s!', recipe.amount or 1, itemLabel),
            'success')
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  Use juice bottle: display remaining ml (unchanged)
-- ─────────────────────────────────────────────────────────────

for name, _ in pairs(Config.VapeJuices) do
    QBCore.Functions.CreateUseableItem(name, function(src, item)
        _G.MncVapes.GetJuiceData(src, item.slot, function(jd)
            if not jd then return end
            _G.MncVapes.Notify(src,
                string.format('Remaining: %.1f ml', jd.remaining_ml or 0), 'inform')
        end)
    end)
end

print("^2[mnc-vapes]^0 Server-side loaded successfully")