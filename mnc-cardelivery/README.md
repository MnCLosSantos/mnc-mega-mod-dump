# 🚚 MNC Car Delivery

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.1.0-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
A complete vehicle delivery job for QBCore: players find a randomly-modded car parked at a pickup location, claim the keys, and drive it to a drop-off point within a time limit while keeping damage under control. Payout scales with how clean and how fast the delivery was. Every vehicle spawn, key claim, and completion is network-synced through server-owned network IDs, and admins get an in-game **route builder** with a free-fly placement camera to add or edit delivery routes without ever touching `config.lua` or restarting the resource.

---

## ✨ Key Features

### 📦 Distance-Based Vehicle Streaming
- Each configured location spawns its delivery vehicle only once a player comes within `Config.Streaming.SpawnDistance` (default 120m), and despawns it again once everyone has left `Config.Streaming.DespawnDistance` (default 200m) — but only if nobody has claimed it yet
- Vehicles are tracked server-side by network ID so claims and state are consistent across every client

### 🔑 Proximity Key Claim
- Walking within `Config.PromptDistance` of an unclaimed delivery vehicle plays a spoken audio prompt; when it finishes, the server hands you the keys through a `QBCore.Functions.TriggerCallback` race-safe claim (first player to reach the callback wins — nobody else can also claim the same car)
- Getting in the driver's seat of a car you hold the keys to automatically starts the delivery job

### 🎨 Randomized Modifications on Spawn
- Every spawned vehicle gets a random cosmetic pass (`Config.Mods.CosmeticModTypes`, weighted by `Config.Mods.CosmeticChance`) plus maxed-out performance mods on `Config.Mods.PerformanceModTypes` (Engine/Brakes/Transmission) and always-on turbo
- Optional random paint color and a randomized plate with a configurable prefix (`Config.Mods.PlatePrefix`, default `MNC`)

### 🛡️ Damage Cap, Not a Damage Race
- While a delivery is active, body/engine/tank health is polled every `Config.DamageCheckInterval` (150ms) and clamped so the vehicle can never take more than `Config.MaxDamagePercent` (default 20%) total damage — crashing hard doesn't total the car, it just costs payout
- A capped, cooldown-limited crash sound (`Config.DamageSoundCooldown`) plays on real hits without spamming on multi-tick collisions

### ⏱️ Timed Delivery with Dynamic Payout
- Each route has its own time limit (`time` in seconds) and delivery radius; a live HUD counts down remaining time and vehicle condition
- Payout is computed from `Config.Payout.BasePercent` (8% of vehicle value at zero damage/instant delivery) scaled down by both damage (`DamagePenaltyWeight`) and time used (`TimeBonusWeight`), clamped between `MinPercent` and `MaxPercent` of the vehicle's value (falling back to `Config.Payout.DefaultVehicleValue` if the model isn't in `QBCore.Shared.Vehicles`)
- Dropping off requires parking inside the delivery radius, removing the keys, and **locking the vehicle** — payout is only issued once the doors are actually locked

### 🗺️ Admin Route Builder
- `/setupcardelivery` (ACE permission `admin` by default) opens an NUI panel listing every saved route, backed by SQL
- **Placement mode**: fly a free camera to set the pickup spawn point (position + heading) and the drop-off point visually, using a preview vehicle model (`Config.Admin.Placement.PreviewVehicle`) so you can see exactly where the car will land
- **`RETURN`** drops/confirms a point, **`R`** picks the preview vehicle back up to reposition it, **`BACK`** cancels placement
- The builder can auto-calculate a fair time limit by driving the route once — it takes the raw drive time, adds `Config.Admin.RouteTimer.BufferPercent` margin, floors it at `MinTime`, and rounds to the nearest `RoundTo` seconds
- Routes, their vehicle pools, and enabled/disabled state are all saved to and loaded from the database — no resource restart needed to go live

### 🔊 Full Audio Feedback
- Numbered prompt/damage/success/fail stings (`prompt1..19.mp3`, etc.) plus a dedicated `dropoff.mp3`, all played through the NUI and randomly rotated via `Config.Sounds.*Count` so the same line doesn't play every time

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| qb-vehiclekeys | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-cardelivery/
```

### 2️⃣ Database Setup

The script manages its own delivery-route table automatically on first start — no manual SQL import needed. Routes created through `/setupcardelivery` are written straight to the database.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure oxmysql
ensure qb-vehiclekeys
ensure mnc-cardelivery
```

### 4️⃣ Configure Settings

Edit `config.lua` to set payout math, damage caps, streaming distances, and your `qb-vehiclekeys` / `qbx` key system, or just use `/setupcardelivery` in-game to place your first routes.

---

## ⚙️ Configuration Guide

```lua
Config = {}
Config.VehicleKeysSystem = 'legacy'  -- 'legacy' (qb-vehiclekeys export) or 'qbx'
Config.PayoutAccount = 'bank'        -- 'cash' | 'bank'

Config.Admin = {
    Command = 'setupcardelivery',
    AcePermission = 'admin',
    RouteTimer = { BufferPercent = 15, MinTime = 45, RoundTo = 10 },
    Placement = { PreviewVehicle = 'sultan', MoveSpeed = 15.0, FastMultiplier = 4.0, RotateSpeed = 90.0, LookSensitivity = 4.0, CamFov = 60.0 },
}

Config.Streaming = { CheckInterval = 3000, SpawnDistance = 120.0, DespawnDistance = 200.0 }
Config.PromptDistance = 3.0

Config.MaxDamagePercent = 20
Config.DamageCheckInterval = 150
Config.DamageSoundCooldown = 3000

Config.Mods = {
    PerformanceModTypes = { 11, 12, 13 },
    AlwaysTurbo = true,
    CosmeticModTypes = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14, 16, 22, 23, 24, 25, 27, 28, 30, 33, 34, 38, 39, 40, 41, 42, 44, 45, 46, 48, 49, 51, 52, 53, 54, 55, 56, 57, 59, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72 },
    CosmeticChance = 0.6,
    RandomizeColor = true,
    RandomizePlate = true,
    PlatePrefix = 'MNC',
}

Config.Payout = {
    BasePercent = 0.08, MinPercent = 0.02, MaxPercent = 0.15,
    DamagePenaltyWeight = 0.6, TimeBonusWeight = 0.4,
    DefaultVehicleValue = 15000,
}

Config.Locations = {
    {
        spawn    = vector4(-31.56, -1089.53, 25.84, 319.92),
        delivery = vector3(-129.89, -2669.04, 5.42),
        radius   = 8.0,
        time     = 300,
        vehicles = { 'sultan', 'kuruma', 'elegy2' },
    },
    -- add more routes here, or use /setupcardelivery in-game instead
}
```

- `Config.Locations` seeds the initial route list, but the admin route builder is the intended way to add or edit routes afterward — anything saved through `/setupcardelivery` persists in the database and survives restarts
- `Config.Payout.DamagePenaltyWeight` / `TimeBonusWeight` control how strongly damage vs. speed each affect the final payout — raise one to make that factor matter more

---

## 🎮 Controls & Usage

| Command / Key | Context | Description |
|---|---|---|
| `/setupcardelivery` | Admin (ACE `admin`) | Opens the route builder UI |
| `RETURN` | Placement mode | Drop / confirm the current point |
| `R` | Placement mode | Pick the preview vehicle back up to reposition |
| `BACK` | Placement mode, or during a test drive | Cancel placement, or cancel a test drive run |

**Playing the job as a normal player:**
1. Head to a pickup blip and approach the parked vehicle
2. Wait for the audio prompt to finish — the server assigns you the keys the instant it completes
3. Get in and drive; a HUD tracks your remaining time and vehicle condition
4. Reach the drop-off blip within the delivery radius, remove the keys, and lock the vehicle to receive payout

---

## 🔧 Troubleshooting

**Vehicle never spawns at a pickup location:**
- Confirm you're within `Config.Streaming.SpawnDistance` of the route's `spawn` point and that the route isn't marked disabled in the route builder

**Prompt plays but I never get keys:**
- Someone else likely claimed the vehicle first — claims are handled with a server-side race-safe callback, so only one player can win a given vehicle

**Payout seems too low/high:**
- Check `Config.Payout.BasePercent`/`MinPercent`/`MaxPercent` and the two weight values; also confirm the delivered model exists in `QBCore.Shared.Vehicles` — unknown models fall back to `Config.Payout.DefaultVehicleValue`

**Damage cap doesn't seem to apply:**
- The cap clamps body/engine/tank health every `Config.DamageCheckInterval` ms during an *active* delivery only — damage taken before claiming keys or after drop-off isn't managed by this script

**Route builder placement camera feels too fast/slow:**
- Tune `Config.Admin.Placement.MoveSpeed`, `FastMultiplier`, and `LookSensitivity`

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.1.0
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

1. **Database**: Requires oxmysql — routes saved through the admin builder persist automatically
2. **Compatibility**: QBCore only — not compatible with ESX
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Pick it up, drive it clean, drop it off. 🚚**
