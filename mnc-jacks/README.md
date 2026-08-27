# 🔩 MNC Jacks

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.1.4-brightgreen.svg)]()

---

## 🌟 Overview

A realistic per-side car jack and axle stand system: use a floor jack to raise one side of a vehicle, then slot two axle stands underneath to hold it there safely, freezing the vehicle in place at the raised height for as long as the stands stay in. Pulls the stands back out (or the jack back off) to lower it again.

---

## ✨ Key Features

### 🚗 Per-Side Lifting
- Approach either side of a vehicle and use the **Car Jack** item to raise that side by `Config.Lift.RaiseHeight` (default 0.17m) over a timed animation (`Config.Lift.JackDuration`, default 5s)
- Left and right sides are lifted independently — jack rotation is separately configured per side (`Config.Lift.JackRotation`) so the prop always faces the right way

### 🔧 Axle Stands for Safe Holding
- Once a side is jacked up, place `Config.Lift.StandsPerSide` (default 2) **Axle Stand** items at the configured front/rear offsets for that side to hold the vehicle up without the jack
- The vehicle freezes at the raised height with a keep-alive loop so it doesn't sink or glitch back down over time
- Removing the stands (or the jack, if stands were never placed) lowers that side back down through a timed animation (`Config.Lift.StandDuration`, default 3s)

### 🎯 Simple Proximity Interaction
- No target system required — walk within `PROMPT_RADIUS`/`Config.InteractDistance` (2.5m) of a vehicle side and press **E** to start jacking or stand placement, **Backspace** to cancel mid-action

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-jacks/
```

### 2️⃣ Register Items

Add `car_jack` and `axle_stand` (or your renamed equivalents matching `Config.CarJackItem`/`Config.AxleStandItem`) to your `qb-core/shared/items.lua`.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure mnc-jacks
```

### 4️⃣ Configure Settings

Edit `config.lua` to adjust raise height, timings, and stand offsets if your vehicle prop alignment needs tuning.

---

## ⚙️ Configuration Guide

```lua
Config = {}

Config.Debug = false

Config.CarJackItem   = 'car_jack'
Config.AxleStandItem = 'axle_stand'
Config.InteractDistance = 2.5

Config.Lift = {
    StandsPerSide = 2,
    JackPropModel  = 'prop_carjack',
    StandPropModel = 'xs_prop_x18_axel_stand_01a',
    JackRotation = { left = -270.0, right = 270.0 },
    JackDuration  = 5000,
    StandDuration = 3000,
    RaiseHeight = 0.17,
    StandOffsets = {
        left  = { [1] = { x = -0.65, y =  1.10, z = -0.30, heading = 0.0 },
                  [2] = { x = -0.65, y = -1.10, z = -0.30, heading = 0.0 } },
        right = { [1] = { x =  0.65, y =  1.10, z = -0.30, heading = 0.0 },
                  [2] = { x =  0.65, y = -1.10, z = -0.30, heading = 0.0 } },
    },
}
```

- `RaiseHeight` — how far off the ground the jacked side sits; raise it for larger vehicles that need more wheel clearance
- `StandOffsets` — fine-tune per-side, per-position (front/rear) placement to match different vehicle wheelbases

---

## 🎮 Controls & Usage

| Input | Description |
|---|---|
| Use **Car Jack** item near a vehicle side | Raises that side of the vehicle |
| **E** at the jacked side | Interact to place or remove an axle stand |
| **Backspace** | Cancels an in-progress jack or stand action |
| Remove both axle stands (or the jack, if no stands placed) | Lowers that side back to the ground |

**Lifting a side:** stand next to the vehicle's left or right side, use the Car Jack item, wait out the timed animation, then place both axle stands underneath before doing any work that needs the vehicle held steady.

---

## 🔧 Troubleshooting

**Vehicle sinks back down or glitches after being jacked:**
- Confirm both axle stands were actually placed — the freeze keep-alive holds the vehicle at height only while stands are in; a jack alone without stands is not meant to hold indefinitely

**Jack prop faces the wrong direction:**
- Adjust `Config.Lift.JackRotation.left`/`right` to match your server's vehicle orientation conventions

**Stand doesn't line up with the wheel:**
- Tune `Config.Lift.StandOffsets` for that side/position — offsets are relative to the vehicle's own local space, not world space

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.1.4
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

1. **Item registration**: both the car jack and axle stand items must exist in your shared items before this works
2. **Session-based**: lift state is tracked client-side per session, not persisted to the database across restarts
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Get it up, prop it up, get to work. 🔩**
