-- ============================================
-- Rollback Script for Package Management Changes
-- Purpose: Reverse all package management migrations
-- Date: 2026-01-17
-- WARNING: This will remove all package-related enhancements
-- ============================================

-- Backup data before rollback (optional)
-- CREATE TABLE personal_details_backup AS SELECT * FROM personal_details;
-- CREATE TABLE itr_packages_backup AS SELECT * FROM itr_packages;

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- 1. Remove package_id from personal_details
-- ============================================

-- Drop foreign key constraint
ALTER TABLE `personal_details` DROP FOREIGN KEY IF EXISTS `fk_personal_details_package`;

-- Drop index
ALTER TABLE `personal_details` DROP INDEX IF EXISTS `idx_package_id`;

-- Drop column
ALTER TABLE `personal_details` DROP COLUMN IF EXISTS `package_id`;

SELECT 'Removed package_id from personal_details table' AS status;

-- ============================================
-- 2. Remove new columns from itr_packages
-- ============================================

ALTER TABLE `itr_packages` DROP COLUMN IF EXISTS `turnover`;
ALTER TABLE `itr_packages` DROP COLUMN IF EXISTS `icon`;
ALTER TABLE `itr_packages` DROP COLUMN IF EXISTS `color`;

SELECT 'Removed turnover, icon, color from itr_packages table' AS status;

-- ============================================
-- 3. Optional: Remove newly added packages
-- ============================================
-- Uncomment the following lines if you want to remove the 7 packages
-- that were inserted by the migration

-- DELETE FROM `itr_packages` WHERE packagename IN (
--     'Small Business Plan',
--     'Growing Business Plan',
--     'Established Business Plan',
--     'Large Business Plan',
--     'NRI Income Plan',
--     'NRIs Business Plan',
--     'E-Verification Service'
-- );

-- SELECT 'Removed frontend packages from database' AS status;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- Verification
-- ============================================

SELECT 'Rollback completed successfully' AS status;

-- Verify personal_details structure
DESCRIBE `personal_details`;

-- Verify itr_packages structure
DESCRIBE `itr_packages`;

-- Count remaining packages
SELECT COUNT(*) as remaining_packages FROM `itr_packages`;
