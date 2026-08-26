-- config.lua
Config = {
    -- Vehicle Config
    Fuel = 'legacy',
    Keys = 'qb',
    Warp = true,
    Debug = false,
	
	-- Requirement = mnc-insurance
    GrantTemporaryInsurance = true,  -- Set to false to disable, mnc-insurance is needed if true
	
    -- Rental requirement
    RequireItem = true, -- Set to false to disable
    RequiredItem = 'driver_license', -- Item name needed to rent
	
    -- Blip settings
    Blip = {
        sprite = 811, -- Rental car icon
        color = 3, -- blue
        scale = 0.8,
        display = 4,
        name = 'Vehicle Rental'
    },
	
    -- UI Styles
    UIStyles = {
        style1 = { primaryBg = 'rgba(32, 33, 36, 0.8)', secondaryBg = 'rgba(48, 49, 52, 0.7)', accent = '#8ab4f8', textPrimary = '#e8eaed', textSecondary = '#9aa0a6', borderColor = 'rgba(95, 99, 104, 0.5)', blur = '10px' },
        style2 = { primaryBg = 'rgba(245, 245, 245, 0.8)', secondaryBg = 'rgba(255, 255, 255, 0.7)', accent = '#4caf50', textPrimary = '#212121', textSecondary = '#757575', borderColor = 'rgba(224, 224, 224, 0.5)', blur = '12px' },
        style3 = { primaryBg = 'rgba(26, 26, 46, 0.8)', secondaryBg = 'rgba(22, 36, 71, 0.7)', accent = '#ff2e63', textPrimary = '#ffffff', textSecondary = '#cccccc', borderColor = 'rgba(255, 46, 99, 0.5)', blur = '8px' },
        style4 = { primaryBg = 'rgba(46, 46, 46, 0.8)', secondaryBg = 'rgba(74, 74, 74, 0.7)', accent = '#ffca28', textPrimary = '#ffffff', textSecondary = '#bdbdbd', borderColor = 'rgba(117, 117, 117, 0.5)', blur = '10px' },
        style5 = { primaryBg = 'rgba(0, 48, 135, 0.8)', secondaryBg = 'rgba(0, 74, 173, 0.7)', accent = '#00e5ff', textPrimary = '#ffffff', textSecondary = '#b3e5fc', borderColor = 'rgba(2, 136, 209, 0.5)', blur = '10px' },
    },
	
    Zones = {
        [1] = {
            name = 'LS Airport Rentals',
            coords = vector3(-986.64, -2690.21, 13.02), -- Rental NPC location
            spawn = vector4(-989.63, -2706.8, 13.22, 333.45), -- Vehicle spawn
            vehicles = {
                {model = 'asbo', name = 'Asbo', rentalPrice = 200, brand = 'Maxwell', category = 'Compacts'},
                {model = 'asea', name = 'Asea', rentalPrice = 300, brand = 'Declasse', category = 'Sedans'},
                {model = 'glendale', name = 'Glendale', rentalPrice = 300, brand = 'Benefactor', category = 'Sedans'},
            },
            logo = 'nui://mnc-rentals/web/images/Trent.png',
            style = 'style2',
            ped = {
                model = 'a_m_y_business_01',
                coords = vector4(-986.64, -2690.21, 14.02, 160.0), -- Position + heading
                animationSet = {
                    dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
        },
		[2] = {
            name = 'Innocence Rentals',
            coords = vector3(-142.19, -1341.44, 29.09), -- Rental NPC location
            spawn = vector4(-141.89, -1346.96, 29.83, 182.18), -- Vehicle spawn
            vehicles = {
                {model = 'asbo', name = 'Asbo', rentalPrice = 200, brand = 'Maxwell', category = 'Compacts'},
                {model = 'asea', name = 'Asea', rentalPrice = 300, brand = 'Declasse', category = 'Sedans'},
                {model = 'glendale', name = 'Glendale', rentalPrice = 300, brand = 'Benefactor', category = 'Sedans'},
            },
            logo = 'nui://mnc-rentals/web/images/Trent.png',
            style = 'style2',
            ped = {
                model = 'a_m_y_business_01',
                coords = vector4(-142.19, -1341.44, 30.09, 186.39), -- Position + heading
                animationSet = {
                    dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
        },
		[3] = {
            name = 'Elgin Rentals',
            coords = vector3(55.42, -876.31, 29.66), -- Rental NPC location
            spawn = vector4(51.52, -872.34, 30.45, 167.06), -- Vehicle spawn
            vehicles = {
                {model = 'asbo', name = 'Asbo', rentalPrice = 200, brand = 'Maxwell', category = 'Compacts'},
                {model = 'asea', name = 'Asea', rentalPrice = 300, brand = 'Declasse', category = 'Sedans'},
                {model = 'glendale', name = 'Glendale', rentalPrice = 300, brand = 'Benefactor', category = 'Sedans'},
            },
            logo = 'nui://mnc-rentals/web/images/Trent.png',
            style = 'style2',
            ped = {
                model = 'a_m_y_business_01',
                coords = vector4(55.42, -876.31, 30.66, 249.94), -- Position + heading
                animationSet = {
                    dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
        },
		[4] = {
            name = 'Pillbox Rentals',
            coords = vector3(435.78, -648.71, 27.74), -- Rental NPC location
            spawn = vector4(416.05, -648.87, 28.5, 271.17), -- Vehicle spawn
            vehicles = {
                {model = 'asbo', name = 'Asbo', rentalPrice = 200, brand = 'Maxwell', category = 'Compacts'},
                {model = 'asea', name = 'Asea', rentalPrice = 300, brand = 'Declasse', category = 'Sedans'},
                {model = 'glendale', name = 'Glendale', rentalPrice = 300, brand = 'Benefactor', category = 'Sedans'},
            },
            logo = 'nui://mnc-rentals/web/images/Trent.png',
            style = 'style2',
            ped = {
                model = 'a_m_y_business_01',
                coords = vector4(435.78, -648.71, 28.74, 92.42), -- Position + heading
                animationSet = {
                    dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
        },
		[5] = {
            name = 'Eclipse Rentals',
            coords = vector3(-770.48, 301.66, 84.71), -- Rental NPC location
            spawn = vector4(-736.56, 308.33, 85.43, 174.04), -- Vehicle spawn
            vehicles = {
                {model = 'asbo', name = 'Asbo', rentalPrice = 200, brand = 'Maxwell', category = 'Compacts'},
                {model = 'asea', name = 'Asea', rentalPrice = 300, brand = 'Declasse', category = 'Sedans'},
                {model = 'glendale', name = 'Glendale', rentalPrice = 300, brand = 'Benefactor', category = 'Sedans'},
            },
            logo = 'nui://mnc-rentals/web/images/Trent.png',
            style = 'style2',
            ped = {
                model = 'a_m_y_business_01',
                coords = vector4(-770.48, 301.66, 85.71, 96.84), -- Position + heading
                animationSet = {
                    dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
        },
		[6] = {
            name = 'Wigwang Rentals',
            coords = vector3(-828.06, -695.2, 27.06), -- Rental NPC location
            spawn = vector4(-835.44, -704.81, 27.28, 87.31), -- Vehicle spawn
            vehicles = {
                {model = 'asbo', name = 'Asbo', rentalPrice = 200, brand = 'Maxwell', category = 'Compacts'},
                {model = 'asea', name = 'Asea', rentalPrice = 300, brand = 'Declasse', category = 'Sedans'},
                {model = 'glendale', name = 'Glendale', rentalPrice = 300, brand = 'Benefactor', category = 'Sedans'},
            },
            logo = 'nui://mnc-rentals/web/images/Trent.png',
            style = 'style2',
            ped = {
                model = 'a_m_y_business_01',
                coords = vector4(-828.06, -695.2, 28.06, 178.14), -- Position + heading
                animationSet = {
                    dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
        },
		[7] = {
            name = 'Route 1 Rentals',
            coords = vector3(-3146.95, 1122.73, 19.87), -- Rental NPC location
            spawn = vector4(-3142.55, 1117.39, 20.71, 281.79), -- Vehicle spawn
            vehicles = {
                {model = 'asbo', name = 'Asbo', rentalPrice = 200, brand = 'Maxwell', category = 'Compacts'},
                {model = 'asea', name = 'Asea', rentalPrice = 300, brand = 'Declasse', category = 'Sedans'},
                {model = 'glendale', name = 'Glendale', rentalPrice = 300, brand = 'Benefactor', category = 'Sedans'},
            },
            logo = 'nui://mnc-rentals/web/images/Trent.png',
            style = 'style2',
            ped = {
                model = 'a_m_y_business_01',
                coords = vector4(-3146.95, 1122.73, 20.87, 247.24), -- Position + heading
                animationSet = {
                    dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
        },
		[8] = {
            name = 'Paleto Rentals',
            coords = vector3(146.49, 6563.0, 30.98), -- Rental NPC location
            spawn = vector4(147.17, 6569.2, 31.88, 351.9), -- Vehicle spawn
            vehicles = {
                {model = 'asbo', name = 'Asbo', rentalPrice = 200, brand = 'Maxwell', category = 'Compacts'},
                {model = 'asea', name = 'Asea', rentalPrice = 300, brand = 'Declasse', category = 'Sedans'},
                {model = 'glendale', name = 'Glendale', rentalPrice = 300, brand = 'Benefactor', category = 'Sedans'},
            },
            logo = 'nui://mnc-rentals/web/images/Trent.png',
            style = 'style2',
            ped = {
                model = 'a_m_y_business_01',
                coords = vector4(146.49, 6563.0, 31.98, 313.1), -- Position + heading
                animationSet = {
                    dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
        },
		[9] = {
            name = 'Sandy Shores Rentals',
            coords = vector3(1989.33, 3780.87, 31.18), -- Rental NPC location
            spawn = vector4(1983.75, 3779.1, 32.18, 204.58), -- Vehicle spawn
            vehicles = {
                {model = 'asbo', name = 'Asbo', rentalPrice = 200, brand = 'Maxwell', category = 'Compacts'},
                {model = 'asea', name = 'Asea', rentalPrice = 300, brand = 'Declasse', category = 'Sedans'},
                {model = 'glendale', name = 'Glendale', rentalPrice = 300, brand = 'Benefactor', category = 'Sedans'},
            },
            logo = 'nui://mnc-rentals/web/images/Trent.png',
            style = 'style2',
            ped = {
                model = 'a_m_y_business_01',
                coords = vector4(1989.33, 3780.87, 32.18, 114.74), -- Position + heading
                animationSet = {
                    dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
        },
		[10] = {
            name = 'Leigon Rentals',
            coords = vector3(214.11, -808.49, 31.01), -- Rental NPC location
            spawn = vector4(219.44, -808.93, 30.08, 247.17), -- Vehicle spawn
            vehicles = {
                {model = 'asbo', name = 'Asbo', rentalPrice = 200, brand = 'Maxwell', category = 'Compacts'},
                {model = 'asea', name = 'Asea', rentalPrice = 300, brand = 'Declasse', category = 'Sedans'},
                {model = 'glendale', name = 'Glendale', rentalPrice = 300, brand = 'Benefactor', category = 'Sedans'},
            },
            logo = 'nui://mnc-rentals/web/images/Trent.png',
            style = 'style2',
            ped = {
                model = 'a_m_y_business_01',
                coords = vector4(214.06, -808.46, 31.01, 157.15), -- Position + heading
                animationSet = {
                    dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
        },
		[11] = {
            name = 'Arena GoKarting',
            coords = vector3(-152.82, -2151.65, 15.71), -- Rental NPC location
            spawn = vector4(-160.78, -2144.11, 16.71, 291.36), -- Vehicle spawn
            vehicles = {
                {model = 'veto', name = 'Veto Classic', rentalPrice = 100, brand = 'Unknown', category = 'Compacts'},
                {model = 'veto2', name = 'Veto Modern', rentalPrice = 300, brand = 'Unknown', category = 'Sedans'},
                },
            logo = 'nui://mnc-rentals/web/images/Orent.png',
            style = 'style2',
            ped = {
                model = 's_m_y_xmech_02',
                coords = vector4(-152.82, -2151.65, 16.71, 0.0), -- Position + heading
                animationSet = {
                    dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
        },
        [12] = {
            name = 'Vespucci Beach Rentals',
            coords = vector3(-1612.77, -1125.94, 1.35),
            spawn = vector4(-1640.83, -1155.78, 0.01, 136.02),
            vehicles = {
                {model = 'tropic', name = 'Tropic', rentalPrice = 100, brand = 'Dinka', category = 'Boats'},
                {model = 'marquis', name = 'Marquis', rentalPrice = 2000, brand = 'Dinka', category = 'Boats'},
                {model = 'seashark', name = 'Seashark', rentalPrice = 500, brand = 'Speedophile', category = 'JetSki'},
            },
            logo = 'nui://mnc-rentals/web/images/Erent.png',
            style = 'style4',
            ped = {
                model = 's_m_y_xmech_02',
                coords = vector4(-1612.77, -1125.94, 2.35, 146.59),
                animationSet = {
                    dict = 'amb@world_human_leaning@male@wall@back@legs_crossed@base',
                    anims = {'idle_a', 'idle_b', 'idle_c'}
                }
            },
        },
    },
}