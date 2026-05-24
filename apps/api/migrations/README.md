# Package Management Migration Guide

This folder contains database migrations and scripts to support the new package management system.

## Overview

The following changes have been implemented:

1. **Database Schema Updates**
   - Added `turnover`, `icon`, and `color` fields to `itr_packages` table
   - Added `package_id` field to `personal_details` table for tracking user package selection

2. **New APIs**
   - `/package/addPackage.php` - Add or update packages (Admin/Professional only)
   - `/package/getPackages.php` - Get all packages (already existed)

3. **Updated APIs**
   - `/itrdetails/personal_details.php` - Now accepts `packageId` parameter
   - `/payment/get_payment_info.php` - Now returns package details in response

### Push notifications (Option A)

- **Migration:** `add_push_notification_tables.sql` — creates `user_fcm_tokens`, `notifications`, and `notification_log`.
- **One token per user:** `one_fcm_token_per_user.sql` — removes duplicate FCM tokens per user and enforces a single row per user (run after the tables exist).
- **Register token:** `POST /auth/register_fcm.php` — register FCM token (requires JWT). Replaces any existing token for that user (one entry per user). Body: `{ "fcm_token": "...", "platform": "android"|"ios" }`.
- **Send manually (Postman / admin):** `POST /admin/send_notification.php` — send a notification now (ADMIN only). Body: `{ "title": "...", "body": "...", "data_payload": {}, "target": "all_users"|"single_user", "target_user_id": 5 }`. Requires `include/firebase_config.php` and a Firebase service account JSON for FCM.

Run the migration, then copy `include/firebase_config.php.example` to `include/firebase_config.php` and set your Firebase project ID and service account path before using the send API:

```bash
mysql -u your_username -p your_database < migrations/add_push_notification_tables.sql
```

## Migration Steps

### Step 1: Run Database Migrations

Execute the following SQL files in order:

```bash
# 1. Add turnover, icon, color fields to itr_packages
mysql -u your_username -p your_database < migrations/add_turnover_to_packages.sql

# 2. Add package_id to personal_details
mysql -u your_username -p your_database < migrations/add_package_id_to_personal_details.sql

# 3. Insert frontend packages data
mysql -u your_username -p your_database < migrations/insert_frontend_packages.sql
```

**OR** use the PHP migration runner:

```bash
php migrations/run_migrations.php
```

### Step 2: Verify Changes

Check that the tables have been updated:

```sql
-- Check itr_packages table structure
DESCRIBE itr_packages;

-- Check personal_details table structure
DESCRIBE personal_details;

-- View all packages
SELECT id, packagename, price, turnover, icon, color FROM itr_packages;
```

## API Usage

### 1. Get All Packages

```bash
GET /package/getPackages.php
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "packages": [
      {
        "id": 1,
        "packagename": "Small Business Plan",
        "price": "3499.00",
        "description1": "Business/Profession (Entry level plan for small businesses or professionals.)",
        "turnover": "Up to 10 lakh",
        "icon": "business_center_outlined",
        "color": "blue",
        "isActive": "1"
      }
    ]
  }
}
```

### 2. Add/Update Package (Admin Only)

```bash
POST /package/addPackage.php
Authorization: Bearer {token}
Content-Type: application/json

{
  "packagename": "Premium Plan",
  "price": 9999,
  "description1": "Premium service for high-value clients",
  "turnover": "Above 1 Crore",
  "icon": "star",
  "color": "gold",
  "isActive": 1
}
```

**Update existing package:**
```json
{
  "id": 1,
  "packagename": "Updated Package Name",
  "price": 4999
}
```

### 3. Submit Personal Details with Package

```bash
POST /itrdetails/personal_details.php
Authorization: Bearer {token}
Content-Type: application/json

{
  "panNumber": "ABCDE1234F",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "packageId": 1,
  "financialYear": "2024-25",
  "mobileNumber": "9876543210"
}
```

### 4. Get Payment Info with Package Details

```bash
GET /payment/get_payment_info.php?packageId=1
Authorization: Bearer {token}
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "order_details": {
      "Name": "John Doe",
      "phone": "9876543210",
      "email": "john@example.com"
    },
    "payment_summary": [
      {
        "display_title": "Small Business Plan Package",
        "display_value": "₹3499",
        "amount": 3499
      },
      {
        "display_title": "Total (Before GST)",
        "display_value": "₹3499",
        "amount": 3499
      },
      {
        "display_title": "GST @18%",
        "display_value": "₹630",
        "amount": 629.82
      },
      {
        "display_title": "GRAND TOTAL",
        "display_value": "₹4129",
        "amount": 4128.82
      }
    ],
    "package": {
      "id": 1,
      "name": "Small Business Plan",
      "description": "Business/Profession (Entry level plan for small businesses or professionals.)",
      "turnover": "Up to 10 lakh",
      "price": "₹3499",
      "icon": "business_center_outlined",
      "color": "blue"
    },
    "gateway_details": {
      "MID": "RgSGKJiDNpMKj7"
    }
  }
}
```

## Frontend Integration

### Package Data Structure Mapping

| Frontend Field | Database Field | Notes |
|---------------|----------------|-------|
| `name` | `packagename` | Package display name |
| `description` | `description1` | Main description |
| `turnover` | `turnover` | Turnover range |
| `price` | `price` | Price in rupees |
| `icon` | `icon` | Icon identifier for UI |
| `color` | `color` | Color code for UI |

### Workflow

1. **User selects package** → Frontend stores `packageId`
2. **User fills personal details** → Frontend sends `packageId` in request body
3. **Backend saves** → `package_id` stored in `personal_details` table
4. **Payment initiated** → Frontend passes `packageId` to payment API
5. **Payment info returned** → Includes package details for display

## Database Schema

### itr_packages Table

```sql
CREATE TABLE `itr_packages` (
  `id` int(11) PRIMARY KEY AUTO_INCREMENT,
  `packagename` varchar(255) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `title1` varchar(255) DEFAULT NULL,
  `description1` text DEFAULT NULL,
  `title2` varchar(255) DEFAULT NULL,
  `description2` text DEFAULT NULL,
  `turnover` varchar(100) DEFAULT NULL,
  `icon` varchar(100) DEFAULT NULL,
  `color` varchar(50) DEFAULT NULL,
  `isActive` tinyint(1) DEFAULT 1,
  `createdAt` datetime DEFAULT CURRENT_TIMESTAMP
);
```

### personal_details Table (Updated)

```sql
ALTER TABLE `personal_details` 
ADD COLUMN `package_id` int(11) DEFAULT NULL,
ADD KEY `idx_package_id` (`package_id`),
ADD FOREIGN KEY (`package_id`) REFERENCES `itr_packages`(`id`) ON DELETE SET NULL;
```

## Rollback

If you need to rollback these changes:

```sql
-- Remove package_id from personal_details
ALTER TABLE `personal_details` 
DROP FOREIGN KEY `fk_personal_details_package`;
ALTER TABLE `personal_details` DROP COLUMN `package_id`;

-- Remove new columns from itr_packages
ALTER TABLE `itr_packages` 
DROP COLUMN `turnover`,
DROP COLUMN `icon`,
DROP COLUMN `color`;
```

## Support

For any issues or questions, please contact the development team.

---

**Date Created:** 2026-01-17
**Version:** 1.0
