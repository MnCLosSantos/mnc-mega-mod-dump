# 🚗 MNC Vehicle Catalog

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-3.0.0-brightgreen.svg)]()

> ⚠️ **Multiple versions of this script exist in this dump — install only ONE.** `mnc-vehiclecatalog` is one of two builds of this tool alongside `mnc-vehiclecatalog-v2`. Running more than one at the same time will register the same commands/exports twice and can corrupt shared data. See "Choosing a Version" below.

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
A multi-dealership vehicle browsing UI for QBCore. Each configured zone (dealership location) shows an NUI catalog listing only the vehicles assigned to that shop — matched by `qb-core`'s `shop` field on each vehicle entry — with its own visual theme, custom title, and category grouping pulled straight from `QBCore.Shared.Vehicles`. An admin command can also open a catalog showing every vehicle in the game regardless of shop.

---

## 🔀 Choosing a Version

This dump contains two builds of the vehicle catalog. **Install only one** — both register the same `mnc-vehiclecatalog` command/event namespace.

| | `mnc-vehiclecatalog` (this one) | `mnc-vehiclecatalog-v2` |
|---|---|---|
| Zone-based dealership catalogs, 5 UI themes | ✅ | ✅ |
| qb-target or E-keypress interaction | ✅ | ✅ |
| Staff job hooks + pre-order submission | ✅ | ✅ |
| Vehicle data source | Relies entirely on `QBCore.Shared.Vehicles` already having `shop`/`price`/`category` set | Ships its own bundled ~500-vehicle database (`shared/vehicles.lua`) pre-assigned to shops, usable even if your `qb-core` shared vehicles aren't fully configured |
| Admin-only live price editing in the catalog UI | ❌ | ✅ |
| Admin access check | ACE-style `Config.AdminGroups` | QBCore `HasPermission(src, 'admin')` |
| Image fallback chain | `docs.fivem.net` → local `./images/{model}.png` → `fallback.png` | `docs.fivem.net` → 2 GitHub image-repo mirrors → local `fallback.png` |
| Version | 3.0.0 | 2.3.0 |

Both versions share the same dealership/theming/pre-order feature set — the real difference is data portability and admin tooling. Pick this version if your `qb-core/shared/vehicles.lua` already has accurate `shop` and `price` fields for every vehicle you want listed. Pick **v2** if you'd rather not touch your shared vehicles file at all, or if you want in-catalog price editing for admins.

---

## ✨ Key Features

### 🏬 Zone-Based Dealership Catalogs
- `Config.Zones` defines any number of dealership locations, each with its own coordinates, interaction radius, UI color style, and display title
- Interaction can use either `qb-target` circle zones or a proximity keybind — players near a zone see a prompt and press **E** to open the catalog (`RegisterKeyMapping('open_catalog', ...)`), toggled by `Config.UseTarget`
- Vehicles shown per-zone are filtered by matching each `QBCore.Shared.Vehicles` entry's `shop` field against the zone name; category, brand, and price data are read straight from the shared vehicle table

### 🎨 Five Built-In Themes
- Dark Modern Glass, Light Clean Glass, Neon Night Glass, Retro Glass, and Oceanic Glass (`style1`–`style5`), defined in `Config.UIStyles` and assignable per zone via `uiStyle`

### 🔑 Admin "All Vehicles" Catalog
- A `lib.addCommand` command (name set by `Config.Command`, default `vehiclecatalog`, restricted to `Config.AdminGroups`) opens an "All Vehicles Catalog" view showing every vehicle in `QBCore.Shared.Vehicles` regardless of shop assignment

### 👔 Staff & Pre-Order Hooks
- The client checks `hasStaffAccess` per zone against a `zone.staffJobs` list and flags it to the NUI
- The NUI can submit vehicle pre-orders (`submitPreOrder`) and request/update an orders list (`getOrders`, `updateOrderStatus`) — these fire `TriggerServerEvent` calls intended for a staff order-management flow

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
[server-data]/resources/[custom]/mnc-vehiclecatalog/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure mnc-vehiclecatalog
```

No database setup required.

### 3️⃣ Configure Settings

Edit `config.lua` to define your dealership zones and confirm every vehicle you want listed already has an accurate `shop` (and ideally `price`/`category`) field in your `qb-core/shared/vehicles.lua`.

---

## ⚙️ Configuration Guide

```lua
Config = {
    Command = 'vehiclecatalog', -- Command to open UI with all vehicles
    AdminGroups = {'group.admin'}, -- Admin groups for command access

    UseTarget = false, -- Use qb-target (true) or keypress E (false)

    Zones = {
        {
            name = 'pdm', -- Dealership name from qb-vehicleshop
            coords = vector3(-55.17, -1089.85, 26.92),
            radius = 2.0,
            uiStyle = 'style1', -- Options: style1, style2, style3, style4, style5
            title = 'Adams Apple PDM Catalogue',
            useAnywhere = false, -- leave false
        },
        -- Add more zones as needed
    },

    UIStyles = {
        style1 = { -- Dark Modern Glass
            -- colors...
        },
        -- style2..style5
    },
}
```

- `Config.Zones` — each zone's `name` must match the `shop` field used by the vehicles you want it to display
- `Config.AdminGroups` — controls who can run the all-vehicles admin command
- `Config.UseTarget` — set `true` to use `qb-target` interaction zones instead of the proximity E-keypress prompt

---

## 🎮 Controls & Usage

| Input | Description |
|---|---|
| Approach a zone, press **E** (or use `qb-target` if enabled) | Opens that dealership's catalog |
| `/vehiclecatalog` (or your `Config.Command`) | Admin-only — opens the all-vehicles catalog regardless of shop |

---

## 🔧 Troubleshooting

**A zone shows no vehicles:**
- Confirm the zone's `name` matches the exact `shop` value on the vehicles in `QBCore.Shared.Vehicles` you expect to see there

**Vehicle images don't load:**
- The fallback chain tries `docs.fivem.net` first, then a local `./images/{model}.png`, then `fallback.png` — add missing images to the `web/images/` folder for any custom vehicles

**Admin command says access denied:**
- Check `Config.AdminGroups` matches an ACE group your admin account is actually in

**Zone doesn't respond to E:**
- Confirm `Config.UseTarget` matches whether you actually have `qb-target` installed and running

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 3.0.0
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

1. **Data dependency**: This version does not ship its own vehicle database — it depends entirely on `shop`/`price`/`category` already being set correctly in your `qb-core/shared/vehicles.lua`
2. **Compatibility**: QBCore only — not compatible with ESX
3. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Browse the lot, pick your ride. 🚗**
