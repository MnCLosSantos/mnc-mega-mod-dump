Config = {

    UseTarget = false, -- Set to false to use only keypress E (disable qb-target)
	
	Debug = false, -- Set to true to enable debug prints, false to disable

	    -- UI Styles
    UIStyles = {
        style1 = { -- Dark Modern Glass
            primaryBg = 'rgba(32, 33, 36, 0.8)',
            secondaryBg = 'rgba(48, 49, 52, 0.7)',
            accent = '#8ab4f8',
            textPrimary = '#e8eaed',
            textSecondary = '#9aa0a6',
            borderColor = 'rgba(95, 99, 104, 0.5)',
            blur = '10px',
        },
        style2 = { -- Light Clean Glass
            primaryBg = 'rgba(245, 245, 245, 0.8)',
            secondaryBg = 'rgba(255, 255, 255, 0.7)',
            accent = '#4caf50',
            textPrimary = '#212121',
            textSecondary = '#757575',
            borderColor = 'rgba(224, 224, 224, 0.5)',
            blur = '12px',
        },
        style3 = { -- Neon Night Glass
            primaryBg = 'rgba(26, 26, 46, 0.8)',
            secondaryBg = 'rgba(22, 36, 71, 0.7)',
            accent = '#ff2e63',
            textPrimary = '#ffffff',
            textSecondary = '#cccccc',
            borderColor = 'rgba(255, 46, 99, 0.5)',
            blur = '8px',
        },
        style4 = { -- Retro Glass
            primaryBg = 'rgba(46, 46, 46, 0.8)',
            secondaryBg = 'rgba(74, 74, 74, 0.7)',
            accent = '#ffca28',
            textPrimary = '#ffffff',
            textSecondary = '#bdbdbd',
            borderColor = 'rgba(117, 117, 117, 0.5)',
            blur = '10px',
        },
        style5 = { -- Oceanic Glass
            primaryBg = 'rgba(0, 48, 135, 0.8)',
            secondaryBg = 'rgba(0, 74, 173, 0.7)',
            accent = '#00e5ff',
            textPrimary = '#ffffff',
            textSecondary = '#b3e5fc',
            borderColor = 'rgba(2, 136, 209, 0.5)',
            blur = '10px',
        },
    },

    -- Zone Config
    Zones = {
        {
            name = 'food', -- item type name
            coords = vector3(24.47, -1346.62, 29.5), -- Interaction point (unchanged)
            radius = 1.5, -- Interaction radius
            uiStyle = 'style1', -- Options: style1, style2, style3, style4, style5
            title = '24/7 Supermarket', -- Custom title for UI
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'}, -- Multiple item types
            useAnywhere = false, -- leave false
            ped = {
                model = 's_m_m_cntrybar_01', -- Example ped model
                coords = vector4(24.2, -1345.8, 29.49, 270.0), -- Moved 1.5m left (previous: 25.7, -1345.8, 29.49, 270.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true, -- Enable or disable blip
                sprite = 52, -- Blip sprite (52 = Store)
                color = 2, -- Blip color (0 = White)
                scale = 0.6, -- Blip scale
                name = '24/7 Supermarket' -- Blip name
            }
        },
        {
            name = 'food',
            coords = vector3(-3039.54, 584.38, 7.91),
            radius = 1.5,
            uiStyle = 'style1',
            title = '24/7 Supermarket',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(-3039.28, 584.29, 7.91, 14.38), -- Moved 1.5m left (previous: -3039.96, 587.0, 7.9, 355.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 2,
                scale = 0.6,
                name = '24/7 Supermarket'
            }
        },
        {
            name = 'food',
            coords = vector3(-3242.97, 1000.01, 12.83),
            radius = 1.5,
            uiStyle = 'style1',
            title = '24/7 Supermarket',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(-3243.16, 1000.08, 12.83, 356.4), -- Moved 1.5m left (previous: -3240.4, 1001.4, 12.83, 0.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 2,
                scale = 0.6,
                name = '24/7 Supermarket'
            }
        },
        {
            name = 'food',
            coords = vector3(1728.07, 6415.63, 35.04),
            radius = 1.5,
            uiStyle = 'style1',
            title = '24/7 Supermarket',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(1727.89, 6415.55, 35.04, 231.35), -- Moved 1.5m left (previous: 1730.43, 6415.05, 35.03, 245.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 2,
                scale = 0.6,
                name = '24/7 Supermarket'
            }
        },
        {
            name = 'food',
            coords = vector3(1959.82, 3740.48, 32.34),
            radius = 1.5,
            uiStyle = 'style1',
            title = '24/7 Supermarket',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(1959.57, 3740.28, 32.34, 300.82), -- Moved 1.5m left (previous: 1961.3, 3741.75, 32.34, 300.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 2,
                scale = 0.6,
                name = '24/7 Supermarket'
            }
        },
        {
            name = 'food',
            coords = vector3(549.13, 2670.85, 42.16),
            radius = 1.5,
            uiStyle = 'style1',
            title = '24/7 Supermarket',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(549.28, 2670.98, 42.16, 95.42), -- Moved 1.5m left (previous: 547.3, 2670.83, 42.15, 100.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 2,
                scale = 0.6,
                name = '24/7 Supermarket'
            }
        },
        {
            name = 'food',
            coords = vector3(2677.47, 3279.76, 55.24),
            radius = 1.5,
            uiStyle = 'style1',
            title = '24/7 Supermarket',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(2677.91, 3279.42, 55.24, 329.25), -- Moved 1.5m left (previous: 2679.25, 3280.3, 55.24, 330.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 2,
                scale = 0.6,
                name = '24/7 Supermarket'
            }
        },
        {
            name = 'food',
            coords = vector3(2556.66, 380.84, 108.62),
            radius = 1.5,
            uiStyle = 'style1',
            title = '24/7 Supermarket',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(2556.77, 380.7, 108.62, 343.11), -- Moved 1.5m left (previous: 2555.5, 382.0, 108.62, 0.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 2,
                scale = 0.6,
                name = '24/7 Supermarket'
            }
        },
        {
            name = 'food',
            coords = vector3(372.66, 326.98, 103.57),
            radius = 1.5,
            uiStyle = 'style1',
            title = '24/7 Supermarket',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(372.54, 326.63, 103.57, 244.77), -- Moved 1.5m left (previous: 374.85, 326.98, 103.56, 255.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 2,
                scale = 0.6,
                name = '24/7 Supermarket'
            }
        },
        {
            name = 'food',
            coords = vector3(-47.02, -1758.23, 29.42),
            radius = 1.5,
            uiStyle = 'style1',
            title = 'LTD Gasoline',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(-47.22, -1758.8, 29.42, 50.18), -- Moved 1.5m left (previous: -47.45, -1756.85, 29.42, 45.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 47,
                scale = 0.6,
                name = 'LTD Gasoline'
            }
        },
        {
            name = 'food',
            coords = vector3(-706.06, -913.97, 19.22),
            radius = 1.5,
            uiStyle = 'style1',
            title = 'LTD Gasoline',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(-706.15, -914.55, 19.22, 90.47), -- Moved 1.5m left (previous: -706.0, -912.5, 19.21, 90.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 47,
                scale = 0.6,
                name = 'LTD Gasoline'
            }
        },
        {
            name = 'food',
            coords = vector3(-1820.02, 794.03, 138.09),
            radius = 1.5,
            uiStyle = 'style1',
            title = 'LTD Gasoline',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(-1819.6, 793.61, 138.09, 143.17), -- Moved 1.5m left (previous: -1819.55, 793.55, 138.11, 135.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 47,
                scale = 0.6,
                name = 'LTD Gasoline'
            }
        },
        {
            name = 'food',
            coords = vector3(1164.71, -322.94, 69.21),
            radius = 1.5,
            uiStyle = 'style1',
            title = 'LTD Gasoline',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(1164.86, -323.6, 69.21, 105.59), -- Moved 1.5m left (previous: 1164.5, -323.0, 69.20, 90.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 47,
                scale = 0.6,
                name = 'LTD Gasoline'
            }
        },
        {
            name = 'food',
            coords = vector3(1697.87, 4922.96, 42.06),
            radius = 1.5,
            uiStyle = 'style1',
            title = 'LTD Gasoline',
            categories = {'food', 'drinks', 'beer', 'snacks', 'misc'},
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(1697.34, 4923.36, 42.06, 322.53), -- Moved 1.5m left (previous: 1699.35, 4923.65, 42.06, 325.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 47,
                scale = 0.6,
                name = 'LTD Gasoline'
            }
        },
        {
            name = 'liquor',
            coords = vector3(-1221.58, -908.15, 12.33),
            radius = 1.5,
            uiStyle = 'style1',
            title = 'Robs Liquor',
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(-1221.42, -908.13, 12.33, 31.41), -- Moved 1.5m left (previous: -1221.3, -905.25, 12.32, 30.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 34,
                scale = 0.6,
                name = 'Robs Liquor'
            }
        },
        {
            name = 'liquor',
            coords = vector3(-1486.59, -377.68, 40.16),
            radius = 1.5,
            uiStyle = 'style1',
            title = 'Robs Liquor',
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(-1487.11, -376.17, 40.16, 135.0), -- Moved 1.5m left (previous: -1486.05, -375.6, 40.16, 135.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 34,
                scale = 0.6,
                name = 'Robs Liquor'
            }
        },
        {
            name = 'liquor',
            coords = vector3(-2966.39, 391.42, 15.04),
            radius = 1.5,
            uiStyle = 'style1',
            title = 'Robs Liquor',
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(-2967.0, 390.0, 15.04, 90.0), -- Moved 1.5m left (previous: -2965.5, 388.5, 15.04, 90.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 34,
                scale = 0.6,
                name = 'Robs Liquor'
            }
        },
        {
            name = 'liquor',
            coords = vector3(1165.17, 2710.88, 38.16),
            radius = 1.5,
            uiStyle = 'style1',
            title = 'Robs Liquor',
            useAnywhere = false,
            ped = {
                model = 's_m_m_cntrybar_01',
                coords = vector4(1165.62, 2710.81, 38.16, 188.11), -- Moved 1.5m left (previous: 1166.0, 2709.5, 38.15, 180.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 34,
                scale = 0.6,
                name = 'Robs Liquor'
            }
        },
        {
            name = 'hardware local',
            coords = vector3(45.68, -1749.04, 29.61),
            radius = 1.5,
            uiStyle = 'style4',
            title = 'YouTool Local',
            useAnywhere = false,
            ped = {
                model = 's_m_m_autoshop_02',
                coords = vector4(46.7, -1749.67, 29.63, 46.83), -- Moved 1.5m left (previous: 44.95, -1746.95, 29.5, 45.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 402,
                color = 69,
                scale = 0.8,
                name = 'YouTool Local'
            }
        },
		{
            name = 'hardware',
            coords = vector3(2747.84, 3472.72, 55.67),
            radius = 1.5,
            uiStyle = 'style4',
            title = 'YouTool Mega',
            useAnywhere = false,
            ped = {
                model = 's_m_m_autoshop_02',
                coords = vector4(2747.84, 3472.72, 55.67, 245.86), -- Moved 1.5m left (previous: 44.95, -1746.95, 29.5, 45.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 402,
                color = 69,
                scale = 0.8,
                name = 'YouTool Mega'
            }
        },
        {
            name = 'weapons',
            coords = vector3(22.09, -1105.49, 29.8),
            radius = 1.5,
            uiStyle = 'style2',
            title = 'Ammunation',
			categories = {'weapons', 'ammo'}, -- Multiple item types
            useAnywhere = false,
            requiredItem = 'weaponlicense',
            ped = {
                model = 's_m_m_ammucountry',
                coords = vector4(24.18, -1105.67, 29.8, 152.85), -- Moved 1.5m left (previous: 22.4, -1104.2, 29.79, 160.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 110,
                color = 49,
                scale = 0.6,
                name = 'Ammunation'
            }
        },
        {
            name = 'weapons',
            coords = vector3(2567.48, 292.59, 108.73),
            radius = 1.5,
            uiStyle = 'style2',
            title = 'Ammunation',
			categories = {'weapons', 'ammo'},
            useAnywhere = false,
            requiredItem = 'weaponlicense',
            ped = {
                model = 's_m_m_ammucountry',
                coords = vector4(2566.53, 292.33, 108.73, 357.55), -- Moved 1.5m left (previous: 2565.5, 294.0, 108.73, 0.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 110,
                color = 49,
                scale = 0.6,
                name = 'Ammunation'
            }
        },
        {
            name = 'weapons',
            coords = vector3(-1118.59, 2700.05, 18.55),
            radius = 1.5,
            uiStyle = 'style2',
            title = 'Ammunation',
			categories = {'weapons', 'ammo'},
            useAnywhere = false,
            requiredItem = 'weaponlicense',
            ped = {
                model = 's_m_m_ammucountry',
                coords = vector4(-1118.1, 2700.91, 18.55, 218.33), -- Moved 1.5m left (previous: -1118.95, 2696.05, 18.55, 315.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 110,
                color = 49,
                scale = 0.6,
                name = 'Ammunation'
            }
        },
        {
            name = 'weapons',
            coords = vector3(841.92, -1035.32, 28.19),
            radius = 1.5,
            uiStyle = 'style2',
            title = 'Ammunation',
			categories = {'weapons', 'ammo'},
            useAnywhere = false,
            requiredItem = 'weaponlicense',
            ped = {
                model = 's_m_m_ammucountry',
                coords = vector4(841.12, -1035.31, 28.19, 0.58), -- Moved 1.5m left (previous: 840.5, -1033.0, 28.19, 0.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 110,
                color = 49,
                scale = 0.6,
                name = 'Ammunation'
            }
        },
        {
            name = 'weapons',
            coords = vector3(-1304.19, -395.12, 36.7),
            radius = 1.5,
            uiStyle = 'style2',
            title = 'Ammunation',
			categories = {'weapons', 'ammo'},
            useAnywhere = false,
            requiredItem = 'weaponlicense',
            ped = {
                model = 's_m_m_ammucountry',
                coords = vector4(-1304.35, -395.75, 36.7, 81.09), -- Moved 1.5m left (previous: -1303.5, -393.95, 36.69, 75.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 110,
                color = 49,
                scale = 0.6,
                name = 'Ammunation'
            }
        },
        {
            name = 'weapons',
            coords = vector3(-3173.31, 1088.85, 20.84),
            radius = 1.5,
            uiStyle = 'style2',
            title = 'Ammunation',
			categories = {'weapons', 'ammo'},
            useAnywhere = false,
            requiredItem = 'weaponlicense',
            ped = {
                model = 's_m_m_ammucountry',
                coords = vector4(-3173.24, 1089.59, 20.84, 244.34), -- Moved 1.5m left (previous: -3171.45, 1085.85, 20.83, 245.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 110,
                color = 49,
                scale = 0.6,
                name = 'Ammunation'
            }
        },
		{
            name = 'weapons',
            coords = vector3(253.89, -50.59, 69.94),
            radius = 1.5,
            uiStyle = 'style2',
            title = 'Ammunation',
			categories = {'weapons', 'ammo'},
            useAnywhere = false,
            requiredItem = 'weaponlicense',
            ped = {
                model = 's_m_m_ammucountry',
                coords = vector4(253.89, -50.59, 69.94, 70.59), -- Moved 1.5m left (previous: -3171.45, 1085.85, 20.83, 245.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 110,
                color = 49,
                scale = 0.6,
                name = 'Ammunation'
            }
        },
		{
            name = 'weapons',
            coords = vector3(-331.52, 6085.14, 31.45),
            radius = 1.5,
            uiStyle = 'style2',
            title = 'Ammunation',
			categories = {'weapons', 'ammo'},
            useAnywhere = false,
            requiredItem = 'weaponlicense',
            ped = {
                model = 's_m_m_ammucountry',
                coords = vector4(-331.52, 6085.14, 31.45, 224.87), -- Moved 1.5m left (previous: -3171.45, 1085.85, 20.83, 245.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 110,
                color = 49,
                scale = 0.6,
                name = 'Ammunation'
            }
        },
		{
            name = 'weapons',
            coords = vector3(1692.54, 3761.66, 34.71),
            radius = 1.5,
            uiStyle = 'style2',
            title = 'Ammunation',
			categories = {'weapons', 'ammo'},
            useAnywhere = false,
            requiredItem = 'weaponlicense',
            ped = {
                model = 's_m_m_ammucountry',
                coords = vector4(1692.54, 3761.66, 34.71, 221.8), -- Moved 1.5m left (previous: -3171.45, 1085.85, 20.83, 245.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 110,
                color = 49,
                scale = 0.6,
                name = 'Ammunation'
            }
        },
        {
            name = 'weedshop',
            coords = vector3(-1168.26, -1573.2, 4.66),
            radius = 1.5,
            uiStyle = 'style3',
            title = 'Smoke On The Water',
			categories = {'smoking'},
            useAnywhere = false,
            ped = {
                model = 'a_m_y_runner_01',
                coords = vector4(-1169.95, -1571.38, 4.66, 175.48), -- Moved 1.5m left (previous: -1168.05, -1570.95, 4.66, 135.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 140,
                color = 43,
                scale = 0.8,
                name = 'Smoke On The Water'
            }
        },
        {
            name = 'gearshop',
            coords = vector3(-1687.03, -1072.18, 13.15),
            radius = 1.5,
            uiStyle = 'style5',
            title = 'Sea Word',
            useAnywhere = false,
            ped = {
                model = 's_m_y_dockwork_01',
                coords = vector4(-1685.75, -1070.05, 13.15, 32.46), -- Moved 1.5m left (previous: -1688.0, -1071.5, 13.15, 180.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 53,
                scale = 0.8,
                name = 'Sea Word'
            }
        },
        {
            name = 'leisure',
            coords = vector3(-1505.91, 1511.95, 115.29),
            radius = 1.5,
            uiStyle = 'style5',
            title = 'Leisure Shop',
			categories = {'leisure misc'},
            useAnywhere = false,
            ped = {
                model = 'a_m_y_surfer_01',
                coords = vector4(-1505.63, 1511.54, 115.29, 258.62), -- Moved 1.5m left (previous: -1504.5, 1512.0, 115.28, 0.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 53,
                scale = 0.8,
                name = 'Leisure Shop'
            }
        },
        {
            name = 'prison',
            coords = vector3(1777.59, 2560.52, 44.62),
            radius = 1.5,
            uiStyle = 'style1',
            title = 'Prison Canteen Shop',
            useAnywhere = false,
            ped = {
                model = 's_m_m_prisguard_01',
                coords = vector4(1777.53, 2560.46, 45.62, 194.18), -- Moved 1.5m left (previous: 1776.5, 2558.5, 44.62, 90.0)
                animationSet = {
                    dict = 'amb@world_human_stand_impatient@male@idle_a', -- Standing idle animation
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
            blip = {
                enabled = true,
                sprite = 52,
                color = 54,
                scale = 0.8,
                name = 'Canteen Shop'
            }
        },
    },

    -- Item Mapping
    Products = {
	    
		-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	    -- -- -- -- -- -- -- -- -- -- -- NORMAL SHOP ITEMS -- -- -- -- -- -- -- -- -- -- --
		-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
        ['food'] = {
            { name = 'tosti',             price = 2,   amount = 50 },
            { name = 'sandwich',          price = 2,   amount = 50 },
        },
		['drinks'] = {
            { name = 'water_bottle',      price = 2,   amount = 50 },
        },
		['snacks'] = {
            { name = 'twerks_candy',  price = 2,   amount = 50 },
            { name = 'snikkel_candy', price = 2,   amount = 50 },
        },
		['beer'] = {
            { name = 'beer',    price = 7,  amount = 50 },
        },
        ['misc'] = {
            { name = 'bandage',                  price = 5, amount = 50 },
            { name = 'lighter',                  price = 2,   amount = 50 },
        },

		-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
		-- -- -- -- -- -- -- -- -- -- -- LIQUOR SHOP ITEMS -- -- -- -- -- -- -- -- -- -- --
		-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
		['liquor'] = {
            { name = 'beer',                     price = 4,    amount = 50 },
            { name = 'whiskey',                  price = 25,   amount = 50 },
            { name = 'vodka',                    price = 32,   amount = 50 },
		    { name = 'lighter',                  price = 2,   amount = 50 },
        },
		
		-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
		-- -- -- -- -- -- -- -- -- -- -- HARDWARE MEGA  -- -- -- -- -- -- -- -- -- -- --		
		-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
        ['hardware'] = {
            { name = 'lockpick',              price = 75,    amount = 50 },
            { name = 'weapon_wrench',         price = 125,   amount = 50 },
            { name = 'weapon_hammer',         price = 125,   amount = 50 },
            { name = 'screwdriverset',        price = 135,   amount = 50 },
            { name = 'cleaningkit',           price = 105,   amount = 50 },
            { name = 'advancedrepairkit',     price = 1750,  amount = 50 },
        },
		
		-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
		-- -- -- -- -- -- -- -- -- -- -- HARDWARE LOCAL -- -- -- -- -- -- -- -- -- -- -- 
		-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
		['hardware local'] = {
        },
		
		-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
		-- -- -- -- -- -- -- -- -- -- -- AMMUNATION SHOP ITEMS (REQUIRES WEAPON LICENSE) -- -- -- -- -- -- -- -- -- -- --
		-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
		['weapons'] = {
            { name = 'weapon_knife',         price = 50,  amount = 250 },
            { name = 'weapon_bat',           price = 50,  amount = 250 },
            { name = 'weapon_hatchet',       price = 50,  amount = 250 },
            { name = 'weapon_vintagepistol', price = 4000, amount = 5, },
        },
		['ammo'] = {
            { name = 'pistol_ammo',          price = 50,  amount = 250, },
        },
		
		-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
		-- -- -- -- -- -- -- -- -- -- -- OTHER SHOP ITEMS  -- -- -- -- -- -- -- -- -- -- --
		-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
        ['weedshop'] = {
            { name = 'joint',                    price = 20,  amount = 50 },
            { name = 'lighter',                  price = 5, amount = 50 },
		    { name = 'water_bottle',             price = 5,   amount = 50 },
        },
        ['gearshop'] = {
            { name = 'diving_gear',       price = 500, amount = 10 },
            { name = 'parachute',         price = 500, amount = 50 },
            { name = 'binoculars',        price = 500,   amount = 50 },
            { name = 'diving_gear',       price = 500, amount = 50 },
            { name = 'diving_fill',       price = 500,  amount = 50 },
        },
		['leisure misc'] = {
            { name = 'parachute',         price = 500, amount = 50 },
            { name = 'binoculars',        price = 500,   amount = 50 },
            { name = 'diving_gear',       price = 500, amount = 50 },
            { name = 'diving_fill',       price = 500,  amount = 50 },
        },
        ['prison'] = {
            { name = 'sandwich',       price = 15,  amount = 50 },
            { name = 'water_bottle',   price = 15,  amount = 50 },
		    { name = 'bandage',        price = 15, amount = 50 },
        }
    },
}
