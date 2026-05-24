-- ============================================
-- Sync local ITR tables schema with production
-- ============================================
-- This script makes local schema compatible with the production
-- setup used on allindiaitr.in.
--
-- It is idempotent and only applies changes when required:
-- 1) Ensures itr_detail uses `updatedAt` (camelCase) column
-- 2) Ensures itr_order_concerns.status_id is nullable (DEFAULT NULL)
-- 3) Adds itr_order_concerns.comment column for ITR status-update comments
--
-- Run against the relevant database:
--   USE your_database_name;
--   SOURCE migrations/sync_itr_tables_with_production.sql;

-- ============================================
-- 1. itr_detail: ensure `updatedAt` exists and is used
-- ============================================

SET @has_updatedAt := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'itr_detail'
    AND COLUMN_NAME = 'updatedAt'
);

SET @has_updated_at := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'itr_detail'
    AND COLUMN_NAME = 'updated_at'
);

-- If we have updated_at but not updatedAt, rename updated_at -> updatedAt
SET @sql := IF(
  @has_updatedAt = 0 AND @has_updated_at = 1,
  'ALTER TABLE `itr_detail` CHANGE COLUMN `updated_at` `updatedAt` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
  'SELECT \"itr_detail timestamp column already in production format\" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 2. itr_order_concerns: make status_id nullable (DEFAULT NULL)
-- ============================================

SET @has_status_id := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'itr_order_concerns'
    AND COLUMN_NAME = 'status_id'
);

SET @status_id_nullable := (
  SELECT IS_NULLABLE
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'itr_order_concerns'
    AND COLUMN_NAME = 'status_id'
  LIMIT 1
);

-- Only alter when the column exists AND is currently NOT NULL
SET @sql2 := IF(
  @has_status_id = 1 AND UPPER(IFNULL(@status_id_nullable, 'YES')) = 'NO',
  'ALTER TABLE `itr_order_concerns` MODIFY COLUMN `status_id` int(11) DEFAULT NULL COMMENT ''FK to itr_order_status (nullable for backwards compatibility)''',
  'SELECT \"itr_order_concerns.status_id already nullable or column missing\" AS info'
);

PREPARE stmt2 FROM @sql2;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

-- ============================================
-- 3. itr_order_concerns: add `comment` column (for ITR status-update comments)
-- ============================================

SET @has_comment := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'itr_order_concerns'
    AND COLUMN_NAME = 'comment'
);

SET @sql3 := IF(
  @has_comment = 0,
  'ALTER TABLE `itr_order_concerns` ADD COLUMN `comment` text DEFAULT NULL COMMENT ''ITR status update comment (also stored in concern_text)'' AFTER `concern_text`',
  'SELECT \"itr_order_concerns.comment already exists\" AS info'
);

PREPARE stmt3 FROM @sql3;
EXECUTE stmt3;
DEALLOCATE PREPARE stmt3;

-- ============================================
-- DONE
-- ============================================
