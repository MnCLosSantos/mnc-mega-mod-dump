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
                    police        = { grade = 0, CustomName = "police patrol 1", performance = "max", order = 1 },
                    police2       = { grade = 0, CustomName = "police patrol 2", performance = "max", order = 2 },
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

        -- AMBULANCE
        {
            zoneEnable = true,
            job      = "ambulance",
            garageId = "ambulance",
            garage = {
                spawn = vec4(343.23, -556.42, 28.74, 341.04),
                out   = vec4(334.03, -561.58, 28.74, 160.35),
                list = {
                    ["example_vehicle"]      = { grade = 2, livery = 2, CustomName = "Sandking Ambulance", performance = "max", order = 1 }, -- use [" "] for spawncodes with _
                    ambulance              = { grade = 3, CustomName = "Ambulance", performance = "max", order = 2 },
                }
            }
        },        
    }
}
