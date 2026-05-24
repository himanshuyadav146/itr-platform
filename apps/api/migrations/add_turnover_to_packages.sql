-- ============================================
-- Migration: Add turnover field to itr_packages table
-- Purpose: Support frontend package requirements with turnover ranges
-- Date: 2026-01-17
-- ============================================

-- Add turnover column to itr_packages
ALTER TABLE `itr_packages` 
ADD COLUMN `turnover` varchar(100) DEFAULT NULL COMMENT 'Turnover range (e.g., Up to 10 lakh, 10-25 Lakh)' AFTER `description2`;

-- Add icon and color columns for frontend display (optional but useful)
ALTER TABLE `itr_packages` 
ADD COLUMN `icon` varchar(100) DEFAULT NULL COMMENT 'Icon identifier for frontend' AFTER `turnover`,
ADD COLUMN `color` varchar(50) DEFAULT NULL COMMENT 'Color code for frontend' AFTER `icon`;

-- Verify changes
SELECT 'itr_packages table updated successfully' AS status;
DESCRIBE `itr_packages`;
