# API Changes Reference - User Journey Implementation

## ✅ Status: Changes Already Applied

All changes below have been **ALREADY IMPLEMENTED** in the code. This document serves as a reference to show what was modified.

---

## File 1: `itrdetails/personal_details.php`

### Change 1: Accept journeyType Parameter (Line ~165)

**ADDED AFTER LINE 163:**
```php
// Journey Type - determines which service flow the user is in
$journeyType = trim($data['journeyType'] ?? '');

// Validate journeyType
$validJourneyTypes = ['ITR', 'E-Verify', 'GST', 'Loan'];
if (!empty($journeyType) && !in_array($journeyType, $validJourneyTypes)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => [
            "message" => "Invalid journeyType. Must be one of: ITR, E-Verify, GST, Loan"
        ]
    ]);
    exit;
}
```

### Change 2: Escape journeyType (Line ~200)

**ADDED AFTER LINE 198 (after other escape variables):**
```php
$journeyType = mysqli_real_escape_string($conn, $journeyType);
```

### Change 3: Handle User Journey Creation/Update (Line ~235)

**ADDED AFTER database connection check, BEFORE UPDATE/INSERT cases:**
```php
// ------------------------------
// HANDLE USER JOURNEY
// ------------------------------
$journeyId = null;

if (!empty($journeyType)) {
    // Check if journey already exists for this user and journey type
    $journeyCheckSql = "SELECT id, status FROM user_journey 
                        WHERE userId = '$UserId' 
                        AND journeyType = '$journeyType' 
                        AND panNumber = '$panNumber'
                        ORDER BY id DESC 
                        LIMIT 1";
    $journeyResult = $conn->query($journeyCheckSql);
    
    if ($journeyResult && $journeyResult->num_rows > 0) {
        // Journey exists - update it
        $journeyRow = $journeyResult->fetch_assoc();
        $journeyId = $journeyRow['id'];
        
        // Update journey status and current step
        $updateJourneySql = "UPDATE user_journey 
                            SET status = 'in_progress',
                                currentStep = 'personal_details',
                                updatedAt = NOW()
                            WHERE id = '$journeyId'";
        $conn->query($updateJourneySql);
    } else {
        // Create new journey
        $createJourneySql = "INSERT INTO user_journey 
                            (userId, panNumber, journeyType, status, currentStep, startedAt, updatedAt)
                            VALUES 
                            ('$UserId', '$panNumber', '$journeyType', 'in_progress', 'personal_details', NOW(), NOW())";
        
        if ($conn->query($createJourneySql)) {
            $journeyId = $conn->insert_id;
        }
    }
}

$journeyIdSql = ($journeyId === null) ? 'NULL' : (int)$journeyId;
```

### Change 4: Add journeyId to UPDATE Query (Line ~292)

**MODIFIED UPDATE query - ADDED `journeyId=$journeyIdSql,` line:**
```php
$sql = "UPDATE personal_details SET
        FirstName='$firstName',
        MiddleName='$middleName',
        LastName='$lastName',
        EMAIL='$email',
        MobileNumber='$mobileNumber',
        aadharCardNumber='$aadharCardNumber',
        Gender='$gender',
        DATEOFBIRTH=$dateOfBirthSql,
        FinancialYear='$financialYear',
        package_id=$packageIdSql,
        journeyId=$journeyIdSql,            // ← ADDED THIS LINE
        Address='$address',
        Country='$country',
        UpdatedAt = NOW()
        WHERE UserId='$UserId' AND PANNumber='$panNumber'";
```

### Change 5: Add journeyId to INSERT Query (Line ~346)

**MODIFIED INSERT query - ADDED `journeyId` to columns and values:**
```php
$sql = "INSERT INTO personal_details 
        (UserId, PANNumber, FirstName, MiddleName, LastName, EMAIL, MobileNumber, aadharCardNumber, 
        Gender, DATEOFBIRTH, FinancialYear, package_id, journeyId, Address, Country, isActive, CreatedAt)
        //                                                      ↑ ADDED THIS
        VALUES 
        ('$UserId', '$panNumber', '$firstName', '$middleName', '$lastName', '$email', '$mobileNumber', 
        '$aadharCardNumber', '$gender', $dateOfBirthSql, '$financialYear', $packageIdSql, $journeyIdSql, '$address', '$country', 1, NOW())";
        //                                                                                   ↑ ADDED THIS
```

### Change 6: Update Success Response - UPDATE Case (Line ~324)

**MODIFIED response to include journeyId and journeyType:**
```php
http_response_code(200);
echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" =>[
        "message" => "Personal details updated successfully",
        "panNumber" => $panNumber,
        "journeyId" => $journeyId,                                    // ← ADDED
        "journeyType" => !empty($journeyType) ? $journeyType : null,  // ← ADDED
    ]
]);
```

### Change 7: Update Success Response - INSERT Case (Line ~370)

**MODIFIED response to include journeyId and journeyType:**
```php
http_response_code(201);
echo json_encode([
    "status" => "success",
    "statusCode" => 201,
    "data" =>[
        "message" => "Personal details added successfully",
        "panNumber" => $panNumber,
        "journeyId" => $journeyId,                                    // ← ADDED
        "journeyType" => !empty($journeyType) ? $journeyType : null,  // ← ADDED
    ]
]);
```

---

## File 2: `itrdetails/save_documents.php`

### Change 1: Accept journeyId and journeyType Parameters (Line ~57-58)

**ADDED AFTER LINE 56:**
```php
$journeyId = isset($data['journeyId']) ? (int)$data['journeyId'] : null;
$journeyType = trim($data['journeyType'] ?? '');
```

### Change 2: Validate journeyType (Line ~76-85)

**ADDED AFTER PanNumber escape:**
```php
// Validate journeyType if provided
$validJourneyTypes = ['ITR', 'E-Verify', 'GST', 'Loan'];
if (!empty($journeyType) && !in_array($journeyType, $validJourneyTypes)) {
    echo json_encode(["status" => "error", "statusCode" => 400,
    "data" =>[ "message" => "Invalid journeyType. Must be one of: ITR, E-Verify, GST, Loan"]]);
    http_response_code(400);
    exit;
}

$journeyType = mysqli_real_escape_string($conn, $journeyType);
```

### Change 3: Handle User Journey (Line ~87-145)

**ADDED BEFORE the DELETE+INSERT logic:**
```php
// HANDLE USER JOURNEY
if (!empty($journeyType) || $journeyId) {
    if ($journeyId) {
        // Verify journey exists and belongs to this user
        $journeyCheckSql = "SELECT id FROM user_journey 
                            WHERE id = '$journeyId' AND userId = '$UserId'";
        $journeyResult = $conn->query($journeyCheckSql);
        
        if (!$journeyResult || $journeyResult->num_rows === 0) {
            echo json_encode(["status" => "error", "statusCode" => 400,
            "data" =>[ "message" => "Invalid journeyId or journey does not belong to this user"]]);
            http_response_code(400);
            exit;
        }
        
        // Update journey status
        $updateJourneySql = "UPDATE user_journey 
                            SET status = 'in_progress',
                                currentStep = 'documents',
                                updatedAt = NOW()
                            WHERE id = '$journeyId'";
        $conn->query($updateJourneySql);
    } elseif (!empty($journeyType)) {
        // Find or create journey based on journeyType
        $journeyCheckSql = "SELECT id FROM user_journey 
                            WHERE userId = '$UserId' 
                            AND journeyType = '$journeyType' 
                            AND panNumber = '$PanNumber'
                            ORDER BY id DESC 
                            LIMIT 1";
        $journeyResult = $conn->query($journeyCheckSql);
        
        if ($journeyResult && $journeyResult->num_rows > 0) {
            $journeyRow = $journeyResult->fetch_assoc();
            $journeyId = $journeyRow['id'];
            
            // Update journey
            $updateJourneySql = "UPDATE user_journey 
                                SET status = 'in_progress',
                                    currentStep = 'documents',
                                    updatedAt = NOW()
                                WHERE id = '$journeyId'";
            $conn->query($updateJourneySql);
        } else {
            // Create new journey
            $createJourneySql = "INSERT INTO user_journey 
                                (userId, panNumber, journeyType, status, currentStep, startedAt, updatedAt)
                                VALUES 
                                ('$UserId', '$PanNumber', '$journeyType', 'in_progress', 'documents', NOW(), NOW())";
            
            if ($conn->query($createJourneySql)) {
                $journeyId = $conn->insert_id;
            }
        }
    }
}

$journeyIdSql = ($journeyId === null) ? 'NULL' : (int)$journeyId;
```

### Change 4: Add journeyId to INSERT Query (Line ~180)

**MODIFIED INSERT query - ADDED `journeyId` column:**
```php
$sql = "
    INSERT INTO document_details 
    (UserId, PanNumber, journeyId, name, type, password, fileName, isActive, createdAt, createdBy)
    //                   ↑ ADDED THIS
    VALUES
    ('$UserId', '$PanNumber', $journeyIdSql, '$docName', '$fileType', '$filePassword', '$fileName', 1, NOW(), '$UserId')
    //                         ↑ ADDED THIS
";
```

### Change 5: Update Success Response (Line ~190)

**MODIFIED response to include journeyId and journeyType:**
```php
echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" =>[
        "message" => "Documents saved successfully",
        "journeyId" => $journeyId,                                    // ← ADDED
        "journeyType" => !empty($journeyType) ? $journeyType : null,  // ← ADDED
    ]
]);
```

---

## File 3: `itrdetails/get_user_journey.php` (NEW FILE)

**LOCATION:** Create new file at `itrdetails/get_user_journey.php`

**FULL CONTENT:** (Already created - see the file for complete code)

Key features:
- GET endpoint to retrieve user journeys
- Filter by journeyId, journeyType, panNumber, status
- Returns journey details with metadata
- Secure (only returns user's own journeys)

---

## File 4: `itrdetails/update_journey_status.php` (NEW FILE)

**LOCATION:** Create new file at `itrdetails/update_journey_status.php`

**FULL CONTENT:** (Already created - see the file for complete code)

Key features:
- POST endpoint to update journey status
- Update status, currentStep, metadata
- Auto-sets completedAt when status = 'completed'
- Validates journey ownership

---

## File 5: `migrations/add_user_journey_table.sql` (NEW FILE)

**LOCATION:** Create new file at `migrations/add_user_journey_table.sql`

**FULL CONTENT:** (Already created - see the file for migration script)

This creates:
- `user_journey` table
- Adds `journeyId` to `personal_details`
- Adds `journeyId` to `document_details`

---

## Summary of Changes

### Modified Files (2):
1. ✅ `itrdetails/personal_details.php` - 7 changes
2. ✅ `itrdetails/save_documents.php` - 5 changes

### New Files (5):
3. ✅ `itrdetails/get_user_journey.php` - NEW endpoint
4. ✅ `itrdetails/update_journey_status.php` - NEW endpoint
5. ✅ `migrations/add_user_journey_table.sql` - Migration script
6. ✅ `USER_JOURNEY_GUIDE.md` - Full documentation
7. ✅ `QUICK_START_USER_JOURNEY.md` - Quick reference
8. ✅ `IMPLEMENTATION_SUMMARY.md` - Implementation overview
9. ✅ `API_CHANGES_REFERENCE.md` - This file

---

## How to Verify Changes Were Applied

### Check personal_details.php:
```bash
grep -n "journeyType" itrdetails/personal_details.php
# Should show multiple lines with journeyType

grep -n "journeyId" itrdetails/personal_details.php
# Should show multiple lines with journeyId
```

### Check save_documents.php:
```bash
grep -n "journeyType" itrdetails/save_documents.php
# Should show multiple lines with journeyType

grep -n "journeyId" itrdetails/save_documents.php
# Should show multiple lines with journeyId
```

### Check new files exist:
```bash
ls -la itrdetails/get_user_journey.php
ls -la itrdetails/update_journey_status.php
ls -la migrations/add_user_journey_table.sql
```

---

## Testing the Changes

### Test 1: Personal Details with Journey
```bash
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

# Expected response should include:
# "journeyId": 1,
# "journeyType": "ITR"
```

### Test 2: Documents with Journey
```bash
curl -X POST http://allindiaitr.in/api/itrdetails/save_documents.php \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "journeyId": 1,
    "PanNumber": "ABCDE1234F",
    "documents": [...]
  }'

# Expected response should include:
# "journeyId": 1
```

### Test 3: Get Journey
```bash
curl -X GET "http://allindiaitr.in/api/itrdetails/get_user_journey.php?journeyId=1" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Expected response should show journey details
```

---

## Next Steps

1. ✅ **Verify all changes are present** in the PHP files
2. ⏳ **Run database migration**: `migrations/add_user_journey_table.sql`
3. ⏳ **Test all endpoints** using the curl commands above
4. ⏳ **Update mobile app** to send journeyType parameter
5. ⏳ **Test end-to-end** flow in staging environment

---

## Need to Make Changes Manually?

If for some reason the changes weren't applied, you can:

1. Open each file mentioned above
2. Find the line numbers indicated
3. Add/modify the code shown in each change section
4. Save the files

All changes are backward compatible - existing API calls without journeyType will continue to work.

---

## Support

If you need to verify any specific change or have questions:
- Check the line numbers mentioned in each change
- Compare with the code shown in this document
- Refer to the full documentation in `USER_JOURNEY_GUIDE.md`
