CREATE TABLE IF NOT EXISTS `mnc_invoices` (
    `id`              INT(11) NOT NULL AUTO_INCREMENT,
    `from_citizenid`  VARCHAR(50)  NOT NULL,
    `from_name`       VARCHAR(100) NOT NULL DEFAULT '',
    `from_job`        VARCHAR(50)  NOT NULL DEFAULT 'unemployed',
    `from_job_label`  VARCHAR(100) NOT NULL DEFAULT '',
    `to_citizenid`    VARCHAR(50)  NOT NULL,
    `to_name`         VARCHAR(100) NOT NULL DEFAULT '',
    `amount`          INT(11)      NOT NULL DEFAULT 0,
    `reason`          VARCHAR(255) NOT NULL DEFAULT '',
    `status`          ENUM('pending','paid','declined','expired') NOT NULL DEFAULT 'pending',
    `created_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `paid_at`         TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_from_cid`  (`from_citizenid`),
    KEY `idx_to_cid`    (`to_citizenid`),
    KEY `idx_from_job`  (`from_job`),
    KEY `idx_status`    (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
