# 📸 MNC Vehicle Image Generator

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![Version](https://img.shields.io/badge/Version-1.8.3-brightgreen.svg)]()

---

## 🌟 Overview
<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />
A powerful **automatic vehicle screenshot tool** for FiveM servers. Capture high-quality images of any vehicle with full camera control, Discord webhook integration, local PNG saving, and smart chunked processing to prevent entity pool crashes.

Built for developers and server owners who need clean, consistent vehicle images for documentation, websites, or in-game menus.

---

## ✨ Key Features

### 🎥 Professional Camera System
- Fully adjustable spawn coordinates, heading, camera offset, rotation & FOV
- Real-time **Preview Mode** with live updates
- Drag & resizable floating UI with opacity control

### 📤 Discord & Local Storage
- Automatic upload to Discord via webhook
- High-quality PNG download & local saving (`vehicle-images/` folder)
- Persistent `vehicle-images.json` tracking

### 🛡️ Smart Performance Handling
- **Chunked Capture** (configurable, recommended 25) to prevent entity/model pool crashes
- Automatic model loading timeout & skipping of invalid vehicles
- Memory cleanup between vehicles

### 🛠️ Quality of Life Tools
- `/vehlist` command to extract vehicle models from `qb-core/shared/vehicles.lua`
- "Select 250", "Select Undone", and bulk selection tools
- Auto-resume after chunk pauses
- Progress bar with ETA
- Skip failed vehicles gracefully

### 📊 Tracking & Resume
- JSON database tracks completed vehicles
- UI shows completed count with strikethrough
- Resume capture after server restart or chunk pause

---

## 📋 Requirements

| Dependency          | Version | Required |
|---------------------|---------|----------|
| **screenshot-basic** | Latest  | ✅ Yes   |
| QBCore Framework    | Latest  | Optional (for `/vehlist`) |
| ox_lib              | Latest  | Recommended (for notifications) |

---

## 🚀 Installation

### 1️⃣ Download & Extract

Place the resource in your resources folder:
```
[server-data]/resources/[custom]/mnc-vehicle-image-generator/
```

### 2️⃣ Add to Server Config

```lua
# server.cfg
ensure screenshot-basic
ensure mnc-vehicle-image-generator
```

### 3️⃣ Configure

Edit `config.lua`:

```lua
Config.DefaultWebhook = 'https://discord.com/api/webhooks/...'

Config.CameraSettings = {
    coords = vector3(90.48, -2731.8, 6.0),
    heading = 290.2,
    cameraOffset = vector3(6.8, -4, 0.6),
    cameraRotation = vector3(176.6, -181.1, -118.5),
    fov = 71.5
}

Config.CaptureDelay = 1000
Config.ChunkSize = 25
```

### 4️⃣ Vehicle List

Use the in-game command:
```bash
/vehlist
```
This will generate `vehlist1.lua`, `vehlist2.lua`, etc. Copy the contents into `Config.VehicleSpawnCodes` in `config.lua`.

---

## ⚙️ Configuration Guide

### VehicleSpawnCodes (config.lua)

```lua
Config.VehicleSpawnCodes = {
    'banshee3',
    'driftjester3',
    'polbuffalo6',
    -- ... up to 250 recommended per batch
}
```

### Camera Settings

All values are live-editable in the UI and can be saved permanently.

---

## 🎮 Usage

1. Type `/vehimage` or `/vehui` in chat
2. Paste your Discord webhook
3. Adjust camera settings (or use Preview)
4. Select vehicles (use **Select 250** for safety)
5. Set Chunk Size (25 recommended)
6. Click **Start Capture**

**Controls:**
- `ESC` – Close UI
- Drag logo to move window
- Resize from edges/corners
- Opacity slider in header

---

## 🔧 Troubleshooting

**Vehicle not appearing / black screen**
- Increase `Config.CaptureDelay`
- Make sure `screenshot-basic` is started before this resource

**Server crashing / freezing**
- Lower `Config.ChunkSize` (try 15–25)
- Never exceed 250 vehicles in one batch

**Images not saving**
- Check server console for errors
- Ensure resource has write permissions to `vehicle-images/` folder

**Webhook not working**
- Use the **Test** button in the UI
- Make sure the webhook has file upload permissions

**Model fails to load**
- Invalid spawn code or model not streamed

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 1.8.3
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

## 🔄 Changelog

### Version 1.8.3 (Current)
**New Features:**
- ✨ Fully draggable & resizable UI
- ✨ Opacity control
- ✨ Auto countdown + resume after chunks
- ✨ Improved model loading timeouts
- ✨ Better error handling and user feedback

**Improvements:**
- 🔧 Enhanced memory cleanup between vehicles
- 🔧 Smarter Discord URL handling (cdn.discordapp.com)
- 🔧 Progress ETA calculation
- 🔧 UI quality-of-life updates

**Bug Fixes:**
- 🐛 Fixed entity pool issues with aggressive cleanup
- 🐛 Resolved preview mode conflicts
- 🐛 Improved chunk resume logic

### Version 1.7.0
- Initial public release with chunking system
- Preview mode
- JSON + local PNG saving
- `/vehlist` command

---

## ⚠️ Important Notes

- **Never** run more than 250 vehicles at once without chunking.
- Always start `screenshot-basic` before this resource.
- Captured images are saved both locally (`vehicle-images/`) and uploaded to Discord.
- Tested stable on large vehicle lists (500+).

---

**Capture clean, professional vehicle images effortlessly! 📸**
