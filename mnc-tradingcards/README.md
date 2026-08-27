# 🃏 MNC Trading Cards System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.3.0-brightgreen.svg)]()

---

## 🌟 Overview

A **fully-featured collectible trading card system** for QBCore-based FiveM servers. Players can open randomised card packs, collect cards across themed sets, store them in binders, and sell them to the in-world card dealer. Complete with a polished NUI, holographic rarity effects, misprint mechanics, a persistent database, and a set-completion bonus system.

---

<img width="1920" height="1080" alt="Screenshot (108)" src="https://github.com/user-attachments/assets/dc3e36c5-50e6-4661-a7ea-1d90dc57dfbf" />

<img width="1920" height="1080" alt="Screenshot (109)" src="https://github.com/user-attachments/assets/e3a72b6a-2a59-4582-b78c-c3f6ef5fdce4" />

<img width="1920" height="1080" alt="Screenshot (110)" src="https://github.com/user-attachments/assets/c7cadbe8-8a0d-4b1d-9a90-24507ae0cb79" />

<img width="1920" height="1080" alt="Screenshot (111)" src="https://github.com/user-attachments/assets/3fd499db-159f-4bb0-8827-161014eab9af" />

<img width="1920" height="1080" alt="Screenshot (112)" src="https://github.com/user-attachments/assets/6e820298-c3b6-4012-a713-dec1159e081d" />

<img width="1920" height="1080" alt="Screenshot (113)" src="https://github.com/user-attachments/assets/27471155-4a54-4581-bd63-8f47cac0d1d1" />

<img width="1920" height="1080" alt="Screenshot (114)" src="https://github.com/user-attachments/assets/1a7c3755-0119-46ed-b971-38c2cb4c7735" />

<img width="1920" height="1080" alt="Screenshot (115)" src="https://github.com/user-attachments/assets/3831ad1e-f56b-4d8c-ac08-d6ed527bc3ef" />

<img width="1920" height="1080" alt="Screenshot (116)" src="https://github.com/user-attachments/assets/00803f07-3f94-42f4-9539-9210d28985d6" />

<img width="1920" height="1080" alt="Screenshot (117)" src="https://github.com/user-attachments/assets/778cc035-f50d-43c9-acb3-be2d7b8e0d71" />

<img width="1920" height="1080" alt="Screenshot (118)" src="https://github.com/user-attachments/assets/3f579d47-cf89-4b9f-a88f-5ece522f99e5" />

<img width="1920" height="1080" alt="Screenshot (119)" src="https://github.com/user-attachments/assets/a22b3c1e-88da-4e3f-94fa-e4f96942a1ac" />

<img width="1920" height="1080" alt="Screenshot (120)" src="https://github.com/user-attachments/assets/bef0c05c-88be-40c5-9117-9a62648647a7" />

<img width="1920" height="1080" alt="Screenshot (121)" src="https://github.com/user-attachments/assets/a2c7bd9b-2536-47d3-a148-a8359f1dd7a4" />

<img width="1920" height="1080" alt="Screenshot (122)" src="https://github.com/user-attachments/assets/85f2dfd6-d1d1-4b22-8873-86cb7c9281e4" />

<img width="1920" height="1080" alt="Screenshot (123)" src="https://github.com/user-attachments/assets/f7d098f3-8611-439b-bbd3-488076b96b99" />

<img width="1920" height="1080" alt="Screenshot (124)" src="https://github.com/user-attachments/assets/159952c7-ae54-421d-85a2-6c72c6db89d1" />

<img width="1920" height="1080" alt="Screenshot (125)" src="https://github.com/user-attachments/assets/e74ce9f3-c3ba-424e-bd37-af6a1f2225e6" />

<img width="1920" height="1080" alt="Screenshot (126)" src="https://github.com/user-attachments/assets/fb0a978d-04e6-4b52-a2a3-37471572927a" />

<img width="1920" height="1080" alt="Screenshot (127)" src="https://github.com/user-attachments/assets/7c8eaae9-aa35-47a0-aee7-2ae8d3922399" />

---

## ✨ Key Features

### 📦 Pack Opening System
- **Three pack tiers** — Basic, Premium, and Legendary — each with configurable card counts and rarity weights
- **Interactive tear animation** with a drag-to-open mechanic and progress indicator
- **Sequential card reveal** — click each card individually to flip and reveal it
- **Misprint cards** — rare alternate variants with their own rarity tier and higher value
- **Damaged cards** — low-value cards that can be discarded for a small payout

### 🎴 Card Collection & Rarity
- **Six rarity tiers**: Common, Uncommon, Rare, Ultra Rare, Misprint, and Damaged, each with a unique colour and value
- **Holographic sheen** on Rare, Ultra Rare, and Misprint cards
- **Per-card print numbering** — a global counter tracks how many of each card have ever been created, so low print numbers carry real prestige
- **Custom image support** — cards can use GTA V vehicle CDN images or your own custom artwork
- **Multi-source vehicle images** — vehicle cards resolve their picture through a configurable fallback chain (FiveM Docs CDN → GitHub image stores), so addon/custom vehicles missing from the official CDN can still show real artwork
- **Custom backgrounds** per card or per set for full visual flexibility

### 📚 Card Binder
- **Physical binder UI** with a spine, rings, and a set contents panel
- **Drag cards in and out** of binder slots directly from the inventory
- **Set progress tracking** — shows how many cards of each set you've collected
- **Drag-to-remove zone** at the top of the binder page to return cards to your inventory
- **Persistent storage** — binder contents survive restarts via the database

### 🏪 Card Dealer Shop (NPC)
- **Ambient dealer NPC** spawned at a configurable world location with a map blip
- **E-key interaction prompt** when the player is within range
- **Sell individual cards** — select any combination from your inventory and see a live price total before confirming
- **Sell an entire set at once** for a configurable set-completion bonus multiplier
- **Configurable sell multiplier** applied to each card's base rarity value

### 🛠️ Card Creator Panel (Admin)
- **`/cardcreator`** — full NUI panel for building and editing card sets at runtime, no restart required
- **Vehicle Image Source toggle** — pick between FiveM Docs, GitHub Storage 1, or GitHub Storage 2 while browsing vehicles for a card
- **Visual image gallery** — switching to a GitHub source opens a dedicated thumbnail gallery instead of a plain text list, pulled live from that repo's actual file listing
- **Addon vehicle discovery** — the gallery isn't limited to known GTA models; any image GitHub actually has (including addon vehicles) shows up, tagged `ADDON`, with a Refresh button to re-check for newly uploaded images
- **Live card preview** as you fill out the form, and inline validation before anything is saved
- **`/cardpreview`** — read-only binder populated with every card in every set, for image and layout QA
- **`/cardgive`** — same full-catalog browser as `/cardpreview`, plus a "Give to Self" button per card

### 🗄️ Persistent Database
- **Automatic table creation** on first resource start — no manual SQL import needed
- **Three tables**: `mnc_trading_cards` (inventory cards), `mnc_binders` (binder ownership), `mnc_binder_cards` (stored cards)
- **Auto-migration** adds new columns to existing installs safely
- **Print counter persistence** — global card print counts are loaded from the database on start so numbering is accurate across restarts

### 🖥️ Polished NUI
- Custom fonts (Bebas Neue, Barlow Condensed) for an authentic card-game aesthetic
- Fully mouse-driven with ESC-key or close button support
- Modular screen system — Pack Open, Pack Reveal, Single Card View, Binder, and Shop each have their own UI layer

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

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-tradingcards/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-tradingcards/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-tradingcards/
```

### 2️⃣ Database Setup

The script **automatically creates** all required tables on first start:

- `mnc_trading_cards` — tracks every card in player inventories
- `mnc_binders` — tracks binder ownership
- `mnc_binder_cards` — tracks cards stored inside binders

No manual SQL import needed!

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure mnc-tradingcards
```

### 4️⃣ Add Items to QBCore

Add all items to `qb-core/shared/items.lua`:

```lua
-- Card Packs
['card_pack_basic'] = {
    ['name'] = 'card_pack_basic',
    ['label'] = 'Basic Card Pack',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'card_pack_basic.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A basic pack of 3 trading cards',
},
['card_pack_premium'] = {
    ['name'] = 'card_pack_premium',
    ['label'] = 'Premium Card Pack',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'card_pack_premium.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A premium pack of 5 trading cards',
},
['card_pack_legendary'] = {
    ['name'] = 'card_pack_legendary',
    ['label'] = 'Legendary Card Pack',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'card_pack_legendary.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A legendary pack with boosted rare drop rates',
},

-- The card item itself (all cards share one item name; metadata differentiates them)
['trading_card'] = {
    ['name'] = 'trading_card',
    ['label'] = 'Trading Card',
    ['weight'] = 10,
    ['type'] = 'item',
    ['image'] = 'trading_card.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A collectible trading card',
},

-- Binder
['card_binder'] = {
    ['name'] = 'card_binder',
    ['label'] = 'Card Binder',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'card_binder.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Store and display your card collection',
},
```

### 5️⃣ Configure Settings

Edit `config.lua` to customise packs, rarities, the shop location, and your card sets.

---

## ⚙️ Configuration Guide

### 🎁 Pack Configuration

```lua
Config.Packs = {
    ['card_pack_basic'] = {
        label          = 'Basic Card Pack',
        cardCount      = 3,           -- cards per pack
        weights        = { common = 70, uncommon = 27, rare = 2, ultraRare = 1 },
        misprintChance = 0.5,         -- % chance any card is a misprint
        damagedChance  = 5,           -- % chance any card is damaged
    },
    -- Add more pack types as needed
}
```

### 💎 Rarity Configuration

```lua
Config.Rarities = {
    common    = { label = 'Common',     color = '#a0a0a0', holo = false, value = 10   },
    uncommon  = { label = 'Uncommon',   color = '#4ade80', holo = false, value = 50   },
    rare      = { label = 'Rare',       color = '#60a5fa', holo = true,  value = 100  },
    ultraRare = { label = 'Ultra Rare', color = '#f59e0b', holo = true,  value = 500  },
    misprint  = { label = 'Misprint',   color = '#e040fb', holo = true,  value = 1000 },
    damaged   = { label = 'Damaged',    color = '#ef5350', holo = false, value = 5    },
}
```

### 🏪 Shop Configuration

```lua
Config.Shop = {
    coords              = vector3(-1288.06, -310.31, 36.65),
    heading             = 360.0,
    blipSprite          = 500,
    blipColor           = 5,
    blipScale           = 0.8,
    blipName            = 'Card Dealer',
    sellMultiplier      = 0.8,    -- cards sell for 80% of their base value
    setCompletionBonus  = 1.25,   -- 25% bonus when selling a complete set
}
```

### 🖼️ Vehicle Image Sources

Any card that only sets a `model` (no custom `image`) has its picture resolved from `Config.VehicleImageSources`, tried in the order given by `Config.VehicleImageSourceOrder` until one of them actually has a picture for that vehicle:

```lua
Config.VehicleImageSources = {
    fivem   = 'https://docs.fivem.net/vehicles/{model}.webp',
    github1 = 'https://github.com/YourOrg/your-vehicle-image-repo/raw/main/{model}.png',
    github2 = 'https://github.com/YourOrg/your-vehicle-image-repo-2/raw/main/{model}.png',
}
Config.VehicleImageSourceOrder = { 'fivem', 'github1', 'github2' }
```

- `{model}` is replaced with the card's spawn model name.
- This is the same fallback chain used everywhere a card renders (pack reveal, binder, shop, single-card view) — an addon vehicle missing from the official FiveM docs CDN will still show real art as long as it's been uploaded to one of your GitHub repos.
- These URLs are exactly what powers the **Vehicle Image Source** toggle and gallery in the `/cardcreator` panel — add or swap repos here and the Card Creator picks them up automatically, no other changes needed.
- Add or remove entries freely; any key you add to `Config.VehicleImageSources` also needs adding to `Config.VehicleImageSourceOrder` to actually be tried.

### 🗂️ Card Set Configuration

Sets are defined in `Config.Sets`. Each card supports:

| Field | Description |
|-------|-------------|
| `number` | Sequential card number within the set |
| `name` | Display name shown on the card |
| `model` | GTA V vehicle model name — image resolved via `Config.VehicleImageSources` (see above) |
| `image` | Custom foreground image path e.g. `'images/mycard.png'` |
| `background` | Custom background image path e.g. `'images/bg_rhino.png'` |
| `rarity` | `'common'`, `'uncommon'`, `'rare'`, or `'ultraRare'` |
| `printNum` | Override the print label shown on the card e.g. `'#042 / 500'` |
| `value` | Override the sell value for this specific card |

```lua
Config.Sets = {
    ['military'] = {
        label = 'Military Forces',
        icon  = '🎖️',
        cards = {
            { number = 1,  name = 'Vetir Troop Transport', model = 'vetir',    rarity = 'common'   },
            { number = 17, name = 'Rhino Tank',            model = 'rhino',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1200 },
            -- ...
        },
    },
    -- Add as many sets as you like
}
```

---

## 🃏 Included Card Sets

| Set | Icon | Cards | Notes |
|-----|------|-------|-------|
| Military Forces | 🎖️ | 20 | Tanks, APCs, and military hardware |
| Police Fleet | 🚔 | 20 | Law enforcement vehicles |
| Motorcycles | 🏍️ | 20 | Street and off-road bikes |
| Bravado Collection | 🔶 | 20 | Manufacturer themed set |
| Pegassi Collection | 🐴 | 10 | Manufacturer themed set |
| Dewbauchee Collection | 💎 | 10 | Manufacturer themed set |
| Grotti Collection | 🐎 | 10 | Manufacturer themed set |
| Truffade Collection | ⚡ | 5 | All Ultra Rare — high value |
| Fruit Collection | 🌟 | 7 | Custom image cards |

---

## 🐛 Troubleshooting

**Pack won't open:**
- Confirm the item name in `Config.Packs` exactly matches the item name in `qb-core/shared/items.lua`
- Check the server console for errors on resource start

**Cards not saving between sessions:**
- Verify `oxmysql` is running and the connection string is correct
- Check the server console confirms `mnc_trading_cards` table is ready on startup

**Binder not opening:**
- Confirm `card_binder` is a registered useable item in QBCore
- Check that `binderId` is being passed correctly from the server event

**Shop NPC not appearing:**
- Verify `Config.Shop.coords` points to a valid pedestrian area
- Check the model `s_m_y_dealer_01` is not restricted on your server

**NUI not closing with ESC:**
- Ensure `ox_lib` is loaded before `mnc-tradingcards` in `server.cfg`

**Addon vehicles missing from the Vehicle Image gallery / GitHub images not loading:**
- The gallery's GitHub listing is fetched by the player's own game client (CEF), not the server — a player-side network or firewall issue, not a server-side one
- Double-check the repo/branch in `Config.VehicleImageSources` matches the actual GitHub URL format: `.../raw/<branch>/{model}.png`
- Click **Refresh** in the gallery to force a re-check after uploading new images to the repo
- If GitHub can't be reached at all, the gallery falls back to the known vehicle list automatically — this is expected, not a bug

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.3.0
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
 
### Version 1.3.0 (Current Release)
**New Features:**
- ✨ Added `Config.VehicleImageSources` / `Config.VehicleImageSourceOrder` — vehicle cards now resolve their image through a configurable, ordered fallback chain (FiveM Docs CDN → any number of GitHub image stores) instead of a single hardcoded CDN URL
- ✨ Added a **Vehicle Image Source** toggle to the `/cardcreator` panel's Vehicle Model tab (FiveM Docs / GitHub Storage 1 / GitHub Storage 2)
- ✨ Added a full-page **image gallery** for browsing vehicles visually — switching to a GitHub source shows PNG thumbnails instead of a plain text list; click a thumbnail to select that vehicle
- ✨ Gallery now fetches the GitHub repo's actual file listing live, so **addon/custom vehicles** that were never in the built-in vehicle list show up too, tagged `ADDON`
- ✨ Added a **Refresh** button in the gallery to re-check GitHub after uploading new images, with results cached for the rest of the session to avoid unnecessary requests

**Improvements:**
- 🔧 Card images across every screen (pack reveal, binder, shop, single-card view, live Card Creator preview) now share the same multi-source fallback logic, so a picture found via GitHub Storage 2 renders correctly everywhere the card appears
- 🔧 Missing/broken thumbnails in the gallery show a clear "No image" placeholder instead of a blank box

### Version 1.2.0
**New Features:**
- ✨ Added `/cardpreview` admin command — opens a read-only binder populated with every card from every set for image and layout Q/A

### Version 1.1.0 
**New Features:**
- ✨ Added Misprint card variant with its own rarity tier and holo effect
- ✨ Added Damaged card variant with discard mechanic
- ✨ Implemented global per-card print counter with database persistence across restarts
- ✨ Added set-completion bonus when selling a full set at the dealer
- ✨ Added `sellSet` NUI callback for bulk set selling
- ✨ Implemented custom image and background support per card
- ✨ Added Fruit Collection set using fully custom artwork
- ✨ Added manufacturer-themed sets (Bravado, Pegassi, Dewbauchee, Grotti, Truffade)

**Improvements:**
- 🔧 Enhanced card data flattening (`FlattenCardInfo`) for consistent NUI payload structure
- 🔧 Added `ALTER TABLE … ADD COLUMN IF NOT EXISTS` migration for safe upgrades from v1.0.0
- 🔧 Improved binder UI with drag-to-remove zone and set progress display
- 🔧 Enhanced shop UI with select-all toggle and live price total
- 🔧 Refined pack tear animation with canvas-based progress indicator

**Bug Fixes:**
- 🐛 Fixed card data not persisting correctly when `_ref` nested structure was present
- 🐛 Resolved binder cards missing `image` and `background` columns on older installs
- 🐛 Fixed sell price calculating from `0` when card value was not flattened properly
- 🐛 Corrected print counter not initialising from existing database rows after restart
- 🐛 Fixed NUI remaining open if resource was stopped mid-session

---

### Version 1.0.0
**Features:**
- ✨ Initial release with core pack opening system
- ✨ Three pack tiers: Basic, Premium, Legendary
- ✨ Six rarity tiers with configurable weights and values
- ✨ Card Binder item with drag-and-drop storage
- ✨ Card Dealer NPC with world blip and E-key interaction
- ✨ Sell individual cards or entire sets at the dealer
- ✨ Automatic database table creation on resource start
- ✨ Military, Police Fleet, and Motorcycle card sets included
- ✨ Full NUI with pack tear animation, card flip reveal, binder book, and shop screens

---

## ⚠️ Important Notes

1. **Compatibility**: QBCore only — not compatible with ESX.
2. **Card Images**: Vehicle cards resolve their image through `Config.VehicleImageSources` automatically via the `model` field (FiveM Docs CDN, then any configured GitHub stores); custom cards require images placed in `web/images/`.
3. **Legal**: For use on FiveM servers only, respect Rockstar's Terms of Service.

---

**Enjoy collecting on your FiveM server! 🃏**
