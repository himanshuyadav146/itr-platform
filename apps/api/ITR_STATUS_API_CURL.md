# ITR Order Status API - cURL Commands for Postman

## Prerequisites

1. **Setup Database**: Run `setup_itr_status_table.sql` in your database
2. **Get Authentication Token**: Login first to get your token

---

## Step 1: Get Authentication Token

First, login to get your token:

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

**Save the token** from the response. You'll need it for all ITR status APIs.

**Example Response:**
```json
{
  "statusCode": 200,
  "status": "success",
  "data": {
    "message": "Login successful",
    "UserId": 1,
    "email": "test@example.com",
    "token": "YOUR_TOKEN_HERE"
  }
}
```

---

## Step 2: ITR Order Status APIs

Replace `YOUR_TOKEN_HERE` with the actual token from Step 1.
Replace `YOUR_ORDER_ID` and `YOUR_ITR_ID` with actual values from your database.

---

### 1. Get Order Status (by orderId)

**GET** - Retrieve status steps for an order using orderId

```bash
curl -X GET "http://localhost/api/itr_status/get_order_status.php?orderId=YOUR_ORDER_ID" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Example with actual orderId:**
```bash
curl -X GET "http://localhost/api/itr_status/get_order_status.php?orderId=ORD123456789" \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "orderId": "ORD123456789",
    "itrId": null,
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
      },
      {
        "step": "documents_verified",
        "title": "Documents Verification",
        "isCompleted": false,
        "completedAt": null,
        "order": 3,
        "hasConcern": false,
        "concern": null
      },
      {
        "step": "filing_itr",
        "title": "Filing ITR",
        "isCompleted": false,
        "completedAt": null,
        "order": 4,
        "hasConcern": false,
        "concern": null
      },
      {
        "step": "acknowledgement_generated",
        "title": "Acknowledgement Generated",
        "isCompleted": false,
        "completedAt": null,
        "order": 5,
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

### 2. Get Order Status (by itrId)

**GET** - Retrieve status steps for an order using itrId

```bash
curl -X GET "http://localhost/api/itr_status/get_order_status.php?itrId=YOUR_ITR_ID" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Example with actual itrId:**
```bash
curl -X GET "http://localhost/api/itr_status/get_order_status.php?itrId=5" \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json"
```

---

### 3. Raise Text Concern

**POST** - Raise a text concern for any status step

```bash
curl -X POST http://localhost/api/itr_status/raise_concern.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "YOUR_ORDER_ID",
    "statusStep": "documents_verified",
    "concernType": "text",
    "concernText": "PAN card image is not clear, please upload a clearer copy"
  }'
```

**Example with actual values:**
```bash
curl -X POST http://localhost/api/itr_status/raise_concern.php \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "ORD123456789",
    "statusStep": "documents_verified",
    "concernType": "text",
    "concernText": "Form 16 document is missing signature page. Please upload complete document."
  }'
```

**Valid statusStep values:**
- `payment_success`
- `expert_assigned`
- `documents_verified`
- `filing_itr`
- `acknowledgement_generated`

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Concern raised successfully",
    "concern": {
      "id": 1,
      "type": "text",
      "message": "Form 16 document is missing signature page. Please upload complete document.",
      "status": "pending",
      "createdAt": "2024-01-16 09:00:00",
      "imageUrl": null
    }
  }
}
```

---

### 4. Raise Image Concern

**POST** - Raise an image concern (multipart/form-data)

```bash
curl -X POST http://localhost/api/itr_status/raise_concern.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -F "orderId=YOUR_ORDER_ID" \
  -F "statusStep=documents_verified" \
  -F "concernType=image" \
  -F "concernText=Please verify the uploaded Form 16 document" \
  -F "image=@/path/to/your/image.jpg"
```

**Example with actual file:**
```bash
curl -X POST http://localhost/api/itr_status/raise_concern.php \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." \
  -F "orderId=ORD123456789" \
  -F "statusStep=documents_verified" \
  -F "concernType=image" \
  -F "concernText=Please verify this document" \
  -F "image=@/Users/username/Desktop/form16_issue.jpg"
```

**Note for Windows:**
```bash
curl -X POST http://localhost/api/itr_status/raise_concern.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -F "orderId=ORD123456789" \
  -F "statusStep=documents_verified" \
  -F "concernType=image" \
  -F "concernText=Please verify this document" \
  -F "image=@C:\Users\username\Desktop\form16_issue.jpg"
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Concern raised successfully",
    "concern": {
      "id": 2,
      "type": "image",
      "message": "Please verify this document",
      "status": "pending",
      "createdAt": "2024-01-16 09:15:00",
      "imageUrl": "uploads/concerns/ORD123456789/concern_67890abc123.jpg"
    }
  }
}
```

---

### 5. Resolve Concern (Admin)

**POST** - Resolve or reject a concern

```bash
curl -X POST http://localhost/api/itr_status/resolve_concern.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "concernId": 1,
    "status": "resolved",
    "resolutionNotes": "Document verified and approved. Proceeding to next step."
  }'
```

**Example with actual concernId:**
```bash
curl -X POST http://localhost/api/itr_status/resolve_concern.php \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "concernId": 1,
    "status": "resolved",
    "resolutionNotes": "Document has been verified. All requirements met. Proceeding to filing."
  }'
```

**To reject a concern:**
```bash
curl -X POST http://localhost/api/itr_status/resolve_concern.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "concernId": 1,
    "status": "rejected",
    "resolutionNotes": "Document is still incomplete. Please upload the complete document."
  }'
```

**Valid status values:**
- `resolved` - Concern is resolved, step can proceed
- `rejected` - Concern is rejected, user needs to address it

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Concern resolved successfully",
    "concern": {
      "id": 1,
      "type": "text",
      "message": "Form 16 document is missing signature page. Please upload complete document.",
      "status": "resolved",
      "createdAt": "2024-01-16 09:00:00",
      "resolvedAt": "2024-01-16 10:30:00",
      "resolutionNotes": "Document has been verified. All requirements met. Proceeding to filing.",
      "imageUrl": null
    }
  }
}
```

---

## Using in Postman

### Import as cURL

1. Copy any of the curl commands above
2. In Postman, click **Import** button
3. Select **Raw text** tab
4. Paste the curl command
5. Click **Import**
6. Postman will automatically parse the request

### Manual Setup in Postman

#### 1. Get Order Status
- **Method**: GET
- **URL**: `http://localhost/api/itr_status/get_order_status.php?orderId=YOUR_ORDER_ID`
- **Headers**: 
  - `Authorization`: `Bearer YOUR_TOKEN_HERE`
  - `Content-Type`: `application/json`

#### 2. Raise Text Concern
- **Method**: POST
- **URL**: `http://localhost/api/itr_status/raise_concern.php`
- **Headers**: 
  - `Authorization`: `Bearer YOUR_TOKEN_HERE`
  - `Content-Type`: `application/json`
- **Body** (raw JSON):
```json
{
  "orderId": "YOUR_ORDER_ID",
  "statusStep": "documents_verified",
  "concernType": "text",
  "concernText": "Your concern message here"
}
```

#### 3. Raise Image Concern
- **Method**: POST
- **URL**: `http://localhost/api/itr_status/raise_concern.php`
- **Headers**: 
  - `Authorization`: `Bearer YOUR_TOKEN_HERE`
- **Body** (form-data):
  - `orderId`: `YOUR_ORDER_ID`
  - `statusStep`: `documents_verified`
  - `concernType`: `image`
  - `concernText`: `Your concern message`
  - `image`: (Select File)

#### 4. Resolve Concern
- **Method**: POST
- **URL**: `http://localhost/api/itr_status/resolve_concern.php`
- **Headers**: 
  - `Authorization`: `Bearer YOUR_TOKEN_HERE`
  - `Content-Type`: `application/json`
- **Body** (raw JSON):
```json
{
  "concernId": 1,
  "status": "resolved",
  "resolutionNotes": "Resolution notes here"
}
```

---

## Testing Flow

1. **Login** → Get token
2. **Get Order Status** → Check current status (should show payment_success if payment was made)
3. **Raise Concern** → Raise a concern for documents_verified step
4. **Get Order Status Again** → Verify concern appears in response
5. **Resolve Concern** → Resolve the concern as admin
6. **Get Order Status Final** → Verify concern is resolved and step can proceed

---

## Notes

- All endpoints require authentication token
- `orderId` or `itrId` must be provided (at least one)
- Image uploads are stored in `uploads/concerns/{orderId or itrId}/`
- Supported image formats: jpg, jpeg, png, pdf
- When a concern is raised, the step is automatically marked as incomplete
- Steps with pending concerns cannot be completed until resolved
- After resolving all concerns, the step can be marked as completed

---

## Error Responses

### 400 Bad Request
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
```json
{
  "status": "error",
  "statusCode": 401,
  "data": {
    "message": "Invalid or expired token"
  }
}
```

### 404 Not Found
```json
{
  "status": "error",
  "statusCode": 404,
  "data": {
    "message": "Concern not found"
  }
}
```

### 500 Internal Server Error
```json
{
  "status": "error",
  "statusCode": 500,
  "data": {
    "message": "Failed to create concern: [error details]"
  }
}
```

