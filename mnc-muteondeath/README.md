# 🔇 MNC Mute when Dead

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
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
[server-data]/resources/[custom]/mnc-deadmute/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure mnc-deadmute
```

---

## ⚙️ Configuration

No configuration required.  
The script automatically detects `isdead` and `inlaststand` states from QBCore metadata.

---

## 📞 Support & Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBs...)

---

## 📜 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
