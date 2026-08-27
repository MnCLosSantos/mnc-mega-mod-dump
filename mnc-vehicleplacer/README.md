# 🅿️ MNC Vehicle Placer

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.8-brightgreen.svg)]()

> ⚠️ **Multiple versions of this script exist in this dump — install only ONE.** `mnc-vehicleplacer` is one of several builds of this tool alongside `mnc-vehicleplacer-v2`. Running more than one at the same time will register the same commands/exports twice and can corrupt shared data. v2 adds a full in-game admin UI (add/edit/delete/teleport), SQL-backed dynamic placements, live vehicle image previews, and anti-drift protection on top of this version's static config-only placements. See "Choosing a Version" below.

---

## 🌟 Overview

MNC Vehicle Placer spawns a fixed, persistent set of "static" decoration vehicles (car meets, police fleet, dealership display cars, etc.) at exact coordinates defined in config, on server start. It watches for missing or deleted vehicles and automatically respawns them, keeping the placed vehicles present for players at all times without any player interaction required.

---

## 🔀 Choosing a Version

This dump contains two builds of the vehicle placer. **Install only one** — both register the same `mnc-vehicleplacer` event namespace.

| | `mnc-vehicleplacer` (this one) | `mnc-vehicleplacer-v2` |
|---|---|---|
| Static placements from `config.lua` | ✅ | ✅ |
| Auto-respawn watchdog for missing/deleted vehicles | ✅ | ✅ |
| In-game admin UI (`/vehplacer`) — add/edit/delete placements | ❌ | ✅ |
| SQL-backed dynamic placements (persist beyond config) | ❌ | ✅ |
| Drive-to-place workflow with live position confirm | ❌ | ✅ |
| Vehicle image previews (docs.fivem.net + GitHub fallback chain) | ❌ | ✅ |
| Proximity spawn/despawn with anti-drift detection | ❌ (interval respawn watchdog only) | ✅ |
| Database | Declared (`oxmysql`) but never queried | Fully used — `mnc_vehicle_placements` table |
| Version | 1.0.8 | 2.1.9 |

This version is the smallest-footprint option — a set-it-and-forget-it static placement script with no in-game UI at all. Pick **v2** instead if you want to add, edit, reposition, or remove placements without hand-editing `config.lua` and restarting the resource.

---

## ✨ Key Features

**Static vehicle placement**
- On resource start, deletes any leftover vehicles matching the configured spawn points/models (cleanup pass), then spawns every entry in `Config.Placements` using `CreateVehicleServerSetter` at its configured `vector4` position and heading, frozen in place once loaded client-side.
- Each placement is tracked by index with its network ID and last-spawn time.

**Auto-respawn watchdog**
- A server loop runs every 60 seconds, checking whether each placed vehicle still exists near its spawn point; if a vehicle has been missing for more than 30 seconds it's cleaned up and respawned automatically.
- Also re-triggers client-side vehicle configuration (freeze/mission-entity flags) for any player within 50 meters of a placement, in case a player's client missed the original sync.

**Cleanup on stop**
- On `onResourceStop`, all tracked placement vehicles are deleted so restarting the resource doesn't duplicate cars.

---

## 📋 Requirements

| Dependency | Required |
|---|---|
| ox_lib | Yes |
| oxmysql | Yes |

*(Note: `oxmysql` is loaded by the manifest but the script logic itself only reads static `Config.Placements` data — no queries are made against the database.)*

---

## 🚀 Installation

```bash
# Place into your resources folder
[server-data]/resources/[custom]/mnc-vehicleplacer/
```

```lua
# server.cfg
ensure mnc-vehicleplacer
```

No database setup needed — all placements are defined directly in `config.lua`.

---

## ⚙️ Configuration Guide

```lua
Config.Debug = false -- Set to true to enable debug prints

Config.Placements = {
    [1] = {
        name = "LA FESTA LIMO",
        vehicleModel = "Stretch",
        vehicleSpawn = vector4(1353.09, 1156.52, 113.57, 130.81), -- x, y, z, heading
    },
    -- ... additional placements
}
```

Each `Placements` entry defines a display name, a vehicle spawn code, and an exact `vector4` (x, y, z, heading) spawn position. `Config.Debug` toggles verbose console logging of spawn/cleanup/respawn activity.

---

## 🔧 Troubleshooting

- **Duplicate vehicles piling up at a spawn point** — usually caused by restarting the resource without letting the `onResourceStop` cleanup run; the built-in start-up cleanup pass should catch orphans matching the configured model/position, but manually verify if using `restart` commands aggressively.
- **A placed vehicle never respawns after being destroyed** — the watchdog only checks once every 60 seconds and requires 30+ seconds of absence before respawning; this is expected latency, not a bug.
- **Vehicle spawns underground/floating** — double-check the `z` coordinate in `vehicleSpawn`; this script does not auto-adjust to ground height.
- **No visible activity in console** — set `Config.Debug = true` to see spawn/cleanup/respawn logging.

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.0.8
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

