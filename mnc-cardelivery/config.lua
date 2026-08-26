Config = {}

-- ===================================================================
-- GENERAL
-- ===================================================================
Config.Locale = 'en'
Config.VehicleKeysSystem = 'legacy'
Config.VehicleKeysResourceName = 'qb-vehiclekeys' -- resource name used for the export, only matters when VehicleKeysSystem = 'qbx'

-- Account money is paid into: 'cash' | 'bank'
Config.PayoutAccount = 'bank'

-- ===================================================================
-- ADMIN / ROUTE BUILDER
-- ===================================================================
Config.Admin = {
    Command = 'setupcardelivery', -- opens the route builder UI (add/remove delivery routes, saved to SQL)

    AcePermission = 'admin',

    RouteTimer = {
        BufferPercent = 15, -- % added on top of the raw drive time, gives players margin over an admin's "perfect" run
        MinTime       = 45, -- floor on the resulting time limit (seconds), regardless of how fast the drive was
        RoundTo       = 10, -- round the final time limit to the nearest N seconds
    },

    Placement = {
        PreviewVehicle  = 'sultan', 
        MoveSpeed       = 15.0, 
        FastMultiplier  = 4.0,  
        RotateSpeed     = 90.0, 
        LookSensitivity = 4.0,
        CamFov          = 60.0,
    },
}

-- ===================================================================
-- DISTANCE BASED LOADING
-- ===================================================================
Config.Streaming = {
    CheckInterval   = 3000, -- ms between distance checks per player
    SpawnDistance   = 120.0, -- spawn the delivery vehicle once a player is within this many units of the spawn point
    DespawnDistance = 200.0, -- despawn it again once every nearby player has left this range (only if nobody has claimed it)
}

-- Distance the player has to be from the vehicle (on foot, keys not yet claimed) to trigger the audio prompt
Config.PromptDistance = 3.0

-- ===================================================================
-- DAMAGE
-- ===================================================================
Config.MaxDamagePercent = 20 -- the player can never push the vehicle's damage above this, extra damage is nullified.
Config.DamageCheckInterval = 150 -- ms, how often the delivery loop checks/caps health while a job is active
Config.DamageSoundCooldown = 3000 -- ms, minimum time between damageX.mp3 stings so it doesn't spam on multi-hit collisions

-- ===================================================================
-- RANDOM MODS (applied on spawn)
-- ===================================================================
Config.Mods = {

    PerformanceModTypes = { 11, 12, 13 }, -- Engine, Brakes, Transmission
	
    AlwaysTurbo = true, -- native mod type 18 (toggle)

    CosmeticModTypes = {
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14, 16,
        22, 23, 24, 25, 27, 28, 30, 33, 34,
        38, 39, 40, 41, 42, 44, 45, 46, 48, 49,
        51, 52, 53, 54, 55, 56, 57, 59, 61, 62,
        63, 64, 65, 66, 67, 68, 69, 70, 71, 72,
    },
    CosmeticChance = 0.6, 
    RandomizeColor = true,
    RandomizePlate = true,
    PlatePrefix = 'MNC', 
}

-- ===================================================================
-- PAYOUT
-- ===================================================================
Config.Payout = {
    BasePercent        = 0.08, -- 8% of vehicle value at 0 damage / instant delivery
    MinPercent         = 0.02, -- payout never drops below 2% of vehicle value on a success
    MaxPercent         = 0.15, -- payout never exceeds 15% of vehicle value
    DamagePenaltyWeight = 0.6, -- how much reaching MaxDamagePercent damage cuts payout (0-1)
    TimeBonusWeight     = 0.4, -- how much finishing right at the time limit cuts payout (0-1), faster = closer to full bonus
    DefaultVehicleValue = 15000, -- fallback if the model isn't found in QBCore.Shared.Vehicles
}

-- ===================================================================
-- SOUNDS
-- ===================================================================
Config.Sounds = {
    PromptCount  = 19, -- prompt1.mp3 .. prompt4.mp3
    DamageCount  = 19, -- damage1.mp3 .. damage4.mp3
    SuccessCount = 19, -- success1.mp3 .. success4.mp3
    FailCount    = 19, -- fail1.mp3 .. fail4.mp3
    -- dropoff.mp3 plays once (no numbered variants) when the vehicle is at the delivery point
}

-- ===================================================================
-- BLIPS
-- ===================================================================
Config.Blips = {
    Pickup = { sprite = 724, color = 27, scale = 0.8, label = 'Vehicle Delivery Pick Up' },
    Dropoff = { sprite = 478, color = 27, scale = 1.0, label = 'Vehicle Delivery Drop Off' },
}

-- ===================================================================
-- DELIVERY LOCATIONS
-- ===================================================================
Config.Locations = {
    {
        spawn    = vector4(-31.56, -1089.53, 25.84, 319.92),
        delivery = vector3(-129.89, -2669.04, 5.42),
        radius   = 8.0,
        time     = 300,
        vehicles = { 'sultan', 'kuruma', 'elegy2' },
    },
    {
        spawn    = vector4(-1626.04, -798.43, 9.61, 206.9),
        delivery = vector3(-129.94, -2662.5, 5.42),
        radius   = 8.0,
        time     = 420,
        vehicles = { 'sandking', 'bison', 'sadler' },
    },
}