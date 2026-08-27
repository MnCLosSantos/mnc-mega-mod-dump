# 💥 MNC Seize Car v2 - Vehicle Removal Commands for QBCore

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.4.7-brightgreen.svg)]()

---

## 🌟 Overview

**MNC SeizeCar** is a lightweight yet powerful administrative and law-enforcement tool for QBCore FiveM servers. It provides clean, user-friendly commands to remove or seize individual vehicles, wipe all vehicles from a specific player, or perform a full server-wide vehicle database wipe.

Built with **ox_lib** for modern dialogs and notifications, and fully integrated with **oxmysql**, this script offers both admin-level destructive tools and job-restricted seizure functionality for police/mechanic roles.

---

## ✨ Key Features

### 🗑️ Vehicle Removal Commands
- **`/removecar`** – Remove a single vehicle by Player Server ID + Plate (Admin only)
- **`/removeallcars`** – Delete **ALL** vehicles belonging to a player (Admin only)
- **`/removeallcarsfromserver`** – **DANGER**: Full server vehicle wipe (Admin only with confirmation)

### 🚔 Job-Restricted Seizure
- **`/seizecar`** – Seize a specific vehicle (Restricted to configured jobs like Police)
- Notifies the vehicle owner (if online) with officer name and job
- Clean deletion from the `player_vehicles` table

### 🎨 UI
- **ox_lib** input dialogs and alert confirmations
- Danger-zone warnings for irreversible actions
- ox_lib notifications
- Automatic plate formatting (uppercase, no spaces)

### 🔒 Security & Safety
- Strict permission checks (admin/god for removal commands)
- Job whitelist for seizure command
- Double confirmation for mass deletion and server wipe
- Input validation and error handling

---

## 📋 Requirements

| Dependency     | Version | Required |
|----------------|---------|----------|
| QBCore Framework | Latest  | ✅ Yes   |
| ox_lib         | Latest  | ✅ Yes   |
| oxmysql        | Latest  | ✅ Yes   |

---

## 🚀 Installation

### 1️⃣ Download & Place

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-seizecar/
```

### 2️⃣ Add to Server Config

Add the following line to your `server.cfg`:

```lua
ensure mnc-seizecar
```

**Make sure** the following are started **before** this resource:
```lua
ensure qb-core
ensure ox_lib
ensure oxmysql
```

---

## 🎮 Commands

| Command                   | Description                                      | Permission / Job      |
|---------------------------|--------------------------------------------------|-----------------------|
| `/removecar`              | Remove one vehicle by ID + Plate                 | Admin / God           |
| `/removeallcars`          | Remove **ALL** vehicles from a player            | Admin / God           |
| `/removeallcarsfromserver`| **WIPE** every vehicle on the server             | Admin / God           |
| `/seizecar`               | Seize a player's vehicle (roleplay tool)         | Configured Jobs       |

---

## ⚙️ How It Works

1. **Admins** type a command → ox_lib dialog appears
2. Enter **Player Server ID** and **Vehicle Plate**.
3. For mass/server wipes → Extra confirmation dialogs
4. Vehicle is permanently deleted from `player_vehicles` table
5. For `/seizecar`: Only allowed jobs can use it, and the owner receives a notification

**Note**: This script only removes vehicles from the database. It does **not** delete currently spawned vehicles on the map.

---

## 🔧 Configuration

The only configurable part is the seizure job list in `server.lua`:

```lua
Config = {
    SeizeCarJob = { ['police'] = true, ['mechanic'] = false, ['mechanic2'] = false },  -- Add more jobs here if needed
}
```

Add or remove jobs as needed for your server.

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.4.7
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

### Version 1.4.7 (Current)
**Improvements:**
- Updated to use latest ox_lib input and alert dialogs
- Added proper plate formatting (uppercase, no spaces)
- Enhanced safety confirmations for destructive actions
- Improved notifications and feedback
- Better error handling and input validation

**Bug Fixes:**
- Fixed potential issues with player not found checks
- Improved citizenid lookup 
- Cleaner code structure and comments

---

**Enjoy safe and easy vehicle management on your server!** 🗑️🚗
