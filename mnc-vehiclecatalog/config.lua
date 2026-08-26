Config = {
    -- Admin Command Config
    Command = 'vehiclecatalog', -- Command to open UI with all vehicles
    AdminGroups = {'group.admin'}, -- Admin groups for command access group.admin is old version

    -- Interaction Config
    UseTarget = false, -- Use qb-target (true) or keypress E (false)

    -- Zone Config
    Zones = {
        {
            name = 'pdm', -- Dealership name from qb-vehicleshop
            coords = vector3(-55.17, -1089.85, 26.92), -- Example coords
            radius = 2.0, -- Interaction radius
            uiStyle = 'style1', -- Options: style1, style2, style3, style4, style5
            title = 'Adams Apple PDM Catalogue', -- Custom title for UI
            useAnywhere = false, -- leave false
        },
        -- Add more zones as needed
        {
            name = 'luxury', -- Another dealership
            coords = vector3(-1146.43, -1733.85, 4.67),
            radius = 1.5,
            uiStyle = 'style2',
            title = 'PDM Deluxe Catalogue',
            useAnywhere = false, -- leave false
        },
		
		{
            name = 'mncmotors', -- Another dealership
            coords = vector3(98.71, 6539.26, 31.67),
            radius = 1.5,
            uiStyle = 'style3',
            title = 'MnC Motors Catalogue',
            useAnywhere = false, -- leave false
        },
		
		{
            name = 'truckntrailer', -- Another dealership
            coords = vector3(-1583.86, -843.2, 10.06),
            radius = 1.5,
            uiStyle = 'style4',
            title = 'Trucks and Trailers Catalogue',
            useAnywhere = false, -- leave false
        },
		
		{
            name = 'racenrally', -- Another dealership
            coords = vector3(-923.53, -2044.35, 9.5),
            radius = 1.5,
            uiStyle = 'style5',
            title = 'Race and Rally Catalogue',
            useAnywhere = false, -- leave false
        },
		
		{
            name = 'driftndrag', -- Another dealership
            coords = vector3(4450.28, -4456.61, 7.24),
            radius = 1.5,
            uiStyle = 'style1',
            title = 'Drift and Drag Catalogue',
            useAnywhere = false, -- leave false
        },
		
		{
            name = 'truck', -- Another dealership
            coords = vector3(-1151.66, -2096.91, 13.37),
            radius = 1.5,
            uiStyle = 'style2',
            title = 'Semi Catalogue',
            useAnywhere = false, -- leave false
        },
		
		-- {
            -- name = 'air', -- Another dealership
            -- coords = vector3(-1146.43, -1733.85, 4.67),
            -- radius = 1.5,
            -- uiStyle = 'style3',
            -- title = 'Plane and Heli Catalogue',
            -- useAnywhere = false,
        -- },
		
    },

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
}
