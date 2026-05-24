# User Journey Tracking System

## Overview

The User Journey system tracks users as they progress through different service flows (ITR, E-Verify, GST, Loan). Each journey maintains the current status, step, and associated data.

## Database Schema

### `user_journey` Table

```sql
CREATE TABLE user_journey (
  id INT PRIMARY KEY AUTO_INCREMENT,
  userId INT NOT NULL,
  panNumber VARCHAR(10),
  journeyType ENUM('ITR', 'E-Verify', 'GST', 'Loan'),
  status ENUM('initiated', 'in_progress', 'completed', 'cancelled'),
  currentStep VARCHAR(100),  -- e.g., 'personal_details', 'documents', 'payment'
  metadata JSON,             -- Additional journey-specific data
  startedAt DATETIME,
  completedAt DATETIME,
  updatedAt DATETIME,
  FOREIGN KEY (userId) REFERENCES users(UserId)
);
```

### Links to Other Tables

- `personal_details.journeyId` → `user_journey.id`
- `document_details.journeyId` → `user_journey.id`

## Journey Types

1. **ITR** - Income Tax Return filing
2. **E-Verify** - Electronic verification services
3. **GST** - GST registration and filing
4. **Loan** - Loan application services

## Journey Statuses

- `initiated` - Journey just started
- `in_progress` - User is actively completing steps
- `completed` - Journey successfully finished
- `cancelled` - Journey was cancelled by user or system

## Common Journey Steps

- `personal_details` - User filling personal information
- `documents` - User uploading documents
- `payment` - User completing payment
- `verification` - Documents being verified
- `processing` - Application being processed
- `completed` - Final step

## API Endpoints

### 1. Submit Personal Details with Journey

**Endpoint:** `POST /api/itrdetails/add_personal_details.php`

**Request:**
```json
{
  "journeyType": "ITR",
  "panNumber": "ABCDE1234F",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "mobileNumber": "9876543210",
  "financialYear": "2023-24",
  ...
}
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 201,
  "data": {
    "message": "Personal details added successfully",
    "panNumber": "ABCDE1234F",
    "journeyId": 123,
    "journeyType": "ITR"
  }
}
```

**Behavior:**
- If journey doesn't exist: Creates new journey with status `in_progress` and step `personal_details`
- If journey exists: Updates existing journey
- Links personal_details record to journey

---

### 2. Submit Documents with Journey

**Endpoint:** `POST /api/itrdetails/save_documents.php`

**Option A: Using journeyId (Recommended)**
```json
{
  "PanNumber": "ABCDE1234F",
  "journeyId": 123,
  "documents": [
    {
      "documentName": "Form 16-A",
      "fileType": "pdf",
      "filePassword": "",
      "fileName": "form16a_12345.pdf"
    }
  ]
}
```

**Option B: Using journeyType**
```json
{
  "PanNumber": "ABCDE1234F",
  "journeyType": "ITR",
  "documents": [...]
}
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Documents saved successfully",
    "journeyId": 123,
    "journeyType": "ITR"
  }
}
```

**Behavior:**
- Updates journey status to `in_progress`
- Sets currentStep to `documents`
- Links all documents to the journey

---

### 3. Get User Journey(s)

**Endpoint:** `GET /api/itrdetails/get_user_journey.php`

**Query Parameters:**
- `journeyId` - Get specific journey by ID
- `journeyType` - Filter by journey type (ITR, E-Verify, GST, Loan)
- `panNumber` - Filter by PAN number
- `status` - Filter by status (initiated, in_progress, completed, cancelled)

**Examples:**

```bash
# Get all journeys for logged-in user
GET /api/itrdetails/get_user_journey.php

# Get specific journey
GET /api/itrdetails/get_user_journey.php?journeyId=123

# Get all ITR journeys
GET /api/itrdetails/get_user_journey.php?journeyType=ITR

# Get all in-progress journeys
GET /api/itrdetails/get_user_journey.php?status=in_progress

# Get ITR journey for specific PAN
GET /api/itrdetails/get_user_journey.php?journeyType=ITR&panNumber=ABCDE1234F
```

**Response (Single Journey):**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "journey": {
      "id": 123,
      "userId": 4,
      "panNumber": "ABCDE1234F",
      "journeyType": "ITR",
      "status": "in_progress",
      "currentStep": "documents",
      "metadata": null,
      "startedAt": "2024-01-15 10:30:00",
      "completedAt": null,
      "updatedAt": "2024-01-15 11:45:00"
    }
  }
}
```

**Response (Multiple Journeys):**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "journeys": [
      {
        "id": 123,
        "userId": 4,
        "journeyType": "ITR",
        "status": "in_progress",
        ...
      },
      {
        "id": 124,
        "userId": 4,
        "journeyType": "GST",
        "status": "completed",
        ...
      }
    ],
    "count": 2
  }
}
```

---

### 4. Update Journey Status

**Endpoint:** `POST /api/itrdetails/update_journey_status.php`

**Request:**
```json
{
  "journeyId": 123,
  "status": "completed",
  "currentStep": "completed",
  "metadata": {
    "paymentId": "PAY123456",
    "completedBy": "admin",
    "notes": "Successfully processed"
  }
}
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Journey updated successfully",
    "journey": {
      "id": 123,
      "userId": 4,
      "journeyType": "ITR",
      "status": "completed",
      "currentStep": "completed",
      "metadata": {
        "paymentId": "PAY123456",
        "completedBy": "admin"
      },
      "completedAt": "2024-01-15 15:30:00",
      ...
    }
  }
}
```

**Use Cases:**
- Mark journey as completed after payment
- Cancel journey if user abandons
- Update current step as user progresses
- Add metadata for tracking additional information

---

## Mobile App Integration

### Typical Flow

```
1. User selects service type (ITR, E-Verify, GST, Loan)
   ↓
2. App sends journeyType with personal details
   POST /add_personal_details.php
   { "journeyType": "ITR", ... }
   ↓
3. Backend creates/updates journey, returns journeyId
   Response: { "journeyId": 123 }
   ↓
4. App stores journeyId locally
   ↓
5. User uploads documents
   POST /save_documents.php
   { "journeyId": 123, "documents": [...] }
   ↓
6. User completes payment
   POST /update_journey_status.php
   { "journeyId": 123, "status": "completed" }
   ↓
7. App can query journey status anytime
   GET /get_user_journey.php?journeyId=123
```

### Recommended Practices

1. **Store journeyId**: Save journeyId in local storage after creating journey
2. **Track Progress**: Use `currentStep` to show progress indicator in UI
3. **Handle Multiple Journeys**: User can have multiple active journeys (different types or PANs)
4. **Resume Journey**: Load incomplete journeys on app startup
5. **Sync State**: Periodically fetch journey status to sync with backend

### Example: Progress Indicator

```dart
// Flutter example
String getProgressPercentage(String currentStep) {
  switch (currentStep) {
    case 'personal_details': return '33%';
    case 'documents': return '66%';
    case 'payment': return '90%';
    case 'completed': return '100%';
    default: return '0%';
  }
}
```

---

## Migration Instructions

### Step 1: Run Migration SQL

```bash
mysql -u itr_services -p itr_services < migrations/add_user_journey_table.sql
```

Or in phpMyAdmin:
1. Select `itr_services` database
2. Go to SQL tab
3. Paste contents of `migrations/add_user_journey_table.sql`
4. Click "Go"

### Step 2: Verify Tables

Check that these changes were applied:
- ✓ New table: `user_journey`
- ✓ New column: `personal_details.journeyId`
- ✓ New column: `document_details.journeyId`

### Step 3: Test API

```bash
# Test creating journey
curl -X POST http://allindiaitr.in/api/itrdetails/add_personal_details.php \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "journeyType": "ITR",
    "panNumber": "ABCDE1234F",
    "firstName": "Test",
    "lastName": "User",
    "email": "test@example.com"
  }'

# Test getting journey
curl -X GET "http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyType=ITR" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Advanced Features

### Custom Journey Steps

You can define custom steps per journey type:

**ITR Journey:**
```
personal_details → documents → verification → payment → processing → completed
```

**Loan Journey:**
```
personal_details → documents → credit_check → approval → disbursal → completed
```

**GST Journey:**
```
business_details → documents → verification → registration → completed
```

### Metadata Usage

Store journey-specific data in JSON:

```json
{
  "journeyId": 123,
  "metadata": {
    "packageId": 1,
    "discountCode": "SUMMER2024",
    "referralSource": "google_ads",
    "estimatedCompletion": "2024-01-20",
    "assignedAgent": "agent_42"
  }
}
```

### Analytics Queries

```sql
-- Count journeys by type
SELECT journeyType, COUNT(*) as count 
FROM user_journey 
GROUP BY journeyType;

-- Completion rate by journey type
SELECT 
  journeyType,
  COUNT(*) as total,
  SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
  (SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) as completion_rate
FROM user_journey 
GROUP BY journeyType;

-- Average journey duration
SELECT 
  journeyType,
  AVG(TIMESTAMPDIFF(HOUR, startedAt, completedAt)) as avg_hours
FROM user_journey 
WHERE status = 'completed'
GROUP BY journeyType;
```

---

## Troubleshooting

### Issue: "Invalid journeyType" Error

**Cause:** journeyType value doesn't match ENUM values  
**Solution:** Use exact values: `ITR`, `E-Verify`, `GST`, or `Loan` (case-sensitive)

### Issue: "Journey not found" Error

**Cause:** journeyId doesn't exist or doesn't belong to user  
**Solution:** Always use journeyId returned from previous API calls

### Issue: Foreign Key Constraint Error

**Cause:** Trying to reference non-existent journey  
**Solution:** Create journey first via personal_details API, then use returned journeyId

---

## Future Enhancements

- [ ] Journey templates for different service types
- [ ] Automated step progression based on events
- [ ] Journey expiry after inactivity period
- [ ] Email notifications at each step
- [ ] Journey analytics dashboard for admin
- [ ] Sub-steps within main steps
- [ ] Multi-user journey support (shared journeys)

---

## Support

For questions or issues:
- Check API response error messages
- Review this documentation
- Contact backend team
