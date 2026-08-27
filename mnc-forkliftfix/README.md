# 🏗️ MNC Forklift Fix

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![Standalone](https://img.shields.io/badge/Framework-Standalone-lightgrey.svg)]()
[![Version](https://img.shields.io/badge/Version-1.1.0-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
`mnc-forkliftfix` gives GTA's forklift real, network-synced lifting: pick up vehicles or props on its forks, raise and lower them smoothly, and carry them anywhere without the load desyncing, freezing, or falling through the map for other players. On top of the core forks it adds a **lift-platform mode** (attach the forklift itself onto the back of a flatbed/utility vehicle) and a **vehicle stacking system** (stack cars directly on top of each other, multiple levels deep) — both fully synced across every client, with a small NUI helper panel that shows the relevant controls only when they're actually usable.

---

## ✨ Key Features

### 🔱 Fork Lifting (Vehicles & Props)
- Drive up to a vehicle or prop with the forks and press **E** to attach it to the forks bone (`Config.ForksBoneName`, default `'forks'`)
- Attached vehicles have their engine killed and are made undriveable and non-collidable while lifted; attached props are frozen against gravity and re-anchored for a couple of frames to eliminate attach jitter
- Hold the **Up/Down arrows** (`Config.LiftControl` / `Config.LowerControl`) to nudge the load up or down at `Config.LiftSpeed` meters/second, clamped between `Config.MinLiftOffset` and `Config.MaxLiftOffset`
- Press **E** again to detach — the vehicle regains gravity, collision, and driveability
- Pickup range is configurable separately for vehicles (`Config.PickupDistance`) and props (`Config.PropPickupDistance`)

### 🚚 Lift-Platform Mode (Forklift-on-Vehicle)
- Press **O** (`Config.ForkliftLiftKeyLabel`) to attach the **forklift itself** onto the bed of a nearby flatbed/utility/service-class vehicle (`Config.PlatformBaseClasses`), turning that vehicle into a rolling platform for hauling the forklift
- While anchored, **E does nothing** — only **O** detaches — preventing an accidental double-attach with the fork-lifting controls
- The anchored forklift can still be nudged up/down with the lift controls (`Config.ForkliftLiftMinOffset` / `Config.ForkliftLiftMaxOffset`)
- Platform attach range is controlled separately via `Config.PlatformPickupDistance`

### 🧱 Vehicle Stacking
- Drive a vehicle directly on top of another and press the attach key (**H**, `Config.StackKeyLabelAttach`) to rigidly stack it onto whatever vehicle is directly below — including onto the current top of an existing stack, so multiple vehicles can be stacked several levels deep
- Built-in **cycle protection** stops you from stacking a vehicle back onto something already above it in the same chain
- Hold the detach key (**N**, `Config.StackKeyLabelDetach`) to peel levels off one at a time — `Config.StackDetachHoldTimePerLevel` (default 1000ms) of holding detaches one additional level, starting from the link closest to the driver and working outward so nothing falls through
- A quick tap of **N** (under 300ms) detaches just the single closest level
- If the vehicle you're driving has nothing stacked directly on it but is towing a trailer that does, control automatically passes to the trailer so the tow driver can still manage the stack
- `/dumpstack` (debug) prints the full stack registry and the current vehicle's chain to the console

### 🖥️ Context-Aware Helper UI
- A small NUI panel (`Config.ShowHelperUI`) appears automatically only when it's relevant — driving a forklift, sitting on an active platform anchor, or controlling a valid stack base — and hides itself otherwise
- **BACK** toggles the helper UI on/off manually if you'd rather hide it permanently
- Uses `ox_lib` notifications by default (`Config.UseOxLibNotify`), or falls back to native GTA notifications if disabled

### 🔄 Full Network Sync
- Every attach/detach (forks, platform, and stacking) is relayed through the server and re-broadcast to all clients, so late-joining players are synced to the current state of every active attachment on join
- Vehicles driving while attached have their engine disabled and are marked undriveable so the physics engine doesn't fight the attach constraint — the exact bug class that used to cause freeze-then-crash issues on attach

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| ox_lib | Latest | ⚠️ Optional (for `Config.UseOxLibNotify`) |

This is a standalone resource — no framework (QBCore/ESX/etc.) is required for any of its functionality.

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-forkliftfix/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure mnc-forkliftfix
```

No database setup required — all attachment state lives in memory and is re-synced to clients on join.

### 3️⃣ Configure Settings

Edit `config.lua` to set keybinds, pickup ranges, lift speed, and which forklift models can lift which vehicle classes.

---

## ⚙️ Configuration Guide

```lua
Config = {}
Config.Debug = false                        -- prints why a lift attempt failed to the F8 console
Config.ShowHelperUI = true
Config.ForkliftLiftKeyLabel = 'O'
Config.StackKeyLabelAttach = 'H'
Config.StackKeyLabelDetach = 'N'
Config.UseOxLibNotify = true                -- Set false to fall back to native gta notifications
Config.ForksBoneName = 'forks'              -- bone name on the forklift's forks
Config.PickupDistance = 4.0                 -- max horizontal distance (meters) from forks bone to a vehicle to allow pickup
Config.PropPickupDistance = 4.0             -- max horizontal distance (meters) from forks bone to a prop to allow pickup
Config.PlatformPickupDistance = 15.0        -- max horizontal distance for platform/lift-mode attach (forklift -> vehicle)
Config.StackSearchDistance = 5.0            -- max distance from vehicle to attach vehicle to another vehicle
Config.StackDetachHoldTimePerLevel = 1000   -- milliseconds per level
Config.ToggleControl = 38                   -- INPUT_PICKUP (E by default) - Attach / Detach
Config.StackAttachKey = 74                  -- H
Config.StackDetachKey = 249                 -- N
Config.LiftControl = 172                    -- INPUT_VEH_SELECT_NEXT_WEAPON (Up Arrow by default)
Config.LowerControl = 173                   -- INPUT_VEH_SELECT_PREV_WEAPON (Down Arrow by default)
Config.LiftSpeed = 0.5                      -- meters per second while lift/lower is held
Config.MinLiftOffset = -1.0                 -- lowest the vehicle can be nudged relative to its captured pickup height
Config.MaxLiftOffset = 2.0                  -- highest the vehicle can be nudged relative to its captured pickup height
Config.ForkliftLiftMinOffset = -1.0         -- lowest the forklift can be nudged relative to its anchor point
Config.ForkliftLiftMaxOffset = 3.0          -- highest the forklift can be nudged relative to its anchor point

-- Which forklift models are allowed to lift vehicles, and which vehicle
-- classes each one is allowed to lift (standard GTA V vehicle class enum)
Config.Forklifts = {
    [`forklift`] = { -- default GTA V forklift
        categories = {
            [0] = true, [1] = true, [2] = true, [3] = true, [4] = true,
            [5] = true, [6] = true, [7] = true, [8] = true, [9] = true,
            [11] = true, [12] = true, [13] = true, [17] = true, [18] = true,
        }
    },
    -- Example of a second, bigger forklift that can lift more classes:
    [`vstruck`] = {
        categories = { --[[ every class, including Industrial/Boats/Aircraft/Military/Commercial/Trains ]] }
    },
}

-- Platform base vehicle restrictions (vehicles the forklift can be lifted ONTO)
Config.PlatformBaseClasses = {
    [10] = true,  -- Industrial
    [11] = true,  -- Utility
    [12] = true,  -- Vans
    [17] = true,  -- Service
    [20] = true,  -- Commercial
}
```

- `Config.Forklifts` — add any custom forklift model here with its own `categories` table to control exactly which vehicle classes it's allowed to lift; a class left out (or commented out, like `Industrial`/`Boats`/`Helicopters`/`Planes`/`Military`/`Trains` on the default forklift) simply can't be picked up by that model
- `Config.PlatformBaseClasses` — controls which vehicle classes are valid **platforms** for lift-platform mode (i.e. what the forklift itself can be loaded onto), independent of what the forklift can lift with its forks
- Vehicle class IDs follow the standard GTA V enum: `0` Compacts, `1` Sedans, `2` SUVs, `3` Coupes, `4` Muscle, `5` Sports Classics, `6` Sports, `7` Super, `8` Motorcycles, `9` Off-road, `10` Industrial, `11` Utility, `12` Vans, `13` Cycles, `14` Boats, `15` Helicopters, `16` Planes, `17` Service, `18` Emergency, `19` Military, `20` Commercial, `21` Trains

---

## 🎮 Controls & Usage

| Input | Context | Action |
|---|---|---|
| **E** | Driving a forklift, near a vehicle/prop | Attach the nearest vehicle/prop to the forks |
| **E** | Forklift has a load on its forks | Detach the load |
| **Up / Down Arrow** | Load attached to forks, or forklift anchored in platform mode | Raise / lower the load or the forklift |
| **O** | Driving a forklift near a valid platform vehicle | Attach the forklift itself onto that vehicle (platform mode) |
| **O** | Forklift anchored in platform mode | Detach the forklift from the platform |
| **H** | Driving a vehicle directly above another vehicle | Stack the current vehicle onto the one below |
| **N** (hold) | Driving/controlling the base of a stack | Detach one level per `Config.StackDetachHoldTimePerLevel` held |
| **N** (tap) | Driving/controlling the base of a stack | Detach just the closest level |
| **BACK** | Any time | Manually toggle the helper NUI panel on/off |
| `/dumpstack` | Debug | Prints the full stack registry and current chain to console |

**Note:** while the forklift is anchored to a platform vehicle (`O`), the **E** key does nothing for it — this is intentional, to prevent accidentally triggering a normal fork-attach while the forklift itself is the thing being carried.

---

## 🔧 Troubleshooting

**Can't attach a vehicle to the forks:**
- Confirm you're within `Config.PickupDistance` (horizontal) of the forks bone, and that you're driving a model listed in `Config.Forklifts`
- Check that the target vehicle's class is enabled in that forklift's `categories` table
- Enable `Config.Debug = true` to print the specific reason a lift attempt failed to the F8 console

**Forklift won't attach to a flatbed/platform vehicle:**
- The target vehicle's class must be enabled in `Config.PlatformBaseClasses`
- You need to be within `Config.PlatformPickupDistance`, which is intentionally much larger than the fork pickup range

**Stacking a vehicle does nothing:**
- You must be the driver, directly above the target vehicle, and within `Config.StackSearchDistance`
- Stacking onto a vehicle that's already part of a chain attaches to the **current top** of that chain automatically — check `/dumpstack` if the result looks wrong
- A stack that would create a loop (attaching a vehicle back onto something already above it) is blocked with an error notification

**Vehicles freeze or judder while attached:**
- This build disables the engine and marks attached vehicles undriveable specifically to stop the physics engine from fighting the attach constraint; if you still see judder, check for another resource also managing physics/collision on the same vehicles

**Helper UI won't show:**
- It only appears while driving a forklift, anchored to a platform, or controlling a usable stack base — confirm `Config.ShowHelperUI` is `true` and that you haven't toggled it off with **BACK**

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.1.0
**Framework**: Standalone
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

1. **Compatibility**: Standalone — works with QBCore, ESX, or no framework at all; `ox_lib` is only used for prettier notifications and is optional
2. **Performance**: Attachment state is tracked in memory only (no database), and is re-synced to each client on join — nothing persists across a full server restart
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Lift it, stack it, haul it — safely synced every time. 🏗️**
