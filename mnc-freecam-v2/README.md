# 🎬 MnC Free Cam (Cinematic Edition)

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
The cinematic build of MnC Free Cam keeps the original fly-cam, mouse look, roll, zoom, and 30-filter cycling from v1, and adds a set of cinematography tools: depth of field, camera shake, cinematic letterbox bars, and adjustable timecycle strength — all controlled with modifier-key + scroll-wheel combos so nothing needs a menu.

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

**Author**: MnCLosSantos
**Version**: 1.0.0
**Framework**: QBCore

Distributed as part of the MnCLosSantos mod-dump collection — open source, please credit the original author if you edit and re-release.
