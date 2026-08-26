Config = {}
Config.Debug = false                        -- prints why a lift attempt failed to the F8 console
Config.ShowHelperUI = true
Config.ForkliftLiftKeyLabel = 'O'
Config.StackKeyLabelAttach = 'H'
Config.StackKeyLabelDetach = 'N'
Config.UseOxLibNotify = true               -- Set false to fall back to native gta notifications
Config.ForksBoneName = 'forks'             -- bone name on the forklift's forks
Config.PickupDistance = 4.0                -- max HORIZONTAL distance (meters) from forks bone to a vehicle to allow pickup
Config.PropPickupDistance = 4.0            -- max HORIZONTAL distance (meters) from forks bone to a prop to allow pickup
Config.PlatformPickupDistance = 15.0       -- max horizontal distance for platform/lift-mode attach (forklift -> vehicle)
Config.StackSearchDistance = 5.0           -- max distance from vehicle to attach vehicle to another vehicle
Config.StackDetachHoldTimePerLevel = 1000  -- milliseconds per level
Config.ToggleControl = 38                  -- INPUT_PICKUP (E by default) - Attach / Detach
Config.StackAttachKey = 74                 -- H
Config.StackDetachKey = 249                -- N
Config.LiftControl = 172                   -- INPUT_VEH_SELECT_NEXT_WEAPON (Up Arrow by default)
Config.LowerControl = 173                  -- INPUT_VEH_SELECT_PREV_WEAPON (Down Arrow by default)
Config.LiftSpeed = 0.5                     -- meters per second while lift/lower is held
Config.MinLiftOffset = -1.0                -- lowest the vehicle can be nudged relative to its captured pickup height
Config.MaxLiftOffset = 2.0                 -- highest the vehicle can be nudged relative to its captured pickup height
Config.ForkliftLiftMinOffset = -1.0        -- lowest the forklift can be nudged relative to its anchor point
Config.ForkliftLiftMaxOffset = 3.0         -- highest the forklift can be nudged relative to its anchor point
Config.Forklifts = {
    [`forklift`] = { -- default GTA V forklift
        categories = {
            [0] = true,  -- Compacts
            [1] = true,  -- Sedans
            [2] = true,  -- SUVs
            [3] = true,  -- Coupes
            [4] = true,  -- Muscle
            [5] = true,  -- Sports Classics
            [6] = true,  -- Sports
            [7] = true,  -- Super
            [8] = true,  -- Motorcycles
            [9] = true,  -- Off-road
            --[10] = true, -- Industrial
            [11] = true, -- Utility
            [12] = true, -- Vans
            [13] = true, -- Cycles
            --[14] = true, -- Boats
            --[15] = true, -- Helicopters
            --[16] = true, -- Planes
            [17] = true, -- Service
            [18] = true, -- Emergency
            --[19] = true, -- Military
            --[20] = true, -- Commercial
            --[21] = true, -- Trains
        }
    },
    -- Example of a second, bigger forklift that can lift more classes:
    [`vstruck`] = {
        categories = {
            [0] = true,  -- Compacts
            [1] = true,  -- Sedans
            [2] = true,  -- SUVs
            [3] = true,  -- Coupes
            [4] = true,  -- Muscle
            [5] = true,  -- Sports Classics
            [6] = true,  -- Sports
            [7] = true,  -- Super
            [8] = true,  -- Motorcycles
            [9] = true,  -- Off-road
            [10] = true, -- Industrial
            [11] = true, -- Utility
            [12] = true, -- Vans
            [13] = true, -- Cycles
            [14] = true, -- Boats
            [15] = true, -- Helicopters
            [16] = true, -- Planes
            [17] = true, -- Service
            [18] = true, -- Emergency
            [19] = true, -- Military
            [20] = true, -- Commercial
            [21] = true, -- Trains
        }
    },
}
-- Platform base vehicle restrictions (vehicles the forklift can be lifted ONTO)
Config.PlatformBaseClasses = {
    [10] = true,  -- Industrial
    [11] = true,  -- Utility
    [12] = true,  -- Vans
    [17] = true,  -- Service
    [20] = true,  -- Commercial
}
-- Which forklift models are allowed to lift vehicles, and which vehicle
-- classes each one is allowed to lift. Vehicle class IDs are the standard
-- GTA V vehicle class enum:
--   0  Compacts        8  Motorcycles     16 Planes
--   1  Sedans          9  Off-road        17 Service
--   2  SUVs            10 Industrial      18 Emergency
--   3  Coupes          11 Utility         19 Military
--   4  Muscle          12 Vans            20 Commercial
--   5  Sports Classics 13 Cycles          21 Trains
--   6  Sports          14 Boats
--   7  Super           15 Helicopters