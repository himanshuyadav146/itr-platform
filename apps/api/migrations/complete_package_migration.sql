-- ============================================
-- Complete Package Management Migration
-- Run this entire file in one go
-- Date: 2026-01-17
-- ============================================

-- Disable foreign key checks temporarily
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- STEP 1: Update itr_packages table
-- ============================================

-- Add turnover column (if not exists)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'itr_packages' 
                   AND COLUMN_NAME = 'turnover');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `itr_packages` ADD COLUMN `turnover` varchar(100) DEFAULT NULL COMMENT ''Turnover range (e.g., Up to 10 lakh)'' AFTER `description2`',
    'SELECT ''Column turnover already exists'' AS message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add icon column (if not exists)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'itr_packages' 
                   AND COLUMN_NAME = 'icon');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `itr_packages` ADD COLUMN `icon` varchar(100) DEFAULT NULL COMMENT ''Icon identifier for frontend'' AFTER `turnover`',
    'SELECT ''Column icon already exists'' AS message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add color column (if not exists)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'itr_packages' 
                   AND COLUMN_NAME = 'color');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `itr_packages` ADD COLUMN `color` varchar(50) DEFAULT NULL COMMENT ''Color code for frontend'' AFTER `icon`',
    'SELECT ''Column color already exists'' AS message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'Step 1: itr_packages table updated' AS Status;

-- ============================================
-- STEP 2: Update personal_details table
-- ============================================

-- Add package_id column (if not exists)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = DATABASE() 
                   AND TABLE_NAME = 'personal_details' 
                   AND COLUMN_NAME = 'package_id');

SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `personal_details` ADD COLUMN `package_id` int(11) DEFAULT NULL COMMENT ''Selected ITR package reference'' AFTER `FinancialYear`',
    'SELECT ''Column package_id already exists'' AS message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add index (if not exists)
SET @index_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
                     WHERE TABLE_SCHEMA = DATABASE() 
                     AND TABLE_NAME = 'personal_details' 
                     AND INDEX_NAME = 'idx_package_id');

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `personal_details` ADD KEY `idx_package_id` (`package_id`)',
    'SELECT ''Index idx_package_id already exists'' AS message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add foreign key constraint (if not exists)
SET @fk_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
                  WHERE TABLE_SCHEMA = DATABASE() 
                  AND TABLE_NAME = 'personal_details' 
                  AND CONSTRAINT_NAME = 'fk_personal_details_package');

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE `personal_details` ADD CONSTRAINT `fk_personal_details_package` FOREIGN KEY (`package_id`) REFERENCES `itr_packages`(`id`) ON DELETE SET NULL',
    'SELECT ''Foreign key fk_personal_details_package already exists'' AS message');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'Step 2: personal_details table updated' AS Status;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- STEP 3: Insert/Update Frontend Packages
-- ============================================

-- Clear existing packages (OPTIONAL - comment out if you want to keep old data)
-- DELETE FROM `itr_packages` WHERE id > 0;

-- Insert or update packages
INSERT INTO `itr_packages` 
(`packagename`, `price`, `description1`, `turnover`, `icon`, `color`, `isActive`, `createdAt`) 
VALUES 
(
    'Small Business Plan', 
    3499.00, 
    'Business/Profession (Entry level plan for small businesses or professionals.)', 
    'Up to 10 lakh', 
    'business_center_outlined', 
    'blue', 
    1, 
    NOW()
),
(
    'Growing Business Plan', 
    4999.00, 
    'Business/Profession (For growing businesses with moderate turnover.)', 
    '10-25 Lakh', 
    'trending_up', 
    'green', 
    1, 
    NOW()
),
(
    'Established Business Plan', 
    4999.00, 
    'Business/Profession (Comprehensive plan for established businesses with higher turnover.)', 
    '25-50 lakh', 
    'apartment', 
    'orange', 
    1, 
    NOW()
),
(
    'Large Business Plan', 
    4999.00, 
    'Business/Profession (Premium plan for large businesses with significant turnover.)', 
    'Above 50 Lakh', 
    'domain', 
    'purple', 
    1, 
    NOW()
),
(
    'NRI Income Plan', 
    4999.00, 
    'Overseas Income (For non-residents with foreign income sources.)', 
    '', 
    'flight_takeoff', 
    'teal', 
    1, 
    NOW()
),
(
    'NRIs Business Plan', 
    7999.00, 
    'NRI Business Plan (For NRIs with foreign income and business/professional earnings.)', 
    '', 
    'business', 
    'indigo', 
    1, 
    NOW()
),
(
    'E-Verification Service', 
    199.00, 
    'Tax Return Verification (Service for electronic verification of income tax returns.)', 
    '', 
    'verified_user', 
    'cyan', 
    1, 
    NOW()
)
ON DUPLICATE KEY UPDATE 
    `packagename` = VALUES(`packagename`),
    `price` = VALUES(`price`),
    `description1` = VALUES(`description1`),
    `turnover` = VALUES(`turnover`),
    `icon` = VALUES(`icon`),
    `color` = VALUES(`color`);

SELECT 'Step 3: Packages inserted/updated' AS Status;

-- ============================================
-- VERIFICATION
-- ============================================

-- Show itr_packages structure
SELECT '=== itr_packages Table Structure ===' AS '';
DESCRIBE `itr_packages`;

-- Show personal_details structure
SELECT '=== personal_details Table Structure ===' AS '';
DESCRIBE `personal_details`;

-- Show all packages
SELECT '=== All Packages ===' AS '';
SELECT id, packagename, price, turnover, icon, color, isActive FROM `itr_packages` ORDER BY id;

-- Count packages
SELECT '=== Package Count ===' AS '';
SELECT COUNT(*) as total_packages FROM `itr_packages` WHERE isActive = 1;

-- Final message
SELECT '✅ ALL MIGRATIONS COMPLETED SUCCESSFULLY!' AS Status;
