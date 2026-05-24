# Detailed Guide: Installing Composer Dependencies via SSH

This guide explains how to access SSH and install Composer dependencies for the payment system.

---

## What is SSH?

SSH (Secure Shell) is a secure way to access your server's command line remotely. Think of it like a remote terminal/command prompt for your server.

---

## Step 1: Check if SSH is Available

### Option A: Check in cPanel

1. **Login to cPanel**
   - Go to: `https://yourdomain.com/cpanel`
   - Login with your credentials

2. **Look for "Terminal" or "SSH Access"**
   - Some cPanel hosts have a built-in Terminal/SSH option
   - Look for icons like: "Terminal", "SSH Access", or "Shell Access"
   - If you see it, click on it - you can skip to Step 3

3. **Check SSH Access Status**
   - Look for "SSH Access" section in cPanel
   - It will show if SSH is enabled for your account
   - If disabled, you may need to enable it or contact your hosting provider

### Option B: Check with Your Hosting Provider

- Some shared hosting providers don't allow SSH access
- Contact your hosting support to enable SSH
- Or ask if they have an alternative method

---

## Step 2: Choose Your Method

You have 3 options:

1. **cPanel Terminal** (Easiest - if available)
2. **SSH Client** (PuTTY for Windows, Terminal for Mac/Linux)
3. **Alternative: Upload vendor folder manually** (If SSH not available)

---

## Method 1: Using cPanel Terminal (Easiest)

### Steps:

1. **Login to cPanel**
   ```
   https://yourdomain.com/cpanel
   ```

2. **Open Terminal**
   - Look for "Terminal" icon in cPanel
   - Click on it
   - A terminal window will open in your browser

3. **Navigate to Your API Directory**
   ```bash
   cd public_html/api
   ```
   Or if your API is in a different location:
   ```bash
   cd public_html/your-api-folder
   ```

4. **Check if Composer is Installed**
   ```bash
   composer --version
   ```
   - If you see a version number (like `Composer version 2.x.x`), Composer is installed ✓
   - If you see "command not found", Composer is not installed - see "Installing Composer" section below

5. **Install Dependencies**
   ```bash
   composer install --no-dev --optimize-autoloader
   ```
   
   This command will:
   - Download payment gateway SDKs (Paytm, Razorpay)
   - Create `vendor/` folder
   - Install all required packages

6. **Verify Installation**
   ```bash
   ls -la vendor/
   ```
   You should see folders like:
   - `vendor/paytm/`
   - `vendor/razorpay/`
   - `vendor/composer/`

**Done!** You can close the terminal and proceed with testing.

---

## Method 2: Using SSH Client (PuTTY for Windows)

### For Windows Users:

#### Step 1: Download PuTTY

1. **Download PuTTY**
   - Go to: https://www.putty.org/
   - Download the installer (putty-64bit-x.x.x-installer.msi)
   - Install it (just click Next, Next, Install)

#### Step 2: Get Your SSH Details from cPanel

1. **Login to cPanel**
2. **Find SSH Information**
   - Look for "SSH Access" section
   - Note down:
     - **Host/Server:** Usually `yourdomain.com` or `server.yourdomain.com`
     - **Port:** Usually `22` (or check with your host)
     - **Username:** Your cPanel username
     - **Password:** Your cPanel password (or SSH key if configured)

#### Step 3: Connect via PuTTY

1. **Open PuTTY**
   - Search for "PuTTY" in Windows Start Menu
   - Click on PuTTY application

2. **Enter Connection Details**
   - **Host Name (or IP address):** Enter your server hostname
   - **Port:** Enter `22` (or the port provided by your host)
   - **Connection type:** Select "SSH"
   - Click **"Open"**

3. **First Time Connection**
   - A security warning may appear - Click **"Yes"**

4. **Login**
   - Enter your cPanel username
   - Press Enter
   - Enter your password (you won't see characters as you type - this is normal)
   - Press Enter

5. **You're Connected!**
   - You should see a command prompt like: `[username@server ~]$`

#### Step 4: Navigate and Install

1. **Navigate to API Directory**
   ```bash
   cd public_html/api
   ```

2. **Check Composer**
   ```bash
   composer --version
   ```

3. **Install Dependencies**
   ```bash
   composer install --no-dev --optimize-autoloader
   ```

4. **Verify**
   ```bash
   ls -la vendor/
   ```

5. **Exit PuTTY**
   ```bash
   exit
   ```

---

## Method 2: Using SSH Client (Terminal for Mac/Linux)

### For Mac/Linux Users:

#### Step 1: Open Terminal

- **Mac:** 
  - Press `Cmd + Space` to open Spotlight
  - Type "Terminal"
  - Press Enter

- **Linux:**
  - Press `Ctrl + Alt + T`
  - Or search for "Terminal" in applications

#### Step 2: Connect via SSH

```bash
ssh username@yourdomain.com
```

Replace:
- `username` with your cPanel username
- `yourdomain.com` with your server hostname

**Example:**
```bash
ssh john@example.com
```

#### Step 3: Enter Password

- Enter your cPanel password when prompted
- You won't see characters as you type (this is normal)
- Press Enter

#### Step 4: Navigate and Install

```bash
# Navigate to API directory
cd public_html/api

# Check Composer
composer --version

# Install dependencies
composer install --no-dev --optimize-autoloader

# Verify installation
ls -la vendor/

# Exit SSH
exit
```

---

## Method 3: Install Composer (If Not Already Installed)

If you see "command not found" when running `composer --version`:

### Option A: Install Composer Globally (Recommended)

1. **Download Composer Installer**
   ```bash
   php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
   ```

2. **Run Installer**
   ```bash
   php composer-setup.php
   ```

3. **Move to Global Location**
   ```bash
   sudo mv composer.phar /usr/local/bin/composer
   ```

4. **Verify Installation**
   ```bash
   composer --version
   ```

### Option B: Use Composer.phar (If no sudo access)

1. **Download Composer**
   ```bash
   php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
   php composer-setup.php
   php -r "unlink('composer-setup.php');"
   ```

2. **Use Composer.phar**
   ```bash
   php composer.phar install --no-dev --optimize-autoloader
   ```

---

## Method 4: Manual Upload (If SSH Not Available)

If you cannot access SSH, you can install Composer locally and upload the vendor folder:

### Step 1: Install Composer Locally (On Your Computer)

**For Windows:**
1. Download Composer-Setup.exe from: https://getcomposer.org/download/
2. Run the installer
3. Follow the installation wizard

**For Mac:**
```bash
# Using Homebrew (if installed)
brew install composer

# Or download manually from getcomposer.org
```

**For Linux:**
```bash
sudo apt-get install composer  # Ubuntu/Debian
# or
sudo yum install composer      # CentOS/RHEL
```

### Step 2: Install Dependencies Locally

1. **Open Terminal/Command Prompt on Your Computer**
2. **Navigate to Your Local API Folder**
   ```bash
   cd /Applications/XAMPP/xamppfiles/htdocs/api
   # or on Windows:
   cd C:\xampp\htdocs\api
   ```

3. **Install Dependencies**
   ```bash
   composer install --no-dev --optimize-autoloader
   ```

4. **Verify Vendor Folder Created**
   - Check if `vendor/` folder exists in your API directory
   - It should contain folders like: `paytm/`, `razorpay/`, `composer/`

### Step 3: Upload Vendor Folder to Server

**Using cPanel File Manager:**
1. Login to cPanel → File Manager
2. Navigate to `public_html/api/`
3. Click "Upload"
4. Select the entire `vendor/` folder from your local computer
5. Wait for upload to complete

**Using FTP Client:**
1. Connect via FTP (FileZilla, WinSCP)
2. Navigate to `/public_html/api/` on server
3. Upload the entire `vendor/` folder
4. Maintain folder structure

**Note:** The vendor folder can be large (10-50 MB). Upload may take a few minutes.

---

## Troubleshooting

### Issue: "Permission Denied" Error

**Solution:**
```bash
# Try with sudo (if you have sudo access)
sudo composer install --no-dev --optimize-autoloader

# Or check folder permissions
chmod 755 public_html/api
```

### Issue: "composer: command not found"

**Solutions:**
- Install Composer (see Method 3 above)
- Or use `php composer.phar` instead of `composer`
- Or contact hosting provider to install Composer

### Issue: "Memory Limit Exceeded"

**Solution:**
```bash
# Increase PHP memory limit temporarily
php -d memory_limit=512M composer install --no-dev --optimize-autoloader
```

### Issue: SSH Connection Failed

**Solutions:**
- Verify SSH is enabled in cPanel
- Check hostname/port is correct
- Contact hosting provider to enable SSH
- Use Method 4 (Manual Upload) instead

### Issue: "Could not find package"

**Solution:**
- Verify `composer.json` file is uploaded
- Check internet connection on server
- Try: `composer clear-cache` then `composer install`

---

## Quick Reference Commands

```bash
# Check if Composer is installed
composer --version

# Navigate to API directory
cd public_html/api

# Install dependencies
composer install --no-dev --optimize-autoloader

# Check if vendor folder exists
ls -la vendor/

# Check what's inside vendor folder
ls vendor/

# If composer not found, use composer.phar
php composer.phar install --no-dev --optimize-autoloader
```

---

## What Gets Installed?

When you run `composer install`, it will download:

1. **Paytm SDK** (`paytm/paytmchecksum`)
   - Location: `vendor/paytm/paytmchecksum/`

2. **Razorpay SDK** (`razorpay/razorpay`)
   - Location: `vendor/razorpay/razorpay/`

3. **Composer Autoloader**
   - Location: `vendor/composer/`
   - File: `vendor/autoload.php` (this is important!)

---

## Verification Checklist

After installation, verify:

- [ ] `vendor/` folder exists in your API directory
- [ ] `vendor/autoload.php` file exists
- [ ] `vendor/paytm/` folder exists
- [ ] `vendor/razorpay/` folder exists
- [ ] No error messages during installation

---

## Next Steps

After successfully installing Composer dependencies:

1. ✅ Test payment APIs
2. ✅ Configure payment gateway webhook
3. ✅ Test payment flow end-to-end

---

## Still Need Help?

If you're still having issues:

1. **Check with Your Hosting Provider**
   - Ask if SSH is available
   - Ask if Composer is pre-installed
   - Ask for SSH connection details

2. **Use Manual Upload Method**
   - Install Composer locally
   - Upload vendor folder manually
   - This works even if SSH is not available

3. **Alternative: Ask Hosting to Install**
   - Some hosts can install Composer for you
   - Submit a support ticket

---

**Good Luck!** 🚀

