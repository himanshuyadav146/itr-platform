# How to Run the ITR API Project Locally

## Prerequisites

- **XAMPP/MAMP/LAMP** installed (or any PHP + MySQL setup)
- **PHP 7.4+** enabled
- **MySQL 5.7+** or **MariaDB 10.3+**
- **Postman** (for API testing - optional)

## Quick Setup (Recommended)

### Step 1: Start Services

1. Open **XAMPP Control Panel** (or your local server)
2. Start **Apache** service
3. Start **MySQL** service

### Step 2: Database Setup (Easy Method)

**Option A: Using Setup Script (Easiest)**
1. Open browser and go to: `http://localhost/api/setup.php`
2. Enter your MySQL credentials (default XAMPP: username=`root`, password=empty)
3. Click "Setup Database" button
4. Wait for success message

**Option B: Using phpMyAdmin**
1. Open phpMyAdmin: `http://localhost/phpmyadmin`
2. Click on "SQL" tab
3. Open `database_setup.sql` file in a text editor
4. Copy all contents and paste in SQL tab
5. Click "Go" to execute

**Option C: Using MySQL Command Line**
```bash
mysql -u root -p < database_setup.sql
```

### Step 3: Verify Setup

1. Test database connection: `http://localhost/api/test_connection.php`
2. You should see: ✅ Database connected successfully!

### Step 4: Test API

1. Import Postman collection: `ITR_API_Postman_Collection.json`
2. Or test manually using the endpoints below

---

## Manual Database Setup

### Database Configuration

The project uses the following database settings (can be changed in `include/config.php`):

- **Database Name**: `allindia_services`
- **Username**: `allindia_seruser` (or `root` for local)
- **Password**: `allitr@#PASss` (or empty for local)
- **Host**: `localhost`

### Database Tables Created

The setup script creates the following tables:

1. **users** - User authentication and profile
2. **services** - Available services
3. **personal_details** - Personal information (PAN, name, etc.)
4. **document_details** - Uploaded documents metadata
5. **itr_detail** - ITR filing records
6. **itr_source** - ITR income sources
7. **itr_packages** - Available ITR packages/pricing

### Sample Data

The setup includes sample data:
- **Test User**: `test@example.com` / `test123`
- **Sample Services**: ITR Filing, Tax Consultation, Document Verification
- **Sample Packages**: Basic (₹499), Standard (₹999), Premium (₹1999)

---

## API Endpoints

### Base URL
```
http://localhost/api
```

### Authentication Endpoints

#### 1. Signup
- **URL**: `POST /auth/signup.php`
- **Body**:
```json
{
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe",
    "mobile": "9876543210",
    "platform": "web",
    "version": "1.0"
}
```

#### 2. Login
- **URL**: `POST /auth/login.php`
- **Body**:
```json
{
    "email": "test@example.com",
    "password": "test123",
    "platform": "web",
    "version": "1.0"
}
```
- **Response**: Returns `token` and `UserId` (save these for authenticated requests)

#### 3. Forget Password
- **URL**: `POST /auth/forget_password.php`
- **Body**:
```json
{
    "email": "user@example.com",
    "password": "newpassword"
}
```

### Personal Details Endpoints

#### 4. Add/Update Personal Details
- **URL**: `POST /itrdetails/personal_details.php`
- **Headers**: `Authorization: Bearer {token}`
- **Body**:
```json
{
    "panNumber": "ABCDE1234F",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "mobileNumber": "9876543210",
    "aadharCardNumber": "123456789012",
    "gender": "Male",
    "DATEOFBIRTH": "1990-01-15",
    "financialYear": "2024-25",
    "address": "123 Main St",
    "country": "India"
}
```

#### 5. Get Personal Details
- **URL**: `GET /itrdetails/get_personal_detail.php?UserId={userId}&PanNumber={panNumber}`
- **Headers**: `Authorization: Bearer {token}`

### Document Endpoints

#### 6. Upload Document
- **URL**: `POST /itrdetails/add_documents.php`
- **Body**: `multipart/form-data`
  - `PanNumber`: PAN number
  - `fileName`: Document name
  - `file`: File (jpg, jpeg, png, pdf)

#### 7. Save Document Details
- **URL**: `POST /itrdetails/save_documents.php`
- **Headers**: `Authorization: Bearer {token}`
- **Body**:
```json
{
    "PanNumber": "ABCDE1234F",
    "documents": [
        {
            "documentName": "Form 16",
            "fileType": "pdf",
            "filePassword": "",
            "fileName": "form16_abc123.pdf"
        }
    ]
}
```

#### 8. Get Documents
- **URL**: `GET /itrdetails/get_documents.php?PanNumber={panNumber}`
- **Headers**: `Authorization: Bearer {token}`

#### 9. Delete Document
- **URL**: `POST /itrdetails/delete_document.php`
- **Headers**: `Authorization: Bearer {token}`
- **Body**:
```json
{
    "id": 1,
    "PanNumber": "ABCDE1234F",
    "fileName": "form16_abc123.pdf"
}
```

### ITR Endpoints

#### 10. Get ITR by User ID
- **URL**: `GET /get_itrbyuser.php?userId={userId}`
- **Headers**: `Authorization: Bearer {token}`

#### 11. Get ITR by ITR ID
- **URL**: `GET /get_itrbyitrid.php?itrId={itrId}`
- **Headers**: `Authorization: Bearer {token}`

### Other Endpoints

#### 12. Get Packages
- **URL**: `GET /package/getPackages.php`
- **No authentication required**

#### 13. Add Service
- **URL**: `POST /add_services.php`
- **Headers**: `Authorization: Bearer {token}`
- **Body**:
```json
{
    "name": "Service Name"
}
```

---

## Testing with Postman

### Import Collection

1. Open Postman
2. Click "Import" button
3. Select `ITR_API_Postman_Collection.json`
4. Collection will be imported with all endpoints

### Using the Collection

1. **Set Base URL**: The collection uses variable `{{base_url}}` = `http://localhost/api`
2. **Login First**: Run "Login" request to get token
3. **Token Auto-Save**: Token is automatically saved to collection variable
4. **Test Other Endpoints**: All authenticated endpoints will use the saved token

### Collection Variables

- `base_url`: `http://localhost/api` (change if your setup is different)
- `token`: Auto-populated after login
- `user_id`: Auto-populated after login
- `pan_number`: Default `ABCDE1234F` (change as needed)

---

## Troubleshooting

### Apache Won't Start
- Check if port 80 is in use
- Change Apache port in XAMPP Control Panel → Config → Apache (httpd.conf)
- Update base URL in Postman collection if port changed

### MySQL Won't Start
- Check if port 3306 is in use
- Check MySQL error logs
- Restart MySQL service

### Database Connection Errors
- Verify MySQL is running
- Check credentials in `include/config.php`
- Ensure database `allindia_services` exists
- Run `test_connection.php` to diagnose

### API Returns 500 Error
- Check PHP error logs: `C:\xampp\php\logs\php_error_log`
- Check Apache error logs: `C:\xampp\apache\logs\error.log`
- Check project error log: `error_log` file in project directory
- Enable PHP error display in `php.ini`:
  ```ini
  display_errors = On
  error_reporting = E_ALL
  ```

### Token Errors (401 Unauthorized)
- Make sure you login first to get a token
- Check if token is expired (default: 10 hours)
- Verify token is sent in header: `Authorization: Bearer {token}`
- Test token using `/auth/test_token.php`

### File Upload Errors
- Check `uploads/` directory has write permissions (chmod 777)
- Verify file size limits in `php.ini`:
  ```ini
  upload_max_filesize = 10M
  post_max_size = 10M
  ```

### CORS Errors (if testing from browser)
- CORS headers are already set in all API files
- If still having issues, check Apache configuration

---

## Project Structure

```
api/
├── auth/                    # Authentication endpoints
│   ├── login.php
│   ├── signup.php
│   ├── forget_password.php
│   └── test_token.php
├── itrdetails/              # ITR details endpoints
│   ├── personal_details.php
│   ├── get_personal_detail.php
│   ├── add_documents.php
│   ├── save_documents.php
│   ├── get_documents.php
│   └── delete_document.php
├── package/                 # Package endpoints
│   └── getPackages.php
├── include/                 # Configuration
│   └── config.php
├── phpjwt/                  # JWT token handling
│   └── Token.php
├── uploads/                 # Uploaded files
├── database_setup.sql       # Complete database schema
├── setup.php                # Web-based setup script
├── test_connection.php      # Database connection test
├── ITR_API_Postman_Collection.json  # Postman collection
└── RUN.md                   # This file
```

---

## Development Notes

### Database Credentials

For local development, you can use:
- Username: `root`
- Password: (empty)

For production, update `include/config.php` with secure credentials.

### JWT Token

- Secret Key: `testitr_key` (change in production)
- Expiry: 36000 seconds (10 hours)
- Location: `include/config.php`

### File Uploads

- Upload directory: `uploads/{PAN_NUMBER}/`
- Allowed types: jpg, jpeg, png, pdf
- Files are stored with unique names to prevent conflicts

---

## Next Steps

1. ✅ Database setup complete
2. ✅ Test connection working
3. ✅ Import Postman collection
4. ✅ Test login endpoint
5. ✅ Test other endpoints
6. 🔄 Customize for your needs

---

## Support

If you encounter any issues:
1. Check error logs
2. Verify database connection
3. Test with Postman collection
4. Review this documentation

**Happy Coding! 🚀**
