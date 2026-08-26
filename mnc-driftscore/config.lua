-- config.lua
Config = {}
Config.DefaultStyle = 1
Config.DriftThresholdAngle = 15.0
Config.MaxDriftAngle = 150.0  
Config.SpinOutRotationRate = 3.5  
Config.MinDriftSpeed = 5.0
Config.PointsMultiplierBase = 1.0
Config.ComboTimeout = 3500
Config.InactiveResetTime = 5000 

Config.HUD = {
    multiplier = { enabled = true, position = { top = "50px", right = "850px" } },
	score = { enabled = true, position = { top = "100px", right = "850px" } },
	reputation = { enabled = true, position = { top = "1020px", right = "650px" } },
	coins = { enabled = true, position = { top = "1020px", right = "850px" } },
	combo = { enabled = true, position = { top = "1020px", right = "1050px" } },
}

-- Leaderboard settings
Config.Leaderboard = {
    DisplayCount = 10,        -- how many rows to show per board
    MinScoreToSubmit = 50,    -- ignore trivial/junk scores
}

-- Reputation & Drift Coins

Config.Reputation = {
    PointsPerRP = 100,  -- points of a saved chain needed to earn 1 Reputation (remainder is dropped)
    RPPerCoin = 10,     -- Reputation needed to earn 1 Drift Coin
}

-- Drift Coin Store (accessible from the "Store" tab on /driftboard)
Config.Store = {
    {
        id = "repair_kit",
        type = "item",
        item = "repairkit",
        amount = 1,
        name = "Repair Kit",
        description = "Patch up your ride after a rough drift session.",
        price = 1,
        icon = "fa-wrench",
    },
    {
        id = "anti_lag2",
        type = "item",
        item = "antilag_2",
        amount = 1,
        name = "street antilag",
        description = "A antilag kit.",
        price = 4,
        icon = "fa-fire",
    },   
    {
        id = "pro_angle_kit",
        type = "item",
        item = "pro_angle_kit",
        amount = 1,
        name = "Pro Angle Kit",
        description = "A Pro angle kit.",
        price = 8,
        icon = "fa-dot-circle",
    },
    {
        id = "bank_10000",
        type = "bank",
        amount = 10000,
        name = "$10,000 Bank Transfer",
        description = "Deposit $10,000 straight into your bank account.",
        price = 10,
        icon = "fa-university",
    },
    {
        id = "bank_20000",
        type = "bank",
        amount = 20000,
        name = "$20,000 Bank Transfer",
        description = "Deposit $20,000 straight into your bank account.",
        price = 20,
        icon = "fa-university",
    },
	{
        id = "bank_30000",
        type = "bank",
        amount = 30000,
        name = "$30,000 Bank Transfer",
        description = "Deposit $30,000 straight into your bank account.",
        price = 30,
        icon = "fa-university",
    },
	{
        id = "bank_40000",
        type = "bank",
        amount = 40000,
        name = "$40,000 Bank Transfer",
        description = "Deposit $40,000 straight into your bank account.",
        price = 40,
        icon = "fa-university",
    },
    {
        id = "bank_50000",
        type = "bank",
        amount = 50000,
        name = "$50,000 Bank Transfer",
        description = "Deposit $50,000 straight into your bank account.",
        price = 50,
        icon = "fa-university",
    },
	{
        id = "bank_100000",
        type = "bank",
        amount = 10000,
        name = "$100,000 Bank Transfer",
        description = "Deposit $100,000 straight into your bank account.",
        price = 85,
        icon = "fa-university",
    },
}

Config.Styles = {
    [1]  = { name = "Classic Green",        bg = "rgba(30,30,46,0.5)",      text = "#ffffff", accent = "#4CAF50",  description = "Clean dark theme with green accents" },
    [2]  = { name = "Purple Storm",         bg = "rgba(44,44,84,0.6)",      text = "#f1c40f", accent = "#e74c3c",  description = "Purple base with red highlights" },
    [3]  = { name = "Neon Dark",            bg = "rgba(20,20,20,0.4)",      text = "#0be881", accent = "#0be881", description = "Dark background with bright neon green" },
    [4]  = { name = "Blue Glass",           bg = "rgba(47,53,66,0.7)",      text = "#70a1ff", accent = "#1e90ff", description = "Modern glass effect with blue tones" },
    [5]  = { name = "Orange Mist",          bg = "rgba(87,96,111,0.7)",     text = "#ffa502", accent = "#ffa502", description = "Grey base with warm orange highlights" },
    [6]  = { name = "Cyberpunk Neon",       bg = "linear-gradient(135deg, rgba(15,15,35,0.9), rgba(25,25,55,0.7))", text = "#00ffff", accent = "#ff00ff", description = "Futuristic cyberpunk aesthetic" },
    [7]  = { name = "Dark Matrix",          bg = "linear-gradient(45deg, rgba(10,10,10,0.95), rgba(30,0,30,0.8))", text = "#b19cd9", accent = "#ff6b6b", description = "Matrix-inspired dark purple theme" },
    [8]  = { name = "Ocean Tech",           bg = "radial-gradient(circle, rgba(0,20,40,0.9), rgba(0,0,20,0.95))", text = "#64ffda", accent = "#ffab00", description = "Deep ocean technology vibes" },
    [9]  = { name = "Pink Hacker",          bg = "linear-gradient(180deg, rgba(15,0,30,0.9), rgba(30,0,15,0.8))", text = "#ff4081", accent = "#e91e63", description = "Hacker aesthetic with pink highlights" },
    [10] = { name = "Rotating Tech",        bg = "conic-gradient(from 180deg, rgba(0,0,0,0.95), rgba(20,20,80,0.8), rgba(0,0,0,0.95))", text = "#00e676", accent = "#76ff03", description = "Rotating gradient with tech green" },
    [11] = { name = "Mars Red",             bg = "linear-gradient(90deg, rgba(40,0,0,0.9), rgba(80,20,0,0.8))", text = "#ffccbc", accent = "#ff5722", description = "Mars-inspired red gradient" },
    [12] = { name = "Ice Blue",             bg = "radial-gradient(ellipse, rgba(0,30,60,0.9), rgba(0,0,30,0.95))", text = "#81d4fa", accent = "#03a9f4", description = "Cool ice blue technology" },
    [13] = { name = "Golden Honey",         bg = "linear-gradient(225deg, rgba(30,30,0,0.9), rgba(60,40,0,0.8))", text = "#fff59d", accent = "#fbc02d", description = "Warm golden honey tones" },
    [14] = { name = "Purple Vortex",        bg = "conic-gradient(from 90deg, rgba(20,0,40,0.95), rgba(40,0,80,0.8), rgba(20,0,40,0.95))", text = "#ce93d8", accent = "#9c27b0", description = "Swirling purple vortex effect" },
    [15] = { name = "Teal Hologram",        bg = "linear-gradient(135deg, rgba(0,40,40,0.95), rgba(0,60,60,0.85), rgba(0,20,40,0.9))", text = "#4dd0e1", accent = "#00acc1", description = "Holographic teal display" },
    [16] = { name = "Sunset Plasma",        bg = "linear-gradient(45deg, rgba(60,0,20,0.9), rgba(100,20,0,0.8), rgba(80,40,0,0.85))", text = "#ffab40", accent = "#ff6d00", description = "Plasma sunset with orange glow" },
    [17] = { name = "Arctic Storm",         bg = "radial-gradient(circle at 30% 70%, rgba(0,40,80,0.9), rgba(10,10,40,0.95))", text = "#b3e5fc", accent = "#0277bd", description = "Fierce arctic storm effect" },
    [18] = { name = "Toxic Waste",          bg = "linear-gradient(180deg, rgba(20,40,0,0.9), rgba(40,60,0,0.8), rgba(60,80,0,0.85))", text = "#c0ff8c", accent = "#76ff03", description = "Radioactive toxic green theme" },
    [19] = { name = "Royal Purple",         bg = "conic-gradient(from 270deg, rgba(40,0,60,0.95), rgba(80,20,100,0.8), rgba(60,0,80,0.9))", text = "#e1bee7", accent = "#ab47bc", description = "Majestic royal purple gradient" },
    [20] = { name = "Blood Moon",           bg = "radial-gradient(ellipse at 80% 20%, rgba(60,0,0,0.95), rgba(40,0,0,0.9), rgba(20,0,0,0.95))", text = "#ffcdd2", accent = "#d32f2f", description = "Ominous blood moon atmosphere" },
	
	[21] = {
        name = "Neon City",
        bg = "linear-gradient(135deg, rgba(0,20,40,0.9), rgba(20,0,60,0.8), rgba(40,0,40,0.85))",
        text = "#64ffda",
        accent = "#e91e63",
        description = "Vibrant neon city lights"
    },
    [22] = {
        name = "Chrome Steel",
        bg = "linear-gradient(90deg, rgba(40,40,50,0.9), rgba(60,60,70,0.8), rgba(50,50,60,0.85))",
        text = "#eceff1",
        accent = "#607d8b",
        description = "Sleek chrome and steel finish"
    },
    [23] = {
        name = "Forest Fire",
        bg = "radial-gradient(circle at 10% 80%, rgba(60,20,0,0.9), rgba(40,40,0,0.8), rgba(20,60,0,0.85))",
        text = "#fff8e1",
        accent = "#ff8f00",
        description = "Blazing forest fire gradient"
    },
    [24] = {
        name = "Deep Space",
        bg = "conic-gradient(from 0deg, rgba(0,0,20,0.98), rgba(20,0,40,0.85), rgba(0,20,60,0.9))",
        text = "#b39ddb",
        accent = "#3f51b5",
        description = "Mysterious deep space nebula"
    },
    [25] = {
        name = "Quantum Flux",
        bg = "linear-gradient(225deg, rgba(20,0,40,0.95), rgba(0,40,60,0.8), rgba(40,20,0,0.9))",
        text = "#80cbc4",
        accent = "#00695c",
        description = "Quantum energy flux field"
    }
}

-- ALL COMBOS - FULLY ACTIVE WITH PROPER DETECTION
Config.Combos = {
    -- ANGLE BASED
    { name = "Mild Drift",       comboType = "angle", condition = function(a) return a > 15 and a <= 30 end,      multiplier = 0.4 },
    { name = "Solid Angle",      comboType = "angle", condition = function(a) return a > 30 and a <= 45 end,      multiplier = 0.8 },
    { name = "Wild Angle",       comboType = "angle", condition = function(a) return a > 45 and a <= 65 end,      multiplier = 1.3 },
    { name = "Insane Angle",     comboType = "angle", condition = function(a) return a > 65 end,                  multiplier = 2.0 },

    -- SPEED BASED
    { name = "Speed Demon",      comboType = "speed", condition = function(s) return s > 40 end,                  multiplier = 0.9 },
    { name = "Hyperspeed",       comboType = "speed", condition = function(s) return s > 55 end,                  multiplier = 1.6 },

    -- PROXIMITY BASED
    { name = "Wall Hugger",      comboType = "proximity", condition = function(d) return d < 1.8 and d > 0.4 end, multiplier = 1.4 },
    { name = "Millimeter Drift", comboType = "proximity", condition = function(d) return d <= 0.4 end,            multiplier = 2.2 },

    -- DURATION BASED
    { name = "Smooth Operator",  comboType = "duration", condition = function(t) return t > 4000 and t <= 8000 end, multiplier = 0.7 },
    { name = "Marathon Drift",   comboType = "duration", condition = function(t) return t > 8000 end,               multiplier = 1.5 },

    -- COMBINATION BASED
    { name = "Tokyo Style",      comboType = "angle_speed", condition = function(a,s) return a > 50 and s > 35 end,     multiplier = 1.8 },
    { name = "Wall Runner",      comboType = "angle_proximity", condition = function(a,d) return a > 40 and d < 2.5 end, multiplier = 1.3 },
    { name = "Risky Business",   comboType = "angle_proximity", condition = function(a,d) return a > 70 and d < 1.2 end, multiplier = 2.8 },
    { name = "Feint Drift",      comboType = "angle_speed", condition = function(a,s) return a > 55 and s <= 25 end,    multiplier = 1.7 },

    -- ADVANCED COMBOS
    { name = "Tandem Bonus",     comboType = "tandem", 
      condition = function(nearbyDrifters) 
          return nearbyDrifters >= 1
      end, 
      multiplier = 1.4 
    },

    { name = "Reverse Entry",    comboType = "reverse_entry", 
      condition = function(reverseDetected, angle) 
          return reverseDetected and angle > 95
      end, 
      multiplier = 1.9 
    },

    { name = "Clutch Kick",      comboType = "clutch_kick", 
      condition = function(throttleDelta, angleDelta) 
          return throttleDelta > 0.5 and angleDelta > 10
      end, 
      multiplier = 1.6 
    },

    { name = "Chicane Master",   comboType = "chicane", 
      condition = function(headingChanges, angle) 
          return headingChanges >= 3 and angle > 30
      end, 
      multiplier = 2.1 
    },

    { name = "Donut King",       comboType = "donut", 
    condition = function(rotVel, speed) return rotVel > 0.6 and speed < 22 end,
    multiplier = 1.9,
    },

    { name = "E-Brake Hero",     comboType = "ebrake", 
      condition = function(timeSinceHandbrake, angleDelta) 
          return timeSinceHandbrake < 300 and angleDelta > 20
      end, 
      multiplier = 1.5 
    },

    { name = "Link Drift",       comboType = "link", 
      condition = function(chainTime, angle, headingChanges) 
          return chainTime > 3000 and angle > 20 and headingChanges >= 2
      end, 
      multiplier = 1.7 
    },
}