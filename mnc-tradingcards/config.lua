Config = {}

Config.Debug = false

-- ============================================================
--  LOOT BOX / PACK CONFIG
-- ============================================================
Config.Packs = {
    ['card_pack_basic'] = {             -- shop value should be around $50
        label     = 'Basic Card Pack',
        cardCount = 3,
        weights   = { common = 70, uncommon = 27, rare = 2, ultraRare = 1 },
        misprintChance = 0.5,
        damagedChance  = 5,
    },
    ['card_pack_premium'] = {             -- shop value should be around $150
        label         = 'Premium Card Pack',
        cardCount     = 5,
        weights       = { common = 60, uncommon = 34, rare = 3, ultraRare = 2 },
        misprintChance = 1,
        damagedChance  = 4,
    },
    ['card_pack_legendary'] = {             -- shop value should be around $200
        label         = 'Legendary Card Pack',
        cardCount     = 5,
        weights       = { common = 50, uncommon = 30, rare = 14, ultraRare = 6 },
        misprintChance = 2,
        damagedChance  = 2,
    },
}

-- ============================================================
--  RARITY DEFINITIONS
--  value = base $ value of a card of this rarity (sell price = value * shop.sellMultiplier)
-- ============================================================
Config.Rarities = {
    common    = { label = 'Common',     color = '#a0a0a0', holo = false, value = 10   },
    uncommon  = { label = 'Uncommon',   color = '#4ade80', holo = false, value = 50   },
    rare      = { label = 'Rare',       color = '#60a5fa', holo = true,  value = 100  },
    ultraRare = { label = 'Ultra Rare', color = '#f59e0b', holo = true,  value = 500 },
    misprint  = { label = 'Misprint',   color = '#e040fb', holo = true,  value = 1000 },
    damaged   = { label = 'Damaged',    color = '#ef5350', holo = false, value = 5    },
}

-- ============================================================
--  BINDER CONFIG
-- ============================================================
Config.Binders = {
    ['card_binder'] = {
        label           = 'Card Binder',
        maxSets         = 999,
        completionBonus = 1.5,
    },
}

-- ============================================================
--  SHOP LOCATION
-- ============================================================
Config.Shop = {
    coords         = vector3(-1288.06, -310.31, 36.65),
    heading        = 360.0,
    blipSprite     = 500,
    blipColor      = 5,
    blipScale      = 0.8,
    blipName       = 'Card Dealer',
    sellMultiplier      = 0.8,
    setCompletionBonus  = 1.25,
}

-- ============================================================
--  VEHICLE IMAGE SOURCES
-- ============================================================
Config.VehicleImageSources = {
    fivem   = 'https://docs.fivem.net/vehicles/{model}.webp',
    github1 = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage/raw/main/{model}.png',
    github2 = 'https://github.com/MnCLosSantos/mnc-vehicle-image-storage-2/raw/main/{model}.png',
}
Config.VehicleImageSourceOrder = { 'fivem', 'github1', 'github2' }

-- ============================================================
--  COLLECTOR SETS
--
--  Card fields:
--    number     = sequential card number in set
--    name       = display name
--    model      = GTA V vehicle model -- image resolved via
--                 Config.VehicleImageSources (see above)
--    image      = custom foreground image  e.g. 'images/mycard.png'
--    background = custom background PNG    e.g. 'images/bg_rhino.png'
--    rarity     = 'common'|'uncommon'|'rare'|'ultraRare'
--    printNum   = override print label shown on card e.g. '#042 / 500'
--    value      = override $ value for this specific card
-- ============================================================
Config.Sets = {

    ['military'] = {
        label  = 'Military Forces',
        icon   = '🎖️',
        cards  = {
            { number = 1,  name = 'Vetir Troop Transport',    model = 'vetir',       rarity = 'common'   },
            { number = 2,  name = 'Barracks Troop Transport', model = 'barracks',    rarity = 'common'   },
            { number = 3,  name = 'Mesa Crusader',            model = 'crusader',    rarity = 'common'   },
            { number = 4,  name = 'Halftrack',                model = 'halftrack',   rarity = 'uncommon' },
            { number = 5,  name = 'RCV',                      model = 'riot2',       rarity = 'uncommon' },
            { number = 6,  name = 'Menacer',                  model = 'menacer',     rarity = 'uncommon' },
            { number = 7,  name = 'Barracks Semi',            model = 'barracks2',   rarity = 'uncommon' },
            { number = 8,  name = 'Army Trailer',             model = 'armytrailer', rarity = 'uncommon' },
            { number = 9,  name = 'Army Tanker',              model = 'armytanker',  rarity = 'uncommon' },
            { number = 10, name = 'Insurgent',                model = 'insurgent',   rarity = 'rare'     },
            { number = 11, name = 'APC',                      model = 'apc',         rarity = 'rare'     },
            { number = 12, name = 'Barrage',                  model = 'barrage',     rarity = 'rare'     },
            { number = 13, name = 'Chernobog',                model = 'chernobog',   rarity = 'rare'     },
            { number = 14, name = 'Nightshark',               model = 'nightshark',  rarity = 'rare'     },
            { number = 15, name = 'Terrorbyte',               model = 'terbyte',     rarity = 'rare',     value = 600  },
            { number = 16, name = 'Khanjali',                 model = 'khanjali',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 17, name = 'Rhino Tank',               model = 'rhino',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1200 },
            { number = 18, name = 'Thruster Jet Pack',        model = 'thruster',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1300 },
            { number = 19, name = 'Kosatka Submarine',        model = 'kosatka',     background = 'images/card2back.png', rarity = 'ultraRare', value = 1400 },
            { number = 20, name = 'KURTZ 31 Patrol Boat',     model = 'patrolboat',  background = 'images/card2back.png', rarity = 'ultraRare', value = 1500 },
        },
    },

    ['police'] = {
        label  = 'Police Fleet',
        icon   = '🚔',
        cards  = {
        { number = 1,  name = 'Police Cruiser',              model = 'police',        rarity = 'common'   },
        { number = 2,  name = 'Police Cruiser 2',            model = 'police2',       rarity = 'common'   },
        { number = 3,  name = 'Police Cruiser 3',            model = 'police3',       rarity = 'common'   },
        { number = 4,  name = 'Sheriff Cruiser',             model = 'sheriff',       rarity = 'common'   },
        { number = 5,  name = 'Unmarked Cruiser',            model = 'police4',       rarity = 'common'   },
        { number = 6,  name = 'Police Rancher',              model = 'policeold1',    rarity = 'uncommon' },
        { number = 7,  name = 'Police Roadcruiser',          model = 'policeold2',    rarity = 'uncommon' },
        { number = 8,  name = 'Sheriff SUV',                 model = 'sheriff2',      rarity = 'uncommon' },
        { number = 9,  name = 'Police Transporter',          model = 'policet',       rarity = 'uncommon' },
        { number = 10, name = 'FIB SUV',                     model = 'fbi',           rarity = 'rare'     },
        { number = 11, name = 'FIB SUV 2',                   model = 'fbi2',          rarity = 'rare'     },
        { number = 12, name = 'Prison Bus',                  model = 'pbus',          rarity = 'rare'     },
        { number = 13, name = 'Brute Riot',                  model = 'riot',          rarity = 'rare'     },
        { number = 14, name = 'Dorado Police Package',       model = 'poldorado',     rarity = 'rare'     },
        { number = 15, name = 'Gauntlet Police Package',     model = 'polgauntlet',   background = 'images/card2back.png', rarity = 'ultraRare', value = 1400 },
        { number = 16, name = 'Dominator Police Package',    model = 'poldominator10',background = 'images/card2back.png', rarity = 'ultraRare', value = 1600 },
        { number = 17, name = 'Impaler Police Package',      model = 'polimpaler5',   background = 'images/card2back.png', rarity = 'ultraRare', value = 1800 },
        { number = 18, name = 'Predator Police Package',     model = 'predator',      background = 'images/card2back.png', rarity = 'ultraRare', value = 2000 },
        { number = 19, name = 'Greenwood Police Package',    model = 'polgreenwood',  background = 'images/card2back.png', rarity = 'ultraRare', value = 2200 },
        { number = 20, name = 'Impaler LX Police Package',   model = 'polimpaler6',   background = 'images/card2back.png', rarity = 'ultraRare', value = 2400 },
        },
    },

    ['planes'] = {
        label  = 'Aviation',
        icon   = '✈️',
        cards  = {
            { number = 1,  name = 'Duster',           model = 'duster',      rarity = 'common'    },
            { number = 2,  name = 'Mammatus',         model = 'mammatus',    rarity = 'common'    },
            { number = 3,  name = 'Dodo',             model = 'dodo',        rarity = 'common'    },
            { number = 4,  name = 'AirLiner',         model = 'jet',         rarity = 'common'    },
            { number = 5,  name = 'Cuban 800',        model = 'cuban800',    rarity = 'uncommon'  },
            { number = 6,  name = 'Mallard',          model = 'stunt',       rarity = 'uncommon'  },
            { number = 7,  name = 'Velum',            model = 'velum',       rarity = 'uncommon'  },
            { number = 8,  name = 'Luxor',            model = 'luxor',       rarity = 'uncommon'  },
            { number = 9,  name = 'Luxor Deluxe',     model = 'luxor2',      rarity = 'uncommon'  },
            { number = 10, name = 'Besra',            model = 'besra',       rarity = 'rare'      },
            { number = 11, name = 'Titan',            model = 'titan',       rarity = 'rare'      },
            { number = 12, name = 'Rogue',            model = 'rogue',       rarity = 'rare'      },
            { number = 13, name = 'Streamer 216',     model = 'streamer216', rarity = 'rare'      },
            { number = 14, name = 'V-65 Molotok',     model = 'molotok',     background = 'images/card2back.png', rarity = 'ultraRare', value = 200  },
            { number = 15, name = 'P-45 Nokota',      model = 'nokota',      background = 'images/card2back.png', rarity = 'ultraRare' },
            { number = 16, name = 'RM-10 Bombushka',  model = 'bombushka',   background = 'images/card2back.png', rarity = 'ultraRare' },
            { number = 17, name = 'RO-86 Alkonost',   model = 'alkonost',    background = 'images/card2back.png', rarity = 'ultraRare', value = 400  },
            { number = 18, name = 'B-11 Strikeforce', model = 'strikeforce', background = 'images/card2back.png', rarity = 'ultraRare', value = 600  },
            { number = 19, name = 'Lazer',            model = 'lazer',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 20, name = 'Hydra',            model = 'hydra',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1500 },
        },
    },

    ['helis'] = {
        label  = 'Helicopters',
        icon   = '🚁',
        cards  = {
            { number = 1, name = 'Frogger',                  model = 'frogger',      rarity = 'common' },
            { number = 2, name = 'Maverick',                 model = 'maverick',     rarity = 'common' },
            { number = 3, name = 'Police Maverick',          model = 'polmav',       rarity = 'common' },      
            { number = 4, name = 'Buzzard',                  model = 'buzzard',      rarity = 'uncommon' },
            { number = 5, name = 'Buzzard Attack Chopper',   model = 'buzzard2',     rarity = 'uncommon' },
            { number = 6, name = 'Swift',                    model = 'swift',        rarity = 'uncommon' },
            { number = 7, name = 'SuperVolito',              model = 'supervolito',  rarity = 'uncommon' },
            { number = 8, name = 'Volatus',                  model = 'volatus',      rarity = 'uncommon' },
            { number = 9, name = 'Annihilator',              model = 'annihilator',  rarity = 'rare' },
            { number = 10, name = 'Cargobob',                model = 'cargobob',     rarity = 'rare' },
            { number = 11, name = 'Valkyrie',                model = 'valkyrie',     rarity = 'rare' },
            { number = 12, name = 'Skylift',                 model = 'skylift',      rarity = 'rare' },
            { number = 13, name = 'Cargobob Jetsam',         model = 'cargobob3',    rarity = 'rare' },
            { number = 14, name = 'Sea Sparrow',             model = 'seasparrow',   rarity = 'rare' },
            { number = 15, name = 'Sparrow',                 model = 'seasparrow2',  rarity = 'rare' },      
            { number = 16, name = 'Havok',                   model = 'havok',        rarity = 'rare' },              
            { number = 17, name = 'Savage',                  model = 'savage',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 18, name = 'Hunter',                  model = 'hunter',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 19, name = 'Akula',                   model = 'akula',        background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 20, name = 'Annihilator Stealth',     model = 'annihilator2', background = 'images/card2back.png', rarity = 'ultraRare', value = 1500 },
        },
    },

    ['motorbikes'] = {
        label  = 'Motorbikes',
        icon   = '🏍️',
        cards  = {
            { number = 1, name = 'PCJ-600',           model = 'pcj',          rarity = 'common' },
            { number = 2, name = 'Sanchez',           model = 'sanchez',      rarity = 'common' },
            { number = 3, name = 'Akuma',             model = 'akuma',        rarity = 'common' },
            { number = 4, name = 'Bati 801',          model = 'bati',         rarity = 'common' },
            { number = 5, name = 'Nagasaki Blazer',   model = 'blazer',       rarity = 'common' }, 
            { number = 6, name = 'Faggio',            model = 'faggio2',      rarity = 'common' },        
            { number = 7, name = 'Ruffian',           model = 'ruffian',      rarity = 'uncommon' },    
            { number = 8, name = 'Daemon',            model = 'daemon',       rarity = 'uncommon' },
            { number = 9, name = 'Carbon RS',         model = 'carbonrs',     rarity = 'uncommon' },
            { number = 10, name = 'Double-T Custom',  model = 'double',       rarity = 'rare' },
            { number = 11, name = 'Nemesis',          model = 'nemesis',      rarity = 'rare' },        
            { number = 12, name = 'Thrust',           model = 'thrust',       rarity = 'rare' },          
            { number = 13, name = 'Vader',            model = 'vader',        rarity = 'rare' },          
            { number = 14, name = 'Hexer',            model = 'hexer',        rarity = 'rare' },            
            { number = 15, name = 'Innovation',       model = 'innovation',   rarity = 'rare' }, 
            { number = 16, name = 'Hakuchou',         model = 'hakuchou',     rarity = 'rare' },
            { number = 17, name = 'Gargoyle',         model = 'gargoyle',     rarity = 'rare' },     
            { number = 18, name = 'Defiler',          model = 'defiler',      rarity = 'rare' },     
	    	{ number = 19, name = 'Sovereign',        model = 'sovereign',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },  
            { number = 20, name = 'Shotaro',          model = 'shotaro',      background = 'images/card2back.png', rarity = 'ultraRare', value = 1200 },  
        },
    },

    ['mfr_bravado'] = {
        label  = 'Bravado Collection',
        icon   = '💎',
        cards  = {
            { number = 1,  name = 'Buffalo',              model = 'buffalo',    rarity = 'common'   },
            { number = 2,  name = 'FCV',                  model = 'riot2',      rarity = 'common'   },
            { number = 3,  name = 'Gauntlet',             model = 'gauntlet',   rarity = 'common'   },
            { number = 4,  name = 'Gresley',              model = 'gresley',    rarity = 'common'   },
            { number = 5,  name = 'Youga',                model = 'youga',      rarity = 'common'   },
            { number = 6,  name = 'Youga Classic',        model = 'youga2',     rarity = 'common'   },
            { number = 7,  name = 'Bison',                model = 'bison',      rarity = 'common'   },
            { number = 8,  name = 'Rat-Loader',           model = 'ratloader',  rarity = 'common'   },
            { number = 9,  name = 'Buffalo S',            model = 'buffalo2',   rarity = 'uncommon' },
            { number = 10, name = 'Dukes',                model = 'dukes',      rarity = 'uncommon' },
            { number = 11, name = 'Dukes O\'Death',       model = 'dukes2',     rarity = 'uncommon' },
            { number = 12, name = 'Gauntlet Classic',     model = 'gauntlet2',  rarity = 'uncommon' },
            { number = 13, name = 'Drift Gauntlet',       model = 'driftgauntlet4',   rarity = 'uncommon' },
            { number = 14, name = 'Banshee',              model = 'banshee',    rarity = 'rare'     },
            { number = 15, name = 'Buffalo STX',          model = 'buffalo4',   rarity = 'rare'     },
            { number = 16, name = 'Gauntlet Hellfire',    model = 'gauntlet3',  rarity = 'rare'     },
            { number = 17, name = 'Youga Classic \'69',   model = 'youga3',     rarity = 'rare'     },
            { number = 18, name = 'Banshee 900R',         model = 'banshee2',   background = 'images/card2back.png', rarity = 'ultraRare', value = 600 },
            { number = 19, name = 'Half-Track',           model = 'halftrack',  background = 'images/card2back.png', rarity = 'ultraRare', value = 800 },
            { number = 20, name = 'Buffalo STX',          model = 'buffalo5',   background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        },
    },

    ['mfr_pegassi'] = {
        label  = 'Pegassi Collection',
        icon   = '💎',
        cards  = {
            { number = 1,  name = 'Monroe',           model = 'monroe',    rarity = 'common'   },
            { number = 2,  name = 'Torero XO',        model = 'torero2',  rarity = 'common'   },
            { number = 3,  name = 'Tezeract',         model = 'tezeract',  rarity = 'uncommon' },
            { number = 4,  name = 'Vacca',            model = 'vacca',     rarity = 'uncommon' },
            { number = 5,  name = 'Infernus',         model = 'infernus',  rarity = 'rare'     },
            { number = 6,  name = 'Reaper',           model = 'reaper',    rarity = 'rare'     },
            { number = 7,  name = 'Tempesta',         model = 'tempesta',  rarity = 'rare'     },
            { number = 8,  name = 'Zorrusso',         model = 'zorrusso',  rarity = 'rare'     },
            { number = 9,  name = 'Zentorno',         model = 'zentorno',  background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 10, name = 'Osiris',           model = 'osiris',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1200 },
        },
    },

    ['mfr_dewbauchee'] = {
        label  = 'Dewbauchee Collection',
        icon   = '💎',
        cards  = {
            { number = 1,  name = 'Exemplar',         model = 'exemplar',  rarity = 'common'    },
            { number = 2,  name = 'Massacro',         model = 'massacro',  rarity = 'common'    },
            { number = 3,  name = 'Rapid GT',         model = 'rapidgt',   rarity = 'uncommon'  },
            { number = 4,  name = 'Massacro Racecar', model = 'massacro2', rarity = 'uncommon'  },
            { number = 5,  name = 'JB 700',           model = 'jb700',     rarity = 'rare'      },
            { number = 6,  name = 'Rapid GT Vert',    model = 'rapidgt2',  rarity = 'rare'      },
            { number = 7,  name = 'Seven-70',         model = 'seven70',   rarity = 'rare'      },
            { number = 8,  name = 'Specter',          model = 'specter',   rarity = 'rare'      },
            { number = 9,  name = 'JB 700W',          model = 'jb7002',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 10, name = 'Specter Custom',   model = 'specter2',  background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        },
    },
	
	['mfr_dinka'] = {
        label  = 'Dinka Collection',
        icon   = '💎',
        cards  = {
            { number = 1,  name = 'Blista',           model = 'blista',    rarity = 'common'    },
            { number = 2,  name = 'kanjo',            model = 'kanjo',     rarity = 'common'    },
            { number = 3,  name = 'Blista Compact',   model = 'blista2',   rarity = 'uncommon'  },
            { number = 4,  name = 'Jester RR',        model = 'jester4',   rarity = 'uncommon'  },
            { number = 5,  name = 'Kanjo SJ',         model = 'kanjosj',   rarity = 'rare'      },
            { number = 6,  name = 'Jester Classic',   model = 'jester3',   rarity = 'rare'      },
            { number = 7,  name = 'Sugoi',            model = 'sugoi',     rarity = 'rare'      },
            { number = 8,  name = 'RT3000',           model = 'rt3000',    rarity = 'rare'      },
            { number = 9,  name = 'Postlude',         model = 'postlude',  background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 10, name = 'Jester Racecar',   model = 'jester2',   background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        },
    },
	
	['mfr_annis'] = {
        label  = 'Annis Collection',
        icon   = '💎',
        cards  = {
            { number = 1,  name = 'Euros',                model = 'euros',       rarity = 'common'    },
            { number = 2,  name = 'Hellion',              model = 'hellion',     rarity = 'common'    },
            { number = 3,  name = 'Elegy Retro Custom',   model = 'elegy',       rarity = 'uncommon'  },
            { number = 4,  name = 'Elegy RH8',            model = 'elegy2',      rarity = 'uncommon'  },
            { number = 5,  name = '300R',                 model = 'r300',        rarity = 'rare'      },
            { number = 6,  name = 'Remus',                model = 'remus',       rarity = 'rare'      },
            { number = 7,  name = 'ZR350',                model = 'zr350',       rarity = 'rare'      },
            { number = 8,  name = 'Savestra',             model = 'savestra',    rarity = 'rare'      },
            { number = 9,  name = 'S80RR',                model = 's80',         background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 10, name = 'RE-7B',                model = 'le7b',        background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        },
    },
	
	['mfr_vapid'] = {
        label  = 'Vapid Collection',
        icon   = '💎',
        cards  = {
            { number = 1,  name = 'Aleutian',             model = 'aleutian',        rarity = 'common'    },
            { number = 2,  name = 'Bobcat XL Open',       model = 'bobcatxl',        rarity = 'common'    },
            { number = 3,  name = 'Caracara 4X4',         model = 'caracara2',       rarity = 'uncommon'  },
            { number = 4,  name = 'Dominator',            model = 'dominator',       rarity = 'uncommon'  },
            { number = 5,  name = 'Clique Wagon',         model = 'clique2',         rarity = 'rare'      },
            { number = 6,  name = 'Chino Luxe',           model = 'chino2',          rarity = 'rare'      },
            { number = 7,  name = 'Dominator ASP',        model = 'dominator7',      rarity = 'rare'      },
            { number = 8,  name = 'Flash GT',             model = 'flashgt',         rarity = 'rare'      },
            { number = 9,  name = 'Dominator GTT',        model = 'dominator8',      background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 10, name = 'FMJ',                  model = 'fmj',             background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        }, 
    },
	
	['mfr_delcasse'] = {
        label  = 'Declasse Collection',
        icon   = '💎',
        cards  = {
            { number = 1,  name = 'Asea',                 model = 'asea',            rarity = 'common'    },
            { number = 2,  name = 'Burrito',              model = 'burrito3',        rarity = 'common'    },
            { number = 3,  name = 'Granger 3600LX',       model = 'granger2',        rarity = 'uncommon'  },
            { number = 4,  name = 'Impaler LX',           model = 'impaler6',        rarity = 'uncommon'  },
            { number = 5,  name = 'Burrito Custom',       model = 'gburrito2',       rarity = 'rare'      },
            { number = 6,  name = 'Tahoma Coupe',         model = 'tahoma',          rarity = 'rare'      },
            { number = 7,  name = 'Tampa',                model = 'tampa',           rarity = 'rare'      },
            { number = 8,  name = 'Yosemite',             model = 'yosemite',        rarity = 'rare'      },
            { number = 9,  name = 'Yosemite Rancher',     model = 'yosemite3',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 10, name = 'Yosemite Drift',       model = 'yosemite2',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        }, 
    },
	
	['mfr_ubermacht'] = {
        label  = 'Übermacht Collection',
        icon   = '💎',
        cards  = {
            { number = 1,  name = 'Oracle',               model = 'oracle',            rarity = 'common'    },
            { number = 2,  name = 'Oracle XS',            model = 'oracle2',           rarity = 'common'    },
            { number = 3,  name = 'Rebla',                model = 'rebla',             rarity = 'uncommon'  },
            { number = 4,  name = 'Rhinehart',            model = 'rhinehart',         rarity = 'uncommon'  },
            { number = 5,  name = 'Sentinel',             model = 'sentinel',          rarity = 'rare'      },
            { number = 6,  name = 'Zion',                 model = 'zion',              rarity = 'rare'      },
            { number = 7,  name = 'Sentinel Classic',     model = 'sentinel3',         rarity = 'rare'      },
            { number = 8,  name = 'Zion Classic',         model = 'zion3',             rarity = 'rare'      },
            { number = 9,  name = 'Niobe',                model = 'niobe',             background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 10, name = 'SC 1',                 model = 'sc1',               background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        }, 
    },
	
	['mfr_benefactor'] = {
        label  = 'Benefactor Collection',
        icon   = '💎',
        cards  = {
            { number = 1,  name = 'Serrano',              model = 'serrano',            rarity = 'common'    },
            { number = 2,  name = 'XLS',                  model = 'xls',                rarity = 'common'    },
            { number = 3,  name = 'Dubsta',               model = 'dubsta',             rarity = 'uncommon'  },
            { number = 4,  name = 'Feltzer',              model = 'feltzer2',           rarity = 'uncommon'  },
            { number = 5,  name = 'Glendale Custom',      model = 'glendale2',          rarity = 'rare'      },
            { number = 6,  name = 'Schlagen',             model = 'schlagen',           rarity = 'rare'      },
            { number = 7,  name = 'SM722',                model = 'sm722',              rarity = 'rare'      },
            { number = 8,  name = 'Krieger',              model = 'krieger',            rarity = 'rare'      },
            { number = 9,  name = 'Stirling GT',          model = 'feltzer3',           background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 10, name = 'BR8',                  model = 'openwheel1',         background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        }, 
    },

    ['mfr_grotti'] = {
        label  = 'Grotti Collection',
        icon   = '💎',
        cards  = {
            { number = 1,  name = 'Carbonizzare',     model = 'carbonizzare', rarity = 'common'                                                        },
            { number = 2,  name = 'Stinger',          model = 'stinger',      rarity = 'uncommon'                                                      },
            { number = 3,  name = 'Stinger GT',       model = 'stingergt',    rarity = 'uncommon'                                                      },
            { number = 4,  name = 'Cheetah',          model = 'cheetah',      rarity = 'rare'                                                          },
            { number = 5,  name = 'Itali GTO',        model = 'italigto',     rarity = 'rare'                                                          },
            { number = 6,  name = 'Itali RSX',        model = 'italirsx',     rarity = 'rare'                                                          },
            { number = 7,  name = 'Turismo R',        model = 'turismor',     rarity = 'rare'                                                          },
            { number = 8,  name = 'Cheetah Classic',  model = 'cheetah2',     background = 'images/card2back.png', rarity = 'ultraRare', value = 1000  },
            { number = 9,  name = 'Furia',            model = 'furia',        background = 'images/card2back.png', rarity = 'ultraRare', value = 1000  },
            { number = 10, name = 'Prototipo',        model = 'prototipo',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1000  },
        },
    },
	
	['mfr_ocelot'] = {
        label  = 'Ocelot Collection',
        icon   = '💎',
        cards  = {
            { number = 1,  name = 'Jackal',           model = 'jackal',       rarity = 'common'                                                        },
            { number = 2,  name = 'F620',             model = 'f620',         rarity = 'uncommon'                                                      },
            { number = 3,  name = 'Jugular',          model = 'jugular',      rarity = 'uncommon'                                                      },
            { number = 4,  name = 'Ardent',           model = 'ardent',       rarity = 'rare'                                                          },
            { number = 5,  name = 'Virtue',           model = 'virtue',       rarity = 'rare'                                                          },
            { number = 6,  name = 'XA-21',            model = 'xa21',         rarity = 'rare'                                                          },
            { number = 7,  name = 'Pariah',           model = 'pariah',       rarity = 'rare'                                                          },
            { number = 8,  name = 'Swinger',          model = 'swinger',      background = 'images/card2back.png', rarity = 'ultraRare', value = 1000  },
            { number = 9,  name = 'Penetrator',       model = 'penetrator',   background = 'images/card2back.png', rarity = 'ultraRare', value = 1000  },
            { number = 10, name = 'R88',              model = 'formula2',     background = 'images/card2back.png', rarity = 'ultraRare', value = 1000  },
        },
    },

    ['mfr_truffade'] = {
        label  = 'Truffade Collection',
        icon   = '⚡',
        cards  = {
            { number = 1, name = 'Adder',       model = 'adder', background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 2, name = 'Thrax',       model = 'thrax', background = 'images/card2back.png', rarity = 'ultraRare', value = 2000 },
            { number = 3, name = 'Nero',        model = 'nero',  background = 'images/card2back.png', rarity = 'ultraRare', value = 3000 },
            { number = 4, name = 'Nero Custom', model = 'nero2', background = 'images/card2back.png', rarity = 'ultraRare', value = 4000 },
            { number = 5, name = 'Z-Type',      model = 'ztype', background = 'images/card2back.png', rarity = 'ultraRare', value = 18000 },
        },
    },
	
	['mfr_enus'] = {
        label  = 'Enus Collection',
        icon   = '⚡',
        cards  = {
            { number = 1, name = 'Deity',                 model = 'deity',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 2, name = 'Jubilee',               model = 'jubilee',     background = 'images/card2back.png', rarity = 'ultraRare', value = 2000 },
            { number = 3, name = 'Cognoscenti 55',        model = 'cog55',       background = 'images/card2back.png', rarity = 'ultraRare', value = 3000 },
            { number = 4, name = 'Paragon',               model = 'paragon',     background = 'images/card2back.png', rarity = 'ultraRare', value = 4000 },
            { number = 5, name = 'Paragon S',             model = 'paragon2',    background = 'images/card2back.png', rarity = 'ultraRare', value = 5000 },
			{ number = 5, name = 'Stafford',              model = 'stafford',    background = 'images/card2back.png', rarity = 'ultraRare', value = 10000 },
        },
    },
	
	['mfr_overflod'] = {
        label  = 'Överflöd Collection',
        icon   = '⚡',
        cards  = {
            { number = 1, name = 'Imorgon',                 model = 'imorgon',      background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 2, name = 'Entity XF',               model = 'entityxf',     background = 'images/card2back.png', rarity = 'ultraRare', value = 2000 },
            { number = 3, name = 'Entity XXR',              model = 'entity2',      background = 'images/card2back.png', rarity = 'ultraRare', value = 3000 },
            { number = 4, name = 'Entity MT',               model = 'entity3',      background = 'images/card2back.png', rarity = 'ultraRare', value = 4000 },
            { number = 5, name = 'Pipistrello',             model = 'pipistrello',  background = 'images/card2back.png', rarity = 'ultraRare', value = 5000 },
			{ number = 5, name = 'Autarch',                 model = 'autarch',      background = 'images/card2back.png', rarity = 'ultraRare', value = 10000 },
        },
    },
	
	['mfr_progen'] = {
        label  = 'Progen Collection',
        icon   = '⚡',
        cards  = {
            { number = 1, name = 'GP1',                     model = 'gp1',          background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 2, name = 'Itali GTB',               model = 'italigtb',     background = 'images/card2back.png', rarity = 'ultraRare', value = 2000 },
            { number = 3, name = 'Itali GTB',               model = 'italigtb2',    background = 'images/card2back.png', rarity = 'ultraRare', value = 3000 },
            { number = 4, name = 'T20',                     model = 't20',          background = 'images/card2back.png', rarity = 'ultraRare', value = 4000 },
            { number = 5, name = 'Emerus',                  model = 'emerus',       background = 'images/card2back.png', rarity = 'ultraRare', value = 5000 },
			{ number = 5, name = 'PR4',                     model = 'formula',      background = 'images/card2back.png', rarity = 'ultraRare', value = 10000 },
        },
    },

    ['fruit_collection'] = {
        label = 'Fruit Collection',
        icon  = '🌟',
        cards = {
            { number = 1, name = 'Blueberry',  image = 'images/blueberry.png',  background = 'images/card1back.png',   rarity = 'ultraRare', value = 100 },
            { number = 2, name = 'Mint',       image = 'images/mint.png',       background = 'images/card1back.png',   rarity = 'ultraRare', value = 200 },
            { number = 3, name = 'Banana',     image = 'images/bananna.png',    background = 'images/card1back.png',   rarity = 'ultraRare', value = 300 },
            { number = 4, name = 'Peach',      image = 'images/peach.png',      background = 'images/card1back.png',   rarity = 'ultraRare', value = 400 },
            { number = 5, name = 'Mango',      image = 'images/mango.png',      background = 'images/card1back.png',   rarity = 'ultraRare', value = 500 },
            { number = 6, name = 'Pineapple',  image = 'images/pineapple.png',  background = 'images/card1back.png',   rarity = 'ultraRare', value = 600 },
            { number = 7, name = 'Watermelon', image = 'images/watermelon.png', background = 'images/card1back.png',   rarity = 'ultraRare', value = 700 },
        },
    },

    ['boats'] = {
        label = 'Nautical Collection',
        icon  = '🚤',
        cards = {
            { number = 1, name = 'Dinghy',          model = 'dinghy2',     rarity = 'common'    },
            { number = 2, name = 'Jet Max',         model = 'jetmax',      rarity = 'common'    },
            { number = 3, name = 'Suntrap',         model = 'suntrap',     rarity = 'common'    },
            { number = 4, name = 'Marquis',         model = 'marquis',     rarity = 'uncommon'  },
            { number = 5, name = 'Toro',            model = 'toro',        rarity = 'uncommon'  },
            { number = 6, name = 'Squalo',          model = 'squalo',      rarity = 'uncommon'  },
            { number = 7, name = 'Speeder',         model = 'speeder',     rarity = 'rare'      },
            { number = 8, name = 'Longfin',         model = 'longfin',     rarity = 'rare'      },
            { number = 9, name = 'Tropic',          model = 'tropic2',     background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        },
    },

    ['offroad'] = {
        label = 'Off-Road Collection',
        icon  = '🏜️',
        cards = {
            { number = 1,  name = 'BF Injection',    model = 'bfinjection', rarity = 'common'   },
            { number = 2,  name = 'Bifta',           model = 'bifta',       rarity = 'common'   },
            { number = 3,  name = 'Blazer Aqua',     model = 'blazer5',     rarity = 'common'   },
            { number = 4,  name = 'Mesa',            model = 'mesa',        rarity = 'uncommon' },
            { number = 5,  name = 'Kalahari',        model = 'kalahari',    rarity = 'uncommon' },
            { number = 6,  name = 'Brawler',         model = 'brawler',     rarity = 'uncommon' },
            { number = 7,  name = 'Sandking XL',     model = 'sandking',    rarity = 'rare'     },
            { number = 8,  name = 'Bodhi',           model = 'bodhi2',      rarity = 'rare'     },
            { number = 9,  name = 'Trophy Truck',    model = 'trophytruck', background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 10, name = 'Draugur',         model = 'draugur',     background = 'images/card2back.png', rarity = 'ultraRare', value = 1500 },
        },
    },

    ['cycles'] = {
        label = 'Pedal Power Collection',
        icon  = '🚲',
        cards = {
            { number = 1, name = 'BMX',                    model = 'bmx',      rarity = 'common'   },
            { number = 2, name = 'Cruiser',                model = 'cruiser',  rarity = 'common'   },
            { number = 3, name = 'Scorcher',               model = 'scorcher', rarity = 'common'   },
            { number = 4, name = 'Fixter',                 model = 'fixter',   rarity = 'uncommon' },
            { number = 5, name = 'Whippet Race Bike',      model = 'whippet',  rarity = 'uncommon' },
            { number = 6, name = 'Tri-Cycles Race Bike',   model = 'tribike',  rarity = 'rare'     },
            { number = 7, name = 'Tri-Cycles Race Bike 2', model = 'tribike2', rarity = 'rare'     },
            { number = 8, name = 'Tri-Cycles Race Bike 3', model = 'tribike3', background = 'images/card2back.png', rarity = 'ultraRare', value = 800 },
        },
    },

    ['vans'] = {
        label = 'Vans & Utility Collection',
        icon  = '📦',
        cards = {
            { number = 1, name = 'Burrito',      model = 'burrito',   rarity = 'common'   },
            { number = 2, name = 'Journey',      model = 'journey',   rarity = 'common'   },
            { number = 3, name = 'Minivan',      model = 'minivan',   rarity = 'common'   },
            { number = 4, name = 'Rumpo',        model = 'rumpo',     rarity = 'uncommon' },
            { number = 5, name = 'Speedo',       model = 'speedo',    rarity = 'uncommon' },
            { number = 6, name = 'Bison',        model = 'bison2',    rarity = 'rare'     },
            { number = 7, name = 'Boxville',     model = 'boxville',  rarity = 'rare'     },
            { number = 8, name = 'Brickade',     model = 'brickade',  background = 'images/card2back.png', rarity = 'ultraRare', value = 1200 },
        },
    },

    ['emergency'] = {
        label = 'Emergency Response Collection',
        icon  = '🚑',
        cards = {
            { number = 1, name = 'Ambulance',       model = 'ambulance', rarity = 'common'   },
            { number = 2, name = 'Fire Truck',      model = 'firetruk',  rarity = 'common'   },
            { number = 3, name = 'Lifeguard',       model = 'lguard',    rarity = 'uncommon' },
            { number = 4, name = 'Prison Bus',      model = 'pbus2',     rarity = 'uncommon' },
            { number = 5, name = 'Police Bike',     model = 'policeb',   rarity = 'rare'     },
        },
    },

    ['bigrigs'] = {
        label = 'Big Rigs Collection',
        icon  = '🚚',
        cards = {
            { number = 1, name = 'Phantom',    model = 'phantom',  rarity = 'common'   },
            { number = 2, name = 'Hauler',     model = 'hauler',   rarity = 'common'   },
            { number = 3, name = 'Packer',     model = 'packer',   rarity = 'uncommon' },
            { number = 4, name = 'Mule',       model = 'mule',     rarity = 'uncommon' },
            { number = 5, name = 'Pounder',    model = 'pounder',  rarity = 'rare'     },
            { number = 6, name = 'Biff',       model = 'biff',     rarity = 'rare'     },
            { number = 7, name = 'Cerberus',   model = 'cerberus3', background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        },
    },

    ['compacts'] = {
        label = 'Compacts Collection',
        icon  = '🚙',
        cards = {
            { number = 1, name = 'Panto',       model = 'panto',      rarity = 'common'   },
            { number = 2, name = 'Brioso R/A',  model = 'brioso',     rarity = 'common'   },
            { number = 3, name = 'Issi',        model = 'issi2',      rarity = 'common'   },
            { number = 4, name = 'Weevil',      model = 'weevil',     rarity = 'uncommon' },
            { number = 5, name = 'Weevil Custom', model = 'weevil2',  rarity = 'uncommon' },
            { number = 6, name = 'Dilettante',  model = 'dilettante', rarity = 'rare'     },
            { number = 7, name = 'Rhapsody',    model = 'rhapsody',   rarity = 'rare'     },
            { number = 8, name = 'Prairie',     model = 'prairie',    background = 'images/card2back.png', rarity = 'ultraRare', value = 800 },
        },
    },

    ['sports_classics'] = {
        label = 'Sports Classics Collection',
        icon  = '🏁',
        cards = {
            { number = 1, name = 'Manana',           model = 'manana',   rarity = 'common'   },
            { number = 2, name = 'Peyote',           model = 'peyote2',  rarity = 'common'   },
            { number = 3, name = 'Tornado',          model = 'tornado',  rarity = 'common'   },
            { number = 4, name = 'Virgo',            model = 'virgo2',   rarity = 'uncommon' },
            { number = 5, name = 'Stromberg',        model = 'stromberg',rarity = 'uncommon' },
            { number = 6, name = 'Dynasty',          model = 'dynasty',  rarity = 'rare'     },
            { number = 7, name = 'Casco',            model = 'casco',    rarity = 'rare'     },
            { number = 8, name = 'Coquette Classic', model = 'coquette2',background = 'images/card2back.png', rarity = 'ultraRare', value = 1200 },
            { number = 9, name = 'GT500',            model = 'gt500',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1500 },
        },
    },

    ['industrial'] = {
        label = 'Industrial Collection',
        icon  = '🏗️',
        cards = {
            { number = 1, name = 'Tipper',    model = 'tiptruck',  rarity = 'common'   },
            { number = 2, name = 'Tipper 2',  model = 'tiptruck2', rarity = 'common'   },
            { number = 3, name = 'Mixer',     model = 'mixer',     rarity = 'uncommon' },
            { number = 4, name = 'Mixer 2',   model = 'mixer2',    rarity = 'uncommon' },
            { number = 5, name = 'Flatbed',   model = 'flatbed',   rarity = 'rare'     },
            { number = 6, name = 'Rubble',    model = 'rubble',    rarity = 'rare'     },
            { number = 7, name = 'Cutter',    model = 'cutter',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        },
    },

    ['weaponized'] = {
        label = 'Weaponized Collection',
        icon  = '🔫',
        cards = {
            { number = 1, name = 'Technical',              model = 'technical',  rarity = 'common'   },
            { number = 2, name = 'Technical Aqua',         model = 'technical3', rarity = 'common'   },
            { number = 3, name = 'Insurgent Pick-Up',      model = 'insurgent2', rarity = 'uncommon' },
            { number = 4, name = 'Insurgent Pick-Up Custom', model = 'insurgent3', rarity = 'uncommon' },
            { number = 5, name = 'Ratel',                  model = 'ratel',      rarity = 'rare'     },
            { number = 6, name = 'Scarab',                 model = 'scarab',     rarity = 'rare'     },
            { number = 7, name = 'Vigilante',               model = 'vigilante', background = 'images/card2back.png', rarity = 'ultraRare', value = 2000 },
        },
    },
}