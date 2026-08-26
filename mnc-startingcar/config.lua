Config = {}

-- ============================================================
--  VEHICLE SPAWN POINTS -- edit coords/heading to your map
--  These are where each showroom car physically sits. They no longer each
--  have their own "[E]" prompt -- they just need to exist here so the
--  selector UI knows what to list and where to check availability.
-- ============================================================
Config.VehicleSpawns = {
    { model = 'sentinel3',    label = 'Sentinel Classic', coords = vector4(-1013.12, -2695.48, 13.42, 149.79), boughtSound = 'sounds/euro.mp3' },
    { model = 'remus',        label = 'Remus',            coords = vector4(-1018.22, -2691.83, 13.3, 151.31),  boughtSound = 'sounds/jdm.mp3'  },
    { model = 'dominator10',  label = 'Dominator FX',     coords = vector4(-1015.56, -2693.84, 13.4, 154.16),  boughtSound = 'sounds/usdm.mp3' },
}

-- ============================================================
--  SELECTOR POINT -- the single spot (with a marker) where players press
--  [E] to open the vehicle browser. Put this in front of the showroom,
--  roughly centered on the three cars above -- edit to your map.
-- ============================================================
Config.SelectionPoint = vector4(-1017.1, -2696.67, 13.98, 328.07)

-- Distance at which the marker itself draws
Config.MarkerDrawDistance = 45.0

-- Distance at which the "[E] Browse Vehicles" prompt appears and E is accepted
Config.InteractionDistance = 2.5

Config.Marker = {
    type = 1, -- Cylinder -- a simple ground disc, good for a "stand here" point
    size = vector3(1.2, 1.2, 0.6),
    color = { r = 178, g = 34, b = 68, a = 140 }, -- pink-slip red
    bobUpAndDown = true,
    faceCamera = false,
    rotate = false,
}

-- ============================================================
--  DELIVERY POINT -- once a player actually claims a vehicle, it is moved
--  here instead of being left parked in its showroom slot. This keeps the
--  showroom clean (the replacement vehicle spawns back into the same slot
--  without overlapping the one that was just bought) and lets you deliver
--  purchased cars somewhere sensible, e.g. right outside the dealership.
--
--  Set to a vector4(x, y, z, heading), or leave as `nil` to keep the old
--  behaviour of handing the vehicle over right where it was parked.
-- ============================================================
Config.DeliveryPoint = vector4(-1010.79, -2685.4, 13.41, 332.31) -- e.g. vector4(-1005.4, -2710.2, 13.9, 30.0)

-- ============================================================
--  SOUNDS -- both are played through the NUI (html/script.js), triggered
--  from client.lua via SendNUIMessage. No external audio resource (e.g.
--  xsound) is required or used.
-- ============================================================

-- Plays once, ever, the very first time a player opens the vehicle browser.
Config.SoundFile = 'audio.mp3'
Config.IntroSoundVolume = 0.6

-- Plays the moment the player is warped into their newly purchased car
-- (see each vehicle's `boughtSound` above).
Config.VehicleSoundVolume = 0.8

-- ============================================================
--  MAP BLIPS -- one blip at the selector point, set enabled = false to disable
-- ============================================================
Config.Blip = {
    enabled = false,
    sprite = 225,
    color = 3,
    scale = 0.7,
    label = 'Claim Starter Vehicle',
}

-- ============================================================
--  GARAGE / OWNERSHIP SETTINGS
-- ============================================================
Config.GarageName = 'pillbox'
Config.FuelSystem = 'legacy'
Config.RespawnDelay = 5000