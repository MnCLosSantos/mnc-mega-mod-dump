# 🎮 MNC Hydro UI

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![Standalone](https://img.shields.io/badge/Framework-Standalone-lightgrey.svg)]()
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A standalone hydraulics control HUD that automatically appears the moment you get behind the wheel of a lowrider-class vehicle (or any vehicle with the native hydraulics mod installed). Bounce each corner independently with the arrow keys, engage a full lift with **O**, or trigger a scripted 3-wheel lean with the numpad — all controlled through direct force application tuned corner-by-corner, since GTA's hydraulics natives can't reliably isolate a single wheel on their own.

---

## ✨ Key Features

### 🚙 Automatic Detection
- The UI opens automatically the instant you sit in the driver's seat of a vehicle that either matches the built-in lowrider model whitelist (Voodoo, Tornado, Faction, Primo, Peyote, Slamvan, Buccaneer, and more) or has the native hydraulics mod (`VMT_HYDRAULICS`, mod type 21) installed through any mod shop — no manual toggle needed
- Stepping out keeps the session open within a configurable exit distance, so you can still control hydraulics remotely for a few moments (e.g. hopping out to check how a lean looks) before the panel closes

### 🕹️ Directional Bounce Control
- **Arrow keys** (`↑` `↓` `←` `→`) bounce the front, rear, left, and right corners independently while held
- **O** engages a full lift, locking the car up high

### 📐 Scripted 3-Wheel Presets
- **Numpad3** runs a two-phase "turning right" trick (locks high, then ramps in a lift on the front-right corner and holds it indefinitely)
- **Numpad1** mirrors it for "turning left" (front-left corner)
- Built on a physics force-couple applied to a specific wheel bone rather than the hydraulics natives directly — testing found the natives couldn't isolate a single corner cleanly, so the 3-wheel effect is achieved with a tuned, ramped force instead
- The lean holds indefinitely once engaged (a real 3-wheel doesn't self-release) — press an arrow key to take manual control back, or **O** to drop it

### 🖥️ Toggleable HUD
- **N** toggles the on-screen hydraulics HUD visibility without ending the control session

### 🧪 Built-In Debug & Testing Tools
- `/hydrodebug` — dumps full current state (model, whitelist match, hydraulics mod tier, UI state, macro phase, last natives sent, vertical velocity) to the F8 console
- `/hydrodebugtoggle` — toggles verbose per-frame debug logging
- `/hydrotest <front|rear|left|right|frontleft|frontright|rearleft|rearright|all|off>` — holds a specific hydraulics native combo indefinitely for testing
- `/hydrotilt <fl|fr|rl|rr|off>` — applies the same tuned force-couple lift used by the 3-wheel presets to any single corner on demand, for testing before trusting it inside the Numpad1/3 presets

### 🔌 Export for Other Resources
- `exports['mnc-hydroui']:IsHydroUIOpen()` — returns whether the hydraulics panel is currently open, for other resources (HUDs, animations, etc.) to check against

---

## 📋 Requirements

| Dependency | Required |
|---|---|
| None — standalone client-side script, no framework or database dependency | — |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-hydroui/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure mnc-hydroui
```

No database or item setup required.

---

## 🎮 Controls & Usage

| Input | Action |
|---|---|
| Sit in a lowrider or hydraulics-modded vehicle | HUD opens automatically |
| **O** (hold) | Engage a full hydraulics lift |
| **↑ / ↓ / ← / →** | Bounce front / rear / left / right corner independently |
| **Numpad3** | Scripted 3-wheel lean, turning right (locks up, then lifts front-right) |
| **Numpad1** | Scripted 3-wheel lean, turning left (locks up, then lifts front-left) |
| **N** | Toggle HUD visibility (control session stays active) |
| `/hydrodebug` | Print current hydraulics/UI state to the F8 console |
| `/hydrodebugtoggle` | Toggle verbose per-frame debug logging |
| `/hydrotest <combo\|off>` | Hold a specific hydraulics native combo for testing |
| `/hydrotilt <fl\|fr\|rl\|rr\|off>` | Apply the 3-wheel force-couple lift to a single corner for testing |

---

## 🔧 Troubleshooting

**HUD doesn't open in a vehicle you'd expect to have hydraulics:**
- Run `/hydrodebug` while seated — it reports whether the model matched the built-in whitelist and whether the native hydraulics mod (tier 0+) is installed
- Non-whitelisted models need the native hydraulics mod actually installed via a mod shop to trigger the HUD

**3-wheel preset doesn't lift the expected corner:**
- Testing found only the front-right and front-left corners reliably isolate with the current force-couple tuning — use `/hydrotilt` to test other corners individually before assuming a preset should use them

**Hydraulics stay engaged after getting out of the vehicle:**
- This is intentional — the session (and remote control) stays active until you move beyond the exit-distance threshold, so you can still control the vehicle briefly after stepping out

**HUD stuck open/closed after a resource restart:**
- The client re-syncs UI state (`open`/`hide`) to the NUI the moment it reports ready, specifically to recover from this — if it still looks stuck, run `/hydrodebug` to confirm the underlying state and toggle **O**/**N** to force a resync

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

1. **Not the same tool as `mnc-hydros`**: this dump also includes [`mnc-hydros`](../mnc-hydros), a separate QBCore-integrated hydraulics kit/wear system with its own admin commands and database persistence. `mnc-hydroui` is a standalone, framework-free control HUD built around GTA's native hydraulics mod and a fixed lowrider model whitelist — the two are independent tools, not alternate versions of each other, and can be run together or separately depending on what your server needs
2. **No config.lua**: settings (whitelist models, keybinds, exit distance) are defined as local constants at the top of `client.lua` rather than a separate config file — edit them there if you need to add models or change tuning
3. **Compatibility**: Framework-agnostic — works alongside QBCore, ESX, or standalone
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Bounce it, lean it, lock it up. 🎮**
