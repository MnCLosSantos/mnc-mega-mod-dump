-- config.lua  (mnc-drivetype)
Config = {}

Config.Debug = false

Config.RequireJob = true
Config.AllowedJobs = {
    ['mechanic'] = 0,
    ['bennys']   = 0,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Drive Types
-- ─────────────────────────────────────────────────────────────────────────────
Config.DriveTypes = {

    -- ── Front Wheel Drive ────────────────────────────────────────────────────
    ['fwd'] = {
        label       = 'Front Wheel Drive',
        item        = 'drivetype_fwd',
        installTime = 6000,
        description = 'All torque sent to the front wheels. Understeer tendency.',

        -- Handling
        driveBias     = 1.0,   -- 100% front
        tractionFront = 0.52,
        tractionRear  = 0.48,

        -- Wheels
        poweredWheels = { [0]=true,  [1]=true,  [2]=false, [3]=false },
        wheelSet = {
            { bone = 'wheel_lf', label = 'Front Left Wheel'  },
            { bone = 'wheel_rf', label = 'Front Right Wheel' },
        },
    },

    -- ── Rear Wheel Drive ─────────────────────────────────────────────────────
    ['rwd'] = {
        label       = 'Rear Wheel Drive',
        item        = 'drivetype_rwd',
        installTime = 6000,
        description = 'All torque sent to the rear wheels. Oversteer tendency, burnouts.',

        -- Handling
        driveBias     = 0.0,   -- 100% rear
        tractionFront = 0.48,
        tractionRear  = 0.52,

        -- Wheels
        poweredWheels = { [0]=false, [1]=false, [2]=true,  [3]=true },
        wheelSet = {
            { bone = 'wheel_lr', label = 'Rear Left Wheel'  },
            { bone = 'wheel_rr', label = 'Rear Right Wheel' },
        },
    },

    -- ── AWD 50 / 50 ──────────────────────────────────────────────────────────
    ['awd_5050'] = {
        label       = 'AWD 50/50 Split',
        item        = 'drivetype_awd5050',
        installTime = 12000,
        description = 'Equal torque split front and rear. Maximum traction.',

        -- Handling
        driveBias     = 0.5,
        tractionFront = 0.50,
        tractionRear  = 0.50,

        -- Wheels
        poweredWheels = { [0]=true, [1]=true, [2]=true, [3]=true },
        wheelSet = {
            { bone = 'wheel_lf', label = 'Front Left Wheel'  },
            { bone = 'wheel_rf', label = 'Front Right Wheel' },
            { bone = 'wheel_lr', label = 'Rear Left Wheel'   },
            { bone = 'wheel_rr', label = 'Rear Right Wheel'  },
        },
    },

    -- ── Haldex 65 / 35 (rear-biased AWD) ────────────────────────────────────
    ['haldex_6535'] = {
        label       = 'Haldex 65/35 Split',
        item        = 'drivetype_haldex',
        installTime = 12000,
        description = 'Rear-biased Haldex-style AWD. 65% rear / 35% front torque.',

        -- Handling
        driveBias     = 0.35,  -- 35% front / 65% rear
        tractionFront = 0.48,
        tractionRear  = 0.52,

        -- Wheels
        poweredWheels = { [0]=true, [1]=true, [2]=true, [3]=true },
        wheelSet = {
            { bone = 'wheel_lf', label = 'Front Left Wheel'  },
            { bone = 'wheel_rf', label = 'Front Right Wheel' },
            { bone = 'wheel_lr', label = 'Rear Left Wheel'   },
            { bone = 'wheel_rr', label = 'Rear Right Wheel'  },
        },
    },

    -- ── Viscous 35 / 65 (front-biased AWD) ──────────────────────────────────
    ['viscous_3565'] = {
        label       = 'Viscous 35/65 Split',
        item        = 'drivetype_viscous',
        installTime = 12000,
        description = 'Front-biased viscous coupling AWD. 65% front / 35% rear torque.',

        -- Handling
        driveBias     = 0.65,  -- 65% front / 35% rear
        tractionFront = 0.52,
        tractionRear  = 0.48,

        -- Wheels
        poweredWheels = { [0]=true, [1]=true, [2]=true, [3]=true },
        wheelSet = {
            { bone = 'wheel_lf', label = 'Front Left Wheel'  },
            { bone = 'wheel_rf', label = 'Front Right Wheel' },
            { bone = 'wheel_lr', label = 'Rear Left Wheel'   },
            { bone = 'wheel_rr', label = 'Rear Right Wheel'  },
        },
    },
}

-- Maximum distance from the vehicle for item use (metres)
Config.ApplyDistance = 2.5

-- Toolbox item name
Config.ToolboxItem = 'driveline_toolbox'