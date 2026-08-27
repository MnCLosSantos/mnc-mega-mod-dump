# 🔫 MNC Weapon UI V2

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.1.0-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
A live on-screen HUD that shows your currently equipped weapon's name, icon, and ammo count, updating in real time as you switch weapons or fire. Ships with 25 selectable visual themes saved per player, and auto-hides itself whenever a weapon HUD shouldn't be showing (unarmed, in a vehicle, game paused).

---

## ✨ Key Features

### 🎯 Live Weapon Tracking
- Watches the player's currently selected weapon and its ammo count, pushing an update to the NUI the instant either changes
- Automatically hides when unarmed, in a vehicle with a non-weapon selected, or while the game is paused — and a safety-net thread double-checks this every 700ms in case of respawns or menu glitches
- Resolves the weapon's icon automatically from whichever inventory is running — `ox_inventory`, `qb-inventory`, or `qs-inventory` — detected via `GetResourceState` at startup

### 🎨 25 Visual Styles
- Same style catalog pattern as the other MNC HUD tools: 25 named themes (Classic Green through Quantum Flux) with solid, linear, radial, and conic gradient backgrounds
- Style choice is saved per player to the database and reloaded automatically on join
- Change style anytime with `/weaponui [1-25]`

### 🔔 Configurable Notification Popup
- A separate, independently positioned/sized notification popup (`Config.NotifyUI`) that other events in the resource can trigger via `ShowNotification(type, title, description)`, themed to match your selected style

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |
| ox_inventory, qb-inventory, or qs-inventory | Latest | ⚠️ Optional — auto-detected for weapon icons; the HUD still works without one, just without an icon |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-weaponUi-V2/
```

> **Note**: this resource's internal `fxmanifest.lua` `name` field is still `mnc-weaponUi` from before it was versioned — that's cosmetic only. Use the actual folder name, `mnc-weaponUi-V2`, in your `ensure` line, since FiveM resolves resources by folder name.

### 2️⃣ Database Setup

The script **automatically creates** its style-preference table on first start — no manual SQL import needed.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-weaponUi-V2
```

### 4️⃣ Configure Settings

Edit `config.lua` to adjust the HUD's screen position, the notification popup's position, and the default style.

---

## ⚙️ Configuration Guide

```lua
Config = {}

Config.DefaultStyle = 1

Config.UI = {
    x = "15px",
    y = "537px",
    width = "auto",
    height = "auto",
}

Config.NotifyUI = {
    x = "1685px",
    y = "20px",
    width = "auto",
    height = "auto",
    duration = 5000,
}

Config.StyleCommand = "weaponui"

-- Auto-detected at resource start — do not hardcode
Config.UseOxInventory = GetResourceState('ox_inventory') == 'started'
Config.UseQbInventory = GetResourceState('qb-inventory') == 'started'
```

- `Config.UI` / `Config.NotifyUI` — plain CSS-style position/size values; adjust to fit your other HUD elements
- 25 entries in `Config.Styles` control the HUD's colors/gradients — add your own by appending a new numbered entry with `name`, `bg`, `text`, `accent`, and `description`

---

## 🎮 Controls & Usage

| Command | Description |
|---|---|
| `/weaponui [1-25]` | Switches to the given style number and saves it to your profile |

The HUD itself requires no interaction — it appears automatically whenever you have a weapon equipped and disappears when you don't.

---

## 🔧 Troubleshooting

**No weapon icon shows, just the name and ammo:**
- None of `ox_inventory`, `qb-inventory`, or `qs-inventory` were detected as running at resource start — start your inventory resource before this one, or ignore this if you don't need icons

**HUD doesn't hide in a vehicle:**
- The hide logic checks for personal weapon vs. vehicle-mounted weapons; some special vehicle weapon setups may need the detection logic in `client.lua` adjusted for your specific vehicles

**Style doesn't persist between sessions:**
- Confirm oxmysql is connected and the style-preference table was created without errors on first start

**HUD flickers or shows stale ammo briefly:**
- Expected during rapid weapon switching — the tracking loop polls every 110ms, so there's a small window before it catches up

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.1.0
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

1. **Database**: Requires oxmysql — the style-preference table is created automatically on first start
2. **Only one copy in this dump**: there is no separate non-V2 `mnc-weaponUi` resource included here despite the internal manifest name — just install this one normally
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Always know what you're packing. 🔫**
