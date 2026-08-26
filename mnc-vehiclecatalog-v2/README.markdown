# 🚗 MNC Vehicle Catalog System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-3.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A **modern vehicle catalog system** for QBCore-based FiveM servers.  
This script provides a **sleek UI** for browsing vehicles, with support for **dealership-specific catalogs**, **admin access**, and **proximity-based interactions**. It integrates with **qb-target** or keypress (`E`) for opening the catalog, featuring customizable UI styles and vehicle filtering.

---

## ✨ Key Features

- 🖥️ **Responsive UI**  
  - Multiple UI themes (Dark Modern, Light Clean, Neon Night, Retro, Oceanic).  
  - Searchable vehicle catalog with category filters.  
  - Lazy-loaded vehicle images with fallback support.  

- 🚘 **Dealership Integration**  
  - Zone-based catalogs tied to specific dealerships (e.g., PDM, Luxury).  
  - Supports proximity UI with `qb-target` or `E` keypress.  
  - Admin command to view all vehicles.  

- 🔧 **Customizable Config**  
  - Define zones with coordinates, radius, and UI styles.  
  - Configure admin access groups and command.  
  - Toggle between `qb-target` or keypress interaction.  

- 🛡️ **Optimized & Secure**  
  - Clean client/server architecture with minimal overhead.  
  - Automatic UI focus management and cleanup.  
  - Error handling for missing vehicle images.  

---

## 📋 Requirements

```bash
Dependency             Version   Required
---------------------- --------- ----------
QBCore Framework       Latest    ✅ Yes
qb-core                Latest    ✅ Yes
ox_lib                 Latest    ✅ Yes
qb-target              Latest    Optional (if UseTarget = true)
```

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone from GitHub
git clone https://github.com/YourUsername/mnc-vehiclecatalog.git

# OR download ZIP from Releases
```

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-vehiclecatalog/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure mnc-vehiclecatalog
```

### 3️⃣ Configure Zones

Update `config.lua` to define dealership zones and UI styles:

```lua
Config.Zones = {
    {
        name = 'pdm',
        coords = vector3(-55.17, -1089.85, 26.92),
        radius = 2.0,
        uiStyle = 'style1',
        title = 'Adams Apple PDM Catalogue',
        useAnywhere = false,
    },
    {
        name = 'luxury',
        coords = vector3(-1146.43, -1733.85, 4.67),
        radius = 1.5,
        uiStyle = 'style2',
        title = 'PDM Deluxe Catalogue',
        useAnywhere = false,
    },
}
```

---

## ⚙️ Configuration

### 🎯 Config Overview

The `config.lua` file allows customization of:

- **Admin Command**: Set command name and access groups.
- **Interaction**: Toggle between `qb-target` or `E` keypress.
- **Zones**: Define dealership locations, UI styles, and titles.
- **UI Styles**: Customize colors, blur, and transparency for each theme.

Example `config.lua` snippet:

```lua
Config = {
    Command = 'vehiclecatalog',
    AdminGroups = {'group.admin'},
    UseTarget = false,
    Zones = {
        {
            name = 'pdm',
            coords = vector3(-55.17, -1089.85, 26.92),
            radius = 2.0,
            uiStyle = 'style1',
            title = 'Adams Apple PDM Catalogue',
            useAnywhere = false,
        },
    },
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
| `E` | Open catalog (if `UseTarget = false` and in zone) |
| `ESC` | Close catalog UI |

---

## 📞 Support & Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/your-discord-link)

---

## 📜 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).