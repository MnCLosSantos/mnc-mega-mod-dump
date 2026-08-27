# 🗺️ MNC Drift Zones

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

An admin zone editor that maps out polygon drift zones and automatically toggles [`mnc-driftscore`](../mnc-driftscore)'s HUD on for players the moment they enter one — and off again once they leave the last overlapping zone. Zones are drawn freehand with a built-in freecam point-placement tool, not typed in as raw coordinates, and persist to SQL so they survive restarts.

---

## ✨ Key Features

### 🎥 Freecam Zone Drawing
- Admins fly a dedicated freecam (independent look/move speed, Shift to boost, Alt to slow down for precision) and drop points along a raycast-projected surface to trace out a zone's polygon shape
- **Left click** adds a point, **Backspace** removes the last one, **Enter** finishes and saves the shape, **Escape** cancels the whole setup
- A live wireframe (`Config.MarkerColor`) and an aim indicator (`Config.AimMarkerColor`) are drawn in real time while building, so you can see exactly what you're tracing before committing

### 🔺 Polygon Zones with Adjustable Height
- Zones require at least `Config.MinZonePoints` (default 3) points to form a valid polygon
- Each zone has its own vertical thickness (`Config.DefaultThickness`, 40m by default, overridable per zone) so a zone only covers the intended elevation range
- Built on `ox_lib`'s `lib.zones.poly`, with `Config.ZoneCheckDebug` available to draw zone wireframes for verification

### 🎯 Automatic Drift Score Integration
- Entering the first active zone automatically runs the `driftscore` command to open [`mnc-driftscore`](../mnc-driftscore)'s HUD; leaving the last one automatically closes it again — players never need to toggle it manually inside a designated drift area
- Overlapping zones are tracked correctly — the HUD only turns off once every zone the player is inside has been exited, and the popup name updates to whichever zone is still active

### 🔔 Enter/Exit Feedback
- A zone-name popup and a distinct enter/exit sound (`Config.SoundVolume`) play through the NUI whenever a player crosses a zone boundary

### 🛡️ Dual Admin Permission Check
- Access to create/edit/delete zones checks `Config.AdminPermission` (QBCore permission group) with `Config.AdminAce` (ACE permission) as a fallback, covering servers using either permission style

### 🗺️ Map Blips
- Each saved zone optionally gets a map blip (`Config.Blip`) so players can see designated drift areas at a glance

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| [`mnc-driftscore`](../mnc-driftscore) | Latest | ✅ Yes — this resource toggles its HUD automatically on zone enter/exit |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-driftzones/
```

### 2️⃣ Database Setup

The script **automatically creates** its zones table on first start — no manual SQL import needed.

### 3️⃣ Add to Server Config

Make sure `mnc-driftscore` is running, since this resource calls its command directly:

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure mnc-driftscore
ensure mnc-driftzones
```

### 4️⃣ Configure Permissions

Edit `config.lua` to set `Config.AdminPermission` to match your QBCore permission groups, or grant the ACE fallback:
```
add_ace group.admin command.driftzones allow
```

---

## ⚙️ Configuration Guide

```lua
Config = {}

Config.AdminPermission = 'admin'
Config.AdminAce = 'command.driftzones'
Config.DefaultThickness = 40.0
Config.MinZonePoints = 3
Config.MarkerColor = { r = 255, g = 0, b = 0, a = 200 }
Config.AimMarkerColor = { r = 0, g = 210, b = 255, a = 200 }
Config.ZoneCheckDebug = false
Config.SoundVolume = 0.4

Config.Freecam = {
    fov = 60.0,
    lookSensitivityX = 4.0,
    lookSensitivityY = 4.0,
    baseSpeed = 0.85,
    fastMultiplier = 6.0,
    slowMultiplier = 6.0,
    raycastDistance = 300.0,
}

Config.Blip = {
    enabled = true,
    sprite = 877,
    color = 27,
    scale = 1.0,
}
```

- `Config.DefaultThickness` — raise this for zones spanning multi-level structures (parking garages, elevated highways); lower it for tightly-bounded flat areas
- `Config.Freecam.raycastDistance` — how far the freecam looks for a surface to drop a point on; increase if you're tracing very large or elevated zones

---

## 🎮 Controls & Usage

| Command / Input | Context | Description |
|---|---|---|
| `/driftzones` | Admin | Opens the zone management menu (create/edit/delete zones) |
| **Left Click** | Freecam zone drawing | Add a point at the current aim location |
| **Backspace** | Freecam zone drawing | Remove the last placed point |
| **Enter** | Freecam zone drawing | Finish and save the zone shape |
| **Escape** | Freecam zone drawing | Cancel the current zone setup entirely |
| **Left Shift** (hold) | Freecam | Move faster |
| **Left Alt** (hold) | Freecam | Move slower, for precise point placement |

**Creating a zone:**
1. Run `/driftzones` and choose to create a new zone
2. Fly the freecam to trace your zone's outline, placing at least `Config.MinZonePoints` points
3. Press **Enter** to finish — the zone is saved to the database and pushed live to every connected client

---

## 🔧 Troubleshooting

**Drift score HUD doesn't toggle on entering a zone:**
- Confirm `mnc-driftscore` is installed and running, and that its command name is actually `driftscore` (this resource calls it directly via `ExecuteCommand`)

**Zone doesn't trigger at all:**
- Confirm the polygon has at least `Config.MinZonePoints` points and that `Config.DefaultThickness` (or the zone's own override) actually covers the player's elevation
- Enable `Config.ZoneCheckDebug` to draw zone wireframes in-game and visually verify placement

**Freecam point placement feels too fast/slow:**
- Tune `Config.Freecam.baseSpeed`, `fastMultiplier`, and `slowMultiplier`

**"Access denied" opening `/driftzones`:**
- Confirm your account matches `Config.AdminPermission` (QBCore group) or has the `Config.AdminAce` ACE permission granted

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

1. **Requires `mnc-driftscore`**: this resource is a zone trigger for that HUD, not a standalone scoring system — install and start `mnc-driftscore` first
2. **Database**: Requires oxmysql — the zones table is created automatically on first start
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Draw the lines, let the drifting begin. 🗺️**
