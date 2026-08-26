# 🗑️ MNC Scrap N Bins

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![Framework](https://img.shields.io/badge/Framework-QBCore%20%7C%20QBX-blue)](https://github.com/qbcore-framework)
[![ ox_lib ](https://img.shields.io/badge/ox__lib-Required-orange)](https://overextended.dev/ox_lib)
[![Version](https://img.shields.io/badge/Version-2.0.0-brightgreen.svg)]()

Dynamic **bin diving** & **scrap searching** system for modern QBCore/QBX servers.

Search trash bins, dumpsters, trash bags and vehicle wrecks with immersive animations, directional sounds, optional minigames, entity cooldowns, needle prick risk, and a weighted tiered loot table.

---

## ✨ Features

- 🔎 **Target-based interaction** (qb-target / ox_target)
- 🎮 Optional **ox_lib skill checks** (different difficulty per bin/scrap)
- 🕒 Per-entity **cooldown** (prevent spam farming)
- 🎥 Realistic rummaging **animation** + context-aware **sounds**
- 💉 Optional **needle prick** mechanic (bins only) – screen effects, damage, pain anim
- 📦 **Tiered loot** (Common / Uncommon / Rare) with configurable chances & items
- ⚖️ Supports **qb-inventory** and **ox_inventory**
- 🔔 Notifications via **qb** or **ox_lib**
- 📊 Progress via **qb**, **ox_lib_bar** or **ox_lib_circle**

---

## 📋 Requirements

| Resource           | Required | Notes                                 |
|--------------------|----------|---------------------------------------|
| **qb-core** / QBX  | Yes      | Core framework                        |
| **ox_lib**         | Yes      | Minigames, progress, notifications    |
| **oxmysql**        | Yes      | (usually already on server)           |
| qb-target          | Optional | if `Config.Target = "qb-target"`      |
| ox_target          | Optional | if `Config.Target = "ox_target"`      |
| qb-inventory       | Optional | if `Config.Inventory = "qb-inventory"`|
| ox_inventory       | Optional | if `Config.Inventory = "ox_inventory"`|

---

## 🚀 Installation

1. Download or clone the resource

   ```bash
   # Recommended: use git (easier updates)
   git clone https://github.com/MnCLosSantos/mnc-scrapnbins.git resources/[custom]/mnc-scrapnbins
   ```

   or download latest release ZIP → extract to `resources/[custom]/mnc-scrapnbins`

2. Ensure dependencies in server.cfg (order matters)

   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure qb-core      # or qbx_core
   # ensure qb-target   # if using
   # ensure ox_target   # if using
   ensure mnc-scrapnbins
   ```

3. Add missing items to `qb-core/shared/items.lua` (or QBX items)

   Make sure **every item** listed in `Config.Tiers` exists. Example:

   ```lua
   ['plastic']       = {['name'] = 'plastic',       ['label'] = 'Plastic',       weight = 100, ...},
   ['metal_scrap']   = {['name'] = 'metal_scrap',   ['label'] = 'Metal Scrap',   weight = 200, ...},
   ['aluminum']      = { ... },
   ['lockpick']      = { ... },
   ['advancedlockpick'] = { ... },
   ['pistol_ammo']   = { ... },
   ```

4. Restart server or `refresh` + `start mnc-scrapnbins`

---

## ⚙️ Configuration Highlights

All settings are in `config.lua`

### Core toggles

```lua
Config.CoreName    = 'qb-core'          -- or 'qbx-core'
Config.Target      = 'ox_target'        -- 'qb-target' | 'ox_target'
Config.Inventory   = 'ox_inventory'     -- 'qb-inventory' | 'ox_inventory'
Config.Notify      = 'ox_lib'           -- 'qb' | 'ox_lib'
Config.Progress    = 'ox_lib_bar'       -- 'qb' | 'ox_lib_bar' | 'ox_lib_circle'
```

### Minigame (ox_lib skillCheck)

```lua
Config.Minigame = {
    Enabled = true,
    BinSkip = { Type = "wasd",   Difficulty = {"easy","easy","easy","easy"}, Duration = 5000 },
    Scrap   = { Type = "1234",   Difficulty = {"medium","easy","medium","easy"}, Duration = 6000 }
}
```

### Loot tiers (cumulative chance system)

```lua
Config.Tiers = {
    Common   = { Chance = 70, Items = {'plastic','metal_scrap','rubber','tosti','glass'} },
    Uncommon = { Chance = 25, Items = {'aluminum','steel','copper','lockpick','lighter'} },
    Rare     = { Chance =  5, Items = {'advancedlockpick','repairkit','joint','pistol_ammo'} }
}
```

### Risk & timing

```lua
Config.SearchTime   = 8000      -- ms
Config.Cooldown     = 45000     -- ms per entity
Config.ChanceToFind = 70        -- % to find anything
Config.MaxAmount    = 3

Config.NeedlePrick = {
    Enabled = true,
    Chance  = 10,               -- only bins
    HealthDrain = 15,
    -- ... screen shake, pain anim, sounds ...
}
```

---

## 🆕 What's New in v2.0.0

- Full **ox_inventory** support (proper AddItem return checking)
- Better **sound cleanup** & animation handling
- Improved **needle prick** realism (configurable shake, vignette, gradual damage)
- More flexible **sound categories** (Bin / Skip / Bag / Scrap)
- Entity-specific cooldown tracking (no global timer abuse)
- Debug prints when items are invalid/missing

---

## 🛠️ Troubleshooting

| Problem                                 | Possible Fix                                      |
|-----------------------------------------|---------------------------------------------------|
| No target option appears                | Check `Config.Target` + ensure target resource running |
| Minigame doesn't show                   | Make sure `ox_lib` is started & up to date        |
| "Item not found" / nothing added        | Item missing in `qb-core/shared/items.lua`        |
| Sounds not playing                      | Check stream folder or sound name spelling        |
| Animation stuck                         | Increase RequestAnimDict timeout or check dict    |
| ox_inventory says inventory full        | Player actually has no space                      |

---

## ❤️ Support & Contributing

Found a bug? Have a cool item/sounds/model suggestion?

→ Open an issue or pull request on GitHub

Enjoy bin diving responsibly! 🗑️🔧

MIT License – feel free to modify & redistribute with credit.
