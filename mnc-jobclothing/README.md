# 👔 MNC Job Clothing System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.3.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A **comprehensive job clothing system** for QBCore-based FiveM servers featuring multi-location locker rooms, persistent outfit saving, grade-based permissions, duty requirements, and immersive changing animations. Built with performance, customization, and realism in mind.

---

## ✨ Key Features

### 👕 Outfit Management
- **Persistent outfit storage** in database (per job, location, gender)
- **Save and load custom outfits** with components and props (hats, glasses, etc.)
- **New format support** for all 12 components and 5 props
- **Legacy outfit compatibility** for backward support
- **Outfit icons** selectable from a predefined list (e.g., hanger, shirt, hard-hat)
- **Minimum grade requirements** per outfit for wearing
- **Update and delete options** for existing outfits

### 📍 Multi-Location System
- **Configurable locker rooms** with custom labels and coordinates
- **Job-restricted access** (optional, or public)
- **On-duty requirements** for specific locations
- **Grade-based permissions** for using and adding outfits
- **qb-target integration** for interactive zones
- **Debug mode** for polygon visualization

### 🎭 Changing Mechanics
- **Progress-based changing** with ox_lib bar or circle
- **Uniform equipping** with original clothes backup
- **Civilian clothes revert** option
- **Cooldown on changes** to prevent spam (10 seconds)
- **Cancellation support** during progress
- **Automatic prop and component application**

### 🛡️ Permission System
- **Minimum grade to use** menu (configurable per location)
- **Minimum grade to add/update** outfits (configurable per location)
- **Job-specific restrictions** per locker room
- **Duty status checks** for access

### 📊 Integration Features
- **ox_lib notifications** and progress bars
- **QBCore player data sync** for job/grade/gender
- **Database persistence** with automatic table creation
- **Resource stop cleanup** for zones

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |
| qb-target | Latest | ✅ Yes (for zones) |
| qb-core | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-jobclothing/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-jobclothing/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-jobclothing/
```

### 2️⃣ Database Setup

The script **automatically creates** the required table on first start:

- `job_outfits` - Stores saved outfits with job, location, gender, data, icon, and min_grade

No manual SQL import needed!

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-jobclothing
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize:

```lua
-- Debug mode
Config.Debug = false

-- Progress style
Config.Progress = 'bar'  -- 'bar' or 'circle'

-- Notification duration
Config.DefaultNotifyTime = 5000

-- Zone size
Config.ZoneSize = { x = 2.0, y = 2.0 }

-- Locker room locations
Config.Locations = {
    {
        name = "autoexotics_clothing",
        label = "Auto Exotics Locker Room",
        coords = vector4(538.86, -166.17, 54.66, 185.45),
        job = "autoexotics",                 -- restrict to this job (set to nil for public)
        require_onduty = false,         -- must be on duty
        min_grade_to_use = 0,           -- minimum grade to open menu
        min_grade_to_add = 4,           -- minimum grade to save new outfits
    },
    -- Add more locations as needed
}
```

### 5️⃣ Add Items (Optional)

This script doesn't require new items, but you can add clothing-related items to `qb-core/shared/items.lua` if integrating with inventory systems.

---

## ⚙️ Configuration Guide

### 📍 Location Configuration

```lua
{
    name = "police_locker",
    label = "Police Locker Room",
    coords = vector4(461.74, -995.94, 30.69, 359.05),
    job = "police",
    require_onduty = true,
    min_grade_to_use = 0,
    min_grade_to_add = 4,
}
```

### 🎨 Outfit Icons

Available icons in save menu:
- hanger (Default)
- shirt
- tshirt
- user-tie (Formal/Suit)
- briefcase (Business)
- hard-hat (Construction)
- wrench (Mechanic)
- vest
- vest-patches
- shield-halved (Police)
- handcuffs (Police)
- stethoscope (Medic)
- And more (see client.lua for full list)

---

## 🎮 Controls & Usage

### Player Controls
| Key | Action |
|-----|--------|
| (Interact via qb-target) | Open locker room menu at zone |

### Outfit Management
1. Approach locker room zone
2. Interact to open menu (if permitted)
3. Select saved outfit to wear/manage
4. Choose "Wear Outfit" to equip
5. Use "Civilian Clothes" to revert
6. (If permitted) Save new outfit with name, min grade, icon
7. Update or delete existing outfits

### Admin/High-Grade Usage
- Save new outfits with current appearance
- Set minimum grade requirements
- Choose custom icons
- Overwrite existing outfits
- Delete unwanted outfits

---

## 🧪 System Mechanics

### Outfit Saving
1. **Capture Current Appearance**: Saves all 12 components and 5 props
2. **Database Storage**: Unique per job/location/gender/name
3. **Permission Check**: Requires min_grade_to_add
4. **Update Mode**: Overwrite data while keeping name/grade/icon
5. **Icon Selection**: Enhances menu visuals

### Access Controls
1. **Job Check**: Must match location.job (if set)
2. **Duty Check**: Must be on duty if require_onduty = true
3. **Grade Check**: Player grade >= min_grade_to_use to open menu
4. **Outfit Grade**: Player grade >= outfit.min_grade to wear

### Changing Process
1. **Progress Bar**: 5s for uniform, 4s for civilian
2. **Backup Original**: Stores current clothes before change
3. **Apply Outfit**: Sets components and props
4. **Cooldown**: 10s between changes
5. **Cancellation**: Stops progress and notifies

### Zone Management
1. **qb-target Zones**: Box zones at configured coords
2. **Dynamic Creation**: On script start
3. **Cleanup**: On resource stop

---

## 🔧 Troubleshooting

### Common Issues

**Zones not appearing:**
- Ensure qb-target is started before mnc-jobclothing
- Check Config.Debug = true for poly visualization
- Verify coords in config.lua

**Outfits not saving:**
- Verify oxmysql is properly configured
- Check database connection in server console
- Confirm job_outfits table exists

**Menu not opening:**
- Check job/grade/duty requirements
- Verify player data sync with QBCore
- Look for client console errors

**Permissions denied:**
- Confirm player.job.name matches location.job
- Check player.job.grade.level >= required
- Verify on-duty status if required

**Legacy outfits not loading:**
- Ensure old format keys (tshirt, torso2, etc.) exist in data
- Script auto-detects and applies fallback

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.3.0
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

### Version 1.3.0 (Current Release)
**New Features:**
- ✨ Added outfit icons with selectable options in save menu
- ✨ Implemented min_grade per outfit for wearing restrictions
- ✨ Created new outfit format with all 12 components and 5 props
- ✨ Added legacy fallback for old saved outfits
- ✨ Implemented update outfit functionality (overwrite with current appearance)
- ✨ Added delete outfit option with confirmation

**Improvements:**
- 🔧 Enhanced menu with ox_lib context and submenus
- 🔧 Improved notification system with custom durations
- 🔧 Added progress cancellation support
- 🔧 Optimized outfit application with better prop handling
- 🔧 Enhanced database schema with automatic column additions (icon, min_grade)

**Bug Fixes:**
- 🐛 Fixed outfits not loading for certain genders
- 🐛 Resolved prop indices not clearing properly
- 🐛 Corrected grade checks causing menu denial
- 🐛 Fixed duplicate outfit inserts with ON DUPLICATE KEY UPDATE
- 🐛 Resolved zone cleanup not working on resource stop

---

### Version 1.2.0
**New Features:**
- ✨ Added multi-location support with configurable locker rooms
- ✨ Implemented job and duty restrictions per location
- ✨ Created grade-based permissions for menu access and saving
- ✨ Added progress bars for changing clothes (bar/circle)
- ✨ Implemented uniform tracking with hasUniform flag

**Improvements:**
- 🔧 Refactored client menu with ox_lib integration
- 🔧 Enhanced server events for outfit fetching/saving
- 🔧 Added cooldown on uniform changes
- 🔧 Improved original clothes backup/restore

**Bug Fixes:**
- 🐛 Fixed multiple changes causing clothing glitches
- 🐛 Resolved server crashes on invalid player data
- 🐛 Corrected gender detection for outfit filtering
- 🐛 Fixed qb-target zones not registering properly

---

### Version 1.1.0
**New Features:**
- ✨ Initial outfit saving system with database persistence
- ✨ Added basic menu for selecting outfits
- ✨ Implemented component variation setting
- ✨ Created qb-target zone system

**Improvements:**
- 🔧 Optimized client-side outfit application
- 🔧 Enhanced notification system with ox_lib

**Bug Fixes:**
- 🐛 Fixed props not attaching correctly
- 🐛 Resolved effects persisting after change
- 🐛 Corrected database query errors

---

### Version 1.0.0 (Beta)
**New Features:**
- ✨ Core job clothing system
- ✨ Basic uniform equipping
- ✨ Database table creation

**Improvements:**
- 🔧 Initial QBCore integration
- 🔧 Basic permission checks

**Bug Fixes:**
- 🐛 Fixed initial loading issues

---

## ⚠️ Important Notes

1. **Server Performance**: Tested stable with 128+ players
2. **Database**: Requires oxmysql - MariaDB 10.3+ recommended
3. **Compatibility**: QBCore only - not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS
5. **Support**: Community-driven, no official warranty provided

---

**Enjoy customizable job clothing on your FiveM server! 👔**
