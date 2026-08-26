local QBCore = exports['qb-core']:GetCoreObject()

-- ─────────────────────────────────────────────
--  Schema init
-- ─────────────────────────────────────────────
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_invoices` (
            `id`              INT(11) NOT NULL AUTO_INCREMENT,
            `from_citizenid`  VARCHAR(50)  NOT NULL,
            `from_name`       VARCHAR(100) NOT NULL DEFAULT '',
            `from_job`        VARCHAR(50)  NOT NULL DEFAULT 'unemployed',
            `from_job_label`  VARCHAR(100) NOT NULL DEFAULT '',
            `to_citizenid`    VARCHAR(50)  NOT NULL,
            `to_name`         VARCHAR(100) NOT NULL DEFAULT '',
            `amount`          INT(11)      NOT NULL DEFAULT 0,
            `reason`          VARCHAR(255) NOT NULL DEFAULT '',
            `status`          ENUM('pending','paid','declined','expired') NOT NULL DEFAULT 'pending',
            `payment_type`    ENUM('cash','bank') NULL DEFAULT NULL,
            `created_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `paid_at`         TIMESTAMP NULL DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `idx_from_cid`  (`from_citizenid`),
            KEY `idx_to_cid`    (`to_citizenid`),
            KEY `idx_from_job`  (`from_job`),
            KEY `idx_status`    (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    -- Expire stale pending invoices on startup
    Citizen.SetTimeout(3000, function()
        MySQL.query("UPDATE mnc_invoices SET status = 'expired' WHERE status = 'pending' AND TIMESTAMPDIFF(SECOND, created_at, NOW()) > ?", {
            Config.InvoiceTimeout
        })
    end)

    -- Migration: add payment_type column to existing installs (MySQL + MariaDB safe)
    Citizen.SetTimeout(1000, function()
        local rows = MySQL.query.await([[
            SELECT COUNT(*) AS cnt FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME   = 'mnc_invoices'
              AND COLUMN_NAME  = 'payment_type'
        ]], {})
        if rows and rows[1] and rows[1].cnt == 0 then
            MySQL.query([[
                ALTER TABLE `mnc_invoices`
                ADD COLUMN `payment_type` ENUM('cash','bank') NULL DEFAULT NULL AFTER `status`
            ]], {})
            print('[mnc-payments] Migrated: added payment_type column.')
        end
    end)

    print('[mnc-payments] Ready.')
end)

-- ─────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────
local function Notify(src, msg, ntype)
    local map = { success = 'success', error = 'error', warning = 'warning', primary = 'inform' }
    TriggerClientEvent('ox_lib:notify', src, { type = map[ntype] or 'inform', description = msg })
end

local function GetCharName(player)
    local pd = player.PlayerData
    if pd.charinfo then
        return (pd.charinfo.firstname or '') .. ' ' .. (pd.charinfo.lastname or '')
    end
    return 'Unknown'
end

-- Deposit money into a job's society (business) bank account.
-- Tries qb-banking first (exports['qb-banking']:AddMoney(jobName, amount)),
-- then qb-management (exports['qb-management']:AddMoney(jobName, amount)),
-- then falls back to the sender's personal bank so money is never lost.
local function DepositToSociety(jobName, amount, fallbackPlayer)
    -- qb-banking society deposit
    local ok, result = pcall(function()
        return exports['qb-banking']:AddMoney(jobName, amount)
    end)
    if ok and result ~= false then return true end

    -- qb-management society deposit
    ok, result = pcall(function()
        return exports['qb-management']:AddMoney(jobName, amount)
    end)
    if ok and result ~= false then return true end

    -- Fallback: personal bank of the sender
    if fallbackPlayer then
        fallbackPlayer.Functions.AddMoney('bank', amount, 'mnc-payments society fallback')
    end
    return false
end

local function CanSendInvoice(jobName)
    for _, blocked in ipairs(Config.BlockedJobs) do
        if blocked == jobName then return false end
    end
    if Config.AutoDetect then return true end
    return Config.Jobs[jobName] ~= nil
end

local function IsBoss(jobName, gradeLevel)
    for _, blocked in ipairs(Config.BlockedJobs) do
        if blocked == jobName then return false end
    end
    local override = Config.Jobs[jobName]
    local bossGrade = override and override.boss_grade or Config.DefaultBossGrade
    return gradeLevel >= bossGrade
end

-- ─────────────────────────────────────────────
--  Callback: getMenuData
--
--  inbox_invoices  — invoices this staff member has SENT (all statuses)
--                    shown in Inbox tab for staff
--  receipts        — invoices this player has PAID (as the recipient/to)
--                    shown in Receipts tab for the player being charged
--  pending         — invoices pending for this player to pay
--                    used for badge count + pay/decline buttons
--  ledger          — ALL invoices from this job (boss only)
--                    shown in Ledger tab for owners
-- ─────────────────────────────────────────────
QBCore.Functions.CreateCallback('mnc-payments:getMenuData', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(nil); return end

    local cid      = Player.PlayerData.citizenid
    local job      = Player.PlayerData.job
    local jobName  = job.name
    local jobLabel = job.label
    local grade    = job.grade.level
    local canSend  = CanSendInvoice(jobName)
    local isBoss   = IsBoss(jobName, grade)

    -- Any player can self-charge; only allowed jobs can send to others
    local isBlocked = false
    for _, blocked in ipairs(Config.BlockedJobs) do
        if blocked == jobName then isBlocked = true; break end
    end
    local canSendSelf = true  -- always allowed

    -- Pending invoices this player needs to pay (for badge + pay/decline)
    local pending = MySQL.query.await(
        "SELECT * FROM mnc_invoices WHERE to_citizenid = ? AND status = 'pending' ORDER BY created_at DESC",
        { cid }
    ) or {}

    -- Inbox: all invoices this player has SENT (any status) — for staff view
    local inboxInvoices = MySQL.query.await(
        "SELECT * FROM mnc_invoices WHERE from_citizenid = ? ORDER BY created_at DESC LIMIT 100",
        { cid }
    ) or {}

    -- Receipts: invoices this player has PAID (they were billed and paid) — for player view
    local receipts = MySQL.query.await(
        "SELECT * FROM mnc_invoices WHERE to_citizenid = ? AND status = 'paid' ORDER BY paid_at DESC LIMIT 50",
        { cid }
    ) or {}

    -- Ledger: every invoice sent by this job (boss/owner view)
    local ledger = {}
    if isBoss then
        ledger = MySQL.query.await(
            "SELECT * FROM mnc_invoices WHERE from_job = ? ORDER BY created_at DESC LIMIT 200",
            { jobName }
        ) or {}
    end

    cb({
        citizenid      = cid,
        job            = jobName,
        job_label      = jobLabel,
        grade          = grade,
        can_send       = canSend,
        can_send_self  = canSendSelf,
        is_boss        = isBoss,
        pending        = pending,
        inbox_invoices = inboxInvoices,
        receipts       = receipts,
        ledger         = ledger,
    })
end)

-- ─────────────────────────────────────────────
--  Callback: get nearby players for target selector
-- ─────────────────────────────────────────────
QBCore.Functions.CreateCallback('mnc-payments:getNearby', function(source, cb)
    local nearby = {}
    for _, pid in ipairs(QBCore.Functions.GetPlayers()) do
        if pid ~= source then
            local dist = #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(pid)))
            if dist <= Config.InvoiceRange then
                local p = QBCore.Functions.GetPlayer(pid)
                if p then
                    nearby[#nearby + 1] = {
                        id        = pid,
                        citizenid = p.PlayerData.citizenid,
                        name      = GetCharName(p),
                    }
                end
            end
        end
    end
    cb(nearby)
end)

-- ─────────────────────────────────────────────
--  Send invoice (to player or self)
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-payments:sendInvoice', function(data)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local job     = Player.PlayerData.job
    local jobName = job.name

    local amount = tonumber(data.amount)
    if not amount or amount < Config.MinAmount or amount > Config.MaxAmount then
        Notify(src, 'Invalid amount.', 'error'); return
    end

    local reason = tostring(data.reason or ''):sub(1, 255)
    if reason == '' then Notify(src, 'A reason is required.', 'error'); return end

    local fromCid  = Player.PlayerData.citizenid
    local fromName = GetCharName(Player)
    local jobLabel = job.label

    -- ── Self-charge: instant payment ──────────
    -- Any job (including unemployed) may charge themselves.
    -- Unemployed: no commission — full amount stays with the player (net zero).
    -- Employed: full amount deposited to the job's society account.
    if data.self_charge then
        local payType = (data.payment_type == 'bank') and 'bank' or 'cash'
        local cash    = Player.PlayerData.money['cash'] or 0
        local bank    = Player.PlayerData.money['bank'] or 0

        if payType == 'cash' then
            if cash < amount then
                Notify(src, 'Not enough cash (' .. Config.CurrencyLabel .. amount .. ' required).', 'error'); return
            end
            Player.Functions.RemoveMoney('cash', amount, 'mnc-payments self-charge')
        else
            if bank < amount then
                Notify(src, 'Not enough bank funds (' .. Config.CurrencyLabel .. amount .. ' required).', 'error'); return
            end
            Player.Functions.RemoveMoney('bank', amount, 'mnc-payments self-charge')
        end

        local isUnemployed = false
        for _, blocked in ipairs(Config.BlockedJobs) do
            if blocked == jobName then isUnemployed = true; break end
        end

        local cutMsg = ''
        if isUnemployed then
            -- Full refund: unemployed players keep the whole amount
            Player.Functions.AddMoney('bank', amount, 'mnc-payments self-charge refund')
        else
            -- Full amount to the job's society account
            local deposited = DepositToSociety(jobName, amount, Player)
            cutMsg = deposited
                and (' → ' .. jobLabel .. ' account')
                or  ' → your bank (no society account)'
        end

        MySQL.insert(
            "INSERT INTO mnc_invoices (from_citizenid, from_name, from_job, from_job_label, to_citizenid, to_name, amount, reason, status, payment_type, paid_at) VALUES (?,?,?,?,?,?,?,?,'paid',?,NOW())",
            { fromCid, fromName, jobName, jobLabel, fromCid, fromName, amount, reason, payType }
        )
        Notify(src, 'Self-payment of ' .. Config.CurrencyLabel .. amount .. ' processed' .. cutMsg .. '.', 'success')
        TriggerClientEvent('mnc-payments:refreshMenu', src)
        return
    end

    -- ── Invoice another player — job check applies here ──
    if not CanSendInvoice(jobName) then
        Notify(src, 'Your job cannot send invoices.', 'error'); return
    end

    local targetCid = tostring(data.to_citizenid or '')
    if targetCid == '' then Notify(src, 'No target specified.', 'error'); return end

    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetCid)
    if not targetPlayer then
        Notify(src, 'Target player is no longer online.', 'error'); return
    end

    local dist = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(targetPlayer.PlayerData.source)))
    if dist > Config.InvoiceRange then
        Notify(src, 'Player is too far away.', 'error'); return
    end

    local toName = GetCharName(targetPlayer)

    local invoiceId = MySQL.insert.await(
        "INSERT INTO mnc_invoices (from_citizenid, from_name, from_job, from_job_label, to_citizenid, to_name, amount, reason) VALUES (?,?,?,?,?,?,?,?)",
        { fromCid, fromName, jobName, jobLabel, targetCid, toName, amount, reason }
    )
    if not invoiceId then Notify(src, 'Failed to create invoice.', 'error'); return end

    -- Expiry timer
    Citizen.CreateThread(function()
        Citizen.Wait(Config.InvoiceTimeout * 1000)
        local row = MySQL.query.await("SELECT status FROM mnc_invoices WHERE id = ?", { invoiceId })
        if row and row[1] and row[1].status == 'pending' then
            MySQL.update("UPDATE mnc_invoices SET status = 'expired' WHERE id = ?", { invoiceId })
            Notify(targetPlayer.PlayerData.source, 'An invoice from ' .. fromName .. ' has expired.', 'warning')
            Notify(src, 'Invoice #' .. invoiceId .. ' expired (not responded to).', 'warning')
            TriggerClientEvent('mnc-payments:refreshMenu', targetPlayer.PlayerData.source)
            TriggerClientEvent('mnc-payments:refreshMenu', src)
        end
    end)

    -- Notify target
    if Config.NotifyOnReceive then
        TriggerClientEvent('mnc-payments:receiveInvoice', targetPlayer.PlayerData.source, {
            id             = invoiceId,
            from_name      = fromName,
            from_job_label = jobLabel,
            amount         = amount,
            reason         = reason,
        })
    end

    -- Refresh sender's inbox so new pending invoice shows immediately
    TriggerClientEvent('mnc-payments:refreshMenu', src)

    Notify(src, 'Invoice #' .. invoiceId .. ' sent to ' .. toName .. '.', 'success')
end)

-- ─────────────────────────────────────────────
--  Respond to invoice (pay or decline)
--  On pay: sender receives 10% commission into bank
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-payments:respondInvoice', function(data)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local invoiceId = tonumber(data.id)
    local accept    = data.accept == true

    if not invoiceId then Notify(src, 'Invalid invoice.', 'error'); return end

    local rows = MySQL.query.await("SELECT * FROM mnc_invoices WHERE id = ? AND status = 'pending'", { invoiceId })
    if not rows or #rows == 0 then
        Notify(src, 'Invoice is no longer valid.', 'error'); return
    end

    local invoice = rows[1]
    if invoice.to_citizenid ~= Player.PlayerData.citizenid then
        Notify(src, 'This invoice is not for you.', 'error'); return
    end

    -- ── Decline ───────────────────────────────
    if not accept then
        MySQL.update("UPDATE mnc_invoices SET status = 'declined' WHERE id = ?", { invoiceId })
        Notify(src, 'Invoice declined.', 'primary')
        local payerName = Player.PlayerData.charinfo
            and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname)
            or 'Player'
        local sender = QBCore.Functions.GetPlayerByCitizenId(invoice.from_citizenid)
        if sender then
            Notify(sender.PlayerData.source, payerName .. ' declined invoice #' .. invoiceId .. '.', 'warning')
            TriggerClientEvent('mnc-payments:refreshMenu', sender.PlayerData.source)
        end
        TriggerClientEvent('mnc-payments:refreshMenu', src)
        return
    end

    -- ── Pay ───────────────────────────────────
    local amount  = invoice.amount
    local payType = (data.payment_type == 'bank') and 'bank' or 'cash'
    local cash    = Player.PlayerData.money['cash'] or 0
    local bank    = Player.PlayerData.money['bank'] or 0

    if payType == 'cash' then
        if cash < amount then
            Notify(src, 'Not enough cash (' .. Config.CurrencyLabel .. amount .. ' required). Try paying by bank.', 'error'); return
        end
        Player.Functions.RemoveMoney('cash', amount, 'mnc-payments invoice #' .. invoiceId)
    else
        if bank < amount then
            Notify(src, 'Not enough bank funds (' .. Config.CurrencyLabel .. amount .. ' required). Try paying by cash.', 'error'); return
        end
        Player.Functions.RemoveMoney('bank', amount, 'mnc-payments invoice #' .. invoiceId)
    end

    MySQL.update("UPDATE mnc_invoices SET status = 'paid', payment_type = ?, paid_at = NOW() WHERE id = ?", { payType, invoiceId })

    -- Check whether the sender's job is blocked (e.g. unemployed)
    local senderJobBlocked = false
    for _, blocked in ipairs(Config.BlockedJobs) do
        if blocked == invoice.from_job then senderJobBlocked = true; break end
    end

    local sender = QBCore.Functions.GetPlayerByCitizenId(invoice.from_citizenid)
    local payerName = Player.PlayerData.charinfo
        and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname)
        or 'Someone'
    local payLabel = payType == 'cash' and 'cash' or 'bank transfer'

    if senderJobBlocked then
        -- Sender was unemployed: full payment refunded to the payer (net zero)
        Player.Functions.AddMoney('bank', amount, 'mnc-payments refund — unemployed invoice #' .. invoiceId)
        Notify(src, 'Paid ' .. Config.CurrencyLabel .. amount .. ' via ' .. payLabel .. ' — refunded (unemployed invoice).', 'success')
        if sender then
            Notify(sender.PlayerData.source, payerName .. ' paid invoice #' .. invoiceId .. ' (no society deposit — unemployed).', 'primary')
            TriggerClientEvent('mnc-payments:refreshMenu', sender.PlayerData.source)
        end
    else
        -- Deposit full amount to the job's society (business) bank account
        local deposited = DepositToSociety(invoice.from_job, amount, sender)
        local destLabel = deposited and (invoice.from_job_label .. ' account') or "sender's bank"

        if sender then
            Notify(
                sender.PlayerData.source,
                payerName .. ' paid invoice #' .. invoiceId .. ' (' .. Config.CurrencyLabel .. amount .. ' via ' .. payLabel .. ') → ' .. destLabel .. '.',
                'success'
            )
            TriggerClientEvent('mnc-payments:refreshMenu', sender.PlayerData.source)
        end
        Notify(src, 'Paid ' .. Config.CurrencyLabel .. amount .. ' via ' .. payLabel .. ' to ' .. invoice.from_job_label .. '.', 'success')
    end

    TriggerClientEvent('mnc-payments:refreshMenu', src)
end)

-- ─────────────────────────────────────────────
--  Item registration — billingtablet
-- ─────────────────────────────────────────────
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if not Config.Item then return end
    Citizen.Wait(500)
    QBCore.Functions.CreateUseableItem(Config.Item, function(source)
        TriggerClientEvent('mnc-payments:client:useItem', source)
    end)
    print('[mnc-payments] Useable item registered: ' .. Config.Item)
end)