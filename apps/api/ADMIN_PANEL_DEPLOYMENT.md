# Admin Panel Database APIs - Server Deployment Guide

This comprehensive guide covers deploying all admin panel database APIs to your server (cPanel, VPS, or shared hosting).

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Database Tables Required](#database-tables-required)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Database Setup](#database-setup)
6. [File Upload & Configuration](#file-upload--configuration)
7. [Admin User Setup](#admin-user-setup)
8. [Testing Deployment](#testing-deployment)
9. [Troubleshooting](#troubleshooting)
10. [Security Checklist](#security-checklist)

---

## 📖 Overview

The Admin Panel consists of **7 main API endpoints** that interact with the database:

### Admin API Endpoints

1. **`/admin/dashboard.php`** - Dashboard statistics and overview
2. **`/admin/users.php`** - User management (list, view, update, delete)
3. **`/admin/orders.php`** - Order/ITR management (list, view, update status)
4. **`/admin/payments.php`** - Payment management (list, view, filter)
5. **`/admin/concerns.php`** - Concern management (list, view, resolve/reject)
6. **`/admin/analytics.php`** - Analytics and reports
7. **`/admin/itrs.php`** - ITR-specific operations

### Database Dependencies

These APIs require the following database tables:
- `users` (with `Role` and `IsActive` columns)
- `itr_detail`
- `payment_info`
- `itr_order_concerns`
- `itr_order_status`
- `itr_packages`
- `personal_details`
- `document_details`
- `services`

---

## ✅ Prerequisites

Before deployment, ensure you have:

- [ ] Server access (cPanel, FTP, SSH, or File Manager)
- [ ] Database creation privileges
- [ ] phpMyAdmin access (or MySQL command line)
- [ ] PHP 7.4 or higher installed
- [ ] MySQL 5.7+ or MariaDB 10.3+
- [ ] All admin panel PHP files ready (`admin/` directory)
- [ ] Database setup scripts ready

---

## 🗄️ Database Tables Required

### Core Tables (Main Application)

1. **`users`** - User accounts
2. **`services`** - ITR services list
3. **`personal_details`** - User personal information
4. **`document_details`** - User documents
5. **`itr_detail`** - ITR orders
6. **`itr_source`** - ITR sources
7. **`itr_packages`** - Package information
8. **`payment_info`** - Payment transactions
9. **`payment_additional_fees`** - Additional payment fees

### Admin-Specific Tables

1. **`itr_order_status`** - Order status tracking
2. **`itr_order_concerns`** - User concerns/complaints

### Required Columns in `users` Table

The admin panel requires these additional columns in the `users` table:
- `Role` (varchar(50), default: 'user') - User role (user, admin)
- `IsActive` (tinyint(1), default: 1) - Active status

---

## 🚀 Step-by-Step Deployment

### Step 1: Prepare Files for Upload

**Admin Panel Files to Upload:**
```
api/
├── admin/
│   ├── dashboard.php
│   ├── users.php
│   ├── orders.php
│   ├── payments.php
│   ├── concerns.php
│   ├── analytics.php
│   └── itrs.php
├── include/
│   └── config.php (or config.local.php)
├── phpjwt/
│   └── Token.php
└── setup_admin_tables.sql
```

**Note:** Ensure you also have all main application files (auth, itrdetails, payment, etc.) as admin APIs depend on the main database structure.

---

## 🗃️ Database Setup

### Method 1: Using phpMyAdmin (Recommended for cPanel)

#### Step 1.1: Import Main Database Schema

1. **Login to phpMyAdmin**
   - Access: `https://yourdomain.com/phpmyadmin` or through cPanel

2. **Select Your Database**
   - Click on your database name (e.g., `username_itr_services`)

3. **Import Main Tables**
   - Go to **"Import"** tab
   - Click **"Choose File"**
   - Select `setup_database_cpanel.sql` (or `setup_database.sql` if already modified for cPanel)
   - **IMPORTANT:** For cPanel, modify the SQL first:
     - Remove `CREATE DATABASE` line (database already exists)
     - Remove `CREATE USER` and `GRANT` lines (user already created in cPanel)
     - Keep only `USE` statement and all `CREATE TABLE` statements
   - Click **"Go"**

4. **Verify Tables Created**
   ```sql
   SHOW TABLES;
   ```
   You should see: `users`, `services`, `personal_details`, `document_details`, `itr_detail`, `itr_packages`, etc.

#### Step 1.2: Import Payment Tables

If payment tables don't exist:

1. **Import Payment Schema**
   - Go to **"Import"** tab
   - Select `setup_payment_table.sql`
   - Click **"Go"**

   OR run in SQL tab:
   ```sql
   -- Payment Info Table
   CREATE TABLE IF NOT EXISTS `payment_info` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `payment_id` varchar(100) NOT NULL,
     `order_id` varchar(100) NOT NULL,
     `user_id` int(11) NOT NULL,
     `package_id` int(11) DEFAULT NULL,
     `subtotal` decimal(10,2) DEFAULT 0.00,
     `tax` decimal(10,2) DEFAULT 0.00,
     `discount` decimal(10,2) DEFAULT 0.00,
     `grand_total` decimal(10,2) NOT NULL,
     `payment_status` varchar(50) DEFAULT 'pending',
     `payment_method` varchar(50) DEFAULT NULL,
     `transaction_id` varchar(255) DEFAULT NULL,
     `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
     `paid_at` datetime DEFAULT NULL,
     PRIMARY KEY (`id`),
     UNIQUE KEY `payment_id` (`payment_id`),
     KEY `idx_user_id` (`user_id`),
     KEY `idx_order_id` (`order_id`),
     KEY `idx_payment_status` (`payment_status`),
     FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
   ```

#### Step 1.3: Import ITR Status Tables

If status tables don't exist:

1. **Import ITR Status Schema**
   - Go to **"Import"** tab
   - Select `setup_itr_status_table.sql`
   - Click **"Go"**

   OR run in SQL tab:
   ```sql
   -- ITR Order Status Table
   CREATE TABLE IF NOT EXISTS `itr_order_status` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `order_id` varchar(100) NOT NULL,
     `itr_id` int(11) NOT NULL,
     `status` varchar(50) NOT NULL DEFAULT 'pending',
     `message` text DEFAULT NULL,
     `updated_by` int(11) DEFAULT NULL,
     `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
     `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
     PRIMARY KEY (`id`),
     KEY `idx_order_id` (`order_id`),
     KEY `idx_itr_id` (`itr_id`),
     KEY `idx_status` (`status`)
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

   -- ITR Order Concerns Table
   CREATE TABLE IF NOT EXISTS `itr_order_concerns` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `order_id` varchar(100) NOT NULL,
     `itr_id` int(11) NOT NULL,
     `user_id` int(11) NOT NULL,
     `concern_type` varchar(100) DEFAULT NULL,
     `description` text NOT NULL,
     `status` varchar(50) DEFAULT 'pending',
     `resolution` text DEFAULT NULL,
     `resolved_by` int(11) DEFAULT NULL,
     `resolved_at` datetime DEFAULT NULL,
     `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
     `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
     PRIMARY KEY (`id`),
     KEY `idx_order_id` (`order_id`),
     KEY `idx_user_id` (`user_id`),
     KEY `idx_status` (`status`),
     FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
   ```

#### Step 1.4: Add Admin Role Support

**This is critical for admin panel to work!**

1. **Go to SQL Tab** in phpMyAdmin

2. **Run Admin Tables Setup**
   - Copy contents of `setup_admin_tables.sql`
   - Paste into SQL tab
   - **IMPORTANT:** Update the database name in the `USE` statement:
     ```sql
     USE `your_cpanel_username_itr_services`;  -- Replace with your actual database name
     ```
   - Click **"Go"**

   OR manually run:
   ```sql
   USE `your_cpanel_username_itr_services`;

   -- Add Role column to users table (if not exists)
   ALTER TABLE `users` 
   ADD COLUMN IF NOT EXISTS `Role` varchar(50) DEFAULT 'user' COMMENT 'user, admin' AFTER `Password`,
   ADD COLUMN IF NOT EXISTS `IsActive` tinyint(1) DEFAULT 1 COMMENT 'Active status' AFTER `Role`;

   -- Create indexes for faster queries
   CREATE INDEX IF NOT EXISTS `idx_role` ON `users` (`Role`);
   CREATE INDEX IF NOT EXISTS `idx_is_active` ON `users` (`IsActive`);
   ```

3. **Verify Admin Columns Added**
   ```sql
   DESCRIBE users;
   ```
   You should see `Role` and `IsActive` columns.

### Method 2: Using MySQL Command Line

If you have SSH access:

```bash
# 1. Connect to MySQL
mysql -u your_username -p

# 2. Use your database
USE your_database_name;

# 3. Import main tables
source /path/to/setup_database_cpanel.sql;

# 4. Import payment tables (if needed)
source /path/to/setup_payment_table.sql;

# 5. Import ITR status tables (if needed)
source /path/to/setup_itr_status_table.sql;

# 6. Add admin role support
source /path/to/setup_admin_tables.sql;
```

---

## 📁 File Upload & Configuration

### Step 2.1: Upload Admin Panel Files

#### Option A: Using cPanel File Manager

1. **Login to cPanel**
2. **Open File Manager**
3. **Navigate to** `public_html/api/` (or your API directory)
4. **Create `admin` folder** if it doesn't exist
5. **Upload all admin files:**
   - `admin/dashboard.php`
   - `admin/users.php`
   - `admin/orders.php`
   - `admin/payments.php`
   - `admin/concerns.php`
   - `admin/analytics.php`
   - `admin/itrs.php`

#### Option B: Using FTP/SFTP

```bash
# Using FileZilla, WinSCP, or command line FTP
# Upload entire admin/ directory to: /public_html/api/admin/
```

### Step 2.2: Set File Permissions

In File Manager, set permissions:

- **PHP Files:** `644`
  - Right-click each `.php` file → Change Permissions → `644`

- **Folders:** `755`
  - Right-click `admin/` folder → Change Permissions → `755`

### Step 2.3: Configure Database Connection

1. **Open `include/config.php`** in File Manager or via FTP

2. **Update Database Credentials:**
   ```php
   <?php
   // Database configuration for cPanel
   $servername = "localhost";  // Usually 'localhost' in cPanel
   $username = "cpaneluser_itr_services";  // Your cPanel database username
   $password = "your_secure_password";  // Your database password
   $database = "cpaneluser_itr_services";  // Your database name
   
   // Create connection
   $conn = mysqli_connect($servername, $username, $password, $database);
   
   // Check connection
   if (!$conn) {
       die("Connection failed: " . mysqli_connect_error());
   }
   
   // JWT Configuration
   $key = 'your_secure_random_key_here';  // Change this to a strong random string
   $expire = 36000;  // Token expiry in seconds (10 hours)
   ?>
   ```

3. **Important Notes:**
   - **Database Host:** In cPanel, it's usually `localhost`, but check your MySQL Databases section
   - **Database Name:** cPanel prefixes usernames, so your database might be `username_itr_services`
   - **JWT Key:** Generate a secure random string for production (minimum 32 characters)

4. **Generate Secure JWT Key:**
   ```bash
   # On Linux/Mac:
   openssl rand -base64 32
   
   # Or use online generator:
   # https://randomkeygen.com/
   ```

### Step 2.4: Verify Required Files Exist

Ensure these supporting files are present:

```
api/
├── include/
│   └── config.php (with correct database credentials)
├── phpjwt/
│   └── Token.php (JWT token handling)
└── admin/
    └── [all admin PHP files]
```

---

## 👤 Admin User Setup

After database setup, you need to create an admin user to access the admin panel.

### Step 3.1: Create Admin User

#### Option A: Update Existing User to Admin

```sql
-- Run in phpMyAdmin SQL tab:
UPDATE users 
SET Role = 'admin', IsActive = 1 
WHERE Email = 'your-email@example.com';
```

#### Option B: Create New Admin User

**Important:** Create user through signup API first, then update role, OR create directly in database:

```sql
-- Run in phpMyAdmin SQL tab:
-- Note: Password should be hashed. Use PHP password_hash() or create user via signup API first.

-- Method 1: Create via API first (recommended)
-- POST to /auth/signup.php with user details
-- Then update role:
UPDATE users SET Role = 'admin' WHERE Email = 'admin@example.com';

-- Method 2: Direct insert (password needs to be hashed)
-- First, hash your password in PHP:
-- <?php echo password_hash('your_password', PASSWORD_DEFAULT); ?>
-- Then insert:
INSERT INTO users 
    (FirstName, LastName, Email, Mobile, Password, Role, Platform, Version, IsActive) 
VALUES 
    ('Admin', 'User', 'admin@example.com', '9876543210', 
     '$2y$10$hashed_password_here', 'admin', 'web', '1.0', 1);
```

#### Option C: Create Admin User via API (Recommended)

```bash
# 1. Signup a new user
curl -X POST https://yourdomain.com/api/auth/signup.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "SecurePassword123!",
    "firstName": "Admin",
    "lastName": "User",
    "mobile": "9876543210",
    "platform": "web",
    "version": "1.0"
  }'

# 2. Update user role to admin in database
# Run in phpMyAdmin SQL tab:
UPDATE users SET Role = 'admin' WHERE Email = 'admin@example.com';
```

### Step 3.2: Verify Admin User

```sql
-- Check admin users
SELECT UserId, FirstName, LastName, Email, Role, IsActive 
FROM users 
WHERE Role = 'admin';
```

You should see at least one user with `Role = 'admin'`.

---

## 🧪 Testing Deployment

### Step 4.1: Test Database Connection

1. **Access test endpoint:**
   ```
   https://yourdomain.com/api/test_connection.php
   ```
   Should return: `✅ Database connected successfully!`

### Step 4.2: Test Authentication

```bash
# 1. Login as admin user
curl -X POST https://yourdomain.com/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "YourPassword",
    "platform": "web",
    "version": "1.0"
  }'

# Save the token from response
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "userId": 1,
      "email": "admin@example.com",
      "role": "admin"
    }
  }
}
```

### Step 4.3: Test Admin Dashboard

```bash
# Replace YOUR_TOKEN with token from login response
curl -X GET https://yourdomain.com/api/admin/dashboard.php \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "summary": {
      "totalUsers": 150,
      "totalOrders": 75,
      "totalPayments": 80,
      "successfulPayments": 65,
      "pendingPayments": 10,
      "pendingConcerns": 5,
      "totalRevenue": 512500.50,
      "todayRevenue": 25000.00,
      "monthRevenue": 125000.00
    },
    "recent": {
      "users": 10,
      "orders": 5,
      "payments": 8
    },
    "packageStats": [...],
    "paymentStatusBreakdown": [...],
    "recentActivity": [...]
  }
}
```

### Step 4.4: Test All Admin Endpoints

```bash
# Set token variable
TOKEN="your_token_here"

# 1. Dashboard
curl -X GET https://yourdomain.com/api/admin/dashboard.php \
  -H "Authorization: Bearer $TOKEN" | jq

# 2. Users List
curl -X GET "https://yourdomain.com/api/admin/users.php?page=1&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq

# 3. Orders List
curl -X GET "https://yourdomain.com/api/admin/orders.php?page=1&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq

# 4. Payments List
curl -X GET "https://yourdomain.com/api/admin/payments.php?page=1&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq

# 5. Concerns List
curl -X GET "https://yourdomain.com/api/admin/concerns.php?status=pending" \
  -H "Authorization: Bearer $TOKEN" | jq

# 6. Analytics
curl -X GET "https://yourdomain.com/api/admin/analytics.php?period=30" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### Step 4.5: Verify Database Queries

Check that all required tables have data or are ready:

```sql
-- Check users table structure
DESCRIBE users;
-- Should show: Role, IsActive columns

-- Check table counts
SELECT 
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM itr_detail) as total_orders,
    (SELECT COUNT(*) FROM payment_info) as total_payments,
    (SELECT COUNT(*) FROM itr_order_concerns) as total_concerns,
    (SELECT COUNT(*) FROM users WHERE Role = 'admin') as admin_users;
```

---

## 🔧 Troubleshooting

### Issue 1: 404 Not Found on Admin Endpoints

**Symptoms:** `GET /admin/dashboard.php` returns 404

**Solutions:**
- ✅ Verify files are uploaded to correct directory: `public_html/api/admin/`
- ✅ Check file permissions (should be 644)
- ✅ Verify Apache/Nginx is configured correctly
- ✅ Check `.htaccess` file exists and allows PHP execution
- ✅ Verify URL path: `https://yourdomain.com/api/admin/dashboard.php`

### Issue 2: 401 Unauthorized

**Symptoms:** All admin endpoints return 401

**Solutions:**
- ✅ Verify JWT token is included in `Authorization: Bearer {token}` header
- ✅ Check token hasn't expired (default: 10 hours)
- ✅ Verify user exists and `Role = 'admin'` (if role-based access is enabled)
- ✅ Test login endpoint: `POST /auth/login.php`
- ✅ Check `include/config.php` has correct JWT key

### Issue 3: 500 Internal Server Error

**Symptoms:** Endpoints return 500 error

**Solutions:**
- ✅ **Check PHP Error Logs:**
  - cPanel: Error Logs section
  - Path: Usually `/home/username/logs/error_log`
- ✅ **Verify Database Connection:**
  ```php
  // Test in test_connection.php
  echo mysqli_connect_error();
  ```
- ✅ **Check Database Credentials:**
  - Verify `include/config.php` has correct database name, username, password
  - Note: cPanel prefixes usernames
- ✅ **Verify Tables Exist:**
  ```sql
  SHOW TABLES;
  -- Should show: users, itr_detail, payment_info, etc.
  ```
- ✅ **Check PHP Version:** Should be PHP 7.4+ (check in cPanel → Select PHP Version)

### Issue 4: Empty Dashboard Data

**Symptoms:** Dashboard returns zeros for all statistics

**Solutions:**
- ✅ This is normal if database is empty (new deployment)
- ✅ Verify tables exist: `SHOW TABLES;`
- ✅ Check if `users` table has `Role` column: `DESCRIBE users;`
- ✅ Test with sample data:
  ```sql
  -- Check if tables have data
  SELECT COUNT(*) FROM users;
  SELECT COUNT(*) FROM itr_detail;
  SELECT COUNT(*) FROM payment_info;
  ```

### Issue 5: Database Connection Failed

**Symptoms:** `Connection failed: Access denied` or similar

**Solutions:**
- ✅ **Verify Database Credentials:**
  - Database name: Check in cPanel → MySQL Databases
  - Username: Usually prefixed with cPanel username
  - Password: Reset if needed in cPanel
  - Host: Usually `localhost` in cPanel
- ✅ **Check User Permissions:**
  ```sql
  -- In phpMyAdmin, verify user has ALL PRIVILEGES on database
  SHOW GRANTS FOR 'your_username'@'localhost';
  ```
- ✅ **Test Connection Manually:**
  ```bash
  mysql -u your_username -p your_database_name
  ```

### Issue 6: Missing Role Column

**Symptoms:** Admin APIs fail or return errors about `Role` column

**Solutions:**
- ✅ Verify admin tables setup ran successfully
- ✅ Check `users` table structure:
  ```sql
  DESCRIBE users;
  -- Should show Role and IsActive columns
  ```
- ✅ If missing, run:
  ```sql
  ALTER TABLE users 
  ADD COLUMN Role varchar(50) DEFAULT 'user' AFTER Password,
  ADD COLUMN IsActive tinyint(1) DEFAULT 1 AFTER Role;
  ```

### Issue 7: CORS Issues (Frontend)

**Symptoms:** Frontend can't call admin APIs, CORS errors

**Solutions:**
- ✅ **Check `.htaccess` in `api/` directory:**
  ```apache
  Header set Access-Control-Allow-Origin "*"
  Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
  Header set Access-Control-Allow-Headers "Content-Type, Authorization"
  ```
- ✅ **Verify mod_headers enabled:**
  - Check in cPanel or contact hosting support
- ✅ **Check PHP CORS headers in admin files:**
  ```php
  header("Access-Control-Allow-Origin: *");
  header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
  header("Access-Control-Allow-Headers: Content-Type, Authorization");
  ```

---

## 🔒 Security Checklist

Before going live, ensure:

### Database Security

- [ ] **Strong Database Password** - Use complex password (min 16 characters, mix of letters, numbers, symbols)
- [ ] **Limited Database User Privileges** - Grant only necessary privileges (SELECT, INSERT, UPDATE, DELETE)
- [ ] **Database Prefix** - cPanel automatically prefixes, but verify no default names
- [ ] **Regular Backups** - Set up automatic database backups in cPanel

### Application Security

- [ ] **Secure JWT Key** - Generate strong random key (32+ characters)
  ```bash
  openssl rand -base64 32
  ```
- [ ] **HTTPS Enabled** - Use SSL certificate (usually included in cPanel)
- [ ] **File Permissions** - Folders: 755, Files: 644
- [ ] **Protect Config File** - Ensure `include/config.php` is not publicly accessible
- [ ] **Remove Test Files** - Delete `test_connection.php`, `setup.php` after deployment

### Admin Panel Security

- [ ] **Strong Admin Password** - Use complex password for admin account
- [ ] **Role-Based Access** - Consider adding role checks in admin endpoints (only admin users)
- [ ] **Rate Limiting** - Consider adding rate limiting to prevent abuse
- [ ] **Activity Logging** - Log admin actions for audit trail
- [ ] **Token Expiry** - Verify JWT tokens expire properly (default: 10 hours)

### Server Security

- [ ] **PHP Version** - Use PHP 7.4+ or 8.0+ (avoid EOL versions)
- [ ] **Error Reporting** - Disable error display in production
  ```php
  // In config.php
  error_reporting(0);
  ini_set('display_errors', 0);
  ```
- [ ] **SQL Injection Protection** - Verify all queries use prepared statements or `mysqli_real_escape_string()`
- [ ] **XSS Protection** - Ensure output is escaped where needed

---

## 📊 Database Tables Summary

### Required for Admin Panel

| Table Name | Purpose | Critical Columns |
|------------|---------|------------------|
| `users` | User accounts | `UserId`, `Email`, `Role`, `IsActive` |
| `itr_detail` | ITR orders | `id`, `userId`, `orderId`, `status` |
| `payment_info` | Payment transactions | `id`, `order_id`, `user_id`, `payment_status`, `grand_total` |
| `itr_order_status` | Order status tracking | `id`, `order_id`, `status` |
| `itr_order_concerns` | User concerns | `id`, `order_id`, `user_id`, `status` |
| `itr_packages` | Package information | `id`, `packagename`, `price` |
| `personal_details` | User personal info | `id`, `UserId`, `PANNumber` |
| `document_details` | User documents | `id`, `UserId`, `fileName` |
| `services` | Services list | `id`, `Name` |

---

## 📝 Quick Reference Commands

### Database Verification

```sql
-- Check all tables exist
SHOW TABLES;

-- Verify users table structure
DESCRIBE users;

-- Check admin users
SELECT UserId, Email, Role, IsActive FROM users WHERE Role = 'admin';

-- Verify table counts
SELECT 
    (SELECT COUNT(*) FROM users) as users,
    (SELECT COUNT(*) FROM itr_detail) as orders,
    (SELECT COUNT(*) FROM payment_info) as payments;
```

### API Testing

```bash
# Login and save token
TOKEN=$(curl -s -X POST https://yourdomain.com/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password","platform":"web","version":"1.0"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Test dashboard
curl -X GET https://yourdomain.com/api/admin/dashboard.php \
  -H "Authorization: Bearer $TOKEN" | jq
```

---

## 📚 Additional Resources

- **API Documentation:** See `ADMIN_PANEL_CURL_COMMANDS.md` for all endpoint details
- **Setup Guide:** See `ADMIN_PANEL_SETUP.md` for local development setup
- **Implementation:** See `ADMIN_PANEL_IMPLEMENTATION.md` for implementation details
- **General Deployment:** See `CPANEL_DEPLOYMENT.md` for main application deployment

---

## ✅ Deployment Checklist

Use this checklist before marking deployment as complete:

### Pre-Deployment
- [ ] All admin PHP files ready in `admin/` directory
- [ ] Database setup scripts ready
- [ ] Server access credentials obtained
- [ ] Database credentials documented

### Database Setup
- [ ] Main database tables created (`users`, `itr_detail`, etc.)
- [ ] Payment tables created (`payment_info`)
- [ ] ITR status tables created (`itr_order_status`, `itr_order_concerns`)
- [ ] Admin role columns added to `users` table (`Role`, `IsActive`)
- [ ] Indexes created on `Role` and `IsActive` columns
- [ ] At least one admin user created

### File Upload
- [ ] All admin PHP files uploaded to server
- [ ] File permissions set correctly (644 for files, 755 for folders)
- [ ] `include/config.php` configured with database credentials
- [ ] JWT key set to secure random string

### Testing
- [ ] Database connection test passes
- [ ] Login endpoint works and returns token
- [ ] All admin endpoints accessible and return valid JSON
- [ ] Dashboard endpoint returns statistics
- [ ] No PHP errors in error logs

### Security
- [ ] Strong database password set
- [ ] Secure JWT key configured
- [ ] HTTPS enabled
- [ ] Error display disabled in production
- [ ] Test files removed or protected

---

## 🎉 Deployment Complete!

Once all checklist items are complete, your admin panel database APIs are ready for use!

**Next Steps:**
1. Integrate admin panel frontend with these APIs
2. Set up monitoring and error logging
3. Schedule regular database backups
4. Monitor server performance and optimize queries if needed

**API Base URL:**
```
https://yourdomain.com/api/admin/
```

**Example Endpoints:**
- Dashboard: `https://yourdomain.com/api/admin/dashboard.php`
- Users: `https://yourdomain.com/api/admin/users.php`
- Orders: `https://yourdomain.com/api/admin/orders.php`

For detailed API documentation and cURL examples, see `ADMIN_PANEL_CURL_COMMANDS.md`.

---

**Need Help?** Check the troubleshooting section above or review server error logs.
