Config = {}

-- Debug (SET TO TRUE TO SEE ZONES AND LOGS)
Config.Debug = false

-- Integrations
Config.Notify = "ox"          -- "qb" or "ox"
Config.Menu = "ox"            -- "qb" or "ox"
Config.Target = "qb"          -- "qb-target"
Config.Progress = "bar"       -- "bar", "circle" and "qb"

-- Job identity
Config.JobName = "gruppe6"

-- Job required
Config.JobRequired = true       -- true = must have job 'gruppe6' | false = anyone can use the job (public)

-- Duty required 
Config.RequireOnDuty = true

-- Uniform enforcement (players must change at schedule pickup)
Config.RequireUniformBeforeWork = true

-- Clothing resource to call QB only for now
Config.ClothingExport = "qb-clothing" 

-- Markers at active locations  
Config.ShowMarkers = true   -- true = show marker at the active stop, false = no markers

-- Depot / schedule coords
Config.Depot = vector3(11.99, -666.1, 33.9)
Config.SchedulePickup = {
    coords = vector3(11.99, -666.1, 33.9),
    heading = 89.0
}

-- Cooldowns in seconds
Config.Cooldowns = {
    Schedule = 1800,     -- 30 minutes before taking another schedule
    FullJob = 3600       -- 60 minutes after completing whole job
}

-- Route settings
Config.LoanRouteCount = 5     -- number of loan agreement stops max 15
Config.CashRouteCount = 10    -- number of cash pickup stops max 20

-- Minigame settings
Config.Minigame = {
    Enabled = true,           -- Set to false to skip minigame
    MinLength = 3,
    MaxLength = 6,
    Difficulty = "easy",      -- Options: "easy", "medium", "hard"
}

-- Location pools
Config.Pool = {
    -- bank-type locations (used for the loan/cash phase)
    banks = {
        { coords = vector3(145.74, -1044.01, 29.38),  name = "Leigon Square" },
        { coords = vector3(-1213.06, -336.02, 37.79), name = "South Boulevard Del Perro" },
        { coords = vector3(-355.07, -53.25, 49.05),   name = "Hawick Avenue" },
        { coords = vector3(-2958.19, 480.02, 15.71),  name = "Great Ocean Highway" },
        { coords = vector3(310.07, -282.39, 54.17),   name = "Hawick Avenue / Meteor Street" },
        { coords = vector3(1177.78, 2711.31, 38.1),   name = "Route 68" },
        { coords = vector3(242.34, 224.96, 106.29),   name = "Vinewood Boulevard Teller 1" },
		{ coords = vector3(247.42, 223.23, 106.29),   name = "Vinewood Boulevard Teller 2" },
		{ coords = vector3(252.76, 221.37, 106.29),   name = "Vinewood Boulevard Teller 3" },
		{ coords = vector3(254.16, 207.49, 106.29),   name = "Vinewood Boulevard Banker 1" },
		{ coords = vector3(248.21, 209.69, 106.29),   name = "Vinewood Boulevard Banker 2" },
		{ coords = vector3(242.11, 211.5, 110.28),    name = "Vinewood Boulevard Banker 3" },
		{ coords = vector3(247.7, 209.23, 110.28),    name = "Vinewood Boulevard banker 4" },
		{ coords = vector3(249.11, 207.86, 110.28),   name = "Vinewood Boulevard banker 5" },
        { coords = vector3(-113.07, 6470.16, 31.63),  name = "Paleto Teller 1" },
		{ coords = vector3(-110.95, 6467.99, 31.63),  name = "Paleto Teller 2" },
		{ coords = vector3(-105.6, 6470.63, 31.63),  name = "Paleto Banker 1" },
		{ coords = vector3(-103.65, 6467.82, 31.63),  name = "Paleto Banker 2" },
    },

    -- CASH-only pool (ATMs) used exclusively for the cash phase
    cash = {
        { coords = vector3( -821.2, -1081.6, 11.13 ), name = "ATM - Mirror Park" },
        { coords = vector3( -386.2, 6045.4, 31.5 ), name = "ATM - Paleto Bay" },
        { coords = vector3( 25.7, -945.3, 29.36 ), name = "ATM - Legion Square" },
        { coords = vector3( 1174.5, 2706.6, 38.09 ), name = "ATM - Paleto Main" },
        { coords = vector3( -56.9, -1752.3, 29.43 ), name = "ATM - Hawick" },
        { coords = vector3( -203.6, -861.0, 30.26 ), name = "ATM - Vespucci" },
        { coords = vector3( 1692.3, 3758.5, 34.7 ), name = "ATM - Sandy Shores" },
        { coords = vector3( -1211.4, -330.8, 37.78 ), name = "ATM - Depot St." },
        { coords = vector3( 117.2, -883.0, 31.19 ), name = "ATM - Pillbox" },
        { coords = vector3( 256.3, 220.0, 106.29 ), name = "ATM - Mission Row" },
        { coords = vector3( -1305.0, -706.4, 25.32 ), name = "ATM - East Los Santos" },
        { coords = vector3( -821.4, -1233.5, 7.34 ), name = "ATM - Del Perro" },
        { coords = vector3( -3038.9, 585.9, 7.91 ), name = "ATM - Great Ocean" },
        { coords = vector3( 174.1, 6638.1, 30.69 ), name = "ATM - Grapeseed" },
        { coords = vector3( -712.5, -818.0, 23.73 ), name = "ATM - Strawberry" }
    }
}

-- Blips
Config.Blips = {
    Depot = { enabled = true, coords = Config.Depot, sprite = 431, color = 2, scale = 1.0, text = "Gruppe 6 Depot" },
    Schedule = { enabled = true, sprite = 280, color = 2, scale = 0.8, text = "Gruppe 6 Schedule" },
    Loan = { sprite = 280, color = 46, scale = 0.7, text = "Loan Pickup" },
    Cash = { sprite = 108, color = 5, scale = 0.7, text = "Cash Pickup" }
}

-- Money
Config.LoanPayout = 1250      -- paid after returning from loan-phase (configurable)
Config.CashPayout = 2500      -- paid after completing cash-phase (configurable)

-- Target interaction sizes (BoxZone size)
Config.ZoneSize = { x = 2.0, y = 2.0, z = 1.0 }

-- Progress times (ms)
Config.Timers = {
    CollectLoan = 5000,
    LoadCase = 4000,
    CollectCash = 6000
}

-- Notification duration for next-location hint (milliseconds)
Config.NextLocationNotifyDuration = 30000 -- 30s

-- Show-all-blips duration (ms)
Config.ShowAllBlipsDuration = 30000 -- UNUSED

-- Default long notification time
Config.DefaultNotifyTime = 15000 -- 15s
