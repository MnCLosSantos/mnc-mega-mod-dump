# 🛠️ MNC Vehicle Spawner

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

> ⚠️ **Multiple versions of this script exist in this dump — install only ONE.** `mnc-vehiclespawner` is one of two builds of this tool alongside `mnc-vehiclespawner-v2`. Running more than one at the same time will register the same commands/exports twice. See "Choosing a Version" below.

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

An admin NUI tool that browses every vehicle defined in `QBCore.Shared.Vehicles` (grouped by category, with brand/price shown) and spawns the selected model at the player's current position, with optional random or fixed performance mods, paint color/finish, and automatic key/fuel setup.

---

## 🔀 Choosing a Version

This dump contains two builds of the vehicle spawner. **Install only one** — both bind the same `/vehiclespawner` command.

| | `mnc-vehiclespawner` (this one) | `mnc-vehiclespawner-v2` |
|---|---|---|
| Vehicle browser NUI, 5 UI themes | ✅ | ✅ |
| Paint color/finish, performance mods, random visual mods | ✅ | ✅ |
| Configurable fuel/key system integration | ✅ | ✅ |
| Vehicle image previews (docs.fivem.net + GitHub fallback chain) | ❌ | ✅ |
| Plate-uniqueness check against `player_vehicles` before spawning | ❌ | ✅ (requires oxmysql) |
| Admin access check | ACE-style `Config.AdminGroups` | QBCore `HasPermission(src, 'admin')`, hardcoded |
| Database dependency | None | oxmysql |
| Version | 1.0.0 | 1.1.3 |

Pick this version for the smallest footprint with no database dependency. Pick **v2** if you want vehicle image previews in the browser UI and a duplicate-plate safety check before a spawned vehicle can be saved.

---

## ✨ Key Features

### 🖥️ Vehicle Browser UI
- NUI menu lists all vehicles from `QBCore.Shared.Vehicles`, categorized by class, themed using one of five configurable glass-style UI presets

### 🚗 Spawn Logic
- Deletes the player's current vehicle (if any) before spawning the new one, finds proper ground height via `GetGroundZFor_3dCoord`, and optionally warps the player into the driver's seat (`Config.Warp`)
- Sets vehicle keys through the configured key system (`qb`/`qbx`/`standalone`) and fuel through the configured fuel system (`legacy`/`cdn`/`ox`/`standalone`)
- Applies a chosen color (10 presets: red, blue, green, black, white, yellow, orange, purple, pink, gray) with a selectable paint finish (metallic, classic, matte, pearlescent, chrome)
- Optional performance mod pass installs max-level Engine/Brakes/Transmission/Suspension mods and enables turbo when `performanceMods` is requested from the UI
- Optional "random visual mods" pass randomizes every non-performance, non-armor mod slot (spoilers, bumpers, skirts, etc.) for a randomized look

### 🔑 Admin Command
- Opens the spawner UI, restricted to configured admin groups

---

## 📋 Requirements

| Dependency | Required |
|---|---|
| qb-core | ✅ Yes |
| ox_lib | ✅ Yes |
| LegacyFuel / cdn-fuel / ox_fuel | Only whichever matches `Config.Fuel` |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-vehiclespawner/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure mnc-vehiclespawner
```

No database setup required — all data is pulled live from `qb-core`'s shared vehicle table.

### 3️⃣ Configure Settings

Edit `config.lua` to match your fuel and key system, admin groups, and UI theme.

---

## ⚙️ Configuration Guide

```lua
Config = {
    Command = 'vehiclespawner',
    AdminGroups = {'group.admin'},

    Fuel = 'legacy', -- legacy | cdn | ox | standalone
    Keys = 'qb',     -- qb | qbx | standalone
    Warp = true,     -- warp player into vehicle on spawn

    UIStyle = 'style1', -- style1 - style5 glass themes
}
```

`Fuel` and `Keys` must match whichever fuel/key resource you actually run so spawned vehicles get proper fuel and locking behavior; `Warp` controls whether the player is placed in the driver's seat automatically; `UIStyle` picks one of the five predefined color themes for the NUI.

---

## 🎮 Controls & Usage

| Command | Description |
|---------|-------------|
| `/vehiclespawner` (configurable via `Config.Command`) | Admin-only — opens the vehicle spawner NUI |

From the UI: pick a vehicle, optional color/paint type, and optional performance/random visual mod toggles, then spawn.

---

## 🔧 Troubleshooting

**Spawned vehicle has no fuel / doesn't lock properly:**
- `Config.Fuel`/`Config.Keys` must match the fuel and key resources actually installed on the server, otherwise the relevant export call will fail silently or print "No valid fuel system configured"

**Command says permission denied:**
- The account's group must be listed in `Config.AdminGroups`

**Color doesn't apply:**
- A color is only applied if both `color` and `paintType` are supplied together from the UI

**Vehicle spawns but player isn't inside it:**
- Check `Config.Warp` is set to `true`

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

## ⚠️ Important Notes

1. **Compatibility**: QBCore only — not compatible with ESX
2. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Pick a model, dial it in, spawn it. 🛠️**
