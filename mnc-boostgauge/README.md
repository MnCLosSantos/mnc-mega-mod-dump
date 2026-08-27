# 🏎️ MNC Boost Gauge System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-2.4.7-brightgreen.svg)]()

---

## 🌟 Overview

A **feature-rich turbo boost gauge system** for QBCore-based FiveM servers.  
This script provides **40 unique gauge styles**, **20 bezels**, **20 preset combinations**, **remap-aware PSI scaling**, **persistent vehicle customization**, **realistic boost physics (no perfomance changes)**, **needle sweep animations**, and **vehicle lighting effects**.  
Fully optimized for **ox_lib**, **oxmysql**, **qb-core**, and **mnc-performanceparts** integration.

---

## ✨ Key Features

- 🎨 **40 Unique Gauge Styles**  
  - Classic analog designs with chrome needles.
  - Modern digital HUD displays (no needle).
  - Neon-themed gauges (cyan, green, orange, purple).
  - Retro JDM and synthwave aesthetics.
  - Luxury gold, carbon fiber, and glass styles.
  - Digital displays with animated effects.

- 💍 **20 Animated Bezels**  
  - Chrome, satin black, and carbon fiber classics.
  - Neon bezels (amber, green, blue, magenta, red, cyan).
  - Animated effects (holographic pulse, rainbow shift, plasma surge).
  - Special effects (lava glow, aurora shift, pulsar wave).
  - Premium finishes (mirror edge, galactic sparkle, chameleon flux).

- 🎁 **20 Preset Combinations**  
  - Pre-configured style + bezel combos.
  - One-item installation for easy setup.
  - Professional themes (Classic Chrome, Digital Black, Matrix Green).
  - Aesthetic combinations (Sunset Blue, Cosmic Holo, Quantum Plasma).

- 🔧 **Remap-Aware PSI System**  
  - Integrates with **mnc-performanceparts** for dynamic PSI scaling.
  - Stage 0 (stock turbo): 6.0 PSI baseline.
  - Stage 1-4+ remaps: 12-30 PSI range.
  - Custom turbo support (RX280, RX560, RX660, RX890).
  - Automatic PSI detection and gauge scaling.

- 🚗 **Persistent Vehicle Customization**  
  - **Database-backed style & bezel storage** per vehicle plate.
  - Customizations persist across sessions.
  - Easy installation via usable items or command.
  - Swappable parts return previous items.
  - Per-vehicle gauge memory.

- 🎯 **Realistic Boost Physics**  
  - RPM-based boost calculation (idle to redline).
  - Throttle position sensitivity.
  - Engine load simulation (speed vs RPM).
  - Smooth needle animation (configurable smoothing).
  - Zero boost without turbo mod 18.

- 🌊 **Needle Sweep Animation**  
  - Dramatic startup sweep (0° to 360° and back).
  - Triggers automatically on engine start.
  - Smooth animation timing (1 second duration).
  - Prevents sweep spam with cooldown.

- ⚠️ **Warning Systems**  
  - High PSI warning icon (85%+ threshold).
  - Amber warning flash animation.
  - RPM-based visual effects.
  - Red tick marks at high RPM.

- 💡 **Vehicle Lighting Effects**  
  - Regular lights: Subtle gauge glow.
  - High beams: Intense illumination.
  - Dynamic brightness scaling.
  - Enhanced text shadows and glow.

- 🎮 **Interactive Installation**  
  - Optional minigame (skillcheck) for installation.
  - Configurable difficulty (1-3 levels).
  - Progress bar/circle animations.
  - Installation animations with props.
  - Cancel-safe installation process.

---

## 📋 Requirements

```bash
Dependency             Version   Required
---------------------- --------- ----------
QBCore Framework       Latest    ✅ Yes
qb-inventory           Latest    ✅ Yes
ox_lib                 Latest    ✅ Yes
oxmysql                Latest    ✅ Yes
mnc-performanceparts   Latest    ⚠️ Optional
```

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-boostgauge/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-boostgauge/` folder
```

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-boostgauge/
```

### 2️⃣ Database Setup

The script **automatically creates** the required database table on first start:

```sql
CREATE TABLE IF NOT EXISTS vehicle_gauges (
    plate VARCHAR(8) NOT NULL,
    style INT DEFAULT 1,
    bezel INT DEFAULT 1,
    PRIMARY KEY (plate)
)
```

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-performanceparts  # Optional - for remap awareness
ensure mnc-boostgauge
```

### 4️⃣ Add Items

Update `qb-core/shared/items.lua`:

```lua
    -- Boost Gauge Items
    ['boostgauge_classic']    = {['name'] = 'boostgauge_classic', ['label'] = 'Classic Analog Chrome', ['weight'] = 1000, ['type'] = 'item', ['image'] = 'boostgauge_classic.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Classic analog chrome boost gauge for a timeless design.'},
    ['boostgauge_digital']    = {['name'] = 'boostgauge_digital', ['label'] = 'Digital HUD (Cyan)', ['weight'] = 900, ['type'] = 'item', ['image'] = 'boostgauge_digital.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Digital cyan HUD boost gauge for a futuristic display.'},
    ['boostgauge_retro']      = {['name'] = 'boostgauge_retro', ['label'] = 'Retro Orange JDM', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_retro.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Retro orange JDM boost gauge for a nostalgic vibe.'},
    ['boostgauge_frost']      = {['name'] = 'boostgauge_frost', ['label'] = 'Minimal Frost', ['weight'] = 900, ['type'] = 'item', ['image'] = 'boostgauge_frost.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Minimal frost boost gauge for a clean, icy look.'},
    ['boostgauge_matrix']     = {['name'] = 'boostgauge_matrix', ['label'] = 'Neon Green Matrix', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_matrix.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Neon green matrix boost gauge for a tech-inspired style.'},
    ['boostgauge_carbon']     = {['name'] = 'boostgauge_carbon', ['label'] = 'Carbon Fiber Sport', ['weight'] = 900, ['type'] = 'item', ['image'] = 'boostgauge_carbon.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Carbon fiber sport boost gauge for a lightweight, sporty feel.'},
    ['boostgauge_racing']     = {['name'] = 'boostgauge_racing', ['label'] = 'Red Racing', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_racing.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Red racing boost gauge for a high-energy look.'},
    ['boostgauge_glass']      = {['name'] = 'boostgauge_glass', ['label'] = 'Blue Glass', ['weight'] = 1000, ['type'] = 'item', ['image'] = 'boostgauge_glass.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Blue glass boost gauge for a sleek, transparent design.'},
    ['boostgauge_phantom']    = {['name'] = 'boostgauge_phantom', ['label'] = 'Purple Phantom', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_phantom.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Purple phantom boost gauge for a mysterious vibe.'},
    ['boostgauge_emerald']    = {['name'] = 'boostgauge_emerald', ['label'] = 'Emerald Glow', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_emerald.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Emerald glow boost gauge for a vibrant green display.'},
    ['boostgauge_sunset']     = {['name'] = 'boostgauge_sunset', ['label'] = 'Amber Sunset', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_sunset.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Amber sunset boost gauge for a warm, glowing look.'},
    ['boostgauge_track']      = {['name'] = 'boostgauge_track', ['label'] = 'Sky Blue Track', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_track.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Sky blue track boost gauge for a crisp, racing-inspired design.'},
    ['boostgauge_drift']      = {['name'] = 'boostgauge_drift', ['label'] = 'Pink Drift', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_drift.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Pink drift boost gauge for a playful, stylish look.'},
    ['boostgauge_electric']   = {['name'] = 'boostgauge_electric', ['label'] = 'Lime Electric', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_electric.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Lime electric boost gauge for a bright, energetic display.'},
    ['boostgauge_luxury']     = {['name'] = 'boostgauge_luxury', ['label'] = 'Gold Luxury', ['weight'] = 1000, ['type'] = 'item', ['image'] = 'boostgauge_luxury.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Gold luxury boost gauge for a premium, elegant style.'},
    ['boostgauge_wave']       = {['name'] = 'boostgauge_wave', ['label'] = 'Teal Wave', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_wave.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Teal wave boost gauge for a smooth, oceanic look.'},
    ['boostgauge_storm']      = {['name'] = 'boostgauge_storm', ['label'] = 'Violet Storm', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_storm.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Violet storm boost gauge for a bold, dynamic design.'},
    ['boostgauge_fresh']      = {['name'] = 'boostgauge_fresh', ['label'] = 'Mint Fresh', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_fresh.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Mint fresh boost gauge for a cool, refreshing style.'},
    ['boostgauge_muscle']     = {['name'] = 'boostgauge_muscle', ['label'] = 'Bronze Muscle', ['weight'] = 1000, ['type'] = 'item', ['image'] = 'boostgauge_muscle.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Bronze muscle boost gauge for a rugged, powerful look.'},
    ['boostgauge_pro']        = {['name'] = 'boostgauge_pro', ['label'] = 'Azure Pro', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_pro.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Azure pro boost gauge for a professional, sleek design.'},
    ['boostgauge_fury']       = {['name'] = 'boostgauge_fury', ['label'] = 'Crimson Fury', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_fury.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Crimson fury boost gauge for an intense, fiery display.'},
    ['boostgauge_turbo']      = {['name'] = 'boostgauge_turbo', ['label'] = 'Aqua Turbo', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_turbo.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Aqua turbo boost gauge for a vibrant, turbocharged look.'},
    ['boostgauge_night']      = {['name'] = 'boostgauge_night', ['label'] = 'Orchid Night', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_night.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Orchid night boost gauge for a dark, elegant style.'},
    ['boostgauge_flash']      = {['name'] = 'boostgauge_flash', ['label'] = 'Chartreuse Flash', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_flash.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Chartreuse flash boost gauge for a bright, flashy display.'},
    ['boostgauge_arctic']     = {['name'] = 'boostgauge_arctic', ['label'] = 'Ice Blue Arctic', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_arctic.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Ice blue arctic boost gauge for a cool, frosty look.'},
    ['boostgauge_holo']       = {['name'] = 'boostgauge_holo', ['label'] = 'Holographic Digital', ['weight'] = 900, ['type'] = 'item', ['image'] = 'boostgauge_holo.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Holographic digital boost gauge with no needle for a futuristic look.'},
    ['boostgauge_synthwave']  = {['name'] = 'boostgauge_synthwave', ['label'] = '80s Retro Synthwave', ['weight'] = 900, ['type'] = 'item', ['image'] = 'boostgauge_synthwave.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = '80s retro synthwave digital boost gauge with no needle.'},
    ['boostgauge_modern']     = {['name'] = 'boostgauge_modern', ['label'] = 'Modern Analog', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_modern.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Modern analog boost gauge for a sleek, contemporary design.'},
    ['boostgauge_stealth']    = {['name'] = 'boostgauge_stealth', ['label'] = 'Stealth Blackout', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_stealth.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Stealth blackout boost gauge for a minimalist, dark style.'},
    ['boostgauge_cosmic']     = {['name'] = 'boostgauge_cosmic', ['label'] = 'Cosmic Nebula', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_cosmic.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Cosmic nebula boost gauge for a starry, otherworldly look.'},
    ['boostgauge_inferno']    = {['name'] = 'boostgauge_inferno', ['label'] = 'Inferno Blaze', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_inferno.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Inferno blaze boost gauge for a fiery, intense display.'},
    ['boostgauge_aurora']     = {['name'] = 'boostgauge_aurora', ['label'] = 'Aurora Borealis', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_aurora.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Aurora borealis boost gauge for a mesmerizing, colorful glow.'},
    ['boostgauge_vapor']      = {['name'] = 'boostgauge_vapor', ['label'] = 'Vaporwave Aesthetic', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_vapor.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Vaporwave aesthetic boost gauge for a retro-futuristic vibe.'},
    ['boostgauge_cyberpunk']  = {['name'] = 'boostgauge_cyberpunk', ['label'] = 'Cyberpunk Neon', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_cyberpunk.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Cyberpunk neon boost gauge for a high-tech, neon-lit look.'},
    ['boostgauge_crystal']    = {['name'] = 'boostgauge_crystal', ['label'] = 'Crystal Prism', ['weight'] = 1000, ['type'] = 'item', ['image'] = 'boostgauge_crystal.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Crystal prism boost gauge for a sparkling, prismatic effect.'},
    ['boostgauge_magma']      = {['name'] = 'boostgauge_magma', ['label'] = 'Magma Flow', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_magma.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Magma flow boost gauge for a molten, fiery design.'},
    ['boostgauge_eclipse']    = {['name'] = 'boostgauge_eclipse', ['label'] = 'Solar Eclipse', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_eclipse.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Solar eclipse boost gauge for a dark, celestial look.'},
    ['boostgauge_zenith']     = {['name'] = 'boostgauge_zenith', ['label'] = 'Zenith Horizon', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_zenith.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Zenith horizon boost gauge for a serene, sky-inspired design.'},
    ['boostgauge_nova']       = {['name'] = 'boostgauge_nova', ['label'] = 'Supernova Burst', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_nova.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Supernova burst boost gauge for an explosive, radiant look.'},
    ['boostgauge_quantum']    = {['name'] = 'boostgauge_quantum', ['label'] = 'Quantum Flux', ['weight'] = 950, ['type'] = 'item', ['image'] = 'boostgauge_quantum.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Quantum flux boost gauge for a cutting-edge, sci-fi style.'},

    -- Bezel Items
    ['bezel_chrome']          = {['name'] = 'bezel_chrome', ['label'] = 'Chrome Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_chrome.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Shiny chrome bezel for a classic look.'},
    ['bezel_satinblack']      = {['name'] = 'bezel_satinblack', ['label'] = 'Satin Black Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_satinblack.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Sleek satin black bezel for a modern style.'},
    ['bezel_carbonfiber']     = {['name'] = 'bezel_carbonfiber', ['label'] = 'Carbon Fiber Bezel', ['weight'] = 450, ['type'] = 'item', ['image'] = 'bezel_carbonfiber.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Lightweight carbon fiber bezel for a sporty aesthetic.'},
    ['bezel_neonamber']       = {['name'] = 'bezel_neonamber', ['label'] = 'Neon Amber Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_neonamber.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Vibrant neon amber bezel for a bold look.'},
    ['bezel_neongreen']       = {['name'] = 'bezel_neongreen', ['label'] = 'Neon Green Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_neongreen.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Eye-catching neon green bezel for a striking appearance.'},
    ['bezel_neonblue']        = {['name'] = 'bezel_neonblue', ['label'] = 'Neon Blue Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_neonblue.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Bright neon blue bezel for a cool, modern vibe.'},
    ['bezel_neonmagenta']     = {['name'] = 'bezel_neonmagenta', ['label'] = 'Neon Magenta Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_neonmagenta.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Vivid neon magenta bezel for a unique style.'},
    ['bezel_neonred']         = {['name'] = 'bezel_neonred', ['label'] = 'Neon Red Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_neonred.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Bold neon red bezel for a fiery look.'},
    ['bezel_retrosynth']      = {['name'] = 'bezel_retrosynth', ['label'] = 'Retro Synthwave Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_retrosynth.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Throwback synthwave bezel with neon 80s vibes.'},
    ['bezel_rainbow']         = {['name'] = 'bezel_rainbow', ['label'] = 'Rainbow Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_rainbow.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Color-shifting rainbow bezel for a vibrant, dynamic look.'},
    ['bezel_holographic']     = {['name'] = 'bezel_holographic', ['label'] = 'Holographic Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_holographic.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Holographic bezel for a futuristic, shimmering effect.'},
    ['bezel_mattegold']       = {['name'] = 'bezel_mattegold', ['label'] = 'Matte Gold Bezel', ['weight'] = 550, ['type'] = 'item', ['image'] = 'bezel_mattegold.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Matte gold bezel for a luxurious, understated look.'},
    ['bezel_neoncyan']        = {['name'] = 'bezel_neoncyan', ['label'] = 'Neon Cyan Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_neoncyan.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Bright neon cyan bezel for a vibrant, modern style.'},
    ['bezel_frostedglass']    = {['name'] = 'bezel_frostedglass', ['label'] = 'Frosted Glass Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_frostedglass.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Frosted glass bezel for a sleek, translucent aesthetic.'},
    ['bezel_lava']            = {['name'] = 'bezel_lava', ['label'] = 'Lava Glow Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_lava.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Lava glow bezel for a molten, fiery appearance.'},
    ['bezel_pulsar']          = {['name'] = 'bezel_pulsar', ['label'] = 'Pulsar Effect Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_pulsar.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Pulsar effect bezel for a dynamic, pulsating look.'},
    ['bezel_chameleon']       = {['name'] = 'bezel_chameleon', ['label'] = 'Chameleon Color-Shift Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_chameleon.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Chameleon color-shift bezel for a unique, shifting hue.'},
    ['bezel_mirror']          = {['name'] = 'bezel_mirror', ['label'] = 'Mirror Finish Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_mirror.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Mirror finish bezel for a reflective, polished look.'},
    ['bezel_galactic']        = {['name'] = 'bezel_galactic', ['label'] = 'Galactic Sparkle Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_galactic.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Galactic sparkle bezel for a starry, cosmic effect.'},
    ['bezel_plasma']          = {['name'] = 'bezel_plasma', ['label'] = 'Plasma Energy Bezel', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bezel_plasma.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Plasma energy bezel for a high-energy, sci-fi style.'},

    -- Boost Gauge Preset Items
    ['boostgauge_preset1']    = {['name'] = 'boostgauge_preset1', ['label'] = 'Classic Chrome Preset', ['weight'] = 1500, ['type'] = 'item', ['image'] = 'boostgauge_preset1.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Classic Analog Chrome gauge with Chrome Bezel.'},
    ['boostgauge_preset2']    = {['name'] = 'boostgauge_preset2', ['label'] = 'Digital Black Preset', ['weight'] = 1400, ['type'] = 'item', ['image'] = 'boostgauge_preset2.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Digital HUD (Cyan) gauge with Satin Black Bezel.'},
    ['boostgauge_preset3']    = {['name'] = 'boostgauge_preset3', ['label'] = 'Retro Carbon Preset', ['weight'] = 1400, ['type'] = 'item', ['image'] = 'boostgauge_preset3.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Retro Orange JDM gauge with Carbon Fiber Bezel.'},
    ['boostgauge_preset4']    = {['name'] = 'boostgauge_preset4', ['label'] = 'Matrix Green Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset4.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Neon Green Matrix gauge with Neon Green Bezel.'},
    ['boostgauge_preset5']    = {['name'] = 'boostgauge_preset5', ['label'] = 'Phantom Magenta Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset5.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Purple Phantom gauge with Neon Magenta Bezel.'},
    ['boostgauge_preset6']    = {['name'] = 'boostgauge_preset6', ['label'] = 'Emerald Amber Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset6.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Emerald Glow gauge with Neon Amber Bezel.'},
    ['boostgauge_preset7']    = {['name'] = 'boostgauge_preset7', ['label'] = 'Sunset Blue Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset7.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Amber Sunset gauge with Neon Blue Bezel.'},
    ['boostgauge_preset8']    = {['name'] = 'boostgauge_preset8', ['label'] = 'Drift Red Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset8.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Pink Drift gauge with Neon Red Bezel.'},
    ['boostgauge_preset9']    = {['name'] = 'boostgauge_preset9', ['label'] = 'Luxury Gold Preset', ['weight'] = 1550, ['type'] = 'item', ['image'] = 'boostgauge_preset9.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Gold Luxury gauge with Matte Gold Bezel.'},
    ['boostgauge_preset10']   = {['name'] = 'boostgauge_preset10', ['label'] = 'Storm Synth Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset10.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Violet Storm gauge with Retro Synthwave Bezel.'},
    ['boostgauge_preset11']   = {['name'] = 'boostgauge_preset11', ['label'] = 'Azure Cyan Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset11.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Azure Pro gauge with Neon Cyan Bezel.'},
    ['boostgauge_preset12']   = {['name'] = 'boostgauge_preset12', ['label'] = 'Aqua Glass Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset12.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Aqua Turbo gauge with Frosted Glass Bezel.'},
    ['boostgauge_preset13']   = {['name'] = 'boostgauge_preset13', ['label'] = 'Arctic Lava Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset13.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Ice Blue Arctic gauge with Lava Glow Bezel.'},
    ['boostgauge_preset14']   = {['name'] = 'boostgauge_preset14', ['label'] = 'Synthwave Rainbow Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset14.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining 80s Retro Synthwave gauge with Rainbow Bezel.'},
    ['boostgauge_preset15']   = {['name'] = 'boostgauge_preset15', ['label'] = 'Cosmic Holo Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset15.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Cosmic Nebula gauge with Holographic Bezel.'},
    ['boostgauge_preset16']   = {['name'] = 'boostgauge_preset16', ['label'] = 'Aurora Pulsar Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset16.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Aurora Borealis gauge with Pulsar Effect Bezel.'},
    ['boostgauge_preset17']   = {['name'] = 'boostgauge_preset17', ['label'] = 'Cyberpunk Chameleon Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset17.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Cyberpunk Neon gauge with Chameleon Color-Shift Bezel.'},
    ['boostgauge_preset18']   = {['name'] = 'boostgauge_preset18', ['label'] = 'Magma Mirror Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset18.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Magma Flow gauge with Mirror Finish Bezel.'},
    ['boostgauge_preset19']   = {['name'] = 'boostgauge_preset19', ['label'] = 'Zenith Galactic Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset19.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Zenith Horizon gauge with Galactic Sparkle Bezel.'},
    ['boostgauge_preset20']   = {['name'] = 'boostgauge_preset20', ['label'] = 'Quantum Plasma Preset', ['weight'] = 1450, ['type'] = 'item', ['image'] = 'boostgauge_preset20.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A preset combining Quantum Flux gauge with Plasma Energy Bezel.'},

```

### 5️⃣ Configure Settings

Edit `config.lua` to customize your setup:

```lua
-- Position and scale
Config.UI = {
    x = 0.204,              -- Horizontal position (0-1)
    y = 0.75,               -- Vertical position (0-1)
    scale = 0.30,           -- Size multiplier
    defaultStyle = 1,       -- Starting gauge style
    defaultBezel = 1,       -- Starting bezel
    bezelThickness = 9,     -- Bezel border size (px)
}

-- Installation settings
Config.Installation = {
    requireMinigame = true,     -- Enable skillcheck minigame
    minigameDifficulty = 3,     -- 1=easy, 2=medium, 3=hard
    progressDuration = 5000,    -- Progress bar time (ms)
    progressType = 'bar',       -- 'bar' or 'circle'
    useAnimation = true,        -- Play installation animation
    animDict = 'mini@repair',
    animClip = 'fixing_a_ped',
}

-- PSI settings for standard turbo
Config.Mod18StandardPSI = 6.0

-- Remap PSI values (requires mnc-performanceparts)
Config.RemapPSI = {
    stage0 = 6.0,
    stage1 = 16.0,
    stage2 = 20.0,
    stage3 = 24.0,
    stage4 = 30.0,
}

-- Custom turbo PSI values  (requires mnc-performanceparts)
Config.TurboPSI = {
    turbo_rx280 = 12.0,
    turbo_rx560 = 16.0,
    turbo_rx660 = 20.0,
    turbo_rx890 = 26.0,
}
```

---

## ⚙️ Configuration

### 🎯 Available Gauge Styles (40 Total)

#### **Analog Gauges (1-35)**
```bash
Style  Name                    Description
------ ----------------------- ----------------------------------
1      Classic Analog Chrome   Traditional gauge with chrome needle
2      Digital HUD (Cyan)      Cyan digital display
3      Retro Orange JDM        Retro Japanese style
4      Frost Green             Matrix-inspired green gauge
5      Neon Green Matrix       Bright neon matrix theme
6      Carbon Fiber Sport      Carbon weave background
7      Red Racing              Racing red theme
8      Blue Glass              Transparent blue glass
9      Purple Phantom          Deep purple mystique
10     Emerald Glow            Green emerald theme
11     Amber Sunset            Orange sunset glow
12     Sky Blue Track          Track-focused blue
13     Pink Drift              Drift-inspired pink
14     Lime Electric           Electric lime green
15     Gold Luxury             Luxurious gold finish
16     Teal Wave               Ocean teal theme
17     Violet Storm            Stormy violet purple
18     Mint Fresh              Fresh mint green
19     Bronze Muscle           Muscle car bronze
20     Azure Pro               Professional azure blue
21     Crimson Fury            Aggressive crimson red
22     Aqua Turbo              Turquoise aqua theme
23     Orchid Night            Dark orchid purple
24     Chartreuse Flash        Bright chartreuse yellow
25     Ice Blue Arctic         Arctic ice blue
26     Stealth Blackout        Tactical black stealth
27     Cosmic Nebula           Space-themed purple
28     Inferno Blaze           Fire-themed orange/red
29     Aurora Borealis         Northern lights teal
30     Vaporwave Aesthetic     Pink/purple retrowave
31     Cyberpunk Neon          Futuristic neon red
32     Crystal Prism           Light blue crystal
33     Magma Flow              Volcanic red/orange
34     Solar Eclipse           Black with gold accents
35     Zenith Horizon          Horizon blue gradient
```

#### **Digital Gauges (36-40)** *(No needle, animated)*
```bash
Style  Name                    Description
------ ----------------------- ----------------------------------
36     Holographic Digital     Cyan holographic pulse effect
37     80s Retro Synthwave     Pink synthwave with flicker
38     Modern Digital          Teal modern display
39     Supernova Digital       Pink supernova pulse
40     Quantum Flux Digital    Green quantum effect
```

---

### 💍 Available Bezels (20 Total)

```bash
Bezel  Name                Effect Type
------ ------------------- ---------------------
1      Chrome              Static gradient
2      Satin Black         Static dark finish
3      Carbon Fiber        Static carbon weave
4      Neon Amber          Static neon orange
5      Neon Green          Static neon green
6      Neon Blue           Static neon blue
7      Neon Magenta        Static neon pink
8      Neon Red            Static neon red
9      Retro Synthwave     Animated gradient shift
10     Rainbow             Animated color cycle
11     Holographic Pulse   Animated holographic
12     Neon Prism          Animated prism flow
13     Cosmic Dust         Animated twinkling
14     Lava Glow           Animated lava flow
15     Aurora Shift        Animated aurora colors
16     Pulsar Wave         Animated pulse effect
17     Chameleon Flux      Animated color shift
18     Mirror Edge         Animated mirror glint
19     Plasma Surge        Animated plasma wave
20     Quantum Ring        Animated quantum effect
```

---

### 🎁 Available Presets (20 Total)

```bash
Preset   Style  Bezel  Theme
-------- ------ ------ ----------------------------------
preset1  1      1      Classic Chrome (analog + chrome)
preset2  2      2      Digital Black (digital + black)
preset3  3      3      Retro Carbon (JDM + carbon)
preset4  5      5      Matrix Green (green + neon green)
preset5  9      7      Phantom Magenta (purple + magenta)
preset6  10     4      Emerald Amber (emerald + amber)
preset7  11     6      Sunset Blue (sunset + neon blue)
preset8  13     8      Drift Red (pink + neon red)
preset9  15     12     Luxury Gold (gold + matte gold)
preset10 17     9      Storm Synth (violet + synthwave)
preset11 20     13     Azure Cyan (azure + neon cyan)
preset12 22     14     Aqua Glass (aqua + frosted glass)
preset13 25     15     Arctic Lava (ice blue + lava)
preset14 27     10     Synthwave Rainbow (retro + rainbow)
preset15 30     11     Cosmic Holo (cosmic + holographic)
preset16 32     16     Aurora Pulsar (aurora + pulsar)
preset17 34     17     Cyberpunk Chameleon (cyber + chameleon)
preset18 36     18     Magma Mirror (magma + mirror)
preset19 38     19     Zenith Galactic (zenith + galactic)
preset20 40     20     Quantum Plasma (quantum + plasma)
```

---

## 🎮 Usage

### In-Game Commands

```lua
-- Manual style/bezel change (driver seat only)
/bgauge [style] [bezel]

-- Examples:
/bgauge 5 10          -- Set style 5 with bezel 10
/bgauge preset15      -- Apply preset 15 (Cosmic Holo)
```

### Using Items

1. **Install Gauge Style:**
   - Use any `boostgauge_*` item while in driver seat
   - Complete skillcheck minigame (if enabled)
   - Previous gauge style is returned to inventory

2. **Install Bezel:**
   - Use any `bezel_*` item while in driver seat
   - Complete installation animation
   - Previous bezel is returned to inventory

3. **Install Preset:**
   - Use any `boostgauge_preset*` item
   - Applies both style and bezel together
   - Both previous items returned

---

## 🔧 PSI System Integration

### Standard Turbo (Mod 18)
- Base PSI: **6.0** (configurable)
- Applies when vehicle has turbo mod 18
- No remap required

### With mnc-performanceparts Integration

#### **Remap Stages:**
```bash
Stage     PSI    Description
--------- ------ ------------------------
stage0    6.0    Stock turbo baseline
stage1    16.0   Stage 1 tune
stage1+   12.0   Stage 1+ tune
stage2    20.0   Stage 2 tune
stage2+   17.0   Stage 2+ tune
stage3    24.0   Stage 3 tune
stage3+   23.0   Stage 3+ tune
stage4    30.0   Stage 4 tune
stage4+   30.0   Stage 4+ tune
```

#### **Custom Turbos:**
```bash
Turbo       PSI    Use Case
----------- ------ ---------------------
turbo_rx280 12.0   Entry-level upgrade
turbo_rx560 16.0   Mid-tier performance
turbo_rx660 20.0   High-performance
turbo_rx890 26.0   Race-spec turbo
```

---

## 🎨 Visual Effects

### High PSI Warning (85%+ boost)
- Amber warning triangle icon
- Flashing animation (0.5s cycle)
- Needle glow effect (orange)
- Pulse animation on needle

### High RPM Effects (85%+ redline)
- Red major tick marks
- Red tick labels
- Enhanced gauge glow
- Needle brightness boost

### Vehicle Lighting Effects
- **Regular Lights ON:**
  - 15% brightness increase
  - Subtle gauge glow (8px)
  - Enhanced text shadows
  - Needle brightness boost

- **High Beams ON:**
  - 35% brightness increase
  - Intense glow (15px)
  - Double text shadow
  - Maximum needle glow
  - Enhanced tick mark visibility

---

## 🎬 Animations

### Needle Sweep (Engine Start)
```bash
Duration: 1.0 second
Range:    0° → 360° → 0°
Trigger:  Engine start (first time)
Cooldown: Per engine cycle
```

### Needle Movement
```bash
Smoothing:  Configurable (1.0-15.0)
Algorithm:  Smooth damping with velocity
Response:   ~60 FPS update rate
Clamping:   0° to 360° range
```

---

## 🛠️ Troubleshooting

### Gauge Not Showing
```bash
✅ Check vehicle has turbo mod 18
✅ Verify you are in driver seat
✅ Confirm script is started: /restart mnc-boostgauge
✅ Check for console errors F8
✅ Ensure ox_lib is loaded
```

### Incorrect PSI Values
```bash
✅ Verify mnc-performanceparts is running if using remaps
✅ Check remap is correctly installed on vehicle
✅ Restart gauge: /restart mnc-boostgauge
✅ Review Config.RemapPSI values
✅ Check Config.TurboPSI for custom turbos
```

### Items Not Working
```bash
✅ Verify items exist in qb-core/shared/items.lua
✅ Confirm item names match Config.StyleItems exactly
✅ Check player has item in inventory
✅ Ensure player is in driver seat
✅ Review installation minigame difficulty
```

### Database Issues
```bash
✅ Check oxmysql is running
✅ Verify database connection in server.cfg
✅ Run query manually to test:
   SELECT * FROM vehicle_gauges;
✅ Check server console for MySQL errors
```

---

## 🎯 Performance Optimization

```bash
Feature                  Impact      Notes
------------------------ ----------- ---------------------------
Update Rate              ~60 FPS     Optimized 16ms loop
Database Queries         1/sec       Cooldown on gauge fetch
Needle Animation         Smooth      Damped interpolation
Prop Cleanup             Automatic   On vehicle exit/death
Memory Usage             Low         Minimal state tracking
Network Traffic          Minimal     Event-based updates only
```

---

## 📞 Support & Community

- 💬 **Discord**: [![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/aTBsSZe5C6) — join for support, bug reports, and update announcements
- 🐛 **Issues**: open an issue on the [mnc-mega-mod-dump GitHub repo](https://github.com/MnCLosSantos/mnc-mega-mod-dump/issues)
- 📖 Check this README's Configuration and Troubleshooting sections first — most questions are answered above

### Common Questions

**Q: Does this work without mnc-performanceparts?**  
A: Yes! It falls back to standard turbo PSI (6.0 default).

**Q: Can I disable the installation minigame?**  
A: Yes! Set `Config.Installation.requireMinigame = false`.

**Q: How do I change gauge position?**  
A: Edit `Config.UI.x`, `Config.UI.y`, and `Config.UI.scale` values.

**Q: Can I toggle gauge visibility?**  
A: Yes! Set a keybind in `Config.Keybinds.toggleGauge` (default: 0/disabled).

---

## 📝 Credits & License

**Author**: Stan Leigh/MnC Los Santos
**Version**: 2.4.7
**Framework**: QBCore
**Dependencies**: ox_lib, oxmysql, rpemotes
**Collection**: part of the [MNC Mega Mod Dump](https://github.com/MnCLosSantos/mnc-mega-mod-dump)

This resource is licensed under **MNC_LICENSE_NDFTEAU** (*No Distribution, Free To Edit And Use*) — see the [MNC_LICENSE_NDFTEAU license](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md) for the full text.

- ✅ Use and edit this resource freely on your own personal or paid server(s)
- ✅ Modify the code however you need to fit your server
- ❌ Do not redistribute, resell, or re-upload this resource (modified or not) as your own work
- ❌ Do not publish forks or copies of this resource outside of channels authorized by MnCLosSantos / carrot

---

## 🔄 Changelog

### Version 2.4.7
- Added 20 preset combinations
- Improved item swap system (returns previous parts)
- Enhanced installation minigame system
- Fixed gauge persistence across sessions
- Optimized database queries with cooldowns
- Added vehicle lighting effects
- Improved needle sweep animation
- Enhanced high PSI/RPM warning system

### Version 2.4.0
- Added 40 unique gauge styles
- Implemented 20 animated bezels
- Integrated remap-aware PSI system
- Added database persistence
- Improved boost physics calculations
- Enhanced visual effects system

**Enjoy your boost gauge! 🏁**
