-- server.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Complete list of all default QBCore weapon item names
local weapons = {
    -- Melee
    "weapon_unarmed", "weapon_dagger", "weapon_bat", "weapon_bottle", "weapon_crowbar",
    "weapon_flashlight", "weapon_golfclub", "weapon_hammer", "weapon_hatchet", "weapon_knuckle",
    "weapon_knife", "weapon_machete", "weapon_switchblade", "weapon_nightstick", "weapon_wrench",
    "weapon_battleaxe", "weapon_poolcue", "weapon_stone_hatchet",

    -- Handguns
    "weapon_pistol", "weapon_pistol_mk2", "weapon_combatpistol", "weapon_appistol",
    "weapon_stungun", "weapon_pistol50", "weapon_snspistol", "weapon_snspistol_mk2",
    "weapon_heavypistol", "weapon_vintagepistol", "weapon_flaregun", "weapon_marksmanpistol",
    "weapon_revolver", "weapon_revolver_mk2", "weapon_doubleaction", "weapon_raypistol",
    "weapon_ceramicpistol", "weapon_navyrevolver", "weapon_gadgetpistol",

    -- SMGs / Machine Pistols
    "weapon_microsmg", "weapon_smg", "weapon_smg_mk2", "weapon_assaultsmg",
    "weapon_combatpdw", "weapon_machinepistol", "weapon_minismg", "weapon_raycarbine",

    -- Shotguns
    "weapon_pumpshotgun", "weapon_pumpshotgun_mk2", "weapon_sawnoffshotgun",
    "weapon_assaultshotgun", "weapon_bullpupshotgun", "weapon_musket",
    "weapon_heavyshotgun", "weapon_dbshotgun", "weapon_autoshotgun",

    -- Assault Rifles
    "weapon_assaultrifle", "weapon_assaultrifle_mk2", "weapon_carbinerifle",
    "weapon_carbinerifle_mk2", "weapon_advancedrifle", "weapon_specialcarbine",
    "weapon_specialcarbine_mk2", "weapon_bullpuprifle", "weapon_bullpuprifle_mk2",
    "weapon_compactrifle",

    -- LMGs
    "weapon_mg", "weapon_combatmg", "weapon_combatmg_mk2", "weapon_gusenberg",

    -- Sniper Rifles
    "weapon_sniperrifle", "weapon_heavysniper", "weapon_heavysniper_mk2",
    "weapon_marksmanrifle", "weapon_marksmanrifle_mk2",

    -- Heavy Weapons
    "weapon_rpg", "weapon_grenadelauncher", "weapon_grenadelauncher_smoke",
    "weapon_minigun", "weapon_firework", "weapon_railgun", "weapon_hominglauncher",
    "weapon_compactlauncher", "weapon_rayminigun",

    -- Throwables
    "weapon_grenade", "weapon_bzgas", "weapon_molotov", "weapon_stickybomb",
    "weapon_proxmine", "weapon_snowball", "weapon_pipebomb", "weapon_ball",
    "weapon_smokegrenade", "weapon_flare",

    -- Miscellaneous
    "weapon_petrolcan", "weapon_hazardcan", "weapon_fireextinguisher"
}

-- Callback to check if player has a weapon
QBCore.Functions.CreateCallback('mnc-robnpc:server:HasWeapon', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    for _, weapon in ipairs(weapons) do
        if Player.Functions.GetItemByName(weapon) then
            cb(true)
            return
        end
    end
    cb(false)
end)

-- Tracks the last time each player successfully collected robbery loot.
-- This is a server-side backstop against spam/replay of the payout event
-- (e.g. from a modified client firing it directly) on top of the client-side
-- per-ped lock in client.lua.
local lastRobbery = {}

-- weaponLoot (optional) = { item = 'weapon_knife' } or
-- { item = 'weapon_pistol', ammoItem = 'pistol_ammo', ammoAmount = 10 }
-- Sent when the player kills a ped that resisted the robbery, so the weapon
-- it fought back with (and its ammo) is added on top of the usual loot.
RegisterServerEvent('mnc-robnpc:server:GiveCash', function(coords, weaponLoot)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local now = GetGameTimer()
    if lastRobbery[src] and (now - lastRobbery[src]) < Config.RobDuration then
        return -- ignore payouts that arrive faster than a legitimate robbery could finish
    end
    lastRobbery[src] = now

    local cashAmount = math.random(Config.MinCash, Config.MaxCash)

    -- Give regular cash
    if Config.RobLoot.guaranteedCash or math.random(100) <= Config.RobLoot.cashChance then
        Player.Functions.AddMoney('cash', cashAmount)
    end

    -- Random items logic
    local itemsGiven = {}

    -- Shuffle items table so order doesn't affect probability
    local shuffledItems = {}
    for _, itemData in ipairs(Config.RobLoot.items) do
        table.insert(shuffledItems, itemData)
    end
    for i = #shuffledItems, 2, -1 do
        local j = math.random(i)
        shuffledItems[i], shuffledItems[j] = shuffledItems[j], shuffledItems[i]
    end

    local itemsAddedCount = 0

    for _, loot in ipairs(shuffledItems) do
        if itemsAddedCount >= Config.RobLoot.maxExtraItems then
            break
        end

        if math.random(100) <= loot.chance then
            local amount = math.random(loot.min, loot.max)
            if Player.Functions.AddItem(loot.item, amount) then
                -- Optional: show nice item box notification
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[loot.item], 'add', amount)
                table.insert(itemsGiven, {label = QBCore.Shared.Items[loot.item].label, amount = amount})
                itemsAddedCount = itemsAddedCount + 1
            end
        end
    end

    -- Bonus loot from killing a resisting ped: their weapon (+ ammo for a gun)
    if weaponLoot and weaponLoot.item and QBCore.Shared.Items[weaponLoot.item] then
        if Player.Functions.AddItem(weaponLoot.item, 1) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[weaponLoot.item], 'add', 1)
            table.insert(itemsGiven, {label = QBCore.Shared.Items[weaponLoot.item].label, amount = 1})
        end

        if weaponLoot.ammoItem and weaponLoot.ammoAmount and QBCore.Shared.Items[weaponLoot.ammoItem] then
            if Player.Functions.AddItem(weaponLoot.ammoItem, weaponLoot.ammoAmount) then
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[weaponLoot.ammoItem], 'add', weaponLoot.ammoAmount)
                table.insert(itemsGiven, {label = QBCore.Shared.Items[weaponLoot.ammoItem].label, amount = weaponLoot.ammoAmount})
            end
        end
    end

    -- Send success notification with summary
    TriggerClientEvent('mnc-robnpc:client:MoneyReceived', src, cashAmount, itemsGiven)

    -- Notify players with configured jobs (unchanged)
    local Players = QBCore.Functions.GetQBPlayers()
    for _, v in pairs(Players) do
        for _, job in ipairs(Config.NotifyJobs) do
            if v.PlayerData.job.name == job then
                TriggerClientEvent('mnc-robnpc:client:NotifyRobbery', v.PlayerData.source, coords)
                break
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    lastRobbery[source] = nil
end)

print("^2[mnc-robnpc]^7 Script loaded successfully!")
