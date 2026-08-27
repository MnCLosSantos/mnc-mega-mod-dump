# 🎛️ MNC Hand UI Plate

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
An admin-only vehicle handling editor for QBCore, identical in UI and feature set to [`mnc-handui`](../mnc-handui) but scoped per **vehicle plate** instead of per model. Two Sultans with different plates can have completely different handling — editing one never touches the other. Tune speed, acceleration, braking, traction, suspension, and damage live in-game with sliders, and save straight to SQL, no `.meta` edits or restarts required.

---

## 🔗 Related Resource

This dump also includes [`mnc-handui`](../mnc-handui), which shares the same editor UI and handling-field set but saves overrides per vehicle **model** instead — one change there applies to every vehicle of that model server-wide. The two are **not** alternate versions of each other and are safe to run together: they use different commands (`/handuiplate` vs `/handui`) and separate database tables, so pick whichever scope (or both) fits your server.

---

## ✨ Key Features

### 🎚️ Live Handling Editor
- Search any vehicle, or hop in one and hit **"Use My Vehicle"**, then tune sliders across five categories: Engine & Power, Braking, Traction & Steering, Suspension, and Mass & Damage
- Optionally spawn a drivable test vehicle to feel changes live before saving, using whatever is currently on your sliders — including unsaved edits
- Game input (WASD/controller) keeps working while the editor panel is open, so you can drive and feel a test vehicle without closing the UI

### 🔖 Per-Plate Scope
- Overrides are keyed to the vehicle's **plate string**, not its model or entity — two identical vehicles with different plates are tuned completely independently
- This makes it ideal for tuning a specific player-owned vehicle, a specific fleet unit, or a one-off event car without affecting every other copy of that model on the server
- **Trade-off to be aware of**: changing a vehicle's plate later (e.g. through a mod shop respray/replate) orphans its saved override, since the save is keyed to the plate string rather than the vehicle itself

### 🎯 Presets
- The same seven built-in presets as `mnc-handui` — Civilian, Police, Eco, Street, Race, Drag, and Drift — applied as multipliers against the vehicle's own vanilla handling values

### 📋 Saved Overrides Tab
- Lists every plate with a custom override, who last edited it, and when
- **Edit** reopens it in the editor; **Revert** deletes the override and restores that specific vehicle's true default handling
- The first save captures that vehicle's vanilla `handling.meta` baseline alongside your changes

### 🧩 Addon Vehicle Support
- Fully supports addon vehicles, not just ones registered in `qb-core/shared/vehicles.lua`
- If an addon vehicle doesn't show up in the search dropdown, type its exact spawn code and press Enter

### 🛡️ Server-Side Validation
- Every handling field is whitelisted against `Config.HandlingFields` and clamped to its configured min/max server-side — NUI input is never trusted directly

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-handuiPlate/
```

### 2️⃣ Database Setup

Run `sql/install.sql` against your database (also auto-checked on start, but run it manually if your `oxmysql` user can't `CREATE TABLE`).

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure mnc-handuiPlate
```

### 4️⃣ Configure Permissions (Optional)

If you don't already grant `admin` via QBCore groups, you can add an ACE permission:
```
add_ace group.admin command.handuiplate allow
```

---

## ⚙️ Configuration Guide

```lua
Config = {}

-- Command admins type to open the editor (no leading slash)
-- Different from mnc-handui's command so both resources can run side by side.
Config.Command = 'handuiplate'

-- QBCore.Functions.HasPermission level required to open/use the editor
Config.AdminPermission = 'admin'

-- How high above the admin (in metres) ghost preview vehicles are spawned
Config.PreviewHeightOffset = 60.0

-- How far in front of the admin a drivable test vehicle is spawned
Config.TestVehicleSpawnDistance = 4.0

-- Delete any spawned test vehicle automatically when the UI is closed
Config.AutoDespawnTestVehicle = true

-- Warp the admin straight into the driver's seat when a test vehicle is spawned
Config.AutoEnterTestVehicle = true

-- Config.HandlingFields and Config.Presets use the same structure as mnc-handui
-- (see that resource's README for the full field/preset reference).
```

- This resource intentionally has **no `Config.AllowedClasses`** — since overrides are per-plate rather than per-model, the editor works on any vehicle you can sit in or search for
- `Config.HandlingFields` — add or remove entries to change what shows up in the UI; `key` must exactly match a `handling.meta` field name

---

## 🎮 Controls & Usage

| Command | Description |
|---------|-------------|
| `/handuiplate` (configurable via `Config.Command`) | Admin-only — opens the per-plate handling editor |

**Editing one specific vehicle's handling:**
1. Sit in the vehicle and click **Use My Vehicle**, or search for it by plate
2. Adjust sliders across the five categories, or apply a preset
3. Optionally spawn a test vehicle to feel the changes live
4. Save — the override applies only to that exact plate, leaving every other vehicle of the same model untouched

---

## 🔧 Troubleshooting

**A saved override "disappeared" after a vehicle was respray'd or replated:**
- This is expected — overrides are keyed to the plate string, and changing a vehicle's plate creates what is effectively a new key. Re-tune and save again for the new plate

**Addon vehicle doesn't appear in search:**
- Sit in it and use **Use My Vehicle**, or type its exact spawn code directly

**Test vehicle fails to spawn:**
- `CreateVehicle` needs collision actually streamed in at the target point; `Config.PreviewHeightOffset` spawns relative to the admin specifically to guarantee this

**Typing in the search box moves my test vehicle:**
- Expected — game input stays active while the panel is open so you can drive and feel changes; type while stationary

**I wanted this override to apply to every vehicle of this model, not just one:**
- Use [`mnc-handui`](../mnc-handui) instead — it's the model-scoped counterpart to this resource

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

1. **Scope**: Overrides apply per **plate** — only that exact vehicle is affected. Use [`mnc-handui`](../mnc-handui) instead if you want a change to apply to every vehicle of a model
2. **Plate changes orphan overrides**: since the save is keyed to the plate string, respraying/replating a vehicle elsewhere disconnects it from its saved override
3. **Database**: Requires oxmysql — run `sql/install.sql` or let the resource auto-create its table on start
4. **Compatibility**: QBCore only — not compatible with ESX
5. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**One car, one setup, dialed in. 🎛️**
