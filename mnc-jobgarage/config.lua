-- config.lua
Config = {
    Debug = false,               -- Enable debug prints
    Notify = "ox",               -- Notification system: "qb" for qb-core, "ox" for ox_lib
    -- Menu = "qb",              -- (Removed) Vehicle pull-out no longer uses qb-menu/ox_lib — it now opens a custom NUI grid with vehicle images.
    Target = "qb",               -- Target system: "qb" for qb-target, "ox" for ox-target
    Fuel = "LegacyFuel",         -- Fuel script (set to your fuel script folder)
    CarDespawn = false,          -- Enable despawn animation
    ReturnDistanceCheck = false,  -- Enable/disable distance check for returning vehicles
    ReturnRadius = 15.0,         -- Radius (in meters) within which vehicles must be returned

    -- Image paths for vehicle models.
    -- Base game and lore vehicles supported (~1900 lore vehicles via mnc-images links).
    -- You can upload your own images via git-bash using LFS.
    ImagePaths = {
        primary        = 'https://docs.fivem.net/vehicles/{model}.webp',
        github1        = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage/raw/main/{model}.png',
        github2        = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage-2/raw/main/{model}.png',
        local_fallback = './images/fallback.png',
    },

    -- Job Garages
    --
    -- Each entry can now have an optional `garageId` field.
    -- garageId must be unique across ALL entries — it is used as the DB key
    -- for vehicles and as the target identifier in-world.
    -- If omitted, garageId defaults to the job name (preserving old behaviour).
    --
    -- To add a second garage for the same job, duplicate the entry and give it
    -- a different garageId (e.g. "police_airport"). Vehicles are linked to
    -- garageId in the DB — they are completely independent between garages.
    --
    Locations = {
        -- POLICE - Mission Row PD (Main Garage)
        {
            zoneEnable = true,
            job      = "police",
            garageId = "police",          -- unique garage identifier
            garage = {
                spawn = vec4(436.2, -976.03, 24.9, 138.13),
                out   = vec4(461.14, -975.53, 25.7, 0.29),
                list = {
                    polnscout        = { grade = 0, CustomName = "police patrol 1", performance = "max", order = 1 },
                    POLGRESLEY       = { grade = 0, CustomName = "police patrol 2", performance = "max", order = 2 },
                    POLICE32         = { grade = 0, CustomName = "police patrol 3", performance = "max", order = 3 },
                    pgranger2        = { grade = 0, CustomName = "police patrol 4", performance = "max", order = 4 },
                    nkstanier        = { grade = 0, CustomName = "police patrol 5", performance = "max", order = 5 },
                    polbuffalosx     = { grade = 1, CustomName = "police patrol 6", performance = "max", order = 6 },
                    lspdscout13      = { grade = 1, CustomName = "police patrol 7", performance = "max", order = 7 },
                    polaleutian      = { grade = 1, CustomName = "police patrol 8", performance = "max", order = 8 },
                    truroamer        = { grade = 1, CustomName = "police patrol 9", performance = "max", order = 9 },
                    trualamo         = { grade = 1, CustomName = "police patrol 10", performance = "max", order = 10 },
                    umkroamer        = { grade = 1, CustomName = "police patrol 11", performance = "max", order = 11 },
                    polthrust        = { grade = 2, CustomName = "police patrol 12", performance = "max", order = 12 },
                    lspdraiden       = { grade = 2, CustomName = "police patrol 13", performance = "max", order = 13 },
                    poldmnts2        = { grade = 2, CustomName = "police patrol 14", performance = "max", order = 14 },
                    trubuffalo       = { grade = 2, CustomName = "police patrol 15", performance = "max", order = 15 },
                    polruiners       = { grade = 2, CustomName = "police patrol 16", performance = "max", order = 16 },
                    polgauntlets     = { grade = 2, CustomName = "police patrol 17", performance = "max", order = 17 },
                    nkbuffalos       = { grade = 2, CustomName = "police patrol 18", performance = "max", order = 18 },
                    nsandstormmk     = { grade = 3, CustomName = "police patrol 19", performance = "max", order = 19 },
                    polgauntlet      = { grade = 3, CustomName = "police patrol 20", performance = "max", order = 20 },
                    rpdvstr          = { grade = 3, CustomName = "police patrol 21", performance = "max", order = 21 },
                    nkbuffalosum     = { grade = 3, CustomName = "police patrol 22", performance = "max", order = 22 },
                    dnscoutun        = { grade = 3, CustomName = "police patrol 23", performance = "max", order = 23 },
                    polvigeros       = { grade = 3, CustomName = "police patrol 24", performance = "max", order = 24 },
                    swatvanr         = { grade = 4, CustomName = "swat van 25", performance = "max", order = 25 },
                    swatvans         = { grade = 4, CustomName = "swat van 26", performance = "max", order = 26 },
                    swatvans2        = { grade = 4, CustomName = "swat van 27", performance = "max", order = 27 },
                    swatinsur        = { grade = 4, CustomName = "swat armoured 28", performance = "max", order = 28 },
                    swatstoc         = { grade = 4, CustomName = "swat patrol 29", performance = "max", order = 29 },
                    DREADS           = { grade = 4, CustomName = "swat patrol 30", performance = "max", order = 30 },
                    polfmjs          = { grade = 5, CustomName = "police super 31", performance = "max", order = 31 },
                    polbullets       = { grade = 5, CustomName = "police super 32", performance = "max", order = 32 },
                    polcoquettes     = { grade = 5, CustomName = "police super 33", performance = "max", order = 33 },
                    poldmnts         = { grade = 5, CustomName = "police muscle 34", performance = "max", order = 34 },
                    polcoquettes2    = { grade = 5, CustomName = "police super 35", performance = "max", order = 35 },
                    trubuffalowidebody = { grade = 5, CustomName = "police muscle 36", performance = "max", order = 36 },
                    nkcoquette       = { grade = 5, CustomName = "police super 37", performance = "max", order = 37 },
                    polcoquettes3    = { grade = 5, CustomName = "police super 38", performance = "max", order = 38 },
                    polregent        = { grade = 5, CustomName = "police patrol 39", performance = "max", order = 39 },
                    expolalamo       = { grade = 5, CustomName = "police patrol 40", performance = "max", order = 40 },
                }
            }
        },

        -- POLICE - Sandy Shores / Secondary Garage Example
        -- Uncomment and fill in to add a second police garage at a different location.
        -- Vehicles added here (in-game or via config) are separate from the main garage.
        --[[
        {
            zoneEnable = true,
            job      = "police",
            garageId = "police_sandy",    -- must be unique
            garage = {
                spawn = vec4(0.0, 0.0, 0.0, 0.0),  -- set your coords
                out   = vec4(0.0, 0.0, 0.0, 0.0),
                list = {
                    -- Add vehicles here, or manage them via the /jobgarage admin panel
                    -- polnscout = { grade = 0, CustomName = "Sandy Patrol", performance = "max", order = 1 },
                }
            }
        },
        --]]

        -- TRACK MARSHALL
        {
            zoneEnable = true,
            job      = "trackmarshall",
            garageId = "trackmarshall",
            garage = {
                spawn = vec4(317.09, -4374.14, 29.86, 90.14),
                out   = vec4(328.47, -4382.77, 29.86, 180.34),
                list = {
                    fdbuff         = { grade = 0, CustomName = "Support Car", performance = "max", order = 1 },
                    fdl300         = { grade = 1, livery = 3, CustomName = "Support Truck", performance = "max", order = 2 },
                    LSFDCMD        = { grade = 2, livery = 0, CustomName = "Support Pickup Truck", performance = "max", order = 3 },
                    polnspeedo     = { grade = 2, livery = 0, CustomName = "Track Emergency Support", performance = "max", order = 4 },
                    medicalrebla   = { grade = 2, CustomName = "Medical Car", performance = "max", order = 5 },
                    cpacecar       = { grade = 3, CustomName = "PaceCar 1", performance = "max", order = 6 },
                    cpacecar2      = { grade = 3, CustomName = "PaceCar 2", performance = "max", order = 7 },
                    dpacecar       = { grade = 3, CustomName = "PaceCar 3", performance = "max", order = 8 },
                    sugoipace      = { grade = 3, CustomName = "PaceCar 4", performance = "max", order = 9 },
                    safetyneon     = { grade = 3, CustomName = "Saftey Car 1", performance = "max", order = 10 },
                    safetyneon2    = { grade = 3, CustomName = "Saftey Car 2", performance = "max", order = 11 },
                    safetycomet    = { grade = 3, CustomName = "Saftey Car 3", performance = "max", order = 12 },
                    safety811      = { grade = 3, CustomName = "Saftey Car 4", performance = "max", order = 13 },
                    safetycypher1  = { grade = 3, CustomName = "Saftey Car 5", performance = "max", order = 14 },
                    safetycypher2  = { grade = 3, CustomName = "Saftey Car 6", performance = "max", order = 15 },
                    safetyxs       = { grade = 3, CustomName = "Saftey Car 7", performance = "max", order = 16 },
                    safetyzion     = { grade = 3, CustomName = "Saftey Car 8", performance = "max", order = 17 },
                    schlagenstr2   = { grade = 4, CustomName = "Chief PaceCar", performance = "max", order = 18 },
                }
            }
        },

        -- AMBULANCE
        {
            zoneEnable = true,
            job      = "ambulance",
            garageId = "ambulance",
            garage = {
                spawn = vec4(343.23, -556.42, 28.74, 341.04),
                out   = vec4(334.03, -561.58, 28.74, 160.35),
                list = {
                    ttmodz_izzy_dorado     = { grade = 1, CustomName = "Dorado Paramedic", order = 1 },
                    ttmodz_izzy_buffalo4   = { grade = 1, CustomName = "Buffalo Paramedic", order = 2 },
                    ttmodz_izzy_castigator = { grade = 1, CustomName = "Castigator Paramedic", order = 3 },
                    ["2vd_vscout2"]        = { grade = 2, livery = 2, CustomName = "Scout Paramedic", performance = "max", order = 4 },
                    emsstalker             = { grade = 2, livery = 1, CustomName = "Stalker Paramedic", performance = "max", order = 5 },
                    ["2vd_vsandking"]      = { grade = 2, livery = 2, CustomName = "Sandking Ambulance", performance = "max", order = 6 },
                    ambulance              = { grade = 3, CustomName = "Ambulance", performance = "max", order = 7 },
                    ambulance2             = { grade = 3, CustomName = "Advanced Ambulance", performance = "max", order = 8 },
                    sandbulance            = { grade = 3, livery = 5, CustomName = "Sandstorm Ambulance", performance = "max", order = 9 },
                    emsscoutmk             = { grade = 3, livery = 2, CustomName = "Scout Paramedic Supervisor", performance = "max", order = 10 },
                    aleutianems            = { grade = 4, CustomName = "Aleutian Paramedic Chief", performance = "max", order = 11 },
                    emscomet               = { grade = 4, CustomName = "Comet Paramedic Chief", performance = "max", order = 12 },
                }
            }
        },

        -- VINEWOOD RECORDS
        {
            zoneEnable = true,
            job      = "vinewoodrecords",
            garageId = "vinewoodrecords",
            garage = {
                spawn = vec4(-495.7, 36.27, 56.5, 99.88),
                out   = vec4(-492.98, 34.21, 56.5, 269.07),
                list = {
                    xls = {
                        CustomName = "Records Company XLS",
                        colors = {12, 12},
                        performance = "max",
                        bulletproof = false,
                        windowTint = 2,
                        order = 1
                    },
                }
            }
        },

        -- LA FESTA
        {
            zoneEnable = true,
            job      = "lafesta",
            garageId = "lafesta",
            garage = {
                spawn = vec4(1401.63, 1110.95, 114.38, 359.78),
                out = vec4(1406.35, 1110.35, 114.83, 270.75),
                list = {
                    panto = {
                        CustomName = "Panto",
                        colors = {12, 12},
                        windowTint = 3,
                        order = 1
                    },
                    algoschafter = {
                        CustomName = "LayBach Schafter",
                        colors = {12, 12},
                        performance = "max",
                        bulletproof = true,
                        livery = 1,
                        windowTint = 3,
                        extras = {1, 2},
                        order = 2
                    },
                    dubsta = {
                        CustomName = "DUBSTA OG",
                        colors = {12, 12},
                        windowTint = 3,
                        livery = 1,
                        extras = { [12] = false, [11] = true },
                        performance = "max",
                        visualUpgrades = {
                            fender = 0,
                            roof = 1,
                            neon = { enabled = true, color = {255, 0, 255}, layout = 13.0 },
                            wheels = 23,
                        },
                        order = 3
                    },
                }
            }
        },

        -- AUTO EXOTICS
        {
            zoneEnable = true,
            job      = "autoexotics",
            garageId = "autoexotics",
            garage = {
                spawn = vec4(564.13, -227.61, 55.83, 334.62),
                out = vec4(561.95, -214.35, 55.83, -36.5),
                list = {
                    imperial   = { livery = 9, CustomName = "Work Van", order = 1 },
                    flatbed3   = { colors = {70, 70}, CustomName = "Flatbed truck", order = 2 },
                    towtruck4  = { livery = 0, CustomName = "Hook Truck", order = 3 },
                    servicevan = { livery = 1, CustomName = "Service Van", order = 4 },
                }
            }
        },

        -- SSMCO
        {
            zoneEnable = true,
            job      = "ssmco",
            garageId = "ssmco",
            garage = {
                spawn = vec4(2500.87, 4081.17, 38.52, 62.31),
                out = vec4(2504.67, 4090.2, 38.63, -120.32),
                list = {
                    seminole2 = { CustomName = "Work Car", order = 1 },
                    muletip   = { CustomName = "Small Work Truck", order = 2 },
                    tiptruck  = { CustomName = "Medium Work Truck", order = 3 },
                    tiptruck2 = { CustomName = "Large Work Truck", order = 4 },
                }
            }
        },

        -- GRUPPE 6
        {
            zoneEnable = true,
            job      = "gruppe6",
            garageId = "gruppe6",
            garage = {
                spawn = vec4(2.35, -670.26, 32.34, 185.42),
                out = vec4(-1.71, -663.66, 32.34, 6.37),
                list = {
                    g6perennial = { CustomName = "G6 Perennial", order = 1 },
                    g6buffalo   = { CustomName = "G6 Buffalo", order = 2 },
                    g6speedo    = { CustomName = "G6 Speedo", order = 3 },
                }
            }
        },

        -- YACHT CLUB
        {
            zoneEnable = true,
            job      = "yachtclub",
            garageId = "yachtclub",
            garage = {
                spawn = vec4(-955.79, -1623.58, 0.19, 134.85),
                out = vec4(-856.46, -1321.66, 1.61, -70.79),
                list = {
                    explorer = { CustomName = "Explorer Yacht", order = 1 },
                    tropic   = { CustomName = "Charter Transport", order = 2 },
                }
            }
        },

        -- MNC RACING
        {
            zoneEnable = true,
            job      = "mncracing",
            garageId = "mncracing",
            garage = {
                spawn = vec4(1206.92, -3197.95, 6.03, 176.48),
                out = vec4(1222.4, -3236.64, 5.53, 90.41),
                list = {
                    bensonc = { CustomName = "Enclosed Car Transport", plate = "MNCRACES", order = 1 },
                }
            }
        },
    }
}