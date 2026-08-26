-- config.lua
Config = {}

Config.Debug = false

-- Max vehicles a player can have parked/out at once
Config.MaxVehiclesOut = 4

-- The item name that must be physically installed on a vehicle before /park works
Config.ParkingLockItem = 'parking_lock'

-- The item name used to remove a parking lock from a vehicle
Config.ParkingKeyItem = 'parking_key'

-- How often (ms) the client syncs the vehicle's current position/state back to the server
Config.SaveInterval = 30000   -- 30 seconds

-- Max distance (metres) from the player to a vehicle to install the parking lock
Config.InteractDistance = 2.5

-- Garage name used in qb-garages as a fallback
Config.RecallGarage = 'pillboxgarage'

-- Garage vehicles are sent to when moved away from their parking spot
-- Must match a valid garage name in qb-garages (the impound lot is best as it'll just get sent there anyways)
Config.ImpoundGarage = 'depotLot'

-- Commands that open the parked-vehicles menu
Config.Commands = {
    'parked',
}

-- Park an owned vehicle you can't sit in (trailers, etc.) by standing
-- next to it, running /park, and picking it by plate.
Config.TrailerPark = {
    Enabled          = true,
    InteractDistance = 10.0,   -- metres to scan for nearby parkable vehicles
}

-- Map blip for each parked vehicle (owner only)
Config.Blip = {
    Enabled = true,
    Sprite  = 225,   -- car icon
    Scale   = 0.8,
    Colour  = 3,     -- blue
}

-- ─── No-Parking / No-Cover Zones ─────────────────────────────────────────────
-- Players cannot use /park or cover a vehicle while inside any of these zones.
-- Each entry: { coords = vector3(x, y, z), radius = metres, label = 'display name' }
-- The label is shown in the notification the player receives.
Config.NoParkZones = {

    -- Example: block parking inside the Mission Row PD lot
    { coords = vector3(441.0, -982.0, 30.7), radius = 100.0, label = 'Mission Row PD' },

    -- Example: block parking inside the casino complex
    { coords = vector3(925.2, 47.0, 81.1), radius = 100.0, label = 'The Diamond Casino' },
	
	-- Example: block parking by pillbox
    { coords = vector3(297.1, -584.4, 43.13), radius = 100.0, label = 'Pillbox Medical center' },
	
	-- Example: block parking by leigion square
    { coords = vector3(220.83, -792.14, 30.51), radius = 100.0, label = 'Leigion Square' },
	
	-- Example: block parking by PDM
    { coords = vector3(-42.79, -1110.88, 26.16), radius = 100.0, label = 'PDM' },
	
	-- Example: block parking by Bennys
    { coords = vector3(-222.83, -1327.49, 39.69), radius = 100.0, label = 'Bennys' },
	
	-- Example: block parking beekers  (downsize if needed)
    { coords = vector3(107.72, 6625.5, 38.43), radius = 200.0, label = 'Beekers' },
	
	-- Example: block parking mech shops
    { coords = vector3(-338.27, -136.59, 38.73), radius = 100.0, label = 'Mechanic shop' },
	
	-- Example: block parking mech shops
    { coords = vector3(-1154.79, -2005.16, 18.23), radius = 100.0, label = 'Mechanic shop' },
	
	-- Example: block parking mech shops
    { coords = vector3(730.54, -1084.35, 21.89), radius = 100.0, label = 'Mechanic shop' },
	
	-- Example: block parking mech shops
    { coords = vector3(1178.81, 2642.99, 37.49), radius = 100.0, label = 'Mechanic shop' },
}

-- ─── Discord VIP Slots ────────────────────────────────────────────────────────

-- Set VipMaxVehiclesOut to however many slots VIP players should receive.
Config.VipMaxVehiclesOut = 15

Config.VipDiscordIds = {
    -- '1234',   -- example Discord snowflake ID
    -- '9876',
}

Config.Cover = {
 
    -- ─── Items ───────────────────────────────────────────────────────────
    CoverItem = 'vehicle_tarp',  -- item consumed to cover the vehicle
	CoverRemoveItem = 'vehicle_tarp_box', -- item to get a stuck cover back
 
    -- ─── Prop models ─────────────────────────────────────────────────────
    -- Cover prop chosen by GTA vehicle class (GetVehicleClass returns 0-22).
    FallbackCoverProp = 'imp_prop_covered_vehicle_03a',
    CoverProps = {
        [0]  = 'imp_prop_covered_vehicle_02a',   -- Compacts
        [1]  = 'imp_prop_covered_vehicle_03a',   -- Sedans
        [2]  = 'imp_prop_covered_vehicle_07a',   -- SUVs
        [3]  = 'prop_jb700_covered',             -- Coupes
        [4]  = 'imp_prop_covered_vehicle_02a',   -- Muscle
        [5]  = 'prop_ztype_covered',             -- Sports Classics
        [6]  = 'imp_prop_covered_vehicle_04a',   -- Sports
        [7]  = 'prop_entityxf_covered',          -- Super
        [9]  = 'imp_prop_covered_vehicle_07a',   -- Off-road
        [10] = 'imp_prop_covered_vehicle_03a',   -- Industrial
        [11] = 'imp_prop_covered_vehicle_07a',   -- Utility
        [12] = 'imp_prop_covered_vehicle_07a',   -- Vans
    },
	
    -- ─── Timings (ms) ────────────────────────────────────────────────────
    CoverDuration   = 4000,   -- progress bar for covering / uncovering
 
    -- ─── Interaction distance (metres) ───────────────────────────────────
    InteractDistance = 2.5,
}