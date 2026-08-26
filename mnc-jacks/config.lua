Config = {}

Config.Debug = false

-- Items
Config.CarJackItem   = 'car_jack'
Config.AxleStandItem = 'axle_stand'

-- How often client syncs (not used in session-only but kept)
Config.SaveInterval = 30000

-- Interaction distance
Config.InteractDistance = 2.5

-- Jack & Stand settings
Config.Lift = {
    -- Items fallback names same as above
    CarJackItem   = 'car_jack',
    AxleStandItem = 'axle_stand',

    -- Stand counts
    StandsPerSide = 2,

    -- Prop models
    JackPropModel     = 'prop_carjack',           -- floor jack
    StandPropModel    = 'xs_prop_x18_axel_stand_01a',

    -- Jack prop rotation per side
    JackRotation = {
        left  = -270.0,   -- Change these if the jack faces wrong direction
        right =  270.0,
    },

    -- Timings
    JackDuration  = 5000,
    StandDuration = 3000,

    -- Raise height
    RaiseHeight = 0.17,

    -- Interaction distance
    InteractDistance = 2.5,

    -- Stand offsets
    StandOffsets = {
        left = {
            [1] = { x = -0.65, y =  1.10, z = -0.30, heading = 0.0 }, -- front-left
            [2] = { x = -0.65, y = -1.10, z = -0.30, heading = 0.0 }, -- rear-left
        },
        right = {
            [1] = { x =  0.65, y =  1.10, z = -0.30, heading = 0.0 }, -- front-right
            [2] = { x =  0.65, y = -1.10, z = -0.30, heading = 0.0 }, -- rear-right
        },
    },
}