local QBCore = exports['qb-core']:GetCoreObject()
local ox_lib = exports.ox_lib

local previewOpen = false

-- ==============================
-- Helpers
-- ==============================

-- Same fallback logic as mnc-boostgauge/client_items.lua's GetItemLabel:
-- use the qb-core shared item label if the item exists, otherwise prettify the item name.
local function GetItemLabel(itemName)
    local item = QBCore.Shared.Items and QBCore.Shared.Items[itemName]
    if item and item.label then
        return item.label
    end
    return (itemName:gsub('_', ' ')):gsub('^%l', string.upper)
end

local function BuildStyleList()
    local list = {}
    for itemName, id in pairs(Config.StyleItems) do
        list[id] = { id = id, label = GetItemLabel(itemName), item = itemName }
    end
    -- fill any gaps so the grid never has a missing card
    for i = 1, Config.StylesCount do
        if not list[i] then
            list[i] = { id = i, label = ('Style %d'):format(i), item = nil }
        end
    end
    return list
end

local function BuildBezelList()
    local list = {}
    for itemName, id in pairs(Config.BezelItems) do
        list[id] = { id = id, label = GetItemLabel(itemName), item = itemName }
    end
    for i = 1, Config.BezelsCount do
        if not list[i] then
            list[i] = { id = i, label = ('Bezel %d'):format(i), item = nil }
        end
    end
    return list
end

local function BuildPresetList()
    local list = {}
    -- Config.Presets keys are presetN - sort numerically so they render in order
    local keys = {}
    for key in pairs(Config.Presets) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        return (tonumber(a:match('%d+')) or 0) < (tonumber(b:match('%d+')) or 0)
    end)
    for _, key in ipairs(keys) do
        local p = Config.Presets[key]
        list[#list + 1] = { key = key, label = p.label, style = p.style, bezel = p.bezel }
    end
    return list
end

local stylesData = BuildStyleList()
local bezelsData = BuildBezelList()
local presetsData = BuildPresetList()

-- ==============================
-- Open / Close
-- ==============================
function OpenPreview()
    if previewOpen then return end
    previewOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = {
            styles = stylesData,
            bezels = bezelsData,
            presets = presetsData,
            stylesCount = Config.StylesCount,
            bezelsCount = Config.BezelsCount,
            defaultStyle = Config.DefaultPreviewStyle,
            defaultBezel = Config.DefaultPreviewBezel,
            bezelThickness = Config.BezelThickness,
            gaugeResource = Config.SourceResource,
        }
    })
end

function ClosePreview()
    if not previewOpen then return end
    previewOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    ClosePreview()
    cb({})
end)

RegisterNetEvent('mnc-boostpreview:open', function()
    OpenPreview()
end)

-- ==============================
-- Command + keybind
-- ==============================
local function HasAllowedJob()
    if not Config.RestrictCommandToJobs then return true end
    local PlayerData = QBCore.Functions.GetPlayerData()
    return PlayerData and PlayerData.job and Config.AllowedJobs[PlayerData.job.name] or false
end

RegisterCommand(Config.OpenCommand, function()
    if not HasAllowedJob() then
        ox_lib:notify({
            title = 'Boost Gauge Preview',
            description = 'You are not authorized to use this command.',
            type = 'error'
        })
        return
    end
    OpenPreview()
end, false)

if Config.RegisterKeybind then
    RegisterKeyMapping(Config.OpenCommand, 'Open Boost Gauge Preview', 'keyboard', Config.DefaultKeybind or 'F6')
end

-- ==============================
-- Press [E] display points
-- ==============================
local function DrawText3D(coords, text)
    local onScreen, sx, sy = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    local camCoords = GetGameplayCamCoords()
    local dist = #(camCoords - coords)
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0 * scale, 0.35 * scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(sx, sy)

    local factor = string.len(text) / 370
    DrawRect(sx, sy + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
end

CreateThread(function()
    if #Config.Locations == 0 then return end

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        local nearest, nearestDist = nil, nil
        for _, loc in ipairs(Config.Locations) do
            local dist = #(pCoords - loc.coords)
            if not nearestDist or dist < nearestDist then
                nearest = loc
                nearestDist = dist
            end
        end

        if nearest and nearestDist <= Config.DrawDistance then
            sleep = 0

            if nearestDist <= Config.PromptDistance then
                if Config.UseMarker then
                    local c = Config.MarkerColor
                    DrawMarker(2, nearest.coords.x, nearest.coords.y, nearest.coords.z + 0.5,
                        0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.35, 0.35, 0.35,
                        c.r, c.g, c.b, c.a or 120, false, true, 2, false, nil, nil, false)
                end

                DrawText3D(nearest.coords, ('[E] %s'):format(nearest.label or 'View Boost Gauges'))

                if not previewOpen and IsControlJustReleased(0, Config.KeyPrompt) then
                    OpenPreview()
                end
            end
        end

        Wait(sleep)
    end
end)

-- Optional ox_target integration (used alongside the press-E prompt, not instead of it)
CreateThread(function()
    if not Config.UseOxTarget then return end
    if GetResourceState('ox_target') ~= 'started' then
        if Config.Debug then
            print('^3[mnc-boostpreview]^7 Config.UseOxTarget is true but ox_target is not started - skipping target zones')
        end
        return
    end

    for _, loc in ipairs(Config.Locations) do
        exports.ox_target:addSphereZone({
            coords = loc.coords,
            radius = 1.5,
            debug = Config.Debug,
            options = {
                {
                    label = loc.label or 'View Boost Gauges',
                    icon = 'fa-solid fa-gauge-high',
                    onSelect = function()
                        OpenPreview()
                    end
                }
            }
        })
    end
end)