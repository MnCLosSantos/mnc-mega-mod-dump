# 🔧 MnC Engine Swap

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.9.3-brightgreen.svg)]()

---

## 🌟 Overview

MnC Engine Swap adds job-restricted engine shops where players browse a huge NUI catalog of engine sounds, pay for one from their bank account, wait for a crate delivery, and physically install it on a nearby vehicle through a multi-stage progress sequence (with an optional skill-check minigame). The purchased engine sound is saved per vehicle plate and automatically re-applied whenever the player gets back in.

---

## ✨ Key Features

**Shops & Catalog**
- `Config.EngineShops` defines shop title, location, delivery point, install point, accent theme, job restriction list, and map blip per shop
- Large built-in NUI engine catalog grouped into categories (Supercars, Sports Cars, Muscle Cars, Lowriders, Sports Classics, Motorcycles, Sedans, Offroad, Commercial, Formula) — over a hundred engine sounds, each with a name, sound hash, price, image, and description

**Purchase & Delivery**
- Server validates the submitted price against `Config.EngineSounds` before charging (anti-tamper)
- Money removed from the player's **bank** via `Player.Functions.RemoveMoney`
- `Config.EngineDeliveryTime` delay before an engine crate + pallet prop spawn at the shop's delivery point
- Player picks up the crate with `[E]` and carries it to their vehicle
- Automatic refund event (`mnc-engineswap:refundPayment`) if installation fails

**Installation**
- Vehicle is tracked by license plate as the player approaches it with the crate
- Three-stage `lib.progressBar` / `lib.progressCircle` sequence (remove stock engine → install conversion kit → install new engine), style controlled by `Config.Installation.progressType`
- Optional `lib.skillCheck` minigame gate (`Config.Installation.requireMinigame`, easy/medium difficulty)
- `Config.RequiredItem` (default `toolbox`) can require an item to perform the install

**Persistence**
- Auto-creates a `vehicle_engines` table (`plate`, `engine_sound`) on first start
- Saved sound is fetched and re-applied automatically whenever the player enters that vehicle

---

## 📋 Requirements

| Dependency | Required |
|---|---|
| qb-core | ✅ Yes |
| ox_lib | ✅ Yes |
| oxmysql | ✅ Yes |

---

## 🚀 Installation

```bash
# Place into your resources folder
[server-data]/resources/[custom]/mnc-engineswap-v1/
```

```lua
# server.cfg
ensure mnc-engineswap-v1
```

No SQL import is needed — the script automatically runs `CREATE TABLE IF NOT EXISTS vehicle_engines` on first start.

---

## ⚙️ Configuration Guide

```lua
Config.EngineShops = {
     {
         title = "LSC Salvage",
         location = vector3(-340.53, -141.85, 38.93),
         theme = "purple",
         delivery = vector3(-358.95, -128.34, 38.71),
         install = vector3(-329.75, -143.7, 39.06),
         jobs = {'mechanic', 'mechanic2', 'mechanic3'},
         blip = {sprite = 446, color = 27, scale = 0.8, name = "LSC Salvage"}
     },
}

Config.EnginePrice = 2500
Config.EngineDeliveryTime = 5000
Config.RequiredItem = 'toolbox'
```

Each shop entry controls where the counter, delivery point, and install marker are, which jobs may use it, and its blip. `Config.EngineSounds` (a much larger table) defines every purchasable engine's name, sound hash, price, and category.

---

## 🎮 Controls & Usage

- Walk up to a shop marker and press **[E]** to open the engine catalog
- After ordering, press **[E]** at the delivery point to pick up the crate
- Carry the crate to the vehicle and press **[E]** near it to begin installation

---

## 🔧 Troubleshooting

- **Shop won't open** — confirm your job matches one of the shop's `jobs` entries and that `ox_lib` has fully started.
- **Payment fails** — the price is validated server-side against `Config.EngineSounds`; make sure the config wasn't edited on only one side (client/server must load the same `config.lua`).
- **Engine sound doesn't stick after relogging** — check that `oxmysql` is connected and the `vehicle_engines` table was created (see server console on startup).
- **No delivery prop appears** — `Config.EngineDeliveryTime` may be too long for testing; lower it temporarily to confirm the flow works.

---

## 📝 Credits & License

**Author**: Stan Leigh
**Version**: 1.9.3
**Framework**: QBCore

Distributed as part of the MnCLosSantos mod-dump collection — open source, please credit the original author if you edit and re-release.
