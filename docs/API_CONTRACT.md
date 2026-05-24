# API Contract

Shared API specification for all ITR Platform clients (mobile, admin). Use this when implementing UI flows that call the backend.

---

## Base URLs

| Environment | Base URL |
|-------------|----------|
| Local | `http://localhost/api` |
| Production | `http://allindiaitr.in/api` |

Mobile app uses host-only base (`http://allindiaitr.in`) and prepends `/api` in constants.

---

## Standard response envelope

Every endpoint returns JSON in this shape:

```json
{
  "statusCode": 200,
  "status": "success",
  "data": { }
}
```

| Field | Type | Values |
|-------|------|--------|
| `statusCode` | number | HTTP-like code (200, 201, 400, 401, 404, 500) |
| `status` | string | `"success"` or `"error"` |
| `data` | object | Payload; always an object (never raw array at root) |

**Error example:**

```json
{
  "statusCode": 401,
  "status": "error",
  "data": {
    "message": "Invalid or expired token"
  }
}
```

**Client handling:**
- Mobile: `ApiResponse` / `BaseResponse` in `lib/core/network/`
- Admin: Axios interceptor in `src/api/client.ts` (401 → logout)

---

## Authentication

### Headers

```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

Public endpoints (login, signup, getPackages) do not require a token.

### Login

**`POST /auth/login.php`**

Request:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "platform": "android",
  "version": "1.0"
}
```

Response (`data`):
```json
{
  "message": "Login successful",
  "UserId": 1,
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "mobile": "9876543210",
  "role": "CLIENT",
  "isActive": true,
  "platform": "android",
  "version": "1.0",
  "token": "eyJ..."
}
```

### Signup

**`POST /auth/signup.php`**

Request:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "mobile": "9876543210"
}
```

### Refresh token

**`POST /auth/refresh_token.php`** — send expired token, receive new one.

### Register FCM token

**`POST /auth/register_fcm.php`** (requires JWT)

```json
{
  "fcm_token": "...",
  "platform": "android"
}
```

### Roles

| Role | Used by |
|------|---------|
| `CLIENT` | Mobile app users |
| `ADMIN` | Admin panel full access |
| `CA` | Chartered accountant (admin panel) |
| `ACCOUNTANT` | Accountant (admin panel) |
| `TAX_EXPERT` | Tax expert (admin panel) |

---

## Auth endpoints

| Method | Path | Auth | Used by |
|--------|------|------|---------|
| POST | `/auth/login.php` | No | Mobile, Admin |
| POST | `/auth/signup.php` | No | Mobile |
| POST | `/auth/forget_password.php` | No | Mobile |
| POST | `/auth/refresh_token.php` | Token | Mobile |
| POST | `/auth/delete_account.php` | JWT | Mobile, Admin |
| POST | `/auth/register_fcm.php` | JWT | Mobile |
| POST | `/auth/register_professional.php` | No | Admin |

---

## ITR & personal details

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/itrdetails/add_personal_details.php` | JWT | Create/update personal info + packageId |
| GET | `/itrdetails/get_personal_detail.php` | JWT | Get by UserId / PanNumber |
| POST | `/itrdetails/personal_details.php` | JWT | Legacy add/update personal info |
| GET | `/get_itrbyuser.php` | JWT | List ITRs for logged-in user |
| GET | `/get_itrbyitrid.php` | JWT | Get ITR by ID |

**Personal details request (key fields):**
```json
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

---

## Documents

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/itrdetails/add_documents.php` | JWT | Upload document file |
| POST | `/itrdetails/save_documents.php` | JWT | Save document metadata |
| GET | `/itrdetails/get_documents.php` | JWT | List documents by PAN |
| POST | `/itrdetails/delete_document.php` | JWT | Delete document |
| GET | `/itrdetails/download_document.php` | JWT | Download document |

**Document file URL pattern:**
```
{baseUrl}/api/uploads/{panNumber}/{fileName}
```

---

## Packages

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/package/getPackages.php` | No* | List active packages |
| POST | `/package/addPackage.php` | JWT (Admin) | Create/update package |
| POST | `/package/deletePackage.php` | JWT (Admin) | Delete package |

**Package response item:**
```json
{
  "id": 1,
  "packagename": "Small Business Plan",
  "price": "3499.00",
  "description1": "...",
  "turnover": "Up to 10 lakh",
  "icon": "business_center_outlined",
  "color": "blue",
  "isActive": "1"
}
```

---

## Payment

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/payment/get_payment_info.php` | JWT | Payment summary + gateway details |
| POST | `/payment/initiate_payment.php` | JWT | Create Razorpay order |
| POST | `/payment/verify_payment.php` | JWT | Verify after Razorpay callback |
| GET | `/payment/get_payment_status.php` | JWT | Check payment status |
| GET | `/payment/get_payment_history.php` | JWT | Payment history |
| POST | `/payment/webhook.php` | No | Razorpay webhook |

**Get payment info:** `GET /payment/get_payment_info.php?packageId=1`

Response includes `order_details`, `payment_summary` (line items + GST), `package`, `gateway_details` (Razorpay key).

---

## ITR status & orders

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/itr_status/get_user_orders.php` | JWT | User's order list |
| GET | `/itr_status/get_detailed_status.php` | JWT | ITR progress timeline |
| GET | `/itr_status/get_order_status.php` | JWT | Single order status |
| GET | `/itr_status/get_status_config.php` | JWT | Status step configuration |
| POST | `/itr_status/raise_concern.php` | JWT | User raises concern |
| PUT | `/itr_status/resolve_concern.php` | JWT | Resolve concern |

---

## Admin endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/admin/dashboard.php` | JWT (Admin+) | Dashboard KPIs |
| GET/PUT/DELETE | `/admin/users.php` | JWT (Admin) | User CRUD |
| GET/PUT | `/admin/itrs.php` | JWT | ITR list/detail/update |
| POST | `/admin/itrs.php?action=comment` | JWT | Add ITR comment |
| POST | `/admin/itrs.php?action=assign` | JWT | Assign ITR |
| POST | `/admin/assign_itr.php` | JWT | Assign ITR to professional |
| GET | `/admin/get_assignments.php` | JWT | List assignments |
| PUT | `/admin/update_assignment.php` | JWT | Update assignment |
| GET | `/admin/documents.php` | JWT | Admin document access |
| POST | `/admin/submit_acknowledgement.php` | JWT | Submit ITR acknowledgement |
| PUT | `/admin/update_status_step.php` | JWT | Update status step |
| GET | `/admin/analytics.php` | JWT (Admin) | Analytics/reports |
| GET/PUT | `/admin/concerns.php` | JWT | Concern management |
| GET | `/admin/payments.php` | JWT (Admin) | Payment list |
| GET/PUT | `/admin/orders.php` | JWT (Admin) | Order management |
| POST | `/admin/send_notification.php` | JWT (Admin) | Push notification |
| GET/PUT | `/admin/status_config.php` | JWT (Admin) | Status config |

---

## HTTP status codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created (signup) |
| 400 | Bad request / validation error |
| 401 | Unauthorized / invalid token |
| 404 | Not found |
| 405 | Method not allowed |
| 500 | Server error |

---

## Client-specific notes

### Mobile (`api_constants.dart`)

Base URL is compile-time: `http://allindiaitr.in`. For local dev, change to emulator IP (`10.0.2.2` on Android emulator).

### Admin (`endpoints.ts`)

Base URL from `VITE_API_BASE_URL` or Vite proxy `/api`. Login uses `/auth/login.php` (not `admin_login.php`).

---

## Postman & curl references

| Resource | Path |
|----------|------|
| Postman collection | `apps/api/ITR_API_Postman_Collection.json` |
| Curl examples | `apps/api/CURL_EXAMPLES.md` |
| Admin curl commands | `apps/api/ADMIN_PANEL_CURL_COMMANDS.md` |
| Payment tests | `apps/api/PAYMENT_API_TEST.md` |
| Full API docs | `apps/api/API_DOCUMENTATION.md` |

---

## When adding a new endpoint

1. Implement PHP file under the correct module folder.
2. Return the standard envelope `{ statusCode, status, data }`.
3. Add JWT check if protected.
4. Update this file and [SCREEN_API_MAP.md](./SCREEN_API_MAP.md).
5. Add to Postman collection if applicable.
