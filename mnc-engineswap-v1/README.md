# 🔧 MnC Engine Swap

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.9.3-brightgreen.svg)]()

> ⚠️ **Multiple versions of this script exist in this dump — install only ONE.** `mnc-engineswap-v1` is one of several builds of this tool alongside `mnc-engineswap-v2`. Running more than one at the same time will register the same commands/exports twice and can corrupt shared data. Both create the same vehicle_engines table and register identical shop markers/blips at the same coordinates - running both doubles every shop interaction. See "Choosing a Version" below.

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

MnC Engine Swap adds job-restricted engine shops where players browse a huge NUI catalog of engine sounds, pay for one from their bank account, wait for a crate delivery, and physically install it on a nearby vehicle through a multi-stage progress sequence (with an optional skill-check minigame). The purchased engine sound is saved per vehicle plate and automatically re-applied whenever the player gets back in.

---

## 🔀 Choosing a Version

This dump contains two builds of the engine swap system. **Install only one.**

| | `mnc-engineswap-v1` (this one) | `mnc-engineswap-v2` |
|---|---|---|
| Player shop, purchase, delivery, install flow | ✅ | ✅ |
| Per-plate saved engine sound | ✅ | ✅ |
| Admin free instant engine-swap menu (`/engineswap`) | ❌ | ✅ |
| Per-vehicle-model default sound overrides (`/vehsoundmeta`) | ❌ | ✅ |
| Broadcasts the new sound to nearby bystanders | ❌ | ✅ |
| Version | 1.9.3 | 1.9.4 |

Both versions use identical `Config.EngineShops` coordinates and both auto-create a `vehicle_engines` table, so running them side by side means two resources fighting over the same shop markers and the same database rows. Pick v1 if you only want the base purchase/install loop; pick **v2** for the same system plus the admin tooling and model-default sounds. There is no reason to run both.

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

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.9.3
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

