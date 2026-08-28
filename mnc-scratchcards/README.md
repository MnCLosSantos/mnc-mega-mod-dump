# 🎰 MNC Scratch Cards

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A **polished scratch card minigame** for QBCore-based FiveM servers featuring 5 unique card tiers, a fully interactive canvas-based scratch mechanic, per-card win tables with configurable odds, and themed NUI with animated effects. Players buy and use scratch cards from their inventory to reveal prizes — all validated server-side to prevent exploitation.

---

## ✨ Key Features

### 🎨 Interactive Scratch UI
- **Canvas-based scratch mechanic** — players physically scratch the card with their mouse
- **Real-time progress bar** tracking how much of the card has been revealed
- **Per-tile win/loss icons** revealed as the player scratches
- **Animated result row** that fades in once the card is fully scratched
- **Collect button** to claim winnings and close the UI
- **ESC key** to close at any time (reward still claimed)
- **Fully themed card UI** — background, accent colour, and shimmer effects driven by config

### 🃏 Five Card Tiers
| Card | Price | Top Prize |
|------|-------|-----------|
| Basic | $15 | $5,000 |
| Silver | $20 | $12,000 |
| Gold | $35 | $30,000 |
| Platinum | $55 | $75,000 |
| Diamond | $65 | $150,000 |

### 🎭 Themed Visual Effects
- **Basic** — clean white accent, minimal styling
- **Silver** — animated silver sheen across the card header
- **Gold** — warm golden shimmer with glowing border
- **Platinum** — cool blue-white shimmer with icy border glow
- **Diamond** — prismatic cyan shimmer with multi-layer glow effect

### 🔒 Server-Side Reward Validation
- Win amount is **calculated on the server** before the UI opens — the client cannot manipulate the result
- `claimReward` validates the submitted amount against the **known win patterns** for that card type
- Item is **removed from inventory before the card is shown**, preventing duplicate claims
- Reward amounts that don't match a valid pattern are silently rejected

### 🔔 Notifications
- **Win notification** via `ox_lib` showing exact cash amount won
- **Loss notification** for no-win outcomes
- Clean, non-intrusive styling consistent with your existing server notifications

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| qb-inventory | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-scratchcards/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-scratchcards/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-scratchcards/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-scratchcards
```

No database tables are required — the script has no SQL dependencies.

### 3️⃣ Add Items to QBCore

Add all five scratch card items to `qb-core/shared/items.lua`:

```lua
['scratch_basic'] = {
    ['name']        = 'scratch_basic',
    ['label']       = 'Basic Scratch Card',
    ['weight']      = 10,
    ['type']        = 'item',
    ['image']       = 'scratch_basic.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'A basic scratch card. Match 3 to win!'
},

['scratch_silver'] = {
    ['name']        = 'scratch_silver',
    ['label']       = 'Silver Scratch Card',
    ['weight']      = 10,
    ['type']        = 'item',
    ['image']       = 'scratch_silver.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'A silver scratch card. Higher prizes await.'
},

['scratch_gold'] = {
    ['name']        = 'scratch_gold',
    ['label']       = 'Gold Scratch Card',
    ['weight']      = 10,
    ['type']        = 'item',
    ['image']       = 'scratch_gold.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'A gold scratch card. Fortune favours the bold.'
},

['scratch_platinum'] = {
    ['name']        = 'scratch_platinum',
    ['label']       = 'Platinum Scratch Card',
    ['weight']      = 10,
    ['type']        = 'item',
    ['image']       = 'scratch_platinum.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'A platinum scratch card. Serious prizes inside.'
},

['scratch_diamond'] = {
    ['name']        = 'scratch_diamond',
    ['label']       = 'Diamond Scratch Card',
    ['weight']      = 10,
    ['type']        = 'item',
    ['image']       = 'scratch_diamond.png',
    ['unique']      = false,
    ['useable']     = true,
    ['shouldClose'] = true,
    ['description'] = 'A diamond scratch card. The ultimate prize.'
},
```

---

## ⚙️ Configuration Guide

All configuration lives in `config.lua`.

### 🐛 Debug Mode

```lua
Config.Debug = false  -- Set to true to enable server/client print logs
```

### 🔊 Sound Files

```lua
Config.ScratchSounds = {
    scratch   = 'sounds/scratch.mp3',
    win_small = 'sounds/small.mp3',
    win_big   = 'sounds/big.mp3',
}
```

Place your `.mp3` or `.ogg` sound files in `web/sounds/`. The manifest already includes both formats.

### 🃏 Scratch Card Items

Each entry in `Config.ScratchItems` defines a card type:

```lua
['scratch_gold'] = {
    label       = 'Gold Scratch Card',  -- Displayed at top of the card UI
    price       = 35,                   -- Reference price (for shop integration)
    revealType  = 'gold',               -- Controls UI theme (see Themes below)
    gridSize    = 3,                    -- Grid dimensions (3 = 3×3 grid of tiles)
    winPatterns = {
        { chance = 6.18, reward = 300,   text = '$300'    },
        { chance = 2.82, reward = 800,   text = '$800'    },
        { chance = 1.35, reward = 30000, text = '$30,000!' },
    },
    scratchColor = '#c8a84b',           -- Colour of the scratch-off layer
    background   = '#1a1208',           -- Card background colour
    accent       = '#f0c040',           -- Header, tile borders, button colour
},
```

#### Win Pattern Fields

| Field | Type | Description |
|-------|------|-------------|
| `chance` | number | Percentage chance of this outcome (e.g. `6.18` = 6.18%) |
| `reward` | number | Cash amount awarded on win |
| `text` | string | Label shown on the winning tile in the UI |

> **Note:** Chances are evaluated sequentially and subtracted from a 0–1 roll. If no pattern matches, the player wins nothing. Total win probability for the Gold card is approximately 10.35%.

#### Theme / `revealType` Values

| Value | Effect |
|-------|--------|
| `basic` | Clean white, no animation |
| `silver` | Animated silver sheen |
| `gold` | Warm golden shimmer + border glow |
| `platinum` | Cool blue-white shimmer + icy glow |
| `diamond` | Prismatic cyan shimmer + multi-layer glow |

---

## 🔧 How It Works

1. Player uses a scratch card item from their inventory
2. Server validates the item exists in the correct slot
3. Item is removed from inventory immediately
4. Server rolls for a win against the configured `winPatterns`
5. Result (`{ won = amount }`) is sent to the client — the client **never decides the outcome**
6. NUI opens with the themed card; player scratches the canvas with their mouse
7. When the scratch threshold is reached, tiles are revealed and the result row appears
8. Player clicks **Collect** (or presses ESC) — client fires `scratchFinished` to the server
9. Server validates the claimed amount against valid win patterns before adding money

---

## 🛠️ Troubleshooting

**Card UI not opening:**
- Confirm `ox_lib` is started before `mnc-scratchcards` in `server.cfg`
- Check that the item name in your inventory exactly matches a key in `Config.ScratchItems`
- Enable `Config.Debug = true` and check server/client console output

**Item removed but UI never appears:**
- Verify `mnc-scratchcards:client:showScratch` event is not being blocked
- Check that `web/index.html` is listed correctly in `fxmanifest.lua`
- Confirm the `ui_page` path matches your folder structure (`web/index.html`)

**Reward not being paid out:**
- Make sure the `reward` values in `winPatterns` are plain integers — no string formatting
- Check server console for any QBCore player lookup errors
- Confirm `oxmysql` is running (required by the manifest even if not used directly by this script)

**Scratch canvas not rendering correctly:**
- Clear your FiveM cache (`%localappdata%/FiveM/FiveM.app/cache`)
- Ensure sound files exist in `web/sounds/` — missing files won't break scratching but may cause console warnings

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

## 🔄 Changelog

### Version 1.0.0 (Current Release)
**New Features:**
- ✨ Initial release with 5 scratch card tiers (Basic, Silver, Gold, Platinum, Diamond)
- ✨ Canvas-based interactive scratch mechanic with real-time progress tracking
- ✨ Server-side win calculation — outcome cannot be manipulated client-side
- ✨ Server-side reward validation before money is awarded
- ✨ Fully themeable card UI driven entirely by `config.lua` values
- ✨ Animated shimmer effects per card tier (silver, gold, platinum, diamond)
- ✨ Per-tile icon reveal system with winner highlighting
- ✨ Animated result row with win/loss feedback
- ✨ ox_lib notification integration for win and loss outcomes
- ✨ ESC key support to close UI at any time
- ✨ Resource cleanup on `onResourceStop` to safely release NUI focus
- ✨ Debug logging toggle in config

---

## ⚠️ Important Notes

1. **No SQL Required**: This script does not create or use any database tables
2. **Anti-Exploit**: Win outcomes are determined and stored server-side before the UI opens — the client only reports which card was used, never the result
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Sounds**: MP3 and OGG formats are both supported; include whichever your audio files use
5. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Good luck scratching! 🎰**
