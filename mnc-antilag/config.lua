Config = {}

Config.Debug = false

Config.RequireJob = true
Config.AllowedJobs = {
    ['mechanic'] = 0,
    ['bennys']   = 0,
}

-- Global volume control (0.0 = silent, 1.0 = full)
-- Acts as fallback if a kit doesn't specify its own volumeScale
Config.MaxVolumeScale = 0.06

-- Sound file to use when no kit-level soundFile is set.
-- Place your .ogg files in: html/sounds/
Config.DefaultSoundFile = 'antilag_pop.ogg'

-- burstInterval : ms between flame bursts
-- flameCount    : pops per burst
-- scale         : particle size
-- volumeScale   : per-kit volume multiplier (0.0–1.0)
-- soundFile     : .ogg filename inside html/sounds/ (optional, falls back to Config.DefaultSoundFile)
Config.Kits = {
    ['antilag_1'] = {
        label         = 'Basic Anti-Lag Kit',
        item          = 'antilag_1',
        burstInterval = 1200,
        flameCount    = 1,
        scale         = 1.0,
        volumeScale   = 0.05,
        soundFile     = 'antilag_pop.ogg',
    },
    ['antilag_2'] = {
        label         = 'Street Anti-Lag Kit',
        item          = 'antilag_2',
        burstInterval = 800,
        flameCount    = 3,
        scale         = 1.2,
        volumeScale   = 0.06,
        soundFile     = 'antilag_pop.ogg',
    },
    ['antilag_3'] = {
        label         = 'Pro Anti-Lag Kit',
        item          = 'antilag_3',
        burstInterval = 700,
        flameCount    = 4,
        scale         = 1.5,
        volumeScale   = 0.07,
        soundFile     = 'antilag_pop.ogg',
    },
}

Config.KitTier = {
    ['antilag_1'] = 1,
    ['antilag_2'] = 2,
    ['antilag_3'] = 3,
}

Config.MinRPM      = 0.65  -- 0.0–1.0 RPM threshold
Config.LiftOffOnly = true  -- true = only fires when throttle is released (antilag)