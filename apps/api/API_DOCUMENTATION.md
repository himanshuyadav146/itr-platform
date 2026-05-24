# ITR API - Complete API Documentation

## Table of Contents

1. [Authentication APIs](#authentication-apis)
2. [Personal Details APIs](#personal-details-apis)
3. [Document Management APIs](#document-management-apis)
4. [Payment APIs](#payment-apis)
5. [ITR Management APIs](#itr-management-apis)
6. [Status Tracking APIs](#status-tracking-apis)
7. [Admin Panel APIs](#admin-panel-apis)
8. [ITR Assignment APIs](#itr-assignment-apis)

---

## Base URL

```
http://localhost/api
```

**Note:** Replace with your production URL in production environment.

---

## Authentication

Most APIs require authentication using JWT tokens. Include the token in the Authorization header:

```
Authorization: Bearer {your_jwt_token}
```

---

## Authentication APIs

### 1. User Signup

**Endpoint:** `POST /auth/signup.php`

**Description:** Register a new user account

**Request Body:**
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

### 2. User Login

**Endpoint:** `POST /auth/login.php`

**Description:** Authenticate user and get JWT token

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "platform": "web",
  "version": "1.0"
}
```

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "message": "Login successful",
    "UserId": 1,
    "email": "user@example.com",
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
  }
}
```

---

### 3. Refresh Token

**Endpoint:** `POST /auth/refresh_token.php`

**Description:** Refresh the JWT token

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "message": "Token refreshed successfully",
    "UserId": 1,
    "token": "new_token_here"
  }
}
```

---

### 4. Forgot Password

**Endpoint:** `POST /auth/forget_password.php`

**Description:** Reset user password

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "newpassword123"
}
```

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "message": "Password updated successfully"
  }
}
```

---

### 4a. Delete Account

**Endpoint:** `POST /auth/delete_account.php`

**Description:** Permanently delete the authenticated user's account and all associated data (personal details, documents, ITR records, payments, etc.). Requires JWT token. User can only delete their own account.

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body (optional - for extra confirmation):**
```json
{
  "password": "current_password"
}
```

**Response (success):**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "message": "Your account and all associated data have been permanently deleted."
  }
}
```

**Notes:**
- Professional accounts (ADMIN, CA, ACCOUNTANT) cannot be deleted via this endpoint
- All uploaded documents and concern images are also deleted from disk
- This action is irreversible

---

## Personal Details APIs

### 5. Add/Update Personal Details

**Endpoint:** `POST /itrdetails/personal_details.php`

**Description:** Add or update personal details for ITR filing

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "panNumber": "ABCDE1234F",
  "firstName": "John",
  "middleName": "",
  "lastName": "Doe",
  "email": "john@example.com",
  "mobileNumber": "9876543210",
  "aadharCardNumber": "123456789012",
  "gender": "Male",
  "DATEOFBIRTH": "1990-01-15",
  "financialYear": "2024-25",
  "address": "123 Main Street, City, State",
  "country": "India"
}
```

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "message": "Personal details saved successfully",
    "id": 1
  }
}
```

---

### 6. Get Personal Details

**Endpoint:** `GET /itrdetails/get_personal_detail.php`

**Description:** Retrieve personal details by UserId and PAN number

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `UserId` (required): User ID
- `PanNumber` (required): PAN number

**Example:**
```
GET /itrdetails/get_personal_detail.php?UserId=1&PanNumber=ABCDE1234F
```

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "id": 1,
    "UserId": 1,
    "PANNumber": "ABCDE1234F",
    "FirstName": "John",
    "LastName": "Doe",
    "EMAIL": "john@example.com",
    "MobileNumber": "9876543210",
    ...
  }
}
```

---

## Document Management APIs

### 7. Upload Document

**Endpoint:** `POST /itrdetails/add_documents.php`

**Description:** Upload a document file

**Headers:**
```
Authorization: Bearer {token}
```

**Request:** `multipart/form-data`
- `PanNumber`: PAN number (required)
- `fileName`: Document name (required)
- `file`: File to upload (required) - Supports: jpg, jpeg, png, pdf

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "message": "Document uploaded successfully",
    "fileName": "form16_abc123.pdf"
  }
}
```

---

### 8. Save Document Details

**Endpoint:** `POST /itrdetails/save_documents.php`

**Description:** Save document metadata to database

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
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

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "message": "Documents saved successfully"
  }
}
```

---

### 9. Get Documents

**Endpoint:** `GET /itrdetails/get_documents.php`

**Description:** Get all documents for a PAN number

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `PanNumber` (required): PAN number

**Example:**
```
GET /itrdetails/get_documents.php?PanNumber=ABCDE1234F
```

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": [
    {
      "id": 1,
      "PanNumber": "ABCDE1234F",
      "name": "Form 16",
      "type": "pdf",
      "fileName": "form16_abc123.pdf",
      ...
    }
  ]
}
```

---

### 10. Delete Document

**Endpoint:** `POST /itrdetails/delete_document.php`

**Description:** Delete a document

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "id": 1,
  "PanNumber": "ABCDE1234F",
  "fileName": "form16_abc123.pdf"
}
```

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "message": "Document deleted successfully"
  }
}
```

---

### 11. Download Document

**Endpoint:** `GET /itrdetails/download_document.php`

**Description:** Download a document file

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `PanNumber` (required): PAN number
- `fileName` (required): File name to download

**Example:**
```
GET /itrdetails/download_document.php?PanNumber=ABCDE1234F&fileName=form16_abc123.pdf
```

---

## Payment APIs

### 12. Get Payment Information

**Endpoint:** `GET /payment/get_payment_info.php`

**Description:** Get payment information including package and fees

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `packageId` (optional): Package ID
- `panNumber` (optional): PAN number

**Example:**
```
GET /payment/get_payment_info.php?packageId=1&panNumber=ABCDE1234F
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
        "display_title": "Basic Package",
        "display_value": "₹499",
        "amount": 499
      },
      {
        "display_title": "E-Filing Fee",
        "display_value": "₹7999",
        "amount": 7999
      }
    ],
    "total": {
      "subtotal": 8498,
      "gst_percentage": 18,
      "gst_amount": 1529.64,
      "grand_total": 10027.64
    },
    "gateway_details": {
      "mode": "test",
      "gateway": "razorpay",
      "key_id": "rzp_test_xxxx",
      "merchant_id": ""
    },
    "package": { "id": 1, "name": "Basic", "description": "...", "turnover": "", "price": "₹499", "icon": "", "color": "" }
  }
}
```

**Note:** `gateway_details` is dynamic from `include/payment_config.php` (test/live mode). See PAYMENT_SETUP.md.

---

### 13. Initiate Payment

**Endpoint:** `POST /payment/initiate_payment.php`

**Description:** Initiate payment and get payment gateway details

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "packageId": 1,
  "panNumber": "ABCDE1234F"
}
```
(Amount is calculated from package + additional fees; no need to send.)

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "payment_id": "PAY123456789",
    "order_id": "ORD123456789",
    "user_id": 1,
    "pan_number": "ABCDE1234F",
    "amount": 10027.64,
    "currency": "INR",
    "merchant_id": "",
    "redirect_url": "https://yourdomain.com/api/payment/success.php",
    "gateway": {
      "name": "razorpay",
      "mode": "test",
      "key_id": "rzp_test_xxxx"
    },
    "razorpay_order_id": "order_xxxx",
    "message": "Payment initiated successfully. Use key_id and redirect_url (or razorpay_order_id) to open gateway checkout."
  }
}
```
`redirect_url`, `gateway`, and `razorpay_order_id` (if Razorpay SDK is installed) are dynamic; switch test/live via `include/payment_config.php`. See PAYMENT_SETUP.md.

---

### 14. Get Payment Status

**Endpoint:** `GET /payment/get_payment_status.php`

**Description:** Get payment status by payment ID or order ID

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `paymentId` (optional): Payment ID
- `orderId` (optional): Order ID

**Example:**
```
GET /payment/get_payment_status.php?paymentId=PAY123456789
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "payment_id": "PAY123456789",
    "payment_status": "success",
    "transaction_id": "TXN123456789",
    "amount": 10027.64,
    ...
  }
}
```

---

### 15. Get Payment History

**Endpoint:** `GET /payment/get_payment_history.php`

**Description:** Get payment history for a user

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": [
    {
      "payment_id": "PAY123456789",
      "amount": 10027.64,
      "payment_status": "success",
      "created_at": "2024-01-15 10:30:00",
      ...
    }
  ]
}
```

---

### 16. Verify Payment

**Endpoint:** `POST /payment/verify_payment.php`

**Description:** Verify payment after gateway callback

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "orderId": "ORD123456789",
  "transactionId": "TXN123456789"
}
```

---

### 17. Payment Webhook

**Endpoint:** `POST /payment/webhook.php`

**Description:** Receive payment status from payment gateway (called by gateway)

**Note:** This endpoint is called by the payment gateway, not directly by clients.

---

## ITR Management APIs

### 18. Get ITR by User ID

**Endpoint:** `GET /get_itrbyuser.php`

**Description:** Get all ITR records (personal details) for a user with documents and status. Use `itrStatus` and `paymentStatus` for UI filtering.

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `userId` (optional): User ID – if omitted, uses UserId from token

**Example:**
```
GET /get_itrbyuser.php?userId=1
```

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "personalDetails": [
      {
        "id": 1,
        "UserId": 1,
        "PANNumber": "ABCDE1234F",
        "FirstName": "John",
        "LastName": "Doe",
        "FinancialYear": "2024-25",
        "documents": [...],
        "documentCount": 2,
        "orderId": "ORD_1234567890",
        "paymentStatus": "success",
        "itrStatus": "in_progress",
        "statusDisplayText": "In Progress"
      }
    ],
    "count": 1,
    "message": "Personal details found"
  }
}
```

**Status fields (for UI filter):**
| Field | Values | Description |
|-------|--------|-------------|
| `itrStatus` | `pending_payment`, `pending`, `in_progress`, `concern_pending`, `completed` | ITR workflow status |
| `paymentStatus` | `success`, or `null` if not paid | Payment gateway status |
| `orderId` | Order ID or `null` | Payment order reference |
| `statusDisplayText` | "Pending", "In Progress", "Action Required", "Completed" | Human-readable label |

---

### 19. Get ITR by ITR ID

**Endpoint:** `GET /get_itrbyitrid.php`

**Description:** Get ITR details by ITR ID

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `itrId` (required): ITR ID

**Example:**
```
GET /get_itrbyitrid.php?itrId=1
```

---

### 20. Get Packages

**Endpoint:** `GET /package/getPackages.php`

**Description:** Get all available ITR packages

**No authentication required**

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": [
    {
      "id": 1,
      "packagename": "Basic",
      "price": 499.00,
      "title1": "Basic ITR Filing",
      "description1": "For individuals with salary income only",
      ...
    }
  ]
}
```

---

### 20a. Delete Package

**Endpoint:** `POST /package/deletePackage.php`

**Description:** Delete a package (Admin/Professional only)

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "id": 3
}
```

**Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "message": "Package deleted successfully",
    "packageId": 3
  }
}
```

---

## Status Tracking APIs

### 21. Get Order Status

**Endpoint:** `GET /itr_status/get_order_status.php`

**Description:** Get status steps for an order

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `orderId` (required): Order ID
- `itrId` (optional): ITR ID

**Example:**
```
GET /itr_status/get_order_status.php?orderId=ORD123456789
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "orderId": "ORD123456789",
    "statusSteps": [
      {
        "step": "payment_success",
        "title": "Payment Success",
        "isCompleted": true,
        "completedAt": "2024-01-15 10:30:00",
        "order": 1,
        "hasConcern": false
      },
      {
        "step": "expert_assigned",
        "title": "Tax Expert Assigned",
        "isCompleted": false,
        "order": 2,
        "hasConcern": false
      }
    ]
  }
}
```

---

### 22. Raise Concern

**Endpoint:** `POST /itr_status/raise_concern.php`

**Description:** Raise a concern for an order status step

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "orderId": "ORD123456789",
  "statusStep": "expert_assigned",
  "concernType": "text",
  "concernText": "I have a question about my assignment"
}
```

**For image concern:**
```json
{
  "orderId": "ORD123456789",
  "statusStep": "expert_assigned",
  "concernType": "image",
  "concernImage": "base64_encoded_image_data"
}
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Concern raised successfully",
    "concernId": 1
  }
}
```

---

### 23. Resolve Concern

**Endpoint:** `POST /itr_status/resolve_concern.php`

**Description:** Resolve a concern (Admin only)

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "concernId": 1,
  "status": "resolved",
  "resolutionNotes": "Issue has been resolved"
}
```

---

## Admin Panel APIs

### 24. Dashboard Statistics

**Endpoint:** `GET /admin/dashboard.php`

**Description:** Get dashboard statistics (Admin only)

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "totalUsers": 100,
    "totalOrders": 50,
    "totalPayments": 45,
    "totalRevenue": 500000,
    ...
  }
}
```

---

### 25. Get Users

**Endpoint:** `GET /admin/users.php`

**Description:** Get users list with filters (Admin only)

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `role` (optional): Filter by role (CLIENT, ADMIN, ACCOUNTANT, CA)
- `page` (optional): Page number
- `limit` (optional): Items per page

**Example:**
```
GET /admin/users.php?role=ACCOUNTANT&page=1&limit=10
```

---

### 26. Get Orders

**Endpoint:** `GET /admin/orders.php`

**Description:** Get orders list (Admin only)

**Headers:**
```
Authorization: Bearer {token}
```

---

### 27. Get Payments

**Endpoint:** `GET /admin/payments.php`

**Description:** Get payments list (Admin only)

**Headers:**
```
Authorization: Bearer {token}
```

---

### 28. Get ITRs

**Endpoint:** `GET /admin/itrs.php`

**Description:** Get ITRs list (Admin only)

**Headers:**
```
Authorization: Bearer {token}
```

---

### 29. Get Concerns

**Endpoint:** `GET /admin/concerns.php`

**Description:** Get concerns list (Admin only)

**Headers:**
```
Authorization: Bearer {token}
```

---

### 30. Get Analytics

**Endpoint:** `GET /admin/analytics.php`

**Description:** Get analytics data (Admin only)

**Headers:**
```
Authorization: Bearer {token}
```

---

## ITR Assignment APIs

### 31. Assign ITR to Professional

**Endpoint:** `POST /admin/assign_itr.php`

**Description:** Assign ITR to a professional/accountant (Admin only)

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "itrId": 1,
  "orderId": "ORD123456789",
  "professionalId": 5,
  "priority": "high",
  "dueDate": "2024-02-15",
  "notes": "Urgent assignment"
}
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "ITR assigned successfully",
    "assignmentId": 1
  }
}
```

---

### 32. Get Assignments

**Endpoint:** `GET /admin/get_assignments.php`

**Description:** Get ITR assignments list (Admin only)

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `professionalId` (optional): Filter by professional ID
- `status` (optional): Filter by status (assigned, in_progress, completed, rejected)

**Example:**
```
GET /admin/get_assignments.php?professionalId=5&status=assigned
```

---

### 33. Update Assignment

**Endpoint:** `POST /admin/update_assignment.php`

**Description:** Update assignment status (Admin only)

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "assignmentId": 1,
  "status": "in_progress",
  "priority": "urgent",
  "notes": "Updated status"
}
```

---

## Error Responses

All APIs return error responses in the following format:

```json
{
  "statusCode": 400,
  "status": "error",
  "message": "Error message here",
  "data": null
}
```

**Common Status Codes:**
- `200`: Success
- `201`: Created
- `400`: Bad Request
- `401`: Unauthorized (Invalid/Missing token)
- `403`: Forbidden (Insufficient permissions)
- `404`: Not Found
- `500`: Internal Server Error

---

## Database Schema

See `ITR_API_Diagrams.pdf` for complete database ER diagram and schema documentation.

---

## Base URL Configuration

Update the base URL in your client application:
- **Local Development:** `http://localhost/api`
- **Production:** `https://yourdomain.com/api`

---

**Document Version:** 1.0  
**Last Updated:** January 2024  
**Generated:** 2024-01-11
