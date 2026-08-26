Config = {}

-- Set to true to print step-by-step purchase debug info to the console.
Config.Debug = false

-- Currency account (bank / cash)
Config.PaymentAccount = 'cash'

-- How close a player must be to interact with a van location (metres)
Config.BuyRange      = 3.0
Config.InteractRange = 3.0

-- Progress bar duration for crafting (ms)
Config.CraftDuration = 6000

-- Admin groups (ace permission names)
Config.AdminGroups = { 'admin', 'god', 'superadmin' }

-- Stash settings per van (stash linked to vanId must be staff or owner to use)
Config.StashSlots     = 50
Config.StashMaxWeight = 100000

--  Payment point MAX
Config.MaxPayment = 500






-- ============================================================
--  Van Locations
-- ============================================================
Config.VanLocations = {

    -- Hotdog locations
    {
        id     = 1,
        label  = 'Rockford Hot Dogs',
        prop   = 'prop_hotdogstand_01',
        coords = vector4(104.7, -201.5, 54.57, 251.75),
        price  = 15000,
    },
	{
        id     = 2,
        label  = 'LSIA Hot Dogs',
        prop   = 'prop_hotdogstand_01',
        coords = vector4(-1045.79, -2732.84, 20.17, 130.19),
        price  = 15000,
    },
	{
        id     = 3,
        label  = 'Paleto Hot Dogs',
        prop   = 'prop_hotdogstand_01',
        coords = vector4(-204.79, 6347.86, 31.48, 38.7),
        price  = 15000,
    },
	{
        id     = 4,
        label  = 'Grapeseed Hot Dogs',
        prop   = 'prop_hotdogstand_01',
        coords = vector4(1695.6, 4792.63, 41.92, 273.89),
        price  = 15000,
    },
	{
        id     = 5,
        label  = 'Sandy Hot Dogs',
        prop   = 'prop_hotdogstand_01',
        coords = vector4(1860.96, 3741.67, 33.14, 32.47),
        price  = 15000,
    },
	
	
	-- Burger locations
    {
        id     = 6,
        label  = 'Vespucci Burgers',
        prop   = 'prop_burgerstand_01',
        coords = vector4(-1187.25, -1506.99, 4.38, 131.25),
        price  = 20000,
    },
	{
        id     = 7,
        label  = 'Dock Burgers',
        prop   = 'prop_burgerstand_01',
        coords = vector4(1212.85, -3231.83, 6.03, 269.7),
        price  = 20000,
    },
	{
        id     = 8,
        label  = 'Casino Burgers',
        prop   = 'prop_burgerstand_01',
        coords = vector4(885.66, -1.53, 78.76, 330.51),
        price  = 20000,
    },
	{
        id     = 9,
        label  = 'Dirt Track Burgers',
        prop   = 'prop_burgerstand_01',
        coords = vector4(963.11, 2211.0, 50.26, 117.05),
        price  = 20000,
    },
	{
        id     = 10,
        label  = 'Flywheels Burgers',
        prop   = 'prop_burgerstand_01',
        coords = vector4(1780.39, 3321.06, 41.35, 122.37),
        price  = 20000,
    },
	
	
	-- Food Van Locations
    -- zOffset corrects for model origin being at the roof/centre rather than the base.
    {
        id      = 11,
        label   = 'Mirror Park Food Van',
        prop    = 'prop_food_van_02',
        coords  = vector4(1130.74, -642.31, 57.74, 336.62),
        price   = 30000,
        zOffset = 1.15,
    },
    {
        id      = 12,
        label   = 'Sandy Shores Food Van',
        prop    = 'prop_food_van_02',
        coords  = vector4(1920.68, 3682.1, 32.68, 214.9),
        price   = 30000,
        zOffset = 1.15,
    },
	{
        id      = 13,
        label   = 'Paleto Food Van',
        prop    = 'prop_food_van_02',
        coords  = vector4(177.2, 6636.6, 31.62, 314.84),
        price   = 30000,
        zOffset = 1.15,
    },
	{
        id      = 14,
        label   = 'Beach Food Van 1',
        prop    = 'prop_food_van_02',
        coords  = vector4(-2072.23, -455.73, 11.68, 57.91),
        price   = 30000,
        zOffset = 1.15,
    },
	{
        id      = 15,
        label   = 'Beach Food Van 2',
        prop    = 'prop_food_van_02',
        coords  = vector4(-1655.4, -969.63, 7.7, 138.51),
        price   = 30000,
        zOffset = 1.15,
    },
	
	
    -- Coffee Locations	
    {
        id     = 16,
        label  = 'Del Perro Coffee',
        prop   = 'p_ld_coffee_vend_s',
        coords = vector4(-1361.63, -528.54, 30.59, 37.55),
        price  = 18000,
    },
	{
        id     = 17,
        label  = 'Coffee',
        prop   = 'p_ld_coffee_vend_s',
        coords = vector4(-954.17, -733.78, 19.92, 275.36),
        price  = 18000,
    },
	{
        id     = 18,
        label  = 'Coffee 2',
        prop   = 'p_ld_coffee_vend_s',
        coords = vector4(-1334.14, -1405.78, 4.31, 205.37),
        price  = 18000,
    },
	{
        id     = 19,
        label  = 'Coffee 3',
        prop   = 'p_ld_coffee_vend_s',
        coords = vector4(1012.49, -683.6, 56.71, 227.77),
        price  = 18000,
    },
	{
        id     = 20,
        label  = 'Coffee 4',
        prop   = 'p_ld_coffee_vend_s',
        coords = vector4(-1716.72, -1006.12, 5.72, 59.31),
        price  = 18000,
    },
}






-- ============================================================
--  Recipes per prop type
-- ============================================================
Config.PropRecipes = {

['prop_hotdogstand_01'] = {
    {
        label = 'Classic Hotdog',
        result = 'van_hotdog_classic',
        amount = 1,
        ingredients = {
            { item = 'van_hotdog_bun', amount = 1 },
            { item = 'van_sausage', amount = 1 },
        },
    },
    {
        label = 'Cheese Hotdog',
        result = 'van_hotdog_cheese',
        amount = 1,
        ingredients = {
            { item = 'van_hotdog_bun', amount = 1 },
            { item = 'van_sausage', amount = 1 },
            { item = 'van_cheese', amount = 1 },
        },
    },
    {
        label = 'Chili Hotdog',
        result = 'van_hotdog_chili',
        amount = 1,
        ingredients = {
            { item = 'van_hotdog_bun', amount = 1 },
            { item = 'van_sausage', amount = 1 },
            { item = 'van_chili', amount = 1 },
        },
    },
    {
        label = 'Loaded Hotdog',
        result = 'van_hotdog_loaded',
        amount = 1,
        ingredients = {
            { item = 'van_hotdog_bun', amount = 1 },
            { item = 'van_sausage', amount = 1 },
            { item = 'van_onion', amount = 1 },
            { item = 'van_sauce', amount = 1 },
        },
    },
    {
        label = 'Cola',
        result = 'van_cola',
        amount = 1,
        ingredients = {
            { item = 'van_cola_syrup', amount = 1 },
            { item = 'van_ice', amount = 1 },
        },
    },
    {
        label = 'Lemonade',
        result = 'van_lemonade',
        amount = 1,
        ingredients = {
            { item = 'van_lemon', amount = 1 },
            { item = 'van_sugar', amount = 1 },
            { item = 'van_ice', amount = 1 },
        },
    },
},
['prop_burgerstand_01'] = {
    {
        label = 'Classic Burger',
        result = 'van_burger_classic',
        amount = 1,
        ingredients = {
            { item = 'van_burger_bun', amount = 1 },
            { item = 'van_burger_patty', amount = 1 },
        },
    },
    {
        label = 'Cheese Burger',
        result = 'van_burger_cheese',
        amount = 1,
        ingredients = {
            { item = 'van_burger_bun', amount = 1 },
            { item = 'van_burger_patty', amount = 1 },
            { item = 'van_cheese', amount = 1 },
        },
    },
    {
        label = 'Bacon Burger',
        result = 'van_burger_bacon',
        amount = 1,
        ingredients = {
            { item = 'van_burger_bun', amount = 1 },
            { item = 'van_burger_patty', amount = 1 },
            { item = 'van_bacon', amount = 1 },
        },
    },
    {
        label = 'Loaded Burger',
        result = 'van_burger_loaded',
        amount = 1,
        ingredients = {
            { item = 'van_burger_bun', amount = 1 },
            { item = 'van_burger_patty', amount = 1 },
            { item = 'van_lettuce', amount = 1 },
            { item = 'van_tomato', amount = 1 },
        },
    },
    {
        label = 'Milkshake',
        result = 'van_milkshake',
        amount = 1,
        ingredients = {
            { item = 'van_milk', amount = 1 },
			{ item = 'van_ice', amount = 1 },
            { item = 'van_sugar', amount = 1 },
        },
    },
    {
        label = 'Orange Soda',
        result = 'van_orange_soda',
        amount = 1,
        ingredients = {
            { item = 'van_orange', amount = 1 },
            { item = 'van_sugar', amount = 1 },
            { item = 'van_ice', amount = 1 },
        },
    },
},
['prop_food_van_02'] = {
	{
        label = 'Classic Hotdog',
        result = 'van_hotdog_classic',
        amount = 1,
        ingredients = {
            { item = 'van_hotdog_bun', amount = 1 },
            { item = 'van_sausage', amount = 1 },
        },
    },
    {
        label = 'Cheese Hotdog',
        result = 'van_hotdog_cheese',
        amount = 1,
        ingredients = {
            { item = 'van_hotdog_bun', amount = 1 },
            { item = 'van_sausage', amount = 1 },
            { item = 'van_cheese', amount = 1 },
        },
    },
    {
        label = 'Chili Hotdog',
        result = 'van_hotdog_chili',
        amount = 1,
        ingredients = {
            { item = 'van_hotdog_bun', amount = 1 },
            { item = 'van_sausage', amount = 1 },
            { item = 'van_chili', amount = 1 },
        },
    },
    {
        label = 'Loaded Hotdog',
        result = 'van_hotdog_loaded',
        amount = 1,
        ingredients = {
            { item = 'van_hotdog_bun', amount = 1 },
            { item = 'van_sausage', amount = 1 },
            { item = 'van_onion', amount = 1 },
            { item = 'van_sauce', amount = 1 },
        },
    },
	    {
        label = 'Classic Burger',
        result = 'van_burger_classic',
        amount = 1,
        ingredients = {
            { item = 'van_burger_bun', amount = 1 },
            { item = 'van_burger_patty', amount = 1 },
        },
    },
    {
        label = 'Cheese Burger',
        result = 'van_burger_cheese',
        amount = 1,
        ingredients = {
            { item = 'van_burger_bun', amount = 1 },
            { item = 'van_burger_patty', amount = 1 },
            { item = 'van_cheese', amount = 1 },
        },
    },
    {
        label = 'Bacon Burger',
        result = 'van_burger_bacon',
        amount = 1,
        ingredients = {
            { item = 'van_burger_bun', amount = 1 },
            { item = 'van_burger_patty', amount = 1 },
            { item = 'van_bacon', amount = 1 },
        },
    },
    {
        label = 'Loaded Burger',
        result = 'van_burger_loaded',
        amount = 1,
        ingredients = {
            { item = 'van_burger_bun', amount = 1 },
            { item = 'van_burger_patty', amount = 1 },
            { item = 'van_lettuce', amount = 1 },
            { item = 'van_tomato', amount = 1 },
        },
    },
    {
        label = 'Chicken Nuggets',
        result = 'van_nuggets',
        amount = 1,
        ingredients = {
            { item = 'van_chicken', amount = 2 },
            { item = 'van_oil', amount = 1 },
        },
    },
    {
        label = 'Fries',
        result = 'van_fries',
        amount = 1,
        ingredients = {
            { item = 'van_potato', amount = 2 },
            { item = 'van_oil', amount = 1 },
        },
    },	
    {
        label = 'Donut',
        result = 'van_donut',
        amount = 1,
        ingredients = {
            { item = 'van_dough', amount = 1 },
            { item = 'van_sugar', amount = 1 },
        },
    },
    {
        label = 'Ice Cream',
        result = 'van_icecream',
        amount = 1,
        ingredients = {
            { item = 'van_milk', amount = 1 },
            { item = 'van_sugar', amount = 1 },
        },
    },
    {
        label = 'Iced Tea',
        result = 'van_iced_tea',
        amount = 1,
        ingredients = {
            { item = 'van_tea', amount = 1 },
            { item = 'van_ice', amount = 1 },
        },
    },
    {
        label = 'Cola',
        result = 'van_cola',
        amount = 1,
        ingredients = {
            { item = 'van_cola_syrup', amount = 1 },
            { item = 'van_ice', amount = 1 },
        },
    },
    {
        label = 'Lemonade',
        result = 'van_lemonade',
        amount = 1,
        ingredients = {
            { item = 'van_lemon', amount = 1 },
            { item = 'van_sugar', amount = 1 },
            { item = 'van_ice', amount = 1 },
        },
    },	
    {
        label = 'Milkshake',
        result = 'van_milkshake',
        amount = 1,
        ingredients = {
            { item = 'van_milk',  amount = 1 },
			{ item = 'van_ice',   amount = 1 },
            { item = 'van_sugar', amount = 1 },
        },
    },
    {
        label = 'Orange Soda',
        result = 'van_orange_soda',
        amount = 1,
        ingredients = {
            { item = 'van_orange', amount = 1 },
            { item = 'van_sugar', amount = 1 },
            { item = 'van_ice', amount = 1 },
        },
    },	
    {
        label = 'Fruit Punch',
        result = 'van_fruit_punch',
        amount = 1,
        ingredients = {
            { item = 'van_fruit_mix', amount = 2 },
            { item = 'van_ice', amount = 1 },
        },
    },
},

['p_ld_coffee_vend_s'] = {
    { label = 'Espresso', result = 'van_espresso', amount = 1, ingredients = { { item = 'van_coffee_beans', amount = 2 } } },
    { label = 'Americano', result = 'van_americano', amount = 1, ingredients = { { item = 'van_espresso', amount = 1 }, { item = 'van_water', amount = 1 } } },
    { label = 'Latte', result = 'van_latte', amount = 1, ingredients = { { item = 'van_espresso', amount = 1 }, { item = 'van_milk', amount = 1 } } },
    { label = 'Cappuccino', result = 'van_cappuccino', amount = 1, ingredients = { { item = 'van_espresso', amount = 1 }, { item = 'van_milk', amount = 1 } } },
    { label = 'Mocha', result = 'van_mocha', amount = 1, ingredients = { { item = 'van_espresso', amount = 1 }, { item = 'van_chocolate', amount = 1 } } },
    { label = 'Caramel Latte', result = 'van_caramel_latte', amount = 1, ingredients = { { item = 'van_espresso', amount = 1 }, { item = 'van_caramel', amount = 1 } } },
    { label = 'Iced Coffee', result = 'van_iced_coffee', amount = 1, ingredients = { { item = 'van_espresso', amount = 1 }, { item = 'van_ice', amount = 1 } } },
    { label = 'Vanilla Frappe', result = 'van_frappe', amount = 1, ingredients = { { item = 'van_espresso', amount = 1 }, { item = 'van_ice', amount = 2 }, { item = 'van_vanilla', amount = 1 } } },
},
}





-- ============================================================
--  Orderable Ingredients
-- ============================================================
Config.OrderableIngredients = {
    { item = 'van_burger_bun',      label = 'Burger Bun',        price = 5,  amount = 10 },
    { item = 'van_hotdog_bun',      label = 'Hotdog Bun',        price = 5,  amount = 10 },
    { item = 'van_burger_patty',    label = 'Burger Patty',      price = 5,  amount = 10 },
    { item = 'van_sausage',         label = 'Sausage',           price = 5,  amount = 10 },
    { item = 'van_cheese',          label = 'Cheese Slice',      price = 5,  amount = 10 },
    { item = 'van_bacon',           label = 'Bacon',             price = 7,  amount = 10 },
    { item = 'van_lettuce',         label = 'Lettuce',           price = 15, amount = 10 },
    { item = 'van_tomato',          label = 'Tomato',            price = 4,  amount = 10 },
    { item = 'van_onion',           label = 'Onion',             price = 4,  amount = 10 },
    { item = 'van_potato',          label = 'Potato',            price = 3,  amount = 10 },
    { item = 'van_oil',             label = 'Cooking Oil',       price = 10, amount = 10 },
    { item = 'van_milk',            label = 'Milk',              price = 17, amount = 10 },
    { item = 'van_sugar',           label = 'Sugar',             price = 30, amount = 15 },
    { item = 'van_ice',             label = 'Ice',               price = 6,  amount = 15 },
    { item = 'van_coffee_beans',    label = 'Coffee Beans',      price = 33, amount = 10 },
    { item = 'van_chicken',         label = 'Raw Chicken',       price = 9,  amount = 10 },
    { item = 'van_dough',           label = 'Dough',             price = 4, amount = 10 },
    { item = 'van_fruit_mix',       label = 'Fruit Mix',         price = 2, amount = 10 },
    { item = 'van_chili',           label = 'Chili',             price = 12, amount = 10 },
    { item = 'van_sauce',           label = 'Sauce',             price = 10, amount = 10 },
    { item = 'van_cola_syrup',      label = 'Cola Syrup',        price = 5, amount = 10 },
    { item = 'van_lemon',           label = 'Lemon',             price = 10, amount = 10 },
    { item = 'van_orange',          label = 'Orange',            price = 10, amount = 10 },
    { item = 'van_tea',             label = 'Tea Leaves',        price = 10, amount = 10 },
    { item = 'van_water',           label = 'Water',             price = 10, amount = 15 },
    { item = 'van_chocolate',       label = 'Chocolate',         price = 25, amount = 10 },
    { item = 'van_caramel',         label = 'Caramel',           price = 15, amount = 10 },
    { item = 'van_vanilla',         label = 'Vanilla',           price = 45, amount = 10 },
}





-- ============================================================
--  NPC Customer Sale Prices
-- ============================================================
Config.CustomerSalePrices = {
    -- Hotdog stand items
    ['van_hotdog_classic'] = 12,
    ['van_hotdog_cheese']  = 15,
    ['van_hotdog_chili']   = 16,
    ['van_hotdog_loaded']  = 17,
    ['van_burger_classic'] = 9,
    ['van_burger_cheese']  = 12,
    ['van_burger_bacon']   = 15,
    ['van_burger_loaded']  = 20,
    ['van_nuggets']        = 4,
    ['van_fries']          = 3,
    ['van_donut']          = 2,
    ['van_icecream']       = 5,
    ['van_cola']           = 2,
    ['van_lemonade']       = 2,
    ['van_iced_tea']       = 3,
    ['van_milkshake']      = 5,
    ['van_orange_soda']    = 2,
    ['van_fruit_punch']    = 2,
    ['van_espresso']       = 4,
    ['van_americano']      = 5,
    ['van_latte']          = 6,
    ['van_cappuccino']     = 7,
    ['van_mocha']          = 8,
    ['van_caramel_latte']  = 9,
    ['van_iced_coffee']    = 10,
    ['van_frappe']         = 11,
}






-- ============================================================
--  DONT TOUCH IF YOU DO MAKE SURE TO SAVE A BACKUP
-- ============================================================
Config.CustomerSpawnRadius = 75.0
Config.StallCloseRadius = 100.0
Config.StallCloseCheckInterval = 15000
Config.DeliveryPedModel  = 'a_m_m_ktown_01'
Config.DeliveryWalkSpeed = 2.0   
Config.DeliveryDelay     = 1000  
Config.SignOpen   = '~g~[OPEN]'
Config.SignClosed = '~r~[CLOSED]'
Config.SignBuy    = '~y~[FOR SALE]~s~ $%s'