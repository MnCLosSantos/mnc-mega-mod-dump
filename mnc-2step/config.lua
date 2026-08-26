Config = {}

Config.Debug = false

Config.RequireJob = true
Config.AllowedJobs = {
    ['mechanic'] = 0,
    ['bennys']   = 0,
}

-- Global volume control (0.0 = silent, 1.0 = full)
Config.MaxVolumeScale = 0.07

-- Sound file to use when no kit-level soundFile is set.
-- Place your .ogg files in: html/sounds/
Config.DefaultSoundFile = 'twostep_pop.ogg'

-- 2-Step key (Right Shift = 21 in GTA V control index)
-- https://docs.fivem.net/docs/game-references/controls/
Config.TwoStepKey = 21  -- INPUT_SPRINT = Right Shift (on foot: sprint, in vehicle: can be polled freely)

-- ─────────────────────────────────────────────
-- Rev-limiter bounce (vehicle stationary, key held)
-- Fires bangs rapidly as the engine bounces off the limiter
-- ─────────────────────────────────────────────
Config.Limiter = {
    burstInterval = 300,   -- ms between bursts while on limiter
    flameCount    = 2,     -- pops per burst
    scale         = 0.80,   -- particle size
    volumeScale   = 0.09,  -- volume
    soundFile     = 'twostep_pop.ogg',
    rpmThreshold  = 0.82,  -- RPM must be at or above this (0.0–1.0) to be "on the limiter"
    speedThreshold = 35.0,  -- m/s — below this = step inactive unless on limiter
}

-- ─────────────────────────────────────────────
-- Rolling 2-step (vehicle moving, key held)
-- Fires bangs as the car is held on boost/rev
-- ─────────────────────────────────────────────
Config.Rolling = {
    burstInterval = 300,   -- ms between bursts while rolling
    flameCount    = 3,
    scale         = 1.5,
    volumeScale   = 0.07,
    soundFile     = 'twostep_pop.ogg',
    rpmThreshold  = 0.70,  -- lower threshold for rolling 2-step
}

-- ─────────────────────────────────────────────
-- Launch boost (applied on key release while moving)
-- ─────────────────────────────────────────────
Config.Boost = {
    duration      = 3000,  -- ms the boost lasts after key release
    multiplier    = 1.35,  -- engine torque multiplier (1.0 = stock)
    finalBurst    = 6,     -- big pop burst on release
    finalScale    = 2.2,   -- particle scale for launch burst
    finalVolume   = 0.12,  -- volume for launch burst
    soundFile     = 'twostep_pop.ogg',
}

-- ─────────────────────────────────────────────
-- Kits
-- burstInterval, flameCount, scale, volumeScale, soundFile
-- are per-kit overrides.  Fields left nil fall back to
-- Config.Limiter / Config.Rolling / Config.Boost above.
-- ─────────────────────────────────────────────
Config.Kits = {
    ['basic_2step'] = {
        label        = 'Basic 2-Step',
        item         = 'basic_2step',
        limiter = {
            burstInterval = 220,
            flameCount    = 2,
            scale         = 1.3,
            volumeScale   = 0.06,
            soundFile     = 'twostep_pop.ogg',
        },
        rolling = {
            burstInterval = 400,
            flameCount    = 2,
            scale         = 1.2,
            volumeScale   = 0.06,
            soundFile     = 'twostep_pop.ogg',
        },
        boost = {
            duration   = 2500,
            multiplier = 1.20,
            finalBurst = 4,
            finalScale = 1.8,
            finalVolume = 0.09,
        },
    },
    ['street_2step'] = {
        label        = 'Street 2-Step',
        item         = 'street_2step',
        limiter = {
            burstInterval = 190,
            flameCount    = 3,
            scale         = 1.6,
            volumeScale   = 0.08,
            soundFile     = 'twostep_pop.ogg',
        },
        rolling = {
            burstInterval = 310,
            flameCount    = 3,
            scale         = 1.4,
            volumeScale   = 0.07,
            soundFile     = 'twostep_pop.ogg',
        },
        boost = {
            duration   = 3000,
            multiplier = 1.30,
            finalBurst = 5,
            finalScale = 2.0,
            finalVolume = 0.11,
        },
    },
    ['pro_2step'] = {
        label        = 'Pro 2-Step',
        item         = 'pro_2step',
        limiter = {
            burstInterval = 160,
            flameCount    = 5,
            scale         = 2.0,
            volumeScale   = 0.10,
            soundFile     = 'twostep_pop.ogg',
        },
        rolling = {
            burstInterval = 260,
            flameCount    = 4,
            scale         = 1.7,
            volumeScale   = 0.09,
            soundFile     = 'twostep_pop.ogg',
        },
        boost = {
            duration    = 3500,
            multiplier  = 1.45,
            finalBurst  = 8,
            finalScale  = 2.5,
            finalVolume = 0.14,
        },
    },
}

Config.KitTier = {
    ['basic_2step']  = 1,
    ['street_2step'] = 2,
    ['pro_2step']    = 3,
}