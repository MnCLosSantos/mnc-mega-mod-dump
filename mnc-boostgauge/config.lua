Config = {}

-- =============================================================================================================================================
-- DEBUG SETTINGS
-- =============================================================================================================================================
Config.Debug = false

-- =============================================================================================================================================
-- COMMAND LOCK SETTINGS
-- =============================================================================================================================================
Config.LockCommandToJobs = true  -- Set to true to lock the /bgauge command to specific jobs only
Config.AllowedJobs = {            -- List of allowed jobs. Players with these jobs can use /bgauge if LockCommandToJobs = true
    ['mechanic'] = true,
	['mechanic2'] = true,
    ['autoexotics'] = true,
    ['mncracing'] = true,
	['yachtclub'] = true,
	['admin'] = true,
    -- Add more jobs as needed, e.g., ['admin'] = true,
}

-- =============================================================================================================================================
-- INSTALLATION SETTINGS
-- =============================================================================================================================================
Config.Installation = {
    -- Require minigame when installing gauge/bezel
    requireMinigame = true,        -- Set to false to use standard progress bar
    
    -- Minigame difficulty (1-3, 1=easiest, 3=hardest)
    minigameDifficulty = 3,
    
    -- Progress bar settings (used when requireMinigame = false)
    progressDuration = 5000,       -- Duration in milliseconds
    progressType = 'bar',          -- Options: 'bar', 'circle'
    
    -- Animation settings
    useAnimation = true,
    animDict = 'mini@repair',
    animClip = 'fixing_a_ped',
}

-- =============================================================================================================================================
-- UI SETTINGS
-- =============================================================================================================================================
Config.UI = {
    -- Position settings
    x = 0.289,              -- Horizontal position (0 = left, 1 = right)
    y = 0.75,               -- Vertical position (0 = top, 1 = bottom)
    
    -- Scale multiplier
    scale = 0.30,           -- Size multiplier (0.5 = half size, 2.0 = double size)
    
    -- Style selection
    defaultStyle = 6,       -- Default gauge style on startup
    
    -- Bezel settings
    defaultBezel = 2,       -- Default bezel style (1=Chrome, 2=Satin Black, 3=Carbon Fiber)
    bezelThickness = 9,     -- Bezel thickness in pixels (default: 9px)
}

-- =============================================================================================================================================
-- PSI / BOOST SETTINGS GTAV
-- =============================================================================================================================================
-- Standard turbo (GTA mod 18) baseline PSI used when vehicle has turbo mod but no remap installed
Config.Mod18StandardPSI = 6.0

-- =============================================================================================================================================
-- PSI / BOOST SETTINGS MNC-PERFORMANCEPARTS
-- =============================================================================================================================================
Config.TurboPSI = {
    turbo_rx280 = 12.0,   -- For Stage 1
    turbo_rx560 = 16.0,   -- For Stage 2
    turbo_rx660 = 20.0,   -- For Stage 3
    turbo_rx890 = 26.0,   -- For Stage 4
}

Config.RemapPSI = {
    stage0 = 6.0,         -- Stock turbo GTAV
    stage1 = 16.0,        -- Stage 1 tune
    stage1plus = 12.0,    -- Stage 1+ tune
    stage2 = 20.0,        -- Stage 2 tune 
    stage2plus = 17.0,    -- Stage 2+ tune
    stage3 = 24.0,        -- Stage 3 tune 
    stage3plus = 23.0,    -- Stage 3+ tune
    stage4 = 30.0,        -- Stage 4 tune
    stage4plus = 30.0,    -- Stage 4+ tune
}

-- =============================================================================================================================================
-- NEEDLE & ANIMATION SETTINGS
-- =============================================================================================================================================
Config.Needle = {
    -- Needle angle
    minAngle = -100,       -- Top position (no boost)
    maxAngle = 270,        -- Full circle for max boost
    
    -- Smoothing factor 
    smoothing = 6.0,       -- Range: 1.0 (very smooth) to 15.0 (instant)
    
    -- Idle response 
    idleResponse = 0.3,    -- Range: 0.0 (no movement) to 1.0 (full movement)
    
    -- Engine load
    useEngineLoad = true,  -- When true, considers vehicle speed vs RPM for more realistic boost
}

-- =============================================================================================================================================
-- PRESET CONFIGURATIONS
-- =============================================================================================================================================
Config.Presets = {
    preset1 = { style = 1, bezel = 1, label = 'Classic Chrome' },        -- Classic Analog Chrome + Chrome Bezel
    preset2 = { style = 2, bezel = 2, label = 'Digital Black' },         -- Digital HUD (Cyan) + Satin Black Bezel
    preset3 = { style = 3, bezel = 3, label = 'Retro Carbon' },          -- Retro Orange JDM + Carbon Fiber Bezel
    preset4 = { style = 5, bezel = 5, label = 'Matrix Green' },          -- Neon Green Matrix + Neon Green Bezel
    preset5 = { style = 9, bezel = 7, label = 'Phantom Magenta' },       -- Purple Phantom + Neon Magenta Bezel
    preset6 = { style = 10, bezel = 2, label = 'Emerald Amber' },        -- Emerald Glow + Neon Amber Bezel
    preset7 = { style = 11, bezel = 2, label = 'Sunset Blue' },          -- Amber Sunset + Neon Blue Bezel
    preset8 = { style = 13, bezel = 2, label = 'Drift Red' },            -- Pink Drift + Neon Red Bezel
    preset9 = { style = 15, bezel = 12, label = 'Luxury Gold' },         -- Gold Luxury + Matte Gold Bezel
    preset10 = { style = 17, bezel = 9, label = 'Storm Synth' },         -- Violet Storm + Retro Synthwave Bezel
    preset11 = { style = 20, bezel = 13, label = 'Azure Cyan' },         -- Azure Pro + Neon Cyan Bezel
    preset12 = { style = 22, bezel = 2, label = 'Aqua Glass' },         -- Aqua Turbo + Frosted Glass Bezel
    preset13 = { style = 25, bezel = 15, label = 'Arctic Lava' },        -- Ice Blue Arctic + Lava Glow Bezel
    preset14 = { style = 27, bezel = 10, label = 'Synthwave Rainbow' },  -- 80s Retro Synthwave + Rainbow Bezel
    preset15 = { style = 2, bezel = 9, label = 'Cosmic Holo' },        -- Cosmic Nebula + Holographic Bezel
    preset16 = { style = 12, bezel = 16, label = 'Aurora Pulsar' },      -- Aurora Borealis + Pulsar Effect Bezel
    preset17 = { style = 34, bezel = 17, label = 'Cyberpunk Chameleon' },-- Cyberpunk Neon + Chameleon Bezel
    preset18 = { style = 36, bezel = 2, label = 'Magma Mirror' },       -- Magma Flow + Mirror Finish Bezel
    preset19 = { style = 38, bezel = 19, label = 'Zenith Galactic' },    -- Zenith Horizon + Galactic Sparkle Bezel
    preset20 = { style = 40, bezel = 20, label = 'Quantum Plasma' },     -- Quantum Flux + Plasma Energy Bezel
}






















































-- =============================================================================================================================================
-- =============================================================================================================================================
-- =============================================================================================================================================
-- =============================================================================================================================================
-- INTERNAL SETTINGS (DO NOT MODIFY)
-- =============================================================================================================================================
Config.StylesCount = 40
Config.BezelsCount = 20
-- =============================================================================================================================================
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
-- =============================================================================================================================================
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
-- =============================================================================================================================================
Config.PresetItems = {
    ['boostgauge_preset1'] = 'preset1',
    ['boostgauge_preset2'] = 'preset2',
    ['boostgauge_preset3'] = 'preset3',
    ['boostgauge_preset4'] = 'preset4',
    ['boostgauge_preset5'] = 'preset5',
    ['boostgauge_preset6'] = 'preset6',
    ['boostgauge_preset7'] = 'preset7',
    ['boostgauge_preset8'] = 'preset8',
    ['boostgauge_preset9'] = 'preset9',
    ['boostgauge_preset10'] = 'preset10',
    ['boostgauge_preset11'] = 'preset11',
    ['boostgauge_preset12'] = 'preset12',
    ['boostgauge_preset13'] = 'preset13',
    ['boostgauge_preset14'] = 'preset14',
    ['boostgauge_preset15'] = 'preset15',
    ['boostgauge_preset16'] = 'preset16',
    ['boostgauge_preset17'] = 'preset17',
    ['boostgauge_preset18'] = 'preset18',
    ['boostgauge_preset19'] = 'preset19',
    ['boostgauge_preset20'] = 'preset20',
}
-- =============================================================================================================================================
