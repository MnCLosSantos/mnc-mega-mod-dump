local isUIOpen   = false
local soundLabel = Config.SoundLabel
local currentSoundLabel = nil  -- per-player unique label
local currentSkin = Config.DefaultiPodSkin
local activeRadius = {}

-- label -> GetGameTimer() deadline before which we should not attempt any
-- setTimeStamp()/Pause() call for that label. See the comment above
-- safeSetTimeStamp() below for why this exists: xsound's own isPlaying()
-- is NOT a real "the browser's YouTube player is ready" signal, so on its
-- own it can't gate seeks safely.
local soundReadyAt = {}

-- Call right after every exports.xsound:PlayUrl() so nothing tries to seek
-- that label until the browser has plausibly had time to actually build a
-- working YouTube iframe player for it.
local function markSoundLoading(label)
    soundReadyAt[label] = GetGameTimer() + (Config.YoutubeLoadGraceMs or 3000)
end

local function soundReady(label)
    return GetGameTimer() >= (soundReadyAt[label] or 0)
end


local currentBattery = Config.BatteryMax


local currentTrackDuration = 0

-- Headphones. nil = not wearing any. Otherwise the Config.HeadphoneSkins
-- entry currently equipped.
local headphonesEquipped = nil

-- Speakers. id -> { coords = vector3, netId = number|nil, owner = number }
local placedSpeakers   = {}
local connectedSpeakerId = nil
local speakerPlaybackPaused = false  -- mirrors the connected speaker's own paused state
local nearestSpeakerId   = nil
local speakerTextUIShown = false


local function debugPrint(msg)
    if Config.Debug then print("^3[mnc-ppod]^7 " .. tostring(msg)) end
end

local function getIpodSoundLabel()
    return soundLabel .. "_" .. GetPlayerServerId(PlayerId())
end

local function isInVehicle()
    local ped = PlayerPedId()
    return IsPedInAnyVehicle(ped, false)
end


-- Seeks a freshly-created xsound instance to where the track actually is.
--
-- `positionOrFn` can be a plain number, or a function returning one -- pass
-- a function when the caller wants the position computed at the moment the
-- seek actually lands (see the speaker relay handler below), since a
-- YouTube link can take anywhere from well under a second to well over ten
-- seconds to buffer before xsound:isPlaying() ever reports true. The
-- previous 3-second/one-shot version gave up long before slower links
-- finished loading, which is why re-entering a radius often just replayed
-- the song from 0:00 instead of resuming where it actually was.
--
-- Once playback is detected we also re-apply the seek a couple more times
-- (some xsound builds silently reset the timestamp back to 0 for a moment
-- right as real audio decoding kicks in) instead of trusting the first
-- call to have stuck.
-- IMPORTANT: exports.xsound:isPlaying(label) is NOT a real "the browser
-- actually built a working YouTube player" signal. Looking at xsound's own
-- source (info.lua/play.lua), isPlaying() just returns a plain Lua-side
-- flag that PlayUrl() sets to true SYNCHRONOUSLY, before the NUI message
-- even reaches the browser -- let alone before the YouTube iframe API has
-- loaded and built a yPlayer with a working seekTo(). And setTimeStamp()
-- is a fire-and-forget SendNUIMessage with no success/failure feedback
-- path back to Lua at all (xsound registers zero NUI callbacks from its
-- JS side), so pcall() around it can never actually observe the
-- "this.yPlayer.seekTo is not a function" error -- that throw happens
-- entirely inside the browser's JS runtime, invisible to Lua. That's why
-- gating purely on isPlaying() let seeks fire on literally the very first
-- check, on every track (not just playlist links), well before the real
-- player existed. soundReady()/markSoundLoading() add an actual minimum
-- time-based grace window on top of isPlaying() so we never even attempt
-- a seek before the browser has plausibly had time to build the player.
local function safeSetTimeStamp(label, positionOrFn, maxTries)
    maxTries = maxTries or 100 -- ~25s of buffering headroom at 250ms/tick
    CreateThread(function()
        local tries = 0
        local confirmations = 0
        while tries < maxTries do
            if not exports.xsound:soundExists(label) then
                return -- destroyed/replaced before it ever got going
            end
            if soundReady(label) and exports.xsound:isPlaying(label) then
                local pos = type(positionOrFn) == "function" and positionOrFn() or positionOrFn
                local ok = pcall(function() exports.xsound:setTimeStamp(label, pos) end)
                if ok then
                    confirmations = confirmations + 1
                    if confirmations >= 3 then return end
                end
            end
            tries = tries + 1
            Wait(250)
        end
        debugPrint("safeSetTimeStamp gave up waiting for '" .. label .. "' to be ready")
    end)
end


local function safePause(label, maxTries)
    maxTries = maxTries or 60 -- ~6s, comfortably spans Config.YoutubeLoadGraceMs
    CreateThread(function()
        local tries = 0
        while tries < maxTries do
            if exports.xsound:soundExists(label) then
                if soundReady(label) and exports.xsound:isPlaying(label) then
                    pcall(function() exports.xsound:Pause(label) end)
                    return
                end
            else
                return -- destroyed/replaced before it ever got going
            end
            tries = tries + 1
            Wait(100)
        end
        debugPrint("safePause gave up waiting for '" .. label .. "' to be ready")
    end)
end


local seekGeneration = {}

local function seekTo(label, position, maxTries)
    maxTries = maxTries or 60 -- ~9s, comfortably spans Config.YoutubeLoadGraceMs
    seekGeneration[label] = (seekGeneration[label] or 0) + 1
    local myGen = seekGeneration[label]
    CreateThread(function()
        local tries = 0
        while tries < maxTries do
            if seekGeneration[label] ~= myGen then
                return -- superseded by a newer seek for this label
            end
            if soundReady(label) and exports.xsound:soundExists(label) and exports.xsound:isPlaying(label) then
                pcall(function() exports.xsound:setTimeStamp(label, position) end)
                return
            end
            tries = tries + 1
            Wait(150)
        end
    end)
end


local activeLocalLabels = {}
local function trackLocalSound(label) activeLocalLabels[label] = true end
local function untrackLocalSound(label) activeLocalLabels[label] = nil end


local function canHearIpod()
    if not Config.RequireHeadphones then return true end
    return headphonesEquipped ~= nil or connectedSpeakerId ~= nil
end


local function canHearIpodLocally()
    if not Config.RequireHeadphones then return connectedSpeakerId == nil end
    return headphonesEquipped ~= nil and connectedSpeakerId == nil
end

local function notifyNoAudioPath()
    lib.notify({
        title = "Ppod",
        description = "Plug in your headphones (or connect a nearby speaker) to hear anything.",
        type = "error",
    })
end


local endWatchLabel         = nil
local endWatchSeenPlay      = false
local endWatchLastPos       = -1
local endWatchStallTicks    = 0
local endWatchSuppressUntil = 0

local function getEndWatchLabel()
    return connectedSpeakerId and ("speaker_" .. connectedSpeakerId) or getIpodSoundLabel()
end


local function resetEndWatch()
    endWatchLabel      = getEndWatchLabel()
    endWatchSeenPlay   = false
    endWatchLastPos    = -1
    endWatchStallTicks = 0
end

-- Called whenever WE explicitly pause something.
local function suppressEndWatch(ms)
    endWatchSuppressUntil = GetGameTimer() + (ms or 3000)
end


local function pushPlayState(playing)
    if isUIOpen then
        SendNUIMessage({ action = "playState", playing = playing })
    end
end


local function pushTrackMeta(fields)
    if not isUIOpen then return end
    fields.action = "trackMeta"
    SendNUIMessage(fields)
end

local function fireSongEnded()

    SendNUIMessage({ action = "songEnded" })
    resetEndWatch()
end

CreateThread(function()
    while true do
        Wait(1500)
        local label = getEndWatchLabel()

        if label ~= endWatchLabel then

            resetEndWatch()
        elseif label and GetGameTimer() >= endWatchSuppressUntil then
            if exports.xsound:soundExists(label) then
                local playing = exports.xsound:isPlaying(label)
                local paused  = exports.xsound:isPaused(label)

                if paused then
                    endWatchStallTicks = 0
                    endWatchLastPos    = -1
                elseif playing then
                    endWatchSeenPlay = true
                    local pos = exports.xsound:getTimeStamp(label) or 0
                    if endWatchLastPos >= 0 and math.abs(pos - endWatchLastPos) < 0.5 then
                        endWatchStallTicks = endWatchStallTicks + 1
                        if endWatchStallTicks >= 2 then
                            fireSongEnded()
                        end
                    else
                        endWatchStallTicks = 0
                    end
                    endWatchLastPos = pos
                elseif endWatchSeenPlay then
                    fireSongEnded()
                end
            elseif endWatchSeenPlay then

                fireSongEnded()
            end
        end
    end
end)


local function resolveTrackDuration(label)
    currentTrackDuration = 0
    if label == getEndWatchLabel() then
        pushTrackMeta({ duration = 0 })
    end
    CreateThread(function()
        local tries = 0
        while tries < 30 do
            if exports.xsound:soundExists(label) then
                local ok, dur = pcall(function() return exports.xsound:getDuration(label) end)
                if ok and type(dur) == "number" and dur > 0 and label == getEndWatchLabel() then
                    currentTrackDuration = dur
                    pushTrackMeta({ duration = dur })
                    return
                end
            else
                return -- destroyed/replaced before we ever got a duration
            end
            tries = tries + 1
            Wait(150)
        end
    end)
end

local function pauseLocalIpod()
    local label = getIpodSoundLabel()
    if exports.xsound:soundExists(label) and exports.xsound:isPlaying(label) then
        exports.xsound:Pause(label)
        suppressEndWatch()
    end
end


local function destroyLocalIpod()
    local label = getIpodSoundLabel()
    if exports.xsound:soundExists(label) then
        exports.xsound:Destroy(label)
        untrackLocalSound(label)
    end
    resetEndWatch()
end


local function resumeLocalIpodIfPossible()
    if not canHearIpodLocally() then return end
    local label = getIpodSoundLabel()
    if exports.xsound:soundExists(label) and not exports.xsound:isPlaying(label) then
        exports.xsound:Resume(label)
        pushPlayState(true)
    end
end

local ipodState = {
    url            = "",
    volume         = Config.DefaultVolume,
    radius         = Config.DefaultRadius,
    paused         = false,
    startedAt      = nil,
    pausedAt       = nil,
    pausedDuration = 0,
}

-- Mirrors server.lua's getElapsed() for the ipod's own local clock.
local function ipodElapsed()
    if not ipodState.startedAt then return 0 end
    local pausedDuration = ipodState.pausedDuration or 0
    local now = (ipodState.paused and ipodState.pausedAt) or GetGameTimer()
    local elapsed = (now - ipodState.startedAt - pausedDuration) / 1000.0
    return elapsed > 0 and elapsed or 0
end

-- ─── Headphone hat prop (qb-clothing hat slot) ─────────────────
local function loadModel(model)
    local hash = type(model) == "string" and GetHashKey(model) or model
    if not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 200 do
        Wait(10)
        tries = tries + 1
    end
    return HasModelLoaded(hash) and hash or nil
end

-- Headphones ride ped prop slot 0 (the hat slot) as texture variants of
-- Config.HeadphoneHatProp, the same way qb-clothing itself renders hats
-- (SetPedPropIndex / ClearPedProp) -- no streamed object, no attach offset
-- to tune, and it behaves identically to any other hat the player equips.
local function removeHeadphoneProp()
    ClearPedProp(PlayerPedId(), 0)
end

local function applyHeadphoneProp(skin)
    if not skin then
        removeHeadphoneProp()
        return
    end
    if skin.texture == nil then
        debugPrint("Headphone skin '" .. tostring(skin.id) .. "' has no texture configured")
        return
    end

    local ped = PlayerPedId()
    SetPedPropIndex(ped, 0, Config.HeadphoneHatProp, skin.texture, true)
end

-- ─── Held ppod prop + animation (visible while the NUI is open) ────────
-- Reuses the classic "checking your phone" prop/anim so the ped visibly
-- holds/looks at the ppod instead of standing there with empty hands.
-- Started in openUI()/stopped in closeUI() so every way the UI can open
-- or close (item use, /ppod command, entering a vehicle, dead battery)
-- funnels through the same two choke points and stays in sync automatically.
local ipodPropHandle = nil

local function startIpodHoldAnim()
    local ped = PlayerPedId()

    local hash = loadModel(Config.iPodPropModel)
    if hash then
        if ipodPropHandle and DoesEntityExist(ipodPropHandle) then
            DeleteEntity(ipodPropHandle)
        end
        ipodPropHandle = CreateObject(hash, GetEntityCoords(ped), true, true, false)
        SetModelAsNoLongerNeeded(hash)

        local bone = GetPedBoneIndex(ped, Config.iPodPropBoneId)
        local off  = Config.iPodPropOffset
        local rot  = Config.iPodPropRotation
        AttachEntityToEntity(ipodPropHandle, ped, bone,
            off.x, off.y, off.z, rot.x, rot.y, rot.z,
            true, true, false, true, 2, true)
    else
        debugPrint("Could not load ppod hold prop '" .. tostring(Config.iPodPropModel) .. "'")
    end

    RequestAnimDict(Config.iPodAnimDict)
    local tries = 0
    while not HasAnimDictLoaded(Config.iPodAnimDict) and tries < 100 do
        Wait(10)
        tries = tries + 1
    end

    if HasAnimDictLoaded(Config.iPodAnimDict) then
        -- flags: 1 (loop) + 16 (upper body/secondary task) + 32 (allow movement)
        TaskPlayAnim(ped, Config.iPodAnimDict, Config.iPodAnimClip, 8.0, -8.0, -1, 49, 0, false, false, false)
    else
        debugPrint("ppod hold anim dict '" .. tostring(Config.iPodAnimDict) .. "' never loaded")
    end
end

local function stopIpodHoldAnim()
    local ped = PlayerPedId()
    ClearPedSecondaryTask(ped)
    if ipodPropHandle and DoesEntityExist(ipodPropHandle) then
        DeleteEntity(ipodPropHandle)
    end
    ipodPropHandle = nil
end


RegisterNetEvent("mnc-ppod:client:toggleHeadphones", function(skin)
    if not skin then return end

    if headphonesEquipped and headphonesEquipped.id == skin.id then
        removeHeadphoneProp()
        headphonesEquipped = nil
        lib.notify({ title = "Headphones", description = "Headphones removed.", type = "inform" })

        pauseLocalIpod()
        pushPlayState(false)
    else
        if connectedSpeakerId then
            lib.notify({ title = "Headphones", description = "Disconnect from the speaker before wearing headphones.", type = "error" })
            return
        end

        headphonesEquipped = skin
        applyHeadphoneProp(skin)
        lib.notify({ title = "Headphones", description = "Headphones (" .. skin.label .. ") plugged in.", type = "success" })

        resumeLocalIpodIfPossible()
    end
end)

AddEventHandler("onClientResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    removeHeadphoneProp()
    stopIpodHoldAnim()
    if speakerTextUIShown then
        pcall(function() lib.hideTextUI() end)
        speakerTextUIShown = false
    end
    -- Destroy every xsound instance we own so nothing orphaned survives
    -- into the next start (see activeLocalLabels comment above).
    for label in pairs(activeLocalLabels) do
        pcall(function()
            if exports.xsound:soundExists(label) then
                exports.xsound:Destroy(label)
            end
        end)
    end
    activeLocalLabels = {}
end)


local function openUI()
    if isUIOpen then return end
    currentSoundLabel = getIpodSoundLabel()

    local playing, paused, volume, url, position
    if connectedSpeakerId then
        playing  = not speakerPlaybackPaused
        paused   = speakerPlaybackPaused
        volume   = math.ceil((ipodState.volume or Config.DefaultVolume) * 100)
        url      = ipodState.url or ""
        position = ipodElapsed()
    else
        local exists = exports.xsound:soundExists(currentSoundLabel)
        playing  = exists and exports.xsound:isPlaying(currentSoundLabel)
        paused   = exists and exports.xsound:isPaused(currentSoundLabel)
        volume   = exists and math.ceil(exports.xsound:getVolume(currentSoundLabel) * 100) or math.ceil((ipodState.volume or Config.DefaultVolume) * 100)
        url      = exists and exports.xsound:getLink(currentSoundLabel) or (ipodState.url or "")
        position = exists and (exports.xsound:getTimeStamp(currentSoundLabel) or 0) or ipodElapsed()
    end
    local radius = activeRadius[currentSoundLabel] or Config.DefaultRadius

    -- Fetch playlists from server
    local playlists = lib.callback.await("mnc-ppod:server:getPlaylists", false)

    SetNuiFocus(true, true)
    isUIOpen = true

    SendNUIMessage({
        action    = "open",
        mode      = "ipod",
        playing   = playing or false,
        paused    = paused  or false,
        volume    = volume,
        radius    = radius,
        url       = url,
        position  = position or 0,
        duration  = currentTrackDuration or 0,
        playlists = playlists or {},
        skin      = currentSkin,
        battery   = currentBattery,
    })

    startIpodHoldAnim()

    debugPrint("UI opened (skin: " .. currentSkin .. ")")
end

local function closeUI()
    if not isUIOpen then return end
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    isUIOpen = false
    stopIpodHoldAnim()
    TriggerServerEvent("mnc-ppod:server:closeIPod")
    debugPrint("UI closed")
end

-- ─── /ppod command (opens the iPod UI directly) ──────────────
-- Optional first arg lets you preview a skin, e.g. /ppod pink

if Config.EnablePpodCommand then
    RegisterCommand("ppod", function(source, args)
        if isUIOpen then
            closeUI()
            return
        end
        if isInVehicle() then
            lib.notify({ title = "Ppod", description = "You can't use the ppod while in a vehicle.", type = "error" })
            return
        end
        currentSkin    = (args and args[1]) or Config.DefaultiPodSkin
        currentBattery = Config.BatteryMax
        openUI()
    end, false)
end


RegisterNetEvent("mnc-ppod:client:openIPod", function(skin, battery)
    currentSkin    = skin or Config.DefaultiPodSkin
    currentBattery = battery or Config.BatteryMax

    if isUIOpen then
        closeUI()
        return
    end
    if isInVehicle() then
        lib.notify({ title = "Ppod", description = "You can't use the ppod while in a vehicle.", type = "error" })
        return
    end
    openUI()
end)


RegisterNetEvent("mnc-ppod:client:batteryUpdate", function(battery)
    currentBattery = battery
    if isUIOpen then
        SendNUIMessage({ action = "battery", battery = battery })
    end
end)

RegisterNetEvent("mnc-ppod:client:batteryDead", function()
    currentSoundLabel = getIpodSoundLabel()
    if exports.xsound:soundExists(currentSoundLabel) then
        exports.xsound:Destroy(currentSoundLabel)
        untrackLocalSound(currentSoundLabel)
    end
    if connectedSpeakerId then
        TriggerServerEvent("mnc-ppod:server:disconnectSpeaker", connectedSpeakerId)
        connectedSpeakerId = nil
        speakerPlaybackPaused = false
    end
    ipodState.url = ""
    ipodState.paused = false
    ipodState.startedAt = nil

    resetEndWatch()
    if isUIOpen then
        closeUI()
    end
    lib.notify({ title = "Ppod", description = "Battery dead — recharge with a ppod charger.", type = "error" })
end)


local function getArtwork(url)
    local videoId = url:match("v=([%w%-_]+)") or url:match("youtu%.be/([%w%-_]+)")
    if videoId then
        return "https://img.youtube.com/vi/" .. videoId .. "/mqdefault.jpg"
    end
    return ""
end

-- xsound's bundled YouTube backend only implements seekTo() against a
-- plain single-video player. A link that still carries playlist context
-- (`&list=...&index=...` -- exactly what pasting straight off a
-- "Radio"/playlist watch page gives you) makes it build a different
-- internal player object with no seekTo() at all, so every attempt to
-- resume mid-song throws "this.yPlayer.seekTo is not a function" in the
-- NUI console and silently never seeks -- no amount of retrying fixes
-- that, since it's not a timing issue. Stripping back to just
-- `watch?v=<id>` before it ever reaches xsound avoids that code path
-- entirely while still playing the exact same video. Mirrors
-- server.lua's sanitizePlaybackUrl, needed here too since personal ipod
-- playback (no speaker) never goes through the server at all.
local function sanitizePlaybackUrl(url)
    if not url or url == "" then return url end
    local id = url:match("[?&]v=([%w%-_]+)") or url:match("youtu%.be/([%w%-_]+)")
    if id then
        return "https://www.youtube.com/watch?v=" .. id
    end
    return url -- not a recognisable YouTube link (e.g. SoundCloud) -- leave as-is
end


local function getIpodPlaybackSnapshot()
    if not ipodState.url or ipodState.url == "" then return nil end
    return {
        label    = getIpodSoundLabel(),
        url      = ipodState.url,
        volume   = math.ceil((ipodState.volume or Config.DefaultVolume) * 100),
        paused   = ipodState.paused or false,
        position = ipodElapsed(),
    }
end

local function playFromNui(data, cb)
    local url    = sanitizePlaybackUrl(data.url)
    local volume = (data.volume or 50) / 100
    local radius = data.radius or Config.DefaultRadius

    if not url or url == "" then
        if cb then cb({ status = "no_url" }) end
        return
    end

    currentSoundLabel = getIpodSoundLabel()

    if not canHearIpod() then
        notifyNoAudioPath()
        if cb then cb({ status = "no_headphones" }) end
        return
    end

    ipodState.url             = url
    ipodState.volume          = volume
    ipodState.radius          = radius
    ipodState.paused          = false
    ipodState.startedAt       = GetGameTimer()
    ipodState.pausedAt        = nil
    ipodState.pausedDuration  = 0

    if connectedSpeakerId then

        destroyLocalIpod()

        TriggerServerEvent("mnc-ppod:server:playUrl", {
            url       = url,
            volume    = volume,
            label     = "speaker_" .. connectedSpeakerId,
            speakerId = connectedSpeakerId,
        })
    else
        if exports.xsound:soundExists(currentSoundLabel) then
            exports.xsound:Destroy(currentSoundLabel)
            untrackLocalSound(currentSoundLabel)
        end

        exports.xsound:PlayUrl(currentSoundLabel, url, volume, false)
        markSoundLoading(currentSoundLabel)
        exports.xsound:Distance(currentSoundLabel, radius)
        activeRadius[currentSoundLabel] = radius
        trackLocalSound(currentSoundLabel)
        resetEndWatch()
        resolveTrackDuration(currentSoundLabel)
    end

    if isUIOpen then
        SendNUIMessage({
            action  = "songStarted",
            url     = url,
            title   = url,
            artwork = getArtwork(url),
            playing = true,
            position = 0,
        })
    end

    if cb then cb({ status = "ok" }) end
end

-- ─── NUI Callbacks ──────────────────────────────────────────


RegisterNUICallback("close", function(data, cb)
    closeUI()
    cb("ok")
end)

-- Play a URL
RegisterNUICallback("playUrl", function(data, cb)
    playFromNui(data, cb)
end)

-- Stop
RegisterNUICallback("stop", function(data, cb)
    destroyLocalIpod()
    if connectedSpeakerId then
        TriggerServerEvent("mnc-ppod:server:disconnectSpeaker", connectedSpeakerId)
        connectedSpeakerId = nil
        speakerPlaybackPaused = false
    end
    ipodState.url = ""
    ipodState.paused = false
    ipodState.startedAt = nil
    cb("ok")
end)

-- Pause / Resume
RegisterNUICallback("pauseResume", function(data, cb)
    currentSoundLabel = getIpodSoundLabel()

    if connectedSpeakerId then

        speakerPlaybackPaused = not speakerPlaybackPaused
        ipodState.paused = speakerPlaybackPaused
        suppressEndWatch()
        TriggerServerEvent("mnc-ppod:server:pauseResume", { label = "speaker_" .. connectedSpeakerId })
        pushPlayState(not speakerPlaybackPaused)
        cb({ status = "ok" })
        return
    end

    if not exports.xsound:soundExists(currentSoundLabel) and ipodState.url ~= "" then

        playFromNui({
            url    = ipodState.url,
            volume = math.ceil((ipodState.volume or Config.DefaultVolume) * 100),
            radius = ipodState.radius,
        }, cb)
        return
    end

    if exports.xsound:soundExists(currentSoundLabel) then
        if exports.xsound:isPlaying(currentSoundLabel) then
            exports.xsound:Pause(currentSoundLabel)
            suppressEndWatch()
            ipodState.paused  = true
            ipodState.pausedAt = GetGameTimer()
        else
            if not canHearIpodLocally() then
                notifyNoAudioPath()
                cb({ status = "no_headphones" })
                return
            end
            exports.xsound:Resume(currentSoundLabel)
            ipodState.paused = false
            ipodState.pausedDuration = (ipodState.pausedDuration or 0) + (GetGameTimer() - (ipodState.pausedAt or GetGameTimer()))
            ipodState.pausedAt = nil
        end
    end

    cb({ status = "ok" })
end)

-- Volume change
RegisterNUICallback("setVolume", function(data, cb)
    currentSoundLabel = getIpodSoundLabel()
    local vol = (data.volume or 50) / 100
    vol = math.max(0.01, math.min(1.0, vol))

    if exports.xsound:soundExists(currentSoundLabel) then
        exports.xsound:setVolume(currentSoundLabel, vol)
    end

    ipodState.volume = vol

    if connectedSpeakerId then
        TriggerServerEvent("mnc-ppod:server:setVolume", { label = "speaker_" .. connectedSpeakerId, volume = vol })
    end

    cb("ok")
end)

-- Radius change
RegisterNUICallback("setRadius", function(data, cb)
    currentSoundLabel = getIpodSoundLabel()
    local r = tonumber(data.radius) or Config.DefaultRadius
    r = math.max(1, math.min(500, r))
    activeRadius[currentSoundLabel] = r

    ipodState.radius = r
    if exports.xsound:soundExists(currentSoundLabel) then
        exports.xsound:Distance(currentSoundLabel, r)
    end

    cb("ok")
end)


RegisterNUICallback("seekTo", function(data, cb)
    currentSoundLabel = getIpodSoundLabel()
    local position = math.max(0, tonumber(data.position) or 0)

    if connectedSpeakerId then
        TriggerServerEvent("mnc-ppod:server:seek", { label = "speaker_" .. connectedSpeakerId, position = position })
    else
        seekTo(currentSoundLabel, position)

        ipodState.startedAt      = GetGameTimer() - (position * 1000)
        ipodState.pausedDuration = 0
        if ipodState.paused then
            ipodState.pausedAt = GetGameTimer()
        end
    end

    cb("ok")
end)


RegisterNUICallback("shuffle", function(data, cb)
    playFromNui(data, cb)
end)

-- Save playlist
RegisterNUICallback("savePlaylist", function(data, cb)
    local name  = data.name
    local songs = data.songs
    if not name or not songs then cb("missing_data") return end
    TriggerServerEvent("mnc-ppod:server:savePlaylist", { name = name, songs = songs })
    cb("ok")
end)

-- Delete playlist
RegisterNUICallback("deletePlaylist", function(data, cb)
    TriggerServerEvent("mnc-ppod:server:deletePlaylist", { id = data.id })
    cb("ok")
end)

-- Update playlist songs (add / remove individual songs from an existing playlist)
RegisterNUICallback("updatePlaylist", function(data, cb)
    if not data.id or not data.songs then cb("missing_data") return end
    TriggerServerEvent("mnc-ppod:server:updatePlaylist", { id = data.id, songs = data.songs })
    cb("ok")
end)

-- Get updated playlists (pull from server and push back to NUI)
RegisterNUICallback("getPlaylists", function(data, cb)
    local playlists = lib.callback.await("mnc-ppod:server:getPlaylists", false)
    SendNUIMessage({ action = "updatePlaylists", playlists = playlists or {} })
    cb("ok")
end)

-- ─── Server → Client events ─────────────────────────────────

-- Speaker relay confirms playback started — update NUI with song info
RegisterNetEvent("mnc-ppod:client:songStarted", function(info)
    if not isUIOpen then return end
    SendNUIMessage({
        action   = "songStarted",
        url      = info.url,
        title    = info.title or info.url,
        artwork  = info.artwork or "",
        playing  = true,
        position = 0,
    })
end)


-- Fired by the server for a connected speaker's audio (either a fresh
-- play or re-entering its proximity range).
RegisterNetEvent("mnc-ppod:client:startVehicleAudio", function(data)
    if not data or not data.label or not data.url then return end

    local label      = data.label
    local url        = data.url
    local volume     = data.volume or Config.DefaultVolume
    local position   = tonumber(data.position) or 0
    -- Anchor for how much real time passes while xsound buffers the link,
    -- so the eventual seek (see below) lands on where the track actually
    -- is *now* rather than where it was the instant this event arrived.
    local receivedAt = GetGameTimer()

    if exports.xsound:soundExists(label) then
        exports.xsound:Destroy(label)
        untrackLocalSound(label)
    end

    exports.xsound:PlayUrl(label, url, volume, false)
    markSoundLoading(label)
    activeRadius[label] = data.radius
    trackLocalSound(label)

    if not data.paused then
        -- Re-entering a radius (or a speaker relaying a track already in
        -- progress) needs to resume mid-song, not from 0:00. xsound needs
        -- time to actually buffer the stream before a seek will stick, and
        -- that buffering time varies a lot, so we hand safeSetTimeStamp a
        -- function that recomputes the true elapsed position at whatever
        -- moment the seek actually lands instead of a value that goes
        -- stale the moment buffering takes more than an instant.
        safeSetTimeStamp(label, function()
            return position + (GetGameTimer() - receivedAt) / 1000.0
        end)
    elseif position > 0 then
        safeSetTimeStamp(label, position)
    end

    if data.paused then
        safePause(label)
    end

    if label == getEndWatchLabel() then
        resetEndWatch()
        pushTrackMeta({ position = position, playing = not (data.paused or false) })
    end

    resolveTrackDuration(label)

    debugPrint("Started local speaker audio for label=" .. label .. " @ " .. position .. "s" .. (data.paused and " (paused)" or ""))
end)


RegisterNetEvent("mnc-ppod:client:stopVehicleAudio", function(data)
    if not data or not data.label then return end

    if data.label == getEndWatchLabel() then
        resetEndWatch()
    end
    if exports.xsound:soundExists(data.label) then
        exports.xsound:Destroy(data.label)
    end
    untrackLocalSound(data.label)
    activeRadius[data.label] = nil
end)

RegisterNetEvent("mnc-ppod:client:setVolume", function(data)
    if not data or not data.label then return end
    if exports.xsound:soundExists(data.label) then
        exports.xsound:setVolume(data.label, data.volume)
    end
end)

RegisterNetEvent("mnc-ppod:client:setRadius", function(data)
    if not data or not data.label then return end
    activeRadius[data.label] = data.radius
end)


RegisterNetEvent("mnc-ppod:client:pauseResume", function(data)
    if not data or not data.label then return end
    if not exports.xsound:soundExists(data.label) then return end

    local isPlaying = exports.xsound:isPlaying(data.label)
    if data.paused and isPlaying then
        exports.xsound:Pause(data.label)
        if data.label == getEndWatchLabel() then suppressEndWatch() end
    elseif not data.paused and not isPlaying then
        exports.xsound:Resume(data.label)
    end


    if data.label == getEndWatchLabel() then
        pushPlayState(not data.paused)
    end
end)


RegisterNetEvent("mnc-ppod:client:seek", function(data)
    if not data or not data.label then return end
    if exports.xsound:soundExists(data.label) then
        seekTo(data.label, data.position or 0)
        if data.label == getEndWatchLabel() then
            pushTrackMeta({ position = data.position or 0 })
        end
    end
end)

-- Playlist saved confirmation
RegisterNetEvent("mnc-ppod:client:playlistSaved", function(playlists)
    if not isUIOpen then return end
    SendNUIMessage({ action = "updatePlaylists", playlists = playlists })
    lib.notify({ title = "Ppod", description = "Playlist saved!", type = "success" })
end)

-- Playlist updated (add/remove songs) confirmation
RegisterNetEvent("mnc-ppod:client:playlistUpdated", function(playlists)
    if not isUIOpen then return end
    SendNUIMessage({ action = "updatePlaylists", playlists = playlists })
end)


CreateThread(function()
    local wasInVehicle = false
    while true do
        Wait(1000)
        local inVeh = isInVehicle()
        if wasInVehicle and not inVeh then
            -- (kept for parity; ppod isn't normally openable in a vehicle
            -- to begin with, but this guards against edge cases like
            -- getting forced into one while the UI is open)
        elseif inVeh and isUIOpen then
            closeUI()
        end
        wasInVehicle = inVeh
    end
end)


AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(2000)
        TriggerServerEvent("mnc-ppod:server:requestSync")
    end)
end)



local function getGroundPlacementCoords(distance)
    local ped    = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, distance, 0.0)
    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 5.0, false)
    local z = found and groundZ or coords.z
    return vector3(coords.x, coords.y, z)
end

-- Item use → enter placement mode
RegisterNetEvent("mnc-ppod:client:placeSpeaker", function()
    local ok = lib.progressBar({
        duration    = Config.SpeakerPlaceTime,
        label       = "Placing speaker…",
        useWhileDead = false,
        canCancel   = true,
        disable     = { move = true, car = true, combat = true },
        anim        = Config.SpeakerAnim,
    })
    if not ok then return end

    local hash = loadModel(Config.SpeakerModel)
    if not hash then
        lib.notify({ title = "Ppod Speaker", description = "Could not load the speaker prop.", type = "error" })
        return
    end

    local coords = getGroundPlacementCoords(1.2)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)
    SetModelAsNoLongerNeeded(hash)

    local netId = NetworkGetNetworkIdFromEntity(obj)
    local finalCoords = GetEntityCoords(obj)

    TriggerServerEvent("mnc-ppod:server:registerSpeaker", {
        coords = { x = finalCoords.x, y = finalCoords.y, z = finalCoords.z },
        netId  = netId,
    })
end)

-- Server tells everyone (including the placer) about a speaker so
-- proximity checks work for all clients, not just whoever placed it.
RegisterNetEvent("mnc-ppod:client:createSpeaker", function(id, coords, netId, owner)
    placedSpeakers[id] = {
        coords = vector3(coords.x, coords.y, coords.z),
        netId  = netId,
        owner  = owner,
    }
end)

RegisterNetEvent("mnc-ppod:client:removeSpeaker", function(id)
    local speaker = placedSpeakers[id]
    if speaker then
        if speaker.netId then
            local ent = NetworkGetEntityFromNetworkId(speaker.netId)
            if ent and ent ~= 0 and DoesEntityExist(ent) then
                DeleteEntity(ent)
            end
        end
        placedSpeakers[id] = nil
    end
    if connectedSpeakerId == id then
        connectedSpeakerId = nil

        pauseLocalIpod()
        pushPlayState(false)
    end
end)

RegisterNetEvent("mnc-ppod:client:speakerConnected", function(id)
    connectedSpeakerId = id
    speakerPlaybackPaused = false
end)

RegisterNetEvent("mnc-ppod:client:speakerDisconnected", function(id)
    if connectedSpeakerId == id then
        connectedSpeakerId = nil
        speakerPlaybackPaused = false
        pushPlayState(false)
    end
end)

local function myServerId()
    return GetPlayerServerId(PlayerId())
end

local function openSpeakerMenu(id)
    local speaker = placedSpeakers[id]
    if not speaker then return end

    local options = {}

    if connectedSpeakerId == id then
        options[#options + 1] = {
            title       = "Disconnect",
            description = "Stop playing your ppod through this speaker",
            icon        = "volume-xmark",
            onSelect    = function()
                TriggerServerEvent("mnc-ppod:server:disconnectSpeaker", id)
                connectedSpeakerId = nil
                speakerPlaybackPaused = false

                pushPlayState(false)
            end,
        }
    else
        options[#options + 1] = {
            title       = "Connect My Ppod",
            description = "Play whatever's on your ppod through this speaker for everyone within " .. Config.SpeakerRadius .. "m",
            icon        = "volume-high",
            onSelect    = function()
                if headphonesEquipped then
                    lib.notify({ title = "Ppod Speaker", description = "Remove your headphones before connecting to a speaker.", type = "error" })
                    return
                end

                -- Nothing needs to be playing to connect — if something's
                -- already loaded on the ppod, its snapshot carries over so
                -- playback continues on the speaker instead of resetting.
                local snapshot = getIpodPlaybackSnapshot()

                if connectedSpeakerId and connectedSpeakerId ~= id then
                    TriggerServerEvent("mnc-ppod:server:disconnectSpeaker", connectedSpeakerId)
                end

                TriggerServerEvent("mnc-ppod:server:connectSpeaker", {
                    speakerId = id,
                    url       = snapshot and snapshot.url or nil,
                    volume    = snapshot and snapshot.volume or nil,
                    position  = snapshot and snapshot.position or nil,
                    paused    = snapshot and snapshot.paused or false,
                })
                connectedSpeakerId = id
                speakerPlaybackPaused = (snapshot and snapshot.paused) or false
                ipodState.paused = speakerPlaybackPaused


                destroyLocalIpod()
                lib.notify({ title = "Ppod Speaker", description = "Connected — playing for everyone nearby.", type = "success" })
            end,
        }
    end

    if speaker.owner == myServerId() then
        options[#options + 1] = {
            title       = "Pick Up Speaker",
            description = "Return it to your inventory",
            icon        = "hand",
            onSelect    = function()
                local ok = lib.progressBar({
                    duration     = Config.SpeakerPickupTime,
                    label        = "Picking up speaker…",
                    useWhileDead = false,
                    canCancel    = true,
                    disable      = { move = true, car = true, combat = true },
                    anim         = Config.SpeakerAnim,
                })
                if ok then
                    TriggerServerEvent("mnc-ppod:server:removeSpeaker", id)
                end
            end,
        }
    end

    lib.registerContext({
        id      = "ppod_speaker_menu",
        title   = "Ppod Speaker",
        options = options,
    })
    lib.showContext("ppod_speaker_menu")
end


CreateThread(function()
    while true do
        local sleep = 1000
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)

        nearestSpeakerId = nil
        local nearestDist = Config.SpeakerInteractDistance

        for id, speaker in pairs(placedSpeakers) do
            local dist = #(coords - speaker.coords)
            if dist <= nearestDist then
                nearestSpeakerId = id
                nearestDist = dist
            end
        end

        if nearestSpeakerId then
            sleep = 0
            if not speakerTextUIShown then
                lib.showTextUI("[E] Speaker")
                speakerTextUIShown = true
            end
            if IsControlJustPressed(0, 38) then -- INPUT_PICKUP / E
                openSpeakerMenu(nearestSpeakerId)
            end
        elseif speakerTextUIShown then
            lib.hideTextUI()
            speakerTextUIShown = false
        end

        Wait(sleep)
    end
end)



RegisterNetEvent("mnc-ppod:client:openChargeMenu", function(ppodItems, chargerSlot)
    if not ppodItems or #ppodItems == 0 then return end

    local options = {}
    for _, item in ipairs(ppodItems) do
        options[#options + 1] = {
            title       = item.label .. " — " .. item.battery .. "%",
            description = "Slot " .. item.slot,
            icon        = "battery-half",
            onSelect    = function()
                local ok = lib.progressBar({
                    duration    = Config.ChargeTime,
                    label       = "Charging " .. item.label .. "…",
                    useWhileDead = false,
                    canCancel   = true,
                    disable     = { move = false, car = true, combat = true },
                })
                if ok then
                    TriggerServerEvent("mnc-ppod:server:chargePpod", { slot = item.slot, chargerSlot = chargerSlot })
                else
                    lib.notify({ title = "Ppod Charger", description = "Charging cancelled.", type = "error" })
                end
            end,
        }
    end

    lib.registerContext({
        id      = "ppod_charge_menu",
        title   = "Charge a Ppod",
        options = options,
    })
    lib.showContext("ppod_charge_menu")
end)