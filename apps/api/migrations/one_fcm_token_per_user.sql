-- ============================================
-- Migration: One FCM token per user
-- Removes duplicate tokens per user and enforces single row per user_id
-- Run this after add_push_notification_tables.sql
-- ============================================
-- For cPanel: replace itr_services with your database name (e.g. allindia_tax_services)
-- ============================================

-- USE `itr_services`;

-- Step 1: Remove duplicate rows – keep one row per user (the row with highest id per user_id)
DELETE t FROM user_fcm_tokens t
LEFT JOIN (SELECT MAX(id) AS id FROM user_fcm_tokens GROUP BY user_id) keep ON t.id = keep.id
WHERE keep.id IS NULL;

-- Step 2: Drop old unique key (user_id + fcm_token)
ALTER TABLE user_fcm_tokens DROP INDEX uq_user_fcm;

-- Step 3: Enforce one row per user
ALTER TABLE user_fcm_tokens ADD UNIQUE KEY uq_user_id (user_id);

-- ============================================
-- End of migration
-- ============================================
