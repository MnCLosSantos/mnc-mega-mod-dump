Config = {}

Config.Debug = true

-- Inventory image path (adjust based on your qb-inventory setup)
Config.InventoryImagePath = "nui://qb-inventory/html/images/"

-- Watermark image path
Config.WatermarkImagePath = "nui://mnc-pricesheets/html/images/"

-- Job grades that can apply discounts (format: job_name = {grades})
Config.DiscountPermissions = {
    -- ['police'] = {3, 4}, -- Lieutenant and above
    -- ['ambulance'] = {3, 4},
    -- ['burgershot'] = {2, 3},
	['autoexotics'] = {3, 4},
}

-- Maximum discount percentage allowed
Config.MaxDiscountPercent = 50

-- Price Sheet Locations
Config.PriceSheets = {

    -- MECHANIC SHOP EXAMPLE
  {
    name = "Auto Exotics Parts & Services",
    location = vector3(544.76, -199.0, 54.51),
    theme = "blue",
    jobs = {}, -- Public access
	watermark = "autoexotics.png",
    
    categories = {
        {
            name = "Tools & Equipment",
            icon = "fa-toolbox",
            items = {
                {name = "OBD Scanner", item = "obd_scanner", price = 200, image = "obd_scanner.png", description = "Diagnostic scanner"},
                {name = "Drag Chip", item = "dragchip", price = 200, image = "obd_scanner_cracked.png", description = "Performance chip"},
				{name = "Vehicle Tracker", item = "vehicletracker", price = 400, image = "vehicletracker.png", description = "GPS vehicle tracker"},
                {name = "Racing GPS", item = "racing_gps", price = 2000, image = "racing_gps.png", description = "High-performance GPS"},
            }
        },
        {
            name = "Repair Kits",
            icon = "fa-wrench",
            items = {
                {name = "Duct Tape", item = "ducttape", price = 9, image = "bodyrepair.png", description = "Quick fixes"},
				{name = "4L of Oil", item = "newoil", price = 20, image = "caroil.png", description = "4L of oil"},
				{name = "Spark Plugs", item = "sparkplugs", price = 55, image = "sparkplugs.png", description = "Pack of sparkplugs"},
				{name = "Car Battery", item = "carbattery", price = 124, image = "carbattery.png", description = "Quick Charging battery"},
				{name = "Axle Shafts", item = "axleparts", price = 211, image = "axleparts.png", description = "New set of axles"},
				{name = "Spare Tire", item = "sparetire", price = 84, image = "sparetire.png", description = "New Tire"},
                {name = "Repair Kit", item = "repairkit", price = 600, image = "repairkit.png", description = "Basic repair kit"},
                {name = "Advanced Repair Kit", item = "advancedrepairkit", price = 1300, image = "advancedkit.png", description = "Professional repair kit"},
            }
        },
        {
            name = "Engine Parts",
            icon = "fa-engine",
            items = {
                {name = "Engine Tier 1", item = "engine1", price = 500, image = "engine1.png", description = "Basic engine upgrade"},
                {name = "Engine Tier 2", item = "engine2", price = 1000, image = "engine2.png", description = "Improved engine"},
                {name = "Engine Tier 3", item = "engine3", price = 2000, image = "engine3.png", description = "Advanced engine"},
                {name = "Engine Tier 4", item = "engine4", price = 3000, image = "engine4.png", description = "High-performance engine"},
                {name = "Engine Tier 5", item = "engine5", price = 4000, image = "engine5.png", description = "Race engine"},
                {name = "Turbo", item = "turbo", price = 2500, image = "turbo.png", description = "Turbocharger system"},
            }
        },
        {
            name = "Transmission",
            icon = "fa-gears",
            items = {
                {name = "Transmission Tier 1", item = "transmission1", price = 500, image = "transmission1.png", description = "Basic transmission"},
                {name = "Transmission Tier 2", item = "transmission2", price = 1000, image = "transmission2.png", description = "Improved transmission"},
                {name = "Transmission Tier 3", item = "transmission3", price = 2000, image = "transmission3.png", description = "Advanced transmission"},
                {name = "Transmission Tier 4", item = "transmission4", price = 3000, image = "transmission4.png", description = "Race transmission"},
            }
        },
        {
            name = "Brakes & Suspension",
            icon = "fa-car-side",
            items = {
                {name = "Brakes Tier 1", item = "brakes1", price = 500, image = "brakes1.png", description = "Basic brake system"},
                {name = "Brakes Tier 2", item = "brakes2", price = 1000, image = "brakes2.png", description = "Performance brakes"},
                {name = "Brakes Tier 3", item = "brakes3", price = 2000, image = "brakes3.png", description = "Race brakes"},
                {name = "Suspension Tier 1", item = "suspension1", price = 500, image = "suspension1.png", description = "Basic suspension"},
                {name = "Suspension Tier 2", item = "suspension2", price = 1000, image = "suspension2.png", description = "Sport suspension"},
                {name = "Suspension Tier 3", item = "suspension3", price = 2000, image = "suspension3.png", description = "Race suspension"},
                {name = "Suspension Tier 4", item = "suspension4", price = 3000, image = "suspension4.png", description = "Advanced race suspension"},
                {name = "Suspension Tier 5", item = "suspension5", price = 4000, image = "suspension5.png", description = "Pro race suspension"},
            }
        },
        {
            name = "Engine Components",
            icon = "fa-cog",
            items = {
                {name = "Oil Pump Tier 1", item = "oilp1", price = 500, image = "oilp1.png", description = "Basic oil pump"},
                {name = "Oil Pump Tier 2", item = "oilp2", price = 1000, image = "oilp2.png", description = "Performance oil pump"},
                {name = "Oil Pump Tier 3", item = "oilp3", price = 2000, image = "oilp3.png", description = "Race oil pump"},
                {name = "Drive System Tier 1", item = "drives1", price = 500, image = "drives1.png", description = "Basic drive system"},
                {name = "Drive System Tier 2", item = "drives2", price = 1000, image = "drives2.png", description = "Performance drive system"},
                {name = "Drive System Tier 3", item = "drives3", price = 2000, image = "drives3.png", description = "Race drive system"},
                {name = "Cylinder Tier 1", item = "cylind1", price = 500, image = "cylind1.png", description = "Basic cylinders"},
                {name = "Cylinder Tier 2", item = "cylind2", price = 1000, image = "cylind2.png", description = "Performance cylinders"},
                {name = "Cylinder Tier 3", item = "cylind3", price = 2000, image = "cylind3.png", description = "Race cylinders"},
                {name = "Cables Tier 1", item = "cables1", price = 500, image = "cables1.png", description = "Basic cables"},
                {name = "Cables Tier 2", item = "cables2", price = 1000, image = "cables2.png", description = "Performance cables"},
                {name = "Cables Tier 3", item = "cables3", price = 2000, image = "cables3.png", description = "Race cables"},
            }
        },
        {
            name = "Fuel & Performance",
            icon = "fa-gas-pump",
            items = {
                {name = "Fuel Tank Tier 1", item = "fueltank1", price = 500, image = "fueltank1.png", description = "Basic fuel tank"},
                {name = "Fuel Tank Tier 2", item = "fueltank2", price = 1000, image = "fueltank2.png", description = "Larger fuel tank"},
                {name = "Fuel Tank Tier 3", item = "fueltank3", price = 2000, image = "fueltank3.png", description = "Race fuel tank"},
                {name = "NOS System", item = "nos", price = 5000, image = "nos.png", description = "Nitrous oxide system"},
                {name = "Anti-Lag System", item = "antilag", price = 5000, image = "antilag.png", description = "Turbo anti-lag"},
            }
        },
        {
            name = "Body Parts",
            icon = "fa-car",
            items = {
                {name = "Hood", item = "hood", price = 500, image = "hood.png", description = "Custom hood"},
                {name = "Roof", item = "roof", price = 300, image = "roof.png", description = "Custom roof"},
                {name = "Spoiler", item = "spoiler", price = 500, image = "spoiler.png", description = "Aerodynamic spoiler"},
                {name = "Bumper", item = "bumper", price = 400, image = "bumper.png", description = "Custom bumper"},
                {name = "Side Skirts", item = "skirts", price = 300, image = "skirts.png", description = "Side skirts"},
                {name = "Exhaust", item = "exhaust", price = 400, image = "exhaust.png", description = "Performance exhaust"},
                {name = "Roll Cage", item = "rollcage", price = 1500, image = "rollcage.png", description = "Safety roll cage"},
            }
        },
        {
            name = "Cosmetics",
            icon = "fa-spray-can",
            items = {
                {name = "Paint Can", item = "paintcan", price = 100, image = "spraycan.png", description = "Vehicle paint"},
                {name = "Livery", item = "livery", price = 750, image = "livery.png", description = "Custom livery design"},
                {name = "Tint Supplies", item = "tint_supplies", price = 500, image = "tint_supplies.png", description = "Window tinting kit"},
                {name = "Custom Plate", item = "customplate", price = 300, image = "plate.png", description = "Personalized plate"},
                {name = "Underglow", item = "underglow", price = 500, image = "underglow.png", description = "LED underglow kit"},
                {name = "Underglow Controller", item = "underglow_controller", price = 350, image = "underglow_controller.png", description = "RGB controller"},
                {name = "NOS Colour", item = "noscolour", price = 200, image = "noscolour.png", description = "Colored NOS purge"},
                {name = "Headlights", item = "headlights", price = 250, image = "headlights.png", description = "Custom headlights"},
            }
        },
        {
            name = "Wheels",
            icon = "fa-circle",
            items = {
                {name = "Tires", item = "tires", price = 200, image = "tires.png", description = "Performance tires"},
                {name = "Rims", item = "rims", price = 700, image = "rims.png", description = "Custom rims"},
            }
        },
        {
            name = "Interior",
            icon = "fa-chair",
            items = {
                {name = "Seat", item = "seat", price = 300, image = "seat.png", description = "Racing seat"},
                {name = "Horn", item = "horn", price = 100, image = "horn.png", description = "Custom horn"},
                {name = "Internals", item = "internals", price = 200, image = "internals.png", description = "Interior upgrades"},
                {name = "Externals", item = "externals", price = 200, image = "mirror.png", description = "External accessories"},
                {name = "Harness", item = "harness", price = 1000, image = "harness.png", description = "Racing harness"},
            }
        },
        {
            name = "Workshop Equipment",
            icon = "fa-warehouse",
            items = {
                {name = "Road Cone", item = "roadcone", price = 25, image = "roadcone.png", description = "Traffic cone Prop"},
                {name = "Ramp 1", item = "ramp1", price = 15, image = "woodramp.png", description = "Small ramp Prop"},
                {name = "Ramp 2", item = "ramp2", price = 25, image = "woodramp.png", description = "Medium ramp Prop"},
                {name = "Ramp 3", item = "ramp3", price = 35, image = "woodramp.png", description = "Large ramp Prop"},
                {name = "Ramp 4", item = "ramp4", price = 45, image = "metalramp.png", description = "Extra large ramp Prop"},
                {name = "Ramp 5", item = "ramp5", price = 55, image = "metalramp.png", description = "Professional ramp Prop"},
                {name = "Car Jack", item = "carjack", price = 35, image = "carjack.png", description = "Hydraulic car jack Prop"},
                {name = "Tool Chest", item = "toolchest", price = 50, image = "toolchest.png", description = "Storage chest Prop"},
            }
        },
    },
    
    specialOffers = {
        {name = "Stancing Bundle", description = "Full Stance Setup ", originalPrice = 3000, salePrice = 2750, image = "stancerkit.png"},
        {name = "Vehicle Detail", description = "Full Interior and Exterior Detail", originalPrice = 200, salePrice = 100, image = "cleaningkit.png"},
		{name = "Membership Program", description = "20% discount on all sales", originalPrice = 25000, salePrice = 17500, image = "gym_pass.png"},
    }
},

	-- BURGERSHOT EXAMPLE
    -- {
        -- name = "Burgershot Menu",
        -- location = vector3(-1193.52, -895.15, 13.99),
        -- blip = {
            -- enabled = true,
            -- sprite = 106,
            -- color = 46,
            -- scale = 0.7,
            -- name = "Burgershot Menu"
        -- },
        -- theme = "orange", -- Options: blue, red, green, purple, orange
        -- jobs = {'burgershot'}, -- Leave empty {} for public access
        
        -- categories = {
            -- {
                -- name = "Burgers",
                -- icon = "fa-burger",
                -- items = {
                    -- {name = "Classic Burger", item = "burger", price = 8, image = "burger.png", description = "Juicy beef patty with fresh toppings"},
                    -- {name = "Cheese Burger", item = "cheeseburger", price = 10, image = "cheeseburger.png", description = "Classic with melted cheese"},
                    -- {name = "Double Burger", item = "doubleburger", price = 15, image = "doubleburger.png", description = "Two patties, double the flavor"},
                    -- {name = "Bacon Burger", item = "baconburger", price = 12, image = "baconburger.png", description = "Crispy bacon on top"},
                -- }
            -- },
            -- {
                -- name = "Sides",
                -- icon = "fa-drumstick-bite",
                -- items = {
                    -- {name = "French Fries", item = "fries", price = 5, image = "fries.png", description = "Crispy golden fries"},
                    -- {name = "Onion Rings", item = "onionrings", price = 6, image = "onionrings.png", description = "Battered and fried"},
                    -- {name = "Chicken Nuggets", item = "nuggets", price = 7, image = "nuggets.png", description = "6 piece tender nuggets"},
                -- }
            -- },
            -- {
                -- name = "Drinks",
                -- icon = "fa-glass-water",
                -- items = {
                    -- {name = "Soda", item = "soda", price = 3, image = "soda.png", description = "Refreshing cola"},
                    -- {name = "Water", item = "water", price = 2, image = "water.png", description = "Bottled water"},
                    -- {name = "Milkshake", item = "milkshake", price = 6, image = "milkshake.png", description = "Creamy milkshake"},
                    -- {name = "Coffee", item = "coffee", price = 4, image = "coffee.png", description = "Hot brewed coffee"},
                -- }
            -- },
        -- },
        
        -- specialOffers = {
            -- {name = "Meal Deal", description = "Burger + Fries + Drink", originalPrice = 16, salePrice = 12, image = "mealdeal.png"},
            -- {name = "Family Pack", description = "4 Burgers + 2 Large Fries", originalPrice = 45, salePrice = 35, image = "familypack.png"},
            -- {name = "Breakfast Special", description = "Available until 11am", originalPrice = 10, salePrice = 7, image = "breakfast.png"},
        -- }
    -- },

    -- POLICE ARMORY EXAMPLE
    -- {
        -- name = "LSPD Armory",
        -- location = vector3(452.95, -980.18, 30.69),
        -- blip = {
            -- enabled = false,
        -- },
        -- theme = "blue",
        -- jobs = {'police'},
        
        -- categories = {
            -- {
                -- name = "Firearms",
                -- icon = "fa-gun",
                -- items = {
                    -- {name = "Pistol", item = "weapon_pistol", price = 0, image = "weapon_pistol.png", description = "Standard issue sidearm"},
                    -- {name = "Combat Pistol", item = "weapon_combatpistol", price = 0, image = "weapon_combatpistol.png", description = "Enhanced sidearm"},
                    -- {name = "Pump Shotgun", item = "weapon_pumpshotgun", price = 0, image = "weapon_pumpshotgun.png", description = "Close quarters"},
                    -- {name = "Carbine Rifle", item = "weapon_carbinerifle", price = 0, image = "weapon_carbinerifle.png", description = "Tactical rifle"},
                -- }
            -- },
            -- {
                -- name = "Ammunition",
                -- icon = "fa-circle",
                -- items = {
                    -- {name = "Pistol Ammo", item = "pistol_ammo", price = 0, image = "pistol_ammo.png", description = "50 rounds"},
                    -- {name = "Shotgun Ammo", item = "shotgun_ammo", price = 0, image = "shotgun_ammo.png", description = "25 shells"},
                    -- {name = "Rifle Ammo", item = "rifle_ammo", price = 0, image = "rifle_ammo.png", description = "100 rounds"},
                -- }
            -- },
            -- {
                -- name = "Equipment",
                -- icon = "fa-shield",
                -- items = {
                    -- {name = "Body Armor", item = "armor", price = 0, image = "armor.png", description = "Ballistic protection"},
                    -- {name = "Flashlight", item = "flashlight", price = 0, image = "flashlight.png", description = "Tactical light"},
                    -- {name = "Radio", item = "radio", price = 0, image = "radio.png", description = "Department radio"},
                -- }
            -- },
        -- },
        
        -- specialOffers = {
            -- {name = "Patrol Kit", description = "Everything needed for patrol", originalPrice = 0, salePrice = 0, image = "patrolkit.png"},
        -- }
    -- },

    -- HOSPITAL PHARMACY EXAMPLE
    -- {
        -- name = "Pillbox Pharmacy",
        -- location = vector3(306.55, -595.45, 43.29),
        -- blip = {
            -- enabled = true,
            -- sprite = 51,
            -- color = 2,
            -- scale = 0.7,
            -- name = "Pharmacy"
        -- },
        -- theme = "red",
        -- jobs = {},
        
        -- categories = {
            -- {
                -- name = "Prescriptions",
                -- icon = "fa-prescription-bottle",
                -- items = {
                    -- {name = "Painkillers", item = "painkillers", price = 50, image = "painkillers.png", description = "For moderate pain"},
                    -- {name = "Antibiotics", item = "antibiotics", price = 75, image = "antibiotics.png", description = "Treats infections"},
                    -- {name = "Bandages", item = "bandage", price = 25, image = "bandage.png", description = "Stop bleeding"},
                -- }
            -- },
            -- {
                -- name = "Medical Supplies",
                -- icon = "fa-kit-medical",
                -- items = {
                    -- {name = "First Aid Kit", item = "firstaid", price = 100, image = "firstaid.png", description = "Emergency supplies"},
                    -- {name = "Medical Bag", item = "medicalbag", price = 500, image = "medicalbag.png", description = "Professional kit"},
                    -- {name = "Defibrillator", item = "defib", price = 1000, image = "defib.png", description = "AED unit"},
                -- }
            -- },
        -- },
        
        -- specialOffers = {
            -- {name = "Health Bundle", description = "First aid + painkillers + bandages", originalPrice = 175, salePrice = 125, image = "healthbundle.png"},
        -- }
    -- },

    -- 24/7 STORE EXAMPLE
    -- {
        -- name = "24/7 Store",
        -- location = vector3(25.74, -1346.91, 29.5),
        -- blip = {
            -- enabled = true,
            -- sprite = 52,
            -- color = 2,
            -- scale = 0.6,
            -- name = "24/7 Store"
        -- },
        -- theme = "green",
        -- jobs = {},
        
        -- categories = {
            -- {
                -- name = "Snacks",
                -- icon = "fa-cookie-bite",
                -- items = {
                    -- {name = "Sandwich", item = "sandwich", price = 4, image = "sandwich.png", description = "Quick meal"},
                    -- {name = "Chips", item = "chips", price = 2, image = "chips.png", description = "Salty snack"},
                    -- {name = "Chocolate Bar", item = "chocolate", price = 3, image = "chocolate.png", description = "Sweet treat"},
                -- }
            -- },
            -- {
                -- name = "Drinks",
                -- icon = "fa-bottle-water",
                -- items = {
                    -- {name = "Water Bottle", item = "water", price = 2, image = "water.png", description = "Refreshing water"},
                    -- {name = "Energy Drink", item = "energydrink", price = 5, image = "energydrink.png", description = "Stay alert"},
                    -- {name = "Beer", item = "beer", price = 7, image = "beer.png", description = "Cold beer"},
                -- }
            -- },
            -- {
                -- name = "Tools",
                -- icon = "fa-screwdriver-wrench",
                -- items = {
                    -- {name = "Phone", item = "phone", price = 500, image = "phone.png", description = "Basic smartphone"},
                    -- {name = "Lockpick", item = "lockpick", price = 50, image = "lockpick.png", description = "Basic lockpick"},
                    -- {name = "Backpack", item = "backpack", price = 200, image = "backpack.png", description = "Carry more items"},
                -- }
            -- },
        -- },
        
        -- specialOffers = {
            -- {name = "Snack Pack", description = "2 snacks + 1 drink", originalPrice = 9, salePrice = 6, image = "snackpack.png"},
        -- }
    -- },
}