-- ============================================
-- Add Admin Role Columns to users table
-- Safe for cPanel - Checks before adding
-- ============================================
-- IMPORTANT: Uncomment and update the USE statement with your actual database name
-- USE `allindia_tax_services`;
-- ============================================

-- ============================================
-- Add Role column (if not exists - check first)
-- ============================================
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

-- ============================================
-- Add IsActive column (if not exists - check first)
-- ============================================
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

-- ============================================
-- Create indexes for faster queries
-- ============================================
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
-- Verification
-- ============================================
-- Uncomment to verify columns exist:
-- DESCRIBE users;

-- Uncomment to check indexes:
-- SHOW INDEXES FROM users;

-- ============================================
-- SETUP COMPLETE!
-- ============================================
-- If columns already exist, you'll see messages like:
-- "Role column already exists"
-- "IsActive column already exists"
--
-- This is normal and means your table already has these columns!
-- ============================================
