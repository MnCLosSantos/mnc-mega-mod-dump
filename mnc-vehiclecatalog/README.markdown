# 🚗 MNC Vehicle Catalog

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-3.0.0-brightgreen.svg)]()

---

## 🌟 Overview

MNC Vehicle Catalog is a multi-dealership browsing UI for QBCore. Each configured zone (dealership location) shows an NUI catalog listing only the vehicles assigned to that shop (via `qb-core`'s `shop` field on each vehicle), each with its own visual theme, custom title, and category grouping pulled from `QBCore.Shared.Vehicles`. An admin command can also open a catalog showing every vehicle in the game regardless of shop.

---

## ✨ Key Features

**Zone-based dealership catalogs**
- `Config.Zones` defines any number of dealership locations, each with its own coordinates, interaction radius, UI color style, and display title.
- Interaction can use either `qb-target` circle zones or a proximity keybind: players near a zone see a proximity prompt and can press **E** to open the catalog (`RegisterKeyMapping('open_catalog', ...)`), toggled by `Config.UseTarget`.
- Vehicles shown per-zone are filtered by matching each `QBCore.Shared.Vehicles` entry's `shop` field against the zone name; categories/brand/price data are read straight from the shared vehicle table.

**Theming**
- Five built-in glass-style UI themes (`style1`–`style5`, e.g. Dark Modern Glass, Neon Night Glass, Oceanic Glass) defined in `Config.UIStyles` and assignable per zone via `uiStyle`.

**Admin catalog**
- A `lib.addCommand` command (name set by `Config.Command`, default `vehiclecatalog`, restricted to `Config.AdminGroups`) opens an "All Vehicles Catalog" view showing every vehicle in `QBCore.Shared.Vehicles` regardless of shop assignment.

**Staff / pre-order UI hooks**
- The client checks `hasStaffAccess` per zone against a `zone.staffJobs` list and flags it to the NUI.
- The NUI can submit vehicle pre-orders (`submitPreOrder`) and request/update an orders list (`getOrders`, `updateOrderStatus`) — these fire `TriggerServerEvent` calls intended for a staff order-management flow.

---

## 📋 Requirements

| Dependency | Required |
|---|---|
| qb-core | Yes |
| ox_lib | Yes |
| qb-target | Optional (only if `Config.UseTarget = true`) |

---

## 🚀 Installation

```bash
# Place into your resources folder
[server-data]/resources/[custom]/mnc-vehiclecatalog/
```

```lua
# server.cfg
ensure mnc-vehiclecatalog
```

No database setup is required. Set up each dealership by adding an entry to `Config.Zones` and make sure the corresponding vehicles in `qb-core/shared/vehicles.lua` have a matching `shop` value.

---

## ⚙️ Configuration Guide

```lua
Config.Command = 'vehiclecatalog'
Config.AdminGroups = {'group.admin'}
Config.UseTarget = false -- qb-target circle zone (true) vs keypress E (false)

Config.Zones = {
    {
        name = 'pdm',
        coords = vector3(-55.17, -1089.85, 26.92),
        radius = 2.0,
        uiStyle = 'style1',
        title = 'Adams Apple PDM Catalogue',
        useAnywhere = false,
    },
    -- additional dealership zones...
}
```

Each `Zones` entry maps a dealership's coordinates and interaction radius to a display title and one of the five `Config.UIStyles` themes; `useAnywhere` (when true) registers the catalog as a chat command instead of a location-based zone. `Config.Command`/`Config.AdminGroups` control the admin "show everything" command.

---

## 🎮 Controls & Usage

- **E key** (or `qb-target` interaction, per `Config.UseTarget`) — open the dealership catalog when standing near a configured zone.
- `/vehiclecatalog` (configurable via `Config.Command`) — admin-only, opens a catalog showing all vehicles regardless of dealership.

---

## 🔧 Troubleshooting

- **Catalog shows no vehicles for a dealership** — the `shop` field on the relevant entries in `qb-core/shared/vehicles.lua` must exactly match the zone's `name`.
- **E prompt doesn't appear / target option missing** — check `Config.UseTarget` matches the interaction method you have installed (`qb-target` must be running if set to `true`).
- **UI won't open near a zone** — confirm the player is within the zone's configured `radius` and that `mnc-vehiclecatalog` started after `qb-core`.
- **Admin command says permission denied** — the account's group must be listed in `Config.AdminGroups`.

---

## 📝 Credits & License

**Author**: Stan Leigh
**Version**: 3.0.0
**Framework**: QBCore

Distributed as part of the MnCLosSantos mod-dump collection — open source, please credit the original author if you edit and re-release.
