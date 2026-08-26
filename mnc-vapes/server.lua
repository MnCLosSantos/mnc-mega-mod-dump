-- server.lua  (mnc-vapes)
-- SQL-backed via oxmysql. INSERT ON DUPLICATE KEY UPDATE for all saves.
-- In-memory Lua cache is the authoritative same-tick source of truth.
-- Crafting logic lives in crafting_server.lua (loaded after this file).

local QBCore = exports['qb-core']:GetCoreObject()

-- ─────────────────────────────────────────────────────────────
--  Auto-create tables on start
-- ─────────────────────────────────────────────────────────────

CreateThread(function()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `mnc_vape_data` (
            `vape_id`     VARCHAR(64)   NOT NULL,
            `citizenid`   VARCHAR(50)   NOT NULL,
            `item_name`   VARCHAR(100)  NOT NULL,
            `slot`        INT           NOT NULL,
            `battery`     INT           NOT NULL DEFAULT 0,
            `juice_ml`    FLOAT         NOT NULL DEFAULT 0,
            `flavor`      VARCHAR(100)  DEFAULT NULL,
            `has_coil`    TINYINT(1)    NOT NULL DEFAULT 0,
            `coil_puffs`  INT           NOT NULL DEFAULT 0,
            `tank`        VARCHAR(100)  DEFAULT NULL,
            `updated_at`  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`vape_id`),
            KEY `idx_citizen_slot` (`citizenid`, `slot`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `mnc_juice_data` (
            `liquid_id`    VARCHAR(64)  NOT NULL,
            `citizenid`    VARCHAR(50)  NOT NULL,
            `item_name`    VARCHAR(100) NOT NULL,
            `slot`         INT          NOT NULL,
            `remaining_ml` FLOAT        NOT NULL DEFAULT 0,
            `updated_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`liquid_id`),
            KEY `idx_citizen_slot` (`citizenid`, `slot`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    print("^2[mnc-vapes]^7 Database tables checked/created successfully!")
end)

-- ─────────────────────────────────────────────────────────────
--  In-memory cache
--  vapeCache[src][slot]  = { vapeId, itemName, battery, juice_ml,
--                             flavor, has_coil, coil_puffs, tank }
--  juiceCache[src][slot] = { liquidId, itemName, remaining_ml }
-- ─────────────────────────────────────────────────────────────

local vapeCache  = {}
local juiceCache = {}

-- ─────────────────────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────────────────────

local function Notify(src, msg, typ)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Vapes', description = msg, type = typ or 'inform' })
end

local function DebugPrint(msg)
    if Config.DebugMode then print('[mnc-vapes][SERVER] ' .. tostring(msg)) end
end

local function GenerateId()
    local t = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(t, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function GetPlayer(src)    return QBCore.Functions.GetPlayer(src) end
local function GetCitizenId(src)
    local P = GetPlayer(src)
    return P and P.PlayerData.citizenid or nil
end

local function GetItemBySlot(src, slot)
    local P = GetPlayer(src)
    if not P then return nil end
    for _, item in pairs(P.PlayerData.items) do
        if item and item.slot == slot then return item end
    end
    return nil
end

local function FindItemSlotByName(src, name)
    local P = GetPlayer(src)
    if not P then return nil end
    for _, item in pairs(P.PlayerData.items) do
        if item and item.name == name then return item.slot end
    end
    return nil
end

-- Find an item by name, skipping a specific slot (so we don't pick the vape itself
-- when looking for a coil/tank stored at a different slot)
local function FindItemSlotByNameExcluding(src, name, excludeSlot)
    local P = GetPlayer(src)
    if not P then return nil end
    for _, item in pairs(P.PlayerData.items) do
        if item and item.name == name and item.slot ~= excludeSlot then return item.slot end
    end
    return nil
end

-- ─────────────────────────────────────────────────────────────
--  Description builders
-- ─────────────────────────────────────────────────────────────

local function FormatJuiceDesc(juiceName, remainingMl)
    local jCfg = Config.VapeJuices[juiceName]
    if not jCfg then return '' end
    local pct   = jCfg.ml > 0 and math.floor((remainingMl / jCfg.ml) * 100) or 0
    local puffs = math.floor(remainingMl * Config.PuffsPerMl)
    return string.format('%s\n%.1f / %d ml (%d%%)\n~%d puffs',
        jCfg.label, remainingMl, jCfg.ml, pct, puffs)
end

local function FormatVapeDesc(itemName, d)
    local cfg = Config.Vapes[itemName]
    if not cfg then return 'Unknown Vape' end
    local battPct = math.floor(((d.battery or 0) / cfg.maxBattery) * 100)
    local desc    = string.format('🔋 Battery: %d%%  (%d/%d)', battPct, d.battery or 0, cfg.maxBattery)
    local maxCap  = cfg.tankSize or 0
    if cfg.canChangeTank and d.tank and Config.Tanks[d.tank] then
        maxCap = Config.Tanks[d.tank].size
    end
    local juicePct = maxCap > 0 and math.floor(((d.juice_ml or 0) / maxCap) * 100) or 0
    desc = desc .. string.format('\n💧 Juice: %.1f/%.0f ml (%d%%)', d.juice_ml or 0, maxCap, juicePct)
    if d.flavor then
        local jCfg = Config.VapeJuices[d.flavor]
        desc = desc .. string.format('\n🍬 Flavour: %s', jCfg and jCfg.label or d.flavor)
    end
    if cfg.canChangeCoil then
        if d.has_coil then
            local coilMax = cfg.maxCoilPuffs or 1
            local coilPct = math.floor(((d.coil_puffs or 0) / coilMax) * 100)
            desc = desc .. string.format('\n🔩 Coil: %d/%d puffs (%d%%)', d.coil_puffs or 0, coilMax, coilPct)
        else
            desc = desc .. '\n🔩 Coil: Not installed'
        end
        if d.tank and Config.Tanks[d.tank] then
            desc = desc .. string.format('\n🛢️ Tank: %s (%dml)', Config.Tanks[d.tank].label, Config.Tanks[d.tank].size)
        else
            desc = desc .. '\n🛢️ Tank: Not installed'
        end
    elseif d.coil_puffs then
        local coilMax = cfg.maxCoilPuffs or 1
        local coilPct = math.floor(((d.coil_puffs or 0) / coilMax) * 100)
        desc = desc .. string.format('\n🔩 Coil: %d/%d puffs (%d%%)', d.coil_puffs or 0, coilMax, coilPct)
    end
    if d.vapeId then desc = desc .. string.format('\n🆔 ID: %s', string.sub(d.vapeId, 1, 8)) end
    return desc
end

-- ─────────────────────────────────────────────────────────────
--  Default data
-- ─────────────────────────────────────────────────────────────

local function DefaultVapeData(itemName, existingId)
    local cfg = Config.Vapes[itemName]
    if not cfg then return nil end
    -- All vapes start empty. dispo_vape/weed_pen have a permanent built-in coil
    -- (canChangeCoil = false) so has_coil is true from birth, but juice_ml = 0
    -- so the player must fill them before use, same as a box_vape.
    return {
        vapeId     = existingId or GenerateId(),
        itemName   = itemName,
        battery    = cfg.maxBattery,
        juice_ml   = 0,
        flavor     = nil,
        has_coil   = not cfg.canChangeCoil,
        coil_puffs = not cfg.canChangeCoil and (cfg.maxCoilPuffs or 0) or 0,
        tank       = nil,
    }
end

local function DefaultJuiceData(juiceName, existingId)
    local jCfg = Config.VapeJuices[juiceName]
    if not jCfg then return nil end
    return {
        liquidId     = existingId or GenerateId(),
        itemName     = juiceName,
        remaining_ml = jCfg.ml,
    }
end

-- ─────────────────────────────────────────────────────────────
--  SQL save helpers  (INSERT … ON DUPLICATE KEY UPDATE)
-- ─────────────────────────────────────────────────────────────

local function SaveVapeToDB(cid, slot, d)
    exports.oxmysql:execute([[
        INSERT INTO mnc_vape_data
            (vape_id, citizenid, item_name, slot, battery, juice_ml, flavor, has_coil, coil_puffs, tank)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            citizenid  = VALUES(citizenid),
            item_name  = VALUES(item_name),
            slot       = VALUES(slot),
            battery    = VALUES(battery),
            juice_ml   = VALUES(juice_ml),
            flavor     = VALUES(flavor),
            has_coil   = VALUES(has_coil),
            coil_puffs = VALUES(coil_puffs),
            tank       = VALUES(tank)
    ]], {
        d.vapeId, cid, d.itemName, slot,
        d.battery or 0, d.juice_ml or 0, d.flavor or nil,
        d.has_coil and 1 or 0, d.coil_puffs or 0, d.tank or nil,
    })
end

local function SaveJuiceToDB(cid, slot, d)
    exports.oxmysql:execute([[
        INSERT INTO mnc_juice_data
            (liquid_id, citizenid, item_name, slot, remaining_ml)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            citizenid    = VALUES(citizenid),
            item_name    = VALUES(item_name),
            slot         = VALUES(slot),
            remaining_ml = VALUES(remaining_ml)
    ]], { d.liquidId, cid, d.itemName, slot, d.remaining_ml or 0 })
end

local function DeleteJuiceFromDB(liquidId)
    if liquidId then
        exports.oxmysql:execute('DELETE FROM mnc_juice_data WHERE liquid_id = ?', { liquidId })
    end
end

local function DeleteVapeFromDB(vapeId)
    if vapeId then
        exports.oxmysql:execute('DELETE FROM mnc_vape_data WHERE vape_id = ?', { vapeId })
    end
end

local function DeleteVapeRowByCitizenSlot(cid, slot, itemName)
    exports.oxmysql:execute(
        'DELETE FROM mnc_vape_data WHERE citizenid = ? AND slot = ? AND item_name = ?',
        { cid, slot, itemName }
    )
end

-- ─────────────────────────────────────────────────────────────
--  Push description to qb-inventory UI
-- ─────────────────────────────────────────────────────────────

local function PushDesc(src, slot, description)
    if not description then return end
    pcall(function()
        exports['qb-inventory']:SetItemData(src, slot, 'info', { description = description })
        exports['qb-inventory']:SetItemData(src, slot, 'description', description)
    end)
    TriggerClientEvent('qb-inventory:client:refreshInventory', src)
end

-- ─────────────────────────────────────────────────────────────
--  Cache-backed GetVapeData / SaveVapeData
-- ─────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────
--  Read UUID stored in item metadata (qb-inventory info field)
-- ─────────────────────────────────────────────────────────────

local function GetItemUUID(item, uuidKey)
    -- qb-inventory stores item metadata in item.info (table)
    if item and item.info and type(item.info) == 'table' then
        local id = item.info[uuidKey]
        if id and id ~= '' then return id end
    end
    return nil
end

local function StoreItemUUID(src, slot, uuidKey, uuid)
    -- Write the UUID into the item's info metadata so it survives slot changes
    pcall(function()
        local P = GetPlayer(src)
        if not P then return end
        local item = GetItemBySlot(src, slot)
        if not item then return end
        local info = (type(item.info) == 'table') and item.info or {}
        info[uuidKey] = uuid
        exports['qb-inventory']:SetItemData(src, slot, 'info', info)
    end)
end

local function GetVapeData(src, slot, cb)
    -- Check in-memory cache first, but ONLY if the cached UUID matches the UUID
    -- currently stored in the item's metadata. This prevents stale cache entries
    -- from bleeding onto a different item that lands in the same slot.
    local item = GetItemBySlot(src, slot)
    if vapeCache[src] and vapeCache[src][slot] then
        local cachedUUID  = vapeCache[src][slot].vapeId
        local metaUUID    = item and GetItemUUID(item, 'vape_id')
        -- If the item has a UUID in metadata and it matches the cache, use cache
        if metaUUID and metaUUID == cachedUUID then
            return cb(vapeCache[src][slot])
        end
        -- UUID mismatch or item has no metadata UUID yet — bust the cache entry
        vapeCache[src][slot] = nil
    end

    if not item then item = GetItemBySlot(src, slot) end
    if not item then return cb(nil) end
    local cid = GetCitizenId(src)
    if not cid then return cb(nil) end

    -- Try to get the stable UUID from item metadata
    local storedUUID = GetItemUUID(item, 'vape_id')

    if not storedUUID then
        -- This item has never been stamped with a vape_id. Treat it as a brand
        -- new vape and mint a fresh UUID immediately — do NOT fall back to
        -- matching an old row by citizenid+slot+item_name. Slots get reused by
        -- completely different physical vapes (sold, dropped, moved, re-picked
        -- up), so a slot-based match can silently hand this vape another
        -- vape's old battery/coil/tank/juice history. A fresh UUID guarantees
        -- every vape you carry tracks independently.
        local d = DefaultVapeData(item.name, nil)
        if not d then return cb(nil) end
        SaveVapeToDB(cid, slot, d)
        StoreItemUUID(src, slot, 'vape_id', d.vapeId)
        if not vapeCache[src] then vapeCache[src] = {} end
        vapeCache[src][slot] = d
        PushDesc(src, slot, FormatVapeDesc(d.itemName, d))
        return cb(d)
    end

    exports.oxmysql:fetch('SELECT * FROM mnc_vape_data WHERE vape_id = ? LIMIT 1', { storedUUID }, function(rows)
        local d
        if rows and rows[1] then
            local r = rows[1]
            DebugPrint(string.format(
                'DB LOAD vape_id=%s slot=%d item=%s | has_coil=%s coil_puffs=%s tank=%s battery=%s juice_ml=%s',
                tostring(r.vape_id), slot, tostring(r.item_name),
                tostring(r.has_coil), tostring(r.coil_puffs),
                tostring(r.tank), tostring(r.battery), tostring(r.juice_ml)
            ))
            d = {
                vapeId     = r.vape_id,
                itemName   = r.item_name,
                battery    = r.battery,
                juice_ml   = r.juice_ml,
                flavor     = r.flavor,
                has_coil   = r.has_coil,
                coil_puffs = r.coil_puffs,
                tank       = r.tank,
            }
            -- Keep DB slot column in sync (slot may have changed after relog/move)
            if r.slot ~= slot or r.citizenid ~= cid then
                exports.oxmysql:execute(
                    'UPDATE mnc_vape_data SET slot = ?, citizenid = ? WHERE vape_id = ?',
                    { slot, cid, d.vapeId }
                )
            end
            -- Sanity: tank without coil is impossible
            if d.tank and not d.has_coil then
                DebugPrint(string.format('SANITY FIX: slot=%d has tank=%s but has_coil=false → clearing tank', slot, tostring(d.tank)))
                d.tank = nil; d.juice_ml = 0; d.flavor = nil
                SaveVapeToDB(cid, slot, d)
            end
            -- box_vape: burned-out coil still flagged true
            if item.name == 'box_vape' and d.has_coil and (d.coil_puffs or 0) <= 0 then
                DebugPrint(string.format('SANITY FIX: slot=%d has_coil=true but coil_puffs=%d ≤0 → resetting coil', slot, d.coil_puffs or 0))
                d.has_coil = false; d.coil_puffs = 0
                SaveVapeToDB(cid, slot, d)
            end
        else
            -- Item has a UUID stamped but its DB row is missing (e.g. deleted) —
            -- recreate it, reusing the same UUID so metadata stays consistent.
            d = DefaultVapeData(item.name, storedUUID)
            if not d then return cb(nil) end
            SaveVapeToDB(cid, slot, d)
        end

        if not vapeCache[src] then vapeCache[src] = {} end
        vapeCache[src][slot] = d
        PushDesc(src, slot, FormatVapeDesc(d.itemName, d))
        cb(d)
    end)
end

local function SaveVapeData(src, slot, newData)
    if not newData then return end
    local cid = GetCitizenId(src)
    if not cid then return end
    if not vapeCache[src] then vapeCache[src] = {} end
    vapeCache[src][slot] = newData
    SaveVapeToDB(cid, slot, newData)
    -- Ensure UUID is always in item metadata
    StoreItemUUID(src, slot, 'vape_id', newData.vapeId)
    PushDesc(src, slot, FormatVapeDesc(newData.itemName, newData))
    TriggerClientEvent('mnc-vapes:client:updateMetadata', src, newData)
end

-- ─────────────────────────────────────────────────────────────
--  Cache-backed GetJuiceData / SaveJuiceData
-- ─────────────────────────────────────────────────────────────

local function GetJuiceData(src, slot, cb)
    -- Validate UUID match before trusting the slot cache (same fix as GetVapeData)
    local item = GetItemBySlot(src, slot)
    if juiceCache[src] and juiceCache[src][slot] then
        local cachedUUID = juiceCache[src][slot].liquidId
        local metaUUID   = item and GetItemUUID(item, 'liquid_id')
        if metaUUID and metaUUID == cachedUUID then
            return cb(juiceCache[src][slot])
        end
        juiceCache[src][slot] = nil
    end

    if not item then item = GetItemBySlot(src, slot) end
    if not item then return cb(nil) end
    local cid = GetCitizenId(src)
    if not cid then return cb(nil) end

    local storedUUID = GetItemUUID(item, 'liquid_id')

    if not storedUUID then
        -- Same reasoning as GetVapeData: never trust a slot-based match for an
        -- unstamped bottle. Mint a fresh liquid_id immediately so every bottle
        -- you carry tracks its own remaining_ml independently, instead of
        -- possibly inheriting a different bottle's leftover row from this slot.
        local jd = DefaultJuiceData(item.name, nil)
        if not jd then return cb(nil) end
        SaveJuiceToDB(cid, slot, jd)
        StoreItemUUID(src, slot, 'liquid_id', jd.liquidId)
        if not juiceCache[src] then juiceCache[src] = {} end
        juiceCache[src][slot] = jd
        PushDesc(src, slot, FormatJuiceDesc(jd.itemName, jd.remaining_ml))
        return cb(jd)
    end

    exports.oxmysql:fetch('SELECT * FROM mnc_juice_data WHERE liquid_id = ? LIMIT 1', { storedUUID }, function(rows)
        local jd
        if rows and rows[1] then
            local r = rows[1]
            jd = { liquidId = r.liquid_id, itemName = r.item_name, remaining_ml = r.remaining_ml }
            -- Keep DB slot/citizenid in sync
            if r.slot ~= slot or r.citizenid ~= cid then
                exports.oxmysql:execute(
                    'UPDATE mnc_juice_data SET slot = ?, citizenid = ? WHERE liquid_id = ?',
                    { slot, cid, jd.liquidId }
                )
            end
        else
            -- Item has a UUID stamped but its DB row is missing (e.g. deleted) —
            -- recreate it, reusing the same UUID so metadata stays consistent.
            jd = DefaultJuiceData(item.name, storedUUID)
            if not jd then return cb(nil) end
            SaveJuiceToDB(cid, slot, jd)
        end

        if not juiceCache[src] then juiceCache[src] = {} end
        juiceCache[src][slot] = jd
        PushDesc(src, slot, FormatJuiceDesc(jd.itemName, jd.remaining_ml))
        cb(jd)
    end)
end

local function SaveJuiceData(src, slot, newData)
    if not newData then return end
    local cid = GetCitizenId(src)
    if not cid then return end
    if not juiceCache[src] then juiceCache[src] = {} end
    juiceCache[src][slot] = newData
    SaveJuiceToDB(cid, slot, newData)
    -- Ensure UUID is always in item metadata
    StoreItemUUID(src, slot, 'liquid_id', newData.liquidId)
    PushDesc(src, slot, FormatJuiceDesc(newData.itemName, newData.remaining_ml))
end

-- ─────────────────────────────────────────────────────────────
--  Expose helpers to crafting_server.lua via _G.MncVapes
-- ─────────────────────────────────────────────────────────────

_G.MncVapes = {
    GetPlayer      = GetPlayer,
    GetCitizenId   = GetCitizenId,
    Notify         = Notify,
    DebugPrint     = DebugPrint,
    GenerateId     = GenerateId,
    GetJuiceData   = GetJuiceData,
    SaveJuiceData  = SaveJuiceData,
    GetVapeData    = GetVapeData,
    SaveVapeData   = SaveVapeData,
    FormatJuiceDesc = FormatJuiceDesc,
    PushDesc       = PushDesc,
}

-- ─────────────────────────────────────────────────────────────
--  Stamp UUID when any vape/juice arrives in inventory
--  (covers shop purchases, admin gives, crafting, etc.)
-- ─────────────────────────────────────────────────────────────

AddEventHandler('qb-inventory:server:ItemAdded', function(src, item, slot)
    if not item or not slot then return end
    -- Stamp vape UUID
    if Config.Vapes[item.name] then
        local existing = GetItemUUID(item, 'vape_id')
        if not existing then
            -- Schedule slightly so inventory has settled
            SetTimeout(200, function()
                local P = GetPlayer(src)
                if not P then return end
                local freshItem = GetItemBySlot(src, slot)
                if freshItem and freshItem.name == item.name then
                    local uuid = GetItemUUID(freshItem, 'vape_id')
                    if not uuid then
                        uuid = GenerateId()
                        StoreItemUUID(src, slot, 'vape_id', uuid)
                        DebugPrint(string.format('[stamp] New vape %s slot=%d → uuid=%s', item.name, slot, uuid))
                    end
                end
            end)
        end
    end
    -- Stamp juice UUID
    if Config.VapeJuices[item.name] then
        local existing = GetItemUUID(item, 'liquid_id')
        if not existing then
            SetTimeout(200, function()
                local P = GetPlayer(src)
                if not P then return end
                local freshItem = GetItemBySlot(src, slot)
                if freshItem and freshItem.name == item.name then
                    local uuid = GetItemUUID(freshItem, 'liquid_id')
                    if not uuid then
                        uuid = GenerateId()
                        StoreItemUUID(src, slot, 'liquid_id', uuid)
                        DebugPrint(string.format('[stamp] New juice %s slot=%d → uuid=%s', item.name, slot, uuid))
                    end
                end
            end)
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
--  Player load / unload: clear cache
-- ─────────────────────────────────────────────────────────────

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = player.PlayerData.source
    vapeCache[src]  = nil
    juiceCache[src] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    vapeCache[src]  = nil
    juiceCache[src] = nil
end)

-- ─────────────────────────────────────────────────────────────
--  Use vape
-- ─────────────────────────────────────────────────────────────

for name, _ in pairs(Config.Vapes) do
    QBCore.Functions.CreateUseableItem(name, function(src, item)
        local P = GetPlayer(src)
        if not P then return end
        GetVapeData(src, item.slot, function(d)
            if not d then return end
            -- Ensure UUID is stamped into item metadata before sending to client
            -- so that if the player moves the item to a different slot, the UUID
            -- travels with it and the next GetVapeData call finds the right DB row.
            StoreItemUUID(src, item.slot, 'vape_id', d.vapeId)
            if (d.battery or 0) <= 0 then
                Notify(src, 'Battery dead! Recharge first.', 'error'); return
            end
            TriggerClientEvent('mnc-vapes:client:equipVape', src, item.name, item.slot, d)
        end)
    end)
end

-- ─────────────────────────────────────────────────────────────
--  Use vape charger
-- ─────────────────────────────────────────────────────────────

QBCore.Functions.CreateUseableItem('vape_charger', function(src, item)
    local P = GetPlayer(src)
    if not P then return end

    -- Collect all vape items from inventory
    local vapeItems = {}
    for _, it in pairs(P.PlayerData.items) do
        if it and Config.Vapes[it.name] then
            table.insert(vapeItems, { name = it.name, slot = it.slot })
        end
    end

    if #vapeItems == 0 then
        Notify(src, 'No vapes in inventory.', 'error'); return
    end

    -- Async accumulate with counter
    local vapes    = {}
    local pending  = #vapeItems
    for _, it in ipairs(vapeItems) do
        GetVapeData(src, it.slot, function(d)
            table.insert(vapes, { name = it.name, slot = it.slot, data = d })
            pending = pending - 1
            if pending <= 0 then
                TriggerClientEvent('mnc-vapes:client:openChargerMenu', src, vapes)
            end
        end)
    end
end)

-- ─────────────────────────────────────────────────────────────
--  Charge vape
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:chargeVape', function(itemName, vapeSlot)
    local src = source; local P = GetPlayer(src)
    if not P then return end
    local chargerSlot = FindItemSlotByName(src, 'vape_charger')
    if not chargerSlot then Notify(src, 'No vape charger!', 'error'); return end
    GetVapeData(src, vapeSlot, function(d)
        if not d then return end
        local cfg = Config.Vapes[itemName]
        if not cfg then return end
        if (d.battery or 0) >= cfg.maxBattery then
            Notify(src, 'Battery already full!', 'error'); return
        end
        TriggerClientEvent('mnc-vapes:client:startProgress', src, 'Charging vape...',
            Config.ChargeTime, 'anim@amb@business@weed@weed_inspecting_high_dry@',
            'weed_inspecting_high_base_inspector')
        SetTimeout(Config.ChargeTime, function()
            local P2 = GetPlayer(src)
            if not P2 then return end
            if not P2.Functions.GetItemByName('vape_charger') then
                Notify(src, 'Charger missing!', 'error'); return
            end
            GetVapeData(src, vapeSlot, function(d2)
                if not d2 then return end
                d2.battery = cfg.maxBattery
                SaveVapeData(src, vapeSlot, d2)
                Notify(src, 'Vape charged to 100%!', 'success')
            end)
        end)
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  Open vape menu
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:openVapeMenu', function(itemName, vapeSlot)
    local src = source; local P = GetPlayer(src)
    if not P then return end
    GetVapeData(src, vapeSlot, function(d)
        if not d then return end
        TriggerClientEvent('mnc-vapes:client:openVapeMenu', src, itemName, vapeSlot, d)
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  Open fill menu
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:openFillMenu', function(itemName, vapeSlot)
    local src = source; local P = GetPlayer(src)
    if not P then return end
    GetVapeData(src, vapeSlot, function(d)
        if not d then return end
        local cfg = Config.Vapes[itemName]
        if not cfg then return end
        local maxCap = cfg.tankSize or 0
        if cfg.canChangeTank and d.tank then
            maxCap = Config.Tanks[d.tank].size or maxCap
        end
        if (d.juice_ml or 0) >= maxCap then
            Notify(src, 'Tank is full!', 'error'); return
        end

        -- Collect compatible juice items
        local juiceItems = {}
        for _, item in pairs(P.PlayerData.items) do
            if item and Config.VapeJuices[item.name] and Config.VapeJuices[item.name].type == cfg.juiceType then
                table.insert(juiceItems, { name = item.name, slot = item.slot })
            end
        end

        if #juiceItems == 0 then
            TriggerClientEvent('mnc-vapes:client:showFillMenu', src, itemName, vapeSlot, {})
            return
        end

        -- Async accumulate juice data with counter
        local juices  = {}
        local pending = #juiceItems
        for _, ji in ipairs(juiceItems) do
            GetJuiceData(src, ji.slot, function(jd)
                if jd and (jd.remaining_ml or 0) > 0 then
                    table.insert(juices, { name = ji.name, slot = ji.slot, remaining_ml = jd.remaining_ml, liquidId = jd.liquidId })
                end
                pending = pending - 1
                if pending <= 0 then
                    TriggerClientEvent('mnc-vapes:client:showFillMenu', src, itemName, vapeSlot, juices)
                end
            end)
        end
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  Fill vape
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:fillVape', function(itemName, vapeSlot, juiceName, juiceSlot)
    local src = source; local P = GetPlayer(src)
    if not P then return end
    GetVapeData(src, vapeSlot, function(d)
        if not d then return end
        local cfg = Config.Vapes[itemName]
        if not cfg then return end
        GetJuiceData(src, juiceSlot, function(jd)
            if not jd then return end
            if jd.itemName ~= juiceName then Notify(src, 'Juice mismatch!', 'error'); return end
            if (jd.remaining_ml or 0) <= 0 then Notify(src, 'Bottle empty!', 'error'); return end
            local jCfg = Config.VapeJuices[juiceName]
            if not jCfg or jCfg.type ~= cfg.juiceType then
                Notify(src, 'Incompatible juice type!', 'error'); return
            end
            local maxCap = cfg.tankSize or 0
            if cfg.canChangeTank and d.tank then maxCap = Config.Tanks[d.tank].size or maxCap end
            local space = maxCap - (d.juice_ml or 0)
            if space <= 0 then Notify(src, 'Tank full!', 'error'); return end
            TriggerClientEvent('mnc-vapes:client:startProgress', src, 'Filling vape...',
                Config.FillTime, 'anim@amb@business@weed@weed_inspecting_high_dry@',
                'weed_inspecting_high_base_inspector')
            SetTimeout(Config.FillTime, function()
                local P2 = GetPlayer(src)
                if not P2 then return end
                GetVapeData(src, vapeSlot, function(d2)
                    if not d2 then return end
                    GetJuiceData(src, juiceSlot, function(jd2)
                        if not jd2 then return end
                        local transfer = math.min(maxCap - (d2.juice_ml or 0), jd2.remaining_ml)
                        if transfer <= 0 then return end
                        d2.juice_ml = (d2.juice_ml or 0) + transfer
                        d2.flavor   = juiceName
                        SaveVapeData(src, vapeSlot, d2)
                        jd2.remaining_ml = jd2.remaining_ml - transfer
                        if jd2.remaining_ml <= 0 then
                            P2.Functions.RemoveItem(juiceName, 1, juiceSlot)
                            TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[juiceName], 'remove')
                            DeleteJuiceFromDB(jd2.liquidId)
                            if juiceCache[src] then juiceCache[src][juiceSlot] = nil end
                            if jCfg.emptyBottle then
                                P2.Functions.AddItem(jCfg.emptyBottle, 1)
                                TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[jCfg.emptyBottle], 'add')
                            end
                        else
                            SaveJuiceData(src, juiceSlot, jd2)
                        end
                        Notify(src, string.format('Filled %.1f ml of %s.', transfer, jCfg.label), 'success')
                    end)
                end)
            end)
        end)
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  Record puff
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:recordPuff', function(itemName, vapeSlot)
    local src = source; local P = GetPlayer(src)
    if not P then return end
    GetVapeData(src, vapeSlot, function(d)
        if not d then return end
        local cfg = Config.Vapes[itemName]
        if not cfg then return end
        if (d.battery or 0) <= 0    then Notify(src, 'Battery dead!',    'error'); return end
        if (d.juice_ml or 0) <= 0   then Notify(src, 'Out of juice!',    'error'); return end
        if not d.has_coil and cfg.canChangeCoil then Notify(src, 'No coil!', 'error'); return end
        if (d.coil_puffs or 0) <= 0 then Notify(src, 'Coil burned out!', 'error'); return end
        d.battery    = math.max(0, d.battery - 1)
        d.juice_ml   = math.max(0, d.juice_ml - cfg.mlPerPuff)
        if d.juice_ml <= 0 then d.flavor = nil end
        d.coil_puffs = math.max(0, (d.coil_puffs or 0) - 1)
        if d.coil_puffs <= 0 then d.has_coil = false end
        SaveVapeData(src, vapeSlot, d)
        local jCfg = d.flavor and Config.VapeJuices[d.flavor]
        TriggerClientEvent('mnc-vapes:client:playExhaleEffect', src, jCfg and jCfg.effects, cfg.exhaleTime)
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  Install coil
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:installCoil', function(itemName, vapeSlot)
    local src = source; local P = GetPlayer(src)
    if not P then return end
    GetVapeData(src, vapeSlot, function(d)
        if not d then return end
        if d.has_coil then Notify(src, 'Coil already installed!', 'error'); return end
        local coilSlot = FindItemSlotByNameExcluding(src, 'vape_coil', vapeSlot)
        if not coilSlot then Notify(src, 'No vape coil!', 'error'); return end
        TriggerClientEvent('mnc-vapes:client:startProgress', src, 'Installing coil...',
            Config.CoilInstallTime, 'amb@prop_human_parking_meter@male@idle_a', 'idle_a')
        SetTimeout(Config.CoilInstallTime, function()
            local P2 = GetPlayer(src)
            if not P2 then return end
            local coilItem2 = GetItemBySlot(src, coilSlot)
            if not coilItem2 or coilItem2.name ~= 'vape_coil' then
                Notify(src, 'Coil item not found!', 'error'); return
            end
            GetVapeData(src, vapeSlot, function(d2)
                if not d2 then return end
                local cid = GetCitizenId(src)
                -- Look up the coil's saved puffs by its UUID (slot-independent)
                -- Fall back to citizenid+slot only if no UUID is stamped yet
                local coilUUID = GetItemUUID(coilItem2, 'vape_id')
                local coilQuery, coilParams
                if coilUUID then
                    coilQuery  = 'SELECT coil_puffs FROM mnc_vape_data WHERE vape_id = ? LIMIT 1'
                    coilParams = { coilUUID }
                else
                    coilQuery  = 'SELECT coil_puffs FROM mnc_vape_data WHERE citizenid = ? AND slot = ? AND item_name = ? LIMIT 1'
                    coilParams = { cid, coilSlot, 'vape_coil' }
                end
                exports.oxmysql:fetch(coilQuery, coilParams, function(rows)
                        local coilPuffs = (rows and rows[1] and rows[1].coil_puffs) or Config.Vapes[itemName].maxCoilPuffs
                        P2.Functions.RemoveItem('vape_coil', 1, coilSlot)
                        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items['vape_coil'], 'remove')
                        DeleteVapeRowByCitizenSlot(cid, coilSlot, 'vape_coil')
                        if vapeCache[src] then vapeCache[src][coilSlot] = nil end
                        d2.has_coil   = true
                        d2.coil_puffs = coilPuffs
                        SaveVapeData(src, vapeSlot, d2)
                        Notify(src, string.format('Coil installed! %d puffs remaining.', coilPuffs), 'success')
                    end
                )
            end)
        end)
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  Remove coil
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:removeCoil', function(itemName, vapeSlot)
    local src = source; local P = GetPlayer(src)
    if not P then return end
    GetVapeData(src, vapeSlot, function(d)
        if not d then return end
        if not d.has_coil then Notify(src, 'No coil installed!', 'error'); return end
        TriggerClientEvent('mnc-vapes:client:startProgress', src, 'Removing coil...',
            Config.CoilInstallTime, 'amb@prop_human_parking_meter@male@idle_a', 'idle_a')
        SetTimeout(Config.CoilInstallTime, function()
            local P2 = GetPlayer(src)
            if not P2 then return end
            GetVapeData(src, vapeSlot, function(d2)
                if not d2 then return end
                local remaining = d2.coil_puffs or 0
                if remaining > 0 then
                    P2.Functions.AddItem('vape_coil', 1)
                    TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items['vape_coil'], 'add')
                    SetTimeout(250, function()
                        local P3 = GetPlayer(src)
                        if not P3 then return end
                        local coilItem = P3.Functions.GetItemByName('vape_coil')
                        if coilItem and coilItem.slot then
                            local cid = GetCitizenId(src)
                            local coilRow = {
                                vapeId = GenerateId(), itemName = 'vape_coil',
                                battery = 0, juice_ml = 0, flavor = nil,
                                has_coil = false, coil_puffs = remaining, tank = nil,
                            }
                            if not vapeCache[src] then vapeCache[src] = {} end
                            vapeCache[src][coilItem.slot] = coilRow
                            SaveVapeToDB(cid, coilItem.slot, coilRow)
                            PushDesc(src, coilItem.slot, string.format(
                                '🔩 %d/%d puffs remaining', remaining, Config.Vapes[itemName].maxCoilPuffs))
                        end
                    end)
                else
                    Notify(src, 'Old coil was burned out and discarded.', 'inform')
                end
                d2.has_coil   = false
                d2.coil_puffs = 0
                SaveVapeData(src, vapeSlot, d2)
                Notify(src, 'Coil removed.', 'success')
            end)
        end)
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  Open tank menu
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:openTankMenu', function(itemName, vapeSlot)
    local src = source; local P = GetPlayer(src)
    if not P then return end
    GetVapeData(src, vapeSlot, function(d)
        if not d then return end
        DebugPrint(string.format('openTankMenu slot=%s has_coil=%s coil_puffs=%s',
            tostring(vapeSlot), tostring(d.has_coil), tostring(d.coil_puffs)))
        if not d.has_coil then
            Notify(src, 'Install a coil before fitting a tank!', 'error'); return
        end
        local tanks = {}
        for _, item in pairs(P.PlayerData.items) do
            if item and item.name and Config.Tanks[item.name] then
                table.insert(tanks, { name = item.name, slot = item.slot })
            end
        end
        TriggerClientEvent('mnc-vapes:client:showTankMenu', src, itemName, vapeSlot, tanks)
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  Install tank
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:installTank', function(itemName, vapeSlot, tankName, tankSlot)
    local src = source; local P = GetPlayer(src)
    if not P then return end
    GetVapeData(src, vapeSlot, function(d)
        if not d then return end
        if not d.has_coil then Notify(src, 'No coil – fit a coil first!', 'error'); return end
        if d.tank          then Notify(src, 'Remove existing tank first!', 'error'); return end
        TriggerClientEvent('mnc-vapes:client:startProgress', src, 'Installing tank...',
            Config.TankInstallTime, 'amb@prop_human_parking_meter@male@idle_a', 'idle_a')
        SetTimeout(Config.TankInstallTime, function()
            local P2 = GetPlayer(src)
            if not P2 then return end
            local tankItem = GetItemBySlot(src, tankSlot)
            if not tankItem or tankItem.name ~= tankName then
                Notify(src, 'Tank item not found!', 'error'); return
            end
            GetVapeData(src, vapeSlot, function(d2)
                if not d2 then return end
                local cid = GetCitizenId(src)
                -- Look up the tank's saved juice by its UUID (slot-independent)
                local tankItem2    = GetItemBySlot(src, tankSlot)
                local tankUUID     = tankItem2 and GetItemUUID(tankItem2, 'vape_id')
                local tankQuery, tankParams
                if tankUUID then
                    tankQuery  = 'SELECT juice_ml, flavor FROM mnc_vape_data WHERE vape_id = ? LIMIT 1'
                    tankParams = { tankUUID }
                else
                    tankQuery  = 'SELECT juice_ml, flavor FROM mnc_vape_data WHERE citizenid = ? AND slot = ? AND item_name = ? LIMIT 1'
                    tankParams = { cid, tankSlot, tankName }
                end
                exports.oxmysql:fetch(tankQuery, tankParams, function(rows)
                        local savedJuice  = (rows and rows[1] and rows[1].juice_ml) or 0
                        local savedFlavor = (rows and rows[1] and rows[1].flavor) or nil
                        P2.Functions.RemoveItem(tankName, 1, tankSlot)
                        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[tankName], 'remove')
                        DeleteVapeRowByCitizenSlot(cid, tankSlot, tankName)
                        if vapeCache[src] then vapeCache[src][tankSlot] = nil end
                        d2.tank     = tankName
                        d2.juice_ml = savedJuice
                        d2.flavor   = savedFlavor
                        SaveVapeData(src, vapeSlot, d2)
                        Notify(src, Config.Tanks[tankName].label .. ' installed!', 'success')
                    end
                )
            end)
        end)
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  Remove tank
-- ─────────────────────────────────────────────────────────────

RegisterNetEvent('mnc-vapes:server:removeTank', function(itemName, vapeSlot)
    local src = source; local P = GetPlayer(src)
    if not P then return end
    GetVapeData(src, vapeSlot, function(d)
        if not d then return end
        if not d.tank then Notify(src, 'No tank installed!', 'error'); return end
        TriggerClientEvent('mnc-vapes:client:startProgress', src, 'Removing tank...',
            Config.TankInstallTime, 'amb@prop_human_parking_meter@male@idle_a', 'idle_a')
        SetTimeout(Config.TankInstallTime, function()
            local P2 = GetPlayer(src)
            if not P2 then return end
            GetVapeData(src, vapeSlot, function(d2)
                if not d2 then return end
                local oldTank, oldJuice, oldFlavor = d2.tank, d2.juice_ml or 0, d2.flavor
                d2.tank = nil; d2.juice_ml = 0; d2.flavor = nil
                SaveVapeData(src, vapeSlot, d2)
                P2.Functions.AddItem(oldTank, 1)
                TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[oldTank], 'add')
                if oldJuice > 0 then
                    SetTimeout(250, function()
                        local P3 = GetPlayer(src)
                        if not P3 then return end
                        local tankItem = P3.Functions.GetItemByName(oldTank)
                        if tankItem and tankItem.slot then
                            local cid = GetCitizenId(src)
                            local tankRow = {
                                vapeId = GenerateId(), itemName = oldTank,
                                battery = 0, juice_ml = oldJuice, flavor = oldFlavor,
                                has_coil = false, coil_puffs = 0, tank = nil,
                            }
                            if not vapeCache[src] then vapeCache[src] = {} end
                            vapeCache[src][tankItem.slot] = tankRow
                            SaveVapeToDB(cid, tankItem.slot, tankRow)
                            local flavorLabel = oldFlavor and Config.VapeJuices[oldFlavor]
                                                and Config.VapeJuices[oldFlavor].label or 'unknown juice'
                            PushDesc(src, tankItem.slot,
                                string.format('🛢️ Contains %.1f ml of %s', oldJuice, flavorLabel))
                        end
                    end)
                end
                Notify(src, 'Tank removed.', 'success')
            end)
        end)
    end)
end)
























-- Helper to give multiple items + show ItemBox + notify
local function GivePackContents(src, items, packLabel)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    for _, v in ipairs(items) do
        -- Stamp a fresh, per-item UUID at creation time (same pattern crafting
        -- already uses) so every vape/juice from a starter set tracks its own
        -- battery/coil/tank/juice independently from the moment it exists,
        -- instead of relying on the ItemAdded hook or lazy first-use stamping.
        local info = nil
        if Config.Vapes[v.name] then
            info = { vape_id = GenerateId() }
        elseif Config.VapeJuices[v.name] then
            info = { liquid_id = GenerateId() }
        end
        Player.Functions.AddItem(v.name, v.amount, false, info)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[v.name], 'add', v.amount)
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Pack Opened',
        description = 'You received the contents of the ' .. packLabel .. '!',
        type = 'success',
        duration = 4500
    })
end

-- ─────────────────────────────────────────────────────────────
--  Usable Item Registrations
-- ─────────────────────────────────────────────────────────────

CreateThread(function()
    Wait(500)  -- small delay to ensure qb-core is ready

    -- Box Set
    QBCore.Functions.CreateUseableItem('box_set', function(source, item)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        if not Player.Functions.RemoveItem('box_set', 1) then return end
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['box_set'], 'remove', 1)

        TriggerClientEvent('mnc-vapes:client:startProgress', src,
            'Opening Box Mod Set...',
            5000,  -- duration (match your other pack times)
            'amb@prop_human_parking_meter@male@idle_a', 'idle_a'
        )

        SetTimeout(5200, function()
            local contents = {
                { name = 'box_vape',        amount = 1 },
                { name = '5ml_tank',        amount = 1 },
                { name = 'vape_charger',    amount = 1 },
                { name = 'vape_coil',       amount = 3  },   -- "coil_pack_3"
                { name = 'juice_mango_60',  amount = 1 }     -- popular flavor choice: Mango (60ml)
                -- You can swap to: juice_strawberry_60, juice_watermelon_60, etc.
            }
            GivePackContents(src, contents, 'Box Mod Starter Set')
        end)
    end)

    -- Disposable Set
    QBCore.Functions.CreateUseableItem('dispo_set', function(source, item)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        if not Player.Functions.RemoveItem('dispo_set', 1) then return end
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['dispo_set'], 'remove', 1)

        TriggerClientEvent('mnc-vapes:client:startProgress', src,
            'Opening Disposable Set...',
            5000,
            'amb@prop_human_parking_meter@male@idle_a', 'idle_a'
        )

        SetTimeout(5200, function()
            local contents = {
                { name = 'dispo_vape',      amount = 1 },
                { name = 'vape_charger',    amount = 1 },
                { name = 'juice_strawberry_60', amount = 1 }   -- popular choice: Strawberry Ice
            }
            GivePackContents(src, contents, 'Disposable Starter Set')
        end)
    end)

    -- Weed Pen Set
    QBCore.Functions.CreateUseableItem('weed_set', function(source, item)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        if not Player.Functions.RemoveItem('weed_set', 1) then return end
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['weed_set'], 'remove', 1)

        TriggerClientEvent('mnc-vapes:client:startProgress', src,
            'Opening Weed Pen Set...',
            5000,
            'amb@prop_human_parking_meter@male@idle_a', 'idle_a'
        )

        SetTimeout(5200, function()
            local contents = {
                { name = 'weed_pen',        amount = 1 },
                { name = 'vape_charger',    amount = 1 },
                { name = 'juice_blueberry_kush', amount = 1 }   -- cannabis-themed: Blueberry Kush (30ml)
            }
            GivePackContents(src, contents, 'Weed Pen Starter Set')
        end)
    end)

    -- Coil Packs (simple direct give)
    local coilPacks = {
        ['vape_coil_pack_3']  = { amount = 3,  label = '3x Coil Pack' },
        ['vape_coil_pack_6']  = { amount = 6,  label = '6x Coil Pack' },
        ['vape_coil_pack_10'] = { amount = 10, label = '10x Coil Pack' },
    }

    for itemName, data in pairs(coilPacks) do
        QBCore.Functions.CreateUseableItem(itemName, function(source, item)
            local src = source
            local Player = QBCore.Functions.GetPlayer(src)
            if not Player then return end

            if not Player.Functions.RemoveItem(itemName, 1) then return end
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove', 1)

            TriggerClientEvent('mnc-vapes:client:startProgress', src,
                'Opening Coil Pack...',
                3500,
                nil, nil  -- no anim needed, or keep simple
            )

            SetTimeout(3700, function()
                Player.Functions.AddItem('vape_coil', data.amount)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['vape_coil'], 'add', data.amount)

                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Coils Received',
                    description = 'You got ' .. data.amount .. 'x Vape Coil!',
                    type = 'success',
                    duration = 3500
                })
            end)
        end)
    end
end)