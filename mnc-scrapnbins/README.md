# 🗑️ MNC Scrap N Bins

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![Framework](https://img.shields.io/badge/Framework-QBCore%20%7C%20QBX-blue)](https://github.com/qbcore-framework)
[![ ox_lib ](https://img.shields.io/badge/ox__lib-Required-orange)](https://overextended.dev/ox_lib)
[![Version](https://img.shields.io/badge/Version-2.0.0-brightgreen.svg)]()

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

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
   # Recommended: use git (easier updates) — this resource lives inside the mnc-mega-mod-dump monorepo
   git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
   # then copy the mnc-scrapnbins/ folder to resources/[custom]/mnc-scrapnbins
   ```

   or download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-scrapnbins/` folder to `resources/[custom]/mnc-scrapnbins`

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

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 2.0.0
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
- 📖 Check this README's Configuration Highlights and Troubleshooting sections first — most questions are answered above

---

## ⚠️ Important Notes

1. **Database**: Requires oxmysql (per-entity cooldown tracking)
2. **Item registration**: every item referenced in `Config.Tiers` must exist in your shared items before it can be looted
3. **Compatibility**: QBCore/QBX only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Enjoy bin diving responsibly! 🗑️🔧**

