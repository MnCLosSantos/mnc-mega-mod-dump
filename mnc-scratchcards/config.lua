Config = {}

Config.Debug = false

Config.ScratchSounds = {
    scratch     = 'sounds/scratch.mp3',
    win_small   = 'sounds/small.mp3',
    win_big     = 'sounds/big.mp3',
}

-- Each scratch card type
Config.ScratchItems = {
    ['scratch_basic'] = {
        label       = 'Basic Scratch Card',
        price       = 15,
        revealType  = 'basic',
        gridSize    = 3,
        winPatterns = {
            { chance = 10.25, reward = 30,   text = '$30'  },
            { chance = 2.58,  reward = 1000, text = '$1000' },
            { chance = 1.55,  reward = 5000, text = '$5,000!' },
        },
        scratchColor = '#d0d0d0',   
        background   = '#1c1c1c',
        accent       = '#ffffff',   
    },

    ['scratch_silver'] = {
        label       = 'Silver Scratch Card',
        price       = 20,
        revealType  = 'silver',
        gridSize    = 3,
        winPatterns = {
            { chance = 7.22, reward = 100,   text = '$100'    },
            { chance = 2.95, reward = 350,   text = '$350'    },
            { chance = 1.45, reward = 12000, text = '$12,000!' },
        },
        scratchColor = '#a8a8b8',  
        background   = '#16161e',
        accent       = '#b0b8cc',  
    },

    ['scratch_gold'] = {
        label       = 'Gold Scratch Card',
        price       = 35,
        revealType  = 'gold',
        gridSize    = 3,
        winPatterns = {
            { chance = 6.18, reward = 300,   text = '$300'    },
            { chance = 2.82, reward = 800,   text = '$800'    },
            { chance = 1.35, reward = 30000, text = '$30,000!' },
        },
        scratchColor = '#c8a84b',  
        background   = '#1a1208',
        accent       = '#f0c040',  
    },

    ['scratch_platinum'] = {
        label       = 'Platinum Scratch Card',
        price       = 55,
        revealType  = 'platinum',
        gridSize    = 3,
        winPatterns = {
            { chance = 5.15, reward = 500,   text = '$500'     },
            { chance = 2.60, reward = 1800,  text = '$1,800'   },
            { chance = 1.22, reward = 75000, text = '$75,000!'  },
        },
        scratchColor = '#c8d0dc',  
        background   = '#0e1420',
        accent       = '#d4dce8', 
    },

    ['scratch_diamond'] = {
        label       = 'Diamond Scratch Card',
        price       = 65,
        revealType  = 'diamond',
        gridSize    = 3,
        winPatterns = {
            { chance = 3.22, reward = 1000,   text = '$1,000'   },
            { chance = 2.55, reward = 3500,   text = '$3,500'   },
            { chance = 1.18, reward = 150000, text = '$150,000!' },
        },
        scratchColor = '#88d8f0',  
        background   = '#060c18',
        accent       = '#7dd8f8', 
    },
}