-- config.lua
Config = {}

Config.Debug = false

-- ============================================================================================================
--                                         Job Restrictions
-- ============================================================================================================
Config.RequireJob = true

Config.AllowedJobs = {
    mechanic    = 0,
    mechanic2   = 0,
    mechanic3   = 0,
    beekers     = 0,
    autoexotics = 0,
    bennys      = 2,
    tuner       = 1,
}

-- ============================================================================================================
--                                         Hydro Items
--
-- HOW IT WORKS:
-- ─────────────
-- fHandBrakeForce — the force applied when the handbrake is held. GTA's default
--                   is typically 0.9–1.0 for most vehicles.
--                   Raising this makes the rear wheels lock harder and faster,
--                   giving a more aggressive e-brake / hydraulic feel.
--
-- HandbrakeForce  — the value fHandBrakeForce is set to while the hydro is
--                   installed. Higher = snappier, more responsive rear lockup.
--
-- InstallTime     — milliseconds the install progress bar takes.
-- ============================================================================================================

Config.Hydros = {
    street_hydro = {
        item          = 'street_hydro',
        label         = 'Street Hydraulics',
        type          = 'street',
        installTime   = 5000,

        -- fHandBrakeForce applied while installed
        HandbrakeForce = 3.5,
    },

    comp_hydro = {
        item          = 'comp_hydro',
        label         = 'Competition Hydraulics',
        type          = 'comp',
        installTime   = 7000,

        -- fHandBrakeForce applied while installed (stronger than street)
        HandbrakeForce = 7.0,
    },
}

-- ============================================================================================================
--                                         Item Duration
-- Each hydro has 3 hours of in-vehicle playtime before wearing out.
-- ============================================================================================================
Config.HydroDurationMs = 3 * 60 * 60 * 1000   -- 3 hours in milliseconds

Config.ApplyDistance   = 2.5     -- metres — proximity needed to install

-- Tier system — higher tier overwrites lower tier
Config.HydroTier = {
    street_hydro = 1,
    comp_hydro   = 2,
}