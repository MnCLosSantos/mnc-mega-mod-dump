Config = {}

-- ===================================================================
-- GENERAL
-- ===================================================================
Config.Locale = 'en'
Config.PayoutAccount = 'bank' -- buy-ins are withdrawn from / payouts paid into this account: 'cash' | 'bank'

-- ===================================================================
-- ADMIN / ROUTE BUILDER  (/setuppinkslips)
-- ===================================================================
Config.Admin = {
    Command = 'setuppinkslips',

    AcePermission = 'admin',

    -- same "drive it once, buffer the time" flow as mnc-cardelivery
    RouteTimer = {
        BufferPercent = 15, -- % added on top of the raw drive time
        MinTime       = 30, -- floor on the resulting time limit (seconds)
        RoundTo       = 5,  -- round the final time limit to the nearest N seconds
    },

    Placement = {
        PreviewVehicle  = 'sultan',
        MoveSpeed       = 15.0,
        FastMultiplier  = 4.0,
        RotateSpeed     = 90.0,
        LookSensitivity = 4.0,
        CamFov          = 60.0,
    },

    MinSpawnPoints = 6, -- a location can't be saved with fewer parked-vehicle spots than this
}

-- ===================================================================
-- PROGRESSION  (tracked per player, per location - see mnc_pinkslips_progress)
-- ===================================================================
Config.Progression = {
    -- hard cap on how many pinkslip attempts a single player can ever unlock at one location
    MaxPinkslipsPerLocation = 4,

    -- paid pot races needed (at that same location) before the player's next pinkslip attempt unlocks
    RacesToUnlockNext = 10,

    -- a completed, paid pot race counts toward that 10 whether the player wins or loses it -
    -- only entering and finishing (or timing out) counts. Set false to require WINS only.
    CountLossesTowardUnlock = false,
}

-- ===================================================================
-- VEHICLE / GARAGE
-- ===================================================================
-- Class lock uses QBCore.Shared.Vehicles[model].category, so every Config.Locations[i].class
-- value below must match a category your qb-core vehicles.lua actually uses
-- (e.g. 'compacts', 'sedans', 'suvs', 'coupes', 'muscle', 'sportsclassics', 'sports', 'super', ...).
Config.WinGarage = 'pillboxgarage' -- qb-garages garage name a won vehicle is parked in (player_vehicles.garage)

Config.Plate = {
    Charset             = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
    Length              = 8,
    MaxGenerateAttempts = 25, -- random plates tried against player_vehicles before giving up (see server.lua GenerateUniquePlate)
}
-- NOTE: every plate this resource hands out (lot/stock display plates AND a pinkslip winner's
-- new plate) comes from GenerateUniquePlate() above - there is no separate "show plate"/prefix
-- scheme any more, and a pinkslip win never carries over the plate the car had on the lot.

-- ===================================================================
-- VEHICLE IMAGES  (admin location builder's "Browse Vehicles" picker)
-- ===================================================================
-- Same chain-of-sources approach as mnc-tradingcards' card creator: the vehicle picker tries
-- each of these in turn (with {model} substituted for a spawn name) until one actually loads,
-- so a lot vehicle that isn't in the official FiveM docs CDN still gets a picture as long as
-- it's in one of the GitHub image stores. The class dropdown and the vehicle grid itself are
-- built live from QBCore.Shared.Vehicles (see client.lua BuildVehicleCatalog) rather than a
-- config list, so they always match whatever's actually spawnable/ownable on this server,
-- addons included.
Config.VehicleImageSources = {
    fivem   = 'https://docs.fivem.net/vehicles/{model}.webp',
    github1 = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage/raw/main/{model}.png',
    github2 = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage-2/raw/main/{model}.png',
}
Config.VehicleImageSourceOrder = { 'fivem', 'github1', 'github2' }

-- ===================================================================
-- PAYOUTS
-- ===================================================================
-- Winning EITHER race type refunds the player's own buy-in plus a matching "house"/NPC buy-in
-- of the same amount (so the base return is always 2x buy-in), on top of a time-weighted bonus
-- below. Losing forfeits the buy-in with nothing returned - a pinkslip loss additionally forfeits
-- the wagered vehicle. See server.lua CalculateRacePayout.
Config.Payout = {
    -- Pinkslip win = 2x buy-in + bonus + the vehicle itself. The bonus is a % of the WON
    -- vehicle's QBCore.Shared.Vehicles price, shifted within the min/max band by how close to
    -- the buzzer the player finished (see TimeBonusWeight).
    PinkslipBasePercent = 0.05,
    PinkslipMinPercent  = 0.02,
    PinkslipMaxPercent  = 0.08,
    DefaultVehicleValue = 15000, -- fallback if a model isn't in QBCore.Shared.Vehicles

    -- Pot race win = 2x buy-in + bonus, cash only - nothing is staked so there's never a vehicle
    -- to lose or win. There's no vehicle value to base the bonus on here, so it's the same %
    -- band applied to the buy-in itself instead.
    PotBasePercent = 0.05,
    PotMinPercent  = 0.02,
    PotMaxPercent  = 0.08,

    TimeBonusWeight = 0.5, -- shared by both bonus calculations above
}

-- ===================================================================
-- DISTANCE BASED LOADING (parked "lot" vehicles waiting to be raced for)
-- ===================================================================
Config.Streaming = {
    CheckInterval   = 3000,
    SpawnDistance   = 70.0,
    DespawnDistance = 200.0,

    -- Stock vehicles spawn this many meters above their configured spawn point, then fall and
    -- settle onto whatever the ground actually is there before being snapped flush and frozen -
    -- see server.lua requestStockSpawn. This fixes lot cars ending up floating or clipped into
    -- the ground when a hand-placed spawn vector's z doesn't exactly match the terrain.
    SpawnHeightOffset = 0.5,  -- meters above spawnPoint.z to spawn at
    SpawnFallTime     = 1000, -- ms to let it fall, unfrozen, before settling
    SpawnSettleTime   = 2000, -- ms to let it settle, unfrozen, before it's snapped to the ground and frozen
}

Config.PromptDistance = 13.0 -- how close to show spot 1 (while driving) before the interact prompt shows

-- Countdown timing - tune these two against however long html/sounds/countdown.mp3 actually
-- runs. Test live with /pinkslips_testcountdown (no race needed) rather than guessing.
Config.RaceCountdown        = 3    -- how many numbers count down (3, 2, 1) - controls frozen throughout
Config.RaceCountdownTickMs  = 1000 -- ms spent on EACH number - lower this to speed the whole countdown up so it matches a shorter countdown.mp3
Config.RaceCountdownGoHoldMs = 600 -- ms "GO!" stays on screen after the countdown before the race HUD takes over

-- ===================================================================
-- SOUNDS
-- ===================================================================
Config.Sounds = {
    PromptCount = 10, -- prompt1.mp3 - plays once when the menu opens
    WinCount    = 14, -- win1.mp3 .. win4.mp3
    LoseCount   = 14, -- lose1.mp3 .. lose4.mp3
    UnlockCount = 2, -- unlock1.mp3 - plays once a new pinkslip attempt unlocks at a location
    -- go.mp3 plays once (no numbered variants) at the end of the start countdown
    -- countdown.mp3 plays once (no numbered variants), right when the countdown starts -
    -- the clip itself covers the full 3-2-1, it is not retriggered per number
}

-- ===================================================================
-- BLIPS
-- ===================================================================
Config.Blips = {
    Start  = { sprite = 724, color = 8, scale = 0.85, label = 'Pinkslip Races' },
    Finish = { sprite = 478, color = 8, scale = 1.0,  label = 'Pinkslip Finish' },
}

-- ===================================================================
-- LOCATIONS
-- ===================================================================
-- spawns   : at least Config.Admin.MinSpawnPoints vector4s - parking spots a car waiting to be
--            raced for can appear in. They don't all need to be filled at once.
-- vehicles : pool of spawn names used to restock an empty spot - keep these the same class as
--            `class` below, since that's also what's required of the vehicle you show up in.
Config.Locations = {
    {
        label         = 'Vinewood Muscle Pinks',
        class         = 'muscle',
        start         = vector4(-215.8, -1418.2, 31.2, 72.0),
        finish        = vector3(-799.4, -1791.6, 27.7),
        radius        = 10.0,
        time          = 240,
        buyInPinkslip = 15000,
        buyInPot      = 2500,
        vehicles      = { 'dominator', 'gauntlet', 'sabregt', 'nightshade' },
        spawns = {
            vector4(-220.1, -1422.6, 31.2, 65.0),
            vector4(-222.9, -1419.4, 31.2, 68.0),
            vector4(-225.6, -1416.1, 31.2, 71.0),
            vector4(-228.4, -1412.9, 31.2, 74.0),
            vector4(-231.1, -1409.6, 31.2, 77.0),
            vector4(-233.9, -1406.3, 31.2, 80.0),
        },
    },
}