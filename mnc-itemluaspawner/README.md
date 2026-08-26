# 📦 MnC Item Spawner (Auto/Full Catalog)

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

MnC Item Spawner gives authorized staff a themed NUI browser that auto-populates with **every** item defined in `QBCore.Shared.Items`, grouped by item type, so they can spawn any item — or a whole cart of items — straight into their inventory for testing or support purposes.

---

## ✨ Key Features

**Access Control**
- `Config.EnableJobLock` gates the tool behind `Config.AllowedJobs`, a job → minimum grade map (defaults: `admin` grade 4, `staff` grade 4, `police` grade 4)
- Access is checked on both the client (before opening the UI) and the server (before granting items)

**Auto-Populated Catalog**
- Every entry in `QBCore.Shared.Items` is pulled in automatically and grouped by its `type` field — no manual item list to maintain
- `Config.ExcludeTypes` and `Config.ExcludeItems` let you hide entire item types (e.g. `weapon`) or specific item names from the browser
- Item images are resolved from each item's configured client image where available

**UI**
- Command `Config.Command` (default `itemspawner`) opens the NUI grid
- 5 selectable visual themes via `Config.UIStyle` (`style1`–`style5`): Dark Modern Glass, Light Clean Glass, Neon Night Glass, Retro Glass, Oceanic Glass
- Supports both spawning a single item and submitting a multi-item cart in one action

**Inventory-Aware Granting**
- Auto-detects whether `ox_inventory` or `qb-inventory` is running and uses the matching add-item / carry-capacity check
- Falls back to a manual weight calculation against `Config.MaxWeight` if neither is detected
- Notifies the player if their inventory is full instead of silently failing

---

## 📋 Requirements

| Dependency | Required |
|---|---|
| qb-core | ✅ Yes |
| ox_lib | ✅ Yes |
| ox_inventory or qb-inventory | Optional (auto-detected for carry-capacity checks) |

---

## 🚀 Installation

```bash
# Place into your resources folder
[server-data]/resources/[custom]/mnc-itemluaspawner/
```

```lua
# server.cfg
ensure mnc-itemluaspawner
```

No database setup required — items are read live from `QBCore.Shared.Items` and inserted directly into the player's inventory.

---

## ⚙️ Configuration Guide

```lua
Config = {
    EnableJobLock = true,
    AllowedJobs = {
        ['admin'] = 4,
        ['staff'] = 4,
        ['police'] = 4,
    },
    Command = 'itemspawner',
    UIStyle = 'style1',
    ExcludeTypes = {
        -- 'weapon',
    },
    ExcludeItems = {
        -- 'money',
    },
}
```

`AllowedJobs` controls who can open the spawner (job name → minimum grade). `ExcludeTypes`/`ExcludeItems` let you hide categories or individual items without touching your `items.lua`.

---

## 🎮 Controls & Usage

```
/itemspawner
```
Opens the NUI browser. Click an item to spawn a single stack, or add multiple items to a cart and submit them together.

---

## 🔧 Troubleshooting

- **"Access Denied" for a staff member** — their job/grade doesn't meet the `AllowedJobs` threshold, or `EnableJobLock` is `true` and their job isn't listed at all.
- **Items missing images in the UI** — the browser resolves images from each item's `client.image` (or `image`) field in your `items.lua`; items without one will fall back to the item name.
- **"Inventory Full" even with space** — if you run `qb-inventory`, confirm `Config.MaxWeight` roughly matches your actual inventory weight limit, since this script calculates capacity manually when `ox_inventory` isn't present.

---

## 📝 Credits & License

**Author**: Stan Leigh
**Version**: 1.0.0
**Framework**: QBCore

Distributed as part of the MnCLosSantos mod-dump collection — open source, please credit the original author if you edit and re-release.
