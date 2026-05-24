# cPanel Deployment Guide - ITR API

This guide will help you deploy your ITR API project to cPanel hosting.

## Prerequisites

- cPanel hosting account with access
- FTP credentials (or cPanel File Manager access)
- Database creation privileges in cPanel
- phpMyAdmin access

---

## Step 1: Prepare Files for Upload

### 1.1 Create a ZIP file (Optional but Recommended)

1. Select all project files (except `uploads` folder if it has test data)
2. Create a ZIP archive
3. Name it: `itr_api.zip`

**Note:** You can upload the `uploads` folder separately or create it on the server.

---

## Step 2: Upload Files to cPanel

### Option A: Using cPanel File Manager (Recommended)

1. **Login to cPanel**
   - Go to: `https://yourdomain.com/cpanel`
   - Enter your username and password

2. **Navigate to File Manager**
   - Find and click **"File Manager"** icon
   - Navigate to `public_html` folder (or your domain's root directory)
   - If you want the API in a subfolder, create it: `public_html/api`

3. **Upload Files**
   - Click **"Upload"** button at the top
   - Select your ZIP file OR individual files
   - Wait for upload to complete
   - If you uploaded a ZIP, right-click it and select **"Extract"**
   - Delete the ZIP file after extraction

4. **Create uploads folder structure**
   - Create folder: `uploads`
   - Set permissions: **755** (right-click → Change Permissions)

### Option B: Using FTP Client (FileZilla, WinSCP, etc.)

1. **Connect via FTP**
   - Host: `ftp.yourdomain.com` or your server IP
   - Username: Your cPanel username
   - Password: Your cPanel password
   - Port: 21 (or 22 for SFTP)

2. **Navigate to public_html**
   - Go to `/public_html/` directory
   - Create `api` folder if needed

3. **Upload all files**
   - Upload all files maintaining the folder structure
   - Ensure `uploads` folder is created with **755** permissions

---

## Step 3: Create Database in cPanel

1. **Open MySQL Databases**
   - In cPanel, find and click **"MySQL Databases"** icon

2. **Create Database**
   - In **"Create New Database"** section:
     - Enter database name: `itr_services` (or your preferred name)
     - Click **"Create Database"**
   - **Note:** cPanel will add a prefix (usually your username), so the full name will be like: `username_itr_services`

3. **Create Database User**
   - Scroll down to **"Add New User"** section:
     - Username: `itr_services` (or your preferred name)
     - Password: Create a strong password (save it!)
     - Click **"Create User"**
   - **Note:** Full username will be: `username_itr_services`

4. **Add User to Database**
   - Scroll to **"Add User To Database"** section:
     - Select the user you just created
     - Select the database you created
     - Click **"Add"**
   - Check **"ALL PRIVILEGES"** checkbox
   - Click **"Make Changes"**

5. **Save Database Credentials**
   - Write down:
     - Database Name: `username_itr_services`
     - Database User: `username_itr_services`
     - Database Password: (the one you created)
     - Database Host: Usually `localhost` (check cPanel for exact hostname)

---

## Step 4: Import Database Schema

1. **Open phpMyAdmin**
   - In cPanel, find and click **"phpMyAdmin"** icon

2. **Select Your Database**
   - Click on your database name in the left sidebar (e.g., `username_itr_services`)

3. **Import SQL File**
   - Click on **"Import"** tab at the top
   - Click **"Choose File"** button
   - Select `setup_database.sql` from your local computer
   - **IMPORTANT:** Before clicking "Go", you need to modify the SQL file:
     - Remove or comment out the `CREATE DATABASE` line (database already exists)
     - Remove or comment out the `CREATE USER` and `GRANT` lines (user already created)
     - Keep only the `USE` statement and table creation statements

4. **Modified SQL for cPanel** (copy this version):
   ```sql
   -- Use the database (already created in cPanel)
   USE `username_itr_services`;  -- Replace with your actual database name
   
   -- Remove these lines (already done in cPanel):
   -- CREATE DATABASE IF NOT EXISTS `itr_services`...
   -- CREATE USER IF NOT EXISTS...
   -- GRANT ALL PRIVILEGES...
   -- FLUSH PRIVILEGES;
   
   -- Keep all the CREATE TABLE statements below...
   ```

5. **Click "Go"** to execute

---

## Step 5: Update Configuration File

1. **Open config.php in File Manager**
   - Navigate to: `public_html/api/include/config.php`
   - Right-click → **"Edit"**

2. **Update Database Credentials**
   ```php
   <?php
   $servername = "localhost";  // Usually 'localhost' in cPanel
   $username = "username_itr_services";  // Your cPanel database username
   $password = "your_database_password";  // The password you created
   $database = "username_itr_services";  // Your cPanel database name
   
   // Create connection
   $conn = mysqli_connect($servername, $username, $password, $database);
   
   // Check connection
   if (!$conn) {
       die("Connection failed: " . mysqli_connect_error());
   }
   
   $key = 'testitr_key';  // Change this to a secure random string for production
   $expire = 36000;
   ?>
   ```

3. **Save the file**

---

## Step 6: Set File Permissions

Set proper permissions for security:

1. **In File Manager**, right-click on each and set permissions:

   - **Folders:** `755`
     - `api/`
     - `api/uploads/`
     - `api/include/`
     - `api/auth/`
     - `api/itrdetails/`
     - `api/package/`
     - `api/phpjwt/`

   - **PHP Files:** `644`
     - All `.php` files

   - **uploads folder:** `755` (must be writable)
     - This is critical for file uploads to work

---

## Step 7: Update .htaccess (Optional but Recommended)

Create or update `.htaccess` file in `public_html/api/`:

```apache
# Enable CORS (if needed)
<IfModule mod_headers.c>
    Header set Access-Control-Allow-Origin "*"
    Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
    Header set Access-Control-Allow-Headers "Content-Type, Authorization"
</IfModule>

# PHP Settings
<IfModule mod_php.c>
    php_value upload_max_filesize 10M
    php_value post_max_size 10M
    php_value max_execution_time 300
    php_value max_input_time 300
</IfModule>

# Security: Hide sensitive files
<FilesMatch "^(config\.php|\.htaccess|error_log)$">
    Order allow,deny
    Deny from all
</FilesMatch>
```

---

## Step 8: Test Your Deployment

### 8.1 Test Database Connection

1. **Access test file:**
   - URL: `https://yourdomain.com/api/test_connection.php`
   - Should show: ✅ Database connected successfully!

### 8.2 Test API Endpoints

Use Postman or browser to test:

1. **Signup:**
   ```
   POST https://yourdomain.com/api/auth/signup.php
   Content-Type: application/json
   
   {
     "email": "test@example.com",
     "password": "test123",
     "name": "Test User",
     "mobile": "1234567890"
   }
   ```

2. **Login:**
   ```
   POST https://yourdomain.com/api/auth/login.php
   Content-Type: application/json
   
   {
     "email": "test@example.com",
     "password": "test123"
   }
   ```

---

## Step 9: Security Checklist

Before going live:

- [ ] Change JWT key in `config.php` to a strong random string
- [ ] Use strong database password
- [ ] Set proper file permissions (755 for folders, 644 for files)
- [ ] Enable HTTPS/SSL certificate
- [ ] Remove or protect test files (`test_connection.php`, `setup.php`)
- [ ] Review and update CORS settings if needed
- [ ] Set up regular database backups
- [ ] Monitor error logs

---

## Troubleshooting

### Database Connection Error

- **Check:** Database credentials in `config.php`
- **Check:** Database host (might be `localhost` or `127.0.0.1`)
- **Check:** User has proper permissions on database

### File Upload Not Working

- **Check:** `uploads` folder permissions (must be 755 or 777)
- **Check:** PHP `upload_max_filesize` and `post_max_size` settings
- **Check:** Disk space on server

### 500 Internal Server Error

- **Check:** PHP error logs in cPanel
- **Check:** File permissions
- **Check:** PHP version (should be 7.4+)
- **Check:** Missing PHP extensions (mysqli, json)

### CORS Issues

- **Check:** `.htaccess` file is present
- **Check:** Headers are set correctly
- **Check:** Server allows mod_headers

---

## Quick Reference: cPanel Database Info

After creating database in cPanel, you'll see:

- **Database Name:** `cpaneluser_itr_services`
- **Database User:** `cpaneluser_itr_services`
- **Database Host:** Usually `localhost` (check in cPanel)
- **Full Connection String:** `cpaneluser_itr_services:password@localhost`

---

## Support

If you encounter issues:

1. Check cPanel error logs
2. Check PHP error logs
3. Enable error reporting temporarily:
   ```php
   error_reporting(E_ALL);
   ini_set('display_errors', 1);
   ```
4. Test database connection separately
5. Verify all files uploaded correctly

---

## Notes

- **Database Prefix:** cPanel automatically prefixes database and user names with your cPanel username
- **File Paths:** Use relative paths in your code (already done)
- **PHP Version:** Ensure PHP 7.4+ is selected in cPanel
- **Backups:** Set up automatic backups for database and files

---

**Deployment Complete!** 🎉

Your API should now be accessible at: `https://yourdomain.com/api/`

