# 🚗 MNC Vehicle Catalog v2

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-2.3.0-brightgreen.svg)]()

> ⚠️ **Multiple versions of this script exist in this dump — install only ONE.** `mnc-vehiclecatalog-v2` is one of two builds of this tool alongside `mnc-vehiclecatalog`. Running more than one at the same time will register the same commands/exports twice and can corrupt shared data. See "Choosing a Version" below.

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
A multi-dealership vehicle browsing UI for QBCore, self-contained enough to run without depending on your server's shared vehicle data being fully filled out. Each configured zone shows an NUI catalog of the vehicles assigned to that shop, using a bundled ~500-vehicle database with shop/price/category data already populated, plus admin-only live price editing and a more resilient multi-source image fallback chain.

---

## 🔀 Choosing a Version

This dump contains two builds of the vehicle catalog. **Install only one** — both register the same `mnc-vehiclecatalog` command/event namespace.

| | `mnc-vehiclecatalog` | `mnc-vehiclecatalog-v2` (this one) |
|---|---|---|
| Zone-based dealership catalogs, 5 UI themes | ✅ | ✅ |
| qb-target or E-keypress interaction | ✅ | ✅ |
| Staff job hooks + pre-order submission | ✅ | ✅ |
| Vehicle data source | Relies entirely on `QBCore.Shared.Vehicles` already having `shop`/`price`/`category` set | Ships its own bundled ~500-vehicle database (`shared/vehicles.lua`) pre-assigned to shops, usable even if your `qb-core` shared vehicles aren't fully configured |
| Admin-only live price editing in the catalog UI | ❌ | ✅ |
| Admin access check | ACE-style `Config.AdminGroups` | QBCore `HasPermission(src, 'admin')` |
| Image fallback chain | `docs.fivem.net` → local `./images/{model}.png` → `fallback.png` | `docs.fivem.net` → 2 GitHub image-repo mirrors → local `fallback.png` |
| Version | 3.0.0 | 2.3.0 |

Both versions share the same dealership/theming/pre-order feature set — the real difference is data portability and admin tooling. Pick **this version** if you'd rather not touch your `qb-core` shared vehicles file at all, or if you want in-catalog price editing for admins. Pick the base version if your shared vehicles file already has accurate `shop`/`price` data for everything you want listed.

---

## ✨ Key Features

### 📦 Self-Contained Vehicle Database
- Ships its own `shared/vehicles.lua` covering roughly 500 base-game vehicles, each pre-assigned a `model`, `name`, `brand`, `price`, `category`, `type`, and default `shop` — the catalog works out of the box even on a server whose `qb-core/shared/vehicles.lua` doesn't set those fields
- Still reads and merges in anything already defined in `QBCore.Shared.Vehicles`, so custom/addon vehicles you've already configured there show up too

### 🏬 Zone-Based Dealership Catalogs
- `Config.Zones` defines any number of dealership locations, each with its own coordinates, interaction radius, UI color style, and display title
- Interaction can use either `qb-target` circle zones or a proximity keybind — players near a zone see a prompt and press **E** to open the catalog, toggled by `Config.UseTarget`

### 🎨 Five Built-In Themes
- Dark Modern, Light Clean, Neon Night, Retro, and Oceanic glass-style themes (`style1`–`style5`), assignable per zone via `uiStyle`

### 💵 Admin-Only Live Price Editing
- Zones can be flagged `canEditPrices = true` — admins browsing that catalog can adjust a vehicle's listed price directly from the UI, while regular players (`canEditPrices = false`) only ever see the read-only listing
- Access to the admin "all vehicles" command uses `QBCore.Functions.HasPermission(src, 'admin')` rather than a manually maintained ACE group list

### 🖼️ Resilient Image Loading
- Vehicle images are tried in order: `docs.fivem.net`, then two configurable GitHub-hosted image mirrors (`Config.ImagePaths.github1` / `github2`), then a local fallback — so a missing or renamed image on one source doesn't leave a broken picture in the catalog

### 👔 Staff & Pre-Order Hooks
- Same staff-job access flagging and pre-order submission flow (`submitPreOrder`, `getOrders`, `updateOrderStatus`) as the base version

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| qb-target | Latest | ⚠️ Optional — only needed if `Config.UseTarget = true` |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-vehiclecatalog-v2/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure mnc-vehiclecatalog-v2
```

No database setup required.

### 3️⃣ Configure Settings

Edit `config.lua` to define your dealership zones, set per-zone `canEditPrices`, and adjust `Config.ImagePaths` if you want to host your own vehicle image mirrors.

---

## ⚙️ Configuration Guide

```lua
Config = {
    Command = 'vehiclecatalog', -- Command to open the admin UI (all vehicles + dealership swap)

    ImagePaths = {
        primary = 'https://docs.fivem.net/vehicles/{model}.webp',
        github1 = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage/raw/main/{model}.png',
        github2 = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage-2/raw/main/{model}.png',
        local_fallback = './images/fallback.png',
    },

    UseTarget = false, -- Use qb-target (true) or keypress E (false)

    Zones = {
        {
            name = 'pdm',
            coords = vector3(-55.17, -1089.85, 26.92),
            radius = 2.0,
            uiStyle = 'style1',
            title = 'Adams Apple PDM Catalogue',
            useAnywhere = false,
            canEditPrices = false, -- Zone visitors can't edit prices
        },
        -- ...
    },

    UIStyles = {
        -- style1..style5, same as base version
    },
}
```

- `Config.ImagePaths` — point `github1`/`github2` at your own image repos if you'd rather not rely on the MnC-hosted mirrors
- `canEditPrices` — set per zone; combine with `QBCore.Functions.HasPermission(src, 'admin')` server-side enforcement so only real admins can actually save a price change even if the UI element is visible

---

## 🎮 Controls & Usage

| Input | Description |
|---|---|
| Approach a zone, press **E** (or use `qb-target` if enabled) | Opens that dealership's catalog |
| `/vehiclecatalog` (or your `Config.Command`) | Admin-only — opens the all-vehicles catalog regardless of shop |
| Price field in an admin-enabled zone | Edit and save a vehicle's listed price directly from the catalog |

---

## 🔧 Troubleshooting

**A zone shows no vehicles:**
- Confirm the zone's `name` matches the `shop` value on the relevant entries in `shared/vehicles.lua` or `QBCore.Shared.Vehicles`

**Vehicle images don't load:**
- The fallback chain tries `docs.fivem.net`, then your two configured GitHub mirrors, then the local fallback — check that `Config.ImagePaths.github1`/`github2` point at working raw-file URLs

**Price edits don't save:**
- Confirm the zone has `canEditPrices = true` and that the editing player actually has the `admin` permission QBCore checks server-side — a visible edit control with no server-side permission will fail silently on save

**Admin command says access denied:**
- Access is checked via `QBCore.Functions.HasPermission(src, 'admin')` — grant that permission through QBCore's admin group system, not just an ACE permission

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 2.3.0
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

1. **Bundled data**: The included `shared/vehicles.lua` covers common base-game vehicles only — add your own addon/custom vehicles to `QBCore.Shared.Vehicles` as usual and they'll be merged in automatically
2. **Compatibility**: QBCore only — not compatible with ESX
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Browse the lot, pick your ride. 🚗**
