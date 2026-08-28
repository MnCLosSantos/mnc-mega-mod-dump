# 🏎️ MNC Drift Score HUD

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.2.1-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A **comprehensive drift scoring system** for QBCore-based FiveM servers featuring an immersive HUD with score tracking, combo multipliers, advanced drift detection, customizable visual styles, and persistent player preferences. Built with performance and realism in mind for engaging drift gameplay.

---

## ✨ Key Features

### 🎯 Drift Scoring & Detection
- **Real-time drift calculation** based on angle, speed, proximity, and duration
- **Chain system** with timeouts and resets (e.g., spin-out, collision, or inactivity)
- **Advanced combos**: Tandem, Reverse Entry, Clutch Kick, Chicane, Donut, E-Brake, Link Drift, and more
- **Proximity detection** to walls/objects for bonus multipliers
- **Nearby player detection** for tandem bonuses
- **Spin-out prevention** with rotation rate checks
- **Collision detection** using vehicle health monitoring

### 📊 HUD & Visuals
- **Toggleable HUD elements**: Score, Multiplier, Combo
- **Customizable positions** for each HUD box
- **Animated transitions** for show/hide effects
- **Notification system** for chain resets, style changes, and events
- **Glow effects** for score gains/losses
- **Persistent HUD toggles** from config

### 🎨 Style Customization
- **25+ visual styles** with unique colors, gradients, and themes (e.g., Classic Green, Cyberpunk Neon, Blood Moon)
- **Persistent style saving** per player via database
- **In-game style selector** in help menu
- **Dynamic style application** with immediate HUD updates

### ❓ Help & Settings Menu
- **Interactive modal** with commands list, scoring explanation, and style grid
- **Style previews** showing colors and descriptions
- **Clickable style cards** to change themes instantly
- **ESC key support** to close menu
- **NUI focus management** for seamless interaction

### 🔧 Technical Features
- **Database persistence** for player styles
- **QBCore integration** for player loading/unloading
- **Fallback initialization** for reliable startup
- **Debug logging** for development
- **Configurable thresholds**: Min angle, max angle, spin-out rate, timeouts, etc.

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-driftscore/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-driftscore/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-driftscore/
```

### 2️⃣ Database Setup

The script **automatically creates** the required table on first start:

- `mnc_drift_styles` - Tracks player style preferences

No manual SQL import needed!

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-driftscore
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize:

```lua
-- Default settings
Config.DefaultStyle = 1
Config.DriftThresholdAngle = 15.0
Config.MaxDriftAngle = 120.0
Config.SpinOutRotationRate = 3.5
Config.MinDriftSpeed = 5.0
Config.PointsMultiplierBase = 1.0
Config.ComboTimeout = 3500
Config.InactiveResetTime = 15000

-- HUD positions
Config.HUD = {
    combo = { enabled = true, position = { top = "80px", right = "20px" } },
	multiplier = { enabled = true, position = { top = "50px", right = "850px" } },
	score = { enabled = true, position = { top = "100px", right = "850px" } },
}

-- Style examples (add/remove as needed)
Config.Styles = {
    [1]  = { name = "Classic Green",        bg = "rgba(30,30,46,0.5)",      text = "#ffffff", accent = "#4CAF50",  description = "Clean dark theme with green accents" },
    -- ... more styles ...
}

-- Combo configurations
Config.Combos = {
    -- Angle based
    { name = "Mild Drift",       comboType = "angle", condition = function(a) return a > 15 and a <= 30 end,      multiplier = 0.4 },
    -- ... more combos ...
}
```

### 5️⃣ Add Items to QBCore

No items are required for this script, as it's command-based. However, ensure QBCore is properly configured for player data handling.

---

## ⚙️ Configuration Guide

### 🎯 Drift Detection Settings

```lua
Config.DriftThresholdAngle = 15.0  -- Minimum angle to start drifting
Config.MaxDriftAngle = 120.0       -- Angle beyond which it's a spin-out
Config.SpinOutRotationRate = 3.5   -- Rotation speed for spin-out detection
Config.MinDriftSpeed = 5.0         -- Minimum speed in m/s to score points
Config.ComboTimeout = 3500         -- ms without drifting to end chain
Config.InactiveResetTime = 15000   -- ms without activity to reset total score
```

### 📊 HUD Configuration

```lua
Config.HUD.combo = {
    enabled = true, 
    position = { top = "80px", right = "20px" }  -- CSS positions (top, right, bottom, left)
}
```

### 🎨 Adding New Styles

Add to `Config.Styles` table:

```lua
[26] = {
    name = "Custom Style",
    bg = "rgba(0,0,0,0.5)",
    text = "#ffffff",
    accent = "#ff0000",
    description = "Your custom theme"
}
```

### 🔄 Combo System

Each combo has a type, condition function, and multiplier:

```lua
{ 
    name = "Tandem Bonus",     
    comboType = "tandem", 
    condition = function(nearbyDrifters) return nearbyDrifters >= 1 end, 
    multiplier = 1.4 
}
```

---

## 🛠️ Usage

### Commands
- `/driftscore` - Toggle the Drift HUD on/off
- `/driftstyle [1-25]` - Change visual style (number from config)
- `/drifthudhelp` - Open help menu with style selector and info

### In-Game Mechanics
- Enter a vehicle and start drifting to begin scoring
- Maintain chains for multipliers and combos
- Use help menu to browse and select styles
- Notifications appear for resets and events

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.2.1
**Framework**: QBCore
**Collection**: part of the [MNC Mega Mod Dump](https://github.com/MnCLosSantos/mnc-mega-mod-dump)

This resource is licensed under **MNC_LICENSE_NDFTEAU** (*No Distribution, Free To Edit And Use*) — see the [MNC_LICENSE_NDFTEAU license](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md) for the full text.

- ✅ Use and edit this resource freely on your own personal or paid server(s)
- ✅ Modify the code however you need to fit your server
- ❌ Do not redistribute, resell, or re-upload this resource (modified or not) as your own work
- ❌ Do not publish forks or copies of this resource outside of channels authorized by MnCLosSantos / carrot

---

## 📜 Changelog

### Version 1.0.0
**New Features:**
- ✨ Initial public release with core drift scoring system
- ✨ Added 25+ visual styles with database persistence
- ✨ Implemented advanced combo detection (angle, speed, proximity, etc.)
- ✨ Created interactive help menu with style selector
- ✨ Added notification system for chain events
- ✨ Implemented HUD toggles and positions
- ✨ Added spin-out and collision detection

**Improvements:**
- 🔧 Optimized drift detection loop for better performance
- 🔧 Enhanced NUI focus management for help menu
- 🔧 Improved style application with dynamic updates
- 🔧 Added fallback initialization for QBCore loading

**Bug Fixes:**
- 🐛 Fixed NUI callbacks not registering properly
- 🐛 Resolved style index mismatches between Lua/JS
- 🐛 Corrected HUD hiding on player unload
- 🐛 Fixed chain reset notifications not showing
- 🐛 Resolved modal not closing on ESC
- 🐛 Fixed database table creation errors
- 🐛 Corrected combo conditions causing false positives

---

## ⚠️ Important Notes

1. **Server Performance**: Tested stable with 128+ players; drift detection runs every 120ms
2. **Database**: Requires oxmysql - MariaDB 10.3+ recommended
3. **Compatibility**: QBCore only - not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS
5. **Support**: Community-driven, no official warranty provided

---

## 📞 Support & Community

- 💬 **Discord**: [![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6) — join for support, bug reports, and update announcements
- 🐛 **Issues**: open an issue on the [mnc-mega-mod-dump GitHub repo](https://github.com/MnCLosSantos/mnc-mega-mod-dump/issues)
- 📖 Check this README's Configuration Guide and Troubleshooting sections first — most questions are answered above

---

