# 🎥 MnC Free Cam

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

MnC Free Cam is a lightweight, standalone free/spectator camera tool. A single command toggles a fly-around camera with full mouse look, adjustable zoom, roll, and the ability to cycle through 30 built-in screen-effect and timecycle filters, all mirrored to a small NUI overlay.

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

**Author**: MnCLosSantos
**Version**: 1.0.0
**Framework**: QBCore

Distributed as part of the MnCLosSantos mod-dump collection — open source, please credit the original author if you edit and re-release.
