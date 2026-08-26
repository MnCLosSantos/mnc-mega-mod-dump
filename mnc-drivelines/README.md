# ⚙️ MNC Drive Type Conversion System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A **lightweight but immersive drive type conversion system** for QBCore-based FiveM servers. Mechanics can physically walk to each required wheel and install a conversion kit — switching any vehicle between FWD, RWD, and three AWD torque split profiles. All conversions persist to a database by license plate and are re-applied automatically whenever the vehicle is entered.

---

## ✨ Key Features

### 🚗 Drive Type Profiles
- **Five conversion types** available out of the box: FWD, RWD, AWD 50/50, Haldex 65/35, and Viscous 35/65
- **`fDriveBiasFront` handling modifier** applied directly to the vehicle, giving a real performance difference
- **Fully configurable** — add, remove, or tweak any profile in `Config.DriveTypes`
- **Lateral swap system** — vehicles can be re-converted between any type at any time, no tier locking

### 🔧 Per-Wheel Installation Flow
- **FWD and RWD** require work on two wheels; **all AWD variants** require all four
- **Walk-up interaction** — player physically walks to each wheel and presses `[E]` to begin work
- **Orange marker** drawn at each required wheel to guide the mechanic
- **On-screen help text** prompts the player when they enter range
- **Per-wheel progress bar** with mechanic animation (`amb@world_human_vehicle_mechanic`)
- **Cancellable at any wheel** — pressing cancel mid-bar cleanly aborts the entire install
- **Step-by-step notifications** confirm each completed wheel and prompt the next

### 💾 Persistence & Sync
- **Database-backed storage** — conversions saved to `vehicle_drivetype` by plate with timestamp and installer name
- **Server-side in-memory cache** (`drivetypeData`) for zero-latency lookups during a session
- **Client-side plate cache** (`driveCache`) avoids redundant server callbacks for already-known vehicles
- **`mnc-drivetype:syncData` broadcast** to all clients on install — driver's handling updates immediately without rejoining
- **Automatic re-application on vehicle entry** — stored type is fetched and applied the moment a player gets in

### 🔒 Security & Validation
- **Server-side job check** re-validates the mechanic's job and grade on every conversion attempt
- **Server-side item check** — conversion kit is only consumed after all validations pass
- **Plate length validation** — rejects malformed or suspiciously long plate strings
- **Duplicate prevention** — server rejects installs if the vehicle is already set to the requested type
- **Client job check** provides immediate feedback before any server event is fired

### 👮 Admin Commands
- **Five admin commands** to forcibly apply any drive type to a target player's current vehicle
- **Permission gated** — requires `admin` ACE permission
- **Notifies both admin and target** player on success
- **Logged to server console** with admin name, type, and plate

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone from GitHub
git clone https://github.com/YourUsername/mnc-drivetype.git

# OR download ZIP from Releases
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-drivetype/
```

### 2️⃣ Database Setup

The script **automatically creates** the required table on first start:

- `vehicle_drivetype` — stores drive type by vehicle plate, with installer name and timestamps

No manual SQL import needed!

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure mnc-drivetype
```

### 4️⃣ Add Items to QBCore

Add all five conversion kit items to `qb-core/shared/items.lua`:

```lua
['drivetype_fwd'] = {
    ['name']        = 'drivetype_fwd',
    ['label']       = 'FWD Conversion Kit',
    ['weight']      = 1000,
    ['type']        = 'item',
    ['image']       = 'drivetype_fwd.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'Converts a vehicle to Front Wheel Drive.',
},
['drivetype_rwd'] = {
    ['name']        = 'drivetype_rwd',
    ['label']       = 'RWD Conversion Kit',
    ['weight']      = 1000,
    ['type']        = 'item',
    ['image']       = 'drivetype_rwd.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'Converts a vehicle to Rear Wheel Drive.',
},
['drivetype_awd5050'] = {
    ['name']        = 'drivetype_awd5050',
    ['label']       = 'AWD 50/50 Conversion Kit',
    ['weight']      = 1500,
    ['type']        = 'item',
    ['image']       = 'drivetype_awd5050.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'Converts a vehicle to equal AWD torque split.',
},
['drivetype_haldex'] = {
    ['name']        = 'drivetype_haldex',
    ['label']       = 'Haldex AWD Conversion Kit',
    ['weight']      = 1500,
    ['type']        = 'item',
    ['image']       = 'drivetype_haldex.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'Installs a rear-biased Haldex-style AWD system (65R/35F).',
},
['drivetype_viscous'] = {
    ['name']        = 'drivetype_viscous',
    ['label']       = 'Viscous AWD Conversion Kit',
    ['weight']      = 1500,
    ['type']        = 'item',
    ['image']       = 'drivetype_viscous.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'Installs a front-biased viscous coupling AWD system (65F/35R).',
},
```

### 5️⃣ Configure Settings

Edit `config.lua` to adjust jobs, drive type profiles, and interaction distance.

---

## ⚙️ Configuration Guide

### 👷 Job Configuration

```lua
Config.RequireJob = true   -- Set to false to allow any player to install kits

Config.AllowedJobs = {
    ['mechanic'] = 0,  -- Job name = minimum grade level required
    ['bennys']   = 0,
}
```

### 🚗 Drive Type Profile Format

```lua
Config.DriveTypes = {
    ['fwd'] = {
        label       = 'Front Wheel Drive',   -- Display name in notifications
        item        = 'drivetype_fwd',        -- QBCore item name
        frontBias   = 1.0,                    -- fDriveBiasFront: 1.0=FWD | 0.0=RWD | 0.5=equal AWD
        rearBias    = 0.0,                    -- Informational only (not applied directly)
        installTime = 6000,                   -- Total progress bar time in ms
        description = 'All torque sent to the front wheels.',
    },
}
```

**`frontBias` reference values:**

| Drive Type | `frontBias` | Wheels Required |
|------------|-------------|-----------------|
| FWD | `1.0` | 2 (front) |
| RWD | `0.0` | 2 (rear) |
| AWD 50/50 | `0.5` | 4 |
| Haldex 65/35 | `0.35` | 4 |
| Viscous 35/65 | `0.65` | 4 |

### 📏 Interaction Distance

```lua
Config.ApplyDistance = 2.5   -- Max metres from vehicle for item use
```

---

## 🔄 How It Works

1. Player uses a conversion kit item from their inventory
2. Client checks the player is on foot and within `Config.ApplyDistance` of a vehicle
3. Job check runs client-side for immediate feedback
4. Player is instructed to walk to the first required wheel
5. An orange marker appears at each wheel; pressing `[E]` in range starts work
6. A progress bar plays with a mechanic crouch animation for each wheel
7. Cancelling at any point aborts the entire install cleanly
8. Once all wheels are complete, a server event fires with the plate and drive type
9. Server re-validates job, item ownership, and plate — then consumes the item
10. Drive type is saved to the database and broadcast to all clients via `syncData`
11. The target vehicle's `fDriveBiasFront` handling float is updated immediately

---

## 🖥️ Admin Commands

| Command | Drive Type Applied |
|---------|--------------------|
| `/drivetypefwd [id]` | Front Wheel Drive |
| `/drivetyperwd [id]` | Rear Wheel Drive |
| `/drivetyreawd [id]` | AWD 50/50 Split |
| `/drivetypehaldex [id]` | Haldex 65/35 Split |
| `/drivetypeviscous [id]` | Viscous 35/65 Split |

- All commands require `admin` ACE permission in `server.cfg`
- `[id]` is the target player's server ID — omit to apply to your own current vehicle
- The target player must be **inside a vehicle** when the command is run

---

## 🐛 Troubleshooting

**Item use has no effect:**
- Confirm the item name in `items.lua` matches the `item` field in `Config.DriveTypes`
- Ensure `mnc-drivetype` is started after `ox_lib` and `oxmysql` in `server.cfg`
- Check server console for job or item validation rejections with `Config.Debug = true`

**Wheel markers not appearing:**
- Confirm the vehicle has standard bone names (`wheel_lf`, `wheel_rf`, `wheel_lr`, `wheel_rr`)
- Verify the player is on foot — the system requires the player to be outside the vehicle

**Drive type not re-applying after restart:**
- Check the `vehicle_drivetype` table was created in your database
- Verify `oxmysql` is fully started before `mnc-drivetype` in `server.cfg`
- Enable `Config.Debug` and watch for "server hit" or "cache hit" logs on vehicle entry

**Handling change not felt in-game:**
- The `fDriveBiasFront` modifier only affects vehicles that support it natively
- Some heavily modified or addon vehicle handling files may override the value

**Admin command returns "Target is not in a vehicle":**
- The target player must be seated inside a vehicle at the time the command is run

---

## 📝 Credits & License

**Author**: Stan Leigh  
**Version**: 1.0.0  
**Framework**: QBCore

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

### Contributing
Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with a detailed description

---

## 📞 Support & Community

For support, bug reports, or feature requests:
- Open an issue on GitHub
- Join our Discord community
- Check existing documentation

---

## 🔄 Changelog

### Version 1.0.0 (Current Release)
**New Features:**
- ✨ Initial release with five configurable drive type profiles (FWD, RWD, AWD 50/50, Haldex 65/35, Viscous 35/65)
- ✨ Per-wheel walk-up installation flow with orange marker and `[E]` prompt
- ✨ Per-wheel ox_lib progress bar with mechanic crouch animation
- ✨ `fDriveBiasFront` handling modifier applied directly to vehicle on install
- ✨ Persistent storage in `vehicle_drivetype` MySQL table with plate, type, installer, and timestamps
- ✨ Server-side in-memory cache loaded from database on startup for instant lookups
- ✨ Client-side plate cache to avoid redundant server callbacks during a session
- ✨ `mnc-drivetype:syncData` broadcast to all clients so driver's vehicle updates immediately
- ✨ Automatic drive type re-application on vehicle entry via `getData` callback
- ✨ Five admin commands to forcibly apply any drive type to a target player's current vehicle
- ✨ Job and grade restriction system with per-job minimum grade configuration
- ✨ Server-side item validation and consumption after all checks pass
- ✨ Lateral re-conversion support — vehicles can be swapped between any type freely
- ✨ `Config.RequireJob = false` option to open conversions to all players

---

## ⚠️ Important Notes

1. **Handling Scope**: `fDriveBiasFront` is a client-side handling override — it applies to the local instance of the vehicle and is re-applied each time the vehicle is entered
2. **Addon Vehicles**: Some addon vehicles with custom handling files may reset the bias value on certain events; re-entry will restore it
3. **Database**: Requires oxmysql — MariaDB 10.3+ recommended
4. **Compatibility**: QBCore only — not compatible with ESX
5. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Give your mechanics something real to do under the hood. ⚙️**