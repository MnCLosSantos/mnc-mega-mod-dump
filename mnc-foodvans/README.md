# 🍔 MNC Food Vans

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.3.6-brightgreen.svg)]()

---

## 🌟 Overview

A **realistic food van / street food business system** for QBCore-based FiveM servers. Players can purchase, own, staff, and operate mobile food vans across Los Santos and Blaine County. Features include purchasable locations, crafting recipes, customer NPCs, ingredient ordering, payment requests, and a van safe system.

Built with performance, realism, and roleplay in mind.

---

## ✨ Key Features

### 🛒 Purchaseable Locations
- **20+ predefined locations** (Hotdog stands, Burger stands, Food Vans, Coffee vendors)
- One-time purchase with configurable prices
- Persistent ownership stored in database
- Owner can sell location back at any time

### 👥 Staff Management
- Owner can add/remove staff members by Citizen ID
- Staff can open/close the van, craft, order ingredients, and request payments
- Authorised list saved in database

### 🍔 Crafting System
- Multiple recipes per van type (Hotdogs, Burgers, Sides, Drinks, Coffee, etc.)
- Ingredient checks before crafting
- ox_lib context menus with confirmation dialogs
- Automatic item removal and addition

### 👤 NPC Customers
- Realistic pedestrian customers automatically spawn near open vans
- Customers walk to the van and request random menu items
- Owner/staff can confirm sale, deny, or make them wait
- 10% of sale goes directly to owner’s bank, 90% to van safe
- Configurable spawn radius and max customers per van

### 💰 Economy & Payments
- **Request Payment** feature (send invoices to any player ID)
- Self-charge option for quick sales
- **Van Safe** system – 90% of NPC sales stored safely
- Owner-only safe withdrawal to bank
- Ingredient ordering with delivery courier

### 📦 Ingredient Delivery
- Order ingredients in batches from a clean ox_lib menu
- Delivery ped spawns and performs handoff animation
- Items automatically added to player inventory after delivery

### 🔄 Auto Close System
- Vans automatically close if owner and all staff are too far away
- Prevents leaving vans open when offline or away

### 🎯 Target & UI
- Full qb-target integration with smart canInteract checks
- ox_lib alerts, inputs, and context menus throughout
- 3D text above vans showing price / open / closed status
- Dynamic blips (always visible + open indicator)

---

## 📋 Requirements

| Dependency       | Version | Required |
|------------------|---------|----------|
| QBCore Framework | Latest  | ✅ Yes   |
| qb-inventory     | Latest  | ✅ Yes   |
| qb-target        | Latest  | ✅ Yes   |
| ox_lib           | Latest  | ✅ Yes   |
| oxmysql          | Latest  | ✅ Yes   |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource into your resources folder:
```
[server-data]/resources/[custom]/mnc-foodvans/
```

### 2️⃣ Database Setup

The script **automatically creates** the required table on first start:
- `mnc_foodvans` – Stores ownership, open status, staff, and safe balance

No manual SQL needed.

### 3️⃣ Add to Server Config

```lua
ensure oxmysql
ensure mnc-foodvans
```

### 4️⃣ Add Items

Add all items from `items.txt` (or the provided list) to your `qb-core/shared/items.lua`.

Example:
```lua
['van_hotdog_classic'] = {
    ['name'] = 'van_hotdog_classic',
    ['label'] = 'Classic Hotdog',
    ['weight'] = 200,
    ['type'] = 'item',
    ['image'] = 'van_hotdog_classic.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A classic hotdog.'
},
```

**Note:** You will also need the corresponding `.png` images in your inventory image folder.

### 5️⃣ Configure Settings

Edit `config.lua` to customize:

- Van locations & prices
- Recipes per prop type
- Ingredient prices & batch sizes
- NPC customer behavior
- Payment limits
- Debug mode

---

## ⚙️ Configuration Highlights

### Van Locations
Multiple categories (Hotdog, Burger, Food Van, Coffee) with custom props and zOffsets.

### Recipes
Fully configurable per prop model with multiple ingredients and output amounts.

### Customer Sale Prices
Set how much each crafted item sells for to NPC customers.

### Key Settings
```lua
Config.Debug = false
Config.PaymentAccount = 'cash'
Config.MaxPayment = 500
Config.CustomerSpawnRadius = 75.0
Config.StallCloseRadius = 100.0
```

---

## 🎮 Controls & Usage

### Owner / Staff Actions
- **Purchase** a location when it shows "FOR SALE"
- **Open / Close** the van
- **Craft Food** using available ingredients
- **Order Ingredients** (delivery arrives in ~45 seconds)
- **Request Payment** from nearby players
- **Manage Staff** & withdraw from van safe (owner only)
- **Sell Location** to recover safe funds

### NPC Customer Flow
1. Open your van
2. Customers automatically approach
3. Accept or deny their order
4. Money splits: 10% to bank, 90% to van safe

### Payment System
- Use "Request Payment" → Enter player ID + amount + reason
- Customer receives clean confirmation dialog
- Payment splits between worker and van safe

---

## 🔧 Troubleshooting

**Van not appearing?**
- Ensure qb-target is running
- Check server console for database errors
- Restart resource after adding to server.cfg

**Items not showing in craft menu?**
- Verify items are added to qb-core/shared/items.lua
- Check that recipe ingredients exist in Config.OrderableIngredients

**Delivery not spawning?**
- Make sure the delivery ped model is valid
- Check Config.DeliveryPedModel

**Safe balance not updating?**
- Confirm oxmysql is working correctly
- Check for errors when NPC sales occur

---

## 📝 Credits

**Author**: Stan Leigh  
**Version**: 1.3.6  
**Framework**: QBCore  

### Contributing
Contributions are welcome! Fork the repository, create a feature branch, and submit a pull request.

---

## 📞 Support

For support, bug reports, or feature requests:
- Open an issue on GitHub
- Check the included readme.txt and items.txt files

---

## 🔄 Changelog

### Version 1.3.6 (Current)
**New Features:**
- ✨ Full NPC customer system with walking, ordering, and interaction
- ✨ Payment request / invoice system with self-charge support
- ✨ Van safe system (90% of NPC & invoice sales stored)
- ✨ Owner-only safe withdrawal
- ✨ Auto-close system when staff are out of range
- ✨ Ingredient delivery with ped handoff animation
- ✨ Dynamic blips (always + open status)

**Improvements:**
- 🔧 ox_lib menus and alerts throughout
- 🔧 Better ownership and authorisation checks
- 🔧 Improved prop spawning with raycasting and zOffset support
- 🔧 Staff management menu with safe balance display

**Bug Fixes:**
- 🐛 Fixed multiple prop spawning issues
- 🐛 Resolved inventory and money handling edge cases
- 🐛 Improved target zone refreshing

---

**Enjoy running your own street food empire on your FiveM server! 🍔🌭☕**