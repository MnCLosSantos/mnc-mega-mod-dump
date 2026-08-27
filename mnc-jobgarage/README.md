# 🚓 MNC Job Garage

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.4.0-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
A full replacement for a static job-garage script: per-job vehicle fleets with grade and custom-role gating, an image-driven NUI pull-out grid (not a text menu), live checkout tracking so everyone can see who has which unit out, and an in-game admin panel that can create, edit, and delete garages, vehicles, and roles without ever touching `config.lua`. Includes an in-world visual setup tool for placing new garage spawn/exit points.

---

## ✨ Key Features

### 🚗 Per-Job Vehicle Fleets
- Any number of job garages, each with its own `garageId` — add a **second garage for the same job** (e.g. `police_sandy`) with a unique `garageId` and it gets a completely independent vehicle list and DB records
- Every vehicle entry supports `grade` (minimum job grade to pull it out), `CustomName`, `colors`, `livery`, `performance = "max"`, `bulletproof`, `windowTint`, `extras`, `plate` override, and full `visualUpgrades` (fender, roof, wheels, neon color/layout)
- An optional **custom role system** layered on top of grade — name roles per job (e.g. "K9 Handler", "Detective") and require one on specific vehicles, independent of grade level

### 🖼️ Image-Driven Pull-Out Grid
- The vehicle picker is a custom NUI grid showing each vehicle's actual image, not a plain text list
- Images resolve through a fallback chain: FiveM's own vehicle doc images first, then two MnC GitHub image-storage repos (covering ~1,900 lore/addon vehicles), then a local fallback image
- `Config.Target` selects **qb-target** or **ox-target** for interacting with the garage prop/zone

### 🛠️ In-Game Garage Setup Tool
- `/garagesetup` drops you into a visual placement mode instead of hand-typing coordinates
- **Enter** (rebindable `garagesetup_confirm` keybind) confirms a point, **Backspace** (rebindable `garagesetup_cancel`) cancels — used to set both the vehicle spawn point and the walk-out point for a garage
- `/printmyveh` (must be seated in a vehicle) prints the current vehicle's model/livery/mods info to help you build new fleet entries

### 🖥️ Admin Panel (No Config Editing Required)
- `/jobgarageadmin` opens a full NUI admin panel (ACE `admin`/`god` or QBCore `admin`/`god`/`superadmin` permission) to create/edit/delete garages, add/edit/hide/restore individual vehicles, and manage the role system — all persisted to the database and pushed live to every connected client
- Admins can remotely **sign a vehicle back in** for any player from the panel
- Config-defined garages can be hidden per-vehicle rather than deleted, and restored later without re-editing `config.lua`

### 🎭 Custom Roles
- Beyond grade gating, bosses (grade 4+ by default) can assign named roles to specific players for their own job directly from the in-game pull-out UI — no admin needed for day-to-day role assignment
- Admins can additionally manage roles and player assignments for **any** job from the admin panel
- Role holders are notified live the moment a role is assigned or removed while online

### 📡 Live Checkout Tracking
- The system tracks which vehicles are currently checked out of each garage and by whom, broadcasting updates (`checkoutUpdated`) so the pull-out UI and admin panel both show real-time "who has what" per garage
- Optional `Config.ReturnDistanceCheck` + `Config.ReturnRadius` require a vehicle to be physically near the garage before it can be checked back in

### 🔧 Integration Options
- `Config.Notify`: `"qb"` or `"ox"` notification style
- `Config.Fuel`: point at your fuel resource's export name (e.g. `LegacyFuel`)
- `Config.CarDespawn`: optional despawn animation when a vehicle is returned

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |
| qb-target | Latest | ✅ Yes (or ox-target — set via `Config.Target`) |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-jobgarage/
```

### 2️⃣ Database Setup

The script **automatically creates and migrates** all four required tables on first start:

- `mnc_job_garages` — garage locations and settings (config-defined garages are mirrored in here on first run)
- `mnc_garage_vehicles` — per-garage vehicle fleet entries
- `mnc_garage_roles` — custom role definitions per job
- `mnc_garage_player_roles` — role assignments per citizen

No manual SQL import needed.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure qb-target
ensure mnc-jobgarage
```

### 4️⃣ Configure Settings

Edit `config.lua` to set your notification/target/fuel systems and define your initial job garages and fleets — or simply start the resource and build everything through `/jobgarageadmin` instead.

---

## ⚙️ Configuration Guide

```lua
Config = {
    Debug = false,
    Notify = "ox",                -- "qb" or "ox"
    Target = "qb",                 -- "qb" or "ox"
    Fuel = "LegacyFuel",
    CarDespawn = false,
    ReturnDistanceCheck = false,
    ReturnRadius = 15.0,

    ImagePaths = {
        primary        = 'https://docs.fivem.net/vehicles/{model}.webp',
        github1        = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage/raw/main/{model}.png',
        github2        = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage-2/raw/main/{model}.png',
        local_fallback = './images/fallback.png',
    },

    Locations = {
        {
            zoneEnable = true,
            job      = "police",
            garageId = "police",       -- unique — duplicate this block with a new garageId for a 2nd garage
            garage = {
                spawn = vec4(436.2, -976.03, 24.9, 138.13),
                out   = vec4(461.14, -975.53, 25.7, 0.29),
                list = {
                    polnscout = { grade = 0, CustomName = "police patrol 1", performance = "max", order = 1 },
                    -- ...
                }
            }
        },
        -- Track Marshall, Ambulance, Vinewood Records, La Festa, Auto Exotics,
        -- SSMCO, Gruppe 6, Yacht Club, and MNC Racing garages ship as examples
    }
}
```

- Any garage added via the admin panel is stored purely in the database — you never have to touch this file after initial setup if you don't want to
- `visualUpgrades` on a vehicle entry (fender, roof, neon, wheels) applies automatically the moment it's pulled out

---

## 🎮 Controls & Usage

| Command / Key | Access | Description |
|---|---|---|
| Target/interact at a garage | Job members | Opens the image-grid pull-out/return menu for that garage |
| `/garagesetup` | Admin (ACE `command.garagesetup`) | Enters visual placement mode for a new garage's spawn/out points |
| **Enter** (rebindable) | During setup mode | Confirms the current placement point |
| **Backspace** (rebindable) | During setup mode | Cancels setup mode |
| `/printmyveh` | Anyone, in a vehicle | Prints the current vehicle's model/mods info to console for building fleet entries |
| `/jobgarageadmin` | Admin only | Opens the full garage/vehicle/role admin panel |

**Role assignment (bosses, grade 4+):** open the pull-out UI at your own job's garage — a role panel lets you assign or remove your job's custom roles from any of your members without admin involvement.

---

## 🔧 Troubleshooting

**A vehicle image never loads, just shows the fallback:**
- The model isn't covered by any of the three remote sources — add your own image locally and point `Config.ImagePaths.local_fallback` at it, or contribute it to the linked GitHub image-storage repos

**`/jobgarageadmin` says permission denied:**
- Requires QBCore `admin`/`god`/`superadmin` permission level, or ACE `add_ace group.admin command.garagesetup allow`-style admin group — grade alone on a job does not grant admin panel access

**Role panel doesn't appear for a boss:**
- Roles are only assignable in-job at grade 4 or above (`ROLE_ASSIGN_MIN_GRADE`); admins can still assign any job's roles from `/jobgarageadmin` regardless of grade

**Vehicle can't be returned:**
- If `Config.ReturnDistanceCheck` is enabled, the vehicle must be within `Config.ReturnRadius` of the garage's `out` point to check back in

**Two garages on the same job are sharing vehicles:**
- Confirm each garage block has a distinct `garageId` — vehicles and checkouts are keyed by `garageId`, not by job name alone

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.4.0
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

1. **Database**: Requires oxmysql — four tables are created and auto-migrated on first start
2. **Vehicle images**: served from external hosts (FiveM docs + GitHub) — a garage without internet access on the client will fall back to the local placeholder image
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Roll out in style, know who's got what, and never fight `config.lua` again. 🚓**
