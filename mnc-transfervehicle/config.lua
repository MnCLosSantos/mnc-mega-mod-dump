Config = {}

-- Enable debug prints in F8 console and server console
Config.Debug = false

-- Prevent selling vehicles with outstanding finance balance
Config.PreventFinanceSelling = true

-- Require signature before transfer completes (always required for this system)
Config.SignatureRequired = true

-- Time in milliseconds before transfer expires (buyer must accept within this time)
-- Default: 300000 = 5 minutes
Config.DocumentExpiration = 300000

-- Maximum distance between seller and buyer in meters
-- Buyer must be within this distance when seller initiates the transfer
Config.TransferDistance = 5.0