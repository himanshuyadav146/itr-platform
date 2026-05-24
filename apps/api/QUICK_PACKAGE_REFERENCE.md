# Quick Package Management Reference

## 🚀 Quick Start

### 1. Run Migrations (One Command)
```bash
cd /Applications/XAMPP/xamppfiles/htdocs/api
php migrations/run_migrations.php
```

### 2. Test APIs

**Get Packages:**
```bash
curl http://allindiaitr.in/api/package/getPackages.php
```

**Get Payment Info with Package:**
```bash
curl "http://allindiaitr.in/api/payment/get_payment_info.php?packageId=1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 📋 Frontend Integration

### Step 1: Fetch Packages
```dart
GET /package/getPackages.php

// Returns:
{
  "status": "success",
  "data": {
    "packages": [
      {
        "id": "1",
        "packagename": "Small Business Plan",
        "price": "3499.00",
        "turnover": "Up to 10 lakh",
        "icon": "business_center_outlined",
        "color": "blue",
        "description1": "..."
      }
    ]
  }
}
```

### Step 2: Submit Personal Details with Package
```dart
POST /itrdetails/personal_details.php

{
  "panNumber": "ABCDE1234F",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "packageId": 1,  // ← Add this field
  "financialYear": "2024-25"
}
```

### Step 3: Get Payment Info
```dart
GET /payment/get_payment_info.php?packageId=1

// Returns package details in response:
{
  "status": "success",
  "data": {
    "package": {
      "id": 1,
      "name": "Small Business Plan",
      "turnover": "Up to 10 lakh",
      "price": "₹3499"
    },
    "payment_summary": [...],
    "order_details": {...}
  }
}
```

---

## 📦 Available Packages

| ID | Name | Price | Turnover |
|----|------|-------|----------|
| 1 | Small Business Plan | ₹3,499 | Up to 10 lakh |
| 2 | Growing Business Plan | ₹4,999 | 10-25 Lakh |
| 3 | Established Business Plan | ₹4,999 | 25-50 lakh |
| 4 | Large Business Plan | ₹4,999 | Above 50 Lakh |
| 5 | NRI Income Plan | ₹4,999 | - |
| 6 | NRIs Business Plan | ₹7,999 | - |
| 7 | E-Verification Service | ₹199 | - |

---

## 🔑 Key API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/package/getPackages.php` | ❌ No | Get all active packages |
| POST | `/package/addPackage.php` | ✅ Admin | Add/update packages |
| POST | `/itrdetails/personal_details.php` | ✅ User | Submit personal details + packageId |
| GET | `/payment/get_payment_info.php` | ✅ User | Get payment info with package details |

---

## 🗄️ Database Changes

### itr_packages (New Columns)
- `turnover` VARCHAR(100) - Turnover range
- `icon` VARCHAR(100) - Icon identifier
- `color` VARCHAR(50) - Color code

### personal_details (New Column)
- `package_id` INT(11) - FK to itr_packages.id

---

## 🛠️ Admin Operations

### Add New Package
```bash
curl -X POST http://allindiaitr.in/api/package/addPackage.php \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "packagename": "New Plan",
    "price": 9999,
    "description1": "Description",
    "turnover": "100+ Crore",
    "icon": "star",
    "color": "gold"
  }'
```

### Update Package
```bash
curl -X POST http://allindiaitr.in/api/package/addPackage.php \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "price": 3999
  }'
```

---

## ⚠️ Important Notes

1. **Run migrations first** - Database must be updated before using new features
2. **Package ID required** - Frontend must pass packageId when submitting personal details
3. **Admin only** - Only Admin/Professional roles can add/update packages
4. **Foreign Key** - package_id in personal_details references itr_packages.id

---

## 📚 Full Documentation

- **Complete Guide:** `migrations/README.md`
- **CURL Examples:** `PACKAGE_API_CURL_COMMANDS.md`
- **Implementation Details:** `PACKAGE_IMPLEMENTATION_SUMMARY.md`
- **Rollback:** `migrations/rollback.sql`

---

## ✅ Verification

```sql
-- Check if migrations ran
SHOW COLUMNS FROM itr_packages LIKE 'turnover';
SHOW COLUMNS FROM personal_details LIKE 'package_id';

-- View packages
SELECT id, packagename, price, turnover FROM itr_packages;
```

---

**Version:** 1.0 | **Date:** 2026-01-17
