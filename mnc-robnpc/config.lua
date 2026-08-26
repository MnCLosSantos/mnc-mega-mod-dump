-- config.lua
Config = {}

Config.NotifyJobs = {"police"}  -- Jobs that will receive notifications about robberies

Config.MinCash = 10  -- Minimum amount of cash stolen
Config.MaxCash = 100  -- Maximum amount of cash stolen

Config.RobLoot = {
    guaranteedCash = true,          -- always give cash (already existing)
    cashChance = 100,               -- 100% chance for cash (you can lower it)

    items = {
        { item = "water_bottle",   min = 1,  max = 3,  chance = 45 },   -- 45% chance
        { item = "sandwich",       min = 1,  max = 2,  chance = 35 },
        { item = "phone",          min = 1,  max = 1,  chance = 15 },
        { item = "lockpick",       min = 1,  max = 2,  chance = 25 },
        { item = "bandage",        min = 1,  max = 3,  chance = 20 },
        { item = "pistol_ammo",    min = 1,  max = 4,  chance = 5  },   -- rare
		{ item = "weapon_pistol",  min = 1,  max = 4,  chance = 2  },   -- rare
    },

    maxExtraItems = 4,  -- max number of different item types player can get (besides cash)
}

Config.RobDuration = 10000  -- Duration of the robbery progress bar in ms

-- Chance for the ped to resist
Config.PedResistance = {
    stabChance = 3,   -- % chance the ped pulls a knife and fights back
    shootChance = 7,  -- % chance the ped pulls a pistol and fights back

    -- If the player kills a resisting ped, the ped's weapon is added to the
    -- normal cash/item robbery loot (knife for a stab, pistol + ammo for a shooting).
    shootAmmoMin = 5,   -- min pistol_ammo given when looting a killed "shoot" ped
    shootAmmoMax = 15,  -- max pistol_ammo given when looting a killed "shoot" ped
}

Config.NotifyDuration = 10000  -- Duration to show the notification and listen for E press in ms

Config.BlipTime = 24  -- Time in seconds the blip stays on the map

Config.NotifyMessage = "🚨 Local robbery in progress at %s - Press [R] to respond!"  -- %s for location

Config.BlipSprite = 161  -- Blip sprite ID
Config.BlipColour = 1  -- Blip color (1 = red)
Config.BlipScale = 1.0  -- Blip scale
Config.BlipLabel = "Local Robbery"  -- Blip label
Config.BlipShortRange = false  -- Short range blip
