Config = {}

-- Debug settings
Config.DebugMode       = false
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- Main settings
Config.PuffsPerMl      = 25      -- max amount of puffs per 1ml of vape juice
Config.ChargeTime      = 80000   -- how long batterys take to charge
Config.FillTime        = 10000   -- how long it takes to refill a vape tank
Config.CoilInstallTime = 5000    -- how long it takes to install coil
Config.TankInstallTime = 5000    -- how long it takes to install tank
Config.PuffCooldown    = 5000    -- how long player must wait between puffs
Config.PropBone        = 18905   -- prop bone left hand
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- Job locked or public juice crafting location 
-- MLO USED: https://www.gta5-mods.com/maps/mlo-legion-weed-clinic
Config.CraftingStations = {
    {
        coords   = vector3(377.54, -820.07, 29.3),   -- where prop spawns
        heading  = 90.0,                             -- prop rotation
        label    = 'Vape Juice Station',              -- qb-target label
        job      = 'bestbudz',                        -- job ristriction
        minGrade = 0,                                 -- grade ristriction
        prop     = 'v_ret_ml_tablea',                 -- prop used
    },
	{
        coords   = vector3(481.46, -570.84, 28.92),
        heading  = 85.0,
        label    = 'Vape Juice Station',
        prop     = 'v_ret_ml_tablea',
    },
	-- {
        -- coords   = vector3(2984.09, 4462.66, 48.64),  
        -- heading  = 180.0,                             
        -- label    = 'Vape Juice Station',              
        -- job      = 'vapeshop',                        
        -- minGrade = 0,                                 
        -- prop     = 'v_ret_ml_tablea',                 
    -- },
	-- Add more if needed
}

-- Job locked or public vape crafting location
Config.VapeCraftingStations = {
    {
        coords   = vector3(376.98, -821.65, 29.3),   
        heading  = 180.0,
        label    = 'Vape Crafting Station',
        job      = 'bestbudz',
        minGrade = 2,
        prop     = 'h4_prop_h4_table_isl_01a',
    },
	{
        coords   = vector3(481.0, -576.1, 28.92), 
        heading  = 85.0,
        label    = 'Vape Crafting Station',
        prop     = 'h4_prop_h4_table_isl_01a',
    },
	-- {
        -- coords   = vector3(4590.01, 5076.01, 7.24), 
        -- heading  = 180.0,
        -- label    = 'Vape Crafting Station',
        -- job      = 'vapeshop',
        -- minGrade = 0,
        -- prop     = 'h4_prop_h4_table_isl_01a',
    -- },
    -- Add more if needed
}

-- Job locked or public concentrate crafting location
Config.ConcentrateCraftingStations = {
    {
        coords   = vector3(379.15, -822.14, 29.3),   -- Adjust as needed (near other vapeshop stations)
        heading  = 180.0,
        label    = 'Concentrate Station',
        job      = 'bestbudz',
        minGrade = 0,
        prop     = 'v_ret_ml_tablea',
    },
    {
        coords   = vector3(479.51, -572.56, 28.92),
        heading  = 85.0,
        label    = 'Concentrate Station',
        prop     = 'v_ret_ml_tablea',
    },
	-- {
        -- coords   = vector3(4591.01, 5077.01, 7.24),
        -- heading  = 180.0,
        -- label    = 'Concentrate Station',
        -- job      = 'vapeshop2',
        -- minGrade = 0,
        -- prop     = 'v_ret_ml_tablea',
    -- },
    -- Add more if needed
}
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- Placeable juice crafting table
Config.PlaceableTableItem  = 'juice_table'       -- qb-target tabel
Config.TableProp           = 'v_ret_ml_tablea'   -- prop used
Config.TableModel          = `v_ret_ml_tablea`   -- model used
Config.TablePickupDistance = 2.2                 -- distance to interact

-- Placeable vape crafting table 
Config.PlaceableVapeTableItem  = 'vape_table'                
Config.VapeTableProp           = 'h4_prop_h4_table_isl_01a'  
Config.VapeTableModel          = `h4_prop_h4_table_isl_01a`  
Config.VapeTablePickupDistance = 2.2                        

-- Placeable concentrate table config
Config.PlaceableConcentrateTableItem  = 'concentrate_table'
Config.ConcentrateTableProp           = 'v_ret_ml_tablea'
Config.ConcentrateTableModel          = `v_ret_ml_tablea`
Config.ConcentrateTablePickupDistance = 2.2
Config.MaxConcentrateTables = 2
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- Tank options
Config.Tanks = {
    ['5ml_tank']  = {      -- tank item name
	  label = '5ml Tank',  -- tank label in menu
	  size = 5             -- ml the tank holds
	},
    ['8ml_tank']  = {      -- tank item name
	  label = '8ml Tank',  -- tank label in menu  
	  size = 8             -- ml the tank holds
	},
    ['12ml_tank'] = {       -- tank item name
	  label = '12ml Tank',  -- tank label in menu 
	  size = 12             -- ml the tank holds
	},
}
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- Vape settings
Config.Vapes = {
    ['dispo_vape'] = {                          -- item name
        label = 'Disposable Vape',              -- menu label
        prop = 'ba_prop_battle_vape_01',        -- prop used
        tankSize = 5,                           -- fallback tank
        mlPerPuff = 0.04,                       -- ml used per puff
        maxCoilPuffs = 250,                     -- how many puffs the coil has
        maxBattery = 100,                       -- max battery
        canChangeCoil = false,                  -- keep false
        canChangeTank = false,                  -- keep false
        juiceType = 'regular',                  -- juice type allowed
        puffAnimation = 'WORLD_HUMAN_SMOKING',  -- animation used
        exhaleTime = 2000,                      -- smoke length
        attachPos = {0.13, 0.03, 0.0},          -- x, y, z offsets
        attachRot = {180.0, 230.0, 20.0},        -- pitch, roll, yaw rotations
    },
    ['weed_pen'] = {
        label = 'Weed Pen',
        prop = 'ba_prop_battle_vape_01',
        tankSize = 5,
        mlPerPuff = 0.04,
        maxCoilPuffs = 250,
        maxBattery = 100,
        canChangeCoil = false,
        canChangeTank = false,
        juiceType = 'weed',
        puffAnimation = 'WORLD_HUMAN_SMOKING',
        exhaleTime = 4000,
        attachPos = {0.13, 0.03, 0.0},  
        attachRot = {180.0, 230.0, 20.0},  
    },
    ['box_vape'] = {
        label = 'Box Vape',
        prop = 'xm3_prop_xm3_vape_01a',
        tankSize = 5,               
        mlPerPuff = 0.04,
        maxCoilPuffs = 500,
        maxBattery = 250,
        canChangeCoil = true,                       -- leave true
        canChangeTank = true,                       -- leave true
        juiceType = 'regular',
        puffAnimation = 'WORLD_HUMAN_SMOKING',
        exhaleTime = 4500,
        attachPos = {0.13, 0.05, 0.0},  
        attachRot = {15.0, 180.0, 20.0},  
    },
}
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- Vape juice settings
Config.VapeJuices = {
    -- 60ml
    ['juice_strawberry_60'] = {                                  -- item name
	  label = 'Strawberry Ice (60ml)',                           -- menu label           
	  ml = 60,                                                   -- ml the item holds
	  type = 'regular',                                          -- juice type
	  emptyBottle = 'empty_bottle_60',                           -- bottle to be retured
	  effects = {                                                -- effects the juice gives and how long for
	    { name = 'runningSpeedIncrease', duration = 10000 }, 
	    { name = 'infiniteStamina', duration = 10000 } 
	  } 
	},
	
    ['juice_blueberry_60']  = { 
	  label = 'Blueberry Blast (60ml)', 
	  ml = 60, 
	  type = 'regular', 
	  emptyBottle = 'empty_bottle_60', 
	  effects = { 
	    { name = 'moreStrength', duration = 8000 } 
	  } 
	},
	
    ['juice_mango_60']      = { 
	  label = 'Mango Madness (60ml)', 
	  ml = 60, 
	  type = 'regular', 
	  emptyBottle = 'empty_bottle_60', 
	  effects = { 
	    { name = 'healthRegen', duration = 12000 } 
	  } 
	},
	
    ['juice_watermelon_60'] = { 
	  label = 'Watermelon Wave (60ml)', 
	  ml = 60, 
	  type = 'regular', 
	  emptyBottle = 'empty_bottle_60', 
	  effects = { 
	    { name = 'foodRegen', duration = 10000 } 
	  } 
	},
	
    ['juice_grape_60']      = { label = 'Grape Ape (60ml)', ml = 60, type = 'regular', emptyBottle = 'empty_bottle_60', effects = { { name = 'drunkWalk', duration = 5000 } } },
    ['juice_mint_60']       = { label = 'Arctic Mint (60ml)', ml = 60, type = 'regular', emptyBottle = 'empty_bottle_60', effects = { { name = 'psycoWalk', duration = 6000 } } },
    ['juice_peach_60']      = { label = 'Peach Rings (60ml)', ml = 60, type = 'regular', emptyBottle = 'empty_bottle_60', effects = { { name = 'outOfBody', duration = 7000 } } },
    ['juice_banana_60']     = { label = 'Banana Cream (60ml)', ml = 60, type = 'regular', emptyBottle = 'empty_bottle_60', effects = { { name = 'cameraShake', duration = 4000 } } },
    ['juice_lemon_60']      = { label = 'Lemon Tart (60ml)', ml = 60, type = 'regular', emptyBottle = 'empty_bottle_60', effects = { { name = 'fogEffect', duration = 9000 } } },
    ['juice_bubblegum_60']  = { label = 'Bubblegum Pop (60ml)', ml = 60, type = 'regular', emptyBottle = 'empty_bottle_60', effects = { { name = 'confusionEffect', duration = 8000 } } },
    -- 120ml
    ['juice_strawberry_120'] = { label = 'Strawberry Ice (120ml)', ml = 120, type = 'regular', emptyBottle = 'empty_bottle_120', effects = { { name = 'runningSpeedIncrease', duration = 15000 }, { name = 'infiniteStamina', duration = 15000 } } },
    ['juice_blueberry_120']  = { label = 'Blueberry Blast (120ml)', ml = 120, type = 'regular', emptyBottle = 'empty_bottle_120', effects = { { name = 'moreStrength', duration = 12000 } } },
    ['juice_mango_120']      = { label = 'Mango Madness (120ml)', ml = 120, type = 'regular', emptyBottle = 'empty_bottle_120', effects = { { name = 'healthRegen', duration = 18000 } } },
    ['juice_watermelon_120'] = { label = 'Watermelon Wave (120ml)', ml = 120, type = 'regular', emptyBottle = 'empty_bottle_120', effects = { { name = 'foodRegen', duration = 15000 } } },
    ['juice_grape_120']      = { label = 'Grape Ape (120ml)', ml = 120, type = 'regular', emptyBottle = 'empty_bottle_120', effects = { { name = 'drunkWalk', duration = 8000 } } },
    ['juice_mint_120']       = { label = 'Arctic Mint (120ml)', ml = 120, type = 'regular', emptyBottle = 'empty_bottle_120', effects = { { name = 'psycoWalk', duration = 9000 } } },
    ['juice_peach_120']      = { label = 'Peach Rings (120ml)', ml = 120, type = 'regular', emptyBottle = 'empty_bottle_120', effects = { { name = 'outOfBody', duration = 10000 } } },
    ['juice_banana_120']     = { label = 'Banana Cream (120ml)', ml = 120, type = 'regular', emptyBottle = 'empty_bottle_120', effects = { { name = 'cameraShake', duration = 6000 } } },
    ['juice_lemon_120']      = { label = 'Lemon Tart (120ml)', ml = 120, type = 'regular', emptyBottle = 'empty_bottle_120', effects = { { name = 'fogEffect', duration = 12000 } } },
    ['juice_bubblegum_120']  = { label = 'Bubblegum Pop (120ml)', ml = 120, type = 'regular', emptyBottle = 'empty_bottle_120', effects = { { name = 'confusionEffect', duration = 11000 } } },
    -- Weed
    ['juice_og_kush']           = { label = 'OG Kush (30ml)', ml = 30, type = 'weed', emptyBottle = 'empty_bottle_30', effects = { { name = 'outOfBody', duration = 15000 }, { name = 'confusionEffect', duration = 15000 } } },
    ['juice_gelato']            = { label = 'Gelato (30ml)', ml = 30, type = 'weed', emptyBottle = 'empty_bottle_30', effects = { { name = 'psycoWalk', duration = 12000 }, { name = 'fogEffect', duration = 12000 } } },
    ['juice_zkittlez']          = { label = 'Zkittlez (30ml)', ml = 30, type = 'weed', emptyBottle = 'empty_bottle_30', effects = { { name = 'drunkWalk', duration = 10000 }, { name = 'cameraShake', duration = 10000 } } },
    ['juice_blueberry_kush']    = { label = 'Blueberry Kush (30ml)', ml = 30, type = 'weed', emptyBottle = 'empty_bottle_30', effects = { { name = 'white', duration = 13000 } } },
    ['juice_pineapple_express'] = { label = 'Pineapple Express (30ml)', ml = 30, type = 'weed', emptyBottle = 'empty_bottle_30', effects = { { name = 'confusionEffect', duration = 14000 }, { name = 'outOfBody', duration = 14000 } } },
}
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- Vape juice crafting
Config.CraftingRecipes = {
    -- 60ml
    { 
	  result = 'juice_strawberry_60',                   -- item produced
	  amount = 1,                                       -- amount of item produced
	  time = 10000,                                     -- time to produce item
	  ingredients = {                                   -- items and amounts required to make juices
	    { item = 'base_liquid', amount = 3 }, 
	    { item = 'strawberry_flavour', amount = 1 }, 
	    { item = 'empty_bottle_60', amount = 1 } 
	  } 
	},
	
    { 
	  result = 'juice_blueberry_60',  
	  amount = 1, 
	  time = 10000, 
	  ingredients = { 
	    { item = 'base_liquid', amount = 3 }, 
		{ item = 'blueberry_flavour', amount = 1 }, 
		{ item = 'empty_bottle_60', amount = 1 } 
	  } 
	},
	
	
    { result = 'juice_mango_60',      amount = 1, time = 10000, ingredients = { { item = 'base_liquid', { item = '3mg_nic', amount = 1 }, amount = 3 }, { item = 'mango_flavour', amount = 1 }, { item = 'empty_bottle_60', amount = 1 } } },
    { result = 'juice_watermelon_60', amount = 1, time = 10000, ingredients = { { item = 'base_liquid', { item = '3mg_nic', amount = 1 }, amount = 3 }, { item = 'watermelon_flavour', amount = 1 }, { item = 'empty_bottle_60', amount = 1 } } },
    { result = 'juice_grape_60',      amount = 1, time = 10000, ingredients = { { item = 'base_liquid', { item = '3mg_nic', amount = 1 }, amount = 3 }, { item = 'grape_flavour', amount = 1 }, { item = 'empty_bottle_60', amount = 1 } } },
    { result = 'juice_mint_60',       amount = 1, time = 10000, ingredients = { { item = 'base_liquid', { item = '3mg_nic', amount = 1 }, amount = 3 }, { item = 'mint_flavour', amount = 1 }, { item = 'empty_bottle_60', amount = 1 } } },
    { result = 'juice_peach_60',      amount = 1, time = 10000, ingredients = { { item = 'base_liquid', { item = '3mg_nic', amount = 1 }, amount = 3 }, { item = 'peach_flavour', amount = 1 }, { item = 'empty_bottle_60', amount = 1 } } },
    { result = 'juice_banana_60',     amount = 1, time = 10000, ingredients = { { item = 'base_liquid', { item = '3mg_nic', amount = 1 }, amount = 3 }, { item = 'banana_flavour', amount = 1 }, { item = 'empty_bottle_60', amount = 1 } } },
    { result = 'juice_lemon_60',      amount = 1, time = 10000, ingredients = { { item = 'base_liquid', { item = '3mg_nic', amount = 1 }, amount = 3 }, { item = 'lemon_flavour', amount = 1 }, { item = 'empty_bottle_60', amount = 1 } } },
    { result = 'juice_bubblegum_60',  amount = 1, time = 10000, ingredients = { { item = 'base_liquid', { item = '3mg_nic', amount = 1 }, amount = 3 }, { item = 'bubblegum_flavour', amount = 1 }, { item = 'empty_bottle_60', amount = 1 } } },
    -- 120ml
    { result = 'juice_strawberry_120', amount = 1, time = 15000, ingredients = { { item = 'base_liquid', amount = 6 }, { item = '3mg_nic', amount = 1 }, { item = 'strawberry_flavour', amount = 2 }, { item = 'empty_bottle_120', amount = 1 } } },
    { result = 'juice_blueberry_120',  amount = 1, time = 15000, ingredients = { { item = 'base_liquid', amount = 6 }, { item = '3mg_nic', amount = 1 }, { item = 'blueberry_flavour', amount = 2 }, { item = 'empty_bottle_120', amount = 1 } } },
    { result = 'juice_mango_120',      amount = 1, time = 15000, ingredients = { { item = 'base_liquid', amount = 6 }, { item = '3mg_nic', amount = 1 }, { item = 'mango_flavour', amount = 2 }, { item = 'empty_bottle_120', amount = 1 } } },
    { result = 'juice_watermelon_120', amount = 1, time = 15000, ingredients = { { item = 'base_liquid', amount = 6 }, { item = '3mg_nic', amount = 1 }, { item = 'watermelon_flavour', amount = 2 }, { item = 'empty_bottle_120', amount = 1 } } },
    { result = 'juice_grape_120',      amount = 1, time = 15000, ingredients = { { item = 'base_liquid', amount = 6 }, { item = '3mg_nic', amount = 1 }, { item = 'grape_flavour', amount = 2 }, { item = 'empty_bottle_120', amount = 1 } } },
    { result = 'juice_mint_120',       amount = 1, time = 15000, ingredients = { { item = 'base_liquid', amount = 6 }, { item = '3mg_nic', amount = 1 }, { item = 'mint_flavour', amount = 2 }, { item = 'empty_bottle_120', amount = 1 } } },
    { result = 'juice_peach_120',      amount = 1, time = 15000, ingredients = { { item = 'base_liquid', amount = 6 }, { item = '3mg_nic', amount = 1 }, { item = 'peach_flavour', amount = 2 }, { item = 'empty_bottle_120', amount = 1 } } },
    { result = 'juice_banana_120',     amount = 1, time = 15000, ingredients = { { item = 'base_liquid', amount = 6 }, { item = '3mg_nic', amount = 1 }, { item = 'banana_flavour', amount = 2 }, { item = 'empty_bottle_120', amount = 1 } } },
    { result = 'juice_lemon_120',      amount = 1, time = 15000, ingredients = { { item = 'base_liquid', amount = 6 }, { item = '3mg_nic', amount = 1 }, { item = 'lemon_flavour', amount = 2 }, { item = 'empty_bottle_120', amount = 1 } } },
    { result = 'juice_bubblegum_120',  amount = 1, time = 15000, ingredients = { { item = 'base_liquid', amount = 6 }, { item = '3mg_nic', amount = 1 }, { item = 'bubblegum_flavour', amount = 2 }, { item = 'empty_bottle_120', amount = 1 } } },
    -- Weed juices
    { result = 'juice_og_kush',           amount = 1, time = 15000, ingredients = { { item = 'weed_stems', amount = 5 }, { item = 'base_liquid', amount = 2 }, { item = 'empty_bottle_30', amount = 1 } } },
    { result = 'juice_gelato',            amount = 1, time = 15000, ingredients = { { item = 'weed_stems', amount = 5 }, { item = 'base_liquid', amount = 2 }, { item = 'grape_flavour', amount = 1 }, { item = 'peach_flavour', amount = 1 }, { item = 'empty_bottle_30', amount = 1 } } },
    { result = 'juice_zkittlez',          amount = 1, time = 15000, ingredients = { { item = 'weed_stems', amount = 5 }, { item = 'base_liquid', amount = 2 }, { item = 'lemon_flavour', amount = 1 }, { item = 'grape_flavour', amount = 1 }, { item = 'peach_flavour', amount = 1 }, { item = 'pineapple_flavour', amount = 1 }, { item = 'empty_bottle_30', amount = 1 } } },
    { result = 'juice_blueberry_kush',    amount = 1, time = 15000, ingredients = { { item = 'weed_stems', amount = 5 }, { item = 'base_liquid', amount = 2 }, { item = 'blueberry_flavour', amount = 1 }, { item = 'empty_bottle_30', amount = 1 } } },
    { result = 'juice_pineapple_express', amount = 1, time = 15000, ingredients = { { item = 'weed_stems', amount = 5 }, { item = 'base_liquid', amount = 2 }, { item = 'pineapple_flavour', amount = 1 }, { item = 'empty_bottle_30', amount = 1 } } },
}

-- Vape crafting recipes
Config.VapeCraftingRecipes = {
    
	{ 
        result = 'vape_battery',               -- item name
        amount = 1,                            -- output amount
        time = 8000,                           -- time to craft
        ingredients = {                        -- items required to build vapes ect
            { item = 'copper', amount = 3 }, 
            { item = 'plastic', amount = 2 } 
        } 
    },
    { 
        result = 'vape_wiring', 
        amount = 1, 
        time = 2000, 
        ingredients = { 
            { item = 'copper', amount = 4 }, 
            { item = 'iron', amount = 1 } 
        } 
    },
    { 
        result = 'shell_dispo', 
        amount = 1, 
        time = 10000, 
        ingredients = { 
            { item = 'plastic', amount = 3 }, 
            { item = 'aluminum', amount = 2 } 
        } 
    },
    { 
        result = 'shell_weed', 
        amount = 1, 
        time = 10000, 
        ingredients = { 
            { item = 'plastic', amount = 3 }, 
            { item = 'aluminum', amount = 2 } 
        } 
    },
    { 
        result = 'shell_box', 
        amount = 1, 
        time = 12000, 
        ingredients = { 
            { item = 'plastic', amount = 4 }, 
            { item = 'aluminum', amount = 3 } 
        } 
    },
    { 
        result = 'vape_lcd', 
        amount = 1, 
        time = 9000, 
        ingredients = { 
            { item = 'plastic', amount = 2 }, 
            { item = 'copper', amount = 2 }, 
            { item = 'iron', amount = 1 } 
        } 
    },
	
	
	{ 
        result = '5ml_tank', 
        amount = 1, 
        time = 8000, 
        ingredients = { 
            { item = 'glass', amount = 2 }, 
            { item = 'aluminum', amount = 1 } 
        } 
    },
	{ 
        result = '8ml_tank', 
        amount = 1, 
        time = 10000, 
        ingredients = { 
            { item = 'glass', amount = 4 }, 
            { item = 'aluminum', amount = 2 } 
        } 
    },
	{ 
        result = '12ml_tank', 
        amount = 1, 
        time = 12000, 
        ingredients = { 
            { item = 'glass', amount = 6 }, 
            { item = 'aluminum', amount = 3 } 
        } 
    },
	
	
	{ 
        result = 'empty_bottle_30', 
        amount = 1, 
        time = 3000, 
        ingredients = { 
            { item = 'plastic', amount = 3 }, 
        } 
    },
	{ 
        result = 'empty_bottle_60', 
        amount = 1, 
        time = 4000, 
        ingredients = { 
            { item = 'plastic', amount = 6 }, 
        } 
    },
	{ 
        result = 'empty_bottle_120', 
        amount = 1, 
        time = 5000, 
        ingredients = { 
            { item = 'plastic', amount = 12 }, 
        } 
    },


	{ 
        result = 'vape_coil', 
        amount = 1, 
        time = 9000, 
        ingredients = { 
            { item = 'copper', amount = 4 }, 
            { item = 'iron', amount = 1 } 
        } 
    },
	
	{ 
        result = 'vape_coil_pack_3', 
        amount = 1, 
        time = 5000, 
        ingredients = { 
            { item = 'vape_coil', amount = 3 }, 
        } 
    },
	
	{ 
        result = 'vape_coil_pack_6', 
        amount = 1, 
        time = 7000, 
        ingredients = { 
            { item = 'vape_coil', amount = 6 }, 
        } 
    },
	
	{ 
        result = 'vape_coil_pack_10', 
        amount = 1, 
        time = 9000, 
        ingredients = { 
            { item = 'vape_coil', amount = 6 }, 
        } 
    },
	
	
	{ 
        result = 'vape_charger', 
        amount = 1, 
        time = 5000, 
        ingredients = { 
            { item = 'plastic', amount = 3 }, 
            { item = 'iron', amount = 2 } 
        } 
    },
	
	{ 
	  result = 'dispo_vape',                     
	  amount = 1,                                
	  time = 10000,                              
	  ingredients = {                            
	    { item = 'vape_battery', amount = 1 }, 
	    { item = 'vape_wiring', amount = 1 }, 
	    { item = 'shell_dispo', amount = 1 } 
	  } 
	},
    { 
	  result = 'weed_pen', 
	  amount = 1, 
	  time = 10000, 
	  ingredients = { 
	    { item = 'vape_battery', amount = 1 }, 
	    { item = 'vape_wiring', amount = 1 }, 
	    { item = 'shell_weed', amount = 1 } 
	  } 
	},
    { 
	  result = 'box_vape', 
	  amount = 1, 
	  time = 15000, 
	  ingredients = { 
	    { item = 'vape_battery', amount = 1 }, 
	    { item = 'vape_wiring', amount = 1 }, 
	    { item = 'shell_box', amount = 1 }, 
	    { item = 'vape_lcd', amount = 1 }        -- Only box_vape needs LCD
	  } 
	},
	
	
	
	{ 
	  result = 'box_set', 
	  amount = 1, 
	  time = 25000, 
	  ingredients = { 
	    { item = 'box_packaging', amount = 1 },
	    { item = 'box_vape', amount = 1 }, 
	    { item = 'vape_charger', amount = 1 }, 
	    { item = '5ml_tank', amount = 1 }, 
	    { item = 'vape_coil', amount = 1 },
        { item = 'vape_coil_pack_3', amount = 1 },
		{ item = 'juice_mango_60', amount = 1 },
	  } 
	},
	{ 
	  result = 'dispo_set', 
	  amount = 1, 
	  time = 25000, 
	  ingredients = { 
	    { item = 'dispo_packaging', amount = 1 },
	    { item = 'dispo_vape', amount = 1 }, 
	    { item = 'vape_charger', amount = 1 }, 
		{ item = 'juice_strawberry_60', amount = 1 },
	  } 
	},
	{ 
	  result = 'weed_set', 
	  amount = 1, 
	  time = 25000, 
	  ingredients = { 
	    { item = 'weed_packaging', amount = 1 },
	    { item = 'dispo_vape', amount = 1 }, 
	    { item = 'vape_charger', amount = 1 }, 
		{ item = 'juice_strawberry_60', amount = 1 },
	  } 
	},
	{ 
	  result = 'box_packaging', 
	  amount = 1, 
	  time = 15000, 
	  ingredients = { 
	    { item = 'paper', amount = 10 },
	  } 
	},
	{ 
	  result = 'dispo_packaging', 
	  amount = 1, 
	  time = 15000, 
	  ingredients = { 
	    { item = 'paper', amount = 10 },
	  } 
	},
	{ 
	  result = 'weed_packaging', 
	  amount = 1, 
	  time = 15000, 
	  ingredients = { 
	    { item = 'paper', amount = 10 },
	  } 
	},
}

-- Concentrate crafting recipes
Config.ConcentrateCraftingRecipes = {
    -- Fruit concentrates
    { result = 'strawberry_flavour', amount = 2, time = 12000, ingredients = { { item = 'strawberry',  amount = 4 }, { item = 'water_bottle', amount = 1 }, { item = 'solvent', amount = 1 } } },
    { result = 'blueberry_flavour',  amount = 2, time = 12000, ingredients = { { item = 'blueberry',   amount = 4 }, { item = 'water_bottle', amount = 1 }, { item = 'solvent', amount = 1 } } },
    { result = 'mango_flavour',      amount = 2, time = 12000, ingredients = { { item = 'mango',       amount = 3 }, { item = 'water_bottle', amount = 1 }, { item = 'solvent', amount = 1 } } },
    { result = 'watermelon_flavour', amount = 2, time = 12000, ingredients = { { item = 'watermelon',  amount = 3 }, { item = 'water_bottle', amount = 1 }, { item = 'solvent', amount = 1 } } },
    { result = 'grape_flavour',      amount = 2, time = 12000, ingredients = { { item = 'grapes',      amount = 4 }, { item = 'water_bottle', amount = 1 }, { item = 'solvent', amount = 1 } } },
    { result = 'peach_flavour',      amount = 2, time = 12000, ingredients = { { item = 'peach',       amount = 3 }, { item = 'water_bottle', amount = 1 }, { item = 'solvent', amount = 1 } } },
    { result = 'banana_flavour',     amount = 2, time = 12000, ingredients = { { item = 'banana',      amount = 3 }, { item = 'water_bottle', amount = 1 }, { item = 'solvent', amount = 1 } } },
    { result = 'lemon_flavour',      amount = 2, time = 12000, ingredients = { { item = 'lemon',       amount = 3 }, { item = 'water_bottle', amount = 1 }, { item = 'solvent', amount = 1 } } },
    { result = 'pineapple_flavour',  amount = 2, time = 12000, ingredients = { { item = 'pineapple',   amount = 3 }, { item = 'water_bottle', amount = 1 }, { item = 'solvent', amount = 1 } } },
    { result = 'mint_flavour',       amount = 2, time = 10000, ingredients = { { item = 'mint_leaves', amount = 5 }, { item = 'water_bottle', amount = 1 }, { item = 'solvent', amount = 1 } } },
    { result = 'bubblegum_flavour',  amount = 2, time = 14000, ingredients = { { item = 'sugar',       amount = 3 }, { item = 'water_bottle', amount = 1 }, { item = 'food_dye', amount = 1 }, { item = 'solvent', amount = 1 } } },
}