-- vip_client.lua
-- mnc-parking — VIP parking slot management (client side)
-- Completely standalone — does NOT touch client.lua / cover_client.lua
-- ─────────────────────────────────────────────────────────────────────────────

local QBCore = nil

CreateThread(function()
    while not QBCore do
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbcore') == 'started' then
            local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
            if ok and obj then QBCore = obj end
        end
        Wait(500)
    end
end)

-- ─── Helper ──────────────────────────────────────────────────────────────────
local function Notify(title, description, ntype, duration)
    lib.notify({
        title       = title or 'VIP Parking',
        description = description,
        type        = ntype   or 'inform',
        duration    = duration or 5000,
    })
end

-- ─── Open the admin VIP grant panel (triggered by /vipparking) ───────────────
RegisterNetEvent('mnc-parking:openVipPanel', function()
    -- Step 1 — collect target Citizen ID
    local inputResult = lib.inputDialog('Grant VIP Parking', {
        {
            type        = 'input',
            label       = 'Player — Server ID or Citizen ID',
            description = 'Enter a server ID (e.g. 5) or a citizenid (e.g. QBM37KXAP).',
            placeholder = 'e.g. 5  or  QBM37KXAP',
            required    = true,
            min         = 1,
            max         = 50,
        },
        {
            type        = 'number',
            label       = 'Max Parking Slots',
            description = 'How many vehicles this player can park at once (1 – 100).',
            default     = 10,
            min         = 1,
            max         = 100,
            required    = true,
        },
        {
            type        = 'number',
            label       = 'Cost (cash, 0 = free)',
            description = 'Amount deducted from YOUR cash as the granting admin. Set 0 for free grants.',
            default     = 0,
            min         = 0,
            max         = 10000000,
            required    = true,
        },
    })

    if not inputResult then return end  -- cancelled

    local targetCid = tostring(inputResult[1] or ''):gsub('%s+', '')
    local maxSlots  = tonumber(inputResult[2]) or 10
    local cost      = tonumber(inputResult[3]) or 0

    if targetCid == '' then
        Notify('VIP Parking', 'Citizen ID cannot be empty.', 'error')
        return
    end

    -- Confirmation dialog
    local confirm = lib.alertDialog({
        header  = 'Confirm VIP Grant',
        content = ('Grant **%d** parking slots to **%s**%s?')
                  :format(
                      maxSlots, targetCid,
                      cost > 0 and (' for **$' .. cost .. '**') or ' (free)'),
        centered = true,
        cancel   = true,
    })
    if confirm ~= 'confirm' then return end

    -- Send to server
    local ok, msg = lib.callback.await('mnc-parking:buyVip', false, targetCid, maxSlots, cost)
    if ok then
        Notify('VIP Parking', msg, 'success', 7000)
    else
        Notify('VIP Parking', msg, 'error', 7000)
    end
end)

-- ─── Open the VIP admin list panel ───────────────────────────────────────────
local function OpenVipListPanel()
    local rows = lib.callback.await('mnc-parking:listVip', false)
    if not rows or #rows == 0 then
        Notify('VIP Parking', 'No active VIP records found.', 'inform')
        return
    end

    local options = {}
    for _, row in ipairs(rows) do
        local expiry = row.expires_at and ('Expires: ' .. row.expires_at) or 'Never expires'
        local r = row  -- upvalue capture
        options[#options + 1] = {
            title       = ('%s — %d slots'):format(r.citizenid, r.max_slots),
            description = ('Granted by: %s | Cost: $%d | %s'):format(
                r.granted_by or 'system', r.cost or 0, expiry),
            icon        = 'star',
            onSelect    = function()
                -- Sub-menu: actions for this VIP entry
                lib.registerContext({
                    id      = 'mnc_vip_action_' .. r.citizenid,
                    title   = 'VIP: ' .. r.citizenid,
                    options = {
                        {
                            title       = 'Edit Slots',
                            description = 'Change the max parking slots for this player.',
                            icon        = 'edit',
                            onSelect    = function()
                                local editInput = lib.inputDialog(
                                    'Edit VIP Slots — ' .. r.citizenid, {
                                    {
                                        type     = 'number',
                                        label    = 'New Max Slots',
                                        default  = r.max_slots,
                                        min      = 1,
                                        max      = 100,
                                        required = true,
                                    },
                                })
                                if not editInput then return end
                                local newSlots = tonumber(editInput[1]) or r.max_slots
                                local ok2, msg2 = lib.callback.await(
                                    'mnc-parking:buyVip', false, r.citizenid, newSlots, 0)
                                Notify('VIP Parking', msg2, ok2 and 'success' or 'error')
                            end,
                        },
                        {
                            title       = 'Revoke VIP',
                            description = 'Remove this player\'s VIP parking status.',
                            icon        = 'trash-alt',
                            onSelect    = function()
                                local confirm2 = lib.alertDialog({
                                    header   = 'Revoke VIP',
                                    content  = ('Remove VIP parking from **%s**?'):format(r.citizenid),
                                    centered = true,
                                    cancel   = true,
                                })
                                if confirm2 ~= 'confirm' then return end
                                local ok2, msg2 = lib.callback.await(
                                    'mnc-parking:revokeVip', false, r.citizenid)
                                Notify('VIP Parking', msg2, ok2 and 'success' or 'error')
                            end,
                        },
                    },
                })
                lib.showContext('mnc_vip_action_' .. r.citizenid)
            end,
        }
    end

    lib.registerContext({
        id      = 'mnc_vip_list',
        title   = ('VIP Parking Records (%d)'):format(#rows),
        options = options,
    })
    lib.showContext('mnc_vip_list')
end

-- ─── /viplist command — admin-only, opens the management list ────────────────
CreateThread(function()
    while not QBCore do Wait(500) end
    RegisterCommand('parkviplist', function()
        OpenVipListPanel()
    end, false)

    -- /myvip — any player can check their own status
    RegisterCommand('parkmyvip', function()
        local status = lib.callback.await('mnc-parking:getVipStatus', false)
        if not status then
            Notify('VIP Parking',
                   ('You have standard parking (%d slots).'):format(Config.MaxVehiclesOut),
                   'inform')
            return
        end
        local expStr = status.expires_at
            and ('Expires: ' .. status.expires_at) or 'No expiry'
        Notify('VIP Parking',
               ('You have **%d** VIP parking slots. %s'):format(status.max_slots, expStr),
               'success', 7000)
    end, false)
end)