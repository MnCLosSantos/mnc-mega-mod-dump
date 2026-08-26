local QBCore = exports['qb-core']:GetCoreObject()

-- ─── Database init ──────────────────────────────────────────

MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_ppod_playlists` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `citizenid`  VARCHAR(50)  NOT NULL,
            `name`       VARCHAR(100) NOT NULL,
            `songs`      LONGTEXT     NOT NULL,
            `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- ─── Helpers ────────────────────────────────────────────────

local function getCitizenId(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

local function debugPrint(msg)
    if Config.Debug then print("^3[mnc-ppod/server]^7 " .. tostring(msg)) end
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
    return url -- not a recognisable YouTube link (e.g. SoundCloud) -- leave as-is
end

local activeSounds = {}

local playersInRange = {}


local syncRange


local openSessions = {}

local function getItemBattery(item)
    if not Config.BatteryEnabled then return nil end
    return (item.info and item.info.battery) or Config.BatteryMax
end


local function setItemBattery(Player, slot, battery)
    local item = Player.Functions.GetItemBySlot(slot)
    if not item then return false end
    item.info = item.info or {}
    item.info.battery = math.max(0, math.min(Config.BatteryMax, battery))
    Player.PlayerData.items[slot] = item
    Player.Functions.SetPlayerData("items", Player.PlayerData.items)
    return true, item.info.battery
end

for _, skin in ipairs(Config.iPodSkins) do
    QBCore.Functions.CreateUseableItem(skin.item, function(source, item)
        local battery = getItemBattery(item)

        if Config.BatteryEnabled and battery <= 0 then
            notify(source, "Ppod", "This ppod's battery is dead — recharge it with a ppod charger first.", "error")
            return
        end

        openSessions[source] = { slot = item.slot, itemName = skin.item, battery = battery or Config.BatteryMax }
        TriggerClientEvent("mnc-ppod:client:openIPod", source, skin.id, battery)
    end)
end


RegisterNetEvent("mnc-ppod:server:closeIPod", function()
    openSessions[source] = nil
end)



for _, skin in ipairs(Config.HeadphoneSkins) do
    QBCore.Functions.CreateUseableItem(skin.item, function(source, item)
        TriggerClientEvent("mnc-ppod:client:toggleHeadphones", source, skin)
    end)
end



if Config.BatteryEnabled then
    CreateThread(function()
        while true do
            Wait(Config.BatteryDrainInterval)
            for source, session in pairs(openSessions) do
                local Player = QBCore.Functions.GetPlayer(source)
                if not Player then
                    openSessions[source] = nil
                else
                    local wasLow = session.battery <= Config.BatteryLowWarning
                    local newBattery = math.max(0, session.battery - Config.BatteryDrainAmount)
                    local ok, persisted = setItemBattery(Player, session.slot, newBattery)

                    if not ok then
                        -- Item no longer exists in that slot (dropped/traded) — stop draining.
                        openSessions[source] = nil
                    else
                        session.battery = persisted
                        TriggerClientEvent("mnc-ppod:client:batteryUpdate", source, persisted)

                        if persisted <= 0 then
                            TriggerClientEvent("mnc-ppod:client:batteryDead", source)
                            openSessions[source] = nil
                        elseif persisted <= Config.BatteryLowWarning and not wasLow then
                            notify(source, "Ppod", "Battery running low (" .. persisted .. "%).", "warning")
                        end
                    end
                end
            end
        end
    end)
end



QBCore.Functions.CreateUseableItem(Config.ChargerItem, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local ppodItems = {}
    for _, skin in ipairs(Config.iPodSkins) do
        for _, invItem in pairs(Player.Functions.GetItemsByName(skin.item) or {}) do
            ppodItems[#ppodItems + 1] = {
                slot    = invItem.slot,
                label   = "Ppod (" .. skin.label .. ")",
                battery = getItemBattery(invItem) or Config.BatteryMax,
            }
        end
    end

    if #ppodItems == 0 then
        notify(source, "Ppod Charger", "You don't have any ppods to charge.", "error")
        return
    end

    TriggerClientEvent("mnc-ppod:client:openChargeMenu", source, ppodItems, item.slot)
end)

RegisterNetEvent("mnc-ppod:server:chargePpod", function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local chargerItem = Player.Functions.GetItemBySlot(data.chargerSlot)
    if not chargerItem or chargerItem.name ~= Config.ChargerItem then
        notify(src, "Ppod Charger", "You no longer have a charger.", "error")
        return
    end

    local targetItem = Player.Functions.GetItemBySlot(data.slot)
    if not targetItem then
        notify(src, "Ppod Charger", "That ppod is gone.", "error")
        return
    end

    local ok, newBattery = setItemBattery(Player, data.slot, Config.ChargeAmount)
    if not ok then
        notify(src, "Ppod Charger", "Couldn't charge that ppod.", "error")
        return
    end

    local session = openSessions[src]
    if session and session.slot == data.slot then
        session.battery = newBattery
        TriggerClientEvent("mnc-ppod:client:batteryUpdate", src, newBattery)
    end

    notify(src, "Ppod Charger", "Charged to " .. newBattery .. "%.", "success")
end)


local speakers = {}
local nextSpeakerId = 1

QBCore.Functions.CreateUseableItem(Config.SpeakerItem, function(source, item)
    TriggerClientEvent("mnc-ppod:client:placeSpeaker", source)
end)

RegisterNetEvent("mnc-ppod:server:registerSpeaker", function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end


    local removed = Player.Functions.RemoveItem(Config.SpeakerItem, 1)
    if not removed then
        notify(src, "Ppod Speaker", "You don't have a speaker to place.", "error")
        return
    end

    local id = nextSpeakerId
    nextSpeakerId = nextSpeakerId + 1

    speakers[id] = {
        coords = vector3(data.coords.x, data.coords.y, data.coords.z),
        netId  = data.netId,
        owner  = src,
    }

    TriggerClientEvent("mnc-ppod:client:createSpeaker", -1, id, data.coords, data.netId, src)
    debugPrint("Speaker #" .. id .. " placed by " .. src)
end)

RegisterNetEvent("mnc-ppod:server:removeSpeaker", function(id)
    local src = source
    local speaker = speakers[id]
    if not speaker then return end
    if speaker.owner ~= src then
        notify(src, "Ppod Speaker", "You didn't place this speaker.", "error")
        return
    end

    local label = "speaker_" .. id
    if activeSounds[label] then
        for playerId in pairs(playersInRange[label] or {}) do
            TriggerClientEvent("mnc-ppod:client:stopVehicleAudio", playerId, { label = label })
        end
        activeSounds[label] = nil
        playersInRange[label] = nil
    end

    speakers[id] = nil
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddItem(Config.SpeakerItem, 1)
    end
    TriggerClientEvent("mnc-ppod:client:removeSpeaker", -1, id)
end)

RegisterNetEvent("mnc-ppod:server:connectSpeaker", function(data)
    local src = source
    local speaker = speakers[data.speakerId]
    if not speaker then return end

    local label = "speaker_" .. data.speakerId

    playersInRange[label] = playersInRange[label] or {}


    if data.url and data.url ~= "" then
        activeSounds[label] = {
            url            = sanitizePlaybackUrl(data.url),
            volume         = data.volume and (data.volume / 100) or Config.DefaultVolume,
            radius         = Config.SpeakerRadius,
            coords         = { x = speaker.coords.x, y = speaker.coords.y, z = speaker.coords.z },
            startedAt      = GetGameTimer() - ((tonumber(data.position) or 0) * 1000),
            paused         = data.paused or false,
            pausedAt       = data.paused and GetGameTimer() or nil,
            pausedDuration = 0,
        }
        syncRange()
    end

    TriggerClientEvent("mnc-ppod:client:speakerConnected", src, data.speakerId)
    debugPrint(src .. " connected to speaker #" .. data.speakerId)
end)

RegisterNetEvent("mnc-ppod:server:disconnectSpeaker", function(speakerId)
    local src = source
    local label = "speaker_" .. speakerId
    if activeSounds[label] then
        for playerId in pairs(playersInRange[label] or {}) do
            TriggerClientEvent("mnc-ppod:client:stopVehicleAudio", playerId, { label = label })
        end
        activeSounds[label] = nil
        playersInRange[label] = nil
    end
    TriggerClientEvent("mnc-ppod:client:speakerDisconnected", src, speakerId)
end)



local function getSourceCoords(snd)
    if snd.coords then
        return vector3(snd.coords.x, snd.coords.y, snd.coords.z)
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
    TriggerClientEvent("mnc-ppod:client:startVehicleAudio", playerId, {
        label    = label,
        url      = snd.url,
        volume   = snd.volume,
        radius   = snd.radius,
        position = getElapsed(snd),
        paused   = snd.paused or false,
    })
end

local function sendStop(playerId, label)
    TriggerClientEvent("mnc-ppod:client:stopVehicleAudio", playerId, { label = label })
end

syncRange = function()
    for label, snd in pairs(activeSounds) do
        local srcCoords = getSourceCoords(snd)
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
        end
    end
end

CreateThread(function()
    while true do
        Wait(Config.RangeCheckInterval or 1000)
        if next(activeSounds) then
            syncRange()
        end
    end
end)

-- Only ever called by a client relaying its ppod's playback to a
-- connected speaker (see client.lua's playFromNui) — always carries a
-- speakerId, never a raw vehicle netId/coords.
RegisterNetEvent("mnc-ppod:server:playUrl", function(data)
    local src    = source
    local url    = sanitizePlaybackUrl(data.url)
    local volume = data.volume or Config.DefaultVolume
    local label  = data.label

    if not url or url == "" or not data.speakerId then return end

    local speaker = speakers[data.speakerId]
    if not speaker then return end

    local coords = { x = speaker.coords.x, y = speaker.coords.y, z = speaker.coords.z }
    local radius = Config.SpeakerRadius

    activeSounds[label] = {
        url            = url,
        volume         = volume,
        radius         = radius,
        coords         = coords,
        startedAt      = GetGameTimer(),
        paused         = false,
        pausedAt       = nil,
        pausedDuration = 0,
    }
    playersInRange[label] = {}

    syncRange()

    debugPrint("Playing '" .. url .. "' label=" .. label .. " radius=" .. tostring(radius))

    -- Try to resolve a YouTube thumbnail as artwork
    local artwork = ""
    local videoId = url:match("v=([%w%-_]+)") or url:match("youtu%.be/([%w%-_]+)")
    if videoId then
        artwork = "https://img.youtube.com/vi/" .. videoId .. "/mqdefault.jpg"
    end

    -- Notify requesting client's NUI so the "now playing" UI updates
    TriggerClientEvent("mnc-ppod:client:songStarted", src, {
        url     = url,
        title   = url,
        artwork = artwork,
    })
end)

RegisterNetEvent("mnc-ppod:server:stop", function(data)
    local label = data.label
    if activeSounds[label] then
        for playerId in pairs(playersInRange[label] or {}) do
            sendStop(playerId, label)
        end
        activeSounds[label] = nil
        playersInRange[label] = nil
    end
end)


RegisterNetEvent("mnc-ppod:server:setVolume", function(data)
    local label = data.label
    local vol   = tonumber(data.volume)
    if not label or not vol or not activeSounds[label] then return end
    activeSounds[label].volume = vol
    for playerId in pairs(playersInRange[label] or {}) do
        TriggerClientEvent("mnc-ppod:client:setVolume", playerId, { label = label, volume = vol })
    end
end)

RegisterNetEvent("mnc-ppod:server:setRadius", function(data)
    local label = data.label
    local r     = tonumber(data.radius)
    if not label or not r or not activeSounds[label] then return end
    activeSounds[label].radius = r

    syncRange()
end)


RegisterNetEvent("mnc-ppod:server:pauseResume", function(data)
    local label = data.label
    local snd   = activeSounds[label]
    if not label or not snd then return end

    if snd.paused then
        snd.pausedDuration = (snd.pausedDuration or 0) + (GetGameTimer() - (snd.pausedAt or GetGameTimer()))
        snd.paused   = false
        snd.pausedAt = nil
    else
        snd.paused   = true
        snd.pausedAt = GetGameTimer()
    end

    for playerId in pairs(playersInRange[label] or {}) do
        TriggerClientEvent("mnc-ppod:client:pauseResume", playerId, { label = label, paused = snd.paused })
    end
end)


RegisterNetEvent("mnc-ppod:server:seek", function(data)
    local label    = data.label
    local position = tonumber(data.position)
    local snd      = activeSounds[label]
    if not label or not position or not snd then return end

    position = math.max(0, position)
    snd.startedAt = GetGameTimer() - (position * 1000)
    if snd.paused then
        snd.pausedAt = GetGameTimer()
        snd.pausedDuration = 0
    end

    for playerId in pairs(playersInRange[label] or {}) do
        TriggerClientEvent("mnc-ppod:client:seek", playerId, { label = label, position = position })
    end
end)


RegisterNetEvent("mnc-ppod:server:requestSync", function()
    local src = source
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pCoords = GetEntityCoords(ped)

    for label, snd in pairs(activeSounds) do
        local srcCoords = getSourceCoords(snd)
        if srcCoords and #(pCoords - srcCoords) <= (snd.radius or Config.DefaultRadius) then
            playersInRange[label] = playersInRange[label] or {}
            playersInRange[label][src] = true
            sendStart(src, label, snd)
        end
    end

    for id, speaker in pairs(speakers) do
        TriggerClientEvent("mnc-ppod:client:createSpeaker", src,
            id, { x = speaker.coords.x, y = speaker.coords.y, z = speaker.coords.z }, speaker.netId, speaker.owner)
    end
end)


AddEventHandler("playerDropped", function()
    local src = source
    for _, inRange in pairs(playersInRange) do
        inRange[src] = nil
    end
    openSessions[src] = nil
end)

-- ─── Playlists ──────────────────────────────────────────────

lib.callback.register("mnc-ppod:server:getPlaylists", function(source)
    local cid = getCitizenId(source)
    if not cid then return {} end

    local rows = MySQL.query.await(
        "SELECT id, name, songs FROM mnc_ppod_playlists WHERE citizenid = ? ORDER BY created_at DESC",
        { cid }
    )

    local playlists = {}
    for _, row in ipairs(rows or {}) do
        local songs = json.decode(row.songs) or {}
        playlists[#playlists + 1] = {
            id    = row.id,
            name  = row.name,
            songs = songs,
        }
    end
    return playlists
end)

RegisterNetEvent("mnc-ppod:server:savePlaylist", function(data)
    local src  = source
    local cid  = getCitizenId(src)
    if not cid then return end

    local name  = tostring(data.name or "Playlist"):sub(1, 100)
    local songs = data.songs or {}

    -- Clamp songs
    if #songs > Config.MaxSongsPerPlaylist then
        songs = { table.unpack(songs, 1, Config.MaxSongsPerPlaylist) }
    end

    -- Count existing playlists
    local count = MySQL.scalar.await(
        "SELECT COUNT(*) FROM mnc_ppod_playlists WHERE citizenid = ?",
        { cid }
    )

    if (count or 0) >= Config.MaxPlaylists then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Ppod",
            description = "Max playlists reached (" .. Config.MaxPlaylists .. ").",
            type = "error",
        })
        return
    end

    MySQL.insert(
        "INSERT INTO mnc_ppod_playlists (citizenid, name, songs) VALUES (?, ?, ?)",
        { cid, name, json.encode(songs) }
    )


    local rows = MySQL.query.await(
        "SELECT id, name, songs FROM mnc_ppod_playlists WHERE citizenid = ? ORDER BY created_at DESC",
        { cid }
    )
    local playlists = {}
    for _, row in ipairs(rows or {}) do
        playlists[#playlists + 1] = { id = row.id, name = row.name, songs = json.decode(row.songs) or {} }
    end

    TriggerClientEvent("mnc-ppod:client:playlistSaved", src, playlists)
    debugPrint("Playlist saved for " .. cid .. ": " .. name)
end)

RegisterNetEvent("mnc-ppod:server:deletePlaylist", function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    MySQL.query("DELETE FROM mnc_ppod_playlists WHERE id = ? AND citizenid = ?", { data.id, cid })
    debugPrint("Playlist " .. tostring(data.id) .. " deleted for " .. cid)
end)



RegisterNetEvent("mnc-ppod:server:updatePlaylist", function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end

    local id    = tonumber(data.id)
    local songs = data.songs or {}

    if not id then return end

    -- Clamp songs
    if #songs > Config.MaxSongsPerPlaylist then
        songs = { table.unpack(songs, 1, Config.MaxSongsPerPlaylist) }
    end

    MySQL.query(
        "UPDATE mnc_ppod_playlists SET songs = ? WHERE id = ? AND citizenid = ?",
        { json.encode(songs), id, cid }
    )


    local rows = MySQL.query.await(
        "SELECT id, name, songs FROM mnc_ppod_playlists WHERE citizenid = ? ORDER BY created_at DESC",
        { cid }
    )
    local playlists = {}
    for _, row in ipairs(rows or {}) do
        playlists[#playlists + 1] = {
            id    = row.id,
            name  = row.name,
            songs = json.decode(row.songs) or {},
        }
    end

    TriggerClientEvent("mnc-ppod:client:playlistUpdated", src, playlists)
    debugPrint("Playlist " .. id .. " updated for " .. cid .. " (" .. #songs .. " songs)")
end)
