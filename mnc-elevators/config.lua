Config = {}

-- Debug Mode
Config.DebugMode = false -- true = show debug prints and zone visuals, false = hide them

-- UI System
Config.MenuType = "qb" -- "ox" or "qb"
Config.NotifyType = "ox" -- "ox" or "qb"

-- Interaction system
Config.UseQbTarget = true -- true = use qb-target | false = press [E]

-- Sounds / Animation / Progress
Config.PlayDingSound = true
Config.DingSound = "ATM_WINDOW"
Config.DingVolume = 0.5
Config.PlayAnim = true
Config.AnimDict = "anim@mp_player_intmenu@key_fob@"
Config.AnimName = "fob_click"
Config.UseProgress = false
Config.ProgressType = "bar" -- "bar", "circle", or "QB" for qb-progressbar
Config.ProgressTime = 2500
Config.ProgressLabel = "Waiting for elevator..."

-- Elevator data
Config.Elevators = {  
    ["PillboxHospital"] = {
        [0] = {
            label = "Helipad",
            coords = vector4(338.85, -583.94, 74.17, 70.0),
            jobs = {"ambulance"},
            items = {"ems_keycard_heli"},
        },
        [1] = {
            label = "Main Floor",
            coords = vector4(311.19, -599.34, 43.29, 243.07),
            jobs = {},
            items = {},
        },
        [2] = {
            label = "Lower Garage",
            coords = vector4(319.87, -559.98, 28.74, 208.19),
            jobs = {"ambulance"},
            items = {"phone"},
        },
    },
	["VinewoodRecords"] = {
        [0] = {
            label = "Garage",
            coords = vector4(-492.74, 36.45, 56.5, 268.12),
            jobs = {"vinewoodrecords"},
        },
        [1] = {
            label = "Main Recording Floor",
            coords = vector4(-478.3, 58.78, 46.7, 81.17),
            jobs = {"vinewoodrecords"},
        }
    },
    ["MazeBank"] = {
        [0] = {
            label = "Office",
            coords = vector4(-75.5, -827.31, 243.39, 237.01),
            jobs = {},
            items = {},
        },
        [1] = {
            label = "Lobby",
            coords = vector4(-1370.44, -502.97, 33.16, 292.04),
            jobs = {},
            items = {},
        },
    },
    ["LafestaMurder"] = {
        [1] = {
            label = "Murder Room Door",
            coords = vector4(1441.01, 1137.91, 114.33, 271.89),
            jobs = {"lafesta"},
            items = {"lafesta_murder_key"},
        },
        [0] = {
            label = "Murder Room",
            coords = vector4(1400.39, 1136.67, 109.75, 282.19),
            jobs = {"lafesta"},
            items = {"lafesta_murder_key"},
        },
    },
    ["WiwangCityHall"] = {
        [0] = {
            label = "Floor 20 - Admin",
            coords = vector4(-824.13, -718.83, 113.77, 204.61),
            arrivalCoords = vector4(-823.81, -717.77, 113.77, 218.5),
            jobs = {"admin"},
            items = {},
        },
        [1] = {
            label = "Floor 19 - DOJ",
            coords = vector4(-824.16, -718.72, 113.77, 215.43),
            arrivalCoords = vector4(-823.88, -717.69, 109.97, 219.83),
            jobs = {"doj"},
            items = {},
        },
        [2] = {
            label = "Floor 18 - PD",
            coords = vector4(-824.15, -718.72, 106.17, 209.82),
            arrivalCoords = vector4(-823.95, -717.62, 106.16, 220.07),
            jobs = {"police"},
            items = {},
        },
        [3] = {
            label = "Floor 17 - EMS",
            coords = vector4(-824.15, -718.72, 102.37, 203.59),
            arrivalCoords = vector4(-823.96, -717.62, 102.36, 219.9),
            jobs = {"ambulance"},
            items = {},
        },
        [4] = {
            label = "Floor 16 - La Festa",
            coords = vector4(-824.15, -718.72, 98.57, 199.42),
            arrivalCoords = vector4(-823.97, -717.61, 98.57, 219.73),
            jobs = {"lafesta"},
            items = {},
        },
        [5] = {
            label = "Floor 15",
            coords = vector4(-824.15, -718.72, 94.77, 192.54),
            arrivalCoords = vector4(-824.04, -717.54, 94.76, 220.04),
            jobs = {},
            items = {},
        },
        [6] = {
            label = "Floor 14",
            coords = vector4(-824.15, -718.72, 90.97, 208.73),
            arrivalCoords = vector4(-824.05, -717.54, 90.96, 219.93),
            jobs = {},
            items = {},
        },
        [7] = {
            label = "Floor 13",
            coords = vector4(-824.15, -718.72, 87.17, 208.31),
            arrivalCoords = vector4(-824.05, -717.53, 87.17, 219.96),
            jobs = {},
            items = {},
        },
        [8] = {
            label = "Floor 12",
            coords = vector4(-824.15, -718.72, 83.37, 207.97),
            arrivalCoords = vector4(-824.12, -717.46, 83.37, 223.31),
            jobs = {},
            items = {},
        },
        [9] = {
            label = "Floor 11",
            coords = vector4(-824.15, -718.72, 79.57, 208.85),
            arrivalCoords = vector4(-824.2, -717.39, 79.57, 220.42),
            jobs = {},
            items = {},
        },
        [10] = {
            label = "Floor 10",
            coords = vector4(-824.15, -718.77, 75.77, 204.55),
            arrivalCoords = vector4(-824.27, -717.32, 75.77, 221.08),
            jobs = {},
            items = {},
        },
        [11] = {
            label = "Floor 9",
            coords = vector4(-824.15, -718.72, 71.97, 209.02),
            arrivalCoords = vector4(-824.32, -717.23, 71.97, 223.36),
            jobs = {},
            items = {},
        },
        [12] = {
            label = "Floor 8",
            coords = vector4(-824.15, -718.72, 68.17, 206.28),
            arrivalCoords = vector4(-824.06, -717.48, 68.16, 221.38),
            jobs = {},
            items = {},
        },
        [13] = {
            label = "Floor 7",
            coords = vector4(-824.15, -718.72, 64.37, 198.61),
            arrivalCoords = vector4(-824.06, -717.48, 64.36, 221.71),
            jobs = {},
            items = {},
        },
        [14] = {
            label = "Floor 6",
            coords = vector4(-824.15, -718.72, 60.57, 202.19),
            arrivalCoords = vector4(-824.07, -717.48, 60.56, 220.95),
            jobs = {},
            items = {},
        },
        [15] = {
            label = "Floor 5",
            coords = vector4(-824.13, -718.8, 56.77, 200.42),
            arrivalCoords = vector4(-824.08, -717.47, 56.76, 221.75),
            jobs = {},
            items = {},
        },
        [16] = {
            label = "Floor 4",
            coords = vector4(-824.15, -718.71, 52.97, 199.92),
            arrivalCoords = vector4(-824.09, -717.47, 52.96, 221.34),
            jobs = {},
            items = {},
        },
        [17] = {
            label = "Floor 3",
            coords = vector4(-824.13, -718.83, 49.17, 200.52),
            arrivalCoords = vector4(-824.1, -717.47, 49.16, 221.29),
            jobs = {},
            items = {},
        },
        [18] = {
            label = "Floor 2",
            coords = vector4(-824.15, -718.72, 45.37, 184.43),
            arrivalCoords = vector4(-824.11, -717.47, 45.36, 221.24),
            jobs = {},
            items = {},
        },
        [19] = {
            label = "Floor 1",
            coords = vector4(-824.15, -718.73, 41.57, 207.04),
            arrivalCoords = vector4(-824.11, -717.47, 41.57, 223.66),
            jobs = {},
            items = {},
        },
        [20] = {
            label = "Lobby",
            coords = vector4(-820.88, -698.91, 28.07, 65.36),
            arrivalCoords = vector4(-819.82, -699.8, 28.07, 90.216),
            jobs = {},
            items = {},
        },
    }
}