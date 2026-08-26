local QBCore = exports['qb-core']:GetCoreObject()

-- Helpers with fallback for fresh items (no metadata yet)
local function GetRemainingTobacco(item)
    if item.info and item.info.remaining_grams ~= nil then
        return item.info.remaining_grams
    end
    local pouchConfig = Config.TobaccoPouches[item.name]
    return pouchConfig and pouchConfig.grams or 0
end

local function GetRemainingFilters(item)
    if item.info and item.info.remaining_filters ~= nil then
        return item.info.remaining_filters
    end
    local packConfig = Config.FilterPacks[item.name]
    return packConfig or 0
end

-- Pickup cigarette butts (FIXED: use export instead of removed CanAddItem)
RegisterNetEvent('mnc-dogends:finishPickup', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local item   = Config.PickupItem
    local amount = Config.PickupAmount

    if not QBCore.Shared.Items[item] then
        TriggerClientEvent('ox_lib:notify', src, {
            description = "Item config error (" .. item .. " not found).",
            type = "error"
        })
        return
    end

    -- Modern qb-inventory check (most 2024–2026 versions use this export)
    local canCarry = exports['qb-inventory']:CanAddItem(src, item, amount)

    if canCarry then
        Player.Functions.AddItem(item, amount, false)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add')
        TriggerClientEvent('ox_lib:notify', src, {
            description = string.format("Picked up %sx %s", amount, QBCore.Shared.Items[item].label),
            type = "success"
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            description = "Your inventory is full!",
            type = "error"
        })
    end
end)

-- Rolling machine usable item
QBCore.Functions.CreateUseableItem(Config.RollItem, function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Check for rolling paper
    if Player.Functions.GetItemByName(Config.RollingPaper) == nil then
        TriggerClientEvent('ox_lib:notify', src, {
            description = "You need at least 1 rolling paper.",
            type = "error"
        })
        return
    end

    -- Check if player has ANY valid way to roll
    local hasButts   = false
    local hasTobacco = false

    local buttsItem = Player.Functions.GetItemByName(Config.PickupItem)
    if buttsItem and buttsItem.amount >= Config.RequiredButts then
        hasButts = true
    end

    for name in pairs(Config.TobaccoPouches) do
        local tob = Player.Functions.GetItemByName(name)
        if tob and GetRemainingTobacco(tob) >= Config.TobaccoPerRoll then
            hasTobacco = true
            break
        end
    end

    if not hasButts and not hasTobacco then
        TriggerClientEvent('ox_lib:notify', src, {
            description = "You don't have enough butts or usable tobacco to roll anything.",
            type = "error"
        })
        return
    end

    -- Tell client to open the method selection menu
    TriggerClientEvent('mnc-dogends:openRollingMenu', src)
end)

-- Show remaining when using tobacco or filter packs
for pouchName in pairs(Config.TobaccoPouches) do
    QBCore.Functions.CreateUseableItem(pouchName, function(source, item)
        local src = source
        local remaining = GetRemainingTobacco(item)
        local rollsLeft = math.floor(remaining / Config.TobaccoPerRoll)
        TriggerClientEvent('ox_lib:notify', src, {
            description = string.format("%s - %.1fg remaining (~%d rolls left)", QBCore.Shared.Items[pouchName].label, remaining, rollsLeft),
            type = "inform"
        })
    end)
end

for filterName in pairs(Config.FilterPacks) do
    QBCore.Functions.CreateUseableItem(filterName, function(source, item)
        local src = source
        local remaining = GetRemainingFilters(item)
        TriggerClientEvent('ox_lib:notify', src, {
            description = string.format("%s - %d filters remaining", QBCore.Shared.Items[filterName].label, remaining),
            type = "inform"
        })
    end)
end

-- Final rolling logic - now supports multiple
-- Final rolling logic - supports multiple cigarettes + mint variant
RegisterNetEvent('mnc-dogends:finishRolling', function(method, tobaccoType, filterType, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    amount = math.max(1, math.min(10, amount or 1))  -- safety clamp

    -- Consume rolling papers
    if not Player.Functions.RemoveItem(Config.RollingPaper, amount) then
        TriggerClientEvent('ox_lib:notify', src, {
            description = "You don't have enough rolling papers for " .. amount .. " cigarette" .. (amount > 1 and "s" or ""),
            type = "error"
        })
        return
    end

    -- Check filter pack (needs at least amount filters remaining)
    local filterItem = Player.Functions.GetItemByName(filterType)
    if not filterItem or GetRemainingFilters(filterItem) < amount then
        TriggerClientEvent('ox_lib:notify', src, {
            description = "Not enough filters left in selected pack (" .. amount .. " needed).",
            type = "error"
        })
        Player.Functions.AddItem(Config.RollingPaper, amount) -- rollback papers
        return
    end

    local success = false
    local usedMsg = ""

    if method == "butts" then
        local neededButts = Config.RequiredButts * amount
        if Player.Functions.RemoveItem(Config.PickupItem, neededButts) then
            success = true
            usedMsg = string.format("Used %d cigarette butts", neededButts)
        else
            usedMsg = "Not enough cigarette butts"
        end
    else
        -- Tobacco path
        local pouch = Player.Functions.GetItemByName(tobaccoType)
        if not pouch then
            TriggerClientEvent('ox_lib:notify', src, {
                description = "Tobacco pouch disappeared.",
                type = "error"
            })
            Player.Functions.AddItem(Config.RollingPaper, amount)
            return
        end

        local currentGrams = GetRemainingTobacco(pouch)
        local neededGrams = Config.TobaccoPerRoll * amount

        if currentGrams < neededGrams then
            TriggerClientEvent('ox_lib:notify', src, {
                description = "Not enough tobacco left (" .. string.format("%.1fg", neededGrams) .. " needed).",
                type = "error"
            })
            Player.Functions.AddItem(Config.RollingPaper, amount)
            return
        end

        local newGrams = currentGrams - neededGrams
        local newInfo = pouch.info or {}
        newInfo.remaining_grams = math.max(0, newGrams)
        newInfo.description = string.format(
            "%s - %.1fg remaining (~%d rolls left)",
            QBCore.Shared.Items[tobaccoType].label,
            newGrams,
            math.floor(newGrams / Config.TobaccoPerRoll)
        )

        Player.Functions.RemoveItem(tobaccoType, 1, pouch.slot)
        Player.Functions.AddItem(tobaccoType, 1, pouch.slot, newInfo)

        success = true
        usedMsg = string.format("Used %.1fg of %s", neededGrams, QBCore.Shared.Items[tobaccoType].label)
    end

    if success then
        -- Consume filters (decrease remaining count)
        local filterInfo = filterItem.info or {}
        filterInfo.remaining_filters = GetRemainingFilters(filterItem) - amount
        filterInfo.description = string.format(
            "%s - %d filters remaining",
            QBCore.Shared.Items[filterType].label,
            filterInfo.remaining_filters
        )

        Player.Functions.RemoveItem(filterType, 1, filterItem.slot)
        Player.Functions.AddItem(filterType, 1, filterItem.slot, filterInfo)

        -- Decide which cigarette to output (mint variant when using mint filters)
        local outputItem = Config.OutputItems.default or 'roll_up'
        if filterType == 'filter_pack_mint' then
            outputItem = Config.OutputItems.mint or 'roll_up_mint'
        end

        -- Give the rolled cigarettes
        Player.Functions.AddItem(outputItem, amount, false)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[outputItem], 'add')

        -- Success message with correct cigarette name
        local cigaretteLabel = QBCore.Shared.Items[outputItem].label
        TriggerClientEvent('ox_lib:notify', src, {
            description = string.format("Rolled %d× %s! %s", amount, cigaretteLabel, usedMsg),
            type = "success"
        })
    else
        -- Rollback papers only on consumption failure (not inventory full etc.)
        Player.Functions.AddItem(Config.RollingPaper, amount)
        TriggerClientEvent('ox_lib:notify', src, {
            description = "Failed to roll cigarettes: " .. usedMsg,
            type = "error"
        })
    end
end)

-- Pickup lighter
RegisterNetEvent('mnc-dogends:finishPickupLighter', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local item   = Config.LighterItem
    local amount = Config.LighterAmount

    if not QBCore.Shared.Items[item] then
        TriggerClientEvent('ox_lib:notify', src, {
            description = "Item config error (" .. item .. " not found).",
            type = "error"
        })
        return
    end

    -- Modern qb-inventory check
    local canCarry = exports['qb-inventory']:CanAddItem(src, item, amount)

    if canCarry then
        Player.Functions.AddItem(item, amount, false)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add')
        TriggerClientEvent('ox_lib:notify', src, {
            description = string.format("Picked up %sx %s", amount, QBCore.Shared.Items[item].label),
            type = "success"
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            description = "Your inventory is full!",
            type = "error"
        })
    end
end)

print("^2[mnc-dogends]^0 Server-side loaded successfully")