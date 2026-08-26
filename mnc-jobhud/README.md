# 💼 MNC Job HUD System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.1.0-brightgreen.svg)]()

---

## 🌟 Overview

A **highly customizable job/bank/cash HUD system** for QBCore-based FiveM servers.  
This script provides **25 unique visual styles**, **persistent player preferences**, **dynamic money tracking with visual effects**, and a **fully configurable display system**.  
Optimized for **ox_lib**, **oxmysql**, and **qb-core** with smooth animations and modern UI design.

---

## ✨ Key Features

- 🎨 **25 Unique Visual Styles**  
  - Classic themes to futuristic cyberpunk aesthetics.  
  - Gradient backgrounds including linear, radial, and conic effects.  
  - Each style has custom colors, accents, and descriptions.  
  - Persistent style preferences saved per player in database.

- 💰 **Advanced Money Tracking**  
  - Real-time bank and cash balance display.  
  - Visual change indicators (+/-) with glow effects.  
  - Money gain: Green glow with pulsing animation.  
  - Money loss: Red glow with pulsing animation.  
  - Change amounts displayed for 10 seconds.

- 🎯 **Fully Configurable Display**  
  - Toggle individual HUD elements (job, ID, players, time, bank, cash).  
  - Custom positioning for each element via config.  
  - Smooth show/hide transitions.  
  - Individual element styling per theme.

- 🔄 **Dynamic Updates**  
  - Real-time player count display.  
  - Live time display (HH:MM format).  
  - Job/gang affiliation tracking.  
  - Player ID and name display.  
  - Updates every second for accuracy.

- 💾 **Persistent Preferences**  
  - Database-backed style storage per citizenid.  
  - Automatic table creation on first run.  
  - Styles saved and loaded on player join.  
  - Cross-session preference retention.

- 🎭 **Visual Effects System**  
  - Smooth fade transitions on value changes.  
  - Pulse animations on updates.  
  - Glow effects on money transactions.  
  - Scale effects on interaction.  
  - Backdrop blur for modern glass effect.

- 📱 **Notification System**  
  - Custom HUD notifications for style changes.  
  - Success/error notification types.  
  - Themed notification boxes matching HUD style.  
  - Auto-dismiss after 5 seconds.

- 🛠️ **Help Interface**  
  - In-game style browser (/hudhelp).  
  - Visual preview of all 25 styles.  
  - Command guide and examples.  
  - ESC to close interface.

---

## 📋 Requirements

```bash
Dependency             Version   Required
---------------------- --------- ----------
QBCore Framework       Latest    ✅ Yes
oxmysql                Latest    ✅ Yes
ox_lib                 Latest    ✅ Yes
```

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone from GitHub
git clone https://github.com/YourUsername/mnc-jobhud.git

# OR download ZIP from Releases
```

Place into your resources folder:

```bash
[server-data]/resources/[custom]/mnc-jobhud/
```

### 2️⃣ Database Setup

The script **automatically creates** the required database table on first start:

```sql
CREATE TABLE IF NOT EXISTS `mnc_hud_styles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `style` int(11) NOT NULL DEFAULT 1,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure mnc-jobhud
```

### 4️⃣ Configure HUD Elements

Edit `config.lua` to customize HUD display:

```lua
Config.DefaultStyle = 1 -- Default style (1-25)

Config.HUD = {
    jobOrGang  = { enabled = true, position = { top = "20px", left = "20px" } },
    id         = { enabled = true, position = { top = "60px", left = "20px" } },
    players    = { enabled = true, position = { top = "100px", left = "20px" } },
    time       = { enabled = true, position = { top = "140px", left = "20px" } },
    bank       = { enabled = true, position = { top = "180px", left = "20px" } },
    cash       = { enabled = true, position = { top = "220px", left = "20px" } },
}
```

---

## ⚙️ Configuration

### 🎯 HUD Element Configuration

Each HUD element can be individually configured:

```lua
elementName = {
    enabled = true,                           -- Show/hide element
    position = {                              -- CSS positioning
        top = "20px",                        -- Distance from top
        left = "20px",                       -- Distance from left
        -- Optional: right, bottom
    }
}
```

**Positioning Options:**
- `top` - Distance from top of screen
- `bottom` - Distance from bottom of screen
- `left` - Distance from left of screen
- `right` - Distance from right of screen

**Example - Right-aligned:**
```lua
bank = { 
    enabled = true, 
    position = { top = "20px", right = "20px" } 
}
```

---

### 🎨 Available Styles (1-25)

**Classic Styles (1-5):**
1. Classic Green - Clean dark theme with green accents
2. Purple Storm - Purple base with red highlights
3. Neon Dark - Dark background with bright neon green
4. Blue Glass - Modern glass effect with blue tones
5. Orange Mist - Grey base with warm orange highlights

**Advanced Gradient Styles (6-15):**
6. Cyberpunk Neon - Futuristic cyberpunk aesthetic
7. Dark Matrix - Matrix-inspired dark purple theme
8. Ocean Tech - Deep ocean technology vibes
9. Pink Hacker - Hacker aesthetic with pink highlights
10. Rotating Tech - Rotating gradient with tech green
11. Mars Red - Mars-inspired red gradient
12. Ice Blue - Cool ice blue technology
13. Golden Honey - Warm golden honey tones
14. Purple Vortex - Swirling purple vortex effect
15. Teal Hologram - Holographic teal display

**Premium Styles (16-25):**
16. Sunset Plasma - Plasma sunset with orange glow
17. Arctic Storm - Fierce arctic storm effect
18. Toxic Waste - Radioactive toxic green theme
19. Royal Purple - Majestic royal purple gradient
20. Blood Moon - Ominous blood moon atmosphere
21. Neon City - Vibrant neon city lights
22. Chrome Steel - Sleek chrome and steel finish
23. Forest Fire - Blazing forest fire gradient
24. Deep Space - Mysterious deep space nebula
25. Quantum Flux - Quantum energy flux field

---

## 🎮 Commands

### Change HUD Style
```bash
/jobhud [style_number]

# Examples:
/jobhud 1          # Classic Green
/jobhud 15         # Teal Hologram
/jobhud 25         # Quantum Flux
```

### View Style Browser
```bash
/hudhelp

# Opens interactive style browser with:
- Visual preview of all 25 styles
- Style names and descriptions
- Command usage guide
- Press ESC to close
```

---

## 💡 Usage Guide

### For Players

#### Changing Your HUD Style
1. Type `/hudhelp` to view all available styles
2. Find a style you like (note the number)
3. Type `/jobhud [number]` to apply it
4. Style saves automatically to your character

#### Understanding HUD Elements
- **Time**: Current in-game time (HH:MM)
- **ID**: Your server ID and character name
- **Players**: Current active players on server
- **Job**: Your current job or gang affiliation
- **Bank**: Bank balance with change tracking
- **Cash**: Cash balance with change tracking

#### Money Change Indicators
- **Green glow + number**: Money added (gain)
- **Red glow + number**: Money removed (loss)
- Change amount displays for 10 seconds
- Glow effect lasts 2 seconds

---

## 🎨 Style Customization

### Creating Custom Styles

Add new styles to `config.lua`:

```lua
[26] = {
    name = "Your Style Name",
    bg = "rgba(30,30,46,0.5)",           -- Background (solid or gradient)
    text = "#ffffff",                     -- Text color
    accent = "#4CAF50",                   -- Accent/border color
    description = "Style description"
}
```

**Background Options:**
- Solid: `"rgba(30,30,46,0.5)"`
- Linear: `"linear-gradient(135deg, rgba(15,15,35,0.9), rgba(25,25,55,0.7))"`
- Radial: `"radial-gradient(circle, rgba(0,20,40,0.9), rgba(0,0,20,0.95))"`
- Conic: `"conic-gradient(from 180deg, rgba(0,0,0,0.95), rgba(20,20,80,0.8))"`

---

## 🔧 Advanced Configuration

### Custom Element Positioning

Move elements anywhere on screen:

```lua
Config.HUD = {
    -- Top-left corner (default)
    jobOrGang = { 
        enabled = true, 
        position = { top = "20px", left = "20px" } 
    },
    
    -- Top-right corner
    bank = { 
        enabled = true, 
        position = { top = "20px", right = "20px" } 
    },
    
    -- Bottom-left corner
    cash = { 
        enabled = true, 
        position = { bottom = "20px", left = "20px" } 
    },
    
    -- Bottom-right corner
    time = { 
        enabled = true, 
        position = { bottom = "20px", right = "20px" } 
    },
    
    -- Centered top
    players = { 
        enabled = true, 
        position = { top = "20px", left = "50%", transform = "translateX(-50%)" } 
    },
}
```

### Disabling Elements

Hide specific HUD elements:

```lua
Config.HUD = {
    jobOrGang  = { enabled = false },  -- Hidden
    id         = { enabled = true },   -- Visible
    players    = { enabled = true },   -- Visible
    time       = { enabled = false },  -- Hidden
    bank       = { enabled = true },   -- Visible
    cash       = { enabled = true },   -- Visible
}
```

---

## 🐛 Troubleshooting

### HUD Not Showing
- Verify oxmysql is running and connected
- Check server console for errors
- Ensure QBCore is loaded before mnc-jobhud
- Try `/hudhelp` to trigger HUD initialization

### Style Not Saving
- Check database connection (oxmysql)
- Verify `mnc_hud_styles` table exists
- Check citizenid is valid in player data
- Review server console for SQL errors

### Money Changes Not Displaying
- Verify qb-core money events are firing
- Check if bank/cash values are updating
- Ensure style is loaded (check with /hudhelp)
- Review browser console (F8) for errors

### Elements Overlapping
- Adjust positioning in `Config.HUD`
- Increase spacing between elements
- Use different screen corners for different elements
- Test with different screen resolutions

---

## 🎯 Features in Detail

### Money Tracking System
- Tracks both bank and cash separately
- Calculates difference on each update
- Displays change amount with +/- indicator
- Green glow effect for money gained
- Red glow effect for money lost
- Smooth pulse animations
- Auto-dismiss after 10 seconds

### Style Persistence
- Each player's style choice is saved to database
- Styles load automatically on player join
- Survives server restarts
- Cross-character if using same citizenid
- Instant style switching with `/jobhud`

### Visual Effects
- Backdrop blur for modern glass effect
- Border glow on hover
- Scale animation on value change
- Smooth transitions between states
- Color-coded status indicators
- Particle-style accent borders

---

## 📱 Responsive Design

The HUD automatically adapts to different screen sizes and maintains proper positioning across resolutions. All elements use viewport-relative sizing for consistency.

---

## 📞 Support & Community

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289da?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/your-link)

---

## 📜 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

---

## 🙏 Credits

- **QBCore Framework** - Base framework
- **ox_lib** - Utilities
- **oxmysql** - Database management
- **Font Awesome** - Icons
- **Community contributors** - Bug reports and suggestions
