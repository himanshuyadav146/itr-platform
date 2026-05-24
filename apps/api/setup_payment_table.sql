-- ============================================
-- Payment System Database Setup
-- Generic payment table - no hardcoded fee types
-- ============================================
-- Run this in phpMyAdmin SQL tab or MySQL command line
-- ============================================

USE `itr_services`;

-- ============================================
-- Table: payment_info
-- Generic payment table - stores payment transactions
-- ============================================
CREATE TABLE IF NOT EXISTS `payment_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `payment_id` varchar(50) NOT NULL COMMENT 'Alphanumeric payment ID',
  `user_id` int(11) NOT NULL COMMENT 'FK to users table',
  `package_id` int(11) DEFAULT NULL COMMENT 'FK to itr_packages table',
  `pan_number` varchar(10) DEFAULT NULL COMMENT 'Reference to PAN, fetch details from personal_details',
  `order_id` varchar(100) DEFAULT NULL COMMENT 'Gateway order ID',
  `transaction_id` varchar(100) DEFAULT NULL COMMENT 'Gateway transaction ID',
  `subtotal` decimal(15,2) NOT NULL COMMENT 'Total before GST (calculated from package + additional fees)',
  `gst_percentage` decimal(5,2) DEFAULT 18.00 COMMENT 'GST percentage',
  `gst_amount` decimal(15,2) NOT NULL COMMENT 'GST amount',
  `grand_total` decimal(15,2) NOT NULL COMMENT 'Final amount to pay',
  `currency` varchar(10) DEFAULT 'INR',
  `payment_status` varchar(50) DEFAULT 'pending' COMMENT 'pending, success, failed, cancelled, refunded',
  `payment_method` varchar(50) DEFAULT NULL COMMENT 'card, netbanking, upi, wallet, etc',
  `gateway_name` varchar(50) DEFAULT NULL COMMENT 'paytm, razorpay, etc',
  `merchant_id` varchar(100) DEFAULT NULL,
  `gateway_response` text DEFAULT NULL COMMENT 'Full gateway response JSON',
  `webhook_data` text DEFAULT NULL COMMENT 'Webhook callback data',
  `failure_reason` text DEFAULT NULL COMMENT 'Reason for failure if any',
  `callback_url` varchar(500) DEFAULT NULL,
  `redirect_url` varchar(500) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `paid_at` datetime DEFAULT NULL COMMENT 'Payment completion time',
  PRIMARY KEY (`id`),
  UNIQUE KEY `payment_id` (`payment_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_package_id` (`package_id`),
  KEY `idx_pan_number` (`pan_number`),
  KEY `idx_order_id` (`order_id`),
  KEY `idx_transaction_id` (`transaction_id`),
  KEY `idx_payment_status` (`payment_status`),
  KEY `idx_created_at` (`created_at`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE,
  FOREIGN KEY (`package_id`) REFERENCES `itr_packages`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: payment_additional_fees
-- Configurable additional fees (E-Filing Fee, E-Verification Fee, etc.)
-- ============================================
CREATE TABLE IF NOT EXISTS `payment_additional_fees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fee_name` varchar(255) NOT NULL COMMENT 'E-Filing Fee, E-Verification Fee, etc',
  `fee_amount` decimal(15,2) NOT NULL,
  `display_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_display_order` (`display_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Insert Sample Additional Fees
-- ============================================
INSERT INTO `payment_additional_fees` (`fee_name`, `fee_amount`, `display_order`, `is_active`) VALUES
('E-Filing Fee', 7999.00, 1, 1),
('E-Verification Fee', 199.00, 2, 1)
ON DUPLICATE KEY UPDATE `fee_name` = `fee_name`;

-- ============================================
-- Verification Queries
-- ============================================
-- SELECT * FROM payment_info;
-- SELECT * FROM payment_additional_fees WHERE is_active = 1;

