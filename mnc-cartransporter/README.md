# 🚛 MNC Car Transporter

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![Standalone](https://img.shields.io/badge/Framework-Standalone-lightgrey.svg)]()
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A two-level vehicle loading system built specifically for the GTA `tr2` flatbed trailer. Drive a car up to the trailer, secure it on the bottom deck, then optionally lift it up and drive it into place on the top deck — carrying up to six vehicles at once (three per level), fully synced across every client and safe to unload in the correct order so nothing clips or falls through the trailer bed.

---

## ✨ Key Features

### 🔱 Two-Level Loading
- Drive within `Config.LoadDistance` of a `tr2` trailer and press **E** to secure the vehicle you're driving onto the **bottom level**, in the next open slot (`Config.MaxVehiclesPerLevel`, default 3 per level)
- From there, choose to lift the vehicle up to the **top level** instead: hold **Up Arrow** to raise it, **Down Arrow** to lower it, clamped between `Config.MinLiftOffset` and `Config.MaxLiftOffset`
- Once lifted high enough, the vehicle is released for you to drive into its final position on top — press **E** again to secure it there
- **Backspace** at any point during the lift cancels and settles the vehicle back onto the level it started on (or fully unloads it if that level is now full)

### 🔒 Load-Order Safety
- Vehicles must be **unloaded in the reverse order they were loaded** — on level 1, everything sitting behind a given slot has to come off first; on level 2, the back slot of level 1 has to be clear before anything unloads
- This prevents unloading a car out from under one stacked above or behind it and having it fall through the trailer bed

### 🚗 Unload from the Driver's Seat
- While driving the vehicle that's towing the loaded trailer, press **B** to unload the next vehicle that's actually eligible to come off (following the load-order rule above)

### 🖥️ Context-Aware Helper UI
- A small NUI panel (`Config.ShowHelperUI`) shows the current controls only while relevant — near a trailer, mid-lift, or towing a loaded one
- **H** toggles the helper panel on/off manually at any time

### 🤝 Forklift Conflict Avoidance
- `mnc-forkliftfix` binds the same **E** / **B** / arrow-key controls for its own lifting logic. This script automatically disables its own controls and UI while you're riding a model listed in `Config.ForkliftModels` (`forklift`, `vstruck` by default), so the two scripts never fight over the same keys

### 🔄 Full Network Sync
- Every attach and detach is relayed through the server and re-broadcast to all clients, with late-joining players synced to every trailer's current load on join

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| ox_lib | Latest | ✅ Yes |

This is a standalone resource — no framework (QBCore/ESX/etc.) is required.

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-cartransporter/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure mnc-cartransporter
```

No database setup required — trailer loads are tracked in memory and re-synced to clients on join.

### 3️⃣ Configure Settings

Edit `config.lua` to adjust load distance, lift speed, slot capacity, and keybinds.

---

## ⚙️ Configuration Guide

```lua
Config = {}
Config.Debug = false
Config.ShowHelperUI = true

Config.TrailerModel = `tr2`
Config.LoadDistance = 10.0
Config.MaxVehiclesPerLevel = 3
Config.NumLevels = 2
Config.LiftSpeed = 0.5
Config.MinLiftOffset = -1.0
Config.MaxLiftOffset = 3.0

-- Vehicle models that hide helper ui when in radius (avoids conflicting with mnc-forkliftfix)
Config.ForkliftModels = {
    `forklift`,
    `vstruck`,
}

-- Controls
Config.LiftUpControl        = 172     -- Arrow Up   - raise the vehicle
Config.LiftDownControl      = 173     -- Arrow Down - lower the vehicle
Config.LiftCancelControl    = 194     -- Backspace  - cancel and settle back on the level it started on
Config.LiftConfirmControl   = 191     -- Enter (INPUT_FRONTEND_ACCEPT) - confirm the current height while lowering
Config.LoadControl          = 38      -- E (INPUT_CONTEXT)
Config.UnloadControl        = 29      -- B - press while driving the vehicle towing the trailer
Config.LoadKeyLabel         = 'E'
Config.ToggleUIKeyLabel     = 'H'
```

- `Config.NumLevels` — set to `1` to disable the lift-to-top-deck flow entirely and only use the bottom level
- `Config.MaxVehiclesPerLevel` — raise or lower how many vehicles fit per level (total trailer capacity is `MaxVehiclesPerLevel × NumLevels`)
- `Config.ForkliftModels` — add any other model here that binds the same E/B/arrow controls to avoid key conflicts

---

## 🎮 Controls & Usage

| Input | Context | Action |
|---|---|---|
| **E** | Driving near a `tr2` trailer | Secure the vehicle onto the bottom level |
| **E** | Positioned on the lift, at the top level | Secure the vehicle onto the top level |
| **Up Arrow** (hold) | Mid-lift | Raise the vehicle toward the top level |
| **Down Arrow** (hold) | Mid-lift | Lower the vehicle back down |
| **Enter** | Mid-lift, lowering | Confirm the current height |
| **Backspace** | Mid-lift | Cancel — settle back on the starting level |
| **B** | Driving the vehicle towing a loaded trailer | Unload the next eligible vehicle |
| **H** | Any time | Toggle the helper UI panel |

---

## 🔧 Troubleshooting

**E does nothing near the trailer:**
- Confirm the nearby trailer is actually the `tr2` model (`Config.TrailerModel`) and that you're within `Config.LoadDistance`
- Make sure you're not riding a model listed in `Config.ForkliftModels` — those disable this script's controls entirely

**Bottom level says full but I only see one or two cars:**
- Check `Config.MaxVehiclesPerLevel` — the default caps each level at 3, so "full" may be reached with fewer vehicles than you expect visually

**B doesn't unload anything:**
- You must be driving the vehicle that is actively towing the loaded trailer, and there must be a vehicle currently eligible under the load-order rule (see Key Features → Load-Order Safety)

**Vehicle falls through the trailer / clips on unload:**
- Always unload in the order the script enforces — trying to bypass it (e.g. via other scripts detaching vehicles directly) can leave a vehicle without proper collision restored

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

1. **Compatibility**: Standalone — works with QBCore, ESX, or no framework at all
2. **Performance**: Load state lives in memory only (no database) and is re-synced to each client on join; it does not persist across a full server restart
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Load it up, lift it high, haul it out. 🚛**
