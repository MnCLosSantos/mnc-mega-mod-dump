local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local hasUniform = false
local originalClothes = nil
local lastUniformAttempt = 0
local zoneRefs = {}

local function Notify(msg, type, duration)
    lib.notify({
        title = 'Job Clothing',
        description = msg,
        type = type or 'inform',
        duration = duration or Config.DefaultNotifyTime
    })
end

local function DoProgress(label, duration)
    local success
    if Config.Progress == 'circle' then
        success = lib.progressCircle({
            duration = duration,
            label = label,
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 }
        })
    else
        success = lib.progressBar({
            duration = duration,
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 }
        })
    end
    return success == true
end

local function GetCurrentOutfit()
    local ped = PlayerPedId()
    local outfit = {}

    for i = 0, 11 do
        outfit['comp_' .. i] = {
            item = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i)
        }
    end

    local propIndices = {0, 1, 2, 6, 7}
    for _, i in ipairs(propIndices) do
        local drawable = GetPedPropIndex(ped, i)
        outfit['prop_' .. i] = {
            item = (drawable ~= -1) and drawable or -1,
            texture = GetPedPropTextureIndex(ped, i)
        }
    end

    return outfit
end

local function ApplyOutfit(outfitData)
    local ped = PlayerPedId()

    local isNewFormat = outfitData.comp_0 ~= nil

    if isNewFormat then
        for i = 0, 11 do
            local key = 'comp_' .. i
            if outfitData[key] then
                SetPedComponentVariation(ped, i, outfitData[key].item or 0, outfitData[key].texture or 0, 0)
            end
        end

        local propIndices = {0, 1, 2, 6, 7}
        for _, i in ipairs(propIndices) do
            local key = 'prop_' .. i
            if outfitData[key] then
                if outfitData[key].item >= 0 then
                    SetPedPropIndex(ped, i, outfitData[key].item, outfitData[key].texture or 0, true)
                else
                    ClearPedProp(ped, i)
                end
            end
        end
    else
        -- Legacy support
        local oldMap = {
            tshirt = 8, torso2 = 11, pants = 4, shoes = 6, arms = 3,
            decals = 10, vest = 9, bag = 5
        }
        for key, slot in pairs(oldMap) do
            if outfitData[key] then
                SetPedComponentVariation(ped, slot, outfitData[key].item or 0, outfitData[key].texture or 0, 0)
            end
        end
        if outfitData.hat then
            if outfitData.hat.item >= 0 then
                SetPedPropIndex(ped, 0, outfitData.hat.item, outfitData.hat.texture or 0, true)
            else
                ClearPedProp(ped, 0)
            end
        end
    end
end

local function ChangeIntoUniform(outfitData)
    if hasUniform then
        Notify('You are already wearing a job uniform!', 'error')
        return
    end

    if GetGameTimer() - lastUniformAttempt < 10000 then
        Notify('Please wait before changing again.', 'error')
        return
    end
    lastUniformAttempt = GetGameTimer()

    local ped = PlayerPedId()

    originalClothes = { components = {}, props = {} }
    for i = 0, 11 do
        originalClothes.components[i] = { drawable = GetPedDrawableVariation(ped, i), texture = GetPedTextureVariation(ped, i) }
    end
    local propIndices = {0, 1, 2, 6, 7}
    for _, i in ipairs(propIndices) do
        originalClothes.props[i] = { drawable = GetPedPropIndex(ped, i), texture = GetPedPropTextureIndex(ped, i) }
    end

    if DoProgress('Putting on uniform...', 5000) then
        ApplyOutfit(outfitData)
        hasUniform = true
        Notify('Uniform equipped!', 'success')
    else
        Notify('Action cancelled.', 'error')
        originalClothes = nil
    end
end

local function ChangeToCivilian()
    if not hasUniform or not originalClothes then
        Notify('You are not wearing a job uniform!', 'error')
        return
    end

    if DoProgress('Changing into civilian clothes...', 4000) then
        local ped = PlayerPedId()
        for i = 0, 11 do
            local c = originalClothes.components[i]
            SetPedComponentVariation(ped, i, c.drawable, c.texture, 0)
        end
        local propIndices = {0, 1, 2, 6, 7}
        for _, i in ipairs(propIndices) do
            local p = originalClothes.props[i]
            if p.drawable >= 0 then
                SetPedPropIndex(ped, i, p.drawable, p.texture, true)
            else
                ClearPedProp(ped, i)
            end
        end

        hasUniform = false
        originalClothes = nil
        Notify('Back to civilian clothes!', 'success')
    else
        Notify('Action cancelled.', 'error')
    end
end

local function OpenClothingMenu(location)
    PlayerData = QBCore.Functions.GetPlayerData()
    local job = PlayerData.job.name
    local grade = PlayerData.job.grade.level
    local gender = (PlayerData.charinfo.gender == 0) and 'male' or 'female'

    if location.job and job ~= location.job then
        Notify('This locker room is for ' .. location.job .. ' only.', 'error')
        return
    end

    if location.require_onduty and not PlayerData.job.onduty then
        Notify('You must be on duty.', 'error')
        return
    end

    if grade < location.min_grade_to_use then
        Notify('Your grade is too low.', 'error')
        return
    end

    TriggerServerEvent('mnc-jobclothing:server:GetOutfits', location.name, job, gender)
end

RegisterNetEvent('mnc-jobclothing:client:ReceiveOutfits', function(outfits, location, canAdd)
    PlayerData = QBCore.Functions.GetPlayerData()
    local playerGrade = PlayerData.job.grade.level

    local options = {}

    if #outfits == 0 then
        table.insert(options, { title = 'No saved outfits', icon = 'ban', disabled = true })
    else
        for _, outfit in ipairs(outfits) do
            local requiredGrade = outfit.min_grade or 0
            local canWear = playerGrade >= requiredGrade

            table.insert(options, {
                title = outfit.name,
                icon = outfit.icon or 'hanger',
                description = canWear and 'Click to manage' or ('Requires Grade ' .. requiredGrade),
                arrow = true,
                metadata = { ['Min Grade'] = requiredGrade },
                disabled = not canWear and not canAdd,
                onSelect = function()
                    local subOptions = {}

                    if canWear then
                        table.insert(subOptions, {
                            title = 'Wear Outfit',
                            icon = 'check',
                            onSelect = function() ChangeIntoUniform(outfit.data) end
                        })
                    end

                    if canAdd then
                        table.insert(subOptions, {
                            title = 'Update Outfit',
                            icon = 'pencil',
                            description = 'Overwrite with current appearance',
                            onSelect = function()
                                local confirmed = lib.alertDialog({
                                    header = 'Update Outfit',
                                    content = ('Overwrite **%s** with your current clothes?\n\nThis will replace the saved version.'):format(outfit.name),
                                    centered = true,
                                    cancel = true
                                })

                                if confirmed == 'confirm' then
                                    local currentData = GetCurrentOutfit()
                                    TriggerServerEvent('mnc-jobclothing:server:SaveOutfit',
                                        location.name, PlayerData.job.name, outfit.name, currentData,
                                        outfit.min_grade, outfit.icon, true)
                                    Wait(600)
                                    TriggerServerEvent('mnc-jobclothing:server:GetOutfits',
                                        location.name, PlayerData.job.name,
                                        (PlayerData.charinfo.gender == 0) and 'male' or 'female')
                                end
                            end
                        })

                        table.insert(subOptions, {
                            title = 'Delete Outfit',
                            icon = 'trash',
                            onSelect = function()
                                local confirmed = lib.alertDialog({
                                    header = 'Delete Outfit',
                                    content = ('Permanently delete **%s**?\n\nThis cannot be undone.'):format(outfit.name),
                                    centered = true,
                                    cancel = true
                                })

                                if confirmed == 'confirm' then
                                    TriggerServerEvent('mnc-jobclothing:server:DeleteOutfit',
                                        outfit.name, location.name, PlayerData.job.name)
                                    Wait(400)
                                    TriggerServerEvent('mnc-jobclothing:server:GetOutfits',
                                        location.name, PlayerData.job.name,
                                        (PlayerData.charinfo.gender == 0) and 'male' or 'female')
                                end
                            end
                        })
                    end

                    lib.registerContext({
                        id = 'outfit_submenu_' .. outfit.name,
                        title = outfit.name,
                        menu = 'jobclothing_menu',
                        options = subOptions
                    })
                    lib.showContext('outfit_submenu_' .. outfit.name)
                end
            })
        end
    end

    table.insert(options, { title = 'Civilian Clothes', icon = 'user', onSelect = ChangeToCivilian })

    if canAdd then
        table.insert(options, {
            title = 'Save New Outfit',
            icon = 'floppy-disk',
            onSelect = function()
                local input = lib.inputDialog('Save New Outfit', {
                    { type = 'input', label = 'Outfit Name', required = true },
                    { type = 'number', label = 'Minimum Grade', default = 0, min = 0, max = 10 },
                    { type = 'select', label = 'Icon', default = 'hanger', options = {
                        { value = 'hanger', label = 'Hanger (Default)' },
                        { value = 'shirt', label = 'Shirt' },
                        { value = 'tshirt', label = 'T-Shirt' },
                        { value = 'user-tie', label = 'Tie (Formal/Suit)' },
                        { value = 'briefcase', label = 'Briefcase (Business)' },
                        { value = 'hard-hat', label = 'Hard Hat (Construction)' },
                        { value = 'wrench', label = 'Wrench (Mechanic)' },
                        { value = 'vest', label = 'Vest' },
                        { value = 'vest-patches', label = 'Vest with Patches' },
                        { value = 'shield-halved', label = 'Badge/Shield (Police)' },
                        { value = 'handcuffs', label = 'Handcuffs (Police)' },
                        { value = 'stethoscope', label = 'Stethoscope (Medic)' },
                        { value = 'helmet-safety', label = 'Safety Helmet' },
                        { value = 'glasses', label = 'Glasses' },
                        { value = 'hat-cowboy', label = 'Cowboy Hat' },
                        { value = 'mask', label = 'Mask' },
                        { value = 'graduation-cap', label = 'Graduation Cap' },
                        { value = 'toolbox', label = 'Toolbox (Mechanic)' },
                        { value = 'screwdriver-wrench', label = 'Tools (Mechanic)' },
                        { value = 'car', label = 'Car (Driver/Mechanic)' },
                        { value = 'id-badge', label = 'ID Badge' },
                        { value = 'id-card', label = 'ID Card' },
                        { value = 'key', label = 'Key (Security)' },
                        { value = 'fire-flame-curved', label = 'Fire (Firefighter)' },
                        { value = 'truck-medical', label = 'Ambulance (Medic)' },
                        { value = 'truck', label = 'Truck (Delivery)' },
                        { value = 'ban', label = 'None (No Icon)' }
                    }}
                })
                if input and input[1] ~= '' then
                    local outfitData = GetCurrentOutfit()
                    TriggerServerEvent('mnc-jobclothing:server:SaveOutfit',
                        location.name, PlayerData.job.name, input[1], outfitData, input[2], input[3], false)
                    Wait(500)
                    TriggerServerEvent('mnc-jobclothing:server:GetOutfits',
                        location.name, PlayerData.job.name,
                        (PlayerData.charinfo.gender == 0) and 'male' or 'female')
                end
            end
        })
    end

    lib.registerContext({
        id = 'jobclothing_menu',
        title = location.label or 'Job Clothing',
        options = options
    })
    lib.showContext('jobclothing_menu')
end)

CreateThread(function()
    for i, loc in ipairs(Config.Locations) do
        local zoneName = 'jobclothing_zone_' .. i
        exports['qb-target']:AddBoxZone(zoneName, vec3(loc.coords.xyz), Config.ZoneSize.x, Config.ZoneSize.y, {
            name = zoneName,
            heading = loc.coords.w,
            debugPoly = Config.Debug,
            minZ = loc.coords.z - 1.5,
            maxZ = loc.coords.z + 1.5,
        }, {
            options = {
                {
                    icon = 'shirt',
                    label = loc.label or 'Change Clothes',
                    action = function() OpenClothingMenu(loc) end
                }
            },
            distance = 2.5
        })
        zoneRefs[i] = zoneName
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, zone in ipairs(zoneRefs) do
            exports['qb-target']:RemoveZone(zone)
        end
    end
end)