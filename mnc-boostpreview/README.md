# 🖼️ MNC Boost Preview

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A companion gallery for [`mnc-boostgauge`](../mnc-boostgauge): a `/boostpreview` (or press-E at a shop counter) browser that shows every one of that resource's 40 gauge styles, 20 bezels, and 20 curated presets before a player spends an item on one. It borrows `mnc-boostgauge`'s own CSS at runtime via `nui://`, so every preview looks pixel-identical to the real installed gauge — nothing is duplicated or hand-recreated.

---

## ✨ Key Features

### 🖼️ Full Style/Bezel/Preset Gallery
- Browses all 40 gauge styles and 20 bezels from `mnc-boostgauge`, plus its 20 curated style+bezel preset combinations (Classic Chrome, Digital Black, Matrix Green, and 17 more)
- Loads `mnc-boostgauge`'s actual `html/style.css` at preview time via the `nui://` scheme, so what you see in the gallery is exactly what the gauge looks like once installed — not a separate, potentially-drifting copy

### 📍 In-World Display Points
- `Config.Locations` defines shop counters/gauge racks where a floating **"[E] View Boost Gauges"** prompt appears when a player walks close enough
- `Config.UseMarker` draws a ground marker at each location; `Config.UseOxTarget` optionally adds an `ox_target` option at the same spots alongside the press-E prompt
- Tighter proximity checks only kick in within `Config.DrawDistance`, keeping the always-on distance check cheap

### ⌨️ Command & Keybind Access
- `/boostpreview` opens the gallery from anywhere
- `Config.RegisterKeybind` additionally registers a real FiveM keybind (default **F6**) that players can rebind in their FiveM settings, independent of the chat command

### 🔒 Optional Job Lock
- `Config.RestrictCommandToJobs` can gate the whole gallery to specific jobs (mechanic, autoexotics, admin, etc.) — off by default, since this is a view-only gallery that never touches items or vehicles

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| [`mnc-boostgauge`](../mnc-boostgauge) | Latest | ✅ Yes — this resource loads its CSS at runtime and previews its exact style/bezel/preset catalog |
| ox_target | Latest | ⚠️ Optional — only used if `Config.UseOxTarget = true` |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-boostpreview/
```

### 2️⃣ Add to Server Config

Make sure `mnc-boostgauge` starts **before** this resource, since the preview loads its CSS at runtime:

```lua
# server.cfg
ensure mnc-boostgauge
ensure mnc-boostpreview
```

No database setup required — this is a pure view-only gallery.

### 3️⃣ Configure Settings

Edit `config.lua` to set your own display point coordinates, the open command/keybind, and optional job restrictions.

---

## ⚙️ Configuration Guide

```lua
Config = Config or {}

Config.Debug = false

-- Folder name of your mnc-boostgauge install — only change if you renamed it
Config.SourceResource = 'mnc-boostgauge'

Config.OpenCommand = 'boostpreview'
Config.RegisterKeybind = true
Config.DefaultKeybind = 'F6'

Config.RestrictCommandToJobs = false
Config.AllowedJobs = {
    ['mechanic'] = true, ['mechanic2'] = true, ['autoexotics'] = true,
    ['mncracing'] = true, ['yachtclub'] = true, ['admin'] = true,
}

Config.PromptDistance = 5.5
Config.DrawDistance = 8.0
Config.KeyPrompt = 38 -- E

Config.UseMarker = true
Config.MarkerColor = { r = 0, g = 200, b = 255, a = 120 }
Config.UseOxTarget = false

Config.Locations = {
    { coords = vector3(103.87, 6622.33, 31.2), label = 'View Boost Gauges' },
    { coords = vector3(-325.19, -139.28, 38.39), label = 'View Boost Gauges' },
    { coords = vector3(-222.57, -1329.7, 30.27), label = 'View Boost Gauges' },
}

Config.DefaultPreviewStyle = 1
Config.DefaultPreviewBezel = 1
Config.BezelThickness = 9
```

- `Config.Locations` — replace the example coordinates with your own shop counters or gauge display racks
- `Config.StylesCount`, `Config.BezelsCount`, `Config.StyleItems`, `Config.BezelItems`, and `Config.Presets` mirror `mnc-boostgauge/config.lua` — if you add new styles/bezels/presets to that resource, mirror the additions here so they show up in the gallery too

---

## 🎮 Controls & Usage

| Input | Description |
|---|---|
| `/boostpreview` | Opens the gauge/bezel/preset gallery from anywhere |
| **F6** (default, rebindable) | Same as the command, via FiveM's own keybind settings |
| **E** near a configured display point | Opens the same gallery, in-context at a shop counter |

---

## 🔧 Troubleshooting

**Preview gauges look different from the real installed gauge:**
- Confirm `Config.SourceResource` matches your actual `mnc-boostgauge` folder name — the preview loads that resource's CSS by folder name via `nui://`

**A new style/bezel/preset you added to `mnc-boostgauge` doesn't show up here:**
- `Config.StyleItems`, `Config.BezelItems`, and `Config.Presets` must be manually mirrored in this resource's `config.lua` — they aren't read live from `mnc-boostgauge`

**Prompt never appears at a display point:**
- Check `Config.PromptDistance` and confirm your coordinates in `Config.Locations` are accurate for your map

**Command is blocked with no explanation:**
- Check `Config.RestrictCommandToJobs` and `Config.AllowedJobs` if you've enabled the job lock

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

1. **Requires `mnc-boostgauge`**: this is a preview-only companion, not a standalone gauge system — install and start `mnc-boostgauge` first
2. **View-only**: no items are consumed and no vehicles are modified by this resource; it's purely a browsing gallery
3. **Compatibility**: QBCore only — not compatible with ESX
4. **Legal**: For use on FiveM servers only, respect Rockstar's ToS

---

**Browse every style before you commit. 🖼️**
