local QBCore = exports['qb-core']:GetCoreObject()

-- Locations[i]      = merged config.lua + SQL location table (see BuildLocationsList)
-- LocationsByKey[k] = same entries, keyed by a stable string ('c'<configIndex> or 'd'<dbId>)
--                     so player progress / stock never gets orphaned by an admin edit.
-- Stock[key][slot]  = { model, props, source ('config'|'captured'), entity, netId, spawned, seeding,
--                        pendingColors ({color1, color2, windowTint, key}, set only while a fresh
--                        config-sourced car's mods are still being seeded - see EnsurePendingLotColors) }
-- activeRace[src]   = { locKey, raceType, slotIndex, buyIn, plate, model, startTime, timeLimit }
local Locations = {}
local LocationsByKey = {}
local locationsReady = false
local Stock = {}
local activeRace = {}

-- Every server-spawned lot/stock vehicle gets a state bag flag (see requestStockSpawn below) so
-- a leftover from before a resource restart can be found and removed (see onResourceStart)
-- without relying on a special plate format - plates are now just plain random plates like any
-- player's car. State bags live on the entity itself (not in this resource's Lua memory), so the
-- flag is still there to read back after the resource - and this file - restarts.
-- NOTE: the Decor* natives (DecorRegister/DecorSetBool/DecorExistOn) are client-only and don't
-- exist server-side at all, which is why an earlier version of this used those and crashed with
-- "attempt to call a nil value (global 'DecorRegister')" the moment the resource started.

-- ===================================================================
-- SCHEMA
-- ===================================================================
local function EnsureSchema()
    local ok, err = pcall(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `mnc_pinkslips_locations` (
              `id` INT NOT NULL AUTO_INCREMENT,
              `label` VARCHAR(50) NOT NULL,
              `class` VARCHAR(30) NOT NULL,
              `start_x` FLOAT NOT NULL, `start_y` FLOAT NOT NULL, `start_z` FLOAT NOT NULL, `start_w` FLOAT NOT NULL,
              `finish_x` FLOAT NOT NULL, `finish_y` FLOAT NOT NULL, `finish_z` FLOAT NOT NULL,
              `radius` FLOAT NOT NULL DEFAULT 10.0,
              `time_limit` INT NOT NULL DEFAULT 240,
              `buy_in_pinkslip` INT NOT NULL DEFAULT 15000,
              `buy_in_pot` INT NOT NULL DEFAULT 2500,
              `vehicles` VARCHAR(255) NOT NULL,
              `spawns` LONGTEXT NOT NULL,
              `created_by` VARCHAR(64) DEFAULT NULL,
              `disabled` TINYINT(1) NOT NULL DEFAULT 0,
              `config_index` INT DEFAULT NULL,
              `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`id`),
              UNIQUE KEY `uniq_config_index` (`config_index`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]])
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `mnc_pinkslips_stock` (
              `location_key` VARCHAR(20) NOT NULL,
              `slot_index` INT NOT NULL,
              `model` VARCHAR(50) NOT NULL,
              `plate` VARCHAR(15) DEFAULT NULL,
              `props` LONGTEXT DEFAULT NULL,
              `source` VARCHAR(10) NOT NULL DEFAULT 'config',
              PRIMARY KEY (`location_key`, `slot_index`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]])
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `mnc_pinkslips_progress` (
              `citizenid` VARCHAR(50) NOT NULL,
              `location_key` VARCHAR(20) NOT NULL,
              `unlocked_slots` INT NOT NULL DEFAULT 1,
              `pinkslips_used` INT NOT NULL DEFAULT 0,
              `pot_progress` INT NOT NULL DEFAULT 0,
              PRIMARY KEY (`citizenid`, `location_key`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]])
    end)
    if not ok then
        print('[mnc-pinkslips] Could not auto-create tables (missing CREATE privilege?). Run install.sql manually. Error: ' .. tostring(err))
    end

    -- lightweight migration for installs from before the `plate` column existed - the CREATE
    -- TABLE above already includes it for fresh installs, this just backfills older ones.
    -- Expected to fail (duplicate column) on every restart after the first, so it's silent.
    pcall(function()
        MySQL.query.await('ALTER TABLE `mnc_pinkslips_stock` ADD COLUMN `plate` VARCHAR(15) DEFAULT NULL')
    end)

    return ok
end

-- ===================================================================
-- HELPERS
-- ===================================================================
local function IsDbTrue(v)
    return v == 1 or v == true
end

local function ParseVehiclesCsv(raw)
    local vehicles = {}
    for v in (raw or ''):gmatch('([^,]+)') do
        local trimmed = v:match('^%s*(.-)%s*$')
        if trimmed ~= '' then vehicles[#vehicles + 1] = trimmed:lower() end
    end
    return vehicles
end

local function ParseSpawnsJson(raw)
    local ok, decoded = pcall(json.decode, raw or '[]')
    if not ok or type(decoded) ~= 'table' then return {} end
    local spawns = {}
    for _, s in ipairs(decoded) do
        if s.x and s.y and s.z and s.w then
            spawns[#spawns + 1] = vector4(tonumber(s.x), tonumber(s.y), tonumber(s.z), tonumber(s.w))
        end
    end
    return spawns
end

local function EncodeSpawnsJson(spawns)
    local list = {}
    for _, s in ipairs(spawns) do
        list[#list + 1] = { x = s.x, y = s.y, z = s.z, w = s.w }
    end
    return json.encode(list)
end

local function BuildStockSummary(locKey)
    local list = {}
    local slots = Stock[locKey] or {}
    for i, s in pairs(slots) do
        if s.model then
            local data = QBCore.Shared.Vehicles[s.model]
            list[#list + 1] = { slotIndex = i, model = s.model, label = (data and data.name) or s.model, source = s.source }
        end
    end
    table.sort(list, function(a, b) return a.slotIndex < b.slotIndex end)
    return list
end

-- ===================================================================
-- LOCATIONS  (config.lua defaults merged with SQL overrides/admin additions)
-- ===================================================================
local function BuildLocationsList()
    local list = {}

    local ok, rows = pcall(function()
        return MySQL.query.await('SELECT * FROM mnc_pinkslips_locations ORDER BY id ASC')
    end)
    if not ok or not rows then
        rows = {}
        print('[mnc-pinkslips] Could not load saved locations from SQL. Continuing with config.lua locations only.')
    end

    local overrides, sqlLocations = {}, {}
    for _, row in ipairs(rows) do
        if row.config_index then
            overrides[row.config_index] = row
        else
            sqlLocations[#sqlLocations + 1] = row
        end
    end

    -- config.lua defaults always get a stable slot (even disabled), so every other index stays stable
    for i, cfgLoc in ipairs(Config.Locations) do
        local override = overrides[i]
        if override and IsDbTrue(override.disabled) then
            list[i] = { disabled = true, configIndex = i, dbId = override.id, fromConfig = true }
        elseif override then
            local vehicles = ParseVehiclesCsv(override.vehicles)
            local spawns = ParseSpawnsJson(override.spawns)
            list[i] = {
                label         = override.label,
                class         = override.class,
                start         = vector4(override.start_x, override.start_y, override.start_z, override.start_w),
                finish        = vector3(override.finish_x, override.finish_y, override.finish_z),
                radius        = override.radius,
                time          = override.time_limit,
                buyInPinkslip = override.buy_in_pinkslip,
                buyInPot      = override.buy_in_pot,
                vehicles      = #vehicles > 0 and vehicles or cfgLoc.vehicles,
                spawns        = #spawns > 0 and spawns or cfgLoc.spawns,
                configIndex   = i,
                dbId          = override.id,
                fromConfig    = true,
            }
        else
            list[i] = {
                label         = cfgLoc.label,
                class         = cfgLoc.class,
                start         = cfgLoc.start,
                finish        = cfgLoc.finish,
                radius        = cfgLoc.radius,
                time          = cfgLoc.time,
                buyInPinkslip = cfgLoc.buyInPinkslip,
                buyInPot      = cfgLoc.buyInPot,
                vehicles      = cfgLoc.vehicles,
                spawns        = cfgLoc.spawns,
                configIndex   = i,
                fromConfig    = true,
            }
        end
    end

    for _, row in ipairs(sqlLocations) do
        if not IsDbTrue(row.disabled) then
            local vehicles = ParseVehiclesCsv(row.vehicles)
            local spawns = ParseSpawnsJson(row.spawns)
            if #vehicles > 0 and #spawns > 0 then
                list[#list + 1] = {
                    label         = row.label,
                    class         = row.class,
                    start         = vector4(row.start_x, row.start_y, row.start_z, row.start_w),
                    finish        = vector3(row.finish_x, row.finish_y, row.finish_z),
                    radius        = row.radius,
                    time          = row.time_limit,
                    buyInPinkslip = row.buy_in_pinkslip,
                    buyInPot      = row.buy_in_pot,
                    vehicles      = vehicles,
                    spawns        = spawns,
                    dbId          = row.id,
                }
            end
        end
    end

    return list
end

local function RebuildLocationsByKey()
    LocationsByKey = {}
    for _, loc in ipairs(Locations) do
        if not loc.disabled then
            loc.key = loc.fromConfig and ('c' .. loc.configIndex) or ('d' .. loc.dbId)
            LocationsByKey[loc.key] = loc
        end
    end
end

-- ===================================================================
-- STOCK  (the parked vehicles waiting to be raced for at each location)
-- ===================================================================
local function LoadStockFromDb()
    local ok, rows = pcall(function()
        return MySQL.query.await('SELECT * FROM mnc_pinkslips_stock')
    end)
    if not ok or not rows then return end
    for _, row in ipairs(rows) do
        Stock[row.location_key] = Stock[row.location_key] or {}
        local props = nil
        if row.props and row.props ~= '' then
            local pok, decoded = pcall(json.decode, row.props)
            if pok and type(decoded) == 'table' then props = decoded end
        end
        Stock[row.location_key][row.slot_index] = { model = row.model, plate = row.plate, props = props, source = row.source }
    end
end

local function EnsureStockSlot(locKey, loc, slotIndex, broadcast)
    Stock[locKey] = Stock[locKey] or {}
    if Stock[locKey][slotIndex] and Stock[locKey][slotIndex].model then return end

    local model = loc.vehicles[math.random(#loc.vehicles)]
    Stock[locKey][slotIndex] = { model = model, plate = nil, props = nil, source = 'config' }

    MySQL.query.await(
        'REPLACE INTO mnc_pinkslips_stock (location_key, slot_index, model, plate, props, source) VALUES (?, ?, ?, NULL, NULL, ?)',
        { locKey, slotIndex, model, 'config' }
    )

    if broadcast then
        TriggerClientEvent('mnc-pinkslips:client:setStock', -1, locKey, BuildStockSummary(locKey))
    end
end

local function DespawnStockVehicle(locKey, slotIndex)
    local stock = Stock[locKey] and Stock[locKey][slotIndex]
    if stock and stock.entity and DoesEntityExist(stock.entity) then
        DeleteEntity(stock.entity)
    end
    if stock then
        stock.entity = nil
        stock.netId = nil
        stock.spawned = false
    end
    TriggerClientEvent('mnc-pinkslips:client:stockDespawned', -1, locKey, slotIndex)
end

-- when a player loses a pinkslip race, their car needs a home: prefer an empty spot,
-- otherwise evict a generic config-seeded filler before ever touching another captured car
local function FindSlotForCapturedVehicle(locKey, loc)
    local slotCount = #loc.spawns
    Stock[locKey] = Stock[locKey] or {}
    for i = 1, slotCount do
        if not (Stock[locKey][i] and Stock[locKey][i].model) then
            return i
        end
    end
    for i = 1, slotCount do
        if Stock[locKey][i].source == 'config' then
            return i
        end
    end
    return math.random(1, slotCount)
end

-- ===================================================================
-- LOT APPEARANCE DISTINCTION  (so duplicate show-vehicle models don't look identical on the lot)
-- ===================================================================
-- Config-seeded lot cars are "fully built": every performance mod slot (Engine/Brakes/
-- Transmission/Suspension/Armour) is always maxed out on every car of a given model, for race
-- fairness - which car you get shouldn't matter, only how you drive it. Everything else -
-- colour, window tint, and which specific part is installed in each of the 11 cosmetic body-kit
-- slots (Spoiler, Bumpers, Skirt, Exhaust, Frame, Grille, Hood, Fenders, Roof) - now varies per
-- car instead of always landing on the same combination, and is guaranteed distinct from any
-- other config-sourced (never-raced-for) show vehicle of the same model at the same location.
-- Captured (player-lost) stock is excluded entirely from all of this - it keeps whatever
-- mods/colour the player already had and is never touched by ApplyRandomLotMods in the first
-- place.
local ReservedLotColors = {} -- ReservedLotColors[locKey][model] = { ['c1:c2:tint'] = true, ... }
local LOT_COLOR_MAX_ATTEMPTS = 40

-- Cosmetic mod type IDs, in the same order/meaning as client.lua's COSMETIC_MOD_TYPES - keep the
-- two lists in sync. COSMETIC_MOD_FIELDS maps each to the field QBCore.Functions.GetVehicleProperties
-- stores it under, so a captured props blob can be read back into a signature keyed by mod type.
local COSMETIC_MOD_TYPES = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
local COSMETIC_MOD_FIELDS = {
    [0] = 'modSpoilers',    [1] = 'modFrontBumper', [2] = 'modRearBumper', [3] = 'modSideSkirt',
    [4] = 'modExhaust',     [5] = 'modFrame',        [6] = 'modGrille',     [7] = 'modHood',
    [8] = 'modFender',      [9] = 'modRightFender', [10] = 'modRoof',
}

local function ExtractCosmeticSignature(props)
    local sig = {}
    for _, modType in ipairs(COSMETIC_MOD_TYPES) do
        sig[modType] = props[COSMETIC_MOD_FIELDS[modType]]
    end
    return sig
end

local function CosmeticSignaturesEqual(a, b)
    for _, modType in ipairs(COSMETIC_MOD_TYPES) do
        if (a[modType] or -1) ~= (b[modType] or -1) then return false end
    end
    return true
end

-- every OTHER config-sourced same-model car's cosmetic signature at this location, handed to the
-- seeding client so it can avoid rolling an exact duplicate (see client.lua ApplyVariedCosmeticMods).
-- Unlike colours there's no reservation system here - the combination space (11 slots, each with
-- however many options that model has) is large enough that two duplicates finishing their seed
-- in the very same tick and rolling identical results is not a realistic concern.
local function CollectCosmeticAvoidList(locKey, model, excludeSlot)
    local list = {}
    local slots = Stock[locKey] or {}
    for i, s in pairs(slots) do
        if i ~= excludeSlot and s.model == model and s.source == 'config' and s.props then
            list[#list + 1] = ExtractCosmeticSignature(s.props)
        end
    end
    return list
end

-- true if some player is mid-race for this exact pinkslip slot right now - reconciliation must
-- never wipe a car out from under an active claim (see ReconcileLotVariety)
local function IsSlotBeingRaced(locKey, slotIndex)
    for _, race in pairs(activeRace) do
        if race.locKey == locKey and race.slotIndex == slotIndex then return true end
    end
    return false
end

local function LotColorKey(c1, c2, tint)
    return c1 .. ':' .. c2 .. ':' .. tint
end

local function CollectUsedLotColorKeys(locKey, model, excludeSlot)
    local used = {}
    local slots = Stock[locKey] or {}
    for i, s in pairs(slots) do
        if i ~= excludeSlot and s.model == model and s.source == 'config' and s.props
            and s.props.color1 ~= nil and s.props.color2 ~= nil then
            used[LotColorKey(s.props.color1, s.props.color2, s.props.windowTint or -1)] = true
        end
    end
    local reserved = ReservedLotColors[locKey] and ReservedLotColors[locKey][model]
    if reserved then
        for key in pairs(reserved) do used[key] = true end
    end
    return used
end

local function ReserveLotColorKey(locKey, model, key)
    ReservedLotColors[locKey] = ReservedLotColors[locKey] or {}
    ReservedLotColors[locKey][model] = ReservedLotColors[locKey][model] or {}
    ReservedLotColors[locKey][model][key] = true
end

local function ReleaseLotColorKey(locKey, model, key)
    local m = ReservedLotColors[locKey] and ReservedLotColors[locKey][model]
    if m then m[key] = nil end
end

-- rolls a colour/tint combo that no OTHER config-sourced stock car of the same model at this
-- location is already using (or currently mid-seed reserving) - bounded so a saturated colour
-- space never hangs, though at up to 160*160*7 combos that's not realistically reachable
local function GenerateDistinctLotColors(locKey, model, excludeSlot)
    local used = CollectUsedLotColorKeys(locKey, model, excludeSlot)
    local c1, c2, tint, key
    for _ = 1, LOT_COLOR_MAX_ATTEMPTS do
        c1, c2, tint = math.random(0, 159), math.random(0, 159), math.random(0, 6)
        key = LotColorKey(c1, c2, tint)
        if not used[key] then break end
    end
    ReserveLotColorKey(locKey, model, key)
    return { color1 = c1, color2 = c2, windowTint = tint, key = key }
end

-- returns the already-reserved colours for a slot that's still mid-seed (e.g. a car_not_ready
-- retry, or a respawn after a distance-based despawn interrupted the first attempt), or rolls
-- and reserves a fresh set the first time this slot is ever seeded
local function EnsurePendingLotColors(locKey, slotIndex)
    local stock = Stock[locKey] and Stock[locKey][slotIndex]
    if not stock then return nil end
    if stock.pendingColors then return stock.pendingColors end
    local colors = GenerateDistinctLotColors(locKey, stock.model, slotIndex)
    stock.pendingColors = colors
    return colors
end

-- The above only stops NEW duplicates when a car is seeded for the very first time - it can't do
-- anything for stock that was already spawned and captured (props saved to mnc_pinkslips_stock)
-- before this dedup logic existed, or for any other reason two same-model config cars already
-- ended up looking the same. This fixes those up retroactively: called once per location right
-- after stock loads (see BOOTSTRAP below), again after an admin edits a location, and on demand
-- via /pinkslips_fixvariety, it finds every config-sourced slot whose colour+tint OR cosmetic mod
-- signature exactly matches an earlier slot of the same model, and wipes just the later one so it
-- re-seeds itself from scratch the next time a player streams it in - through the exact same
-- pipeline above, so the replacement is guaranteed distinct too. This deliberately doesn't try to
-- patch mods onto a possibly-already-spawned entity in place: cosmetic mod counts are model-
-- specific and only queryable client-side (GetNumVehicleMods), so "delete the DB row/despawn/let
-- EnsureStockSlot reseed it" is the simplest thing that's guaranteed to work whether or not the
-- car is currently spawned or even streamed to anyone. The replacement may land on a different
-- model entirely (EnsureStockSlot picks fresh from the location's vehicle pool) - that's fine, it
-- still resolves the collision either way. The first slot of a given model (by slot index) always
-- keeps its existing car; only later collisions get replaced.
local function ReconcileLotVariety(locKey, loc)
    local slots = Stock[locKey]
    if not slots then return end

    local byModel = {}
    for i, s in pairs(slots) do
        if s.model and s.source == 'config' and s.props then
            byModel[s.model] = byModel[s.model] or {}
            byModel[s.model][#byModel[s.model] + 1] = i
        end
    end

    for model, slotIndexes in pairs(byModel) do
        if #slotIndexes > 1 then
            table.sort(slotIndexes)
            for n = 2, #slotIndexes do
                local i = slotIndexes[n]
                local stock = slots[i]
                if not IsSlotBeingRaced(locKey, i) then
                    local myColorKey = LotColorKey(stock.props.color1, stock.props.color2, stock.props.windowTint or -1)
                    local mySig = ExtractCosmeticSignature(stock.props)
                    local collides = false

                    for m = 1, n - 1 do
                        local other = slots[slotIndexes[m]]
                        if other.props then
                            local otherColorKey = LotColorKey(other.props.color1, other.props.color2, other.props.windowTint or -1)
                            if otherColorKey == myColorKey or CosmeticSignaturesEqual(mySig, ExtractCosmeticSignature(other.props)) then
                                collides = true
                                break
                            end
                        end
                    end

                    if collides then
                        DespawnStockVehicle(locKey, i)
                        MySQL.query.await('DELETE FROM mnc_pinkslips_stock WHERE location_key = ? AND slot_index = ?', { locKey, i })
                        slots[i] = nil
                        EnsureStockSlot(locKey, loc, i, true)
                    end
                end
            end
        end
    end
end

-- ===================================================================
-- PLAYER PROGRESS  (per citizenid, per location)
-- ===================================================================
local function GetOrCreateProgress(citizenid, locKey)
    local row = MySQL.single.await('SELECT * FROM mnc_pinkslips_progress WHERE citizenid = ? AND location_key = ?', { citizenid, locKey })
    if row then return row end
    MySQL.insert.await('INSERT INTO mnc_pinkslips_progress (citizenid, location_key) VALUES (?, ?)', { citizenid, locKey })
    return { citizenid = citizenid, location_key = locKey, unlocked_slots = 1, pinkslips_used = 0, pot_progress = 0 }
end

local function IncrementPinkslipsUsed(citizenid, locKey)
    MySQL.update.await('UPDATE mnc_pinkslips_progress SET pinkslips_used = pinkslips_used + 1 WHERE citizenid = ? AND location_key = ?', { citizenid, locKey })
end

-- returns true if a new pinkslip attempt was unlocked
local function AddPotProgress(citizenid, locKey, progress)
    local newProgress = progress.pot_progress + 1
    if newProgress >= Config.Progression.RacesToUnlockNext and progress.unlocked_slots < Config.Progression.MaxPinkslipsPerLocation then
        MySQL.update.await(
            'UPDATE mnc_pinkslips_progress SET pot_progress = 0, unlocked_slots = unlocked_slots + 1 WHERE citizenid = ? AND location_key = ?',
            { citizenid, locKey }
        )
        return true
    end
    MySQL.update.await('UPDATE mnc_pinkslips_progress SET pot_progress = ? WHERE citizenid = ? AND location_key = ?', { newProgress, citizenid, locKey })
    return false
end

-- ===================================================================
-- PLATES
-- ===================================================================
local function RandomPlate()
    local chars = Config.Plate.Charset
    local len = #chars
    local out = {}
    for i = 1, Config.Plate.Length do
        local idx = math.random(1, len)
        out[i] = chars:sub(idx, idx)
    end
    return table.concat(out)
end

local function PlateExists(plate)
    return MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ?', { plate }) ~= nil
end

-- checked against player_vehicles so a winner (or a freshly seeded lot car) never gets handed
-- a plate that's already in use. This is the ONLY plate generator in the resource now - there is
-- no separate cosmetic "show plate"/prefix scheme for lot cars any more.
local function GenerateUniquePlate()
    for _ = 1, Config.Plate.MaxGenerateAttempts do
        local plate = RandomPlate()
        if not PlateExists(plate) then return plate end
    end
    return nil
end

-- ===================================================================
-- OWNERSHIP / CLASS CHECKS
-- ===================================================================
local function PlayerOwnsVehicle(citizenid, plate)
    local row = MySQL.single.await('SELECT plate FROM player_vehicles WHERE citizenid = ? AND plate = ?', { citizenid, plate })
    return row ~= nil
end

local vehicleHashToName = nil
local function GetModelNameFromHash(hash)
    if not vehicleHashToName then
        vehicleHashToName = {}
        for name, _ in pairs(QBCore.Shared.Vehicles) do
            vehicleHashToName[GetHashKey(name)] = name
        end
    end
    return vehicleHashToName[hash]
end

local function GetVehicleClassOk(model, class)
    local data = QBCore.Shared.Vehicles[model]
    return data ~= nil and data.category == class
end

-- ===================================================================
-- PAYOUT
-- ===================================================================
-- Winning either race type returns the player's own buy-in PLUS a matching "house"/NPC buy-in of
-- the same amount (2x buy-in total), on top of a time-weighted bonus. A pinkslip win additionally
-- hands over the wagered-for vehicle; a pot race never stakes or awards a vehicle at all - see
-- CalculatePotBonus below.
local function CalculateTimeWeightedBonus(value, elapsedSeconds, timeLimit, basePercent, minPercent, maxPercent)
    local p = Config.Payout
    local timeRatio = math.max(0, math.min(1, (elapsedSeconds or timeLimit) / timeLimit))
    local timeFactor = 1 - (timeRatio * p.TimeBonusWeight)
    local payoutPercent = basePercent * timeFactor
    payoutPercent = math.max(minPercent, math.min(maxPercent, payoutPercent))
    return math.floor(value * payoutPercent)
end

local function CalculatePinkslipBonus(vehicleValue, elapsedSeconds, timeLimit)
    local p = Config.Payout
    return CalculateTimeWeightedBonus(vehicleValue, elapsedSeconds, timeLimit, p.PinkslipBasePercent, p.PinkslipMinPercent, p.PinkslipMaxPercent)
end

-- pot races have no vehicle to value the bonus off of, so it's the same time-weighted % band
-- applied to the buy-in itself instead
local function CalculatePotBonus(buyIn, elapsedSeconds, timeLimit)
    local p = Config.Payout
    return CalculateTimeWeightedBonus(buyIn, elapsedSeconds, timeLimit, p.PotBasePercent, p.PotMinPercent, p.PotMaxPercent)
end

-- the player's own buy-in back, plus a matching buy-in from "the house"/NPC side, plus the bonus
local function CalculateRacePayout(buyIn, bonus)
    return (buyIn * 2) + bonus
end

-- ===================================================================
-- BOOTSTRAP
-- ===================================================================
CreateThread(function()
    EnsureSchema()
    Locations = BuildLocationsList()
    RebuildLocationsByKey()
    LoadStockFromDb()

    for _, loc in ipairs(Locations) do
        if not loc.disabled then
            for i = 1, #loc.spawns do
                EnsureStockSlot(loc.key, loc, i, false)
            end
            -- fix up any same-model duplicates that were already captured/persisted looking
            -- identical before this resource start (see ReconcileLotVariety)
            ReconcileLotVariety(loc.key, loc)
        end
    end

    locationsReady = true

    local stockMap = {}
    for key, _ in pairs(LocationsByKey) do
        stockMap[key] = BuildStockSummary(key)
    end
    TriggerClientEvent('mnc-pinkslips:client:setLocations', -1, Locations, stockMap)
end)

RegisterNetEvent('mnc-pinkslips:server:requestLocations', function()
    local src = source

    if not locationsReady then
        -- Bootstrap hasn't finished yet (e.g. this player was already connected when the
        -- resource was `ensure`d and reconnected client-side faster than the server-side
        -- DB queries finished). Don't queue up our own delayed send here - the bootstrap
        -- thread already broadcasts setLocations to every currently-connected client (-1)
        -- the moment locationsReady flips true, and that broadcast includes this player.
        -- Sending here too used to double-fire setLocations at this client, which double
        -- triggered the stock-vehicle streaming logic and spawned every lot vehicle twice.
        return
    end

    local stockMap = {}
    for key, _ in pairs(LocationsByKey) do
        stockMap[key] = BuildStockSummary(key)
    end
    TriggerClientEvent('mnc-pinkslips:client:setLocations', src, Locations, stockMap)
end)

-- ===================================================================
-- STOCK STREAMING  (distance based, mirrors mnc-cardelivery's vehicle streaming)
-- ===================================================================
RegisterNetEvent('mnc-pinkslips:server:requestStockSpawn', function(locKey, slotIndex)
    local src = source
    local loc = LocationsByKey[locKey]
    local stock = Stock[locKey] and Stock[locKey][slotIndex]
    if not loc or not stock or not stock.model or stock.spawned or stock.seeding then return end

    local spawnPoint = loc.spawns[slotIndex]
    if not spawnPoint then return end

    stock.seeding = true

    local modelHash = GetHashKey(stock.model)
    -- Spawn above the configured point - it falls and settles onto the real ground in the
    -- background below, instead of snapping straight to spawnPoint.z and freezing immediately,
    -- which was leaving some lot cars floating and others clipped into the ground (a hand-placed
    -- spawn vector's z doesn't always match the terrain exactly).
    local heightOffset = Config.Streaming.SpawnHeightOffset or 0
    local veh = CreateVehicleServerSetter(modelHash, 'automobile', spawnPoint.x, spawnPoint.y, spawnPoint.z + heightOffset, spawnPoint.w)

    local attempts = 0
    while not DoesEntityExist(veh) and attempts < 50 do
        Wait(50)
        attempts = attempts + 1
    end

    if not DoesEntityExist(veh) then
        stock.seeding = false
        return
    end

    -- captured (player-lost) stock keeps the plate it already had, so its saved mods/props
    -- (which include that same plate) keep matching the entity. A fresh config-seeded car gets
    -- a brand new plate from the same generator used for pinkslip winners, checked against
    -- player_vehicles so it can't clash with a real player's plate, and that plate is
    -- remembered for the life of this stock slot.
    local plate = stock.plate or (stock.props and stock.props.plate)
    local isNewPlate = not plate
    if not plate then
        plate = GenerateUniquePlate()
        if not plate then
            print(('[mnc-pinkslips] Could not generate a unique plate for %s slot %d after %d attempts - vehicle spawn skipped.'):format(locKey, slotIndex, Config.Plate.MaxGenerateAttempts))
            DeleteEntity(veh)
            stock.seeding = false
            return
        end
    end
    stock.plate = plate

    SetVehicleNumberPlateText(veh, plate)
    Entity(veh).state:set('mncPinkslipStock', true, false) -- tag it so a leftover from before a restart can be cleaned up (see onResourceStart)
    -- SET_ENTITY_INVINCIBLE is a client-only native - calling it here threw "attempt to call
    -- a nil value" and killed the rest of this handler before stock.spawned/props/mods ever
    -- got set up. Each client sets it locally instead (see client:stockSpawned).

    if isNewPlate then
        MySQL.query.await('UPDATE mnc_pinkslips_stock SET plate = ? WHERE location_key = ? AND slot_index = ?', { plate, locKey, slotIndex })
    end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    stock.entity = veh
    stock.netId = netId
    stock.spawned = true
    stock.seeding = false

    -- notify clients about the new stock / kick off mod-seeding straight away, same as before -
    -- none of that should wait on the vehicle settling onto the ground below
    TriggerClientEvent('mnc-pinkslips:client:stockSpawned', -1, locKey, slotIndex, netId, stock.model)

    if stock.props then
        TriggerClientEvent('mnc-pinkslips:client:applyStockProps', src, netId, stock.props)
    else
        -- never captured before (fresh config seed) - let the requesting client randomize it
        -- once and report back what it looks like so every future respawn stays consistent.
        -- propsPending lets completeRace tell "still waiting on that round trip" apart from
        -- "never captured and never will be" if a player wins the race before it lands.
        -- The colour/tint combo is rolled and reserved here (server-side) rather than left to the
        -- client, so it can be guaranteed distinct from any other config-sourced car of the same
        -- model already on this lot (see EnsurePendingLotColors). The cosmetic mod slots can't be
        -- pre-generated server-side (GetNumVehicleMods is client-only), so instead the client gets
        -- a list of what every sibling already looks like and avoids rolling an exact match (see
        -- CollectCosmeticAvoidList / client.lua ApplyVariedCosmeticMods).
        stock.propsPending = true
        local colors = EnsurePendingLotColors(locKey, slotIndex)
        local cosmeticAvoid = CollectCosmeticAvoidList(locKey, stock.model, slotIndex)
        TriggerClientEvent('mnc-pinkslips:client:seedStockProps', src, locKey, slotIndex, netId, colors, cosmeticAvoid)
    end

    -- let it fall (unfrozen) then settle before fixing it flush to the ground and freezing it in
    -- place - run in the background so none of the above (plate/mods/broadcasts) waits on it
    CreateThread(function()
        Wait(Config.Streaming.SpawnFallTime or 1000)   -- fall
        Wait(Config.Streaming.SpawnSettleTime or 2000) -- settle

        if not DoesEntityExist(veh) then return end -- despawned or otherwise gone while settling

        SetEntityHeading(veh, spawnPoint.w)
        SetVehicleOnGroundProperly(veh) -- fix: snap it flush to whatever it settled on
        FreezeEntityPosition(veh, true) -- freeze: lock it in its settled, corrected spot
    end)
end)

RegisterNetEvent('mnc-pinkslips:server:requestStockDespawn', function(locKey, slotIndex)
    local stock = Stock[locKey] and Stock[locKey][slotIndex]
    if stock and stock.spawned then
        DespawnStockVehicle(locKey, slotIndex)
    end
end)

RegisterNetEvent('mnc-pinkslips:server:capturedInitialProps', function(locKey, slotIndex, props)
    local stock = Stock[locKey] and Stock[locKey][slotIndex]
    if not stock or stock.props or type(props) ~= 'table' then return end -- first responder wins
    stock.props = props
    stock.propsPending = nil
    if stock.pendingColors then
        -- now permanently reflected in stock.props itself (CollectUsedLotColorKeys reads that
        -- too), so the temporary reservation can be released
        ReleaseLotColorKey(locKey, stock.model, stock.pendingColors.key)
        stock.pendingColors = nil
    end
    MySQL.update.await('UPDATE mnc_pinkslips_stock SET props = ? WHERE location_key = ? AND slot_index = ?', { json.encode(props), locKey, slotIndex })
end)

-- ===================================================================
-- MENU DATA
-- ===================================================================
QBCore.Functions.CreateCallback('mnc-pinkslips:server:getMenuData', function(source, cb, locKey)
    local src = source
    local loc = LocationsByKey[locKey]
    if not loc then cb(nil) return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then cb(nil) return end

    local progress = GetOrCreateProgress(Player.PlayerData.citizenid, locKey)

    cb({
        label         = loc.label,
        class         = loc.class,
        buyInPinkslip = loc.buyInPinkslip,
        buyInPot      = loc.buyInPot,
        unlockedSlots = progress.unlocked_slots,
        pinkslipsUsed = progress.pinkslips_used,
        maxSlots      = Config.Progression.MaxPinkslipsPerLocation,
        potProgress   = progress.pot_progress,
        potGoal       = Config.Progression.RacesToUnlockNext,
        stock         = BuildStockSummary(locKey),
    })
end)

-- ===================================================================
-- RACE CLAIM  (buy in, lock the attempt, hand the client its race parameters)
-- ===================================================================
QBCore.Functions.CreateCallback('mnc-pinkslips:server:claimRace', function(source, cb, locKey, raceType, slotIndex)
    local src = source

    if activeRace[src] then cb({ success = false, reason = 'already_racing' }) return end

    local loc = LocationsByKey[locKey]
    if not loc then cb({ success = false, reason = 'invalid_location' }) return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then cb({ success = false, reason = 'no_player' }) return end

    local ped = GetPlayerPed(src)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
        cb({ success = false, reason = 'not_driving' })
        return
    end

    local rawPlate = GetVehicleNumberPlateText(veh) or ''
    local plate = rawPlate:gsub('^%s+', ''):gsub('%s+$', '')
    if plate == '' or not PlayerOwnsVehicle(Player.PlayerData.citizenid, plate) then
        cb({ success = false, reason = 'not_owned' })
        return
    end

    local modelName = GetModelNameFromHash(GetEntityModel(veh))
    if not modelName or not GetVehicleClassOk(modelName, loc.class) then
        cb({ success = false, reason = 'wrong_class' })
        return
    end

    local buyIn
    if raceType == 'pinkslip' then
        local progress = GetOrCreateProgress(Player.PlayerData.citizenid, locKey)
        if progress.pinkslips_used >= progress.unlocked_slots then
            cb({ success = false, reason = 'no_slip_unlocked' })
            return
        end
        local stock = Stock[locKey] and Stock[locKey][slotIndex]
        if not stock or not stock.model then
            cb({ success = false, reason = 'no_car' })
            return
        end
        if not stock.props then
            -- mods for this car haven't finished being captured yet (it just spawned, or the
            -- original seed round-trip never made it back) - never hand out a win with no
            -- mods. Kick off (or retry) seeding via this player's own client, since they're
            -- right here and about to race for it, then ask them to try again shortly.
            if stock.entity and DoesEntityExist(stock.entity) then
                local now = GetGameTimer()
                if not stock.seedRetryAt or now >= stock.seedRetryAt then
                    stock.seedRetryAt = now + 4000
                    local colors = EnsurePendingLotColors(locKey, slotIndex)
                    local cosmeticAvoid = CollectCosmeticAvoidList(locKey, stock.model, slotIndex)
                    TriggerClientEvent('mnc-pinkslips:client:seedStockProps', src, locKey, slotIndex, stock.netId, colors, cosmeticAvoid)
                end
            end
            cb({ success = false, reason = 'car_not_ready' })
            return
        end
        buyIn = loc.buyInPinkslip
    elseif raceType == 'pot' then
        buyIn = loc.buyInPot
        slotIndex = nil
    else
        cb({ success = false, reason = 'bad_type' })
        return
    end

    local money = Player.PlayerData.money[Config.PayoutAccount] or 0
    if money < buyIn then
        cb({ success = false, reason = 'no_money' })
        return
    end

    Player.Functions.RemoveMoney(Config.PayoutAccount, buyIn, 'mnc-pinkslips-buyin')

    activeRace[src] = {
        locKey    = locKey,
        raceType  = raceType,
        slotIndex = slotIndex,
        buyIn     = buyIn,
        plate     = plate,
        model     = modelName,
        startTime = os.time(),
        timeLimit = loc.time,
    }

    local stakeLabel
    if raceType == 'pinkslip' then
        local stockModel = Stock[locKey][slotIndex].model
        local data = QBCore.Shared.Vehicles[stockModel]
        stakeLabel = (data and data.name) or stockModel
    else
        stakeLabel = ('$%d pot'):format(buyIn)
    end

    cb({
        success    = true,
        raceType   = raceType,
        slotIndex  = slotIndex,
        finish     = loc.finish,
        radius     = loc.radius,
        timeLimit  = loc.time,
        stakeLabel = stakeLabel,
    })
end)

-- ===================================================================
-- RACE RESULT
-- ===================================================================
RegisterNetEvent('mnc-pinkslips:server:completeRace', function(elapsed)
    local src = source
    local race = activeRace[src]
    if not race then return end
    activeRace[src] = nil

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local loc = LocationsByKey[race.locKey]
    if not loc then return end

    -- sanity check the claimed elapsed time against the server's own clock (small buffer for latency)
    local serverElapsed = os.time() - race.startTime
    if serverElapsed > race.timeLimit + 5 then
        TriggerClientEvent('mnc-pinkslips:client:raceResult', src, false, race.raceType, 0)
        return
    end

    if race.raceType == 'pinkslip' then
        local stock = Stock[race.locKey] and Stock[race.locKey][race.slotIndex]
        if not stock or not stock.model then
            TriggerClientEvent('mnc-pinkslips:client:raceResult', src, false, 'pinkslip', 0)
            return
        end

        -- mods/props are normally captured within a second of the car first spawning (see
        -- seedStockProps / capturedInitialProps) - long before anyone could actually finish a
        -- timed race for it. This just covers the unlikely case that capture is still mid-flight
        -- right as the race finishes, so a winner doesn't get handed a plain, un-modded car.
        local waited = 0
        while not stock.props and stock.propsPending and waited < 3000 do
            Wait(100)
            waited = waited + 100
        end
        if not stock.props then
            print(('[mnc-pinkslips] Warning: no captured mods/props for %s slot %d at win time (citizenid %s) - the transferred vehicle will be un-modded. This should be rare; if it keeps happening, that stock car is being raced for before its mods ever finished seeding.'):format(race.locKey, race.slotIndex, Player.PlayerData.citizenid))
        end

        local vehicleData = QBCore.Shared.Vehicles[stock.model]
        local vehicleValue = (vehicleData and vehicleData.price) or Config.Payout.DefaultVehicleValue
        local bonus = CalculatePinkslipBonus(vehicleValue, elapsed, race.timeLimit)
        local payout = CalculateRacePayout(race.buyIn, bonus)
        Player.Functions.AddMoney(Config.PayoutAccount, payout, 'mnc-pinkslips-win')

        -- keep whatever plate the car already had on the lot: its own randomly-generated plate
        -- for a fresh config car, or - importantly - the original owner's plate for a car that
        -- was itself won off another player (a "captured" car keeps its plate through to
        -- whoever eventually wins it next, same as the mods/props it was captured with).
        local plate = stock.plate or (stock.props and stock.props.plate)
        if plate and PlateExists(plate) then plate = nil end -- extremely unlikely, but don't hand out a plate that's now in use
        if not plate then plate = GenerateUniquePlate() end
        local vehicleLabel = (vehicleData and vehicleData.name) or stock.model

        if not plate then
            print('[mnc-pinkslips] Could not generate a unique plate after ' .. Config.Plate.MaxGenerateAttempts .. ' attempts - vehicle transfer skipped, player kept the cash payout.')
            TriggerClientEvent('mnc-pinkslips:client:raceResult', src, true, 'pinkslip', payout, nil, false)
        else
            local props = stock.props or {}
            props.plate = plate
            props.model = GetHashKey(stock.model)

            MySQL.insert.await(
                'INSERT INTO player_vehicles (citizenid, vehicle, hash, mods, plate, garage, fuel, engine, body, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                { Player.PlayerData.citizenid, stock.model, GetHashKey(stock.model), json.encode(props), plate, Config.WinGarage, 100, 1000.0, 1000.0, 1 }
            )

            -- ownership row in player_vehicles doesn't register keys by itself - qb-vehiclekeys
            -- tracks that separately, the same way qb-vehicleshop does it on a purchase. If
            -- your qb-vehiclekeys fork listens for a different event/export, swap this line.
            TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)

            DespawnStockVehicle(race.locKey, race.slotIndex)
            MySQL.query.await('DELETE FROM mnc_pinkslips_stock WHERE location_key = ? AND slot_index = ?', { race.locKey, race.slotIndex })
            Stock[race.locKey][race.slotIndex] = nil
            -- let any menu already open elsewhere know this car is gone immediately, rather
            -- than waiting on the reseed broadcast a few seconds from now
            TriggerClientEvent('mnc-pinkslips:client:setStock', -1, race.locKey, BuildStockSummary(race.locKey))

            TriggerClientEvent('mnc-pinkslips:client:raceResult', src, true, 'pinkslip', payout, vehicleLabel, false)

            SetTimeout(5000, function()
                EnsureStockSlot(race.locKey, loc, race.slotIndex, true)
            end)
        end

        GetOrCreateProgress(Player.PlayerData.citizenid, race.locKey)
        IncrementPinkslipsUsed(Player.PlayerData.citizenid, race.locKey)
    elseif race.raceType == 'pot' then
        local bonus = CalculatePotBonus(race.buyIn, elapsed, race.timeLimit)
        local payout = CalculateRacePayout(race.buyIn, bonus)
        Player.Functions.AddMoney(Config.PayoutAccount, payout, 'mnc-pinkslips-pot-win')

        local progress = GetOrCreateProgress(Player.PlayerData.citizenid, race.locKey)
        local unlocked = AddPotProgress(Player.PlayerData.citizenid, race.locKey, progress)

        TriggerClientEvent('mnc-pinkslips:client:raceResult', src, true, 'pot', payout, nil, unlocked)
    end
end)

RegisterNetEvent('mnc-pinkslips:server:failRace', function(props)
    local src = source
    local race = activeRace[src]
    if not race then return end
    activeRace[src] = nil

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local loc = LocationsByKey[race.locKey]

    if race.raceType == 'pinkslip' then
        -- the wagered vehicle is gone - strip ownership, then park it at the location for someone else
        MySQL.query.await('DELETE FROM player_vehicles WHERE citizenid = ? AND plate = ?', { Player.PlayerData.citizenid, race.plate })

        if loc then
            local targetSlot = FindSlotForCapturedVehicle(race.locKey, loc)
            if targetSlot then
                if Stock[race.locKey][targetSlot] and Stock[race.locKey][targetSlot].model then
                    DespawnStockVehicle(race.locKey, targetSlot)
                end

                local capturedProps = (type(props) == 'table') and props or nil
                -- keep the plate the vehicle already had as the player's car, so it (and its
                -- saved mods, which travel with the same props blob) stay attached to it
                local capturedPlate = (capturedProps and capturedProps.plate) or race.plate
                Stock[race.locKey][targetSlot] = { model = race.model, plate = capturedPlate, props = capturedProps, source = 'captured' }

                MySQL.query.await(
                    'REPLACE INTO mnc_pinkslips_stock (location_key, slot_index, model, plate, props, source) VALUES (?, ?, ?, ?, ?, ?)',
                    { race.locKey, targetSlot, race.model, capturedPlate, json.encode(capturedProps or {}), 'captured' }
                )

                TriggerClientEvent('mnc-pinkslips:client:setStock', -1, race.locKey, BuildStockSummary(race.locKey))
            end
        end

        GetOrCreateProgress(Player.PlayerData.citizenid, race.locKey)
        IncrementPinkslipsUsed(Player.PlayerData.citizenid, race.locKey)

        TriggerClientEvent('mnc-pinkslips:client:raceResult', src, false, 'pinkslip', 0)
        TriggerClientEvent('mnc-pinkslips:client:forfeitVehicle', src, race.plate)
    else
        if Config.Progression.CountLossesTowardUnlock then
            local progress = GetOrCreateProgress(Player.PlayerData.citizenid, race.locKey)
            local unlocked = AddPotProgress(Player.PlayerData.citizenid, race.locKey, progress)
            TriggerClientEvent('mnc-pinkslips:client:raceResult', src, false, 'pot', 0, nil, unlocked)
        else
            TriggerClientEvent('mnc-pinkslips:client:raceResult', src, false, 'pot', 0)
        end
    end
end)

-- release the buy-in lock if a player disconnects mid-race (they've already paid - that's the risk of racing)
AddEventHandler('playerDropped', function()
    local src = source
    activeRace[src] = nil
end)

-- ===================================================================
-- ADMIN: LOCATION BUILDER (/setuppinkslips)
-- ===================================================================
RegisterCommand(Config.Admin.Command, function(source)
    local src = source
    if src == 0 then return end
    if not IsPlayerAceAllowed(src, Config.Admin.AcePermission) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access denied', description = 'You do not have permission to do this.', type = 'error' })
        return
    end
    TriggerClientEvent('mnc-pinkslips:client:openSetupUI', src)
end, false)

-- Forces the same-model appearance dedup (ReconcileLotVariety) to re-run right now against every
-- location, without needing a full resource restart. Console-only (or an in-game admin with the
-- ace permission) - useful for checking the fix took effect, or for cleaning up an existing lot
-- immediately after updating this resource rather than waiting for the next restart.
RegisterCommand('pinkslips_fixvariety', function(source)
    local src = source
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.Admin.AcePermission) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access denied', description = 'You do not have permission to do this.', type = 'error' })
        return
    end

    local fixedLocations = 0
    for _, loc in ipairs(Locations) do
        if not loc.disabled then
            ReconcileLotVariety(loc.key, loc)
            fixedLocations = fixedLocations + 1
        end
    end

    local msg = ('[mnc-pinkslips] Re-checked lot vehicle colours and cosmetic mods across %d location(s) for same-model duplicates.'):format(fixedLocations)
    print(msg)
    if src ~= 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Pinkslips', description = msg, type = 'success' })
    end
end, false)

RegisterNetEvent('mnc-pinkslips:server:saveLocation', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Admin.AcePermission) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access denied', description = 'You do not have permission to do this.', type = 'error' })
        return
    end
    if type(data) ~= 'table' then return end

    local label = tostring(data.label or ''):sub(1, 50)
    local class = tostring(data.class or ''):lower()
    local start, finish = data.start, data.finish
    local radius = tonumber(data.radius)
    local timeLimit = tonumber(data.timeLimit)
    local buyInPinkslip = tonumber(data.buyInPinkslip)
    local buyInPot = tonumber(data.buyInPot)

    local vehicles = ParseVehiclesCsv(tostring(data.vehicles or ''))
    local spawns = {}
    if type(data.spawns) == 'table' then
        for _, s in ipairs(data.spawns) do
            if tonumber(s.x) and tonumber(s.y) and tonumber(s.z) and tonumber(s.w) then
                spawns[#spawns + 1] = vector4(tonumber(s.x), tonumber(s.y), tonumber(s.z), tonumber(s.w))
            end
        end
    end

    local valid = label ~= '' and class ~= '' and type(start) == 'table' and type(finish) == 'table'
        and tonumber(start.x) and tonumber(start.y) and tonumber(start.z) and tonumber(start.w)
        and tonumber(finish.x) and tonumber(finish.y) and tonumber(finish.z)
        and radius and radius > 0 and timeLimit and timeLimit > 0
        and buyInPinkslip and buyInPinkslip > 0 and buyInPot and buyInPot > 0
        and #vehicles > 0 and #spawns >= Config.Admin.MinSpawnPoints

    if not valid then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Invalid location',
            description = ('Fill in every field correctly (radius/time/buy-ins > 0, at least one vehicle, at least %d spawn points).'):format(Config.Admin.MinSpawnPoints),
            type = 'error',
        })
        return
    end

    local sx, sy, sz, sw = tonumber(start.x), tonumber(start.y), tonumber(start.z), tonumber(start.w)
    local fx, fy, fz = tonumber(finish.x), tonumber(finish.y), tonumber(finish.z)
    local vehiclesCsv = table.concat(vehicles, ',')
    local spawnsJson = EncodeSpawnsJson(spawns)
    local adminName = GetPlayerName(src) or 'unknown'

    local configIndex = tonumber(data.configIndex)
    local dbId = tonumber(data.dbId)

    local function broadcastAndNotify(actionLabel)
        Locations = BuildLocationsList()
        RebuildLocationsByKey()
        for _, loc in ipairs(Locations) do
            if not loc.disabled then
                for i = 1, #loc.spawns do
                    EnsureStockSlot(loc.key, loc, i, false)
                end
                ReconcileLotVariety(loc.key, loc)
            end
        end
        local stockMap = {}
        for key, _ in pairs(LocationsByKey) do
            stockMap[key] = BuildStockSummary(key)
        end
        TriggerClientEvent('mnc-pinkslips:client:setLocations', -1, Locations, stockMap)
        TriggerClientEvent('ox_lib:notify', src, { title = actionLabel, description = ('"%s" is now live for every player.'):format(label), type = 'success' })
    end

    -- editing (or first-time overriding) one of the config.lua locations
    if configIndex and Locations[configIndex] and Locations[configIndex].fromConfig then
        local loc = Locations[configIndex]
        -- NOTE: table.unpack(params) only expands fully when it's the LAST item in a table
        -- constructor - anywhere else it truncates to one value. Build each params array
        -- explicitly (rather than splicing extra values onto a shared `params` list) to
        -- avoid that footgun.
        if loc.dbId then
            MySQL.update.await(
                'UPDATE mnc_pinkslips_locations SET label=?, class=?, start_x=?, start_y=?, start_z=?, start_w=?, finish_x=?, finish_y=?, finish_z=?, radius=?, time_limit=?, buy_in_pinkslip=?, buy_in_pot=?, vehicles=?, spawns=?, disabled=0 WHERE id = ?',
                { label, class, sx, sy, sz, sw, fx, fy, fz, radius, timeLimit, buyInPinkslip, buyInPot, vehiclesCsv, spawnsJson, loc.dbId }
            )
        else
            local id = MySQL.insert.await(
                'INSERT INTO mnc_pinkslips_locations (label, class, start_x, start_y, start_z, start_w, finish_x, finish_y, finish_z, radius, time_limit, buy_in_pinkslip, buy_in_pot, vehicles, spawns, created_by, config_index) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                { label, class, sx, sy, sz, sw, fx, fy, fz, radius, timeLimit, buyInPinkslip, buyInPot, vehiclesCsv, spawnsJson, adminName, configIndex }
            )
            if not id then
                TriggerClientEvent('ox_lib:notify', src, { title = 'Save failed', description = 'Could not write the location to the database.', type = 'error' })
                return
            end
        end

        broadcastAndNotify('Location updated')
        return
    end

    -- editing an existing admin-added location
    if dbId then
        local target = nil
        for _, loc in ipairs(Locations) do
            if loc.dbId == dbId and not loc.fromConfig then
                target = loc
                break
            end
        end
        if not target then
            TriggerClientEvent('ox_lib:notify', src, { title = 'Save failed', description = 'That location no longer exists.', type = 'error' })
            return
        end

        MySQL.update.await(
            'UPDATE mnc_pinkslips_locations SET label=?, class=?, start_x=?, start_y=?, start_z=?, start_w=?, finish_x=?, finish_y=?, finish_z=?, radius=?, time_limit=?, buy_in_pinkslip=?, buy_in_pot=?, vehicles=?, spawns=?, disabled=0 WHERE id = ?',
            { label, class, sx, sy, sz, sw, fx, fy, fz, radius, timeLimit, buyInPinkslip, buyInPot, vehiclesCsv, spawnsJson, dbId }
        )

        broadcastAndNotify('Location updated')
        return
    end

    -- brand new admin-added location
    local id = MySQL.insert.await(
        'INSERT INTO mnc_pinkslips_locations (label, class, start_x, start_y, start_z, start_w, finish_x, finish_y, finish_z, radius, time_limit, buy_in_pinkslip, buy_in_pot, vehicles, spawns, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { label, class, sx, sy, sz, sw, fx, fy, fz, radius, timeLimit, buyInPinkslip, buyInPot, vehiclesCsv, spawnsJson, adminName }
    )
    if not id then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Save failed', description = 'Could not write the location to the database.', type = 'error' })
        return
    end

    broadcastAndNotify('Location saved')
end)

RegisterNetEvent('mnc-pinkslips:server:deleteLocation', function(data)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Admin.AcePermission) then return end
    if type(data) ~= 'table' then return end

    local configIndex = tonumber(data.configIndex)
    local dbId = tonumber(data.dbId)

    if configIndex and Locations[configIndex] and Locations[configIndex].fromConfig then
        local loc = Locations[configIndex]
        if loc.dbId then
            MySQL.update.await('UPDATE mnc_pinkslips_locations SET disabled = 1 WHERE id = ?', { loc.dbId })
        else
            local cfgLoc = Config.Locations[configIndex]
            MySQL.insert.await(
                'INSERT INTO mnc_pinkslips_locations (label, class, start_x, start_y, start_z, start_w, finish_x, finish_y, finish_z, radius, time_limit, buy_in_pinkslip, buy_in_pot, vehicles, spawns, created_by, config_index, disabled) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)',
                {
                    loc.label or ('Config location ' .. configIndex), cfgLoc.class,
                    cfgLoc.start.x, cfgLoc.start.y, cfgLoc.start.z, cfgLoc.start.w,
                    cfgLoc.finish.x, cfgLoc.finish.y, cfgLoc.finish.z,
                    cfgLoc.radius, cfgLoc.time, cfgLoc.buyInPinkslip, cfgLoc.buyInPot,
                    table.concat(cfgLoc.vehicles, ','), EncodeSpawnsJson(cfgLoc.spawns),
                    GetPlayerName(src) or 'unknown', configIndex,
                }
            )
        end
    elseif dbId then
        MySQL.update.await('UPDATE mnc_pinkslips_locations SET disabled = 1 WHERE id = ?', { dbId })
    else
        return
    end

    Locations = BuildLocationsList()
    RebuildLocationsByKey()
    local stockMap = {}
    for key, _ in pairs(LocationsByKey) do
        stockMap[key] = BuildStockSummary(key)
    end
    TriggerClientEvent('mnc-pinkslips:client:setLocations', -1, Locations, stockMap)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Location removed', description = 'That location will no longer be raceable.', type = 'success' })
end)

-- ===================================================================
-- CLEANUP
-- ===================================================================
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CreateThread(function()
        Wait(1000) -- let the vehicle pool populate after start

        local ok, vehicles = pcall(GetAllVehicles)
        if not ok or not vehicles then return end

        local removed = 0

        for _, veh in ipairs(vehicles) do
            -- identified by the mncPinkslipStock state bag flag set on spawn (see
            -- requestStockSpawn) rather than a plate prefix, now that lot cars carry plain
            -- random plates like any player's car
            if DoesEntityExist(veh) and Entity(veh).state.mncPinkslipStock then
                DeleteEntity(veh)
                removed = removed + 1
            end
        end

        if removed > 0 then
            print(('[mnc-pinkslips] Cleaned up %d leftover lot vehicle(s) from before the restart.'):format(removed))
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, slots in pairs(Stock) do
        for _, stock in pairs(slots) do
            if stock.entity and DoesEntityExist(stock.entity) then
                DeleteEntity(stock.entity)
            end
        end
    end
end)