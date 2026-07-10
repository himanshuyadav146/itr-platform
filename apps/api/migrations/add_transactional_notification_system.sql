-- ============================================
-- Transactional email + push notification system
-- Reusable templates for ADMIN, CLIENT, PROFESSIONAL
-- ============================================
-- Run after add_push_notification_tables.sql
-- Replace itr_services with your database name if needed
-- ============================================

USE `itr_services`;

-- Global settings (admin inbox, from address, toggles)
CREATE TABLE IF NOT EXISTS `notification_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text NOT NULL,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_setting_key` (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `notification_settings` (`setting_key`, `setting_value`) VALUES
  ('admin_email', 'finnextgen2026@gmail.com'),
  ('from_email', 'noreply@allindiaitr.in'),
  ('from_name', 'FinApp'),
  ('admin_panel_url', 'https://allindiaitr.in/admin'),
  ('email_enabled', '1'),
  ('push_enabled', '1')
ON DUPLICATE KEY UPDATE `setting_value` = VALUES(`setting_value`);

-- Editable templates per event + audience + channel
CREATE TABLE IF NOT EXISTS `notification_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `event_key` varchar(100) NOT NULL,
  `audience` enum('ADMIN','CLIENT','PROFESSIONAL') NOT NULL,
  `channel` enum('EMAIL','PUSH','BOTH') NOT NULL DEFAULT 'BOTH',
  `email_subject` varchar(255) DEFAULT NULL,
  `email_body_html` text DEFAULT NULL,
  `email_body_text` text DEFAULT NULL,
  `push_title` varchar(255) DEFAULT NULL,
  `push_body` text DEFAULT NULL,
  `push_route` varchar(255) DEFAULT NULL COMMENT 'Mobile deep link route e.g. /status',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_event_audience` (`event_key`, `audience`),
  KEY `idx_event_key` (`event_key`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Delivery audit log (transactional; separate from campaign notification_log)
CREATE TABLE IF NOT EXISTS `notification_delivery_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `event_key` varchar(100) NOT NULL,
  `audience` varchar(50) NOT NULL,
  `channel` enum('EMAIL','PUSH') NOT NULL,
  `recipient` varchar(255) NOT NULL COMMENT 'email address or user_id for push',
  `reference_type` varchar(50) DEFAULT NULL COMMENT 'user_id, order_id, itr_id',
  `reference_id` varchar(100) DEFAULT NULL,
  `status` enum('sent','failed','skipped') NOT NULL DEFAULT 'sent',
  `error_message` text DEFAULT NULL,
  `payload_json` json DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_event_reference` (`event_key`, `reference_type`, `reference_id`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Seed templates (edit copy in DB anytime)
-- Placeholders: {{clientName}}, {{email}}, {{mobile}}, {{pan}},
-- {{financialYear}}, {{packageName}}, {{amount}}, {{orderId}}, {{itrId}},
-- {{expertName}}, {{expertEmail}}, {{documentCount}}, {{adminPanelUrl}}
-- ============================================

INSERT INTO `notification_templates`
  (`event_key`, `audience`, `channel`, `email_subject`, `email_body_html`, `email_body_text`, `push_title`, `push_body`, `push_route`, `is_active`)
VALUES
  ('client.registered', 'ADMIN', 'EMAIL',
   'New FinApp registration: {{clientName}}',
   '<p>A new client registered on FinApp.</p><ul><li><b>Name:</b> {{clientName}}</li><li><b>Email:</b> {{email}}</li><li><b>Mobile:</b> {{mobile}}</li></ul><p><a href="{{adminPanelUrl}}">Open admin panel</a></p>',
   'New client registered: {{clientName}} ({{email}}, {{mobile}})',
   NULL, NULL, NULL, 1),

  ('client.registered', 'CLIENT', 'BOTH',
   'Welcome to FinApp',
   '<p>Hi {{clientName}},</p><p>Welcome to FinApp! Your account is ready. Start your ITR filing journey in the app.</p>',
   'Welcome to FinApp, {{clientName}}! Your account is ready.',
   'Welcome to FinApp', 'Hi {{clientName}}, your account is ready.', '/', 1),

  ('personal_info.submitted', 'ADMIN', 'EMAIL',
   'Personal details submitted — PAN {{pan}}',
   '<p>Client <b>{{clientName}}</b> submitted personal information.</p><ul><li><b>PAN:</b> {{pan}}</li><li><b>Financial year:</b> {{financialYear}}</li><li><b>Package:</b> {{packageName}}</li></ul>',
   'Personal details submitted for PAN {{pan}} by {{clientName}}',
   NULL, NULL, NULL, 1),

  ('personal_info.submitted', 'CLIENT', 'BOTH',
   'Personal details received',
   '<p>Hi {{clientName}},</p><p>We received your personal details for PAN <b>{{pan}}</b>. Please upload your documents next.</p>',
   'We received your personal details for PAN {{pan}}.',
   'Details saved', 'Personal information for {{pan}} was saved.', '/document_upload', 1),

  ('documents.uploaded', 'ADMIN', 'EMAIL',
   'Documents uploaded — PAN {{pan}}',
   '<p>Client <b>{{clientName}}</b> uploaded/submitted documents.</p><ul><li><b>PAN:</b> {{pan}}</li><li><b>Documents:</b> {{documentCount}}</li></ul>',
   'Documents uploaded for PAN {{pan}} by {{clientName}} ({{documentCount}} files)',
   NULL, NULL, NULL, 1),

  ('documents.uploaded', 'CLIENT', 'BOTH',
   'Documents received',
   '<p>Hi {{clientName}},</p><p>We received your documents for PAN <b>{{pan}}</b>. Proceed to payment when ready.</p>',
   'Your documents for PAN {{pan}} were received.',
   'Documents received', 'We received your documents for {{pan}}.', '/document_upload', 1),

  ('payment.success', 'ADMIN', 'EMAIL',
   'Payment received — {{amount}} for PAN {{pan}}',
   '<p>Payment successful for <b>{{clientName}}</b>.</p><ul><li><b>Order:</b> {{orderId}}</li><li><b>Amount:</b> ₹{{amount}}</li><li><b>PAN:</b> {{pan}}</li></ul>',
   'Payment ₹{{amount}} received for order {{orderId}} (PAN {{pan}})',
   NULL, NULL, NULL, 1),

  ('payment.success', 'CLIENT', 'BOTH',
   'Payment successful — FinApp',
   '<p>Hi {{clientName}},</p><p>Your payment of <b>₹{{amount}}</b> for order <b>{{orderId}}</b> was successful. Our team will process your filing.</p>',
   'Payment of ₹{{amount}} for order {{orderId}} was successful.',
   'Payment successful', '₹{{amount}} paid for order {{orderId}}.', '/status', 1),

  ('expert.assigned', 'ADMIN', 'EMAIL',
   'ITR {{itrId}} assigned to {{expertName}}',
   '<p>ITR <b>{{itrId}}</b> (PAN {{pan}}) assigned to <b>{{expertName}}</b> ({{expertEmail}}).</p>',
   'ITR {{itrId}} assigned to {{expertName}}',
   NULL, NULL, NULL, 1),

  ('expert.assigned', 'CLIENT', 'BOTH',
   'Your tax expert is assigned',
   '<p>Hi {{clientName}},</p><p><b>{{expertName}}</b> is now your tax expert for PAN <b>{{pan}}</b>. You can track progress in the app.</p>',
   'Your tax expert {{expertName}} is assigned for PAN {{pan}}.',
   'Expert assigned', '{{expertName}} is your tax expert.', '/status', 1),

  ('expert.assigned', 'PROFESSIONAL', 'EMAIL',
   'New ITR assigned — PAN {{pan}}',
   '<p>Hi {{expertName}},</p><p>A new ITR (ID {{itrId}}, PAN <b>{{pan}}</b>) has been assigned to you for client <b>{{clientName}}</b>.</p><p><a href="{{adminPanelUrl}}">Open admin panel</a></p>',
   'New ITR {{itrId}} (PAN {{pan}}) assigned to you for client {{clientName}}.',
   NULL, NULL, NULL, 1)

ON DUPLICATE KEY UPDATE
  `channel` = VALUES(`channel`),
  `email_subject` = VALUES(`email_subject`),
  `email_body_html` = VALUES(`email_body_html`),
  `email_body_text` = VALUES(`email_body_text`),
  `push_title` = VALUES(`push_title`),
  `push_body` = VALUES(`push_body`),
  `push_route` = VALUES(`push_route`),
  `is_active` = VALUES(`is_active`);
