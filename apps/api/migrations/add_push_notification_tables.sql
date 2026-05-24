-- ============================================
-- Migration: Push Notifications (Option A)
-- Purpose: FCM token storage and notification records for cron + admin
-- ============================================
-- For cPanel: replace itr_services with your database name or run without USE
-- ============================================

USE `itr_services`;

-- ============================================
-- Table: user_fcm_tokens
-- Stores FCM device tokens per user (supports multiple devices)
-- ============================================
CREATE TABLE IF NOT EXISTS `user_fcm_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT 'FK to users.UserId',
  `fcm_token` varchar(500) NOT NULL,
  `platform` varchar(20) DEFAULT NULL COMMENT 'android, ios, etc.',
  `is_active` tinyint(1) DEFAULT 1 COMMENT '1=use for sending, 0=invalidated',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_fcm` (`user_id`, `fcm_token`(255)),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_fcm_token` (`fcm_token`(255)),
  KEY `idx_is_active` (`is_active`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: notifications
-- Stores every notification (cron campaigns + admin-created)
-- ============================================
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `body` text DEFAULT NULL,
  `data_payload` json DEFAULT NULL COMMENT 'Optional key-value for app (screen, id, etc.)',
  `type` varchar(50) DEFAULT 'scheduled_campaign' COMMENT 'scheduled_campaign, admin_sent, order_update, etc.',
  `scheduled_at` datetime DEFAULT NULL COMMENT 'When to send (cron uses this)',
  `sent_at` datetime DEFAULT NULL COMMENT 'When actually sent',
  `target` varchar(50) DEFAULT 'all_users' COMMENT 'all_users, single_user',
  `target_user_id` int(11) DEFAULT NULL COMMENT 'If target=single_user',
  `created_by` int(11) DEFAULT NULL COMMENT 'Admin UserId if created from admin',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_scheduled_sent` (`scheduled_at`, `sent_at`),
  KEY `idx_type` (`type`),
  KEY `idx_target` (`target`),
  KEY `idx_created_by` (`created_by`),
  FOREIGN KEY (`target_user_id`) REFERENCES `users`(`UserId`) ON DELETE SET NULL,
  FOREIGN KEY (`created_by`) REFERENCES `users`(`UserId`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: notification_log (optional – per-user send tracking)
-- ============================================
CREATE TABLE IF NOT EXISTS `notification_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `notification_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `fcm_token_id` int(11) DEFAULT NULL COMMENT 'FK to user_fcm_tokens.id',
  `sent_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `success` tinyint(1) DEFAULT 1 COMMENT '1=success, 0=failure',
  PRIMARY KEY (`id`),
  KEY `idx_notification_id` (`notification_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_sent_at` (`sent_at`),
  FOREIGN KEY (`notification_id`) REFERENCES `notifications`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE,
  FOREIGN KEY (`fcm_token_id`) REFERENCES `user_fcm_tokens`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- End of migration
-- ============================================
