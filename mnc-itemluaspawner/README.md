# 📦 MNC Item Spawner (Locked Access Default)

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

> ⚠️ **Multiple versions of this script exist in this dump — install only ONE.** `mnc-itemluaspawner` is one of several builds of this tool alongside `mnc-itemspawner`. Running more than one at the same time will register the same commands/exports twice and can corrupt shared data. This build ships with Config.EnableJobLock = true (locked) by default, vs. false (open) on mnc-itemspawner. See "Choosing a Version" below.

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

## 🔀 Choosing a Version

| | `mnc-itemluaspawner` (this one) | `mnc-itemspawner` |
|---|---|---|
| Code | Identical | Identical |
| Default `Config.EnableJobLock` | `true` (locked to `Config.AllowedJobs` out of the box) | `false` (open to everyone out of the box) |
| Best for | Servers that want the tool locked down immediately after install | Servers that will configure access themselves before going live |

Pick **one**, install it, and set `Config.EnableJobLock` to whatever you actually want — the two builds are otherwise byte-for-byte the same script.

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

1. **Pick one build**: install either `mnc-itemluaspawner` or `mnc-itemspawner`, never both — see "Choosing a Version" above
2. **Compatibility**: QBCore only — not compatible with ESX
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Spawn what you need, exactly when you need it. 📦**

