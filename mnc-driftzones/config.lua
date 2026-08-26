Config = {}

-- main config options
Config.AdminPermission = 'admin'                                -- QBCore permission group required to create/edit/delete drift zones.
Config.AdminAce = 'command.driftzones'                          -- ACE permission checked as a fallback (add "add_principal identifier.XXX group.admin" or "add_ace group.admin command.driftzones allow" server-side if you use ACE/principals instead of QBCore groups).
Config.DefaultThickness = 40.0                                  -- Default vertical height (Z thickness) of a drift zone if not overridden
Config.MinZonePoints = 3                                        -- Minimum points required to save a zone (a polygon needs at least 3)
Config.MarkerColor = { r = 255, g = 0, b = 0, a = 200 }         -- Marker/line color used while building a zone's shape in freecam.
Config.AimMarkerColor = { r = 0, g = 210, b = 255, a = 200 }    -- Marker color for the "you are aiming here" indicator shown in freeroam
Config.ZoneCheckDebug = false                                   -- Passed through to ox_lib's zone debug draw (shows zone wireframes in-game).
Config.SoundVolume = 0.4                                        -- Volume (0.0 - 1.0) for the enter/exit sounds played through the NUI.

-- Freecam options
Config.Freecam = {
    fov = 60.0,               -- camera field of view
    lookSensitivityX = 4.0,   -- mouse look speed (yaw)
    lookSensitivityY = 4.0,   -- mouse look speed (pitch)
    baseSpeed = 0.85,         -- base fly speed
    fastMultiplier = 6.0,     -- speed multiplier while holding Left Shift
    slowMultiplier = 6.0,     -- speed divisor while holding Left Alt (precision)
    raycastDistance = 300.0,  -- how far to look for a surface to drop a point on;
}

-- blip options
Config.Blip = {
    enabled = true,
    sprite = 877,
    color = 27,
    scale = 1.0,
}