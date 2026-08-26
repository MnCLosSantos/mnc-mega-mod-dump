-- server.lua
local QBCore = exports['qb-core']:GetCoreObject()
local vehicleFile = 'vehiclesaves.lua'

-----------------------------------------------------------------
-- SAVE NEW VEHICLE (to vehiclesaves.lua)
-----------------------------------------------------------------
RegisterNetEvent('mnc-vehiclelua:saveVehicle', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not IsPlayerAceAllowed(src, 'command') and not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {title='Unauthorized', description='No permission', type='error'})
        return
    end

    local norm = {
        model = data.model:lower(),
        name  = data.name and data.name:lower():gsub("^%l", string.upper) or data.model:lower():gsub("^%l", string.upper),
        brand = data.brand or "Unknown",
        price = tonumber(data.price) or 0,
        category = data.category or "unknown",
        type = data.type or "automobile",
        shop = data.shop or "luxury"
    }

    local fmt = string.format([[

    {
        model = '%s',
        name = '%s',
        brand = '%s',
        price = %d,
        category = '%s',
        type = '%s',
        shop = '%s',
    },
    ]], norm.model, norm.name, norm.brand, norm.price, norm.category, norm.type, norm.shop)

    local path = ('%s/%s'):format(GetResourcePath(GetCurrentResourceName()), vehicleFile)
    local f = io.open(path, 'a')
    if f then
        f:write('\n'..fmt)
        f:close()
        TriggerClientEvent('ox_lib:notify', src, {title='Saved', description=('%s added'):format(norm.name), type='success'})
    else
        TriggerClientEvent('ox_lib:notify', src, {title='Error', description='Cannot write vehiclesaves.lua', type='error'})
    end
end)

-----------------------------------------------------------------
-- EDIT / REPLACE ONE VEHICLE IN qb-core/shared/vehicles.lua
-----------------------------------------------------------------
RegisterNetEvent('mnc-vehiclelua:replaceVehicle', function(oldModel, newData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not IsPlayerAceAllowed(src, 'command') and not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {title='Unauthorized', description='No permission', type='error'})
        return
    end

    local norm = {
        model = newData.model:lower(),
        name  = newData.name and newData.name:lower():gsub("^%l", string.upper) or newData.model:lower():gsub("^%l", string.upper),
        brand = newData.brand or "Unknown",
        price = tonumber(newData.price) or 0,
        category = newData.category or "unknown",
        type = newData.type or "automobile",
        shop = newData.shop or "luxury"
    }

    -----------------------------------------------------------------
    -- 1. Locate qb-core/shared/vehicles.lua
    -----------------------------------------------------------------
    local qbPath = GetResourcePath('qb-core') .. '/shared/vehicles.lua'
    local f = io.open(qbPath, 'r')
    if not f then
        TriggerClientEvent('ox_lib:notify', src, {title='Error', description='Cannot open vehicles.lua', type='error'})
        return
    end
    local content = f:read('*a')
    f:close()

    -----------------------------------------------------------------
    -- 2. Find the exact model line (case-insensitive)
    -----------------------------------------------------------------
    local modelPat = "model%s*=%s*['\"]"..oldModel:lower().."['\"]"
    local modelPos = content:find(modelPat)
    if not modelPos then
        TriggerClientEvent('ox_lib:notify', src, {title='Error', description='Vehicle not found', type='error'})
        return
    end

    -----------------------------------------------------------------
    -- 3. Walk backward to the opening `{` of this entry
    -----------------------------------------------------------------
    local blockStart = nil
    for i = modelPos, 1, -1 do
        local ch = content:sub(i,i)
        if ch == '{' then
            blockStart = i
            break
        end
    end
    if not blockStart then
        TriggerClientEvent('ox_lib:notify', src, {title='Error', description='Block start not found', type='error'})
        return
    end

    -----------------------------------------------------------------
    -- 4. Walk forward to the matching `}` (including optional comma)
    -----------------------------------------------------------------
    local depth = 0
    local blockEnd = nil
    for i = blockStart, #content do
        local ch = content:sub(i,i)
        if ch == '{' then depth = depth + 1
        elseif ch == '}' then
            depth = depth - 1
            if depth == 0 then
                blockEnd = i
                -- include trailing comma if present
                local after = content:find('[^,%s]', i+1)
                if after and content:sub(after-1,after-1) == ',' then
                    blockEnd = after - 1
                end
                break
            end
        end
    end
    if not blockEnd then
        TriggerClientEvent('ox_lib:notify', src, {title='Error', description='Block end not found', type='error'})
        return
    end

    -----------------------------------------------------------------
    -- 5. Preserve original indentation
    -----------------------------------------------------------------
    local oldBlock = content:sub(blockStart, blockEnd)
    local indent = oldBlock:match('^%s*') or '    '

    -----------------------------------------------------------------
    -- 6. Build the new block
    -----------------------------------------------------------------
    local newBlock = string.format([[%s{
        model = '%s',
        name = '%s',
        brand = '%s',
        price = %d,
        category = '%s',
        type = '%s',
        shop = '%s',
    },]], indent,
        norm.model, norm.name, norm.brand,
        norm.price, norm.category, norm.type, norm.shop)

    -----------------------------------------------------------------
    -- 7. Write the file back
    -----------------------------------------------------------------
    local newContent = content:sub(1, blockStart-1) .. newBlock .. content:sub(blockEnd+1)
    f = io.open(qbPath, 'w')
    if f then
        f:write(newContent)
        f:close()
        TriggerClientEvent('ox_lib:notify', src, {title='Success', description=('%s updated'):format(norm.name), type='success'})
    else
        TriggerClientEvent('ox_lib:notify', src, {title='Error', description='Write failed', type='error'})
    end
end)

-----------------------------------------------------------------
-- EXPORT ALL (chunked) → vehiclesaves.lua
-----------------------------------------------------------------
RegisterNetEvent('mnc-vehiclelua:exportChunk', function(chunk)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not IsPlayerAceAllowed(src, 'command') and not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {title='Unauthorized', description='No permission', type='error'})
        return
    end

    local path = ('%s/%s'):format(GetResourcePath(GetCurrentResourceName()), vehicleFile)
    local f = io.open(path, 'a')
    if not f then
        TriggerClientEvent('ox_lib:notify', src, {title='Error', description='Cannot open vehiclesaves.lua', type='error'})
        return
    end

    for _, v in ipairs(chunk) do
        local fmt = string.format([[
    {
        model = '%s',
        name = '%s',
        brand = '%s',
        price = %d,
        category = '%s',
        type = '%s',
        shop = '%s',
    },
    ]], v.model:lower(),
          v.name and v.name:lower():gsub("^%l", string.upper) or v.model:lower():gsub("^%l", string.upper),
          v.brand or "Unknown",
          tonumber(v.price) or 0,
          v.category or "unknown",
          v.type or "automobile",
          v.shop or "luxury")
        f:write('\n'..fmt)
    end
    f:close()

    TriggerClientEvent('ox_lib:notify', src, {title='Chunk saved', description=#chunk..' vehicles appended', type='info'})
end)

-----------------------------------------------------------------
-- CREATE vehiclelist.lua FROM CLIENT MODELS (admin only) + DUPLICATE WARNING
-----------------------------------------------------------------
local listFile = 'vehiclelist.lua'

RegisterNetEvent('mnc-vehiclelua:createVehicleList', function(allModels)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not IsPlayerAceAllowed(src, 'command') and not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {title='Unauthorized', description='No permission', type='error'})
        return
    end

    -----------------------------------------------------------------
    -- 1. Separate into in / not in QB-Core + count occurrences
    -----------------------------------------------------------------
    local inCore, notInCore = {}, {}
    local seen = {}               -- model → count
    local qbModels = {}
    local qbVehicles = QBCore.Shared.Vehicles or {}

    for _, v in pairs(qbVehicles) do
        if v.model then
            local m = v.model:lower()
            qbModels[m] = true
        end
    end

    for _, model in ipairs(allModels) do
        local m = model:lower()
        seen[m] = (seen[m] or 0) + 1

        if qbModels[m] then
            table.insert(inCore, m)
        else
            table.insert(notInCore, m)
        end
    end

    -----------------------------------------------------------------
    -- 2. Sort both sections
    -----------------------------------------------------------------
    table.sort(inCore)
    table.sort(notInCore)

    -----------------------------------------------------------------
    -- 3. Build the file line-by-line
    -----------------------------------------------------------------
    local lines = {
        '-- vehiclelist.lua  (generated by /vehiclelist)',
        '-- In QB-Core (' .. #inCore .. ')',
        ''
    }

    -- ---- In QB-Core -------------------------------------------------
    for i, model in ipairs(inCore) do
        local line = string.format('%-8d - %s', i, model)
        if seen[model] and seen[model] > 1 then
            line = line .. '   WARNING DUPLICATE SPAWNCODE'
        end
        table.insert(lines, line)
    end

    table.insert(lines, '')
    table.insert(lines, '-- NOT in QB-Core (' .. #notInCore .. ')')
    table.insert(lines, '')

    -- ---- Not in QB-Core ---------------------------------------------
    local offset = #inCore
    for i, model in ipairs(notInCore) do
        local line = string.format('%-8d - %s', i + offset, model)
        if seen[model] and seen[model] > 1 then
            line = line .. '   WARNING DUPLICATE SPAWNCODE'
        end
        table.insert(lines, line)
    end

    -----------------------------------------------------------------
    -- 4. Write (overwrite) the file
    -----------------------------------------------------------------
    local path = ('%s/%s'):format(GetResourcePath(GetCurrentResourceName()), listFile)
    local f = io.open(path, 'w')
    if f then
        f:write(table.concat(lines, '\n') .. '\n')
        f:close()
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'vehiclelist.lua',
            description = 'Created – ' .. (#inCore + #notInCore) .. ' models',
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Cannot write vehiclelist.lua',
            type = 'error'
        })
    end
end)

print("^2[mnc-vehiclemanager-v2]^7 Script loaded")