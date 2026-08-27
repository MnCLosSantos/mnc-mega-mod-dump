# 🔇 MNC Mute when Dead

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![pma-voice](https://img.shields.io/badge/Voice-pma--voice-orange.svg)](https://github.com/AvarianKnight/pma-voice)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

This script automatically **mutes players when they are dead or in last stand** using **QBCore** metadata and **pma-voice**.  
It ensures that players cannot talk while incapacitated, improving RP immersion.

---

## ✨ Key Features

- 🔇 **Automatic Muting**  
  - Mutes voice when `isdead` or `inlaststand` metadata is set.  
  - Automatically unmutes when revived.  

- ⚡ **Optimized Loop**  
  - Checks player state every **1 second** (lightweight).  

- 🎮 **Plug & Play**  
  - No commands required.  
  - Works seamlessly with QBCore + pma-voice.  

---

## 📋 Requirements

```bash
Dependency             Version   Required
---------------------- --------- ----------
QBCore Framework       Latest    ✅ Yes
pma-voice              Latest    ✅ Yes
```

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-muteondeath/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure mnc-muteondeath
```

---

## ⚙️ Configuration

No configuration required.  
The script automatically detects `isdead` and `inlaststand` states from QBCore metadata.

---

## 📞 Support & Community

- 💬 **Discord**: [![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6) — join for support, bug reports, and update announcements
- 🐛 **Issues**: open an issue on the [mnc-mega-mod-dump GitHub repo](https://github.com/MnCLosSantos/mnc-mega-mod-dump/issues)
- 📖 Check this README's Configuration Guide and Troubleshooting sections first — most questions are answered above

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

