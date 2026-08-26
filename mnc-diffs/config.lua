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
--                                         Differential Items
--
-- HOW IT WORKS:
-- ─────────────
-- Two handling floats are scaled as RPM rises past SpinRpm:
--
-- fTractionCurveMin    — the grip floor of the tyres. Lowering it makes the rear wheels
--                        break loose and spin more easily. Stock is roughly 1.7–2.2.
--                        TractionMin is the value it lerps down to at full RPM.
--
-- fTractionLossMult    — how aggressively traction is lost under wheelspin. Raising this
--                        makes both rear wheels spin together (locked diff feel).
--                        SpinLossMult is the value it lerps up to at full RPM.
--
--
-- SpinRpm              — normalised RPM (0.0–1.0) where traction starts dropping.
--                        Below this RPM the vehicle behaves completely stock.
--
-- TractionMin          — fTractionCurveMin target at full RPM. Lower = more spin.
--                        Typical stock values: 1.7–2.2. Good spin values: 0.1–0.5.
--
-- SpinLossMult         — fTractionLossMult target at full RPM. Higher = both wheels
--                        lose grip faster together. Stock: ~1.0. Locked feel: 5.0–15.0.
--
-- GearSpinCutoff       — gear number where the diff effect is suppressed and stock
--                        handling restored. Simulates the diff becoming irrelevant at
--                        speed. Set to 0 to keep the diff active in all gears.
-- ============================================================================================================

Config.Diffs = {
    welded_diff = {
        item           = 'welded_diff',
        label          = 'Welded Differential',
        type           = 'welded',
        installTime    = 5000,

        -- RPM (0.0–1.0) where rear traction starts dropping
        SpinRpm        = 0.90,
        -- fTractionCurveMin floor at full RPM (lower = more wheelspin)
        TractionMin    = 0.45,
        -- fTractionLossMult ceiling at full RPM (higher = spins together harder)
        SpinLossMult   = 2.5,
        -- Suppress diff above this gear (0 = always active)
        GearSpinCutoff = 4,
    },

    lsd_diff = {
        item           = 'lsd_diff',
        label          = 'Limited Slip Differential',
        type           = 'lsd',
        installTime    = 6000,

        -- LSD only engages above this RPM
        LsdLockRpm     = 1.95,
        -- LSD releases below this RPM (gap prevents flickering)
        LsdUnlockRpm   = 1.85,
        -- Within the locked band, traction starts scaling from this RPM
        SpinRpm        = 1.95,
        -- fTractionCurveMin floor when fully locked
        TractionMin    = 0.20,
        -- fTractionLossMult ceiling when fully locked (gentler than welded)
        SpinLossMult   = 4.0,
        -- Suppress diff above this gear (0 = always active)
        GearSpinCutoff = 3,
    },
}

-- ============================================================================================================
--                                         Item Duration
-- Each diff has 3 hours of in-vehicle playtime before wearing out.
-- ============================================================================================================
Config.DiffDurationMs = 3 * 60 * 60 * 1000   -- 3 hours in milliseconds

Config.ApplyDistance  = 2.5     -- metres — proximity needed to install

-- Tier system — higher tier overwrites lower tier
Config.DiffTier = {
    welded_diff = 1,
    lsd_diff    = 2,
}