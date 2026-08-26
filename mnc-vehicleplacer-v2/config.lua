Config = {}

Config.Debug = false -- Set to true to enable debug prints

Config.AdminGroups = { 'admin', 'superadmin', 'god' } -- QBCore permission groups allowed to use /vehplacer

Config.ImagePaths = { -- image paths for vehicle models base game and lore supported (around 1900 lore vehicles supported with mnc-images links, you can upload your own images via git-bash using lfs if you want it to show the vehicle image)
    primary        = 'https://docs.fivem.net/vehicles/{model}.webp',
    github1        = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage/raw/main/{model}.png',
    github2        = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage-2/raw/main/{model}.png',
    local_fallback = './images/fallback.png',
}

-- ─── Proximity & anti-drift settings ─────────────────────────

Config.ProximitySpawnRadius   = 85.0     -- When to spawn
Config.ProximityDespawnRadius = 90.0     -- When to despawn (must be bigger)
Config.ProximityCheckInterval = 3500     -- Check every 3.5 seconds

Config.DriftLimit             = 1.5      -- Meters till vehicles is classed as lost

-- ─── Static placements ───────────────────────────────────────

-- Static placements defined in config (always available, cannot be deleted via UI).
-- Vehicles start dormant and are spawned automatically when a player is within proximity.
Config.Placements = {
    -- [1] = {
        -- name = "LA FESTA LIMO",
        -- vehicleModel = "Stretch",
        -- vehicleSpawn = vector4(1353.09, 1156.52, 113.57, 130.81), -- x, y, z, heading
    -- },
    -- [2] = {
        -- name = "AutoExotics yosem stepside",
        -- vehicleModel = "ysf",
        -- vehicleSpawn = vector4(535.5, -256.86, 50.55, 288.95), -- x, y, z, heading
    -- },
    -- [3] = {
        -- name = "elegyx_1",
        -- vehicleModel = "elegyx",
        -- vehicleSpawn = vector4(-790.18, -236.28, 37.73, 57.31), -- x, y, z, heading
    -- },
    -- [4] = {
        -- name = "elegyrh6_1",
        -- vehicleModel = "elegyrh6",
        -- vehicleSpawn = vector4(-786.33, -242.96, 37.73, 154.27), -- x, y, z, heading
    -- },
    -- [5] = {
        -- name = "police32_1",
        -- vehicleModel = "police32",
        -- vehicleSpawn = vector4(473.7, 5410.73, 671.27, 0.32), -- x, y, z, heading
    -- },
    -- [6] = {
        -- name = "police32_2",
        -- vehicleModel = "police32",
        -- vehicleSpawn = vector4(479.59, 5414.49, 671.27, 359.9), -- x, y, z, heading
    -- },
    -- [7] = {
        -- name = "polsultan_1",
        -- vehicleModel = "polsultan",
        -- vehicleSpawn = vector4(462.51, 5389.99, 671.28, 0.64), -- x, y, z, heading
    -- },
    -- [8] = {
        -- name = "polsentinel_1",
        -- vehicleModel = "polsentinel",
        -- vehicleSpawn = vector4(467.14, 5389.82, 671.28, 359.43), -- x, y, z, heading
    -- },
    -- [9] = {
        -- name = "pvtjv_1",
        -- vehicleModel = "pvtjv",
        -- vehicleSpawn = vector4(471.78, 5389.45, 671.19, 1.43), -- x, y, z, heading
    -- },
	-- [10] = {
        -- name = "meet_1",
        -- vehicleModel = "revolutions",
        -- vehicleSpawn = vector4(854.09, -2363.66, 29.76, 277.02), -- x, y, z, heading
    -- },
	-- [11] = {
        -- name = "meet_2",
        -- vehicleModel = "zodiacr",
        -- vehicleSpawn = vector4(854.0, -2357.2, 29.74, 31.99), -- x, y, z, heading
    -- },
	-- [12] = {
        -- name = "meet_3",
        -- vehicleModel = "glendaleks",
        -- vehicleSpawn = vector4(850.45, -2356.19, 30.04, 335.99), -- x, y, z, heading
    -- },
	-- [13] = {
        -- name = "meet_4",
        -- vehicleModel = "tampax2",
        -- vehicleSpawn = vector4(845.92, -2356.43, 29.68, 25.6), -- x, y, z, heading
    -- },
	-- [14] = {
        -- name = "meet_5",
        -- vehicleModel = "bypdbe",
        -- vehicleSpawn = vector4(841.76, -2357.23, 29.77, 355.07), -- x, y, z, heading
    -- },
}