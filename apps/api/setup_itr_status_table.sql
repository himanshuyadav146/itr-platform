-- ============================================
-- ITR Order Status Tracking System
-- Database Setup
-- ============================================
-- Run this in phpMyAdmin SQL tab or MySQL command line
-- ============================================

USE `itr_services`;

-- ============================================
-- Table: itr_order_status
-- Track individual status steps for each ITR order
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_order_status` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` varchar(100) DEFAULT NULL COMMENT 'From payment_info table',
  `itr_id` int(11) DEFAULT NULL COMMENT 'FK to itr_detail table',
  `user_id` int(11) NOT NULL COMMENT 'FK to users table',
  `payment_id` varchar(50) DEFAULT NULL COMMENT 'From payment_info table',
  `pan_number` varchar(10) DEFAULT NULL,
  `status_step` varchar(50) NOT NULL COMMENT 'payment_success, expert_assigned, documents_verified, filing_itr, acknowledgement_generated',
  `is_completed` tinyint(1) DEFAULT 0,
  `completed_at` datetime DEFAULT NULL,
  `notes` text DEFAULT NULL COMMENT 'Additional info like expert name, acknowledgement number',
  `has_concern` tinyint(1) DEFAULT 0 COMMENT 'Flag to indicate if step has pending concern',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_itr_id` (`itr_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status_step` (`status_step`),
  KEY `idx_order_status` (`order_id`, `status_step`),
  KEY `idx_itr_status` (`itr_id`, `status_step`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE,
  FOREIGN KEY (`itr_id`) REFERENCES `itr_detail`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: itr_order_concerns
-- Track concerns/issues raised for each status step
-- Supports text and image uploads
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_order_concerns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `status_id` int(11) NOT NULL COMMENT 'FK to itr_order_status',
  `order_id` varchar(100) DEFAULT NULL COMMENT 'For quick lookup',
  `itr_id` int(11) DEFAULT NULL COMMENT 'For quick lookup',
  `user_id` int(11) NOT NULL COMMENT 'FK to users table',
  `concern_type` varchar(20) NOT NULL COMMENT 'text or image',
  `concern_text` text DEFAULT NULL COMMENT 'Text concern message',
  `concern_image_path` varchar(500) DEFAULT NULL COMMENT 'Path to uploaded image file',
  `status` varchar(20) DEFAULT 'pending' COMMENT 'pending, resolved, rejected',
  `resolved_at` datetime DEFAULT NULL,
  `resolved_by` int(11) DEFAULT NULL COMMENT 'Admin/user who resolved',
  `resolution_notes` text DEFAULT NULL COMMENT 'Admin response/notes',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_status_id` (`status_id`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_itr_id` (`itr_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  FOREIGN KEY (`status_id`) REFERENCES `itr_order_status`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Verification Queries
-- ============================================
-- SELECT * FROM itr_order_status;
-- SELECT * FROM itr_order_concerns;

