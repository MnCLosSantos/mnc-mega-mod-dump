local QBCore = exports['qb-core']:GetCoreObject()
local LocalResourceName = GetCurrentResourceName()

-- ── Admin command ─────────────────────────────────────────────────────────────
lib.addCommand(Config.Command, {
    help = 'Opens Vehicle Catalog with All Vehicles (Admin)',
}, function(source, args, raw)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {
            title       = 'Access Denied',
            description = 'You do not have permission to use this command.',
            type        = 'error',
        })
        return
    end
    TriggerClientEvent('mnc-vehiclecatalog:openAdminUI', src)
end)

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function findZone(zoneName)
    if not zoneName or zoneName == '' then return nil end
    for _, z in ipairs(Config.Zones) do
        if z.name == zoneName then return z end
    end
    return nil
end

-- ── File I/O (Local Copy) ─────────────────────────────────────────────────────
local function readVehiclesFile()
    return LoadResourceFile(LocalResourceName, 'shared/vehicles.lua')
end

local function writeVehiclesFile(content)
    local toWrite = content:gsub('\r\n', '\n'):gsub('\n*$', '') .. '\n'
    local ok = SaveResourceFile(LocalResourceName, 'shared/vehicles.lua', toWrite, -1)
    
    if not ok then
        return nil, 'Failed to save local vehicles.lua'
    end
    return true
end

-- ── Line-by-line patcher ──────────────────────────────────────────────────────
local function patchVehiclesField(fileContent, model, fieldName, newValue)
    local esc = model:gsub('([%(%)%.%%%+%-%*%?%[%^%$])', '%%%1')
    local lines = {}
    local inEntry = false
    local fieldDone = false
    local braceDepth = 0
    local insertAfter = nil

    for line in (fileContent .. '\n'):gmatch('([^\n]*)\n') do
        local processedLine = line

        if not fieldDone then
            if not inEntry then
                local isA = line:match('%f[%a]model%s*=%s*[\'"]' .. esc .. '[\'"]')
                local isB = line:match("%['%s*" .. esc .. "%s*'%]%s*=") or
                            line:match('%["%s*' .. esc .. '%s*"%]%s*=') or
                            line:match('^%s*' .. esc .. '%s*=')

                if isA or isB then
                    inEntry = true
                    braceDepth = 0
                    for _ in line:gmatch('{') do braceDepth = braceDepth + 1 end
                    for _ in line:gmatch('}') do braceDepth = braceDepth - 1 end

                    if braceDepth <= 0 then
                        if fieldName == 'price' and line:match('%f[%a]price%s*=%s*%d+') then
                            processedLine = line:gsub('(%f[%a]price%s*=%s*)%d+', '%1' .. tostring(math.floor(newValue)), 1)
                            fieldDone = true
                        elseif fieldName == 'shop' then
                            if line:match('%f[%a]shop%s*=%s*[\'"]') then
                                if newValue ~= '' then
                                    processedLine = line:gsub("(%f[%a]shop%s*=%s*)['\"][^'\"]*['\"]", "%1'" .. newValue .. "'", 1)
                                else
                                    processedLine = line:gsub(",?%s*%f[%a]shop%s*=%s*['\"][^'\"]*['\"]", '', 1)
                                end
                                fieldDone = true
                            elseif newValue ~= '' then
                                processedLine = line:gsub('(%s*})', ", shop = '" .. newValue .. "'%1", 1)
                                fieldDone = true
                            else
                                fieldDone = true
                            end
                        end
                        inEntry = false
                    end
                end
            else
                for _ in line:gmatch('{') do braceDepth = braceDepth + 1 end
                for _ in line:gmatch('}') do braceDepth = braceDepth - 1 end

                if fieldName == 'price' and line:match('%f[%a]price%s*=%s*%d+') then
                    processedLine = line:gsub('(%f[%a]price%s*=%s*)%d+', '%1' .. tostring(math.floor(newValue)), 1)
                    fieldDone = true
                    inEntry = false
                elseif fieldName == 'shop' and line:match('%f[%a]shop%s*=%s*[\'"]') then
                    if newValue ~= '' then
                        processedLine = line:gsub("(%f[%a]shop%s*=%s*)['\"][^'\"]*['\"]", "%1'" .. newValue .. "'", 1)
                    else
                        processedLine = line:gsub(",?%s*%f[%a]shop%s*=%s*['\"][^'\"]*['\"]", '', 1)
                    end
                    fieldDone = true
                    inEntry = false
                end

                if braceDepth <= 0 and not fieldDone then
                    if fieldName == 'shop' and newValue ~= '' then
                        insertAfter = #lines + 1
                    end
                    fieldDone = true
                    inEntry = false
                end
            end
        end

        table.insert(lines, processedLine)
    end

    if insertAfter and fieldName == 'shop' and newValue ~= '' then
        table.insert(lines, insertAfter, string.format("        shop = '%s',", newValue))
    end

    local result = table.concat(lines, '\n')
    if result:sub(-1) == '\n' then result = result:sub(1, -2) end
    return result, fieldDone
end

-- ── Price & Shop Events ───────────────────────────────────────────────────────
RegisterNetEvent('mnc-vehiclecatalog:updateVehiclePrice', function(model, newPrice, vehicleName, zoneName)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local isAdmin = QBCore.Functions.HasPermission(src, 'admin')

    -- Only admins can edit prices
    if not isAdmin then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access Denied', description = 'Only admins can edit prices.', type = 'error' })
        return
    end

    model    = tostring(model):gsub('[^%w_]', '')
    newPrice = math.floor(tonumber(newPrice) or -1)

    if model == '' or newPrice < 0 or not QBShared.Vehicles[model] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Invalid data.', type = 'error' })
        return
    end

    local fileContent = readVehiclesFile()
    if not fileContent then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Read Error', description = 'Could not read local vehicles.lua', type = 'error' })
        return
    end

    local oldPrice = QBShared.Vehicles[model].price
    local newContent, replaced = patchVehiclesField(fileContent, model, 'price', newPrice)

    if not replaced then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Price field not found.', type = 'error' })
        return
    end

    local saved, writeErr = writeVehiclesFile(newContent)
    if not saved then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Write Error', description = writeErr, type = 'error' })
        return
    end

    QBShared.Vehicles[model].price = newPrice

    TriggerClientEvent('mnc-vehiclecatalog:priceUpdated', -1, model, newPrice)

    print(string.format('^2[mnc-vehiclecatalog]^7 %s updated price: %s $%s → $%s', GetPlayerName(src), model, oldPrice, newPrice))

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Price Updated',
        description = string.format('%s → $%s', vehicleName or model, newPrice),
        type = 'success',
        duration = 5000,
    })
end)

RegisterNetEvent('mnc-vehiclecatalog:updateVehicleShop', function(model, newShop, vehicleName)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access Denied', description = 'Admin only.', type = 'error' })
        return
    end

    model = tostring(model):gsub('[^%w_]', '')
    newShop = tostring(newShop):gsub('[^%w_]', '')

    if model == '' or not QBShared.Vehicles[model] then return end

    local fileContent = readVehiclesFile()
    if not fileContent then return end

    local newContent, patched = patchVehiclesField(fileContent, model, 'shop', newShop)
    if not patched then return end

    local saved = writeVehiclesFile(newContent)
    if not saved then return end

    QBShared.Vehicles[model].shop = newShop ~= '' and newShop or nil

    print(string.format('^2[mnc-vehiclecatalog]^7 %s changed shop: %s → %s', GetPlayerName(src), model, newShop ~= '' and newShop or '(none)'))

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Dealership Updated',
        description = string.format('%s → %s', vehicleName or model, newShop ~= '' and newShop or '(none)'),
        type = 'success'
    })
end)

-- ── Fallback Image Scanner ───────────────────────────────────────────────────
local CONCURRENT_LIMIT = 5
local REQUEST_TIMEOUT  = 10000
local RETRY_LIMIT      = 2

local activeScans = {}

local function checkImageExists(url, cb)
    local attempts = 0
    local function attempt()
        attempts = attempts + 1
        local done = false

        PerformHttpRequest(url, function(statusCode)
            if done then return end
            done = true
            if statusCode == 0 and attempts <= RETRY_LIMIT then
                Citizen.SetTimeout(1000 * attempts, attempt)
            else
                cb(statusCode ~= 404)
            end
        end, 'GET')

        Citizen.SetTimeout(REQUEST_TIMEOUT, function()
            if not done then
                done = true
                if attempts <= RETRY_LIMIT then
                    Citizen.SetTimeout(500, attempt)
                else
                    cb(true)
                end
            end
        end)
    end
    attempt()
end

local function sanitizeModel(model)
    return tostring(model):gsub('[^%w_]', '')
end

local function formatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    if seconds < 60 then
        return string.format('%ds', seconds)
    elseif seconds < 3600 then
        return string.format('%dm %ds', math.floor(seconds / 60), seconds % 60)
    else
        return string.format('%dh %dm', math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

local function buildProgressBar(pct)
    local filled = math.floor(pct / 5)
    return string.rep('█', filled) .. string.rep('░', 20 - filled)
end

local function pushProgressMenu(src, scan)
    local elapsed   = os.time() - scan.startTime
    local checked   = scan.checked
    local total     = scan.total
    local fallbacks = #scan.fallbackModels
    local pct       = total > 0 and math.floor((checked / total) * 100) or 0
    local rate      = elapsed > 1 and (checked / elapsed) or 0
    local remaining = (rate > 0 and checked < total) and math.floor((total - checked) / rate) or 0

    TriggerClientEvent('mnc-vehiclecatalog:openScanMenu', src, {
        id    = 'fallback_scan_progress',
        title = '🔍 Fallback Image Scanner',
        options = {
            { title = string.format('Progress: %d%%  [%s]', pct, buildProgressBar(pct)), description = string.format('%d of %d vehicles checked', checked, total), disabled = true },
            { title = string.format('✅ Valid images: %d', checked - fallbacks), description = 'Vehicles that resolved to a real image', disabled = true },
            { title = string.format('❌ Fallbacks found: %d', fallbacks), description = 'Vehicles that will use fallback.png', disabled = true },
            { title = string.format('⏱ Elapsed: %s', formatTime(elapsed)), description = string.format('Est. remaining: %s  |  Rate: %.1f/sec', formatTime(remaining), rate), disabled = true },
            { title = string.format('🔁 Active requests: %d / %d', scan.activeRequests, CONCURRENT_LIMIT), description = string.format('Queued: %d  |  Dispatched: %d', scan.total - scan.dispatched, scan.dispatched), disabled = true },
            { title = '🔄 Refresh', description = 'Pull latest progress into this menu', event = 'mnc-vehiclecatalog:requestProgressRefresh' },
            { title = '⛔ Cancel Scan', description = 'Stop the scan without saving', event = 'mnc-vehiclecatalog:requestCancel' },
        },
    })
end

RegisterNetEvent('mnc-vehiclecatalog:requestProgressRefresh', function()
    local src = source
    if activeScans[src] then
        pushProgressMenu(src, activeScans[src])
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'No Active Scan', description = 'The scan has already finished or was cancelled.', type = 'error' })
    end
end)

RegisterNetEvent('mnc-vehiclecatalog:requestCancel', function()
    local src = source
    if activeScans[src] then
        activeScans[src].cancelled = true
        activeScans[src] = nil
        TriggerClientEvent('mnc-vehiclecatalog:closeScanMenu', src)
        TriggerClientEvent('ox_lib:notify', src, { title = 'Scan Cancelled', description = 'Fallback scan was stopped. No file was saved.', type = 'error' })
    end
end)

-- ── Scanner Core Functions ───────────────────────────────────────────────────
local function checkModelChain(model, onComplete)
    local primaryUrl = Config.ImagePaths.primary:gsub('{model}', model)
    local g1url      = Config.ImagePaths.github1 and Config.ImagePaths.github1:gsub('{model}', model) or nil
    local g2url      = Config.ImagePaths.github2 and Config.ImagePaths.github2:gsub('{model}', model) or nil

    checkImageExists(primaryUrl, function(primaryOk)
        if primaryOk then
            onComplete(false)
            return
        end

        local function tryG2()
            if g2url then
                checkImageExists(g2url, function(g2Ok)
                    onComplete(not g2Ok)
                end)
            else
                onComplete(true)
            end
        end

        if g1url then
            checkImageExists(g1url, function(g1Ok)
                if g1Ok then onComplete(false) else tryG2() end
            end)
        else
            tryG2()
        end
    end)
end

local function processQueue(src, scan)
    while scan.activeRequests < CONCURRENT_LIMIT and scan.dispatched < scan.total and not scan.cancelled do
        scan.dispatched = scan.dispatched + 1
        scan.activeRequests = scan.activeRequests + 1

        local model = scan.models[scan.dispatched]

        checkModelChain(model, function(isFallback)
            if scan.cancelled then
                scan.activeRequests = scan.activeRequests - 1
                return
            end

            if isFallback then
                scan.fallbackModels[#scan.fallbackModels + 1] = model
            end

            scan.checked = scan.checked + 1
            scan.activeRequests = scan.activeRequests - 1

            processQueue(src, scan)

            if scan.checked >= scan.total and not scan.completed then
                scan.completed = true
                onScanComplete(src, scan)
            end
        end)
    end
end

function onScanComplete(src, scan)
    table.sort(scan.fallbackModels)

    local lines = {}
    for i = 1, #scan.fallbackModels do
        lines[#lines + 1] = string.format("    '%s',", scan.fallbackModels[i])
    end

    local output   = 'Config.VehicleSpawnCodes = {\n' .. table.concat(lines, '\n') .. '\n}\n'
    local fileName = 'fallback_vehicles.lua'
    SaveResourceFile(GetCurrentResourceName(), fileName, output, -1)

    local elapsed = os.time() - scan.startTime
    print(string.format('^2[mnc-vehiclecatalog]^7 Scan complete. %d/%d are fallbacks. Saved to %s in %s.', #scan.fallbackModels, scan.total, fileName, formatTime(elapsed)))

    TriggerClientEvent('mnc-vehiclecatalog:openScanMenu', src, {
        id    = 'fallback_scan_complete',
        title = '✅ Scan Complete',
        options = {
            { title = string.format('Scanned: %d vehicles', scan.total), description = string.format('Completed in %s', formatTime(elapsed)), disabled = true },
            { title = string.format('✅ Valid images: %d', scan.total - #scan.fallbackModels), description = 'These vehicles have real images', disabled = true },
            { title = string.format('❌ Fallback vehicles: %d', #scan.fallbackModels), description = 'These will use fallback.png', disabled = true },
            { title = '📁 File saved', description = string.format('resources/%s/fallback_vehicles.lua', GetCurrentResourceName()), disabled = true },
            { title = '✔ Close', description = 'Dismiss this menu', event = 'mnc-vehiclecatalog:closeScanMenu' },
        },
    })

    activeScans[src] = nil
end

-- ── Scan Commands ─────────────────────────────────────────────────────────────
lib.addCommand('scancatalog', {
    help = 'Check fallback scan progress',
}, function(source)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access Denied', description = 'Admin only.', type = 'error' })
        return
    end

    if activeScans[src] then
        pushProgressMenu(src, activeScans[src])
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'No Active Scan', description = 'Use /exportfallbackvehicles to start one.', type = 'error' })
    end
end)

lib.addCommand('exportfallbackvehicles', {
    help = 'Scans all vehicle images and exports fallback list',
}, function(source)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Access Denied', description = 'Admin only.', type = 'error' })
        return
    end

    if activeScans[src] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Scan Already Running', type = 'error' })
        return
    end

    local models = {}
    for model in pairs(QBShared.Vehicles) do
        local safe = sanitizeModel(model)
        if safe ~= '' then models[#models + 1] = safe end
    end

    if #models == 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'No Vehicles Found', type = 'error' })
        return
    end

    print(string.format('^3[mnc-vehiclecatalog]^7 Admin %s started fallback scan — %d vehicles.', GetPlayerName(src), #models))

    local scan = {
        startTime      = os.time(),
        models         = models,
        total          = #models,
        dispatched     = 0,
        checked        = 0,
        activeRequests = 0,
        fallbackModels = {},
        cancelled      = false,
        completed      = false,
    }
    activeScans[src] = scan

    TriggerClientEvent('ox_lib:notify', src, { title = 'Scan Started', description = 'Processing vehicles...', type = 'inform' })
    pushProgressMenu(src, scan)
    processQueue(src, scan)
end)

print('^2[mnc-vehiclecatalog-v2]^7 Server loaded successfully')