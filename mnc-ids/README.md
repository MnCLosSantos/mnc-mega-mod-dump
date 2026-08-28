# 🆔 MNC ID Check System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.1.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

An **ID checking system** for FiveM servers (QBCore compatible).  
Players can press a key (default **Z**) to show their **server ID** above their head and notify nearby players with a ui saying ids are being checked.  
Includes a **cooldown system**, **duration timer**, and **NUI notifications**.

---

## ✨ Key Features

- 🆔 **Display Server IDs**  
  - Show your own ID above your character.  
  - See nearby players’ IDs within range.  

- ⏳ **Duration & Cooldown**  
  - IDs visible for a set time (default **30s**).  
  - Built-in cooldown before requesting again.  

- 📢 **Nearby Notifications**  
  - Sends a UI notification to players within range.  
  - Informs them that their ID has been requested.  

- 🎨 **NUI Interface**  
  - Clean HTML/CSS/JS frontend for messages.  

---

## 📋 Requirements

```bash
Dependency             Version   Required
---------------------- --------- ----------
QBCore Framework       Latest    ✅ Yes
```

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-ids/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure mnc-ids
```

---

## 🧩 How It Works

1. Press **Z key** to trigger an ID check.  
2. Your own ID appears above your head for **30s**.  
3. Nearby players within **25m** are notified.  
4. They see a UI popup and their own ID above their head.  
5. After 30s → IDs disappear automatically.  
6. **Cooldown prevents spam** (30s).  

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
- 📖 Check this README's How It Works section first — most questions are answered above

---

## ⚠️ Important Notes

1. **No database required**: this is a pure client/NUI resource with no persistence
2. **Compatibility**: QBCore only — not compatible with ESX
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Check IDs at a glance. 🆔**

