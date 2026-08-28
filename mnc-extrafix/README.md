# 🚛 MNC Extra Fix

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![Standalone](https://img.shields.io/badge/Framework-Standalone-lightgrey.svg)]()
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A small, standalone fix for a long-standing GTA V bug: certain trailer models visually deform or glitch out for **every client except the one who toggled the extra** whenever one of their "extras" is switched on or off. `mnc-extrafix` polls tracked vehicles on every client, detects the moment an extra changes state, silently repairs the vehicle locally, and then broadcasts the fix through the server so every other player's streamed copy of that same vehicle gets fixed too — not just the player who caused it.

---

## ✨ Key Features

### 🔍 Automatic Extra-Change Detection
- Every client polls nearby vehicles (`GetGamePool('CVehicle')`) every `Config.PollInterval` (default 1000ms), limited to the models listed in `Config.TrackedModels`
- For each tracked vehicle, a signature of every extra's on/off state (up to `Config.MaxExtraIndex`, default 14) is recorded and compared against the previous poll
- The instant a signature changes, that vehicle is flagged as having just had an extra toggled

### 🔧 Instant Repair, Synced Everywhere
- The detecting client immediately fixes its own copy with `SetVehicleFixed`, `SetVehicleDeformationFixed`, and a full health/dirt reset
- It then tells the server, which broadcasts the fix to every connected client — so everyone's locally streamed copy of that same networked vehicle (matched by network ID) is repaired, not just the client that noticed the change
- A per-vehicle cooldown (`Config.FixCooldown`, default 1500ms) prevents repeated fixes from spamming if extras are toggled rapidly

### 🎯 Manual Override
- `/extrafix` manually fixes the nearest tracked vehicle within 10 meters — useful for testing or fixing a vehicle immediately without waiting for the next poll cycle

### 🪶 Zero Dependencies
- No framework (QBCore/ESX/etc.), no database, and no UI library required — this is a pure client+server pair that works on any FiveM server

---

## 📋 Requirements

| Dependency | Required |
|---|---|
| None — standalone client/server script, no framework or library dependency | — |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-extrafix/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure mnc-extrafix
```

No database or item setup required.

### 3️⃣ Configure Settings

Edit `config.lua` to adjust poll rate, cooldown, and which vehicle models are tracked.

---

## ⚙️ Configuration Guide

```lua
Config = {}

-- Print debug info to console (client + server)
Config.Debug = false

-- How often (ms) each client scans tracked vehicles for extra changes
Config.PollInterval = 1000

-- Minimum time (ms) between fixes on the same vehicle, prevents spamming
-- SetVehicleFixed/repair if extras are toggled rapidly
Config.FixCooldown = 1500

-- GTA extras typically range from 1 to 14. DoesExtraExist() guards anything
-- a given model doesn't actually have, so it's safe to scan the full range.
Config.MaxExtraIndex = 14

-- Vehicle models that should be auto-fixed when an extra is toggled.
-- Add/remove model names as needed (case as used by the game, all lowercase).
Config.TrackedModels = {
    "trailerflat2",
    "trailercar",
    "20fttrailer",
    "codestacker",
    "ctrailer",
    "bensonc",
    "bensonc2",
}
```

- `Config.PollInterval` — lower values catch extra toggles faster but scan the vehicle pool more often; 1000ms is a safe default
- `Config.FixCooldown` — keep this at or above `Config.PollInterval` to avoid redundant fixes on the same vehicle within one poll window
- `Config.TrackedModels` — add any other trailer/vehicle model that exhibits the same extra-toggle deformation bug on your server

---

## 🎮 Controls & Usage

| Command | Description |
|---------|-------------|
| `/extrafix` | Manually fixes the nearest tracked vehicle within 10 meters — useful for testing or an immediate fix |

The resource otherwise runs entirely in the background with no player interaction required.

---

## 🛠️ How It Works

1. Each client polls nearby vehicles every `Config.PollInterval` ms, filtered to the models in `Config.TrackedModels`
2. For each tracked vehicle, it records a signature of every extra's on/off state; if the signature changes since the last poll, that vehicle just had an extra toggled
3. The detecting client immediately fixes its own copy (`SetVehicleFixed`, `SetVehicleDeformationFixed`, full health/dirt repair), then tells the server
4. The server broadcasts to all clients, so everyone's locally streamed copy of that same vehicle (matched by network ID) also gets fixed — not just the player who toggled the extra
5. A per-vehicle cooldown (`Config.FixCooldown`) prevents repeated fixes if extras are toggled rapidly

---

## 📁 Files

```
mnc-extrafix/
├── fxmanifest.lua
├── config.lua
├── client/
│   └── main.lua
└── server/
    └── main.lua
```

---

## 🔧 Troubleshooting

**A tracked vehicle still looks deformed after toggling an extra:**
- Confirm the model name is spelled exactly as it appears in-game (all lowercase) in `Config.TrackedModels`
- Enable `Config.Debug = true` to print fix events to the console and confirm the poll is detecting the change

**Fix triggers too often / too rarely:**
- Raise `Config.FixCooldown` if fixes are firing back-to-back on the same vehicle
- Lower `Config.PollInterval` if changes aren't being caught quickly enough (at the cost of slightly more scanning overhead)

**`/extrafix` says nothing happens:**
- The command only affects the nearest tracked vehicle within 10 meters — make sure you're close enough and that the vehicle's model is in `Config.TrackedModels`

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.0.0
**Framework**: Standalone
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

1. **Compatibility**: Framework-agnostic — works alongside QBCore, ESX, or any other framework since it doesn't touch either
2. **Performance**: The poll loop only scans vehicles already in the client's game pool and only checks models listed in `Config.TrackedModels`, keeping overhead minimal
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Toggle it, glitch it, forget it — this fixes itself. 🚛**
