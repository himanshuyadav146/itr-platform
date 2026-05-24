# Admin Panel API Setup Guide

## ✅ What's Been Created

All admin panel APIs have been created and are ready to use. Here's what's included:

### 📁 Admin API Files Created:

1. **`/admin/dashboard.php`** - Main dashboard endpoint with statistics
2. **`/admin/users.php`** - User management (list, view, update, delete)
3. **`/admin/orders.php`** - Order/ITR management (list, view, update status)
4. **`/admin/payments.php`** - Payment management (list, view, filter)
5. **`/admin/concerns.php`** - Concern management (list, view, resolve/reject)
6. **`/admin/analytics.php`** - Analytics and reports

### 📄 Database Setup:

- **`setup_admin_tables.sql`** - SQL to add admin role support to users table

### 📚 Documentation:

- **`ADMIN_PANEL_CURL_COMMANDS.md`** - Complete cURL commands reference (updated with all admin endpoints)

---

## 🚀 Quick Setup (3 Steps)

### Step 1: Setup Admin Tables

Run the admin tables setup SQL in your database:

**Option A: Using phpMyAdmin (Recommended)**
1. Open phpMyAdmin: `http://localhost/phpmyadmin`
2. Select `itr_services` database
3. Click on **SQL** tab
4. Copy and paste contents of `setup_admin_tables.sql`
5. Click **Go** button

**Option B: Using MySQL Command Line**
```bash
mysql -u root -p itr_services < setup_admin_tables.sql
```

**Option C: Using phpMyAdmin Import**
1. Go to **Import** tab in phpMyAdmin
2. Choose file: `setup_admin_tables.sql`
3. Click **Go**

### Step 2: Create Admin User

**Option A: Update Existing User**
```sql
-- Run in phpMyAdmin SQL tab:
UPDATE users SET Role = 'admin' WHERE Email = 'test@example.com';
```

**Option B: Create New Admin User**
```sql
-- Run in phpMyAdmin SQL tab:
INSERT INTO users 
    (FirstName, LastName, Email, Mobile, Password, Role, Platform, Version, IsActive) 
VALUES 
    ('Admin', 'User', 'admin@example.com', '9876543210', 'admin123', 'admin', 'web', '1.0', 1);
```

### Step 3: Test Admin Dashboard

```bash
# 1. Login to get token
curl -X POST http://localhost/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123",
    "platform": "web",
    "version": "1.0"
  }'

# Save the token from response, then:

# 2. Test dashboard endpoint
curl -X GET http://localhost/api/admin/dashboard.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

If you get a successful response with dashboard statistics, everything is working! ✅

---

## 📋 Available Admin Endpoints

### Dashboard
- **GET** `/admin/dashboard.php` - Get dashboard statistics

### User Management
- **GET** `/admin/users.php` - List all users (pagination, search)
- **GET** `/admin/users.php?userId={id}` - Get single user details
- **PUT** `/admin/users.php` - Update user
- **DELETE** `/admin/users.php?userId={id}` - Delete user

### Order Management
- **GET** `/admin/orders.php` - List all orders (pagination, filters)
- **GET** `/admin/orders.php?orderId={id}` - Get order by orderId
- **GET** `/admin/orders.php?itrId={id}` - Get order by itrId
- **PUT** `/admin/orders.php` - Update order status

### Payment Management
- **GET** `/admin/payments.php` - List all payments (pagination, filters)
- **GET** `/admin/payments.php?paymentId={id}` - Get payment details
- **GET** `/admin/payments.php?orderId={id}` - Get payment by orderId

### Concern Management
- **GET** `/admin/concerns.php` - List all concerns (filters)
- **GET** `/admin/concerns.php?concernId={id}` - Get concern details
- **PUT** `/admin/concerns.php` - Resolve/reject concern

### Analytics
- **GET** `/admin/analytics.php` - Get analytics/reports
  - `?type=overview` (default) - All analytics
  - `?type=revenue` - Revenue analytics
  - `?type=users` - User analytics
  - `?type=orders` - Order analytics
  - `?period=30` - Number of days (default: 7)

---

## 🔧 Frontend Integration

### Base URL Configuration

**Important:** Your frontend should call the APIs using Apache server, not Vite dev server.

**Correct Base URL:**
```
http://localhost/api/admin/dashboard.php
```

**NOT:**
```
http://localhost:5173/api/admin/dashboard.php  ❌
```

### Example Frontend Call (JavaScript/TypeScript)

```javascript
// Set base URL
const API_BASE_URL = 'http://localhost/api';

// Get dashboard data
async function getDashboard(token) {
  const response = await fetch(`${API_BASE_URL}/admin/dashboard.php`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  
  const data = await response.json();
  return data;
}

// Example usage
const token = 'your_jwt_token_here';
const dashboardData = await getDashboard(token);
console.log(dashboardData.data.summary);
```

---

## 🧪 Testing All Endpoints

See **`ADMIN_PANEL_CURL_COMMANDS.md`** for complete cURL commands for all endpoints.

Quick test sequence:

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","platform":"web","version":"1.0"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo "Token: $TOKEN"

# 2. Test Dashboard
curl -X GET http://localhost/api/admin/dashboard.php \
  -H "Authorization: Bearer $TOKEN" | jq

# 3. Test Users List
curl -X GET "http://localhost/api/admin/users.php?page=1&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq

# 4. Test Orders List
curl -X GET "http://localhost/api/admin/orders.php?page=1&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq

# 5. Test Payments List
curl -X GET "http://localhost/api/admin/payments.php?page=1&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq

# 6. Test Analytics
curl -X GET "http://localhost/api/admin/analytics.php?period=30" \
  -H "Authorization: Bearer $TOKEN" | jq
```

---

## 📊 Dashboard Response Structure

The dashboard endpoint returns:

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

---

## 🔐 Authentication

All admin endpoints require authentication token. The token is obtained from the login endpoint:

```bash
POST /auth/login.php
```

**Note:** Currently, all authenticated users can access admin endpoints. If you need role-based access control (only users with `Role='admin'` can access), you can add that check to each admin endpoint.

---

## 🐛 Troubleshooting

### 404 Not Found
- **Issue:** Endpoint not found
- **Solution:** Make sure Apache is running and files are in `/Applications/XAMPP/xamppfiles/htdocs/api/admin/`

### 401 Unauthorized
- **Issue:** Invalid or missing token
- **Solution:** Login again to get a fresh token

### 500 Internal Server Error
- **Issue:** Database error or PHP error
- **Solution:** 
  - Check Apache error logs: `/Applications/XAMPP/xamppfiles/logs/error_log`
  - Verify database connection in `include/config.php`
  - Make sure all tables exist (run `setup_admin_tables.sql`)

### Empty Dashboard Data
- **Issue:** No data in database
- **Solution:** This is normal if you have no users/orders/payments yet. Create some test data or use the existing test user.

---

## ✅ Checklist

Before running your admin panel frontend:

- [ ] Database tables created (`setup_admin_tables.sql` run)
- [ ] Admin user created (or existing user updated to admin)
- [ ] Apache server is running
- [ ] MySQL database is running
- [ ] Can access `http://localhost/api/admin/dashboard.php` (should return JSON with stats)
- [ ] Frontend API base URL set to `http://localhost/api` (not `localhost:5173`)
- [ ] Authentication token obtained from login endpoint

---

## 📚 Next Steps

1. **Test all endpoints** using the cURL commands in `ADMIN_PANEL_CURL_COMMANDS.md`
2. **Integrate with frontend** - Update your React admin panel to call these endpoints
3. **Add role-based access** (optional) - Modify endpoints to check `Role='admin'`
4. **Add admin middleware** (optional) - Create a helper file to check admin role

---

## 💡 Tips

1. **Use Postman** - Import the cURL commands into Postman for easier testing
2. **Add `| jq`** - For pretty JSON output: `curl ... | jq`
3. **Save tokens** - Store token in environment variable or Postman variable
4. **Check logs** - If errors occur, check Apache and PHP error logs

---

**All admin APIs are ready! You can now run your admin panel frontend.** 🎉

If you need any modifications or additional endpoints, let me know!
