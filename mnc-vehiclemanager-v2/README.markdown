# MNC Vehicle.LUA Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-2.3.7-brightgreen.svg)]()

---

## Overview

A **comprehensive vehicle management system** for QBCore-based FiveM servers.  
This script provides an **intuitive UI** for editing and saving vehicle information directly from in-game vehicles, with dynamic dropdowns, auto-pricing, and theme customization.  
Fully optimized for **QBCore Framework**, **ox_lib notifications**, and seamless integration.

---

## Key Features

- **Intuitive UI Editor**  
  - Accessible via the `/vehiclelua` command while in a vehicle.  
  - Auto-populates vehicle details (model, name, brand, category, type, shop).  
  - Dynamic dropdowns for brands, categories, types, and shops based on QB-Core shared vehicle data.  
  - Supports light and dark themes with smooth transitions.

- **Dynamic Auto-Pricing**  
  - Calculates vehicle prices based on category, brand, type, and shop.  
  - Configurable pricing with base prices, brand multipliers, type multipliers, and shop premiums.  
  - Optional randomization (±5%) for price variation.  
  - Toggleable auto-pricing in the settings modal.

- **Vehicle Data Saving**  
  - Saves vehicle data to `vehiclesaves.lua` with proper formatting for Qb-core `vehicles.lua` ensuring a ready to paste format.  
  - Admin-only access with ACE permissions or QBCore admin checks.  
  - Success/error notifications for save operations.

- **Dynamic Dropdowns**  
  - Populates dropdowns with unique values from QB-Core’s shared vehicle data.  
  - Searchable and filterable inputs with autocomplete on Enter key.  
  - Smooth dropdown behavior with scrollable lists.

- **Customization Options**  
  - Light and dark theme toggle in the settings modal.  
  - Responsive UI with animated transitions and gradient effects.  

- **Safety & Optimization**  
  - Automatic UI cleanup on close or Escape key press.  
  - Prevents unauthorized access with permission checks.  
  - Optimized for performance with minimal server load.

- **Export All Vehicles**  
  - Bulk export all vehicles (those not in QB-Core `vehicles.lua`) to `vehiclesaves.lua`.  
  - Options to exclude emergency vehicles (class 18), apply auto-pricing, and set fallback shop.

---

## Requirements

```bash
Dependency             Version   Required
---------------------- --------- ----------
QBCore Framework       Latest    Yes
ox_lib                 Latest    Yes
```

---

## Installation

### 1. Download & Extract

```bash
# Clone from GitHub
git clone https://github.com/MnCLosSantos/mnc-vehiclemanager.git

# OR download ZIP from Releases
```

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-vehiclemanager/
```

### 2. Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure mnc-vehiclemanager
```

### 3. File Setup

The script **automatically creates** the following file:
- `vehiclesaves.lua`: Stores saved vehicle data.

> No additional database setup is required — data is saved directly to `vehiclesaves.lua`.

### 4. Configure Permissions

Ensure admins have the necessary permissions:

```lua
# ACE Permissions (recommended)
add_ace group.admin command allow
```

> The script also supports QBCore admin checks via `QBCore.Functions.HasPermission(src, 'admin')`.

---

## Configuration

### Pricing Configuration

pricing logic:

```javascript
const pricingConfig = {
  basePrices: {
    compacts: 15000,
    sedans: 25000,
    suvs: 35000,
    coupes: 30000,
    muscle: 40000,
    sportsclassics: 50000,
    sports: 60000,
    super: 100000,
    motorcycles: 20000,
    offroad: 30000,
    industrial: 25000,
    utility: 20000,
    vans: 25000,
    cycles: 5000,
    boats: 50000,
    helicopters: 150000,
    planes: 200000,
    service: 20000,
    emergency: 30000,
    military: 50000,
    commercial: 40000,
    trains: 100000
  },
  brandMultipliers: {
    Albany: 0.9,
    Annis: 1.1,
    Benefactor: 1.2,
    // ... (full list is in the resource)
    Unknown: 0.9
  },
  typeMultipliers: {
    automobile: 1.0,
    bike: 0.8,
    boat: 1.2,
    heli: 1.5,
    plane: 1.7,
    train: 2.0
  },
  premiumShopMultiplier: {
    luxury: 1.3,
    import: 1.4,
    airshop: 1.5,
    boatshop: 1.2,
    moto: 1.1,
    pdm: 1.0
  }
};
```

> Prices are calculated as:  
> `base × brand × type × shop × (1 ± 5% random)`

---

## Controls

| Key | Action |
|-----|--------|
| `/vehiclelua` | Open the vehicle editor (must be in a vehicle) |
| `Escape` | Close the editor or any modal |

---

## UI Features

### Editor Layout
- **Left Panel**: Lists all vehicles **in** and **not in** QB-Core `vehicles.lua`.
- **Right Panel**: Form to edit and save vehicle entries.
- **Settings Button** (top-right): Toggle theme, enable auto-pricing.
- **Export All Button**: Bulk export all vehicles with filtering options.

### Export All Modal
- **Fallback Shop**: Default shop if none defined.
- **Exclude Emergency Vehicles**: Skips class 18 (police, fire, etc.).
- **Auto-Price All**: Applies dynamic pricing to every vehicle.
- **Progress Bar**: Real-time feedback during export.

---

## How to Use

1. **Enter any vehicle** in-game.
2. Type `/vehiclelua` to open the editor.
3. Modify fields as needed:
   - Use dropdowns or type directly.
   - Enable **Auto-Price** in settings for dynamic pricing.
4. Click **"Save to vehiclesaves.lua"**.
5. Optionally use **Export All** to batch-save missing vehicles.

> Saved entries in `vehiclesaves.lua` can later be merged into `qb-core/shared/vehicles.lua`.

---
## Preview

1. **Main UI page** triggered by command.
![alt text](<FiveM® by Cfx.re - Midnight Club Los Santo's 29_10_2025 01_40_51.png>)

2. **Main UI page** triggered by command in light mode.
![alt text](<FiveM® by Cfx.re - Midnight Club Los Santo's 29_10_2025 01_37_18.png>)

3. **Settings modal** triggered by settings button.
![alt text](<FiveM® by Cfx.re - Midnight Club Los Santo's 29_10_2025 01_40_29.png>)

4. **Export all modal** triggered by export all button.
![alt text](<FiveM® by Cfx.re - Midnight Club Los Santo's 29_10_2025 01_40_18.png>)

## Download and Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6)

[![GitHub](https://img.shields.io/badge/GitHub-View%20Script-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/MnCLosSantos/mnc-vehiclemanager)

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

**Made with ❤️ for the FiveM Community**  
*Version 2.3.7 — Fully Updated & Optimized*