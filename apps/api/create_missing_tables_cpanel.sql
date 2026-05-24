-- ============================================
-- Missing Tables Creation Script for cPanel
-- ============================================
-- This script creates the missing tables found in itr_services database
-- but not in allindia_tax_services database
-- ============================================
-- 
-- Missing Tables:
-- 1. itr_acknowledgement
-- 2. itr_assignments
-- 3. itr_comments
-- 4. professionals
-- ============================================
--
-- IMPORTANT: Uncomment and update the USE statement with your actual database name
-- USE `allindia_tax_services`;
-- ============================================

-- ============================================
-- Table: professionals
-- Stores professional/expert information who handle ITR filing
-- ============================================
CREATE TABLE IF NOT EXISTS `professionals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `FirstName` varchar(100) NOT NULL,
  `LastName` varchar(100) NOT NULL,
  `Email` varchar(255) NOT NULL,
  `Mobile` varchar(20) DEFAULT NULL,
  `Qualification` varchar(255) DEFAULT NULL,
  `Experience` int(11) DEFAULT 0 COMMENT 'Years of experience',
  `Specialization` varchar(255) DEFAULT NULL,
  `LicenseNumber` varchar(100) DEFAULT NULL,
  `IsActive` tinyint(1) DEFAULT 1,
  `CreatedAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `UpdatedAt` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Email` (`Email`),
  KEY `idx_email` (`Email`),
  KEY `idx_is_active` (`IsActive`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: itr_acknowledgement
-- Stores ITR acknowledgement numbers and details
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_acknowledgement` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `itr_id` int(11) NOT NULL COMMENT 'FK to itr_detail table',
  `order_id` varchar(100) DEFAULT NULL COMMENT 'Order reference',
  `user_id` int(11) NOT NULL COMMENT 'FK to users table',
  `acknowledgement_number` varchar(100) NOT NULL COMMENT 'ITR acknowledgement number',
  `acknowledgement_date` date DEFAULT NULL,
  `assessment_year` varchar(20) DEFAULT NULL,
  `filing_date` datetime DEFAULT NULL,
  `itr_form` varchar(50) DEFAULT NULL COMMENT 'ITR form type (ITR-1, ITR-2, etc.)',
  `status` varchar(50) DEFAULT 'generated' COMMENT 'generated, verified, filed, processed',
  `pdf_path` varchar(500) DEFAULT NULL COMMENT 'Path to acknowledgement PDF',
  `remarks` text DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `acknowledgement_number` (`acknowledgement_number`),
  KEY `idx_itr_id` (`itr_id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_acknowledgement_date` (`acknowledgement_date`),
  KEY `idx_status` (`status`),
  FOREIGN KEY (`itr_id`) REFERENCES `itr_detail`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: itr_assignments
-- Stores assignment of professionals to ITR orders
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `itr_id` int(11) NOT NULL COMMENT 'FK to itr_detail table',
  `order_id` varchar(100) DEFAULT NULL COMMENT 'Order reference',
  `user_id` int(11) NOT NULL COMMENT 'FK to users table',
  `professional_id` int(11) NOT NULL COMMENT 'FK to professionals table',
  `assigned_by` int(11) DEFAULT NULL COMMENT 'Admin user who assigned',
  `assignment_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `status` varchar(50) DEFAULT 'assigned' COMMENT 'assigned, in_progress, completed, rejected',
  `priority` varchar(20) DEFAULT 'normal' COMMENT 'low, normal, high, urgent',
  `due_date` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_itr_id` (`itr_id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_professional_id` (`professional_id`),
  KEY `idx_status` (`status`),
  KEY `idx_assignment_date` (`assignment_date`),
  FOREIGN KEY (`itr_id`) REFERENCES `itr_detail`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE,
  FOREIGN KEY (`professional_id`) REFERENCES `professionals`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: itr_comments
-- Stores comments/notes related to ITR orders
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_comments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `itr_id` int(11) NOT NULL COMMENT 'FK to itr_detail table',
  `order_id` varchar(100) DEFAULT NULL COMMENT 'Order reference',
  `user_id` int(11) DEFAULT NULL COMMENT 'FK to users table (who created comment)',
  `professional_id` int(11) DEFAULT NULL COMMENT 'FK to professionals table',
  `comment_type` varchar(50) DEFAULT 'general' COMMENT 'general, issue, resolution, internal, note',
  `comment_text` text NOT NULL,
  `is_internal` tinyint(1) DEFAULT 0 COMMENT 'Internal comment (not visible to user)',
  `is_important` tinyint(1) DEFAULT 0 COMMENT 'Important/urgent comment flag',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_itr_id` (`itr_id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_professional_id` (`professional_id`),
  KEY `idx_comment_type` (`comment_type`),
  KEY `idx_created_at` (`created_at`),
  FOREIGN KEY (`itr_id`) REFERENCES `itr_detail`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE SET NULL,
  FOREIGN KEY (`professional_id`) REFERENCES `professionals`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Uncomment these to verify the tables were created successfully:

-- Show all tables
-- SHOW TABLES;

-- Check table structures
-- DESCRIBE professionals;
-- DESCRIBE itr_acknowledgement;
-- DESCRIBE itr_assignments;
-- DESCRIBE itr_comments;

-- Count tables (should show all 4 new tables)
-- SELECT TABLE_NAME 
-- FROM INFORMATION_SCHEMA.TABLES 
-- WHERE TABLE_SCHEMA = DATABASE() 
--   AND TABLE_NAME IN ('professionals', 'itr_acknowledgement', 'itr_assignments', 'itr_comments');

-- ============================================
-- SETUP COMPLETE!
-- ============================================
-- 
-- All 4 missing tables have been created:
-- ✓ professionals
-- ✓ itr_acknowledgement
-- ✓ itr_assignments
-- ✓ itr_comments
--
-- Your database now matches the itr_services structure!
-- ============================================
