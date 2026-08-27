# 🚗 MNC Rolling Coal - Vehicle Smoke Kit System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.2.5-brightgreen.svg)]()

---

## 🌟 Overview

A **comprehensive vehicle smoke kit system** for QBCore-based FiveM servers featuring realistic exhaust smoke effects, EGR/DPF delete prerequisites, adjustable smoke levels, auto-kit support for specific vehicle classes, and persistent database storage. Built with performance and realism in mind, allowing players to "roll coal" with thick, trailing exhaust particles.

---

## ✨ Key Features

### 💨 Smoke Effects & Tuning
- **Dynamic particle effects** attached to exhaust bones (trails naturally behind vehicles)
- **Adjustable smoke levels** (up to configurable max, e.g., 5 levels)
- **RPM-based scaling** for throttle-responsive smoke output
- **Engine/RPM checks** to only emit smoke when accelerating
- **Automatic fallback** to root bone if no exhaust bones found
- **Configurable particle assets** (e.g., thick truck rig exhaust)

### 🔧 Installation & Persistence
- **Item-based installation** with progress bars and animations (EGR delete, DPF delete, smoke kit)
- **Prerequisite system**: EGR and DPF deletes required before smoke kit
- **Database persistence** for installed kits and levels across sessions
- **Auto-kit system** for specific vehicle classes (e.g., trucks, vans) with default levels
- **Sync across clients** for immediate updates to smoke levels/mods

### 🚀 Vehicle Integration
- **Command-based menu** (`/rollingcoal`) to adjust smoke output
- **Front-bumper detection** for on-foot installations (must stand at vehicle front)
- **Hood open/close animation** during installs
- **Cancelable progress bars** for realistic mechanics
- **Debug mode** for logging and troubleshooting

### 📊 Additional Mechanics
- **Vehicle class filtering** for auto-kits (configurable classes like commercial, utility)
- **Plate-based tracking** to handle any vehicle uniquely
- **Ox_lib integration** for notifications and menus
- **MySQL support** with automatic table creation/upgrades

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
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-rollingcoal/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-rollingcoal/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-rollingcoal/
```

### 2️⃣ Database Setup

The script **automatically creates** the required table on first start:

- `vehicle_smoke_kits` - Stores installed kits, levels, and mods per plate

No manual SQL import needed!

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-rollingcoal
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize:

```lua
-- System toggles
Config.Debug = true

-- Smoke levels
Config.MaxSmokeAmount = 5       -- Maximum adjustable levels
Config.MinRPM         = 0.22    -- Minimum RPM for smoke emission

-- Particle effects
Config.ParticleDict = "core"                    -- Particle dictionary
Config.ParticleName = "veh_exhaust_truck_rig"   -- Particle name

-- Scale tuning
Config.BaseScale           = 1.5     -- Base scale at level 1
Config.ScaleStep           = 2.8     -- Increase per level
Config.RpmScaleMultiplier  = 1.8     -- RPM multiplier
Config.MaxScale            = 156.0   -- Maximum scale
Config.SmokeInterval       = 10      -- Update interval (ms)

-- Items
Config.SmokeKitItem          = "smoke_kit"          -- Smoke kit item
Config.EgrDeleteItem         = "egr_delete_kit"     -- EGR delete item
Config.DpfDeleteItem         = "dpf_delete_kit"     -- DPF delete item
Config.ApplyDistance         = 2.5                  -- Install distance

-- Auto-kits
Config.AutoKitDefaultAmount  = 2                    -- Default level for auto-kits
Config.AutoKitClasses        = {                    -- Vehicle classes for auto-kits
   20, 19, 18, 17, 12, 11, 10, 9 
}
```

### 5️⃣ Add Items to QBCore

Add items to `qb-core/shared/items.lua`. Examples:

```lua
-- Kits
['smoke_kit'] = {
    ['name'] = 'smoke_kit',
    ['label'] = 'Smoke Kit',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'smoke_kit.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Installs rolling coal system (requires EGR/DPF deletes)'
},

['egr_delete_kit'] = {
    ['name'] = 'egr_delete_kit',
    ['label'] = 'EGR Delete Kit',
    ['weight'] = 300,
    ['type'] = 'item',
    ['image'] = 'egr_delete_kit.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Deletes EGR system'
},

['dpf_delete_kit'] = {
    ['name'] = 'dpf_delete_kit',
    ['label'] = 'DPF Delete Kit',
    ['weight'] = 300,
    ['type'] = 'item',
    ['image'] = 'dpf_delete_kit.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Deletes DPF system'
},
```

---

## ⚙️ Configuration Guide

### 🎯 Smoke Kit Configuration

All settings are in `config.lua` as shown above. Customize particle effects, scales, and auto-kit classes to fit your server.

### 🏭 Auto-Kit System

```lua
Config.AutoKitClasses = { 20, 19, 18, 17, 12, 11, 10, 9 }  -- GTA vehicle classes (e.g., 20 = commercial trucks)
```

Auto-kits apply built-in EGR/DPF/smoke kits to matching vehicles with a default level.

---

## 🎮 Controls & Usage

### Player Controls
| Key/Command | Action |
|-------------|--------|
| `/rollingcoal` | Open smoke level menu (must be driver) |

### Installation
1. Stand directly in front of vehicle (within 1m of headlights)
2. Use EGR Delete Kit item → Progress bar
3. Use DPF Delete Kit item → Progress bar
4. Use Smoke Kit item → Progress bar (requires EGR/DPF installed)
5. Enter vehicle as driver → Smoke emits on acceleration
6. Use `/rollingcoal` to adjust levels (0 = off)

### Auto-Kit Vehicles
- Automatically have kits installed based on class
- Levels persist in database and survive restarts
- Use `/rollingcoal` to adjust

---

## 🧪 System Mechanics

### Smoke Emission
1. **Checks**: Engine on, RPM > MinRPM
2. **Scaling**: Base + level step + RPM boost (capped at MaxScale)
3. **Particles**: Looped on exhaust bones, trails naturally
4. **Update**: Every SmokeInterval ms

### Installation System
1. **Detection**: Player must be on foot, at vehicle front
2. **Prerequisites**: EGR/DPF before smoke kit (enforced client/server)
3. **Progress**: 3-4s bars with mechanic animation, hood opens/closes
4. **Persistence**: Stored in DB with plate, amount, mods, applied_by

### Auto-Kit System
1. **Detection**: On enter, check vehicle class
2. **Fallback**: Use saved DB level or default
3. **No Items Needed**: Built-in for qualifying classes

---

## 🔧 Troubleshooting

### Common Issues

**Smoke not appearing:**
- Ensure particle dict is loaded (check console for errors)
- Verify exhaust bones exist on vehicle model
- Check RPM is above MinRPM while accelerating

**Installation failing:**
- Confirm player is exactly at front bumper
- Check inventory for required items
- Verify prerequisites (EGR/DPF) are installed

**Data not saving:**
- Verify oxmysql is properly configured
- Check database connection in server console
- Confirm `vehicle_smoke_kits` table exists

**Menu not opening:**
- Ensure in driver seat
- For auto-kits, wait for data load
- Check QBCore is loaded

**Particles wrong:**
- Update Config.ParticleDict/Name to valid assets
- Test with Debug = true for logs

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.2.5
**Framework**: QBCore
**Collection**: part of the [MNC Mega Mod Dump](https://github.com/MnCLosSantos/mnc-mega-mod-dump)

This resource is licensed under **MNC_LICENSE_NDFTEAU** (*No Distribution, Free To Edit And Use*) — see the [MNC_LICENSE_NDFTEAU license](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md) for the full text.

- ✅ Use and edit this resource freely on your own personal or paid server(s)
- ✅ Modify the code however you need to fit your server
- ❌ Do not redistribute, resell, or re-upload this resource (modified or not) as your own work
- ❌ Do not publish forks or copies of this resource outside of channels authorized by MnCLosSantos / carrot

---

## 📞 Support & Community

- 💬 **Discord**: [![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6) — join for support, bug reports, and update announcements
- 🐛 **Issues**: open an issue on the [mnc-mega-mod-dump GitHub repo](https://github.com/MnCLosSantos/mnc-mega-mod-dump/issues)
- 📖 Check this README's Configuration Guide and Troubleshooting sections first — most questions are answered above

---

## 🔄 Changelog

### Version 1.2.5 (Current Release)
**New Features:**
- ✨ Added EGR/DPF delete prerequisites with separate items
- ✨ Implemented auto-kit system for specific vehicle classes
- ✨ Created persistent database storage for kits and levels
- ✨ Added sync events for real-time client updates
- ✨ Implemented front-bumper detection for installations

**Improvements:**
- 🔧 Enhanced particle scaling with RPM boost
- 🔧 Improved bone detection with fallback
- 🔧 Added debug logging for troubleshooting
- 🔧 Optimized main thread with configurable intervals

**Bug Fixes:**
- 🐛 Fixed smoke persisting when engine off
- 🐛 Resolved plate trimming issues
- 🐛 Corrected menu showing without kit
- 🐛 Fixed progress bar cancellations

---

### Version 1.0.0 (Initial Release)
**New Features:**
- ✨ Core smoke kit system with particle effects
- ✨ Adjustable levels via command
- ✨ Item-based installation
- ✨ Basic database persistence

**Known Issues:**
- ⚠️ No prerequisites for installation
- ⚠️ Limited to manual kits only
- ⚠️ No auto-kit support

---

## ⚠️ Important Notes

1. **Server Performance**: Tested stable with 128+ players
2. **Database**: Requires oxmysql - MariaDB 10.3+ recommended
3. **Compatibility**: QBCore only - not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS
5. **Support**: Community-driven, no official warranty provided

---

**Enjoy realistic rolling coal on your FiveM server! 💨**
