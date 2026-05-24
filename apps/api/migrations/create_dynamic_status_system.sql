-- ============================================
-- Dynamic ITR Status System - Complete Setup
-- ============================================
-- Purpose: Create fully dynamic status management system
-- Features:
--   - Database-driven status configurations
--   - Audit trail for all status changes
--   - Role-based access control
--   - Automatic and manual status updates
-- ============================================

USE `itr_services`;

-- ============================================
-- TABLE 1: Status Configuration (Dynamic Steps)
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_status_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `step_code` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `subtitle` varchar(500) DEFAULT NULL,
  `description` text DEFAULT NULL COMMENT 'Detailed description for professionals',
  `display_order` int(11) NOT NULL,
  `icon` varchar(50) DEFAULT NULL,
  `color` varchar(20) DEFAULT NULL,
  `is_automatic` tinyint(1) DEFAULT 0 COMMENT '1=auto by system, 0=manual by professionals',
  `requires_assignment` tinyint(1) DEFAULT 0 COMMENT 'Requires ITR assigned to professional',
  `requires_documents` tinyint(1) DEFAULT 0 COMMENT 'Requires documents uploaded',
  `can_be_reverted` tinyint(1) DEFAULT 1 COMMENT 'Can step be marked incomplete',
  `required_role` varchar(50) DEFAULT NULL COMMENT 'Required role: ADMIN, CA, ACCOUNTANT (comma-separated)',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `step_code` (`step_code`),
  KEY `idx_display_order` (`display_order`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLE 2: Status Audit Trail
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_status_audit` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `status_id` int(11) NOT NULL COMMENT 'FK to itr_order_status',
  `order_id` varchar(100) DEFAULT NULL,
  `itr_id` int(11) DEFAULT NULL,
  `status_step` varchar(50) NOT NULL,
  `action` varchar(20) NOT NULL COMMENT 'created, completed, reverted, updated',
  `previous_value` tinyint(1) DEFAULT NULL COMMENT 'Previous is_completed value',
  `new_value` tinyint(1) DEFAULT NULL COMMENT 'New is_completed value',
  `updated_by` int(11) NOT NULL COMMENT 'Professional/Admin who made change',
  `updated_by_role` varchar(50) DEFAULT NULL COMMENT 'Role at time of update',
  `notes` text DEFAULT NULL,
  `ip_address` varchar(50) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_status_id` (`status_id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_itr_id` (`itr_id`),
  KEY `idx_updated_by` (`updated_by`),
  KEY `idx_created_at` (`created_at`),
  FOREIGN KEY (`status_id`) REFERENCES `itr_order_status`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`updated_by`) REFERENCES `users`(`UserId`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- INSERT DEFAULT STATUS CONFIGURATIONS
-- ============================================
INSERT INTO `itr_status_config` 
  (`step_code`, `title`, `subtitle`, `description`, `display_order`, `icon`, `color`, `is_automatic`, `requires_assignment`, `requires_documents`, `can_be_reverted`, `required_role`) 
VALUES
  -- Step 1: Automatic (Payment webhook)
  ('payment_success', 'Payment Success', 'Payment confirmed and verified', 
   'Automatically marked when payment webhook confirms successful payment', 
   1, 'payment', '#28a745', 1, 0, 0, 0, NULL),
  
  -- Step 2: Automatic (Assignment)
  ('expert_assigned', 'Tax Expert Assigned', 'Expert reviewing your case', 
   'Automatically marked when admin assigns professional to this ITR', 
   2, 'person', '#17a2b8', 1, 0, 0, 0, NULL),
  
  -- Step 3: Manual (Professional marks)
  ('documents_verified', 'Documents Verification', 'Verifying uploaded documents', 
   'Professional verifies all uploaded documents are correct and complete. Requires documents to be uploaded first.', 
   3, 'verified', '#ffc107', 0, 1, 1, 1, NULL),
  
  -- Step 4: Manual (Professional marks - restricted to CA/Accountant)
  ('filing_itr', 'Filing ITR', 'Filing process in progress', 
   'Professional files ITR with Income Tax Department portal. Only CA and Accountants can perform this action.', 
   4, 'upload_file', '#fd7e14', 0, 1, 1, 1, 'CA,ACCOUNTANT'),
  
  -- Step 5: Manual (CA/Admin only - final step)
('acknowledgement_generated', 'Acknowledgement Generated', 'ITR Acknowledgement received',
   'ITR acknowledgement number received from Income Tax portal. CA, Admin and Accountant can mark this step. Cannot be reverted.',
   5, 'check_circle', '#6f42c1', 0, 1, 0, 0, 'CA,ADMIN,ACCOUNTANT')
ON DUPLICATE KEY UPDATE 
  title = VALUES(title),
  subtitle = VALUES(subtitle),
  description = VALUES(description);

-- ============================================
-- ADD is_active COLUMN to itr_assignments (if not exists)
-- ============================================
SET @dbname = DATABASE();
SET @tablename = 'itr_assignments';
SET @columnname = 'is_active';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN ', @columnname, ' tinyint(1) DEFAULT 1 AFTER status')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Add index for is_active if not exists
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (index_name = 'idx_is_active')
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tablename, ' ADD KEY idx_is_active (is_active)')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
SELECT '=== Status Configuration Created ===' AS '';
SELECT step_code, title, is_automatic, requires_assignment, required_role, is_active 
FROM itr_status_config 
ORDER BY display_order;

SELECT '' AS '';
SELECT '=== Audit Trail Table ===' AS '';
SELECT 
  TABLE_NAME as 'Table',
  TABLE_ROWS as 'Rows'
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'itr_status_audit';

SELECT '' AS '';
SELECT 'Setup Complete! ✓' AS Status;
SELECT 'Total Status Steps Configured:' as Info, COUNT(*) as Count FROM itr_status_config WHERE is_active = 1;
