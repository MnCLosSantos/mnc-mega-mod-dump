Config = {}

-- Debug mode (set to true for extra logs/notifications/prints)
Config.Debug = false

-- Jobs that count as "mechanic on duty" → public respray points get hidden when any of these are on duty
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
Config.ResprayPrices = {
    primary      = 350,
    secondary    = 300,
    pearlescent  = 250,
    wheel        = 200,
    interior     = 300,   -- Interior trim color
    dashboard    = 250,   -- Dashboard color
    livery       = 500,   -- Vehicle livery
    full         = 1000,
}

-- Nice color list (feel free to add/remove)
Config.VehicleColors = {
    {name = "Black",               index = 0},
    {name = "Carbon Black",        index = 147},
    {name = "Graphite",            index = 1},
    {name = "Anthracite Black",    index = 11},
    {name = "Black Steel",         index = 2},
    {name = "Dark Silver",         index = 3},
    {name = "Silver",              index = 4},
    {name = "Bluish Silver",       index = 5},
    {name = "Rolled Steel",        index = 6},
    {name = "Shadow Silver",       index = 7},
    {name = "Stone Silver",        index = 8},
    {name = "Midnight Silver",     index = 9},
    {name = "White",               index = 111},
    {name = "Frost White",         index = 112},
    {name = "Red",                 index = 27},
    {name = "Torino Red",          index = 28},
    {name = "Formula Red",         index = 29},
    {name = "Lava Red",            index = 150},
    {name = "Blaze Red",           index = 30},
    {name = "Grace Red",           index = 31},
    {name = "Garnet Red",          index = 32},
    {name = "Sunset Red",          index = 33},
    {name = "Cabernet Red",        index = 34},
    {name = "Candy Red",           index = 35},
    {name = "Hot Pink",            index = 135},
    {name = "Pfister Pink",        index = 137},
    {name = "Salmon Pink",         index = 136},
    {name = "Sunrise Orange",      index = 36},
    {name = "Orange",              index = 38},
    {name = "Bright Orange",       index = 41},
    {name = "Tangerine",           index = 40},
    {name = "Gold",                index = 37},
    {name = "Bronze",              index = 90},
    {name = "Yellow",              index = 88},
    {name = "Race Yellow",         index = 89},
    {name = "Dew Yellow",          index = 91},
    {name = "Lime Green",          index = 55},
    {name = "Green",               index = 52},
    {name = "Forest Green",        index = 53},
    {name = "Olive Green",         index = 54},
    {name = "Dark Green",          index = 56},
    {name = "Racing Green",        index = 50},
    {name = "Sea Green",           index = 57},
    {name = "Gasoline Green",      index = 58},
    {name = "Dark Blue",           index = 63},
    {name = "Blue",                index = 64},
    {name = "Midnight Blue",       index = 75},
    {name = "Saxony Blue",         index = 65},
    {name = "Harbor Blue",         index = 66},
    {name = "Diamond Blue",        index = 67},
    {name = "Surf Blue",           index = 68},
    {name = "Nautical Blue",       index = 69},
    {name = "Racing Blue",         index = 73},
    {name = "Ultra Blue",          index = 71},
    {name = "Light Blue",          index = 74},
    {name = "Schafter Purple",     index = 141},
    {name = "Purple",              index = 142},
    {name = "Bright Purple",       index = 145},
    {name = "Spinnaker Purple",    index = 143},
    {name = "Wine Red",            index = 143},
    {name = "Matte Black",         index = 12},
    {name = "Matte Gray",          index = 13},
    {name = "Matte Light Gray",    index = 14},
    {name = "Matte White",         index = 131},
    {name = "Matte Red",           index = 39},
    {name = "Matte Orange",        index = 41},
    {name = "Matte Yellow",        index = 42},
    {name = "Matte Lime Green",    index = 55},
    {name = "Matte Green",         index = 128},
    {name = "Matte Blue",          index = 70},
    {name = "Matte Purple",        index = 148},
    {name = "Chrome",              index = 120},
    {name = "Brushed Steel",       index = 117},
    {name = "Brushed Black Steel", index = 118},
    {name = "Brushed Aluminum",    index = 119},
}

Config.Locations = {
    respray = {
        -- Public respray points (visible when no mechanics on duty)
        {
            coords = vector4(-211.1, -1308.04, 30.67, 270.37),
            name = 'Bennys Respray Point',
        },
        {
            coords = vector4(108.0, 6608.75, 31.35, 319.44),
            name = 'Beekers Respray Point',
        },
        {
            coords = vector4(-360.16, -128.23, 38.09, 72.47),
            name = 'LSC Respray Point',
        },

        -- Job-restricted example: Police-only respray bay
        {
            coords = vector4(462.73, -1014.6, 27.68, 271.51),   -- Example: MRPD garage area coords – change to your preferred coords
            name = 'MRPD Respray Bay',     -- Name used in drawtext
            job = 'police',                -- Only players with job 'police' can see & use this point
            minGrade = 0,                  -- Optional: minimum job grade (0 = any rank). Remove or set higher if needed
            emergencyOnly = true,          -- Optional: restrict to class 18 (emergency)
        },
        {
            coords = vector4(-476.48, 6031.95, 30.95, 222.6),
            name = 'BCSO Respray Bay',
            job = 'police',
            minGrade = 0,
            emergencyOnly = true,
        },
        {
            coords = vector4(337.79, -561.15, 28.35, 160.82),
            name = 'Pillbox Medical Respray Bay',
            job = 'ambulance',
            minGrade = 0,
            emergencyOnly = true,
        },
    }
}