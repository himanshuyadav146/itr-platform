-- ============================================
-- Migration: Add User Journey Table
-- Purpose: Track user's journey through different service flows
-- ============================================

USE `itr_services`;

-- ============================================
-- Table: user_journey
-- Tracks which service flow the user is currently in
-- ============================================
CREATE TABLE IF NOT EXISTS `user_journey` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `userId` INT(11) NOT NULL,
  `panNumber` VARCHAR(10) DEFAULT NULL,
  `journeyType` ENUM('ITR', 'E-Verify', 'GST', 'Loan') NOT NULL,
  `status` ENUM('initiated', 'in_progress', 'completed', 'cancelled') DEFAULT 'initiated',
  `currentStep` VARCHAR(100) DEFAULT NULL COMMENT 'Current step in the journey (e.g., personal_details, documents, payment)',
  `metadata` JSON DEFAULT NULL COMMENT 'Additional journey-specific data',
  `startedAt` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `completedAt` DATETIME DEFAULT NULL,
  `updatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_userid` (`userId`),
  KEY `idx_pan` (`panNumber`),
  KEY `idx_journey_type` (`journeyType`),
  KEY `idx_status` (`status`),
  KEY `idx_userid_journey` (`userId`, `journeyType`),
  FOREIGN KEY (`userId`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add index for active journeys
CREATE INDEX idx_active_journey ON user_journey(userId, journeyType, status);

-- ============================================
-- Add journeyId reference to personal_details
-- ============================================
ALTER TABLE `personal_details` 
ADD COLUMN `journeyId` INT(11) DEFAULT NULL AFTER `package_id`,
ADD KEY `idx_journey` (`journeyId`),
ADD FOREIGN KEY (`journeyId`) REFERENCES `user_journey`(`id`) ON DELETE SET NULL;

-- ============================================
-- Add journeyId reference to document_details
-- ============================================
ALTER TABLE `document_details` 
ADD COLUMN `journeyId` INT(11) DEFAULT NULL AFTER `PanNumber`,
ADD KEY `idx_journey` (`journeyId`),
ADD FOREIGN KEY (`journeyId`) REFERENCES `user_journey`(`id`) ON DELETE SET NULL;

-- ============================================
-- Sample Data (Optional - for testing)
-- ============================================
-- You can uncomment these lines to test with sample data
-- INSERT INTO `user_journey` (`userId`, `panNumber`, `journeyType`, `status`, `currentStep`) VALUES
-- (1, 'ABCDE1234F', 'ITR', 'in_progress', 'personal_details'),
-- (1, 'ABCDE1234F', 'GST', 'initiated', 'documents');
