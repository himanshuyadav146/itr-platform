-- ============================================
-- Admin Panel Database Setup
-- Adds admin role support and any admin-specific tables
-- ============================================
-- Run this after running the main database_setup.sql
-- ============================================

USE `itr_services`;

-- ============================================
-- Add Role column to users table (if not exists)
-- ============================================
ALTER TABLE `users` 
ADD COLUMN IF NOT EXISTS `Role` varchar(50) DEFAULT 'user' COMMENT 'user, admin' AFTER `Password`,
ADD COLUMN IF NOT EXISTS `IsActive` tinyint(1) DEFAULT 1 COMMENT 'Active status' AFTER `Role`;

-- Create index on Role for faster queries
CREATE INDEX IF NOT EXISTS `idx_role` ON `users` (`Role`);
CREATE INDEX IF NOT EXISTS `idx_is_active` ON `users` (`IsActive`);

-- ============================================
-- Optional: Create Admin User
-- ============================================
-- Uncomment and update to create an admin user
-- INSERT INTO `users` 
--     (`FirstName`, `LastName`, `Email`, `Mobile`, `Password`, `Role`, `Platform`, `Version`, `IsActive`) 
-- VALUES 
--     ('Admin', 'User', 'admin@example.com', '9876543210', 'admin123', 'admin', 'web', '1.0', 1)
-- ON DUPLICATE KEY UPDATE `Email` = `Email`;

-- ============================================
-- Optional: Update existing test user to admin (for testing)
-- ============================================
-- UPDATE `users` SET `Role` = 'admin' WHERE `Email` = 'test@example.com';

-- ============================================
-- Verification Queries
-- ============================================
-- SELECT * FROM users WHERE Role = 'admin';
-- SELECT COUNT(*) as admin_count FROM users WHERE Role = 'admin';
-- SELECT COUNT(*) as user_count FROM users WHERE Role = 'user';
