-- ============================================
-- ROLLBACK ALL DATABASE CHANGES
-- ============================================
-- This script removes all database changes made for role-based access control
-- Run this ONLY if you applied the migrations and want to revert them
-- ============================================

-- IMPORTANT: Backup your database before running this!
-- mysqldump -u root -p itr_services > backup_before_rollback.sql

-- ============================================
-- Step 1: Remove 'type' column from itr_detail (if it exists)
-- ============================================
SET @exist := (SELECT COUNT(*) 
               FROM information_schema.COLUMNS 
               WHERE TABLE_SCHEMA = DATABASE() 
               AND TABLE_NAME = 'itr_detail' 
               AND COLUMN_NAME = 'type');

SET @sqlstmt := IF(@exist > 0, 
                   'ALTER TABLE `itr_detail` DROP COLUMN `type`', 
                   'SELECT ''Column type does not exist in itr_detail'' AS message');

PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- Step 2: Drop itr_assignments table (if it exists)
-- ============================================
DROP TABLE IF EXISTS `itr_assignments`;

-- ============================================
-- Step 3: Remove Role column from users (OPTIONAL - only if you want to remove it)
-- ============================================
-- UNCOMMENT BELOW ONLY IF YOU WANT TO REMOVE THE ROLE COLUMN
-- WARNING: This will remove all role data!

-- SET @exist := (SELECT COUNT(*) 
--                FROM information_schema.COLUMNS 
--                WHERE TABLE_SCHEMA = DATABASE() 
--                AND TABLE_NAME = 'users' 
--                AND COLUMN_NAME = 'Role');
-- 
-- SET @sqlstmt := IF(@exist > 0, 
--                    'ALTER TABLE `users` DROP COLUMN `Role`', 
--                    'SELECT ''Column Role does not exist in users'' AS message');
-- 
-- PREPARE stmt FROM @sqlstmt;
-- EXECUTE stmt;
-- DEALLOCATE PREPARE stmt;

-- ============================================
-- Verification
-- ============================================
-- Check what was removed:
SELECT 'Checking if type column exists...' AS status;
SELECT COUNT(*) as type_column_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'itr_detail' 
AND COLUMN_NAME = 'type';

SELECT 'Checking if itr_assignments table exists...' AS status;
SELECT COUNT(*) as itr_assignments_exists
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'itr_assignments';

-- ============================================
-- ROLLBACK COMPLETE!
-- ============================================
-- What was removed:
-- ✓ type column from itr_detail table (if existed)
-- ✓ itr_assignments table (if existed)
-- ✓ Role column from users table (if you uncommented that section)
-- 
-- Your database is now back to the state before the changes
-- ============================================
