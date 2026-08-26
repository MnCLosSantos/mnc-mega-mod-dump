# 🩺 MNC Crutch System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-2.1.0-brightgreen.svg)]()

---

## 🌟 Overview

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
# Clone from GitHub
git clone https://github.com/YourUsername/mnc-crutchsystem.git

# OR download ZIP from Releases
```

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-crutchsystem/
```

### 2️⃣ Database Setup

No manual database setup is required. The script uses in-memory storage (`ActiveAids` table) for active mobility aids, which clears on script/server restart.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-crutchsystem
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

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/your-link)

---

## 📜 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).