# Admin Panel - Complete cURL Commands Reference

## ⚠️ Important: Base URL Configuration

**Issue from Screenshot:** The frontend is trying to access `http://localhost:5173/api/auth/login.php`, but your PHP API is served from **Apache**, not the Vite dev server.

**Correct Base URLs:**
- **Local XAMPP (Default):** `http://localhost/api/`
- **If XAMPP on different port:** `http://localhost:8080/api/` (or your configured port)
- **Production:** `https://yourdomain.com/api/`

**Fix in Frontend:** Update your API base URL to point to the Apache server, not the Vite dev server port.

---

## Quick Start

1. **Get Authentication Token** (use Login endpoint below)
2. **Save the token** - You'll need it for all authenticated endpoints
3. **Replace `YOUR_TOKEN_HERE`** in all commands below with your actual token

---

## 🔐 Authentication Endpoints

### 1. User Signup

```bash
curl -X POST http://localhost/api/auth/signup.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123",
    "name": "Admin User",
    "mobile": "9876543210",
    "platform": "web",
    "version": "1.0"
  }'
```

**Response:**
```json
{
  "statusCode": 201,
  "status": "success",
  "data": {
    "message": "User registered successfully"
  }
}
```

---

### 2. Login (Get Token) ⭐ **START HERE**

```bash
curl -X POST http://localhost/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123",
    "platform": "web",
    "version": "1.0"
  }'
```

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "message": "Login successful",
    "UserId": 1,
    "email": "test@example.com",
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  }
}
```

**💡 Save the token from this response!**

---

### 3. Refresh Token

```bash
curl -X POST http://localhost/api/auth/refresh_token.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "message": "Token refreshed successfully",
    "UserId": 1,
    "email": "test@example.com",
    "token": "NEW_TOKEN_HERE"
  }
}
```

---

### 4. Forget Password

```bash
curl -X POST http://localhost/api/auth/forget_password.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "newpassword123"
  }'
```

---

### 5. Test Token

```bash
curl -X GET http://localhost/api/auth/test_token.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

---

## 👤 Personal Details Endpoints

### 6. Add/Update Personal Details

```bash
curl -X POST http://localhost/api/itrdetails/personal_details.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "panNumber": "ABCDE1234F",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "mobileNumber": "9876543210",
    "aadharCardNumber": "123456789012",
    "gender": "Male",
    "DATEOFBIRTH": "1990-01-15",
    "financialYear": "2024-25",
    "address": "123 Main St, City",
    "country": "India"
  }'
```

---

### 7. Get Personal Details

```bash
curl -X GET "http://localhost/api/itrdetails/get_personal_detail.php?UserId=1&PanNumber=ABCDE1234F" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

---

## 📄 Document Endpoints

### 8. Upload Document (Multipart Form Data)

```bash
curl -X POST http://localhost/api/itrdetails/add_documents.php \
  -F "PanNumber=ABCDE1234F" \
  -F "fileName=form16.pdf" \
  -F "file=@/path/to/your/document.pdf"
```

**Note:** Replace `/path/to/your/document.pdf` with actual file path.

**Windows Example:**
```bash
curl -X POST http://localhost/api/itrdetails/add_documents.php \
  -F "PanNumber=ABCDE1234F" \
  -F "fileName=form16.pdf" \
  -F "file=@C:\Users\username\Documents\form16.pdf"
```

---

### 9. Save Document Details

```bash
curl -X POST http://localhost/api/itrdetails/save_documents.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "PanNumber": "ABCDE1234F",
    "documents": [
      {
        "documentName": "Form 16",
        "fileType": "pdf",
        "filePassword": "",
        "fileName": "form16_abc123.pdf"
      },
      {
        "documentName": "PAN Card",
        "fileType": "jpg",
        "filePassword": "",
        "fileName": "pan_card_abc123.jpg"
      }
    ]
  }'
```

---

### 10. Get Documents

```bash
curl -X GET "http://localhost/api/itrdetails/get_documents.php?PanNumber=ABCDE1234F" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

---

### 11. Delete Document

```bash
curl -X POST http://localhost/api/itrdetails/delete_document.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "PanNumber": "ABCDE1234F",
    "fileName": "form16_abc123.pdf"
  }'
```

---

## 📦 Package Endpoints

### 12. Get All Packages

```bash
curl -X GET http://localhost/api/package/getPackages.php \
  -H "Content-Type: application/json"
```

**Note:** No authentication required.

---

## 💳 Payment Endpoints

### 13. Get Payment Information

```bash
# Get default payment info (no package)
curl -X GET http://localhost/api/payment/get_payment_info.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Get payment info with package ID
curl -X GET "http://localhost/api/payment/get_payment_info.php?packageId=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Get payment info with PAN and package
curl -X GET "http://localhost/api/payment/get_payment_info.php?panNumber=ABCDE1234F&packageId=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

---

### 14. Initiate Payment

```bash
curl -X POST http://localhost/api/payment/initiate_payment.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "panNumber": "ABCDE1234F",
    "packageId": 1
  }'
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "payment_id": "PAY1737024000ABC123",
    "order_id": "ORD1737024000XYZ789",
    "user_id": 1,
    "pan_number": "ABCDE1234F",
    "amount": 10262.46,
    "currency": "INR",
    "merchant_id": "RgSGKJiDNpMKj7",
    "message": "Payment initiated successfully"
  }
}
```

**💡 Save `payment_id` and `order_id` for status checks!**

---

### 15. Verify Payment

```bash
curl -X POST http://localhost/api/payment/verify_payment.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "ORD1737024000XYZ789",
    "paymentStatus": "success",
    "transactionId": "TXN123456789",
    "paymentMethod": "UPI",
    "gatewayName": "razorpay",
    "gatewayResponse": {
      "razorpay_payment_id": "pay_ABC123",
      "razorpay_order_id": "order_XYZ789"
    }
  }'
```

**For Failed Payment:**
```bash
curl -X POST http://localhost/api/payment/verify_payment.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "ORD1737024000XYZ789",
    "paymentStatus": "failed",
    "failureReason": "Payment declined by bank"
  }'
```

---

### 16. Get Payment Status

```bash
# Using payment ID
curl -X GET "http://localhost/api/payment/get_payment_status.php?paymentId=PAY1737024000ABC123" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Using order ID
curl -X GET "http://localhost/api/payment/get_payment_status.php?orderId=ORD1737024000XYZ789" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

---

### 17. Get Payment History

```bash
curl -X GET http://localhost/api/payment/get_payment_history.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

---

## 📊 ITR Status Endpoints

### 18. Get Order Status (by orderId)

```bash
curl -X GET "http://localhost/api/itr_status/get_order_status.php?orderId=ORD1737024000XYZ789" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

---

### 19. Get Order Status (by itrId)

```bash
curl -X GET "http://localhost/api/itr_status/get_order_status.php?itrId=5" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "orderId": "ORD1737024000XYZ789",
    "itrId": 5,
    "statusSteps": [
      {
        "step": "payment_success",
        "title": "Payment Success",
        "isCompleted": true,
        "completedAt": "2024-01-15 10:30:00",
        "order": 1,
        "hasConcern": false,
        "concern": null
      },
      {
        "step": "expert_assigned",
        "title": "Tax Expert Assigned",
        "isCompleted": false,
        "completedAt": null,
        "order": 2,
        "hasConcern": false,
        "concern": null
      }
    ],
    "overallStatus": "in_progress",
    "currentStep": 1,
    "totalSteps": 5
  }
}
```

---

### 20. Raise Text Concern

```bash
curl -X POST http://localhost/api/itr_status/raise_concern.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "ORD1737024000XYZ789",
    "statusStep": "documents_verified",
    "concernType": "text",
    "concernText": "PAN card image is not clear, please upload a clearer copy"
  }'
```

**Valid statusStep values:**
- `payment_success`
- `expert_assigned`
- `documents_verified`
- `filing_itr`
- `acknowledgement_generated`

---

### 21. Raise Image Concern

```bash
curl -X POST http://localhost/api/itr_status/raise_concern.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -F "orderId=ORD1737024000XYZ789" \
  -F "statusStep=documents_verified" \
  -F "concernType=image" \
  -F "concernText=Please verify the uploaded Form 16 document" \
  -F "image=@/path/to/your/image.jpg"
```

**Windows Example:**
```bash
curl -X POST http://localhost/api/itr_status/raise_concern.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -F "orderId=ORD1737024000XYZ789" \
  -F "statusStep=documents_verified" \
  -F "concernType=image" \
  -F "concernText=Please verify this document" \
  -F "image=@C:\Users\username\Desktop\form16_issue.jpg"
```

---

### 22. Resolve Concern (Admin)

```bash
# Resolve concern
curl -X POST http://localhost/api/itr_status/resolve_concern.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "concernId": 1,
    "status": "resolved",
    "resolutionNotes": "Document verified and approved. Proceeding to next step."
  }'

# Reject concern
curl -X POST http://localhost/api/itr_status/resolve_concern.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "concernId": 1,
    "status": "rejected",
    "resolutionNotes": "Document is still incomplete. Please upload the complete document."
  }'
```

**Valid status values:** `resolved` or `rejected`

---

## 📋 ITR Endpoints

### 23. Get ITR by User ID

```bash
curl -X GET "http://localhost/api/get_itrbyuser.php?userId=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

---

### 24. Get ITR by ITR ID

```bash
curl -X GET "http://localhost/api/get_itrbyitrid.php?itrId=5" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

---

## 🔧 Service Endpoints

### 25. Add Service

```bash
curl -X POST http://localhost/api/add_services.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Service Name"
  }'
```

---

## 🧪 Complete Test Flow (Admin Panel)

Here's a recommended test sequence for admin panel functionality:

```bash
# 1. Login to get token
TOKEN=$(curl -s -X POST http://localhost/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","platform":"web","version":"1.0"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo "Token: $TOKEN"

# 2. Get all packages (no auth required)
curl -X GET http://localhost/api/package/getPackages.php

# 3. Get ITR by user
curl -X GET "http://localhost/api/get_itrbyuser.php?userId=1" \
  -H "Authorization: Bearer $TOKEN"

# 4. Get order status (after payment)
curl -X GET "http://localhost/api/itr_status/get_order_status.php?orderId=ORD123456789" \
  -H "Authorization: Bearer $TOKEN"

# 5. Resolve a concern (admin action)
curl -X POST http://localhost/api/itr_status/resolve_concern.php \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "concernId": 1,
    "status": "resolved",
    "resolutionNotes": "Issue resolved by admin"
  }'

# 6. Get payment history
curl -X GET http://localhost/api/payment/get_payment_history.php \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🔍 Quick Reference Table

| # | Endpoint | Method | Auth Required | Purpose |
|---|----------|--------|---------------|---------|
| 1 | `/auth/signup.php` | POST | No | User registration |
| 2 | `/auth/login.php` | POST | No | **Get authentication token** ⭐ |
| 3 | `/auth/refresh_token.php` | POST | Yes | Refresh expired token |
| 4 | `/auth/forget_password.php` | POST | No | Reset password |
| 5 | `/auth/test_token.php` | GET | Yes | Validate token |
| 6 | `/itrdetails/personal_details.php` | POST | Yes | Add/update personal details |
| 7 | `/itrdetails/get_personal_detail.php` | GET | Yes | Get personal details |
| 8 | `/itrdetails/add_documents.php` | POST | No | Upload document file |
| 9 | `/itrdetails/save_documents.php` | POST | Yes | Save document metadata |
| 10 | `/itrdetails/get_documents.php` | GET | Yes | Get user documents |
| 11 | `/itrdetails/delete_document.php` | POST | Yes | Delete document |
| 12 | `/package/getPackages.php` | GET | No | Get all packages |
| 13 | `/payment/get_payment_info.php` | GET | Yes | Get payment breakdown |
| 14 | `/payment/initiate_payment.php` | POST | Yes | Create payment order |
| 15 | `/payment/verify_payment.php` | POST | Yes | Update payment status |
| 16 | `/payment/get_payment_status.php` | GET | Yes | Check payment status |
| 17 | `/payment/get_payment_history.php` | GET | Yes | Get all user payments |
| 18-19 | `/itr_status/get_order_status.php` | GET | Yes | Get order/ITR status |
| 20-21 | `/itr_status/raise_concern.php` | POST | Yes | Raise concern (text/image) |
| 22 | `/itr_status/resolve_concern.php` | POST | Yes | **Resolve concern (Admin)** |
| 23 | `/get_itrbyuser.php` | GET | Yes | Get ITRs by user |
| 24 | `/get_itrbyitrid.php` | GET | Yes | Get ITR by ID |
| 25 | `/add_services.php` | POST | Yes | Add new service |

---

## 🐛 Troubleshooting

### Issue: 404 Not Found
- **Problem:** Frontend calling wrong URL (e.g., `localhost:5173/api/...`)
- **Solution:** Update frontend API base URL to `http://localhost/api/` (Apache server)

### Issue: 401 Unauthorized
- **Problem:** Missing or invalid token
- **Solution:** Login again to get a fresh token, ensure token is sent as `Authorization: Bearer TOKEN`

### Issue: 500 Internal Server Error
- **Problem:** Database connection or PHP error
- **Solution:** Check Apache/PHP error logs, verify database is running

### Issue: CORS Error
- **Problem:** Browser blocking cross-origin requests
- **Solution:** All API endpoints have CORS headers. If still issues, check Apache configuration.

---

## 📝 Notes

1. **Token Expiry:** Default token expiry is 10 hours. Use refresh_token endpoint to get new token.
2. **File Uploads:** Use `-F` flag for multipart/form-data (documents, images)
3. **JSON Requests:** Use `-d` flag with `Content-Type: application/json` header
4. **Windows Users:** Use Git Bash or WSL for better curl compatibility
5. **Pretty JSON:** Add `| jq` at the end if you have `jq` installed: `curl ... | jq`

---

## 🔗 Related Documentation

- `RUN.md` - Complete setup and running guide
- `ITR_STATUS_API_CURL.md` - Detailed ITR status API documentation
- `PAYMENT_API_TEST.md` - Detailed payment API documentation
- `QUICK_START.md` - Quick setup guide

---

---

## 🎛️ Admin Panel Endpoints

All admin endpoints require authentication token. Make sure you have a valid token from login.

### 26. Admin Dashboard (Stats Overview) ⭐ **MAIN ADMIN ENDPOINT**

Get dashboard statistics and overview for admin panel.

```bash
curl -X GET http://localhost/api/admin/dashboard.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Response:**
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
    "packageStats": [
      {
        "id": 1,
        "name": "Basic",
        "price": 499.00,
        "orderCount": 30,
        "revenue": 150000.00
      }
    ],
    "paymentStatusBreakdown": [
      {
        "status": "success",
        "count": 65,
        "amount": 500000.00
      }
    ],
    "recentActivity": [...]
  }
}
```

---

### 27. Admin - List Users

Get all users with pagination, search, and role filtering.

**Query Parameters:**
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20, max: 100)
- `search` - Search by email, firstName, lastName, or mobile (optional)
- `role` - Filter by role: 'user', 'admin', 'CLIENT', etc. (inclusion - optional)
- `excludeRole` - Exclude users with this role: 'user', 'admin', 'CLIENT', etc. (exclusion - optional)
- **Note:** If both `role` and `excludeRole` are provided, `excludeRole` takes precedence

```bash
# List all users (page 1, 100 per page)
curl -X GET "http://localhost/api/admin/users.php?page=1&limit=100" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Get all users with CLIENT role (inclusion)
curl -X GET "http://localhost/api/admin/users.php?role=CLIENT&page=1&limit=100" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Get all users EXCEPT CLIENT role (exclusion - role != CLIENT)
curl -X GET "http://localhost/api/admin/users.php?excludeRole=CLIENT&page=1&limit=100" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Get all admin users
curl -X GET "http://localhost/api/admin/users.php?role=admin&page=1&limit=100" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Get all users EXCEPT admin role
curl -X GET "http://localhost/api/admin/users.php?excludeRole=admin&page=1&limit=100" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Get all regular users (role=user)
curl -X GET "http://localhost/api/admin/users.php?role=user&page=1&limit=100" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Search users with role filter (e.g., search for CLIENT users)
curl -X GET "http://localhost/api/admin/users.php?search=john&role=CLIENT&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Search users EXCLUDING CLIENT role
curl -X GET "http://localhost/api/admin/users.php?search=john&excludeRole=CLIENT&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Search users without role filter
curl -X GET "http://localhost/api/admin/users.php?search=test@example.com&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Combined: Get CLIENT role users with pagination
curl --location 'http://localhost/api/admin/users.php?role=CLIENT&page=1&limit=100' \
  --header 'Authorization: Bearer YOUR_TOKEN_HERE' \
  --header 'Content-Type: application/json'

# Combined: Get all users EXCEPT CLIENT role with pagination
curl --location 'http://localhost/api/admin/users.php?excludeRole=CLIENT&page=1&limit=100' \
  --header 'Authorization: Bearer YOUR_TOKEN_HERE' \
  --header 'Content-Type: application/json'
```

**Response (with role field):**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "users": [
      {
        "userId": 1,
        "firstName": "Test",
        "middleName": null,
        "lastName": "User",
        "email": "test@example.com",
        "mobile": "9876543210",
        "role": "CLIENT",
        "platform": "web",
        "createdAt": "2024-01-15 10:30:00",
        "paymentsCount": 5,
        "totalSpent": 50000.00
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 100,
      "total": 150,
      "totalPages": 2
    }
  }
}
```

---

### 28. Admin - Get Single User Details

```bash
curl -X GET "http://localhost/api/admin/users.php?userId=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Response (with role field):**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "user": {
      "userId": 1,
      "firstName": "Test",
      "middleName": null,
      "lastName": "User",
      "email": "test@example.com",
      "mobile": "9876543210",
      "role": "CLIENT",
      "platform": "web",
      "version": "1.0",
      "createdAt": "2024-01-15 10:30:00",
      "updatedAt": "2024-01-15 10:30:00",
      "statistics": {
        "personalDetailsCount": 2,
        "documentsCount": 5,
        "itrCount": 3,
        "paymentsCount": 5,
        "totalSpent": 50000.00
      }
    }
  }
}
```

---

### 29. Admin - Update User

```bash
curl -X PUT http://localhost/api/admin/users.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "firstName": "Updated",
    "lastName": "Name",
    "email": "updated@example.com",
    "mobile": "9876543211"
  }'
```

**Note:** Only include fields you want to update.

---

### 30. Admin - Delete User

```bash
curl -X DELETE "http://localhost/api/admin/users.php?userId=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**⚠️ Warning:** This will delete the user and all related data (cascade delete).

---

### 31. Admin - List Orders/ITRs

Get all orders with pagination and filters.

```bash
# List all orders
curl -X GET "http://localhost/api/admin/orders.php?page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Filter by payment status
curl -X GET "http://localhost/api/admin/orders.php?status=success&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "orders": [
      {
        "id": 1,
        "paymentId": "PAY123456",
        "orderId": "ORD123456",
        "userId": 1,
        "userEmail": "test@example.com",
        "userName": "Test User",
        "panNumber": "ABCDE1234F",
        "packageName": "Basic",
        "amount": 10262.46,
        "status": "success",
        "paymentMethod": "UPI",
        "createdAt": "2024-01-15 10:30:00",
        "paidAt": "2024-01-15 10:35:00"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 75,
      "totalPages": 4
    }
  }
}
```

---

### 32. Admin - Get Single Order Details

```bash
# By orderId
curl -X GET "http://localhost/api/admin/orders.php?orderId=ORD123456" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# By itrId
curl -X GET "http://localhost/api/admin/orders.php?itrId=5" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Response includes:** Full order details with status steps, user info, payment info, and ITR details.

---

### 33. Admin - Update Order Status

Update order/ITR status step.

```bash
curl -X PUT http://localhost/api/admin/orders.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "ORD123456",
    "statusStep": "expert_assigned",
    "isCompleted": true,
    "notes": "Expert assigned: John Doe"
  }'
```

**Valid statusStep values:**
- `payment_success`
- `expert_assigned`
- `documents_verified`
- `filing_itr`
- `acknowledgement_generated`

---

### 33a. Admin - Submit Acknowledgement (ITR completed & closed)

When the tax expert enters the acknowledgement number, this single API stores it, marks **filing_itr** and **acknowledgement_generated** complete, sets **itr_detail.status = COMPLETED**, and closes the assignment. Use this instead of calling update status step twice.

**Auth:** Bearer token – ADMIN, ACCOUNTANT, or CA only (client cannot call).

**Request body:**
- `itrId` (required) – ITR detail id
- `acknowledgementNumber` (required) – Acknowledgement number from Income Tax portal
- `acknowledgementDate` (optional) – e.g. `"2025-03-15"`
- `remarks` (optional)
- `itrForm` (optional) – e.g. `"ITR-1"`, `"ITR-2"`
- `assessmentYear` (optional) – e.g. `"2024-25"`

```bash
curl -X POST https://allindiaitr.in/api/admin/submit_acknowledgement.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "itrId": 24,
    "acknowledgementNumber": "ACK123456789",
    "acknowledgementDate": "2025-03-15",
    "remarks": "Filed via portal",
    "itrForm": "ITR-1",
    "assessmentYear": "2024-25"
  }'
```

**Minimal body (required fields only):**
```bash
curl -X POST https://allindiaitr.in/api/admin/submit_acknowledgement.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"itrId": 24, "acknowledgementNumber": "ACK123456789"}'
```

**Success response (200):**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Acknowledgement submitted. ITR marked completed and closed.",
    "itrId": 24,
    "acknowledgementNumber": "ACK123456789",
    "itrStatus": "COMPLETED",
    "stepsUpdated": ["filing_itr", "acknowledgement_generated"],
    "acknowledgementStored": true,
    "updatedBy": { "id": 2, "role": "ACCOUNTANT" },
    "timestamp": "2025-03-15 14:30:00"
  }
}
```

**Errors:** 400 (missing itrId/acknowledgementNumber, or acknowledgement number already registered), 401 (invalid token), 403 (not assigned / not professional), 404 (ITR not found).

---

### 34. Admin - List Payments

Get all payments with pagination and filters.

```bash
# List all payments
curl -X GET "http://localhost/api/admin/payments.php?page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Filter by status
curl -X GET "http://localhost/api/admin/payments.php?status=success&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Filter by date range
curl -X GET "http://localhost/api/admin/payments.php?fromDate=2024-01-01&toDate=2024-01-31&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Search payments
curl -X GET "http://localhost/api/admin/payments.php?search=PAY123456&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

---

### 35. Admin - Get Single Payment Details

```bash
# By paymentId
curl -X GET "http://localhost/api/admin/payments.php?paymentId=PAY123456" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# By orderId
curl -X GET "http://localhost/api/admin/payments.php?orderId=ORD123456" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

---

### 36. Admin - List Concerns

Get all concerns/raised issues with filters.

```bash
# List all concerns
curl -X GET "http://localhost/api/admin/concerns.php?page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Filter by status (pending, resolved, rejected)
curl -X GET "http://localhost/api/admin/concerns.php?status=pending&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Filter by type (text, image)
curl -X GET "http://localhost/api/admin/concerns.php?type=text&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Filter by orderId
curl -X GET "http://localhost/api/admin/concerns.php?orderId=ORD123456&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "concerns": [
      {
        "id": 1,
        "orderId": "ORD123456",
        "userId": 1,
        "userEmail": "test@example.com",
        "userName": "Test User",
        "statusStep": "documents_verified",
        "concernType": "text",
        "concernText": "PAN card image is not clear",
        "concernImagePath": null,
        "status": "pending",
        "createdAt": "2024-01-16 09:00:00"
      }
    ],
    "summary": [
      {
        "status": "pending",
        "count": 5
      },
      {
        "status": "resolved",
        "count": 10
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 15,
      "totalPages": 1
    }
  }
}
```

---

### 37. Admin - Get Single Concern Details

```bash
curl -X GET "http://localhost/api/admin/concerns.php?concernId=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

---

### 38. Admin - Resolve/Reject Concern

Resolve or reject a concern raised by users.

```bash
# Resolve concern
curl -X PUT http://localhost/api/admin/concerns.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "concernId": 1,
    "status": "resolved",
    "resolutionNotes": "Issue resolved. Documents verified and approved."
  }'

# Reject concern
curl -X PUT http://localhost/api/admin/concerns.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "concernId": 1,
    "status": "rejected",
    "resolutionNotes": "Documents are still incomplete. Please upload complete documents."
  }'
```

**Valid status values:** `resolved`, `rejected`

---

### 39. Admin - Analytics (Revenue)

Get revenue analytics and reports.

```bash
# Overall analytics (all types)
curl -X GET "http://localhost/api/admin/analytics.php?period=30" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Revenue analytics only
curl -X GET "http://localhost/api/admin/analytics.php?type=revenue&period=30" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# User analytics
curl -X GET "http://localhost/api/admin/analytics.php?type=users&period=30" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"

# Order analytics
curl -X GET "http://localhost/api/admin/analytics.php?type=orders&period=30" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "analytics": {
      "revenue": [
        {
          "date": "2024-01-15",
          "transactionCount": 5,
          "totalRevenue": 50000.00,
          "subtotal": 42000.00,
          "gstAmount": 8000.00
        }
      ],
      "revenueByPackage": [...],
      "revenueByMethod": [...],
      "users": [...],
      "usersByPlatform": [...],
      "orders": [...],
      "ordersByStatus": [...]
    },
    "overallStats": {
      "totalRevenue": 512500.50,
      "totalUsers": 150,
      "totalOrders": 75,
      "successfulOrders": 65,
      "averageOrderValue": 7884.62
    },
    "period": 30,
    "type": "overview"
  }
}
```

**Parameters:**
- `type`: `overview` (default), `revenue`, `users`, `orders`
- `period`: Number of days (default: 7)

---

## 📋 Admin Panel Endpoints Summary Table

| # | Endpoint | Method | Auth | Purpose |
|---|----------|--------|------|---------|
| 26 | `/admin/dashboard.php` | GET | Yes | **Get dashboard stats** ⭐ |
| 27 | `/admin/users.php` | GET | Yes | List all users (pagination, search, role filter) |
| 28 | `/admin/users.php?userId={id}` | GET | Yes | Get single user details |
| 29 | `/admin/users.php` | PUT | Yes | Update user |
| 30 | `/admin/users.php?userId={id}` | DELETE | Yes | Delete user |
| 31 | `/admin/orders.php` | GET | Yes | List all orders (pagination, filters) |
| 32 | `/admin/orders.php?orderId={id}` | GET | Yes | Get single order by orderId |
| 32 | `/admin/orders.php?itrId={id}` | GET | Yes | Get single order by itrId |
| 33 | `/admin/orders.php` | PUT | Yes | Update order status |
| 34 | `/admin/payments.php` | GET | Yes | List all payments (pagination, filters) |
| 35 | `/admin/payments.php?paymentId={id}` | GET | Yes | Get single payment details |
| 35 | `/admin/payments.php?orderId={id}` | GET | Yes | Get payment by orderId |
| 36 | `/admin/concerns.php` | GET | Yes | List all concerns (filters) |
| 37 | `/admin/concerns.php?concernId={id}` | GET | Yes | Get single concern details |
| 38 | `/admin/concerns.php` | PUT | Yes | Resolve/reject concern |
| 39 | `/admin/analytics.php` | GET | Yes | Get analytics/reports |

---

## 🚀 Admin Panel Setup Instructions

### Step 1: Setup Admin Tables

Run the admin tables setup SQL:

```bash
# Using phpMyAdmin:
# 1. Open phpMyAdmin: http://localhost/phpmyadmin
# 2. Select 'itr_services' database
# 3. Go to SQL tab
# 4. Copy and paste contents of setup_admin_tables.sql
# 5. Click Go

# Or using MySQL command line:
mysql -u root -p itr_services < setup_admin_tables.sql
```

### Step 2: Create Admin User (Optional)

```bash
# Update existing test user to admin
# Run in phpMyAdmin SQL tab:
UPDATE users SET Role = 'admin' WHERE Email = 'test@example.com';
```

### Step 3: Test Admin Dashboard

```bash
# 1. Login to get token
TOKEN=$(curl -s -X POST http://localhost/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","platform":"web","version":"1.0"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# 2. Test dashboard endpoint
curl -X GET http://localhost/api/admin/dashboard.php \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

---

## 💡 Admin Panel Features

✅ **Dashboard Statistics:**
- Total users, orders, payments
- Revenue (total, today, this month)
- Recent activity
- Package statistics
- Payment status breakdown

✅ **User Management:**
- List users with pagination & search
- View user details with statistics
- Update user information
- Delete users

✅ **Order Management:**
- List all orders with filters
- View order details with status steps
- Update order/ITR status
- Track order progress

✅ **Payment Management:**
- List all payments with filters
- View payment details
- Filter by status, date range, search
- Payment summary statistics

✅ **Concern Management:**
- List all concerns with filters
- View concern details
- Resolve/reject concerns
- Track concern status

✅ **Analytics & Reports:**
- Revenue analytics (daily, by package, by method)
- User analytics (daily registrations, by platform)
- Order analytics (daily orders, by status)
- Overall statistics

---

**Last Updated:** 2025-01-17
