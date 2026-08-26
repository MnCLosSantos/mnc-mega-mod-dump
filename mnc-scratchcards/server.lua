local QBCore = exports['qb-core']:GetCoreObject()

local function startScratch(src, itemName, slot)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local item = Player.Functions.GetItemBySlot(slot)
    if not item or item.name ~= itemName then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Scratch Card',
            description = 'Item not found in your inventory.',
            type = 'error'
        })
        return
    end

    local cfg = Config.ScratchItems[itemName]
    if not cfg then return end

    -- Remove the scratch card
    Player.Functions.RemoveItem(itemName, 1, slot)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')

    -- Calculate win (chances are percentages, roll is 0.0–1.0)
    local won = 0
    local roll = math.random()

    for _, pattern in ipairs(cfg.winPatterns) do
        if roll <= (pattern.chance / 100) then  -- ✅ Bug 2 fixed
            won = pattern.reward
            break
        end
        roll = roll - (pattern.chance / 100)
    end

    TriggerClientEvent('mnc-scratchcards:client:showScratch', src, itemName, { won = won })
end

-- Keep as a net event so it can still be triggered remotely if needed
RegisterNetEvent('mnc-scratchcards:server:startScratch', function(itemName, slot)
    startScratch(source, itemName, slot)
end)

-- Client finished scratching → give money
RegisterNetEvent('mnc-scratchcards:server:claimReward', function(itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local cfg = Config.ScratchItems[itemName]
    if not cfg then return end

    local valid = false
    for _, p in ipairs(cfg.winPatterns) do
        if amount == p.reward then
            valid = true
            break
        end
    end

    if amount > 0 and valid then
        Player.Functions.AddMoney('cash', amount, 'scratchcard-win')
        TriggerClientEvent('mnc-scratchcards:client:giveReward', src, amount)
    else
        TriggerClientEvent('mnc-scratchcards:client:giveReward', src, 0)
    end
end)

for itemName, _ in pairs(Config.ScratchItems) do
    QBCore.Functions.CreateUseableItem(itemName, function(source, item)
        startScratch(source, item.name, item.slot)
    end)
end

print("^2[mnc-scratchcards] Server loaded successfully^7")