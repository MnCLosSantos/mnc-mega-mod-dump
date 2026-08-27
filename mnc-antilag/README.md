# 🔥 MNC Anti-Lag / Exhaust Flame System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A **fully-featured anti-lag and exhaust flame system** for QBCore-based FiveM servers. Mechanics install tiered anti-lag kits onto turbo-equipped vehicles, producing realistic exhaust flames and audio pops when the driver lifts off the throttle at high RPM. Flames spawn directly from each exhaust bone using accurate world-space rotation, sounds play through a pooled NUI audio engine, and all kit data persists by license plate across sessions.

---

## ✨ Key Features

### 💥 Flame & Sound Behaviour
- **Automatic activation** — flames and pops fire passively whenever the driver's RPM meets the configured threshold
- **Lift-off mode** (`Config.LiftOffOnly = true`) — fires only when throttle is below 10%, replicating real anti-lag lift-off behaviour; set to `false` to fire continuously at high RPM
- **~45% fire chance per eligible window** — a built-in skip chance keeps the effect present but natural, not constant
- **±1 pop count variation** per burst for organic feel (minimum 1)
- **RPM-scaled volume** — small boost applied at higher RPM so the effect intensifies as the engine spins harder
- **±20% interval jitter** — burst timing varies each cycle to avoid a robotic, metronomic cadence

### 🎆 Particle System
- **`veh_backfire` particles** spawned at each detected exhaust bone using `StartParticleFxNonLoopedAtCoord`
- **Bone world-space rotation** retrieved via `GetEntityBoneRotation` and applied to the particle, ensuring flames exit the pipe at the correct angle regardless of vehicle heading
- **Multi-bone support** — scans for `exhaust`, `exhaust_2`–`exhaust_4`, `exhaust_ml`, `exhaust_mr`, `exhaust_dl`, `exhaust_dr` on every burst
- **Fallback positioning** — vehicles with no named exhaust bones receive flames at a fixed rear offset (`0.0, -2.2, 0.3`) so no vehicle is left without effect
- **Scale randomisation** — each individual flame is scaled `0.5–1.1×` the kit's base scale for a natural, non-uniform look

### 🔊 NUI Audio Engine
- **Pooled Audio instances** — 10 Audio objects per sound file allow overlapping pops without clipping or delays
- **Per-pop delay and volume scheduling** — each pop in a burst has its own randomised timing offset (`140–260 ms` apart) and independent volume with `±12%` variation
- **Audio/visual sync guarantee** — flames are spawned in a thread that mirrors the exact delay array sent to NUI, so each pop and its flame always coincide
- **Custom `.ogg` support** — drop any sound file into `html/sounds/` and reference it per-kit or as the global default

### 🌐 Networked Flames
- **`mnc-antilag:broadcastFlames`** server relay sends flame effects to all nearby clients after every local burst
- **Driver exemption** — the originating driver's client skips the broadcast replay to prevent double-spawning
- **Randomised remote timing** — remote clients apply `140–260 ms` jitter between pops for natural-looking variation across different machines

### 🔧 Tiered Kit System
- **Three kit tiers** out of the box: Basic (Tier 1), Street (Tier 2), and Pro (Tier 3)
- **Upgrade-only install** — a kit can only be installed over a lower tier; equal or higher tiers are rejected
- **Per-kit configuration** for burst interval, flame count, particle scale, volume, and sound file
- **Global volume fallback** via `Config.MaxVolumeScale` for any kit without an explicit `volumeScale`

### 🔒 Installation Requirements
- **Turbo required** — vehicles must have GTA V's base turbo mod (mod index 18) before any anti-lag kit can be fitted
- **Client-side turbo check for admin installs** — the target client verifies turbo presence and reports back to the server before the kit is committed, preventing server-side spoofing
- **Player must be on foot**, standing within **1 metre of the vehicle's front** (headlight area)
- **Hood opens** during installation and closes on completion or cancellation
- **Single progress bar** with mechanic crouch animation; cancellable at any point with no item consumed
- **Tier pre-check before animation** — existing kit tier is queried before the progress bar starts, preventing wasted install time

### 💾 Persistence & Sync
- **Database-backed storage** — kit name, tier, installer name, and timestamps saved to `vehicle_antilag` by license plate
- **Server-side in-memory cache** pre-loaded from database on startup for instant lookups during the session
- **Global client-side plate cache** (`_G['mnc_antilag_cache_' .. plate]`) avoids redundant server callbacks for already-known plates
- **`mnc-antilag:syncData` broadcast** to all clients after install — the driver's anti-lag loop starts immediately without rejoining

### 🔒 Security & Validation
- **Server-side job check** re-validates mechanic job and grade on every install attempt
- **Server-side item check** — kit item consumed only after all validations pass
- **Server-side tier check** — prevents equal or downgrade installs
- **Plate length validation** — rejects malformed or oversized plate strings
- **Admin permission re-validation** on the `adminCommitKit` callback — prevents spoofed commit events
- **Client-side early checks** provide instant feedback before any server event is fired

### 👮 Admin Commands
- **Three admin commands** to forcibly apply any kit tier to a target player's current vehicle
- **Two-step admin flow** — server triggers turbo check on target client first; kit is only committed after the check passes
- **Permission gated** — requires `admin` ACE permission
- **Notifies both admin and target** player on success
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
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-antilag/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-antilag/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-antilag/
```

### 2️⃣ Database Setup

The script **automatically creates** the required table on first start:

- `vehicle_antilag` — stores kit name, tier, installer name, and timestamps by vehicle plate

No manual SQL import needed!

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure mnc-antilag
```

### 4️⃣ Add Items to QBCore

Add all three kit items to `qb-core/shared/items.lua`:

```lua
['antilag_1'] = {
    ['name']        = 'antilag_1',
    ['label']       = 'Basic Anti-Lag Kit',
    ['weight']      = 500,
    ['type']        = 'item',
    ['image']       = 'antilag_1.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'Entry-level anti-lag system. Mild pops on lift-off.',
},
['antilag_2'] = {
    ['name']        = 'antilag_2',
    ['label']       = 'Street Anti-Lag Kit',
    ['weight']      = 500,
    ['type']        = 'item',
    ['image']       = 'antilag_2.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'Street-tuned anti-lag with stronger flames and faster bursts.',
},
['antilag_3'] = {
    ['name']        = 'antilag_3',
    ['label']       = 'Pro Anti-Lag Kit',
    ['weight']      = 500,
    ['type']        = 'item',
    ['image']       = 'antilag_3.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'Race-grade anti-lag. Maximum flames and volume.',
},
```

### 5️⃣ Add Custom Sounds (Optional)

Place any `.ogg` files into `html/sounds/` and reference them in `config.lua`:

```lua
Config.DefaultSoundFile = 'antilag_pop.ogg'

-- Or per-kit:
['antilag_3'] = {
    soundFile = 'my_loud_pop.ogg',
}
```

### 6️⃣ Configure Settings

Edit `config.lua` to adjust kits, RPM thresholds, lift-off mode, and job restrictions.

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

### 🎛️ Global Behaviour Settings

```lua
Config.MinRPM      = 0.65   -- Minimum RPM (0.0–1.0) required to trigger flames
Config.LiftOffOnly = true   -- true = only fires when throttle < 0.1 (lift-off)
                             -- false = fires continuously at threshold RPM
Config.MaxVolumeScale = 0.06  -- Global volume fallback if kit has no volumeScale
Config.DefaultSoundFile = 'antilag_pop.ogg'  -- Fallback sound for kits without soundFile
```

### 🔧 Kit Configuration Format

```lua
Config.Kits = {
    ['antilag_3'] = {
        label         = 'Pro Anti-Lag Kit',   -- Display name in notifications
        item          = 'antilag_3',           -- QBCore item name
        burstInterval = 700,                   -- ms between burst windows
        flameCount    = 4,                     -- pops per burst (±1 variation applied)
        scale         = 1.5,                   -- base particle scale (0.5–1.1× random applied per flame)
        volumeScale   = 0.07,                  -- volume (scaled by RPM boost at runtime)
        soundFile     = 'antilag_pop.ogg',     -- .ogg file in html/sounds/
    },
}

Config.KitTier = {
    ['antilag_1'] = 1,
    ['antilag_2'] = 2,
    ['antilag_3'] = 3,
}
```

### 🎚️ Kit Comparison

| Kit | Tier | Burst Interval | Flames/Burst | Particle Scale |
|-----|------|---------------|--------------|----------------|
| Basic Anti-Lag | 1 | 1200 ms | 1 | 1.0 |
| Street Anti-Lag | 2 | 800 ms | 3 | 1.2 |
| Pro Anti-Lag | 3 | 700 ms | 4 | 1.5 |

---

## 🔄 How It Works

1. Player uses a kit item from inventory while standing in front of a turbo-equipped vehicle
2. Client verifies job, proximity (within 1m of front), existing tier, and that a turbo is installed — before the animation runs
3. Hood opens; a 5-second progress bar plays with mechanic crouch animation
4. On completion, a server event fires with the plate and kit name
5. Server re-validates job, item ownership, plate, and tier — then consumes the item
6. Kit data is saved to the database and broadcast to all clients via `syncData`
7. The anti-lag loop starts automatically for the driver's current vehicle
8. Every ~`burstInterval` ms (±20% jitter), the loop checks RPM and throttle:
   - RPM below `Config.MinRPM` → skip
   - `LiftOffOnly = true` and throttle above 10% → skip
   - 55% random skip chance applied to remaining windows
9. On a firing window: per-pop delays and volumes are generated, sent to NUI audio, and flames are spawned in a synced thread at each exhaust bone
10. A server broadcast sends the flame count to all nearby clients for networked visuals

---

## 🖥️ Admin Commands

| Command | Kit Applied |
|---------|-------------|
| `/antilag1 [id]` | Basic Anti-Lag Kit (Tier 1) |
| `/antilag2 [id]` | Street Anti-Lag Kit (Tier 2) |
| `/antilag3 [id]` | Pro Anti-Lag Kit (Tier 3) |

- All commands require `admin` ACE permission in `server.cfg`
- `[id]` is the target's server ID — omit to apply to your own current vehicle
- The target player must be **inside a turbo-equipped vehicle** when commands are run
- Admin installs use a two-step turbo check: server asks the target client to verify turbo before committing

---

## 🐛 Troubleshooting

**Item use has no effect:**
- Confirm item names in `items.lua` match the `item` field in `Config.Kits`
- Ensure the vehicle has a GTA V turbo installed (Mod index 18 in LSC)
- Verify the player is on foot within 1m of the vehicle's front
- Enable `Config.Debug = true` and check server console for validation errors

**No flames appearing while driving:**
- Confirm RPM is above `Config.MinRPM` — try raising throttle briefly then lifting off
- If `Config.LiftOffOnly = true`, ensure you are fully releasing the throttle
- Check client console (F8) for particle asset load errors
- Note the built-in 55% skip chance means flames will not fire on every eligible window

**Flames appear in the wrong position:**
- The vehicle may use non-standard exhaust bone names — enable `Config.Debug` to see how many bones are detected
- Vehicles with zero detected bones fall back to a fixed rear offset; this is expected behaviour for some addon vehicles

**No sound playing:**
- Confirm the `.ogg` file exists in `html/sounds/` and the filename matches exactly in config
- Check browser/NUI console (F8) for audio errors
- Verify `ui_page` and `files` entries are present in `fxmanifest.lua`

**Kit not persisting after server restart:**
- Check the `vehicle_antilag` table was created in your database
- Verify `oxmysql` is started before `mnc-antilag` in `server.cfg`
- Enable `Config.Debug` and watch for "cache hit" / "server hit" logs on vehicle entry

**Admin command: "Target vehicle does not have a Turbo installed":**
- The target player's vehicle must have GTA V's turbo mod (mod index 18) equipped before admin force-install will work

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

### Version 1.0.0 (Current Release)
**New Features:**
- ✨ Initial release with three tiered anti-lag kits (Basic, Street, Pro)
- ✨ Passive anti-lag loop — fires automatically when RPM and throttle conditions are met
- ✨ `Config.LiftOffOnly` toggle — restrict flames to throttle lift-off or allow continuous high-RPM firing
- ✨ `veh_backfire` particles at every detected exhaust bone using bone world-space rotation for correct flame direction
- ✨ Fallback flame positioning for vehicles with no named exhaust bones
- ✨ Per-flame scale randomisation (0.5–1.1×) for natural, non-uniform visual variation
- ✨ 55% skip chance per eligible window to keep the effect natural, not constant
- ✨ ±1 pop count variation per burst with RPM-scaled volume boost
- ✨ ±20% burst interval jitter to eliminate robotic timing patterns
- ✨ Audio/visual sync guarantee — flame thread mirrors exact NUI delay array so each pop and its flame coincide
- ✨ Pooled NUI audio engine (10 instances per file) for overlap-safe sound playback
- ✨ Per-pop delay and volume scheduling with ±12% volume randomisation
- ✨ Custom `.ogg` sound file support with per-kit and global default fallback
- ✨ Networked flame broadcast to all nearby clients via server relay with randomised remote timing
- ✨ Turbo requirement check (mod index 18) before any kit installation
- ✨ Two-step admin turbo verification — client-side check reported back to server before commit
- ✨ Admin permission re-validation on commit callback to prevent spoofed events
- ✨ Front-of-vehicle proximity check (1m from headlight area) for item use
- ✨ Hood open/close during installation with mechanic crouch animation
- ✨ Tier pre-check before progress bar starts — no wasted animation time on invalid installs
- ✨ Upgrade-only tier system — equal or lower tier installs are rejected server-side
- ✨ Persistent `vehicle_antilag` MySQL table with kit, tier, installer name, and timestamps
- ✨ Server-side in-memory cache pre-loaded on startup for instant lookups
- ✨ Global client-side plate cache to eliminate redundant server callbacks
- ✨ `mnc-antilag:syncData` broadcast to all clients for instant post-install loop activation
- ✨ Three admin commands to force-apply any kit tier to a target player's vehicle
- ✨ Job and grade restriction system with `Config.RequireJob = false` override option

---

## ⚠️ Important Notes

1. **Turbo Dependency**: The anti-lag system requires GTA V's native turbo mod (mod index 18) — both player installs and admin commands check this before proceeding
2. **Exhaust Bones**: Flame accuracy depends on standard GTA V exhaust bone names; addon vehicles with non-standard bones will fall back to the fixed rear-offset position
3. **Skip Chance**: The built-in 55% skip chance is intentional — flames firing on every eligible window looks unnatural. Lower it in the source if you prefer a more aggressive effect
4. **Audio Files**: The included `antilag_pop.ogg` is the default sound. Replacements must be `.ogg` format and placed in `html/sounds/`
5. **Database**: Requires oxmysql — MariaDB 10.3+ recommended
6. **Compatibility**: QBCore only — not compatible with ESX
7. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Pops, flames, and anti-lag on every lift. 🔥**
