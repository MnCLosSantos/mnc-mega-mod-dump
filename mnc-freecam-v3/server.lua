-- server.lua — mnc-freecam

-- ─────────────────────────────────────────────
-- oxmysql export alias
-- ─────────────────────────────────────────────
local ox = exports['oxmysql']

-- ─────────────────────────────────────────────
-- Auto-create table
-- ─────────────────────────────────────────────
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Citizen.CreateThread(function()
        -- Poll until oxmysql is ready
        while not pcall(function() ox:query('SELECT 1', {}, function() end) end) do
            Wait(200)
        end
        ox:query([[
            CREATE TABLE IF NOT EXISTS `mnc_freecam_sequences` (
                `id`               INT(11)      NOT NULL AUTO_INCREMENT,
                `citizenid`        VARCHAR(50)  NOT NULL,
                `name`             VARCHAR(100) NOT NULL DEFAULT 'Untitled',
                `type`             ENUM('world','vehicle') NOT NULL DEFAULT 'world',
                `share_code`       VARCHAR(40)  NOT NULL,
                `keyframes`        LONGTEXT     NOT NULL,
                `default_duration` FLOAT        NOT NULL DEFAULT 3.0,
                `playback_mode`    ENUM('once','loop','pingpong') NOT NULL DEFAULT 'once',
                `source_share_code` VARCHAR(40)  NULL DEFAULT NULL,
                `created_at`       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                UNIQUE KEY `uq_share_code` (`share_code`),
                KEY `idx_citizenid` (`citizenid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]], {}, function()
            print('^2[mnc-freecam]^7 Sequences table ready.')
        end)

        -- Add source_share_code column if upgrading from older schema
        ox:query([[
            ALTER TABLE `mnc_freecam_sequences`
            ADD COLUMN IF NOT EXISTS `source_share_code` VARCHAR(40) NULL DEFAULT NULL
        ]], {}, function() end)

        -- Fix mode_id boolean coercion: TINYINT(1) is treated as bool by some drivers
        ox:query([[
            ALTER TABLE `mnc_freecam_cam_offsets`
            MODIFY COLUMN `mode_id` TINYINT(4) NOT NULL COMMENT '0=Bumper 1=Close 2=Far 4=Driver'
        ]], {}, function() end)

        ox:query([[
            CREATE TABLE IF NOT EXISTS `mnc_freecam_cam_offsets` (
                `citizenid`      VARCHAR(50)  NOT NULL,
                `mode_id`        TINYINT(4)   NOT NULL COMMENT '0=Bumper 1=Close 2=Far 4=Driver',
                `lx`             FLOAT        NOT NULL DEFAULT 0.0,
                `ly`             FLOAT        NOT NULL DEFAULT 0.0,
                `lz`             FLOAT        NOT NULL DEFAULT 0.0,
                `init_pitch`     FLOAT        NOT NULL DEFAULT 0.0,
                `init_yaw`       FLOAT        NOT NULL DEFAULT 0.0,
                `init_roll`      FLOAT        NOT NULL DEFAULT 0.0,
                `init_fov`       FLOAT        NOT NULL DEFAULT 70.0,
                `model_allowed`  TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '1 = per-model presets enabled for this cam',
                PRIMARY KEY (`citizenid`, `mode_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]], {}, function()
            print('^2[mnc-freecam]^7 Cam offsets table ready.')
        end)

        -- Add new columns to existing tables (upgrade path)
        ox:query([[
            ALTER TABLE `mnc_freecam_cam_offsets`
            ADD COLUMN IF NOT EXISTS `init_yaw`      FLOAT      NOT NULL DEFAULT 0.0,
            ADD COLUMN IF NOT EXISTS `init_roll`     FLOAT      NOT NULL DEFAULT 0.0,
            ADD COLUMN IF NOT EXISTS `init_fov`      FLOAT      NOT NULL DEFAULT 70.0,
            ADD COLUMN IF NOT EXISTS `model_allowed` TINYINT(1) NOT NULL DEFAULT 0
        ]], {}, function() end)

        -- Per-model cam offsets (any cam with model_allowed=1), keyed by mode_id + model_hash
        ox:query([[
            CREATE TABLE IF NOT EXISTS `mnc_freecam_model_offsets` (
                `citizenid`  VARCHAR(50)  NOT NULL,
                `mode_id`    TINYINT(4)   NOT NULL DEFAULT 4 COMMENT 'cam mode this preset applies to',
                `model_hash` INT          NOT NULL COMMENT 'GetEntityModel() hash',
                `lx`         FLOAT        NOT NULL DEFAULT 0.0,
                `ly`         FLOAT        NOT NULL DEFAULT 0.0,
                `lz`         FLOAT        NOT NULL DEFAULT 0.0,
                `init_pitch` FLOAT        NOT NULL DEFAULT 0.0,
                `init_yaw`   FLOAT        NOT NULL DEFAULT 0.0,
                `init_roll`  FLOAT        NOT NULL DEFAULT 0.0,
                `init_fov`   FLOAT        NOT NULL DEFAULT 70.0,
                `model_name` VARCHAR(60)  NOT NULL DEFAULT '',
                PRIMARY KEY (`citizenid`, `mode_id`, `model_hash`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]], {}, function()
            print('^2[mnc-freecam]^7 Model offsets table ready.')
        end)

        -- Upgrade: add mode_id and init_fov to existing model_offsets table
        ox:query([[
            ALTER TABLE `mnc_freecam_model_offsets`
            ADD COLUMN IF NOT EXISTS `mode_id`  TINYINT(4) NOT NULL DEFAULT 4,
            ADD COLUMN IF NOT EXISTS `init_fov` FLOAT      NOT NULL DEFAULT 70.0
        ]], {}, function()
            -- Rebuild PK to include mode_id (safe even if already correct)
            ox:query([[
                ALTER TABLE `mnc_freecam_model_offsets`
                DROP PRIMARY KEY,
                ADD PRIMARY KEY (`citizenid`, `mode_id`, `model_hash`)
            ]], {}, function() end)
        end)

        -- Per-citizen cam flags (cycle-hidden, hide-peds, auto-head-track) — replaces KVP
        ox:query([[
            CREATE TABLE IF NOT EXISTS `mnc_freecam_cam_flags` (
                `citizenid`       VARCHAR(50)  NOT NULL,
                `cam_id`          VARCHAR(40)  NOT NULL COMMENT 'e.g. vehicle_0, vehicle_4, freecam',
                `cycle_hidden`    TINYINT(1)   NOT NULL DEFAULT 0,
                `hide_peds`       TINYINT(1)   NOT NULL DEFAULT 0,
                `auto_head_track` TINYINT(1)   NOT NULL DEFAULT 0,
                PRIMARY KEY (`citizenid`, `cam_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]], {}, function()
            print('^2[mnc-freecam]^7 Cam flags table ready.')
        end)

        -- Per-citizen custom cam definitions — replaces KVP JSON blob
        ox:query([[
            CREATE TABLE IF NOT EXISTS `mnc_freecam_custom_cams` (
                `citizenid`  VARCHAR(50)  NOT NULL,
                `cam_id`     INT          NOT NULL COMMENT 'numeric GTA view mode id',
                `label`      VARCHAR(40)  NOT NULL DEFAULT 'Custom Cam',
                PRIMARY KEY (`citizenid`, `cam_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]], {}, function()
            print('^2[mnc-freecam]^7 Custom cams table ready.')
        end)

        -- Per-citizen freecam presets — replaces KVP slots 1-20
        ox:query([[
            CREATE TABLE IF NOT EXISTS `mnc_freecam_presets` (
                `citizenid`   VARCHAR(50)  NOT NULL,
                `slot`        TINYINT(4)   NOT NULL COMMENT '1-20',
                `name`        VARCHAR(60)  NOT NULL DEFAULT 'Preset',
                `data`        TEXT         NOT NULL COMMENT 'JSON blob of preset fields',
                PRIMARY KEY (`citizenid`, `slot`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]], {}, function()
            print('^2[mnc-freecam]^7 Presets table ready.')
        end)
    end)
end)

-- ─────────────────────────────────────────────
-- 4-word share code generator
-- ─────────────────────────────────────────────
local WORDS_A = {"TIGER","WOLF","EAGLE","RAVEN","COBRA","VIPER","GHOST","STORM","IRON","NEON","AZURE","JADE","ONYX","RUBY","EMBER","FROST","LUNAR","SOLAR","NOVA","ECHO"}
local WORDS_B = {"BLUE","RED","GOLD","SILVER","BLACK","WHITE","GREEN","VIOLET","AMBER","CRIMSON","TEAL","PEARL","SAGE","CORAL","STEEL","SLATE","IVORY","SMOKE","BONE","ASH"}
local WORDS_C = {"1","2","3","4","5","6","7","8","9","11","12","13","21","22","33","44","55","66","77","88"}
local WORDS_D = {"SUNSET","DAWN","DUSK","ZENITH","PEAK","RIDGE","VALE","CREST","EDGE","VOID","GATE","MARK","LINE","WAVE","PULSE","SHIFT","DRIFT","GLOW","FLARE","BURN"}

local function generateShareCode()
    local a = WORDS_A[math.random(#WORDS_A)]
    local b = WORDS_B[math.random(#WORDS_B)]
    local c = WORDS_C[math.random(#WORDS_C)]
    local d = WORDS_D[math.random(#WORDS_D)]
    return a .. "-" .. b .. "-" .. c .. "-" .. d
end

-- Async: generates a unique code, then calls cb(code)
local function uniqueShareCode(cb)
    local code = generateShareCode()
    ox:scalar('SELECT COUNT(*) FROM mnc_freecam_sequences WHERE share_code = ?', { code }, function(count)
        if count and count > 0 then
            uniqueShareCode(cb)   -- retry
        else
            cb(code)
        end
    end)
end

-- ─────────────────────────────────────────────
-- Get player citizenid
-- ─────────────────────────────────────────────
local function getCitizenId(src)
    local Player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(src)
    if Player then return Player.PlayerData.citizenid end
    return nil
end

-- ─────────────────────────────────────────────
-- Cinematic sequences
-- ─────────────────────────────────────────────
RegisterNetEvent('mnc-freecam:saveSequence', function(data)
    local src    = source
    local cid    = getCitizenId(src)
    if not cid then return end

    local seqId  = data.id
    local name   = tostring(data.name or 'Untitled'):sub(1, 100)
    local seqType = (data.type == 'vehicle') and 'vehicle' or 'world'
    local kfJson = json.encode(data.keyframes or {})
    local dur    = tonumber(data.default_duration) or 3.0
    local mode   = (data.playback_mode == 'loop' or data.playback_mode == 'pingpong') and data.playback_mode or 'once'

    if seqId and tonumber(seqId) and tonumber(seqId) > 0 then
        -- Update existing
        ox:scalar('SELECT citizenid FROM mnc_freecam_sequences WHERE id = ?', { data.id }, function(owner)
            if owner ~= cid then
                TriggerClientEvent('mnc-freecam:notify', src, 'error', 'Not your sequence.')
                return
            end
            ox:query(
                'UPDATE mnc_freecam_sequences SET name=?, type=?, keyframes=?, default_duration=?, playback_mode=? WHERE id=? AND citizenid=?',
                { name, seqType, kfJson, dur, mode, seqId, cid },
                function()
                    ox:scalar('SELECT share_code FROM mnc_freecam_sequences WHERE id=?', { seqId }, function(sc)
                        TriggerClientEvent('mnc-freecam:sequenceSaved', src, { id=seqId, share_code=sc or '' })
                    end)
                end
            )
        end)
    else
        -- Insert new
        uniqueShareCode(function(code)
            ox:insert(
                'INSERT INTO mnc_freecam_sequences (citizenid, name, type, share_code, keyframes, default_duration, playback_mode) VALUES (?,?,?,?,?,?,?)',
                { cid, name, seqType, code, kfJson, dur, mode },
                function(newId)
                    TriggerClientEvent('mnc-freecam:sequenceSaved', src, { id=newId, share_code=code })
                end
            )
        end)
    end
end)

RegisterNetEvent('mnc-freecam:loadMySequences', function()
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    ox:query(
        'SELECT id, name, type, share_code, default_duration, playback_mode, created_at FROM mnc_freecam_sequences WHERE citizenid = ? ORDER BY created_at DESC',
        { cid },
        function(rows)
            TriggerClientEvent('mnc-freecam:receiveSequences', src, rows or {})
        end
    )
end)

RegisterNetEvent('mnc-freecam:loadSequence', function(seqId)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    ox:query(
        'SELECT * FROM mnc_freecam_sequences WHERE id = ? AND citizenid = ?',
        { seqId, cid },
        function(rows)
            if rows and rows[1] then
                local row = rows[1]
                local ok, kf = pcall(json.decode, row.keyframes or '[]')
                row.keyframes = (ok and kf) or {}
                TriggerClientEvent('mnc-freecam:receiveSequence', src, row)
            end
        end
    )
end)

RegisterNetEvent('mnc-freecam:deleteSequence', function(seqId)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    ox:scalar('SELECT citizenid FROM mnc_freecam_sequences WHERE id = ?', { seqId }, function(owner)
        if owner ~= cid then
            TriggerClientEvent('mnc-freecam:notify', src, 'error', 'Not your sequence.')
            return
        end
        ox:query('DELETE FROM mnc_freecam_sequences WHERE id = ? AND citizenid = ?', { seqId, cid }, function()
            TriggerClientEvent('mnc-freecam:sequenceDeleted', src, seqId)
        end)
    end)
end)

RegisterNetEvent('mnc-freecam:importByCode', function(code)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    -- Check if player already owns the original OR a previously imported copy of it
    ox:scalar('SELECT share_code FROM mnc_freecam_sequences WHERE share_code = ?', { code }, function(found)
        if not found then
            TriggerClientEvent('mnc-freecam:notify', src, 'error', 'Share code not found: ' .. code)
            return
        end
        ox:query(
            'SELECT COUNT(*) FROM mnc_freecam_sequences WHERE citizenid = ? AND (share_code = ? OR source_share_code = ?)',
            { cid, code, code },
            function(rows)
                local count = rows and rows[1] and (rows[1]['COUNT(*)'] or 0) or 0
                if count > 0 then
                    TriggerClientEvent('mnc-freecam:notify', src, 'error', 'You already have this sequence.')
                    return
                end
                ox:query('SELECT * FROM mnc_freecam_sequences WHERE share_code = ?', { code }, function(srcRows)
                    if not srcRows or not srcRows[1] then return end
                    local orig = srcRows[1]
                    local ok, kf = pcall(json.decode, orig.keyframes or '[]')
                    local kfJson = json.encode((ok and kf) or {})
                    uniqueShareCode(function(newCode)
                        ox:insert(
                            'INSERT INTO mnc_freecam_sequences (citizenid, name, type, share_code, source_share_code, keyframes, default_duration, playback_mode) VALUES (?,?,?,?,?,?,?,?)',
                            { cid, orig.name, orig.type, newCode, code, kfJson, orig.default_duration, orig.playback_mode },
                            function()
                                TriggerClientEvent('mnc-freecam:sequenceImported', src, { name = orig.name })
                            end
                        )
                    end)
                end)
            end
        )
    end)
end)

-- ─────────────────────────────────────────────
-- Cam offset save / load
-- ─────────────────────────────────────────────

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, tonumber(v) or 0)) end

-- Load all saved offsets for the player — sent on freecam open
RegisterNetEvent('mnc-freecam:loadCamOffsets', function()
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    ox:query(
        'SELECT mode_id, lx, ly, lz, init_pitch, init_yaw, init_roll, init_fov, model_allowed FROM mnc_freecam_cam_offsets WHERE citizenid = ?',
        { cid },
        function(rows)
            TriggerClientEvent('mnc-freecam:receiveCamOffsets', src, rows or {})
        end
    )
end)

-- Save one mode's offsets (upsert)
RegisterNetEvent('mnc-freecam:saveCamOffset', function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    local modeId = tonumber(data.mode_id)
    local lx = clamp(data.lx,        -8,  8)
    local ly = clamp(data.ly,       -20, 20)
    local lz = clamp(data.lz,        -3, 15)
    local ip = clamp(data.init_pitch,-89, 89)
    local iy = clamp(data.init_yaw, -180,180)
    local ir = clamp(data.init_roll, -89, 89)
    local ifov = clamp(data.init_fov or 70.0, 10, 120)
    local ma = data.model_allowed and 1 or 0

    ox:query('DELETE FROM mnc_freecam_cam_offsets WHERE citizenid = ? AND mode_id = ?',
        { cid, modeId },
        function()
            ox:insert(
                'INSERT INTO mnc_freecam_cam_offsets (citizenid, mode_id, lx, ly, lz, init_pitch, init_yaw, init_roll, init_fov, model_allowed) VALUES (?,?,?,?,?,?,?,?,?,?)',
                { cid, modeId, lx, ly, lz, ip, iy, ir, ifov, ma },
                function(newId)
                    TriggerClientEvent('mnc-freecam:notify', src, 'success', 'Camera offset saved.')
                    TriggerClientEvent('mnc-freecam:camOffsetSaved', src, {
                        mode_id=modeId, lx=lx, ly=ly, lz=lz,
                        init_pitch=ip, init_yaw=iy, init_roll=ir,
                        init_fov=ifov, model_allowed=ma,
                    })
                end
            )
        end
    )
end)

-- Reset one mode's offsets back to default (delete row)
RegisterNetEvent('mnc-freecam:resetCamOffset', function(modeId)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    ox:query('DELETE FROM mnc_freecam_cam_offsets WHERE citizenid = ? AND mode_id = ?', { cid, modeId }, function()
        TriggerClientEvent('mnc-freecam:notify', src, 'success', 'Camera offset reset to default.')
        TriggerClientEvent('mnc-freecam:camOffsetReset', src, modeId)
    end)
end)

-- ─────────────────────────────────────────────
-- Per-model driver cam offsets
-- ─────────────────────────────────────────────

RegisterNetEvent('mnc-freecam:loadModelOffsets', function()
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    ox:query(
        'SELECT mode_id, model_hash, model_name, lx, ly, lz, init_pitch, init_yaw, init_roll, init_fov FROM mnc_freecam_model_offsets WHERE citizenid = ?',
        { cid },
        function(rows)
            TriggerClientEvent('mnc-freecam:receiveModelOffsets', src, rows or {})
        end
    )
end)

RegisterNetEvent('mnc-freecam:saveModelOffset', function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    local modeId    = tonumber(data.mode_id) or 4
    local hash      = tonumber(data.model_hash)
    local modelName = tostring(data.model_name or ''):sub(1, 60)
    local lx = clamp(data.lx,        -8,  8)
    local ly = clamp(data.ly,       -20, 20)
    local lz = clamp(data.lz,        -3, 15)
    local ip = clamp(data.init_pitch,-89, 89)
    local iy = clamp(data.init_yaw, -180,180)
    local ir = clamp(data.init_roll, -89, 89)
    local ifov = clamp(data.init_fov or 70.0, 10, 120)

    ox:query('DELETE FROM mnc_freecam_model_offsets WHERE citizenid = ? AND mode_id = ? AND model_hash = ?',
        { cid, modeId, hash },
        function()
            ox:insert(
                'INSERT INTO mnc_freecam_model_offsets (citizenid, mode_id, model_hash, model_name, lx, ly, lz, init_pitch, init_yaw, init_roll, init_fov) VALUES (?,?,?,?,?,?,?,?,?,?,?)',
                { cid, modeId, hash, modelName, lx, ly, lz, ip, iy, ir, ifov },
                function()
                    TriggerClientEvent('mnc-freecam:notify', src, 'success', 'Model cam saved: ' .. modelName)
                    TriggerClientEvent('mnc-freecam:modelOffsetSaved', src, {
                        mode_id=modeId, model_hash=hash, model_name=modelName,
                        lx=lx, ly=ly, lz=lz, init_pitch=ip, init_yaw=iy, init_roll=ir, init_fov=ifov,
                    })
                end
            )
        end
    )
end)

RegisterNetEvent('mnc-freecam:deleteModelOffset', function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    local modeId = tonumber(data.mode_id) or 4
    local hash   = tonumber(data.model_hash)
    ox:query('DELETE FROM mnc_freecam_model_offsets WHERE citizenid = ? AND mode_id = ? AND model_hash = ?',
        { cid, modeId, hash },
        function()
            TriggerClientEvent('mnc-freecam:notify', src, 'success', 'Model cam preset deleted.')
            TriggerClientEvent('mnc-freecam:modelOffsetDeleted', src, { mode_id=modeId, model_hash=hash })
        end
    )
end)

-- ─────────────────────────────────────────────
-- Cam flags (cycle-hidden, hide-peds, auto-head-track) — per citizenid
-- ─────────────────────────────────────────────

-- Load all flags for this player on freecam/camsets open
RegisterNetEvent('mnc-freecam:loadCamFlags', function()
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    ox:query('SELECT cam_id, cycle_hidden, hide_peds, auto_head_track FROM mnc_freecam_cam_flags WHERE citizenid = ?',
        { cid },
        function(rows)
            TriggerClientEvent('mnc-freecam:receiveCamFlags', src, rows or {})
        end
    )
end)

-- Upsert one cam's flags
RegisterNetEvent('mnc-freecam:saveCamFlag', function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    local camId = tostring(data.cam_id or ''):sub(1, 40)
    if camId == '' then return end
    local ch  = data.cycle_hidden    and 1 or 0
    local hp  = data.hide_peds       and 1 or 0
    local aht = data.auto_head_track and 1 or 0
    ox:query(
        'INSERT INTO mnc_freecam_cam_flags (citizenid, cam_id, cycle_hidden, hide_peds, auto_head_track) VALUES (?,?,?,?,?) ON DUPLICATE KEY UPDATE cycle_hidden=VALUES(cycle_hidden), hide_peds=VALUES(hide_peds), auto_head_track=VALUES(auto_head_track)',
        { cid, camId, ch, hp, aht },
        function() end
    )
end)

-- ─────────────────────────────────────────────
-- Custom cams — per citizenid
-- ─────────────────────────────────────────────

RegisterNetEvent('mnc-freecam:loadCustomCams', function()
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    ox:query('SELECT cam_id, label FROM mnc_freecam_custom_cams WHERE citizenid = ? ORDER BY cam_id ASC',
        { cid },
        function(rows)
            TriggerClientEvent('mnc-freecam:receiveCustomCams', src, rows or {})
        end
    )
end)

RegisterNetEvent('mnc-freecam:saveCustomCam', function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    local camId = tonumber(data.cam_id)
    local label = tostring(data.label or ''):sub(1, 40)
    if not camId then return end
    ox:query(
        'INSERT INTO mnc_freecam_custom_cams (citizenid, cam_id, label) VALUES (?,?,?) ON DUPLICATE KEY UPDATE label=VALUES(label)',
        { cid, camId, label },
        function() end
    )
end)

RegisterNetEvent('mnc-freecam:deleteCustomCam', function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    local camId = tonumber(data.cam_id)
    if not camId then return end
    ox:query('DELETE FROM mnc_freecam_custom_cams WHERE citizenid = ? AND cam_id = ?', { cid, camId }, function() end)
end)

-- ─────────────────────────────────────────────
-- Freecam presets — per citizenid
-- ─────────────────────────────────────────────

RegisterNetEvent('mnc-freecam:loadPresets', function()
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    ox:query('SELECT slot, name, data FROM mnc_freecam_presets WHERE citizenid = ? ORDER BY slot ASC',
        { cid },
        function(rows)
            TriggerClientEvent('mnc-freecam:receivePresets', src, rows or {})
        end
    )
end)

RegisterNetEvent('mnc-freecam:savePreset', function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    local slot = tonumber(data.slot)
    if not slot or slot < 1 or slot > 20 then return end
    local name    = tostring(data.name or 'Preset'):sub(1, 60)
    local payload = tostring(data.data or '{}')
    ox:query(
        'INSERT INTO mnc_freecam_presets (citizenid, slot, name, data) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE name=VALUES(name), data=VALUES(data)',
        { cid, slot, name, payload },
        function()
            TriggerClientEvent('mnc-freecam:presetSaved', src, { slot = slot })
        end
    )
end)

RegisterNetEvent('mnc-freecam:deletePreset', function(data)
    local src = source
    local cid = getCitizenId(src)
    if not cid then return end
    local slot = tonumber(data.slot)
    if not slot then return end
    ox:query('DELETE FROM mnc_freecam_presets WHERE citizenid = ? AND slot = ?', { cid, slot }, function()
        TriggerClientEvent('mnc-freecam:presetDeleted', src, { slot = slot })
    end)
end)