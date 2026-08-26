Config = {}

-- Framework systems
Config.MenuSystem = "qb-menu"        -- "ox_lib" or "qb-menu"
Config.NotifySystem = "ox_lib"      -- "ox_lib" or "qb-notify"
Config.ProgressType = "bar"      -- "bar", "circle", or "QB"

-- Default durations (minutes)
Config.DefaultDuration = {
    Crutch = 15,
    Cane = 10
}

-- Movement realism
Config.RestrictMovement = true      -- Disable sprint/jump while using an aid

-- EMS visibility
Config.EMSCanSeeRemaining = true    -- Show remaining time on target if true

-- Job allowed to apply/remove
Config.EMSJob = "ambulance"

-- Aid props and animations
Config.Aids = {
    ['crutch'] = {
        label = "Crutch",
        prop = "v_med_crutch01",
        animDict = "move_m@injured",
        bone = 57005, -- Right Hand
        offset = {x = 1.02, y = 0.03, z = -0.03}, -- Adjusted for natural grip
        rotation = {x = 180.0, y = 90.0, z = 210.0}, -- Adjusted for realistic angle
        defaultTime = 15, -- minutes
        progressLabel = "Applying Crutch..."
    },
    ['cane'] = {
        label = "Cane",
        prop = "prop_cs_walking_stick",
        animDict = "move_m@injured",
        bone = 57005, -- Right Hand
        offset = {x = 0.12, y = 0.03, z = -0.03}, -- Adjusted for natural grip
        rotation = {x = 180.0, y = 90.0, z = 15.0}, -- Adjusted for realistic angle
        defaultTime = 10, -- minutes
        progressLabel = "Applying Cane..."
    }
}

-- Progress durations (seconds)
Config.ProgressDurations = {
    apply = 15,
    remove = 10
}