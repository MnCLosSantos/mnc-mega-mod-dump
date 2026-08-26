-- config.lua
Config = {}

-- Debug Mode
Config.DebugMode = false

-- UI System
Config.MenuType = "qb" -- "ox" or "qb"
Config.NotifyType = "ox" -- "ox" or "qb"

-- Interaction system
Config.UseQbTarget = false -- true = use qb-target | false = press [E]

-- Sounds / Animation / Progress
Config.PlayTravelSound = true
Config.TravelSound = "ATM_WINDOW"
Config.PlayAnim = true
Config.AnimDict = "anim@mp_player_intmenu@key_fob@"
Config.AnimName = "fob_click"
Config.UseProgress = true
Config.ProgressType = "bar" -- "bar", "circle", or "QB"
Config.ProgressTime = 5500
Config.ProgressLabel = "Preparing for your trip..."

-- Location data
Config.Locations = {  
    ["LSIA"] = {
        [0] = {
            label = "Airport",
            coords = vector4(-551.88, 6514.87, 5.93, 303.78),
            arrivalCoords = vector4(-551.88, 6514.87, 5.93, 303.78),
            allowVehicle = true,
			cost = 500, -- $500 to travel to Paleto
            blip = {
                sprite = 251,      -- Plane icon
                color = 3,         -- Light blue
                scale = 0.8,
                name = "Paleto International Airtravel"
            }
        },
        [1] = {
            label = "Tokyo",
            coords = vector4(-6570.06, 2022.34, 10.62, 25.3),
            arrivalCoords = vector4(-6570.06, 2022.34, 10.62, 25.3),
            allowVehicle = true,
			cost = 1000, -- $1000 to travel to Tokyo
        },
    },
}