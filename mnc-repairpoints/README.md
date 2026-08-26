# 🔧 MNC Repair Points

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

**MNC Repair Points** is a clean, lightweight pay-to-repair system for QBCore servers.  
Players can repair their vehicles at public repair stations (when no mechanics are on duty), emergency vehicles get **free repairs** at designated bays, and job-restricted repair points (police, EMS, etc.) stay private.

Built with **ox_lib** for menus, notifications, and confirmation dialogs.

## 🌟 Preview Images

<img width="1920" height="1080" alt="Screenshot (22)" src="https://github.com/user-attachments/assets/3b0bef37-0c48-4834-890b-7aa716b9b761" />

<img width="1920" height="1080" alt="Screenshot (23)" src="https://github.com/user-attachments/assets/727f84b4-63ac-4a58-a2bd-8ddab9841b76" />

<img width="1920" height="1080" alt="Screenshot (29)" src="https://github.com/user-attachments/assets/85f4dc9a-496b-4331-b0a2-d316429bf11d" />

---

## ✨ Key Features

### 🛠️ Repair Options
- **Full Repair** – Engine + Body + Dirt (default $750)
- **Body Repair Only** – Visual damage only (default $350)
- Clean confirmation dialogs with price display
- ox_lib context menu (beautiful & modern)

### 🚨 Emergency-Only & Free Repairs
- Locations marked `emergencyOnly = true` are **free** for emergency vehicles (class 18)
- Police/EMS/Ambulance bays can be completely free
- Perfect for MRPD, Pillbox, BCSO garages

### 👷 Mechanic Duty Integration
- When **any mechanic** (from Config.MechanicJobs) is on duty → public repair points are hidden
- Players see a red “Mechanic on duty – visit garage!” message instead
- No more competing with public repair stations when your mechanics are working

### 🔐 Job-Restricted Bays
- Police-only, EMS-only, or custom job repair points
- Optional `minGrade` requirement
- Works perfectly with qb-policejob, qb-ambulancejob, etc.

### 🧰 Performance & Polish
- Uses `ox_lib` for everything (no native menus)
- Clean 3D text with distance checks
- Debug mode with detailed console logs
- Automatic mechanic duty check every 2 minutes

---

## 📋 Requirements

| Dependency     | Version | Required |
|----------------|---------|----------|
| QBCore Framework | Latest  | ✅ Yes   |
| ox_lib         | Latest  | ✅ Yes   |

---

## 🚀 Installation

1. Download the resource and place it in your resources folder:
   ```
   [server-data]/resources/[custom]/mnc-repairpoints/
   ```

2. Add to your `server.cfg`:
   ```lua
   ensure mnc-repairpoints
   ```

3. (Optional) Add items to `qb-core/shared/items.lua` if you want repair kits in the future (not required for this script).

---

## ⚙️ Configuration

All settings are in `config.lua`

### Main Settings
```lua
Config.Debug = false                    -- Extra logs & notifications
Config.DutyCheckInterval = 120          -- Seconds between mechanic checks
Config.RepairPriceFull = 750
Config.RepairPriceBody = 350
```

### Mechanic Jobs (hides public points when any are on duty)
```lua
Config.MechanicJobs = {
    mechanic = true,
    mechanic2 = true,
    beekers = true,
    bennys = true,
    autoexotics = true,
    -- add your custom mechanic jobs here
}
```

### Repair Locations
```lua
Config.Locations = {
    repair = {
        -- Public (visible when no mechanics on duty)
        { coords = vector4(-200.1, -1308.51, 30.68, 269.81), name = 'Bennys Repair Point' },
        { coords = vector4(124.47, 6624.61, 31.2, 314.5),   name = 'Beekers Repair Point' },

        -- Police-only free emergency bay
        { 
            coords = vector4(463.35, -1019.35, 27.61, 90.38),
            name = 'MRPD Repair Bay',
            job = 'police',
            emergencyOnly = true,
        },

        -- EMS-only free bay
        { 
            coords = vector4(342.45, -562.64, 28.26, 158.72),
            name = 'Pillbox Medical Repair Bay',
            job = 'ambulance',
            emergencyOnly = true,
        },
    }
}
```

---

## 🎮 How to Use

1. Drive your vehicle to a repair point
2. Stand near the marker (within 5 meters) and press **E**
3. Choose **Full Repair** or **Body Repair Only**
4. Confirm the payment (or free if emergency bay)

Emergency vehicles at `emergencyOnly` locations repair **for free**.

---

## 🔧 Troubleshooting

| Issue                                | Solution |
|--------------------------------------|----------|
| No repair menu appears               | Make sure you're the driver and within 5m |
| Public points still show with mechanics on duty | Check `Config.MechanicJobs` names match your job names |
| Police/EMS bays not working          | Verify `job = 'police'` or `'ambulance'` matches your framework |
| No 3D text                           | Check `DrawText3D` is not blocked by other resources |
| Debug logs not showing               | Set `Config.Debug = true` |

---

## 📝 Credits 

**Author**: Stan Leigh  
**Version**: 1.0.0  
**Framework**: QBCore  

---

## 🔄 Changelog

### Version 1.0.0 (Initial Release)
- ✨ Full & body repair options with ox_lib menus
- ✨ Emergency-only free repair system
- ✨ Mechanic duty detection (hides public points)
- ✨ Job-restricted & minGrade repair bays
- ✨ ox_lib notify + alertDialog integration
- ✨ Clean 3D text & debug mode
- ✨ Full documentation

---

**Enjoy your clean, professional and lightweight repair system! 🔧**
