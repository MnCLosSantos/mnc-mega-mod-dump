# 🚘 MNC Vehicle Spawner System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-2.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A **powerful vehicle spawner system** for QBCore-based FiveM servers.  
This script provides a **modern UI** for admins to spawn vehicles with customizable options, including paint types, colors, performance mods, and visual mods. It supports multiple fuel and key systems, with a sleek interface and configurable UI themes.

---

## ✨ Key Features

- 🖥️ **Intuitive UI**  
  - Browse vehicles by category with a searchable interface.  
  - Choose from multiple UI themes (Dark Modern, Light Clean, Neon Night, Retro, Oceanic).  
  - Lazy-loaded vehicle images with fallback support.  

- 🚗 **Vehicle Customization**  
  - Select paint types (Metallic, Classic, Matte, Pearlescent, Chrome).  
  - Choose from 10 predefined colors.  
  - Toggle performance mods (engine, brakes, transmission, suspension, turbo).  
  - Add random visual mods for unique vehicle appearances.  

- 🔌 **Integration Support**  
  - Fuel systems: LegacyFuel, cdn-fuel, ox, or standalone.  
  - Key systems: qb-vehiclekeys, qbx-vehiclekeys, or standalone.  
  - Option to warp player into the vehicle on spawn.  

- 🔒 **Admin-Only Access**  
  - Restricted to configurable admin groups.  
  - Simple command to open the spawner UI.  

- 🛠️ **Optimized & Robust**  
  - Clean client/server architecture with minimal resource usage.  
  - Proper vehicle cleanup and ground placement.  
  - Error handling for model loading and mod applications.  

---

## 📋 Requirements

```bash
Dependency             Version   Required
---------------------- --------- ----------
QBCore Framework       Latest    ✅ Yes
qb-core                Latest    ✅ Yes
ox_lib                 Latest    ✅ Yes
LegacyFuel             Latest    ✅ Yes
qb-vehiclekeys         Latest    ✅ Yes
```

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone from GitHub
git clone https://github.com/YourUsername/mnc-vehiclespawner.git

# OR download ZIP from Releases
```

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-vehiclespawner/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure mnc-vehiclespawner
```

### 3️⃣ Configure Settings

Update `config.lua` to set up the spawner:

```lua
Config = {
    Command = 'vehiclespawner',
    AdminGroups = {'group.admin'},
    Fuel = 'legacy',
    Keys = 'qb',
    Warp = true, -- Warp player into vehicle on spawn
    UIStyle = 'style1', -- Options: style1, style2, style3, style4, style5
}
```

---

## ⚙️ Configuration

### 🎯 Config Overview

The `config.lua` file allows customization of:

- **Admin Command**: Set command name and access groups.
- **Warp**: Enable/disable warping player into the vehicle.
- **UI Style**: Select a theme for the spawner UI.

Example `config.lua` snippet:

```lua
Config = {
    Command = 'vehiclespawner',
    AdminGroups = {'group.admin'},
    Fuel = 'legacy',
    Keys = 'qb',
    Warp = true,
    UIStyle = 'style1',
    UIStyles = {
        style1 = {
            primaryBg = 'rgba(32, 33, 36, 0.8)',
            secondaryBg = 'rgba(48, 49, 52, 0.7)',
            accent = '#8ab4f8',
            textPrimary = '#e8eaed',
            textSecondary = '#9aa0a6',
            borderColor = 'rgba(95, 99, 104, 0.5)',
            blur = '10px',
        },
        -- Additional styles...
    },
}
```

---

## 🎮 Controls

| Key | Action |
|-----|--------|
| `ESC` | Close spawner UI |
| `Click` | Select vehicle, paint type, color, or mods |
| `Confirm` | Spawn vehicle with selected options |

---

## 📞 Support & Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/your-discord-link)

---

## 📜 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).