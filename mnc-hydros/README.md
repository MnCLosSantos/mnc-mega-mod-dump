# 🎚️ MNC Vehicle Hydro Handbrakes System (Street & Competition)

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
A **hydraulic handbrake system** for QBCore-based FiveM servers. Mechanics install **Street** or **Competition** hydraulic kits that raise a vehicle's `fHandBrakeForce` handling value, giving a much snappier, harder-locking rear handbrake — perfect for e-brake drift entries and hydraulic-style stunts. Kits are tiered, job-restricted, fully persistent by license plate, and wear out after a set amount of in-vehicle playtime, just like the rest of the MNC handling-mod line-up (`mnc-diffs`, `mnc-drivelines`, `mnc-anglekit`).

---

## ✨ Key Features

### 🎛️ Hydraulic Kit Types
- **Street Hydraulics** — raises `fHandBrakeForce` to `3.5`
- **Competition Hydraulics** — raises `fHandBrakeForce` to `7.0` for an aggressive, near-instant rear lockup
- **Tier system** — Competition (tier 2) overwrites Street (tier 1); you cannot install a lower tier over a higher one

### 🔧 Installation
- **Item-based install** — use the kit item while on foot near the target vehicle (within `Config.ApplyDistance`, 2.5m)
- **Per-kit install time** — Street takes 5 seconds, Competition takes 7 seconds, both with a mechanic-style ox_lib progress bar
- **Job-restricted** — mechanic-family jobs by default (`mechanic`, `mechanic2`, `mechanic3`, `beekers`, `autoexotics`, `bennys`, `tuner`), each with its own minimum grade
- **Removal toolbox** — a separate `hydro_toolbox` item strips the installed kit from a vehicle and returns it to the mechanic's inventory

### ⏳ Realistic Wear & Tear
- Exactly **3 hours of in-vehicle playtime** (`Config.HydroDurationMs`) before the hydraulic kit wears out
- Timer only counts down while the player is actually inside the vehicle
- Automatic removal and notification once the timer reaches zero

### 💾 Persistence & Sync
- Database-backed storage in `vehicle_hydros`, keyed by license plate
- Server-side in-memory cache loaded on startup for instant lookups
- Client-side plate cache to avoid redundant server callbacks
- Handling value is re-applied automatically every time the vehicle is entered, and restored to stock the moment the kit expires or is removed

### 👷 Job & Admin Controls
- `Config.RequireJob` toggle to open installs to everyone
- Two admin commands to force-apply either tier to a target player's current vehicle: `/hydrostreet [id]` and `/hydrocomp [id]`
- Full permission check via QBCore's admin ACE group

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
[server-data]/resources/[custom]/mnc-hydros/
```

### 2️⃣ Database Setup

The script **automatically creates** the `vehicle_hydros` table on first start. No manual SQL import needed.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-hydros
```

### 4️⃣ Add Items to QBCore

Add these to `qb-core/shared/items.lua`:

```lua
['street_hydro'] = {
    ['name'] = 'street_hydro',
    ['label'] = 'Street Hydraulics',
    ['weight'] = 2000,
    ['type'] = 'item',
    ['image'] = 'street_hydro.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Street-grade hydraulic handbrake kit'
},

['comp_hydro'] = {
    ['name'] = 'comp_hydro',
    ['label'] = 'Competition Hydraulics',
    ['weight'] = 3000,
    ['type'] = 'item',
    ['image'] = 'comp_hydro.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Competition-grade hydraulic handbrake kit'
},

['hydro_toolbox'] = {
    ['name'] = 'hydro_toolbox',
    ['label'] = 'Hydraulics Removal Toolbox',
    ['weight'] = 1500,
    ['type'] = 'item',
    ['image'] = 'hydro_toolbox.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Use near a vehicle to remove its installed hydraulic kit and return it to your inventory.'
},
```

### 5️⃣ Configure Settings

Edit `config.lua` to adjust jobs, handbrake force values, wear duration, and interaction distance.

---

## ⚙️ Configuration Guide

### 👷 Job Restrictions

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

### 🎛️ Hydro Kit Definitions

```lua
Config.Hydros = {
    street_hydro = {
        item           = 'street_hydro',
        label          = 'Street Hydraulics',
        type           = 'street',
        installTime    = 5000,
        HandbrakeForce = 3.5,   -- fHandBrakeForce applied while installed
    },

    comp_hydro = {
        item           = 'comp_hydro',
        label          = 'Competition Hydraulics',
        type           = 'comp',
        installTime    = 7000,
        HandbrakeForce = 7.0,   -- stronger, near-instant lockup
    },
}
```

| Kit | `fHandBrakeForce` | Install Time | Tier |
|-----|-------------------|--------------|------|
| Street Hydraulics | 3.5 | 5s | 1 |
| Competition Hydraulics | 7.0 | 7s | 2 |

### ⏱️ Duration & Distance

```lua
Config.HydroDurationMs = 3 * 60 * 60 * 1000   -- 3 hours in-vehicle playtime before wear-out
Config.ApplyDistance   = 2.5                   -- metres — proximity needed to install

Config.HydroTier = {
    street_hydro = 1,
    comp_hydro   = 2,
}
```

---

## 🎮 Controls & Usage

| Action | How |
|--------|-----|
| Install hydraulic kit | Use item while on foot within 2.5m of the vehicle |
| Remove hydraulic kit | Use `hydro_toolbox` near the vehicle |
| Cancel installation | Press **X** during the progress bar |

### Admin Commands

| Command | Kit Applied |
|---------|-------------|
| `/hydrostreet [id]` | Street Hydraulics (Tier 1) |
| `/hydrocomp [id]` | Competition Hydraulics (Tier 2) |

- Both require `admin` ACE permission in `server.cfg`
- `[id]` is the target's server ID — omit to apply to your own current vehicle
- The target player must be **inside a vehicle** when the command is run

---

## 🧪 System Mechanics

### Installation Flow
1. Player uses a kit item near the vehicle
2. Client checks job and proximity
3. Progress bar plays with mechanic animation
4. Server re-validates job, item, and tier, then consumes the item
5. `fHandBrakeForce` is set on the vehicle and the kit is saved to the database
6. All clients receive a sync event so the driver's handbrake updates immediately

### Wear & Removal
- The 3-hour timer only runs while the player is the vehicle's occupant
- On expiry, the kit is removed from the database and `fHandBrakeForce` is restored to stock
- The `hydro_toolbox` item removes a kit early and returns it to the mechanic's inventory

### Tier Protection
Competition (tier 2) overwrites Street (tier 1). A lower or equal tier cannot be installed over an existing kit.

---

## 🔧 Troubleshooting

**Kit not applying:**
- Confirm the item name in `items.lua` matches the `item` field in `Config.Hydros`
- Check the player is on foot within `Config.ApplyDistance` of the vehicle
- Enable `Config.Debug = true` and check the server console for job/item rejections

**Handbrake doesn't feel different:**
- Confirm you are the driver — the handling override only applies to the seated driver's local vehicle
- Some heavily modified addon vehicles may override `fHandBrakeForce` in their own handling meta

**Kit not persisting after restart:**
- Check the `vehicle_hydros` table was created in your database
- Verify `oxmysql` starts before `mnc-hydros` in `server.cfg`

**Admin command fails with "Target is not in a vehicle":**
- The target player must be seated inside a vehicle when the command is run

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

1. **Handling Scope**: `fHandBrakeForce` is applied client-side to the vehicle's live handling and is re-applied every time it is entered
2. **Database**: Requires oxmysql — MariaDB 10.3+ recommended
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Lock the rears and let it ride. 🎚️**
