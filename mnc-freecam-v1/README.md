# 🎬 MnC Free Cam (Cinematic Edition)

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

> ⚠️ **Multiple versions of this script exist in this dump — install only ONE.** `mnc-freecam-v2` is one of several builds of this tool alongside `mnc-freecam-v1`, `mnc-freecam-v3`. Running more than one at the same time will register the same commands/exports twice and can corrupt shared data. All three register the same /freecam command. See "Choosing a Version" below.

---

## 🌟 Overview

The cinematic build of MnC Free Cam keeps the original fly-cam, mouse look, roll, zoom, and 30-filter cycling from v1, and adds a set of cinematography tools: depth of field, camera shake, cinematic letterbox bars, and adjustable timecycle strength — all controlled with modifier-key + scroll-wheel combos so nothing needs a menu.

---

## 🔀 Choosing a Version

This dump contains three builds of the free camera. **Install only one** — all three bind the same `/freecam` command and ship the same NUI page.

| | `mnc-freecam-v1` | `mnc-freecam-v2` (this one) | `mnc-freecam-v3` |
|---|---|---|---|
| Fly cam, mouse look, roll, zoom, 30 filters | ✅ | ✅ | ✅ |
| Depth of field / camera shake / cinematic bars / timecycle strength | ❌ | ✅ | ✅ |
| Vehicle camera mode customization (8 modes, per-vehicle-model saved offsets) | ❌ | ❌ | ✅ |
| Cinematic keyframe sequence editor (record, loop/pingpong playback) | ❌ | ❌ | ✅ |
| Share-code import/export for cinematics | ❌ | ❌ | ✅ |
| 20-slot presets, custom cam slots, database persistence | ❌ | ❌ | ✅ |
| Dependencies | none | none | qb-core, oxmysql |
| Version | 1.0.0 | 1.0.0 | 3.0.0 |

v3 is a strict superset of this build's cinematography tools, plus a much larger vehicle-camera-customization and cinematic-editor suite on top of that. Stick with v2 if you want the DOF/shake/bars extras with zero dependencies and no database; move to **v3** if you also want per-vehicle camera presets, a shareable cinematic sequence editor, and persistence.

---

## ✨ Key Features

**Core Camera (same as v1)**
- `Config.ActivationCommand` (default `freecam`) toggles the camera, hides HUD/radar, freezes the player, shows the NUI overlay
- `W/A/S/D` move, `Q/E` up/down, mouse look, `◄/►` roll, mouse wheel zoom (10–120 FOV), `▲/▼` cycle 30 filters, `Backspace` toggles HUD

**Cinematic Tools (new in v2)**
- **Depth of Field** — hold `Z` + scroll to adjust near-focus distance, hold `X` + scroll to adjust far-focus distance (auto-enables DOF); tap `Z` alone to toggle DOF on/off
- **Camera Shake** — hold `C` + scroll to dial hand-shake amplitude from 0.0–3.0
- **Timecycle Strength** — hold `G` + scroll to adjust the active filter's timecycle strength (0.0–5.0)
- **Cinematic Bars** — hold `B` + scroll to resize letterbox bars (0–30% of screen height); tap `B` alone to toggle bars on/off
- All cinematic effects (DOF, shake, bars, filter) automatically reset when the camera is closed

---

## 📋 Requirements

| Dependency | Required |
|---|---|
| None — standalone client script, no framework or library dependency | — |

---

## 🚀 Installation

```bash
# Place into your resources folder
[server-data]/resources/[custom]/mnc-freecam-v2/
```

```lua
# server.cfg
ensure mnc-freecam-v2
```

No database or item setup required — this is a pure client-side camera tool.

---

## ⚙️ Configuration Guide

```lua
Config = {}

-- Command to toggle free cam
Config.ActivationCommand = "freecam"

-- Maximum distance the camera can move from spawn point
Config.CameraRange = 100.0
```

Same two config keys as v1: the activation command and a declared camera range limit.

---

## 🎮 Controls & Usage

| Input | Action |
|---|---|
| `/freecam` | Toggle free camera on/off |
| `W A S D` / `Q` `E` | Move / strafe / up / down |
| Mouse | Look around |
| Mouse wheel (no modifier) | Zoom (FOV) |
| `◄` / `►` | Roll camera |
| `▲` / `▼` | Cycle filters |
| Hold `Z` + scroll | DOF near distance (tap alone = toggle DOF) |
| Hold `X` + scroll | DOF far distance |
| Hold `C` + scroll | Camera shake amplitude |
| Hold `G` + scroll | Timecycle strength |
| Hold `B` + scroll | Cinematic bar size (tap alone = toggle bars) |
| `Backspace` | Toggle HUD overlay |

---

## 🔧 Troubleshooting

- **DOF looks wrong/blurry everywhere** — DOF requires `SetUseHiDof()` to run every frame while active, which the script already handles; make sure no other camera resource is also managing DOF.
- **Modifier keys not registering** — the hold keys (Z/X/C/G/B) use `IsDisabledControlPressed`, so they should work even with other controls disabled; confirm no other resource is stealing those raw control indexes.
- **Effects persist after closing free cam** — `resetEffects()` runs on close; if bars/shake linger, check for script errors in the F8 console.

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

