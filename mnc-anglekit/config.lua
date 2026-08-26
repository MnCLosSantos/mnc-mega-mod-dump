-- config.lua
Config = {}

Config.Debug = false

-- ============================================================================================================
--                                         Job Restrictions
-- Set Config.RequireJob = true to restrict kit installation to specific jobs/grades.
-- Set to false to allow any player to use the items regardless of job.
-- AllowedJobs: key = job name, value = minimum grade required (0 = any grade of that job).
-- ============================================================================================================
Config.RequireJob = true

Config.AllowedJobs = {
    mechanic = 0,   -- any grade
	mechanic2 = 0,
	mechanic3 = 0,
	beekers = 0,
	autoexotics = 0,
    bennys    = 2,
    tuner     = 1,
}

-- ============================================================================================================
--                                         Angle Kit Items
-- Each kit sets a fixed steering lock angle (in degrees) applied to the front wheels.
-- The Pro kit additionally allows the /angle command to set a custom value between 1 and MaxAngle.
-- ============================================================================================================

Config.Kits = {
    basic_angle_kit = {
        item         = 'basic_angle_kit',
        label        = 'Basic Angle Kit',
        angle        = 45,       -- degrees of steering lock granted
        installTime  = 4000,     -- progress bar duration (ms)
        canSetAngle  = false,    -- no /angle command for basic
    },
    street_angle_kit = {
        item         = 'street_angle_kit',
        label        = 'Street Angle Kit',
        angle        = 55,
        installTime  = 5000,
        canSetAngle  = false,
    },
    pro_angle_kit = {
        item         = 'pro_angle_kit',
        label        = 'Pro Angle Kit',
        angle        = 65,       -- default angle; player can override via /angle
        installTime  = 6000,
        canSetAngle  = true,     -- enables /angle command
    },
}

Config.Remover = {
    item       = 'angle_kit_remover',
    label      = 'Angle Kit Remover',
    removeTime = 5000,     -- total time for all 4 wheels (ms)
}

Config.MaxAngle       = 85      -- hard ceiling on /angle input
Config.MinAngle       = 45      -- floor for /angle input

Config.ApplyDistance  = 2.5     -- max distance to the vehicle for item use

-- Kit hierarchy — installing a higher tier overwrites a lower tier.
-- Order: basic < street < pro  (index = tier level)
Config.KitTier = {
    basic_angle_kit  = 1,
    street_angle_kit = 2,
    pro_angle_kit    = 3,
}