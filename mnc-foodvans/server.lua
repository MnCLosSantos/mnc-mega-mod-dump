local QBCore = exports['qb-core']:GetCoreObject()

-- Pending invoices: invoiceId -> { src, targetSrc, vanId, amount, workerName }
local pendingInvoices = {}
local invoiceCounter  = 0

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_foodvans` (
            `id`          INT          NOT NULL,
            `citizenid`   VARCHAR(50)  NULL DEFAULT NULL,
            `owner_name`  VARCHAR(100) NULL DEFAULT NULL,
            `is_open`     TINYINT(1)   NOT NULL DEFAULT 0,
            `purchased`   TINYINT(1)   NOT NULL DEFAULT 0,
            `authorised`   TEXT         NULL DEFAULT NULL,
            `safe_balance` INT          NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
        -- Ensure safe_balance column exists when upgrading from older versions
        MySQL.query('ALTER TABLE `mnc_foodvans` ADD COLUMN IF NOT EXISTS `safe_balance` INT NOT NULL DEFAULT 0', {}, function() end)
        MySQL.query('UPDATE `mnc_foodvans` SET `is_open` = 0', {}, function()
            print('^2[mnc-foodvans]^7 All stalls reset to CLOSED.')

            local placeholders, values = {}, {}
            for _, loc in ipairs(Config.VanLocations) do
                placeholders[#placeholders + 1] = '(?, NULL, NULL, 0, 0, NULL)'
                values[#values + 1] = loc.id
            end
            if #placeholders == 0 then return end

            local sql = 'INSERT IGNORE INTO `mnc_foodvans` (`id`,`citizenid`,`owner_name`,`is_open`,`purchased`,`authorised`) VALUES '
                      .. table.concat(placeholders, ', ')

            MySQL.query(sql, values, function(result)
                local inserted = (result and result.affectedRows) or 0
                print(('^2[mnc-foodvans]^7 Database ready. %d new row(s) seeded.'):format(inserted))
            end)
        end)
    end)
end)

local function DebugLog(src, msg)
    if not Config.Debug then return end
    print(('^3[MNC-DEBUG][SERVER] src=%s | %s^7'):format(tostring(src), msg))
end

local function IsAdmin(source)
    for _, g in ipairs(Config.AdminGroups or {}) do
        if IsPlayerAceAllowed(source, 'group.' .. g) then return true end
    end
    return false
end

local function GetVanDB(vanId, cb)
    MySQL.query('SELECT * FROM mnc_foodvans WHERE id = ? LIMIT 1', { vanId }, function(rows)
        cb(rows and rows[1] or nil)
    end)
end

local function ParseAuthorised(row)
    if not row or not row.authorised then return {} end
    local ok, t = pcall(json.decode, row.authorised)
    return (ok and type(t) == 'table') and t or {}
end

local function IsAuthorised(row, citizenid)
    if not row or not citizenid then return false end
    if row.citizenid == citizenid then return true end
    for _, cid in ipairs(ParseAuthorised(row)) do
        if cid == citizenid then return true end
    end
    return false
end

local function RemoveMoney(source, amount, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false) return end
    if Player.Functions.GetMoney(Config.PaymentAccount) < amount then cb(false) return end
    Player.Functions.RemoveMoney(Config.PaymentAccount, amount, 'foodvan-purchase')
    cb(true)
end

local function AddMoney(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then Player.Functions.AddMoney(Config.PaymentAccount, amount, 'foodvan-payment') end
end

local function HasIngredients(source, ingredients)
    for _, ing in ipairs(ingredients) do
        local count = exports['qb-inventory']:GetItemCount(source, ing.item)
        if count < ing.amount then
            return false, ing.item, ing.amount
        end
    end
    return true
end

local function RemoveIngredients(source, ingredients)
    for _, ing in ipairs(ingredients) do
        exports['qb-inventory']:RemoveItem(source, ing.item, ing.amount)
    end
end

local function GiveItem(source, itemName, amount)
    exports['qb-inventory']:AddItem(source, itemName, amount)
end

local function SyncStates(target)
    target = target or -1
    MySQL.query('SELECT id, citizenid, owner_name, is_open, purchased, authorised, safe_balance FROM mnc_foodvans', {}, function(rows)
        local stateMap = {}
        for _, row in ipairs(rows or {}) do
            stateMap[tostring(row.id)] = row
        end
        TriggerClientEvent('mnc-foodvans:client:syncStates', target, stateMap)
    end)
end

-- Client requests its own state sync (on resource start or after QB player load)
RegisterNetEvent('mnc-foodvans:server:requestStates', function()
    local src = source
    DebugLog(src, 'requestStates received')
    SyncStates(src)
end)

-- QB-Core server event — fires when a player fully loads server-side
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if not Player then return end
    local src = Player.PlayerData.source
    DebugLog(src, 'QBCore:Server:PlayerLoaded — sending states')
    SyncStates(src)
end)

RegisterNetEvent('mnc-foodvans:server:purchase', function(vanId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    DebugLog(src, ('server:purchase | vanId=%s'):format(tostring(vanId)))
    if not Player then return end

    local locConfig = nil
    for _, loc in ipairs(Config.VanLocations) do
        if loc.id == vanId then locConfig = loc; break end
    end
    if not locConfig then return end

    GetVanDB(vanId, function(row)
        if not row or (row.purchased == 1 or row.purchased == true) then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'This location is already owned.', 'error')
            return
        end

        RemoveMoney(src, locConfig.price, function(ok)
            if not ok then
                TriggerClientEvent('mnc-foodvans:client:notify', src,
                    ('You cannot afford this location ($%s).'):format(locConfig.price), 'error')
                return
            end

            local citizenid = Player.PlayerData.citizenid
            local ownerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname

            MySQL.query(
                'UPDATE mnc_foodvans SET citizenid=?, owner_name=?, purchased=1, is_open=0 WHERE id=?',
                { citizenid, ownerName, vanId },
                function(result)
                    DebugLog(src, ('DB UPDATE affectedRows=%s'):format(result and result.affectedRows or 0))
                    SyncStates()
                    Wait(500)
                    TriggerClientEvent('mnc-foodvans:client:forceRefresh', src)
                    TriggerClientEvent('mnc-foodvans:client:notify', src, 'You purchased ' .. locConfig.label .. '!', 'success')
                end
            )
        end)
    end)
end)

RegisterNetEvent('mnc-foodvans:server:toggleOpen', function(vanId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    GetVanDB(vanId, function(row)
        if not row then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'Van not found.', 'error')
            return
        end

        local purchased = (row.purchased == 1 or row.purchased == true) and 1 or 0
        local isOpen    = (row.is_open   == 1 or row.is_open   == true) and 1 or 0

        if purchased ~= 1 then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'You do not own this location.', 'error')
            return
        end

        if not IsAdmin(src) and not IsAuthorised(row, Player.PlayerData.citizenid) then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'You do not own this location.', 'error')
            return
        end

        local newState = (isOpen == 1) and 0 or 1
        MySQL.query('UPDATE mnc_foodvans SET is_open=? WHERE id=?', { newState, vanId }, function()
            local msg = (newState == 1) and 'Van is now OPEN for business!' or 'Van is now CLOSED.'
            TriggerClientEvent('mnc-foodvans:client:notify', src, msg, 'success')
            SyncStates()
        end)
    end)
end)

RegisterNetEvent('mnc-foodvans:server:openCraft', function(vanId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local locConfig = nil
    for _, loc in ipairs(Config.VanLocations) do
        if loc.id == vanId then locConfig = loc; break end
    end
    if not locConfig then return end

    GetVanDB(vanId, function(row)
        if not row or (row.purchased ~= 1 and row.purchased ~= true) then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'This van is not available.', 'error')
            return
        end
        if row.is_open ~= 1 and row.is_open ~= true then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'This van is currently closed.', 'error')
            return
        end
        if not IsAdmin(src) and not IsAuthorised(row, Player.PlayerData.citizenid) then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'You are not authorised to use this van.', 'error')
            return
        end

        local recipes = Config.PropRecipes[locConfig.prop] or {}
        if #recipes == 0 then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'No recipes available for this van.', 'error')
            return
        end

        -- Send recipes back to the client — the client handler will build the menu
        TriggerClientEvent('mnc-foodvans:client:openCraft', src, {
            vanId   = vanId,
            label   = locConfig.label,
            recipes = recipes,
        })
    end)
end)

RegisterNetEvent('mnc-foodvans:server:openStash', function(vanId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    GetVanDB(vanId, function(row)
        if not row or (row.purchased ~= 1 and row.purchased ~= true) then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'This van has no storage.', 'error')
            return
        end
        if not IsAdmin(src) and not IsAuthorised(row, Player.PlayerData.citizenid) then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'You are not authorised to access this storage.', 'error')
            return
        end

        -- New qb-inventory: OpenInventory server-side (no RegisterStash needed, no client event needed)
        local stashId = 'mnc_van_stash_' .. vanId
        exports['qb-inventory']:OpenInventory(src, stashId, {
            label     = 'Van Storage ' .. vanId,
            maxweight = Config.StashMaxWeight,
            slots     = Config.StashSlots,
        })
    end)
end)

RegisterNetEvent('mnc-foodvans:server:craft', function(vanId, recipeIndex)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local locConfig = nil
    for _, loc in ipairs(Config.VanLocations) do
        if loc.id == vanId then locConfig = loc; break end
    end
    if not locConfig then return end

    GetVanDB(vanId, function(row)
        if not row or (row.purchased ~= 1 and row.purchased ~= true) or (row.is_open ~= 1 and row.is_open ~= true) then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'Van is not open.', 'error')
            return
        end
        if not IsAdmin(src) and not IsAuthorised(row, Player.PlayerData.citizenid) then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'You are not authorised to craft here.', 'error')
            return
        end

        local recipes = Config.PropRecipes[locConfig.prop] or {}
        local recipe  = recipes[recipeIndex]
        if not recipe then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'Invalid recipe.', 'error')
            return
        end

        local hasAll, missingItem, neededAmt = HasIngredients(src, recipe.ingredients)
        if not hasAll then
            TriggerClientEvent('mnc-foodvans:client:notify', src,
                ('Missing: %dx %s'):format(neededAmt, missingItem), 'error')
            return
        end

        RemoveIngredients(src, recipe.ingredients)
        GiveItem(src, recipe.result, recipe.amount)
        TriggerClientEvent('mnc-foodvans:client:notify', src, 'Crafted: ' .. recipe.label, 'success')
    end)
end)

RegisterNetEvent('mnc-foodvans:server:requestPayment', function(vanId, targetServerId, amount, reason)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or amount > Config.MaxPayment then
        TriggerClientEvent('mnc-foodvans:client:notify', src, 'Invalid payment amount.', 'error')
        return
    end

    reason = (type(reason) == 'string' and #reason > 0) and reason or 'Food purchase'

    GetVanDB(vanId, function(row)
        if not row or (row.purchased ~= 1 and row.purchased ~= true) then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'Van not found or not purchased.', 'error')
            return
        end
        if not IsAdmin(src) and not IsAuthorised(row, Player.PlayerData.citizenid) then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'You are not authorised on this van.', 'error')
            return
        end

        local TargetPlayer = QBCore.Functions.GetPlayer(targetServerId)
        if not TargetPlayer then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'Player not found online.', 'error')
            return
        end

        local workerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        local isSelf     = (targetServerId == src)

        -- Self-charge: send invoice back to yourself so the same modal appears
        if isSelf then
            invoiceCounter = invoiceCounter + 1
            local invoiceId = invoiceCounter
            pendingInvoices[invoiceId] = {
                src        = src,
                targetSrc  = src,
                vanId      = vanId,
                amount     = amount,
                workerName = workerName,
                reason     = reason,
            }
            TriggerClientEvent('mnc-foodvans:client:receiveInvoice', src, {
                invoiceId  = invoiceId,
                workerName = workerName,
                amount     = amount,
                reason     = reason,
                isSelf     = true,
            })
            return
        end

        -- Register pending invoice
        invoiceCounter = invoiceCounter + 1
        local invoiceId = invoiceCounter
        pendingInvoices[invoiceId] = {
            src        = src,
            targetSrc  = targetServerId,
            vanId      = vanId,
            amount     = amount,
            workerName = workerName,
            reason     = reason,
        }

        -- Send invoice modal to the target player
        TriggerClientEvent('mnc-foodvans:client:receiveInvoice', targetServerId, {
            invoiceId  = invoiceId,
            workerName = workerName,
            amount     = amount,
            reason     = reason,
            isSelf     = false,
        })

        -- Notify the worker the request has been sent
        TriggerClientEvent('mnc-foodvans:client:notify', src,
            ('Invoice of $%d sent to %s. Waiting for response...'):format(
                amount,
                TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
            ), 'inform')

        DebugLog(src, ('Invoice #%d sent | target=%d | amount=%d | reason=%s'):format(
            invoiceId, targetServerId, amount, reason))
    end)
end)

RegisterNetEvent('mnc-foodvans:server:respondInvoice', function(invoiceId, confirmed)
    local src     = source
    local invoice = pendingInvoices[invoiceId]

    if not invoice then
        TriggerClientEvent('mnc-foodvans:client:notify', src, 'Invoice no longer valid.', 'error')
        return
    end

    -- Make sure the right player is responding
    if invoice.targetSrc ~= src then
        TriggerClientEvent('mnc-foodvans:client:notify', src, 'This invoice is not for you.', 'error')
        return
    end

    pendingInvoices[invoiceId] = nil

    local TargetPlayer = QBCore.Functions.GetPlayer(src)
    local targetName   = TargetPlayer
        and (TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname)
        or  'Unknown'

    if not confirmed then
        -- Denied
        TriggerClientEvent('mnc-foodvans:client:notify', src,
            ('You declined the $%d invoice from %s.'):format(invoice.amount, invoice.workerName), 'error')
        TriggerClientEvent('mnc-foodvans:client:notify', invoice.src,
            ('%s declined your $%d invoice.'):format(targetName, invoice.amount), 'error')
        DebugLog(src, ('Invoice #%d denied by target'):format(invoiceId))
        return
    end

    -- Confirmed — charge the target
    RemoveMoney(src, invoice.amount, function(ok)
        if not ok then
            TriggerClientEvent('mnc-foodvans:client:notify', src,
                ('Insufficient funds — $%d required.'):format(invoice.amount), 'error')
            TriggerClientEvent('mnc-foodvans:client:notify', invoice.src,
                ('%s tried to pay but had insufficient funds.'):format(targetName), 'error')
            return
        end

        -- 10% paid directly to the worker; 90% held in the van safe
        local workerCut = math.max(1, math.floor(invoice.amount * 0.10))
        local safeCut   = invoice.amount - workerCut
        AddMoney(invoice.src, workerCut)
        MySQL.query('UPDATE mnc_foodvans SET safe_balance = safe_balance + ? WHERE id = ?', { safeCut, invoice.vanId }, function()
            SyncStates()
        end)

        TriggerClientEvent('mnc-foodvans:client:notify', src,
            ('You paid $%d to %s. Reason: %s'):format(invoice.amount, invoice.workerName, invoice.reason), 'success')
        TriggerClientEvent('mnc-foodvans:client:notify', invoice.src,
            ('%s paid your $%d invoice! ($%d to your bank, $%d held in safe)'):format(targetName, invoice.amount, workerCut, safeCut), 'success')

        DebugLog(src, ('Invoice #%d paid | $%d from %d to %d (worker=$%d safe=$%d)'):format(
            invoiceId, invoice.amount, src, invoice.src, workerCut, safeCut))
    end)
end)

RegisterNetEvent('mnc-foodvans:server:getManageData', function(vanId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    GetVanDB(vanId, function(row)
        if not row or (row.purchased ~= 1 and row.purchased ~= true) then return end
        if not IsAdmin(src) and row.citizenid ~= Player.PlayerData.citizenid then return end

        local authorised = ParseAuthorised(row)
        TriggerClientEvent('mnc-foodvans:client:openManage', src, vanId, authorised, tonumber(row.safe_balance) or 0)
    end)
end)

RegisterNetEvent('mnc-foodvans:server:addAuthorised', function(vanId, targetCitizenId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if type(targetCitizenId) ~= 'string' or #targetCitizenId < 5 then
        TriggerClientEvent('mnc-foodvans:client:notify', src, 'Invalid Citizen ID.', 'error')
        return
    end

    GetVanDB(vanId, function(row)
        if not row or (row.purchased ~= 1 and row.purchased ~= true) then return end
        if not IsAdmin(src) and row.citizenid ~= Player.PlayerData.citizenid then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'Only the owner can manage staff.', 'error')
            return
        end

        local authorised = ParseAuthorised(row)
        if targetCitizenId == row.citizenid then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'That is the owner.', 'error')
            return
        end
        for _, cid in ipairs(authorised) do
            if cid == targetCitizenId then
                TriggerClientEvent('mnc-foodvans:client:notify', src, 'Already authorised.', 'error')
                return
            end
        end

        authorised[#authorised + 1] = targetCitizenId
        MySQL.query('UPDATE mnc_foodvans SET authorised=? WHERE id=?', { json.encode(authorised), vanId }, function()
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'Added ' .. targetCitizenId .. ' as staff.', 'success')
            TriggerEvent('mnc-foodvans:server:getManageData', src, vanId)
            SyncStates()
        end)
    end)
end)

RegisterNetEvent('mnc-foodvans:server:removeAuthorised', function(vanId, targetCitizenId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    GetVanDB(vanId, function(row)
        if not row or (row.purchased ~= 1 and row.purchased ~= true) then return end
        if not IsAdmin(src) and row.citizenid ~= Player.PlayerData.citizenid then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'Only the owner can manage staff.', 'error')
            return
        end

        local authorised = ParseAuthorised(row)
        local newList = {}
        for _, cid in ipairs(authorised) do
            if cid ~= targetCitizenId then newList[#newList + 1] = cid end
        end

        MySQL.query('UPDATE mnc_foodvans SET authorised=? WHERE id=?', { json.encode(newList), vanId }, function()
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'Removed ' .. targetCitizenId .. ' from staff.', 'success')
            TriggerEvent('mnc-foodvans:server:getManageData', src, vanId)
            SyncStates()
        end)
    end)
end)

RegisterNetEvent('mnc-foodvans:server:orderIngredients', function(vanId, orderList)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if type(orderList) ~= 'table' or #orderList == 0 then
        TriggerClientEvent('mnc-foodvans:client:notify', src, 'Empty order.', 'error')
        return
    end

    GetVanDB(vanId, function(row)
        if not row or (row.purchased ~= 1 and row.purchased ~= true) then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'You do not own this van.', 'error')
            return
        end
        if not IsAdmin(src) and not IsAuthorised(row, Player.PlayerData.citizenid) then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'Not authorised.', 'error')
            return
        end

        local orderableLookup = {}
        for _, ing in ipairs(Config.OrderableIngredients) do
            orderableLookup[ing.item] = ing
        end

        local totalCost  = 0
        local validOrder = {}
        for _, line in ipairs(orderList) do
            local def = orderableLookup[line.item]
            if def and type(line.qty) == 'number' and line.qty > 0 then
                local batches = math.floor(line.qty)
                totalCost = totalCost + (def.price * batches)
                validOrder[#validOrder + 1] = { item = def.item, amount = def.amount * batches }
            end
        end

        if #validOrder == 0 then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'No valid items in order.', 'error')
            return
        end

        RemoveMoney(src, totalCost, function(ok)
            if not ok then
                TriggerClientEvent('mnc-foodvans:client:notify', src, ('Cannot afford order — total $%d.'):format(totalCost), 'error')
                return
            end

            TriggerClientEvent('mnc-foodvans:client:notify', src, ('Order placed! $%d charged. Delivery arriving in ~45 seconds.'):format(totalCost), 'success')
            TriggerClientEvent('mnc-foodvans:client:spawnDelivery', src, vanId)

            -- Give items directly to the player after 45 seconds
            SetTimeout(25000, function()
                local P = QBCore.Functions.GetPlayer(src)
                if not P then return end
                for _, line in ipairs(validOrder) do
                    exports['qb-inventory']:AddItem(src, line.item, line.amount)
                end
            end)
        end)
    end)
end)

RegisterNetEvent('mnc-foodvans:server:npcSale', function(vanId, itemName, amount)
    local src = source

    -- Basic input validation
    if type(itemName) ~= 'string' or #itemName < 2 then return end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or amount > 10000 then return end

    -- Double-check this item/price is in our config (client-side spoofing prevention)
    local configuredPrice = Config.CustomerSalePrices and Config.CustomerSalePrices[itemName]
    if not configuredPrice or configuredPrice ~= amount then
        DebugLog(src, ('npcSale REJECTED: item=%s amount=%d not matching config'):format(itemName, amount))
        return
    end

    GetVanDB(vanId, function(row)
        if not row or (row.purchased ~= 1 and row.purchased ~= true) then return end
        if (row.is_open ~= 1 and row.is_open ~= true) then return end

        -- Find the van owner online
        local ownerPlayer = nil
        for _, pid in ipairs(GetPlayers()) do
            local P = QBCore.Functions.GetPlayer(tonumber(pid))
            if P and P.PlayerData.citizenid == row.citizenid then
                ownerPlayer = P
                break
            end
        end

        if not ownerPlayer then
            DebugLog(src, ('npcSale: owner offline for van %d'):format(vanId))
            return
        end

        local ownerSrc = ownerPlayer.PlayerData.source

        -- Check the owner actually has the item in their inventory
        local itemCount = exports['qb-inventory']:GetItemCount(ownerSrc, itemName)
        if itemCount < 1 then
            DebugLog(src, ('npcSale FAILED (sold out): van=%d item=%s owner=%s'):format(
                vanId, itemName, tostring(row.citizenid)))
            return
        end

        -- Consume the item — 10% to owner's bank immediately, 90% held in the van safe
        exports['qb-inventory']:RemoveItem(ownerSrc, itemName, 1)
        local ownerCut = math.max(1, math.floor(amount * 0.10))
        local safeCut  = amount - ownerCut
        AddMoney(ownerSrc, ownerCut)
        MySQL.query('UPDATE mnc_foodvans SET safe_balance = safe_balance + ? WHERE id = ?', { safeCut, vanId }, function()
            SyncStates()
        end)
        TriggerClientEvent('mnc-foodvans:client:notify', ownerSrc,
            ('NPC sale: $%d to your bank, $%d added to van safe!'):format(ownerCut, safeCut), 'success')

        DebugLog(src, ('npcSale OK: van=%d item=%s price=%d owner=%s (bank=$%d safe=$%d)'):format(
            vanId, itemName, amount, tostring(row.citizenid), ownerCut, safeCut))
    end)
end)

local function GetVanCoords(vanId)
    for _, loc in ipairs(Config.VanLocations) do
        if loc.id == vanId then
            return vector3(loc.coords.x, loc.coords.y, loc.coords.z)
        end
    end
    return nil
end

local function GetPlayerCoordsBySource(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local coords = GetEntityCoords(ped)
    return coords
end

CreateThread(function()
    local interval = (Config.StallCloseCheckInterval and Config.StallCloseCheckInterval > 0)
        and Config.StallCloseCheckInterval or 15000

    while true do
        Wait(interval)

        MySQL.query('SELECT id, citizenid, is_open, authorised FROM mnc_foodvans WHERE is_open = 1 AND purchased = 1', {}, function(rows)
            if not rows or #rows == 0 then return end

            for _, row in ipairs(rows) do
                local vanId     = row.id
                local vanCoords = GetVanCoords(vanId)
                if not vanCoords then goto nextVan end

                local radius       = Config.StallCloseRadius or 100.0
                local authorised   = ParseAuthorised(row)
                local anyoneNearby = false

                -- Check every online player against the owner + authorised list
                for _, pid in ipairs(GetPlayers()) do
                    local psrc = tonumber(pid)
                    local P    = QBCore.Functions.GetPlayer(psrc)
                    if P then
                        local cid = P.PlayerData.citizenid
                        local isStaff = (cid == row.citizenid)
                        if not isStaff then
                            for _, authCid in ipairs(authorised) do
                                if authCid == cid then isStaff = true; break end
                            end
                        end

                        if isStaff then
                            local pCoords = GetPlayerCoordsBySource(psrc)
                            if pCoords and #(pCoords - vanCoords) <= radius then
                                anyoneNearby = true
                                break
                            end
                        end
                    end
                end

                if not anyoneNearby then
                    MySQL.query('UPDATE mnc_foodvans SET is_open = 0 WHERE id = ?', { vanId }, function()
                        DebugLog(-1, ('Auto-closed van %d — owner/workers out of range'):format(vanId))
                        SyncStates()
                    end)
                end

                ::nextVan::
            end
        end)
    end
end)

RegisterNetEvent('mnc-foodvans:server:adminReset', function(vanId)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('mnc-foodvans:client:notify', src, 'Permission denied.', 'error')
        return
    end
    MySQL.query('UPDATE mnc_foodvans SET citizenid=NULL, owner_name=NULL, purchased=0, is_open=0, authorised=NULL WHERE id=?', { vanId }, function()
        TriggerClientEvent('mnc-foodvans:client:notify', src, 'Van location reset.', 'success')
        SyncStates()
    end)
end)

RegisterNetEvent('mnc-foodvans:server:withdrawSafe', function(vanId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    GetVanDB(vanId, function(row)
        if not row or (row.purchased ~= 1 and row.purchased ~= true) then return end
        if row.citizenid ~= Player.PlayerData.citizenid then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'Only the owner can access the safe.', 'error')
            return
        end

        local balance = tonumber(row.safe_balance) or 0
        if balance <= 0 then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'The safe is empty.', 'error')
            return
        end

        MySQL.query('UPDATE mnc_foodvans SET safe_balance = 0 WHERE id = ?', { vanId }, function()
            AddMoney(src, balance)
            TriggerClientEvent('mnc-foodvans:client:notify', src,
                ('Withdrew $%d from the van safe!'):format(balance), 'success')
            SyncStates()
        end)
    end)
end)

RegisterNetEvent('mnc-foodvans:server:sellLocation', function(vanId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    GetVanDB(vanId, function(row)
        if not row or (row.purchased ~= 1 and row.purchased ~= true) then return end
        if not IsAdmin(src) and row.citizenid ~= Player.PlayerData.citizenid then
            TriggerClientEvent('mnc-foodvans:client:notify', src, 'Only the owner can sell this location.', 'error')
            return
        end

        local balance = tonumber(row.safe_balance) or 0
        -- Pay out any remaining safe balance to the owner before selling
        if balance > 0 then
            AddMoney(src, balance)
        end

        MySQL.query(
            'UPDATE mnc_foodvans SET citizenid=NULL, owner_name=NULL, purchased=0, is_open=0, authorised=NULL, safe_balance=0 WHERE id=?',
            { vanId },
            function()
                local msg = balance > 0
                    and ('Location sold! $%d from the safe has been paid to your bank.'):format(balance)
                    or  'Location put back up for sale.'
                TriggerClientEvent('mnc-foodvans:client:notify', src, msg, 'success')
                SyncStates()
            end
        )
    end)
end)

print('^2[mnc-foodvans]^7 Script loaded successfully!')