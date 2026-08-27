# 📋 MNC Price Sheets

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

A configurable, catalog-style price sheet board for any business location — mechanic shops, restaurants, pharmacies, armories, stores, anything with a menu of items and prices. Players press E at a marked location to view a themed, categorized catalog with item images and descriptions; authorized job members can apply live discounts and post special-offer bundles that everyone sees instantly.

---

## ✨ Key Features

### 🛒 Categorized Catalog Display
- Each price sheet location has its own name, theme color, categories (with Font Awesome icons), and item list — items carry a name, price, image, and description
- Ships with a full ready-to-use **Auto Exotics Parts & Services** sheet (14 categories covering tools, repair kits, engine/transmission/brake tiers, body parts, cosmetics, wheels, interior, and workshop props) plus commented-out examples for a restaurant, police armory, pharmacy, and 24/7 store
- Optional map blip per location, and `jobs = {}` for public access or a job list to restrict who can even view the sheet

### 🎨 Per-Location Theming
- Choose a theme (`blue`, `red`, `green`, `purple`, `orange`) per sheet — colors the prompt, header, and accents to match the business
- Watermark image support (`Config.WatermarkImagePath`) so each sheet can show its own shop branding

### 💸 Live Discounts
- `Config.DiscountPermissions` grants specific job grades the ability to apply a percentage discount (capped by `Config.MaxDiscountPercent`) to a sheet in real time
- Discounts apply instantly for every player viewing or opening that sheet afterward — no restart needed

### 🎁 Special Offers
- Authorized staff can post bundled special offers (name, description, original price, sale price, image) directly onto a sheet from in-game, in addition to whatever ships in `config.lua`

### 📍 Proximity Prompt, Not a Command
- A ground marker appears within 5m of a configured location; within 2m a themed **"[E] View <Sheet Name>"** prompt appears — press **E** to open
- No admin command needed for players — it's purely a walk-up-and-view interaction

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| qb-inventory | Latest | ⚠️ Optional — only for `Config.InventoryImagePath` item-image lookups |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-pricesheets/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure mnc-pricesheets
```

No database setup required — sheets, discounts, and special offers are held in memory and defined in `config.lua` (discounts/offers applied live in-game reset back to config values on resource restart).

### 3️⃣ Configure Settings

Edit `config.lua` to add your own price sheet locations, categories, and items, and to set which job grades can apply discounts.

---

## ⚙️ Configuration Guide

```lua
Config = {}

Config.Debug = true

Config.InventoryImagePath = "nui://qb-inventory/html/images/"
Config.WatermarkImagePath = "nui://mnc-pricesheets/html/images/"

Config.DiscountPermissions = {
    ['autoexotics'] = {3, 4},   -- job = { grades allowed to apply discounts }
}

Config.MaxDiscountPercent = 50

Config.PriceSheets = {
    {
        name = "Auto Exotics Parts & Services",
        location = vector3(544.76, -199.0, 54.51),
        theme = "blue",
        jobs = {},                     -- {} = public, or list job names to restrict
        watermark = "autoexotics.png",
        categories = {
            {
                name = "Tools & Equipment",
                icon = "fa-toolbox",
                items = {
                    { name = "OBD Scanner", item = "obd_scanner", price = 200, image = "obd_scanner.png", description = "Diagnostic scanner" },
                    -- ...
                }
            },
            -- more categories...
        },
        specialOffers = {
            { name = "Stancing Bundle", description = "Full Stance Setup", originalPrice = 3000, salePrice = 2750, image = "stancerkit.png" },
        }
    },
    -- Add as many locations as you want — restaurant, armory, pharmacy,
    -- and 24/7 store templates are included commented-out for reference
}
```

- `blip` is optional per sheet — omit it or set `enabled = false` for an unmarked location
- Item `image` files are expected in `html/images/` — add your own PNGs there to match new items you define

---

## 🎮 Controls & Usage

| Input | Description |
|---|---|
| Walk within 5m of a price sheet location | Ground marker appears |
| **E** within 2m | Opens the catalog for that location |
| **Esc** | Closes the catalog |

**Applying a discount or posting a special offer (authorized staff):** open the sheet, use the in-menu management controls — visible only to job grades listed in `Config.DiscountPermissions` for that sheet's job(s).

---

## 🔧 Troubleshooting

**Prompt never appears at a location:**
- Confirm the `location` vector3 in `Config.PriceSheets` is accurate, and that you're within 5m

**Discount option isn't visible:**
- Your job and grade must be listed under `Config.DiscountPermissions` for that specific job — grade alone on an unlisted job won't show it

**Item images don't show:**
- Confirm the referenced `.png` exists in `html/images/`, or check `Config.InventoryImagePath` if pulling from your inventory resource's image folder

**Discounts/offers reset after a restart:**
- Expected — live changes are in-memory only; bake anything permanent into `config.lua`'s `specialOffers`/pricing directly

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

1. **Database**: none required — this is a config/memory-driven display resource
2. **Persistence**: in-game discounts and special offers reset to `config.lua` values on resource restart
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Post the menu, price it right, and let the shop sell itself. 📋**
