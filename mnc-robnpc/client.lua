-- client.lua
local QBCore = exports['qb-core']:GetCoreObject()

local robbedPeds = {}
local WEAPON_UNARMED = `WEAPON_UNARMED`
local WEAPON_KNIFE = `WEAPON_KNIFE`
local WEAPON_PISTOL = `WEAPON_PISTOL`

-- Add target option to all non-player human peds
exports['qb-target']:AddGlobalPed({
    options = {
        {
            type = "client",
            event = "mnc-robnpc:client:AttemptRob",
            icon = "fas fa-sack-dollar",
            label = "Rob Pedestrian",
            canInteract = function(entity)
                return IsPedHuman(entity)
                    and not IsPedAPlayer(entity)
                    and not IsEntityDead(entity)
                    and not IsPedInAnyVehicle(entity, false)
                    and not robbedPeds[entity]
            end,
        },
    },
    distance = 2.5
})

-- Ped resists instead of complying: pulls a weapon and actually fights back.
-- Civilian peds default to fairly passive/flee-prone combat AI, so their
-- attributes are tuned here to make them aggressively close in and attack.
local function HandlePedResistance(ped, playerPed, resistType)
    SetPedFleeAttributes(ped, 0, false)          -- don't run away instead of fighting
    SetPedCombatAttributes(ped, 5, true)         -- BF_AlwaysFight
    SetPedCombatAttributes(ped, 46, true)        -- BF_CanFightArmedPedsWhenNotArmed
    SetPedCombatAbility(ped, 100)                -- professional/aggressive fighter
    SetPedCombatMovement(ped, 3)                 -- will actively close the distance to attack
    SetPedAlertness(ped, 3)
    SetBlockingOfNonTemporaryEvents(ped, false)  -- let the ped react/attack normally
    SetPedDropsWeaponsWhenDead(ped, false)       -- loot is handled by the script below, not a ground pickup

    local weaponLoot -- what to add to the robbery loot if the player kills this ped

    if resistType == 'stab' then
        GiveWeaponToPed(ped, WEAPON_KNIFE, 1, false, true)
        SetCurrentPedWeapon(ped, WEAPON_KNIFE, true)
        SetPedCombatRange(ped, 0) -- force close/melee-range engagement

        lib.notify({
            title = 'Robbery Failed',
            description = 'The pedestrian pulled a knife and lunged at you!',
            type = 'error',
            duration = 6000
        })

        TaskCombatPed(ped, playerPed, 0, 16)

        weaponLoot = { item = 'weapon_knife' }

        -- The player is already within striking distance (robbery requires
        -- being within a few meters), so land a guaranteed stab shortly after
        -- rather than relying purely on the AI's own melee hit detection,
        -- which can otherwise whiff if the player immediately backs off.
        CreateThread(function()
            Wait(400)
            if DoesEntityExist(ped) and not IsEntityDead(ped)
                and DoesEntityExist(playerPed) and not IsEntityDead(playerPed)
                and #(GetEntityCoords(ped) - GetEntityCoords(playerPed)) <= 2.5 then
                ApplyDamageToPed(playerPed, math.random(10, 25), false)
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.25)
            end
        end)
    else -- 'shoot'
        GiveWeaponToPed(ped, WEAPON_PISTOL, 250, false, true)
        SetCurrentPedWeapon(ped, WEAPON_PISTOL, true)
        SetPedCombatRange(ped, 2) -- far range, will back up and shoot

        lib.notify({
            title = 'Robbery Failed',
            description = 'The pedestrian pulled a gun and opened fire!',
            type = 'error',
            duration = 6000
        })

        TaskCombatPed(ped, playerPed, 0, 16)

        weaponLoot = {
            item = 'weapon_pistol',
            ammoItem = 'pistol_ammo',
            ammoAmount = math.random(Config.PedResistance.shootAmmoMin, Config.PedResistance.shootAmmoMax)
        }
    end

    -- If the player kills the resisting ped, loot the body: the weapon it
    -- was using (+ ammo for a gun) on top of the normal cash/item loot.
    CreateThread(function()
        local elapsed = 0
        while elapsed < 30000 do
            if not DoesEntityExist(ped) then return end
            if IsEntityDead(ped) then
                TriggerServerEvent('mnc-robnpc:server:GiveCash', GetEntityCoords(ped), weaponLoot)
                return
            end
            Wait(500)
            elapsed = elapsed + 500
        end
    end)

    -- Let the ped despawn naturally once the fight is over
    SetTimeout(15000, function()
        if DoesEntityExist(ped) then
            SetPedAsNoLongerNeeded(ped)
        end
    end)
end

-- Attempt to rob the targeted NPC
RegisterNetEvent('mnc-robnpc:client:AttemptRob', function(data)
    local ped = data.entity
    local playerPed = PlayerPedId()

    if not DoesEntityExist(ped) or IsEntityDead(ped) then return end
    if robbedPeds[ped] then return end -- already robbed, resisted, or a robbery is already in progress on this ped

    if #(GetEntityCoords(playerPed) - GetEntityCoords(ped)) > 3.0 then return end

    -- Check if player has drawn weapon (not unarmed)
    local currentWeapon = GetSelectedPedWeapon(playerPed)
    if currentWeapon == WEAPON_UNARMED then
        lib.notify({
            title = 'Robbery Failed',
            description = 'You need to draw a weapon to rob someone!',
            type = 'error',
            duration = 5000
        })
        return
    end

    -- Lock the ped immediately (before the async callback below) so a second
    -- target click on the same ped can't start an overlapping robbery attempt
    -- while this one is still running. This is what previously allowed a ped
    -- to be "spam robbed" for repeated loot within a single progress bar.
    robbedPeds[ped] = true

    -- Check if player has any weapon in inventory
    QBCore.Functions.TriggerCallback('mnc-robnpc:server:HasWeapon', function(hasWeapon)
        if not hasWeapon then
            lib.notify({
                title = 'Robbery Failed',
                description = 'You need a weapon in your inventory!',
                type = 'error',
                duration = 5000
            })
            robbedPeds[ped] = nil -- robbery never started, let the player try again
            return
        end

        if not DoesEntityExist(ped) or IsEntityDead(ped) then
            robbedPeds[ped] = nil
            return
        end

        -- Roll to see if the ped resists instead of handing over their belongings
        local roll = math.random(1, 100)
        if roll <= Config.PedResistance.stabChance then
            HandlePedResistance(ped, playerPed, 'stab')
            return
        elseif roll <= (Config.PedResistance.stabChance + Config.PedResistance.shootChance) then
            HandlePedResistance(ped, playerPed, 'shoot')
            return
        end

        -- Load animation dicts
        lib.requestAnimDict('missminuteman_1ig_2')

        -- Freeze the ped in place
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedKeepTask(ped, true)  -- Lock ped tasks to prevent interruptions

        -- Force ped to face the player
        TaskTurnPedToFaceEntity(ped, playerPed, -1)

        -- Lock legs/movement completely during robbery
        TaskStandStill(ped, Config.RobDuration + 2000)

        -- Play hands-up animation (looping with flag 49)
        TaskPlayAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 8.0, -8.0, -1, 49, 0, false, false, false)

        -- Make player aim at the ped during robbery
        TaskAimGunAtEntity(playerPed, ped, Config.RobDuration + 1000, true)

        -- Progress bar
        local success = lib.progressBar({
            duration = Config.RobDuration,
            label = 'Robbing pedestrian...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
            },
        })

        -- Clear player aiming task
        ClearPedTasks(playerPed)

        -- Always unfreeze and clear ped tasks after robbery (success or cancel)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        SetBlockingOfNonTemporaryEvents(ped, false)
        ClearPedTasks(ped)
		SetPedFleeAttributes(ped, 0, false)          -- reset any previous restrictions
        SetPedFleeAttributes(ped, 1 << 15, false)     -- 0x8000 = force cower (optional - remove if you don't want cowering)
        TaskReactAndFleePed(ped, playerPed)

        -- Note: robbedPeds[ped] is left set to true here whether the robbery
        -- succeeded or was cancelled, so this ped can never be targeted again.

        if success then
            local coords = GetEntityCoords(ped)
            TriggerServerEvent('mnc-robnpc:server:GiveCash', coords)
        else
            lib.notify({
                title = 'Robbery Cancelled',
                description = 'You feel sorry for the local and regret your lifes choices.',
                type = 'inform',
                duration = 8000
            })
        end
    end)
end)

-- Notification from server about received mone
RegisterNetEvent('mnc-robnpc:client:MoneyReceived', function(cashAmount, itemsGiven)
    local message = 'You stole **$' .. cashAmount .. '**'

    if #itemsGiven > 0 then
        message = message .. ' + '
        for i, item in ipairs(itemsGiven) do
            if i > 1 then message = message .. ', ' end
            message = message .. item.amount .. 'x ' .. item.label
        end
    end

    lib.notify({
        title = 'Robbery Success',
        description = message,
        type = 'success',
        duration = 7500
    })
end)

-- Notification for jobs about robbery
RegisterNetEvent('mnc-robnpc:client:NotifyRobbery', function(coords)
    local streetHash1, streetHash2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName1 = GetStreetNameFromHashKey(streetHash1)
    local streetName2 = GetStreetNameFromHashKey(streetHash2)
    local zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))

    local location = (zoneName ~= "" and zoneName ~= "UNKNOWN") and zoneName or "Unknown Area"
    if streetName1 ~= "" then
        location = streetName1
    end
    if streetName2 ~= "" then
        location = location .. " / " .. streetName2
    end

    lib.notify({
        title = 'Local Robbery Alert',
        description = string.format(Config.NotifyMessage, location),
        type = 'inform',
        duration = Config.NotifyDuration
    })

    local listening = true
    SetTimeout(Config.NotifyDuration, function()
        listening = false
    end)

    CreateThread(function()
        while listening do
            if IsControlJustPressed(0, 45) then  -- R key
                listening = false

                -- Add temporary blip
                local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
                SetBlipSprite(blip, Config.BlipSprite)
                SetBlipColour(blip, Config.BlipColour)
                SetBlipScale(blip, Config.BlipScale)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(Config.BlipLabel)
                EndTextCommandSetBlipName(blip)

                -- Set GPS waypoint
                SetNewWaypoint(coords.x, coords.y)

                Wait(Config.BlipTime * 1000)
                RemoveBlip(blip)
                break
            end
            Wait(0)
        end
    end)
end)
