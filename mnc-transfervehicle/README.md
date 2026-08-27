# 📄 MNC Vehicle Transfer

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
A proper pink-slip style ownership transfer system for QBCore. Instead of a bare `/givecar`-style handoff, the seller fills out a document (buyer, sale amount) through an NUI form, the buyer has to actually review and digitally sign it, and both parties end up holding a permanent, reviewable `vehicletransdocument` item recording the sale — price, date, signature, and payment method included. Money and ownership only change hands once the buyer accepts.

---

## ✨ Key Features

### 📝 Seller-Initiated Document
- `/transfervehicle [ID] [amount]` while sitting in the vehicle you want to sell opens an NUI form pre-filled with the vehicle's plate
- Looks up the vehicle's `player_vehicles` row to confirm you actually own it
- If `Config.PreventFinanceSelling` is enabled (default), vehicles with an outstanding finance balance can't be listed for transfer at all

### 🤝 Buyer Review & Signature
- The seller sends the completed document to a specific buyer, who must be within `Config.TransferDistance` (default 5.0m)
- The buyer sees an approval UI with the vehicle details and sale amount and must **digitally sign** to accept — signatures are always required (`Config.SignatureRequired`)
- The buyer can deny the transfer instead, cancelling it for both parties

### 💰 Safe Payment Handling
- On acceptance, the buyer is charged automatically from cash if they have enough, falling back to bank if not — the transfer is rejected with a clear error if neither covers the full amount
- Ownership (`citizenid` + `license`) is only updated in `player_vehicles` after payment succeeds, and vehicle keys are handed to the buyer via `vehiclekeys:client:SetOwner`

### 🧾 Permanent Paper Trail
- Both the seller and the buyer receive a copy of the completed `vehicletransdocument` item once the sale finalizes, recording price, both parties, the buyer's signature, payment method, and completion date
- Using the item again later re-opens it as a read-only document viewer through the same NUI

### ⏳ Auto-Expiring Offers
- A pending transfer that the buyer never responds to expires automatically after `Config.DocumentExpiration` (default 5 minutes / 300000ms), so stale offers don't linger indefinitely

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes (notifications) |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-transfervehicle/
```

### 2️⃣ Register the Item

Add a `vehicletransdocument` item to your `qb-core` shared items (e.g. `qb-core/shared/items.lua`) so it can be given to both parties on completion:

```lua
['vehicletransdocument'] = { name = 'vehicletransdocument', label = 'Vehicle Transfer Document', weight = 10, type = 'item', image = 'document.png', unique = true, useable = true, shouldClose = true, description = 'Proof of a vehicle sale' },
```

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure oxmysql
ensure mnc-transfervehicle
```

No custom database table is required — the script reads and updates the existing `player_vehicles` table directly.

### 4️⃣ Configure Settings

Edit `config.lua` to adjust finance protection, expiration time, and required buyer proximity.

---

## ⚙️ Configuration Guide

```lua
Config = {}

-- Enable debug prints in F8 console and server console
Config.Debug = false

-- Prevent selling vehicles with outstanding finance balance
Config.PreventFinanceSelling = true

-- Require signature before transfer completes (always required for this system)
Config.SignatureRequired = true

-- Time in milliseconds before transfer expires (buyer must accept within this time)
-- Default: 300000 = 5 minutes
Config.DocumentExpiration = 300000

-- Maximum distance between seller and buyer in meters
-- Buyer must be within this distance when seller initiates the transfer
Config.TransferDistance = 5.0
```

---

## 🎮 Controls & Usage

| Command | Description |
|---------|-------------|
| `/transfervehicle [ID] [amount]` | Open the seller UI for the vehicle you're currently in; both arguments are optional and can be filled in from the form instead |

**Completing a sale:**
1. Seller sits in the vehicle to sell and runs `/transfervehicle`, filling in the buyer's ID and sale amount
2. Buyer (must be within `Config.TransferDistance`) receives the offer and reviews it in their own UI
3. Buyer signs to accept, or denies to cancel
4. On acceptance, payment is deducted from the buyer, ownership transfers in `player_vehicles`, keys are handed over, and both parties receive a `vehicletransdocument` recording the sale

---

## 🔧 Troubleshooting

**"You must be in a vehicle" when running the command:**
- The seller must be seated in the exact vehicle being sold when the command runs — the plate is read directly from that vehicle

**"Cannot sell a financed vehicle":**
- The vehicle's `player_vehicles.balance` is greater than 0; either pay off the finance first or set `Config.PreventFinanceSelling = false` if your server doesn't use finance/loans

**Buyer never receives the offer:**
- Confirm the buyer is within `Config.TransferDistance` of the seller at the moment the seller sends the document — moving apart before sending will fail the proximity check

**Transfer silently expires:**
- The buyer has `Config.DocumentExpiration` milliseconds to respond; raise this value if your players need more time to review

**"Insufficient funds" on accept:**
- The buyer's cash and bank balances are checked at the moment of acceptance, not when the offer was sent — funds spent in between can cause this

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

## 📞 Support & Community

- 💬 **Discord**: [![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6) — join for support, bug reports, and update announcements
- 🐛 **Issues**: open an issue on the [mnc-mega-mod-dump GitHub repo](https://github.com/MnCLosSantos/mnc-mega-mod-dump/issues)
- 📖 Check this README's Configuration Guide and Troubleshooting sections first — most questions are answered above

---

## ⚠️ Important Notes

1. **Item registration**: The `vehicletransdocument` item must be added to your shared items before this script can hand out or reopen sale documents (see Installation)
2. **Database**: Requires oxmysql — reads/writes directly against your existing `player_vehicles` table, no separate table is created
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Sign it, seal it, hand over the keys. 📄**
