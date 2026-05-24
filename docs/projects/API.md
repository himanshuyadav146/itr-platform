# API Reference — PHP Backend

Project-specific reference for `apps/api`. For cross-app contracts see [../API_CONTRACT.md](../API_CONTRACT.md).

---

## Overview

| Property | Value |
|----------|-------|
| **Path** | `apps/api` |
| **Stack** | PHP 7.4+, MySQL, Apache |
| **Local URL** | `http://localhost/api` |
| **Production URL** | `http://allindiaitr.in/api` |
| **Database** | `itr_services` |
| **Auth** | JWT Bearer token |

---

## Quick start

```bash
# Symlink to XAMPP (macOS)
ln -sf "$PWD/apps/api" /Applications/XAMPP/xamppfiles/htdocs/api

# Config
cp apps/api/include/config.local.php.example apps/api/include/config.php

# Database (browser)
open http://localhost/api/setup.php

# Dependencies
cd apps/api && composer install
```

See [../ENVIRONMENTS.md](../ENVIRONMENTS.md) and [../README.md](../README.md).

---

## Directory structure

```
apps/api/
├── auth/                  # Login, signup, FCM, token refresh
├── admin/                 # Admin panel endpoints
├── payment/               # Razorpay/Paytm
├── package/               # ITR packages
├── itrdetails/            # Personal info, documents, journey
├── itr_status/            # Orders, status timeline, concerns
├── include/               # config.php, CORS, FCM, payment config
├── phpjwt/                # JWT Token.php
├── migrations/            # SQL migrations
├── cron/                  # Scheduled jobs
├── uploads/               # User documents ({PAN}/{file})
├── vendor/                # Composer (gitignored)
└── *.sql                  # Database setup scripts
```

---

## Configuration files

| File | In git? | Purpose |
|------|---------|---------|
| `include/config.php` | ❌ | DB connection + JWT key |
| `include/config.php.example` | ✅ | Template |
| `include/config.local.php.example` | ✅ | Local XAMPP template |
| `include/payment_config.php` | ❌ | Razorpay/Paytm keys |
| `include/payment_config.php.example` | ✅ | Template |
| `include/firebase_config.php` | ❌ | FCM service account |
| `include/firebase_config.php.example` | ✅ | Template |
| `include/cors.php` | ✅ | CORS headers |

---

## Database setup

### Base schema

```bash
# Browser: http://localhost/api/setup.php
# Or import:
mysql -u root < apps/api/setup_database.sql
```

**Core tables:** `users`, `services`, `personal_details`, `document_details`, `itr_detail`, `itr_source`, `itr_packages`

### Additional setup scripts

| Script | Purpose |
|--------|---------|
| `setup_admin_tables.sql` | Admin role columns |
| `setup_payment_table.sql` | Payment tables |
| `setup_itr_status_table.sql` | Status tracking |
| `setup_itr_assignment_tables.sql` | ITR assignments |
| `migrations/*.sql` | Incremental migrations |

Run migrations: `php migrations/run_migrations.php`

---

## API modules & endpoints

### auth/

| File | Method | Auth |
|------|--------|------|
| `login.php` | POST | No |
| `signup.php` | POST | No |
| `refresh_token.php` | POST | Token |
| `forget_password.php` | POST | No |
| `delete_account.php` | POST | JWT |
| `register_fcm.php` | POST | JWT |
| `register_professional.php` | POST | No |

### itrdetails/

| File | Method | Auth |
|------|--------|------|
| `add_personal_details.php` | POST | JWT |
| `get_personal_detail.php` | GET | JWT |
| `personal_details.php` | POST | JWT |
| `add_documents.php` | POST | JWT |
| `save_documents.php` | POST | JWT |
| `get_documents.php` | GET | JWT |
| `delete_document.php` | POST | JWT |
| `download_document.php` | GET | JWT |
| `get_user_journey.php` | GET | JWT |
| `update_journey_status.php` | POST | JWT |

### itr_status/

| File | Method | Auth |
|------|--------|------|
| `get_user_orders.php` | GET | JWT |
| `get_detailed_status.php` | GET | JWT |
| `get_order_status.php` | GET | JWT |
| `get_status_config.php` | GET | JWT |
| `raise_concern.php` | POST | JWT |
| `resolve_concern.php` | PUT | JWT |

### payment/

| File | Method | Auth |
|------|--------|------|
| `get_payment_info.php` | GET | JWT |
| `initiate_payment.php` | POST | JWT |
| `verify_payment.php` | POST | JWT |
| `get_payment_status.php` | GET | JWT |
| `get_payment_history.php` | GET | JWT |
| `webhook.php` | POST | No |

### package/

| File | Method | Auth |
|------|--------|------|
| `getPackages.php` | GET | No* |
| `addPackage.php` | POST | JWT (Admin) |
| `deletePackage.php` | POST | JWT (Admin) |

### admin/

| File | Purpose |
|------|---------|
| `dashboard.php` | KPI statistics |
| `users.php` | User CRUD |
| `itrs.php` | ITR list/detail/update |
| `assign_itr.php` | Assign to professional |
| `get_assignments.php` | List assignments |
| `update_assignment.php` | Update assignment |
| `update_status_step.php` | Update ITR status step |
| `submit_acknowledgement.php` | Submit acknowledgement |
| `documents.php` | Admin document access |
| `analytics.php` | Reports |
| `concerns.php` | Concern management |
| `payments.php` | Payment list |
| `orders.php` | Order management |
| `send_notification.php` | Push notification |
| `status_config.php` | Status configuration |

### Root endpoints

| File | Purpose |
|------|---------|
| `get_itrbyuser.php` | ITRs for user |
| `get_itrbyitrid.php` | ITR by ID |
| `add_services.php` | Add service type |

---

## Response format

```json
{
  "statusCode": 200,
  "status": "success",
  "data": { "message": "...", ... }
}
```

See [../API_CONTRACT.md](../API_CONTRACT.md).

---

## JWT authentication

```php
// Protected endpoint pattern
$headers = getallheaders();
$token = str_replace('Bearer ', '', $headers['Authorization'] ?? '');
$payload = Token::Verify($token, $key);
$userId = $payload['UserId'];
$role = $payload['Role'];
```

**Roles:** `CLIENT`, `ADMIN`, `CA`, `ACCOUNTANT`, `TAX_EXPERT`

---

## Composer dependencies

```json
{
  "paytm/paytmchecksum": "^1.1",
  "razorpay/razorpay": "^2.8"
}
```

```bash
composer install
```

---

## Testing

```bash
# Connection
curl http://localhost/api/test_connection.php

# Login
curl -X POST http://localhost/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","platform":"web","version":"1.0"}'

# Packages
curl http://localhost/api/package/getPackages.php
```

**Postman:** Import `ITR_API_Postman_Collection.json`

---

## Legacy documentation (in app folder)

| File | Topic |
|------|-------|
| `API_DOCUMENTATION.md` | Full API reference |
| `LOCAL_SETUP.md` | Detailed local setup |
| `ADMIN_PANEL_SETUP.md` | Admin API setup |
| `PAYMENT_SETUP.md` | Payment gateway |
| `CURL_EXAMPLES.md` | cURL examples |
| `ADMIN_PANEL_CURL_COMMANDS.md` | Admin cURL |
| `CPANEL_DEPLOYMENT.md` | Production deploy |
| `USER_JOURNEY_GUIDE.md` | User journey |
| `DYNAMIC_STATUS_SYSTEM_GUIDE.md` | Status system |

---

## Related docs

| Doc | Purpose |
|-----|---------|
| [../API_CONTRACT.md](../API_CONTRACT.md) | Request/response contract |
| [../SCREEN_API_MAP.md](../SCREEN_API_MAP.md) | Which client uses which API |
| [../WORKFLOWS.md](../WORKFLOWS.md) | Business flows |
| [../ENVIRONMENTS.md](../ENVIRONMENTS.md) | Config per environment |
