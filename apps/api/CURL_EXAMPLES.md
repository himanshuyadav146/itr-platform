# CURL Examples - User Journey APIs

Complete CURL examples for testing all User Journey APIs.

**Note:** Replace `YOUR_TOKEN` with your actual JWT Bearer token.

---

## 1. Personal Details API (Modified)

### POST: Add/Update Personal Details with Journey

**Endpoint:** `http://allindiaitr.in/api/itrdetails/add_personal_details.php`

#### Example 1: ITR Journey
```bash
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyType": "ITR",
    "panNumber": "AKJPD1235J",
    "firstName": "John",
    "middleName": "Michael",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "mobileNumber": "9876543210",
    "aadhaarCardNumber": "123456789012",
    "gender": "Male",
    "financialYear": "2023-24",
    "address": "123 Main Street, City, State, PIN",
    "country": "India"
}'
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 201,
  "data": {
    "message": "Personal details added successfully",
    "panNumber": "AKJPD1235J",
    "journeyId": 1,
    "journeyType": "ITR"
  }
}
```

#### Example 2: E-Verify Journey
```bash
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyType": "E-Verify",
    "panNumber": "BCDEX5678K",
    "firstName": "Jane",
    "lastName": "Smith",
    "email": "jane.smith@example.com",
    "mobileNumber": "9876543211",
    "gender": "Female",
    "address": "456 Oak Avenue, City, State, PIN",
    "country": "India"
}'
```

#### Example 3: GST Journey
```bash
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyType": "GST",
    "panNumber": "CDEFG9012L",
    "firstName": "Robert",
    "lastName": "Johnson",
    "email": "robert.j@example.com",
    "mobileNumber": "9876543212",
    "address": "789 Business Park, City, State, PIN",
    "country": "India"
}'
```

#### Example 4: Loan Journey
```bash
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyType": "Loan",
    "panNumber": "DEFGH3456M",
    "firstName": "Maria",
    "lastName": "Garcia",
    "email": "maria.garcia@example.com",
    "mobileNumber": "9876543213",
    "address": "321 Pine Street, City, State, PIN",
    "country": "India"
}'
```

#### Example 5: Without Journey (Backward Compatible)
```bash
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "panNumber": "EFGHI7890N",
    "firstName": "David",
    "lastName": "Lee",
    "email": "david.lee@example.com",
    "mobileNumber": "9876543214"
}'
```

---

## 2. Save Documents API (Modified)

### POST: Save Documents with Journey

**Endpoint:** `http://allindiaitr.in/api/itrdetails/save_documents.php`

#### Example 1: Using journeyId (Recommended)
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/save_documents.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 1,
    "PanNumber": "AKJPD1235J",
    "documents": [
        {
            "documentName": "Form 16-A",
            "fileType": "png",
            "filePassword": "",
            "fileName": "form16a_69710a44640729.42541169.png"
        },
        {
            "documentName": "Form 16-B",
            "fileType": "jpg",
            "filePassword": "",
            "fileName": "form16b_69710a673af425.66636880.jpg"
        },
        {
            "documentName": "Other Documents",
            "fileType": "pdf",
            "filePassword": "secure123",
            "fileName": "others_69710a6ae9f8f6.04476936.pdf"
        }
    ]
}'
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Documents saved successfully",
    "journeyId": 1,
    "journeyType": "ITR"
  }
}
```

#### Example 2: Using journeyType (Alternative)
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/save_documents.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyType": "ITR",
    "PanNumber": "AKJPD1235J",
    "documents": [
        {
            "documentName": "Form 16-A",
            "fileType": "png",
            "filePassword": "",
            "fileName": "form16a_69710a44640729.42541169.png"
        }
    ]
}'
```

#### Example 3: Multiple Documents (Real Scenario)
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/save_documents.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 1,
    "PanNumber": "AKJPD1235J",
    "documents": [
        {
            "documentName": "Form 16-A",
            "fileType": "png",
            "filePassword": "",
            "fileName": "form16a_69710a44640729.42541169.png"
        },
        {
            "documentName": "Form 16-B",
            "fileType": "jpg",
            "filePassword": "",
            "fileName": "form16b_69710a673af425.66636880.jpg"
        },
        {
            "documentName": "Bank Statement",
            "fileType": "pdf",
            "filePassword": "",
            "fileName": "bank_statement_69710a7b1234ab.56789012.pdf"
        },
        {
            "documentName": "Salary Slip",
            "fileType": "pdf",
            "filePassword": "",
            "fileName": "salary_slip_69710a8c5678cd.12345678.pdf"
        },
        {
            "documentName": "Other Documents",
            "fileType": "jpg",
            "filePassword": "",
            "fileName": "others_69710a6ae9f8f6.04476936.jpg"
        }
    ]
}'
```

#### Example 4: Without Journey (Backward Compatible)
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/save_documents.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "PanNumber": "EFGHI7890N",
    "documents": [
        {
            "documentName": "Form 16",
            "fileType": "pdf",
            "filePassword": "",
            "fileName": "form16_12345.pdf"
        }
    ]
}'
```

---

## 3. Get User Journey API (NEW)

### GET: Retrieve User Journey Information

**Endpoint:** `http://allindiaitr.in/api/itrdetails/get_user_journey.php`

#### Example 1: Get All Journeys for User
```bash
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php' \
--header 'Authorization: Bearer YOUR_TOKEN'
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "journeys": [
      {
        "id": 1,
        "userId": 4,
        "panNumber": "AKJPD1235J",
        "journeyType": "ITR",
        "status": "in_progress",
        "currentStep": "documents",
        "metadata": null,
        "startedAt": "2024-01-22 10:30:00",
        "completedAt": null,
        "updatedAt": "2024-01-22 11:45:00"
      },
      {
        "id": 2,
        "userId": 4,
        "panNumber": "BCDEX5678K",
        "journeyType": "E-Verify",
        "status": "completed",
        "currentStep": "completed",
        "metadata": null,
        "startedAt": "2024-01-20 09:00:00",
        "completedAt": "2024-01-21 15:30:00",
        "updatedAt": "2024-01-21 15:30:00"
      }
    ],
    "count": 2
  }
}
```

#### Example 2: Get Specific Journey by ID
```bash
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyId=1' \
--header 'Authorization: Bearer YOUR_TOKEN'
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "journey": {
      "id": 1,
      "userId": 4,
      "panNumber": "AKJPD1235J",
      "journeyType": "ITR",
      "status": "in_progress",
      "currentStep": "documents",
      "metadata": null,
      "startedAt": "2024-01-22 10:30:00",
      "completedAt": null,
      "updatedAt": "2024-01-22 11:45:00"
    }
  }
}
```

#### Example 3: Filter by Journey Type
```bash
# Get all ITR journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyType=ITR' \
--header 'Authorization: Bearer YOUR_TOKEN'

# Get all E-Verify journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyType=E-Verify' \
--header 'Authorization: Bearer YOUR_TOKEN'

# Get all GST journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyType=GST' \
--header 'Authorization: Bearer YOUR_TOKEN'

# Get all Loan journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyType=Loan' \
--header 'Authorization: Bearer YOUR_TOKEN'
```

#### Example 4: Filter by Status
```bash
# Get all in-progress journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?status=in_progress' \
--header 'Authorization: Bearer YOUR_TOKEN'

# Get all completed journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?status=completed' \
--header 'Authorization: Bearer YOUR_TOKEN'

# Get all initiated journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?status=initiated' \
--header 'Authorization: Bearer YOUR_TOKEN'

# Get all cancelled journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?status=cancelled' \
--header 'Authorization: Bearer YOUR_TOKEN'
```

#### Example 5: Filter by PAN Number
```bash
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?panNumber=AKJPD1235J' \
--header 'Authorization: Bearer YOUR_TOKEN'
```

#### Example 6: Multiple Filters Combined
```bash
# Get ITR journey for specific PAN
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyType=ITR&panNumber=AKJPD1235J' \
--header 'Authorization: Bearer YOUR_TOKEN'

# Get in-progress ITR journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyType=ITR&status=in_progress' \
--header 'Authorization: Bearer YOUR_TOKEN'

# Get completed journeys for specific PAN
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?panNumber=AKJPD1235J&status=completed' \
--header 'Authorization: Bearer YOUR_TOKEN'
```

---

## 4. Update Journey Status API (NEW)

### POST: Update Journey Status and Progress

**Endpoint:** `http://allindiaitr.in/api/itrdetails/update_journey_status.php`

#### Example 1: Mark Journey as Completed
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/update_journey_status.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 1,
    "status": "completed",
    "currentStep": "completed"
}'
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Journey updated successfully",
    "journey": {
      "id": 1,
      "userId": 4,
      "panNumber": "AKJPD1235J",
      "journeyType": "ITR",
      "status": "completed",
      "currentStep": "completed",
      "metadata": null,
      "startedAt": "2024-01-22 10:30:00",
      "completedAt": "2024-01-22 15:30:00",
      "updatedAt": "2024-01-22 15:30:00"
    }
  }
}
```

#### Example 2: Update to Payment Step
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/update_journey_status.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 1,
    "status": "in_progress",
    "currentStep": "payment"
}'
```

#### Example 3: Update with Metadata
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/update_journey_status.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 1,
    "status": "completed",
    "currentStep": "completed",
    "metadata": {
        "paymentId": "PAY123456789",
        "paymentMethod": "UPI",
        "amount": 999.00,
        "completedBy": "user",
        "notes": "Payment successful, ITR filed"
    }
}'
```

#### Example 4: Cancel Journey
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/update_journey_status.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 1,
    "status": "cancelled",
    "currentStep": "cancelled",
    "metadata": {
        "reason": "User abandoned process",
        "cancelledAt": "2024-01-22 14:00:00"
    }
}'
```

#### Example 5: Update to Verification Step
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/update_journey_status.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 1,
    "status": "in_progress",
    "currentStep": "verification",
    "metadata": {
        "assignedTo": "verifier_42",
        "verificationStarted": "2024-01-22 12:00:00"
    }
}'
```

#### Example 6: Update Only Status
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/update_journey_status.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 1,
    "status": "in_progress"
}'
```

#### Example 7: Update Only Current Step
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/update_journey_status.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 1,
    "currentStep": "processing"
}'
```

---

## 5. Complete Journey Flow Example

### Step-by-Step Journey: ITR Filing

```bash
# STEP 1: Create Personal Details (Journey Auto-Created)
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyType": "ITR",
    "panNumber": "AKJPD1235J",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "mobileNumber": "9876543210"
}'
# Response: journeyId = 1

# STEP 2: Upload Documents
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/save_documents.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 1,
    "PanNumber": "AKJPD1235J",
    "documents": [
        {
            "documentName": "Form 16-A",
            "fileType": "pdf",
            "filePassword": "",
            "fileName": "form16a_12345.pdf"
        }
    ]
}'

# STEP 3: Check Journey Status
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyId=1' \
--header 'Authorization: Bearer YOUR_TOKEN'

# STEP 4: Move to Payment Step
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/update_journey_status.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 1,
    "currentStep": "payment"
}'

# STEP 5: Complete Journey
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/update_journey_status.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 1,
    "status": "completed",
    "currentStep": "completed",
    "metadata": {
        "paymentId": "PAY123456",
        "completedAt": "2024-01-22 15:30:00"
    }
}'
```

---

## 6. Testing Different Journey Types

### ITR Journey Flow
```bash
# 1. Create ITR Journey
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{"journeyType": "ITR", "panNumber": "TEST1234A", "firstName": "Test", "lastName": "User", "email": "test@test.com"}'

# 2. Get ITR Journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyType=ITR' \
--header 'Authorization: Bearer YOUR_TOKEN'
```

### E-Verify Journey Flow
```bash
# 1. Create E-Verify Journey
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{"journeyType": "E-Verify", "panNumber": "TEST5678B", "firstName": "Test2", "lastName": "User2", "email": "test2@test.com"}'

# 2. Get E-Verify Journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyType=E-Verify' \
--header 'Authorization: Bearer YOUR_TOKEN'
```

### GST Journey Flow
```bash
# 1. Create GST Journey
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{"journeyType": "GST", "panNumber": "TEST9012C", "firstName": "Test3", "lastName": "User3", "email": "test3@test.com"}'

# 2. Get GST Journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyType=GST' \
--header 'Authorization: Bearer YOUR_TOKEN'
```

### Loan Journey Flow
```bash
# 1. Create Loan Journey
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{"journeyType": "Loan", "panNumber": "TEST3456D", "firstName": "Test4", "lastName": "User4", "email": "test4@test.com"}'

# 2. Get Loan Journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyType=Loan' \
--header 'Authorization: Bearer YOUR_TOKEN'
```

---

## 7. Error Testing

### Invalid Journey Type
```bash
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyType": "INVALID",
    "panNumber": "TEST9999X",
    "firstName": "Test",
    "lastName": "User",
    "email": "test@test.com"
}'
```

**Expected Error:**
```json
{
  "status": "error",
  "statusCode": 400,
  "data": {
    "message": "Invalid journeyType. Must be one of: ITR, E-Verify, GST, Loan"
  }
}
```

### Invalid Journey ID
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/save_documents.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyId": 99999,
    "PanNumber": "TEST1234A",
    "documents": [{"documentName": "Test", "fileType": "pdf", "filePassword": "", "fileName": "test.pdf"}]
}'
```

**Expected Error:**
```json
{
  "status": "error",
  "statusCode": 400,
  "data": {
    "message": "Invalid journeyId or journey does not belong to this user"
  }
}
```

---

## 8. Quick Reference

### Valid Journey Types (Case-Sensitive)
- `ITR`
- `E-Verify`
- `GST`
- `Loan`

### Valid Statuses
- `initiated`
- `in_progress`
- `completed`
- `cancelled`

### Common Current Steps
- `personal_details`
- `documents`
- `payment`
- `verification`
- `processing`
- `completed`

---

## 9. Postman Collection

You can import these CURLs into Postman:
1. Copy any CURL command
2. Open Postman
3. Click "Import" → "Raw text"
4. Paste the CURL
5. Click "Import"

---

## 10. Bearer Token

Replace `YOUR_TOKEN` with your actual JWT token from login:

```
eyJhbGdvIjoiSFMyNTYiLCJ0eXBlIjoiSldUIiwiZXhwaXJlIjoxNzY5MDUzODE0fQ==.eyJpc3MiOiJhbGxpbmRpYWl0ci5pbiIsIlVzZXJJZCI6IjQiLCJSb2xlIjoiQ0xJRU5UIiwidGltZSI6MTc2OTAxNzgxNH0=.M2MxMTkyNjAwZmMzY2U0NjIxYzZhYjJiNGM2NzcyMTM4MzBkYzQ1NmM3ZjE3MDY3MTY5NGZiYzE4ODUxYTQzMQ==
```

---

## Need Help?

- See `VERIFICATION_CHECKLIST.md` for testing steps
- See `API_CHANGES_REFERENCE.md` for code changes
- See `USER_JOURNEY_GUIDE.md` for complete documentation
