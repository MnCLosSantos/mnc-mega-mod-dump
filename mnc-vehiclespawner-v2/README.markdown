# 🚘 MNC Vehicle Spawner v2

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.1.3-brightgreen.svg)]()

> ⚠️ **Multiple versions of this script exist in this dump — install only ONE.** `mnc-vehiclespawner-v2` is one of two builds of this tool alongside `mnc-vehiclespawner`. Running more than one at the same time will register the same commands/exports twice. See "Choosing a Version" below.

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
An admin NUI tool that browses every vehicle defined in `QBCore.Shared.Vehicles`, shows a live image preview for each one, and spawns the selected model at the player's current position with optional paint, performance mods, and random visual mods. This build adds vehicle images and a duplicate-plate safety check on top of the original spawner.

---

## 🔀 Choosing a Version

This dump contains two builds of the vehicle spawner. **Install only one** — both bind the same `/vehiclespawner` command.

| | `mnc-vehiclespawner` | `mnc-vehiclespawner-v2` (this one) |
|---|---|---|
| Vehicle browser NUI, 5 UI themes | ✅ | ✅ |
| Paint color/finish, performance mods, random visual mods | ✅ | ✅ |
| Configurable fuel/key system integration | ✅ | ✅ |
| Vehicle image previews (docs.fivem.net + GitHub fallback chain) | ❌ | ✅ |
| Plate-uniqueness check against `player_vehicles` before spawning | ❌ | ✅ (requires oxmysql) |
| Admin access check | ACE-style `Config.AdminGroups` | QBCore `HasPermission(src, 'admin')`, hardcoded |
| Database dependency | None | oxmysql |
| Version | 1.0.0 | 1.1.3 |

Pick **this version** if you want image previews in the vehicle browser and a safety check against duplicate plates. Pick the base version if you'd rather not add an oxmysql dependency for a pure spawn-only tool.

---

## ✨ Key Features

### 🖥️ Vehicle Browser UI with Image Previews
- NUI menu lists all vehicles from `QBCore.Shared.Vehicles`, categorized by class, themed using one of five configurable glass-style UI presets
- Each vehicle shows a live preview image, tried in order from `docs.fivem.net`, two configurable GitHub mirrors, then a local fallback

### 🚗 Spawn Logic
- Deletes the player's current vehicle (if any) before spawning the new one, finds proper ground height, and optionally warps the player into the driver's seat (`Config.Warp`)
- Sets vehicle keys and fuel through your configured key/fuel systems
- Applies a chosen color (10 presets) with a selectable paint finish (metallic, classic, matte, pearlescent, chrome)
- Optional performance mod pass (max Engine/Brakes/Transmission/Suspension + turbo) and optional random visual mods pass

### 🔒 Plate Uniqueness Check
- Before a spawned vehicle can be registered, the server checks the generated plate against the existing `player_vehicles` table via `oxmysql` and regenerates it if a collision is found — preventing duplicate-plate conflicts with real owned vehicles

### 🔑 Hardened Admin Access
- The spawner command checks `QBCore.Functions.HasPermission(src, 'admin')` directly, rather than a manually maintained ACE group list — access denial sends a clear in-game notification instead of failing silently

---

## 📋 Requirements

| Dependency | Required |
|---|---|
| qb-core | ✅ Yes |
| ox_lib | ✅ Yes |
| oxmysql | ✅ Yes |
| LegacyFuel / cdn-fuel / ox_fuel | Only whichever matches `Config.Fuel` |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-vehiclespawner-v2/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-vehiclespawner-v2
```

No custom database table is required — the plate check reads directly from your existing `player_vehicles` table.

### 3️⃣ Configure Settings

Edit `config.lua` to match your fuel and key system, UI theme, and image sources.

---

## ⚙️ Configuration Guide

```lua
Config = {
    Command = 'vehiclespawner',

    Fuel = 'legacy', -- legacy | cdn | ox | standalone
    Keys = 'qb',     -- qb | qbx | standalone
    Warp = true,     -- warp player into vehicle on spawn

    ImagePaths = {
        primary = 'https://docs.fivem.net/vehicles/{model}.webp',
        github1 = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage/raw/main/{model}.png',
        github2 = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage-2/raw/main/{model}.png',
        local_fallback = './images/fallback.png',
    },

    UIStyle = 'style1', -- style1 - style5 glass themes
}
```

`Fuel` and `Keys` must match whichever fuel/key resource you actually run; `ImagePaths` controls the image fallback order shown in the browser UI.

---

## 🎮 Controls & Usage

| Command | Description |
|---------|-------------|
| `/vehiclespawner` (configurable via `Config.Command`) | Admin-only — opens the vehicle spawner NUI |

From the UI: pick a vehicle, optional color/paint type, and optional performance/random visual mod toggles, then spawn.

---

## 🔧 Troubleshooting

**Spawned vehicle has no fuel / doesn't lock properly:**
- `Config.Fuel`/`Config.Keys` must match the fuel and key resources actually installed on the server

**"Access Denied" notification on command:**
- The command checks `QBCore.Functions.HasPermission(src, 'admin')` — grant that permission through QBCore's admin group system

**Vehicle images don't load:**
- The fallback chain tries `docs.fivem.net`, then your two configured GitHub mirrors, then the local fallback — check `Config.ImagePaths` and that the model name matches the image filename

**Plate check seems to hang:**
- Confirm `oxmysql` is running and connected before this resource starts — the plate check query needs it

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.1.3
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

1. **Database**: Requires oxmysql for the plate-uniqueness check — reads directly against your existing `player_vehicles` table, no separate table is created
2. **Compatibility**: QBCore only — not compatible with ESX
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Pick a model, dial it in, spawn it. 🚘**
