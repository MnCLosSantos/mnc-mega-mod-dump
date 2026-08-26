local QBCore = exports['qb-core']:GetCoreObject()

local activeDelivery = false

-- ─────────────────────────────────────────────
-- Icon + colour map by vehicle class
-- Uses ox_lib iconColor (hex) and FontAwesome icons
-- ─────────────────────────────────────────────
local function GetVehicleIcon(model)
    local hash  = GetHashKey(model)
    local class = GetVehicleClassFromName(hash)
    -- class reference: 0=Compact,1=Sedan,2=SUV,3=Coupe,4=Muscle,5=SportClassic,
    --                  6=Sport,7=Super,8=Motorcycle,9=OffRoad,10=Industrial,
    --                  11=Utility,12=Van,13=Cycles,14=Boat,15=Helicopter,
    --                  16=Plane,17=Service,18=Emergency,19=Military,20=Commercial,21=Train
    local map = {
        [0]  = { icon = 'car',                  color = '#7EB8F7' }, -- Compact    – light blue
        [1]  = { icon = 'car',                  color = '#A8D8A8' }, -- Sedan      – light green
        [2]  = { icon = 'car',                  color = '#F4A261' }, -- SUV        – orange
        [3]  = { icon = 'car',             color = '#C9B8F5' }, -- Coupe      – lavender
        [4]  = { icon = 'car',                  color = '#E63946' }, -- Muscle     – red
        [5]  = { icon = 'star',                 color = '#FFD166' }, -- SportClass – gold
        [6]  = { icon = 'star',                 color = '#06D6A0' }, -- Sport      – teal
        [7]  = { icon = 'bolt',                 color = '#FF6B6B' }, -- Super      – coral
        [8]  = { icon = 'motorcycle',           color = '#F77F00' }, -- Motorcycle – amber
        [9]  = { icon = 'mountain',             color = '#8B6914' }, -- Off-Road   – brown
        [10] = { icon = 'truck',                color = '#6C757D' }, -- Industrial – grey
        [11] = { icon = 'toolbox',              color = '#ADB5BD' }, -- Utility    – silver
        [12] = { icon = 'star',                 color = '#4CC9F0' }, -- Van        – sky blue
        [13] = { icon = 'bicycle',              color = '#52B788' }, -- Cycles     – green
        [14] = { icon = 'sailboat',             color = '#0096C7' }, -- Boat       – ocean blue
        [15] = { icon = 'helicopter',           color = '#9B72CF' }, -- Helicopter – purple
        [16] = { icon = 'plane',                color = '#48CAE4' }, -- Plane      – cyan
        [17] = { icon = 'bus',                  color = '#F4D03F' }, -- Service    – yellow
        [18] = { icon = 'truck-medical',        color = '#E74C3C' }, -- Emergency  – red
        [19] = { icon = 'shield-halved',        color = '#2D6A4F' }, -- Military   – dark green
        [20] = { icon = 'truck',                color = '#495057' }, -- Commercial – dark grey
        [21] = { icon = 'train',                color = '#343A40' }, -- Train      – near black
    }
    return map[class] or { icon = 'car', color = '#FFFFFF' }
end

-- Fuel icon colour based on level
local function GetFuelColor(fuel)
    if fuel > 60 then return '#2ECC71'  -- green
    elseif fuel > 30 then return '#F39C12' -- orange
    else return '#E74C3C' end           -- red
end

-- ─────────────────────────────────────────────
-- Utility: find a driveable road point ~distance away
-- ─────────────────────────────────────────────
local function GetSpawnPointFarFrom(playerCoords, distance)
    for _ = 1, 30 do
        local angle  = math.random() * math.pi * 2
        local dx     = math.cos(angle) * distance
        local dy     = math.sin(angle) * distance
        local testX  = playerCoords.x + dx
        local testY  = playerCoords.y + dy

        local found, nodePos = GetClosestVehicleNodeWithHeading(testX, testY, playerCoords.z, 1, 3.0, 0)
        if found then return nodePos end
    end
    local angle = math.random() * math.pi * 2
    return vector3(
        playerCoords.x + math.cos(angle) * distance,
        playerCoords.y + math.sin(angle) * distance,
        playerCoords.z
    )
end

-- ─────────────────────────────────────────────
-- Helper: block until anim dict loaded (max 3s)
-- ─────────────────────────────────────────────
local function LoadAnimDict(dict)
    if not DoesAnimDictExist(dict) then return false end
    local timeout = 0
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(100)
        timeout = timeout + 1
        if timeout > 30 then return false end
    end
    return true
end

-- ─────────────────────────────────────────────
-- Key handoff animation
--   givetake1_a = give/hand-off (ped)
--   givetake1_b = receive/catch (player)
-- ─────────────────────────────────────────────
local function PlayKeyHandoffAnimation(ped, playerPed)
    local dict = 'mp_common'
    if not LoadAnimDict(dict) then return end

    local pedPos  = GetEntityCoords(ped)
    local plyrPos = GetEntityCoords(playerPed)

    SetEntityHeading(ped,       GetHeadingFromVector_2d(plyrPos.x - pedPos.x,  plyrPos.y - pedPos.y))
    SetEntityHeading(playerPed, GetHeadingFromVector_2d(pedPos.x  - plyrPos.x, pedPos.y  - plyrPos.y))

    TaskPlayAnim(ped,       dict, 'givetake1_a', 8.0, -8.0, 2000, 0, 0, false, false, false)
    Wait(300)
    TaskPlayAnim(playerPed, dict, 'givetake1_b', 8.0, -8.0, 2000, 0, 0, false, false, false)
    Wait(2000)

    StopAnimTask(ped,       dict, 'givetake1_a', 1.0)
    StopAnimTask(playerPed, dict, 'givetake1_b', 1.0)
    RemoveAnimDict(dict)
end

-- ─────────────────────────────────────────────
-- Main menu
-- ─────────────────────────────────────────────
local function OpenCallCarMenu()
    if activeDelivery then
        lib.notify({ title = 'Valet', description = 'A vehicle is already on its way!', type = 'warning' })
        return
    end

    -- Server returns ONLY garaged vehicles (state != 0 means out / already spawned)
    local vehicles = lib.callback.await('mnc-callcar:getPlayerVehicles', false)

    if not vehicles or #vehicles == 0 then
        lib.notify({ title = 'Valet', description = 'You have no vehicles stored in a garage.', type = 'error' })
        return
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local options = {}

    for _, v in ipairs(vehicles) do
        local fee       = Config.BaseCost + math.floor(Config.SpawnDistance * Config.CostPerMeter)
        local iconData  = GetVehicleIcon(v.model)
        local fuelColor = GetFuelColor(v.fuel)

        options[#options + 1] = {
            title     = v.label,
            description = string.format(
                'Garage: %s\nCondition: %s  |  Fuel: %d%%\nDelivery fee: $%d',
                v.garage, v.condition, v.fuel, fee
            ),
            icon      = iconData.icon,
            iconColor = iconData.color,
            metadata  = {
                -- Extra coloured badges shown inside the context item
                { label = 'Fuel',      value = v.fuel .. '%',         progress = v.fuel,         colorScheme = v.fuel > 60         and 'green' or v.fuel > 30         and 'orange' or 'red' },
                { label = 'Condition', value = v.conditionAvg .. '%', progress = v.conditionAvg, colorScheme = v.conditionAvg >= 70 and 'green' or v.conditionAvg >= 40 and 'orange' or 'red' },
                { label = 'Cost',      value = '$' .. fee },
            },
            onSelect  = function()
                local confirmed = lib.alertDialog({
                    header  = 'Call Vehicle',
                    content = string.format('Call **%s** for **$%d**?', v.label, fee),
                    centered = true,
                    cancel   = true,
                })
                if confirmed ~= 'confirm' then return end

                local charged = lib.callback.await('mnc-callcar:chargeFee', false, fee)
                if not charged then
                    lib.notify({ title = 'Valet', description = 'Insufficient funds.', type = 'error' })
                    return
                end

                DeliverVehicle(v, playerCoords)
            end,
        }
    end

    lib.registerContext({
        id      = 'mnc_callcar_menu',
        title   = '🚗 Call Your Vehicle',
        options = options,
    })
    lib.showContext('mnc_callcar_menu')
end

-- ─────────────────────────────────────────────
-- Delivery logic
-- ─────────────────────────────────────────────
function DeliverVehicle(vehicleData, playerCoords)
    activeDelivery = true

    -- Mark vehicle as out on the server (also acts as duplicate-spawn guard)
    local marked = lib.callback.await('mnc-callcar:markVehicleOut', false, vehicleData.plate)
    if not marked then
        lib.notify({ title = 'Valet', description = 'That vehicle is already out or unavailable.', type = 'error' })
        activeDelivery = false
        return
    end

    CreateThread(function()
        local props     = json.decode(vehicleData.props) or {}
        local modelName = vehicleData.model or 'adder'
        local model     = GetHashKey(modelName)

        RequestModel(model)
        for i = 1, 100 do
            if HasModelLoaded(model) then break end
            Wait(100)
        end

        if not HasModelLoaded(model) then
            lib.notify({ title = 'Valet', description = 'Failed to load vehicle model: ' .. tostring(modelName), type = 'error' })
            TriggerServerEvent('mnc-callcar:releaseVehicle', vehicleData.plate, vehicleData.state)
            activeDelivery = false
            return
        end

        local spawnDist   = math.min(Config.SpawnDistance, 250)
        local spawnCoords = GetSpawnPointFarFrom(playerCoords, spawnDist)

        local groundZ       = spawnCoords.z
        local gFound, gZ    = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 50.0, false)
        if gFound then groundZ = gZ end

        local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, groundZ + 0.5, 0.0, true, false)

        for i = 1, 50 do
            if DoesEntityExist(vehicle) then break end
            Wait(100)
        end

        if not DoesEntityExist(vehicle) then
            lib.notify({ title = 'Valet', description = 'Failed to spawn vehicle.', type = 'error' })
            SetModelAsNoLongerNeeded(model)
            TriggerServerEvent('mnc-callcar:releaseVehicle', vehicleData.plate, vehicleData.state)
            activeDelivery = false
            return
        end

        SetEntityAsMissionEntity(vehicle, true, true)
        lib.setVehicleProperties(vehicle, props)
        SetVehicleNumberPlateText(vehicle, vehicleData.plate)
        SetModelAsNoLongerNeeded(model)

        -- Valet ped
        local pedModel = GetHashKey('s_m_y_valet_01')
        RequestModel(pedModel)
        for i = 1, 50 do
            if HasModelLoaded(pedModel) then break end
            Wait(100)
        end

        local ped = CreatePedInsideVehicle(vehicle, 26, pedModel, -1, true, false)
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 17, true)
        SetModelAsNoLongerNeeded(pedModel)

        -- Blip
        local blip = AddBlipForEntity(vehicle)
        SetBlipSprite(blip, 225)
        SetBlipColour(blip, 2)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Your Vehicle')
        EndTextCommandSetBlipName(blip)

        lib.notify({ title = 'Valet', description = 'Your vehicle is on its way!', type = 'success', duration = 5000 })

        local speed = Config.DrivingSpeed == 1 and 15.0 or Config.DrivingSpeed == 2 and 25.0 or 40.0

        TaskVehicleDriveToCoordLongrange(ped, vehicle,
            playerCoords.x, playerCoords.y, playerCoords.z,
            speed, Config.DrivingStyle, 5.0)

        -- Watch loop
        local timeout     = 0
        local handoffDone = false

        while true do
            Wait(500) -- poll every 0.5s for tighter distance reaction
            timeout = timeout + 0.5

            if not DoesEntityExist(vehicle) then
                if DoesBlipExist(blip) then RemoveBlip(blip) end
                activeDelivery = false
                break
            end

            local vehCoords = GetEntityCoords(vehicle)
            local playerNow = GetEntityCoords(PlayerPedId())
            local dist      = #(vehCoords - playerNow)

            -- ── SAFE STOP: brake and park when 20m away ──────────
            -- This fires BEFORE the 8m handoff zone so the car never
            -- drives into the player.
            if dist < 20.0 and not handoffDone then
                -- Kill drive task so the ped doesn't keep steering toward player
                ClearPedTasks(ped)
                SetVehicleEngineOn(vehicle, true, true, false)
                -- Smooth brake to stop (native: flag 1 = pull handbrake-stop)
                TaskVehicleTempAction(ped, vehicle, 1, 1500) -- action 1 = brake
                Wait(1600)
            end
            -- ─────────────────────────────────────────────────────

            -- Refresh drive task every 5 seconds while still far
            if dist >= 20.0 and math.floor(timeout) % 5 == 0 then
                TaskVehicleDriveToCoordLongrange(ped, vehicle,
                    playerNow.x, playerNow.y, playerNow.z,
                    speed, Config.DrivingStyle, 5.0)
            end

            -- ── HANDOFF ZONE: 8m ─────────────────────────────────
            if dist < 8.0 and not handoffDone then
                handoffDone = true

                -- Fully stop vehicle
                ClearPedTasks(ped)
                SetVehicleHandbrake(vehicle, true)
                Wait(500)
                TaskLeaveVehicle(ped, vehicle, 0)
                Wait(3000)

                -- Walk close to player (stop 1.5m away)
                local closeTarget = GetEntityCoords(PlayerPedId())
                TaskGoStraightToCoord(ped, closeTarget.x, closeTarget.y, closeTarget.z,
                    1.0, 4000, GetEntityHeading(ped), 1.5)
                Wait(3000)

                -- Key handoff animation
                lib.notify({
                    title       = 'Valet',
                    description = '🔑 Here are your keys!',
                    type        = 'inform',
                    duration    = 3500,
                })
                PlayKeyHandoffAnimation(ped, PlayerPedId())

                -- Give keys server-side
                TriggerServerEvent('mnc-callcar:giveKeys', vehicleData.plate)

                if DoesBlipExist(blip) then RemoveBlip(blip) end

                -- Ped walks away then despawns
                Wait(400)
                local pedPos    = GetEntityCoords(ped)
                local awayAngle = math.rad(GetEntityHeading(ped) + 180)
                TaskGoStraightToCoord(ped,
                    pedPos.x + math.cos(awayAngle) * 12,
                    pedPos.y + math.sin(awayAngle) * 12,
                    pedPos.z,
                    1.0, 5000, GetEntityHeading(ped), 0.5)
                Wait(3500)

                if DoesEntityExist(ped) then DeleteEntity(ped) end

                -- Release vehicle to player
                SetVehicleHandbrake(vehicle, false)
                NetworkRequestControlOfEntity(vehicle)
                Wait(200)
                SetEntityAsMissionEntity(vehicle, false, true)

                lib.notify({
                    title       = 'Valet',
                    description = string.format('Your %s has arrived!', vehicleData.label),
                    type        = 'success',
                    duration    = 5000,
                })

                activeDelivery = false
                break
            end

            if timeout > 300 then
                lib.notify({ title = 'Valet', description = 'Vehicle delivery timed out.', type = 'error' })
                if DoesBlipExist(blip) then RemoveBlip(blip) end
                if DoesEntityExist(ped)     then DeleteEntity(ped) end
                if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
                TriggerServerEvent('mnc-callcar:releaseVehicle', vehicleData.plate, vehicleData.state)
                activeDelivery = false
                break
            end
        end
    end)
end

-- ─────────────────────────────────────────────
-- Register commands
-- ─────────────────────────────────────────────
for _, cmd in ipairs(Config.Commands) do
    RegisterCommand(cmd, function()
        OpenCallCarMenu()
    end, false)
end