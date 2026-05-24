-- ============================================
-- Migration: Add package_id to personal_details table
-- Purpose: Track which package user selected during personal details submission
-- Date: 2026-01-17
-- ============================================

-- Add package_id column to personal_details
ALTER TABLE `personal_details` 
ADD COLUMN `package_id` int(11) DEFAULT NULL COMMENT 'Selected ITR package reference' AFTER `FinancialYear`;

-- Add index for better performance
ALTER TABLE `personal_details` 
ADD KEY `idx_package_id` (`package_id`);

-- Add foreign key constraint
ALTER TABLE `personal_details` 
ADD CONSTRAINT `fk_personal_details_package` 
FOREIGN KEY (`package_id`) REFERENCES `itr_packages`(`id`) ON DELETE SET NULL;

-- Verify changes
SELECT 'personal_details table updated successfully' AS status;
DESCRIBE `personal_details`;
