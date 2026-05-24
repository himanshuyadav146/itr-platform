-- ============================================
-- CHECK DATABASE STATUS
-- Copy and paste this in phpMyAdmin SQL tab to see what's wrong
-- ============================================

-- 1. Check if table exists
SHOW TABLES LIKE 'itr_packages';

-- 2. Check table structure (columns)
DESCRIBE itr_packages;

-- 3. Count total packages
SELECT COUNT(*) as total_packages FROM itr_packages;

-- 4. Count active packages
SELECT COUNT(*) as active_packages FROM itr_packages WHERE isActive = 1;

-- 5. See all packages (with isActive status)
SELECT id, packagename, price, turnover, icon, color, isActive, createdAt 
FROM itr_packages 
ORDER BY id;

-- 6. Check if turnover column exists
SHOW COLUMNS FROM itr_packages LIKE 'turnover';

-- 7. Check if icon column exists
SHOW COLUMNS FROM itr_packages LIKE 'icon';

-- 8. Check if color column exists
SHOW COLUMNS FROM itr_packages LIKE 'color';

-- 9. Check personal_details for package_id
SHOW COLUMNS FROM personal_details LIKE 'package_id';
