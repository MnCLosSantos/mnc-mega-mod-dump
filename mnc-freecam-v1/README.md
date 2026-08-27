# 🎥 MnC Free Cam

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

> ⚠️ **Multiple versions of this script exist in this dump — install only ONE.** `mnc-freecam-v1` is one of several builds of this tool alongside `mnc-freecam-v2`, `mnc-freecam-v3`. Running more than one at the same time will register the same commands/exports twice and can corrupt shared data. All three register the same /freecam command. See "Choosing a Version" below.

---

## 🌟 Overview

MnC Free Cam is a lightweight, standalone free/spectator camera tool. A single command toggles a fly-around camera with full mouse look, adjustable zoom, roll, and the ability to cycle through 30 built-in screen-effect and timecycle filters, all mirrored to a small NUI overlay.

---

## 🔀 Choosing a Version

This dump contains three builds of the free camera. **Install only one** — all three bind the same `/freecam` command and ship the same NUI page.

| | `mnc-freecam-v1` (this one) | `mnc-freecam-v2` | `mnc-freecam-v3` |
|---|---|---|---|
| Fly cam, mouse look, roll, zoom, 30 filters | ✅ | ✅ | ✅ |
| Depth of field / camera shake / cinematic bars / timecycle strength | ❌ | ✅ | ✅ |
| Vehicle camera mode customization (8 modes, per-vehicle-model saved offsets) | ❌ | ❌ | ✅ |
| Cinematic keyframe sequence editor (record, loop/pingpong playback) | ❌ | ❌ | ✅ |
| Share-code import/export for cinematics | ❌ | ❌ | ✅ |
| 20-slot presets, custom cam slots, database persistence | ❌ | ❌ | ✅ |
| Dependencies | none | none | qb-core, oxmysql |
| Version | 1.0.0 | 1.0.0 | 3.0.0 |

v3 is a strict superset of v1 and v2's camera and cinematography tools, plus a much larger vehicle-camera-customization and cinematic-editor suite on top. Pick v1 only if you want the smallest possible footprint with zero dependencies; pick v2 for the DOF/shake/bars cinematography extras without a database; pick **v3** for the full feature set (requires qb-core + oxmysql).

---

## ✨ Key Features

**Camera Toggle**
- `Config.ActivationCommand` (default `freecam`) creates and activates a scripted camera at the player's position, hides the HUD/radar, freezes the player, and shows the NUI overlay
- Running the command again destroys the camera, clears any active filter, and restores the player and HUD

**Movement & Look**
- `W/A/S/D` fly forward/back/strafe left/right relative to camera facing
- `Q` / `E` move straight up/down
- Free mouse look while active
- Left/Right arrow keys roll the camera
- Mouse scroll wheel zooms (FOV clamped between 30–120)

**Filters**
- 30 predefined filters (screen effects like `SniperOverlay`, `Rampage`, `PPFilter`/`PPGreen`/`PPOrange`/`PPPink`/`PPPurple`, `LostTimeDay`/`Night`, `BikerFilter`, etc., plus one timecycle modifier)
- Up/Down arrow keys cycle forward/backward through the filter list
- **Backspace** toggles the NUI HUD panel on/off

---

## 📋 Requirements

| Dependency | Required |
|---|---|
| None — standalone client script, no framework or library dependency | — |

---

## 🚀 Installation

```bash
# Place into your resources folder
[server-data]/resources/[custom]/mnc-freecam-v1/
```

```lua
# server.cfg
ensure mnc-freecam-v1
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

`Config.ActivationCommand` sets the chat command that toggles the camera. `Config.CameraRange` is declared for limiting how far the camera can roam from its starting point.

---

## 🎮 Controls & Usage

| Input | Action |
|---|---|
| `/freecam` | Toggle free camera on/off |
| `W A S D` | Move forward / back / strafe |
| `Q` / `E` | Move up / down |
| Mouse | Look around |
| Mouse wheel | Zoom (FOV) |
| `◄` / `►` | Roll camera |
| `▲` / `▼` | Cycle filters forward / backward |
| `Backspace` | Toggle HUD overlay |

---

## 🔧 Troubleshooting

- **Command does nothing** — verify the resource actually started (`ensure mnc-freecam-v1` in server.cfg) and that no other resource is also bound to the `/freecam` command.
- **Camera controls feel unresponsive** — free cam disables most player controls while active; if movement still leaks through, check for conflicting keybind resources.
- **Filters look wrong in-game** — some entries are screen effects and one (`yell_tunnel_nodirect`) is a timecycle modifier; both are cleared automatically when you cycle away or close the camera.

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

