local QBCore = exports['qb-core']:GetCoreObject()

-- ─── Shared state (must be declared before any function that closes over it) ──
local installed        = {}
local installedByPlate = {}
local activeSounds     = {}
local playersInRange   = {}

-- ─── Database init ──────────────────────────────────────────

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_carplay_playlists` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `citizenid`  VARCHAR(50)  NOT NULL,
            `name`       VARCHAR(100) NOT NULL,
            `songs`      LONGTEXT     NOT NULL,
            `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_carplay_installs` (
            `plate`         VARCHAR(12)  NOT NULL,
            `skin_id`       VARCHAR(50)  NOT NULL,
            `item`          VARCHAR(50)  NOT NULL,
            `citizenid`     VARCHAR(50)  DEFAULT NULL,
            `offset_x`      FLOAT NOT NULL DEFAULT 0,
            `offset_y`      FLOAT NOT NULL DEFAULT 0,
            `offset_z`      FLOAT NOT NULL DEFAULT 0,
            `rot_x`         FLOAT NOT NULL DEFAULT 0,
            `rot_y`         FLOAT NOT NULL DEFAULT 0,
            `rot_z`         FLOAT NOT NULL DEFAULT 0,
            `prop_model_id` VARCHAR(50) NOT NULL DEFAULT 'impexp',
            `screen_offset_x` FLOAT NOT NULL DEFAULT 0,
            `screen_offset_y` FLOAT NOT NULL DEFAULT 0,
            `screen_offset_z` FLOAT NOT NULL DEFAULT 0,
            `screen_attached` TINYINT(1) NOT NULL DEFAULT 1,
            `prop_hidden`     TINYINT(1) NOT NULL DEFAULT 0,
            `worldui_enabled` TINYINT(1) NOT NULL DEFAULT 1,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local hasColumn = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'mnc_carplay_installs'
          AND COLUMN_NAME = 'prop_model_id'
    ]])
    if not hasColumn or hasColumn == 0 then
        MySQL.query.await(
            ("ALTER TABLE `mnc_carplay_installs` ADD COLUMN `prop_model_id` VARCHAR(50) NOT NULL DEFAULT '%s'"):format(Config.DefaultTabletProp)
        )
    end


    local screenColumns = {
        { name = "screen_offset_x", ddl = "FLOAT NOT NULL DEFAULT 0" },
        { name = "screen_offset_y", ddl = "FLOAT NOT NULL DEFAULT 0" },
        { name = "screen_offset_z", ddl = "FLOAT NOT NULL DEFAULT 0" },
        { name = "screen_attached", ddl = "TINYINT(1) NOT NULL DEFAULT 1" },
        { name = "prop_hidden",     ddl = "TINYINT(1) NOT NULL DEFAULT 0" },
        { name = "worldui_enabled", ddl = "TINYINT(1) NOT NULL DEFAULT 1" },
    }
    for _, col in ipairs(screenColumns) do
        local exists = MySQL.scalar.await([[
            SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'mnc_carplay_installs'
              AND COLUMN_NAME = ?
        ]], { col.name })
        if not exists or exists == 0 then
            MySQL.query.await(("ALTER TABLE `mnc_carplay_installs` ADD COLUMN `%s` %s"):format(col.name, col.ddl))
        end
    end

    loadInstallsFromDB()
end)

-- ─── Helpers ────────────────────────────────────────────────

local function getCitizenId(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

local function debugPrint(msg)
    if Config.Debug then print("^3[mnc-carplay/server]^7 " .. tostring(msg)) end
end

local function notify(src, title, description, type)
    TriggerClientEvent("ox_lib:notify", src, { title = title, description = description, type = type })
end

local function sanitizePlaybackUrl(url)
    if not url or url == "" then return url end
    local id = url:match("[?&]v=([%w%-_]+)") or url:match("youtu%.be/([%w%-_]+)")
    if id then
        return "https://www.youtube.com/watch?v=" .. id
    end
    return url -- not a recognisable YouTube link (e.g. SoundCloud) — leave as-is
end

local function urlEncode(str)
    if not str or str == "" then return "" end
    return (tostring(str):gsub("([^%w%-%_%.%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function buildOembedUrl(url)
    if url:find("youtu%.be") or url:find("youtube%.com") then
        return "https://www.youtube.com/oembed?url=" .. urlEncode(url) .. "&format=json"
    elseif url:find("soundcloud%.com") then
        return "https://soundcloud.com/oembed?url=" .. urlEncode(url) .. "&format=json"
    end
    return nil
end

local function resolveAndBroadcastTitle(label, url)
    local oembedUrl = buildOembedUrl(url)
    if not oembedUrl then return end

    PerformHttpRequest(oembedUrl, function(statusCode, responseText)
        if statusCode ~= 200 or not responseText or responseText == "" then return end

        local ok, data = pcall(json.decode, responseText)
        if not ok or not data or not data.title or data.title == "" then return end

        local snd = activeSounds[label]
        if not snd or snd.url ~= url then return end -- stale response, track has since changed
        if snd.title == data.title then return end

        snd.title = data.title
        TriggerClientEvent("mnc-carplay:client:nowPlayingUpdate", -1, snd.vehNetId, {
            url = snd.url, title = snd.title, playing = not snd.paused, paused = snd.paused or false,
        })
    end, "GET", "", { ["Accept"] = "application/json" })
end

local function getSkinById(id)
    for _, skin in ipairs(Config.CarplaySkins) do
        if skin.id == id then return skin end
    end
    return nil
end

local function getPropOptionById(id)
    for _, opt in ipairs(Config.TabletPropOptions) do
        if opt.id == id then return opt end
    end
    return nil
end

local function resolvePropModelId(id)
    if id and getPropOptionById(id) then return id end
    return Config.DefaultTabletProp
end

local function toBool(v, default)
    if v == nil then return default end
    if type(v) == "boolean" then return v end
    return v == 1 or v == "1" or v == true
end

local function defaultScreenOffset()
    return { x = Config.DefaultScreenOffset.x, y = Config.DefaultScreenOffset.y, z = Config.DefaultScreenOffset.z }
end

local function clampRadius(r)
    r = tonumber(r) or Config.DefaultRadius
    return math.max(Config.MinRadius, math.min(Config.MaxRadius, r))
end

local function trimPlate(plate)
    if not plate then return nil end
    plate = plate:match("^%s*(.-)%s*$")
    return plate ~= "" and plate or nil
end

local function vecToTable(v)
    return { x = v.x, y = v.y, z = v.z }
end

local function clampVec(v, lo, hi)
    v = v or {}
    return {
        x = math.max(lo, math.min(hi, tonumber(v.x) or 0)),
        y = math.max(lo, math.min(hi, tonumber(v.y) or 0)),
        z = math.max(lo, math.min(hi, tonumber(v.z) or 0)),
    }
end


local function getUnitLabel(netId)
    return Config.SoundLabel .. "_" .. tostring(netId)
end

function loadInstallsFromDB()
    local rows = MySQL.query.await("SELECT * FROM mnc_carplay_installs") or {}
    installedByPlate = {}
    for _, row in ipairs(rows) do
        installedByPlate[row.plate] = {
            skinId         = row.skin_id,
            item           = row.item,
            citizenid      = row.citizenid,
            offset         = { x = row.offset_x, y = row.offset_y, z = row.offset_z },
            rotation       = { x = row.rot_x, y = row.rot_y, z = row.rot_z },
            propModel      = resolvePropModelId(row.prop_model_id),
            screenOffset   = { x = row.screen_offset_x or 0, y = row.screen_offset_y or 0, z = row.screen_offset_z or 0 },
            screenAttached = toBool(row.screen_attached, true),
            propHidden     = toBool(row.prop_hidden, false),
            worldUiEnabled = toBool(row.worldui_enabled, true),
        }
    end
    debugPrint(("Loaded %d persisted Carplay install(s) from SQL"):format(#rows))
end

for _, skin in ipairs(Config.CarplaySkins) do
    QBCore.Functions.CreateUseableItem(skin.item, function(source, item)
        TriggerClientEvent("mnc-carplay:client:beginInstall", source, skin.id)
    end)
end

QBCore.Functions.CreateUseableItem(Config.RemovalTool, function(source, item)
    TriggerClientEvent("mnc-carplay:client:beginRemoval", source)
end)

RegisterNetEvent("mnc-carplay:server:registerInstall", function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not data or not data.netId or not data.skinId then return end

    local veh = NetworkGetEntityFromNetworkId(data.netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end

    local plate = trimPlate(GetVehicleNumberPlateText(veh))
    if not plate then
        notify(src, "Carplay", "Couldn't read that vehicle's plate.", "error")
        return
    end

    if installedByPlate[plate] then
        notify(src, "Carplay", "This vehicle already has a Carplay unit installed.", "error")
        return
    end

    local skin = getSkinById(data.skinId)
    if not skin then return end

    local removed = Player.Functions.RemoveItem(skin.item, 1)
    if not removed then
        notify(src, "Carplay", "You don't have that unit anymore.", "error")
        return
    end

    local offset         = vecToTable(Config.TabletPropOffset)
    local rotation       = vecToTable(Config.TabletPropRotation)
    local propModel      = Config.DefaultTabletProp
    local screenOffset   = defaultScreenOffset()
    local screenAttached = true  -- new installs start with the screen glued to the prop
    local propHidden     = false
    local worldUiEnabled = true
    local citizenid      = Player.PlayerData.citizenid

    MySQL.insert(
        "INSERT INTO mnc_carplay_installs (plate, skin_id, item, citizenid, offset_x, offset_y, offset_z, rot_x, rot_y, rot_z, prop_model_id, screen_offset_x, screen_offset_y, screen_offset_z, screen_attached, prop_hidden, worldui_enabled) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        {
            plate, skin.id, skin.item, citizenid, offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, propModel,
            screenOffset.x, screenOffset.y, screenOffset.z, screenAttached, propHidden, worldUiEnabled,
        }
    )

    installedByPlate[plate] = {
        skinId = skin.id, item = skin.item, citizenid = citizenid,
        offset = offset, rotation = rotation, propModel = propModel,
        screenOffset = screenOffset, screenAttached = screenAttached,
        propHidden = propHidden, worldUiEnabled = worldUiEnabled,
    }
    installed[data.netId] = {
        skinId = skin.id, item = skin.item, ownerSrc = src, plate = plate,
        offset = offset, rotation = rotation, propModel = propModel,
        screenOffset = screenOffset, screenAttached = screenAttached,
        propHidden = propHidden, worldUiEnabled = worldUiEnabled,
    }

    TriggerClientEvent("mnc-carplay:client:createUnit", -1, {
        netId = data.netId, skinId = skin.id, owner = src,
        offset = offset, rotation = rotation, propModel = propModel,
        screenOffset = screenOffset, screenAttached = screenAttached,
        propHidden = propHidden, worldUiEnabled = worldUiEnabled,
    })
    notify(src, "Carplay", "Installed (" .. skin.label .. ").", "success")
    debugPrint("Carplay unit installed on plate=" .. plate .. " (netId=" .. data.netId .. ") by " .. src)
end)

RegisterNetEvent("mnc-carplay:server:removeInstall", function(netId)
    local src = source
    local rec = installed[netId]
    if not rec then return end

    local label = getUnitLabel(netId)
    if activeSounds[label] then
        for playerId in pairs(playersInRange[label] or {}) do
            TriggerClientEvent("mnc-carplay:client:stopAudio", playerId, { label = label })
        end
        activeSounds[label] = nil
        playersInRange[label] = nil
    end

    installed[netId] = nil
    if rec.plate then
        installedByPlate[rec.plate] = nil
        MySQL.query("DELETE FROM mnc_carplay_installs WHERE plate = ?", { rec.plate })
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddItem(rec.item, 1)
    end

    TriggerClientEvent("mnc-carplay:client:removeUnit", -1, netId)
    notify(src, "Carplay", "Unit removed.", "success")
    debugPrint("Carplay unit removed from plate=" .. tostring(rec.plate) .. " (netId=" .. netId .. ") by " .. src)
end)


lib.callback.register("mnc-carplay:server:getInstallForPlate", function(source, netId, plate)
    plate = trimPlate(plate)
    if not plate or not netId then return nil end

    local rec = installedByPlate[plate]
    if not rec then return nil end

    installed[netId] = {
        skinId = rec.skinId, item = rec.item, ownerSrc = nil, plate = plate,
        offset = rec.offset, rotation = rec.rotation, propModel = rec.propModel,
        screenOffset = rec.screenOffset or defaultScreenOffset(),
        screenAttached = rec.screenAttached, propHidden = rec.propHidden, worldUiEnabled = rec.worldUiEnabled,
    }

    debugPrint(("getInstallForPlate: src=%s netId=%s plate=%s returning rotation=(%.1f,%.1f,%.1f) propModel=%s"):format(
        tostring(source), tostring(netId), plate,
        (rec.rotation and rec.rotation.x) or 0, (rec.rotation and rec.rotation.y) or 0, (rec.rotation and rec.rotation.z) or 0,
        tostring(rec.propModel)))

    return {
        skinId = rec.skinId, offset = rec.offset, rotation = rec.rotation, propModel = rec.propModel,
        screenOffset = rec.screenOffset or defaultScreenOffset(),
        screenAttached = rec.screenAttached, propHidden = rec.propHidden, worldUiEnabled = rec.worldUiEnabled,
    }
end)


RegisterNetEvent("mnc-carplay:server:savePosition", function(data)
    local src = source
    if not data or not data.netId then
        debugPrint("savePosition: rejected — missing data/netId from src=" .. tostring(source))
        return
    end

    debugPrint(("savePosition: src=%s netId=%s RAW rotation in=(%s,%s,%s) propModel in=%s"):format(
        tostring(src), tostring(data.netId),
        tostring(data.rotation and data.rotation.x), tostring(data.rotation and data.rotation.y), tostring(data.rotation and data.rotation.z),
        tostring(data.propModel)
    ))

    local rec = installed[data.netId]
    if not rec or not rec.plate then
        debugPrint("savePosition: no installed record for netId=" .. tostring(data.netId) .. " — ignoring")
        notify(src, "Carplay", "No installed unit found on this vehicle.", "error")
        return
    end

    local offset    = clampVec(data.offset, Config.PositionRange.offset[1], Config.PositionRange.offset[2])
    local rotation  = clampVec(data.rotation, Config.PositionRange.rotation[1], Config.PositionRange.rotation[2])
    local propModel = resolvePropModelId(data.propModel or rec.propModel)


    local screenOffset   = clampVec(data.screenOffset or rec.screenOffset, Config.ScreenOffsetRange[1], Config.ScreenOffsetRange[2])
    local screenAttached = toBool(data.screenAttached, toBool(rec.screenAttached, true))
    local propHidden     = toBool(data.propHidden, toBool(rec.propHidden, false))
    local worldUiEnabled = toBool(data.worldUiEnabled, toBool(rec.worldUiEnabled, true))

    if rotation.x ~= data.rotation.x or rotation.y ~= data.rotation.y or rotation.z ~= data.rotation.z then
        debugPrint(("savePosition: ^1rotation CHANGED by clampVec^7 in=(%s,%s,%s) out=(%.1f,%.1f,%.1f) range=[%s,%s]"):format(
            tostring(data.rotation.x), tostring(data.rotation.y), tostring(data.rotation.z),
            rotation.x, rotation.y, rotation.z,
            tostring(Config.PositionRange.rotation[1]), tostring(Config.PositionRange.rotation[2])
        ))
    end

    MySQL.query(
        "UPDATE mnc_carplay_installs SET offset_x = ?, offset_y = ?, offset_z = ?, rot_x = ?, rot_y = ?, rot_z = ?, prop_model_id = ?, " ..
        "screen_offset_x = ?, screen_offset_y = ?, screen_offset_z = ?, screen_attached = ?, prop_hidden = ?, worldui_enabled = ? WHERE plate = ?",
        {
            offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, propModel,
            screenOffset.x, screenOffset.y, screenOffset.z, screenAttached, propHidden, worldUiEnabled,
            rec.plate,
        }
    )

    rec.offset         = offset
    rec.rotation       = rotation
    rec.propModel      = propModel
    rec.screenOffset   = screenOffset
    rec.screenAttached = screenAttached
    rec.propHidden     = propHidden
    rec.worldUiEnabled = worldUiEnabled
    if installedByPlate[rec.plate] then
        installedByPlate[rec.plate].offset         = offset
        installedByPlate[rec.plate].rotation       = rotation
        installedByPlate[rec.plate].propModel      = propModel
        installedByPlate[rec.plate].screenOffset   = screenOffset
        installedByPlate[rec.plate].screenAttached = screenAttached
        installedByPlate[rec.plate].propHidden     = propHidden
        installedByPlate[rec.plate].worldUiEnabled = worldUiEnabled
    end

    debugPrint(("savePosition: broadcasting positionUpdated to ALL clients for netId=%s rotation=(%.1f,%.1f,%.1f) propModel=%s screenAttached=%s propHidden=%s worldUiEnabled=%s"):format(
        tostring(data.netId), rotation.x, rotation.y, rotation.z, propModel, tostring(screenAttached), tostring(propHidden), tostring(worldUiEnabled)))
    TriggerClientEvent("mnc-carplay:client:positionUpdated", -1, data.netId, {
        offset = offset, rotation = rotation, propModel = propModel,
        screenOffset = screenOffset, screenAttached = screenAttached,
        propHidden = propHidden, worldUiEnabled = worldUiEnabled,
    })
    notify(src, "Carplay", "Prop position saved.", "success")
    debugPrint(("Position saved for plate=%s offset=(%.2f,%.2f,%.2f) rot=(%.1f,%.1f,%.1f) propModel=%s")
        :format(rec.plate, offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, propModel))
end)

local function getVehicleCoords(vehNetId)
    local veh = NetworkGetEntityFromNetworkId(vehNetId)
    if veh and veh ~= 0 and DoesEntityExist(veh) then
        return GetEntityCoords(veh)
    end
    return nil
end

local function getElapsed(snd)
    if not snd.startedAt then return 0 end
    local pausedDuration = snd.pausedDuration or 0
    local now = (snd.paused and snd.pausedAt) or GetGameTimer()
    local elapsed = (now - snd.startedAt - pausedDuration) / 1000.0
    return elapsed > 0 and elapsed or 0
end

local function sendStart(playerId, label, snd)
    TriggerClientEvent("mnc-carplay:client:startAudio", playerId, {
        label    = label,
        url      = snd.url,
        volume   = snd.volume,
        radius   = snd.radius,
        position = getElapsed(snd),
        paused   = snd.paused or false,
    })
end

local function sendStop(playerId, label)
    TriggerClientEvent("mnc-carplay:client:stopAudio", playerId, { label = label })
end

-- Fully stops a sound: tells every player currently marked in-range to kill
-- their local playback, clears our server-side bookkeeping for the label,
-- and (if we know which vehicle it belonged to) tells everyone the
-- "now playing" state is gone. Used both for explicit stop requests and by
-- the self-healing check in syncRange() below.
local function stopSound(label, vehNetId)
    for playerId in pairs(playersInRange[label] or {}) do
        sendStop(playerId, label)
    end
    activeSounds[label] = nil
    playersInRange[label] = nil

    if vehNetId then
        TriggerClientEvent("mnc-carplay:client:nowPlayingUpdate", -1, vehNetId, {
            url = "", title = "", playing = false, paused = false,
        })
    end
end

local function syncRange()
    for label, snd in pairs(activeSounds) do
        local srcCoords = getVehicleCoords(snd.vehNetId)
        if srcCoords then
            local radius = snd.radius or Config.DefaultRadius
            playersInRange[label] = playersInRange[label] or {}
            local inRange = playersInRange[label]

            for _, strId in ipairs(GetPlayers()) do
                local playerId = tonumber(strId)
                local ped = GetPlayerPed(playerId)
                if ped and ped ~= 0 then
                    local dist  = #(GetEntityCoords(ped) - srcCoords)
                    local wasIn = inRange[playerId] or false
                    local limit = wasIn and (radius + (Config.RangeHysteresis or 0)) or radius
                    local within = dist <= limit

                    if within and not wasIn then
                        inRange[playerId] = true
                        sendStart(playerId, label, snd)
                    elseif not within and wasIn then
                        inRange[playerId] = nil
                        sendStop(playerId, label)
                    end
                end
            end
        else
            -- The vehicle no longer resolves anywhere on the server -- stored
            -- in a garage (qb-garages or otherwise), despawned, etc. Stop the
            -- sound outright instead of leaving it dangling for whoever was
            -- already in range. This also caps how often getVehicleCoords()
            -- (and its NetworkGetEntityFromNetworkId call) gets polled for a
            -- dead netId to once, instead of every RangeCheckInterval forever.
            debugPrint("syncRange: vehicle netId=" .. tostring(snd.vehNetId) .. " no longer resolvable — stopping label=" .. label)
            stopSound(label, snd.vehNetId)
        end
    end
end

CreateThread(function()
    while true do
        Wait(Config.RangeCheckInterval or 500)
        if next(activeSounds) then
            syncRange()
        end
    end
end)

-- ─── qb-garages integration (best-effort) ──────────────────────────
-- qb-garages (and most forks/rewrites) fire this server event when a
-- vehicle is stored, but the exact payload shape has drifted across
-- versions, so we defensively check a few common field names for the
-- plate. If this never fires for your garage script, the syncRange()
-- fallback above still catches it -- getVehicleCoords() returns nil once
-- the vehicle entity is actually gone, which stops the audio within one
-- RangeCheckInterval regardless of which garage resource deleted it.
AddEventHandler("qb-garages:server:storeVehicle", function(data)
    local plate = data and (data.plate or (data.vehicle and data.vehicle.plate) or (data.props and data.props.plate))
    plate = trimPlate(plate)
    if not plate then return end

    for netId, rec in pairs(installed) do
        if rec.plate == plate then
            local label = getUnitLabel(netId)
            if activeSounds[label] then
                debugPrint("qb-garages:server:storeVehicle: plate=" .. plate .. " (netId=" .. netId .. ") stored — stopping Carplay audio")
                stopSound(label, netId)
            end
            break
        end
    end
end)

RegisterNetEvent("mnc-carplay:server:playUrl", function(data)
    local src = source
    if not data or not data.netId then return end
    local rec = installed[data.netId]
    if not rec then return end

    local url = sanitizePlaybackUrl(data.url)
    if not url or url == "" then return end

    local label  = getUnitLabel(data.netId)
    local volume = data.volume or Config.DefaultVolume
    local radius = clampRadius(data.radius)

    activeSounds[label] = {
        url            = url,
        title          = url, -- placeholder until reportTrackMeta lands the real oEmbed title (see below)
        volume         = volume,
        radius         = radius,
        vehNetId       = data.netId,
        startedAt      = GetGameTimer(),
        paused         = false,
        pausedAt       = nil,
        pausedDuration = 0,
    }

    playersInRange[label] = {}
    syncRange()

    local artwork = ""
    local videoId = url:match("v=([%w%-_]+)") or url:match("youtu%.be/([%w%-_]+)")
    if videoId then
        artwork = "https://img.youtube.com/vi/" .. videoId .. "/mqdefault.jpg"
    end

    for playerId in pairs(playersInRange[label]) do
        TriggerClientEvent("mnc-carplay:client:songStarted", playerId, {
            label = label, url = url, title = url, artwork = artwork,
        })
    end

    TriggerClientEvent("mnc-carplay:client:nowPlayingUpdate", -1, data.netId, {
        url = url, title = url, playing = true, paused = false,
    })

    resolveAndBroadcastTitle(label, url)

    debugPrint("Playing '" .. url .. "' label=" .. label .. " radius=" .. tostring(radius))
end)


RegisterNetEvent("mnc-carplay:server:reportTrackMeta", function(data)
    if not data or not data.netId or not data.title or data.title == "" then return end
    local label = getUnitLabel(data.netId)
    local snd = activeSounds[label]
    if not snd then return end

    if data.url and data.url ~= snd.url then return end

    snd.title = data.title
    TriggerClientEvent("mnc-carplay:client:nowPlayingUpdate", -1, data.netId, {
        url = snd.url, title = snd.title, playing = not snd.paused, paused = snd.paused or false,
    })
end)

RegisterNetEvent("mnc-carplay:server:stop", function(data)
    local label = data and data.label
    if label and activeSounds[label] then
        stopSound(label, activeSounds[label].vehNetId)
    end
end)

RegisterNetEvent("mnc-carplay:server:setVolume", function(data)
    local label = data and data.label
    local vol   = tonumber(data and data.volume)
    if not label or not vol or not activeSounds[label] then return end
    activeSounds[label].volume = vol
    for playerId in pairs(playersInRange[label] or {}) do
        TriggerClientEvent("mnc-carplay:client:setVolume", playerId, { label = label, volume = vol })
    end
end)

RegisterNetEvent("mnc-carplay:server:setRadius", function(data)
    local label = data and data.label
    if not label or not activeSounds[label] then return end
    local r = clampRadius(data.radius)
    activeSounds[label].radius = r
    for playerId in pairs(playersInRange[label] or {}) do
        TriggerClientEvent("mnc-carplay:client:setRadius", playerId, { label = label, radius = r })
    end
    syncRange()
end)

RegisterNetEvent("mnc-carplay:server:pauseResume", function(data)
    local label = data and data.label
    local snd   = label and activeSounds[label]
    if not snd then return end

    if snd.paused then
        snd.pausedDuration = (snd.pausedDuration or 0) + (GetGameTimer() - (snd.pausedAt or GetGameTimer()))
        snd.paused   = false
        snd.pausedAt = nil
    else
        snd.paused   = true
        snd.pausedAt = GetGameTimer()
    end

    for playerId in pairs(playersInRange[label] or {}) do
        TriggerClientEvent("mnc-carplay:client:pauseResume", playerId, { label = label, paused = snd.paused })
    end

    TriggerClientEvent("mnc-carplay:client:nowPlayingUpdate", -1, snd.vehNetId, {
        url = snd.url, title = snd.title or snd.url, playing = not snd.paused, paused = snd.paused,
    })
end)

RegisterNetEvent("mnc-carplay:server:seek", function(data)
    local label    = data and data.label
    local position = tonumber(data and data.position)
    local snd      = label and activeSounds[label]
    if not snd or not position then return end

    position = math.max(0, position)
    snd.startedAt = GetGameTimer() - (position * 1000)
    if snd.paused then
        snd.pausedAt = GetGameTimer()
        snd.pausedDuration = 0
    end

    for playerId in pairs(playersInRange[label] or {}) do
        TriggerClientEvent("mnc-carplay:client:seek", playerId, { label = label, position = position })
    end
end)


lib.callback.register("mnc-carplay:server:getState", function(source, netId)
    local rec = installed[netId]
    if not rec then return nil end

    local label = getUnitLabel(netId)
    local snd = activeSounds[label]
    if not snd then
        return { skinId = rec.skinId }
    end

    return {
        skinId   = rec.skinId,
        url      = snd.url,
        volume   = math.ceil(snd.volume * 100),
        radius   = snd.radius,
        paused   = snd.paused or false,
        position = getElapsed(snd),
    }
end)


RegisterNetEvent("mnc-carplay:server:requestSync", function()
    local src = source
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pCoords = GetEntityCoords(ped)

    for netId, rec in pairs(installed) do
        TriggerClientEvent("mnc-carplay:client:createUnit", src, {
            netId = netId, skinId = rec.skinId, owner = rec.ownerSrc,
            offset = rec.offset, rotation = rec.rotation, propModel = rec.propModel,
            screenOffset = rec.screenOffset or defaultScreenOffset(),
            screenAttached = rec.screenAttached, propHidden = rec.propHidden, worldUiEnabled = rec.worldUiEnabled,
        })
    end


    -- its broadcast radius.
    for label, snd in pairs(activeSounds) do
        TriggerClientEvent("mnc-carplay:client:nowPlayingUpdate", src, snd.vehNetId, {
            url = snd.url, title = snd.title or snd.url, playing = not snd.paused, paused = snd.paused or false,
        })
    end

    for label, snd in pairs(activeSounds) do
        local srcCoords = getVehicleCoords(snd.vehNetId)
        if srcCoords and #(pCoords - srcCoords) <= (snd.radius or Config.DefaultRadius) then
            playersInRange[label] = playersInRange[label] or {}
            playersInRange[label][src] = true
            sendStart(src, label, snd)
        end
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    for _, inRange in pairs(playersInRange) do
        inRange[src] = nil
    end
end)

-- ─── Playlists ──────────────────────────────────────────────

lib.callback.register("mnc-carplay:server:getPlaylists", function(source)
    local cid = getCitizenId(source)
    if not cid then return {} end

    local rows = MySQL.query.await(
        "SELECT id, name, songs FROM mnc_carplay_playlists WHERE citizenid = ? ORDER BY created_at DESC",
        { cid }
    )

    local playlists = {}
    for _, row in ipairs(rows or {}) do
        playlists[#playlists + 1] = { id = row.id, name = row.name, songs = json.decode(row.songs) or {} }
    end
    return playlists
end)

RegisterNetEvent("mnc-carplay:server:savePlaylist", function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end

    local name  = tostring(data.name or "Playlist"):sub(1, 100)
    local songs = data.songs or {}
    if #songs > Config.MaxSongsPerPlaylist then
        songs = { table.unpack(songs, 1, Config.MaxSongsPerPlaylist) }
    end

    local count = MySQL.scalar.await(
        "SELECT COUNT(*) FROM mnc_carplay_playlists WHERE citizenid = ?", { cid }
    )
    if (count or 0) >= Config.MaxPlaylists then
        notify(src, "Carplay", "Max playlists reached (" .. Config.MaxPlaylists .. ").", "error")
        return
    end

    MySQL.insert(
        "INSERT INTO mnc_carplay_playlists (citizenid, name, songs) VALUES (?, ?, ?)",
        { cid, name, json.encode(songs) }
    )

    local rows = MySQL.query.await(
        "SELECT id, name, songs FROM mnc_carplay_playlists WHERE citizenid = ? ORDER BY created_at DESC",
        { cid }
    )
    local playlists = {}
    for _, row in ipairs(rows or {}) do
        playlists[#playlists + 1] = { id = row.id, name = row.name, songs = json.decode(row.songs) or {} }
    end

    TriggerClientEvent("mnc-carplay:client:playlistSaved", src, playlists)
    debugPrint("Playlist saved for " .. cid .. ": " .. name)
end)

RegisterNetEvent("mnc-carplay:server:deletePlaylist", function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    MySQL.query("DELETE FROM mnc_carplay_playlists WHERE id = ? AND citizenid = ?", { data.id, cid })
    debugPrint("Playlist " .. tostring(data.id) .. " deleted for " .. cid)
end)

RegisterNetEvent("mnc-carplay:server:updatePlaylist", function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end

    local id    = tonumber(data.id)
    local songs = data.songs or {}
    if not id then return end
    if #songs > Config.MaxSongsPerPlaylist then
        songs = { table.unpack(songs, 1, Config.MaxSongsPerPlaylist) }
    end

    MySQL.query(
        "UPDATE mnc_carplay_playlists SET songs = ? WHERE id = ? AND citizenid = ?",
        { json.encode(songs), id, cid }
    )

    local rows = MySQL.query.await(
        "SELECT id, name, songs FROM mnc_carplay_playlists WHERE citizenid = ? ORDER BY created_at DESC",
        { cid }
    )
    local playlists = {}
    for _, row in ipairs(rows or {}) do
        playlists[#playlists + 1] = { id = row.id, name = row.name, songs = json.decode(row.songs) or {} }
    end

    TriggerClientEvent("mnc-carplay:client:playlistUpdated", src, playlists)
    debugPrint("Playlist " .. id .. " updated for " .. cid .. " (" .. #songs .. " songs)")
end)