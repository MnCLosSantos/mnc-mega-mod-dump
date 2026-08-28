# 🔑 MNC Starting Car

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A one-time "pick your first car" showroom for new characters. Three vehicles sit on permanent display; a marker at a central selection point opens a browser UI where a player picks one, signs a pink-slip style ownership document, and is delivered their new vehicle — fully owned, keyed, and registered to `player_vehicles` — at a configurable delivery point away from the showroom. Each character can only ever claim one starter vehicle, enforced server-side by a unique database constraint, not just a client-side flag.

---

## ✨ Key Features

### 🏬 Persistent Showroom
- `Config.VehicleSpawns` defines up to any number of showroom vehicles, each with its own model, display label, exact parking coords, and a unique "bought" sound
- Showroom vehicles are always present — when one is claimed, a fresh replacement spawns back into the same slot so the showroom never sits empty

### 🎯 Single Interaction Point
- Rather than an `[E]` prompt on every car, one marker (`Config.SelectionPoint`) opens a browser UI listing all three vehicles at once, with live availability (a slot briefly shows unavailable while its replacement respawns)
- Marker draw distance and interaction distance are both configurable (`Config.MarkerDrawDistance`, `Config.InteractionDistance`)

### ✍️ One-Time Signed Claim
- Claiming opens a signing flow that records the player's name and signature (type + data) alongside the claim in `mnc_startingcar_claims`
- A **unique key on `citizenid`** in that table is the actual enforcement — even if the client-side "already claimed" flag were bypassed, the database will still refuse a second claim for the same character
- Vehicles are delivered to `Config.DeliveryPoint` (or handed over right in the showroom slot if left `nil`), keeping the showroom itself clear of purchased cars

### 🔊 Built-In Audio (No External Sound Resource Needed)
- An intro jingle (`Config.SoundFile`) plays once, ever, the first time a player opens the browser — tracked per-`citizenid` in `mnc_startingcar_sound_log` so it never repeats
- Each vehicle has its own delivery sound (e.g. `sounds/euro.mp3`, `sounds/jdm.mp3`, `sounds/usdm.mp3`) that plays the moment the player is warped into their new car
- All audio plays through the resource's own NUI — no `xsound` calls are actually made in the code despite it being listed as a manifest dependency (see Important Notes)

### 🐛 Built-In Debug Tool
- `/startercardebug` toggles a live F8 console readout of your distance to the selector point and each vehicle spawn, and whether a vehicle is actually detected at each one — the fastest way to diagnose a miscalibrated `config.lua` after pasting in your own coordinates

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |
| xsound | Latest | ⚠️ Declared in `fxmanifest.lua`, not actually called by any code — see Important Notes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-startingcar/
```

### 2️⃣ Database Setup

The script **automatically creates** both `mnc_startingcar_claims` and `mnc_startingcar_sound_log` on first start — no manual SQL import needed.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure xsound
ensure mnc-startingcar
```

### 4️⃣ Configure Settings

Edit `config.lua` to set your showroom's exact coordinates, vehicle choices, delivery point, and marker appearance — these are placeholder coordinates and **must** be changed to match your map.

---

## ⚙️ Configuration Guide

```lua
Config = {}

Config.VehicleSpawns = {
    { model = 'sentinel3',    label = 'Sentinel Classic', coords = vector4(-1013.12, -2695.48, 13.42, 149.79), boughtSound = 'sounds/euro.mp3' },
    { model = 'remus',        label = 'Remus',            coords = vector4(-1018.22, -2691.83, 13.3, 151.31),  boughtSound = 'sounds/jdm.mp3'  },
    { model = 'dominator10',  label = 'Dominator FX',     coords = vector4(-1015.56, -2693.84, 13.4, 154.16),  boughtSound = 'sounds/usdm.mp3' },
}

Config.SelectionPoint = vector4(-1017.1, -2696.67, 13.98, 328.07)
Config.MarkerDrawDistance = 45.0
Config.InteractionDistance = 2.5

Config.Marker = {
    type = 1, size = vector3(1.2, 1.2, 0.6),
    color = { r = 178, g = 34, b = 68, a = 140 },
    bobUpAndDown = true, faceCamera = false, rotate = false,
}

-- Where a claimed vehicle is delivered instead of its showroom slot; nil = hand it over in place
Config.DeliveryPoint = vector4(-1010.79, -2685.4, 13.41, 332.31)

Config.SoundFile = 'audio.mp3'
Config.IntroSoundVolume = 0.6
Config.VehicleSoundVolume = 0.8

Config.Blip = { enabled = false, sprite = 225, color = 3, scale = 0.7, label = 'Claim Starter Vehicle' }

Config.GarageName = 'pillbox'
Config.FuelSystem = 'legacy'
Config.RespawnDelay = 5000
```

- `Config.VehicleSpawns` — add or remove showroom vehicles freely; each entry needs its own unique `coords` and can optionally set its own `boughtSound`
- `Config.RespawnDelay` — how long (ms) after a claim before the replacement vehicle spawns back into that slot
- `Config.GarageName` / `Config.FuelSystem` — must match the garage and fuel resource your server actually uses so the claimed vehicle registers correctly

---

## 🎮 Controls & Usage

| Command / Interaction | Description |
|---|---|
| Walk to `Config.SelectionPoint` marker, press **E** | Opens the vehicle browser UI |
| `/startercardebug` | Toggles a live distance/detection readout in the F8 console for calibrating coordinates |

**Claiming flow:**
1. Stand on the marker and press **E** to open the browser
2. Pick one of the available showroom vehicles
3. Sign the pink-slip document with your character's name
4. The vehicle is registered to your character and delivered to `Config.DeliveryPoint` (or handed over in place); the showroom slot respawns a fresh replacement after `Config.RespawnDelay`

---

## 🔧 Troubleshooting

**Marker/prompt never appears:**
- Run `/startercardebug` and check the reported distance to `Config.SelectionPoint` — if it never gets small, your pasted coordinates don't match where you're actually standing
- Increase `Config.MarkerDrawDistance` if the marker should be visible from further away

**A showroom slot shows no vehicle:**
- `/startercardebug` reports whether a vehicle is actually detected at each spawn; if distance is fine but "vehicle" stays false, the vehicle never spawned server-side — check the server console for spawn errors
- A slot briefly shows unavailable for `Config.RespawnDelay` ms right after being claimed — this is expected

**Player can't claim a second vehicle (intentional) but reports a bug:**
- This is enforced by a unique key on `citizenid` in `mnc_startingcar_claims` — one claim per character is by design, not a bug

**Resource won't start / dependency error mentioning `xsound`:**
- `xsound` is listed as a manifest dependency but the actual audio playback goes entirely through this resource's own NUI, not through `xsound` calls — you still need `ensure xsound` running before this resource for FiveM's dependency check to pass, even though it isn't functionally used

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

1. **Coordinates**: Every location in `config.lua` is a placeholder from the original build — you must update the showroom, selector, and delivery coordinates to match your own map before use
2. **Database**: Requires oxmysql — two tables are created automatically on first start
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Pick one, sign for it, drive away. 🔑**
