local QBCore = exports['qb-core']:GetCoreObject()
local isUIOpen  = false
local binderId  = nil
local shopMenuOpen = false

local function DebugPrint(msg)
    if Config.Debug then print('[mnc-tradingcards] ' .. msg) end
end

-- ============================================================
--  NUI HELPERS
-- ============================================================
local function OpenUI()
    isUIOpen = true
    SetNuiFocus(true, true)
end

local function CloseUI()
    isUIOpen = false
    binderId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeUI' })
end

-- ============================================================
--  OPEN PACK
-- ============================================================
RegisterNetEvent('mnc-tradingcards:client:startOpenPack', function(itemName, itemSlot)
    if isUIOpen then return end
    local packConfig = Config.Packs[itemName]
    if not packConfig then return end
    TriggerServerEvent('mnc-tradingcards:server:openPack', itemName, itemSlot)
end)

-- ============================================================
--  PACK OPENED
-- ============================================================
RegisterNetEvent('mnc-tradingcards:client:packOpened', function(cards, packLabel)
    DebugPrint('Pack opened, received ' .. #cards .. ' cards')
    OpenUI()
    SendNUIMessage({
        type      = 'showPackReveal',
        packLabel = packLabel or 'Card Pack',
        cards     = cards,
        sets      = Config.Sets,
        rarities  = Config.Rarities,
        imageSources     = Config.VehicleImageSources,
        imageSourceOrder = Config.VehicleImageSourceOrder,
    })
end)

-- ============================================================
--  VIEW SINGLE CARD
-- ============================================================
RegisterNetEvent('mnc-tradingcards:client:startViewCard', function(slot, info)
    if isUIOpen then return end
    if not info then return end
    OpenUI()
    SendNUIMessage({
        type             = 'viewCard',
        card             = info,
        rarities         = Config.Rarities,
        imageSources     = Config.VehicleImageSources,
        imageSourceOrder = Config.VehicleImageSourceOrder,
    })
end)

RegisterNetEvent('mnc-tradingcards:client:viewCard', function(info)
    if not info then return end
    OpenUI()
    SendNUIMessage({
        type             = 'viewCard',
        card             = info,
        rarities         = Config.Rarities,
        imageSources     = Config.VehicleImageSources,
        imageSourceOrder = Config.VehicleImageSourceOrder,
    })
end)

-- ============================================================
--  BINDER
-- ============================================================
RegisterNetEvent('mnc-tradingcards:client:startBinder', function(slot)
    if isUIOpen then return end
    TriggerServerEvent('mnc-tradingcards:server:useBinder', slot)
end)

RegisterNetEvent('mnc-tradingcards:client:openBinder', function(binderData)
    binderId = binderData.binderId
    OpenUI()
    SendNUIMessage({
        type           = 'openBinder',
        binderId       = binderData.binderId,
        sets           = binderData.sets,
        rarities       = binderData.rarities,
        storedCards    = binderData.storedCards,
        inventoryCards = binderData.inventoryCards,
        imageSources     = Config.VehicleImageSources,
        imageSourceOrder = Config.VehicleImageSourceOrder,
    })
end)

RegisterNetEvent('mnc-tradingcards:client:cardStoredInBinder', function(cardInfo)
    SendNUIMessage({ type = 'cardStoredInBinder', cardInfo = cardInfo })
end)

RegisterNetEvent('mnc-tradingcards:client:cardRemovedFromBinder', function(cardInfo)
    SendNUIMessage({ type = 'cardRemovedFromBinder', cardInfo = cardInfo })
end)

RegisterNetEvent('mnc-tradingcards:client:cardDiscarded', function(cardId)
    SendNUIMessage({ type = 'cardDiscarded', cardId = cardId })
end)

-- ============================================================
--  SELL COMPLETE — server confirmed the sale
-- ============================================================
RegisterNetEvent('mnc-tradingcards:client:sellComplete', function(data)
    SendNUIMessage({ type = 'sellComplete', sold = data.sold, total = data.total })
end)

-- ============================================================
--  NUI CALLBACKS
-- ============================================================
RegisterNUICallback('closeUI', function(_, cb)
    CloseUI(); cb({ status = 'ok' })
end)

-- Fired by the front-end once the pack reveal screen is actually
-- dismissed (button click or ESC). This is what tells the server it
-- is now safe to write the rolled cards to SQL and the player's
-- inventory -- see mnc-tradingcards:server:claimPack.
RegisterNUICallback('claimPack', function(_, cb)
    TriggerServerEvent('mnc-tradingcards:server:claimPack')
    cb({ status = 'ok' })
end)

-- Card Creator panel (/cardcreator, admin only) -- each just forwards
-- the form payload to the matching server event, which validates,
-- persists to SQL and replies with mnc-tradingcards:client:ccResult.
RegisterNUICallback('ccNewSet', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:ccNewSet', data)
    cb({ status = 'ok' })
end)

RegisterNUICallback('ccAddCard', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:ccAddCard', data)
    cb({ status = 'ok' })
end)

RegisterNUICallback('ccRemoveCard', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:ccRemoveCard', data)
    cb({ status = 'ok' })
end)

RegisterNUICallback('ccRemoveSet', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:ccRemoveSet', data)
    cb({ status = 'ok' })
end)

RegisterNUICallback('ccEditSet', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:ccEditSet', data)
    cb({ status = 'ok' })
end)

RegisterNUICallback('ccEditCard', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:ccEditCard', data)
    cb({ status = 'ok' })
end)

RegisterNUICallback('adminGiveCard', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:adminGiveCard', data.setId, data.number)
    cb({ status = 'ok' })
end)

RegisterNUICallback('notify', function(data, cb)
    lib.notify({ title = data.title or 'Trading Cards', description = data.description, type = data.type or 'info' })
    cb({ status = 'ok' })
end)

RegisterNUICallback('storeCardInBinder', function(data, cb)
    if not binderId then cb({ status = 'error', message = 'No active binder' }); return end
    TriggerServerEvent('mnc-tradingcards:server:storeCardInBinder', binderId, data.slot, data.cardid)
    cb({ status = 'ok' })
end)

RegisterNUICallback('removeCardFromBinder', function(data, cb)
    if not binderId then cb({ status = 'error', message = 'No active binder' }); return end
    TriggerServerEvent('mnc-tradingcards:server:removeCardFromBinder', data.binderId or binderId, data.cardid)
    cb({ status = 'ok' })
end)

RegisterNUICallback('discardDamaged', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:discardDamaged', data.cardid)
    cb({ status = 'ok' })
end)

RegisterNUICallback('sellCards', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:sellCards', data.cards)
    cb({ status = 'ok' })
end)

RegisterNUICallback('sellSet', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:sellSet', data.setId)
    cb({ status = 'ok' })
end)

-- ============================================================
--  SHOP NPC
-- ============================================================
local shopPed   = nil
local shopBlip  = nil
local nearShop  = false

CreateThread(function()
    -- Blip
    shopBlip = AddBlipForCoord(Config.Shop.coords.x, Config.Shop.coords.y, Config.Shop.coords.z)
    SetBlipSprite(shopBlip, Config.Shop.blipSprite)
    SetBlipDisplay(shopBlip, 4)
    SetBlipScale(shopBlip, Config.Shop.blipScale)
    SetBlipColour(shopBlip, Config.Shop.blipColor)
    SetBlipAsShortRange(shopBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Shop.blipName)
    EndTextCommandSetBlipName(shopBlip)

    -- Ped (simple ambient dealer NPC)
    RequestModel(`s_m_m_movalien_01`)  -- fallback generic model
    local model = `s_m_y_dealer_01`
    RequestModel(model)
    local timer = 0
    while not HasModelLoaded(model) and timer < 5000 do
        Wait(100); timer = timer + 100
    end
    if not HasModelLoaded(model) then model = `a_m_m_skater_01` end

    local c = Config.Shop.coords
    shopPed = CreatePed(4, model, c.x, c.y, c.z - 1.0, Config.Shop.heading, false, true)
    SetEntityInvincible(shopPed, true)
    SetBlockingOfNonTemporaryEvents(shopPed, true)
    FreezeEntityPosition(shopPed, true)
    SetPedAsCop(shopPed, true)
    SetPedComponentVariation(shopPed, 0, 0, 0, 2)
end)

-- Proximity check + E prompt
CreateThread(function()
    while true do
        local sleep = 1000
        local pos   = GetEntityCoords(PlayerPedId())
        local dist  = #(pos - Config.Shop.coords)

        if dist < 2.0 then
            sleep = 0
            nearShop = true

            if not isUIOpen and not shopMenuOpen then
                -- Draw marker
                DrawMarker(20, Config.Shop.coords.x, Config.Shop.coords.y, Config.Shop.coords.z - 0.98,
                    0, 0, 0, 0, 0, 0, 0.6, 0.6, 0.3, 80, 200, 120, 150, false, true, 2, nil, nil, false)

                -- Draw help text
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Card Dealer')
                EndTextCommandDisplayHelp(0, false, true, -1)

                if IsControlJustPressed(0, 38) then  -- E key
                    if not isUIOpen then
                        -- Gather inventory cards
                        TriggerServerEvent('mnc-tradingcards:server:requestShopOpen')
                    end
                end
            end
        else
            nearShop = false
        end

        Wait(sleep)
    end
end)

-- Server sends inventory for shop UI
RegisterNetEvent('mnc-tradingcards:client:openShop', function(inventoryCards)
    if isUIOpen then return end
    OpenUI()
    SendNUIMessage({
        type           = 'openShop',
        inventoryCards = inventoryCards,
        sets           = Config.Sets,
        rarities       = Config.Rarities,
        sellMultiplier = Config.Shop.sellMultiplier,
        imageSources     = Config.VehicleImageSources,
        imageSourceOrder = Config.VehicleImageSourceOrder,
    })
end)

-- ============================================================
--  ADMIN PREVIEW — /cardpreview
--  Opens a read-only binder populated with every card in every
--  set so admins can QA card images without owning any cards.
--
--  ADMIN GIVE — /cardgive
--  Same full-catalog binder, but with a "Give to Self" button enabled
--  on every card so an admin can browse the whole catalog and grant
--  themselves an exact card instead of gambling on packs.
-- ============================================================

-- Builds a fake "storedCards" table containing one copy of every card
-- in every set, shared by both /cardpreview and /cardgive so the two
-- commands can never drift out of sync with each other.
local function BuildAllCardsCatalog()
    local allCards = {}
    for setId, setData in pairs(Config.Sets) do
        for _, card in ipairs(setData.cards) do
            allCards[#allCards + 1] = {
                id         = setId .. '_' .. card.number,
                cardid     = setId .. '_' .. card.number,
                setId      = setId,
                setLabel   = setData.label,
                number     = card.number,
                name       = card.name,
                model      = card.model,
                image      = card.image,
                background = card.background,
                rarity     = card.rarity,
                printNum   = card.printNum,
                value      = card.value,
                preview    = true,   -- flag so JS can hide sell/remove controls
            }
        end
    end
    return allCards
end

RegisterNetEvent('mnc-tradingcards:client:openCardPreview', function()
    if isUIOpen then return end
    OpenUI()
    SendNUIMessage({
        type           = 'openBinder',
        binderId       = 'preview',
        sets           = Config.Sets,
        rarities       = Config.Rarities,
        storedCards    = BuildAllCardsCatalog(),
        inventoryCards = {},          -- nothing in inventory — preview only
        previewMode    = true,
        imageSources     = Config.VehicleImageSources,
        imageSourceOrder = Config.VehicleImageSourceOrder,
    })
end)

RegisterCommand('cardpreview', function(source, args, rawCmd)
    -- Client-side: server already did the permission check before firing the event,
    -- but we also guard here so the command only fires via the server route.
    TriggerServerEvent('mnc-tradingcards:server:requestCardPreview')
end, false)

RegisterNetEvent('mnc-tradingcards:client:openAdminGive', function()
    if isUIOpen then return end
    OpenUI()
    SendNUIMessage({
        type           = 'openBinder',
        binderId       = 'admin_give',
        sets           = Config.Sets,
        rarities       = Config.Rarities,
        storedCards    = BuildAllCardsCatalog(),
        inventoryCards = {},
        previewMode    = true,
        grantMode      = true,   -- flag so JS shows a "Give to Self" button per card
        imageSources     = Config.VehicleImageSources,
        imageSourceOrder = Config.VehicleImageSourceOrder,
    })
end)

RegisterCommand('cardgive', function(source, args, rawCmd)
    -- Same pattern as /cardpreview -- server does the real permission
    -- check before it ever fires the event back to open the UI.
    TriggerServerEvent('mnc-tradingcards:server:requestAdminGive')
end, false)

-- Fired whenever an admin deletes a custom set (see /cardcreator ->
-- ccRemoveSet on the server). Keeps our local Config.Sets copy in sync
-- and, if any trading-card UI is currently open, tells the NUI to drop
-- that set immediately instead of showing stale/broken cards.
RegisterNetEvent('mnc-tradingcards:client:setRemoved', function(setId)
    if not setId then return end
    Config.Sets[setId] = nil
    if isUIOpen then
        SendNUIMessage({ type = 'setRemoved', setId = setId })
    end
end)

-- ============================================================
--  ESC to close
-- ============================================================
CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen and IsControlJustPressed(0, 200) then
            CloseUI()
        end
    end
end)

-- ============================================================
--  CUSTOM SETS SYNC (see /cardcreator on the server)
--  Config.Sets is a shared_script table, loaded fresh into each Lua
--  VM at resource start. Sets created at runtime via /cardcreator
--  only exist in the server's copy until it's pushed down to us, so
--  we ask for the current list on load and merge whatever comes back.
-- ============================================================
RegisterNetEvent('mnc-tradingcards:client:syncCustomSets', function(customSets)
    if not customSets then return end
    for setId, data in pairs(customSets) do
        Config.Sets[setId] = data
    end
    DebugPrint('Synced custom sets from server')
end)

-- ============================================================
--  CARD CREATOR PANEL  (/cardcreator, admin only)
--  The server already checked permissions before firing this --
--  it only ever reaches an admin's client.
-- ============================================================
RegisterNetEvent('mnc-tradingcards:client:openCardCreator', function(data)
    if isUIOpen then return end
    OpenUI()
    SendNUIMessage({
        type         = 'openCardCreator',
        sets         = data.sets         or Config.Sets,
        customSetIds = data.customSetIds or {},
        rarities     = data.rarities     or Config.Rarities,
        imageSources     = Config.VehicleImageSources,
        imageSourceOrder = Config.VehicleImageSourceOrder,
    })
end)

RegisterNetEvent('mnc-tradingcards:client:ccResult', function(data)
    if not data then return end
    SendNUIMessage({
        type          = 'ccResult',
        ok            = data.ok,
        message       = data.message,
        sets          = data.sets,
        customSetIds  = data.customSetIds,
        selectedSetId = data.selectedSetId,
        removedSetId  = data.removedSetId,
    })
end)

CreateThread(function()
    TriggerServerEvent('mnc-tradingcards:server:requestCustomSets')

    -- Chat suggestions for admins. Safe no-op if the server isn't
    -- running a chat resource that listens for this event.
    TriggerEvent('chat:addSuggestion', '/cardcreator', 'Open the card set creator panel (admin only)')
    TriggerEvent('chat:addSuggestion', '/cardgive', 'Browse every card and give yourself one (admin only)')
end)

-- ============================================================
--  Resource cleanup
-- ============================================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isUIOpen then SetNuiFocus(false, false); isUIOpen = false; binderId = nil end
        if shopPed  and DoesEntityExist(shopPed)  then DeleteEntity(shopPed)  end
        if shopBlip and DoesBlipExist(shopBlip)   then RemoveBlip(shopBlip)   end
    end
end)