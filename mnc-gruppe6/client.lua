-- client.lua - mnc-gruppe6 (FINAL: Both phases require return to depot + Withdraw wages for loan AND cash)
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local hasUniform = false
local originalClothes = nil
local activeRoute = nil
local loanIndex = 0
local cashIndex = 0
local activeBlip = nil
local zoneRefs = {}
local nuiOpen = false
local lastUniformAttempt = 0
local loanPhaseComplete = false
local cashPhaseComplete = false

-- Debug
local function dbg(msg)
    if Config.Debug then print("^3[GRUPPE6-DEBUG]^7 " .. tostring(msg)) end
end

-- Notify
local function Notify(msg, type, duration)
    type = type or "success"
    duration = duration or Config.DefaultNotifyTime or 15000
    if Config.Notify == "ox" and lib then
        lib.notify({ title = "Gruppe 6", description = msg, type = type, duration = duration })
    else
        QBCore.Functions.Notify(msg, type, duration)
    end
    dbg("Notify: " .. msg)
end

-- Progress Bar
local function DoProgress(label, duration, dict, anim)
    local ped = PlayerPedId()
    if dict and anim then
        lib.requestAnimDict(dict)
        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    end
    local success = false
    if Config.Progress == "qb" then
        QBCore.Functions.Progressbar("gruppe6_job", label, duration, false, true, {
            disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true,
        }, {}, {}, {}, function() success = true end, function() success = false end)
        Wait(duration + 100)
    elseif Config.Progress == "circle" and lib then
        success = lib.progressCircle({duration = duration, label = label, position = "bottom", useWhileDead = false, canCancel = true,
            disable = {move = true, car = true, combat = true},
            anim = dict and anim and {dict = dict, clip = anim} or nil}) == true
    elseif Config.Progress == "bar" and lib then
        success = lib.progressBar({duration = duration, label = label, useWhileDead = false, canCancel = true,
            disable = {move = true, car = true, combat = true},
            anim = dict and anim and {dict = dict, clip = anim} or nil})
    else
        Wait(duration)
        success = true
    end
    if dict and anim then ClearPedTasks(ped) end
    return success
end

-- Minigame
local function DoMinigame()
    if not Config.Minigame.Enabled then return true end
    local length = math.random(Config.Minigame.MinLength, Config.Minigame.MaxLength)
    local useNumbers = math.random(1, 2) == 1
    local inputs = useNumbers and {'1', '2', '3', '4'} or {'w', 'a', 's', 'd'}
    local settings = { easy = {areaSize = 60, speedMultiplier = 1.0}, medium = {areaSize = 40, speedMultiplier = 1.5}, hard = {areaSize = 25, speedMultiplier = 2.0} }
    local diff = settings[Config.Minigame.Difficulty] or settings.medium
    local difficulty = {}
    for i = 1, length do difficulty[i] = diff end
    local success = lib.skillCheck(difficulty, inputs)
    if success then Notify("SUCCESS!", "success") else Notify("FAILED!", "error") end
    return success
end

-- Blip helpers
local function removeActiveBlip()
    if activeBlip and DoesBlipExist(activeBlip) then RemoveBlip(activeBlip) activeBlip = nil end
end

local function createRouteBlip(coords, stage, name)
    removeActiveBlip()
    local cfg = stage == "loan" and Config.Blips.Loan or Config.Blips.Cash
    activeBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(activeBlip, cfg.sprite)
    SetBlipColour(activeBlip, cfg.color)
    SetBlipScale(activeBlip, cfg.scale)
    SetBlipAsShortRange(activeBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name or cfg.text)
    EndTextCommandSetBlipName(activeBlip)
    SetNewWaypoint(coords.x, coords.y)
end

-- Static depot blip
CreateThread(function()
    Wait(1000)
    if Config.Blips.Depot.enabled then
        local b = AddBlipForCoord(Config.Depot.x, Config.Depot.y, Config.Depot.z)
        SetBlipSprite(b, Config.Blips.Depot.sprite)
        SetBlipColour(b, Config.Blips.Depot.color)
        SetBlipScale(b, Config.Blips.Depot.scale)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blips.Depot.text)
        EndTextCommandSetBlipName(b)
    end
end)

-- qb-target zone
CreateThread(function()
    while not exports['qb-target'] do Wait(1000) end
    exports['qb-target']:AddBoxZone("mnc_gruppe6_schedule", Config.SchedulePickup.coords, Config.ZoneSize.x, Config.ZoneSize.y, {
        name = "mnc_gruppe6_schedule", heading = Config.SchedulePickup.heading, debugPoly = Config.Debug,
        minZ = Config.SchedulePickup.coords.z - 1.5, maxZ = Config.SchedulePickup.coords.z + 1.5,
    }, {
        options = {{ type = "client", event = "mnc-gruppe6:client:OpenScheduleMenu", icon = "fas fa-clipboard-list", label = "Gruppe 6 - Open Menu" }},
        distance = 2.5
    })
end)

-- MENU
RegisterNetEvent("mnc-gruppe6:client:OpenScheduleMenu", function()
    PlayerData = QBCore.Functions.GetPlayerData()

    -- Check if job is required and player doesn't have it
    if Config.JobRequired and PlayerData.job.name ~= Config.JobName then
        return Notify("You must be employed by Gruppe 6 to access this menu.", "error")
    end

    -- Separate check for duty requirement
    if Config.RequireOnDuty and not PlayerData.job.onduty then
        return Notify("You must be clocked in to access this menu.", "error")
    end

    local options = {
        -- Changes title depending on whether job is required
        { header = Config.JobRequired and "Gruppe 6 Depot" or "Public Collection Route", isMenuHeader = true },
        { header = "Take Schedule", txt = "Start collection route", params = { event = "mnc-gruppe6:client:RequestSchedule" } },
        { header = "Put on Uniform", txt = "Change into Gruppe 6 outfit", params = { event = "mnc-gruppe6:client:ChangeIntoUniform" } },
        { header = "Civilian Clothes", txt = "Change back", params = { event = "mnc-gruppe6:client:ChangeToCivilian" } },
    }

    if loanPhaseComplete then
        table.insert(options, #options, { header = "Withdraw Loan Wages", txt = "Collect your $"..Config.LoanPayout.." payment", params = { event = "mnc-gruppe6:client:WithdrawLoanWages" } })
    end

    if cashPhaseComplete then
        table.insert(options, #options, { header = "Withdraw Final Wages", txt = "Collect your $"..Config.CashPayout.." payment", params = { event = "mnc-gruppe6:client:WithdrawCashWages" } })
    end

    if activeRoute and loanIndex > #activeRoute.loan and cashIndex == 0 and not loanPhaseComplete then
        table.insert(options, #options, { header = "Start Cash Phase", txt = "Begin cash collections", params = { event = "mnc-gruppe6:client:StartCashPhase" } })
    end

    table.insert(options, { header = "Close", isMenuHeader = true })

    if Config.Menu == "qb" then
        exports['qb-menu']:openMenu(options)
    else
        local libOpts = {}
        for _, opt in ipairs(options) do
            if not opt.isMenuHeader then
                libOpts[#libOpts+1] = { title = opt.header, description = opt.txt or "", onSelect = function() TriggerEvent(opt.params.event) end }
            end
        end
        lib.registerContext({ id = 'gruppe6_menu', title = 'Gruppe 6', options = libOpts })
        lib.showContext('gruppe6_menu')
    end
end)

-- Clothing
RegisterNetEvent("mnc-gruppe6:client:ChangeIntoUniform", function()
    local now = GetGameTimer()
    if now - lastUniformAttempt < 30000 and hasUniform then return end
    lastUniformAttempt = now
    if hasUniform then 
        Notify("You are already wearing the Gruppe 6 uniform!", "error") 
        return 
    end
    
    -- Get gender from QBCore data (0 = male, 1 = female)
    PlayerData = QBCore.Functions.GetPlayerData()
    local charGender = PlayerData.charinfo.gender
    local gender = (charGender == 0) and "male" or "female"
    
    local ped = PlayerPedId()
    local outfit = Uniforms.Gruppe6[gender].outfit
    
    dbg("=== CHANGING INTO UNIFORM ===")
    dbg("Gender detected: " .. gender)
    
    -- Save original clothes
    originalClothes = { components = {}, props = {} }
    for i = 0, 11 do 
        originalClothes.components[i] = { 
            drawable = GetPedDrawableVariation(ped, i), 
            texture = GetPedTextureVariation(ped, i) 
        } 
    end
    for i = 0, 7 do 
        originalClothes.props[i] = { 
            drawable = GetPedPropIndex(ped, i), 
            texture = GetPedPropTextureIndex(ped, i) 
        } 
    end
    
    -- Apply outfit components (standard GTA V clothing slots)
    local compMap = { 
        tshirt = 8,   -- Undershirt
        torso2 = 11,  -- Tops
        pants = 4,    -- Legs
        shoes = 6,    -- Shoes
        arms = 3,     -- Arms/Gloves
        decals = 10,  -- Decals
        vest = 9,     -- Body Armor/Vests
        bag = 5       -- Bags/Parachutes
    }
    
    -- Apply each component
    for key, componentId in pairs(compMap) do 
        if outfit[key] then 
            local item = outfit[key].item or 0
            local texture = outfit[key].texture or 0
            dbg(string.format("Setting %s (slot %d): item=%d, texture=%d", key, componentId, item, texture))
            SetPedComponentVariation(ped, componentId, item, texture, 0)
        else
            dbg(string.format("Warning: %s not found in outfit config", key))
        end 
    end
    
    -- Apply hat (prop slot 0)
    if outfit.hat then
        if outfit.hat.item ~= -1 then 
            dbg(string.format("Setting hat: item=%d, texture=%d", outfit.hat.item, outfit.hat.texture or 0))
            SetPedPropIndex(ped, 0, outfit.hat.item, outfit.hat.texture or 0, true)
        else 
            dbg("Clearing hat (no hat in config)")
            ClearPedProp(ped, 0)
        end
    end
    
    hasUniform = true
    dbg("=== UNIFORM APPLIED ===")
    Notify("Gruppe 6 uniform equipped!", "success")
    
    -- Auto-debug after 500ms to verify
    if Config.Debug then
        SetTimeout(500, function()
            print("^3[Auto-verify after uniform change]^7")
            ExecuteCommand("debugoutfit")
        end)
    end
end)

RegisterNetEvent("mnc-gruppe6:client:ChangeToCivilian", function()
    if not hasUniform or not originalClothes then Notify("You are not wearing the Gruppe 6 uniform!", "error") return end
    local ped = PlayerPedId()
    for i = 0, 11 do local c = originalClothes.components[i] SetPedComponentVariation(ped, i, c.drawable, c.texture, 0) end
    for i = 0, 7 do local p = originalClothes.props[i] if p.drawable == -1 then ClearPedProp(ped, i) else SetPedPropIndex(ped, i, p.drawable, p.texture, true) end end
    hasUniform = false originalClothes = nil
    Notify("Back to civilian clothes.", "success")
end)

-- Job Start
RegisterNetEvent("mnc-gruppe6:client:RequestSchedule", function()
    if activeRoute then return Notify("Finish your current route first!", "error") end
    if Config.RequireUniformBeforeWork and not hasUniform then return Notify("You must wear the Gruppe 6 uniform first.", "error") end
    TriggerServerEvent("mnc-gruppe6:server:RequestSchedule")
end)

RegisterNetEvent("mnc-gruppe6:client:ReceiveSchedule", function(route)
    activeRoute = route
    loanIndex = 1
    cashIndex = 0
    loanPhaseComplete = false
    cashPhaseComplete = false
    for _, z in pairs(zoneRefs) do exports['qb-target']:RemoveZone(z.id) end
    zoneRefs = {}
    createLoanZones(route.loan)
    createRouteBlip(route.loan[1].coords, "loan", route.loan[1].name)
    Notify("New schedule received! First loan stop marked.", "success")
    
    PlayerData = QBCore.Functions.GetPlayerData()
    local playerName = PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname
    
    local loanData = {}
    for i, v in ipairs(route.loan) do
        table.insert(loanData, { x = v.coords.x, y = v.coords.y, z = v.coords.z, name = v.name })
    end
    local cashData = {}
    for i, v in ipairs(route.cash) do
        table.insert(cashData, { x = v.coords.x, y = v.coords.y, z = v.coords.z, name = v.name })
    end
    
    SendNUIMessage({ 
        action = "openRouteCard", 
        loan = loanData, 
        cash = cashData,
        playerName = playerName,
        completedLoan = {},  -- Fresh start
        completedCash = {}   -- Fresh start
    })
    SetNuiFocus(true, true)
    nuiOpen = true
end)

function createLoanZones(list)
    for _, z in pairs(zoneRefs) do exports['qb-target']:RemoveZone(z.id) end
    zoneRefs = {}
    for i, locData in ipairs(list) do
        local id = "loan_"..i
        dbg("Creating loan zone " .. i .. " at " .. locData.name)
        exports['qb-target']:AddBoxZone(id, locData.coords, Config.ZoneSize.x, Config.ZoneSize.y, {
            name = id, debugPoly = Config.Debug, minZ = locData.coords.z - 1.5, maxZ = locData.coords.z + 1.5
        }, {
            options = {
                {
                    type = "client",
                    event = "mnc-gruppe6:client:CollectLoan",
                    icon = "fas fa-file-contract",
                    label = "Collect Loan Agreements",
                    stopIndex = i
                }
            },
            distance = 2.5
        })
        zoneRefs[#zoneRefs+1] = {id = id}
    end
end

function createCashZones(list)
    for _, z in pairs(zoneRefs) do exports['qb-target']:RemoveZone(z.id) end
    zoneRefs = {}
    for i, locData in ipairs(list) do
        local id = "cash_"..i
        dbg("Creating cash zone " .. i .. " at " .. locData.name)
        exports['qb-target']:AddBoxZone(id, locData.coords, Config.ZoneSize.x, Config.ZoneSize.y, {
            name = id, debugPoly = Config.Debug, minZ = locData.coords.z - 1.5, maxZ = locData.coords.z + 1.5
        }, {
            options = {
                {
                    type = "client",
                    event = "mnc-gruppe6:client:CollectCash",
                    icon = "fas fa-briefcase",
                    label = "Collect Cash Case",
                    stopIndex = i
                }
            },
            distance = 2.5
        })
        zoneRefs[#zoneRefs+1] = {id = id}
    end
end

local function IsPlayerInAllowedVehicle(list)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return false end
    local veh = GetVehiclePedIsIn(ped, false)
    local model = GetEntityModel(veh)
    for _, name in ipairs(list) do if GetHashKey(name) == model then return true end end
    return false
end

--========================================================
-- FLOATING MARKERS FOR ACTIVE STOPS (RESPECTS CONFIG)
--========================================================
CreateThread(function()
    while true do
        Wait(0)

        -- Config disabled? Stop immediately
        if not Config.ShowMarkers then
            goto continue
        end

        -- No active route? Nothing to draw
        if not activeRoute then
            goto continue
        end

        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)

        -------------------------------------------------------
        -- LOAN PHASE MARKER (GREEN)
        -------------------------------------------------------
        if loanIndex and loanIndex > 0 
        and activeRoute.loan 
        and activeRoute.loan[loanIndex] 
        then
            local loc = activeRoute.loan[loanIndex].coords
            local dist = #(pcoords - loc)

            if dist < 50.0 then
                DrawMarker(
                    1, loc.x, loc.y, loc.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    1.5, 1.5, 1.0,
                    0, 255, 0, 180,        -- 💚 GREEN for LOAN PHASE
                    false, true, 2, false, nil, nil, false
                )
            end
        end


        -------------------------------------------------------
        -- CASH PHASE MARKER (BLUE)
        -------------------------------------------------------
        if cashIndex and cashIndex > 0
        and activeRoute.cash
        and activeRoute.cash[cashIndex]
        then
            local loc = activeRoute.cash[cashIndex].coords
            local dist = #(pcoords - loc)

            if dist < 50.0 then
                DrawMarker(
                    1, loc.x, loc.y, loc.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    1.5, 1.5, 1.0,
                    0, 200, 255, 180,      -- 💙 BLUE for CASH PHASE
                    false, true, 2, false, nil, nil, false
                )
            end
        end

        ::continue::
    end
end)

-- LOAN PHASE
RegisterNetEvent("mnc-gruppe6:client:CollectLoan", function(data)
    if not activeRoute or not activeRoute.loan[loanIndex] then return end
    
    local index = data.index or data.stopIndex or 0
    dbg("CollectLoan - data.index: " .. tostring(data.index) .. ", data.stopIndex: " .. tostring(data.stopIndex) .. ", loanIndex: " .. loanIndex)
    
    if not index or index == 0 or not activeRoute.loan[index] then
        dbg("Invalid index: " .. tostring(index))
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local targetStopCoords = activeRoute.loan[index].coords
    local dist = #(playerCoords - targetStopCoords)
    
    dbg("CollectLoan - distance: " .. dist)
    
    if index ~= loanIndex then
        Notify("Visit stops in order! Current stop: " .. activeRoute.loan[loanIndex].name, "error")
        return
    end
    
    if dist > 20.0 then
        Notify("You are too far from the stop!", "error")
        return
    end

    if Config.Minigame.Enabled and not DoMinigame() then return end
    if not DoProgress("Collecting loan documents...", Config.Timers.CollectLoan, "amb@prop_human_bum_bin@idle_b", "idle_d") then return end

    -- Calculate 0-based index BEFORE incrementing
    local completedIndex = loanIndex - 1
    Notify("Loan agreements collected at " .. activeRoute.loan[loanIndex].name .. "!", "success")
    
    -- Send status update with 0-based index
    dbg("Sending updateLoanStatus - loanIndex: " .. loanIndex .. ", completedIndex (0-based): " .. completedIndex)
    SendNUIMessage({ action = "updateLoanStatus", index = completedIndex })
    dbg("Sent updateLoanStatus with index: " .. completedIndex)
    dbg("Message sent successfully")
    
    -- Now increment for next stop
    loanIndex = loanIndex + 1

    if loanIndex > #activeRoute.loan then
        createRouteBlip(Config.Depot, "loan", "Gruppe 6 Depot")
        Notify("All loan agreements collected! Return to the Gruppe 6 depot to collect your wages.", "success", 30000)
        loanPhaseComplete = true
    else
        createRouteBlip(activeRoute.loan[loanIndex].coords, "loan", activeRoute.loan[loanIndex].name)
    end
end)

-- WITHDRAW LOAN WAGES
RegisterNetEvent("mnc-gruppe6:client:WithdrawLoanWages", function()
    if not loanPhaseComplete then Notify("You haven't completed the loan phase yet!", "error") return end

    -- Remove tablet from player (server handles inventory)
    TriggerServerEvent("mnc-gruppe6:server:RemoveTablet")

    TriggerServerEvent("mnc-gruppe6:server:CompleteLoanPhase")
    Notify("Loan phase wages collected: +$"..Config.LoanPayout.."!", "success")
    loanPhaseComplete = false
end)

-- CASH PHASE
RegisterNetEvent("mnc-gruppe6:client:CollectCash", function(data)
    if cashIndex == 0 then
        Notify("Cash phase hasn't started yet! Complete the loan phase first.", "error")
        return
    end
    
    if not activeRoute or not activeRoute.cash[cashIndex] then return end
    
    local index = data.index or data.stopIndex or 0
    dbg("CollectCash - data.index: " .. tostring(data.index) .. ", data.stopIndex: " .. tostring(data.stopIndex) .. ", cashIndex: " .. cashIndex)
    
    if not index or index == 0 or not activeRoute.cash[index] then
        dbg("Invalid index: " .. tostring(index))
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local targetStopCoords = activeRoute.cash[index].coords
    local dist = #(playerCoords - targetStopCoords)
    
    dbg("CollectCash - distance: " .. dist)
    
    if index ~= cashIndex then
        Notify("Visit stops in order! Current stop: " .. activeRoute.cash[cashIndex].name, "error")
        return
    end
    
    if dist > 20.0 then
        Notify("You are too far from the stop!", "error")
        return
    end

    if Config.RequireVehicleForCash and not IsPlayerInAllowedVehicle(Config.CashRequiredVehicles) then
        Notify("Recommended: Use the Gruppe 6 Speedo (armored van) for cash transport", "primary", 8000)
    end

    if Config.Minigame.Enabled and not DoMinigame() then return end
    if not DoProgress("Picking up cash case...", Config.Timers.CollectCash, "amb@prop_human_bum_bin@idle_b", "idle_d") then return end
    if not DoProgress("Loading case into vehicle...", Config.Timers.LoadCase, "amb@prop_human_bum_bin@idle_b", "idle_d") then return end

    -- Calculate 0-based index BEFORE incrementing
    local completedIndex = cashIndex - 1
    Notify("Cash case loaded at " .. activeRoute.cash[cashIndex].name .. "!", "success")
    
    -- Send status update with 0-based index
    dbg("Sending updateCashStatus - cashIndex: " .. cashIndex .. ", completedIndex (0-based): " .. completedIndex)
    SendNUIMessage({ action = "updateCashStatus", index = completedIndex })
    dbg("Sent updateCashStatus with index: " .. completedIndex)
    dbg("Message sent successfully")
    
    -- Now increment for next stop
    cashIndex = cashIndex + 1

    if cashIndex > #activeRoute.cash then
        removeActiveBlip()
        for _, z in pairs(zoneRefs) do exports['qb-target']:RemoveZone(z.id) end
        zoneRefs = {}
        createRouteBlip(Config.Depot, "cash", "Gruppe 6 Depot")
        Notify("All cash collected! Return to the Gruppe 6 depot to collect your final $"..Config.CashPayout.." payment.", "success", 35000)
        cashPhaseComplete = true
    else
        createRouteBlip(activeRoute.cash[cashIndex].coords, "cash", activeRoute.cash[cashIndex].name)
    end
end)

-- WITHDRAW FINAL CASH WAGES
RegisterNetEvent("mnc-gruppe6:client:WithdrawCashWages", function()
    if not cashPhaseComplete then Notify("You haven't completed the cash phase yet!", "error") return end

    -- Remove tablet from player (server handles inventory)
    TriggerServerEvent("mnc-gruppe6:server:RemoveTablet")

    TriggerServerEvent("mnc-gruppe6:server:CompleteCashPhase")
    Notify("Final wages collected: +$"..Config.CashPayout.."! Job complete.", "success")
    activeRoute = nil
    loanIndex = 0
    cashIndex = 0
    cashPhaseComplete = false
    removeActiveBlip()
end)

-- Start Cash Phase
RegisterNetEvent("mnc-gruppe6:client:StartCashPhase", function()
    if loanIndex <= #activeRoute.loan then Notify("Finish the loan phase first!", "error") return end
    if loanPhaseComplete then Notify("You already collected your loan wages.", "primary") end

    if Config.RequireVehicleForCash and not IsPlayerInAllowedVehicle(Config.CashRequiredVehicles) then
        Notify("Recommended: Use the Gruppe 6 Speedo for cash collections", "primary", 15000)
    end

    cashIndex = 1
    createCashZones(activeRoute.cash)
    createRouteBlip(activeRoute.cash[1].coords, "cash", activeRoute.cash[1].name)
    Notify("Cash phase started!", "success")
end)

-- Open GPS UI when item is used
RegisterNetEvent("mnc-gruppe6:client:OpenGPS", function()
    if not activeRoute then 
        Notify("You don't have an active route!", "error")
        return 
    end
    
    if nuiOpen then
        Notify("GPS is already open!", "error")
        return
    end
    
    PlayerData = QBCore.Functions.GetPlayerData()
    local playerName = PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname
    
    -- Build completed arrays (1-based for Lua, will be converted to proper array by json.encode)
    local completedLoanArray = {}
    for i = 1, #activeRoute.loan do
        table.insert(completedLoanArray, (i < loanIndex))  -- true if already completed
    end
    
    local completedCashArray = {}
    for i = 1, #activeRoute.cash do
        table.insert(completedCashArray, (cashIndex > 0 and i < cashIndex))  -- true if already completed
    end
    
    local loanData = {}
    for i, v in ipairs(activeRoute.loan) do
        table.insert(loanData, { x = v.coords.x, y = v.coords.y, z = v.coords.z, name = v.name })
    end
    local cashData = {}
    for i, v in ipairs(activeRoute.cash) do
        table.insert(cashData, { x = v.coords.x, y = v.coords.y, z = v.coords.z, name = v.name })
    end
    
    dbg("Opening GPS - loanIndex: " .. loanIndex .. ", cashIndex: " .. cashIndex)
    dbg("Completed loan stops: " .. json.encode(completedLoanArray))
    dbg("Completed cash stops: " .. json.encode(completedCashArray))
    
    SendNUIMessage({ 
        action = "openRouteCard", 
        loan = loanData, 
        cash = cashData,
        playerName = playerName,
        completedLoan = completedLoanArray,
        completedCash = completedCashArray
    })
    SetNuiFocus(true, true)
    nuiOpen = true
end)

RegisterCommand("copyoutfit", function(_, args)
    if not args[1] then
        return Notify("Usage: /copyoutfit male OR /copyoutfit female", "error")
    end

    local gender = string.lower(args[1])
    if gender ~= "male" and gender ~= "female" then
        return Notify("Usage: /copyoutfit male OR /copyoutfit female", "error")
    end

    -- Get true character gender from QB data
    local PlayerData = QBCore.Functions.GetPlayerData()
    local charGender = PlayerData.charinfo.gender   -- 0 = male, 1 = female

    local isFemaleChar = (charGender == 1)
    local isMaleChar = (charGender == 0)

    -- Gender mismatch notifications
    if gender == "male" and not isMaleChar then
        return Notify("Character gender isn't male – cannot copy male outfit.", "error")
    end
    if gender == "female" and not isFemaleChar then
        return Notify("Character gender isn't female – cannot copy female outfit.", "error")
    end

    local ped = PlayerPedId()
    local hat = GetPedPropIndex(ped, 0)
    local hatTex = GetPedPropTextureIndex(ped, 0)
    
    -- Get all component values with slot information
    local components = {
        tshirt = { slot = 8, drawable = GetPedDrawableVariation(ped, 8), texture = GetPedTextureVariation(ped, 8) },
        torso2 = { slot = 11, drawable = GetPedDrawableVariation(ped, 11), texture = GetPedTextureVariation(ped, 11) },
        pants = { slot = 4, drawable = GetPedDrawableVariation(ped, 4), texture = GetPedTextureVariation(ped, 4) },
        shoes = { slot = 6, drawable = GetPedDrawableVariation(ped, 6), texture = GetPedTextureVariation(ped, 6) },
        arms = { slot = 3, drawable = GetPedDrawableVariation(ped, 3), texture = GetPedTextureVariation(ped, 3) },
        decals = { slot = 10, drawable = GetPedDrawableVariation(ped, 10), texture = GetPedTextureVariation(ped, 10) },
        vest = { slot = 9, drawable = GetPedDrawableVariation(ped, 9), texture = GetPedTextureVariation(ped, 9) },
        bag = { slot = 5, drawable = GetPedDrawableVariation(ped, 5), texture = GetPedTextureVariation(ped, 5) },
    }

    -- Format the outfit code
    local result = string.format([[ 
Uniforms.Gruppe6.%s = {
    outfit = {
        ["tshirt"] = { item = %d, texture = %d },
        ["torso2"] = { item = %d, texture = %d },
        ["pants"]  = { item = %d, texture = %d },
        ["shoes"]  = { item = %d, texture = %d },
        ["arms"]   = { item = %d, texture = %d },
        ["decals"] = { item = %d, texture = %d },
        ["vest"]   = { item = %d, texture = %d },
        ["bag"]    = { item = %d, texture = %d },
        ["hat"]    = { item = %d, texture = %d },
    }
}
]], gender,
        components.tshirt.drawable, components.tshirt.texture,
        components.torso2.drawable, components.torso2.texture,
        components.pants.drawable, components.pants.texture,
        components.shoes.drawable, components.shoes.texture,
        components.arms.drawable, components.arms.texture,
        components.decals.drawable, components.decals.texture,
        components.vest.drawable, components.vest.texture,
        components.bag.drawable, components.bag.texture,
        hat == -1 and -1 or hat, hatTex
    )

    print("^3========================================^7")
    print("^3=== GRUPPE 6 UNIFORM COPIED - " .. string.upper(gender) .. " ===^7")
    print("^3========================================^7")
    print("^2" .. result .. "^7")
    print("^3========================================^7")
    print("^3=== DETAILED BREAKDOWN ===^7")
    print("^3========================================^7")
    for name, data in pairs(components) do
        print(string.format("^5%s^7 (slot ^6%d^7): drawable=^2%d^7, texture=^2%d^7", name, data.slot, data.drawable, data.texture))
    end
    print(string.format("^5hat^7 (prop ^60^7): drawable=^2%d^7, texture=^2%d^7", hat, hatTex))
    print("^3========================================^7")
    print("^3=== COPY ABOVE CODE INTO uniforms.lua ===^7")
    print("^3========================================^7")
    
    Notify("Uniform copied to F8 console! Check details above.", "success", 20000)
end, false)

RegisterCommand("debugoutfit", function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local charGender = PlayerData.charinfo.gender
    local gender = (charGender == 0) and "male" or "female"
    local ped = PlayerPedId()
    
    print("^3========================================^7")
    print("^3=== OUTFIT DEBUG - " .. string.upper(gender) .. " CHARACTER ===^7")
    print("^3========================================^7")
    print("^6Comparing: Current Outfit vs Configured Gruppe 6 Uniform^7")
    print("")
    
    local outfit = Uniforms.Gruppe6[gender].outfit
    local compMap = { 
        tshirt = 8, 
        torso2 = 11, 
        pants = 4, 
        shoes = 6, 
        arms = 3, 
        decals = 10, 
        vest = 9, 
        bag = 5 
    }
    
    local mismatches = 0
    
    for name, slot in pairs(compMap) do
        local currentDraw = GetPedDrawableVariation(ped, slot)
        local currentTex = GetPedTextureVariation(ped, slot)
        local configDraw = outfit[name] and outfit[name].item or 0
        local configTex = outfit[name] and outfit[name].texture or 0
        
        local drawableMatch = (currentDraw == configDraw)
        local textureMatch = (currentTex == configTex)
        local fullMatch = drawableMatch and textureMatch
        
        local match = fullMatch and "^2✓ MATCH^7" or "^1✗ MISMATCH^7"
        
        if not fullMatch then
            mismatches = mismatches + 1
        end
        
        print(string.format("%s ^5%-8s^7 (slot ^6%2d^7): Current=(^3%3d^7, ^3%2d^7) | Config=(^2%3d^7, ^2%2d^7)", 
            match, name, slot, currentDraw, currentTex, configDraw, configTex))
    end
    
    -- Check hat
    local currentHat = GetPedPropIndex(ped, 0)
    local currentHatTex = GetPedPropTextureIndex(ped, 0)
    local configHat = outfit.hat and outfit.hat.item or -1
    local configHatTex = outfit.hat and outfit.hat.texture or 0
    local hatMatch = (currentHat == configHat and currentHatTex == configHatTex)
    
    if not hatMatch then
        mismatches = mismatches + 1
    end
    
    local hatMatchStr = hatMatch and "^2✓ MATCH^7" or "^1✗ MISMATCH^7"
    print(string.format("%s ^5%-8s^7 (prop ^6%2d^7): Current=(^3%3d^7, ^3%2d^7) | Config=(^2%3d^7, ^2%2d^7)", 
        hatMatchStr, "hat", 0, currentHat, currentHatTex, configHat, configHatTex))
    
    print("^3========================================^7")
    if mismatches == 0 then
        print("^2✓ ALL COMPONENTS MATCH! Outfit is correctly configured.^7")
    else
        print(string.format("^1✗ FOUND %d MISMATCH(ES)^7", mismatches))
        print("^3Fix: Use /copyoutfit " .. gender .. " while wearing the correct uniform^7")
    end
    print("^3========================================^7")
    
end, false)

RegisterNetEvent("mnc-gruppe6:client:ScheduleCooldown", function(sec)
    local m = math.floor(sec / 60)
    local s = sec % 60
    Notify(string.format("Cooldown: %02d:%02d", m, s), "error")
end)

RegisterNUICallback('close', function(_, cb)
    SendNUIMessage({action = "hide"})
    SetNuiFocus(false, false)
    nuiOpen = false
    cb('ok')
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    if not activeRoute then 
        cb('ok')
        return 
    end
    
    local coords = nil
    local targetIndex = data.index + 1
    local currentRoute = data.type == "loan" and activeRoute.loan or activeRoute.cash
    local currentIndex = data.type == "loan" and loanIndex or cashIndex
    
    if targetIndex < currentIndex then
        Notify("You've already completed that stop!", "error")
        cb('ok')
        return
    end
    
    if currentRoute[targetIndex] then
        coords = currentRoute[targetIndex].coords
        local name = currentRoute[targetIndex].name
        
        if targetIndex == currentIndex then
            Notify("Setting waypoint to current stop: " .. name, "success", 3000)
        else
            Notify("Setting waypoint to: " .. name .. " (not current stop)", "info", 3000)
        end
        
        SetNewWaypoint(coords.x, coords.y)
    end
    
    cb('ok')
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        removeActiveBlip()
        for _, z in pairs(zoneRefs) do if z.id then exports['qb-target']:RemoveZone(z.id) end end
    end
end)

CreateThread(function()
    Wait(3000)
end)
