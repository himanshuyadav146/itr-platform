-- ============================================
-- Associate marketplace: profiles, service fees,
-- and snapshot columns for booking + payment.
-- Safe to re-run: duplicate column/key errors are skipped
-- by migrations/run_migrations.php
-- ============================================

-- Profiles for CA / Accountant / Tax Expert associates.
-- Clients only see associates with approval_status = 'approved'.
CREATE TABLE IF NOT EXISTS `associate_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT 'FK to users.UserId',
  `role` varchar(30) NOT NULL DEFAULT 'CA' COMMENT 'CA, ACCOUNTANT, TAX_EXPERT',
  `icai_membership_no` varchar(50) DEFAULT NULL,
  `gstin` varchar(20) DEFAULT NULL,
  `pan` varchar(10) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `bio` text DEFAULT NULL,
  `years_experience` int(11) DEFAULT 0,
  `approval_status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT 'pending, approved, rejected, unlisted',
  `rejection_reason` text DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_associate_user` (`user_id`),
  KEY `idx_approval_status` (`approval_status`),
  KEY `idx_city` (`city`),
  KEY `idx_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Per-associate listed fee for a platform service (not package price).
CREATE TABLE IF NOT EXISTS `associate_service_fees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `associate_id` int(11) NOT NULL COMMENT 'users.UserId of the associate',
  `service_id` int(11) NOT NULL COMMENT 'FK to services.id',
  `listed_fee` decimal(15,2) NOT NULL DEFAULT 0.00,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_associate_service` (`associate_id`, `service_id`),
  KEY `idx_service_id` (`service_id`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Optional catalog fields on services (Name + CreatedAt already exist)
ALTER TABLE `services`
  ADD COLUMN `description` text DEFAULT NULL AFTER `Name`;

ALTER TABLE `services`
  ADD COLUMN `is_active` tinyint(1) DEFAULT 1 AFTER `description`;

ALTER TABLE `services`
  ADD COLUMN `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `CreatedAt`;

-- Client booking: which associate + service the filing is for
ALTER TABLE `personal_details`
  ADD COLUMN `associate_id` int(11) DEFAULT NULL COMMENT 'Selected associate users.UserId' AFTER `package_id`;

ALTER TABLE `personal_details`
  ADD COLUMN `service_id` int(11) DEFAULT NULL COMMENT 'Selected platform service' AFTER `associate_id`;

ALTER TABLE `personal_details`
  ADD KEY `idx_associate_id` (`associate_id`);

ALTER TABLE `personal_details`
  ADD KEY `idx_service_id` (`service_id`);

-- Payment snapshot of the associate listed fee at initiate time
ALTER TABLE `payment_info`
  ADD COLUMN `associate_id` int(11) DEFAULT NULL COMMENT 'Associate paid for this order' AFTER `package_id`;

ALTER TABLE `payment_info`
  ADD COLUMN `service_id` int(11) DEFAULT NULL AFTER `associate_id`;

ALTER TABLE `payment_info`
  ADD COLUMN `quoted_fee` decimal(15,2) DEFAULT NULL COMMENT 'Associate listed_fee snapshot (ex-GST)' AFTER `service_id`;

ALTER TABLE `payment_info`
  ADD KEY `idx_associate_id` (`associate_id`);

-- Seed catalog if empty (keep India ITR labels, not US tax forms)
INSERT INTO `services` (`Name`, `description`, `is_active`)
SELECT 'ITR Filing', 'Income Tax Return filing with a named associate', 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `services` WHERE `Name` = 'ITR Filing');

INSERT INTO `services` (`Name`, `description`, `is_active`)
SELECT 'Tax Consultation', 'One-to-one tax consultation with a CA or tax expert', 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `services` WHERE `Name` = 'Tax Consultation');

INSERT INTO `services` (`Name`, `description`, `is_active`)
SELECT 'Notice Handling', 'Help responding to income-tax notices', 1
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `services` WHERE `Name` = 'Notice Handling');
