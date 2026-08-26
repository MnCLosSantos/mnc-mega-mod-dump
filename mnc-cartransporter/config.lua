Config = {}

Config.Debug = false

Config.ShowHelperUI = true

Config.TrailerModel = `tr2`
Config.LoadDistance = 10.0
Config.MaxVehiclesPerLevel = 3
Config.NumLevels = 2
Config.LiftSpeed = 0.5
Config.MinLiftOffset = -1.0
Config.MaxLiftOffset = 3.0

-- Vehicle models that hide helper ui when in radius
Config.ForkliftModels = {
    `forklift`,
	`vstruck`,
}


-- Controls
Config.LiftUpControl        = 172     -- Arrow Up   - raise the vehicle
Config.LiftDownControl      = 173     -- Arrow Down - lower the vehicle
Config.LiftCancelControl    = 194     -- Backspace  - cancel and settle back on the level it started on
Config.LiftConfirmControl   = 191     -- Enter (INPUT_FRONTEND_ACCEPT) - confirm the current height while lowering
Config.LoadControl          = 38      -- E (INPUT_CONTEXT)
Config.UnloadControl        = 29      -- B - press while driving the vehicle towing the trailer
Config.LoadKeyLabel         = 'E'     -- Attach the vehicle you're driving to the trailer / secure it in place
Config.ToggleUIKeyLabel     = 'H'     -- Shown in the UI - hides/shows this helper panel