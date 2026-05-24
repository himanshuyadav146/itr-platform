-- ============================================
-- ITR Assignment Tables Setup Script
-- ============================================
-- This script creates the table required for ITR assignment to associates
-- 
-- Note: Uses existing users table with Role filtering
-- Associates/Professionals are users with Role='ACCOUNTANT' or Role='CA'
-- 
-- Table Created:
-- 1. itr_assignments - Stores ITR assignments to professionals (users with ACCOUNTANT/CA role)
-- ============================================
-- 
-- INSTRUCTIONS:
-- 1. Open phpMyAdmin: http://localhost/phpmyadmin
-- 2. Select your database (e.g., itr_services, allindia_services)
-- 3. Click "SQL" tab
-- 4. Copy and paste this entire file
-- 5. Click "Go"
-- ============================================
-- 
-- PREREQUISITES:
-- - users table must exist
-- - users table should have Role column (can be VARCHAR or ENUM)
-- - Associates/Professionals should have Role='ACCOUNTANT' or Role='CA'
-- ============================================

-- ============================================
-- Table: itr_assignments
-- Stores assignment of professionals to ITR orders
-- professional_id references users.UserId (users with Role='ACCOUNTANT' or 'CA')
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_assignments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `itr_id` int(11) NOT NULL COMMENT 'FK to itr_detail table',
  `order_id` varchar(100) DEFAULT NULL COMMENT 'Order reference',
  `user_id` int(11) NOT NULL COMMENT 'FK to users table (client who owns the ITR)',
  `professional_id` int(11) NOT NULL COMMENT 'FK to users table (associate with Role=ACCOUNTANT or CA)',
  `assigned_by` int(11) DEFAULT NULL COMMENT 'Admin user who assigned (FK to users.UserId)',
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
  FOREIGN KEY (`professional_id`) REFERENCES `users`(`UserId`) ON DELETE RESTRICT,
  FOREIGN KEY (`assigned_by`) REFERENCES `users`(`UserId`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Setup Complete!
-- ============================================
-- Table created:
-- ✓ itr_assignments
-- 
-- Note: Associates/Professionals are users with Role='ACCOUNTANT' or Role='CA'
-- Use the existing /admin/users.php API with role filter to get associates
-- ============================================
