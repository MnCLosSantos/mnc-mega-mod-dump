# 🚗 MNC Vehicle Rentals

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
A **comprehensive vehicle rental system** for QBCore-based FiveM servers featuring immersive UI designs, temporary vehicle insurance/registration/inspection, multi-location support, rental limits, refund mechanics, and persistent database tracking. Built with performance and realism in mind.

---

## ✨ Key Features

### 🚙 Rental System
- **Customizable UI styles** with 5 themes (dark/light variants)
- **Categorized vehicle selection** with brands, prices, and categories
- **Hour-based rentals** (1-3 hours) with dynamic pricing
- **Refund system** (10% on early return)
- **Active rental limit** (max 3 per player)
- **Cross-location returns** (return to any rental spot)
- **Vehicle spawning** with fuel, keys, and warp options
- **Required item check** (e.g., driver's license)

### 📝 Temporary Documentation
- **Automatic insurance grant** with expiration
- **Temporary registration & inspection** for rented vehicles
- **Database persistence** for insured/registered/inspected vehicles
- **Expiration handling** with auto-cleanup
- **Disconnect cleanup** to remove active rentals

### 🧑‍💼 Rental Locations & Peds
- **Multiple zones** with unique names, logos, and vehicle lists
- **Ped spawners** with animations and periodic respawn checks
- **Blip creation** for easy location finding
- **3D text prompts** for interaction (open menu or return vehicle)
- **Proximity-based detection** for efficient performance

### 🔒 Security & Limits
- **Rental count tracking** to prevent abuse
- **Plate generation** with "RENT" prefix
- **Vehicle cleanup** on return/expiration
- **Debug mode** for ped spawning logs

### 🛠️ Integration Support
- **Fuel systems**: LegacyFuel, cdn-fuel, ox, standalone
- **Key systems**: QB, standalone
- **Insurance integration** with mnc-insurance (optional)
- **Configurable blips** with sprites, colors, and scales

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| qb-core/shared/vehicles.lua | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes (for database) |
| mnc-insurance | Any | ❌ Optional (for temporary insurance) |

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-rentals/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-rentals/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-rentals/
```

### 2️⃣ Database Setup

The script uses existing tables from mnc-insurance (if enabled):
- `insured_vehicles`
- `registered_vehicles`
- `inspected_vehicles`

No manual SQL import needed if mnc-insurance is installed. Otherwise, create these tables manually if using GrantTemporaryInsurance.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-rentals
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize:

```lua
-- System toggles
Config.GrantTemporaryInsurance = true  -- Requires mnc-insurance
Config.RequireItem = true
Config.RequiredItem = 'driver_license'

-- Vehicle systems
Config.Fuel = 'legacy'  -- 'legacy', 'cdn', 'ox', 'standalone'
Config.Keys = 'qb'      -- 'qb', 'standalone'
Config.Warp = true      -- Warp player into vehicle on spawn

-- Blip settings
Config.Blip = {
    sprite = 811, -- Rental car icon
    color = 3,    -- blue
    scale = 0.8,
    display = 4,
    name = 'Vehicle Rental'
}

-- UI Styles (5 options)
Config.UIStyles = {
    style1 = { primaryBg = 'rgba(32, 33, 36, 0.8)', ... },
    -- ...
}

-- Rental Zones (10+ examples provided)
Config.Zones = {
    [1] = {
        name = 'LS Airport Rentals',
        coords = vector3(-986.64, -2690.21, 13.02),
        spawn = vector4(-989.63, -2706.8, 13.22, 333.45),
        vehicles = {
            {model = 'asbo', name = 'Asbo', rentalPrice = 200, brand = 'Maxwell', category = 'Compacts'},
            -- ...
        },
        logo = 'nui://mnc-rentals/web/images/Trent.png',
        style = 'style2',
        ped = {
            model = 'a_m_y_business_01',
            coords = vector4(-986.64, -2690.21, 14.02, 160.0),
            animationSet = {
                dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                anims = {'idle_a', 'idle_b', 'idle_c'}
            }
        },
    },
    -- More zones...
}
```

### 5️⃣ Add Items to QBCore

No new items needed beyond vehicles. If RequireItem is true, ensure 'driver_license' exists in qb-core/shared/items.lua.

---

## ⚙️ Configuration Guide

### 🚗 Vehicle Configuration (per zone)

```lua
vehicles = {
    {model = 'asbo', name = 'Asbo', rentalPrice = 200, brand = 'Maxwell', category = 'Compacts'},
    {model = 'asea', name = 'Asea', rentalPrice = 300, brand = 'Declasse', category = 'Sedans'},
    -- Add more...
}
```

### 🧑 Ped Configuration (per zone)

```lua
ped = {
    model = 'a_m_y_business_01',
    coords = vector4(x, y, z, heading),
    animationSet = {
        dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
        anims = {'idle_a', 'idle_b', 'idle_c'}
    }
}
```

### 🎨 UI Style Configuration

```lua
style = 'style2',  -- Choose from style1 to style5
logo = 'nui://mnc-rentals/web/images/Trent.png',
```

---

## 🎮 Controls & Usage

### Player Controls
| Key | Action |
|-----|--------|
| `E` | Open rental menu (at NPC) or return vehicle (at NPC/spawn point) |

### Rental Process
1. Approach rental NPC (3D text prompt)
2. Press E to open UI
3. Select category and vehicle
4. Choose duration (1-3 hours)
5. Confirm rental (deducts cash)
6. Vehicle spawns with full fuel and keys
7. Return to any location's NPC or spawn point for refund

### Admin/Dev Tools
- Enable Config.Debug for ped spawning logs
- Monitor console for expiration/cleanup messages

---

## 🧪 System Mechanics

### Rental System
1. **Processing**: Check money, item, and rental limit
2. **Spawning**: Load model, set plate, colors, fuel, keys
3. **Documentation**: Grant temp insurance/registration/inspection
4. **Tracking**: Store in activeRentals table with endTime
5. **Expiration**: Auto-remove docs after time; notify player
6. **Return**: Refund 10%, delete vehicle, clear records
7. **Cleanup**: On disconnect or server cleanup thread

### Ped System
1. **Spawning**: Create ped on resource start; network sync
2. **Animations**: Random idle anims from set
3. **Respawn**: Check every minute; respawn if missing
4. **Cleanup**: Delete on resource stop or manual cleanup

### Database Integration
- Insert into insured/registered/inspected on rental
- Delete on return/expiration
- Load checks to avoid duplicates

---

## 🔧 Troubleshooting

### Common Issues

**UI not opening:**
- Ensure ox_lib is started
- Check NUI focus (SetNuiFocus)
- Verify web/index.html loads

**Peds not spawning:**
- Enable Config.Debug for logs
- Check model hash loading
- Verify animation dict exists

**Insurance not granting:**
- Install mnc-insurance
- Set Config.GrantTemporaryInsurance = true
- Check database tables exist

**Vehicle not spawning:**
- Verify model in qb-core/shared/vehicles.lua
- Check spawn coords are clear
- Look for hash loading errors

**Returns not working:**
- Ensure in proximity of NPC or spawn
- Check activeRentals table in client
- Verify plate matches

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
- ✨ Core rental system with UI and multi-zone support
- ✨ Temporary insurance/registration/inspection integration
- ✨ Ped spawner with animations and respawn logic
- ✨ Rental limits, refunds, and cross-location returns
- ✨ Fuel and key system integrations
- ✨ Database persistence for vehicle docs
- ✨ Blip and 3D text prompts
- ✨ Cleanup threads for expirations and disconnects

**Improvements:**
- 🔧 Optimized proximity loops for performance
- 🔧 Enhanced NUI with category sorting and vehicle images
- 🔧 Added debug mode for ped management

**Bug Fixes:**
- 🐛 Fixed ped netID sync issues
- 🐛 Resolved vehicle plate duplicates
- 🐛 Corrected refund calculations
- 🐛 Fixed cleanup on resource stop

---

**Enjoy realistic vehicle rentals on your FiveM server! 🚗**
