# 📱 MNC Carplay

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A dash-mounted tablet music unit players install into their own vehicle: pick from 15 physical skins, wire up YouTube/SoundCloud-style URLs into personal playlists, and play music through a synced, radius-based audio system that everyone in and around the car actually hears together — not just the local client. Doors closed muffle it for anyone outside, and it comes right back off with a reusable removal tool whenever you want to relocate or uninstall it.

---

## ✨ Key Features

### 🎨 15 Physical Skins
- 10 solid color units (Silver, Black, White, Red, Blue, Green, Yellow, Purple, Orange, Pink) plus 5 artwork wraps (Racing Stripes, Carbon Fiber, Tactical Camo, Gunmetal Engraved, Walnut Wood)
- Each skin is its own consumable item — installing consumes the specific skin item you used, and the unit visually matches it in-game and in the tablet UI

### 🔧 Real Install/Remove Flow
- Use a Carplay unit item near a vehicle to install it with a timed animation (`Config.InstallTime`, default 4s); a reusable, never-consumed **Carplay Removal Tool** item pulls the installed unit back off (`Config.RemoveTime`) and hands the original skin item back
- `Config.AllowedVehicleClasses` can restrict which vehicle classes accept an install; left `nil`, any vehicle qualifies
- Install records persist server-side per vehicle **plate**, including which skin, tablet prop, and position offset were used, so everything survives a restart

### 📺 Synced Radius Playback
- Music plays through `xsound`, synced to everyone within `Config.DefaultRadius` (adjustable per-install between `Config.MinRadius`/`Config.MaxRadius`) — not just the driver, and not just locally rendered per-client
- Accepts YouTube links directly, resolving video ID/title/thumbnail server-side via YouTube's oEmbed endpoint; other link types (e.g. SoundCloud) are passed through as-is
- A real xsound-readiness signal (not just `isPlaying`) gates seek/pause/resume calls, avoiding race conditions where a YouTube IFrame player hasn't actually finished initializing yet

### 🔇 Door/Window Muffling
- With every door in `Config.MuffleDoorIndexes` (default all four) closed, playback is scaled down by `Config.MuffledVolumeFactor` (default 0.35) for anyone listening from **outside** the vehicle — occupants always hear it at full volume
- Automatically restores full volume for outside listeners the instant a door opens, and auto-closes doors left open after someone exits (`Config.DoorAutoCloseDelayMs`) so the seal check doesn't get stuck open

### 📋 Personal Playlists
- Each player can save up to `Config.MaxPlaylists` playlists (default 100) with up to `Config.MaxSongsPerPlaylist` songs each (default 1500), persisted server-side per `citizenid` — every occupant loads their own playlists independently of who owns the vehicle

### 💃 In-Car Dancing
- `Config.EnableCarDance` lets seated passengers (front passenger and both rear seats, configurable via `Config.DanceSeats`) play a synced dance animation while music is playing

### 🖥️ Positionable Tablet Prop
- Choose from 4 tablet prop models (`Config.TabletPropOptions`), attached to the dash bone with an adjustable offset/rotation, plus an in-game positioning tool (`Config.PositionRange`) to fine-tune placement per install
- An optional in-world 3D UI (`Config.WorldUI`) can render the now-playing info directly above the unit up to `Config.WorldUI.MaxDrawDistance`

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |
| xsound | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-carplay/
```

### 2️⃣ Register Items

Add all 16 items from `install/items.txt` (10 color units, 5 artwork wraps, 1 removal tool) to your `qb-core/shared/items.lua`.

### 3️⃣ Database Setup

The script **automatically creates** `mnc_carplay_playlists` and `mnc_carplay_installs` on first start, including automatic column migrations for existing installs.

### 4️⃣ Add to Server Config

```lua
# server.cfg
ensure xsound
ensure oxmysql
ensure ox_lib
ensure mnc-carplay
```

### 5️⃣ Configure Settings

Edit `config.lua` to adjust playback radius, muffling behavior, allowed vehicle classes, and tablet prop positioning.

---

## ⚙️ Configuration Guide

```lua
Config = {}

Config.Debug = false

Config.SoundLabel          = "mnc_carplay"
Config.DefaultVolume       = 0.3
Config.DefaultRadius       = 15.0
Config.MinRadius           = 5.0
Config.MaxRadius           = 50.0
Config.YoutubeLoadGraceMs  = 3000
Config.RangeCheckInterval  = 500
Config.RangeHysteresis     = 5.0

Config.MuffledVolumeFactor  = 0.35
Config.MuffleDoorIndexes    = { 0, 1, 2, 3 }
Config.MuffleWindowIndexes  = {} -- see config.lua comments on why this is intentionally empty
Config.MuffleCheckInterval  = 250
Config.DoorAutoCloseDelayMs = 800

Config.MaxPlaylists        = 100
Config.MaxSongsPerPlaylist = 1500

Config.InteractDistance = 3.0
Config.InstallTime = 4000
Config.RemoveTime  = 4000
Config.RemovalTool = "carplay_tool"
Config.AllowedVehicleClasses = nil -- nil = any vehicle class

Config.EnableCarplayCommand = true
Config.CarplayCommand = "carplay"

Config.EnableCarDance = true
Config.DanceSeats = {
    [0]  = "ps",  -- front passenger
    [1]  = "rds", -- rear, driver side
    [2]  = "rps", -- rear, passenger side
}

Config.TabletPropOptions = {
    { id = "impexp", model = "imp_prop_impexp_tablet", label = "ImpExp Tablet" },
    -- 3 more options...
}
Config.DefaultTabletProp = "impexp"
Config.TabletPropBone     = "dash"
Config.TabletPropOffset   = vector3(0.13, 0.35, 0.42)
Config.TabletPropRotation = vector3(0.0, -90.0, -20.0)

Config.WorldUI = { Enabled = true, MaxDrawDistance = 12.0 }
```

- `Config.MuffleWindowIndexes` is intentionally left empty by default — `IsVehicleWindowIntact()` isn't a reliable "window rolled down" check (it only detects broken/missing glass, and at least one vehicle model reports a window as "not intact" from spawn with nothing broken), so only add window indexes here if you've personally verified the behavior on the vehicles you care about
- `Config.AllowedVehicleClasses` — set to a table of GTA vehicle class IDs to restrict installs to specific vehicle types; leave `nil` to allow any vehicle

---

## 🎮 Controls & Usage

| Command / Item | Description |
|---|---|
| Use a Carplay skin item near a vehicle | Installs that skin's unit onto the dash |
| Use the **Carplay Removal Tool** near an installed unit | Uninstalls it and returns the original skin item |
| `/carplay` (if `Config.EnableCarplayCommand`) | Opens the tablet UI for the vehicle's installed unit |

**Playing music:**
1. Install a unit, then open it with `/carplay` or by interacting with the dash prop
2. Paste a YouTube (or supported) link, or pick a saved playlist
3. Playback syncs to everyone within the configured radius — closing the doors muffles it for anyone outside

---

## 🔧 Troubleshooting

**Unit won't install:**
- Check `Config.AllowedVehicleClasses` — if set, only listed classes accept an install
- Confirm you're within `Config.InteractDistance` of the vehicle

**Audio only plays for the driver, not passengers or nearby players:**
- Confirm `xsound` is running and started before `mnc-carplay` — playback is synced through it, not played locally per-client

**Muffling never kicks in outside the car:**
- All doors listed in `Config.MuffleDoorIndexes` must be closed simultaneously — check that none are stuck open, and note that window state is deliberately not checked (see Configuration Guide)

**Seek/pause causes desync or errors right after a track starts:**
- This is the exact race condition `Config.YoutubeLoadGraceMs` exists to avoid — the readiness check waits for xsound's real "ready" signal, not just `isPlaying`; raise this value if it still happens on a slow connection

**Playlists don't carry over between vehicles:**
- This is expected — playlists are saved per-`citizenid`, not per-vehicle, so they follow the player, not the installed unit

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

1. **Item registration**: All 16 items in `install/items.txt` must be added to your shared items before installs will work
2. **Database**: Requires oxmysql — two tables are created and auto-migrated on first start
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS; music playback via third-party links is the responsibility of the server operator

---

**Install it, style it, play it loud. 📱**
