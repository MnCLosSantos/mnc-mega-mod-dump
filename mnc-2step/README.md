# 🔥 MNC 2-Step / Launch Control System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A **fully-featured 2-step and launch control system** for QBCore-based FiveM servers. Mechanics can install tiered 2-step kits onto turbo-equipped vehicles, unlocking three distinct behaviours — rev-limiter bouncing on the spot, rolling anti-lag on the move, and a launch boost burst on key release. Flames spray from every exhaust bone, sounds play through a pooled NUI audio engine, and all kit data persists by license plate across sessions.

---

## ✨ Key Features

### 🚀 Three Active Modes
- **Rev-limiter bounce** — hold `RShift` while stationary above the RPM threshold; the engine bounces off the limiter, firing rapid flame bursts and pops at a configurable interval
- **Rolling 2-step** — hold `RShift` while moving above the speed threshold; continuous anti-lag bangs keep boost up mid-roll
- **Launch burst** — release `RShift` while rolling; a large final burst fires and an engine torque multiplier kicks in for a configurable duration, simulating the launch pull

### 🔧 Tiered Kit System
- **Three kit tiers** out of the box: Basic (Tier 1), Street (Tier 2), and Pro (Tier 3)
- **Upgrade-only install** — a kit can only replace an equal or lower tier; you cannot downgrade
- **Per-kit overrides** for burst interval, flame count, particle scale, volume, sound file, boost multiplier, boost duration, and final burst size
- **Global fallback defaults** — any field not set in a kit's config automatically falls back to `Config.Limiter`, `Config.Rolling`, or `Config.Boost`

### 💥 Particle & Sound Effects
- **`veh_backfire` particle effect** fired on every exhaust bone the vehicle has (`exhaust`, `exhaust_1`–`exhaust_9`, `exhaust_f`, `roll_exhaust`)
- **Looped handle trick** — starts a looped particle then stops it after 50 ms for a clean single burst per pop, correctly bone-positioned and rotated
- **Staggered multi-pop** — each flame in a burst fires 35 ms apart, giving a natural rapid-fire effect
- **Pooled NUI audio engine** — 16 Audio instances per sound file allow overlapping pops without clipping or delay
- **Per-delay, per-volume scheduling** — each pop in a burst can have its own timing offset and volume via the `mnc_2step_pop` NUI message
- **Custom `.ogg` support** — drop any sound file into `html/sounds/` and reference it per-kit or as the global default

### 🌐 Networked Flames
- **`mnc-2step:broadcastFlames`** server event relays flame effects to all nearby clients
- **Driver exemption** — the driver's own client skips the broadcast replay to avoid double-spawning particles

### 🔒 Installation Requirements
- **Turbo required** — vehicles must have GTA V's base turbo mod installed (mod index 18) before any 2-step kit can be fitted
- **Player must be on foot**, standing within **1 metre of the vehicle's front** (headlight area) to install
- **Hood opens** during installation and closes on completion or cancellation
- **Single progress bar** with mechanic crouch animation for the full install duration
- **Cancellable** — pressing cancel cleanly aborts with no item consumed

### 💾 Persistence & Sync
- **Database-backed storage** — kit, tier, installer name, and timestamps saved to `vehicle_2step` by license plate
- **Server-side in-memory cache** pre-loaded from database on startup for instant lookups
- **Client-side plate cache** avoids redundant server callbacks for already-known vehicles
- **`mnc-2step:syncData` broadcast** to all clients after install — the driver's kit activates immediately without rejoining

### 🔒 Security & Validation
- **Server-side job check** re-validates mechanic job and grade on every install attempt
- **Server-side item check** — kit item consumed only after all validations pass
- **Server-side tier check** — prevents downgrading via duplicate install attempts
- **Plate length validation** — rejects malformed or oversized plate strings
- **Client-side early checks** provide instant feedback before any server event is fired

### 👮 Admin Commands & Info
- **Three admin commands** to forcibly apply any kit tier to a target player's current vehicle
- **`/twostepinfo`** client command — shows the installed kit name and tier while seated as driver
- **Admin permission gated** — all admin commands require `admin` ACE permission
- **Notifies both admin and target** on forced installs
- **Logged to server console** with admin name, kit, and plate

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

```bash
# Clone from GitHub
git clone https://github.com/YourUsername/mnc-2step.git

# OR download ZIP from Releases
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-2step/
```

### 2️⃣ Database Setup

The script **automatically creates** the required table on first start:

- `vehicle_2step` — stores kit name, tier, installer name, and timestamps by vehicle plate

No manual SQL import needed!

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure mnc-2step
```

### 4️⃣ Add Items to QBCore

Add all three kit items to `qb-core/shared/items.lua`:

```lua
['basic_2step'] = {
    ['name']        = 'basic_2step',
    ['label']       = 'Basic 2-Step Kit',
    ['weight']      = 500,
    ['type']        = 'item',
    ['image']       = 'basic_2step.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'Entry-level 2-step launch control kit.',
},
['street_2step'] = {
    ['name']        = 'street_2step',
    ['label']       = 'Street 2-Step Kit',
    ['weight']      = 500,
    ['type']        = 'item',
    ['image']       = 'street_2step.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'Street-tuned 2-step with stronger flames and better launch.',
},
['pro_2step'] = {
    ['name']        = 'pro_2step',
    ['label']       = 'Pro 2-Step Kit',
    ['weight']      = 500,
    ['type']        = 'item',
    ['image']       = 'pro_2step.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'Race-grade 2-step with maximum flames, boost, and launch force.',
},
```

### 5️⃣ Add Custom Sounds (Optional)

Place any `.ogg` files into `html/sounds/` and reference them in `config.lua`:

```lua
Config.DefaultSoundFile = 'twostep_pop.ogg'

-- Or per-kit:
limiter = { soundFile = 'my_custom_pop.ogg' }
```

### 6️⃣ Configure Settings

Edit `config.lua` to adjust kits, thresholds, boost values, and job restrictions.

---

## ⚙️ Configuration Guide

### 👷 Job Configuration

```lua
Config.RequireJob = true   -- Set to false to allow any player to install kits

Config.AllowedJobs = {
    ['mechanic'] = 0,   -- Job name = minimum grade level required
    ['bennys']   = 0,
}
```

### 🎛️ Global Defaults

These apply to any kit field left as `nil`:

```lua
Config.Limiter = {
    burstInterval  = 300,     -- ms between bursts while bouncing on limiter
    flameCount     = 2,       -- pops per burst
    scale          = 0.80,    -- particle size
    volumeScale    = 0.09,    -- volume (0.0–1.0, scaled by Config.MaxVolumeScale)
    soundFile      = 'twostep_pop.ogg',
    rpmThreshold   = 0.92,    -- minimum RPM to trigger limiter mode
    speedThreshold = 35.0,    -- m/s — below this = limiter mode (not rolling)
}

Config.Rolling = {
    burstInterval = 300,
    flameCount    = 3,
    scale         = 1.5,
    volumeScale   = 0.07,
    soundFile     = 'twostep_pop.ogg',
    rpmThreshold  = 0.70,     -- lower threshold for rolling 2-step
}

Config.Boost = {
    duration    = 3000,   -- ms the torque multiplier stays active after key release
    multiplier  = 1.35,   -- engine torque multiplier (1.0 = stock)
    finalBurst  = 6,      -- number of pops in the launch burst
    finalScale  = 2.2,    -- particle scale for launch burst
    finalVolume = 0.12,
    soundFile   = 'twostep_pop.ogg',
}
```

### 🔧 Kit Configuration Format

```lua
Config.Kits = {
    ['pro_2step'] = {
        label = 'Pro 2-Step',     -- Display name in notifications
        item  = 'pro_2step',      -- QBCore item name

        limiter = {
            burstInterval = 160,  -- Override any global field here
            flameCount    = 5,
            scale         = 2.0,
            volumeScale   = 0.10,
            soundFile     = 'twostep_pop.ogg',
        },
        rolling = {
            burstInterval = 260,
            flameCount    = 4,
            scale         = 1.7,
            volumeScale   = 0.09,
            soundFile     = 'twostep_pop.ogg',
        },
        boost = {
            duration    = 3500,
            multiplier  = 1.45,
            finalBurst  = 8,
            finalScale  = 2.5,
            finalVolume = 0.14,
        },
    },
}

Config.KitTier = {
    ['basic_2step']  = 1,
    ['street_2step'] = 2,
    ['pro_2step']    = 3,
}
```

### 🎚️ Kit Comparison

| Kit | Tier | Limiter Interval | Boost Multiplier | Launch Burst |
|-----|------|-----------------|------------------|--------------|
| Basic 2-Step | 1 | 220 ms | ×1.20 | 4 pops |
| Street 2-Step | 2 | 190 ms | ×1.30 | 5 pops |
| Pro 2-Step | 3 | 160 ms | ×1.45 | 8 pops |

---

## 🔄 How It Works

1. Player uses a kit item from inventory while standing in front of a turbo-equipped vehicle
2. Client checks job, proximity (within 1m of front), and that a turbo is installed
3. Server kit tier is queried to prevent downgrade attempts before the animation plays
4. Hood opens; a progress bar plays with mechanic animation for the install duration
5. On completion, a server event fires with the plate and kit name
6. Server re-validates job, item ownership, plate, and tier — then consumes the item
7. Kit data is saved to the database and broadcast to all clients via `syncData`
8. While the driver holds `RShift`:
   - Stationary + high RPM → limiter bounce mode (rapid pops, smaller flames)
   - Moving + threshold RPM → rolling 2-step mode (continuous anti-lag)
9. On `RShift` release while rolling → launch burst fires and torque multiplier activates for the configured duration
10. All flame effects are networked to nearby players via server relay

---

## 🖥️ Commands

| Command | Who | Description |
|---------|-----|-------------|
| `/twostepinfo` | Any driver | Shows the installed kit name and tier for the current vehicle |
| `/twostepbasic [id]` | Admin | Force-installs Basic 2-Step on target player's vehicle |
| `/twostepstreet [id]` | Admin | Force-installs Street 2-Step on target player's vehicle |
| `/twosteppro [id]` | Admin | Force-installs Pro 2-Step on target player's vehicle |

- Admin commands require `admin` ACE permission in `server.cfg`
- `[id]` is the target's server ID — omit to apply to your own current vehicle
- The target player must be **inside a vehicle** when admin commands are run

---

## 🐛 Troubleshooting

**Item use has no effect:**
- Confirm item names in `items.lua` match the `item` field in `Config.Kits`
- Ensure the vehicle has a GTA V turbo installed (Mod index 18 in LSC)
- Verify the player is on foot within 1m of the vehicle's front
- Enable `Config.Debug = true` and check server console for validation errors

**No flames appearing:**
- Check client console for particle asset load errors
- Confirm the vehicle has at least one named exhaust bone — heavily modified addon vehicles may use non-standard bone names
- Ensure `ptfxLoaded` is true before flames are triggered (wait a few seconds after resource start)

**No sound playing:**
- Confirm the `.ogg` file exists in `html/sounds/` and the filename matches exactly in config
- Check browser console (F8 in FiveM) for NUI audio errors
- Verify the `ui_page` and `files` entries are present in `fxmanifest.lua`

**Kit not persisting after restart:**
- Check the `vehicle_2step` table was created in your database
- Verify `oxmysql` is fully started before `mnc-2step` in `server.cfg`
- Enable `Config.Debug` and watch for cache/callback logs on vehicle entry

**Boost not felt after launch:**
- The torque multiplier requires the player to be the driver in seat `-1`
- Confirm `Config.Boost.multiplier` is above `1.0` — the default is `1.35`
- Some vehicles with very high base torque may not show a noticeable difference

**Admin command returns "Target is not in a vehicle":**
- The target player must be seated inside a vehicle at the time the command is run

---

## 📝 Credits & License

**Author**: Stan Leigh  
**Version**: 1.0.0  
**Framework**: QBCore

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

### Contributing
Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with a detailed description

---

## 📞 Support & Community

For support, bug reports, or feature requests:
- Open an issue on GitHub
- Join our Discord community
- Check existing documentation

---

## 🔄 Changelog

### Version 1.0.0 (Current Release)
**New Features:**
- ✨ Initial release with three tiered 2-step kits (Basic, Street, Pro)
- ✨ Rev-limiter bounce mode — rapid flame bursts while stationary with key held above RPM threshold
- ✨ Rolling 2-step mode — continuous anti-lag while moving above speed and RPM thresholds
- ✨ Launch burst on key release — final flame burst + engine torque multiplier for configurable duration
- ✨ `veh_backfire` particle effects across all detected exhaust bones with looped-handle burst trick
- ✨ Staggered multi-pop timing (35 ms between flames per burst) for natural rapid-fire feel
- ✨ Pooled NUI audio engine (16 instances per file) for overlap-safe sound playback
- ✨ Per-delay, per-volume scheduling on every pop burst via `mnc_2step_pop` NUI message
- ✨ Custom `.ogg` sound file support with per-kit and global default configuration
- ✨ Networked flame broadcast to all nearby clients via server relay
- ✨ Turbo requirement check — vehicle must have GTA turbo mod installed before kit can be fitted
- ✨ Front-of-vehicle proximity check (1m from headlight area) for item use
- ✨ Hood open/close during installation with mechanic crouch animation
- ✨ Tier-locked upgrade system — kits can only be installed over equal or lower tiers
- ✨ Persistent `vehicle_2step` MySQL table with kit, tier, installer name, and timestamps
- ✨ Server-side in-memory cache pre-loaded on startup for instant lookups
- ✨ Client-side plate cache to eliminate redundant server callbacks
- ✨ `mnc-2step:syncData` broadcast to all clients for instant post-install activation
- ✨ Per-kit override system with global fallback defaults for all flame and boost parameters
- ✨ Three admin commands to force-apply any kit tier to a target player's vehicle
- ✨ `/twostepinfo` driver command to query the installed kit name and tier
- ✨ Job and grade restriction system with `Config.RequireJob = false` override option

---

## ⚠️ Important Notes

1. **Turbo Dependency**: The 2-step system requires GTA V's native turbo mod (mod index 18) — the loop silently skips vehicles without it to prevent unwanted activation
2. **Exhaust Bones**: Flame effects rely on standard GTA V exhaust bone names; some heavily modded addon vehicles may have non-standard bones and show no flames
3. **Torque Multiplier**: The launch boost uses `SetVehicleEngineTorqueMultiplier` — this is a client-side call and resets to `1.0` automatically when boost expires
4. **Audio Files**: The included `twostep_pop.ogg` is the default sound. Replacements must be `.ogg` format and placed in `html/sounds/`
5. **Database**: Requires oxmysql — MariaDB 10.3+ recommended
6. **Compatibility**: QBCore only — not compatible with ESX
7. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Flames out the exhaust, grip off the line. 🔥**