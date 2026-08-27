# 🚬 MNC Dogends System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
A **scavenging and crafting system** for QBCore-based FiveM servers that allows players to pick up cigarette butts from the ground, collect lighters, and roll their own cigarettes using butts, tobacco pouches, filter packs, and rolling papers. Features immersive animations, progress bars, minigames, and persistent item metadata for realistic resource management. Built with performance and roleplay immersion in mind.

---

## ✨ Key Features

### 🔍 Scavenging System
- **Interactive prop pickups** using qb-target for cigarette butts and lighters
- **Multiple prop models** supported (ashtrays, cigarette piles, lighters)
- **Minigame integration** (WASD skill check) before pickup
- **Progress bars** with animations for realistic interaction
- **Audio feedback** with random pickup sounds
- **Anti-dupe checks** to prevent multiple pickups from the same entity
- **Optional entity deletion** after pickup (for lighters or butts)

### 🛠️ Cigarette Rolling System
- **Multi-path rolling**: Use collected butts or fresh tobacco pouches
- **Persistent metadata**: Track remaining grams in tobacco pouches and filters in packs
- **Batch rolling**: Select quantities (1-10) with scaled time and requirements
- **Filter variants**: Normal, slim, and mint options with special outputs (e.g., mint cigarettes)
- **Required items**: Rolling papers, filters, and either butts or tobacco
- **Progress bars and animations** for rolling process
- **Failure handling**: Cancel mid-progress with notifications

### 📋 Menu System
- **Intuitive ox_lib menus** for selecting rolling methods, filter packs, and quantities
- **Dynamic options**: Only shows available pouches/packs with sufficient resources
- **Usable item triggers**: Rolling machine item opens the main menu
- **Informational displays**: Show remaining grams/filters when using pouches/packs

### 📊 Item Management
- **Configurable requirements**: Butts per cigarette, grams per roll
- **Variant outputs**: Standard or mint cigarettes based on filters
- **Inventory integration**: Uses qb-inventory for item addition/removal
- **Metadata updates**: Automatically updates item descriptions with remaining amounts
- **Rollback safety**: Restores items on failure (e.g., insufficient resources)

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| qb-inventory | Latest | ✅ Yes |
| qb-target | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-dogends/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-dogends/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-dogends/
```

### 2️⃣ Database Setup

No manual SQL import needed! The script uses QBCore's item system and does not require additional tables.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure mnc-dogends
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize:

```lua
-- Core settings
Config.CoreName    = 'qb-core'
Config.Target      = 'qb-target'
Config.Inventory   = 'qb-inventory'
Config.Notify      = 'ox_lib'

-- Pickup configuration
Config.PickupItem      = 'cig_butt'
Config.PickupAmount    = 1
Config.LighterItem     = 'lighter'
Config.LighterAmount   = 1
Config.RequiredButts   = 5
Config.TobaccoPerRoll  = 0.5

-- Times and minigame
Config.SearchTime      = 3500
Config.RollTime        = 8000
Config.Minigame = {
    Enabled    = true,
    Type       = "wasd",
    Difficulty = {"easy", "easy", "medium"},
}

-- Prop models
Config.PropModels = { ... }  -- List of ashtray/cigarette props
Config.LighterModels = { ... }  -- List of lighter props

-- Tobacco and filter packs
Config.TobaccoPouches = { ... }  -- Various sizes and types
Config.FilterPacks = { ... }     -- Slim, normal, mint

-- Output items
Config.OutputItems = {
    default     = 'roll_up',
    mint        = 'roll_up_mint',
}
```

### 5️⃣ Add Items to QBCore

Add all items from the config to `qb-core/shared/items.lua`. Examples:

```lua
-- Pickups
['cig_butt'] = {
    ['name'] = 'cig_butt',
    ['label'] = 'Cigarette Butt',
    ['weight'] = 1,
    ['type'] = 'item',
    ['image'] = 'cig_butt.png',
    ['unique'] = false,
    ['useable'] = false,
    ['shouldClose'] = false,
    ['description'] = 'Used cigarette butt'
},

-- Tobacco
['tobacco_classic_125'] = {
    ['name'] = 'tobacco_classic_125',
    ['label'] = 'Classic Tobacco 12.5g',
    ['weight'] = 125,
    ['type'] = 'item',
    ['image'] = 'tobacco.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Tobacco pouch'
},

-- Filters
['filter_pack_slim'] = {
    ['name'] = 'filter_pack_slim',
    ['label'] = 'Slim Filters',
    ['weight'] = 50,
    ['type'] = 'item',
    ['image'] = 'filters.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Pack of slim filters'
},

-- Tools
['rolling_machine'] = {
    ['name'] = 'rolling_machine',
    ['label'] = 'Rolling Machine',
    ['weight'] = 200,
    ['type'] = 'item',
    ['image'] = 'rolling_machine.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Machine for rolling cigarettes'
},

-- Outputs
['roll_up'] = {
    ['name'] = 'roll_up',
    ['label'] = 'Roll-Up Cigarette',
    ['weight'] = 5,
    ['type'] = 'item',
    ['image'] = 'roll_up.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Hand-rolled cigarette'
},
```

---

## ⚙️ Configuration Guide

### 🛠️ Item Configuration

All core items are defined in `config.lua`. Customize requirements, models, and outputs as needed.

### 🔧 Prop Models

```lua
Config.PropModels = {
    `ng_proc_cigbuts01a`,
    `ng_proc_cigbuts02a`,
    -- Add more ashtray hashes
}
```

### 📦 Tobacco & Filter Packs

```lua
Config.TobaccoPouches = {
    tobacco_classic_125 = { grams = 12.5, max_rolls = 30 },
    -- Add more variants
}

Config.FilterPacks = {
    filter_pack_slim   = 45,
    -- Add more packs
}
```

---

## 🎮 Controls & Usage

### Player Controls
| Action | Description |
|--------|-------------|
| Approach prop & interact | Use qb-target to pick up butts/lighters |
| Use rolling machine item | Opens main rolling menu |
| Select options in menu | Choose method, filters, and quantity |

### Rolling Process
1. Collect butts or buy tobacco/filter packs
2. Use rolling machine item to open menu
3. Select rolling method (butts or tobacco)
4. Choose filter pack
5. Select quantity (1-10)
6. Complete progress bar and animation

### Viewing Remaining Resources
- Use tobacco pouch: Shows remaining grams and estimated rolls
- Use filter pack: Shows remaining filters

---

## 🧪 System Mechanics

### Scavenging System
1. **Target Props**: qb-target adds options to supported models
2. **Checks**: Ensures not already searched, runs minigame
3. **Pickup**: Adds items to inventory, plays sound, optional delete entity

### Rolling System
1. **Menu Flow**: Checks inventory for valid options
2. **Consumption**: Removes papers, butts/tobacco, decreases filter count
3. **Metadata**: Updates pouch/pack info with remaining amounts
4. **Output**: Adds rolled cigarettes (default or mint variant)
5. **Rollback**: Restores items if process fails midway

### Item Persistence
- **Metadata**: Uses QBCore's item.info for remaining_grams/remaining_filters
- **Descriptions**: Dynamically updates item descriptions in inventory

---

## 🔧 Troubleshooting

### Common Issues

**Props not targetable:**
- Ensure qb-target is started before mnc-dogends
- Check prop hashes match in config.lua

**Items not adding:**
- Verify qb-inventory exports are available
- Check server console for item config errors
- Confirm CanAddItem export exists

**Menus not opening:**
- Ensure ox_lib is properly configured
- Check for inventory item existence
- Look for client console errors on use

**Metadata not updating:**
- Verify item slots are correctly handled
- Check for QBCore version compatibility

**Sounds not playing:**
- Confirm sound names exist in GTA5 audio files
- Check entity existence during playback

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

### Version 1.0.0 (Initial Release)
**New Features:**
- ✨ Core scavenging system for cigarette butts and lighters
- ✨ Rolling system with butts and tobacco paths
- ✨ Persistent metadata for pouches and packs
- ✨ Minigame and progress bar integration
- ✨ ox_lib menus for user-friendly interaction
- ✨ qb-target support for prop interactions
- ✨ Audio and animation enhancements

**Improvements:**
- 🔧 Optimized client-side entity tracking
- 🔧 Enhanced server-side item management with rollbacks
- 🔧 Added configurable times and requirements

**Bug Fixes:**
- 🐛 Fixed duplicate pickups from same entity
- 🐛 Resolved metadata not initializing on fresh items
- 🐛 Corrected amount scaling for batch rolling
- 🐛 Fixed notifications not showing on failures

---

**Enjoy scavenging and rolling on your FiveM server! 🚬**
