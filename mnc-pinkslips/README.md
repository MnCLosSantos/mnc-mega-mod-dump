# 🏁 MNC Pinkslip Racing

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A **class-locked, point-to-point pinkslip racing system** for QBCore-based FiveM servers. Players grind buy-in **pot races** at a location to unlock **pinkslip attempts** — winner-takes-the-car races against a fully-built, class-matched car parked on the lot. Win, and the car goes straight to your garage. Lose, and your own vehicle stays on the line for the next player to race for.

Every location is built entirely in-game through an **admin location builder** (`/setuppinkslips`) — no map editor or manual coordinate hunting required. Race times are set by driving the route once, start/finish/spawn points can be dropped with a free-fly placement camera, and the lot vehicle pool is picked from a live, image-backed browser sourced straight from `QBCore.Shared.Vehicles`.

---

## ✨ Key Features

- 🏆 **Two Race Types, One Location**
  - **Pot Race** — cash buy-in, no vehicle at stake. Win or lose, only money changes hands.
  - **Pinkslip Race** — buy-in plus your own vehicle. Win and take the parked stock car home; lose and forfeit the car you raced in.

- 📈 **Per-Player Progression**
  - Every player starts with 1 unlocked pinkslip attempt per location.
  - Grinding a configurable number of pot races unlocks the next attempt, up to a per-location cap.
  - Optionally count losses toward that grind, or require wins only.

- 🚗 **Fully-Built, Fair Lot Vehicles**
  - Every "stock" car on the lot has every performance mod (Engine, Brakes, Transmission, Suspension, Armour) maxed and the turbo installed — which car you're racing for never matters, only how you drive.
  - Cosmetic body-kit mods (11 slots), paint colour and window tint are randomized per car and **guaranteed distinct** from every other never-raced car of the same model at that location, so duplicate models never look identical on the lot.
  - A background reconciliation pass (and an on-demand admin command) retroactively fixes any duplicates from before this system was in place.

- 🔑 **Captured Vehicles Stay Real**
  - A car a player loses keeps the exact mods, paint and plate it had at the moment it was lost — it's never touched by the randomization system, and it takes priority over generic filler stock when a lot needs to make room for it.

- 💰 **Time-Weighted Payouts**
  - Winning either race type refunds your buy-in plus a matching "house" stake (2x buy-in), plus a bonus that scales with how close to the time limit you finished.
  - Pinkslip bonuses are a percentage of the won vehicle's shop value; pot bonuses use the same percentage band applied to the buy-in itself.

- 🛠️ **In-Game Admin Location Builder** (`/setuppinkslips`)
  - Set label, vehicle class, start/finish points, radius, buy-ins and lot vehicles entirely through an in-game panel.
  - **Drive-to-time**: drive the route once and the race's time limit is calculated automatically (with a configurable buffer).
  - **Free-fly placement camera**: fly a ghost vehicle into position for the start, finish, or any spawn point instead of physically driving there.
  - **Vehicle gallery picker**: a class-filtered, image-backed grid built live from `QBCore.Shared.Vehicles`, with a chained fallback across the FiveM docs CDN and two GitHub image stores, plus manual entry for anything not pictured.
  - Locations can be edited or soft-deleted, and changes sync live to every connected player — no resource restart needed.

- 📡 **Distance-Based Vehicle Streaming**
  - Lot vehicles spawn and despawn based on player proximity, falling and settling naturally onto the terrain instead of snapping into place, mirroring the streaming approach used by `mnc-cardelivery`.

- 🎬 **Race Presentation**
  - Countdown with synced audio (3-2-1-GO), a route blip to the finish line, a live race HUD with a countdown timer bar, and win/lose/unlock sound stingers.

---

## 📋 Requirements

```bash
Dependency        Version   Required
----------------- --------- ----------------------------------------
qb-core            Latest    ✅ Yes
qb-garages         Latest    ✅ Yes
ox_lib             Latest    ✅ Yes
oxmysql            Latest    ✅ Yes
qb-vehiclekeys     Latest    ⚠️ Recommended (see note below)
```

> **Vehicle keys note**: winning a pinkslip and starting an admin test drive both grant keys via the `vehiclekeys:client:SetOwner` event (the same event `qb-vehicleshop` uses on a purchase). If your server runs a `qb-vehiclekeys` fork that listens for a different event or export, update the two call sites in `client.lua` / `server.lua` to match, or winners/admins will be locked out of the vehicle's ignition.

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-pinkslips/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-pinkslips/` folder
```

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-pinkslips/
```

### 2️⃣ Database Setup

The script **automatically creates** its required tables on first start (needs `CREATE` privilege — otherwise run the equivalent SQL manually):

```sql
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mnc_pinkslips_stock` (
  `location_key` VARCHAR(20) NOT NULL,
  `slot_index` INT NOT NULL,
  `model` VARCHAR(50) NOT NULL,
  `plate` VARCHAR(15) DEFAULT NULL,
  `props` LONGTEXT DEFAULT NULL,
  `source` VARCHAR(10) NOT NULL DEFAULT 'config',
  PRIMARY KEY (`location_key`, `slot_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mnc_pinkslips_progress` (
  `citizenid` VARCHAR(50) NOT NULL,
  `location_key` VARCHAR(20) NOT NULL,
  `unlocked_slots` INT NOT NULL DEFAULT 1,
  `pinkslips_used` INT NOT NULL DEFAULT 0,
  `pot_progress` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`citizenid`, `location_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 3️⃣ Add Sound Files

`fxmanifest.lua` streams every file under `html/sounds/*.mp3` — add your own clips there using this naming convention (numbered variants are picked at random per event):

```bash
File                  Count   Plays when...
--------------------- ------- ----------------------------------------
prompt1 .. prompt10   10      the pinkslip menu is opened
win1 .. win14         14      a race is won
lose1 .. lose14       14      a race is lost
unlock1 .. unlock2    2       a new pinkslip attempt unlocks
go.mp3                1       the countdown hits "GO!"
countdown.mp3         1       the 3-2-1 countdown starts (single clip, not per-number)
```

Tune `Config.RaceCountdownTickMs` / `Config.RaceCountdownGoHoldMs` against however long your `countdown.mp3` actually runs, and use `/pinkslips_testcountdown` (see [Usage](#-usage)) to preview the timing without starting a real race.

### 4️⃣ Add to Server Config

```bash
# server.cfg
ensure oxmysql
ensure ox_lib
ensure qb-garages
ensure mnc-pinkslips
```

### 5️⃣ Configure Settings

Edit `config.lua` to set up your first location — see [Configuration](#️-configuration) below for every option.

---

## ⚙️ Configuration

### General

```lua
Config.Locale = 'en'
Config.PayoutAccount = 'bank' -- buy-ins are withdrawn from / payouts paid into this account: 'cash' | 'bank'
```

### Admin / Location Builder

```lua
Config.Admin = {
    Command = 'setuppinkslips',
    AcePermission = 'admin',

    -- "drive it once, buffer the time" flow, same as mnc-cardelivery's route builder
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
```

### Progression

```lua
Config.Progression = {
    MaxPinkslipsPerLocation = 4,  -- hard cap on unlocked pinkslip attempts per player, per location
    RacesToUnlockNext = 10,       -- paid pot races needed before the next attempt unlocks
    CountLossesTowardUnlock = false, -- true = any completed pot race counts; false = wins only
}
```

### Vehicle / Garage

```lua
-- Class lock uses QBCore.Shared.Vehicles[model].category - every Config.Locations[i].class
-- must match a category your qb-core vehicles.lua actually uses.
Config.WinGarage = 'pillboxgarage' -- qb-garages garage a won vehicle is parked in

Config.Plate = {
    Charset             = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
    Length              = 8,
    MaxGenerateAttempts = 25,
}
```

### Vehicle Images (admin "Browse Vehicles" picker)

```lua
Config.VehicleImageSources = {
    fivem   = 'https://docs.fivem.net/vehicles/{model}.webp',
    github1 = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage/raw/main/{model}.png',
    github2 = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage-2/raw/main/{model}.png',
}
Config.VehicleImageSourceOrder = { 'fivem', 'github1', 'github2' }
```

### Payouts

```lua
Config.Payout = {
    -- Pinkslip win = 2x buy-in + bonus + the vehicle. Bonus is a % of the WON vehicle's
    -- QBCore.Shared.Vehicles price, weighted by how close to the buzzer you finished.
    PinkslipBasePercent = 0.05,
    PinkslipMinPercent  = 0.02,
    PinkslipMaxPercent  = 0.08,
    DefaultVehicleValue = 15000, -- fallback if a model isn't in QBCore.Shared.Vehicles

    -- Pot win = 2x buy-in + bonus, cash only. Same % band, applied to the buy-in instead.
    PotBasePercent = 0.05,
    PotMinPercent  = 0.02,
    PotMaxPercent  = 0.08,

    TimeBonusWeight = 0.5, -- shared by both bonus calculations above
}
```

### Streaming (parked lot vehicles)

```lua
Config.Streaming = {
    CheckInterval   = 3000,
    SpawnDistance   = 70.0,
    DespawnDistance = 200.0,

    SpawnHeightOffset = 0.5,  -- meters above the spawn point to spawn at
    SpawnFallTime     = 1000, -- ms to let it fall, unfrozen, before settling
    SpawnSettleTime   = 2000, -- ms to let it settle before being snapped to the ground and frozen
}
```

### Interaction, Countdown & Blips

```lua
Config.PromptDistance = 13.0 -- how close (while driving) before the interact prompt shows

Config.RaceCountdown         = 3    -- how many numbers count down (3, 2, 1)
Config.RaceCountdownTickMs   = 1000 -- ms spent on EACH number
Config.RaceCountdownGoHoldMs = 600  -- ms "GO!" stays on screen before the race HUD takes over

Config.Blips = {
    Start  = { sprite = 724, color = 8, scale = 0.85, label = 'Pinkslip Races' },
    Finish = { sprite = 478, color = 8, scale = 1.0,  label = 'Pinkslip Finish' },
}
```

### Locations

Locations can be predefined in `config.lua` and/or added entirely through the admin builder (both are merged at runtime):

```lua
Config.Locations = {
    {
        label         = 'Vinewood Muscle Pinks',
        class         = 'muscle',                       -- must match a QBCore.Shared.Vehicles category
        start         = vector4(-215.8, -1418.2, 31.2, 72.0),
        finish        = vector3(-799.4, -1791.6, 27.7),
        radius        = 10.0,
        time          = 240,
        buyInPinkslip = 15000,
        buyInPot      = 2500,
        vehicles      = { 'dominator', 'gauntlet', 'sabregt', 'nightshade' }, -- lot restock pool
        spawns = {                                       -- at least Config.Admin.MinSpawnPoints vector4s
            vector4(-220.1, -1422.6, 31.2, 65.0),
            vector4(-222.9, -1419.4, 31.2, 68.0),
            vector4(-225.6, -1416.1, 31.2, 71.0),
            vector4(-228.4, -1412.9, 31.2, 74.0),
            vector4(-231.1, -1409.6, 31.2, 77.0),
            vector4(-233.9, -1406.3, 31.2, 80.0),
        },
    },
}
```

---

## 🎮 Usage

### Racing

1. Drive an **owned vehicle of the correct class** up to a location's blip and stand/park within `Config.PromptDistance`.
2. Press **E** to open the pinkslip menu.
3. Choose **Buy in for Pot Race** (cash only), or pick a car from **Cars on the line** to **Race for Pinkslip** (requires an unlocked attempt).
4. Your vehicle is warped to the location's start point, a 3-2-1-GO countdown plays, and a blip routes you to the finish.
5. Reach the finish radius before the time limit to win — miss it, leave the vehicle, or run out of time and you lose.

### Commands & Keybinds

```bash
Command                    Access        Description
--------------------------- ------------- ---------------------------------------------------
/setuppinkslips             Admin (ace)   Opens the in-game location builder
/pinkslips_fixvariety       Admin (ace)   Force re-checks every location for duplicate-looking
                                           lot vehicles right now, without a resource restart
/pinkslips_testcountdown    Everyone      Previews the countdown audio/visual timing, no race
                                           needed - use this to tune Config.RaceCountdownTickMs
```

```bash
Keybind (default)  Command                        Context
------------------ ------------------------------ ----------------------------------------
BACKSPACE           pinkslips_forfeit              Forfeit your active race
BACKSPACE           pinkslips_testdrive_cancel     Cancel an admin route test drive
BACKSPACE           pinkslips_placement_cancel     Cancel camera placement
ENTER                pinkslips_placement_action     Drop / confirm during camera placement
R                    pinkslips_placement_refly      Pick the placement vehicle back up
```

All keybinds are registered with `RegisterKeyMapping`, so players and admins can remap them under FiveM's own keybind settings.

---

## 🛠️ Admin: Location Builder

Open the builder with `/setuppinkslips` (requires the `Config.Admin.AcePermission` ace):

1. **Label & class** — the vehicle class dropdown is built live from `QBCore.Shared.Vehicles` categories, so it always matches what your server can actually spawn.
2. **Start / Finish points** — use **Use my position**, or **Place with camera** to free-fly a ghost preview vehicle (WASD + mouse, Space/Ctrl for up/down, Shift to move faster, Left/Right to rotate) and drop it exactly where you want.
3. **Lot vehicles** — click **Browse Vehicles** to open a class-filtered image gallery pulled from `QBCore.Shared.Vehicles`, with pictures resolved through a fallback chain (FiveM docs CDN → your configured GitHub image stores). Anything not pictured can be added manually by spawn name.
4. **Buy-ins** — set the pinkslip and pot race entry costs.
5. **Race time** — click **Drive to set race time**, drive the route once, and the time limit is calculated automatically (raw time + `RouteTimer.BufferPercent`, floored at `MinTime`, rounded to `RoundTo`). Changing the start, finish, radius, or vehicle list invalidates the timed value until you drive it again.
6. **Spawn points** — add at least `Config.Admin.MinSpawnPoints` parked-vehicle spots, via **Use my position** or the same camera placement tool.
7. **Save** — the location goes live for every connected player immediately, no restart required. **View Locations** lists everything (including default `config.lua` locations) for editing or soft-deleting.

---

## 🏆 Race Mechanics

### Lot Variety

Every never-raced ("config-sourced") stock car has all five performance mod slots (Engine, Brakes, Transmission, Suspension, Armour) maxed and the turbo installed — fairness means the win should come down to driving, not which car you're handed. Paint colour, window tint, and the 11 cosmetic body-kit slots are randomized per car and checked against every other config-sourced car of the same model at that location so duplicates never look identical. A background reconciliation pass runs on every resource start and location edit (and can be forced on demand with `/pinkslips_fixvariety`) to retroactively fix any pre-existing collisions.

### Captured Vehicles

A car a player loses in a pinkslip race keeps exactly the mods, paint, and plate it had at the moment it was lost. It's parked in an empty lot slot (or replaces a generic filler car if the lot is full) and is never touched by the randomization system above — it stays exactly as its previous owner built or won it until someone races for it again.

### Progression & Payouts

Every player starts with 1 unlocked pinkslip attempt per location. Completing `Config.Progression.RacesToUnlockNext` pot races (wins only by default, or any completed race if `CountLossesTowardUnlock` is enabled) unlocks the next attempt, up to `MaxPinkslipsPerLocation`. Winning either race type refunds your buy-in plus a matching "house" stake, plus a bonus that's largest for a fast finish and shrinks toward the time limit — pinkslip bonuses are a percentage of the won vehicle's shop value, pot bonuses use the same percentage band applied to the buy-in itself. Losing a pot race forfeits the buy-in; losing a pinkslip race forfeits the buy-in **and** the vehicle you raced in.

---

## 🛠️ Troubleshooting

### Interact Prompt / Menu Not Showing
```bash
✅ Confirm you're driving (driver's seat) an owned vehicle within Config.PromptDistance
✅ Check the location isn't disabled in the admin builder's location list
✅ Verify the script started cleanly: /restart mnc-pinkslips and check F8 console
✅ Ensure ox_lib is loaded before mnc-pinkslips in server.cfg
```

### "That car is still getting set up" / No Mods on a Won Car
```bash
✅ The car's mods/props are still being captured after it first spawned - try again a few seconds later
✅ Check the F8 console for a "Could not capture properties" warning naming the location/slot
✅ Confirm the client that streamed the car in didn't disconnect mid-capture
```

### Location Builder Won't Save
```bash
✅ Every field must be filled (radius/time/buy-ins > 0)
✅ At least Config.Admin.MinSpawnPoints spawn points are required
✅ The route must be test-driven after any start/finish/radius/vehicle change
✅ Confirm you hold the Config.Admin.AcePermission ace permission
```

### Database Issues
```bash
✅ Check oxmysql is running and connected before mnc-pinkslips starts
✅ Confirm the account has CREATE privileges, or run the schema in Installation manually
✅ Query manually to check: SELECT * FROM mnc_pinkslips_locations;
✅ Check the F8/server console for MySQL errors on resource start
```

### Winner Didn't Get Keys
```bash
✅ Confirm your qb-vehiclekeys fork listens for 'vehiclekeys:client:SetOwner' - see the
   Requirements note above if it uses a different event/export
```

---

## 🎯 Performance Notes

```bash
Feature                   Impact      Notes
-------------------------- ----------- ---------------------------------------------
Lot Streaming              Low         Distance-checked every Config.Streaming.CheckInterval
Prompt Loop                Low         Sleeps 0ms only while a prompt is actually shown
Location Sync               Event-only  Only rebroadcasts on admin save/delete or a join
Stock Vehicle Cleanup       Automatic   State-bag tagged, swept on resource start & stop
```

---

## 📞 Support & Community

- 💬 **Discord**: [![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6) — join for support, bug reports, and update announcements
- 🐛 **Issues**: open an issue on the [mnc-mega-mod-dump GitHub repo](https://github.com/MnCLosSantos/mnc-mega-mod-dump/issues)
- 📖 Check this README's Configuration and Troubleshooting sections first — most questions are answered above

### Common Questions

**Q: Can players race for a pinkslip in any vehicle?**
A: No - the vehicle must be owned by the player and match the location's configured `class`, exactly as `QBCore.Shared.Vehicles[model].category` reports it.

**Q: What happens to a location if I delete a default config.lua location?**
A: It's soft-disabled (an SQL override row is created/flagged), never deleted outright - remove the entry from `config.lua` yourself if you want it gone for good.

**Q: Can I run multiple locations with different classes and buy-ins?**
A: Yes - `Config.Locations` accepts as many entries as you want, and admins can add more in-game without touching `config.lua` at all.

**Q: Do lost vehicles disappear forever?**
A: No - they're re-parked on the same lot as "captured" stock, mods and plate intact, for the next player to race for.

---

## 📝 Credits & License

**Author**: MnC Los Santos
**Version**: 1.0.0
**Framework**: QBCore
**Dependencies**: qb-core, qb-garages, ox_lib, oxmysql
**Collection**: part of the [MNC Mega Mod Dump](https://github.com/MnCLosSantos/mnc-mega-mod-dump)

This resource is licensed under **MNC_LICENSE_NDFTEAU** (*No Distribution, Free To Edit And Use*) — see the [MNC_LICENSE_NDFTEAU license](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md) for the full text.

- ✅ Use and edit this resource freely on your own personal or paid server(s)
- ✅ Modify the code however you need to fit your server
- ❌ Do not redistribute, resell, or re-upload this resource (modified or not) as your own work
- ❌ Do not publish forks or copies of this resource outside of channels authorized by MnCLosSantos / carrot

---

## 🔄 Changelog

### Version 1.0.0
- Initial release
- Pot race and pinkslip race modes with per-player, per-location progression
- In-game location builder with drive-to-time race timing and free-fly camera placement
- Live, image-backed vehicle gallery sourced from QBCore.Shared.Vehicles
- Distance-based lot vehicle streaming with fall/settle spawning
- Fully-built lot vehicles with guaranteed-distinct cosmetic variety per model/location
- Captured (player-lost) vehicles preserved exactly as raced away from their owner
- Time-weighted payout system for both race types

**See you at the line. 🏁**
