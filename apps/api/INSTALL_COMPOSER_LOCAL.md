# Install Composer Dependencies Locally (Mac)

Since SSH is not working, we'll install Composer on your Mac and upload the vendor folder.

## Step 1: Install Composer on Your Mac

### Option A: Using Homebrew (Recommended)

1. **Check if Homebrew is installed:**
   ```bash
   brew --version
   ```

2. **If Homebrew is NOT installed, install it:**
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   (Follow the prompts, enter your Mac password when asked)

3. **Install Composer:**
   ```bash
   brew install composer
   ```

4. **Verify installation:**
   ```bash
   composer --version
   ```
   Should show: `Composer version 2.x.x`

### Option B: Manual Installation (If Homebrew doesn't work)

1. **Download Composer:**
   ```bash
   php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
   ```

2. **Run installer:**
   ```bash
   php composer-setup.php
   ```

3. **Move to global location:**
   ```bash
   sudo mv composer.phar /usr/local/bin/composer
   ```
   (Enter your Mac password when prompted)

4. **Clean up:**
   ```bash
   php -r "unlink('composer-setup.php');"
   ```

5. **Verify:**
   ```bash
   composer --version
   ```

---

## Step 2: Install Dependencies Locally

1. **Navigate to your API folder:**
   ```bash
   cd /Applications/XAMPP/xamppfiles/htdocs/api
   ```

2. **Install dependencies:**
   ```bash
   composer install --no-dev --optimize-autoloader
   ```

3. **Wait for installation** (may take 1-2 minutes)

4. **Verify vendor folder created:**
   ```bash
   ls -la vendor/
   ```

   You should see:
   - `vendor/paytm/`
   - `vendor/razorpay/`
   - `vendor/composer/`
   - `vendor/autoload.php`

---

## Step 3: Upload vendor Folder to Server

### Using cPanel File Manager:

1. **Login to cPanel:**
   - Go to: `https://allindia.in/cpanel`

2. **Open File Manager:**
   - Click "File Manager" icon
   - Navigate to: `public_html/api/` (or wherever your API is located)

3. **Upload vendor folder:**
   - Click "Upload" button
   - Navigate to: `/Applications/XAMPP/xamppfiles/htdocs/api/vendor/`
   - Select the entire `vendor` folder
   - Wait for upload (may take 2-5 minutes, folder is ~10-20 MB)

4. **Verify:**
   - Check that `vendor/` folder exists in `public_html/api/`
   - Should contain: `paytm/`, `razorpay/`, `composer/` folders

### Using FTP (Alternative):

1. **Connect via FTP client** (FileZilla, Cyberduck, etc.)
   - Host: `allindia.in` or `ftp.allindia.in`
   - Username: Your cPanel username
   - Password: Your cPanel password
   - Port: 21

2. **Navigate to:** `/public_html/api/` on server

3. **Upload:** Drag and drop the `vendor/` folder from local to server

---

## Quick Commands Summary

```bash
# 1. Install Composer (if not installed)
brew install composer

# 2. Navigate to API folder
cd /Applications/XAMPP/xamppfiles/htdocs/api

# 3. Install dependencies
composer install --no-dev --optimize-autoloader

# 4. Verify vendor folder
ls -la vendor/
```

Then upload `vendor/` folder via cPanel File Manager.

---

## Troubleshooting

### "brew: command not found"
- Install Homebrew first (see Option A above)
- Or use Option B (Manual Installation)

### "Permission denied" when moving composer
- Use `sudo` before the command
- Enter your Mac password when prompted

### Vendor folder upload fails
- Try uploading via FTP instead
- Or compress vendor folder to ZIP, upload, then extract on server

---

## Done!

After vendor folder is uploaded, your payment APIs will work. Test with:

```bash
curl https://allindia.in/api/payment/get_payment_info.php
```

