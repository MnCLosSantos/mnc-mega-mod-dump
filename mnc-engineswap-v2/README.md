# 🔧 MNC Engine Swap System

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.9.4-brightgreen.svg)]()

---

## 🌟 Overview

A **feature-rich engine swap system** for QBCore FiveM servers. Players can purchase high-performance engine sounds and handling profiles from specialized mechanic shops, have them delivered, and install them with immersive progress-based mechanics. Features persistent per-plate saving, model-level defaults, admin tools, and full database integration.

Perfect for roleplay servers wanting deeper vehicle customization and mechanic job enhancement.

---

## ✨ Key Features

### 🛒 Shop & Purchase System
- Multiple customizable shop locations with job restrictions
- Categorized engine menu (Supercars, Sports, Muscle, Lowriders, etc.)
- Bank payment validation with price checking
- Themed shop UIs

### 📦 Delivery System
- Configurable delivery delay
- Visual engine crate + pallet props at delivery point
- Immersive delivery experience

### 🔧 Installation System
- Multi-stage progress bars/circles (removing stock → conversion kit → new engine)
- Optional skillcheck minigame
- Repair animation support
- Hood animation + proximity checks
- Vehicle tracking by license plate

### 💾 Persistence
- **Per-plate engine saves** (database-backed)
- **Per-model default sounds** (admin configurable)
- Automatic application on vehicle entry
- Survives server restarts and player disconnects

### ⚙️ Handling Integration
- Transfers real handling data (`fInitialDriveForce`, `fInitialDriveMaxFlatVel`, `fTractionCurveMax`)
- Temporary model spawning for accurate data extraction

### 👮‍♂️ Admin Tools
- `/engineswap` — Free instant engine swap menu for admins
- `/vehsoundmeta` — Manage default sounds per vehicle model
- Full model sound override system

### 🎨 Additional Features
- Full ox_lib integration (notifications, contexts, progress)
- Debug mode support
- Clean prop management
- Sound application redundancy for reliability

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

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-engineswap/
```

### 2️⃣ Database Setup

The script **automatically creates** required tables on first start:
- `vehicle_engines` — Per-plate engine assignments
- `vehicle_model_sounds` — Model-level default overrides

No manual SQL required.

### 3️⃣ Add to Server Config

```lua
ensure oxmysql
ensure ox_lib
ensure mnc-engineswap
```

### 4️⃣ Configure Settings

Edit `config.lua`:
- Shop locations, delivery/install points
- Job restrictions per shop
- Engine prices and delivery time
- Installation settings (minigame, progress type, animation)
- Required toolbox item

### 5️⃣ Add Items (Optional)

If using `Config.RequiredItem`, add to `qb-core/shared/items.lua`:
```lua
['toolbox'] = {
    name = 'toolbox',
    label = 'Toolbox',
    weight = 5000,
    type = 'item',
    image = 'toolbox.png',
    unique = false,
    useable = true,
    shouldClose = false,
    description = 'Tools for engine work'
},
```

---

## ⚙️ Configuration Guide

### Shop Configuration
```lua
Config.EngineShops = {
    {
        title = "LSC Salvage",
        location = vector3(-340.53, -141.85, 38.93),
        theme = "purple",
        delivery = vector3(-358.95, -128.34, 38.71),
        install = vector3(-329.75, -143.7, 39.06),
        jobs = {'mechanic', 'mechanic2'},
        blip = {sprite = 446, color = 27, scale = 0.8, name = "LSC Salvage"}
    }
}
```

### Installation Settings
```lua
Config.Installation = {
    requireMinigame = false,
    minigameMode = 'easy',
    progressDuration = 25000,
    progressType = 'bar', -- 'bar' or 'circle'
    useAnimation = true,
}
```

### Engine List
Engines are defined in `Config.EngineSounds` with categories, names, sound hashes, prices, and images.

---

## 🎮 Usage

### Player Flow
1. Go to an engine shop (if you have the required job)
2. Open the shop menu → Select engine → Pay
3. Wait for delivery (crate spawns)
4. Go to installation point with the target vehicle
5. Track vehicle → Install engine (proximity + hood opens)
6. Enjoy new engine sound + handling

### Admin Commands
- `/engineswap` — Open admin engine swap menu (free & instant)
- `/vehsoundmeta` — Manage default engine sounds for vehicle models

### Persistence
- Engines are saved to the vehicle's license plate
- Model defaults apply if no plate-specific engine is saved
- Both systems work together seamlessly

---

## 🔧 Commands

| Command | Description | Access |
|---------|-------------|--------|
| `/engineswap` | Open admin engine swap menu | Admin/God |
| `/vehsoundmeta` | Manage model sound overrides | Admin/God |

---

## ⚠️ Important Notes

- Vehicles must have **valid license plates**
- Players must be near the front of the vehicle for installation
- Sound hashes must match those available in your `dlc` files or custom audio
- Handling data is pulled from actual vehicle models when possible
- Strongly recommended to use with the engines pack included

---

## 🎬 Troubleshooting

**Engine sound not applying:**
- Check console for errors
- Ensure the sound hash exists in your game files
- Try using admin command to test

**Delivery prop not spawning:**
- Check coordinates in config
- Ensure `prop_car_engine_01` and `prop_pallet_02a` are streamed

**Database issues:**
- Verify oxmysql is running
- Check server console for table creation messages

**Handling not changing:**
- Some vehicles have locked handling — results may vary

**Shop not opening:**
- Confirm job requirements and toolbox (if enabled)

---

## 📝 Credits & License

**Author**: Stan Leigh  
**Version**: 1.9.4  

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

**Enhance your server's vehicle roleplay with realistic engine swaps!** 🔥