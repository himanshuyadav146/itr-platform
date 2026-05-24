-- ============================================
-- Admin Panel Complete Database Setup for cPanel
-- ============================================
-- This file contains ALL tables needed for Admin Panel APIs
-- Can be run directly in phpMyAdmin after creating database in cPanel
-- ============================================
-- 
-- IMPORTANT INSTRUCTIONS:
-- 1. Create database in cPanel → MySQL Databases
-- 2. Create database user in cPanel → MySQL Databases
-- 3. Add user to database with ALL PRIVILEGES
-- 4. Replace 'your_cpanel_username_itr_services' below with your actual database name
-- 5. Run this entire file in phpMyAdmin SQL tab
-- ============================================
-- 
-- Example: If your cPanel username is 'john', database will be 'john_itr_services'
-- So replace 'your_cpanel_username_itr_services' with 'john_itr_services'
-- ============================================

-- IMPORTANT: Uncomment and update the USE statement with your actual database name
-- USE `your_cpanel_username_itr_services`;

-- ============================================
-- PART 1: Core Tables
-- ============================================

-- ============================================
-- Table: users
-- ============================================
CREATE TABLE IF NOT EXISTS `users` (
  `UserId` int(11) NOT NULL AUTO_INCREMENT,
  `FirstName` varchar(100) DEFAULT NULL,
  `MiddleName` varchar(100) DEFAULT NULL,
  `LastName` varchar(100) DEFAULT NULL,
  `Email` varchar(255) NOT NULL,
  `Mobile` varchar(20) DEFAULT NULL,
  `Password` varchar(255) NOT NULL,
  `Platform` varchar(50) DEFAULT 'web',
  `Version` varchar(20) DEFAULT '1.0',
  `CreatedAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `UpdatedAt` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`UserId`),
  UNIQUE KEY `Email` (`Email`),
  KEY `idx_email` (`Email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: services
-- ============================================
CREATE TABLE IF NOT EXISTS `services` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) NOT NULL,
  `CreatedAt` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Name` (`Name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: personal_details
-- ============================================
CREATE TABLE IF NOT EXISTS `personal_details` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `PANNumber` varchar(10) NOT NULL,
  `FirstName` varchar(100) NOT NULL,
  `MiddleName` varchar(100) DEFAULT NULL,
  `LastName` varchar(100) NOT NULL,
  `EMAIL` varchar(255) NOT NULL,
  `MobileNumber` varchar(20) DEFAULT NULL,
  `aadharCardNumber` varchar(20) DEFAULT NULL,
  `Gender` varchar(10) DEFAULT NULL,
  `DATEOFBIRTH` date DEFAULT NULL,
  `FinancialYear` varchar(20) DEFAULT NULL,
  `Address` text DEFAULT NULL,
  `Country` varchar(100) DEFAULT 'India',
  `isActive` tinyint(1) DEFAULT 1,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `createdBy` int(11) DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `updatedBy` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_userid` (`UserId`),
  KEY `idx_pan` (`PANNumber`),
  KEY `idx_userid_pan` (`UserId`, `PANNumber`),
  FOREIGN KEY (`UserId`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: document_details
-- ============================================
CREATE TABLE IF NOT EXISTS `document_details` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `PanNumber` varchar(10) NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` varchar(50) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `fileName` varchar(255) NOT NULL,
  `isActive` tinyint(1) DEFAULT 1,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `createdBy` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_userid` (`UserId`),
  KEY `idx_pan` (`PanNumber`),
  KEY `idx_userid_pan` (`UserId`, `PanNumber`),
  FOREIGN KEY (`UserId`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: itr_detail
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_detail` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userId` int(11) NOT NULL,
  `panNumber` varchar(10) DEFAULT NULL,
  `financialYear` varchar(20) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_userid` (`userId`),
  KEY `idx_pan` (`panNumber`),
  FOREIGN KEY (`userId`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: itr_source
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_source` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `itrId` int(11) NOT NULL,
  `sourceType` varchar(100) DEFAULT NULL,
  `sourceName` varchar(255) DEFAULT NULL,
  `amount` decimal(15,2) DEFAULT NULL,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_itrid` (`itrId`),
  FOREIGN KEY (`itrId`) REFERENCES `itr_detail`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: itr_packages
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_packages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `packagename` varchar(255) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `title1` varchar(255) DEFAULT NULL,
  `description1` text DEFAULT NULL,
  `title2` varchar(255) DEFAULT NULL,
  `description2` text DEFAULT NULL,
  `isActive` tinyint(1) DEFAULT 1,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- PART 2: Payment Tables
-- ============================================

-- ============================================
-- Table: payment_info
-- ============================================
CREATE TABLE IF NOT EXISTS `payment_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `payment_id` varchar(50) NOT NULL COMMENT 'Alphanumeric payment ID',
  `user_id` int(11) NOT NULL COMMENT 'FK to users table',
  `package_id` int(11) DEFAULT NULL COMMENT 'FK to itr_packages table',
  `pan_number` varchar(10) DEFAULT NULL COMMENT 'Reference to PAN, fetch details from personal_details',
  `order_id` varchar(100) DEFAULT NULL COMMENT 'Gateway order ID',
  `transaction_id` varchar(100) DEFAULT NULL COMMENT 'Gateway transaction ID',
  `subtotal` decimal(15,2) NOT NULL COMMENT 'Total before GST (calculated from package + additional fees)',
  `gst_percentage` decimal(5,2) DEFAULT 18.00 COMMENT 'GST percentage',
  `gst_amount` decimal(15,2) NOT NULL COMMENT 'GST amount',
  `grand_total` decimal(15,2) NOT NULL COMMENT 'Final amount to pay',
  `currency` varchar(10) DEFAULT 'INR',
  `payment_status` varchar(50) DEFAULT 'pending' COMMENT 'pending, success, failed, cancelled, refunded',
  `payment_method` varchar(50) DEFAULT NULL COMMENT 'card, netbanking, upi, wallet, etc',
  `gateway_name` varchar(50) DEFAULT NULL COMMENT 'paytm, razorpay, etc',
  `merchant_id` varchar(100) DEFAULT NULL,
  `gateway_response` text DEFAULT NULL COMMENT 'Full gateway response JSON',
  `webhook_data` text DEFAULT NULL COMMENT 'Webhook callback data',
  `failure_reason` text DEFAULT NULL COMMENT 'Reason for failure if any',
  `callback_url` varchar(500) DEFAULT NULL,
  `redirect_url` varchar(500) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `paid_at` datetime DEFAULT NULL COMMENT 'Payment completion time',
  PRIMARY KEY (`id`),
  UNIQUE KEY `payment_id` (`payment_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_package_id` (`package_id`),
  KEY `idx_pan_number` (`pan_number`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_transaction_id` (`transaction_id`),
  KEY `idx_payment_status` (`payment_status`),
  KEY `idx_created_at` (`created_at`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE,
  FOREIGN KEY (`package_id`) REFERENCES `itr_packages`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: payment_additional_fees
-- ============================================
CREATE TABLE IF NOT EXISTS `payment_additional_fees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fee_name` varchar(255) NOT NULL COMMENT 'E-Filing Fee, E-Verification Fee, etc',
  `fee_amount` decimal(15,2) NOT NULL,
  `display_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_display_order` (`display_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- PART 3: ITR Status & Concerns Tables
-- ============================================

-- ============================================
-- Table: itr_order_status
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_order_status` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` varchar(100) DEFAULT NULL COMMENT 'From payment_info table',
  `itr_id` int(11) DEFAULT NULL COMMENT 'FK to itr_detail table',
  `user_id` int(11) NOT NULL COMMENT 'FK to users table',
  `payment_id` varchar(50) DEFAULT NULL COMMENT 'From payment_info table',
  `pan_number` varchar(10) DEFAULT NULL,
  `status_step` varchar(50) NOT NULL COMMENT 'payment_success, expert_assigned, documents_verified, filing_itr, acknowledgement_generated',
  `is_completed` tinyint(1) DEFAULT 0,
  `completed_at` datetime DEFAULT NULL,
  `notes` text DEFAULT NULL COMMENT 'Additional info like expert name, acknowledgement number',
  `has_concern` tinyint(1) DEFAULT 0 COMMENT 'Flag to indicate if step has pending concern',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_itr_id` (`itr_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status_step` (`status_step`),
  KEY `idx_order_status` (`order_id`, `status_step`),
  KEY `idx_itr_status` (`itr_id`, `status_step`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE,
  FOREIGN KEY (`itr_id`) REFERENCES `itr_detail`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: itr_order_concerns
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_order_concerns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `status_id` int(11) DEFAULT NULL COMMENT 'FK to itr_order_status (nullable for backwards compatibility)',
  `order_id` varchar(100) DEFAULT NULL COMMENT 'For quick lookup',
  `itr_id` int(11) DEFAULT NULL COMMENT 'For quick lookup',
  `user_id` int(11) NOT NULL COMMENT 'FK to users table',
  `concern_type` varchar(100) DEFAULT NULL COMMENT 'text, image, or other types',
  `description` text DEFAULT NULL COMMENT 'Text concern message (kept for compatibility)',
  `concern_text` text DEFAULT NULL COMMENT 'Text concern message',
  `concern_image_path` varchar(500) DEFAULT NULL COMMENT 'Path to uploaded image file',
  `status` varchar(20) DEFAULT 'pending' COMMENT 'pending, resolved, rejected',
  `resolved_at` datetime DEFAULT NULL,
  `resolved_by` int(11) DEFAULT NULL COMMENT 'Admin/user who resolved',
  `resolution` text DEFAULT NULL COMMENT 'Admin response/notes (kept for compatibility)',
  `resolution_notes` text DEFAULT NULL COMMENT 'Admin response/notes',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_status_id` (`status_id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_itr_id` (`itr_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  FOREIGN KEY (`status_id`) REFERENCES `itr_order_status`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- PART 4: Admin Panel Support
-- ============================================

-- ============================================
-- Add Admin Role Columns to users table
-- ============================================
-- Note: If columns already exist, you will get an error - that's safe to ignore
-- OR use the conditional approach below (Method 2) if you prefer

-- METHOD 1: Simple approach (recommended)
-- If you get "Duplicate column name" error, columns already exist - that's OK!
-- Just verify with: DESCRIBE users;

-- Add Role column (if not exists - check first)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'users' 
    AND COLUMN_NAME = 'Role');

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE `users` ADD COLUMN `Role` varchar(50) DEFAULT ''user'' COMMENT ''user, admin'' AFTER `Password`',
    'SELECT ''Role column already exists'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add IsActive column (if not exists - check first)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'users' 
    AND COLUMN_NAME = 'IsActive');

SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE `users` ADD COLUMN `IsActive` tinyint(1) DEFAULT 1 COMMENT ''Active status'' AFTER `Role`',
    'SELECT ''IsActive column already exists'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Create indexes for faster queries
-- Note: MySQL < 5.7 doesn't support IF NOT EXISTS in CREATE INDEX
-- So we check if index exists first before creating

-- Create idx_role index (if not exists - check first)
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'users' 
    AND INDEX_NAME = 'idx_role');

SET @sql = IF(@idx_exists = 0, 
    'CREATE INDEX `idx_role` ON `users` (`Role`)',
    'SELECT ''idx_role index already exists'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Create idx_is_active index (if not exists - check first)
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'users' 
    AND INDEX_NAME = 'idx_is_active');

SET @sql = IF(@idx_exists = 0, 
    'CREATE INDEX `idx_is_active` ON `users` (`IsActive`)',
    'SELECT ''idx_is_active index already exists'' AS message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- PART 5: Sample Data (Optional)
-- ============================================

-- Sample Services
INSERT INTO `services` (`Name`) VALUES 
('ITR Filing'),
('Tax Consultation'),
('Document Verification')
ON DUPLICATE KEY UPDATE `Name` = `Name`;

-- Sample ITR Packages
INSERT INTO `itr_packages` (`packagename`, `price`, `title1`, `description1`, `title2`, `description2`, `isActive`) VALUES
('Basic', 499.00, 'Basic ITR Filing', 'For individuals with salary income only', 'Quick Processing', 'Get your ITR filed within 24 hours', 1),
('Standard', 999.00, 'Standard ITR Filing', 'For individuals with multiple income sources', 'Expert Support', 'Dedicated tax expert support', 1),
('Premium', 1999.00, 'Premium ITR Filing', 'For complex tax situations', 'Priority Processing', 'Priority processing with audit support', 1)
ON DUPLICATE KEY UPDATE `packagename` = `packagename`;

-- Sample Additional Fees
INSERT INTO `payment_additional_fees` (`fee_name`, `fee_amount`, `display_order`, `is_active`) VALUES
('E-Filing Fee', 7999.00, 1, 1),
('E-Verification Fee', 199.00, 2, 1)
ON DUPLICATE KEY UPDATE `fee_name` = `fee_name`;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Uncomment these queries to verify the setup after running this script

-- Show all tables
-- SHOW TABLES;

-- Check users table structure (should show Role and IsActive)
-- DESCRIBE users;

-- Count records in each table
-- SELECT 'users' as table_name, COUNT(*) as count FROM users
-- UNION ALL
-- SELECT 'services', COUNT(*) FROM services
-- UNION ALL
-- SELECT 'personal_details', COUNT(*) FROM personal_details
-- UNION ALL
-- SELECT 'document_details', COUNT(*) FROM document_details
-- UNION ALL
-- SELECT 'itr_detail', COUNT(*) FROM itr_detail
-- UNION ALL
-- SELECT 'itr_source', COUNT(*) FROM itr_source
-- UNION ALL
-- SELECT 'itr_packages', COUNT(*) FROM itr_packages
-- UNION ALL
-- SELECT 'payment_info', COUNT(*) FROM payment_info
-- UNION ALL
-- SELECT 'payment_additional_fees', COUNT(*) FROM payment_additional_fees
-- UNION ALL
-- SELECT 'itr_order_status', COUNT(*) FROM itr_order_status
-- UNION ALL
-- SELECT 'itr_order_concerns', COUNT(*) FROM itr_order_concerns;

-- Verify admin columns exist
-- SELECT COLUMN_NAME, DATA_TYPE, COLUMN_DEFAULT, COLUMN_COMMENT 
-- FROM INFORMATION_SCHEMA.COLUMNS 
-- WHERE TABLE_SCHEMA = DATABASE() 
--   AND TABLE_NAME = 'users' 
--   AND COLUMN_NAME IN ('Role', 'IsActive');

-- ============================================
-- CREATE ADMIN USER (Optional)
-- ============================================
-- IMPORTANT: Password should be hashed using password_hash() in PHP
-- 
-- Option 1: Create user via signup API first, then run:
-- UPDATE users SET Role = 'admin' WHERE Email = 'admin@example.com';
--
-- Option 2: Hash password in PHP and insert directly:
-- <?php echo password_hash('your_password', PASSWORD_DEFAULT); ?>
-- Then uncomment and update the INSERT below:

-- INSERT INTO `users` 
--     (`FirstName`, `LastName`, `Email`, `Mobile`, `Password`, `Role`, `Platform`, `Version`, `IsActive`) 
-- VALUES 
--     ('Admin', 'User', 'admin@example.com', '9876543210', '$2y$10$hashed_password_here', 'admin', 'web', '1.0', 1)
-- ON DUPLICATE KEY UPDATE `Email` = `Email`;

-- ============================================
-- SETUP COMPLETE!
-- ============================================
-- 
-- Next Steps:
-- 1. Verify all tables were created: SHOW TABLES;
-- 2. Check users table has Role and IsActive columns: DESCRIBE users;
-- 3. Create an admin user (see above)
-- 4. Configure include/config.php with database credentials
-- 5. Test admin panel APIs
-- 
-- For detailed deployment instructions, see: ADMIN_PANEL_DEPLOYMENT.md
-- ============================================
