Config = {

    EnableJobLock = false, -- Set to false to disable job/grade restrictions

    AllowedJobs = { -- Job name as key, minimum grade as value
        ['admin'] = 4,
        ['staff'] = 4,
		['police'] = 4,
        -- Add more jobs as needed, e.g., ['doj'] = 4,
    },

    -- Interaction Config
    Command = 'itemspawner', -- Command to open the item spawner
    UIStyle = 'style1', -- Default UI style: style1, style2, style3, style4, style5

    -- Items are loaded automatically from QBCore.Shared.Items and grouped by their 'type' field.
    -- Use the lists below to control what appears in the spawner.

    -- Item types to exclude from the spawner (matches the 'type' field in items.lua)
    ExcludeTypes = {
        -- 'weapon',   -- uncomment to hide weapon items
    },

    -- Specific item names to exclude regardless of type
    ExcludeItems = {
        -- 'money',
        -- 'black_money',
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