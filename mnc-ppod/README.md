# 🎧 MNC Ppod

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A personal iPod-style music player, distinct from the vehicle-mounted [`mnc-carplay`](../mnc-carplay): 15 physical skins, a battery you have to actually manage and recharge, headphones required to hear it privately, and an optional placeable speaker prop for sharing music with everyone nearby instead.

---

## ✨ Key Features

### 🎨 15 Physical Skins
- 10 solid colors (Silver, Black, White, Red, Blue, Green, Yellow, Purple, Orange, Pink) plus 5 artwork skins (Racing Stripes, Carbon Fiber, Tactical Camo, Gunmetal Engraved, Green Haze)
- Each skin is its own item; using it renders the matching phone-prop colors and accent in-hand and in the NUI

### 🎧 Headphones Required (Configurable)
- `Config.RequireHeadphones = true` by default — you must have a pair of headphones equipped (worn as a `qb-clothing` hat-slot prop) to hear your own ppod, or be connected to a nearby speaker instead
- 8 headphone colors ship as separate items, each mapping to one of the 8 real texture variants the hat prop supports
- Wearing headphones and connecting to a speaker are mutually exclusive — connecting to a speaker requires removing headphones first, and vice versa

### 🔋 Battery & Charging
- The ppod has a real battery (`Config.BatteryMax`, default 100%) that drains while open (`Config.BatteryDrainAmount` per `Config.BatteryDrainInterval`, default 1% every 30s) and warns at `Config.BatteryLowWarning` (default 15%)
- A dedicated **Charger** item (`Config.ChargerItem`) fully recharges the battery over `Config.ChargeTime` (default 60s)

### 🔊 Placeable Speaker (Shared Listening)
- The **Speaker** item (`Config.SpeakerItem`) places a physical speaker prop that anyone nearby (`Config.SpeakerRadius`, default 15m) can hear without needing headphones of their own
- Placing and picking the speaker back up both run a timed progress animation (`Config.SpeakerPlaceTime`/`Config.SpeakerPickupTime`)

### 📋 Personal Playlists
- Save up to `Config.MaxPlaylists` playlists (default 100) with up to `Config.MaxSongsPerPlaylist` songs each (default 1500), persisted server-side per player
- YouTube-style links resolve automatically through `xsound`

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |
| xsound | Latest | ✅ Yes |
| qb-clothing | Latest | ⚠️ Required only if `Config.RequireHeadphones = true` (default) |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-ppod/
```

### 2️⃣ Register Items

Add the 15 ppod skins, 8 headphone colors, the charger item, and the speaker item to your `qb-core/shared/items.lua`.

### 3️⃣ Database Setup

The script **automatically creates** its playlist table on first start — no manual SQL import needed.

### 4️⃣ Add to Server Config

```lua
# server.cfg
ensure xsound
ensure oxmysql
ensure ox_lib
ensure mnc-ppod
```

### 5️⃣ Configure Settings

Edit `config.lua` to adjust battery drain/charge times, headphone requirement, speaker radius, and the default skin used by `/ppod`.

---

## ⚙️ Configuration Guide

```lua
Config = {}

Config.Debug = false
Config.SoundLabel = "mnc_ppod"
Config.DefaultVolume = 0.1
Config.DefaultRadius = 5.0

Config.MaxPlaylists = 100
Config.MaxSongsPerPlaylist = 1500

Config.DefaultiPodSkin = "silver"
Config.EnablePpodCommand = false   -- false = item-only access

Config.RequireHeadphones = true    -- turn false if not using qb-clothing
Config.HeadphoneHatProp = 15

Config.SpeakerItem = "ppod_speaker"
Config.SpeakerRadius = 15.0
Config.SpeakerPlaceTime = 1200
Config.SpeakerPickupTime = 1200

Config.BatteryEnabled = true
Config.BatteryMax = 100
Config.BatteryDrainAmount = 1
Config.BatteryDrainInterval = 30000
Config.BatteryLowWarning = 15

Config.ChargerItem = "ppod_charger"
Config.ChargeTime = 60000
Config.ChargeAmount = 100
```

- `Config.EnablePpodCommand = false` by default — the ppod only opens by using a skin item, not via `/ppod`; set to `true` and use `/ppod [skin]` if you want command-based access too
- `Config.BatteryEnabled = false` disables the battery system entirely if you'd rather it never runs out

---

## 🎮 Controls & Usage

| Input | Description |
|---|---|
| Use a ppod skin item | Opens the ppod (if `Config.EnablePpodCommand` is false, this is the only way in) |
| `/ppod [skin]` (if enabled) | Opens the ppod, optionally with a specific skin |
| Use a headphone item | Equips/removes that headphone color (hat slot) |
| Use the **Speaker** item near a valid surface | Places a shared speaker; use again to pick it back up |
| Use the **Charger** item | Starts a timed full recharge of your ppod's battery |

**Listening privately:** equip headphones, then use your ppod skin item and play something — only you can hear it. **Listening with others:** place a speaker instead and connect to it (removing headphones first) so everyone in range hears the same audio.

---

## 🔧 Troubleshooting

**"Plug in your headphones" message won't go away:**
- `Config.RequireHeadphones` is on — either equip a headphone item or connect to a nearby placed speaker instead

**Can't wear headphones:**
- You're currently connected to a speaker — disconnect first, the two are mutually exclusive

**Battery keeps dying fast:**
- Adjust `Config.BatteryDrainAmount`/`Config.BatteryDrainInterval`, or set `Config.BatteryEnabled = false` to remove the battery system

**Speaker doesn't play for nearby players:**
- Confirm they're within `Config.SpeakerRadius` and that `xsound` is running and started before `mnc-ppod`

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

1. **Item registration**: all skins, headphone colors, charger, and speaker items must be added to your shared items before this works
2. **Database**: Requires oxmysql — the playlist table is created automatically on first start
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Related resource**: [`mnc-carplay`](../mnc-carplay) is the vehicle-mounted equivalent of this tool — they are separate, complementary resources, not alternate versions of each other
5. **Legal**: For use on FiveM servers only, respect Rockstar's ToS; music playback via third-party links is the responsibility of the server operator

---

**Your music, your pocket, your rules. 🎧**
