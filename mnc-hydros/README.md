# 🎒 MNC Bag System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.2.0-brightgreen.svg)]()

---

## 🌟 Overview

A **comprehensive bag and inventory expansion system** for QBCore-based FiveM servers featuring visual backpack props, automatic weight bonuses, shared bag storage, and seamless integration with qb-inventory. Built with performance and immersion in mind.

---

## ✨ Key Features

### 🎒 Visual Bag System
- **Automatic prop attachment** - Backpacks appear on player's back when in inventory
- **Priority-based display** - Shows largest bag automatically (XL > Large > Medium > Small)
- **Persistent across sessions** - Bag visuals survive reconnects and server restarts
- **Multiple bag models** - Each bag tier has unique 3D prop
- **Automatic cleanup** - Props removed on death, resource restart, or player logout
- **Bone-based attachment** - Properly positioned on player spine for realistic appearance

### 💼 Shared Bag Storage
- **Unique bag IDs** - Each bag instance generates a persistent stash ID
- **Share with anyone** - Drop bag for others to access the same inventory
- **Separate storage** - Each bag has its own independent stash space
- **Persistent contents** - Items stored in bags survive server restarts
- **No ownership restriction** - Anyone can use a dropped bag
- **Stash integration** - Works seamlessly with qb-inventory stash system

### ⚖️ Dynamic Weight System
- **Automatic weight bonuses** - Carrying a bag increases max inventory weight
- **Tiered capacity** - Different bag sizes provide different weight bonuses
  - Wallet: +1,000 weight (5 slots)
  - Small Bag: +5,000 weight (10 slots)
  - Medium Bag: +8,000 weight (15 slots)
  - Large Bag: +10,000 weight (20 slots)
  - XL Bag: +20,000 weight (40 slots)
- **Real-time updates** - Weight adjusts immediately when bag acquired/removed
- **Metadata tracking** - Bonus weight stored in player metadata
- **Configurable defaults** - Customize base weight and bag bonuses

### 🔄 Smart Detection System
- **Multiple event listeners** - Monitors inventory changes from various sources
- **Polling system** - Background check every 30 seconds for reliability
- **Delayed updates** - Configurable delays ensure inventory is fully updated before checking
- **Debug mode** - Comprehensive logging system for troubleshooting
- **Manual commands** - Test and debug with `/bagtest`, `/bagremove`, `/baginv`
- **Player state awareness** - Only runs when player is logged in

### 🛠️ Developer-Friendly
- **Clean codebase** - Well-organized and commented
- **Configurable everything** - Customize models, positions, weights, and slots
- **Debug tools** - Built-in testing commands and console logging
- **No database required** - Uses QBCore's built-in systems
- **Lightweight** - Minimal performance impact
- **Easy customization** - All settings in single config file

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| qb-inventory | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone from GitHub
git clone https://github.com/YourUsername/mnc-bags.git

# OR download ZIP from Releases
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-bags/
```

### 2️⃣ No Database Setup Required!

This script uses QBCore's built-in player metadata and inventory systems - **no SQL imports needed!**

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure qb-core
ensure qb-inventory
ensure ox_lib
ensure mnc-bags
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize:

```lua
-- Enable debug messages in F8 console
Config.Debug = false

-- Match your qb-core player max weight
Config.DefaultMaxWeight = 35000

-- Customize bag properties
Config.Bags = {   
    ['wallet'] = {
        label = 'Wallet',
        weight = 1000,  -- Weight bonus
        slots = 5,      -- Bag storage slots
        -- No prop (wallet is small)
    },
    ['smallbag'] = {
        label = 'Small Bag',
        weight = 5000,
        slots = 10,
        prop = 'sf_prop_sf_backpack_03a',  -- 3D model
        attach = {
            bone = 24818,  -- Spine bone
            x = 0.06, y = -0.14, z = -0.05,
            rx = 0.0, ry = 90.0, rz = 180.0
        }
    }
}
```

### 5️⃣ Add Items to QBCore

Add all bag items from config to `qb-core/shared/items.lua`:

```lua
-- Wallet (no visual prop)
['wallet'] = {
    ['name'] = 'wallet',
    ['label'] = 'Wallet',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'wallet.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A leather wallet with card slots'
},

-- Small Bag
['smallbag'] = {
    ['name'] = 'smallbag',
    ['label'] = 'Small Bag',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'smallbag.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A small backpack for carrying items (+5kg capacity, 10 slots)'
},

-- Medium Bag
['mediumbag'] = {
    ['name'] = 'mediumbag',
    ['label'] = 'Medium Bag',
    ['weight'] = 750,
    ['type'] = 'item',
    ['image'] = 'mediumbag.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A medium backpack for carrying items (+8kg capacity, 15 slots)'
},

-- Large Bag
['largebag'] = {
    ['name'] = 'largebag',
    ['label'] = 'Large Bag',
    ['weight'] = 1000,
    ['type'] = 'item',
    ['image'] = 'largebag.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A large backpack for carrying items (+10kg capacity, 20 slots)'
},

-- XL Bag
['xlbag'] = {
    ['name'] = 'xlbag',
    ['label'] = 'XL Bag',
    ['weight'] = 1500,
    ['type'] = 'item',
    ['image'] = 'xlbag.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'An extra large duffel bag (+20kg capacity, 40 slots)'
},
```

### 6️⃣ Add Images

Place bag images in your inventory image folder:
```
[qb]/qb-inventory/html/images/
```

Required images:
- `wallet.png`
- `smallbag.png`
- `mediumbag.png`
- `largebag.png`
- `xlbag.png`

---

## ⚙️ Configuration Guide

### 🎯 Bag Item Configuration

```lua
['xlbag'] = {
    label = 'XL Bag',              -- Display name
    weight = 20000,                -- Weight bonus granted
    slots = 40,                    -- Bag storage slots
    prop = 'p_ld_heist_bag_01',   -- 3D prop model
    attach = {
        bone = 24818,              -- Attachment bone (24818 = spine)
        x = 0.05,                  -- X offset
        y = 0.05,                  -- Y offset
        z = 0.0,                   -- Z offset
        rx = 0.0,                  -- X rotation
        ry = 90.0,                 -- Y rotation
        rz = 180.0                 -- Z rotation
    }
}
```

### 🎨 Custom Prop Models

To use custom backpack models:

1. Add your model to your server resources
2. Update the `prop` field in config:
```lua
prop = 'your_custom_backpack_model'
```
3. Adjust `attach` coordinates for proper positioning
4. Enable debug mode to see real-time positioning

### ⚖️ Weight System

```lua
-- Base player weight (no bags)
Config.DefaultMaxWeight = 35000

-- Bag bonuses stack on top:
-- Player with XL Bag: 35,000 + 20,000 = 55,000 total weight
-- Player with Medium Bag: 35,000 + 8,000 = 43,000 total weight
```

### 🐛 Debug Mode

```lua
Config.Debug = true  -- Enable detailed console logging
```

When enabled, you'll see:
- Inventory scans
- Bag detection
- Prop attachment/removal
- Event triggers
- Weight updates

---

## 🎮 Usage Guide

### Player Usage

**Getting a Bag:**
1. Acquire a bag item (purchase, find, or receive)
2. Bag automatically appears on your back
3. Your max weight increases immediately
4. Inventory updates to show new capacity

**Using Bag Storage:**
1. Right-click the bag in inventory
2. Select "Use"
3. Separate stash opens
4. Store items inside (respects bag's slot/weight limits)
5. Close stash when done

**Sharing Bags:**
1. Drop bag on ground
2. Another player picks it up
3. They can use it to access the same stash
4. Items remain in bag across transfers
5. Bag ID persists forever

**Removing Bags:**
1. Drop or sell the bag item
2. Prop automatically disappears
3. Max weight returns to normal
4. Bag contents remain accessible if bag is retrieved

### Admin/Debug Commands

| Command | Description |
|---------|-------------|
| `/bagtest` | Manually trigger bag visual update |
| `/bagremove` | Force remove current bag prop |
| `/baginv` | Debug current inventory state |

---

## 🧠 System Mechanics

### Priority System
Displays the **largest** bag automatically when player has multiple:

**Priority Order:**
1. XL Bag (largest)
2. Large Bag
3. Medium Bag
4. Small Bag
5. Wallet (smallest, no visual)

Example: Player has Small Bag + Large Bag → Only Large Bag prop shows

### Weight Calculation
```
Total Max Weight = Base Weight + Largest Bag Bonus

Examples:
- No bag: 35,000
- Small Bag: 35,000 + 5,000 = 40,000
- XL Bag: 35,000 + 20,000 = 55,000
- Multiple bags: Uses only the largest (no stacking)
```

### Shared Bag IDs
Each bag generates a unique identifier:
```lua
'sharedbag_1234567_89012'
```

- **Persistent**: Survives server restarts
- **Universal**: Anyone can access the same bag
- **Unique**: Each bag has different contents
- **Permanent**: ID never changes or expires

### Update Detection

The script monitors inventory changes through:

1. **QBCore Events**
   - `QBCore:Player:SetPlayerData`
   - `QBCore:Client:OnPlayerLoaded`
   - `QBCore:Client:OnPlayerUnload`

2. **Inventory Events**
   - `inventory:client:ItemBox`
   - `qb-inventory:client:ItemBox`
   - `inventory:client:UpdatePlayerInventory`

3. **Polling System**
   - Checks every 30 seconds
   - Only when player is logged in
   - Catches missed events

4. **Manual Commands**
   - `/bagtest` for instant update
   - Useful for testing/debugging

---

## 🔧 Troubleshooting

### Common Issues

**Bag prop not appearing:**
- Check if model name is correct in config
- Verify prop exists on server
- Enable debug mode (`Config.Debug = true`)
- Run `/bagtest` to manually trigger update
- Check F8 console for errors

**Weight not increasing:**
- Verify `Config.DefaultMaxWeight` matches qb-core
- Check server console for errors
- Restart both qb-core and mnc-bags
- Run `/baginv` to verify inventory detection

**Bag storage not opening:**
- Ensure qb-inventory is running
- Check item is marked as `useable = true`
- Verify ox_lib is installed
- Look for console errors when using bag

**Prop in wrong position:**
- Adjust `attach` coordinates in config
- Enable debug mode to see prop spawn
- Use different bone index if needed
- Test with different bag models

**Multiple bags showing:**
- This shouldn't happen - only largest shows
- If it does, run `/bagremove` then `/bagtest`
- Check debug logs for priority selection
- Report bug if persists

**Bag disappeared after death:**
- This is intended behavior
- Prop reattaches when you respawn
- Check inventory to confirm you still have bag
- Wait 1-2 seconds for automatic reattachment

**Weight bonus not removing:**
- Drop/remove bag from inventory
- Run `/bagtest` to force update
- Check metadata: `/baginv`
- Restart if issue persists

---

## 🎨 Customization Examples

### Adding a New Bag Tier

```lua
-- In config.lua
['megabag'] = {
    label = 'Mega Bag',
    weight = 30000,        -- +30kg bonus
    slots = 50,            -- 50 storage slots
    prop = 'prop_cs_heist_bag_02',
    attach = {
        bone = 24818,
        x = 0.0, y = -0.15, z = 0.0,
        rx = 0.0, ry = 90.0, rz = 180.0
    }
}
```

Then add to qb-core items and update priority in client.lua:
```lua
local bagPriority = {'megabag', 'xlbag', 'largebag', 'mediumbag', 'smallbag'}
```

### Using Custom Models

```lua
['custombackpack'] = {
    label = 'Tactical Backpack',
    weight = 15000,
    slots = 30,
    prop = 'bkr_prop_biker_backpack_01',  -- Custom model
    attach = {
        bone = 24818,
        x = 0.10, y = -0.20, z = 0.05,    -- Adjust as needed
        rx = 5.0, ry = 85.0, rz = 175.0
    }
}
```

### Adjusting Base Weight

```lua
-- Match your qb-core/config.lua player max weight
Config.DefaultMaxWeight = 50000  -- If you increased base capacity
```

### Creating Item-Specific Bags

```lua
['toolbag'] = {
    label = 'Tool Bag',
    weight = 12000,
    slots = 25,
    prop = 'prop_tool_box_01',
    attach = {bone = 24818, x = 0.0, y = -0.10, z = 0.0, rx = 0.0, ry = 90.0, rz = 180.0}
}
```

---

## 📊 Performance

### Optimization Features
- **Minimal network traffic**: Only updates when inventory changes
- **Efficient polling**: 30-second intervals (configurable)
- **Smart caching**: Tracks current bag to avoid redundant updates
- **Automatic cleanup**: Removes props immediately when not needed
- **No database calls**: Uses existing QBCore systems
- **Lightweight threads**: Only runs when player logged in

### Tested With
- ✅ 128+ concurrent players
- ✅ Multiple bags per player
- ✅ Rapid inventory changes
- ✅ Server restarts during use
- ✅ Extended play sessions (24+ hours)

---

## 🔐 Security

### Anti-Exploit Features
- **Server-side weight validation**: Bags only grant bonuses if in inventory
- **Unique bag IDs**: Prevents bag duplication exploits
- **Metadata tracking**: Server verifies all weight changes
- **Amount checking**: Ensures bag quantity > 0 before granting bonus
- **Secure callbacks**: All inventory checks use server callbacks

### Inventory Systems
Currently designed for **qb-inventory**. For ox_inventory or other systems, modifications may be required to:
- Item amount detection
- Stash opening methods
- Event triggers

---

## 📝 Credits & License

**Author**: Stan Leigh  
**Version**: 1.2.0  
**Framework**: QBCore  
**Dependencies**: qb-inventory, ox_lib

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

### Contributing
Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

### Special Thanks
- QBCore Development Team
- FiveM Community
- All contributors and testers

---

## 📞 Support & Community

For support, bug reports, or feature requests:
- 🐛 Open an issue on GitHub
- 💬 Join our Discord community
- 📚 Check existing documentation
- 🔍 Search closed issues first

---

## 📄 Changelog

### Version 1.2.0 (Current Release)
**New Features:**
- ✨ Added polling system for reliable bag detection every 30 seconds
- ✨ Implemented multiple event listeners for comprehensive inventory monitoring
- ✨ Added delayed update system with configurable wait times
- ✨ Created `/baginv` debug command for inventory state inspection
- ✨ Enhanced debug logging with detailed item scanning

**Improvements:**
- 🔧 Increased event delays to ensure inventory data is fully updated (800-1000ms)
- 🔧 Added longer initial delay on player load (3 seconds)
- 🔧 Improved resource start detection with 5-second delay
- 🔧 Enhanced bag detection to handle items without amount field
- 🔧 Added comprehensive debug output for troubleshooting

**Bug Fixes:**
- 🐛 Fixed bags not appearing immediately after pickup
- 🐛 Resolved inventory scanning missing items with nil amounts
- 🐛 Corrected bag visual not updating when inventory changes
- 🐛 Fixed props not attaching after player respawn
- 🐛 Resolved race condition between inventory update and visual refresh

---

### Version 1.1.0
**New Features:**
- ✨ Added manual test commands (`/bagtest`, `/bagremove`)
- ✨ Implemented debug mode with console logging
- ✨ Created comprehensive inventory scanning system
- ✨ Added support for items without amount field

**Improvements:**
- 🔧 Enhanced prop cleanup on resource stop
- 🔧 Improved event handler reliability
- 🔧 Better error handling for missing inventory data
- 🔧 Optimized prop attachment logic

**Bug Fixes:**
- 🐛 Fixed bags not detecting in some inventory systems
- 🐛 Resolved prop duplication issues
- 🐛 Corrected weight bonus not applying consistently
- 🐛 Fixed memory leaks in prop management

---

### Version 1.0.0 (Initial Release)
**New Features:**
- ✨ Initial public release
- ✨ Automatic bag prop attachment system
- ✨ Priority-based bag display (largest only)
- ✨ Dynamic weight bonus system
- ✨ Shared bag storage with unique IDs
- ✨ Multiple bag tiers (wallet, small, medium, large, XL)
- ✨ Configurable prop models and positions
- ✨ Event-based inventory monitoring
- ✨ Automatic cleanup on death/logout

**Features:**
- 🎒 Five bag tiers with increasing capacity
- ⚖️ Real-time weight bonus adjustments
- 🔄 Persistent bag IDs across server restarts
- 🎨 Customizable prop models and positioning
- 🛠️ Developer-friendly configuration
- 🐛 Debug mode for troubleshooting

---

## ⚠️ Important Notes

1. **Inventory Compatibility**: Designed for qb-inventory - other systems may need adjustments
2. **Performance**: Tested stable with 128+ players, minimal resource impact
3. **Shared Bags**: Anyone with the bag item can access its contents - no ownership system
4. **Weight Stacking**: Only the largest bag applies - multiple bags don't stack weight bonuses
5. **Prop Models**: Ensure custom models are properly streamed on your server
6. **Debug Mode**: Disable in production to reduce console spam (`Config.Debug = false`)

---

## 🎯 Future Plans

### Planned Features
- 🔮 Bag ownership system with permissions
- 🔮 Weight bonus stacking option
- 🔮 Bag degradation/durability system
- 🔮 Custom bag crafting recipes
- 🔮 Visual bag customization (colors, patches)
- 🔮 Integration with more inventory systems
- 🔮 Admin commands for bag management
- 🔮 Bag rental/lease system for shops

### Under Consideration
- 💡 Bag insurance system
- 💡 Searchable bags for police
- 💡 Bag lock system with keys
- 💡 Temporary bag buffs/debuffs
- 💡 Bag trading/marketplace integration

*Have a feature request? Open an issue on GitHub!*

---

**Enjoy enhanced inventory management on your FiveM server! 🎒**