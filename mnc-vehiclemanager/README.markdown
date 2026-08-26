# 🚗 MNC Vehicle.LUA Manager

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.4.2-brightgreen.svg)]()

---
![mncvehiclemanager](https://github.com/user-attachments/assets/343e82b9-83a0-4863-84d2-e303b6274db8)

## 🌟 Overview

A **comprehensive vehicle management system** for QBCore-based FiveM servers.  
This script provides an **intuitive UI** for editing and saving vehicle information directly from in-game vehicles, with dynamic dropdowns, auto-pricing, and theme customization.  
Fully optimized for **QBCore Framework**, **ox_lib notifications**, and seamless integration with server-side vehicle data storage.

---

## ✨ Key Features

- 🖼️ **Intuitive UI Editor**  
  - Accessible via the `/vehiclelua` command while in a vehicle.  
  - Auto-populates vehicle details (model, name, brand, category, type, shop).  
  - Dynamic dropdowns for brands, categories, types, and shops based on QB-Core shared vehicle data.  
  - Supports light and dark themes with smooth transitions.

- 💰 **Dynamic Auto-Pricing**  
  - Calculates vehicle prices based on category, brand, type, and shop.  
  - Configurable pricing with base prices, brand multipliers, type multipliers, and shop premiums.  
  - Optional randomization (±5%) for price variation.  
  - Toggleable auto-pricing in the settings modal.

- 📝 **Vehicle Data Saving**  
  - Saves vehicle data to `vehiclesaves.lua` with proper formatting.  
  - Admin-only access with ACE permissions or QBCore admin checks.  
  - Success/error notifications for save operations.

- 🔍 **Dynamic Dropdowns**  
  - Populates dropdowns with unique values from QB-Core’s shared vehicle data.  
  - Searchable and filterable inputs with autocomplete on Enter key.  
  - Smooth dropdown behavior with scrollable lists.

- 🎨 **Customization Options**  
  - Light and dark theme toggle in the settings modal.  
  - Responsive UI with animated transitions and gradient effects.  

- 🧹 **Safety & Optimization**  
  - Automatic UI cleanup on close or Escape key press.  
  - Prevents unauthorized access with permission checks.  
  - Optimized for performance with minimal server load.
---
## ✨ Preview Image

<img width="695" height="712" alt="vehiclemangerv1" src="https://github.com/user-attachments/assets/16400fe6-2814-4c2c-894f-dd1bcf396f9e" />

---

## 📋 Requirements

```bash
Dependency             Version   Required
---------------------- --------- ----------
QBCore Framework       Latest    ✅ Yes
ox_lib                 Latest    ✅ Yes
```

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone from GitHub
git clone https://github.com/MnCLosSantos/mnc-vehiclemanager.git

# OR download ZIP from Releases
```

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-vehiclemanager/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure mnc-vehiclemanager
```

### 3️⃣ File Setup

The script **automatically creates** the following file:
- `vehiclesaves.lua`: Stores saved vehicle data.

No additional database setup is required, as vehicle data is saved to `vehiclesaves.lua`.

### 4️⃣ Configure Permissions

Ensure admins have the necessary permissions for saving vehicles:

```lua
# Add to server permissions (e.g., ACE permissions)
add_ace group.admin command allow
```

Alternatively, the script checks for QBCore admin permissions (`QBCore.Functions.HasPermission(src, 'admin')`) in this case just set permissions through admin menu in server.

---

## ⚙️ Configuration

### 🎯 Pricing Configuration

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
    // ... (other brands)
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

---

## 🎮 Controls

| Key | Action |
|-----|--------|
| `/vehiclelua` | Open the vehicle editor (must be in a vehicle) |
| `Escape` | Close the editor or settings modal |

---

## 📞 Download and Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6)

[![GitHub](https://img.shields.io/badge/GitHub-View%20Script-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/MnCLosSantos/mnc-vehiclemanager)

---

**Made with ❤️ for the FiveM Community**  
*Version 1.4.2 — Fully Updated & Optimized*
