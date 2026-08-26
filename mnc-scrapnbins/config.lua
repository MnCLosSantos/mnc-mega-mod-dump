Config = {}
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
                        --✅ Core and system integrations
Config.CoreName =   'qb-core'                                -- ox is backwards compatible, ESX NOT SUPPORTED
Config.Target =     "qb-target"                              -- "qb-target" or "ox_target"
Config.Inventory =  "qb-inventory"                           -- "qb-inventory" or "ox_inventory"
Config.Notify =     "ox_lib"                                 -- "qb" or "ox_lib"
Config.Progress =   "ox_lib_bar"                             -- "qb", "ox_lib_bar", "ox_lib_circle"

-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
                              --✅ Minigame settings
Config.Minigame = {
    Enabled = true,                                          -- Enable/disable minigame requirement
    BinSkip = {
        Type = "wasd",                                       -- "wasd" or "1234"
        Difficulty = {"easy", "easy", "easy", "easy" },      -- Skill check difficulty use {"easy", "medium", "hard"} for even harder options
        Duration = 5000                                      -- ms for minigame
    },
    Scrap = {
        Type = "1234",                                       -- "wasd" or "1234"
        Difficulty = {"medium", "easy", "medium", "easy"},   -- Skill check difficulty use {"easy", "medium", "hard"} for even harder options
        Duration = 6000                                      -- ms for minigame
    }
}

-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
                             -- ✅ Main settings
Config.SearchTime = 8000                                     -- ms (time to search)
Config.Cooldown = 45000                                      -- ms cooldown per entity
Config.ChanceToFind = 70                                     -- 70% chance to find item
Config.MaxAmount = 3                                         -- max item quantity found
Config.Debug = false                                         -- debug prints

-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
                          -- ✅ Tiered loot system
Config.Tiers = {
    Common = {
        Chance = 70,
        Items = {'plastic', 'metal_scrap', 'rubber', 'tosti', 'glass'}
    },
    Uncommon = {
        Chance = 25,
        Items = {'aluminum', 'steel', 'copper', 'lockpick', 'lighter'}
    },
    Rare = {
        Chance = 5,
        Items = {'advancedlockpick', 'repairkit', 'joint', 'pistol_ammo'}
    }
}

-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
                     -- ✅ Bin & Trash-Related Props
Config.BinModels = {
    -- Standard bins
    `prop_bin_01a`, `prop_bin_02a`, `prop_bin_03a`, `prop_bin_04a`, `prop_bin_05a`, `prop_bin_06a`,
    `prop_bin_07a`, `prop_bin_07b`, `prop_bin_07c`, `prop_bin_08a`, `prop_bin_08open`,
    `prop_bin_09a`, `prop_bin_10a`, `prop_bin_11a`, `prop_bin_14a`, `prop_bin_14b`,
    `prop_bin_14c`, `prop_bin_14d`, `prop_bin_14e`, `prop_bin_14f`,
    `prop_bin_15a`, `prop_bin_16a`, `prop_bin_18a`,

    -- Special / location-specific bins
    `prop_bin_beach_01d`, `prop_bin_delpiero`, `prop_bin_warehouse_01a`,

    -- Recycle bins
    `prop_recyclebin_01a`, `prop_recyclebin_02a`, `prop_recyclebin_02b`, `prop_recyclebin_02_c`,
    `prop_recyclebin_03_a`, `prop_recyclebin_04_a`, `prop_recyclebin_05_a`,
    `prop_recyclebin_01b`, `prop_recyclebin_01c`,
    
    -- Trash bags
    `prop_trash_binbag_01`, `prop_trash_binbag_02`, `prop_trash_binbag_03`,
    `prop_trash_binbag_04`, `prop_trash_binbag_05`, `prop_trash_binbag_06`,
    `prop_trash_binbag_07`, `prop_trash_binbag_08`, `prop_trash_binbag_09`,
    `prop_cs_rub_binbag_01`, `prop_cs_rub_binbag_02`,

    -- Loose trash piles
    `prop_rub_bike_01`, `prop_rub_pile_01`, `prop_rub_pile_02`, `prop_rub_pile_03`,
    `prop_rub_pile_04`, `prop_rub_pile_05`, `prop_rub_pile_06`, `prop_rub_pile_07`, `prop_rub_pile_08`,
    `prop_rub_trolley01a`,

    -- Dumpsters
    `prop_dumpster_01a`, `prop_dumpster_02a`, `prop_dumpster_02b`,
    `prop_dumpster_3a`, `prop_dumpster_4a`, `prop_dumpster_4b`,
    `prop_dumpster_01a_l2`, `prop_dumpster_02b_l1`,
    `prop_cs_dumpster_01a`
}

-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
                       -- ✅ Scrap Yard Vehicle Wrecks 
Config.ScrapModels = {
    `prop_rub_carwreck_1`, `prop_rub_carwreck_2`, `prop_rub_carwreck_3`,
    `prop_rub_carwreck_4`, `prop_rub_carwreck_5`, `prop_rub_carwreck_6`,
    `prop_rub_carwreck_7`, `prop_rub_carwreck_8`, `prop_rub_carwreck_9`,
    `prop_rub_carwreck_10`, `prop_rub_carwreck_11`, `prop_rub_carwreck_12`,
    `prop_rub_carwreck_13`, `prop_rub_carwreck_14`, `prop_rub_carwreck_15`,
    `prop_rub_carwreck_16`,
    
    -- Additional wreck variations
    `prop_rub_carwreck_17`, `prop_rub_carwreck_18`, `prop_rub_carwreck_19`,
    `prop_rub_carwreck_20`,

    -- Large junkyard objects
    `prop_rub_scrap_01`, `prop_rub_scrap_02`, `prop_rub_scrap_03`, `prop_rub_scrap_04`,

    -- Burnt / destroyed vehicles
    `prop_burnt_ambulance`, `prop_burnt_bike_01`, `prop_burnt_car_01`,
    `prop_burnt_truck_01`, `prop_burnt_truck_02`,
    `prop_rub_trukwreck_1`, `prop_rub_trukwreck_2`,

    -- Industrial junk
    `prop_rub_litter_01`, `prop_rub_litter_03`
}

-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
                         -- ✅ Rummage Sound Sets
Config.RummageSounds = {
    Bin = {
        "Dumpster_Empty", "Bag_Structure_Small", "BAG_DROP",
        "CLOTH_PICKUP", "PICKUP_LOW", "PICKUP_WEAPON_UNARMED"
    },

    Scrap = {
        "CAR_DOOR_OPEN", "CAR_METAL_CLUNK", "WOOD_CRUNCH",
        "COLLECT_PICKUP", "RUMBLE_SMALL", "RUMBLE_FOREST"
    },

    Skip = {
        "COLLECT_BOTTLE", "CRATE_RATTLE", "CRATE_PICKUP",
        "PICKUP_WEAPON_PISTOL", "CRUNCH", "SPLINTER"
    },

    Bag = {
        "PICKUP_LOW", "BAG_DROP", "CLOTH_PICKUP",
        "PICKUP_WEAPON_UNARMED"
    }
}

-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --

-- Needle / injury chance when searching BINS only
Config.NeedlePrick = {
    Enabled           = true,
    Chance            = 10,              -- % chance per successful BIN search (only bins, not scrap)
    HealthDrain       = 15,             -- total health points to lose
    DrainTicks        = 5,              -- number of damage applications
    TickInterval      = 1600,           -- ms between each damage tick

    NotifyMessage     = "You pricked your finger on a used needle!",
    NotifyType        = "error",

    -- Visual & reaction
    BloodScreenEffect    = "DeathFailMPIn",     -- red vignette + damage feel
    BloodEffectDuration  = 3500,                -- ms

    ExtraShake           = true,
    ShakeAmplitude       = 0.4,
    ShakeDuration        = 1800,                -- ms

    -- Pain reaction animation
    PainAnimDict = "missheistdockssetup1ig@talk",
    PainAnimName = "pain_idle",
    PainAnimDuration  = 1200,                   -- ms (keep short)
    PainAnimFlag      = 49                      -- upper body only
}

Config.NeedleSounds = {
    "WASTED",
    "Bed",
    "Pain",
    "DLC_HEIST_BIOLAB_DELIVER_EMP_SOUNDS"
}

-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --
-- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- ---- -- -- -- --