-- ============================================
-- INSERT PACKAGES ONLY
-- Run this in phpMyAdmin SQL tab
-- This will insert all 7 packages
-- ============================================

-- First, let's check what's in the table
SELECT 'Current packages in database:' AS status;
SELECT id, packagename, price, isActive FROM itr_packages;

-- Delete old test data if any (OPTIONAL - comment out if you want to keep)
-- DELETE FROM itr_packages;

-- Insert the 7 packages
INSERT INTO `itr_packages` 
(packagename, price, description1, title1, title2, description2, turnover, icon, color, isActive, createdAt) 
VALUES 
(
    'Small Business Plan', 
    3499.00, 
    'Business/Profession (Entry level plan for small businesses or professionals.)',
    'Small Business',
    'Entry Level',
    'For small businesses with basic ITR filing needs',
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
    'Growing Business',
    'Moderate Growth',
    'For growing businesses with increasing revenue',
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
    'Established Business',
    'Comprehensive',
    'Full service package for established businesses',
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
    'Large Business',
    'Premium Service',
    'Premium ITR filing for large enterprises',
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
    'NRI Income',
    'Foreign Income',
    'Specialized service for NRI income tax filing',
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
    'NRI Business',
    'Comprehensive NRI',
    'Complete tax solution for NRI business owners',
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
    'E-Verification',
    'Quick Service',
    'Fast electronic verification of your ITR',
    '', 
    'verified_user', 
    'cyan', 
    1, 
    NOW()
);

-- Verify insertion
SELECT 'Packages after insertion:' AS status;
SELECT id, packagename, price, turnover, isActive FROM itr_packages ORDER BY id;

SELECT CONCAT('Total packages: ', COUNT(*)) AS result FROM itr_packages;
SELECT CONCAT('Active packages: ', COUNT(*)) AS result FROM itr_packages WHERE isActive = 1;
