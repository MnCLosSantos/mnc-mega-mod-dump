# 🛠️ MNC Vehicle Spawner

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

MNC Vehicle Spawner is an admin NUI tool that browses every vehicle defined in `QBCore.Shared.Vehicles` (grouped by category, with brand/price shown) and spawns the selected model at the player's current position, with optional random or fixed performance mods, paint color/finish, and automatic key/fuel setup.

---

## ✨ Key Features

**Vehicle browser UI**
- NUI menu lists all vehicles from `QBCore.Shared.Vehicles`, categorized by class, themed using one of five configurable glass-style UI presets.

**Spawn logic**
- Deletes the player's current vehicle (if any) before spawning the new one, finds proper ground height via `GetGroundZFor_3dCoord`, and optionally warps the player into the driver's seat (`Config.Warp`).
- Sets vehicle keys through the configured key system (`qb`/`qbx`/`standalone`) and fuel through the configured fuel system (`legacy`/`cdn`/`ox`/`standalone`).
- Applies a chosen color (10 presets: red, blue, green, black, white, yellow, orange, purple, pink, gray) with a selectable paint finish (metallic, classic, matte, pearlescent, chrome).
- Optional performance mod pass installs max-level Engine/Brakes/Transmission/Suspension mods and enables turbo when `performanceMods` is requested from the UI.
- Optional "random visual mods" pass randomizes every non-performance, non-armor mod slot (spoilers, bumpers, skirts, etc.) for a randomized look.

**Admin command**
- Opens the spawner UI, restricted to configured admin groups.

---

## 📋 Requirements

| Dependency | Required |
|---|---|
| qb-core | Yes |
| ox_lib | Yes |
| LegacyFuel / cdn-fuel / ox_fuel | Only whichever matches `Config.Fuel` |

---

## 🚀 Installation

```bash
# Place into your resources folder
[server-data]/resources/[custom]/mnc-vehiclespawner/
```

```lua
# server.cfg
ensure mnc-vehiclespawner
```

No database setup required — all data is pulled live from `qb-core`'s shared vehicle table.

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

- `/vehiclespawner` (configurable via `Config.Command`) — admin-only, opens the vehicle spawner NUI. From the UI, pick a vehicle, optional color/paint type, and optional performance/random visual mod toggles, then spawn.

---

## 🔧 Troubleshooting

- **Spawned vehicle has no fuel / doesn't lock properly** — `Config.Fuel`/`Config.Keys` must match the fuel and key resources actually installed on the server, otherwise the relevant export call will fail silently or print "No valid fuel system configured".
- **Command says permission denied** — the account's group must be listed in `Config.AdminGroups`.
- **Color doesn't apply** — a color is only applied if both `color` and `paintType` are supplied together from the UI.
- **Vehicle spawns but player isn't inside it** — check `Config.Warp` is set to `true`.

---

## 📝 Credits & License

**Author**: Stan Leigh
**Version**: 1.0.0
**Framework**: QBCore

Distributed as part of the MnCLosSantos mod-dump collection — open source, please credit the original author if you edit and re-release.
