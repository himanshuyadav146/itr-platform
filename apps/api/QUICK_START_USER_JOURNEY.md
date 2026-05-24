# Quick Start: User Journey Implementation

## ✅ What Has Been Implemented

### 1. Database Changes
- ✅ Created `user_journey` table to track user progress through different services
- ✅ Added `journeyId` column to `personal_details` table
- ✅ Added `journeyId` column to `document_details` table

### 2. API Updates
- ✅ Modified `personal_details.php` to accept `journeyType` parameter
- ✅ Modified `save_documents.php` to accept `journeyType` or `journeyId`
- ✅ Created `get_user_journey.php` to retrieve journey information
- ✅ Created `update_journey_status.php` to update journey progress

### 3. Journey Types Available
- ITR (Income Tax Return)
- E-Verify (Electronic Verification)
- GST (GST Services)
- Loan (Loan Services)

---

## 🚀 Setup Instructions

### Step 1: Run Database Migration

Execute this SQL file in your MySQL database:

```bash
mysql -u itr_services -p itr_services < migrations/add_user_journey_table.sql
```

**OR** via phpMyAdmin:
1. Open phpMyAdmin
2. Select `itr_services` database
3. Click "SQL" tab
4. Open and paste contents of `migrations/add_user_journey_table.sql`
5. Click "Go"

### Step 2: Verify Tables Created

Check that these exist:
```sql
-- Check if user_journey table exists
SHOW TABLES LIKE 'user_journey';

-- Check if columns were added
DESCRIBE personal_details;  -- Should show journeyId column
DESCRIBE document_details;  -- Should show journeyId column
```

---

## 📱 Mobile App Integration

### Updated CURL: Submit Personal Details

**Before:**
```bash
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "panNumber": "ABCDE1234F",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com"
}'
```

**After (with journey tracking):**
```bash
curl --location 'http://allindiaitr.in/api/itrdetails/add_personal_details.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
    "journeyType": "ITR",
    "panNumber": "ABCDE1234F",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com"
}'
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 201,
  "data": {
    "message": "Personal details added successfully",
    "panNumber": "ABCDE1234F",
    "journeyId": 1,
    "journeyType": "ITR"
  }
}
```

**Store the `journeyId` in your app!**

---

### Updated CURL: Submit Documents

**Option 1: Use journeyId (Recommended)**
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/save_documents.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
  "PanNumber":"AKJPD1235J",
  "journeyId": 1,
  "documents":[
    {
      "documentName":"Form 16-A",
      "fileType":"png",
      "filePassword":"",
      "fileName":"form16a_69710a44640729.42541169.png"
    }
  ]
}'
```

**Option 2: Use journeyType**
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/save_documents.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
  "PanNumber":"AKJPD1235J",
  "journeyType": "ITR",
  "documents":[...]
}'
```

---

### New CURL: Get User Journey

```bash
# Get all journeys for logged-in user
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php' \
--header 'Authorization: Bearer YOUR_TOKEN'

# Get specific journey by ID
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyId=1' \
--header 'Authorization: Bearer YOUR_TOKEN'

# Get all ITR journeys
curl --location --request GET 'http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyType=ITR' \
--header 'Authorization: Bearer YOUR_TOKEN'
```

---

### New CURL: Update Journey Status

```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/update_journey_status.php' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--header 'Content-Type: application/json' \
--data-raw '{
  "journeyId": 1,
  "status": "completed",
  "currentStep": "payment_completed"
}'
```

---

## 🎯 Common Use Cases

### 1. User Starts ITR Filing

```json
POST /add_personal_details.php
{
  "journeyType": "ITR",
  "panNumber": "ABCDE1234F",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com"
}

// Response includes journeyId: 1
// Save this journeyId in local storage
```

### 2. User Uploads Documents

```json
POST /save_documents.php
{
  "journeyId": 1,  // Use saved journeyId
  "PanNumber": "ABCDE1234F",
  "documents": [...]
}
```

### 3. Check Journey Progress

```bash
GET /get_user_journey.php?journeyId=1

// Returns current status and step
{
  "journey": {
    "status": "in_progress",
    "currentStep": "documents"
  }
}
```

### 4. Complete Journey

```json
POST /update_journey_status.php
{
  "journeyId": 1,
  "status": "completed"
}
```

---

## 🔄 Journey Flow Example

```
User Flow:

1. Select Service Type → journeyType = "ITR"
   ↓
2. Fill Personal Details → Creates journey (journeyId = 1)
   ↓
3. Upload Documents → Links to journeyId = 1
   ↓
4. Make Payment → Update status to "completed"
   ↓
5. View Progress → Get journey status anytime
```

---

## 💡 Mobile App Tips

### Dart/Flutter Example

```dart
class JourneyService {
  int? currentJourneyId;
  String? currentJourneyType;
  
  // Save journeyId after creating journey
  void saveJourneyId(int id, String type) {
    currentJourneyId = id;
    currentJourneyType = type;
    // Also save to SharedPreferences for persistence
  }
  
  // Include in subsequent API calls
  Map<String, dynamic> getDocumentPayload() {
    return {
      'journeyId': currentJourneyId,
      'PanNumber': panNumber,
      'documents': documents,
    };
  }
  
  // Check if user has incomplete journey
  Future<bool> hasIncompleteJourney() async {
    final response = await api.get(
      '/get_user_journey.php?status=in_progress'
    );
    return response['data']['count'] > 0;
  }
}
```

### React Native Example

```javascript
// Store journeyId
const saveJourneyId = (journeyId, journeyType) => {
  AsyncStorage.setItem('journeyId', journeyId.toString());
  AsyncStorage.setItem('journeyType', journeyType);
};

// Retrieve journeyId
const getJourneyId = async () => {
  return await AsyncStorage.getItem('journeyId');
};

// Submit with journey
const submitDocuments = async (documents) => {
  const journeyId = await getJourneyId();
  return fetch('/save_documents.php', {
    method: 'POST',
    body: JSON.stringify({
      journeyId,
      PanNumber: pan,
      documents,
    }),
  });
};
```

---

## 📊 Journey States

| Status | Meaning | When to Use |
|--------|---------|-------------|
| `initiated` | Journey just started | Auto-set on creation |
| `in_progress` | User actively filling details | Auto-updated as user progresses |
| `completed` | Successfully finished | After payment/final step |
| `cancelled` | User abandoned journey | When user cancels or times out |

---

## ⚠️ Important Notes

1. **Always send `journeyType`** when creating personal details for the first time
2. **Store `journeyId`** returned in response for future API calls
3. **journeyType values are case-sensitive**: Use exact values: `ITR`, `E-Verify`, `GST`, `Loan`
4. **Multiple journeys allowed**: Users can have different journeys for different services or PANs
5. **Optional field**: If you don't send `journeyType`, the API still works (backward compatible)

---

## 🔍 Testing Checklist

- [ ] Can create journey by sending `journeyType` with personal details
- [ ] Response includes `journeyId` and `journeyType`
- [ ] Can submit documents with `journeyId`
- [ ] Can retrieve journey info with GET request
- [ ] Can update journey status
- [ ] Can filter journeys by type, status, PAN
- [ ] Multiple journeys can coexist for same user

---

## 📞 Support

If you encounter issues:

1. **Check response messages** - API returns detailed error messages
2. **Verify journeyType spelling** - Must be exact: `ITR`, `E-Verify`, `GST`, `Loan`
3. **Ensure migration ran** - Check if `user_journey` table exists
4. **Test with Postman** - Use provided CURL examples
5. **Check logs** - Look at MySQL error logs if queries fail

---

## 📚 Full Documentation

For complete details, see: `USER_JOURNEY_GUIDE.md`
