```markdown
<DOCUMENT filename="README.md">
# 🚗 MNC Parking System

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.4.0-brightgreen.svg)]()

---

## 🌟 Overview

A **robust persistent vehicle parking system** for QBCore-based FiveM servers. Features realistic parking mechanics with physical parking locks, vehicle covering with tarps, dynamic blips, state synchronization, and full integration with qb-garages and qb-vehiclekeys. Includes an advanced vehicle cover system that persists across restarts and player reconnects.

Built with performance, realism, and compatibility in mind.

---

## ✨ Key Features

### 🔒 Parking Lock System
- **Physical parking lock item** required before parking (`parking_lock`)
- **Dedicated parking key item** to remove locks (`parking_key`)
- **Ownership validation** — only vehicle owners can install/remove locks
- **Database persistence** for installed locks

### 🏞️ Persistent Parking
- **Database-backed** parked vehicle storage (`mnc_parked_vehicles`)
- **Full vehicle state saving**: position, heading, props, fuel, engine & body health
- **Periodic client-to-server sync** (every 30 seconds by default)
- **Automatic garage state management** with qb-garages integration
- **Move detection** — driving a parked vehicle sends it to the impound/depot after restart

### 🛡️ Vehicle Cover / Tarp System
- **Placeable vehicle tarps** using `vehicle_tarp` item
- **Class-specific cover props** (different models for compacts, sedans, SUVs, sports, etc.)
- **Persistent covers** across server restarts and player reconnects
- **Tarp removal box** (`vehicle_tarp_box`) for emergency uncover
- **qb-target** integration for uncovering covered vehicles
- **Proper visibility/collision handling** while covered

### 📍 Visual & Quality of Life
- **Owner-only blips** on the map for parked vehicles
- **Parked vehicles menu** (`/parked` or configured commands)
  - Set waypoint to vehicle
  - Re-issue keys
  - Recall vehicle to garage
- **No-Park Zones** — configurable restricted areas (PD, hospitals, PDM, Benny's, etc.)
- **VIP Discord slot system** — extra parking slots for VIP players

### 🔧 Advanced Mechanics
- **Session-based spawn handling** for addon vehicles (client-side model streaming)
- **Network ownership management** for reliable prop application
- **Graceful reconnect/restart recovery** for both vehicles and covers
- **Cover teardown on recall** with proper prop cleanup
- **Anti-duplication and anti-exploit** safeguards

---

## 📋 Requirements

| Dependency          | Version | Required |
|---------------------|---------|----------|
| QBCore Framework    | Latest  | ✅ Yes   |
| qb-inventory        | Latest  | ✅ Yes   |
| qb-target           | Latest  | ✅ Yes   |
| ox_lib              | Latest  | ✅ Yes   |
| oxmysql             | Latest  | ✅ Yes   |
| qb-vehiclekeys      | Latest  | ✅ Yes   |
| qb-garages          | Latest  | Recommended |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource into your resources folder:
```
[server-data]/resources/[custom]/mnc-parking/
```

### 2️⃣ Database Setup

The script **automatically creates** all required tables on first start:
- `mnc_parking_locks`
- `mnc_parked_vehicles`
- `mnc_cover_state` (for vehicle tarps)

No manual SQL import needed!

### 3️⃣ Add to Server Config

```lua
ensure oxmysql
ensure mnc-parking
```

**Important**: Start after qb-core, qb-inventory, qb-target, and ox_lib.

### 4️⃣ Configure Settings

Edit `config.lua`:

```lua
Config.Debug = false

Config.MaxVehiclesOut = 4
Config.VipMaxVehiclesOut = 15

Config.ParkingLockItem = 'parking_lock'
Config.ParkingKeyItem = 'parking_key'

Config.SaveInterval = 30000        -- 30 seconds
Config.InteractDistance = 2.5

Config.RecallGarage = 'pillboxgarage'
Config.ImpoundGarage = 'depotLot'

Config.Commands = { 'parked' }

-- No-Park Zones (PD, hospitals, dealerships, etc.)
Config.NoParkZones = { ... }

-- VIP Discord IDs for extra slots
Config.VipDiscordIds = { ... }

-- Vehicle Cover Settings
Config.Cover = {
    CoverItem = 'vehicle_tarp',
    CoverRemoveItem = 'vehicle_tarp_box',
    CoverDuration = 4000,
    InteractDistance = 2.5,
    -- Class-specific props defined in config
}
```

### 5️⃣ Add Items to QBCore

Add these items to `qb-core/shared/items.lua`:

```lua
['parking_lock'] = {
    ['name'] = 'parking_lock',
    ['label'] = 'Parking Lock',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'parking_lock.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Install on a vehicle to enable parking'
},

['parking_key'] = {
    ['name'] = 'parking_key',
    ['label'] = 'Parking Key',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'parking_key.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Remove a parking lock from a vehicle'
},

['vehicle_tarp'] = {
    ['name'] = 'vehicle_tarp',
    ['label'] = 'Vehicle Tarp',
    ['weight'] = 2000,
    ['type'] = 'item',
    ['image'] = 'vehicle_tarp.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Cover your parked vehicle'
},

['vehicle_tarp_box'] = {
    ['name'] = 'vehicle_tarp_box',
    ['label'] = 'Tarp Removal Box',
    ['weight'] = 1500,
    ['type'] = 'item',
    ['image'] = 'vehicle_tarp_box.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Emergency vehicle cover remover'
},
```

---

## 🎮 Controls & Usage

### Player Commands
| Command     | Description                          |
|-------------|--------------------------------------|
| `/park`     | Park the current vehicle (must be driver + lock installed) |
| `/parked`   | Open parked vehicles menu            |

### Key Features Usage
- **Install Lock**: Use `parking_lock` item near your vehicle
- **Park Vehicle**: Sit in driver seat → `/park` → Confirm
- **Cover Vehicle**: Use `vehicle_tarp` on a parked vehicle
- **Uncover**: Target the cover prop with qb-target → "Uncover Vehicle"
- **Emergency Uncover**: Use `vehicle_tarp_box` near a covered vehicle
- **Recall**: Use parked menu → "Recall Vehicle" (sends to garage)

### No-Park Zones
Players cannot park or cover vehicles inside configured restricted areas (police stations, hospitals, dealerships, etc.).

---

## 🧪 System Mechanics

### Parking Flow
1. Install **Parking Lock** on vehicle
2. Drive to desired location
3. Use `/park` while in driver seat
4. Vehicle is saved with full state and locked
5. Blip appears for owner only

### Vehicle Cover Flow
1. Park the vehicle
2. Use **Vehicle Tarp** item nearby
3. Cover prop spawns, vehicle becomes hidden
4. Cover persists across restarts/reconnects
5. Use qb-target on prop to uncover or use removal box

### Move Detection
- If a parked vehicle is driven away, it is automatically removed from the parked list
- After server restart it will appear in the configured impound garage

### VIP System
Players with Discord IDs listed in `Config.VipDiscordIds` receive extra parking slots (`VipMaxVehiclesOut`).

---

## 🔧 Configuration Guide

Key config options:

- `MaxVehiclesOut` / `VipMaxVehiclesOut` — parking slot limits
- `NoParkZones` — array of restricted areas with radius
- `Cover.CoverProps` — vehicle class → prop model mapping
- `SaveInterval` — how often parked vehicles sync position/health
- `RecallGarage` / `ImpoundGarage` — garage names from qb-garages

---

## ⚠️ Important Notes

1. **Addon Vehicles**: Fully supported — spawning is handled client-side
2. **Performance**: Optimized with periodic sync and smart entity management
3. **Compatibility**: Works alongside qb-garages and qb-vehiclekeys
4. **Covers**: Vehicle tarps are fully persistent and network-safe
5. **No-Park Zones**: Prevent parking in sensitive roleplay areas

**Tested stable with 128+ players.**

---

## 📝 Credits

**Author**: Stan Leigh  
**Version**: 1.4.0  
**Framework**: QBCore  

### Contributing
Contributions welcome! Fork → Branch → Pull Request.

---

## 📞 Support

For issues or feature requests:
- Open an issue on GitHub
- Check the configuration and logs

---

## 🔄 Changelog

### Version 1.4.0 (Current)
**New Features:**
- ✨ Complete vehicle cover / tarp system with persistence
- ✨ Class-specific cover props
- ✨ Tarp removal box item for emergency uncover
- ✨ qb-target integration for uncovering
- ✨ Full reconnect/restart recovery for covers
- ✨ No-Park Zone support for both parking and covering

**Improvements:**
- 🔧 Robust network ownership and prop management
- 🔧 Batch cover state loading on player join
- 🔧 Improved move detection and impound handling
- 🔧 Better error handling and debug logging

**Bug Fixes:**
- 🐛 Fixed cover prop deletion and vehicle restore
- 🐛 Resolved stale netId issues on reconnect
- 🐛 Fixed ownership validation across all actions
- 🐛 Corrected garage state management with qb-garages

### Version 1.3.0
- Added persistent parking with full vehicle state saving
- Implemented periodic sync and move detection
- Added owner blips and parked menu
- VIP Discord slot system

### Earlier Versions
- Initial parking lock system
- Basic database persistence

---

**Enjoy realistic vehicle parking and protection on your FiveM server! 🚗**