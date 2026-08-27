# 🏙️ MNC Mega Mod Dump

[![License: MNC](https://img.shields.io/badge/License-MNC__LICENSE__NDFTEAU-purple.svg)](MNC)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Resources](https://img.shields.io/badge/Resources-71-brightgreen.svg)]()

---

## 🌟 Overview

**MNC Mega Mod Dump** is a large collection of 71 independent QBCore/FiveM resources — vehicle ownership and logistics tools, handling and cosmetic vehicle mods, job and economy systems, HUDs, admin utilities, and assorted roleplay scripts — built and maintained by **Stan Leigh of MnCLosSantos**. Every resource in this dump has its own dedicated README covering installation, configuration, controls, and troubleshooting; this root README is the index that ties them all together.

A handful of tools in this dump ship in **more than one build** (a `-v1`/`-v2`/`-v3` naming pattern, or two differently-named builds of the same script). Where that's the case, **install only ONE build of that tool** — running two builds of the same resource at once means duplicate command/export registrations and, in some cases, corrupted shared database tables. The [Choosing Between Versions](#-choosing-between-versions) section below lists every one of these groups explicitly, and each affected resource's own README repeats the same warning with a side-by-side comparison table.

---

## 📋 Requirements

Nearly every resource in this dump targets the same baseline stack. Individual resources may add framework-specific extras (qb-target, qb-inventory, PolyZone, xsound, etc.) — check each resource's own README for its exact list.

| Dependency | Notes |
|---|---|
| [QBCore Framework](https://github.com/qbcore-framework) | Required by essentially every resource in this dump |
| [ox_lib](https://overextended.dev/ox_lib) | Required by the large majority — menus, notifications, progress bars, skill checks |
| [oxmysql](https://github.com/overextended/oxmysql) | Required by any resource with database persistence |
| [qb-target](https://github.com/qbcore-framework/qb-target) | Required by many interaction-based resources |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Clone or extract this dump into your resources folder — either as one folder containing every resource, or by copying individual resource subfolders wherever you organize custom resources:
```
[server-data]/resources/[custom]/mnc-mega-mod-dump/
```

### 2️⃣ Pick What You Actually Want

You do not need to run all 71 resources. Go through the category tables below, decide which tools fit your server, and **for any tool listed in [Choosing Between Versions](#-choosing-between-versions), pick exactly one build.**

### 3️⃣ Install Dependencies First

Make sure `qb-core`, `ox_lib`, `oxmysql`, and any resource-specific dependencies (`qb-target`, `qb-inventory`, `PolyZone`, `xsound`, etc.) are installed and started **before** any MNC resource that needs them.

### 4️⃣ `ensure` Each Resource You're Using

Add one `ensure` line per resource you've chosen to `server.cfg`, in dependency order (each resource's own README calls out anything it needs to start after). For example:

```lua
# server.cfg — example subset, not every resource
ensure oxmysql
ensure ox_lib
ensure qb-target
ensure mnc-jobgarage
ensure mnc-parking
ensure mnc-boostgauge
ensure mnc-boostpreview
```

### 5️⃣ Follow Each Resource's Own README

Every resource folder has its own README covering database setup, item registration, and `config.lua` — some create their own tables automatically, some ship a `.sql`/`install/` file you need to import manually, and some need items added to `qb-core/shared/items.lua` before they'll work. Read the specific resource's README before starting it.

---

## 🔀 Choosing Between Versions

These resources exist in more than one build in this dump. **Install only one build from each group** — each resource's own README has a full side-by-side comparison table under its "Choosing a Version" section.

| Tool | Builds in this dump | Why only one |
|---|---|---|
| Vehicle catalog UI | [`mnc-vehiclecatalog`](mnc-vehiclecatalog), [`mnc-vehiclecatalog-v2`](mnc-vehiclecatalog-v2) | v2 bundles its own ~500-vehicle database, admin live price editing, and a more resilient image fallback chain |
| Vehicle data editor | [`mnc-vehiclemanager`](mnc-vehiclemanager), [`mnc-vehiclemanager-v2`](mnc-vehiclemanager-v2) | v2 adds full-server vehicle discovery and bulk "Export All" for unregistered models |
| Static vehicle placer | [`mnc-vehicleplacer`](mnc-vehicleplacer), [`mnc-vehicleplacer-v2`](mnc-vehicleplacer-v2) | v2 adds an in-game UI for dynamic placements, proximity-based spawning, and SQL persistence |
| Admin vehicle spawner | [`mnc-vehiclespawner`](mnc-vehiclespawner), [`mnc-vehiclespawner-v2`](mnc-vehiclespawner-v2) | v2 adds live image previews and a duplicate-plate safety check |
| Engine swap shop | [`mnc-engineswap-v1`](mnc-engineswap-v1), [`mnc-engineswap-v2`](mnc-engineswap-v2) | Both create the same `vehicle_engines` table and register identical shop markers/blips — running both doubles every shop interaction |
| Free/spectator camera | [`mnc-freecam-v1`](mnc-freecam-v1), [`mnc-freecam-v2`](mnc-freecam-v2), [`mnc-freecam-v3`](mnc-freecam-v3) | All three bind the same `/freecam` command; v2 adds cinematography tools, v3 adds a full cinematic sequence editor and per-vehicle camera system on top of v2 |
| Item spawner (staff tool) | [`mnc-itemspawner`](mnc-itemspawner), [`mnc-itemluaspawner`](mnc-itemluaspawner) | Byte-for-byte identical code — the only difference is the shipped default for `Config.EnableJobLock` (open vs. locked) |

**Not version conflicts** — these look similar by name but are genuinely different, complementary tools and are safe to run together (or independently):

| Resources | Why they're not duplicates |
|---|---|
| [`mnc-carplay`](mnc-carplay) / [`mnc-ppod`](mnc-ppod) | Vehicle-mounted dash music unit vs. a personal handheld music player — different install targets, different mechanics |
| [`mnc-hydros`](mnc-hydros) / [`mnc-hydroui`](mnc-hydroui) | `mnc-hydros` is a handling-mod hydraulic **handbrake** upgrade; `mnc-hydroui` is a **HUD** for GTA's native lowrider hydraulics — unrelated systems that happen to share the word "hydraulics" |
| [`mnc-handui`](mnc-handui) / [`mnc-handuiPlate`](mnc-handuiPlate) | Identical handling editor, but one scopes changes per vehicle **model** and the other per **plate** — pick based on the granularity you want, or run both for different use cases |
| [`mnc-boostgauge`](mnc-boostgauge) / [`mnc-boostpreview`](mnc-boostpreview) | The gauge system and its optional style-preview gallery — `mnc-boostpreview` is a companion that requires `mnc-boostgauge` to function, not an alternate build of it |
| [`mnc-driftscore`](mnc-driftscore) / [`mnc-driftzones`](mnc-driftzones) | The drift-scoring HUD and its optional zone-trigger companion — `mnc-driftzones` requires `mnc-driftscore` to function, not an alternate build of it |

---

## 📚 Resource Index

### 🚗 Vehicle Ownership & Transfer
| Resource | Description |
|---|---|
| [`mnc-givecar`](mnc-givecar) | Instantly grant a vehicle to a player, for admins or automated systems (e.g. Tebex) |
| [`mnc-transfervehicle`](mnc-transfervehicle) | Pink-slip style ownership transfer — buyer and seller both sign a document, money and ownership change hands only on acceptance |
| [`mnc-startingcar`](mnc-startingcar) | One-time "pick your first car" showroom for brand-new characters, enforced server-side to one claim per character |
| [`mnc-seizecar-v2`](mnc-seizecar-v2) | Admin/law-enforcement tool to seize or wipe individual vehicles, a player's whole garage, or the entire vehicle database |
| [`mnc-callcar`](mnc-callcar) | Valet service — call a garaged vehicle for NPC-driven delivery with dynamic fees |
| [`mnc-takeatrip`](mnc-takeatrip) | Configurable teleport system with job/item restrictions, payment, and optional vehicle support |

### 🚚 Vehicle Logistics & Delivery
| Resource | Description |
|---|---|
| [`mnc-cardelivery`](mnc-cardelivery) | Timed vehicle delivery job with damage-scaled payout and an in-game admin route builder |
| [`mnc-cartransporter`](mnc-cartransporter) | Two-level flatbed trailer loading system carrying up to 6 vehicles at once, fully network-synced |
| [`mnc-towfinder`](mnc-towfinder) | Admin/dev diagnostic tool that scans every vehicle model for tow-hitch bones and outputs a ready-to-use Lua table |
| [`mnc-forkliftfix`](mnc-forkliftfix) | Network-synced forklift lifting, a lift-platform mode, and a vehicle-stacking system |
| [`mnc-extrafix`](mnc-extrafix) | Standalone fix for the trailer "extras" desync bug that glitches trailers for every client except the one who toggled them |

### 🏪 Vehicle Catalog, Spawner & Data Tools (Admin/Dev)
| Resource | Description |
|---|---|
| [`mnc-vehiclecatalog`](mnc-vehiclecatalog) / [`mnc-vehiclecatalog-v2`](mnc-vehiclecatalog-v2) | Multi-dealership vehicle browsing UI — **pick one**, see [Choosing Between Versions](#-choosing-between-versions) |
| [`mnc-vehiclemanager`](mnc-vehiclemanager) / [`mnc-vehiclemanager-v2`](mnc-vehiclemanager-v2) | In-game vehicle-data editor that exports to `vehiclesaves.lua` — **pick one** |
| [`mnc-vehicleplacer`](mnc-vehicleplacer) / [`mnc-vehicleplacer-v2`](mnc-vehicleplacer-v2) | Persistent static vehicle placement (car meets, dealership displays, fleets) — **pick one** |
| [`mnc-vehiclespawner`](mnc-vehiclespawner) / [`mnc-vehiclespawner-v2`](mnc-vehiclespawner-v2) | Admin NUI vehicle spawner with mods/paint/keys — **pick one** |
| [`mnc-vehicle-image-generator`](mnc-vehicle-image-generator) | Automatic vehicle screenshot tool with Discord webhook integration and chunked batch processing |

### 🎨 Vehicle Customization & Handling Mods
| Resource | Description |
|---|---|
| [`mnc-handui`](mnc-handui) | Live in-game handling editor scoped **per vehicle model** |
| [`mnc-handuiPlate`](mnc-handuiPlate) | Identical handling editor scoped **per vehicle plate** |
| [`mnc-customplate`](mnc-customplate) | Custom license plate text with live preview and duplicate-plate protection |
| [`mnc-diffs`](mnc-diffs) | Welded / Limited-Slip Differential upgrades via safe handling-float changes |
| [`mnc-drivelines`](mnc-drivelines) | Drive-type conversion — FWD/RWD/AWD torque split kits, installed per wheel |
| [`mnc-anglekit`](mnc-anglekit) | Tiered steering-angle kits for enhanced drift lock |
| [`mnc-hydros`](mnc-hydros) | Hydraulic handbrake kits (Street/Competition) that raise `fHandBrakeForce` |
| [`mnc-hydroui`](mnc-hydroui) | HUD for GTA's native lowrider hydraulics — corner bounce, full lift, 3-wheel lean |
| [`mnc-2step`](mnc-2step) | 2-step/launch control kits — rev-limiter bounce, rolling anti-lag, launch boost |
| [`mnc-antilag`](mnc-antilag) | Anti-lag exhaust flame and pop system for turbo vehicles |
| [`mnc-rollingcoal`](mnc-rollingcoal) | Exhaust smoke kits with EGR/DPF-delete prerequisites and adjustable smoke levels |
| [`mnc-engineswap-v1`](mnc-engineswap-v1) / [`mnc-engineswap-v2`](mnc-engineswap-v2) | Engine sound/handling swap shops — **pick one** |

### 🖥️ Vehicle HUDs & In-Car Media
| Resource | Description |
|---|---|
| [`mnc-boostgauge`](mnc-boostgauge) | Turbo boost gauge with 40 styles, 20 bezels, and remap-aware PSI scaling |
| [`mnc-boostpreview`](mnc-boostpreview) | Style/bezel/preset preview gallery for `mnc-boostgauge` (companion, requires it) |
| [`mnc-driftscore`](mnc-driftscore) | Drift scoring HUD with combos, 25+ visual styles, and persistent preferences |
| [`mnc-driftzones`](mnc-driftzones) | Admin-drawn zones that auto-toggle `mnc-driftscore`'s HUD (companion, requires it) |
| [`mnc-carplay`](mnc-carplay) | Dash-mounted tablet music unit with 15 skins and synced radius playback |
| [`mnc-ppod`](mnc-ppod) | Personal handheld music player with battery, headphones, and a placeable speaker |
| [`mnc-weaponUi-V2`](mnc-weaponUi-V2) | Live weapon/ammo HUD with 25 selectable visual themes |

### 🎥 Camera & World Tools
| Resource | Description |
|---|---|
| [`mnc-freecam-v1`](mnc-freecam-v1) / [`mnc-freecam-v2`](mnc-freecam-v2) / [`mnc-freecam-v3`](mnc-freecam-v3) | Free/spectator camera tool — **pick one** |
| [`mnc-safezones`](mnc-safezones) | Admin-authored polygon safe zones with job exemptions and a no-restart NUI panel |
| [`mnc-elevators`](mnc-elevators) | Configurable elevator system with job/item access restrictions |

### 👔 Jobs & Economy
| Resource | Description |
|---|---|
| [`mnc-jobclothing`](mnc-jobclothing) | Multi-location job locker rooms with persistent outfit saving and grade permissions |
| [`mnc-jobgarage`](mnc-jobgarage) | Full job-garage replacement: per-job fleets, custom roles, live checkout tracking, admin panel |
| [`mnc-jobhud`](mnc-jobhud) | Job/bank/cash HUD with 25 visual styles and persistent preferences |
| [`mnc-payments`](mnc-payments) | Job-based invoicing with a boss ledger view |
| [`mnc-pricesheets`](mnc-pricesheets) | Configurable catalog-style price sheet boards with live discounts and special offers |
| [`mnc-rentals`](mnc-rentals) | Vehicle rental system with temporary insurance/registration/inspection |
| [`mnc-shops`](mnc-shops) | Dynamic shop system with categorized items, stock, and ped shopkeepers |
| [`mnc-foodvans`](mnc-foodvans) | Purchasable/staffable mobile food van business with NPC customers and a van safe |
| [`mnc-insurance`](mnc-insurance) | Vehicle insurance, registration, and inspection paperwork system |
| [`mnc-gruppe6`](mnc-gruppe6) | Immersive Gruppe 6 security job with a two-phase collection route and tablet UI |

### 🛠️ Vehicle Maintenance & Garage Tools
| Resource | Description |
|---|---|
| [`mnc-jacks`](mnc-jacks) | Per-side car jack and axle stand system |
| [`mnc-parking`](mnc-parking) | Persistent vehicle parking with locks, tarps/covers, and trailer parking |
| [`mnc-repairpoints`](mnc-repairpoints) | Pay-to-repair stations with free emergency bays and mechanic-on-duty hiding |
| [`mnc-respraypoints`](mnc-respraypoints) | Pay-to-respray stations with the same mechanic-duty and emergency-bay logic |

### 🛡️ Admin & Item Tools
| Resource | Description |
|---|---|
| [`mnc-adminmenu`](mnc-adminmenu) | Player lookup/management panel (jobs, money, vehicles, inventory) plus a self-service `/movegarage` |
| [`mnc-itemspawner`](mnc-itemspawner) / [`mnc-itemluaspawner`](mnc-itemluaspawner) | Auto-populated item spawner for staff — **pick one** |
| [`mnc-ids`](mnc-ids) | Press-key ID check system showing your server ID above your head |

### 🎭 Roleplay & Immersion
| Resource | Description |
|---|---|
| [`mnc-crutch`](mnc-crutch) | EMS mobility-aid system (crutches and canes) with movement restrictions |
| [`mnc-muteondeath`](mnc-muteondeath) | Automatically mutes players via pma-voice while dead or in last stand |
| [`mnc-robnpc`](mnc-robnpc) | Weapon-based pedestrian robbery with police GPS alerts |
| [`mnc-scrapnbins`](mnc-scrapnbins) | Bin diving and scrap searching with tiered loot and a needle-prick risk |
| [`mnc-dogends`](mnc-dogends) | Pick up cigarette butts and roll your own cigarettes |
| [`mnc-vapes`](mnc-vapes) | Craftable vape devices and juices with battery management |

### 🎰 Gambling & Collectibles
| Resource | Description |
|---|---|
| [`mnc-scratchcards`](mnc-scratchcards) | 5-tier scratch card minigame with server-validated rewards |
| [`mnc-tradingcards`](mnc-tradingcards) | Collectible card packs, binders, holographic rarities, and an in-world dealer |

---

## 📝 Credits & License

**Author**: Stan Leigh
**Collection Amount**: 71 resources

This entire collection is licensed under **MNC_LICENSE_NDFTEAU** (*No Distribution, Free To Edit And Use*) — Every individual resource in this dump is covered by the same license.

- ✅ Use and edit any resource in this dump freely on your own personal or paid server(s)
- ✅ Modify the code however you need to fit your server
- ❌ Do not redistribute, resell, or re-upload this dump or any individual resource from it (modified or not) as your own work
- ❌ Do not publish forks or copies of this dump outside of channels authorized by MnCLosSantos / carrot

---

## 📞 Support & Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6)
- 🐛 **Issues**: open an issue on the [mnc-mega-mod-dump GitHub repo](https://github.com/MnCLosSantos/mnc-mega-mod-dump/issues)
- 📖 Each resource's own README covers its configuration and troubleshooting in depth — check there first

---

## ⚠️ Important Notes

1. **Read before installing**: not every resource needs every dependency listed above — check each resource's own README for its exact requirement list
2. **Version conflicts**: several tools ship multiple builds in this dump — see [Choosing Between Versions](#-choosing-between-versions) and never run two builds of the same tool together
3. **Database**: most resources with persistence create their own tables automatically on first start; a few ship a `.sql`/`install/` file that needs manual import — each resource's README says which
4. **Compatibility**: this entire collection targets QBCore — none of it is guaranteed compatible with ESX
5. **Legal**: For use on FiveM servers only, respect Rockstar's Terms of Service

---

**71 resources, one collection, one license. Pick what fits your server. 🏙️**
