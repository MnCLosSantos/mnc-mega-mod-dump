local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    MySQL.ready(function()
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `job_outfits` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `job` VARCHAR(50) NOT NULL,
                `location` VARCHAR(50) NOT NULL,
                `name` VARCHAR(100) NOT NULL,
                `gender` ENUM('male','female') NOT NULL,
                `data` JSON NOT NULL,
                `icon` VARCHAR(50) DEFAULT 'hanger',
                `min_grade` INT DEFAULT 0,
                INDEX idx_job_location_gender (job, location, gender)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])

        MySQL.scalar('SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = "job_outfits" AND COLUMN_NAME = "icon"', {}, function(result)
            if result == 0 then
                MySQL.query('ALTER TABLE `job_outfits` ADD COLUMN `icon` VARCHAR(50) DEFAULT "hanger" AFTER `data`')
                print('^3[mnc-jobclothing]^7 Added missing "icon" column to job_outfits table.')
            end
        end)

        MySQL.scalar('SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = "job_outfits" AND COLUMN_NAME = "min_grade"', {}, function(result)
            if result == 0 then
                MySQL.query('ALTER TABLE `job_outfits` ADD COLUMN `min_grade` INT DEFAULT 0 AFTER `icon`')
                print('^3[mnc-jobclothing]^7 Added missing "min_grade" column to job_outfits table.')
            end
        end)

        print('^2[mnc-jobclothing]^7 Database table `job_outfits` ready.')
    end)
end)

RegisterNetEvent('mnc-jobclothing:server:GetOutfits', function(locationName, job, gender)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local result = MySQL.query.await('SELECT name, data, min_grade, icon FROM job_outfits WHERE location = ? AND job = ? AND gender = ?', {
        locationName, job, gender
    })

    local outfits = {}
    for _, row in ipairs(result) do
        table.insert(outfits, {
            name = row.name,
            data = json.decode(row.data),
            min_grade = row.min_grade or 0,
            icon = row.icon or 'hanger'
        })
    end

    local locationCfg = nil
    for _, loc in ipairs(Config.Locations) do
        if loc.name == locationName then locationCfg = loc break end
    end

    local canAdd = locationCfg and (Player.PlayerData.job.grade.level >= (locationCfg.min_grade_to_add or 0))

    TriggerClientEvent('mnc-jobclothing:client:ReceiveOutfits', src, outfits, locationCfg or {}, canAdd)
end)

RegisterNetEvent('mnc-jobclothing:server:SaveOutfit', function(locationName, job, outfitName, outfitData, minGrade, selectedIcon, isUpdate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local locationCfg = nil
    for _, loc in ipairs(Config.Locations) do
        if loc.name == locationName then locationCfg = loc break end
    end

    if not locationCfg or Player.PlayerData.job.grade.level < (locationCfg.min_grade_to_add or 0) then 
        lib.notify(src, { title = 'Error', description = 'No permission to save outfits.', type = 'error' })
        return 
    end

    local gender = (Player.PlayerData.charinfo.gender == 0) and 'male' or 'female'
    minGrade = tonumber(minGrade) or 0
    selectedIcon = selectedIcon or 'hanger'

    local query, params
    if isUpdate then
        -- Update existing outfit
        query = 'UPDATE job_outfits SET data = ?, icon = ?, min_grade = ? WHERE job = ? AND location = ? AND name = ? AND gender = ?'
        params = { json.encode(outfitData), selectedIcon, minGrade, job, locationName, outfitName, gender }
    else
        -- Insert new (or update if exists due to unique key)
        query = 'INSERT INTO job_outfits (job, location, name, gender, data, icon, min_grade) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data), icon = VALUES(icon), min_grade = VALUES(min_grade)'
        params = { job, locationName, outfitName, gender, json.encode(outfitData), selectedIcon, minGrade }
    end

    MySQL.update(query, params, function(affectedRows)
        if affectedRows > 0 then
            lib.notify(src, { title = 'Success', description = '"'..outfitName..'" ' .. (isUpdate and 'updated' or 'saved') .. '!', type = 'success' })
        else
            lib.notify(src, { title = 'Error', description = 'Failed to save outfit.', type = 'error' })
        end
    end)
end)

RegisterNetEvent('mnc-jobclothing:server:DeleteOutfit', function(outfitName, locationName, job)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local locationCfg = nil
    for _, loc in ipairs(Config.Locations) do
        if loc.name == locationName then locationCfg = loc break end
    end

    if not locationCfg or Player.PlayerData.job.grade.level < (locationCfg.min_grade_to_add or 0) then
        lib.notify(src, { title = 'Error', description = 'No permission.', type = 'error' })
        return
    end

    local gender = (Player.PlayerData.charinfo.gender == 0) and 'male' or 'female'

    MySQL.query('DELETE FROM job_outfits WHERE name = ? AND location = ? AND job = ? AND gender = ?', {
        outfitName, locationName, job, gender
    }, function(affectedRows)
        if affectedRows > 0 then
            lib.notify(src, { title = 'Success', description = '"'..outfitName..'" deleted.', type = 'success' })
        else
            lib.notify(src, { title = 'Error', description = 'Outfit not found.', type = 'error' })
        end
    end)
end)

print("^2[mnc-jobclothing]^7 Script loaded successfully!")