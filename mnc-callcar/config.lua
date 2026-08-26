Config = {}

-- Cost per call (can be 0 for free)
Config.BaseCost = 100        -- Base fee to call any vehicle
Config.CostPerMeter = 0.25  -- Additional cost per meter vehicle travels

-- How far away the ped spawns the vehicle from (meters)
Config.SpawnDistance = 800

-- How fast the ped drives (1-3 scale: 1=normal, 2=fast, 3=very fast)
Config.DrivingSpeed = 1

-- Driving style flag (786603 = normal)
Config.DrivingStyle = 786603

-- Commands that all open the same menu
Config.Commands = {
    'callcar',
    'bringcar',
    'valet',
    'mycar',
    'getcar',
    'fetchcar',
}
