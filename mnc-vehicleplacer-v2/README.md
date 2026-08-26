# 🚗 MNC Vehicle Placer

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-3.2.0-brightgreen.svg)]()

---

## 🌟 Overview

A **persistent vehicle placement manager** for QBCore-based FiveM servers. Allows admins to define static vehicle placements via config or dynamically add them through an in-game UI, with automatic proximity-based spawning/despawning, anti-drift protection, and full SQL persistence. Built with performance and ease of use in mind.

---

## ✨ Key Features

### 🖥️ Admin UI
- **Full in-game management panel** for adding, editing, and deleting vehicle placements
- **Live vehicle image previews** with multi-source fallback (FiveM docs → GitHub image repos → local fallback)
- **Search & filter** across all placements by name or model
- **Distance display** showing how far each vehicle is from the admin
- **Status badges** indicating Config vs SQL placements and proximity spawn state
- **Teleport to placement** directly from the UI

### 📍 Placement Mode
- **Drive-to-place workflow**: spawns the vehicle and warps the admin into it for precise positioning
- **Confirm or cancel** placement from the UI banner without closing the panel
- **Heading preserved** on confirmation so vehicles face exactly the right direction
- **Automatic freeze** after placement to prevent drift

### 🔄 Proximity Spawning
- **Automatic spawn/despawn** when any player enters or leaves the configured radius
- **Configurable spawn and despawn radii** (default 85 m / 90 m) with independent thresholds to prevent flicker
- **Configurable check interval** (default every 3.5 seconds) for performance tuning
- **Vehicles start dormant** and are only loaded into the world when needed

### 🛡️ Anti-Drift Protection
- **Configurable drift limit** (default 1.5 m) — vehicles that move beyond this threshold are flagged as lost
- **Position reporting** from clients back to the server every second for real-time tracking
- **Automatic re-freeze** when placement mode is exited

### 💾 Dual Placement Types
- **Config placements** — defined in `config.lua`, always available, read-only in the UI
- **SQL placements** — created and managed in-game, fully editable and deletable, persisted across restarts

### 🔔 Notifications
- **ox_lib notify** support with automatic fallback to QBCore native notifications

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
# Clone from GitHub
git clone https://github.com/MnCLosSantos/mnc-vehicleplacer-v2.git

# OR download ZIP from Releases
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-vehicleplacer/
```

### 2️⃣ Database Setup

The script **automatically creates** the required table on first start:

- `mnc_vehicle_placements` — stores all SQL-based vehicle placements

No manual SQL import needed!

### 3️⃣ Add to Server Config

```cfg
# server.cfg
ensure oxmysql
ensure ox_lib
ensure mnc-vehicleplacer
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize permissions, proximity radii, and static placements:

```lua
Config.Debug = false

Config.AdminGroups = { 'admin', 'superadmin', 'god' }

Config.ProximitySpawnRadius   = 85.0
Config.ProximityDespawnRadius = 90.0
Config.ProximityCheckInterval = 3500

Config.DriftLimit = 1.5
```

### 5️⃣ Define Static Placements (Optional)

Add config-based placements directly in `config.lua`:

```lua
Config.Placements = {
    [1] = {
        name         = "LA FESTA LIMO",
        vehicleModel = "Stretch",
        vehicleSpawn = vector4(1353.09, 1156.52, 113.57, 130.81),
    },
}
```

These are always available and cannot be edited or deleted via the UI.

---

## ⚙️ Configuration Guide

### 🖼️ Vehicle Image Paths

The UI attempts to load vehicle preview images from multiple sources in order:

```lua
Config.ImagePaths = {
    primary        = 'https://docs.fivem.net/vehicles/{model}.webp',
    github1        = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage/raw/main/{model}.png',
    github2        = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage-2/raw/main/{model}.png',
    local_fallback = './images/fallback.png',
}
```

Around **1,900 lore-friendly vehicles** are supported via the MnC image repos. For custom vehicles, upload images to your own GitHub repo using Git LFS and point one of the paths at it.

### 🔐 Admin Permissions

Access to `/vehplacer` is restricted by QBCore permission group:

```lua
Config.AdminGroups = { 'admin', 'superadmin', 'god' }
```

Add or remove groups as needed for your server's permission structure.

### 📏 Proximity Settings

```lua
Config.ProximitySpawnRadius   = 85.0   -- Spawn vehicle when a player is within this distance (metres)
Config.ProximityDespawnRadius = 90.0   -- Despawn when all players are beyond this distance (must be > spawn radius)
Config.ProximityCheckInterval = 3500   -- How often to run the proximity check (milliseconds)
Config.DriftLimit             = 1.5    -- Maximum allowed movement before a vehicle is considered lost (metres)
```

Keep the despawn radius slightly larger than the spawn radius to avoid vehicles rapidly toggling near the boundary.

---

## 🕹️ Usage

### Opening the UI

```
/vehplacer
```

Only players in a configured `AdminGroups` group can open the panel.

### Adding a Placement

1. Click **+ Add** in the sidebar
2. Fill in the name, vehicle model, and coordinates
3. Use **"Use My Position"** to auto-fill your current coords and heading
4. Click **Save** — the vehicle will spawn within ~15 seconds

### Editing a Placement

1. Select a placement from the list
2. Click **✏ Edit** in the detail panel
3. Adjust values and click **Save**

> **Tip:** Use Placement Mode (see below) to reposition a vehicle physically rather than editing coordinates manually.

### Placement Mode

1. Select an SQL placement and click **✏ Edit → (enter placement mode via the UI)**
2. The UI minimises and you are warped into the vehicle
3. Drive it to the desired location
4. Click **Confirm Position** in the banner — coordinates and heading are saved automatically

### Deleting a Placement

1. Select an SQL placement from the list
2. Click **🗑 Delete** and confirm in the dialog

> Config placements cannot be deleted via the UI — remove them from `config.lua` instead.

### Teleporting to a Placement

Select any placement and click **🚀 Teleport** to jump directly to its coordinates.

---

## ⚠️ Important Notes

1. **Vehicle limits**: Too many vehicles spawned in one area can prevent other vehicle spawns (e.g. from `/car` or garages). Keep placements spread out and avoid clustering more than **4 vehicles** near public or private garages.
2. **Admin workaround**: If you need to spawn a vehicle near a placement zone, noclip away from the area first (despawn distance).
3. **Script refresh**: Occasionally after adding a new placement you may need to restart the resource (`ensure mnc-vehicleplacer-v2`) for the last spawn to trigger correctly.
4. **Config vs SQL**: Config placements are always loaded regardless of database state. SQL placements require oxmysql to be running.
5. **Framework**: QBCore only — not compatible with ESX.

---

## 🐛 Troubleshooting

**UI won't open:**
- Confirm your character has the correct QBCore permission group set in `Config.AdminGroups`
- Check server console for errors on resource start

**Vehicle not spawning:**
- Walk within the `ProximitySpawnRadius` distance of the placement coords
- Wait one full `ProximityCheckInterval` cycle (default 3.5 s)
- Check that the vehicle model name is correct (case-insensitive but must be a valid GTA model)

**Vehicle drifting after placement:**
- Ensure you confirmed placement properly via the **Confirm Position** button
- Check `Config.DriftLimit` — lowering it makes the anti-drift system more sensitive

**Images not loading:**
- Verify the model name matches the image filename in the repo
- For custom vehicles, add images to a GitHub LFS repo and update `Config.ImagePaths`

**"Vehicle not found nearby!" error in placement mode:**
- The vehicle may not have streamed in yet — wait a moment and try again
- Increase `Config.ProximitySpawnRadius` if the vehicle is just outside the spawn threshold

---

## 📝 Credits

**Author**: Stan Leigh  
**Version**: 2.1.9  
**Framework**: QBCore  

### Contributing
Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with a detailed description of changes

---

## 📞 Support & Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6)

[![GitHub](https://img.shields.io/badge/GitHub-View%20Script-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/MnCLosSantos/mnc-vehiclespawner-v2)


---

## 🔄 Changelog

### Version 2.1.9 (Current Release)
**New Features:**
- ✨ Added real-time vehicle position tracking from client to server
- ✨ Implemented `trackedVehicles` table for per-key network ID tracking
- ✨ Added server-side position reporting event (`reportVehiclePos`)
- ✨ Added `placementPositionUpdated` event to sync confirmed coords back to the UI

**Improvements:**
- 🔧 Improved placement mode reliability with better entity control handoff
- 🔧 Enhanced anti-drift detection using live position reports
- 🔧 Refined confirm placement flow — player exits vehicle before freeze is applied

**Bug Fixes:**
- 🐛 Fixed vehicle occasionally remaining unfrozen after placement confirmation
- 🐛 Resolved tracked vehicle entries not being cleaned up on despawn
- 🐛 Corrected heading offset applied to player after confirming placement

---

### Version 2.0.0
**New Features:**
- ✨ Added multi-source image fallback chain (FiveM docs → GitHub repo 1 → GitHub repo 2 → local)
- ✨ Implemented distance display per placement in the sidebar list
- ✨ Added `statTotal` and `statLive` counters in the topbar

**Improvements:**
- 🔧 Improved image loading with sequential error fallback rather than parallel requests
- 🔧 Enhanced list rendering with active row highlighting
- 🔧 Added debounced model input preview in the Add/Edit form

**Bug Fixes:**
- 🐛 Fixed placement list not refreshing after save
- 🐛 Resolved image element remaining visible when all sources fail
- 🐛 Corrected form not clearing properly when switching from edit to add

---

### Version 1.5.0
**New Features:**
- ✨ Complete UI rewrite with sidebar + detail panel layout
- ✨ Added in-game placement mode (drive-to-position workflow)
- ✨ Implemented search and filter for placement list
- ✨ Added Config vs SQL badge indicators
- ✨ Added proximity status badges (Within Prox / Not Within Prox)
- ✨ Added delete confirmation dialog
- ✨ Added "Use My Position" button to auto-fill coords from player location

**Improvements:**
- 🔧 Unified notify system with ox_lib + QBCore fallback
- 🔧 Refactored NUI callbacks for cleaner client↔UI communication
- 🔧 ESC key now properly cancels placement mode and closes UI

**Bug Fixes:**
- 🐛 Fixed NUI focus not releasing on ESC press
- 🐛 Resolved placement mode leaving player stuck in vehicle on cancel
- 🐛 Fixed heading not being saved when confirming placement

---

### Version 1.0.0
**Features:**
- ✨ Initial release with proximity-based spawn/despawn system
- ✨ Config-defined static placements
- ✨ SQL-backed dynamic placements
- ✨ Basic admin UI for managing placements
- ✨ `/vehplacer` command with QBCore permission check
- ✨ ox_lib and oxmysql integration

---

## ⚠️ Disclaimer

For use on FiveM servers only. Respect Rockstar Games' Terms of Service. Community-supported — no official warranty provided.

---

**Keep your server's world alive with persistent vehicle placements! 🚗**