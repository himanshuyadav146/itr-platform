# ITR Detailed Status API Documentation

## Overview
This API provides comprehensive status information for ITR orders, including workflow status, payment status, assignment status, and ITR details in a single response.

## Endpoint
```
GET /itr_status/get_detailed_status.php
```

## Authentication
Requires JWT token in Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

## Query Parameters
At least one of the following is required:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| orderId | string | conditional | Payment order ID (e.g., ORD_1737176537_1) |
| itrId | integer | conditional | ITR detail ID |

## Response Structure

### Success Response (200)
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "orderId": "ORD_1737176537_1",
    "itrId": 5,
    "userId": 1,
    "panNumber": "ABCDE1234F",
    
    "itrStatus": {
      "steps": [...],
      "overallStatus": "in_progress",
      "currentStep": 2,
      "totalSteps": 5,
      "progressPercentage": 40
    },
    
    "paymentStatus": {...},
    "assignmentStatus": {...},
    "itrDetails": {...}
  }
}
```

## Data Objects

### 1. itrStatus Object
Tracks the 5-step ITR processing workflow.

#### Structure:
```json
{
  "steps": [
    {
      "step": "payment_success",
      "title": "Payment Success",
      "order": 1,
      "isCompleted": true,
      "completedAt": "2026-01-18 10:30:00",
      "hasConcern": false,
      "notes": "Payment completed via Razorpay",
      "concern": null
    },
    {
      "step": "expert_assigned",
      "title": "Tax Expert Assigned",
      "order": 2,
      "isCompleted": true,
      "completedAt": "2026-01-18 11:00:00",
      "hasConcern": false,
      "notes": "Assigned to CA Sharma",
      "concern": null
    },
    {
      "step": "documents_verified",
      "title": "Documents Verification",
      "order": 3,
      "isCompleted": false,
      "completedAt": null,
      "hasConcern": true,
      "notes": null,
      "concern": {
        "id": 1,
        "type": "text",
        "message": "Form 16 is missing",
        "status": "pending",
        "createdAt": "2026-01-18 12:00:00",
        "imageUrl": null
      }
    },
    {
      "step": "filing_itr",
      "title": "Filing ITR",
      "order": 4,
      "isCompleted": false,
      "completedAt": null,
      "hasConcern": false,
      "notes": null,
      "concern": null
    },
    {
      "step": "acknowledgement_generated",
      "title": "Acknowledgement Generated",
      "order": 5,
      "isCompleted": false,
      "completedAt": null,
      "hasConcern": false,
      "notes": null,
      "concern": null
    }
  ],
  "overallStatus": "concern_pending",
  "currentStep": 2,
  "totalSteps": 5,
  "progressPercentage": 40
}
```

#### Status Steps (5 steps):
1. **payment_success** - Payment Success
2. **expert_assigned** - Tax Expert Assigned
3. **documents_verified** - Documents Verification
4. **filing_itr** - Filing ITR
5. **acknowledgement_generated** - Acknowledgement Generated

#### Overall Status Values:
- `pending` - No steps completed
- `in_progress` - Some steps completed
- `concern_pending` - Has pending concerns requiring action
- `completed` - All steps completed

### 2. paymentStatus Object
Contains payment information from the payment gateway.

#### Structure:
```json
{
  "paymentId": "PAY_1737176537_1",
  "orderId": "ORD_1737176537_1",
  "amount": 999.00,
  "gst": 179.82,
  "grandTotal": 1178.82,
  "status": "success",
  "paymentMethod": "UPI",
  "gatewayName": "Razorpay",
  "transactionId": "pay_ABC123XYZ",
  "paidAt": "2026-01-18 10:30:00",
  "createdAt": "2026-01-18 10:25:00",
  "failureReason": null
}
```

#### Payment Status Values:
- `pending` - Payment is pending
- `success` - Payment completed successfully
- `failed` - Payment failed
- `cancelled` - Payment was cancelled

### 3. assignmentStatus Object
Information about ITR assignment to tax professionals.

#### Structure:
```json
{
  "assignmentId": 3,
  "professionalId": 10,
  "professionalName": "CA Sharma",
  "professionalEmail": "ca.sharma@example.com",
  "professionalMobile": "9876543210",
  "professionalRole": "CA",
  "status": "in_progress",
  "priority": "normal",
  "assignedAt": "2026-01-18 11:00:00",
  "dueDate": "2026-01-25 23:59:59",
  "completedAt": null,
  "notes": "High priority case"
}
```

#### Assignment Status Values:
- `assigned` - Newly assigned
- `in_progress` - Professional is working on it
- `completed` - ITR filing completed
- `rejected` - Assignment rejected

#### Priority Values:
- `low` - Low priority
- `normal` - Normal priority
- `high` - High priority
- `urgent` - Urgent priority

### 4. itrDetails Object
Basic ITR and user information.

#### Structure:
```json
{
  "itrId": 5,
  "userId": 1,
  "panNumber": "ABCDE1234F",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "mobile": "9876543210",
  "financialYear": "2023-2024",
  "packageId": 2,
  "packageName": "Capital Gains",
  "documentsCount": 5,
  "createdAt": "2026-01-18 10:00:00"
}
```

## Usage Examples

### Example 1: Get status by Order ID
```bash
curl 'https://allindiaitr.in/api/itr_status/get_detailed_status.php?orderId=ORD_1737176537_1' \
  -H 'Authorization: Bearer eyJhbGdvIjoiSFMyNTYi...'
```

### Example 2: Get status by ITR ID
```bash
curl 'https://allindiaitr.in/api/itr_status/get_detailed_status.php?itrId=5' \
  -H 'Authorization: Bearer eyJhbGdvIjoiSFMyNTYi...'
```

### Example 3: JavaScript/React
```javascript
const getDetailedStatus = async (orderId) => {
  const response = await fetch(
    `https://allindiaitr.in/api/itr_status/get_detailed_status.php?orderId=${orderId}`,
    {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    }
  );
  
  const data = await response.json();
  
  if (data.status === 'success') {
    console.log('Overall Status:', data.data.itrStatus.overallStatus);
    console.log('Progress:', data.data.itrStatus.progressPercentage + '%');
    console.log('Payment Status:', data.data.paymentStatus.status);
    console.log('Professional:', data.data.assignmentStatus?.professionalName);
  }
};
```

## Error Responses

### 400 Bad Request
Missing required parameters:
```json
{
  "status": "error",
  "statusCode": 400,
  "data": {
    "message": "orderId or itrId is required"
  }
}
```

### 401 Unauthorized
Invalid or missing token:
```json
{
  "status": "error",
  "statusCode": 401,
  "data": {
    "message": "Authorization token required"
  }
}
```

### 404 Not Found
No data found for the provided orderId or itrId:
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "orderId": null,
    "itrId": null,
    "userId": 1,
    "panNumber": null,
    "itrStatus": {
      "steps": [...],
      "overallStatus": "pending",
      "currentStep": 0,
      "totalSteps": 5,
      "progressPercentage": 0
    },
    "paymentStatus": null,
    "assignmentStatus": null,
    "itrDetails": null
  }
}
```

## Status Enums

### ITR Status Steps
```
payment_success
expert_assigned
documents_verified
filing_itr
acknowledgement_generated
```

### Overall Status
```
pending
in_progress
concern_pending
completed
```

### Payment Status
```
pending
success
failed
cancelled
```

### Assignment Status
```
assigned
in_progress
completed
rejected
```

### Concern Status
```
pending
resolved
rejected
```

## Database Tables Used
- `itr_order_status` - ITR workflow status tracking
- `itr_order_concerns` - Concerns raised for each step
- `payment_info` - Payment information
- `itr_assignments` - Professional assignments
- `itr_detail` - ITR details
- `personal_details` - User personal information
- `packages` - ITR packages
- `document_details` - Uploaded documents
- `users` - User information

## Related APIs
- `POST /itr_status/raise_concern.php` - Raise a concern for a status step
- `PUT /itr_status/resolve_concern.php` - Resolve a concern (admin)
- `GET /itr_status/get_order_status.php` - Get only ITR workflow status
- `POST /admin/assign_itr.php` - Assign ITR to professional
- `PUT /admin/update_assignment.php` - Update assignment status

## Notes
- The API returns `null` for objects that don't exist (e.g., if no payment or assignment found)
- All monetary values are in INR (Indian Rupees)
- Timestamps are in MySQL datetime format (YYYY-MM-DD HH:MM:SS)
- Progress percentage is calculated as: (currentStep / totalSteps) * 100
- If a step has a pending concern, it cannot be marked as completed until the concern is resolved
