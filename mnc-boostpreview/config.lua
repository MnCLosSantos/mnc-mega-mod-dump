Config = Config or {}

-- =============================================================================================================================================
-- DEBUG
-- =============================================================================================================================================
Config.Debug = false

-- =============================================================================================================================================
-- SOURCE RESOURCE
-- =============================================================================================================================================
-- Folder name of your mnc-boostgauge install. The preview NUI loads that resource's
-- html/style.css at runtime (via the nui:// scheme) so every style/bezel looks identical
-- to the real gauge. Only change this if you renamed the mnc-boostgauge resource folder.
Config.SourceResource = 'mnc-boostgauge'

-- =============================================================================================================================================
-- COMMAND
-- =============================================================================================================================================
Config.OpenCommand = 'boostpreview'      -- usage: /boostpreview
Config.RegisterKeybind = true            -- lets players bind a key to it in FiveM keybind settings (Config.OpenCommand still works too)
Config.DefaultKeybind = 'F6'

-- Optional job lock (off by default - this is a view-only gallery, no items/vehicles are touched)
Config.RestrictCommandToJobs = false
Config.AllowedJobs = {
    ['mechanic'] = true,
    ['mechanic2'] = true,
    ['autoexotics'] = true,
    ['mncracing'] = true,
    ['yachtclub'] = true,
    ['admin'] = true,
}

-- =============================================================================================================================================
-- PRESS [E] DISPLAY POINTS
-- =============================================================================================================================================
-- Any of these locations will show a floating "[E] View Boost Gauges" prompt when the
-- player walks close enough, and pressing E opens the same preview as /boostpreview.
Config.PromptDistance = 5.5     -- distance (units) at which the prompt appears / E can be pressed
Config.DrawDistance = 8.0       -- distance at which the script starts running the tighter 0ms loop
Config.KeyPrompt = 38           -- 38 = E (FiveM control hash for INPUT_PICKUP, commonly used as "E")

Config.UseMarker = true
Config.MarkerColor = { r = 0, g = 200, b = 255, a = 120 }

-- Set to true if you run ox_target - adds a proper target option at each location
-- in addition to the press-E prompt (both can be used together).
Config.UseOxTarget = false

Config.Locations = {
    -- EDIT ME: replace with your own display coordinates (shop counters, gauge racks, etc.)
    { coords = vector3(103.87, 6622.33, 31.2), label = 'View Boost Gauges' },  -- beekers
    { coords = vector3(-325.19, -139.28, 38.39), label = 'View Boost Gauges' },  -- LS Customs (Burton)
    { coords = vector3(-222.57, -1329.7, 30.27), label = 'View Boost Gauges' }, -- Benny's Original Motor Works
}

-- =============================================================================================================================================
-- PREVIEW DEFAULTS
-- =============================================================================================================================================
Config.DefaultPreviewStyle = 1
Config.DefaultPreviewBezel = 1
Config.BezelThickness = 9   -- purely cosmetic for the preview cards, matches mnc-boostgauge's default

-- =============================================================================================================================================
-- =============================================================================================================================================
-- INTERNAL DATA (KEEP IN SYNC WITH mnc-boostgauge/config.lua)
-- If you add new styles/bezels/presets to mnc-boostgauge, mirror the additions here so
-- they show up in the preview gallery too.
-- =============================================================================================================================================
Config.StylesCount = 40
Config.BezelsCount = 20

Config.StyleItems = {
    ['boostgauge_classic'] = 1,
    ['boostgauge_digital'] = 2,
    ['boostgauge_retro'] = 3,
    ['boostgauge_frost'] = 4,
    ['boostgauge_matrix'] = 5,
    ['boostgauge_carbon'] = 6,
    ['boostgauge_racing'] = 7,
    ['boostgauge_glass'] = 8,
    ['boostgauge_phantom'] = 9,
    ['boostgauge_emerald'] = 10,
    ['boostgauge_sunset'] = 11,
    ['boostgauge_track'] = 12,
    ['boostgauge_drift'] = 13,
    ['boostgauge_electric'] = 14,
    ['boostgauge_luxury'] = 15,
    ['boostgauge_wave'] = 16,
    ['boostgauge_storm'] = 17,
    ['boostgauge_fresh'] = 18,
    ['boostgauge_muscle'] = 19,
    ['boostgauge_pro'] = 20,
    ['boostgauge_fury'] = 21,
    ['boostgauge_turbo'] = 22,
    ['boostgauge_night'] = 23,
    ['boostgauge_flash'] = 24,
    ['boostgauge_arctic'] = 25,
    ['boostgauge_holo'] = 26,
    ['boostgauge_synthwave'] = 27,
    ['boostgauge_modern'] = 28,
    ['boostgauge_stealth'] = 29,
    ['boostgauge_cosmic'] = 30,
    ['boostgauge_inferno'] = 31,
    ['boostgauge_aurora'] = 32,
    ['boostgauge_vapor'] = 33,
    ['boostgauge_cyberpunk'] = 34,
    ['boostgauge_crystal'] = 35,
    ['boostgauge_magma'] = 36,
    ['boostgauge_eclipse'] = 37,
    ['boostgauge_zenith'] = 38,
    ['boostgauge_nova'] = 39,
    ['boostgauge_quantum'] = 40,
}

Config.BezelItems = {
    ['bezel_chrome'] = 1,
    ['bezel_satinblack'] = 2,
    ['bezel_carbonfiber'] = 3,
    ['bezel_neonamber'] = 4,
    ['bezel_neongreen'] = 5,
    ['bezel_neonblue'] = 6,
    ['bezel_neonmagenta'] = 7,
    ['bezel_neonred'] = 8,
    ['bezel_retrosynth'] = 9,
    ['bezel_rainbow'] = 10,
    ['bezel_holographic'] = 11,
    ['bezel_mattegold'] = 12,
    ['bezel_neoncyan'] = 13,
    ['bezel_frostedglass'] = 14,
    ['bezel_lava'] = 15,
    ['bezel_pulsar'] = 16,
    ['bezel_chameleon'] = 17,
    ['bezel_mirror'] = 18,
    ['bezel_galactic'] = 19,
    ['bezel_plasma'] = 20,
}

Config.Presets = {
    preset1 = { style = 1, bezel = 1, label = 'Classic Chrome' },
    preset2 = { style = 2, bezel = 2, label = 'Digital Black' },
    preset3 = { style = 3, bezel = 3, label = 'Retro Carbon' },
    preset4 = { style = 5, bezel = 5, label = 'Matrix Green' },
    preset5 = { style = 9, bezel = 7, label = 'Phantom Magenta' },
    preset6 = { style = 10, bezel = 2, label = 'Emerald Amber' },
    preset7 = { style = 11, bezel = 2, label = 'Sunset Blue' },
    preset8 = { style = 13, bezel = 2, label = 'Drift Red' },
    preset9 = { style = 15, bezel = 12, label = 'Luxury Gold' },
    preset10 = { style = 17, bezel = 9, label = 'Storm Synth' },
    preset11 = { style = 20, bezel = 13, label = 'Azure Cyan' },
    preset12 = { style = 22, bezel = 2, label = 'Aqua Glass' },
    preset13 = { style = 25, bezel = 15, label = 'Arctic Lava' },
    preset14 = { style = 27, bezel = 10, label = 'Synthwave Rainbow' },
    preset15 = { style = 2, bezel = 9, label = 'Cosmic Holo' },
    preset16 = { style = 12, bezel = 16, label = 'Aurora Pulsar' },
    preset17 = { style = 34, bezel = 17, label = 'Cyberpunk Chameleon' },
    preset18 = { style = 36, bezel = 2, label = 'Magma Mirror' },
    preset19 = { style = 38, bezel = 19, label = 'Zenith Galactic' },
    preset20 = { style = 40, bezel = 20, label = 'Quantum Plasma' },
}