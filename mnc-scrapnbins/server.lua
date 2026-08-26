local QBCore = exports[Config.CoreName]:GetCoreObject()

-- ✅ Finish search event (FIXED: Proper item validation + inventory checks)
RegisterNetEvent("mnc-scrapnbins:finishSearch", function(type)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Nothing found
    if math.random(1, 100) > Config.ChanceToFind then
        if Config.Notify == "qb" then
            TriggerClientEvent('QBCore:Notify', src, "You found nothing.", "error")
        else
            TriggerClientEvent('ox_lib:notify', src, {description = "You found nothing.", type = "error"})
        end
        return
    end

    -- Determine tier (FIXED: Cumulative chances)
    local roll = math.random(1, 100)
    local tier
    if roll <= Config.Tiers.Rare.Chance then
        tier = Config.Tiers.Rare
    elseif roll <= (Config.Tiers.Rare.Chance + Config.Tiers.Uncommon.Chance) then
        tier = Config.Tiers.Uncommon
    else
        tier = Config.Tiers.Common
    end

    local item = tier.Items[math.random(1, #tier.Items)]
    local amount = math.random(1, Config.MaxAmount)

    -- Validate item exists in QBCore
    if not QBCore.Shared.Items[item] then
        if Config.Debug then
            print(string.format("Invalid item '%s' attempted to be added for player %d", item, src))
        end
        if Config.Notify == "qb" then
            TriggerClientEvent('QBCore:Notify', src, "Something went wrong, item not found.", "error")
        else
            TriggerClientEvent('ox_lib:notify', src, {description = "Something went wrong, item not found.", type = "error"})
        end
        return
    end

    -- Add item based on inventory
    if Config.Inventory == "qb-inventory" then
        -- Check if item can be added
        local canAdd = Player.Functions.CanAddItem and Player.Functions.CanAddItem(item, amount) or true
        if not canAdd then
            if Config.Notify == "qb" then
                TriggerClientEvent('QBCore:Notify', src, "Inventory full!", "error")
            else
                TriggerClientEvent('ox_lib:notify', src, {description = "Inventory full!", type = "error"})
            end
            return
        end

        if Player.Functions.AddItem(item, amount) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "add")
            if Config.Notify == "qb" then
                TriggerClientEvent('QBCore:Notify', src, "You found "..amount.."x "..QBCore.Shared.Items[item].label.."!", "success")
            else
                TriggerClientEvent('ox_lib:notify', src, {description = "You found "..amount.."x "..QBCore.Shared.Items[item].label.."!", type = "success"})
            end
        else
            if Config.Debug then
                print(string.format("Failed to add item '%s' (amount: %d) for player %d", item, amount, src))
            end
            if Config.Notify == "qb" then
                TriggerClientEvent('QBCore:Notify', src, "Failed to add item!", "error")
            else
                TriggerClientEvent('ox_lib:notify', src, {description = "Failed to add item!", type = "error"})
            end
        end
    elseif Config.Inventory == "ox_inventory" then
        local added = exports.ox_inventory:AddItem(src, item, amount)
        if added then
            TriggerClientEvent('ox_lib:notify', src, {description = "You found "..amount.."x "..(QBCore.Shared.Items[item].label or item).."!", type = "success"})
        else
            if Config.Debug then
                print(string.format("ox_inventory failed to add item '%s' (amount: %d) for player %d", item, amount, src))
            end
            TriggerClientEvent('ox_lib:notify', src, {description = "Inventory full!", type = "error"})
        end
    end
end)

print("^2[mnc-scrapnbins]^7 Script loaded successfully!")