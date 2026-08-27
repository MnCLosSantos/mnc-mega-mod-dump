# 🎛️ MNC Hand UI

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

An admin-only, **model-based** vehicle handling editor for QBCore. Tune a vehicle's speed, acceleration, braking, traction, suspension, and damage live in-game with sliders, and save the result to SQL — no `.meta` file edits, no server restart required. Because the change is stored per **model**, it instantly applies to every vehicle of that model on the server, existing spawns and all future ones.

---

## 🔗 Related Resource

This dump also includes [`mnc-handuiPlate`](../mnc-handuiPlate), which shares the same editor UI and handling-field set but saves overrides per **vehicle plate** instead of per model — editing one Sultan never touches another Sultan with a different plate. The two are **not** alternate versions of each other and are safe to run together: they use different commands (`/handui` vs `/handuiplate`) and separate database tables, so pick whichever scope (or both) fits your server.

---

## ✨ Key Features

### 🎚️ Live Handling Editor
- Search any vehicle, or hop in one and hit **"Use My Vehicle"**, then tune sliders across five categories: Engine & Power, Braking, Traction & Steering, Suspension, and Mass & Damage
- Optionally spawn a drivable test vehicle to feel changes live before saving — the test vehicle uses whatever is currently on your sliders, including unsaved edits
- Game input (WASD/controller) keeps working while the editor panel is open, so you can drive and feel a test vehicle without closing the UI first

### 🎯 Presets
- Seven built-in presets — Civilian, Police, Eco, Street, Race, Drag, and Drift — each a set of multipliers applied against the vehicle's own vanilla handling values, not flat absolute numbers, so a preset behaves sensibly on both a Panto and a Zentorno
- The Drift preset also sets absolute front-bias targets (`fDriveBiasFront = 0.0`) since bias fields are a 0–1 position on a spectrum, not a magnitude that multiplies meaningfully

### 📋 Saved Overrides Tab
- Lists every model with a custom override, who last edited it, and when
- **Edit** reopens it in the editor; **Revert** deletes the override and snaps every currently-spawned vehicle of that model back to its true default handling
- The first save captures the model's vanilla `handling.meta` baseline alongside your changes — that's what Revert restores you to, even after multiple rounds of edits

### 🧩 Addon Vehicle Support
- Fully supports addon vehicles, not just ones registered in `qb-core/shared/vehicles.lua` — **"Use My Vehicle"** reads the model straight off the entity you're sitting in, with an automatic fallback to the shared-vehicle table on older server builds
- If an addon vehicle doesn't show up in the search dropdown, type its exact spawn code and press Enter

### 🛡️ Server-Side Validation
- Every handling field is whitelisted against `Config.HandlingFields` and clamped to its configured min/max server-side — NUI input is never trusted directly

### 🔄 Live Propagation
- Overrides are cached server-side and pushed to clients on join/resource start; any vehicle of an overridden model gets the saved handling applied the moment it streams in, no per-vehicle setup needed

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
[server-data]/resources/[custom]/mnc-handui/
```

### 2️⃣ Database Setup

Run `sql/install.sql` against your database (also auto-checked on start, but run it manually if your `oxmysql` user can't `CREATE TABLE`).

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure mnc-handui
```

### 4️⃣ Configure Permissions (Optional)

If you don't already grant `admin` via QBCore groups, you can add an ACE permission:
```
add_ace group.admin command.handui allow
```

---

## ⚙️ Configuration Guide

```lua
Config = {}

-- Command admins type to open the editor (no leading slash)
Config.Command = 'handui'

-- QBCore.Functions.HasPermission level required to open/use the editor
Config.AdminPermission = 'admin'

-- Allowed vehicle classes/categories/models that can be tuned with this editor.
Config.AllowedClasses = {
    18,        -- emergency class ID
    'secret',  -- QBCore category
    'military',
}

-- How high above the admin (in metres) ghost preview vehicles are spawned
Config.PreviewHeightOffset = 60.0

-- How far in front of the admin a drivable test vehicle is spawned
Config.TestVehicleSpawnDistance = 4.0

-- Delete any spawned test vehicle automatically when the UI is closed
Config.AutoDespawnTestVehicle = true

-- Warp the admin straight into the driver's seat when a test vehicle is spawned
Config.AutoEnterTestVehicle = true

-- Config.HandlingFields — the tunable fields, grouped into tabs.
-- `key` must match a real handling.meta field name; `type` is 'float' or 'int'.

-- Config.Presets — sparse multiplier tables applied against each vehicle's
-- own vanilla handling values (see Key Features → Presets above).
```

- `Config.AllowedClasses` — accepts a mix of integer vehicle class IDs, string categories, or exact model names; only vehicles matching one of these will open the editor
- `Config.HandlingFields` — add or remove entries to change what shows up in the UI; `key` must exactly match a `handling.meta` field name
- `Config.Presets` — add your own preset by defining a `multipliers` table (relative) and/or an `absolute` table (fixed targets, needed for 0–1 bias-style fields)

---

## 🎮 Controls & Usage

| Command | Description |
|---------|-------------|
| `/handui` (configurable via `Config.Command`) | Admin-only — opens the handling editor |

**Editing a model's handling:**
1. Search for a vehicle model, or sit in one and click **Use My Vehicle**
2. Adjust sliders across the five categories, or apply a preset
3. Optionally spawn a test vehicle to feel the changes live
4. Save — the override applies instantly to every vehicle of that model, present and future

---

## 🔧 Troubleshooting

**Editor won't open for a vehicle:**
- Check `Config.AllowedClasses` — only vehicles matching a listed class ID, category, or exact model name can be tuned

**Addon vehicle doesn't appear in search:**
- There's no generic way to enumerate every streamed addon on a server — sit in it and use **Use My Vehicle**, or type its exact spawn code directly

**Test vehicle fails to spawn:**
- `CreateVehicle` needs collision actually streamed in at the target point; `Config.PreviewHeightOffset` spawns relative to the admin specifically to guarantee this — don't set it to place vehicles somewhere with nothing streamed

**Typing in the search box moves my test vehicle:**
- This is expected — `SetNuiFocusKeepInput` keeps game input active while the panel is open so you can drive and feel changes without closing the UI; type while stationary

**Revert doesn't seem to fully reset a vehicle:**
- Revert restores the captured vanilla baseline from the first time that model was saved — if the model was never saved through this editor, there's nothing to revert to

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

1. **Scope**: Overrides apply per **model** — every vehicle of that model on the server is affected, not just one instance. Use [`mnc-handuiPlate`](../mnc-handuiPlate) instead if you need per-vehicle handling
2. **Database**: Requires oxmysql — run `sql/install.sql` or let the resource auto-create its table on start
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Dial it in, save it, done. 🎛️**
