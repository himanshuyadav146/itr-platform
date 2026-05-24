-- ============================================
-- ITR API - Create Tables Only (For cPanel)
-- ============================================
-- IMPORTANT: DO NOT RUN THIS UNTIL YOU HAVE:
-- 1. Created database in cPanel → MySQL Databases
-- 2. Created database user in cPanel
-- 3. Added user to database with ALL PRIVILEGES
-- 4. Selected the database in phpMyAdmin
-- ============================================
-- 
-- INSTRUCTIONS:
-- 1. In cPanel, go to MySQL Databases
-- 2. Create database: tax_services (or your preferred name)
-- 3. Create database user with password
-- 4. Add user to database with ALL PRIVILEGES
-- 5. Open phpMyAdmin
-- 6. Click on your database name in left sidebar
-- 7. Click "SQL" tab
-- 8. Copy and paste this entire file
-- 9. Click "Go"
-- ============================================

-- ============================================
-- Table: users
-- ============================================
CREATE TABLE IF NOT EXISTS `users` (
  `UserId` int(11) NOT NULL AUTO_INCREMENT,
  `FirstName` varchar(100) DEFAULT NULL,
  `MiddleName` varchar(100) DEFAULT NULL,
  `LastName` varchar(100) DEFAULT NULL,
  `Email` varchar(255) NOT NULL,
  `Mobile` varchar(20) DEFAULT NULL,
  `Password` varchar(255) NOT NULL,
  `Platform` varchar(50) DEFAULT 'web',
  `Version` varchar(20) DEFAULT '1.0',
  `CreatedAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `UpdatedAt` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`UserId`),
  UNIQUE KEY `Email` (`Email`),
  KEY `idx_email` (`Email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: services
-- ============================================
CREATE TABLE IF NOT EXISTS `services` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) NOT NULL,
  `CreatedAt` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Name` (`Name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: personal_details
-- ============================================
CREATE TABLE IF NOT EXISTS `personal_details` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `PANNumber` varchar(10) NOT NULL,
  `FirstName` varchar(100) NOT NULL,
  `MiddleName` varchar(100) DEFAULT NULL,
  `LastName` varchar(100) NOT NULL,
  `EMAIL` varchar(255) NOT NULL,
  `MobileNumber` varchar(20) DEFAULT NULL,
  `aadharCardNumber` varchar(20) DEFAULT NULL,
  `Gender` varchar(10) DEFAULT NULL,
  `DATEOFBIRTH` date DEFAULT NULL,
  `FinancialYear` varchar(20) DEFAULT NULL,
  `Address` text DEFAULT NULL,
  `Country` varchar(100) DEFAULT 'India',
  `isActive` tinyint(1) DEFAULT 1,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `createdBy` int(11) DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `updatedBy` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_userid` (`UserId`),
  KEY `idx_pan` (`PANNumber`),
  KEY `idx_userid_pan` (`UserId`, `PANNumber`),
  FOREIGN KEY (`UserId`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: document_details
-- ============================================
CREATE TABLE IF NOT EXISTS `document_details` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `PanNumber` varchar(10) NOT NULL,
  `name` varchar(255) NOT NULL,
  `type` varchar(50) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `fileName` varchar(255) NOT NULL,
  `isActive` tinyint(1) DEFAULT 1,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `createdBy` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_userid` (`UserId`),
  KEY `idx_pan` (`PanNumber`),
  KEY `idx_userid_pan` (`UserId`, `PanNumber`),
  FOREIGN KEY (`UserId`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: itr_detail
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_detail` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userId` int(11) NOT NULL,
  `panNumber` varchar(10) DEFAULT NULL,
  `financialYear` varchar(20) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_userid` (`userId`),
  KEY `idx_pan` (`panNumber`),
  FOREIGN KEY (`userId`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: itr_source
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_source` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `itrId` int(11) NOT NULL,
  `sourceType` varchar(100) DEFAULT NULL,
  `sourceName` varchar(255) DEFAULT NULL,
  `amount` decimal(15,2) DEFAULT NULL,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_itrid` (`itrId`),
  FOREIGN KEY (`itrId`) REFERENCES `itr_detail`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: itr_packages
-- ============================================
CREATE TABLE IF NOT EXISTS `itr_packages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `packagename` varchar(255) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `title1` varchar(255) DEFAULT NULL,
  `description1` text DEFAULT NULL,
  `title2` varchar(255) DEFAULT NULL,
  `description2` text DEFAULT NULL,
  `isActive` tinyint(1) DEFAULT 1,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Insert Sample Data (Optional)
-- ============================================

-- Sample Services
INSERT INTO `services` (`Name`) VALUES 
('ITR Filing'),
('Tax Consultation'),
('Document Verification')
ON DUPLICATE KEY UPDATE `Name` = `Name`;

-- Sample ITR Packages
INSERT INTO `itr_packages` (`packagename`, `price`, `title1`, `description1`, `title2`, `description2`, `isActive`) VALUES
('Basic', 499.00, 'Basic ITR Filing', 'For individuals with salary income only', 'Quick Processing', 'Get your ITR filed within 24 hours', 1),
('Standard', 999.00, 'Standard ITR Filing', 'For individuals with multiple income sources', 'Expert Support', 'Dedicated tax expert support', 1),
('Premium', 1999.00, 'Premium ITR Filing', 'For complex tax situations', 'Priority Processing', 'Priority processing with audit support', 1)
ON DUPLICATE KEY UPDATE `packagename` = `packagename`;

