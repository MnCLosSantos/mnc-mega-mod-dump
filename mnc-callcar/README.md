# 🚗 MNC CallCar - Valet Vehicle Delivery

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A **comprehensive valet service system** for QBCore-based FiveM servers that allows players to call their garaged vehicles for delivery. Features immersive NPC-driven delivery, key handoff animations, dynamic fees, and seamless integration with vehicle states. Built with performance and realism in mind.

---

## ✨ Key Features

### 🚙 Vehicle Delivery System
- **Menu-based selection** of garaged vehicles with detailed stats (fuel, condition, garage location)
- **Dynamic delivery fees** based on base cost plus distance traveled
- **NPC valet driver** spawns vehicle far away and drives it to the player
- **Blip tracking** for incoming vehicle on the map
- **Safe stopping logic** to prevent vehicle from running into the player
- **Timeout safeguards** to handle failed deliveries (e.g., despawn after 5 minutes)

### 🎭 Immersive Animations
- **Key handoff animation** with synchronized ped and player movements
- **Prop cleanup** on delivery completion or failure
- **Customizable driving styles** (normal, fast, very fast) and speeds
- **Heading alignment** for realistic face-to-face interactions

### 🗄️ Persistent Vehicle Management
- **Database integration** to track vehicle states (garaged, out, impounded)
- **Duplicate spawn prevention** by checking vehicle state before delivery
- **Automatic state updates** (mark as "out" on spawn, revert on failure)
- **Player-owned vehicle filtering** to show only eligible garaged vehicles

### 💰 Fee & Economy Integration
- **Server-side fee charging** from cash or bank
- **Configurable costs** (base fee + per-meter charge)
- **Insufficient funds handling** with notifications

### 📊 Vehicle Display Enhancements
- **Icon and color mapping** by vehicle class (e.g., cars, bikes, planes)
- **Colored badges** for fuel and condition in menu (green/orange/red)
- **Metadata display** for quick vehicle overview

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |

**Note:** This script relies on QBCore's vehicle system (player_vehicles table) and does not require additional dependencies like qb-inventory or qb-target.

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone from GitHub
git clone https://github.com/MnCLosSantos/mnc-callcar.git

# OR download ZIP from Releases
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-callcar/
```

### 2️⃣ Database Setup

The script uses QBCore's existing `player_vehicles` table—no additional tables needed! It automatically handles state updates via MySQL queries.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-callcar
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize:

```lua
-- Delivery costs
Config.BaseCost = 100        -- Base fee to call any vehicle
Config.CostPerMeter = 0.25  -- Additional cost per meter vehicle travels

-- Spawn and driving options
Config.SpawnDistance = 800   -- How far away the ped spawns the vehicle from (meters)
Config.DrivingSpeed = 1      -- How fast the ped drives (1=normal, 2=fast, 3=very fast)
Config.DrivingStyle = 786603 -- Driving style flag (786603 = normal)

-- Menu commands
Config.Commands = {
    'callcar',
    'bringcar',
    'valet',
    'mycar',
    'getcar',
    'fetchcar',
}
```

### 5️⃣ Add Items (Optional)

No items are required, as the system is command/menu-based. However, you can integrate it with items if desired by triggering the menu event.

---

## ⚙️ Configuration Guide

### 🚗 Vehicle Menu Configuration
The menu is generated dynamically from player vehicles. Customize icons and colors via the `GetVehicleIcon` function in `client.lua` (e.g., add more classes or change hex colors).

### 📍 Spawn Logic
- **Spawn Distance**: Configurable up to 1000m (clamped for performance)
- **Road Finding**: Uses `GetClosestVehicleNodeWithHeading` for driveable spawn points
- **Fallback**: Random point if no road found after 30 attempts

### 🔑 Handoff Animation
- Uses 'mp_common' dictionary with 'givetake1_a/b' animations
- Automatic heading sync for ped and player
- 2-second playback with cleanup

---

## 🎮 Controls & Usage

### Player Controls
| Key/Command | Action |
|-------------|--------|
| `/callcar` (or aliases) | Open valet menu to select vehicle |

### Usage Steps
1. Use command (e.g., `/callcar`) to open menu
2. Select garaged vehicle from list
3. Confirm delivery and pay fee
4. Track incoming vehicle via map blip
5. Receive keys via handoff animation
6. Drive away—vehicle state updates automatically

---

## 🧪 System Mechanics

### Delivery Process
1. **Menu Check**: Fetches garaged vehicles (state != 0) from server
2. **Fee Calculation**: Base + (distance * per-meter cost)
3. **Spawn & Drive**: NPC spawns vehicle far away, drives to player
4. **Handoff Zone**: At <8m, ped stops, exits, hands off keys
5. **Cleanup**: Ped walks away and despawns; blip removed
6. **Failure Handling**: Timeout after 5 minutes; revert vehicle state

### Vehicle State Management
- **Garaged (state=1)**: Available for call
- **Impounded (state=2)**: Available but labeled as such
- **Out (state=0)**: Excluded from menu; prevents duplicates

### Fee System
1. **Server Verification**: Checks cash/bank balance
2. **Removal**: Uses QBCore's RemoveMoney function
3. **Notifications**: Success/failure messages via ox_lib

---

## 🔧 Troubleshooting

### Common Issues

**Menu shows no vehicles:**
- Ensure player has vehicles in `player_vehicles` with state != 0 (eg: garaged)
- Check server logs for SQL query errors

**Vehicle not spawning:**
- Verify model exists in QBCore.Shared.Vehicles
- Check spawn distance isn't too large (causing pathfinding issues)
- Look for client console errors on model loading

**Animation not playing:**
- Ensure 'mp_common' dict is available (base game asset)
- Check for conflicting scripts overriding animations

**Fee not charging:**
- Verify QBCore money functions are working
- Check player has sufficient funds in cash/bank

**NPC not driving properly:**
- Adjust DrivingStyle flag in config
- Ensure spawn point is on a road (increase attempts if needed)

---

## 📝 Credits & License

**Author**: Stan Leigh  
**Version**: 1.0.0  
**Framework**: QBCore  

### Contributing
Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

---

## 📞 Support & Community

For support, bug reports, or feature requests:
- Open an issue on GitHub
- Join our Discord community
- Check existing documentation

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6)

[![GitHub](https://img.shields.io/badge/GitHub-View%20Script-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/MnCLosSantos/mnc-callcar)

---

## 🔄 Changelog

### Version 1.0.0 (Initial Release)
**New Features:**
- ✨ Core valet delivery system with NPC driver
- ✨ Menu integration for vehicle selection
- ✨ Key handoff animation and blip tracking
- ✨ Dynamic fee calculation and charging
- ✨ Vehicle state management with duplicate prevention
- ✨ Configurable commands, costs, and driving options

**Improvements:**
- 🔧 Optimized spawn point finding with road priority
- 🔧 Enhanced notifications with ox_lib
- 🔧 Added color-coded fuel and condition badges

**Bug Fixes:**
- 🐛 Fixed potential infinite loops in model loading
- 🐛 Resolved heading misalignment in animations
- 🐛 Corrected state revert on delivery timeouts

---

**Enjoy seamless vehicle delivery on your FiveM server! 🚗**