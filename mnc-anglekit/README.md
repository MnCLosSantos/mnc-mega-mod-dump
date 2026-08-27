# 🚗 MNC Angle Kit System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A **comprehensive vehicle angle kit system** for QBCore-based FiveM servers featuring tiered steering lock modifications, persistent database storage, job-restricted installation, per-wheel progress animations, custom angle adjustments for pro kits, and admin tools. Built with performance and realism in mind for enhanced drifting mechanics.

---

## ✨ Key Features

### 🔧 Kit Installation & Animations
- **Immersive per-wheel installation** with progress bars and mechanic animations
- **Tiered kits** (Basic, Street, Pro) with increasing steering angles
- **Prevent downgrades** by checking existing kit tiers
- **Job restrictions** to limit installation to mechanics or specific roles
- **Progress bar integration** using ox_lib for smooth UI
- **Automatic handling modifications** applied in real-time
- **Vehicle entry/exit detection** to apply/restore angles dynamically

### 💾 Persistent Data System
- **Database-backed storage** for angle kits across server restarts
- **Automatic table creation** on startup (no manual SQL needed)
- **In-memory caching** for fast access with database sync
- **Plate-based tracking** to associate kits with specific vehicles
- **Admin-applied kits** logged with applicator name

### 🛠️ Custom Adjustment Tools
- **/angle Command**: Set custom steering lock (45°–85°) for Pro kits
- **Admin Commands**: `/anglebasic`, `/anglestreet`, `/anglepro` to grant kits directly
- **Permission checks** using QBCore's admin system
- **Target player support** for admin commands (optional ID parameter)

### 🚫 Restrictions & Balances
- **Job & Grade Requirements**: Configurable per job (e.g., mechanics only)
- **Distance Checks**: Must be near vehicle to install
- **Item Consumption**: Kits are usable items that remove on success
- **Debug Mode**: Optional logging for development

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
# then copy the `mnc-anglekit/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-anglekit/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-anglekit/
```

### 2️⃣ Database Setup

The script **automatically creates** the required table on first start:

- `vehicle_angle_kits` - Stores installed kits per vehicle plate

No manual SQL import needed!

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-anglekit
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize:

```lua
-- System toggles
Config.Debug = false
Config.RequireJob = true

-- Job restrictions
Config.AllowedJobs = {
    mechanic = 0,   -- any grade
    mechanic2 = 0,
    mechanic3 = 0,
    beekers = 0,
    autoexotics = 0,
    bennys    = 2,
    tuner     = 1,
}

-- Kit configurations
Config.Kits = {
    basic_angle_kit = {
        item         = 'basic_angle_kit',
        label        = 'Basic Angle Kit',
        angle        = 45,       -- degrees of steering lock granted
        installTime  = 4000,     -- progress bar duration (ms)
        canSetAngle  = false,    -- no /angle command for basic
    },
    -- ... (street and pro kits)
}

Config.MaxAngle       = 85      -- hard ceiling on /angle input
Config.MinAngle       = 45      -- floor for /angle input
Config.ApplyDistance  = 2.5     -- max distance to the vehicle for item use

-- Kit hierarchy
Config.KitTier = {
    basic_angle_kit  = 1,
    street_angle_kit = 2,
    pro_angle_kit    = 3,
}
```

### 5️⃣ Add Items to QBCore

Add all items from the config to `qb-core/shared/items.lua`. Examples:

```lua
-- Kits
['basic_angle_kit'] = {
    ['name'] = 'basic_angle_kit',
    ['label'] = 'Basic Angle Kit',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'basic_angle_kit.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Basic steering angle upgrade'
},

['street_angle_kit'] = {
    ['name'] = 'street_angle_kit',
    ['label'] = 'Street Angle Kit',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'street_angle_kit.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Street-level steering angle upgrade'
},

['pro_angle_kit'] = {
    ['name'] = 'pro_angle_kit',
    ['label'] = 'Pro Angle Kit',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'pro_angle_kit.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Professional steering angle upgrade'
},
```

---

## ⚙️ Configuration Guide

### 🎯 Kit Item Configuration

```lua
['basic_angle_kit'] = {
    item         = 'basic_angle_kit',
    label        = 'Basic Angle Kit',
    angle        = 45,       -- degrees of steering lock granted
    installTime  = 4000,     -- progress bar duration (ms)
    canSetAngle  = false,    -- no /angle command for basic
},
```

---

## 🎬 Available Kits

| Kit | Angle | Install Time | Custom Angle | Tier |
|-----|-------|--------------|--------------|------|
| Basic | 45° | 4s | No | 1 |
| Street | 55° | 5s | No | 2 |
| Pro | 65° (default) | 6s | Yes (45°–85°) | 3 |

---

## 🎮 Controls & Usage

### Player Controls
| Key | Action |
|-----|--------|
| `E` | Install kit at each wheel (prompt appears when near) |

### Commands
- **/angle [degrees]**: Set custom angle for Pro kit (must be driving)
- **/anglebasic [id]**: Admin - Grant Basic kit to player (optional ID)
- **/anglestreet [id]**: Admin - Grant Street kit
- **/anglepro [id]**: Admin - Grant Pro kit

### Installation Process
1. Use kit item near vehicle
2. Walk to each wheel and press E
3. Complete progress bar per wheel
4. Kit applies on success (item consumed)

---

## 🧪 System Mechanics

### Kit Installation
1. **Job Check**: Must have allowed job/grade
2. **Vehicle Detection**: Within 2.5m, not in vehicle
3. **Tier Validation**: Cannot install lower/same tier
4. **Per-Wheel Loop**: Player moves to each wheel manually
5. **Database Sync**: Immediate save and client broadcast

### Persistence System
1. **Loading**: All kits loaded from DB on startup
2. **Caching**: In-memory for quick checks
3. **Sync**: Real-time updates to all clients on changes
4. **Handling**: Original values cached and restored on exit

### Admin Tools
1. **Permission**: Requires QBCore admin access
2. **Target**: Applies to current vehicle of target player
3. **Bypass**: Ignores tier/job/item requirements
4. **Logging**: Console print for admin actions

---

## 🔧 Troubleshooting

### Common Issues

**Kits not saving:**
- Verify oxmysql is properly configured
- Check database connection in server console
- Confirm `vehicle_angle_kits` table exists

**Animations not playing:**
- Ensure ox_lib is started before mnc-anglekit
- Check animation dict names in client.lua

**Commands not working:**
- Confirm QBCore permissions for admin
- Check if player is in vehicle for /angle
- Look for server console errors

**Handling not applying:**
- Verify vehicle is driveable
- Check client console for debug logs
- Ensure no conflicting handling mods

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.0.0
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

### Version 1.0.0 (Initial Release)
**New Features:**
- ✨ Core angle kit system with tiered installations
- ✨ Persistent database storage for vehicle kits
- ✨ Per-wheel installation animations with progress bars
- ✨ /angle command for custom Pro kit adjustments
- ✨ Job restrictions and admin commands
- ✨ Real-time handling modifications
- ✨ Automatic DB table creation and data loading

**Improvements:**
- 🔧 Optimized client-side vehicle detection and caching
- 🔧 Enhanced server-client sync for angle changes
- 🔧 Added debug mode for logging

**Bug Fixes:**
- 🐛 Fixed handling not restoring on vehicle exit
- 🐛 Resolved database race conditions on load
- 🐛 Corrected plate trimming for consistency

---

**Enjoy enhanced vehicle handling on your FiveM server! 🚗**
