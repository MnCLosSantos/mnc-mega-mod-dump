# 🚗 MNC Custom Plate System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A **fully-featured custom license plate system** for QBCore-based FiveM servers. Players can personalize their vehicle plates using a consumable item, with a live USA-style plate preview UI, duplicate plate protection checked directly against the `player_vehicles` database, optional job locking, and an admin command bypass. Built with immersion and server safety in mind.

---

## ✨ Key Features

### 🪪 Live Plate Preview UI
- **USA-style plate design** with real-time text preview as you type
- **5 selectable color themes**: White Classic, Black Edition, Ocean Blue, Red Fury, Forest Green
- **Character counter** with enforced min/max length validation
- **Alphanumeric-only filter** — no invalid characters can be entered
- **Keyboard support**: press `ESC` to close at any time

### 🔒 Duplicate Plate Protection
- **Server-side database check** against `player_vehicles` before any plate is applied
- **Case-insensitive comparison** to prevent near-duplicate exploits
- **Real-time rejection** with ox_lib notification if plate is already taken

### 🎬 Immersive Application
- **Cancellable ox_lib progress bar** (5 seconds) while applying the plate
- **Ped animation** plays for the full duration of the progress bar
- **Automatic cleanup** if the player cancels or dies mid-apply

### 📦 Item-Based System
- **Consumable item** (`custom_plate_kit`) registered with qb-inventory
- **Item consumed only on successful** plate application — no wasted kits on failures
- **Optional job lock** — restrict item use to specific jobs and grades
- **shouldClose integration** to properly dismiss inventory on use

### 🛡️ Admin Command
- **`/customplate`** command for admins — bypasses item requirement entirely
- **Permission-based access** using QBCore permission groups (god, admin, superadmin)
- **Fully configurable** group list in `config.lua`

### 🔔 ox_lib Notifications
- **Success, error, and info** notifications for every outcome
- Applied plate text confirmed in the success message
- Cancellation, duplicate, invalid format, and permission errors all notify clearly

---

## 📋 Requirements

| Dependency | Version | Required |
|---|---|---|
| QBCore Framework | Latest | ✅ Yes |
| qb-inventory | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Place Resource

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-customplate/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-customplate/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-customplate/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure qb-core
ensure qb-inventory
ensure mnc-customplate
```

### 3️⃣ Add Item to QBCore

Open `qb-core/shared/items.lua` and add:

```lua
['custom_plate_kit'] = {
    ['name']        = 'custom_plate_kit',
    ['label']       = 'Custom Plate Kit',
    ['weight']      = 200,
    ['type']        = 'item',
    ['image']       = 'custom_plate_kit.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['combinable']  = nil,
    ['description'] = 'Apply a custom license plate to your vehicle.',
},
```

### 4️⃣ Add Item Image

Place `custom_plate_kit.png` into:
```
qb-inventory/html/images/custom_plate_kit.png
```

### 5️⃣ Configure Settings

Edit `config.lua` to match your server:

```lua
-- Item name
Config.Item = 'custom_plate_kit'

-- Plate length limits
Config.MaxPlateLength = 8
Config.MinPlateLength = 1

-- Apply animation duration (ms)
Config.ProgressDuration = 5000

-- Admin groups with /customplate access
Config.AdminGroups = { 'god', 'admin', 'superadmin' }

-- Job lock (nil = no restriction)
Config.JobLock = nil
-- Example: Config.JobLock = { name = 'mechanic', grade = 0 }

-- State label shown on plate preview
Config.PlateState = 'MNC STATE'
```

### 6️⃣ Restart Resources

```
restart qb-core
restart qb-inventory
start mnc-customplate
```

---

## ⚙️ Configuration Guide

### 🎨 Plate Theme Configuration

```lua
Config.PlateThemes = {
    { id = 'default', label = 'White Classic', bg = '#FFFFFF', text = '#1a1a2e', border = '#c9aa71' },
    { id = 'black',   label = 'Black Edition', bg = '#1a1a1a', text = '#FFD700', border = '#FFD700' },
    { id = 'blue',    label = 'Ocean Blue',    bg = '#003087', text = '#FFFFFF', border = '#FFD700' },
    { id = 'red',     label = 'Red Fury',      bg = '#8B0000', text = '#FFFFFF', border = '#c9aa71' },
    { id = 'green',   label = 'Forest Green',  bg = '#1B4332', text = '#FFFFFF', border = '#FFD700' },
}
```

Each theme requires four fields: `id` (unique string), `label` (display name), `bg` (hex background), `text` (hex text color), and `border` (hex border color). Add as many themes as needed.

### 🔐 Job Lock Configuration

```lua
-- Allow only mechanics grade 0+ to use the item
Config.JobLock = { name = 'mechanic', grade = 0 }

-- Allow no job restriction (default)
Config.JobLock = nil
```

### 🛡️ Admin Command Configuration

```lua
-- Enable or disable the /customplate command
Config.AdminCommand = true
Config.AdminCommandName = 'customplate'

-- Groups that can use the admin command
Config.AdminGroups = { 'god', 'admin', 'superadmin' }
```

### ⏱️ Animation & Progress Configuration

```lua
-- Animation dictionary and clip played during application
Config.AnimDict = 'anim@heists@box_carry@'
Config.AnimName = 'idle'

-- Progress bar duration in milliseconds
Config.ProgressDuration = 5000
```

---

## 🔄 How It Works

1. **Player uses** `custom_plate_kit` from inventory (or admin runs `/customplate`)
2. **Server validates** item ownership and optional job lock before opening UI
3. **UI opens** with live USA-style plate preview — player types their desired plate text
4. **Player selects** a color theme from the picker
5. **Player clicks Apply** — UI closes and the animation + progress bar begin
6. **Server validates** plate format (length, characters) and checks `player_vehicles` for duplicates
7. **If approved** — database is updated, item is consumed, plate is applied visually
8. **ox_lib notification** confirms the new plate or explains the rejection

---

## 🐛 Troubleshooting

**UI not opening when using the item:**
- Confirm `Config.Item` matches the item name in `qb-core/shared/items.lua`
- Check that `useable = true` and `shouldClose = true` are set on the item
- Verify `mnc-customplate` is started after `qb-core` and `qb-inventory`

**Plate not saving to database:**
- Ensure the player is in the driver seat of a vehicle owned in `player_vehicles`
- Check oxmysql console for query errors
- Verify the vehicle's current plate exists in the DB — personal vehicles only

**Duplicate plate check not working:**
- Confirm oxmysql is running and connected
- Check `player_vehicles` table exists and has a `plate` column
- Look for server console errors on the `mnc-customplate:server:applyPlate` event

**Admin command not working:**
- Verify the player's QBCore permission group is listed in `Config.AdminGroups`
- Confirm `Config.AdminCommand = true` in `config.lua`
- Check that the command name doesn't conflict with another resource

**Progress bar not showing:**
- Confirm `ox_lib` is started before `mnc-customplate`
- Check client console for ox_lib errors

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

### Version 1.0.0 (Current Release)
**New Features:**
- ✨ Initial release of MNC Custom Plate system
- ✨ Live USA-style plate preview with real-time text updates
- ✨ 5 selectable color themes with fully hex-configurable colors
- ✨ Server-side duplicate plate check against `player_vehicles` database
- ✨ Case-insensitive plate comparison to block near-duplicate exploits
- ✨ Consumable item system (`custom_plate_kit`) with qb-inventory integration
- ✨ Cancellable ox_lib progress bar with ped animation during application
- ✨ Optional job lock system with configurable job name and minimum grade
- ✨ Admin `/customplate` command bypassing item requirement
- ✨ Permission-based admin access using QBCore groups (god, admin, superadmin)
- ✨ ox_lib notifications for all success, error, and cancellation states
- ✨ Alphanumeric-only plate validation (letters, numbers, spaces)
- ✨ Configurable min/max plate character length
- ✨ Item consumed only on successful plate application — no wasted kits on rejected attempts
- ✨ ESC key support to close the UI at any time
- ✨ Configurable plate state label displayed on the preview UI

---

## ⚠️ Important Notes

1. **Database**: Only updates plates for vehicles stored in `player_vehicles` — temporary or admin-spawned vehicles will have the plate applied visually but no DB record will be updated
2. **GTA Limit**: GTA V enforces a maximum of 8 characters on license plates — do not set `Config.MaxPlateLength` beyond 8
3. **Compatibility**: QBCore only — not compatible with ESX
4. **oxmysql**: Required for the duplicate check query — do not replace with another MySQL wrapper without updating the server script
5. **Legal**: For use on FiveM servers only, respect Rockstar's Terms of Service

---

**Give your players the personal touch they deserve! 🚗**
