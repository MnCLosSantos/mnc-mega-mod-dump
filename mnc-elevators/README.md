# 🛗 MNC Elevator System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.4.2-brightgreen.svg)]()

---

## 🌟 Overview

A **feature-rich elevator system** for QBCore-based FiveM servers.  
This script provides **immersive elevator interactions** with configurable floors, job and item-based access restrictions, animations, sound effects, and progress bars. Fully compatible with **ox_lib** and **qb-target**, it offers a seamless hybrid experience for both QB and OX frameworks.

---

## ✨ Key Features

- 🛗 **Configurable Elevators**  
  - Define multiple elevators with custom floors, coordinates, and labels.  
  - Restrict access by jobs or items for specific floors.  
  - Supports unlimited floors per elevator.
  - Separate arrival coordinates for precise teleport positioning (defaults to interaction coords if not specified).

- 🔒 **Access Control**  
  - Job-based access (e.g., restrict floors to specific roles like "ambulance").  
  - Item-based access (e.g., require keycards or specific items).  
  - Combined job and item checks for secure access.  

- 🎥 **Immersive Interactions**  
  - Smooth teleportation with screen fade effects.  
  - Configurable animations during elevator use (e.g., key fob animation).  
  - Optional "ding" sound effect on arrival.  
  - Progress bars or circles for realistic wait times (supports QB or OX styles).

- 🖥️ **Flexible UI**  
  - Supports **ox_lib** context menus or **qb-menu** for floor selection.  
  - Notification system compatible with **ox_lib** or **qb-core** notifications.  
  - Interaction via **qb-target** or classic [E] key prompts with 3D text or OX text UI.

- 🛠️ **Highly Configurable**  
  - Toggle animations, sounds, and progress bars.  
  - Customize progress bar type (bar, circle, or QB-style).  
  - Adjust progress duration and labels.  
  - Configurable sound effects and volumes.
  - Debug mode to show console prints and visualize interaction zones for easier setup.

- 🧹 **Optimized & Safe**  
  - Automatic cleanup of animations and tasks.  
  - Efficient threading for non-target interactions.  
  - Error handling for invalid elevator or floor data.

---

## 📋 Requirements

```bash
Dependency             Version   Required
---------------------- --------- ----------
QBCore Framework       Latest    🟠 Optional (job lock)
qb-inventory           Latest    🟠 Optional (item lock)
qb-target              Latest    🟠 Optional (target)
ox_lib                 Latest    🟠 Optional (instead of qb-menu/notify)
```

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone from GitHub
git clone https://github.com/YourUsername/mnc-elevators.git

# OR download ZIP from Releases
```

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-elevators/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure ox_lib
ensure mnc-elevators
```

### 3️⃣ Add Items (Optional)

If using item-based access, update `qb-core/shared/items.lua`:

```lua
['ems_keycard_heli'] = {
    ['name'] = 'ems_keycard_heli',
    ['label'] = 'EMS Helipad Keycard',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'ems_keycard_heli.png',
    ['unique'] = false,
    ['useable'] = false,
    ['shouldClose'] = true,
    ['description'] = 'Keycard for EMS helipad access'
},
['phone'] = {
    ['name'] = 'phone',
    ['label'] = 'Phone',
    ['weight'] = 200,
    ['type'] = 'item',
    ['image'] = 'phone.png',
    ['unique'] = false,
    ['useable'] = false,
    ['shouldClose'] = true,
    ['description'] = 'A smartphone'
},
```

### 4️⃣ Configure Elevators

Edit `config.lua` to define elevators, floors, access restrictions, and optional arrival coordinates:

```lua
Config.Elevators = {
    ["PillboxHospital"] = {
        [0] = {
            label = "Helipad",
            coords = vector4(338.85, -583.94, 74.17, 70.0),
            jobs = {"ambulance"},
            items = {"ems_keycard_heli"},
        },
        [1] = {
            label = "Main Floor",
            coords = vector4(311.19, -599.34, 43.29, 243.07),
            jobs = {},
            items = {},
        },
        [2] = {
            label = "Lower Garage",
            coords = vector4(319.87, -559.98, 28.74, 208.19),
            jobs = {"ambulance"},
            items = {"phone"},
        },
    },
    ["WiwangCityHall"] = {
        [0] = {
            label = "Floor 20 - Admin",
            coords = vector4(-824.13, -718.83, 113.77, 204.61),
            arrivalCoords = vector4(-823.81, -717.77, 113.77, 218.5),
            jobs = {"admin"},
            items = {},
        },
        [20] = {
            label = "Lobby",
            coords = vector4(-820.88, -698.91, 28.07, 65.36),
            arrivalCoords = vector4(-819.82, -699.8, 28.07, 90.216),
            jobs = {},
            items = {},
        },
    },
}
```

---

## ⚙️ Configuration

### 🎯 Elevator Setup Example

```lua
Config.Elevators = {
    ["ExampleElevator"] = {
        [0] = {
            label = "Rooftop",
            coords = vector4(x, y, z, heading),          -- Interaction point
            arrivalCoords = vector4(x, y, z, heading),   -- Optional: Arrival point
            jobs = {"police", "ambulance"},
            items = {"keycard"},
        },
        [1] = {
            label = "Ground Floor",
            coords = vector4(x, y, z, heading),
            jobs = {},
            items = {},
        },
    },
}
```

### 🎚️ UI & Interaction Options

```lua
Config.DebugMode = false      -- true = show debug prints and zone visuals, false = hide them
Config.MenuType = "qb"        -- "ox" or "qb" for menu system
Config.NotifyType = "ox"      -- "ox" or "qb" for notifications
Config.UseQbTarget = true     -- true = use qb-target, false = use [E] key
Config.PlayDingSound = true   -- Play sound on arrival
Config.DingSound = "ATM_WINDOW" -- Sound effect name
Config.PlayAnim = true        -- Play animation during teleport
Config.AnimDict = "anim@mp_player_intmenu@key_fob@"
Config.AnimName = "fob_click"
Config.UseProgress = false    -- Show progress bar/circle
Config.ProgressType = "bar"   -- "bar", "circle", or "QB"
Config.ProgressTime = 2500    -- Duration in milliseconds
Config.ProgressLabel = "Waiting for elevator..."
```

### 🐛 Debug Mode

When `Config.DebugMode = true`:
- Console prints show player data, job updates, access checks, teleport actions, and zone creation.
- Visual debug zones appear for `qb-target` polyzones and [E] key prompt markers.
- Useful for verifying coordinates and access restrictions during setup.

---

## 🎮 Controls

| Key | Action |
|-----|--------|
| `E` | Interact with elevator (if `Config.UseQbTarget = false`) |

---

## 📞 Support & Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/your-link)

---

## 📜 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).