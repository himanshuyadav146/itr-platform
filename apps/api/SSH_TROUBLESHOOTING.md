# SSH Connection Refused - Troubleshooting Guide

## Error: "ssh: connect to host allindia.in port 22: Connection refused"

This error means your server is not accepting SSH connections on port 22. Here are solutions:

---

## Solution 1: Check SSH Port (Most Common)

Many hosting providers use a different port (not 22) for security.

### Try Different Ports:

```bash
# Try port 2222 (common alternative)
ssh -p 2222 allindia@allindia.in

# Try port 2200
ssh -p 2200 allindia@allindia.in

# Try port 22222
ssh -p 22222 allindia@allindia.in
```

### How to Find Your SSH Port:

1. **Check cPanel:**
   - Login to cPanel
   - Look for "SSH Access" section
   - It should show the SSH port (might be 2222, 2200, etc.)

2. **Check Welcome Email:**
   - Check your hosting provider's welcome email
   - SSH port is usually mentioned there

3. **Contact Hosting Support:**
   - Ask them: "What is the SSH port for my account?"
   - Or: "Is SSH enabled and what port should I use?"

---

## Solution 2: Check if SSH is Enabled

Some shared hosting providers don't enable SSH by default.

### Check in cPanel:

1. Login to cPanel
2. Look for "SSH Access" section
3. Check status:
   - **Enabled** = SSH is active
   - **Disabled** = SSH is not enabled
   - **Not Available** = Your hosting plan doesn't support SSH

### Enable SSH (if option available):

1. In cPanel → SSH Access
2. Click "Manage SSH Keys" or "Enable SSH Access"
3. Follow the prompts
4. Some hosts require you to request SSH access via support ticket

---

## Solution 3: Use cPanel Terminal Instead

Many cPanel hosts have a built-in terminal that works even if external SSH is disabled.

### Steps:

1. **Login to cPanel**
   - Go to: `https://allindia.in/cpanel`
   - Or: `https://allindia.in:2083`

2. **Look for Terminal:**
   - Search for "Terminal" in cPanel search box
   - Or look for icons: "Terminal", "Web Terminal", "Shell Access"
   - Click on it

3. **If Terminal Available:**
   - A terminal window opens in your browser
   - You can run commands directly without SSH
   - Skip to "Run Commands" section below

---

## Solution 4: Use Manual Upload Method (Recommended if SSH Not Available)

If SSH is not working, use the manual method - it's easier and works 100% of the time.

### Step 1: Install Composer on Your Mac

1. **Open Terminal on Your Mac** (you already have it open)

2. **Check if Composer is installed:**
   ```bash
   composer --version
   ```

3. **If not installed, install it:**
   ```bash
   # Install Homebrew first (if not installed)
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   
   # Then install Composer
   brew install composer
   ```

   OR download manually:
   ```bash
   php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
   php composer-setup.php
   sudo mv composer.phar /usr/local/bin/composer
   ```

### Step 2: Install Dependencies Locally

1. **Navigate to your API folder:**
   ```bash
   cd /Applications/XAMPP/xamppfiles/htdocs/api
   ```

2. **Install dependencies:**
   ```bash
   composer install --no-dev --optimize-autoloader
   ```

3. **Verify vendor folder created:**
   ```bash
   ls -la vendor/
   ```
   You should see: `paytm/`, `razorpay/`, `composer/` folders

### Step 3: Upload vendor Folder to Server

1. **Using cPanel File Manager:**
   - Login to cPanel
   - Go to File Manager
   - Navigate to: `public_html/api/` (or wherever your API is)
   - Click "Upload"
   - Select the `vendor/` folder from: `/Applications/XAMPP/xamppfiles/htdocs/api/vendor/`
   - Wait for upload to complete

2. **Using FTP Client (FileZilla, Cyberduck, etc.):**
   - Connect via FTP
   - Navigate to: `/public_html/api/` on server
   - Upload entire `vendor/` folder
   - Maintain folder structure

**Done!** This method works even if SSH is disabled.

---

## Solution 5: Contact Your Hosting Provider

If none of the above works, contact your hosting support:

### Ask Them:

1. "Is SSH enabled for my account?"
2. "What is the SSH port number?" (might not be 22)
3. "How do I enable SSH access?"
4. "Can you enable SSH for my account?"

### Common Responses:

- **"SSH is not available on shared hosting"** → Use Manual Upload Method (Solution 4)
- **"SSH is on port 2222"** → Use: `ssh -p 2222 allindia@allindia.in`
- **"SSH needs to be enabled"** → They'll enable it, then try again

---

## Quick Decision Guide

**Choose based on your situation:**

| Situation | Solution |
|-----------|----------|
| SSH port might be different | Try Solution 1 (different ports) |
| cPanel has Terminal option | Use Solution 3 (cPanel Terminal) |
| SSH not available/working | Use Solution 4 (Manual Upload) ⭐ Recommended |
| Need SSH for other reasons | Contact hosting (Solution 5) |

---

## Recommended: Use Manual Upload (Solution 4)

**Why?**
- ✅ Works 100% of the time
- ✅ No SSH configuration needed
- ✅ Faster and easier
- ✅ Works on all hosting types (shared, VPS, dedicated)

**Steps:**
1. Install Composer on your Mac
2. Run `composer install` locally
3. Upload `vendor/` folder via cPanel/FTP
4. Done!

---

## Test Your Setup

After installing dependencies (any method), test:

1. **Check vendor folder exists on server:**
   - Via File Manager: `public_html/api/vendor/` should exist
   - Should contain: `paytm/`, `razorpay/`, `composer/` folders

2. **Test API:**
   ```bash
   curl https://allindia.in/api/payment/get_payment_info.php
   ```
   (Should return error about authentication, but file should be accessible)

---

## Still Having Issues?

1. **Try cPanel Terminal first** (easiest if available)
2. **Use Manual Upload method** (always works)
3. **Contact hosting support** for SSH help

Good luck! 🚀

