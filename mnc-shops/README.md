# 🏪 MNC Shops System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A **dynamic shop system** for QBCore-based FiveM servers.  
This script provides a **modern shop interface** with categorized items, stock management, payment options (cash/bank), and proximity-based or target-based interactions. It includes **customizable shop zones**, **ped spawners**, and a **responsive UI** with search functionality. Fully optimized for **ox_lib**, **ox_inventory** or **qb-inventory**, and **qb-target** (optional).

---

## ✨ Key Features

- 🛒 **Interactive Shop UI**  
  - Modern dashboard with categorized item browsing.  
  - Search functionality to filter items by name.  
  - Cart system for bulk purchases.  
  - Customizable UI styles (`style1`, `style2`, etc.) per shop zone.  
  - Payment options: cash, bank, or split payments.

- 📍 **Flexible Shop Zones**  
  - Proximity-based interaction (press `E`) or qb-target integration.  
  - Configurable shop locations with radius-based detection.  
  - Blip support for map visibility.  
  - Ped spawners with idle animations for immersive shopkeepers.  
  - Optional required items for shop access (e.g., membership card).

- 🛠 **Stock Management**  
  - Per-zone stock tracking with automatic restocking on resource start.  
  - Real-time stock updates across clients.  
  - Prevents purchases if stock or inventory space is insufficient.

- 💸 **Payment System**  
  - Supports cash and bank payments.  
  - Validates player funds before purchase.  
  - Inventory checks to ensure players can carry items.

- 🧍 **Ped Spawners**  
  - Spawns shopkeeper peds with configurable models and animations.  
  - Automatic cleanup of orphaned peds on resource start/stop.  
  - Proximity-based ped animation triggers for nearby players.

- 🧹 **Cleanup & Safety**  
  - Automatic ped cleanup on resource stop.  
  - Notification cooldowns to prevent spam.  
  - Inventory full and insufficient funds notifications.  
  - Robust error handling for missing items or zones.

---

## 📋 Requirements

```bash
Dependency             Version   Required
---------------------- --------- ----------
QBCore Framework       Latest    ✅ Yes
ox_lib                 Latest    ✅ Yes
ox_inventory           Latest    ⬜ Optional
qb-inventory           Latest    ⬜ Optional
qb-target              Latest    ⬜ Optional
```

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone from GitHub
git clone https://github.com/YourUsername/mnc-shops.git

# OR download ZIP from Releases
```

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-shops/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure mnc-shops
```

### 3️⃣ Configure Items

Ensure items are defined in `qb-core/shared/items.lua`. Example:

```lua
['sandwich'] = {
    ['name'] = 'sandwich',
    ['label'] = 'Sandwich',
    ['weight'] = 200,
    ['type'] = 'item',
    ['image'] = 'sandwich.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A tasty sandwich'
},

['water_bottle'] = {
    ['name'] = 'water_bottle',
    ['label'] = 'Water Bottle',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'water_bottle.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A bottle of water'
},

['joint'] = {
    ['name'] = 'joint',
    ['label'] = 'Joint',
    ['weight'] = 10,
    ['type'] = 'item',
    ['image'] = 'joint.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Hand-rolled cannabis joint'
},
```

### 4️⃣ Configure Shop Zones

Edit `config.lua` to customize shop zones, categories, and items. Example:

```lua
Config.Zones = {
    {
        name = 'food',
        coords = vector3(24.47, -1346.62, 29.5),
        radius = 1.5,
        uiStyle = 'style1',
        title = '24/7 Supermarket',
        categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
        useAnywhere = false,
        ped = {
            model = 's_m_m_cntrybar_01',
            coords = vector4(24.2, -1345.8, 29.49, 270.0),
            animationSet = {
                dict = 'amb@world_human_stand_impatient@male@idle_a',
                anims = {'idle_a', 'idle_b', 'idle_c'}
            }
        },
        blip = {
            enabled = true,
            sprite = 52,
            color = 2,
            scale = 0.6,
            name = '24/7 Supermarket'
        }
    }
}

Config.Products = {
    ['food'] = {
        { name = 'sandwich', price = 4, amount = 50 },
        { name = 'water_bottle', price = 4, amount = 50 }
    },
    ['weedshop'] = {
        { name = 'joint', price = 10, amount = 50 }
    }
}
```

### 5️⃣ Optional: Enable qb-target

To use qb-target instead of proximity-based interaction, set in `config.lua`:

```lua
Config.UseTarget = true
```

Ensure `qb-target` is running in your server.

---

## ⚙️ Configuration

### 🎯 Shop Zone Setup

```lua
Config.Zones = {
    {
        name = 'food', -- Unique identifier for the zone
        coords = vector3(24.47, -1346.62, 29.5), -- Interaction point
        radius = 1.5, -- Interaction radius
        uiStyle = 'style1', -- UI style (style1, style2, etc.)
        title = '24/7 Supermarket', -- Shop title in UI
        categories = {'food', 'drinks'}, -- Item categories to display
        useAnywhere = false, -- Set to true for command-based access
        requiredItem = nil, -- Optional: Item required to access shop
        staffJobs = nil, -- Optional: Restrict to specific jobs
        ped = {
            model = 's_m_m_cntrybar_01', -- Ped model
            coords = vector4(24.2, -1345.8, 29.49, 270.0), -- Ped spawn location
            animationSet = {
                dict = 'amb@world_human_stand_impatient@male@idle_a',
                anims = {'idle_a', 'idle_b', 'idle_c'}
            }
        },
        blip = {
            enabled = true,
            sprite = 52, -- Store blip
            color = 2, -- Green
            scale = 0.6,
            name = '24/7 Supermarket'
        }
    }
}
```

### 🛍 Product Configuration

```lua
Config.Products = {
    ['food'] = {
        { name = 'sandwich', price = 4, amount = 50 },
        { name = 'water_bottle', price = 4, amount = 50 }
    },
    ['weedshop'] = {
        { name = 'joint', price = 10, amount = 50 },
        { name = 'rolling_paper', price = 2, amount = 1000 }
    }
}
```

---

## 🎮 Controls

| Key | Action |
|-----|--------|
| `E` | Open shop (proximity mode, when `UseTarget = false`) |
| `Escape` | Close shop UI |

---

## 📞 Support & Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/your-link)

---

## 📜 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
