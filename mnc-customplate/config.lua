Config = {}

-- ============================================================
--  MNC Custom Plate - Config
-- ============================================================

-- Item name (must match qb-core items)
Config.Item = 'custom_plate_kit'

-- Max plate characters (GTA limit is 8)
Config.MaxPlateLength = 8
Config.MinPlateLength = 1

-- Animation applied while applying the plate
Config.AnimDict = 'anim@heists@box_carry@'
Config.AnimName = 'idle'

-- Progress bar duration (ms)
Config.ProgressDuration = 5000

-- Admin permission (ace / qb job)
Config.AdminGroups = { 'admin', 'god', 'superadmin' }   -- ← edit to match your actual groups

-- Job lock: set to nil to allow everyone with the item to use it
-- Example: Config.JobLock = { name = 'mechanic', grade = 0 }
Config.JobLock = nil

-- Whether to allow the /customplate command for admins (no item needed)
Config.AdminCommand = true
Config.AdminCommandName = 'customplate'

-- Plate state pattern displayed in UI
Config.PlateState = 'MNC STATE'

-- Single white theme only
Config.PlateThemes = {
    { id = 'default', label = 'White Classic', bg = '#FFFFFF', text = '#1a1a2e', border = '#c9aa71' },
}