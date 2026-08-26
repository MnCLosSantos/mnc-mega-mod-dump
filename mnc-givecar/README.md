# 🚗 MNC GiveCar System
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.3.1-brightgreen.svg)]()

---

## 🌟 Overview

The **MNC GiveCar System** allows admins or automated systems (like Tebex) to **instantly grant vehicles to players**.
It automatically detects the installed **garage system**, supports all modern **QBCore** builds, and adapts to your `player_vehicles` table automatically — even if it doesn’t include the `mileage` column.

Vehicles are saved to the player’s garage with:

* ✅ Full fuel and health
* ✅ Zero mileage
* ✅ Default detected garage
* ✅ Auto-generated license plate

---

## ✨ Key Features

* 🧠 **Automatic Garage Detection**

  * Works with:

    * `qb-garages`
    * `cdn-garage`
    * `jg-advancedgarages`
  * Fallback to **pillboxgarage** if unknown.

* 🔢 **Auto Plate Generation**

  * Automatically creates a random **8-character alphanumeric**.

* 💾 **Smart DB Compatibility**

  * Dynamically checks for the `mileage` column and adjusts the SQL query automatically.

* ⚙️ **Full Vehicle Condition**

  * Full fuel (`100%`), engine health (`1000`), and body health (`1000`).

* 📢 **Custom ox_lib Notifications**

  * Sender sees confirmation for **15 seconds**.
  * Receiver sees confirmation for **4 minutes**.

* 🧩 **Tebex-Ready**

  * Supports console or chat commands from Tebex reward actions.

---

## 📋 Requirements

| Dependency        | Version   | Required |
| ----------------- | --------- | -------- |
| QBCore Framework  | Latest    | ✅        |
| oxmysql           | Latest    | ✅        |
| ox_lib            | Latest    | ✅        |
| Any Garage System | Supported | ✅        |

---

## 🚀 Installation

### 1️⃣ Download & Install

```bash
git clone https://github.com/MnCLosSantos/mnc-givecar.git
```

Or download and extract the ZIP into:

```
[server-data]/resources/[scripts]/mnc-givecar
```

---

### 2️⃣ Add to Server Config

```lua
ensure oxmysql
ensure ox_lib
ensure mnc-givecar
```

---

### 3️⃣ Command Usage

```bash
/givecar [playerID] [vehicleModel]
```

#### 🧰 Examples

```bash
/givecar 1 adder
/givecar "ID" "SPAWNCODE"
```

* A plate will be **generated automatically**.
* Vehicle is saved into the **default detected garage** (e.g., pillboxgarage or A).

---

### 4️⃣ Tebex Integration (Donations)

Add Tebex package commands like:

```bash
say Thank you for supporting MnC!
givecar {{sid}} adder
say A player has received their donation car!
```

This automatically gives the vehicle when the Tebex purchase completes.

---

### 🏁 Garage Detection Logic

| Garage System      | Default Garage |
| ------------------ | -------------- |
| qb-garages         | pillboxgarage  |
| cdn-garage         | A              |
| jg-advancedgarages | pillboxgarage  |
| Unknown/Fallback   | pillboxgarage  |

The script auto-detects which garage is active on startup — no config needed.

---

## 🧠 Developer Notes

* Works with both `license` and `citizenid` identifiers.
* Auto-detects DB schema (mileage or no mileage).
* Inserts clean, valid entries into `player_vehicles`.
* Fully compatible with `ox_lib` notification system and Tebex.

---

## 📞 Support & Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Support%20Server-7289da?style=for-the-badge\&logo=discord\&logoColor=white)](https://discord.gg/aTBsSZe5C6)
