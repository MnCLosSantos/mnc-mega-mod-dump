local QBCore = exports['qb-core']:GetCoreObject()

-- ── Permission helper ─────────────────────────────────────────
-- Uses QBCore's built-in permission check (reads PlayerData.permission,
-- not PlayerData.group — group is job rank, not admin level).
local function IsAdmin(src)
    
	-- HasPermission checks 'god' > 'admin' > 'mod' > 'user' hierarchy
    if QBCore.Functions.HasPermission(src, 'admin') then return true end

    -- ACE-based fallback
    -- if IsPlayerAceAllowed(tostring(src), 'command.towfinder') then return true end

    return false
end

-- ── Read qb-core vehicles ─────────────────────────────────────
local function GetAllVehicleModels()
    local vehicles = QBCore.Shared.Vehicles
    local models   = {}

    for model, data in pairs(vehicles) do
        table.insert(models, {
            model = model,
            name  = data.name or model,
        })
    end

    -- Sort alphabetically so the output file is readable
    table.sort(models, function(a, b) return a.model < b.model end)

    return models
end

-- ── Save Results (client → server) ───────────────────────────
RegisterNetEvent('mnc-towfinder:server:SaveResults', function(results)
    local src = source

    if not IsAdmin(src) then
        print('[MNC-TowFinder] Unauthorized SaveResults attempt from player ' .. src)
        return
    end
    if type(results) ~= 'table' then return end

    -- ── Group entries by bone name ────────────────────────────
    local groups  = {}   -- { [boneName] = { entry, … } }
    local order   = {}   -- ordered list of bone names (insertion order)

    for _, entry in ipairs(results) do
        local bone = entry.bone or 'unknown'
        if not groups[bone] then
            groups[bone] = {}
            table.insert(order, bone)
        end
        table.insert(groups[bone], entry)
    end

    -- Sort bone group names alphabetically for a consistent file
    table.sort(order)

    -- ── Build output Lua ──────────────────────────────────────
    local lines = {
        '-- MNC TowFinder Results',
        '-- Generated on: ' .. os.date('%Y-%m-%d %H:%M:%S'),
        '-- Total vehicles with tow capability: ' .. #results,
        '',
        'TowBarVehicles = {',
    }

    for _, bone in ipairs(order) do
        local entries = groups[bone]

        -- Section header comment
        table.insert(lines, '')
        table.insert(lines, string.format('    -- ── Bone: %-25s (%d vehicles)', bone, #entries))

        for _, entry in ipairs(entries) do
            table.insert(lines, string.format(
                '    %-30s -- %s',
                '"' .. entry.model .. '",',
                entry.name
            ))
        end
    end

    table.insert(lines, '}')

    local output = table.concat(lines, '\n')

    -- ── Write file ────────────────────────────────────────────
    local path = GetResourcePath(GetCurrentResourceName()) .. '/output/tow_vehicles.lua'
    local file = io.open(path, 'w')
    if file then
        file:write(output)
        file:close()
        print('[MNC-TowFinder] Saved ' .. #results .. ' vehicles to ' .. path)
        TriggerClientEvent('mnc-towfinder:client:SaveDone', src, #results, true)
    else
        print('\n[MNC-TowFinder] Could not write file – dumping to console:\n' .. output)
        TriggerClientEvent('mnc-towfinder:client:SaveDone', src, #results, false)
    end
end)

-- ── Request vehicle list (client → server) ────────────────────
RegisterNetEvent('mnc-towfinder:server:RequestVehicles', function()
    local src = source

    -- Gate: only admins may trigger a scan
    if not IsAdmin(src) then
        TriggerClientEvent('mnc-towfinder:client:AccessDenied', src)
        print('[MNC-TowFinder] Non-admin player ' .. src .. ' tried to start a scan.')
        return
    end

    local models = GetAllVehicleModels()
    TriggerClientEvent('mnc-towfinder:client:ReceiveVehicles', src, models)
end)

-- ── Create output directory on start ─────────────────────────
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    local outputDir = GetResourcePath(GetCurrentResourceName()) .. '/output'
    os.execute('mkdir -p "' .. outputDir .. '"')
    print('[MNC-TowFinder] Resource started. Output directory: ' .. outputDir)
end)