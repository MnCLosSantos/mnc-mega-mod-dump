Config = {}

-- Jobs where members can send invoices.
-- grade = minimum grade required to send invoices (0 = any grade)
-- boss_grade = minimum grade to view the job ledger
-- If a job is not listed here, its members cannot send invoices.
-- Set Config.AutoDetect = true to allow ALL QBCore jobs to send invoices with no restrictions.
Config.AutoDetect = true

-- When AutoDetect is true, all jobs can invoice. You can still override specific jobs below.
-- When AutoDetect is false, only jobs listed here can invoice.
Config.Jobs = {
    -- ['police']     = { grade = 0, boss_grade = 3 },
    -- ['mechanic']   = { grade = 0, boss_grade = 2 },
    -- ['ambulance']  = { grade = 0, boss_grade = 3 },
}

-- Jobs that are NEVER allowed to send invoices (blocklist, applies even with AutoDetect on)
Config.BlockedJobs = {
    'unemployed',
    'offduty',
}

-- Minimum boss grade when AutoDetect is on (no override defined)
Config.DefaultBossGrade = 3

-- Maximum invoice amount
Config.MaxAmount = 1000000

-- Minimum invoice amount
Config.MinAmount = 1

-- How far away a player can be to receive an invoice (metres)
Config.InvoiceRange = 10.0

-- How long the target player has to respond to an invoice before it auto-expires (seconds)
Config.InvoiceTimeout = 120

-- Currency label shown in UI
Config.CurrencyLabel = '$'

-- Notify target player when they receive an invoice
Config.NotifyOnReceive = true

-- Command to open the payment menu
Config.Command = 'payments'

-- Keybind to open the payment menu (F10)
Config.Keybind = 'F10'

-- Item that opens the payment menu when used
-- Set to nil to disable item usage
Config.Item = 'billingtablet'
