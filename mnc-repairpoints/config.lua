Config = {}

-- Debug mode (set to true for extra logs/notifications/prints)
Config.Debug = false

-- Jobs that count as "mechanic on duty" → public repair points get hidden when any of these are on duty
Config.MechanicJobs = {
    mechanic = true,   -- default qb-mechanicjob job name
    mechanic2 = true,   
    mechanic3 = true,   
    beekers = true,   
    bennys = true,  
    autoexotics = true,   	 
    -- Add as needed
}

-- How often to check & broadcast duty status (in seconds)
Config.DutyCheckInterval = 120

-- Prices (bank money) - these are defaults for public locations
Config.RepairPriceFull = 750   -- Full repair (engine + body + dirt)
Config.RepairPriceBody = 350   -- Body damage only

Config.Locations = {
    repair = {
        -- Public repair points (visible when no mechanics on duty)
        { 
            coords = vector4(-200.1, -1308.51, 30.68, 269.81), 
            name = 'Bennys Repair Point' 
        },
        { 
            coords = vector4(124.47, 6624.61, 31.2, 314.5), 
            name = 'Beekers Repair Point' 
        },
        { 
            coords = vector4(-364.04, -137.46, 38.08, 284.29), 
            name = 'LSC Repair Point' 
        },

        -- Job-restricted example: Police-only repair bay
        { 
            coords = vector4(463.35, -1019.35, 27.61, 90.38),   -- Example: MRPD garage area coords – change to your preferred coords
            name = 'MRPD Repair Bay', -- Name used in drawtext
            job = 'police',           -- Only players with job 'police' can see & use this point
            minGrade = 0,             -- Optional: minimum job grade (0 = any rank). Remove or set higher if needed
            emergencyOnly = true,     -- Optional: restrict to class 18 (emergency)
        },
        { 
            coords = vector4(-482.28, 6024.34, 30.86, 41.8),   
            name = 'BCSO Repair Bay',
            job = 'police',           
            minGrade = 0,   
            emergencyOnly = true,          
        },
        {
            coords = vector4(342.45, -562.64, 28.26, 158.72),
            name = 'Pillbox Medical Repair Bay',
            job = 'ambulance',
            minGrade = 0,     
            emergencyOnly = true,     
        },
    }
}