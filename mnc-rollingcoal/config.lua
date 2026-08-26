-- config.lua
Config = {}

Config.Debug = false

-- ============================================================================================================
--                                 Job lock for applying kits (items only)
-- ============================================================================================================
Config.RequireJob = true                    -- set to false to disable job check completely

Config.AllowedJobs = {
    mechanic    = 0,     -- grade 0 or higher
    mechanic2   = 0,
    mechanic3   = 0,
    beekers     = 0,
    autoexotics = 0,
    bennys      = 2,     -- requires grade 2+
    tuner       = 1,     -- requires grade 1+
}

-- ============================================================================================================
--                                             Smoke levels
-- ============================================================================================================
Config.MaxSmokeAmount = 5       -- smoke levels

Config.MinRPM         = 0.22    -- minimum rpm for rpm based smoke


-- ============================================================================================================
--                        Particle (thick exhaust – particles should trail/drift behind naturally)
-- ============================================================================================================
Config.ParticleDict = "core"                    -- effect dict

Config.ParticleName = "veh_exhaust_truck_rig"   -- effect name


-- ============================================================================================================
--                        Scale tuning (particles inherit some velocity from car → trail effect)
-- ============================================================================================================
Config.BaseScale           = 1.5     -- visible at level 1

Config.ScaleStep           = 2.8     -- stronger per level

Config.RpmScaleMultiplier  = 1.8     -- rpm increase

Config.MaxScale            = 156.0    -- max smoke output

Config.SmokeInterval       = 10      -- Update interval 


-- ============================================================================================================
--                   Smoke Kit Items / Auto Smoke Kits 
-- ============================================================================================================
Config.SmokeKitItem          = "smoke_kit"          -- smoke kit item name (requires EGR + DPF deletes first)

Config.EgrDeleteItem         = "egr_delete_kit"     -- EGR delete kit item name (must be installed before smoke kit)

Config.DpfDeleteItem         = "dpf_delete_kit"     -- DPF delete kit item name (must be installed before smoke kit)

Config.RemovalKitItem        = "smoke_removal_kit"  -- removal kit item name (strips all installed kits from a vehicle)

Config.RefundOnRemoval       = true                 -- if true, removed kit items are returned to the mechanic's inventory

Config.ApplyDistance         = 2.5                  -- distance to apply items

Config.AutoKitDefaultAmount  = 2                    -- default smoke level for auto-kit vehicles

Config.AutoKitClasses        = {                    -- GTA vehicle class IDs that always have EGR, DPF & smoke kit built-in
   20, 
   19,  
   17,
   12, 
   11, 
   10, 
   9 
}