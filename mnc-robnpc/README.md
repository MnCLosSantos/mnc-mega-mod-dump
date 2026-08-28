# 💰 MNC Rob NPC System

[![License: MNC](https://img.shields.io/badge/License-MNC-purple.svg)](https://github.com/MnCLosSantos/MNC_LICENSE_NDFTEAU/blob/main/LICENSE.md)
[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.1.0-brightgreen.svg)]()

---

## 🌟 Overview

<img width="1919" height="1079" alt="script_poster_4" src="https://github.com/user-attachments/assets/c2ab147e-dfc0-41a7-9366-acef8d8d57a7" />

A **realistic pedestrian robbery system** for QBCore-based FiveM servers featuring weapon requirements, immersive animations, police notifications with GPS tracking, and anti-exploit protections. Built for roleplay servers prioritizing realism and balance.

---

## ✨ Key Features

### 🔫 Weapon-Based Robbery System
- **Drawn weapon requirement** - Must have weapon equipped to intimidate NPCs
- **Inventory verification** - Server-side check ensures player actually owns a weapon
- **All weapon types supported** - Melee, handguns, shotguns, rifles, throwables, and more
- **Visual intimidation** - NPCs react by raising hands in surrender
- **Realistic aiming** - Player automatically aims weapon during robbery
- **Cancel anytime** - Stop the robbery mid-progress with no consequences

### 🎭 Immersive NPC Interactions
- **qb-target integration** - Smooth targeting system for nearby pedestrians
- **Hands-up animations** - NPCs surrender with looping hands-up pose
- **Face player mechanic** - NPC turns to face robber during holdup
- **Frozen in place** - Prevents NPC from fleeing or fighting back
- **Smart targeting** - Only human NPCs can be robbed (no animals, mission peds)
- **One-time robbery** - Each NPC can only be robbed once per session
- **Distance checks** - Prevents exploitation from long range

### 🚨 Police Alert System
- **Job-based notifications** - Configurable list of jobs that receive alerts (police, sheriff, etc.)
- **Location details** - Shows street name, cross street, and zone name
- **Interactive alerts** - Press [E] within notification duration to respond
- **GPS waypoint** - Automatically sets waypoint to robbery location
- **Temporary blip** - Red blip appears on map for configured duration (24 seconds default)
- **Custom blip settings** - Configurable sprite, color, scale, and label
- **Timed removal** - Blip disappears after time expires

### ⚖️ Balanced Reward System
- **Random cash amounts** - Configurable minimum and maximum payout ($10-$100 default)
- **Cash only** - Money added directly to player's cash (not bank)
- **Instant notification** - Player sees amount stolen immediately
- **No item drops** - Simple cash-based system (expandable)
- **Server-side validation** - Prevents client-side manipulation

### 🛡️ Anti-Exploit Protections
- **One robbery per NPC** - Session-based tracking prevents re-robbery
- **Weapon validation** - Server confirms player has weapon in inventory
- **Distance checks** - Ensures player is close enough to target
- **Progress bar cancellation** - No exploits from interrupted robberies
- **Proper cleanup** - NPCs released correctly whether robbery succeeds or fails
- **Entity health checks** - Can't rob dead or vehicle-bound NPCs

### 🎮 User-Friendly Experience
- **ox_lib progress bar** - Smooth visual progress indicator
- **ox_lib notifications** - Clean, modern notification system
- **Configurable duration** - Adjust robbery time to fit server pace (16 seconds default)
- **Clear feedback** - Distinct messages for success, failure, and errors
- **No commands needed** - Entirely interaction-based system
- **Lightweight** - Minimal performance impact

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| qb-target | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone the full mod dump from GitHub (this resource lives inside the mnc-mega-mod-dump monorepo)
git clone https://github.com/MnCLosSantos/mnc-mega-mod-dump.git
# then copy the `mnc-robnpc/` folder into your server's resources directory

# OR download the ZIP from https://github.com/MnCLosSantos/mnc-mega-mod-dump/releases and extract just the `mnc-robnpc/` folder
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-robnpc/
```

### 2️⃣ No Database Setup Required!

This script uses **session-based tracking** - no SQL database needed! All data resets on server restart.

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure qb-core
ensure qb-target
ensure ox_lib
ensure mnc-robnpc
```

### 4️⃣ Configure Settings

Edit `config.lua` to customize:

```lua
-- Jobs that receive robbery notifications
Config.NotifyJobs = {"police"}

-- Cash reward range
Config.MinCash = 10
Config.MaxCash = 100

-- Robbery duration (milliseconds)
Config.RobDuration = 16000

-- Notification settings
Config.NotifyDuration = 10000  -- How long notification shows
Config.NotifyMessage = "🚨 Pedestrian robbery in progress at %s - Press [E] to respond!"

-- Blip settings
Config.BlipTime = 24          -- Seconds blip stays on map
Config.BlipSprite = 161       -- Blip icon
Config.BlipColour = 1         -- Red
Config.BlipScale = 1.0        -- Size
Config.BlipLabel = "Pedestrian Robbery"
```

### 5️⃣ Verify Dependencies

Ensure these are running **before** mnc-robnpc:
- ✅ qb-core
- ✅ qb-target  
- ✅ ox_lib

---

## ⚙️ Configuration Guide

### 🎯 Basic Settings

```lua
-- Jobs that will be notified
Config.NotifyJobs = {"police", "bcso", "sheriff"}

-- Cash amounts
Config.MinCash = 10    -- Minimum cash stolen
Config.MaxCash = 100   -- Maximum cash stolen

-- Robbery duration
Config.RobDuration = 16000  -- 16 seconds (in milliseconds)
```

### 🚨 Police Notification Settings

```lua
-- Notification display time
Config.NotifyDuration = 10000  -- 10 seconds to press [E]

-- Custom notification message (%s = location)
Config.NotifyMessage = "🚨 Pedestrian robbery in progress at %s - Press [E] to respond!"
```

### 📍 Blip Customization

```lua
Config.BlipTime = 24           -- Blip duration (seconds)
Config.BlipSprite = 161        -- Sprite ID (see FiveM docs)
Config.BlipColour = 1          -- Color (1=red, 2=green, 3=blue, etc.)
Config.BlipScale = 1.0         -- Size (0.5-2.0 recommended)
Config.BlipLabel = "Pedestrian Robbery"  -- Map label
```

**Popular Blip Sprites:**
- `161` - GTAOBossBike (default)
- `110` - PersonalVehicleCar
- `432` - GangAttackPackage
- `162` - PoliceHelicopter

**Blip Colors:**
- `1` - Red (danger/crime)
- `2` - Green (safe)
- `3` - Blue (friendly)
- `5` - Yellow (warning)

---

## 🎮 Usage Guide

### Player Usage

**Robbing a Pedestrian:**

1. **Equip a Weapon**
   - Must have weapon in inventory
   - Must draw/equip the weapon (not holstered)

2. **Find a Target**
   - Approach any NPC pedestrian
   - Must be within 2.5 meters

3. **Initiate Robbery**
   - Look at NPC (qb-target eye appears)
   - Select "Rob Pedestrian" option
   - System validates weapon requirement

4. **Complete Robbery**
   - Stay still during progress bar (16 seconds default)
   - Player automatically aims weapon at NPC
   - NPC raises hands in surrender
   - Cancel anytime by moving or pressing escape

5. **Receive Reward**
   - Cash added to inventory
   - Notification shows amount stolen
   - NPC can't be robbed again this session

**Tips:**
- Rob in secluded areas to avoid police
- More police online = higher chance of quick response
- Each NPC can only be robbed once
- Can't rob NPCs in vehicles or mission peds

### Police/Law Enforcement Usage

**Responding to Robberies:**

1. **Receive Alert**
   - Notification appears with location details
   - Shows street name and zone
   - Alert visible for 10 seconds (configurable)

2. **Set Waypoint**
   - Press **[E]** during notification
   - GPS waypoint set automatically
   - Red blip appears on map

3. **Navigate to Scene**
   - Follow GPS waypoint
   - Blip disappears after 24 seconds
   - Respond before robber escapes

**Alert Details Include:**
- Primary street name
- Cross street (if applicable)
- Zone name (e.g., "Downtown Vinewood")
- GPS coordinates (via blip)

---

## 🧠 System Mechanics

### Weapon Validation System

**Client-Side Check:**
```lua
-- Checks if weapon is drawn (not holstered)
GetSelectedPedWeapon(playerPed) ~= WEAPON_UNARMED
```

**Server-Side Verification:**
```lua
-- Confirms player actually owns a weapon in inventory
QBCore.Functions.CreateCallback('mnc-robnpc:server:HasWeapon')
```

**Supported Weapon Categories:**
- 🔪 Melee (knives, bats, crowbars, etc.)
- 🔫 Handguns (pistols, revolvers)
- 🔫 SMGs (machine pistols, micro SMGs)
- 🔫 Shotguns (pump, sawed-off, assault)
- 🔫 Assault Rifles (carbines, bullpups)
- 🔫 LMGs (combat MG, Gusenberg)
- 🔫 Sniper Rifles
- 💣 Heavy Weapons (RPG, grenade launcher)
- 💣 Throwables (grenades, Molotovs)

**Complete weapon list in `server.lua` - 80+ weapons supported!**

### Robbery Flow

```
1. Player targets NPC with weapon drawn
   ↓
2. Client validates: drawn weapon + distance
   ↓
3. Server validates: weapon in inventory
   ↓
4. NPC freezes, raises hands, faces player
   ↓
5. Player aims weapon automatically
   ↓
6. Progress bar runs (16s default)
   ↓
7. Success: Cash given, police notified
   OR
   Cancel: NPC released, no reward
   ↓
8. NPC marked as robbed (can't rob again)
```

### Police Notification Flow

```
1. Robbery completes successfully
   ↓
2. Server gets robbery coordinates
   ↓
3. Finds all online players with police job
   ↓
4. Sends notification to each officer
   ↓
5. Officer sees alert with location
   ↓
6. Officer presses [E] within 10 seconds
   ↓
7. GPS waypoint set + blip appears
   ↓
8. Blip disappears after 24 seconds
```

### Anti-Robbery Protections

**NPCs Cannot Be Robbed If:**
- ❌ Already robbed this session
- ❌ In a vehicle
- ❌ Dead
- ❌ Not human (animals, special models)
- ❌ Mission/scripted NPCs
- ❌ Player is too far away (>3m)

**Players Cannot Rob If:**
- ❌ No weapon drawn
- ❌ No weapon in inventory
- ❌ Too far from target

---

## 🔧 Troubleshooting

### Common Issues

**"Rob Pedestrian" option not appearing:**
- Ensure qb-target is running
- Check if NPC is human (not animal/special ped)
- Verify NPC isn't in vehicle
- Confirm NPC hasn't been robbed already
- Try restarting resource: `/restart mnc-robnpc`

**"You need to draw a weapon" error:**
- Actually equip/draw your weapon (not just have it)
- Press weapon key or use weapon wheel
- Verify weapon is visible in your hands
- Try switching to different weapon

**"You need a weapon in inventory" error:**
- Check you actually own a weapon
- Weapon must be in inventory, not just equipped
- Verify weapon item name matches QBCore items
- Check server console for callback errors

**Police not receiving alerts:**
- Verify job name matches `Config.NotifyJobs`
- Check officer is on duty (job.onduty = true may be required)
- Ensure ox_lib is properly installed
- Look for client console errors

**Blip not appearing:**
- Must press [E] within notification duration
- Check `Config.BlipTime` isn't set to 0
- Verify notification shows up first
- Client console may show errors

**NPC stuck with hands up:**
- Restart resource: `/restart mnc-robnpc`
- NPC should unfreeze automatically after robbery
- Check for client errors during cleanup
- Bug may occur if resource stopped mid-robbery

**Progress bar doesn't appear:**
- Ensure ox_lib is running
- Check ox_lib version is current
- Look for client console errors
- Verify resource started after ox_lib

---

## 🎨 Customization Examples

### Adjusting Difficulty & Rewards

```lua
-- Make robberies faster and more profitable
Config.RobDuration = 8000   -- 8 seconds instead of 16
Config.MinCash = 50         -- $50 minimum
Config.MaxCash = 300        -- $300 maximum

-- Make robberies slower and less rewarding
Config.RobDuration = 30000  -- 30 seconds
Config.MinCash = 5          -- $5 minimum
Config.MaxCash = 50         -- $50 maximum
```

### Adding Multiple Law Enforcement Jobs

```lua
Config.NotifyJobs = {
    "police",
    "bcso",        -- Blaine County Sheriff
    "sheriff",
    "sasp",        -- San Andreas State Police
    "corrections", -- Prison guards
    "rangers"      -- Park rangers
}
```

### Custom Notification Messages

```lua
-- Casual server style
Config.NotifyMessage = "Someone's getting mugged at %s! Get over there!"

-- Serious RP style
Config.NotifyMessage = "10-31 - Armed Robbery in progress at %s. All units respond. Press [E] to mark."

-- Minimal style
Config.NotifyMessage = "Robbery at %s - [E] to respond"
```

### Changing Blip Appearance

```lua
-- Discrete response (green, smaller)
Config.BlipSprite = 161
Config.BlipColour = 2      -- Green
Config.BlipScale = 0.7     -- Smaller
Config.BlipTime = 15       -- 15 seconds only

-- High priority (flashing red, larger)
Config.BlipSprite = 161
Config.BlipColour = 1      -- Red
Config.BlipScale = 1.5     -- Larger
Config.BlipTime = 60       -- 1 minute
```

### Extended Blip Duration

```lua
-- Blip lasts 2 minutes for slow response
Config.BlipTime = 120

-- Blip lasts only 10 seconds (quick dispatch)
Config.BlipTime = 10
```

---

## 🔗 Advanced Modifications

### Adding Item Rewards

Modify `server.lua` in the `GiveCash` event:

```lua
-- Give cash + chance for items
local amount = math.random(Config.MinCash, Config.MaxCash)
Player.Functions.AddMoney('cash', amount)

-- 30% chance to get a phone
if math.random(100) <= 30 then
    Player.Functions.AddItem('phone', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, 
        QBCore.Shared.Items['phone'], "add")
end

-- 10% chance to get jewelry
if math.random(100) <= 10 then
    Player.Functions.AddItem('rolex', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, 
        QBCore.Shared.Items['rolex'], "add")
end
```

### Adding Success Chance

Modify `client.lua` before giving cash:

```lua
if success then
    robbedPeds[ped] = true
    local coords = GetEntityCoords(ped)
    
    -- 85% success chance, 15% NPC fights back
    if math.random(100) <= 85 then
        TriggerServerEvent('mnc-robnpc:server:GiveCash', coords)
    else
        -- NPC fights back
        TaskCombatPed(ped, playerPed, 0, 16)
        lib.notify({
            title = 'Robbery Failed',
            description = 'The pedestrian fought back!',
            type = 'error'
        })
    end
end
```

### Adding Cooldown System

Add to `client.lua`:

```lua
local lastRobbery = 0
local ROBBERY_COOLDOWN = 60000  -- 60 seconds

-- In AttemptRob event, before weapon check:
if GetGameTimer() - lastRobbery < ROBBERY_COOLDOWN then
    local remaining = math.ceil((ROBBERY_COOLDOWN - (GetGameTimer() - lastRobbery)) / 1000)
    lib.notify({
        title = 'Cooldown Active',
        description = 'Wait ' .. remaining .. ' seconds before robbing again.',
        type = 'error'
    })
    return
end

-- After successful robbery:
lastRobbery = GetGameTimer()
```

### Adding Wanted Level

Add to `server.lua` after cash is given:

```lua
-- Give 2-star wanted level
TriggerClientEvent('police:SetCopCount', src, 2)
```

### Blacklisting Specific Weapon Types

Modify `server.lua` weapons table to exclude categories:

```lua
-- Remove throwables if you don't want grenade robberies
-- Just delete or comment out the throwables section:
-- "weapon_grenade", "weapon_bzgas", "weapon_molotov", etc.

-- Or create separate lists:
local validRobberyWeapons = {
    "weapon_pistol",
    "weapon_combatpistol",
    -- Only allow handguns...
}
```

---

## 📊 Performance

### Optimization Features
- **Event-driven architecture** - Only runs when players interact
- **Session-based tracking** - No database queries
- **Efficient targeting** - qb-target handles NPC detection
- **Smart cleanup** - Entities released properly every time
- **No continuous threads** - Only creates threads during active robberies
- **Minimal network traffic** - Server events only on robbery completion

### Resource Usage
- **Client CPU**: < 0.01ms (idle), ~0.05ms (during robbery)
- **Server CPU**: < 0.01ms average
- **Memory**: ~500 KB
- **Network**: Negligible

### Tested With
- ✅ 128+ concurrent players
- ✅ Multiple simultaneous robberies
- ✅ Heavy qb-target usage
- ✅ Server restarts during robbery
- ✅ Extended play sessions (24+ hours)

---

## 🔐 Security

### Anti-Exploit Features
- **Server-side weapon validation** - Client can't fake weapon ownership
- **Distance checks** - Prevents long-range exploitation
- **One robbery per NPC** - Session tracking prevents spam
- **Progress bar required** - Can't instantly rob NPCs
- **Proper entity validation** - Can't target invalid entities
- **Double-check weapon draw** - Client + server validation

### Known Limitations
- Robbed NPC list resets on server restart
- Players can rob unlimited different NPCs (no global cooldown by default)
- No reputation/heat system (can be added)
- Police alerts don't stack (one alert per robbery)

### Recommended Additional Security
- Add cooldown between robberies (see customization examples)
- Implement wanted level system
- Add rep/heat that increases police response
- Log robberies to database for admin review
- Add blacklist for weapon types

---

## 🔄 Compatibility

### Tested & Compatible
- ✅ qb-core (latest)
- ✅ qb-target
- ✅ ox_lib notifications
- ✅ ox_lib progress bars
- ✅ qb-policejob
- ✅ qb-ambulancejob
- ✅ Most inventory systems

### Known Conflicts
- ⚠️ Other NPC robbery scripts (use only one)
- ⚠️ Custom wanted level systems (may need integration)
- ⚠️ NPC protection scripts (may block targeting)

### Integration Opportunities
- 💡 qb-dispatch (replace basic alerts with advanced dispatch)
- 💡 qb-phone (send robbery alerts to phone app)
- 💡 ps-mdt/qb-mdt (log crimes to police database)
- 💡 Custom reputation systems
- 💡 Gang territory scripts

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

## 📄 Changelog

### Version 1.1.0 (Current Release)
**New Features:**
- ✨ Added comprehensive weapon validation system with 80+ supported weapons
- ✨ Implemented dual-check weapon system (client draw + server inventory)
- ✨ Added distance validation to prevent long-range exploits
- ✨ Created session-based robbed NPC tracking
- ✨ Implemented automatic NPC cleanup after robbery (success or cancel)

**Improvements:**
- 🔧 Enhanced NPC interaction with hands-up animation loops
- 🔧 Improved player aiming mechanic during robbery
- 🔧 Better notification system with ox_lib integration
- 🔧 Added proper entity unfreezing on cancel/complete
- 🔧 Enhanced police alert with street and zone details

**Bug Fixes:**
- 🐛 Fixed NPCs remaining frozen after cancelled robbery
- 🐛 Resolved player getting stuck in aiming pose
- 🐛 Corrected NPC tasks not clearing properly
- 🐛 Fixed multiple robberies on same NPC exploit
- 🐛 Resolved targeting issues with mission peds
- 🐛 Fixed distance check bypass vulnerability

---

### Version 1.0.0 (Initial Release)
**New Features:**
- ✨ Initial public release
- ✨ qb-target integration for NPC targeting
- ✨ Weapon requirement system
- ✨ Police notification system with GPS blips
- ✨ Interactive [E] to respond mechanic
- ✨ ox_lib progress bar integration
- ✨ Random cash reward system ($10-$100)
- ✨ Configurable robbery duration
- ✨ Hands-up NPC animations
- ✨ Automatic player weapon aiming
- ✨ One-time robbery per NPC
- ✨ Temporary map blips for police

**Features:**
- 💰 Cash-based reward system
- 🚨 Multi-job police alerts
- 📍 GPS waypoint automation
- 🎯 Smart NPC targeting filters
- ⏱️ Customizable timings
- 🔫 All weapon type support
- 🛡️ Anti-exploit protections

---

## ⚠️ Important Notes

1. **Weapon Requirement**: Players MUST have weapon drawn AND in inventory - both checks required
2. **Session-Based**: Robbed NPC tracking resets on server restart
3. **No Cooldown**: By default, players can rob unlimited NPCs - add cooldown if desired
4. **Police Alerts**: Only jobs in `Config.NotifyJobs` receive notifications
5. **One Robbery Per NPC**: Each NPC can only be robbed once per session
6. **qb-target Required**: This script relies entirely on qb-target for NPC interaction
7. **Cash Only**: Default system gives cash - modify for item rewards

---

*Have a feature request? Open an issue on GitHub!*

---

**Enjoy realistic NPC robberies on your FiveM server! 💰**
