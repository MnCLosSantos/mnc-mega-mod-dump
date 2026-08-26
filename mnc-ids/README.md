# 🆔 MNC ID Check System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.1.0-brightgreen.svg)]()

---

## 🌟 Overview

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

## 📞 Support & Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBs...)

---

## 📜 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
