# 🚗 MNC Vehicle.LUA Manager v2

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-2.3.7-brightgreen.svg)]()

> ⚠️ **Multiple versions of this script exist in this dump — install only ONE.** `mnc-vehiclemanager-v2` is one of two builds of this tool alongside `mnc-vehiclemanager`. Running more than one at the same time will register the same `/vehiclelua` command twice. See "Choosing a Version" below.

---

## 🌟 Overview

A comprehensive vehicle-data editor for QBCore, extended with full-server vehicle discovery. Sit in any vehicle, run `/vehiclelua`, and get an in-game UI that auto-populates model, name, brand, category, type, and shop, with dynamic dropdowns and an auto-pricing calculator — but unlike the base version, v2 can also find and list **every vehicle model that exists on your server but isn't yet registered** in `QBCore.Shared.Vehicles`, and bulk-export all of them to a ready-to-merge `vehiclesaves.lua` in one pass.

---

## 🔀 Choosing a Version

This dump contains two builds of the vehicle manager. **Install only one** — both bind the same `/vehiclelua` command and write to the same `vehiclesaves.lua` file.

| | `mnc-vehiclemanager` | `mnc-vehiclemanager-v2` (this one) |
|---|---|---|
| In-game editor UI via `/vehiclelua` | ✅ | ✅ |
| Dynamic dropdowns from `QBCore.Shared.Vehicles` | ✅ | ✅ |
| Auto-pricing calculator (base × brand × type × shop) | ✅ | ✅ |
| Light/dark theme toggle | ✅ | ✅ |
| Vehicle discovery | Only vehicles already registered in `QBCore.Shared.Vehicles` | Also discovers every vehicle model that exists on the server but is **not yet** in `QBCore.Shared.Vehicles` (including addon/DLC vehicles), using native model/class detection and a built-in brand-name normalizer |
| Bulk "Export All" to `vehiclesaves.lua` | ❌ | ✅ — with options to exclude emergency vehicles, auto-price everything, and set a fallback shop |
| Version | 1.4.2 | 2.3.7 |

This version is a strict superset of the original editor. Pick it any time you want to onboard addon vehicle packs or find everything missing from your shared vehicles file in one sweep, rather than adding vehicles one at a time.

---

## ✨ Key Features

### 🌐 Full-Server Vehicle Discovery
- Scans every vehicle model that exists in the game's model list (`GetAllVehicleModels`), not just what's already registered in `QBCore.Shared.Vehicles`
- For anything missing from your shared vehicles file, it auto-detects vehicle class, infers a display type (automobile/bike/boat/heli/plane), and normalizes the manufacturer name through a large built-in brand map (correctly handling special cases like Übermacht and Schäfter variants)
- The editor's left panel clearly separates vehicles already in `qb-core` from ones that aren't yet registered

### 📦 Export All (Bulk Onboarding)
- One button exports **every** undiscovered vehicle straight to `vehiclesaves.lua` in a single pass, instead of hand-editing them one at a time
- Options to exclude emergency-class vehicles (class 18), apply auto-pricing to the whole batch, and set a fallback shop for anything without one
- A real-time progress bar tracks the export as it runs

### 🖼️ Intuitive UI Editor
- Same auto-populating form, dynamic dropdowns, and light/dark theme toggle as the base version, plus the discovery panel described above

### 💰 Dynamic Auto-Pricing
- Identical base × brand × type × shop pricing formula, with optional ±5% randomization, usable both per-vehicle and across a full Export All batch

### 📝 Vehicle Data Saving
- Saves to `vehiclesaves.lua` in a format ready to paste directly into `qb-core/shared/vehicles.lua`
- Admin-only, gated the same way as the base version (ACE permission or QBCore admin check)

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
[server-data]/resources/[custom]/mnc-vehiclemanager-v2/
```

### 2️⃣ File Setup

The script **automatically creates** `vehiclesaves.lua` on first save or export — no manual setup needed.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure mnc-vehiclemanager-v2
```

### 4️⃣ Configure Permissions

```
add_ace group.admin command allow
```

Or rely on the built-in QBCore admin check (`QBCore.Functions.HasPermission(src, 'admin')`).

---

## ⚙️ Configuration Guide

Same pricing configuration shape as the base version:

```lua
basePrices      = { compacts = 15000, sedans = 25000, suvs = 35000, coupes = 30000, muscle = 40000, sportsclassics = 50000, sports = 60000, super = 100000, motorcycles = 20000, offroad = 30000, industrial = 25000, utility = 20000, vans = 25000, cycles = 5000, boats = 50000, helicopters = 150000, planes = 200000, service = 20000, emergency = 30000, military = 50000, commercial = 40000, trains = 100000 }
brandMultipliers = { Albany = 0.9, Annis = 1.1, Benefactor = 1.2, --[[ ...full list in the resource ]] Unknown = 0.9 }
typeMultipliers  = { automobile = 1.0, bike = 0.8, boat = 1.2, heli = 1.5, plane = 1.7, train = 2.0 }
premiumShopMultiplier = { luxury = 1.3, import = 1.4, airshop = 1.5, boatshop = 1.2, moto = 1.1, pdm = 1.0 }
```

Final price = `base × brand × type × shop × (1 ± 5% random, if enabled)`.

---

## 🎮 Controls & Usage

| Key | Action |
|-----|--------|
| `/vehiclelua` | Open the vehicle editor (must be in a vehicle) |
| `Escape` | Close the editor or any open modal |

**Onboarding every addon vehicle on your server:**
1. Run `/vehiclelua` from any vehicle
2. Click **Export All** in the editor
3. Choose whether to exclude emergency vehicles and enable auto-pricing, set a fallback shop
4. Confirm — the progress bar tracks the export, and every undiscovered vehicle lands in `vehiclesaves.lua`
5. Merge the resulting file into `qb-core/shared/vehicles.lua`

**Editing a single vehicle:**
1. Sit in the vehicle, run `/vehiclelua`
2. Adjust fields or enable Auto-Price
3. Save — the entry is appended to `vehiclesaves.lua`

---

## 🔧 Troubleshooting

**Export All takes a long time / seems stuck:**
- Scanning every vehicle model on the server can take a while on a large addon-vehicle pack — watch the progress bar rather than assuming it's frozen

**A discovered vehicle has the wrong brand name:**
- The brand normalizer covers common GTA manufacturers; an unmapped raw brand string falls back to a title-cased conversion — you can still hand-edit the field before saving

**"Access denied" on save/export:**
- Confirm your account has the `group.admin` ACE permission or QBCore admin permission

**Saved/exported entries don't show in-game:**
- `vehiclesaves.lua` is a staging file, not a live vehicle table — merge its contents into `qb-core/shared/vehicles.lua` and restart `qb-core`

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 2.3.7
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

1. **Not a live editor**: Saved/exported data goes to `vehiclesaves.lua`, a staging file — it must be manually merged into `qb-core/shared/vehicles.lua` to take effect in-game
2. **Compatibility**: QBCore only — not compatible with ESX
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Edit it, price it, save it. 🚗**
