# 🚀 Local Development Setup Guide

Complete guide to run the ITR API project on your local machine.

---

## 📋 Prerequisites

Before starting, ensure you have:

- ✅ **XAMPP** (or MAMP/WAMP/LAMP) installed
- ✅ **PHP 7.4+** (comes with XAMPP)
- ✅ **MySQL 5.7+** (comes with XAMPP)
- ✅ **Postman** (optional, for API testing)
- ✅ **Text Editor** (VS Code, PHPStorm, etc.)

---

## 🔧 Step 1: Install XAMPP

### Download & Install
1. Download XAMPP from: https://www.apachefriends.org/
2. Install XAMPP (default location: `C:\xampp` on Windows, `/Applications/XAMPP` on Mac)
3. Make sure Apache and MySQL are available

---

## 📁 Step 2: Setup Project Files

### Option A: Clone from Git (if using version control)
```bash
cd /Applications/XAMPP/xamppfiles/htdocs
git clone <your-repo-url> api
cd api
```

### Option B: Copy Project Files
1. Copy your project folder to:
   - **Windows**: `C:\xampp\htdocs\api`
   - **Mac**: `/Applications/XAMPP/xamppfiles/htdocs/api`
   - **Linux**: `/var/www/html/api` or `/opt/lampp/htdocs/api`

---

## ⚙️ Step 3: Configure Local Database

### 3.1 Update config.php for Local Development

Edit `include/config.php` with local MySQL credentials:

```php
<?php
$servername = "localhost";
$username = "root";           // Default XAMPP username
$password = "";                // Default XAMPP password (empty)
$database = "itr_services";   // Local database name

// Create connection
$conn = mysqli_connect($servername, $username, $password, $database);

// Check connection
if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}

$key = 'testitr_key';
$expire = 36000;
?>
```

**Note:** If you're using the example config template:
```bash
cp include/config.php.example include/config.php
# Then edit config.php with your local credentials
```

---

## 🗄️ Step 4: Setup Database

### Method 1: Using Setup Script (Easiest) ⭐

1. **Start XAMPP Services:**
   - Open XAMPP Control Panel
   - Click "Start" for **Apache**
   - Click "Start" for **MySQL**

2. **Run Setup Script:**
   - Open browser: `http://localhost/api/setup.php`
   - Enter MySQL credentials:
     - Username: `root`
     - Password: (leave empty for default XAMPP)
   - Click **"Setup Database"** button
   - Wait for success message ✅

### Method 2: Using phpMyAdmin

1. **Start XAMPP Services** (Apache + MySQL)

2. **Open phpMyAdmin:**
   - Go to: `http://localhost/phpmyadmin`

3. **Create Database:**
   - Click "New" in left sidebar
   - Database name: `itr_services`
   - Collation: `utf8mb4_unicode_ci`
   - Click "Create"

4. **Import SQL:**
   - Select `itr_services` database
   - Click "Import" tab
   - Choose file: `setup_database.sql`
   - Click "Go"

### Method 3: Using MySQL Command Line

```bash
# Navigate to project directory
cd /Applications/XAMPP/xamppfiles/htdocs/api

# Run SQL file (Windows)
C:\xampp\mysql\bin\mysql.exe -u root < setup_database.sql

# Run SQL file (Mac/Linux)
/Applications/XAMPP/xamppfiles/bin/mysql -u root < setup_database.sql
```

---

## ✅ Step 5: Verify Setup

### Test Database Connection

1. Open browser: `http://localhost/api/test_connection.php`
2. You should see: **✅ Database connected successfully!**

### Check Database Tables

1. Open phpMyAdmin: `http://localhost/phpmyadmin`
2. Select `itr_services` database
3. Verify these tables exist:
   - ✅ `users`
   - ✅ `services`
   - ✅ `personal_details`
   - ✅ `document_details`
   - ✅ `itr_detail`
   - ✅ `itr_source`
   - ✅ `itr_packages`

---

## 🧪 Step 6: Test API Endpoints

### Using Postman (Recommended)

1. **Import Collection:**
   - Open Postman
   - Click "Import"
   - Select `ITR_API_Postman_Collection.json`
   - Collection imported! ✅

2. **Set Base URL:**
   - Collection variable: `base_url` = `http://localhost/api`

3. **Test Signup:**
   - Request: `POST /auth/signup.php`
   - Body:
     ```json
     {
       "email": "test@example.com",
       "password": "test123",
       "name": "Test User",
       "mobile": "9876543210"
     }
     ```
   - Click "Send"
   - Should return success with status 201

4. **Test Login:**
   - Request: `POST /auth/login.php`
   - Body:
     ```json
     {
       "email": "test@example.com",
       "password": "test123"
     }
     ```
   - Click "Send"
   - Should return token ✅

### Using cURL (Command Line)

**Signup:**
```bash
curl -X POST http://localhost/api/auth/signup.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123",
    "name": "Test User",
    "mobile": "9876543210"
  }'
```

**Login:**
```bash
curl -X POST http://localhost/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123"
  }'
```

### Using Browser (GET requests only)

- Get Packages: `http://localhost/api/package/getPackages.php`
- Test Connection: `http://localhost/api/test_connection.php`

---

## 📝 Step 7: Create Uploads Directory

Ensure uploads folder has write permissions:

```bash
# Mac/Linux
chmod 755 uploads/

# Windows (usually already has permissions)
```

---

## 🔍 Troubleshooting

### Issue: "Connection failed" Error

**Solution:**
1. Check MySQL is running in XAMPP
2. Verify credentials in `include/config.php`
3. Check database exists: `http://localhost/phpmyadmin`
4. Try default XAMPP credentials: `root` / (empty password)

### Issue: "Access denied" Error

**Solution:**
1. Check MySQL username/password in `config.php`
2. For XAMPP default: username=`root`, password=empty
3. If you changed MySQL root password, update `config.php`

### Issue: Tables Not Created

**Solution:**
1. Check database exists in phpMyAdmin
2. Re-run `setup_database.sql` in phpMyAdmin
3. Check for SQL errors in phpMyAdmin

### Issue: File Upload Not Working

**Solution:**
1. Check `uploads/` folder exists
2. Set folder permissions: `chmod 755 uploads/`
3. Check PHP `upload_max_filesize` in `php.ini`

### Issue: 404 Not Found

**Solution:**
1. Verify project is in correct location:
   - Windows: `C:\xampp\htdocs\api`
   - Mac: `/Applications/XAMPP/xamppfiles/htdocs/api`
2. Check Apache is running
3. Try: `http://localhost/api/index.php`

### Issue: CORS Errors

**Solution:**
- CORS headers are already set in PHP files
- If testing from browser, use Postman or enable CORS in browser
- For production, update CORS settings in PHP files

---

## 📚 API Endpoints Reference

### Base URL
```
http://localhost/api
```

### Authentication
- `POST /auth/signup.php` - User registration
- `POST /auth/login.php` - User login
- `POST /auth/forget_password.php` - Reset password

### Personal Details
- `POST /itrdetails/personal_details.php` - Add/Update personal info
- `GET /itrdetails/get_personal_detail.php?PanNumber=XXXXX` - Get personal info

### Documents
- `POST /itrdetails/save_documents.php` - Save document metadata
- `GET /itrdetails/get_documents.php?PanNumber=XXXXX` - Get documents
- `POST /itrdetails/delete_document.php` - Delete document

### ITR
- `GET /get_itrbyuser.php?userId=1` - Get ITR by user
- `GET /get_itrbyitrid.php?itrId=1` - Get ITR by ID

### Packages
- `GET /package/getPackages.php` - Get all packages

### Services
- `POST /add_services.php` - Add service

---

## 🎯 Quick Test Checklist

- [ ] XAMPP Apache is running
- [ ] XAMPP MySQL is running
- [ ] Database `itr_services` exists
- [ ] All 7 tables created
- [ ] `config.php` has correct local credentials
- [ ] `test_connection.php` shows success
- [ ] Can signup new user
- [ ] Can login and get token
- [ ] `uploads/` folder has write permissions

---

## 💡 Development Tips

1. **Enable Error Display (Development Only):**
   Add to top of PHP files:
   ```php
   error_reporting(E_ALL);
   ini_set('display_errors', 1);
   ```

2. **Check PHP Version:**
   ```bash
   php -v
   ```
   Should be 7.4 or higher

3. **Check MySQL Version:**
   ```bash
   mysql --version
   ```

4. **View PHP Errors:**
   - Check `error_log` files in project
   - Check XAMPP error logs

5. **Database Management:**
   - Use phpMyAdmin: `http://localhost/phpmyadmin`
   - Or MySQL Workbench

---

## 🚀 You're Ready!

Your local development environment is now set up! 

- **API Base URL**: `http://localhost/api`
- **phpMyAdmin**: `http://localhost/phpmyadmin`
- **Test Connection**: `http://localhost/api/test_connection.php`

Start developing! 🎉

---

## 📞 Need Help?

- Check `RUN.md` for detailed API documentation
- Check `QUICK_START.md` for quick reference
- Review error logs in project directory

