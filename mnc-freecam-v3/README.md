# 🎬 MNC Free Cam v3 (Cinematic Suite)

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-3.0.0-brightgreen.svg)]()

> ⚠️ **Multiple versions of this script exist in this dump — install only ONE.** `mnc-freecam-v3` is one of three builds of this tool alongside `mnc-freecam-v1` and `mnc-freecam-v2`. All three bind the same `/freecam` command and NUI page — running more than one at once means duplicate camera controllers fighting for the same keys. See "Choosing a Version" below.

---

## 🌟 Overview

The full cinematic suite build of MnC Free Cam. It keeps every camera and cinematography tool from v1/v2 (fly cam, mouse look, 30 filters, depth of field, camera shake, cinematic letterbox bars, timecycle strength) and adds a completely new layer on top: a **per-vehicle camera customization system** with 8 built-in view modes and per-model saved offsets, a **keyframe-based cinematic sequence editor** with recording, looped/ping-pong playback and a 4-word share-code system so players can trade their cinematics, a **20-slot freecam preset system**, custom camera slots, and full database persistence via `oxmysql` — everything is saved per-`citizenid` and survives restarts.

---

## 🔀 Choosing a Version

This dump contains three builds of the free camera. **Install only one** — all three bind the same `/freecam` command and ship the same NUI page.

| | `mnc-freecam-v1` | `mnc-freecam-v2` | `mnc-freecam-v3` (this one) |
|---|---|---|---|
| Fly cam, mouse look, roll, zoom, 30 filters | ✅ | ✅ | ✅ |
| Depth of field / camera shake / cinematic bars / timecycle strength | ❌ | ✅ | ✅ |
| Vehicle camera mode customization (8 modes, per-vehicle-model saved offsets) | ❌ | ❌ | ✅ |
| Cinematic keyframe sequence editor (record, loop/pingpong playback) | ❌ | ❌ | ✅ |
| Share-code import/export for cinematics | ❌ | ❌ | ✅ |
| 20-slot presets, custom cam slots, database persistence | ❌ | ❌ | ✅ |
| Dependencies | none | none | qb-core, oxmysql |
| Version | 1.0.0 | 1.0.0 | 3.0.0 |

v3 is a strict superset of the other two — pick it unless you deliberately want the smaller, dependency-free builds. There is no reason to run more than one at a time.

---

## ✨ Key Features

### 🎥 Core Free Camera (inherited from v1/v2)
- `Config.ActivationCommand` (default `freecam`) toggles a fly-around camera, hides HUD/radar, freezes the player, and shows the NUI overlay
- `W/A/S/D` move, `Q`/`E` up/down, mouse look, `[`/`]` roll left/right, mouse wheel zoom
- `,` / `.` cycle backward/forward through 30 built-in screen-effect and timecycle filters
- Depth of field, hand-shake camera shake, cinematic letterbox bars, and timecycle strength — all tunable with modifier-key + scroll combos, and reset automatically when the camera closes

### 🚗 Vehicle Camera Customization (new in v3)
- **8 built-in camera modes**: bumper, close chase, far chase, farther chase, driver (in-car), left side, right side, and top-down
- **`/camsets`** opens a live editor while you're in a vehicle to nudge each mode's position, pitch/yaw/roll, FOV, and clamp ranges
- **Per-citizen offsets** for every mode, saved to `mnc_freecam_cam_offsets` and re-applied on every session
- **Per-vehicle-model overrides** — a mode can additionally be tuned per model (e.g. a lower driver cam just for supercars) and is stored separately in `mnc_freecam_model_offsets`
- **Cam flags** per camera (cycle-hidden, hide-peds, auto-head-track) persisted in `mnc_freecam_cam_flags`
- **Custom cam slots** (`mnc_freecam_custom_cams`) for mapping additional numeric GTA view modes with a player-given label
- **`/freecam_cam_switcher_v2`** and **`/freecam_cam_cycle`** to open the switcher UI or cycle through configured vehicle cams

### 🎞️ Cinematic Sequence Editor (new in v3)
- **Keyframe capture** — press **`K`** while in free cam to drop a keyframe (position, rotation, FOV, timing)
- **Playback modes**: once, loop, or ping-pong
- **`/freecam_cinematic`** (default key **`I`**) opens the cinematic editor / completes the current capture setup
- **`/cinematics`** toggles the cinematic panel while free cam is active
- **Save, rename, and reload** sequences per player, stored in `mnc_freecam_sequences` as JSON keyframe data
- **4-word share codes** (e.g. `TIGER-BLUE-7-SUNSET`) — every saved sequence gets a unique code; **`/importcinematic <code>`** lets another player pull a copy of it into their own library without overwriting the original
- World-space and vehicle-relative sequence types are both supported

### 🗂️ Presets & Misc
- **20 freecam presets** (`mnc_freecam_presets`) — save/recall full camera+effect state by slot
- **`/freecam_preset_mgr_v2`** opens the preset manager UI
- **`/freecam_hide_ped`** toggles hiding your own ped model while filming
- All database tables are created and upgraded automatically on resource start (including in-place `ALTER TABLE` upgrades for older schemas)

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |

Unlike v1/v2 (which are dependency-free), v3 needs `qb-core` (to resolve each player's `citizenid`) and `oxmysql` (for all persistence).

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-freecam-v3/
```

### 2️⃣ Database Setup

The script **automatically creates and upgrades** all required tables on first start — no manual SQL import needed:

- `mnc_freecam_sequences` — saved cinematic sequences, keyframes, playback mode, and share codes
- `mnc_freecam_cam_offsets` — per-citizen offsets for each of the 8 vehicle camera modes
- `mnc_freecam_model_offsets` — per-citizen, per-vehicle-model camera overrides
- `mnc_freecam_cam_flags` — per-camera flags (cycle-hidden, hide-peds, auto-head-track)
- `mnc_freecam_custom_cams` — player-defined custom camera slots
- `mnc_freecam_presets` — 20-slot freecam presets

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-freecam-v3
```

### 4️⃣ Configure Settings

```lua
Config = {}
Config.ActivationCommand = "freecam"   -- chat command to toggle the camera
Config.CameraRange = 100.0             -- declared range limit from spawn point
```

---

## 🎮 Controls & Usage

| Input | Action |
|---|---|
| `/freecam` | Toggle free camera on/off |
| `W A S D` / `Q` `E` | Move / strafe / up / down |
| Mouse | Look around |
| Mouse wheel | Zoom (FOV) |
| `[` / `]` | Roll camera left / right |
| `,` / `.` | Previous / next filter |
| `K` | Capture keyframe / camera position |
| `I` | Open cinematic editor / complete setup |
| `/cinematics` | Toggle the cinematic panel |
| `/importcinematic <code>` | Import someone else's shared cinematic sequence |
| `H` | Toggle hiding your own ped |
| `/` | Open the vehicle camera switcher |
| `C` | Cycle vehicle camera mode |
| `O` | Open the freecam preset manager |
| `/camsets` | Open the live vehicle-camera offset editor (while in a vehicle) |

---

## 🔧 Troubleshooting

**Vehicle cam offsets don't save:**
- Confirm `oxmysql` is connected and the `mnc_freecam_cam_offsets` / `mnc_freecam_model_offsets` tables exist in the server console log on startup
- Offsets are keyed by `citizenid` — make sure `qb-core` has finished loading the player before adjusting cams

**Imported cinematic says "already have this sequence":**
- The importer checks both the share code and the `source_share_code` of previously imported copies — you can only import a given sequence once per character

**Camera controls feel unresponsive:**
- Free cam disables most player controls while active; if movement still leaks through, check for conflicting keybind resources bound to the same raw control indexes (`[`, `]`, `,`, `.`, `K`, `I`, `H`, `/`, `C`, `O`)

**DOF/shake/bars don't reset:**
- These are cleared automatically when free cam closes; if they linger, check the F8 console for script errors interrupting `resetEffects()`

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 3.0.0
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

1. **Database**: Requires oxmysql — MariaDB 10.3+ recommended; six tables are created/upgraded automatically on first start
2. **Compatibility**: QBCore only — not compatible with ESX (uses `citizenid` for all persistence)
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Direct it, capture it, share it. 🎬**
