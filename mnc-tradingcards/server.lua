local QBCore = exports['qb-core']:GetCoreObject()

local function DebugPrint(msg)
    if Config.Debug then print('[mnc-tradingcards] ' .. msg) end
end

-- Flatten _ref nested fields back to top level for NUI / client events
local function FlattenCardInfo(info)
    if not info then return nil end
    local ref = info._ref or {}
    return {
        cardid     = ref.cardid     or info.cardid,
        setId      = ref.setId      or info.setId,
        setLabel   = ref.setLabel   or info.setLabel,
        number     = info.number,
        name       = info.name,
        model      = ref.model      or info.model      or '',
        image      = ref.image      or info.image      or '',
        background = ref.background or info.background or '',
        rarity     = info.rarity,
        isMisprint = info.isMisprint or false,
        isDamaged  = info.isDamaged  or false,
        printNum   = info.printNum   or '',
        value      = info.value      or 0,
    }
end

-- ============================================================
--  AUTO-CREATE TABLES
-- ============================================================
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_trading_cards` (
            `id`              varchar(64)  NOT NULL,
            `owner_citizenid` varchar(50)  NOT NULL,
            `set_id`          varchar(50)  NOT NULL,
            `card_number`     int          NOT NULL,
            `rarity`          varchar(20)  NOT NULL,
            `is_misprint`     tinyint(1)   NOT NULL DEFAULT 0,
            `is_damaged`      tinyint(1)   NOT NULL DEFAULT 0,
            `print_num`       varchar(30)  NOT NULL DEFAULT '',
            `card_value`      int          NOT NULL DEFAULT 0,
            `acquired_at`     timestamp    DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_owner` (`owner_citizenid`),
            INDEX `idx_set`   (`set_id`)
        )
    ]], {}, function()
        -- Add new columns to existing installs
        MySQL.query('ALTER TABLE mnc_trading_cards ADD COLUMN IF NOT EXISTS `is_misprint` tinyint(1) NOT NULL DEFAULT 0', {})
        MySQL.query('ALTER TABLE mnc_trading_cards ADD COLUMN IF NOT EXISTS `is_damaged`  tinyint(1) NOT NULL DEFAULT 0', {})
        MySQL.query('ALTER TABLE mnc_trading_cards ADD COLUMN IF NOT EXISTS `print_num`   varchar(30) NOT NULL DEFAULT \'\'', {})
        MySQL.query('ALTER TABLE mnc_trading_cards ADD COLUMN IF NOT EXISTS `card_value`  int NOT NULL DEFAULT 0', {})
        print('^2[mnc-tradingcards]^7 Table `mnc_trading_cards` ready.')
    end)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_binders` (
            `id`              varchar(64) NOT NULL,
            `owner_citizenid` varchar(50) NOT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_owner` (`owner_citizenid`)
        )
    ]], {}, function()
        print('^2[mnc-tradingcards]^7 Table `mnc_binders` ready.')
    end)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_binder_cards` (
            `card_id`         varchar(64)  NOT NULL,
            `binder_id`       varchar(64)  NOT NULL,
            `owner_citizenid` varchar(50)  NOT NULL,
            `set_id`          varchar(50)  NOT NULL,
            `card_number`     int          NOT NULL,
            `rarity`          varchar(20)  NOT NULL,
            `name`            varchar(100) NOT NULL DEFAULT '',
            `model`           varchar(100) NOT NULL DEFAULT '',
            `image`           varchar(500) NOT NULL DEFAULT '',
            `background`      varchar(500) NOT NULL DEFAULT '',
            `set_label`       varchar(100) NOT NULL DEFAULT '',
            `is_misprint`     tinyint(1)   NOT NULL DEFAULT 0,
            `is_damaged`      tinyint(1)   NOT NULL DEFAULT 0,
            `print_num`       varchar(30)  NOT NULL DEFAULT '',
            `card_value`      int          NOT NULL DEFAULT 0,
            `stored_at`       timestamp    DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`card_id`),
            INDEX `idx_binder`  (`binder_id`),
            INDEX `idx_owner`   (`owner_citizenid`)
        )
    ]], {}, function()
        MySQL.query('ALTER TABLE mnc_binder_cards ADD COLUMN IF NOT EXISTS `image`      varchar(500) NOT NULL DEFAULT \'\'', {})
        MySQL.query('ALTER TABLE mnc_binder_cards ADD COLUMN IF NOT EXISTS `background` varchar(500) NOT NULL DEFAULT \'\'', {})
        -- Widen for installs from before URL images were supported
        MySQL.query('ALTER TABLE mnc_binder_cards MODIFY COLUMN `image`      varchar(500) NOT NULL DEFAULT \'\'', {})
        MySQL.query('ALTER TABLE mnc_binder_cards MODIFY COLUMN `background` varchar(500) NOT NULL DEFAULT \'\'', {})
        MySQL.query('ALTER TABLE mnc_binder_cards ADD COLUMN IF NOT EXISTS `is_misprint` tinyint(1) NOT NULL DEFAULT 0', {})
        MySQL.query('ALTER TABLE mnc_binder_cards ADD COLUMN IF NOT EXISTS `is_damaged`  tinyint(1) NOT NULL DEFAULT 0', {})
        MySQL.query('ALTER TABLE mnc_binder_cards ADD COLUMN IF NOT EXISTS `print_num`   varchar(30) NOT NULL DEFAULT \'\'', {})
        MySQL.query('ALTER TABLE mnc_binder_cards ADD COLUMN IF NOT EXISTS `card_value`  int NOT NULL DEFAULT 0', {})
        print('^2[mnc-tradingcards]^7 Table `mnc_binder_cards` ready.')
    end)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_custom_sets` (
            `set_id`     varchar(64)  NOT NULL,
            `label`      varchar(100) NOT NULL,
            `icon`       varchar(60)  NOT NULL DEFAULT '',
            `created_by` varchar(50)  NOT NULL DEFAULT '',
            `created_at` timestamp    DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`set_id`)
        )
    ]], {}, function()
        -- Widen `icon` for existing installs -- FontAwesome class strings
        -- (e.g. "fa-solid fa-car-side") run longer than a plain emoji.
        MySQL.query('ALTER TABLE mnc_custom_sets MODIFY COLUMN `icon` varchar(60) NOT NULL DEFAULT \'\'', {})
        print('^2[mnc-tradingcards]^7 Table `mnc_custom_sets` ready.')
    end)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_custom_set_cards` (
            `id`          int          NOT NULL AUTO_INCREMENT,
            `set_id`      varchar(64)  NOT NULL,
            `card_number` int          NOT NULL,
            `name`        varchar(100) NOT NULL,
            `model`       varchar(100) NOT NULL DEFAULT '',
            `image`       varchar(500) NOT NULL DEFAULT '',
            `background`  varchar(500) NOT NULL DEFAULT '',
            `rarity`      varchar(20)  NOT NULL,
            `card_value`  int          NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`),
            UNIQUE KEY `idx_set_card` (`set_id`, `card_number`),
            INDEX `idx_set` (`set_id`)
        )
    ]], {}, function()
        -- Widen image/background for existing installs -- full URLs run
        -- much longer than a local "images/xyz.png" path.
        MySQL.query('ALTER TABLE mnc_custom_set_cards MODIFY COLUMN `image` varchar(500) NOT NULL DEFAULT \'\'', {})
        MySQL.query('ALTER TABLE mnc_custom_set_cards MODIFY COLUMN `background` varchar(500) NOT NULL DEFAULT \'\'', {})
        print('^2[mnc-tradingcards]^7 Table `mnc_custom_set_cards` ready.')
    end)
end)

-- ============================================================
--  UTILITY: weighted random rarity
-- ============================================================
local function RollRarity(weights)
    local total = 0
    for _, w in pairs(weights) do total = total + w end
    local roll = math.random(1, total)
    local cumulative = 0
    local order = { 'common', 'uncommon', 'rare', 'ultraRare' }
    for _, rarity in ipairs(order) do
        cumulative = cumulative + (weights[rarity] or 0)
        if roll <= cumulative then return rarity end
    end
    return 'common'
end

-- ============================================================
--  UTILITY: pick a random card of a given rarity from all sets
-- ============================================================
local function PickRandomCard(rarity)
    local pool = {}
    for setId, setData in pairs(Config.Sets) do
        for _, card in ipairs(setData.cards) do
            if card.rarity == rarity then
                table.insert(pool, {
                    setId      = setId,
                    setLabel   = setData.label,
                    number     = card.number,
                    name       = card.name,
                    model      = card.model      or '',
                    image      = card.image      or '',
                    background = card.background or (setData.background or ''),
                    rarity     = card.rarity,
                    printNum   = card.printNum   or '',
                    -- per-card value override, else fall back to rarity default
                    value      = card.value or (Config.Rarities[card.rarity] and Config.Rarities[card.rarity].value) or 0,
                })
            end
        end
    end
    if #pool == 0 then return PickRandomCard('common') end
    return pool[math.random(1, #pool)]
end

-- ============================================================
--  UTILITY: generate a unique ID
-- ============================================================
local function GenerateId(prefix)
    return prefix .. '_' .. math.random(1000000, 9999999) .. '_' .. (GetGameTimer() % 100000)
end

-- ============================================================
--  UTILITY: per-card global print counter (setId_cardNumber → count)
--  Loaded from DB on start, incremented each time a card is created.
--  Misprints share the same counter as their base card so their
--  rarity is obvious from the low print number, but are labelled
--  separately so they never occupy a normal set slot.
-- ============================================================
local _printCounters = {}   -- key: "setId_cardNumber"

local function _pcKey(setId, cardNumber)
    return tostring(setId) .. '_' .. tostring(cardNumber)
end

-- Initialise counters from existing DB rows so counts survive restarts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- Small delay to let the CREATE TABLE queries finish first
    SetTimeout(2000, function()
        MySQL.query('SELECT set_id, card_number, COUNT(*) AS cnt FROM mnc_trading_cards GROUP BY set_id, card_number', {}, function(rows)
            if not rows then return end
            for _, row in ipairs(rows) do
                local key = _pcKey(row.set_id, row.card_number)
                _printCounters[key] = (row.cnt or 0)
            end
            -- Also count cards currently stored in binders
            MySQL.query('SELECT set_id, card_number, COUNT(*) AS cnt FROM mnc_binder_cards GROUP BY set_id, card_number', {}, function(brows)
                if not brows then return end
                for _, row in ipairs(brows) do
                    local key = _pcKey(row.set_id, row.card_number)
                    _printCounters[key] = (_printCounters[key] or 0) + (row.cnt or 0)
                end
                DebugPrint('Print counters loaded (' .. #rows .. ' inventory + ' .. #brows .. ' binder entries)')
            end)
        end)
    end)
end)

local function NextPrintNum(setId, cardNumber, setLabel)
    local key = _pcKey(setId, cardNumber)
    _printCounters[key] = (_printCounters[key] or 0) + 1
    local n = _printCounters[key]
    -- Format: #00042 [Set Name]  — set name appended so no two sets share the same print string
    local numStr = tostring(n)
    while #numStr < 5 do numStr = '0' .. numStr end
    local label = setLabel and ('[' .. setLabel .. ']') or ('[' .. tostring(setId) .. ']')
    return '#' .. numStr .. ' ' .. label
end

-- ============================================================
--  UTILITY: resolve card value (misprint / damaged overrides)
-- ============================================================
local function ResolveCardValue(baseValue, isMisprint, isDamaged)
    if isDamaged  then return 0 end
    if isMisprint then return Config.Rarities.misprint and Config.Rarities.misprint.value or baseValue * 2 end
    return baseValue
end

-- ============================================================
--  PENDING PACK CLAIMS
--  Cards are rolled immediately so the reveal screen has something
--  to show, but they are NOT written to SQL or added to the
--  player's inventory at this point. That only happens once the
--  client confirms the reveal screen has actually been dismissed
--  (see 'claimPack' below). This stops cards from showing up in
--  the player's inventory before they've finished the pack-opening
--  animation.
-- ============================================================
local pendingPacks = {} -- citizenid -> { cards = {...} }

local function FinalizePendingPack(citizenid, src)
    local pending = pendingPacks[citizenid]
    if not pending then return 0 end
    pendingPacks[citizenid] = nil

    local Player = (src and QBCore.Functions.GetPlayer(src)) or QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if not Player then return 0 end

    for _, cardInfo in ipairs(pending.cards) do
        MySQL.insert(
            'INSERT INTO mnc_trading_cards (id, owner_citizenid, set_id, card_number, rarity, is_misprint, is_damaged, print_num, card_value) VALUES (?,?,?,?,?,?,?,?,?)',
            { cardInfo.id, citizenid, cardInfo.setId, cardInfo.number, cardInfo.rarity,
              cardInfo.isMisprint and 1 or 0, cardInfo.isDamaged and 1 or 0, cardInfo.printNum, cardInfo.value }
        )

        Player.Functions.AddItem('trading_card', 1, false, {
            -- visible in QB-Core inventory tooltip
            number     = cardInfo.number,
            name       = cardInfo.name,
            rarity     = cardInfo.rarity,
            isMisprint = cardInfo.isMisprint,
            isDamaged  = cardInfo.isDamaged,
            printNum   = cardInfo.printNum,
            value      = cardInfo.value,
            -- nested so QB-Core tooltip does not display these raw fields
            _ref = {
                cardid     = cardInfo.id,
                setId      = cardInfo.setId,
                setLabel   = cardInfo.setLabel,
                model      = cardInfo.model,
                image      = cardInfo.image,
                background = cardInfo.background,
            },
        })

        DebugPrint('Granted card ' .. cardInfo.setId .. ' #' .. cardInfo.number .. ' to ' .. citizenid ..
            ' (' .. cardInfo.rarity .. ') print=' .. cardInfo.printNum)
    end

    DebugPrint('Finalized ' .. #pending.cards .. ' pending card(s) for ' .. citizenid)
    return #pending.cards
end

-- ============================================================
--  OPEN PACK
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:openPack', function(itemName, itemSlot)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local packConfig = Config.Packs[itemName]
    if not packConfig then
        DebugPrint('Unknown pack item: ' .. tostring(itemName))
        return
    end

    local citizenid = Player.PlayerData.citizenid

    -- Safety net: if this player somehow has an unclaimed pack sitting
    -- around (e.g. they disconnected mid-reveal last time), grant it
    -- now so a paid-for pack is never lost before opening a new one.
    if pendingPacks[citizenid] then
        FinalizePendingPack(citizenid, src)
    end

    local removed = Player.Functions.RemoveItem(itemName, 1, itemSlot)
    if not removed then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = "Couldn't open pack.", type = 'error' })
        return
    end

    local droppedCards = {}

    for i = 1, packConfig.cardCount do
        local rarity     = RollRarity(packConfig.weights)
        local cardData   = PickRandomCard(rarity)
        local cardId     = GenerateId('card')

        -- Roll for misprint / damaged
        local mRoll = math.random(1, 100)
        local dRoll = math.random(1, 100)
        local isMisprint = (mRoll <= (packConfig.misprintChance or 0))
        local isDamaged  = (not isMisprint) and (dRoll <= (packConfig.damagedChance or 0))

        -- Effective rarity for display purposes
        local displayRarity = rarity
        if isMisprint then displayRarity = 'misprint' end
        if isDamaged  then displayRarity = 'damaged'  end

        local cardValue = ResolveCardValue(cardData.value, isMisprint, isDamaged)

        -- Sequential print number: every card ever created for this set+number gets the next count.
        -- This makes early prints rare and gives each physical card a unique identity.
        -- Set name is appended so print numbers are globally unique across all sets.
        local printLabel = NextPrintNum(cardData.setId, cardData.number, cardData.setLabel)
        if isMisprint then
            printLabel = printLabel .. ' MISPRINT'
        end
        if isDamaged then
            printLabel = printLabel .. ' (DMG)'
        end

        local cardInfo = {
            id          = cardId,
            cardid      = cardId,
            setId       = cardData.setId,
            setLabel    = cardData.setLabel,
            number      = cardData.number,
            name        = cardData.name,
            model       = cardData.model,
            image       = cardData.image,
            background  = cardData.background,
            rarity      = displayRarity,
            baseRarity  = rarity,
            isMisprint  = isMisprint,
            isDamaged   = isDamaged,
            printNum    = printLabel,
            value       = cardValue,
        }

        table.insert(droppedCards, cardInfo)

        DebugPrint('Player ' .. src .. ' rolled card: ' .. cardData.setId .. ' #' .. cardData.number ..
            ' (' .. displayRarity .. ') print=' .. printLabel .. (isMisprint and ' [MISPRINT]' or '') .. (isDamaged and ' [DAMAGED]' or ''))
    end

    -- Hold the rolled cards until the client confirms the reveal screen
    -- has been closed. A 2-minute fallback timer auto-claims them in
    -- case the NUI never confirms (crash, disconnect, etc.) so cards
    -- the player already paid for are never lost.
    pendingPacks[citizenid] = { cards = droppedCards }
    SetTimeout(120000, function()
        if pendingPacks[citizenid] then
            DebugPrint('Auto-claiming pack for ' .. citizenid .. ' after timeout (reveal never confirmed)')
            FinalizePendingPack(citizenid, nil)
        end
    end)

    TriggerClientEvent('mnc-tradingcards:client:packOpened', src, droppedCards, packConfig.label)
end)

-- ============================================================
--  CLAIM PACK — fired by the client once the reveal screen has
--  actually been dismissed. This is the point the rolled cards are
--  written to SQL and added to the player's inventory.
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:claimPack', function()
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    local count = FinalizePendingPack(citizenid, src)
    if count > 0 then
        DebugPrint('Player ' .. src .. ' claimed ' .. count .. ' card(s) after closing the reveal screen')
    end
end)

-- Flush any pending pack if the player disconnects before closing the
-- reveal screen, so a paid-for pack is never lost.
AddEventHandler('playerDropped', function()
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    FinalizePendingPack(Player.PlayerData.citizenid, src)
end)

-- ============================================================
--  USE CARD (view single card)
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:useCard', function(itemSlot)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local items    = Player.PlayerData.items
    local cardItem = nil

    for slot, item in pairs(items) do
        if item and item.name == 'trading_card' and tostring(slot) == tostring(itemSlot) then
            cardItem = item; break
        end
    end
    if not cardItem then
        for slot, item in pairs(items) do
            if item and item.name == 'trading_card' then cardItem = item; break end
        end
    end

    if not cardItem or not cardItem.info then return end
    TriggerClientEvent('mnc-tradingcards:client:viewCard', src, FlattenCardInfo(cardItem.info))
end)

-- ============================================================
--  DISCARD DAMAGED CARD
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:discardDamaged', function(cardId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local items = Player.PlayerData.items
    local foundSlot = nil
    for slot, item in pairs(items) do
        if item and item.name == 'trading_card' and item.info then
            local ref = item.info._ref or item.info
            if ref.cardid == cardId then
                if item.info.isDamaged then
                    foundSlot = slot; break
                end
            end
        end
    end

    if not foundSlot then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Card not found or not damaged.', type = 'error' })
        return
    end

    Player.Functions.RemoveItem('trading_card', 1, foundSlot)
    MySQL.query('DELETE FROM mnc_trading_cards WHERE id = ? AND owner_citizenid = ?', { cardId, Player.PlayerData.citizenid })

    TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Damaged card discarded.', type = 'info' })
    TriggerClientEvent('mnc-tradingcards:client:cardDiscarded', src, cardId)
    DebugPrint('Player ' .. src .. ' discarded damaged card ' .. cardId)
end)

-- ============================================================
--  USE BINDER — loads binder data from SQL and sends to client
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:useBinder', function(itemSlot)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local items      = Player.PlayerData.items
    local binderItem = nil
    local binderSlot = itemSlot

    for slot, item in pairs(items) do
        if item and item.name == 'card_binder' then
            if tostring(slot) == tostring(itemSlot) or not binderItem then
                binderItem = item; binderSlot = slot
            end
        end
    end
    if not binderItem then return end

    local citizenid = Player.PlayerData.citizenid
    local binderId  = binderItem.info and binderItem.info.binderid

    if not binderId then
        binderId = GenerateId('binder')
        local info = binderItem.info or {}
        info.binderid = binderId
        MySQL.insert('INSERT INTO mnc_binders (id, owner_citizenid) VALUES (?, ?)', { binderId, citizenid })
        Player.Functions.RemoveItem('card_binder', 1, binderSlot)
        Player.Functions.AddItem('card_binder', 1, binderSlot, info)
        DebugPrint('Created new binder ID: ' .. binderId)
    end

    MySQL.query(
        'SELECT * FROM mnc_binder_cards WHERE binder_id = ? AND owner_citizenid = ?',
        { binderId, citizenid },
        function(binderCards)
            binderCards = binderCards or {}

            local inventoryCards = {}
            for slot, item in pairs(Player.PlayerData.items) do
                if item and item.name == 'trading_card' and item.info and (item.info.cardid or (item.info._ref and item.info._ref.cardid)) then
                    local ref = item.info._ref or item.info
                    table.insert(inventoryCards, {
                        slot        = slot,
                        cardid      = ref.cardid,
                        setId       = ref.setId,
                        setLabel    = ref.setLabel,
                        number      = item.info.number,
                        name        = item.info.name,
                        model       = ref.model      or '',
                        image       = ref.image      or '',
                        background  = ref.background or '',
                        rarity      = item.info.rarity,
                        isMisprint  = item.info.isMisprint  or false,
                        isDamaged   = item.info.isDamaged   or false,
                        printNum    = item.info.printNum    or '',
                        value       = item.info.value       or 0,
                    })
                end
            end

            local storedCards = {}
            for _, row in ipairs(binderCards) do
                table.insert(storedCards, {
                    cardid      = row.card_id,
                    setId       = row.set_id,
                    setLabel    = row.set_label,
                    number      = row.card_number,
                    name        = row.name,
                    model       = row.model       or '',
                    image       = row.image       or '',
                    background  = row.background  or '',
                    rarity      = row.rarity,
                    isMisprint  = row.is_misprint == 1,
                    isDamaged   = row.is_damaged  == 1,
                    printNum    = row.print_num   or '',
                    value       = row.card_value  or 0,
                })
            end

            TriggerClientEvent('mnc-tradingcards:client:openBinder', src, {
                binderId       = binderId,
                sets           = Config.Sets,
                rarities       = Config.Rarities,
                storedCards    = storedCards,
                inventoryCards = inventoryCards,
            })
        end
    )
end)

-- ============================================================
--  STORE CARD INTO BINDER
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:storeCardInBinder', function(binderId, cardSlot, cardId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not binderId or not cardId then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Invalid binder or card data.', type = 'error' })
        return
    end

    local citizenid = Player.PlayerData.citizenid

    MySQL.query('SELECT id FROM mnc_binders WHERE id = ? AND owner_citizenid = ?', { binderId, citizenid }, function(rows)
        if not rows or #rows == 0 then
            TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Binder not found.', type = 'error' })
            return
        end

        local items     = Player.PlayerData.items
        local cardItem  = nil
        local foundSlot = nil

        for slot, item in pairs(items) do
            if item and item.name == 'trading_card' and item.info then
                local ref = item.info._ref or item.info
                if ref.cardid == cardId then
                    if tostring(slot) == tostring(cardSlot) then cardItem = item; foundSlot = slot; break end
                end
            end
        end
        if not cardItem then
            for slot, item in pairs(items) do
                if item and item.name == 'trading_card' and item.info then
                    local ref = item.info._ref or item.info
                    if ref.cardid == cardId then
                        cardItem = item; foundSlot = slot; break
                    end
                end
            end
        end

        if not cardItem or not cardItem.info then
            TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Card not found in inventory.', type = 'error' })
            return
        end

        local info = cardItem.info
        local ref  = info._ref or info

        -- Block damaged cards from being stored in a binder
        if info.isDamaged then
            TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Damaged cards cannot be stored in a binder.', type = 'error' })
            return
        end

        MySQL.query('SELECT card_id FROM mnc_binder_cards WHERE card_id = ?', { cardId }, function(existing)
            if existing and #existing > 0 then
                TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Card is already stored in a binder.', type = 'error' })
                return
            end

            local removed = Player.Functions.RemoveItem('trading_card', 1, foundSlot)
            if not removed then
                TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = "Couldn't remove card from inventory.", type = 'error' })
                return
            end

            MySQL.insert(
                'INSERT INTO mnc_binder_cards (card_id, binder_id, owner_citizenid, set_id, card_number, rarity, name, model, image, background, set_label, is_misprint, is_damaged, print_num, card_value) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                {
                    cardId, binderId, citizenid,
                    ref.setId      or '',
                    info.number    or 0,
                    info.rarity    or 'common',
                    info.name      or '',
                    ref.model      or '',
                    ref.image      or '',
                    ref.background or '',
                    ref.setLabel   or '',
                    info.isMisprint and 1 or 0,
                    info.isDamaged  and 1 or 0,
                    info.printNum  or '',
                    info.value     or 0,
                },
                function(insertId)
                    if not insertId then
                        Player.Functions.AddItem('trading_card', 1, false, info)
                        TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Database error — card returned to inventory.', type = 'error' })
                        return
                    end

                    DebugPrint('Card ' .. cardId .. ' stored in binder ' .. binderId)

                    TriggerClientEvent('mnc-tradingcards:client:cardStoredInBinder', src, {
                        cardid      = ref.cardid,
                        setId       = ref.setId,
                        setLabel    = ref.setLabel,
                        number      = info.number,
                        name        = info.name,
                        model       = ref.model      or '',
                        image       = ref.image      or '',
                        background  = ref.background or '',
                        rarity      = info.rarity,
                        isMisprint  = info.isMisprint or false,
                        isDamaged   = info.isDamaged  or false,
                        printNum    = info.printNum   or '',
                        value       = info.value      or 0,
                    })

                    TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = (info.name or 'Card') .. ' stored in binder!', type = 'success' })
                end
            )
        end)
    end)
end)

-- ============================================================
--  REMOVE CARD FROM BINDER
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:removeCardFromBinder', function(binderId, cardId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not binderId or not cardId then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Invalid data.', type = 'error' })
        return
    end

    local citizenid = Player.PlayerData.citizenid

    MySQL.query(
        'SELECT * FROM mnc_binder_cards WHERE card_id = ? AND binder_id = ? AND owner_citizenid = ?',
        { cardId, binderId, citizenid },
        function(rows)
            if not rows or #rows == 0 then
                TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Card not found in binder.', type = 'error' })
                return
            end

            local row = rows[1]

            MySQL.query('DELETE FROM mnc_binder_cards WHERE card_id = ? AND owner_citizenid = ?', { cardId, citizenid }, function(affected)
                if not affected or affected == 0 then
                    TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Could not remove card.', type = 'error' })
                    return
                end

                local info = {
                    -- visible tooltip fields
                    number     = row.card_number,
                    name       = row.name,
                    rarity     = row.rarity,
                    isMisprint = row.is_misprint == 1,
                    isDamaged  = row.is_damaged  == 1,
                    printNum   = row.print_num   or '',
                    value      = row.card_value  or 0,
                    -- nested hidden fields
                    _ref = {
                        cardid     = cardId,
                        setId      = row.set_id,
                        setLabel   = row.set_label,
                        model      = row.model      or '',
                        image      = row.image      or '',
                        background = row.background or '',
                    },
                }

                -- flat copy for client event (NUI expects flat structure)
                local clientInfo = {
                    cardid     = cardId,
                    setId      = row.set_id,
                    setLabel   = row.set_label,
                    number     = row.card_number,
                    name       = row.name,
                    model      = row.model      or '',
                    image      = row.image      or '',
                    background = row.background or '',
                    rarity     = row.rarity,
                    isMisprint = row.is_misprint == 1,
                    isDamaged  = row.is_damaged  == 1,
                    printNum   = row.print_num   or '',
                    value      = row.card_value  or 0,
                }

                Player.Functions.AddItem('trading_card', 1, false, info)
                DebugPrint('Card ' .. cardId .. ' removed from binder and returned to inventory')

                TriggerClientEvent('mnc-tradingcards:client:cardRemovedFromBinder', src, clientInfo)
                TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = (row.name or 'Card') .. ' returned to inventory.', type = 'info' })
            end)
        end
    )
end)

-- ============================================================
--  SHOP — SELL CARDS
--  Accepts a list of { cardid, slot } from the client
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:sellCards', function(cardList)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not cardList or #cardList == 0 then return end

    local citizenid = Player.PlayerData.citizenid
    local multiplier = Config.Shop.sellMultiplier or 0.8
    local totalPay  = 0
    local sold      = 0

    for _, entry in ipairs(cardList) do
        local cardId = entry.cardid
        local items  = Player.PlayerData.items
        local foundSlot = nil
        local cardInfo  = nil

        for slot, item in pairs(items) do
            if item and item.name == 'trading_card' and item.info then
                local ref = item.info._ref or item.info
                if ref.cardid == cardId then
                    foundSlot = slot; cardInfo = item.info; break
                end
            end
        end

        if foundSlot and cardInfo then
            local baseVal = cardInfo.value or 0
            local pay = math.floor(baseVal * multiplier)
            Player.Functions.RemoveItem('trading_card', 1, foundSlot)
            MySQL.query('DELETE FROM mnc_trading_cards WHERE id = ? AND owner_citizenid = ?', { cardId, citizenid })
            totalPay = totalPay + pay
            sold = sold + 1
        end
    end

    if totalPay > 0 then
        Player.Functions.AddMoney('cash', totalPay, 'card-shop-sell')
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title       = 'Card Dealer',
        description = 'Sold ' .. sold .. ' card(s) for $' .. totalPay,
        type        = 'success',
    })
    TriggerClientEvent('mnc-tradingcards:client:sellComplete', src, { sold = sold, total = totalPay })
    DebugPrint('Player ' .. src .. ' sold ' .. sold .. ' cards for $' .. totalPay)
end)

-- ============================================================
--  SHOP — SELL COMPLETE SET (all cards of a setId in inventory)
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:sellSet', function(setId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local setData = Config.Sets[setId]
    if not setData then return end

    local citizenid  = Player.PlayerData.citizenid
    local multiplier = Config.Shop.sellMultiplier or 0.8
    local bonus      = Config.Shop.setCompletionBonus or 1.0
    local items      = Player.PlayerData.items

    local toSell = {}
    local valueSum = 0

    for slot, item in pairs(items) do
        if item and item.name == 'trading_card' and item.info then
            local ref = item.info._ref or item.info
            if ref.setId == setId then
                table.insert(toSell, { slot = slot, info = item.info })
                valueSum = valueSum + (item.info.value or 0)
            end
        end
    end

    if #toSell == 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Card Dealer', description = 'No cards from that set in your inventory.', type = 'error' })
        return
    end

    -- Check if selling a complete set for the bonus
    local ownedNums = {}
    for _, entry in ipairs(toSell) do ownedNums[entry.info.number] = true end
    local isComplete = (#setData.cards == #toSell)  -- rough check; all cards present
    local mult = multiplier * (isComplete and bonus or 1.0)
    local totalPay = math.floor(valueSum * mult)

    for _, entry in ipairs(toSell) do
        Player.Functions.RemoveItem('trading_card', 1, entry.slot)
        local ref = entry.info._ref or entry.info
        MySQL.query('DELETE FROM mnc_trading_cards WHERE id = ? AND owner_citizenid = ?', { ref.cardid, citizenid })
    end

    if totalPay > 0 then
        Player.Functions.AddMoney('cash', totalPay, 'card-shop-sell-set')
    end

    local msg = 'Sold ' .. #toSell .. ' ' .. setData.label .. ' card(s) for $' .. totalPay
    if isComplete then msg = msg .. ' (Complete set bonus!)' end

    TriggerClientEvent('ox_lib:notify', src, { title = 'Card Dealer', description = msg, type = 'success' })
    TriggerClientEvent('mnc-tradingcards:client:sellComplete', src, { sold = #toSell, total = totalPay })
    DebugPrint('Player ' .. src .. ' sold set ' .. setId .. ' for $' .. totalPay)
end)

-- ============================================================
--  USEABLE ITEMS
-- ============================================================
for packName, _ in pairs(Config.Packs) do
    QBCore.Functions.CreateUseableItem(packName, function(source, item)
        local src    = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end
        TriggerClientEvent('mnc-tradingcards:client:startOpenPack', src, item.name, item.slot)
    end)
end

QBCore.Functions.CreateUseableItem('trading_card', function(source, item)
    local src = source
    TriggerClientEvent('mnc-tradingcards:client:startViewCard', src, item.slot, FlattenCardInfo(item.info))
end)

QBCore.Functions.CreateUseableItem('card_binder', function(source, item)
    local src = source
    TriggerClientEvent('mnc-tradingcards:client:startBinder', src, item.slot)
end)

-- ============================================================
--  SHOP — send player's inventory cards to client for shop UI
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:requestShopOpen', function()
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local inventoryCards = {}
    for slot, item in pairs(Player.PlayerData.items) do
        if item and item.name == 'trading_card' and item.info and (item.info._ref or item.info.cardid) then
            local ref = item.info._ref or item.info
            table.insert(inventoryCards, {
                slot       = slot,
                cardid     = ref.cardid,
                setId      = ref.setId,
                setLabel   = ref.setLabel,
                number     = item.info.number,
                name       = item.info.name,
                model      = ref.model      or '',
                image      = ref.image      or '',
                background = ref.background or '',
                rarity     = item.info.rarity,
                isMisprint = item.info.isMisprint  or false,
                isDamaged  = item.info.isDamaged   or false,
                printNum   = item.info.printNum    or '',
                value      = item.info.value       or 0,
            })
        end
    end

    TriggerClientEvent('mnc-tradingcards:client:openShop', src, inventoryCards)
end)

-- ============================================================
--  ADMIN CARD PREVIEW  (/cardpreview)
--  Add this block to your mnc-tradingcards server.lua
-- ============================================================

RegisterNetEvent('mnc-tradingcards:server:requestCardPreview', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Admin / god permission check
    if not QBCore.Functions.HasPermission(src, 'admin')
    and not QBCore.Functions.HasPermission(src, 'god') then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'You do not have permission to use /cardpreview.',
            type        = 'error',
        })
        return
    end

    -- Fire the preview event back to the requesting client only
    TriggerClientEvent('mnc-tradingcards:client:openCardPreview', src)
end)

-- ============================================================
--  CUSTOM CARD SETS  (/cardcreator)
--  Lets admins create and manage extra card sets at runtime without
--  touching config.lua or restarting the resource. Everything is
--  persisted to SQL (mnc_custom_sets / mnc_custom_set_cards) and
--  merged straight into Config.Sets on the server AND on every
--  connected client, so new packs can roll cards from them right
--  away.
--
--  Only sets created through this command can be edited/removed this
--  way -- the sets shipped in config.lua are read-only from chat so a
--  typo here can never damage them. Edit those directly in the file.
-- ============================================================
local customSetIds = {} -- setId -> true, tracks which Config.Sets entries came from SQL

local VALID_CARD_RARITIES = { common = true, uncommon = true, rare = true, ultraRare = true }

-- Only these two background images actually ship with the resource --
-- the Card Creator panel only ever offers these plus "None" (empty).
local VALID_BACKGROUNDS = { [''] = true, ['images/card1back.png'] = true, ['images/card2back.png'] = true }

local function IsCardAdmin(src)
    return QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')
end

local function CustomSetsSnapshot()
    local snapshot = {}
    for setId in pairs(customSetIds) do
        snapshot[setId] = Config.Sets[setId]
    end
    return snapshot
end

local function BroadcastCustomSets()
    TriggerClientEvent('mnc-tradingcards:client:syncCustomSets', -1, CustomSetsSnapshot())
end

-- ============================================================
--  PURGE A SET FROM EVERY PLAYER
--  Called right before a custom set's definition is deleted so nobody
--  is left holding a card (in their inventory, or stored in a binder)
--  that points at a set which no longer exists. Online players get
--  their live inventory cleaned up directly (SQL deletes alone don't
--  touch what QB-Core already has loaded in memory); the SQL deletes
--  then cover offline players' loose cards and everyone's binder-
--  stored copies, since binder storage has no in-memory representation.
-- ============================================================
local function PurgeSetFromPlayers(setId)
    local sources = QBCore.Functions.GetPlayers()
    for _, src2 in ipairs(sources) do
        local Player = QBCore.Functions.GetPlayer(src2)
        if Player then
            local items      = Player.PlayerData.items
            local removedAny = false
            for slot, item in pairs(items) do
                if item and item.name == 'trading_card' and item.info then
                    local ref = item.info._ref or item.info
                    if ref.setId == setId then
                        Player.Functions.RemoveItem('trading_card', 1, slot)
                        removedAny = true
                    end
                end
            end
            if removedAny then
                TriggerClientEvent('ox_lib:notify', src2, {
                    title       = 'Trading Cards',
                    description = 'An admin removed a card set. Any cards you had from it are gone.',
                    type        = 'info',
                })
            end
        end
    end

    -- DB cleanup — offline players' loose inventory records, plus every
    -- binder-stored copy of this set for online AND offline players.
    MySQL.query('DELETE FROM mnc_trading_cards WHERE set_id = ?', { setId })
    MySQL.query('DELETE FROM mnc_binder_cards  WHERE set_id = ?', { setId })

    DebugPrint('Purged set ' .. tostring(setId) .. ' from all players')
end

local function LoadCustomSetsFromDB(cb)
    MySQL.query('SELECT * FROM mnc_custom_sets', {}, function(setRows)
        setRows = setRows or {}
        MySQL.query('SELECT * FROM mnc_custom_set_cards ORDER BY set_id, card_number', {}, function(cardRows)
            cardRows = cardRows or {}

            for _, row in ipairs(setRows) do
                Config.Sets[row.set_id] = { label = row.label, icon = row.icon, cards = {} }
                customSetIds[row.set_id] = true
            end

            for _, row in ipairs(cardRows) do
                local set = Config.Sets[row.set_id]
                if set then
                    table.insert(set.cards, {
                        number     = row.card_number,
                        name       = row.name,
                        model      = row.model      ~= '' and row.model      or nil,
                        image      = row.image      ~= '' and row.image      or nil,
                        background = row.background ~= '' and row.background or nil,
                        rarity     = row.rarity,
                        value      = row.card_value > 0 and row.card_value or nil,
                    })
                end
            end

            DebugPrint('Loaded ' .. #setRows .. ' custom set(s), ' .. #cardRows .. ' custom card(s) from SQL')
            if cb then cb() end
        end)
    end)
end

-- Load custom sets once the tables above have had time to be created
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    SetTimeout(2500, function()
        LoadCustomSetsFromDB(function()
            print('^2[mnc-tradingcards]^7 Custom sets ready (' .. (function() local n=0 for _ in pairs(customSetIds) do n=n+1 end return n end)() .. ' loaded from SQL).')
        end)
    end)
end)

-- A client asks for the current custom sets on resource start / connect,
-- since Config.Sets is a shared_script table loaded fresh per-VM and the
-- client has no way to read SQL itself.
RegisterNetEvent('mnc-tradingcards:server:requestCustomSets', function()
    local src = source
    -- Always reload before answering -- this used to trust whatever the
    -- fixed onResourceStart SetTimeout had (or hadn't) loaded yet, so a
    -- player connecting shortly after a restart could get an empty/
    -- incomplete snapshot with no way to ever refresh it.
    LoadCustomSetsFromDB(function()
        TriggerClientEvent('mnc-tradingcards:client:syncCustomSets', src, CustomSetsSnapshot())
    end)
end)

-- ============================================================
--  CARD CREATOR NUI ACTIONS
--  Fired by the /cardcreator panel. Same validation/persistence as
--  before, just driven by structured NUI payloads instead of chat
--  arguments, with a result sent straight back to refresh the panel.
-- ============================================================
local function CCSendResult(src, ok, message, selectedSetId, removedSetId)
    TriggerClientEvent('mnc-tradingcards:client:ccResult', src, {
        ok            = ok,
        message       = message,
        sets          = CustomSetsSnapshot(),
        customSetIds  = customSetIds,
        selectedSetId = selectedSetId,
        removedSetId  = removedSetId,
    })
end

local function CCTrim(v)
    if v == nil then return nil end
    return tostring(v):gsub('^%s+', ''):gsub('%s+$', '')
end

RegisterNetEvent('mnc-tradingcards:server:ccNewSet', function(data)
    local src = source
    if not IsCardAdmin(src) then return end
    data = data or {}

    local setId = data.setId
    local icon  = CCTrim(data.icon)
    local label = CCTrim(data.label)

    if type(setId) ~= 'string' or not setId:match('^%a[%w_]*$') or #setId > 40 then
        CCSendResult(src, false, 'Invalid set ID -- use letters/numbers/underscores, starting with a letter.')
        return
    end
    if not icon or icon == '' or not label or label == '' then
        CCSendResult(src, false, 'Icon and label are required.')
        return
    end
    if Config.Sets[setId] then
        CCSendResult(src, false, 'A set with ID "' .. setId .. '" already exists.')
        return
    end

    MySQL.insert('INSERT INTO mnc_custom_sets (set_id, label, icon, created_by) VALUES (?,?,?,?)',
        { setId, label, icon, GetPlayerName(src) or 'unknown' },
        function(insertId)
            if not insertId then
                CCSendResult(src, false, 'Database error creating set.')
                return
            end
            Config.Sets[setId] = { label = label, icon = icon, cards = {} }
            customSetIds[setId] = true
            BroadcastCustomSets()
            CCSendResult(src, true, 'Created set "' .. label .. '".', setId)
        end)
end)

RegisterNetEvent('mnc-tradingcards:server:ccEditSet', function(data)
    local src = source
    if not IsCardAdmin(src) then return end
    data = data or {}

    local setId = data.setId
    local icon  = CCTrim(data.icon)
    local label = CCTrim(data.label)

    if not setId or not customSetIds[setId] then
        CCSendResult(src, false, 'Unknown custom set.', setId)
        return
    end
    if not icon or icon == '' or not label or label == '' then
        CCSendResult(src, false, 'Icon and label are required.', setId)
        return
    end

    MySQL.query('UPDATE mnc_custom_sets SET label = ?, icon = ? WHERE set_id = ?', { label, icon, setId }, function(affected)
        if not affected or affected == 0 then
            CCSendResult(src, false, 'Failed to update set.', setId)
            return
        end
        Config.Sets[setId].label = label
        Config.Sets[setId].icon  = icon
        BroadcastCustomSets()
        CCSendResult(src, true, 'Updated set "' .. label .. '".', setId)
    end)
end)

RegisterNetEvent('mnc-tradingcards:server:ccAddCard', function(data)
    local src = source
    if not IsCardAdmin(src) then return end
    data = data or {}

    local setId      = data.setId
    local number      = tonumber(data.number)
    local rarity      = CCTrim(data.rarity) -- exact-case match required: VALID_CARD_RARITIES uses camelCase 'ultraRare'
    local value       = tonumber(data.value)
    local name        = CCTrim(data.name)
    local model       = CCTrim(data.model)
    local image       = CCTrim(data.image)
    local background  = CCTrim(data.background) or ''

    if not setId or not customSetIds[setId] then
        CCSendResult(src, false, 'Unknown custom set.', setId)
        return
    end
    if not number or number <= 0 or number ~= math.floor(number) then
        CCSendResult(src, false, 'Card number must be a positive whole number.', setId)
        return
    end
    if not rarity or not VALID_CARD_RARITIES[rarity] then
        CCSendResult(src, false, 'Rarity must be one of: common, uncommon, rare, ultraRare.', setId)
        return
    end
    if not name or name == '' then
        CCSendResult(src, false, 'Card needs a name.', setId)
        return
    end
    -- The face image: either a vehicle model, or a custom image (URL / hardcoded PNG path)
    if (not model or model == '') and (not image or image == '') then
        CCSendResult(src, false, 'Provide a vehicle model or a custom image.', setId)
        return
    end
    -- The card back only ever comes from the dropdown -- reject anything else
    if not VALID_BACKGROUNDS[background] then
        CCSendResult(src, false, 'Invalid card background.', setId)
        return
    end
    for _, c in ipairs(Config.Sets[setId].cards) do
        if c.number == number then
            CCSendResult(src, false, 'Set already has a card #' .. number .. '.', setId)
            return
        end
    end

    MySQL.insert(
        'INSERT INTO mnc_custom_set_cards (set_id, card_number, name, model, image, background, rarity, card_value) VALUES (?,?,?,?,?,?,?,?)',
        { setId, number, name, model or '', image or '', background or '', rarity, value or 0 },
        function(insertId)
            if not insertId then
                CCSendResult(src, false, 'Database error adding card (maybe that number is already taken).', setId)
                return
            end
            table.insert(Config.Sets[setId].cards, {
                number     = number,
                name       = name,
                model      = (model ~= '' and model) or nil,
                image      = (image ~= '' and image) or nil,
                background = (background ~= '' and background) or nil,
                rarity     = rarity,
                value      = (value and value > 0) and value or nil,
            })
            BroadcastCustomSets()
            CCSendResult(src, true, 'Added card #' .. number .. ' "' .. name .. '".', setId)
        end)
end)

RegisterNetEvent('mnc-tradingcards:server:ccEditCard', function(data)
    local src = source
    if not IsCardAdmin(src) then return end
    data = data or {}

    local setId      = data.setId
    local number      = tonumber(data.number)
    local rarity      = CCTrim(data.rarity) -- exact-case match required: VALID_CARD_RARITIES uses camelCase 'ultraRare'
    local value       = tonumber(data.value)
    local name        = CCTrim(data.name)
    local model       = CCTrim(data.model)
    local image       = CCTrim(data.image)
    local background  = CCTrim(data.background) or ''

    if not setId or not customSetIds[setId] then
        CCSendResult(src, false, 'Unknown custom set.', setId)
        return
    end
    if not number then
        CCSendResult(src, false, 'Invalid card number.', setId)
        return
    end
    if not rarity or not VALID_CARD_RARITIES[rarity] then
        CCSendResult(src, false, 'Rarity must be one of: common, uncommon, rare, ultraRare.', setId)
        return
    end
    if not name or name == '' then
        CCSendResult(src, false, 'Card needs a name.', setId)
        return
    end
    if (not model or model == '') and (not image or image == '') then
        CCSendResult(src, false, 'Provide a vehicle model or a custom image.', setId)
        return
    end
    if not VALID_BACKGROUNDS[background] then
        CCSendResult(src, false, 'Invalid card background.', setId)
        return
    end

    -- Number is the primary key alongside setId and is never changed by
    -- an edit -- only the card's other fields can be updated.
    local existingIdx = nil
    for i, c in ipairs(Config.Sets[setId].cards) do
        if c.number == number then existingIdx = i; break end
    end
    if not existingIdx then
        CCSendResult(src, false, 'No card #' .. number .. ' found to edit.', setId)
        return
    end

    MySQL.query(
        'UPDATE mnc_custom_set_cards SET name = ?, model = ?, image = ?, background = ?, rarity = ?, card_value = ? WHERE set_id = ? AND card_number = ?',
        { name, model or '', image or '', background or '', rarity, value or 0, setId, number },
        function(affected)
            if not affected or affected == 0 then
                CCSendResult(src, false, 'Database error updating card.', setId)
                return
            end
            Config.Sets[setId].cards[existingIdx] = {
                number     = number,
                name       = name,
                model      = (model ~= '' and model) or nil,
                image      = (image ~= '' and image) or nil,
                background = (background ~= '' and background) or nil,
                rarity     = rarity,
                value      = (value and value > 0) and value or nil,
            }
            BroadcastCustomSets()
            CCSendResult(src, true, 'Updated card #' .. number .. ' "' .. name .. '".', setId)
        end
    )
end)

RegisterNetEvent('mnc-tradingcards:server:ccRemoveCard', function(data)
    local src = source
    if not IsCardAdmin(src) then return end
    data = data or {}

    local setId  = data.setId
    local number = tonumber(data.number)

    if not setId or not customSetIds[setId] then
        CCSendResult(src, false, 'Unknown custom set.', setId)
        return
    end
    if not number then
        CCSendResult(src, false, 'Invalid card number.', setId)
        return
    end

    MySQL.query('DELETE FROM mnc_custom_set_cards WHERE set_id = ? AND card_number = ?', { setId, number }, function(affected)
        if not affected or affected == 0 then
            CCSendResult(src, false, 'No card #' .. number .. ' found.', setId)
            return
        end
        local cards = Config.Sets[setId].cards
        for i, c in ipairs(cards) do
            if c.number == number then table.remove(cards, i); break end
        end
        BroadcastCustomSets()
        CCSendResult(src, true, 'Removed card #' .. number .. '.', setId)
    end)
end)

RegisterNetEvent('mnc-tradingcards:server:ccRemoveSet', function(data)
    local src = source
    if not IsCardAdmin(src) then return end
    data = data or {}

    local setId = data.setId
    if not setId or not customSetIds[setId] then
        CCSendResult(src, false, 'Unknown custom set.', setId)
        return
    end

    -- Strip this set's cards out of every player's hands (inventory +
    -- binders, online + offline) before the set definition disappears
    -- from under them.
    PurgeSetFromPlayers(setId)

    MySQL.query('DELETE FROM mnc_custom_set_cards WHERE set_id = ?', { setId })
    MySQL.query('DELETE FROM mnc_custom_sets WHERE set_id = ?', { setId }, function(affected)
        if not affected or affected == 0 then
            CCSendResult(src, false, 'Failed to remove set.', setId)
            return
        end
        Config.Sets[setId]  = nil
        customSetIds[setId] = nil
        BroadcastCustomSets()
        -- Tell every connected client right away so any open binder or
        -- admin preview/give screen drops this set immediately instead
        -- of showing stale cards from a set that no longer exists.
        TriggerClientEvent('mnc-tradingcards:client:setRemoved', -1, setId)
        CCSendResult(src, true, 'Removed set "' .. setId .. '".', nil, setId)
    end)
end)

-- ============================================================
--  ADMIN GIVE  (/cardgive)
--  Same full-catalog binder UI as /cardpreview (built client-side in
--  client.lua, see openCardPreview / openAdminGive), but with a
--  "Give to Self" action enabled on every card so an admin can browse
--  every set/card and grant themselves an exact copy without needing
--  to roll packs. Uses the same print-counter / value-resolution path
--  as a normal pack drop so the granted card is indistinguishable
--  from an organically rolled one (aside from the ADMIN tag).
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:requestAdminGive', function()
    local src = source
    if not IsCardAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title       = 'Trading Cards',
            description = 'You do not have permission to use /cardgive.',
            type        = 'error',
        })
        return
    end
    TriggerClientEvent('mnc-tradingcards:client:openAdminGive', src)
end)

RegisterNetEvent('mnc-tradingcards:server:adminGiveCard', function(setId, number)
    local src = source
    if not IsCardAdmin(src) then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local setData = Config.Sets[setId]
    if not setData then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Unknown set.', type = 'error' })
        return
    end

    number = tonumber(number)
    local cardDef = nil
    for _, c in ipairs(setData.cards) do
        if c.number == number then cardDef = c; break end
    end
    if not cardDef then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Unknown card.', type = 'error' })
        return
    end

    local citizenid = Player.PlayerData.citizenid
    local cardId     = GenerateId('card')
    local cardValue  = cardDef.value or (Config.Rarities[cardDef.rarity] and Config.Rarities[cardDef.rarity].value) or 0
    local printLabel = NextPrintNum(setId, cardDef.number, setData.label) .. ' ADMIN'

    local cardInfo = {
        id         = cardId,
        cardid     = cardId,
        setId      = setId,
        setLabel   = setData.label,
        number     = cardDef.number,
        name       = cardDef.name,
        model      = cardDef.model      or '',
        image      = cardDef.image      or '',
        background = cardDef.background or (setData.background or ''),
        rarity     = cardDef.rarity,
        printNum   = printLabel,
        value      = cardValue,
    }

    MySQL.insert(
        'INSERT INTO mnc_trading_cards (id, owner_citizenid, set_id, card_number, rarity, is_misprint, is_damaged, print_num, card_value) VALUES (?,?,?,?,?,?,?,?,?)',
        { cardInfo.id, citizenid, cardInfo.setId, cardInfo.number, cardInfo.rarity, 0, 0, cardInfo.printNum, cardInfo.value }
    )

    Player.Functions.AddItem('trading_card', 1, false, {
        number     = cardInfo.number,
        name       = cardInfo.name,
        rarity     = cardInfo.rarity,
        isMisprint = false,
        isDamaged  = false,
        printNum   = cardInfo.printNum,
        value      = cardInfo.value,
        _ref = {
            cardid     = cardInfo.id,
            setId      = cardInfo.setId,
            setLabel   = cardInfo.setLabel,
            model      = cardInfo.model,
            image      = cardInfo.image,
            background = cardInfo.background,
        },
    })

    TriggerClientEvent('ox_lib:notify', src, {
        title       = 'Trading Cards',
        description = 'Gave yourself ' .. cardInfo.name .. ' (' .. (Config.Rarities[cardInfo.rarity] and Config.Rarities[cardInfo.rarity].label or cardInfo.rarity) .. ').',
        type        = 'success',
    })
    DebugPrint('Admin ' .. src .. ' self-granted ' .. setId .. ' #' .. cardInfo.number)
end)

-- ============================================================
--  /cardcreator — opens the NUI panel for admins. All the actual
--  create/edit/delete logic happens through the ccNewSet/ccAddCard/
--  ccRemoveCard/ccRemoveSet events above, fired by that panel.
-- ============================================================
RegisterCommand('cardcreator', function(source, args, rawCommand)
    local src = source
    if src == 0 then
        print('^1[cardcreator]^7 Run this in-game as an admin, not from the server console.')
        return
    end
    if not IsCardAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title       = 'Card Creator',
            description = 'You do not have permission to use /cardcreator.',
            type        = 'error',
        })
        return
    end

    LoadCustomSetsFromDB(function()
        TriggerClientEvent('mnc-tradingcards:client:openCardCreator', src, {
            sets         = Config.Sets,
            customSetIds = customSetIds,
            rarities     = Config.Rarities,
        })
    end)
end, false)

print("^2[mnc-tradingcards]^7 Script loaded successfully!")