# 🚗 MNC Vehicle Differential System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A **realistic vehicle differential system** for QBCore-based FiveM servers. Install **Welded** or **Limited-Slip Differential (LSD)** upgrades that permanently modify rear-wheel traction in real-time using only safe handling floats (`fTractionCurveMin` + `fTractionLossMult`). No wheel mesh glitches, no fTractionBiasFront changes — just pure, performant, RPM-scaled physics that feel exactly like a locked spool or true LSD.

Built for car meets, drag nights, and street racing servers. Fully persistent, job-restricted, and admin-friendly.

---

## ✨ Key Features

### 🛠️ Differential Types
- **Welded Differential** — Full lock from ~90% RPM. Both rear wheels spin together aggressively.
- **Limited-Slip Differential (LSD)** — Hysteresis lock/unlock (1.95 → 1.85 RPM) for realistic street/track feel.

### ⚙️ Real-Time Physics Engine
- Linear RPM scaling of traction floor and loss multiplier
- Gear-based cutoff (suppresses diff effect at highway speeds)
- Stock handling restored instantly when exiting vehicle or diff expires
- 50ms physics thread — buttery smooth even on 200+ player servers

### 🎬 Immersive Installation
- Use item → walk to each rear wheel → press **E**
- Mechanic-style animations + progress bars + world markers
- Two-step rear-axle process (configurable time per wheel)

### 💾 Persistent & Synced
- MySQL-backed `vehicle_diffs` table (plate = primary key)
- Instant sync to all clients when installed/removed
- Tier system (Welded = 1, LSD = 2) — no downgrades allowed

### ⏳ Realistic Wear & Tear
- Exactly **3 hours of in-vehicle playtime** before differential wears out
- Automatic removal + notification when timer hits zero

### 👷 Job & Admin Controls
- Mechanic-only installation (configurable jobs + grade levels)
- Two admin commands: `/diffwelded [id]` and `/difflsd [id]`
- Full permission check via QBCore

### 🛡️ Safe & Optimized
- Only modifies two safe handling floats
- Automatic original handling cache & restore
- Zero impact on wheel visuals or other vehicles

---

## 📋 Requirements

| Dependency       | Version | Required |
|------------------|---------|----------|
| QBCore Framework | Latest  | ✅ Yes   |
| qb-core          | Latest  | ✅ Yes   |
| ox_lib           | Latest  | ✅ Yes   |
| oxmysql          | Latest  | ✅ Yes   |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-diffs/
```

### 2️⃣ Database Setup

The script **automatically creates** the `vehicle_diffs` table on first start. No manual SQL required.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-diffs
```

### 4️⃣ Add Items to QBCore

Add these to `qb-core/shared/items.lua`:

```lua
['welded_diff'] = {
    ['name'] = 'welded_diff',
    ['label'] = 'Welded Differential',
    ['weight'] = 2500,
    ['type'] = 'item',
    ['image'] = 'welded_diff.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Permanently locks rear wheels together'
},

['lsd_diff'] = {
    ['name'] = 'lsd_diff',
    ['label'] = 'Limited Slip Differential',
    ['weight'] = 2800,
    ['type'] = 'item',
    ['image'] = 'lsd_diff.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Street-legal performance differential'
},
```

### 5️⃣ Configure Settings

Edit `config.lua` to customize jobs, physics values, duration, etc. (full guide below).

---

## ⚙️ Configuration Guide

### 🔧 Job Restrictions
```lua
Config.RequireJob = true
Config.AllowedJobs = {
    mechanic    = 0,
    mechanic2   = 0,
    mechanic3   = 0,
    beekers     = 0,
    autoexotics = 0,
    bennys      = 2,
    tuner       = 1,
}
```

### 📊 Differential Physics (per type)
```lua
Config.Diffs = {
    welded_diff = {
        SpinRpm        = 0.90,   -- when traction starts dropping
        TractionMin    = 0.45,   -- fTractionCurveMin floor
        SpinLossMult   = 2.5,    -- fTractionLossMult ceiling
        GearSpinCutoff = 4,      -- disable above this gear
    },
    lsd_diff = {
        LsdLockRpm     = 1.95,
        LsdUnlockRpm   = 1.85,
        SpinRpm        = 1.95,
        TractionMin    = 0.20,
        SpinLossMult   = 4.0,
        GearSpinCutoff = 3,
    }
}
```

### ⏱️ Duration & Tiers
```lua
Config.DiffDurationMs = 3 * 60 * 60 * 1000   -- 3 hours in-vehicle time
Config.DiffTier = {
    welded_diff = 1,
    lsd_diff    = 2,
}
```

---

## 🎮 How It Works

### Welded Differential
- Always active above SpinRpm
- Both rear wheels lose grip together → perfect drag launches and burnouts

### LSD Differential
- Hysteresis lock (locks at 1.95 RPM, unlocks at 1.85 RPM)
- Smoother street driving with on-demand lock for corners

### Physics Scaling
```lua
-- Linear interpolation from stock values → target values as RPM rises
local t = (rpm - SpinRpm) / (1.0 - SpinRpm)
curveMin = stockMin + t * (TractionMin - stockMin)
lossMult = stockLoss + t * (SpinLossMult - stockLoss)
```

### Gear Cutoff
High gears (highway) automatically restore stock handling so the car drives normally at speed.

---

## 🎮 Controls & Usage

### Player Controls
| Action                  | How                              |
|-------------------------|----------------------------------|
| Install Differential    | Use item → approach rear wheels → press **E** |
| Cancel Installation     | Press **X** during progress bar  |

### Admin Commands
- `/diffwelded [playerID]` — instantly installs welded diff
- `/difflsd [playerID]`    — instantly installs LSD diff

---

## 🧪 System Mechanics

### Installation Flow
1. Player uses item (`welded_diff` or `lsd_diff`)
2. Client checks nearby vehicle + job
3. Two-step rear-wheel mini-game with animations
4. Server validates item, tier, job, then saves to DB
5. All clients receive sync event

### Duration & Wear
- Timer starts only while **inside** the vehicle
- After 3 hours → automatic removal + notification
- Diff stays on the plate until worn out or manually removed

### Tier Protection
LSD (tier 2) overwrites Welded (tier 1). You cannot install a lower tier.

### Performance
- Only one 50ms thread per client
- Handling cache per vehicle (restored on exit)
- Zero network traffic except on install/remove/sync

---

## 🔧 Troubleshooting

### Common Issues

**Diff not applying?**
- Check server console for job/item checks
- Ensure plate is clean (no spaces)
- Verify item exists in `qb-core/shared/items.lua`

**Handling not changing?**
- Enable `Config.Debug = true`
- Check console for cached stock values
- Make sure you're the driver

**Vehicle disappears or wheels vanish?**
- This script never touches `fTractionBiasFront` — impossible to cause that issue

**Duration not counting?**
- Timer only runs while you are **inside** the vehicle as driver

**Admin commands not working?**
- Must have `admin` permission in QBCore
- Target player must be in a vehicle

**Database not saving?**
- oxmysql must be started before mnc-diffs

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

## 🔄 Changelog

### Version 1.0.0 (Initial Release)
**New Features:**
- ✨ Full welded & LSD differential system
- ✨ Real-time RPM-scaled handling physics
- ✨ LSD hysteresis lock/unlock
- ✨ Gear-based cutoff system
- ✨ Animated two-wheel installation
- ✨ 3-hour wear-out timer
- ✨ Persistent MySQL storage
- ✨ Tier system + no-downgrade protection
- ✨ Mechanic job restrictions
- ✨ Admin install commands
- ✨ Full client-server sync
- ✨ Debug mode & safe handling only

**Improvements:**
- 🔧 Zero visual glitches (no wheel mesh issues)
- 🔧 Optimized 50ms physics thread
- 🔧 Automatic handling cache & restore

**Bug Fixes:**
- None — clean first release

---

## ⚠️ Important Notes

1. **Performance**: Tested stable on 200+ player servers
2. **Compatibility**: Only modifies two safe floats — works with any handling mod
3. **Legal**: For FiveM roleplay servers only
4. **Support**: Community-driven

**Ready to make every car meet legendary?** 🔥
