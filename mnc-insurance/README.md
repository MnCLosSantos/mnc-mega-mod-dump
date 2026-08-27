# 🚔 MNC Insurance, Registration & Inspection

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.2.0-brightgreen.svg)]()

---

## 🌟 Overview

A full vehicle paperwork system covering three separate documents — **insurance**, **registration**, and **inspection** — each priced by vehicle category and modification tier, each with its own purchase and lookup commands, and each persisted per-plate in the database. Emergency-category vehicles are automatically underwritten by "LosSantosGov" instead of the standard "MNC" insurer.

---

## ✨ Key Features

### 🛡️ Insurance
- Cost is calculated from the vehicle's category, its modification tier (1–5, auto-detected from installed performance mods and clamped to that range), business-use status, plus fees, processing fee, and tax
- A configurable per-company premium rate is applied on top of the subtotal (`insuranceCompanyPremiums`) — emergency-category vehicles are automatically insured by **LosSantosGov** rather than the standard **MNC** company
- Renewing an already-insured, non-expired vehicle carries its existing mod tier and insurer forward rather than re-pricing from scratch

### 📝 Registration & 🔍 Inspection
- Separate, independently-priced registration and inspection documents per vehicle, each with their own purchase and status-check commands
- All three document types record the plate, citizen ID, player name, vehicle category/name/colors, and relevant date fields

### 📅 Expiry-Based Validity
- Insurance and registration store `startDate`/`endDate` (or a registration date) using your configured `Config.DateFormat` (`'USA'` or a custom format)
- Checking a vehicle's status reports whether each document is currently valid, expired, or never purchased

### 🖥️ In-Vehicle NUI Lookups
- Every purchase and check command opens a themed NUI panel (with the resource's own logo branding) rather than a plain chat message
- `/checkvehdocs` gives a single combined view of insurance, registration, and inspection status for the vehicle you're in

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

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-insurance/
```

### 2️⃣ Database Setup

Import `install/create_tables.sql` (a plain-text copy is also provided at `install/manualEntry/create_tables.txt` for servers that need to paste it into a GUI tool). It creates three tables:

- `insured_vehicles`
- `registered_vehicles`
- `inspected_vehicles`

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure mnc-insurance
```

### 4️⃣ Configure Settings

Edit `config.lua` to set your preferred date format:

```lua
Config.DateFormat = 'USA'
```

---

## 🎮 Controls & Usage

| Command | Description |
|---|---|
| `/insurance` | Purchase or renew insurance for the vehicle you're in |
| `/checkinsurance` | Check insurance status for the vehicle you're in |
| `/registration` | Purchase registration for the vehicle you're in |
| `/checkregistration` | Check registration status |
| `/inspection` | Purchase an inspection for the vehicle you're in |
| `/checkinspection` | Check inspection status |
| `/checkvehdocs` | Combined insurance + registration + inspection status in one view |

**Buying insurance:** enter your vehicle, run `/insurance`, review the calculated cost (category + mod tier + business surcharge + fees/tax), and confirm. Emergency-category vehicles are automatically priced and insured under LosSantosGov instead of MNC.

---

## 🔧 Troubleshooting

**Insurance price seems too high/low:**
- Cost scales with modification tier (1–5) as well as vehicle category and business-use status — check `modTierPrices` and `insuranceCompanyPremiums` in `server.lua` if you've customized pricing

**Wrong insurer shown for an emergency vehicle:**
- Emergency-category vehicles are hard-coded to LosSantosGov — confirm the vehicle's category is correctly classified as emergency in your vehicle data

**Status check shows "not insured" for a vehicle you just paid for:**
- Confirm oxmysql is connected and the plate matches exactly — insurance is looked up by plate, so a plate change after purchase will show as unregistered

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.2.0
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

1. **Database**: Requires oxmysql — import `install/create_tables.sql` before first start (no auto-creation)
2. **Known open issues** (per the resource's own dev TODO list): the status-check UI can show a stale player name when a vehicle isn't insured, the UI can misbehave if you move away from the vehicle mid-check, and vehicle name display has known edge cases — treat these as cosmetic rough edges rather than blocking bugs, and verify document status server-side if you build anything that depends on it
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS
5. **Related resource**: [`mnc-rentals`](../mnc-rentals) can optionally grant temporary insurance/registration/inspection using this resource's own tables — install this resource first if you want that integration

---

**Get legal, stay legal. 🚔**
