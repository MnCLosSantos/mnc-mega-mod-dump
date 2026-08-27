# 💼 MNC Take a Trip - Teleport System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A **comprehensive teleport system** for QBCore-based FiveM servers featuring job and item access restrictions, optional vehicle support, payment mechanics, visual markers, blips, animations, and progress indicators. Built with flexibility and immersion in mind, supporting both QB and OX interfaces.

---

## ✨ Key Features

### 🚀 Teleport Mechanics
- **Configurable locations** with multiple destinations per hub
- **Job-based access** to restrict travel to specific roles (e.g., police-only areas)
- **Item-based access** requiring specific inventory items for entry
- **Vehicle support** allowing or disallowing vehicles per destination
- **Payment system** with configurable costs per trip (cash or bank)
- **Arrival coordinates** for precise drop-off points and headings

### 🎨 Visual & Interactive Elements
- **Blips on map** with customizable sprites, colors, scales, and names
- **Visible markers** (simple upward arrows) detectable from up to 75m for easy spotting
- **Progress bars** (OX bar, circle, or QB style) during travel preparation
- **Animations and sounds** for immersive teleport sequences
- **Menu system** supporting OX context menus or QB menus
- **Notifications** via OX or QB systems
- **Target integration** optional via qb-target for interactive zones

### 🔒 Access & Security
- **Hybrid checks**: Combine job and item requirements for layered access
- **Debug mode** for detailed logging and troubleshooting
- **Fallback controls**: Use [E] key if qb-target is disabled

### 📊 Integration Options
- **UI flexibility**: Choose between OX or QB for menus, notifies, and progress
- **Inventory checks**: Seamless integration with qb-inventory for item validation
- **Performance optimized**: Thread-based rendering for markers and interactions

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| qb-inventory | Latest | ✅ Yes (for item checks) |
| qb-target | Latest | Optional (if enabled in config) |
| qb-menu | Latest | Optional (if QB menu type selected) |

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-takeatrip/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-takeatrip/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-takeatrip/
```

### 2️⃣ Database Setup

No database tables required! The script uses in-memory player data and QBCore functions.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure mnc-takeatrip
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize:

```lua
-- Debug Mode
Config.DebugMode = false

-- UI System
Config.MenuType = "qb" -- "ox" or "qb"
Config.NotifyType = "ox" -- "ox" or "qb"

-- Interaction system
Config.UseQbTarget = false -- true = use qb-target | false = press [E]

-- Sounds / Animation / Progress
Config.PlayTravelSound = true
Config.TravelSound = "ATM_WINDOW"
Config.PlayAnim = true
Config.AnimDict = "anim@mp_player_intmenu@key_fob@"
Config.AnimName = "fob_click"
Config.UseProgress = true
Config.ProgressType = "bar" -- "bar", "circle", or "QB"
Config.ProgressTime = 5500
Config.ProgressLabel = "Preparing for your trip..."
```

### 5️⃣ Add Locations

Customize locations in `config.lua`. No items needed unless using item restrictions.

---

## ⚙️ Configuration Guide

### 🎯 Location Configuration

```lua
Config.Locations = {  
    ["LSIA"] = {
        [0] = {
            label = "Airport",
            coords = vector4(-551.88, 6514.87, 5.93, 303.78),
            arrivalCoords = vector4(-551.88, 6514.87, 5.93, 303.78),
            allowVehicle = true,
            cost = 500, -- $500 to travel to Paleto
            blip = {
                sprite = 251,      -- Plane icon
                color = 3,         -- Light blue
                scale = 0.8,
                name = "Paleto International Airtravel"
            },
            jobs = {'police'}, -- Optional: Restrict to specific jobs
            items = {'vip_pass'} -- Optional: Require specific items
        },
        [1] = {
            label = "Tokyo",
            coords = vector4(-6570.06, 2022.34, 10.62, 25.3),
            arrivalCoords = vector4(-6570.06, 2022.34, 10.62, 25.3),
            allowVehicle = true,
            cost = 1000 -- $1000 to travel to Tokyo
        },
    },
}
```

### 🛠️ Available Options

| Option | Description | Default Value |
|--------|-------------|---------------|
| `label` | Display name of the destination | Required |
| `coords` | Teleport entry point (vector4 with heading) | Required |
| `arrivalCoords` | Drop-off point (overrides coords if set) | Optional |
| `allowVehicle` | Allow teleporting with vehicles | true |
| `cost` | Price to travel (0 for free) | 0 |
| `blip` | Map blip settings (sprite, color, scale, name) | Optional |
| `jobs` | Array of job names required for access | Optional |
| `items` | Array of item names required for access | Optional |

---

## 🎮 Controls & Usage

### Player Controls
| Key | Action |
|-----|--------|
| `E` | Open menu (if qb-target disabled) |

### Teleport Usage
1. Approach a marked location (visible arrow marker)
2. Interact via qb-target or [E] key
3. Select destination from menu (shows cost, vehicle allowance, locks if restricted)
4. Pay if required and teleport with animation/progress
5. Arrive at destination with optional vehicle

---

## 🧪 System Mechanics

### Access System
1. **Job Check**: Must match configured jobs if set
2. **Item Check**: Must have at least one required item if set
3. **Combined Restrictions**: Both job and item must pass if both are configured
4. **Locked Display**: Shows "Locked" in menu with error notification on attempt

### Teleport System
1. **Vehicle Handling**: Teleports vehicle if allowed; prevents if in vehicle and not allowed
2. **Payment**: Deducts from cash or bank; fails if insufficient funds
3. **Fade Effects**: Screen fade out/in for smooth transition
4. **Animations**: Plays configurable anim during prep
5. **Progress**: Optional bar/circle with disable controls

### Visual System
1. **Markers**: Tall, bobbing arrows visible from 75m
2. **Blips**: Short-range map icons for easy navigation
3. **Threads**: Optimized for low performance impact

---

## 🔧 Troubleshooting

### Common Issues

**Menu not opening:**
- Ensure ox_lib or qb-menu is started
- Check if qb-target is enabled/disabled correctly in config
- Verify location coords in config

**Access denied errors:**
- Confirm job name matches PlayerData.job.name
- Check inventory for required items via qb-inventory
- Enable debug mode for console logs

**Teleport not working:**
- Verify cost and sufficient player money
- Check for vehicle allowance if in a vehicle
- Look for client console errors

**Markers not visible:**
- Ensure thread is running (no script errors)
- Check distance calculations in client.lua

**Blips not showing:**
- Confirm blip config is set per destination
- Restart script after config changes

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

### Version 1.0.0 (Current Release)
**New Features:**
- ✨ Initial release with core teleport system
- ✨ Job and item access restrictions
- ✨ Vehicle support with optional allowance
- ✨ Payment mechanics via cash/bank
- ✨ Customizable blips and visible markers
- ✨ Animation, sound, and progress bar integration
- ✨ Hybrid QB/OX support for menus, notifies, and progress
- ✨ Debug mode for troubleshooting

**Improvements:**
- 🔧 Optimized threads for marker rendering and interactions
- 🔧 Flexible config for UI and interaction types
- 🔧 Smooth fade effects and vehicle handling

---

## ⚠️ Important Notes

1. **Server Performance**: Tested stable with 128+ players
2. **Compatibility**: QBCore only - not compatible with ESX
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS
4. **Support**: Community-driven, no official warranty provided

---

**Enjoy seamless travel on your FiveM server! ✈️**
