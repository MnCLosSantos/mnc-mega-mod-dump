Config = {}

-- Debug mode
Config.Debug = false

-- xsound label prefix. The label actually used per vehicle is
Config.SoundLabel          = "mnc_carplay"
Config.DefaultVolume       = 0.3
Config.DefaultRadius       = 15.0
Config.MinRadius           = 5.0
Config.MaxRadius           = 50.0  
Config.YoutubeLoadGraceMs  = 3000
Config.RangeCheckInterval  = 500
Config.RangeHysteresis     = 5.0

-- Door/window muffling for nearby listeners who are not riding in the
-- vehicle. When every listed door is closed, playback is scaled by
-- MuffledVolumeFactor for everyone outside the car; anyone inside the
-- vehicle always hears it at full volume, and it goes back to full volume
-- for outside listeners the moment a door opens. Door indexes follow the
-- standard GTA V ordering: 0/1 front left/right, 2/3 rear left/right.
Config.MuffledVolumeFactor  = 0.35
Config.MuffleDoorIndexes    = { 0, 1, 2, 3 }

-- Left empty on purpose. IsVehicleWindowIntact() is not a reliable "window
-- rolled down" check -- vanilla GTA V has no native for that at all, only
-- for broken/missing glass -- and testing showed at least one vehicle model
-- reporting a window index as "not intact" from the moment it spawned, with
-- nothing having broken it. That permanently blocked the seal check
-- regardless of door state. Add specific window indexes here only if you've
-- verified IsVehicleWindowIntact behaves correctly for the vehicles you
-- care about; otherwise leave this empty and rely on doors only.
Config.MuffleWindowIndexes  = {}

Config.MuffleCheckInterval  = 250

-- GTA does not close a vehicle door behind a ped that gets out, so without
-- this the seal check above would never see a Carplay vehicle as sealed
-- after someone exits. Delay (ms) after exiting before we shut whichever
-- doors got left open, so it doesn't fight the exit animation.
Config.DoorAutoCloseDelayMs = 800



-- Max playlists/songs a player can save (personal — each occupant loads there playlists)
Config.MaxPlaylists        = 100
Config.MaxSongsPerPlaylist = 1500



-- ── Install / removal ──────────────────────────────────────────
Config.InteractDistance = 3.0    
Config.InstallTime = 4000        
Config.RemoveTime  = 4000         
Config.InstallAnim = { dict = "mini@repair", clip = "fixing_a_ped" }
Config.RemoveAnim  = { dict = "mini@repair", clip = "fixing_a_ped" }



-- Reusable removal tool item.
Config.RemovalTool = "carplay_tool"



-- Leave as nil to allow installing on any vehicle class.
Config.AllowedVehicleClasses = nil



-- Command that opens the UI
Config.EnableCarplayCommand = true
Config.CarplayCommand = "carplay"



-- ── In-car dancing ───────────────────────────────────────────────
Config.EnableCarDance = true
Config.DanceAnim = {
    dict = "amb@code_human_in_car_mp_actions@dance@std@%s@base",
    clip = "idle_b",
    flag = 1, -- loop
}
-- Seat index → animation-dict suffix. Seats with no entry here (e.g.
-- 3rd-row seats in vans/SUVs) simply never get the dance anim. (will make ped fall off on those seats if dancing)
Config.DanceSeats = {
    --[-1] = "ds",  -- driver
    [0]  = "ps",  -- front passenger
    [1]  = "rds", -- rear, driver side
    [2]  = "rps", -- rear, passenger side
}



-- ── Tablet prop options ─────────────────────────────────────────────
Config.TabletPropOptions = {
    { id = "impexp", model = "imp_prop_impexp_tablet",  label = "ImpExp Tablet" },
    { id = "cs",     model = "prop_cs_tablet",           label = "CS Tablet" },
    { id = "heist",  model = "hei_prop_dlc_tablet",      label = "Heist Tablet" },
    { id = "rehab",  model = "reh_prop_reh_tablet_01a",  label = "Rehab Tablet" },
}


Config.DefaultTabletProp = "impexp"

-- ── Tablet prop ─────────────────────────────────────────────────
Config.TabletPropBone     = "dash"
Config.TabletPropOffset   = vector3(0.13, 0.35, 0.42)
Config.TabletPropRotation = vector3(0.0, -90.0, -20.0)
Config.TabletAttachWaitMs = 500   
Config.TabletAttachMaxTries = 60 

-- ── Prop positioning tool ───────────────────────────────────────
Config.PositionRange = {
    offset   = { -5.0, 5.0 },
    rotation = { -180.0, 180.0 }, 
}


Config.WorldUI = {
    Enabled         = true,  
    MaxDrawDistance = 12.0,  
}


Config.ScreenOffsetRange   = { -1.0, 1.0 } 
Config.DefaultScreenOffset = { x = 0.0, y = 0.0, z = 0.0 }

-- ── Skins: one item per skin, 15 total (10 colours + 5 artwork wraps) ──
Config.CarplaySkins = {
    -- ── Solid colours (10) ──────────────────────────────────
    { id = "silver", item = "carplay_silver", label = "Silver", type = "color",
      accent = "#2563eb", bezel = "#d2d3d8", bezelD = "#a9abb3", bezelDD = "#888a92" },
    { id = "black",  item = "carplay_black",  label = "Black", type = "color",
      accent = "#3b82f6", bezel = "#2b2d33", bezelD = "#1c1d21", bezelDD = "#131315" },
    { id = "white",  item = "carplay_white",  label = "White", type = "color",
      accent = "#2563eb", bezel = "#f5f6f8", bezelD = "#dcdde2", bezelDD = "#c3c5cb" },
    { id = "red",    item = "carplay_red",    label = "Red", type = "color",
      accent = "#ef4444", bezel = "#c2373c", bezelD = "#9c2b2f", bezelDD = "#7f2226" },
    { id = "blue",   item = "carplay_blue",   label = "Blue", type = "color",
      accent = "#60a5fa", bezel = "#3b6cc9", bezelD = "#2d549e", bezelDD = "#234480" },
    { id = "green",  item = "carplay_green",  label = "Green", type = "color",
      accent = "#4ade80", bezel = "#3f9e5b", bezelD = "#317e48", bezelDD = "#28653a" },
    { id = "yellow", item = "carplay_yellow", label = "Yellow", type = "color",
      accent = "#eab308", bezel = "#e8c94a", bezelD = "#c9ab2f", bezelDD = "#a68c22" },
    { id = "purple", item = "carplay_purple", label = "Purple", type = "color",
      accent = "#a855f7", bezel = "#8354c9", bezelD = "#66409e", bezelDD = "#513180" },
    { id = "orange", item = "carplay_orange", label = "Orange", type = "color",
      accent = "#fb923c", bezel = "#d97a3a", bezelD = "#b1602c", bezelDD = "#8f4d23" },
    { id = "pink",   item = "carplay_pink",   label = "Pink", type = "color",
      accent = "#f472b6", bezel = "#e478b0", bezelD = "#c2578e", bezelDD = "#9e4373" },

    -- ── Artwork wraps (5) ────────────────────────────────────
    { id = "racing",   item = "carplay_racing",   label = "Racing Stripes", type = "artwork",
      accent = "#ef4444", bezel = "#1c1d21", bezelD = "#131315", bezelDD = "#0c0c0d" },
    { id = "carbon",   item = "carplay_carbon",   label = "Carbon Fiber", type = "artwork",
      accent = "#9ca3af", bezel = "#232428", bezelD = "#17181b", bezelDD = "#0f1012" },
    { id = "camo",     item = "carplay_camo",     label = "Tactical Camo", type = "artwork",
      accent = "#84cc16", bezel = "#5b5a3f", bezelD = "#46452f", bezelDD = "#363524" },
    { id = "engraved", item = "carplay_engraved", label = "Gunmetal Engraved", type = "artwork",
      accent = "#cbd5e1", bezel = "#4b4f56", bezelD = "#383b40", bezelDD = "#2a2c30" },
    { id = "wood",     item = "carplay_wood",     label = "Walnut Wood", type = "artwork",
      accent = "#eab308", bezel = "#5b3a24", bezelD = "#472c1b", bezelDD = "#331f13" },
}