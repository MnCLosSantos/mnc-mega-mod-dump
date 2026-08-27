# 🛡️ MNC Admin Menu

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-2.0.0-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_2" src="https://github.com/user-attachments/assets/2aa976e8-aa79-459d-bb4b-ad5fe49b4efb" />
A single NUI panel for the day-to-day admin work that would otherwise need half a dozen separate commands: look up a player and manage their jobs, money, vehicles, and inventory from one screen. Also bundles a completely separate, all-players self-service command for moving your own vehicle between garages.

---

## ✨ Key Features

### 🔍 Player Lookup & Management
- Look up any online player and pull their current jobs, money (cash/bank/etc. per money type), owned vehicles, and inventory into the panel
- **Jobs**: set a job and grade, remove a specific job, or clear all of a player's jobs — includes multi-job sync support so removed jobs disappear from their UI live
- **Money**: add, remove, or hard-set any configured money type for a player
- **Vehicles**: view a player's owned vehicles, delete one outright, or reassign it to a different garage
- **Inventory**: view a player's current inventory and remove a specific item/amount

### 🚗 Self-Service Garage Mover (`/movegarage`)
- Available to **every player**, not just admins — lets a player move one of their own owned vehicles to a different garage without needing staff assistance
- Runs through its own server-checked flow, separate from the admin panel's vehicle tools

### 🔐 Permission-Gated Admin Access
- `/mncadmin` is checked server-side against QBCore's `admin` permission before the panel ever opens — non-admins get no response, not just a hidden button

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-adminmenu/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-adminmenu
```

No database setup required — the panel reads and writes directly against QBCore's own player, vehicle, and inventory data; no separate tables of its own.

### 3️⃣ Grant Admin Access

Make sure the staff who should use `/mncadmin` have QBCore `admin` permission (via your permissions/ACE setup) — this resource has no config file of its own to whitelist users through.

---

## 🎮 Controls & Usage

| Command | Access | Description |
|---|---|---|
| `/mncadmin` | QBCore `admin` permission | Opens the full player/job/money/vehicle/inventory admin panel |
| `/movegarage` | Everyone | Opens a simple picker to move one of your own vehicles to a different garage |

**Managing a player:** run `/mncadmin`, look up the player by name/ID/citizen ID, then use the Jobs, Money, Vehicles, or Inventory tabs to view and edit their data live.

---

## 🔧 Troubleshooting

**`/mncadmin` does nothing:**
- The server-side permission check silently no-ops for non-admins — confirm the account actually has QBCore `admin` permission

**Job removal doesn't update the player's UI:**
- The panel pushes a live sync event on removal; if it's still stale, confirm the target player is actually online and their client received `mnc-adminmenu:client:syncMultijobUI`

**`/movegarage` shows no vehicles:**
- The player must actually own at least one vehicle in the database under their citizen ID

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 2.0.0
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
- 📖 Check this README's Troubleshooting section first — most questions are answered above

---

## ⚠️ Important Notes

1. **No config file**: access is controlled entirely through QBCore's `admin` permission — there's no `AllowedJobs`-style whitelist to edit
2. **Database**: no dedicated tables — reads and writes go straight through QBCore/oxmysql against existing player/vehicle data
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Everything an admin needs, one panel away. 🛡️**
