-- ============================================
-- Associate marketplace schema
-- Tables: associate_profiles, associate_service_fees
-- Columns: personal_details.associate_id/service_id
--          payment_info.associate_id/service_id/quoted_fee
-- Seed: bookable services catalog
-- ============================================

CREATE TABLE IF NOT EXISTS `associate_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT 'FK to users.UserId',
  `bio` text DEFAULT NULL,
  `years_experience` int(11) DEFAULT 0,
  `qualification` varchar(255) DEFAULT NULL,
  `license_number` varchar(100) DEFAULT NULL COMMENT 'ICAI / license number',
  `city` varchar(100) DEFAULT NULL,
  `languages` varchar(255) DEFAULT NULL COMMENT 'CSV, e.g. English,Hindi',
  `photo_url` varchar(500) DEFAULT NULL,
  `verification_status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `is_listed` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Only 1 when approved and listed',
  `rejection_reason` varchar(500) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_associate_user` (`user_id`),
  KEY `idx_verification_status` (`verification_status`),
  KEY `idx_is_listed` (`is_listed`),
  KEY `idx_city` (`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `associate_service_fees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT 'FK to users.UserId',
  `service_id` int(11) NOT NULL COMMENT 'FK to services.id',
  `fee` decimal(10,2) NOT NULL DEFAULT 0.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_associate_service` (`user_id`, `service_id`),
  KEY `idx_service_id` (`service_id`),
  KEY `idx_user_active` (`user_id`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `services` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `isActive` tinyint(1) DEFAULT 1,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `services` (`id`, `name`, `description`, `isActive`) VALUES
  (1, 'ITR Filing', 'File your income tax return with a named associate', 1),
  (2, 'Tax Consultation', 'One-on-one tax advice and planning', 1),
  (3, 'Document Verification', 'Verify and review supporting documents', 1),
  (4, 'E-Verify', 'e-Verify a filed ITR with an associate', 1),
  (5, 'GST Filing', 'GST return filing and compliance', 1)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `description` = VALUES(`description`),
  `isActive` = VALUES(`isActive`);

-- personal_details: associate + service (package_id stays for old rows)
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'personal_details' AND COLUMN_NAME = 'associate_id'
);
SET @sql := IF(@col_exists = 0,
  'ALTER TABLE `personal_details` ADD COLUMN `associate_id` int(11) DEFAULT NULL COMMENT ''Selected associate user_id'' AFTER `package_id`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'personal_details' AND COLUMN_NAME = 'service_id'
);
SET @sql := IF(@col_exists = 0,
  'ALTER TABLE `personal_details` ADD COLUMN `service_id` int(11) DEFAULT NULL COMMENT ''Selected bookable service'' AFTER `associate_id`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'personal_details' AND INDEX_NAME = 'idx_associate_id'
);
SET @sql := IF(@idx_exists = 0,
  'ALTER TABLE `personal_details` ADD KEY `idx_associate_id` (`associate_id`)',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'personal_details' AND INDEX_NAME = 'idx_service_id'
);
SET @sql := IF(@idx_exists = 0,
  'ALTER TABLE `personal_details` ADD KEY `idx_pd_service_id` (`service_id`)',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- payment_info: snapshot associate fee so later edits do not change paid orders
SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'payment_info' AND COLUMN_NAME = 'associate_id'
);
SET @sql := IF(@col_exists = 0,
  'ALTER TABLE `payment_info` ADD COLUMN `associate_id` int(11) DEFAULT NULL AFTER `package_id`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'payment_info' AND COLUMN_NAME = 'service_id'
);
SET @sql := IF(@col_exists = 0,
  'ALTER TABLE `payment_info` ADD COLUMN `service_id` int(11) DEFAULT NULL AFTER `associate_id`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'payment_info' AND COLUMN_NAME = 'quoted_fee'
);
SET @sql := IF(@col_exists = 0,
  'ALTER TABLE `payment_info` ADD COLUMN `quoted_fee` decimal(10,2) DEFAULT NULL COMMENT ''Associate fee snapshot at initiate'' AFTER `service_id`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Backfill pending profiles for existing professional users
INSERT INTO `associate_profiles` (`user_id`, `verification_status`, `is_listed`)
SELECT `UserId`, 'pending', 0
FROM `users`
WHERE UPPER(TRIM(`Role`)) IN ('CA', 'ACCOUNTANT', 'TAX_EXPERT')
ON DUPLICATE KEY UPDATE `user_id` = `user_id`;
