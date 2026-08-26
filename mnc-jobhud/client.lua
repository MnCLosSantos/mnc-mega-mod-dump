local QBCore = exports['qb-core']:GetCoreObject()
local currentStyle = Config.DefaultStyle or 1
local lastValues = {}
local playerToggles = {}
local styleLoaded = false
local hudInitialized = false
local isPauseMenuActive = false
local shouldHudBeVisible = false
local cachedPlayerCount = 0

-- Initialize player toggles from config
for field, settings in pairs(Config.HUD) do
    playerToggles[field] = {
        enabled = settings.enabled,
        position = settings.position
    }
end

-- Custom notification function
local function ShowNotification(message, type)
    if not styleLoaded or not hudInitialized then return end
    
    SendNUIMessage({
        action = "showNotification",
        message = message,
        type = type or "success",
        style = Config.Styles[currentStyle]
    })
end

-- Get player count from server (reliable method)
local function GetPlayerCountFromServer()
    QBCore.Functions.TriggerCallback('mnc-hud:getPlayerCount', function(count)
        cachedPlayerCount = count
    end)
end

-- Calculate if HUD should be visible based on config and pause menu state
local function CalculateHudVisibility()
    if Config.ShowOnlyInPauseMenu then
        return isPauseMenuActive
    else
        return not isPauseMenuActive
    end
end

-- Update HUD visibility
local function UpdateHudVisibility()
    if MNC_FREECAM_HIDE then return end  -- freecam guard
    if not styleLoaded or not hudInitialized then
        SendNUIMessage({ action = "hide" })
        shouldHudBeVisible = false
        return
    end

    local newVisibility = CalculateHudVisibility()
    
    if newVisibility ~= shouldHudBeVisible then
        shouldHudBeVisible = newVisibility
        if shouldHudBeVisible then
            SendNUIMessage({ action = "show" })
        else
            SendNUIMessage({ action = "hide" })
        end
    end
end

-- NUI updater
local function updateHUD()
    if MNC_FREECAM_HIDE then return end  -- freecam guard
    if not styleLoaded or not hudInitialized or not shouldHudBeVisible then 
        return
    end

    local playerData = QBCore.Functions.GetPlayerData()
    local cash = playerData.money['cash'] or 0
    local bank = playerData.money['bank'] or 0
    local job = playerData.job and playerData.job.label or "Unemployed"
    local playerName = playerData.charinfo and playerData.charinfo.firstname .. " " .. playerData.charinfo.lastname or GetPlayerName(PlayerId())

    local year, month, day, hour, minute, second = GetLocalTime()
    local formattedTime = string.format("%02d:%02d", hour, minute)

    local playerCount = cachedPlayerCount

    local info = {
        time = formattedTime,
        id = "ID " .. GetPlayerServerId(PlayerId()) .. " - " .. playerName,
        players = playerCount,
        jobOrGang = job,
        bank = bank,
        cash = cash,
        style = Config.Styles[currentStyle],
        toggle = playerToggles,
        currentStyleIndex = currentStyle
    }

    -- Check for changes to trigger effect and track money changes
    for k, v in pairs(info) do
        if type(v) ~= "table" then
            if lastValues[k] ~= nil and lastValues[k] ~= v then
                SendNUIMessage({ action = "effect", field = k })
                if k == "bank" then
                    info.bankChange = v - (lastValues[k] or 0)
                elseif k == "cash" then
                    info.cashChange = v - (lastValues[k] or 0)
                end
            end
            lastValues[k] = v
        end
    end

    SendNUIMessage({ action = "update", data = info })
end

-- Monitor pause menu state
CreateThread(function()
    while true do
        local newPauseState = IsPauseMenuActive()
        if newPauseState ~= isPauseMenuActive then
            isPauseMenuActive = newPauseState
            UpdateHudVisibility()
        end
        Wait(50)
    end
end)

-- Update player count periodically from server (every 30 seconds)
CreateThread(function()
    while true do
        if hudInitialized and styleLoaded then
            GetPlayerCountFromServer()
        end
        Wait(30000)
    end
end)

-- Load player's saved style
local function LoadPlayerStyle()
    QBCore.Functions.TriggerCallback('mnc-hud:getStyle', function(style)
        currentStyle = style
        styleLoaded = true
        ShowNotification("HUD style loaded: " .. Config.Styles[style].name, "success")
        
        GetPlayerCountFromServer()
        
        UpdateHudVisibility()
        CreateThread(function()
            while hudInitialized do
                updateHUD()
                Wait(1000)
            end
        end)
    end)
end

-- Initialize HUD when player is loaded
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SendNUIMessage({ action = "hide" })
    isPauseMenuActive = IsPauseMenuActive()
    LoadPlayerStyle()
    hudInitialized = true
end)

-- Handle player unload
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    styleLoaded = false
    hudInitialized = false
    shouldHudBeVisible = false
    isPauseMenuActive = false
    cachedPlayerCount = 0
    SendNUIMessage({ action = "hide" })
end)

-- Handle script restart or resource stop
AddEventHandler('onClientResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        styleLoaded = false
        hudInitialized = false
        shouldHudBeVisible = false
        isPauseMenuActive = false
        cachedPlayerCount = 0
        SendNUIMessage({ action = "hide" })
    end
end)

-- Handle script start/restart
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        SendNUIMessage({ action = "hide" })
        if QBCore.Functions.GetPlayerData().citizenid then
            isPauseMenuActive = IsPauseMenuActive()
            LoadPlayerStyle()
            hudInitialized = true
        end
    end
end)

-- Legacy command for backwards compatibility
RegisterCommand("jobhud", function(_, args)
    if not styleLoaded or not hudInitialized then
        ShowNotification("Please wait for HUD to initialize", "error")
        return
    end

    local styleNum = tonumber(args[1])
    if styleNum and Config.Styles[styleNum] then
        currentStyle = styleNum
        ShowNotification("HUD style changed to " .. styleNum .. " - " .. Config.Styles[styleNum].name, "success")
        TriggerServerEvent('mnc-hud:saveStyle', styleNum)
        UpdateHudVisibility()
        if shouldHudBeVisible then
            updateHUD()
        end
    else
        ShowNotification("Please provide a valid style number (e.g., /jobhud 1)", "error")
    end
end)

-- HUD Help UI
RegisterCommand("hudhelp", function()
    local styles = {}
    for i, style in ipairs(Config.Styles) do
        styles[#styles+1] = {
            index = i,
            name = style.name,
            bg = style.bg,
            text = style.text,
            accent = style.accent
        }
    end

    SendNUIMessage({
        action = "openHudHelp",
        styles = styles,
        guide = [[# Command Guide
/jobhud [number] - Change Job HUD style
/weaponui [number] - Change Weapon HUD style
# Example Commands
Example: "/jobhud 15"
Example: "/weaponui 15"
]]
    })

    SetNuiFocus(true, true)
end)

-- Close from NUI
RegisterNUICallback("closeHudHelp", function(_, cb)
    SetNuiFocus(false, false)
    cb("ok")
    UpdateHudVisibility()
end)

-- ============================================================
-- /freecamhideuis — Toggle mnc-jobhud + companion HUDs
-- ============================================================
MNC_FREECAM_HIDE = false
CreateThread(function()
    while true do
        if MNC_FREECAM_HIDE then
            SendNUIMessage({ action = "hide" })
            DisplayRadar(false)
            DisplayHud(false)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Tracks whether companion HUDs are currently visible.
-- Starts true so the first off-duty call correctly toggles them off.
local MNC_COMPANION_HUDS_VISIBLE = true

--- Show or hide all companion HUDs.
--- Guards against double-calling (toggle commands only fire on state change).
--- @param visible boolean
function MNC_SetCompanionHUDs(visible)
    if MNC_COMPANION_HUDS_VISIBLE == visible then return end
    MNC_COMPANION_HUDS_VISIBLE = visible
    -- jim-mechanic: /showodo toggles the odo/fuel/gear/speed HUD on/off
    ExecuteCommand("showodo")
    -- 919-speedlimits: /togglespeed toggles the speed limit sign on/off
    ExecuteCommand("togglespeed")
    -- mnc-boostgauge: event-based
    TriggerEvent('mnc-boostgauge:setVisible', visible)
    -- mnc-weaponui: event-based
    TriggerEvent('mnc-weaponui:setVisible', visible)
    -- mnc-safezones: event-based
    TriggerEvent('mnc-safezones:setVisible', visible)
end

AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    local pd = QBCore and QBCore.Functions.GetPlayerData() or nil
    if pd and pd.job then
        MNC_SetCompanionHUDs(pd.job.onduty == true)
    end
end)

AddEventHandler('QBCore:Client:SetDuty', function(onDuty)
    MNC_SetCompanionHUDs(onDuty == true)
end)

CreateThread(function()
    local timeout = 0
    while QBCore == nil and timeout < 60 do
        Wait(500)
        timeout = timeout + 1
    end
    if QBCore == nil then return end
    Wait(2500)
    local pd = QBCore.Functions.GetPlayerData()
    if pd and pd.job then
        local onDuty = pd.job.onduty == true
        MNC_COMPANION_HUDS_VISIBLE = not onDuty
        MNC_SetCompanionHUDs(onDuty)
    end
end)

local function applyHideUIs()
    SendNUIMessage({ action = "hide" })
    TriggerEvent('mnc-freecam:qbhud:SetVisible', false)
    TriggerEvent('mnc-boostgauge:setVisible', false)
    TriggerEvent('mnc-weaponui:setVisible', false)
    TriggerEvent('mnc-safezones:setVisible', false)
    ExecuteCommand("showodo")
    ExecuteCommand("togglespeed")
    QBCore.Functions.Notify('UIs hidden', 'primary')
end

local function applyShowUIs()
    DisplayRadar(true)
    DisplayHud(true)
    TriggerEvent('mnc-freecam:qbhud:SetVisible', true)
    TriggerEvent('mnc-boostgauge:setVisible', true)
    TriggerEvent('mnc-weaponui:setVisible', true)
    TriggerEvent('mnc-safezones:setVisible', true)
    ExecuteCommand("showodo")
    ExecuteCommand("togglespeed")
    if styleLoaded and hudInitialized then
        shouldHudBeVisible = false
        UpdateHudVisibility()
        updateHUD()
    end
    QBCore.Functions.Notify('UIs restored', 'success')
end

-- ─────────────────────────────────────────────
-- MNC_SetFreecamHide(bool)
-- Explicit-state setter used by mnc-freecam client.lua via local event.
-- Replaces the old toggle-based ExecuteCommand approach so callers can
-- request hide=true or hide=false without risking double-flip.
-- ─────────────────────────────────────────────
AddEventHandler('mnc-freecam:setHideUIs', function(hide)
    if MNC_FREECAM_HIDE == hide then return end  -- already in requested state, no-op
    MNC_FREECAM_HIDE = hide
    if MNC_FREECAM_HIDE then
        applyHideUIs()
    else
        applyShowUIs()
    end
end)

-- /freecamhideuis — manual toggle command (kept for admin/debug use)
RegisterCommand("freecamhideuis", function()
    MNC_FREECAM_HIDE = not MNC_FREECAM_HIDE
    if MNC_FREECAM_HIDE then
        applyHideUIs()
    else
        applyShowUIs()
    end
end, false)

-- /jobhudhideuis — manual toggle command (kept for admin/debug use)
RegisterCommand("jobhudhideuis", function()
    MNC_FREECAM_HIDE = not MNC_FREECAM_HIDE
    if MNC_FREECAM_HIDE then
        applyHideUIs()
    else
        applyShowUIs()
    end
end, false)