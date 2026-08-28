# 🩺 MNC Crutch System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-2.1.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A **realistic mobility aid system** for QBCore-based FiveM servers.  
This script provides **immersive EMS tools** for applying and managing mobility aids (crutches and canes) with **prop-based animations**, **movement restrictions**, and **persistent timers**. Fully optimized for **qb-target**, **ox_lib**, **qb-menu**, and **qb-core** frameworks, it enhances roleplay with medical realism.

---

## ✨ Key Features

- 🩺 **Immersive Mobility Aids**  
  - Crutches and canes with **attached props** for realistic visuals.  
  - **Injured animations** synced with movement for authenticity.  
  - Automatic prop cleanup on aid removal or session end.

- ⏰ **Persistent Timer System**  
  - Configurable durations for each aid (default: 15 min for crutches, 10 min for canes).  
  - Timers persist across sessions and resume after clothing reloads.  
  - EMS can check remaining time on active aids.

- 🚷 **Realistic Movement Restrictions**  
  - Disables sprinting, jumping, and combat while using aids.  
  - Enforces injured movement animations for roleplay immersion.  
  - Restrictions lift automatically when aids are removed.

- 🩹 **EMS Interaction Tools**  
  - **qb-target** integration for seamless player targeting.  
  - EMS-exclusive menu to apply or remove crutches/canes.  
  - Progress bars for applying/removing aids with cancelable animations.  
  - Configurable EMS job restrictions (default: `ambulance`).

- 🧹 **Cleanup & Optimization**  
  - Automatic prop and effect cleanup on aid removal or script restart.  
  - Efficient client/server sync for active aids.  
  - Error handling for invalid configurations or missing jobs.

---

## 📋 Requirements

```bash
Dependency             Version   Required
---------------------- --------- ----------
QBCore Framework       Latest    ✅ Yes
qb-target              Latest    ✅ Yes
ox_lib                 Latest    ✅ Yes
qb-menu                Latest    ❌ Optional
oxmysql                Latest    ✅ Yes
```

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-crutch/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-crutch/` folder
```

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-crutch/
```

### 2️⃣ Database Setup

No manual database setup is required. The script uses in-memory storage (`ActiveAids` table) for active mobility aids, which clears on script/server restart.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-crutch
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize:

```lua
Config.MenuSystem = "qb-menu"        -- "ox_lib" or "qb-menu"
Config.NotifySystem = "ox_lib"       -- "ox_lib" or "qb-notify"
Config.ProgressType = "bar"          -- "bar", "circle", or "QB"
Config.EMSJob = "ambulance"          -- Job allowed to apply/remove aids
Config.RestrictMovement = true       -- Disable sprint/jump while using aids
Config.EMSCanSeeRemaining = true     -- Allow EMS to check remaining aid time
```

---

## ⚙️ Configuration

### 🎯 Mobility Aid Setup

```lua
Config.Aids = {
    ['crutch'] = {
        label = "Crutch",
        prop = "v_med_crutch01",
        animDict = "move_m@injured",
        bone = 57005, -- Right Hand
        offset = {x = 1.02, y = 0.03, z = -0.03},
        rotation = {x = 180.0, y = 90.0, z = 210.0},
        defaultTime = 15, -- minutes
        progressLabel = "Applying Crutch..."
    },
    ['cane'] = {
        label = "Cane",
        prop = "prop_cs_walking_stick",
        animDict = "move_m@injured",
        bone = 57005, -- Right Hand
        offset = {x = 0.12, y = 0.03, z = -0.03},
        rotation = {x = 180.0, y = 90.0, z = 15.0},
        defaultTime = 10, -- minutes
        progressLabel = "Applying Cane..."
    }
}
```

### ⏳ Progress Durations

```lua
Config.ProgressDurations = {
    apply = 15, -- seconds to apply aid
    remove = 10 -- seconds to remove aid
}
```

---

## 🎮 Controls

| Key | Action |
|-----|--------|
| None | EMS interactions via `qb-target` menu |

---

## 📞 Support & Community

- 💬 **Discord**: [![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6) — join for support, bug reports, and update announcements
- 🐛 **Issues**: open an issue on the [mnc-mega-mod-dump GitHub repo](https://github.com/MnCLosSantos/mnc-mega-mod-dump/issues)
- 📖 Check this README's Configuration Guide and Troubleshooting sections first — most questions are answered above

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 2.1.0
**Framework**: QBCore
**Collection**: part of the [MNC Mega Mod Dump](https://github.com/MnCLosSantos/mnc-mega-mod-dump)

This resource is licensed under **MNC_LICENSE_NDFTEAU** (*No Distribution, Free To Edit And Use*) — see the [MNC_LICENSE_NDFTEAU license](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md) for the full text.

- ✅ Use and edit this resource freely on your own personal or paid server(s)
- ✅ Modify the code however you need to fit your server
- ❌ Do not redistribute, resell, or re-upload this resource (modified or not) as your own work
- ❌ Do not publish forks or copies of this resource outside of channels authorized by MnCLosSantos / carrot

---

