CREATE TABLE IF NOT EXISTS `mnc_handling_overrides_plate` (
  `plate`         VARCHAR(12)  NOT NULL,
  `model`         VARCHAR(64)  DEFAULT NULL,
  `data`          LONGTEXT     NOT NULL,
  `original_data` LONGTEXT     NOT NULL DEFAULT '',
  `updated_by`    VARCHAR(100) DEFAULT NULL,
  `updated_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
