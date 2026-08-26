Config = {}

Config.Debug = false

-- ox_lib progress settings
Config.Progress = 'bar'         -- 'bar' or 'circle'

-- Notification time
Config.DefaultNotifyTime = 5000

-- Zone size for qb-target
Config.ZoneSize = { x = 2.0, y = 2.0 }

-- Changing room locations
Config.Locations = {
    {
        name = "autoexotics_clothing",
        label = "Auto Exotics Locker Room",
        coords = vector4(538.86, -166.17, 54.66, 185.45),
        job = "autoexotics",                 -- restrict to this job (set to nil for public)
        require_onduty = false,         -- must be on duty
        min_grade_to_use = 0,           -- minimum grade to open menu
        min_grade_to_add = 4,           -- minimum grade to save new outfits
    },
    {
        name = "police_locker",
        label = "Police Locker Room",
        coords = vector4(461.74, -995.94, 30.69, 359.05),
        job = "police",
        require_onduty = true,
        min_grade_to_use = 0,
        min_grade_to_add = 4,
    },
	{
        name = "gokart_locker",
        label = "Gokarting Locker Room",
        coords = vector4(-153.74, -2151.87, 16.71, 197.81),
        job = "mncracing",
        require_onduty = true,
        min_grade_to_use = 0,
        min_grade_to_add = 4,
    },
}