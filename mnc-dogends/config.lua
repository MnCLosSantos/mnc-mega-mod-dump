-- config.lua
Config = {}

Config.Debug = false

Config.CoreName    = 'qb-core'
Config.Target      = 'qb-target'
Config.Inventory   = 'qb-inventory'
Config.Notify      = 'ox_lib'

Config.PickupItem      = 'cig_butt'
Config.PickupAmount    = 1

Config.LighterItem = 'lighter'
Config.LighterAmount = 1
Config.RequiredButts   = 5                   -- for butts path
Config.TobaccoPerRoll  = 0.5                 -- grams per roll_up when using tobacco

-- rolling paper item 
Config.RollingPaper    = 'paper'
Config.RollItem        = 'rolling_machine'   -- usable item
Config.OutputItems = {
    default     = 'roll_up',                 -- used for normal/slim filters & butts path
    mint        = 'roll_up_mint',            -- only when filter_pack_mint is used
}

Config.SearchTime      = 3500
Config.RollTime        = 8000                -- a bit longer now

Config.PropModels = {
    `ng_proc_cigbuts01a`,
    `ng_proc_cigbuts02a`,
    `ng_proc_cigbuts03a`,
    `prop_fib_ashtray_01`,
    `v_ret_fh_ashtray`,
    `prop_ashtray_01`,
    `v_res_mp_ashtrayb`,
}

Config.LighterModels = {
    `p_cs_lighter_01`,
    `m25_2_prop_m52_lighter_02a`,
    `m25_2_prop_m52_lighter_01a`,
    `ex_prop_exec_lighter_01`,
	`v_res_tt_lighter`,
}

-- Tobacco pouch sizes → max roll_ups
Config.TobaccoPouches = {
    tobacco_classic_125 = { grams = 12.5,  max_rolls = 30 },
    tobacco_normal_125  = { grams = 12.5,  max_rolls = 30 },
    tobacco_mature_125  = { grams = 12.5,  max_rolls = 30 },
    tobacco_classic_30  = { grams = 30,   max_rolls = 60  },
    tobacco_normal_30   = { grams = 30,   max_rolls = 60  },
    tobacco_mature_30   = { grams = 30,   max_rolls = 60  },
    tobacco_classic_50  = { grams = 50,   max_rolls = 100 },
    tobacco_normal_50   = { grams = 50,   max_rolls = 100 },
    tobacco_mature_50   = { grams = 50,   max_rolls = 100 },
}

-- Filter packs → max filters
Config.FilterPacks = {
    filter_pack_slim   = 45,
    filter_pack_normal = 30,
    filter_pack_mint   = 25,
}

Config.Minigame = {
    Enabled    = true,
    Type       = "wasd",
    Difficulty = {"easy", "easy", "medium"},
}

Config.PickupSounds = { "PICKUP_LOW", "CLOTH_PICKUP", "PICKUP_WEAPON_UNARMED" }