# Payment System Deployment Guide

This guide will help you deploy the payment system to your production server (cPanel or similar).

---

## 📋 Pre-Deployment Checklist

- [ ] All payment files are tested locally
- [ ] Database backup created
- [ ] Server credentials ready (FTP/cPanel)
- [ ] Payment gateway credentials ready
- [ ] Webhook URL configured in payment gateway dashboard

---

## Step 1: Prepare Files for Upload

### Files to Upload

Create a list of all new files that need to be uploaded:

**New Payment Files:**
```
payment/
├── PaymentHelper.php
├── get_payment_info.php
├── initiate_payment.php
├── webhook.php
├── get_payment_status.php
├── get_payment_history.php
└── success.php
```

**Configuration Files:**
```
composer.json (if not already exists)
setup_payment_table.sql
setup_payment.php (optional - for server setup)
```

**Documentation (Optional):**
```
PAYMENT_SETUP.md
PAYMENT_API_TEST.md
PAYMENT_DEPLOYMENT.md
```

---

## Step 2: Upload Files to Server

### Option A: Using cPanel File Manager

1. **Login to cPanel**
   - Go to: `https://yourdomain.com/cpanel`
   - Enter your credentials

2. **Navigate to File Manager**
   - Click **"File Manager"** icon
   - Navigate to your API directory (usually `public_html/api` or `public_html/your-api-folder`)

3. **Create Payment Directory**
   - Right-click in the file manager
   - Select **"Create Folder"**
   - Name it: `payment`

4. **Upload Files**
   - Navigate to the `payment` folder
   - Click **"Upload"** button
   - Select all files from your local `payment/` folder:
     - `PaymentHelper.php`
     - `get_payment_info.php`
     - `initiate_payment.php`
     - `webhook.php`
     - `get_payment_status.php`
     - `get_payment_history.php`
     - `success.php`
   - Wait for upload to complete

5. **Upload Root Files**
   - Go back to main API directory
   - Upload `composer.json` (if not exists)
   - Upload `setup_payment_table.sql` (for reference)

6. **Set Permissions** (Usually Not Required)
   - **Folders:** Should be **755** (read, write, execute for owner; read, execute for others)
   - **PHP Files:** Should be **644** (read, write for owner; read for others)
   - **Note:** Most servers set correct permissions automatically. Only change if you get permission errors.
   - **When to change:** Only if files show `000`, `600`, or `777` permissions
   - **Your payment folder at 755 is CORRECT - no changes needed!**

### Option B: Using FTP Client (FileZilla, WinSCP, etc.)

1. **Connect via FTP**
   ```
   Host: ftp.yourdomain.com (or your server IP)
   Username: Your cPanel username
   Password: Your cPanel password
   Port: 21 (or 22 for SFTP)
   ```

2. **Navigate to API Directory**
   - Go to `/public_html/api/` (or your API path)

3. **Create Payment Folder**
   - Create new folder: `payment`

4. **Upload All Files**
   - Upload all files from local `payment/` folder to server `payment/` folder
   - Upload `composer.json` to root API directory
   - Maintain folder structure

5. **Set Permissions**
   - Folders: **755**
   - PHP files: **644**

---

## Step 3: Database Setup on Server

### Option A: Using phpMyAdmin (Recommended)

1. **Open phpMyAdmin**
   - Go to: `https://yourdomain.com/phpmyadmin`
   - Or access via cPanel → phpMyAdmin

2. **Select Your Database**
   - Click on your database name (e.g., `yourdb_name`)

3. **Run SQL Script**
   - Click on **"SQL"** tab
   - Open `setup_payment_table.sql` file locally
   - **IMPORTANT:** Before pasting, check the database name in the SQL file
   - If SQL file has `USE itr_services;`, change it to your actual database name, OR
   - Remove the `USE` statement and make sure you've selected the correct database
   - Copy all SQL code
   - Paste into SQL tab
   - Click **"Go"** button

4. **Verify Tables Created**
   - Check if you see:
     - `payment_info` table
     - `payment_additional_fees` table
   - Click on `payment_additional_fees` table
   - Verify it has 2 rows (E-Filing Fee and E-Verification Fee)

### Option B: Using Setup Script (If Uploaded)

1. **Access Setup Script**
   - Go to: `https://yourdomain.com/api/setup_payment.php`
   - Click **"Create Payment Tables"** button
   - Verify success message

2. **Delete Setup Script After Use** (Security)
   - Remove `setup_payment.php` from server after tables are created

### Option C: Using MySQL Command Line (If SSH Access)

```bash
# Connect to server via SSH
ssh username@yourdomain.com

# Navigate to your API directory
cd /home/username/public_html/api

# Run SQL file
mysql -u database_user -p database_name < setup_payment_table.sql
```

---

## Step 4: Install Composer Dependencies

**📖 Detailed Instructions:** See `SSH_COMPOSER_INSTALL_GUIDE.md` for complete step-by-step guide.

### Quick Overview:

You have 3 options (choose based on your hosting setup):

### Option A: Via cPanel Terminal (Easiest - If Available)

1. **Login to cPanel** → Look for **"Terminal"** icon
2. **Navigate to API directory:**
   ```bash
   cd public_html/api
   ```
3. **Check Composer:**
   ```bash
   composer --version
   ```
4. **Install Dependencies:**
   ```bash
   composer install --no-dev --optimize-autoloader
   ```
5. **Verify:**
   ```bash
   ls -la vendor/
   ```

### Option B: Via SSH Client (PuTTY/Terminal)

**For Windows:**
- Download PuTTY from https://www.putty.org/
- Connect using: `ssh username@yourdomain.com`
- Follow steps in Option A above

**For Mac/Linux:**
- Open Terminal app
- Connect: `ssh username@yourdomain.com`
- Follow steps in Option A above

### Option C: Manual Upload (If SSH Not Available)

1. **Install Composer on Your Local Computer**
   - Download from: https://getcomposer.org/download/

2. **Install Dependencies Locally**
   ```bash
   cd /Applications/XAMPP/xamppfiles/htdocs/api
   composer install --no-dev --optimize-autoloader
   ```

3. **Upload `vendor/` Folder to Server**
   - Via cPanel File Manager or FTP
   - Upload entire `vendor/` folder to `public_html/api/`

**📖 For detailed instructions with screenshots, see: `SSH_COMPOSER_INSTALL_GUIDE.md`**

---

## Step 5: Update Configuration

### Update Database Configuration

1. **Check Server Database Config**
   - Open `include/config.php` on server
   - Verify database credentials match your server database:
     ```php
     $servername = "localhost";
     $username = "your_db_user";
     $password = "your_db_password";
     $database = "your_database_name";
     ```

2. **Add Payment Gateway Config (Optional)**
   - Add to `include/config.php`:
     ```php
     // Payment Gateway Configuration
     $payment_gateway_merchant_id = "RgSGKJiDNpMKj7";
     $payment_gateway_key = "YOUR_MERCHANT_KEY";
     $payment_gateway_website = "DEFAULT"; // Use "DEFAULT" for production
     $payment_gateway_industry_type = "Retail";
     $payment_gateway_channel_id = "WEB";
     ```

---

## Step 6: Configure Payment Gateway Webhook

### For Paytm

1. **Login to Paytm Dashboard**
   - Go to: https://dashboard.paytm.com/

2. **Set Webhook URL**
   - Navigate to: **Settings** → **Webhook**
   - Add webhook URL: `https://yourdomain.com/api/payment/webhook.php`
   - Save settings

### For Razorpay

1. **Login to Razorpay Dashboard**
   - Go to: https://dashboard.razorpay.com/

2. **Set Webhook URL**
   - Navigate to: **Settings** → **Webhooks**
   - Add webhook URL: `https://yourdomain.com/api/payment/webhook.php`
   - Select events: `payment.captured`, `payment.failed`
   - Save settings

### For Other Gateways

- Follow your payment gateway's documentation
- Set webhook/callback URL to: `https://yourdomain.com/api/payment/webhook.php`

---

## Step 7: Test on Server

### Test 1: Check File Access

```bash
# Test if files are accessible
curl https://yourdomain.com/api/payment/get_payment_info.php
```

Expected: Should return error (needs authentication), but file should be accessible.

### Test 2: Test Login

```bash
curl -X POST https://yourdomain.com/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "your_test_email@example.com",
    "password": "your_password",
    "platform": "web",
    "version": "1.0"
  }'
```

### Test 3: Test Payment Info API

```bash
# Get token from login response first
curl -X GET "https://yourdomain.com/api/payment/get_payment_info.php?packageId=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

### Test 4: Test Webhook (If Gateway Supports)

Some gateways allow you to test webhook URLs. Use their test feature to verify webhook is receiving data.

---

## Step 8: Security Checklist

- [ ] **Remove Setup Scripts**
  - Delete `setup_payment.php` from server
  - Delete `setup_payment_table.sql` from server (or keep in secure location)

- [ ] **Verify Permissions (Usually Already Correct)**
  - Folders should be **755** (your payment folder is already 755 ✓)
  - PHP files should be **644** (usually set automatically)
  - **Note:** Most cPanel servers set permissions correctly by default. Only change if you get permission errors.

- [ ] **Protect Sensitive Files**
  - Ensure `include/config.php` is not publicly accessible
  - Add `.htaccess` if needed:
    ```apache
    <Files "config.php">
        Order allow,deny
        Deny from all
    </Files>
    ```

- [ ] **Enable HTTPS**
  - Ensure your site uses HTTPS
  - Update webhook URLs to use HTTPS

- [ ] **Verify Webhook Security**
  - Implement webhook signature verification in `webhook.php`
  - Validate requests come from payment gateway

---

## Step 9: Post-Deployment Verification

### Database Verification

1. **Check Tables Exist**
   ```sql
   SHOW TABLES LIKE 'payment%';
   ```
   Should show: `payment_info` and `payment_additional_fees`

2. **Check Additional Fees**
   ```sql
   SELECT * FROM payment_additional_fees WHERE is_active = 1;
   ```
   Should show 2 rows (E-Filing Fee, E-Verification Fee)

3. **Check Foreign Keys**
   ```sql
   SELECT 
     TABLE_NAME,
     COLUMN_NAME,
     CONSTRAINT_NAME,
     REFERENCED_TABLE_NAME,
     REFERENCED_COLUMN_NAME
   FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
   WHERE TABLE_SCHEMA = 'your_database_name'
     AND TABLE_NAME = 'payment_info'
     AND REFERENCED_TABLE_NAME IS NOT NULL;
   ```

### API Verification

1. **Test All Endpoints**
   - Use Postman or curl to test all payment APIs
   - Verify responses match expected format

2. **Test Error Handling**
   - Test with invalid tokens
   - Test with missing parameters
   - Verify proper error responses

---

## Step 10: Monitoring & Maintenance

### Enable Error Logging

1. **Check Error Logs**
   - Monitor server error logs
   - Check PHP error logs
   - Monitor payment webhook logs

2. **Add Logging to Webhook** (Optional)
   - Add logging in `webhook.php` to track all webhook calls
   - Log to file or database

### Regular Checks

- [ ] Monitor payment success/failure rates
- [ ] Check webhook delivery status
- [ ] Review error logs weekly
- [ ] Verify database backups include payment tables

---

## Troubleshooting

### Issue: Tables Not Created

**Solution:**
- Check database name matches
- Verify user has CREATE TABLE permissions
- Check SQL syntax errors in phpMyAdmin

### Issue: Composer Not Found

**Solution:**
- Install Composer on server
- Or upload vendor folder manually
- Or use cPanel's Composer installer

### Issue: Webhook Not Receiving Data

**Solution:**
- Verify webhook URL is correct
- Check if server allows incoming POST requests
- Verify HTTPS certificate is valid
- Check server firewall settings
- Test webhook URL accessibility

### Issue: 500 Internal Server Error

**Solution:**
- Check PHP error logs
- Verify file permissions
- Check database connection
- Verify all required files are uploaded
- Check PHP version (needs 7.4+)

### Issue: Foreign Key Constraint Errors

**Solution:**
- Verify `users` table exists
- Verify `itr_packages` table exists
- Check if foreign key columns match
- Temporarily disable foreign key checks if needed:
  ```sql
  SET FOREIGN_KEY_CHECKS = 0;
  -- Run your SQL
  SET FOREIGN_KEY_CHECKS = 1;
  ```

---

## Rollback Plan

If something goes wrong:

1. **Restore Database Backup**
   ```sql
   -- Drop payment tables
   DROP TABLE IF EXISTS payment_info;
   DROP TABLE IF EXISTS payment_additional_fees;
   ```

2. **Remove Payment Files**
   - Delete `payment/` folder from server
   - Remove `composer.json` if it was new

3. **Restore Previous Version**
   - Restore from backup
   - Or revert uploaded files

---

## Quick Deployment Checklist

- [ ] Upload all payment files to server
- [ ] Create payment tables in database
- [ ] Install Composer dependencies
- [ ] Update configuration files
- [ ] Configure payment gateway webhook
- [ ] Test all APIs on server
- [ ] Remove setup scripts
- [ ] Set proper file permissions
- [ ] Enable HTTPS
- [ ] Verify webhook is working
- [ ] Monitor error logs

---

## Support

If you encounter issues:

1. Check server error logs
2. Verify database connection
3. Test APIs individually
4. Check payment gateway dashboard for webhook status
5. Verify all files are uploaded correctly

---

## Notes

- Always backup database before making changes
- Test on staging server first if available
- Keep local and server versions in sync
- Document any server-specific configurations
- Update webhook URLs in payment gateway dashboard after deployment

