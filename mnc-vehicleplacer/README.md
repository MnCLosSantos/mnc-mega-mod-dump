# 🅿️ MNC Vehicle Placer

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.8-brightgreen.svg)]()

---

## 🌟 Overview

MNC Vehicle Placer spawns a fixed, persistent set of "static" decoration vehicles (car meets, police fleet, dealership display cars, etc.) at exact coordinates defined in config, on server start. It watches for missing or deleted vehicles and automatically respawns them, keeping the placed vehicles present for players at all times without any player interaction required.

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

**Author**: Stan Leigh
**Version**: 1.0.8
**Framework**: QBCore

Distributed as part of the MnCLosSantos mod-dump collection — open source, please credit the original author if you edit and re-release.
