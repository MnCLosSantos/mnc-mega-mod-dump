# 💨 MNC Vapes System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A **comprehensive vaping system** for QBCore-based FiveM servers featuring craftable vape devices, customizable juices, realistic puffing animations with particle effects, persistent device management, portable crafting tables, and job-restricted stations. Built with performance and immersion in mind.

---

## ✨ Key Features

### 🎭 Vape Usage & Effects
- **Immersive prop-based animations** with exhale particle effects (smoke clouds)
- **Configurable puff cooldowns** and exhale durations per device
- **Multiple effects**: running speed boost, infinite stamina, strength increase, health/food regen, drunk/psycho walk, screen effects (outOfBody, cameraShake, fog, confusion, white overlay)
- **Cancel puffing** with automatic prop cleanup
- **Automatic prop detachment** on death/respawn
- **Battery drainage** and low-battery warnings
- **Juice consumption** per puff with empty tank notifications

### 🔋 Persistent Device Management
- **Database-backed vape tracking** across sessions (battery, juice, coil, tank, flavor)
- **Unique IDs** for each vape and juice bottle
- **Dynamic descriptions** updating in real-time (battery %, juice ml, puffs remaining)
- **Management menus**: fill juice, charge battery, install/remove coils/tanks
- **Coil degradation** with puff counting and replacement
- **Tank swapping** with capacity upgrades (5ml, 8ml, 12ml)
- **Charger item** for battery restoration

### 🏭 Crafting & Assembly System
- **Placeable crafting tables** with SQL persistence (juice and vape tables)
- **Owner-only pickup** protection with distance checks
- **Table limit per player** (tracked via citizen ID)
- **Multiple table types**: juice mixing, vape assembly
- **Recipe system** for juices and devices with ingredients, craft times, and amounts
- **Progress bars** for crafting (ox_lib or QB style)
- **Job-locked static stations** with prop spawning and qb-target integration
- **Batch crafting** for coils, tanks, bottles, and sets

### 📦 Pack & Set System
- **Starter sets** (box, disposable, weed) with opening progress and contents
- **Coil packs** (3x, 6x, 10x) that unpack into individual coils
- **Packaging crafting** for sets (box, disposable, weed)
- **Empty bottles** in various sizes (30ml, 60ml, 120ml) for juice storage
- **Device shells** and components (batteries, wiring, LCD) as craftable parts

### 🛠️ Customization Options
- **Multiple vape types**: disposable, weed pen, box mod
- **Juice flavors** with effects, ml sizes, and types (regular/weed)
- **Prop attachments** with configurable offsets and rotations
- **Tank capacities** and coil lifespans per device
- **Crafting ingredients** from base materials (plastic, copper, aluminum, etc.)

### 📊 Integration Features
- **QB Inventory sync** for item data and descriptions
- **QB Target** for interactive zones and props
- **OX Lib** for menus, notifications, and progress bars
- **Stress relief** integration with qb-hud
- **Debug mode** for development logging

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| qb-inventory | Latest | ✅ Yes |
| qb-target | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-vapes/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-vapes/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-vapes/
```

### 2️⃣ Database Setup

The script **automatically creates** required tables on first start:

- `mnc_vapes_tables` - Stores placed crafting tables
- `mnc_vape_data` - Tracks vape device states
- `mnc_juice_data` - Tracks juice bottle states

No manual SQL import needed!

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-vapes
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize:

```lua
-- Debug settings
Config.DebugMode = false

-- Main settings
Config.PuffsPerMl = 25      -- max amount of puffs per 1ml of vape juice
Config.ChargeTime = 80000   -- how long batterys take to charge
Config.FillTime = 10000     -- how long it takes to refill a vape tank
Config.CoilInstallTime = 5000    -- how long it takes to install coil
Config.TankInstallTime = 5000    -- how long it takes to install tank
Config.PuffCooldown = 5000    -- how long player must wait between puffs
Config.PropBone = 18905   -- prop bone left hand

-- Job locked juice crafting location
Config.CraftingStations = {
    {
        coords = vector3(2984.09, 4462.66, 48.64),   -- where prop spawns
        heading = 180.0,                             -- prop rotation
        label = 'Vape Juice Station',              -- qb-target label
        job = 'vapeshop',                        -- job ristriction
        minGrade = 0,                                 -- grade ristriction
        prop = 'v_ret_ml_tablea',                 -- prop used
    },
    -- Add more if needed
}

-- Placeable juice crafting table
Config.PlaceableTableItem = 'juice_table'       -- qb-target tabel
Config.TableProp = 'v_ret_ml_tablea'   -- prop used
Config.TableModel = `v_ret_ml_tablea`   -- model used
Config.TablePickupDistance = 2.2                 -- distance to interact

-- Tank options
Config.Tanks = {
    ['5ml_tank'] = {      -- tank item name
      label = '5ml Tank',  -- tank label in menu
      size = 5             -- ml the tank holds
    },
    -- Add more
}

-- Vape settings
Config.Vapes = {
    ['dispo_vape'] = {                          -- item name
        label = 'Disposable Vape',              -- menu label
        prop = 'ba_prop_battle_vape_01',        -- prop used
        tankSize = 5,                           -- fallback tank
        mlPerPuff = 0.04,                       -- ml used per puff
        maxCoilPuffs = 250,                     -- how many puffs the coil has
        maxBattery = 100,                       -- max battery
        canChangeCoil = false,                  -- keep false
        canChangeTank = false,                  -- keep false
        juiceType = 'regular',                  -- juice type allowed
        puffAnimation = 'WORLD_HUMAN_SMOKING',  -- animation used
        exhaleTime = 2000,                      -- smoke length
        attachPos = {0.13, 0.03, 0.0},          -- x, y, z offsets
        attachRot = {180.0, 230.0, 20.0},        -- pitch, roll, yaw rotations
    },
    -- Add more
}

-- Juice settings
Config.VapeJuices = {
    ['juice_mango_30'] = {
        label = 'Mango 30ml',
        ml = 30,
        type = 'regular',
        effects = {
            { name = 'runningSpeedIncrease', duration = 20000 },
            -- Add more effects
        },
    },
    -- Add more
}

-- Crafting recipes
Config.CraftingRecipes = {
    {
        result = 'juice_mango_30',
        amount = 1,
        time = 10000,
        ingredients = {
            { item = 'mango_extract', amount = 1 },
            { item = 'base_liquid', amount = 30 }
        }
    },
    -- Add more
}

-- Vape crafting recipes
Config.VapeCraftingRecipes = {
    {
        result = 'vape_battery',
        amount = 1,
        time = 5000,
        ingredients = {
            { item = 'copper', amount = 3 },
            { item = 'plastic', amount = 2 }
        }
    },
    -- Add more
}
```

### 5️⃣ Add Items to QBCore

Add all items from the config to `qb-core/shared/items.lua`. Examples:

```lua
-- Vapes
['dispo_vape'] = {
    ['name'] = 'dispo_vape',
    ['label'] = 'Disposable Vape',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'dispo_vape.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Disposable vaping device'
},

-- Juices
['juice_mango_30'] = {
    ['name'] = 'juice_mango_30',
    ['label'] = 'Mango Juice 30ml',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'juice_mango_30.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Mango flavored vape juice'
},

-- Components
['vape_coil'] = {
    ['name'] = 'vape_coil',
    ['label'] = 'Vape Coil',
    ['weight'] = 20,
    ['type'] = 'item',
    ['image'] = 'vape_coil.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Replacement coil for vapes'
},

-- Tables
['juice_table'] = {
    ['name'] = 'juice_table',
    ['label'] = 'Juice Crafting Table',
    ['weight'] = 5000,
    ['type'] = 'item',
    ['image'] = 'juice_table.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Portable table for mixing vape juices'
},
```

---

## ⚙️ Configuration Guide

### 🎯 Vape Item Configuration

```lua
['dispo_vape'] = {
    label = 'Disposable Vape',
    prop = 'ba_prop_battle_vape_01',
    tankSize = 5,
    mlPerPuff = 0.04,
    maxCoilPuffs = 250,
    maxBattery = 100,
    canChangeCoil = false,
    canChangeTank = false,
    juiceType = 'regular',
    puffAnimation = 'WORLD_HUMAN_SMOKING',
    exhaleTime = 2000,
    attachPos = {0.13, 0.03, 0.0},
    attachRot = {180.0, 230.0, 20.0},
}
```

### 🧪 Juice Item Configuration

```lua
['juice_mango_30'] = {
    label = 'Mango 30ml',
    ml = 30,
    type = 'regular',
    effects = {
        { name = 'runningSpeedIncrease', duration = 20000 },
        { name = 'infiniteStamina', duration = 20000 },
        { name = 'moreStrength', duration = 20000 },
        { name = 'healthRegen', duration = 20000 },
        { name = 'foodRegen', duration = 20000 },
        { name = 'drunkWalk', duration = 20000 },
        { name = 'psycoWalk', duration = 20000 },
        { name = 'outOfBody', duration = 20000 },
        { name = 'cameraShake', duration = 20000 },
        { name = 'fogEffect', duration = 20000 },
        { name = 'confusionEffect', duration = 20000 },
        { name = 'white', duration = 20000 },
    },
}
```

### 🏭 Crafting Recipe Configuration

```lua
-- Juice Recipes
Config.CraftingRecipes = {
    {
        result = 'juice_mango_30',
        amount = 1,
        time = 10000,
        ingredients = {
            { item = 'mango_extract', amount = 1 },
            { item = 'base_liquid', amount = 30 }
        }
    },
    -- Add more
}

-- Vape Recipes
Config.VapeCraftingRecipes = {
    {
        result = 'vape_battery',
        amount = 1,
        time = 5000,
        ingredients = {
            { item = 'copper', amount = 3 },
            { item = 'plastic', amount = 2 }
        }
    },
    -- Add more
}
```

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

## 📜 Changelog

### Version 1.0.0
**New Features:**
- ✨ Initial release with core vaping system
- ✨ Added craftable vapes (disposable, weed pen, box mod)
- ✨ Implemented juice crafting with multiple flavors and effects
- ✨ Created persistent device management with DB tracking
- ✨ Added placeable tables for juice and vape crafting
- ✨ Implemented management menus for filling, charging, parts installation
- ✨ Added pack opening for sets and coil packs
- ✨ Created component crafting (batteries, coils, tanks, bottles)

**Improvements:**
- 🔧 Optimized client-side animations and particle effects
- 🔧 Enhanced server-side data caching for performance
- 🔧 Added job restrictions for static stations
- 🔧 Improved notification system with ox_lib

**Bug Fixes:**
- 🐛 Fixed vape props not attaching properly
- 🐛 Resolved data not saving on server restart
- 🐛 Corrected crafting progress bars not canceling
- 🐛 Fixed table props duplicating on placement
- 🐛 Resolved juice filling not updating descriptions
- 🐛 Fixed coil degradation not tracking puffs
- 🐛 Corrected tank removal not preserving juice

---

## ⚠️ Important Notes

1. **Server Performance**: Tested stable with 128+ players
2. **Database**: Requires oxmysql - MariaDB 10.3+ recommended
3. **Compatibility**: QBCore only - not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS
5. **Support**: Community-driven, no official warranty provided

---

**Enjoy realistic vaping mechanics on your FiveM server! 💨**
