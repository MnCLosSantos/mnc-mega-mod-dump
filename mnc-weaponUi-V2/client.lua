local QBCore = exports['qb-core']:GetCoreObject()
local currentWeapon, currentAmmo = nil, 0
local currentStyle = Config.DefaultStyle
local playerLoaded = false
local styleLoaded = false

-- Custom notification function
function ShowNotification(type, title, description)
    SendNUIMessage({
        action = "notify",
        type = type,
        title = title,
        description = description,
        style = currentStyle,
        ui = Config.NotifyUI
    })
end

-- Initialize when player is loaded
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    print("[mnc-weaponui] Player loaded, fetching style")
    playerLoaded = true
    LoadPlayerStyle()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    print("[mnc-weaponui] Player unloaded")
    playerLoaded = false
    styleLoaded = false
    SendNUIMessage({ action = "hide" })
end)

-- Load player's saved style
function LoadPlayerStyle()
    QBCore.Functions.TriggerCallback('mnc-weaponui:getStyle', function(style)
        currentStyle = style or Config.DefaultStyle
        styleLoaded = true
        print("[mnc-weaponui] Loaded style: " .. currentStyle .. " (" .. Config.Styles[currentStyle].name .. ")")
        if currentWeapon then
            print("[mnc-weaponui] Weapon active, sending UI data")
            SendWeaponData()
        end
    end)
end

-- Helper: Detect if currently using a vehicle-mounted weapon (automatic, no list needed for most cases)
local function IsUsingVehicleWeapon(ped)
    local weapon = GetSelectedPedWeapon(ped)
    if weapon == `WEAPON_UNARMED` then return false end
    
    local weaponName = GetWeaponNameFromHash and GetWeaponNameFromHash(weapon) or ""
    return string.find(weaponName:upper(), "VEHICLE_WEAPON_") ~= nil
end

-- Minimal fallback list for vehicles that do NOT switch to VEHICLE_WEAPON_* (e.g. fire trucks with water cannon)
local specialWeaponizedVehicles = {
    "firetruk",         -- Standard fire truck
    "firetruck",        -- Alternative name some servers use
    "fireeng",
    "lsfdtruck",
    "lsfdtruck2",
    "lsfdtruck3",
    "lsfd2",
    "lsfd5",
    "lsfd3",
    "lsfd4",
    "lsfd",
    -- Add only if needed: "ambulance", "policeb", etc. (very rare cases)
}

-- Helper: Check if in a special non-switching weaponized vehicle
local function IsInSpecialWeaponizedVehicle(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return false end
    
    local model = GetEntityModel(veh)
    for _, name in ipairs(specialWeaponizedVehicles) do
        if model == GetHashKey(name) then
            return true
        end
    end
    return false
end

-- External visibility flag — set false by mnc-jobhud to force-hide this UI.
-- TriggerEvent('mnc-weaponui:setVisible', false)  -- hide
-- TriggerEvent('mnc-weaponui:setVisible', true)   -- show
local MNC_WEAPONUI_VISIBLE = true

AddEventHandler('mnc-weaponui:setVisible', function(v)
    if MNC_WEAPONUI_VISIBLE == v then return end
    MNC_WEAPONUI_VISIBLE = v
    if not v then
        -- Force hide immediately
        currentWeapon = nil
        currentAmmo = 0
        SendNUIMessage({ action = "hide" })
    end
    -- When restoring, the main loop naturally re-shows on next weapon check
end)

-- Helper: Should we show the personal weapon UI?
local function shouldShowWeaponUI()
    -- Externally force-hidden by mnc-jobhud
    if not MNC_WEAPONUI_VISIBLE then return false end

    if not playerLoaded or not styleLoaded then return false end
    
    -- Always hide in pause menu
    if IsPauseMenuActive() then return false end
    
    local ped = PlayerPedId()
    
    -- Hide if actively using vehicle-mounted weapon (most common case - automatic)
    if IsUsingVehicleWeapon(ped) then return false end
    
    -- Hide in special vehicles that don't use standard vehicle weapons (e.g. fire truck water cannon)
    if IsInSpecialWeaponizedVehicle(ped) then return false end
    
    -- Normal personal weapon check
    local weapon = GetSelectedPedWeapon(ped)
    return weapon ~= `WEAPON_UNARMED`
end

-- Main weapon tracking thread
CreateThread(function()
    -- Wait for resource initialization
    Wait(2000)
    
    -- Check if player is already loaded
    if not playerLoaded then
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.citizenid then
            print("[mnc-weaponui] Player already loaded, fetching style")
            playerLoaded = true
            LoadPlayerStyle()
        end
    end
    
    while true do
        Wait(110)
        
        if playerLoaded and styleLoaded then
            local ped = PlayerPedId()
            
            if not shouldShowWeaponUI() then
                if currentWeapon ~= nil then
                    print("[mnc-weaponui] Hiding UI → pause / vehicle weapon / special vehicle / unarmed")
                    currentWeapon = nil
                    currentAmmo = 0
                    SendNUIMessage({ action = "hide" })
                end
                Wait(280)
                goto continue
            end
            
            local weapon = GetSelectedPedWeapon(ped)
            local ammo   = GetAmmoInPedWeapon(ped, weapon)
            
            if weapon ~= currentWeapon or ammo ~= currentAmmo then
                print("[mnc-weaponui] Weapon changed or ammo updated: " .. weapon .. ", Ammo: " .. ammo)
                currentWeapon = weapon
                currentAmmo = ammo
                SendWeaponData()
            end
        end
        
        ::continue::
    end
end)

-- Safety net thread (handles respawn, menu glitches, etc.)
CreateThread(function()
    while true do
        Wait(700)
        if currentWeapon and not shouldShowWeaponUI() then
            SendNUIMessage({ action = "hide" })
            currentWeapon = nil
            currentAmmo = 0
        end
    end
end)

-- Send data to UI
function SendWeaponData()
    if not currentWeapon or not playerLoaded or not styleLoaded then 
        print("[mnc-weaponui] SendWeaponData blocked - weapon: " .. tostring(currentWeapon) .. ", playerLoaded: " .. tostring(playerLoaded) .. ", styleLoaded: " .. tostring(styleLoaded))
        return 
    end
    
    if not shouldShowWeaponUI() then
        SendNUIMessage({ action = "hide" })
        return
    end
    
    local hash = currentWeapon
    local weaponInfo = QBCore.Shared.Weapons[hash]
    local weaponName = weaponInfo and weaponInfo.label or "Unknown"
    local image = GetWeaponImage(hash)

    local data = {
        action = "show",
        weapon = weaponName,
        ammo = currentAmmo,
        image = image,
        style = currentStyle,
        ui = Config.UI
    }
    
    print("[mnc-weaponui] Sending NUI data: " .. json.encode(data))
    SendNUIMessage(data)
end

-- Get weapon image from qb, ox, or quasar inventory
function GetWeaponImage(hash)
    local weaponInfo = QBCore.Shared.Weapons[hash]
    if not weaponInfo then 
        print("[mnc-weaponui] No weapon info for hash: " .. hash)
        return "" 
    end
    local weaponName = weaponInfo.name:lower()

    local imagePath
    if Config.UseOxInventory then
        imagePath = "nui://ox_inventory/web/images/" .. weaponName .. ".png"
    elseif Config.UseQbInventory then
        imagePath = "nui://qb-inventory/html/images/" .. weaponName .. ".png"
    elseif Config.UseQuasarInventory then
        imagePath = "nui://qs-inventory/html/images/" .. weaponName .. ".png"
    else
        imagePath = ""
    end
    print("[mnc-weaponui] Weapon image path: " .. imagePath)
    return imagePath
end

-- Switch styles with database saving
RegisterCommand(Config.StyleCommand, function(_, args)
    if not playerLoaded then
        ShowNotification('error', 'Weapons', 'Please wait for player data to load')
        return
    end

    local style = tonumber(args[1])
    if style and style >= 1 and style <= 25 then
        currentStyle = style
        TriggerServerEvent('mnc-weaponui:saveStyle', style)
        if currentWeapon then
            SendWeaponData()
        end
        ShowNotification('success', 'Weapons', 'Weapon UI style set to ' .. Config.Styles[style].name .. ' and saved!')
    else
        ShowNotification('error', 'Weapons', 'Invalid style! Use: /' .. Config.StyleCommand .. ' [1-25]')
    end
end)