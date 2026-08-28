# 🛡️ MNC Safe Zones System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-2.0.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

An **admin-authored polygon safe-zone system** for QBCore-based FiveM servers. Admins draw irregular, straight-edged zones (not just circles) with adjustable vertical height, either by walking to each corner and capturing their position or by flying a built-in freecam and dropping points remotely. Players get an on-screen indicator whenever they enter a defined zone, along with awareness of whether their current job is exempt from it — all managed through a single NUI admin panel with no server restart required to add, edit, or delete a zone.

---

## ✨ Key Features

### 🗺️ Polygon Zone Editor
- Zones are drawn as **straight-edge polygons**, not fixed circles — any shape with at least `Config.MinZonePoints` (default 4) corner points is valid
- **Two ways to place points**: "Capture My Position" while standing on foot, or "Start Freecam" to fly around and drop points from the air
- Adjustable **vertical height range** per zone (`Config.DefaultHeightRange` fallback, 20m by default) so a zone only covers the correct floor(s) of a building
- Full **CRUD from the NUI panel** — add, update, or remove a zone without touching a config file or restarting the resource

### 🎯 Built-in Freecam for Placement
- A dedicated free-fly camera (fixed speed, Shift to boost, adjustable look sensitivity) opens straight from the `/safezones` panel
- A preview marker sits a configurable distance in front of the camera so admins can always see exactly where the next point will land

### 🔔 Player-Facing HUD
- Shows a HUD indicator the moment a player enters a defined zone, and hides it on exit
- Displays whether the player's **current job is exempt** (`Config.ExemptJobs`, defaults to `police`, `fire`, `ambulance`, `sheriff`, `swat`)
- Configurable enter/exit notifications (`Config.NotifyOnEnter` / `Config.NotifyOnExit`)
- Job data is always read live from QBCore (never cached) so exempt status updates immediately after a job change

### 🔗 mnc-jobhud Integration
- Exposes a `mnc-safezones:setVisible` event so [`mnc-jobhud`](../mnc-jobhud) (or any other HUD resource) can hide/show the zone indicator alongside its own UI elements without fighting over screen space

### 💾 Persistence
- Zones are stored server-side in the `mnc_safezones` MySQL table (auto-created on first start) and pushed to every client on join

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-safezones/
```

### 2️⃣ Database Setup

The script **automatically creates** the `mnc_safezones` table on first start. No manual SQL import needed.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-safezones
```

### 4️⃣ Configure Settings

Edit `config.lua` to adjust exempt jobs, notifications, default zone height, and freecam feel.

---

## ⚙️ Configuration Guide

```lua
Config.Debug = false

-- Jobs that bypass the zone's exempt/HUD messaging
Config.ExemptJobs = { 'police', 'fire', 'ambulance', 'sheriff', 'swat' }

Config.NotifyOnEnter = true
Config.NotifyOnExit  = true

-- Default vertical thickness (height) when a zone doesn't specify one
Config.DefaultHeightRange = 20.0

-- Minimum vector points required to form a valid polygon
Config.MinZonePoints = 4

-- Freecam settings used by the /safezones panel's "Start Freecam" placement mode
Config.FreecamSpeed           = 1.5
Config.FreecamBoostMultiplier = 3.0
Config.FreecamLookSensitivity = 200.0
Config.FreecamPreviewDistance = 2.5
```

---

## 🎮 Controls & Usage

| Command | Who | Description |
|---------|-----|-------------|
| `/safezones` | Admin | Opens the NUI panel to create, edit, or delete polygon safe zones |

**Creating a zone from the panel:**
1. Run `/safezones` and choose to start a new zone
2. Capture at least `Config.MinZonePoints` corner points — either walk to each one and press "Capture My Position," or use "Start Freecam" to fly and drop points remotely
3. Set the zone's label and vertical height range
4. Save — the zone is written to the database and pushed live to every connected client

---

## 🔧 Troubleshooting

**Zone doesn't trigger the HUD indicator:**
- Confirm the polygon has at least `Config.MinZonePoints` points and that the height range actually covers the player's Z coordinate
- Enable `Config.Debug = true` to print zone entry/exit events to the console

**Zone HUD conflicts with another HUD element:**
- Use the `mnc-safezones:setVisible` event from your other HUD resource to hide/show the indicator instead of disabling this script

**Freecam placement feels too fast/slow:**
- Tune `Config.FreecamSpeed` and `Config.FreecamBoostMultiplier` in `config.lua`

**Zones don't persist after restart:**
- Verify `oxmysql` starts before `mnc-safezones` and that the `mnc_safezones` table was created

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 2.0.0
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

1. **What this resource does and doesn't do**: `mnc-safezones` defines zones and shows players a HUD indicator plus exempt-job awareness — it does not itself block damage, weapon fire, or driving. If you need actual gameplay enforcement inside a zone, wire it up in your combat/weapon resource against the same zone data, or extend the script yourself.
2. **Database**: Requires oxmysql — MariaDB 10.3+ recommended
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Draw the lines, keep players informed. 🛡️**
