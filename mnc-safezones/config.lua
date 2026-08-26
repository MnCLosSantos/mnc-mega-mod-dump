Config = {}

Config.Debug = false

-- Jobs that bypass safe zone restrictions
Config.ExemptJobs = {
    'police',
    'fire',
    'ambulance',
    'sheriff',
    'swat',
}

Config.NotifyOnEnter = true
Config.NotifyOnExit  = true

-- Default vertical thickness (height) when a zone doesn't specify one
Config.DefaultHeightRange = 20.0

-- Safe zones are now drawn as polygons (straight-edge boundaries) instead of
-- circles. Each zone needs at least this many vector points to form a valid
-- shape. Admins capture points from the /safezones panel — either "Capture My
-- Position" on foot, or by flying around with "Start Freecam".
Config.MinZonePoints = 4

-- ─── Freecam settings (started from the /safezones panel) ────────────────────
Config.FreecamSpeed           = 1.5    -- fixed fly speed (units per tick)
Config.FreecamBoostMultiplier = 3.0    -- multiplier while holding Shift
Config.FreecamLookSensitivity = 200.0
-- How far in front of the camera the preview/placement point sits, so it's
-- always visible on screen instead of sitting invisibly at the camera itself.
Config.FreecamPreviewDistance = 2.5