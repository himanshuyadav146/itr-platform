-- ============================================
-- Insert Frontend Packages Data
-- Purpose: Insert all packages as defined in frontend requirements
-- Date: 2026-01-17
-- ============================================

-- Clear existing packages (optional - comment out if you want to keep existing data)
-- TRUNCATE TABLE `itr_packages`;

-- Insert packages matching frontend requirements
INSERT INTO `itr_packages` 
(`packagename`, `price`, `description1`, `turnover`, `icon`, `color`, `isActive`, `createdAt`) 
VALUES 
(
    'Small Business Plan', 
    3499.00, 
    'Business/Profession (Entry level plan for small businesses or professionals.)', 
    'Up to 10 lakh', 
    'business_center_outlined', 
    'blue', 
    1, 
    NOW()
),
(
    'Growing Business Plan', 
    4999.00, 
    'Business/Profession (For growing businesses with moderate turnover.)', 
    '10-25 Lakh', 
    'trending_up', 
    'green', 
    1, 
    NOW()
),
(
    'Established Business Plan', 
    4999.00, 
    'Business/Profession (Comprehensive plan for established businesses with higher turnover.)', 
    '25-50 lakh', 
    'apartment', 
    'orange', 
    1, 
    NOW()
),
(
    'Large Business Plan', 
    4999.00, 
    'Business/Profession (Premium plan for large businesses with significant turnover.)', 
    'Above 50 Lakh', 
    'domain', 
    'purple', 
    1, 
    NOW()
),
(
    'NRI Income Plan', 
    4999.00, 
    'Overseas Income (For non-residents with foreign income sources.)', 
    '', 
    'flight_takeoff', 
    'teal', 
    1, 
    NOW()
),
(
    'NRIs Business Plan', 
    7999.00, 
    'NRI Business Plan (For NRIs with foreign income and business/professional earnings.)', 
    '', 
    'business', 
    'indigo', 
    1, 
    NOW()
),
(
    'E-Verification Service', 
    199.00, 
    'Tax Return Verification (Service for electronic verification of income tax returns.)', 
    '', 
    'verified_user', 
    'cyan', 
    1, 
    NOW()
)
ON DUPLICATE KEY UPDATE 
    `packagename` = VALUES(`packagename`),
    `price` = VALUES(`price`),
    `description1` = VALUES(`description1`),
    `turnover` = VALUES(`turnover`),
    `icon` = VALUES(`icon`),
    `color` = VALUES(`color`);

-- Verify insertion
SELECT 'Packages inserted successfully' AS status;
SELECT id, packagename, price, turnover, icon, color FROM `itr_packages` ORDER BY id;
