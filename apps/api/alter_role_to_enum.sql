-- ============================================
-- Alter Role Column from VARCHAR to ENUM
-- ============================================
-- This script changes the Role column in users table
-- from VARCHAR(50) to ENUM('CLIENT', 'ADMIN', 'ACCOUNTANT', 'CA')
-- ============================================
-- IMPORTANT: Replace the database name below if different
-- USE `allindia_tax_services`;
-- ============================================

-- ============================================
-- Step 1: Update existing 'user' values to 'CLIENT' (if any)
-- ============================================
-- This ensures existing data is compatible with the new ENUM
UPDATE `users` SET `Role` = 'CLIENT' WHERE `Role` = 'user';

-- ============================================
-- Step 2: Update existing 'admin' values to 'ADMIN' (if any)
-- ============================================
UPDATE `users` SET `Role` = 'ADMIN' WHERE `Role` = 'admin';

-- ============================================
-- Step 3: Alter Role column to ENUM type
-- ============================================
ALTER TABLE `users` 
MODIFY COLUMN `Role` ENUM('CLIENT', 'ADMIN', 'ACCOUNTANT', 'CA') DEFAULT 'CLIENT' COMMENT 'User role: CLIENT, ADMIN, ACCOUNTANT, or CA' AFTER `Password`;

-- ============================================
-- Verification
-- ============================================
-- Uncomment to verify the column structure:
-- DESCRIBE users;
-- 
-- Or check the column definition:
-- SHOW COLUMNS FROM users WHERE Field = 'Role';

-- ============================================
-- SETUP COMPLETE!
-- ============================================
-- The Role column is now ENUM('CLIENT', 'ADMIN', 'ACCOUNTANT', 'CA')
-- Existing 'user' values have been migrated to 'CLIENT'
-- Existing 'admin' values have been migrated to 'ADMIN'
-- ============================================
