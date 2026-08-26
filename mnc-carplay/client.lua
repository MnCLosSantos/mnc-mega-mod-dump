local isUIOpen       = false
local currentSkin     = nil
local currentVehNetId = nil   -- vehicle whose unit is open on THIS client right now
local currentRadius   = Config.DefaultRadius
local currentVolume   = Config.DefaultVolume
local currentTrackDuration = 0
local installedUnits = {}
local attachedProps = {}
local nowPlaying = {}
local livePreviewToggles = {}
local hudShown     = false
local hudLastTitle = nil

local function debugPrint(msg)
    if Config.Debug then print("^3[mnc-carplay]^7 " .. tostring(msg)) end
end

-- Rotation/vector debugging helpers ------------------------------------
local function vecStr(v)
    if not v then return "nil" end
    return string.format("(%.2f, %.2f, %.2f)", tonumber(v.x) or 0, tonumber(v.y) or 0, tonumber(v.z) or 0)
end

local function getUnitLabel(netId)
    return Config.SoundLabel .. "_" .. tostring(netId)
end

local function trimPlate(plate)
    if not plate then return "" end
    return plate:match("^%s*(.-)%s*$") or ""
end

local function defaultOffset()
    return { x = Config.TabletPropOffset.x, y = Config.TabletPropOffset.y, z = Config.TabletPropOffset.z }
end

local function defaultRotation()
    return { x = Config.TabletPropRotation.x, y = Config.TabletPropRotation.y, z = Config.TabletPropRotation.z }
end


local function withDefault(v, default)
    if v == nil then return default end
    return v
end


local function getPropOptionById(id)
    for _, opt in ipairs(Config.TabletPropOptions) do
        if opt.id == id then return opt end
    end
    return nil
end


local function resolvePropModelId(unit)
    local id = unit and unit.propModel
    if id and getPropOptionById(id) then return id end
    return Config.DefaultTabletProp
end

local function resolvePropModelString(id)
    local opt = getPropOptionById(id)
    if opt then return opt.model end
    local fallback = getPropOptionById(Config.DefaultTabletProp)
    return fallback and fallback.model or nil
end


-- ─── Real xsound readiness tracking ──────────────────────────────────
-- exports.xsound:isPlaying(label) is NOT a reliable readiness check: xsound
-- flips soundInfo[label].playing = true synchronously inside PlayUrl(), before
-- the NUI has even received the message -- let alone before the underlying
-- YouTube IFrame Player has finished initializing. And xsound's own
-- setTimeStamp() calls `this.yPlayer.seekTo(...)` with no readiness guard, so
-- seeking too early throws "this.yPlayer.seekTo is not a function" inside
-- xsound's own NUI (SoundPlayer.js). That's not our bug to fix directly -- but
-- we can stop triggering it. xsound DOES expose a genuine readiness signal:
-- the onPlayStart callback (passed via PlayUrl's 5th "options" arg) only
-- fires once xsound's JS-side isReady() has run, which for YouTube tracks
-- happens inside the YT.Player onReady event -- i.e. exactly when
-- yPlayer.seekTo becomes callable. We gate every seek/pause/volume call
-- behind that real signal, and only fall back to the old timer as a
-- last-resort safety net in case the event is ever missed (so we never hang).
local soundReadyAt    = {}
local soundReadyFired = {}
local function markSoundLoading(label)
    soundReadyFired[label] = false
    soundReadyAt[label] = GetGameTimer() + (Config.YoutubeLoadGraceMs or 3000) * 3
end
local function markSoundReady(label)
    soundReadyFired[label] = true
end
local function soundReady(label)
    if soundReadyFired[label] then return true end
    return GetGameTimer() >= (soundReadyAt[label] or 0)
end

local activeLocalLabels = {}

-- ─── Local volume / muffling state ────────────────────────────────
-- soundBaseVolume is the "real" volume for a label (what the user picked via
-- the volume slider, synced from the server). soundAppliedVolume is what we
-- last actually pushed into xsound, which may be soundBaseVolume scaled down
-- by Config.MuffledVolumeFactor when the vehicle is sealed up and we're not
-- inside it. Keeping these separate means the muffle thread (below) is the
-- single place that decides the real output volume, instead of racing with
-- server-driven volume updates.
local soundBaseVolume         = {}
local soundAppliedVolume      = {}
local soundVolumePending      = {}
local muffleVehHandle         = {}
local muffleResolveThrottleAt = {}
local muffleResolveAttempts   = {}

local function trackLocalSound(label) activeLocalLabels[label] = true end
local function untrackLocalSound(label)
    activeLocalLabels[label] = nil
    soundBaseVolume[label] = nil
    soundAppliedVolume[label] = nil
    soundVolumePending[label] = nil
    muffleVehHandle[label] = nil
    muffleResolveThrottleAt[label] = nil
    muffleResolveAttempts[label] = nil
end

local function safeSetTimeStamp(label, positionOrFn, maxTries)
    maxTries = maxTries or 100
    CreateThread(function()
        local tries = 0
        local confirmations = 0
        while tries < maxTries do
            if not exports.xsound:soundExists(label) then return end
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
    maxTries = maxTries or 60
    CreateThread(function()
        local tries = 0
        while tries < maxTries do
            if exports.xsound:soundExists(label) then
                if soundReady(label) and exports.xsound:isPlaying(label) then
                    pcall(function() exports.xsound:Pause(label) end)
                    return
                end
            else
                return
            end
            tries = tries + 1
            Wait(100)
        end
    end)
end

-- onDone (if given) is always called exactly once, with true if the volume
-- was actually sent to xsound and false if we gave up (sound never became
-- ready, or stopped existing) -- callers that track "is a retry in flight"
-- state need that guarantee to release their guard either way.
local function safeSetVolume(label, volume, maxTries, onDone)
    maxTries = maxTries or 60
    CreateThread(function()
        local tries = 0
        while tries < maxTries do
            if exports.xsound:soundExists(label) then
                if soundReady(label) then
                    local ok = pcall(function() exports.xsound:setVolume(label, volume) end)
                    if onDone then onDone(ok) end
                    return
                end
            else
                if onDone then onDone(false) end
                return
            end
            tries = tries + 1
            Wait(100)
        end
        if onDone then onDone(false) end
    end)
end

local seekGeneration = {}
local function seekTo(label, position, maxTries)
    maxTries = maxTries or 60
    seekGeneration[label] = (seekGeneration[label] or 0) + 1
    local myGen = seekGeneration[label]
    CreateThread(function()
        local tries = 0
        while tries < maxTries do
            if seekGeneration[label] ~= myGen then return end
            if soundReady(label) and exports.xsound:soundExists(label) and exports.xsound:isPlaying(label) then
                pcall(function() exports.xsound:setTimeStamp(label, position) end)
                return
            end
            tries = tries + 1
            Wait(150)
        end
    end)
end

local function sanitizePlaybackUrl(url)
    if not url or url == "" then return url end
    local id = url:match("[?&]v=([%w%-_]+)") or url:match("youtu%.be/([%w%-_]+)")
    if id then
        return "https://www.youtube.com/watch?v=" .. id
    end
    return url
end

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


local endWatchLabel         = nil
local endWatchSeenPlay      = false
local endWatchLastPos       = -1
local endWatchStallTicks    = 0
local endWatchSuppressUntil = 0

local function getEndWatchLabel()
    return currentVehNetId and getUnitLabel(currentVehNetId) or nil
end

local function resetEndWatch()
    endWatchLabel      = getEndWatchLabel()
    endWatchSeenPlay   = false
    endWatchLastPos    = -1
    endWatchStallTicks = 0
end

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
                return
            end
            tries = tries + 1
            Wait(150)
        end
    end)
end

-- ─── Vehicle lookup helpers ────────────────────────────────────

local function findNearestVehicle(coords, maxDist)
    local best, bestDist = nil, maxDist
    for _, veh in ipairs(GetGamePool("CVehicle")) do
        local d = #(coords - GetEntityCoords(veh))
        if d <= bestDist then
            best, bestDist = veh, d
        end
    end
    return best
end

local function findNearestInstalledVehicleNetId(coords, maxDist)
    local best, bestDist = nil, maxDist
    for netId in pairs(installedUnits) do
        local veh = NetworkGetEntityFromNetworkId(netId)
        if veh and veh ~= 0 and DoesEntityExist(veh) then
            local d = #(coords - GetEntityCoords(veh))
            if d <= bestDist then
                best, bestDist = netId, d
            end
        end
    end
    if best then return best end


    local veh = findNearestVehicle(coords, maxDist)
    if not veh or not NetworkGetEntityIsNetworked(veh) then return nil end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    local plate = trimPlate(GetVehicleNumberPlateText(veh))
    if plate == "" then return nil end

    local data = lib.callback.await("mnc-carplay:server:getInstallForPlate", false, netId, plate)
    if data then
        installedUnits[netId] = {
            skin = data.skinId, offset = data.offset, rotation = data.rotation, propModel = data.propModel,
            propHidden = withDefault(data.propHidden, false),
            worldUiEnabled = withDefault(data.worldUiEnabled, true),
        }
        attachTablet(netId)
        return netId
    end
    return nil
end

local function classAllowed(veh)
    if not Config.AllowedVehicleClasses then return true end
    local class = GetVehicleClass(veh)
    for _, c in ipairs(Config.AllowedVehicleClasses) do
        if c == class then return true end
    end
    return false
end


local livePreview = {}
local livePreviewPropModel = {}

local function computeTabletTransform(netId, veh)
    local boneIdx = GetEntityBoneIndexByName(veh, Config.TabletPropBone)
    if not boneIdx or boneIdx == -1 then boneIdx = 0 end
    local boneCoords = GetWorldPositionOfEntityBone(veh, boneIdx)

    local preview  = livePreview[netId]
    local unit     = installedUnits[netId]
    local offset   = (preview and preview.offset) or (unit and unit.offset) or defaultOffset()
    local rotation = (preview and preview.rotation) or (unit and unit.rotation) or defaultRotation()


    local right, forward, up = GetEntityMatrix(veh)
    local pos = vector3(
        boneCoords.x + offset.x * right.x + offset.y * forward.x + offset.z * up.x,
        boneCoords.y + offset.x * right.y + offset.y * forward.y + offset.z * up.y,
        boneCoords.z + offset.x * right.z + offset.y * forward.z + offset.z * up.z
    )


    local vehRot = GetEntityRotation(veh)
    local finalRot = vector3(vehRot.x + rotation.x, vehRot.y + rotation.y, vehRot.z + rotation.z)

    return pos, finalRot, right, forward, up
end

local function syncTabletTransform(netId, obj, veh)
    local pos, finalRot = computeTabletTransform(netId, veh)
    SetEntityCoords(obj, pos.x, pos.y, pos.z, false, false, false, false)
    SetEntityRotation(obj, finalRot.x, finalRot.y, finalRot.z, 2, false)
    return pos, finalRot
end

local function resolvePropHidden(netId)
    local preview = livePreviewToggles[netId]
    if preview and preview.propHidden ~= nil then return preview.propHidden end
    local unit = installedUnits[netId]
    return withDefault(unit and unit.propHidden, false)
end

local function resolveWorldUiEnabled(netId)
    local preview = livePreviewToggles[netId]
    if preview and preview.worldUiEnabled ~= nil then return preview.worldUiEnabled end
    local unit = installedUnits[netId]
    return withDefault(unit and unit.worldUiEnabled, true)
end

-- Cache of the last-known-good vehicle entity handle per netId used by the
-- attached-prop sync loop below, plus a bounded retry counter. Once a netId
-- has failed to resolve VEH_RESOLVE_MAX_ATTEMPTS times in a row we stop
-- asking the network for it -- that's what keeps an orphaned prop (installed
-- unit whose vehicle went away) from hammering NetworkGetEntityFromNetworkId()
-- forever and spamming "GetNetworkObject: no object by ID N" in the console.
local attachedVehHandle        = {}
local vehResolveThrottleAt     = {}
local vehResolveAttempts       = {}
local VEH_RESOLVE_MAX_ATTEMPTS = 10

local function resetVehResolveState(netId)
    attachedVehHandle[netId] = nil
    vehResolveThrottleAt[netId] = nil
    vehResolveAttempts[netId] = nil
end

function attachTablet(netId)
    if attachedProps[netId] then
        debugPrint("attachTablet(netId=" .. tostring(netId) .. "): already have a prop, skipping")
        return
    end
    debugPrint("attachTablet(netId=" .. tostring(netId) .. "): starting attach-wait loop")
    CreateThread(function()
        local tries = 0
        while tries < (Config.TabletAttachMaxTries or 60) do
            local veh = NetworkGetEntityFromNetworkId(netId)
            if veh and veh ~= 0 and DoesEntityExist(veh) and not attachedProps[netId] then
                local unit         = installedUnits[netId]
                local propModelId  = livePreviewPropModel[netId] or resolvePropModelId(unit)
                local propModelStr = resolvePropModelString(propModelId)
                local hash         = propModelStr and loadModel(propModelStr) or nil

                if hash then
                    local offset   = (unit and unit.offset) or defaultOffset()
                    local rotation = (unit and unit.rotation) or defaultRotation()

                    debugPrint("attachTablet(netId=" .. tostring(netId) .. "): creating prop model=" .. tostring(propModelStr)
                        .. " offset=" .. vecStr(offset) .. " rotation=" .. vecStr(rotation)
                        .. " (source=" .. (unit and "installedUnits" or "default") .. ")")

                    local obj = CreateObject(hash, GetEntityCoords(veh), false, true, false)
                    FreezeEntityPosition(obj, true)
                    SetEntityCollision(obj, false, false)
                    SetEntityAsMissionEntity(obj, true, true)
                    SetEntityVisible(obj, not resolvePropHidden(netId), false)
                    SetModelAsNoLongerNeeded(hash)
                    attachedProps[netId] = obj
                    resetVehResolveState(netId)

                    local pos, finalRot = syncTabletTransform(netId, obj, veh)
                    debugPrint("attachTablet(netId=" .. tostring(netId) .. "): created obj=" .. tostring(obj)
                        .. " placed at pos=" .. vecStr(pos) .. " rotation=" .. vecStr(finalRot))
                end
                return
            end
            tries = tries + 1
            Wait(Config.TabletAttachWaitMs or 500)
        end
        debugPrint("Gave up waiting to attach tablet prop for netId=" .. tostring(netId))
    end)
end

local function detachTablet(netId)
    local obj = attachedProps[netId]
    if obj and DoesEntityExist(obj) then
        DeleteEntity(obj)
    end
    attachedProps[netId] = nil
    livePreview[netId] = nil
    livePreviewPropModel[netId] = nil
    livePreviewToggles[netId] = nil
    nowPlaying[netId] = nil
    resetVehResolveState(netId)
end


local function recreateTabletProp(netId)
    local obj = attachedProps[netId]
    if obj and DoesEntityExist(obj) then
        DeleteEntity(obj)
    end
    attachedProps[netId] = nil
    attachTablet(netId)
end


local function repositionTablet(netId, offset, rotation)
    debugPrint("repositionTablet(netId=" .. tostring(netId) .. "): live preview set — offset=" .. vecStr(offset) .. " rotation=" .. vecStr(rotation))
    livePreview[netId] = { offset = offset, rotation = rotation }
end


local function clearLivePreview(netId)
    debugPrint("clearLivePreview(netId=" .. tostring(netId) .. ")")
    livePreview[netId] = nil
end


local function previewPropModelForNetId(netId, propModelId)
    local current = livePreviewPropModel[netId] or resolvePropModelId(installedUnits[netId])
    if current == propModelId then return end
    debugPrint("previewPropModelForNetId(netId=" .. tostring(netId) .. "): " .. tostring(current) .. " -> " .. tostring(propModelId))
    livePreviewPropModel[netId] = propModelId
    recreateTabletProp(netId)
end


local function clearLivePreviewPropModel(netId)
    livePreviewPropModel[netId] = nil
end


local function cancelPropModelPreview(netId)
    if livePreviewPropModel[netId] ~= nil then
        livePreviewPropModel[netId] = nil
        recreateTabletProp(netId)
    end
end


local function vehicleUnitImInRightNow()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or not IsPedInAnyVehicle(ped, false) then return nil end
    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then return nil end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    if installedUnits[netId] then return netId end
    return nil
end

local function updateNowPlayingHud()
    local show  = false
    local title = nil

    local netId = Config.WorldUI.Enabled and vehicleUnitImInRightNow() or nil

    if netId and resolveWorldUiEnabled(netId) then
        local meta = nowPlaying[netId]
        if meta and meta.playing and meta.url and meta.url ~= "" then
            show  = true
            title = meta.title or meta.url
        end
    end

    if show ~= hudShown or (show and title ~= hudLastTitle) then
        SendNUIMessage({ action = "nowPlayingHud", show = show, title = title })
        hudShown     = show
        hudLastTitle = title
    end
end

CreateThread(function()
    while true do
        Wait(500)
        updateNowPlayingHud()
    end
end)


local dancingPeds = {}

local function updateCarDance()
    local dance = Config.DanceAnim
    local eligible = {}

    if Config.EnableCarDance and dance and dance.dict and dance.clip then
        for netId in pairs(installedUnits) do
            local meta = nowPlaying[netId]
            if meta and meta.playing and meta.url and meta.url ~= "" then
                local veh = NetworkGetEntityFromNetworkId(netId)
                if veh and veh ~= 0 and DoesEntityExist(veh) then
                    for seat, suffix in pairs(Config.DanceSeats) do
                        local ped = GetPedInVehicleSeat(veh, seat)
                        if ped and ped ~= 0 and DoesEntityExist(ped) then
                            eligible[ped] = {
                                dict = dance.dict:format(suffix),
                                clip = dance.clip,
                                flag = dance.flag or 1,
                            }
                        end
                    end
                end
            end
        end
    end


    for ped, prev in pairs(dancingPeds) do
        local cur = eligible[ped]
        if not cur or cur.dict ~= prev.dict then
            if DoesEntityExist(ped) then
                StopAnimTask(ped, prev.dict, prev.clip, 1.0)
            end
        end
    end

    -- Start/maintain everyone currently eligible.
    for ped, cur in pairs(eligible) do
        if not HasAnimDictLoaded(cur.dict) then
            RequestAnimDict(cur.dict)
        elseif not IsEntityPlayingAnim(ped, cur.dict, cur.clip, 3) then
            TaskPlayAnim(ped, cur.dict, cur.clip, 8.0, -8.0, -1, cur.flag, 0, false, false, false)
        end
    end

    dancingPeds = eligible
end

CreateThread(function()
    while true do
        Wait(500)
        updateCarDance()
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        for netId, obj in pairs(attachedProps) do
            if not DoesEntityExist(obj) then
                attachedProps[netId] = nil
                resetVehResolveState(netId)
            else
                local veh = attachedVehHandle[netId]
                if not veh or veh == 0 or not DoesEntityExist(veh) then
                    veh = nil
                    local attempts = vehResolveAttempts[netId] or 0
                    if attempts < VEH_RESOLVE_MAX_ATTEMPTS then
                        local now = GetGameTimer()
                        -- Only ask the network layer for a fresh handle a
                        -- couple times a second while unresolved, instead of
                        -- every frame, and give up entirely after
                        -- VEH_RESOLVE_MAX_ATTEMPTS misses in a row -- the 3s
                        -- watchdog below will either reattach the prop once
                        -- the vehicle is actually back, or forget the unit
                        -- for good if it's gone.
                        if (vehResolveThrottleAt[netId] or 0) <= now then
                            vehResolveThrottleAt[netId] = now + 500
                            local resolved = NetworkGetEntityFromNetworkId(netId)
                            if resolved and resolved ~= 0 and DoesEntityExist(resolved) then
                                veh = resolved
                                vehResolveAttempts[netId] = 0
                            else
                                attempts = attempts + 1
                                vehResolveAttempts[netId] = attempts
                                if attempts >= VEH_RESOLVE_MAX_ATTEMPTS then
                                    debugPrint("attachedProps sync: netId=" .. tostring(netId)
                                        .. " unresolved after " .. VEH_RESOLVE_MAX_ATTEMPTS
                                        .. " tries, giving up until the watchdog reattaches or forgets it")
                                end
                            end
                        end
                    end
                    attachedVehHandle[netId] = veh
                end

                if veh then
                    syncTabletTransform(netId, obj, veh)
                    SetEntityVisible(obj, not resolvePropHidden(netId), false)
                end
            end
        end
    end
end)

-- ─── Door/window muffling ──────────────────────────────────────────
-- Every playing carplay sound this client has loaded (activeLocalLabels
-- covers both "I'm riding in/near this vehicle and hearing it live" and any
-- other in-range listener) gets scaled down from its base volume whenever
-- the source vehicle is fully sealed (no open door, no broken/missing
-- window) and we're not one of its occupants. Anyone actually inside the
-- vehicle, or anyone near it with a door or window open, hears it at full
-- volume. This is a local, per-listener decision -- it doesn't touch the
-- server-synced base volume, so it can't drift what the driver's volume
-- slider says.
local function isPedRidingIn(veh)
    local ped = PlayerPedId()
    return DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) == veh
end

-- Returns sealed(bool), reason(string) -- the reason is only for debugPrint
-- below, so we can see exactly which door/window index is keeping a vehicle
-- from reading as sealed instead of guessing.
local function isVehicleSealed(veh)
    for _, doorIdx in ipairs(Config.MuffleDoorIndexes) do
        local ratio = GetVehicleDoorAngleRatio(veh, doorIdx)
        if ratio > 0.0 then return false, "door " .. doorIdx .. " open (ratio=" .. tostring(ratio) .. ")" end
    end
    for _, winIdx in ipairs(Config.MuffleWindowIndexes) do
        if not IsVehicleWindowIntact(veh, winIdx) then return false, "window " .. winIdx .. " not intact" end
    end
    return true, "sealed"
end

local function labelNetId(label)
    return tonumber(label:match("_(%d+)$"))
end

CreateThread(function()
    while true do
        Wait(Config.MuffleCheckInterval or 250)

        for label in pairs(activeLocalLabels) do
            local base = soundBaseVolume[label]
            if base then
                local netId = labelNetId(label)
                local veh = netId and muffleVehHandle[label]

                if netId and (not veh or veh == 0 or not DoesEntityExist(veh)) then
                    veh = nil
                    local attempts = muffleResolveAttempts[label] or 0
                    if attempts < VEH_RESOLVE_MAX_ATTEMPTS then
                        local now = GetGameTimer()
                        if (muffleResolveThrottleAt[label] or 0) <= now then
                            muffleResolveThrottleAt[label] = now + 500
                            local resolved = NetworkGetEntityFromNetworkId(netId)
                            if resolved and resolved ~= 0 and DoesEntityExist(resolved) then
                                veh = resolved
                                muffleResolveAttempts[label] = 0
                            else
                                attempts = attempts + 1
                                muffleResolveAttempts[label] = attempts
                                if attempts >= VEH_RESOLVE_MAX_ATTEMPTS then
                                    debugPrint("muffle check: label=" .. label .. " netId=" .. tostring(netId)
                                        .. " unresolved after " .. VEH_RESOLVE_MAX_ATTEMPTS .. " tries, giving up")
                                end
                            end
                        end
                    end
                    muffleVehHandle[label] = veh
                end

                local occupant = veh and isPedRidingIn(veh)
                local sealed, sealReason = false, "no vehicle handle"
                if veh then
                    sealed, sealReason = isVehicleSealed(veh)
                end
                local effective = base
                if veh and not occupant and sealed then
                    effective = base * (Config.MuffledVolumeFactor or 0.35)
                end

                if Config.Debug then
                    debugPrint(("muffle check: label=%s netId=%s veh=%s occupant=%s sealed=%s (%s) base=%.2f effective=%.2f"):format(
                        label, tostring(netId), tostring(veh), tostring(occupant), tostring(sealed), sealReason, base, effective))
                end

                -- Only mark a volume as "applied" once safeSetVolume actually
                -- confirms it went through. Marking it optimistically here
                -- was a real bug: if the sound wasn't yet "ready" (xsound
                -- readiness can lag several seconds behind PlayUrl, see
                -- soundReady() above) safeSetVolume would silently give up,
                -- but we'd already have recorded the muffled volume as
                -- applied -- so a later un-muffle (or re-muffle) would never
                -- retry, leaving playback stuck at whatever volume was last
                -- genuinely sent. soundVolumePending stops us from stacking
                -- up duplicate retry threads while one is already in flight.
                local applied = soundAppliedVolume[label]
                if not soundVolumePending[label] and (not applied or math.abs(applied - effective) > 0.005) then
                    soundVolumePending[label] = true
                    safeSetVolume(label, effective, 100, function(success)
                        if success then soundAppliedVolume[label] = effective end
                        soundVolumePending[label] = nil
                    end)
                end
            end
        end
    end
end)

-- ─── Auto-close doors on exit ──────────────────────────────────────
-- GTA doesn't shut a vehicle's door behind you when you get out -- it just
-- stays open until something closes it. Without this, the seal check above
-- never sees a Carplay vehicle as "sealed" after anyone gets out, since the
-- door they used is still hanging open. We only do this for vehicles that
-- actually have a Carplay unit installed, so we're not changing door
-- behaviour on every car in the server.
CreateThread(function()
    local lastVehicle = 0
    while true do
        Wait(250)
        local ped = PlayerPedId()
        local veh = 0
        if DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) then
            veh = GetVehiclePedIsIn(ped, false)
        end

        if lastVehicle ~= 0 and veh ~= lastVehicle and DoesEntityExist(lastVehicle) then
            local exitedVeh = lastVehicle
            local netId = NetworkGetNetworkIdFromEntity(exitedVeh)
            debugPrint("door auto-close: exit detected, exitedVeh=" .. tostring(exitedVeh) .. " netId=" .. tostring(netId)
                .. " installed=" .. tostring(installedUnits[netId] ~= nil))
            if installedUnits[netId] then
                CreateThread(function()
                    -- Give the exit animation a moment to finish before
                    -- swinging the door shut, otherwise it can fight the
                    -- ped's own exit motion.
                    Wait(Config.DoorAutoCloseDelayMs or 800)
                    if DoesEntityExist(exitedVeh) then
                        -- Door state is part of the vehicle's networked sync
                        -- tree, authoritative from whichever client currently
                        -- has control of the entity. If we're not that
                        -- client, SetVehicleDoorShut only changes our own
                        -- local view for a moment before the owner's
                        -- still-open state syncs back over it -- which is
                        -- exactly what the debug log showed: the door
                        -- "closes" and then immediately reads as open again
                        -- forever. Take control first so the shut state
                        -- actually sticks and propagates to everyone else.
                        if not NetworkHasControlOfEntity(exitedVeh) then
                            NetworkRequestControlOfEntity(exitedVeh)
                            local tries = 0
                            while not NetworkHasControlOfEntity(exitedVeh) and tries < 20 do
                                Wait(50)
                                tries = tries + 1
                            end
                        end

                        if NetworkHasControlOfEntity(exitedVeh) then
                            for _, doorIdx in ipairs(Config.MuffleDoorIndexes) do
                                local ratio = GetVehicleDoorAngleRatio(exitedVeh, doorIdx)
                                if ratio > 0.0 then
                                    debugPrint("door auto-close: shutting doorIdx=" .. doorIdx .. " (was ratio=" .. tostring(ratio) .. ")")
                                    SetVehicleDoorShut(exitedVeh, doorIdx, false)
                                end
                            end
                        else
                            debugPrint("door auto-close: never got network control of netId=" .. tostring(netId) .. ", giving up")
                        end
                    else
                        debugPrint("door auto-close: exitedVeh no longer exists by the time the delay elapsed")
                    end
                end)
            end
        end

        lastVehicle = veh
    end
end)


local checkedAt = {}

CreateThread(function()
    while true do
        Wait(3000)
        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            local coords = GetEntityCoords(ped)

            -- (1) + (2) — heal or clean up everything we already track
            for netId, unit in pairs(installedUnits) do
                local veh = NetworkGetEntityFromNetworkId(netId)
                local vehExists = veh and veh ~= 0 and DoesEntityExist(veh)

                if not vehExists then
                    local obj = attachedProps[netId]
                    if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
                    attachedProps[netId] = nil
                    installedUnits[netId] = nil
                    checkedAt[netId] = nil
                    nowPlaying[netId] = nil
                    livePreviewToggles[netId] = nil
                    resetVehResolveState(netId)
                    debugPrint("Vehicle netId=" .. tostring(netId) .. " no longer exists (stored/deleted) — prop cleaned up")
                else
                    local obj = attachedProps[netId]
                    if not obj or not DoesEntityExist(obj) then
                        debugPrint("watchdog(netId=" .. tostring(netId) .. "): prop missing entirely, re-attaching from scratch")
                        attachedProps[netId] = nil
                        attachTablet(netId)
                    end

                end
            end

            for _, veh in ipairs(GetGamePool("CVehicle")) do
                if DoesEntityExist(veh) and NetworkGetEntityIsNetworked(veh) and #(coords - GetEntityCoords(veh)) <= 60.0 then
                    local netId = NetworkGetNetworkIdFromEntity(veh)
                    if not installedUnits[netId] then
                        local last = checkedAt[netId] or 0
                        if GetGameTimer() - last > 20000 then
                            checkedAt[netId] = GetGameTimer()
                            local plate = trimPlate(GetVehicleNumberPlateText(veh))
                            if plate ~= "" then
                                local data = lib.callback.await("mnc-carplay:server:getInstallForPlate", false, netId, plate)
                                if data then
                                    installedUnits[netId] = {
                                        skin = data.skinId, offset = data.offset, rotation = data.rotation, propModel = data.propModel,
                                        propHidden = withDefault(data.propHidden, false),
                                        worldUiEnabled = withDefault(data.worldUiEnabled, true),
                                    }
                                    attachTablet(netId)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)



RegisterNetEvent("mnc-carplay:client:beginInstall", function(skinId)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local veh    = findNearestVehicle(coords, Config.InteractDistance)

    if not veh then
        lib.notify({ title = "Carplay", description = "No vehicle nearby to install a unit on.", type = "error" })
        return
    end
    if not classAllowed(veh) then
        lib.notify({ title = "Carplay", description = "This unit can't be installed on that kind of vehicle.", type = "error" })
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    if installedUnits[netId] then
        lib.notify({ title = "Carplay", description = "This vehicle already has a Carplay unit installed.", type = "error" })
        return
    end

    local ok = lib.progressBar({
        duration     = Config.InstallTime,
        label        = "Installing Carplay unit…",
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = Config.InstallAnim,
    })
    if not ok then return end

    TriggerServerEvent("mnc-carplay:server:registerInstall", { netId = netId, skinId = skinId })
end)


RegisterNetEvent("mnc-carplay:client:createUnit", function(data)
    installedUnits[data.netId] = {
        skin      = data.skinId,
        owner     = data.owner,
        offset    = data.offset or defaultOffset(),
        rotation  = data.rotation or defaultRotation(),
        propModel = data.propModel or Config.DefaultTabletProp,
        propHidden     = withDefault(data.propHidden, false),
        worldUiEnabled = withDefault(data.worldUiEnabled, true),
    }
    attachTablet(data.netId)
end)

RegisterNetEvent("mnc-carplay:client:removeUnit", function(netId)
    installedUnits[netId] = nil
    detachTablet(netId)

    local label = getUnitLabel(netId)
    if exports.xsound:soundExists(label) then
        exports.xsound:Destroy(label)
        untrackLocalSound(label)
    end

    if currentVehNetId == netId then
        if isUIOpen then
            SetNuiFocus(false, false)
            SendNUIMessage({ action = "close" })
            isUIOpen = false
        end
        currentVehNetId = nil
        resetEndWatch()
    end
end)


RegisterNetEvent("mnc-carplay:client:positionUpdated", function(netId, payload)
    payload = payload or {}
    local offset, rotation, propModel = payload.offset, payload.rotation, payload.propModel

    debugPrint("event positionUpdated: netId=" .. tostring(netId)
        .. " offset=" .. vecStr(offset) .. " rotation=" .. vecStr(rotation)
        .. " propModel=" .. tostring(propModel)
        .. " propHidden=" .. tostring(payload.propHidden)
        .. " worldUiEnabled=" .. tostring(payload.worldUiEnabled)
        .. " knownLocally=" .. tostring(installedUnits[netId] ~= nil))

    if installedUnits[netId] then
        local prevPropModel = installedUnits[netId].propModel
        installedUnits[netId].offset   = offset
        installedUnits[netId].rotation = rotation
        if payload.propHidden     ~= nil then installedUnits[netId].propHidden     = payload.propHidden end
        if payload.worldUiEnabled ~= nil then installedUnits[netId].worldUiEnabled = payload.worldUiEnabled end
        if propModel then
            installedUnits[netId].propModel = propModel
            if propModel ~= prevPropModel then

                recreateTabletProp(netId)
            end
        end
    end


    clearLivePreview(netId)
    clearLivePreviewPropModel(netId)
    livePreviewToggles[netId] = nil
end)

-- ─── Removal flow (tool use → find nearest installed vehicle) ──

RegisterNetEvent("mnc-carplay:client:beginRemoval", function()
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local netId  = findNearestInstalledVehicleNetId(coords, Config.InteractDistance)

    if not netId then
        lib.notify({ title = "Carplay", description = "No installed Carplay unit nearby.", type = "error" })
        return
    end

    local ok = lib.progressBar({
        duration     = Config.RemoveTime,
        label        = "Removing Carplay unit…",
        useWhileDead = false,
        canCancel    = true,
        disable      = { move = true, car = true, combat = true },
        anim         = Config.RemoveAnim,
    })
    if not ok then return end

    TriggerServerEvent("mnc-carplay:server:removeInstall", netId)
end)


local function vehicleWithUnitImIn()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return nil end
    local veh = GetVehiclePedIsIn(ped, false)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    if installedUnits[netId] then return netId end


    local plate = trimPlate(GetVehicleNumberPlateText(veh))
    if plate == "" then return nil end

    local data = lib.callback.await("mnc-carplay:server:getInstallForPlate", false, netId, plate)
    if data then
        installedUnits[netId] = {
            skin = data.skinId, offset = data.offset, rotation = data.rotation, propModel = data.propModel,
            propHidden = withDefault(data.propHidden, false),
            worldUiEnabled = withDefault(data.worldUiEnabled, true),
        }
        attachTablet(netId)
        return netId
    end
    return nil
end

local function closeUI()
    if not isUIOpen then return end
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    isUIOpen = false
    debugPrint("UI closed")
end

local function openUI(netId)
    if isUIOpen then return end
    currentVehNetId = netId

    local unit = installedUnits[netId]
    currentSkin = unit and unit.skin or Config.CarplaySkins[1].id

    local state     = lib.callback.await("mnc-carplay:server:getState", false, netId) or {}
    local playlists = lib.callback.await("mnc-carplay:server:getPlaylists", false) or {}

    currentRadius = state.radius or Config.DefaultRadius
    currentVolume = state.volume and (state.volume / 100) or Config.DefaultVolume

    SetNuiFocus(true, true)
    isUIOpen = true
    resetEndWatch()

    SendNUIMessage({
        action    = "open",
        skin      = currentSkin,
        playing   = (state.url and state.url ~= "" and not state.paused) and true or false,
        paused    = state.paused or false,
        volume    = state.volume or math.ceil(Config.DefaultVolume * 100),
        radius    = currentRadius,
        url       = state.url or "",
        position  = state.position or 0,
        duration  = currentTrackDuration or 0,
        playlists = playlists,
    })

    debugPrint("UI opened for vehicle netId=" .. netId .. " (skin: " .. tostring(currentSkin) .. ")")
end

if Config.EnableCarplayCommand then
    RegisterCommand(Config.CarplayCommand, function()
        if isUIOpen then
            closeUI()
            return
        end

        local netId = vehicleWithUnitImIn()
        if not netId then
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) then
                lib.notify({ title = "Carplay", description = "You need to be in a vehicle to use Carplay.", type = "error" })
            else
                lib.notify({ title = "Carplay", description = "This vehicle doesn't have a Carplay unit installed.", type = "error" })
            end
            return
        end

        openUI(netId)
    end, false)
end


CreateThread(function()
    while true do
        Wait(1000)
        if isUIOpen then
            local stillIn = false
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                stillIn = NetworkGetNetworkIdFromEntity(veh) == currentVehNetId
            end
            if not stillIn then closeUI() end
        end
    end
end)

-- ─── NUI → client ────────────────────────────────────────────────

local function playFromNui(data, cb)
    if not currentVehNetId then
        if cb then cb({ status = "no_vehicle" }) end
        return
    end

    local url = sanitizePlaybackUrl(data.url)
    if not url or url == "" then
        if cb then cb({ status = "no_url" }) end
        return
    end

    currentVolume = data.volume and (data.volume / 100) or currentVolume

    TriggerServerEvent("mnc-carplay:server:playUrl", {
        netId  = currentVehNetId,
        url    = url,
        volume = currentVolume,
        radius = currentRadius,
    })

    if cb then cb({ status = "ok" }) end
end

RegisterNUICallback("close", function(data, cb)
    closeUI()
    cb("ok")
end)

RegisterNUICallback("playUrl", function(data, cb)
    playFromNui(data, cb)
end)

RegisterNUICallback("shuffle", function(data, cb)
    playFromNui(data, cb)
end)

RegisterNUICallback("stop", function(data, cb)
    if currentVehNetId then
        TriggerServerEvent("mnc-carplay:server:stop", { label = getUnitLabel(currentVehNetId) })
    end
    cb("ok")
end)

RegisterNUICallback("pauseResume", function(data, cb)
    if currentVehNetId then
        TriggerServerEvent("mnc-carplay:server:pauseResume", { label = getUnitLabel(currentVehNetId) })
    end
    cb({ status = "ok" })
end)

RegisterNUICallback("setVolume", function(data, cb)
    local vol = math.max(0.01, math.min(1.0, (data.volume or 50) / 100))
    currentVolume = vol
    if currentVehNetId then
        TriggerServerEvent("mnc-carplay:server:setVolume", { label = getUnitLabel(currentVehNetId), volume = vol })
    end
    cb("ok")
end)

RegisterNUICallback("setRadius", function(data, cb)
    local r = tonumber(data.radius) or Config.DefaultRadius
    r = math.max(Config.MinRadius, math.min(Config.MaxRadius, r))
    currentRadius = r
    if currentVehNetId then
        TriggerServerEvent("mnc-carplay:server:setRadius", { label = getUnitLabel(currentVehNetId), radius = r })
    end
    cb("ok")
end)

RegisterNUICallback("seekTo", function(data, cb)
    local position = math.max(0, tonumber(data.position) or 0)
    if currentVehNetId then
        TriggerServerEvent("mnc-carplay:server:seek", { label = getUnitLabel(currentVehNetId), position = position })
    end
    cb("ok")
end)

RegisterNUICallback("savePlaylist", function(data, cb)
    if not data.name or not data.songs then cb("missing_data") return end
    TriggerServerEvent("mnc-carplay:server:savePlaylist", { name = data.name, songs = data.songs })
    cb("ok")
end)

RegisterNUICallback("deletePlaylist", function(data, cb)
    TriggerServerEvent("mnc-carplay:server:deletePlaylist", { id = data.id })
    cb("ok")
end)

RegisterNUICallback("updatePlaylist", function(data, cb)
    if not data.id or not data.songs then cb("missing_data") return end
    TriggerServerEvent("mnc-carplay:server:updatePlaylist", { id = data.id, songs = data.songs })
    cb("ok")
end)

RegisterNUICallback("getPlaylists", function(data, cb)
    local playlists = lib.callback.await("mnc-carplay:server:getPlaylists", false)
    SendNUIMessage({ action = "updatePlaylists", playlists = playlists or {} })
    cb("ok")
end)

RegisterNUICallback("openPositionModal", function(data, cb)
    if not currentVehNetId then
        debugPrint("NUI openPositionModal: no currentVehNetId — replying no_vehicle")
        cb({ status = "no_vehicle" })
        return
    end

    local unit = installedUnits[currentVehNetId]
    local payload = {
        status      = "ok",
        offset      = (unit and unit.offset) or defaultOffset(),
        rotation    = (unit and unit.rotation) or defaultRotation(),
        range       = {
            offset   = Config.PositionRange.offset,
            rotation = Config.PositionRange.rotation,
        },
        propModel   = resolvePropModelId(unit),
        propOptions = Config.TabletPropOptions,
        propHidden     = withDefault(unit and unit.propHidden, false),
        worldUiEnabled = withDefault(unit and unit.worldUiEnabled, true),
    }
    debugPrint("NUI openPositionModal: netId=" .. tostring(currentVehNetId)
        .. " replying offset=" .. vecStr(payload.offset) .. " rotation=" .. vecStr(payload.rotation)
        .. " propModel=" .. tostring(payload.propModel))
    cb(payload)
end)

RegisterNUICallback("previewPosition", function(data, cb)
    if currentVehNetId and data and data.offset and data.rotation then
        debugPrint("NUI previewPosition: netId=" .. tostring(currentVehNetId)
            .. " raw data.rotation=" .. vecStr(data.rotation))
        repositionTablet(currentVehNetId, data.offset, data.rotation)
    else
        debugPrint("NUI previewPosition: dropped — currentVehNetId=" .. tostring(currentVehNetId)
            .. " data.offset=" .. tostring(data and data.offset) .. " data.rotation=" .. tostring(data and data.rotation))
    end
    cb("ok")
end)

RegisterNUICallback("previewPropModel", function(data, cb)
    if currentVehNetId and data and data.propModel then
        debugPrint("NUI previewPropModel: netId=" .. tostring(currentVehNetId) .. " propModel=" .. tostring(data.propModel))
        previewPropModelForNetId(currentVehNetId, data.propModel)
    else
        debugPrint("NUI previewPropModel: dropped — currentVehNetId=" .. tostring(currentVehNetId)
            .. " data.propModel=" .. tostring(data and data.propModel))
    end
    cb("ok")
end)


RegisterNUICallback("previewToggle", function(data, cb)
    if currentVehNetId and data then
        local existing = livePreviewToggles[currentVehNetId] or {}
        if data.propHidden     ~= nil then existing.propHidden     = data.propHidden end
        if data.worldUiEnabled ~= nil then existing.worldUiEnabled = data.worldUiEnabled end
        livePreviewToggles[currentVehNetId] = existing
        debugPrint("NUI previewToggle: netId=" .. tostring(currentVehNetId)
            .. " propHidden=" .. tostring(existing.propHidden)
            .. " worldUiEnabled=" .. tostring(existing.worldUiEnabled))
        updateNowPlayingHud()
    end
    cb("ok")
end)

RegisterNUICallback("savePosition", function(data, cb)
    if currentVehNetId and data and data.offset and data.rotation then
        debugPrint("NUI savePosition: netId=" .. tostring(currentVehNetId)
            .. " offset=" .. vecStr(data.offset) .. " rotation=" .. vecStr(data.rotation)
            .. " propModel=" .. tostring(data.propModel)
            .. " propHidden=" .. tostring(data.propHidden)
            .. " worldUiEnabled=" .. tostring(data.worldUiEnabled)
            .. " — forwarding to server")
        TriggerServerEvent("mnc-carplay:server:savePosition", {
            netId = currentVehNetId, offset = data.offset, rotation = data.rotation,
            propModel = data.propModel,
            propHidden = data.propHidden, worldUiEnabled = data.worldUiEnabled,
        })
    else
        debugPrint("NUI savePosition: dropped — currentVehNetId=" .. tostring(currentVehNetId)
            .. " data.offset=" .. tostring(data and data.offset) .. " data.rotation=" .. tostring(data and data.rotation))
    end
    cb("ok")
end)

RegisterNUICallback("cancelPosition", function(data, cb)
    if currentVehNetId then
        debugPrint("NUI cancelPosition: netId=" .. tostring(currentVehNetId) .. " dropping live previews, reverting to last-saved values")
        clearLivePreview(currentVehNetId)
        cancelPropModelPreview(currentVehNetId)
        livePreviewToggles[currentVehNetId] = nil
        updateNowPlayingHud()
    end
    cb("ok")
end)


RegisterNUICallback("reportTrackMeta", function(data, cb)
    if currentVehNetId and data and data.title and data.title ~= "" then
        TriggerServerEvent("mnc-carplay:server:reportTrackMeta", {
            netId = currentVehNetId, url = data.url, title = data.title,
        })
    end
    cb("ok")
end)



RegisterNetEvent("mnc-carplay:client:songStarted", function(info)
    if not isUIOpen or not currentVehNetId then return end
    if info.label and info.label ~= getUnitLabel(currentVehNetId) then return end
    SendNUIMessage({
        action   = "songStarted",
        url      = info.url,
        title    = info.title or info.url,
        artwork  = info.artwork or "",
        playing  = true,
        position = 0,
    })
end)


RegisterNetEvent("mnc-carplay:client:nowPlayingUpdate", function(netId, info)
    if not netId then return end
    if not info or not info.url or info.url == "" then
        nowPlaying[netId] = nil
    else
        nowPlaying[netId] = {
            url     = info.url,
            title   = info.title or info.url,
            playing = info.playing or false,
            paused  = info.paused or false,
        }
    end

    updateNowPlayingHud()
end)

RegisterNetEvent("mnc-carplay:client:startAudio", function(data)
    if not data or not data.label or not data.url then return end

    local label      = data.label
    local url        = data.url
    local volume     = data.volume or Config.DefaultVolume
    local position   = tonumber(data.position) or 0
    local receivedAt = GetGameTimer()

    if exports.xsound:soundExists(label) then
        exports.xsound:Destroy(label)
        untrackLocalSound(label)
    end

    markSoundLoading(label)
    exports.xsound:PlayUrl(label, url, volume, false, {
        -- Fires once xsound's JS side has actually finished loading/creating
        -- the player (and, for YouTube, once the YT.Player onReady event has
        -- run) -- the real "safe to seek" signal, unlike isPlaying().
        onPlayStart = function()
            markSoundReady(label)
        end,
    })
    trackLocalSound(label)
    -- This is the "real" volume; the muffle thread below is what actually
    -- decides what gets sent to xsound (full volume, or scaled down if this
    -- vehicle is sealed up and we're not riding in it).
    soundBaseVolume[label] = volume
    soundAppliedVolume[label] = volume

    if not data.paused then
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

    debugPrint("Started carplay audio label=" .. label .. " @ " .. position .. "s" .. (data.paused and " (paused)" or ""))
end)

RegisterNetEvent("mnc-carplay:client:stopAudio", function(data)
    if not data or not data.label then return end
    if data.label == getEndWatchLabel() then resetEndWatch() end
    if exports.xsound:soundExists(data.label) then
        exports.xsound:Destroy(data.label)
    end
    untrackLocalSound(data.label)
end)

RegisterNetEvent("mnc-carplay:client:setVolume", function(data)
    if not data or not data.label then return end
    -- Don't push this straight to xsound -- just update the base volume.
    -- The muffle thread re-applies (base, possibly muffled) within its next
    -- tick, so a slider change still reaches everyone, it just stays subject
    -- to whatever muffling currently applies to each listener.
    soundBaseVolume[data.label] = data.volume
end)

RegisterNetEvent("mnc-carplay:client:setRadius", function(data)
    if not data or not data.label then return end
    if data.label == getEndWatchLabel() then
        currentRadius = data.radius
        if isUIOpen then SendNUIMessage({ action = "radius", radius = data.radius }) end
    end
end)

RegisterNetEvent("mnc-carplay:client:pauseResume", function(data)
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

RegisterNetEvent("mnc-carplay:client:seek", function(data)
    if not data or not data.label then return end
    if exports.xsound:soundExists(data.label) then
        seekTo(data.label, data.position or 0)
        if data.label == getEndWatchLabel() then
            pushTrackMeta({ position = data.position or 0 })
        end
    end
end)

RegisterNetEvent("mnc-carplay:client:playlistSaved", function(playlists)
    if not isUIOpen then return end
    SendNUIMessage({ action = "updatePlaylists", playlists = playlists })
    lib.notify({ title = "Carplay", description = "Playlist saved!", type = "success" })
end)

RegisterNetEvent("mnc-carplay:client:playlistUpdated", function(playlists)
    if not isUIOpen then return end
    SendNUIMessage({ action = "updatePlaylists", playlists = playlists })
end)

-- ─── Lifecycle ───────────────────────────────────────────────────

AddEventHandler("onClientResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for netId in pairs(attachedProps) do
        local obj = attachedProps[netId]
        if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    attachedProps = {}
    nowPlaying = {}
    livePreviewToggles = {}

    for ped, prev in pairs(dancingPeds) do
        if DoesEntityExist(ped) then
            StopAnimTask(ped, prev.dict, prev.clip, 1.0)
        end
    end
    dancingPeds = {}

    for label in pairs(activeLocalLabels) do
        pcall(function()
            if exports.xsound:soundExists(label) then
                exports.xsound:Destroy(label)
            end
        end)
    end
    activeLocalLabels = {}
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(2000)
        TriggerServerEvent("mnc-carplay:server:requestSync")
    end)
end)