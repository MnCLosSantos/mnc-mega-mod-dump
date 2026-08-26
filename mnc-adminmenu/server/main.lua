local QBCore = exports['qb-core']:GetCoreObject()

-- ─────────────────────────────────────────────
--  Config
-- ─────────────────────────────────────────────
local USE_MULTIJOB         = true   -- set false if ps-multijob not installed
local MOVE_GARAGE_FEE      = 100    -- $ charged per /movegarage action

-- ─────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────
local function ParseMetadata(metaRaw)
    if not metaRaw then return {} end
    if type(metaRaw) == 'table' then return metaRaw end
    if type(metaRaw) == 'string' and metaRaw:find('{') then
        local ok, decoded = pcall(json.decode, metaRaw)
        if ok and decoded then return decoded end
    end
    return {}
end

-- IsAdmin: uses QBCore's native permission check (respects server's config)
local function IsAdmin(source)
    return QBCore.Functions.HasPermission(source, 'admin')
end

-- Build a lowercase-keyed vehicle name lookup once per request.
-- row.vehicle in player_vehicles is a RAW spawn-name string (e.g. "hela"), NOT JSON.
local function BuildVehicleNameLookup()
    local lookup = {}
    if QBCore.Shared.Vehicles then
        for spawnName, vehData in pairs(QBCore.Shared.Vehicles) do
            lookup[string.lower(spawnName)] = vehData.name or spawnName
        end
    end
    return lookup
end

local function GetJobList()
    local list = {}
    for jobName, jobData in pairs(QBCore.Shared.Jobs) do
        local grades = {}
        for gradeNum, gradeData in pairs(jobData.grades) do
            grades[#grades + 1] = { grade = tonumber(gradeNum), label = gradeData.name }
        end
        table.sort(grades, function(a, b) return a.grade < b.grade end)
        list[#list + 1] = { name = jobName, label = jobData.label, grades = grades }
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

-- Read public garages directly from qb-garages config.lua via LoadResourceFile.
-- qb-garages has no exports for its Config table — it's a shared Lua table
-- that only exists inside the qb-garages resource environment. The only
-- reliable cross-resource way to read it is to load the raw file ourselves
-- and execute it in a sandbox that stubs out the QBCore dependency.
local _cachedGarages = nil

local function GetPublicGarages()
    if _cachedGarages then return _cachedGarages end

    local garages = {}

    -- Load qb-garages config.lua as raw text
    local raw = LoadResourceFile('qb-garages', 'config.lua')
    if not raw then
        -- Try alternate path used in some repacks
        raw = LoadResourceFile('qb-garages', 'shared/config.lua')
    end

    if raw then
        -- Build a minimal sandbox: Config is the real target, everything else
        -- that config.lua might reference (QBCore, vector3, etc.) gets stubbed.
        local sandbox = {
            Config   = {},
            QBCore   = setmetatable({}, { __index = function() return function() end end }),
            vector3  = function(x, y, z) return { x=x, y=y, z=z } end,
            vector4  = function(x, y, z, w) return { x=x, y=y, z=z, w=w } end,
            pairs    = pairs,
            ipairs   = ipairs,
            tonumber = tonumber,
            tostring = tostring,
            math     = math,
            table    = table,
            string   = string,
            type     = type,
            print    = print,
        }
        sandbox._G = sandbox

        local fn, err = load(raw, 'qb-garages/config.lua', 't', sandbox)
        if fn then
            local ok = pcall(fn)
            if ok and type(sandbox.Config.Garages) == 'table' then
                for name, data in pairs(sandbox.Config.Garages) do
                    if type(data) == 'table' then
                        local gtype = data.type or data.garageType or 'public'
                        if gtype == 'public' then
                            garages[#garages + 1] = {
                                name  = name,
                                label = data.label or name,
                            }
                        end
                    end
                end
            else
                print('[mnc-adminmenu] Parsed qb-garages config.lua but Config.Garages was empty or missing.')
            end
        else
            print('[mnc-adminmenu] Failed to parse qb-garages config.lua: ' .. tostring(err))
        end
    else
        print('[mnc-adminmenu] Could not find qb-garages config.lua via LoadResourceFile.')
    end

    if #garages == 0 then
        print('[mnc-adminmenu] WARNING: No public garages found. Garage dropdowns will be empty.')
    else
        print('[mnc-adminmenu] Loaded ' .. #garages .. ' public garages from qb-garages.')
    end

    table.sort(garages, function(a, b) return a.label < b.label end)
    _cachedGarages = garages
    return garages
end

local function Notify(src, msg, ntype)
    local typeMap = { primary='inform', error='error', success='success', warning='warning' }
    TriggerClientEvent('ox_lib:notify', src, { type = typeMap[ntype] or 'inform', description = msg })
end

local function ResolvePlayer(input)
    if not input or input == '' then return nil, nil end
    local serverId = tonumber(input)
    if serverId then
        local p = QBCore.Functions.GetPlayer(serverId)
        if p then return p, p.PlayerData.citizenid end
    end
    local p = QBCore.Functions.GetPlayerByCitizenId(input)
    if p then return p, input end
    return nil, input
end

local function GetAllJobsForCid(citizenid, onlinePlayer)
    local jobMap = {}

    if onlinePlayer then
        local job = onlinePlayer.PlayerData.job
        jobMap[job.name] = {
            name        = job.name,
            label       = QBCore.Shared.Jobs[job.name] and QBCore.Shared.Jobs[job.name].label or job.name,
            grade       = job.grade.level,
            grade_label = job.grade.name,
            active      = true,
            online      = true,
        }
    end

    if USE_MULTIJOB then
        local ok, multiJobs = pcall(function() return exports['ps-multijob']:GetJobs(citizenid) end)
        if ok and multiJobs and type(multiJobs) == 'table' then
            for jobName, grade in pairs(multiJobs) do
                local jobData   = QBCore.Shared.Jobs[jobName]
                local gradeData = jobData and jobData.grades[tostring(grade)]
                if not jobMap[jobName] then
                    jobMap[jobName] = {
                        name        = jobName,
                        label       = jobData and jobData.label or jobName,
                        grade       = tonumber(grade) or 0,
                        grade_label = gradeData and gradeData.name or 'Grade '..tostring(grade),
                        active      = false,
                        online      = onlinePlayer ~= nil,
                    }
                end
            end
        end
    end

    local jobs = {}
    for _, j in pairs(jobMap) do jobs[#jobs + 1] = j end
    table.sort(jobs, function(a, b)
        if a.active ~= b.active then return a.active end
        return a.label < b.label
    end)
    return jobs
end

-- ─────────────────────────────────────────────
--  Startup
-- ─────────────────────────────────────────────
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    print('[mnc-adminmenu] started — multijob: ' .. tostring(USE_MULTIJOB) .. ', move fee: $' .. MOVE_GARAGE_FEE)
end)

-- ═════════════════════════════════════════════
--  ADMIN MENU  (/mncadmin — admin only)
-- ═════════════════════════════════════════════
RegisterNetEvent('mnc-adminmenu:server:checkAdmin', function()
    local src = source
    if not IsAdmin(src) then
        Notify(src, 'No permission.', 'error')
        return
    end
    TriggerClientEvent('mnc-adminmenu:client:open', src, {
        mode    = 'admin',
        jobs    = GetJobList(),
        garages = GetPublicGarages(),
    })
end)

-- ═════════════════════════════════════════════
--  PLAYER GARAGE MENU  (/movegarage — all players)
-- ═════════════════════════════════════════════
RegisterNetEvent('mnc-adminmenu:server:openMoveGarage', function()
    local src    = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    TriggerClientEvent('mnc-adminmenu:client:open', src, {
        mode    = 'player',
        jobs    = {},
        garages = GetPublicGarages(),
    })
end)

-- ─────────────────────────────────────────────
--  Lookup own vehicles (player /movegarage)
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-adminmenu:server:lookupOwnVehicles', function()
    local src    = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local citizenid  = player.PlayerData.citizenid
    local nameLookup = BuildVehicleNameLookup()

    MySQL.query(
        'SELECT plate, vehicle, garage, state FROM player_vehicles WHERE citizenid = ?',
        { citizenid },
        function(rows)
            if not rows then
                TriggerClientEvent('mnc-adminmenu:client:ownVehicles', src, nil); return
            end
            local vehicles = {}
            for _, row in ipairs(rows) do
                local model    = (type(row.vehicle) == 'string' and row.vehicle ~= '') and row.vehicle or row.plate
                local modelKey = string.lower(model)
                vehicles[#vehicles + 1] = {
                    plate  = row.plate,
                    model  = modelKey,
                    label  = nameLookup[modelKey] or model,
                    garage = row.garage or 'unknown',
                    state  = row.state  or 0,
                }
            end
            TriggerClientEvent('mnc-adminmenu:client:ownVehicles', src, vehicles)
        end
    )
end)

-- ─────────────────────────────────────────────
--  Player move vehicle to garage (charges $100, garaged-only enforced)
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-adminmenu:server:playerMoveVehicle', function(plate, garage)
    local src    = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    if not plate or plate == '' then Notify(src, 'Invalid plate.', 'error'); return end
    if not garage or garage == '' then Notify(src, 'Invalid garage.', 'error'); return end

    local citizenid = player.PlayerData.citizenid

    -- Verify ownership — player can only move their own garaged vehicles
    MySQL.query(
        'SELECT plate, state FROM player_vehicles WHERE plate = ? AND citizenid = ?',
        { plate, citizenid },
        function(rows)
            if not rows or #rows == 0 then
                Notify(src, 'Vehicle not found in your account.', 'error'); return
            end

            -- Charge the fee
            local cash = player.PlayerData.money['cash'] or 0
            local bank = player.PlayerData.money['bank'] or 0
            if cash + bank < MOVE_GARAGE_FEE then
                Notify(src, 'You need $' .. MOVE_GARAGE_FEE .. ' to move a vehicle.', 'error'); return
            end

            -- Deduct from cash first, then bank
            if cash >= MOVE_GARAGE_FEE then
                player.Functions.RemoveMoney('cash', MOVE_GARAGE_FEE, 'movegarage-fee')
            else
                local remaining = MOVE_GARAGE_FEE - cash
                player.Functions.RemoveMoney('cash', cash, 'movegarage-fee')
                player.Functions.RemoveMoney('bank', remaining, 'movegarage-fee')
            end

            -- Move the vehicle (force state=1 so it's available to pull from the new garage)
            MySQL.update(
                'UPDATE player_vehicles SET garage = ?, state = 1 WHERE plate = ? AND citizenid = ?',
                { garage, plate, citizenid },
                function(affected)
                    if affected and affected > 0 then
                        Notify(src, 'Vehicle moved to ' .. garage .. '. Fee: $' .. MOVE_GARAGE_FEE, 'success')
                        -- Refresh the player's own vehicle list in the UI
                        TriggerEvent('mnc-adminmenu:server:lookupOwnVehicles')
                    else
                        -- Refund if DB update failed
                        player.Functions.AddMoney('cash', MOVE_GARAGE_FEE, 'movegarage-refund')
                        Notify(src, 'Failed to move vehicle. Refunded.', 'error')
                    end
                end
            )
        end
    )
end)

-- ═════════════════════════════════════════════
--  JOB MANAGEMENT (admin only)
-- ═════════════════════════════════════════════

RegisterNetEvent('mnc-adminmenu:server:setSelfJob', function(jobName, grade)
    local src = source
    if not IsAdmin(src) then return end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    if not QBCore.Shared.Jobs[jobName] then
        Notify(src, 'Invalid job: '..tostring(jobName), 'error'); return
    end
    local gradeData = QBCore.Shared.Jobs[jobName].grades[tostring(grade)]
    if not gradeData then Notify(src, 'Invalid grade.', 'error'); return end
    player.Functions.SetJob(jobName, grade)
    if USE_MULTIJOB then
        pcall(function() exports['ps-multijob']:AddJob(player.PlayerData.citizenid, jobName, grade) end)
    end
    Notify(src, 'Your job set to '..QBCore.Shared.Jobs[jobName].label..' ('..gradeData.name..')', 'success')
end)

RegisterNetEvent('mnc-adminmenu:server:lookupPlayer', function(input)
    local src = source
    if not IsAdmin(src) then return end
    local onlinePlayer, citizenid = ResolvePlayer(input)
    if not citizenid then
        TriggerClientEvent('mnc-adminmenu:client:playerJobs', src, input, nil); return
    end
    local jobs = GetAllJobsForCid(citizenid, onlinePlayer)
    TriggerClientEvent('mnc-adminmenu:client:playerJobs', src, citizenid, jobs)
end)

RegisterNetEvent('mnc-adminmenu:server:removePlayerJob', function(input, jobName)
    local src = source
    if not IsAdmin(src) then return end
    local onlinePlayer, citizenid = ResolvePlayer(input)
    if not citizenid then Notify(src, 'Player not found.', 'error'); return end

    if USE_MULTIJOB then
        pcall(function() exports['ps-multijob']:RemoveJob(citizenid, jobName) end)
        TriggerClientEvent('mnc-adminmenu:client:syncMultijobUI', onlinePlayer and QBCore.Functions.GetPlayerByIdentifier(citizenid) or nil, jobName)
    end
    if onlinePlayer then
        local currentJob = onlinePlayer.PlayerData.job.name
        if currentJob == jobName then
            onlinePlayer.Functions.SetJob('unemployed', 0)
        end
    else
        MySQL.query('SELECT job FROM players WHERE citizenid = ?', { citizenid }, function(rows)
            if not rows or #rows == 0 then return end
        end)
    end
    Notify(src, 'Removed job '..jobName..' from '..citizenid, 'success')
    -- Refresh lookup for admin
    local jobs = GetAllJobsForCid(citizenid, onlinePlayer)
    TriggerClientEvent('mnc-adminmenu:client:playerJobs', src, citizenid, jobs)
end)

RegisterNetEvent('mnc-adminmenu:server:removeAllPlayerJobs', function(input)
    local src = source
    if not IsAdmin(src) then return end
    local onlinePlayer, citizenid = ResolvePlayer(input)
    if not citizenid then Notify(src, 'Player not found.', 'error'); return end

    if USE_MULTIJOB then
        pcall(function() exports['ps-multijob']:ClearJobs(citizenid) end)
    end
    if onlinePlayer then
        onlinePlayer.Functions.SetJob('unemployed', 0)
    end
    Notify(src, 'Removed all jobs from '..citizenid, 'success')
end)

RegisterNetEvent('mnc-adminmenu:server:setPlayerJob', function(input, jobName, grade)
    local src = source
    if not IsAdmin(src) then return end
    local onlinePlayer, citizenid = ResolvePlayer(input)
    if not citizenid then Notify(src, 'Player not found.', 'error'); return end
    if not QBCore.Shared.Jobs[jobName] then
        Notify(src, 'Invalid job: '..tostring(jobName), 'error'); return
    end
    local gradeData = QBCore.Shared.Jobs[jobName].grades[tostring(grade)]
    if not gradeData then Notify(src, 'Invalid grade.', 'error'); return end

    if onlinePlayer then
        onlinePlayer.Functions.SetJob(jobName, grade)
        if USE_MULTIJOB then
            pcall(function() exports['ps-multijob']:AddJob(citizenid, jobName, grade) end)
        end
        Notify(src, 'Set '..citizenid..' job to '..QBCore.Shared.Jobs[jobName].label, 'success')
    else
        -- Offline player — update DB directly
        local jobJson = json.encode({ name=jobName, label=QBCore.Shared.Jobs[jobName].label, grade={ level=grade, name=gradeData.name } })
        MySQL.update('UPDATE players SET job = ? WHERE citizenid = ?', { jobJson, citizenid }, function(affected)
            if affected and affected > 0 then
                Notify(src, 'Set offline player '..citizenid..' job to '..QBCore.Shared.Jobs[jobName].label, 'success')
            else
                Notify(src, 'Could not update offline player.', 'error')
            end
        end)
    end
end)

-- ═════════════════════════════════════════════
--  MONEY MANAGEMENT (admin only)
-- ═════════════════════════════════════════════

local function DecodeMoney(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) == 'string' and raw:find('{') then
        local ok, decoded = pcall(json.decode, raw)
        if ok and decoded then return decoded end
    end
    return {}
end

RegisterNetEvent('mnc-adminmenu:server:lookupMoney', function(input)
    local src = source
    if not IsAdmin(src) then return end
    local onlinePlayer, citizenid = ResolvePlayer(input)
    if not citizenid then
        TriggerClientEvent('mnc-adminmenu:client:playerMoney', src, input, nil); return
    end

    if onlinePlayer then
        local money = {
            cash = onlinePlayer.PlayerData.money['cash'] or 0,
            bank = onlinePlayer.PlayerData.money['bank'] or 0,
        }
        TriggerClientEvent('mnc-adminmenu:client:playerMoney', src, citizenid, money)
        return
    end

    MySQL.query('SELECT money FROM players WHERE citizenid = ?', { citizenid }, function(rows)
        if not rows or #rows == 0 then
            TriggerClientEvent('mnc-adminmenu:client:playerMoney', src, citizenid, nil); return
        end
        local m = DecodeMoney(rows[1].money)
        TriggerClientEvent('mnc-adminmenu:client:playerMoney', src, citizenid, {
            cash = tonumber(m['cash']) or 0,
            bank = tonumber(m['bank']) or 0,
        })
    end)
end)

RegisterNetEvent('mnc-adminmenu:server:addMoney', function(input, moneytype, amount)
    local src = source
    if not IsAdmin(src) then return end
    if not amount or amount <= 0 then Notify(src, 'Invalid amount.', 'error'); return end
    if moneytype ~= 'cash' and moneytype ~= 'bank' then Notify(src, 'Invalid type.', 'error'); return end
    local onlinePlayer, citizenid = ResolvePlayer(input)
    if onlinePlayer then
        onlinePlayer.Functions.AddMoney(moneytype, amount, 'admin-add')
        Notify(src, 'Added $'..amount..' ('..moneytype..') to '..citizenid, 'success')
        TriggerClientEvent('mnc-adminmenu:client:playerMoney', src, citizenid, {
            cash = onlinePlayer.PlayerData.money['cash'] or 0,
            bank = onlinePlayer.PlayerData.money['bank'] or 0,
        })
        return
    end
    if not citizenid then Notify(src, 'Player not found.', 'error'); return end
    MySQL.query('SELECT money FROM players WHERE citizenid = ?', { citizenid }, function(rows)
        if not rows or #rows == 0 then Notify(src, 'Player not found.', 'error'); return end
        local m = DecodeMoney(rows[1].money)
        m[moneytype] = (tonumber(m[moneytype]) or 0) + amount
        MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', { json.encode(m), citizenid }, function(affected)
            if affected and affected > 0 then
                Notify(src, 'Added $'..amount..' ('..moneytype..') to offline '..citizenid, 'success')
                TriggerClientEvent('mnc-adminmenu:client:playerMoney', src, citizenid, { cash=tonumber(m['cash']) or 0, bank=tonumber(m['bank']) or 0 })
            else Notify(src, 'DB update failed.', 'error') end
        end)
    end)
end)

RegisterNetEvent('mnc-adminmenu:server:removeMoney', function(input, moneytype, amount)
    local src = source
    if not IsAdmin(src) then return end
    if not amount or amount <= 0 then Notify(src, 'Invalid amount.', 'error'); return end
    if moneytype ~= 'cash' and moneytype ~= 'bank' then Notify(src, 'Invalid type.', 'error'); return end
    local onlinePlayer, citizenid = ResolvePlayer(input)
    if onlinePlayer then
        local current = onlinePlayer.PlayerData.money[moneytype] or 0
        if current < amount then Notify(src, 'Player only has $'..current..' in '..moneytype..'.', 'warning'); return end
        onlinePlayer.Functions.RemoveMoney(moneytype, amount, 'admin-remove')
        Notify(src, 'Removed $'..amount..' ('..moneytype..') from '..citizenid, 'success')
        TriggerClientEvent('mnc-adminmenu:client:playerMoney', src, citizenid, {
            cash = onlinePlayer.PlayerData.money['cash'] or 0,
            bank = onlinePlayer.PlayerData.money['bank'] or 0,
        })
        return
    end
    if not citizenid then Notify(src, 'Player not found.', 'error'); return end
    MySQL.query('SELECT money FROM players WHERE citizenid = ?', { citizenid }, function(rows)
        if not rows or #rows == 0 then Notify(src, 'Player not found.', 'error'); return end
        local m = DecodeMoney(rows[1].money)
        local current = tonumber(m[moneytype]) or 0
        if current < amount then Notify(src, 'Player only has $'..current..' in '..moneytype..'.', 'warning'); return end
        m[moneytype] = current - amount
        MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', { json.encode(m), citizenid }, function(affected)
            if affected and affected > 0 then
                Notify(src, 'Removed $'..amount..' ('..moneytype..') from offline '..citizenid, 'success')
                TriggerClientEvent('mnc-adminmenu:client:playerMoney', src, citizenid, { cash=tonumber(m['cash']) or 0, bank=tonumber(m['bank']) or 0 })
            else Notify(src, 'DB update failed.', 'error') end
        end)
    end)
end)

RegisterNetEvent('mnc-adminmenu:server:setMoney', function(input, moneytype, amount)
    local src = source
    if not IsAdmin(src) then return end
    if amount == nil or amount < 0 then Notify(src, 'Invalid amount.', 'error'); return end
    if moneytype ~= 'cash' and moneytype ~= 'bank' then Notify(src, 'Invalid type.', 'error'); return end
    local onlinePlayer, citizenid = ResolvePlayer(input)
    if onlinePlayer then
        local current = onlinePlayer.PlayerData.money[moneytype] or 0
        local diff = amount - current
        if diff > 0 then
            onlinePlayer.Functions.AddMoney(moneytype, diff, 'admin-set')
        elseif diff < 0 then
            onlinePlayer.Functions.RemoveMoney(moneytype, math.abs(diff), 'admin-set')
        end
        Notify(src, 'Set '..moneytype..' to $'..amount..' for '..citizenid, 'success')
        TriggerClientEvent('mnc-adminmenu:client:playerMoney', src, citizenid, {
            cash = onlinePlayer.PlayerData.money['cash'] or 0,
            bank = onlinePlayer.PlayerData.money['bank'] or 0,
        })
        return
    end
    if not citizenid then Notify(src, 'Player not found.', 'error'); return end
    MySQL.query('SELECT money FROM players WHERE citizenid = ?', { citizenid }, function(rows)
        if not rows or #rows == 0 then Notify(src, 'Player not found.', 'error'); return end
        local m = DecodeMoney(rows[1].money)
        m[moneytype] = amount
        MySQL.update('UPDATE players SET money = ? WHERE citizenid = ?', { json.encode(m), citizenid }, function(affected)
            if affected and affected > 0 then
                Notify(src, 'Set '..moneytype..' to $'..amount..' for offline '..citizenid, 'success')
                TriggerClientEvent('mnc-adminmenu:client:playerMoney', src, citizenid, { cash=tonumber(m['cash']) or 0, bank=tonumber(m['bank']) or 0 })
            else Notify(src, 'DB update failed.', 'error') end
        end)
    end)
end)

-- ═════════════════════════════════════════════
--  VEHICLE MANAGEMENT (admin only)
-- ═════════════════════════════════════════════

RegisterNetEvent('mnc-adminmenu:server:lookupVehicles', function(input)
    local src = source
    if not IsAdmin(src) then return end
    if not input or input == '' then Notify(src, 'Enter a player ID or Citizen ID.', 'error'); return end

    local _, citizenid = ResolvePlayer(input)
    if not citizenid then
        TriggerClientEvent('mnc-adminmenu:client:playerVehicles', src, input, nil); return
    end

    local nameLookup = BuildVehicleNameLookup()

    MySQL.query(
        'SELECT plate, vehicle, garage, fuel, engine, body, state FROM player_vehicles WHERE citizenid = ?',
        { citizenid },
        function(rows)
            if not rows then
                TriggerClientEvent('mnc-adminmenu:client:playerVehicles', src, citizenid, nil); return
            end
            local vehicles = {}
            for _, row in ipairs(rows) do
                local model    = (type(row.vehicle) == 'string' and row.vehicle ~= '') and row.vehicle or row.plate
                local modelKey = string.lower(model)
                vehicles[#vehicles + 1] = {
                    plate   = row.plate,
                    model   = modelKey,
                    label   = nameLookup[modelKey] or model,
                    fuel    = row.fuel   or 100,
                    engine  = row.engine or 1000,
                    body    = row.body   or 1000,
                    garage  = row.garage or 'unknown',
                    state   = row.state  or 0,
                }
            end
            TriggerClientEvent('mnc-adminmenu:client:playerVehicles', src, citizenid, vehicles)
        end
    )
end)

RegisterNetEvent('mnc-adminmenu:server:deleteVehicle', function(plate)
    local src = source
    if not IsAdmin(src) then return end
    if not plate or plate == '' then Notify(src, 'Invalid plate.', 'error'); return end
    MySQL.update('DELETE FROM player_vehicles WHERE plate = ?', { plate }, function(affected)
        if affected and affected > 0 then
            Notify(src, 'Vehicle '..plate..' deleted.', 'success')
        else
            Notify(src, 'Vehicle not found: '..plate, 'error')
        end
    end)
end)

RegisterNetEvent('mnc-adminmenu:server:setVehicleGarage', function(plate, garage)
    local src = source
    if not IsAdmin(src) then return end
    if not plate or plate == '' then Notify(src, 'Invalid plate.', 'error'); return end
    if not garage or garage == '' then Notify(src, 'Invalid garage.', 'error'); return end
    MySQL.update(
        'UPDATE player_vehicles SET garage = ?, state = 1 WHERE plate = ?',
        { garage, plate },
        function(affected)
            if affected and affected > 0 then
                Notify(src, 'Vehicle '..plate..' moved to '..garage..'.', 'success')
            else
                Notify(src, 'Vehicle not found: '..plate, 'error')
            end
        end
    )
end)

-- ═════════════════════════════════════════════
--  INVENTORY (admin only, reads qb-inventory)
-- ═════════════════════════════════════════════

RegisterNetEvent('mnc-adminmenu:server:lookupInventory', function(input)
    local src = source
    if not IsAdmin(src) then return end
    if not input or input == '' then Notify(src, 'Enter a player ID or Citizen ID.', 'error'); return end

    local _, citizenid = ResolvePlayer(input)
    if not citizenid then
        TriggerClientEvent('mnc-adminmenu:client:playerInventory', src, input, nil); return
    end

    MySQL.query(
        'SELECT inventory FROM players WHERE citizenid = ?',
        { citizenid },
        function(rows)
            if not rows or #rows == 0 then
                TriggerClientEvent('mnc-adminmenu:client:playerInventory', src, citizenid, nil); return
            end

            local raw   = rows[1].inventory
            local items = {}

            local function processItem(item)
                if type(item) == 'table' and item.name then
                    local qty = tonumber(item.amount or item.count) or 1
                    if qty > 0 then
                        local shared = QBCore.Shared.Items[item.name]
                        items[#items + 1] = {
                            name   = item.name,
                            label  = (shared and shared.label) or item.label or item.name,
                            amount = qty,
                            slot   = item.slot or 0,
                        }
                    end
                end
            end

            if type(raw) == 'string' and raw:find('{') then
                local ok, decoded = pcall(json.decode, raw)
                if ok and decoded then
                    -- Array format: [{name, amount, slot, …}]
                    if decoded[1] ~= nil then
                        for _, item in ipairs(decoded) do processItem(item) end
                    else
                        -- Object/map format: { "1" = {…}, "2" = {…} }
                        for _, item in pairs(decoded) do processItem(item) end
                    end
                end
            end

            table.sort(items, function(a, b) return a.label < b.label end)
            TriggerClientEvent('mnc-adminmenu:client:playerInventory', src, citizenid, items)
        end
    )
end)

-- ─────────────────────────────────────────────
--  Remove single inventory item (admin only, uses qb-inventory)
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-adminmenu:server:removeInventoryItem', function(input, itemName, amount)
    local src = source
    if not IsAdmin(src) then return end
    if not itemName or itemName == '' then Notify(src, 'Invalid item.', 'error'); return end
    amount = tonumber(amount) or 1
    if amount < 1 then Notify(src, 'Invalid amount.', 'error'); return end

    local onlinePlayer, citizenid = ResolvePlayer(input)

    if onlinePlayer then
        -- Online: use qb-inventory export directly
        local removed = exports['qb-inventory']:RemoveItem(onlinePlayer.PlayerData.source, itemName, amount)
        if removed then
            Notify(src, 'Removed ' .. amount .. 'x ' .. itemName .. ' from ' .. citizenid, 'success')
            -- Refresh inventory display
            TriggerEvent('mnc-adminmenu:server:lookupInventory', citizenid)
        else
            Notify(src, 'Could not remove item (not enough in inventory?).', 'error')
        end
        return
    end

    if not citizenid then Notify(src, 'Player not found.', 'error'); return end

    -- Offline: edit the inventory JSON in the DB directly
    MySQL.query('SELECT inventory FROM players WHERE citizenid = ?', { citizenid }, function(rows)
        if not rows or #rows == 0 then Notify(src, 'Player not found.', 'error'); return end

        local raw   = rows[1].inventory
        local items = {}
        if type(raw) == 'string' and raw:find('{') then
            local ok, decoded = pcall(json.decode, raw)
            if ok and decoded then items = decoded end
        end

        local removed = 0
        -- Handle both array and object formats
        local isArray = items[1] ~= nil
        if isArray then
            for _, item in ipairs(items) do
                if item and item.name == itemName then
                    local qty = tonumber(item.amount or item.count) or 0
                    local take = math.min(qty, amount - removed)
                    item.amount = qty - take
                    if item.amount then item.count = item.amount end
                    removed = removed + take
                    if removed >= amount then break end
                end
            end
            -- Remove zero-quantity entries
            local cleaned = {}
            for _, item in ipairs(items) do
                if item and (tonumber(item.amount or item.count) or 0) > 0 then
                    cleaned[#cleaned + 1] = item
                end
            end
            items = cleaned
        else
            for slot, item in pairs(items) do
                if type(item) == 'table' and item.name == itemName then
                    local qty = tonumber(item.amount or item.count) or 0
                    local take = math.min(qty, amount - removed)
                    items[slot].amount = qty - take
                    if items[slot].amount == 0 then items[slot] = nil end
                    removed = removed + take
                    if removed >= amount then break end
                end
            end
        end

        if removed == 0 then
            Notify(src, 'Item not found in offline player inventory.', 'error'); return
        end

        MySQL.update('UPDATE players SET inventory = ? WHERE citizenid = ?', { json.encode(items), citizenid },
            function(affected)
                if affected and affected > 0 then
                    Notify(src, 'Removed ' .. removed .. 'x ' .. itemName .. ' from offline ' .. citizenid, 'success')
                    -- Re-query so admin UI refreshes
                    TriggerClientEvent('mnc-adminmenu:server:lookupInventory', src, citizenid)
                else
                    Notify(src, 'DB update failed.', 'error')
                end
            end
        )
    end)
end)

-- ─────────────────────────────────────────────
--  Sync ps-multijob NUI when a job is removed server-side
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-adminmenu:client:syncMultijobUI', function(jobName)
    SendNUIMessage({ action = 'removejob', name = jobName })
end)