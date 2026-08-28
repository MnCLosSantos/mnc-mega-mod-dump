# 🚗 MNC Vehicle.LUA Manager

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.4.2-brightgreen.svg)]()

> ⚠️ **Multiple versions of this script exist in this dump — install only ONE.** `mnc-vehiclemanager` is one of two builds of this tool alongside `mnc-vehiclemanager-v2`. Running more than one at the same time will register the same `/vehiclelua` command twice. See "Choosing a Version" below.

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A comprehensive vehicle-data editor for QBCore. Sit in any vehicle, run `/vehiclelua`, and get an in-game UI that auto-populates the vehicle's model, name, brand, category, type, and shop — complete with dynamic dropdowns pulled from your existing `QBCore.Shared.Vehicles` data and an optional auto-pricing calculator — then save the finished entry straight to a ready-to-merge `vehiclesaves.lua` file.

---

## 🔀 Choosing a Version

This dump contains two builds of the vehicle manager. **Install only one** — both bind the same `/vehiclelua` command and write to the same `vehiclesaves.lua` file.

| | `mnc-vehiclemanager` (this one) | `mnc-vehiclemanager-v2` |
|---|---|---|
| In-game editor UI via `/vehiclelua` | ✅ | ✅ |
| Dynamic dropdowns from `QBCore.Shared.Vehicles` | ✅ | ✅ |
| Auto-pricing calculator (base × brand × type × shop) | ✅ | ✅ |
| Light/dark theme toggle | ✅ | ✅ |
| Vehicle discovery | Only vehicles already registered in `QBCore.Shared.Vehicles` | Also discovers every vehicle model that exists on the server but is **not yet** in `QBCore.Shared.Vehicles` (including addon/DLC vehicles), using native model/class detection and a built-in brand-name normalizer |
| Bulk "Export All" to `vehiclesaves.lua` | ❌ | ✅ — with options to exclude emergency vehicles, auto-price everything, and set a fallback shop |
| Version | 1.4.2 | 2.3.7 |

Pick this version if you only ever need to hand-edit vehicles one at a time that are already in your shared vehicles file. Pick **v2** if you want to find and export every unregistered/addon vehicle on your server in bulk.

---

## ✨ Key Features

### 🖼️ Intuitive UI Editor
- Accessible via `/vehiclelua` while sitting in a vehicle
- Auto-populates vehicle details (model, name, brand, category, type, shop)
- Dynamic dropdowns for brands, categories, types, and shops, sourced from your existing `QBCore.Shared.Vehicles` data
- Searchable/filterable dropdown inputs with autocomplete on Enter
- Light and dark theme toggle with smooth transitions

### 💰 Dynamic Auto-Pricing
- Calculates a suggested price from category base price × brand multiplier × type multiplier × shop premium
- Optional ±5% randomization for natural price variation
- Toggleable per-save in the settings modal

### 📝 Vehicle Data Saving
- Saves each entry to `vehiclesaves.lua` in proper Lua table format, ready to merge into `qb-core/shared/vehicles.lua`
- Admin-only — access requires either an ACE permission or a QBCore admin check
- Clear success/error notifications on save

### 🧹 Safety & Cleanup
- Automatic UI cleanup on close or Escape key press
- Unauthorized access attempts are blocked and notified server-side

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-vehiclemanager/
```

### 2️⃣ File Setup

The script **automatically creates** `vehiclesaves.lua` on first save — no manual setup needed. Saved entries can later be merged into your `qb-core/shared/vehicles.lua`.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure mnc-vehiclemanager
```

### 4️⃣ Configure Permissions

Grant admins access via ACE permission:

```
add_ace group.admin command allow
```

Or rely on the script's built-in QBCore admin check (`QBCore.Functions.HasPermission(src, 'admin')`) — set through your normal admin management flow.

---

## ⚙️ Configuration Guide

Pricing logic lives in the resource's own pricing config and follows this shape:

```lua
basePrices      = { compacts = 15000, sedans = 25000, suvs = 35000, coupes = 30000, muscle = 40000, sportsclassics = 50000, sports = 60000, super = 100000, motorcycles = 20000, offroad = 30000, industrial = 25000, utility = 20000, vans = 25000, cycles = 5000, boats = 50000, helicopters = 150000, planes = 200000, service = 20000, emergency = 30000, military = 50000, commercial = 40000, trains = 100000 }
brandMultipliers = { Albany = 0.9, Annis = 1.1, --[[ ...full brand list in the resource ]] Unknown = 0.9 }
typeMultipliers  = { automobile = 1.0, bike = 0.8, boat = 1.2, heli = 1.5, plane = 1.7, train = 2.0 }
premiumShopMultiplier = { luxury = 1.3, import = 1.4, airshop = 1.5, boatshop = 1.2, moto = 1.1, pdm = 1.0 }
```

Final price = `base × brand × type × shop × (1 ± 5% random, if enabled)`.

---

## 🎮 Controls & Usage

| Key | Action |
|-----|--------|
| `/vehiclelua` | Open the vehicle editor (must be in a vehicle) |
| `Escape` | Close the editor or settings modal |

**Editing a vehicle:**
1. Sit in the vehicle you want to add or edit
2. Run `/vehiclelua` — the form auto-fills from the vehicle's current model
3. Adjust brand, category, type, shop, and price (or enable auto-pricing)
4. Save — the entry is written to `vehiclesaves.lua`

---

## 🔧 Troubleshooting

**Command does nothing:**
- Confirm you're actually seated in a vehicle — the editor requires an active vehicle context to auto-populate

**"Access denied" on save:**
- Confirm your account has the `group.admin` ACE permission or QBCore admin permission

**Dropdowns are empty:**
- Dropdown options are built from your existing `QBCore.Shared.Vehicles` data — an empty or minimal shared vehicles file will produce empty dropdowns

**Saved entries don't show in-game:**
- `vehiclesaves.lua` is a staging file, not a live vehicle table — merge its contents into `qb-core/shared/vehicles.lua` and restart `qb-core` for changes to take effect

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.4.2
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

## ⚠️ Important Notes

1. **Not a live editor**: Saved data goes to `vehiclesaves.lua`, a staging file — it must be manually merged into `qb-core/shared/vehicles.lua` to actually take effect in-game
2. **Compatibility**: QBCore only — not compatible with ESX
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Edit it, price it, save it. 🚗**
