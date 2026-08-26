Config = {}

-- Default UI style (1-25)
Config.DefaultStyle = 1 

-- UI Position & Size (Adjusted for better visibility)
Config.UI = {
    x = "15px",  -- Moved closer to screen edge
    y = "537px",  -- Moved higher for visibility
    width = "auto",  -- Increased width for better readability
    height = "auto",
}

-- Notification UI Position & Size
Config.NotifyUI = {
    x = "1685px",  -- Left side of screen
    y = "20px",  -- Top of screen
    width = "auto",
    height = "auto",
    duration = 5000  -- Duration in milliseconds (3 seconds)
}

-- Command to switch UI style
Config.StyleCommand = "weaponui"

-- Framework auto-detect
Config.UseOxInventory = GetResourceState('ox_inventory') == 'started'
Config.UseQbInventory = GetResourceState('qb-inventory') == 'started'


-- 25 Advanced Styles with names and descriptions
Config.Styles = {
    [1] = { 
        name = "Classic Green",
        bg = "rgba(30,30,46,0.5)", 
        text = "#ffffff", 
        accent = "rgba(76, 175, 80, 0.3)",
        description = "Clean dark theme with green accents"
    },
    [2] = { 
        name = "Purple Storm",
        bg = "rgba(44,44,84,0.6)", 
        text = "#f1c40f", 
        accent = "rgba(231, 76, 60, 0.3)",
        description = "Purple base with red highlights"
    },
    [3] = { 
        name = "Neon Dark",
        bg = "rgba(20,20,20,0.4)", 
        text = "#0be881", 
        accent = "rgba(11, 232, 129, 0.3)",
        description = "Dark background with bright neon green"
    },
    [4] = { 
        name = "Blue Glass",
        bg = "rgba(47,53,66,0.7)", 
        text = "#70a1ff", 
        accent = "rgba(30, 144, 255, 0.3)",
        description = "Modern glass effect with blue tones"
    },
    [5] = { 
        name = "Orange Mist",
        bg = "rgba(87,96,111,0.7)", 
        text = "#ffa502", 
        accent = "rgba(255, 165, 2, 0.3)",
        description = "Grey base with warm orange highlights"
    },
    [6] = { 
        name = "Cyberpunk Neon",
        bg = "linear-gradient(135deg, rgba(15,15,35,0.9), rgba(25,25,55,0.7))", 
        text = "#00ffff", 
        accent = "rgba(255, 0, 255, 0.3)",
        description = "Futuristic cyberpunk aesthetic"
    },
    [7] = { 
        name = "Dark Matrix",
        bg = "linear-gradient(45deg, rgba(10,10,10,0.95), rgba(30,0,30,0.8))", 
        text = "#b19cd9", 
        accent = "rgba(255, 107, 107, 0.3)",
        description = "Matrix-inspired dark purple theme"
    },
    [8] = { 
        name = "Ocean Tech",
        bg = "radial-gradient(circle, rgba(0,20,40,0.9), rgba(0,0,20,0.95))", 
        text = "#64ffda", 
        accent = "rgba(255, 171, 0, 0.3)",
        description = "Deep ocean technology vibes"
    },
    [9] = { 
        name = "Pink Hacker",
        bg = "linear-gradient(180deg, rgba(15,0,30,0.9), rgba(30,0,15,0.8))", 
        text = "#ff4081", 
        accent = "rgba(233, 30, 99, 0.3)",
        description = "Hacker aesthetic with pink highlights"
    },
    [10] = { 
        name = "Rotating Tech",
        bg = "conic-gradient(from 180deg, rgba(0,0,0,0.95), rgba(20,20,80,0.8), rgba(0,0,0,0.95))", 
        text = "#00e676", 
        accent = "rgba(118, 255, 3, 0.3)",
        description = "Rotating gradient with tech green"
    },
    [11] = { 
        name = "Mars Red",
        bg = "linear-gradient(90deg, rgba(40,0,0,0.9), rgba(80,20,0,0.8))", 
        text = "#ffccbc", 
        accent = "rgba(255, 87, 34, 0.3)",
        description = "Mars-inspired red gradient"
    },
    [12] = { 
        name = "Ice Blue",
        bg = "radial-gradient(ellipse, rgba(0,30,60,0.9), rgba(0,0,30,0.95))", 
        text = "#81d4fa", 
        accent = "rgba(3, 169, 244, 0.3)",
        description = "Cool ice blue technology"
    },
    [13] = { 
        name = "Golden Honey",
        bg = "linear-gradient(225deg, rgba(30,30,0,0.9), rgba(60,40,0,0.8))", 
        text = "#fff59d", 
        accent = "rgba(251, 192, 45, 0.3)",
        description = "Warm golden honey tones"
    },
    [14] = { 
        name = "Purple Vortex",
        bg = "conic-gradient(from 90deg, rgba(20,0,40,0.95), rgba(40,0,80,0.8), rgba(20,0,40,0.95))", 
        text = "#ce93d8", 
        accent = "rgba(156, 39, 176, 0.3)",
        description = "Swirling purple vortex effect"
    },
    [15] = { 
        name = "Teal Hologram",
        bg = "linear-gradient(135deg, rgba(0,40,40,0.95), rgba(0,60,60,0.85), rgba(0,20,40,0.9))", 
        text = "#4dd0e1", 
        accent = "rgba(0, 172, 193, 0.3)",
        description = "Holographic teal display"
    },
    [16] = {
        name = "Sunset Plasma",
        bg = "linear-gradient(45deg, rgba(60,0,20,0.9), rgba(100,20,0,0.8), rgba(80,40,0,0.85))",
        text = "#ffab40",
        accent = "rgba(255, 109, 0, 0.3)",
        description = "Plasma sunset with orange glow"
    },
    [17] = {
        name = "Arctic Storm",
        bg = "radial-gradient(circle at 30% 70%, rgba(0,40,80,0.9), rgba(10,10,40,0.95))",
        text = "#b3e5fc",
        accent = "rgba(2, 119, 189, 0.3)",
        description = "Fierce arctic storm effect"
    },
    [18] = {
        name = "Toxic Waste",
        bg = "linear-gradient(180deg, rgba(20,40,0,0.9), rgba(40,60,0,0.8), rgba(60,80,0,0.85))",
        text = "#c0ff8c",
        accent = "rgba(118, 255, 3, 0.3)",
        description = "Radioactive toxic green theme"
    },
    [19] = {
        name = "Royal Purple",
        bg = "conic-gradient(from 270deg, rgba(40,0,60,0.95), rgba(80,20,100,0.8), rgba(60,0,80,0.9))",
        text = "#e1bee7",
        accent = "rgba(171, 71, 188, 0.3)",
        description = "Majestic royal purple gradient"
    },
    [20] = {
        name = "Blood Moon",
        bg = "radial-gradient(ellipse at 80% 20%, rgba(60,0,0,0.95), rgba(40,0,0,0.9), rgba(20,0,0,0.95))",
        text = "#ffcdd2",
        accent = "rgba(211, 47, 47, 0.3)",
        description = "Ominous blood moon atmosphere"
    },
    [21] = {
        name = "Neon City",
        bg = "linear-gradient(135deg, rgba(0,20,40,0.9), rgba(20,0,60,0.8), rgba(40,0,40,0.85))",
        text = "#64ffda",
        accent = "rgba(233, 30, 99, 0.3)",
        description = "Vibrant neon city lights"
    },
    [22] = {
        name = "Chrome Steel",
        bg = "linear-gradient(90deg, rgba(40,40,50,0.9), rgba(60,60,70,0.8), rgba(50,50,60,0.85))",
        text = "#eceff1",
        accent = "rgba(96, 125, 139, 0.3)",
        description = "Sleek chrome and steel finish"
    },
    [23] = {
        name = "Forest Fire",
        bg = "radial-gradient(circle at 10% 80%, rgba(60,20,0,0.9), rgba(40,40,0,0.8), rgba(20,60,0,0.85))",
        text = "#fff8e1",
        accent = "rgba(255, 143, 0, 0.3)",
        description = "Blazing forest fire gradient"
    },
    [24] = {
        name = "Deep Space",
        bg = "conic-gradient(from 0deg, rgba(0,0,20,0.98), rgba(20,0,40,0.85), rgba(0,20,60,0.9))",
        text = "#b39ddb",
        accent = "rgba(63, 81, 181, 0.3)",
        description = "Mysterious deep space nebula"
    },
    [25] = {
        name = "Quantum Flux",
        bg = "linear-gradient(225deg, rgba(20,0,40,0.95), rgba(0,40,60,0.8), rgba(40,20,0,0.9))",
        text = "#80cbc4",
        accent = "rgba(0, 105, 92, 0.3)",
        description = "Quantum energy flux field"
    }
}