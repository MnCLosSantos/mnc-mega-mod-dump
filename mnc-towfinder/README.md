# 🔍 MNC Tow Finder

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

An **admin/developer diagnostic tool**, not a player-facing job: it automatically spawns every vehicle model registered in `QBCore.Shared.Vehicles`, one at a time, checks its skeleton for tow-hitch bones (`tow_arm`, `attach_female`, `hook`, and related names), and writes out a ready-to-use Lua table of every model that actually supports towing or being towed. Instead of manually test-driving dozens of vehicles to find which ones have a tow bar or hitch, run one scan and get a categorized, bone-grouped list in seconds.

---

## ✨ Key Features

### 🦴 Skeleton-Based Detection
- Checks each vehicle for any of nine known tow-related bone names (`tow_arm`, `tow_arm_l`, `tow_arm_r`, `attach_female`, `attach_male`, `tow_bar`, `hook`, `hook_l`, `hook_r`) using `GetEntityBoneIndexByName` — far more reliable than guessing from vehicle class or name
- Every vehicle in `QBCore.Shared.Vehicles` is scanned, not just a hardcoded shortlist, so the results stay accurate even after you add custom vehicles to your server

### 🤖 Fully Automated Scan
- Spawns each model at a quiet, out-of-the-way location (`Config.SpawnCoords`, defaults to a dock/LSIA-style spot), checks its bones, then deletes it and moves to the next — no manual spawning required
- A progress circle and periodic chat notifications ("Scanning 15/312 | Found: 4") keep you informed during what can be a multi-minute scan over hundreds of models
- The player is frozen in place for the duration of the scan and automatically unfrozen when it finishes or is cancelled

### 📄 Auto-Generated Output File
- Results are grouped by which bone was found and written to `output/tow_vehicles.lua` as a ready-to-paste `TowBarVehicles` table, commented with generation date and total count
- If the file can't be written (permissions, read-only filesystem), the full result is dumped to the server console instead so nothing is lost

### 📋 In-Game Results Browser
- After a scan, an `ox_lib` context menu lists every tow-capable vehicle found, grouped and labeled by which bone it has — useful for a quick look without opening the output file at all

### 🔒 Admin-Only, Server-Enforced
- Both starting a scan and saving results check `QBCore.Functions.HasPermission(src, 'admin')` **server-side** — a non-admin typing the command receives an explicit "access denied" notification rather than the command silently doing nothing, and can't be bypassed from the client

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-towfinder/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure mnc-towfinder
```

No database setup required. The resource creates its own `output/` folder on the vehicle's `resources` path automatically when it starts.

### 3️⃣ Configure Settings

Edit the `Config` table at the top of `client/main.lua` to change the spawn location or add additional bone names to check for.

---

## ⚙️ Configuration Guide

```lua
local Config = {
    -- Milliseconds to wait after spawning before checking.
    -- 300 ms is usually fine; raise to 600/1000 if models load slowly.
    SpawnDelay = 300,

    -- Spawn coords – somewhere flat and quiet. docks or lsia is ideal
    SpawnCoords = vector3(87.99, -2723.12, 6.0),

    -- Bones whose presence means "this vehicle can tow or be towed".
    TowBones = {
        'tow_arm', 'tow_arm_l', 'tow_arm_r',
        'attach_female',   -- hitch receiver
        'attach_male',     -- hitch ball
        'tow_bar',
        'hook', 'hook_l', 'hook_r',
    },
}
```

- `Config.SpawnDelay` — raise this if a scan through custom/high-poly vehicle models reports false negatives, since the bone check runs before the model has necessarily fully finished streaming in
- `Config.TowBones` — add any additional bone name here if you have custom vehicles using a non-standard hitch bone naming scheme
- `Config.SpawnCoords` — pick anywhere flat, empty, and away from players; hundreds of vehicles will spawn and despawn there in quick succession during a scan

---

## 🎮 Controls & Usage

| Command | Who | Description |
|---------|-----|-------------|
| `/towfinder` | Admin | Requests the full vehicle list and opens the start menu |
| `/mnc-towfinder` | Admin | Alias for `/towfinder` |

**Running a scan:**
1. Run `/towfinder` as an admin — the server sends back every model in `QBCore.Shared.Vehicles`
2. Select **Start Bone Scan** from the menu
3. Wait for the scan to complete (a progress circle tracks estimated time remaining)
4. Review the results in the in-game context menu, and/or open `resources/[custom]/mnc-towfinder/output/tow_vehicles.lua` for the full generated table

---

## 🔧 Troubleshooting

**"You do not have permission to use TowFinder":**
- The command checks `QBCore.Functions.HasPermission(src, 'admin')` server-side — grant your account the `admin` permission group through QBCore, not just an ACE permission

**Scan finds fewer tow-capable vehicles than expected:**
- Some custom vehicle models use non-standard bone names for their hitch — add them to `Config.TowBones`
- Try raising `Config.SpawnDelay` if models are still streaming in when the bone check runs

**Output file wasn't created:**
- Check the server console — a failed file write dumps the full result there instead, usually caused by filesystem permissions on the resource's folder
- Confirm the `output/` folder exists under the resource path; it's created automatically on resource start but can be recreated manually if needed

**Scan takes a long time:**
- This is expected — every single vehicle model on your server is spawned and checked individually. A server with several hundred registered vehicles can take a few minutes to fully scan

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

1. **This is a diagnostic/dev tool, not a player-facing feature** — it's meant to be run once (or occasionally after adding new vehicles) by server staff, not exposed to regular players
2. **Performance impact**: A full scan spawns and despawns potentially hundreds of vehicles in rapid succession — run it on a low-population server or during downtime, not during peak hours
3. **Compatibility**: QBCore only — reads directly from `QBCore.Shared.Vehicles`, not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Scan once, tow forever. 🔍**
