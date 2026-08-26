Config = {}

-- Print debug info to console (client + server)
Config.Debug = false

-- How often (ms) each client scans tracked vehicles for extra changes
Config.PollInterval = 1000

-- Minimum time (ms) between fixes on the same vehicle, prevents spamming
-- SetVehicleFixed/repair if extras are toggled rapidly
Config.FixCooldown = 1500

-- GTA extras typically range from 1 to 14. DoesExtraExist() guards anything
-- a given model doesn't actually have, so it's safe to scan the full range.
Config.MaxExtraIndex = 14

-- Vehicle models that should be auto-fixed when an extra is toggled.
-- Add/remove model names as needed (case as used by the game, all lowercase).
Config.TrackedModels = {
    "trailerflat2",
    "trailercar",
    "20fttrailer",
    "codestacker",
    "ctrailer",
	"bensonc",
	"bensonc2",
}
