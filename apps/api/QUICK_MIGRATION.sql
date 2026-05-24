-- Quick Package Migration - Copy and paste this entire content into phpMyAdmin SQL tab
-- If you get "Duplicate column" errors, that's OK - it means columns already exist!

-- Add new columns to itr_packages
ALTER TABLE `itr_packages` ADD COLUMN `turnover` varchar(100) DEFAULT NULL;
ALTER TABLE `itr_packages` ADD COLUMN `icon` varchar(100) DEFAULT NULL;
ALTER TABLE `itr_packages` ADD COLUMN `color` varchar(50) DEFAULT NULL;

-- Add package_id to personal_details
ALTER TABLE `personal_details` ADD COLUMN `package_id` int(11) DEFAULT NULL;

-- Add index
ALTER TABLE `personal_details` ADD INDEX `idx_package_id` (`package_id`);

-- Add foreign key
ALTER TABLE `personal_details` 
ADD CONSTRAINT `fk_personal_details_package` 
FOREIGN KEY (`package_id`) REFERENCES `itr_packages`(`id`) ON DELETE SET NULL;

-- Insert packages
INSERT INTO `itr_packages` (`packagename`, `price`, `description1`, `turnover`, `icon`, `color`, `isActive`, `createdAt`) VALUES 
('Small Business Plan', 3499.00, 'Business/Profession (Entry level plan for small businesses or professionals.)', 'Up to 10 lakh', 'business_center_outlined', 'blue', 1, NOW()),
('Growing Business Plan', 4999.00, 'Business/Profession (For growing businesses with moderate turnover.)', '10-25 Lakh', 'trending_up', 'green', 1, NOW()),
('Established Business Plan', 4999.00, 'Business/Profession (Comprehensive plan for established businesses with higher turnover.)', '25-50 lakh', 'apartment', 'orange', 1, NOW()),
('Large Business Plan', 4999.00, 'Business/Profession (Premium plan for large businesses with significant turnover.)', 'Above 50 Lakh', 'domain', 'purple', 1, NOW()),
('NRI Income Plan', 4999.00, 'Overseas Income (For non-residents with foreign income sources.)', '', 'flight_takeoff', 'teal', 1, NOW()),
('NRIs Business Plan', 7999.00, 'NRI Business Plan (For NRIs with foreign income and business/professional earnings.)', '', 'business', 'indigo', 1, NOW()),
('E-Verification Service', 199.00, 'Tax Return Verification (Service for electronic verification of income tax returns.)', '', 'verified_user', 'cyan', 1, NOW());

-- Verify
SELECT 'Migration Complete!' AS Status;
SELECT id, packagename, price, turnover FROM itr_packages;
