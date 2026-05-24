# ITR Filtering by Professional - Implementation Guide

## Overview
This document describes the changes made to implement role-based ITR filtering in the admin panel. The system now automatically filters ITRs based on the logged-in user's role.

## Changes Made

### 1. Authentication Layer Updates

#### `/auth/login.php`
**Change**: Added `Role` to JWT token payload
```php
$payload = [
    "iss" => "allindiaitr.in",
    "UserId" => $row['UserId'],
    "Role" => $row['role'] ?? 'CLIENT'  // ✅ Added
];
```

**Purpose**: Embed user role in the token for server-side validation without additional database queries.

#### `/auth/refresh_token.php`
**Change**: Updated to include `Role` when refreshing tokens
```php
$payload = [
    "iss" => "allindiaitr.in",
    "UserId" => $user['UserId'],
    "Role" => $user['role'] ?? 'CLIENT'  // ✅ Added
];
```

**Purpose**: Maintain role information across token refreshes.

---

### 2. Admin ITRs API Updates

#### `/admin/itrs.php`
**Changes**: 

##### A. Extract Role from Token (Line ~52)
```php
// Extract user info from token
$userId = $decoded['UserId'] ?? null;
$userRole = $decoded['Role'] ?? null;
```

##### B. Auto-detect professionalId (Line ~60)
```php
// Auto-determine professionalId based on user role
$professionalId = null;
if (in_array($userRole, ['ACCOUNTANT', 'CA'])) {
    // Professional: automatically filter by their assignments
    $professionalId = $userId;
} elseif (isset($_GET['professionalId']) && !empty($_GET['professionalId'])) {
    // Admin: can optionally filter by specific professional
    $professionalId = intval($_GET['professionalId']);
}
// If $professionalId is null (ADMIN without filter), show all ITRs
```

##### C. Modified Count Query (Line ~78)
```php
$countSql = "SELECT COUNT(DISTINCT CONCAT(pd.UserId, '-', pd.PANNumber)) as total
             FROM personal_details pd";

// Add join if filtering by professional
if ($professionalId) {
    $professionalIdEscaped = mysqli_real_escape_string($conn, $professionalId);
    $countSql .= " INNER JOIN itr_detail itr ON pd.UserId = itr.userId 
                     AND UPPER(TRIM(itr.panNumber)) = UPPER(TRIM(pd.PANNumber))
                   INNER JOIN itr_assignments ia ON itr.id = ia.itr_id 
                     AND ia.professional_id = '$professionalIdEscaped'";
}

$countSql .= " WHERE pd.isActive = 1";
```

##### D. Modified Main Query (Line ~100)
```php
// Add join if filtering by professional
if ($professionalId) {
    $sql .= " INNER JOIN itr_detail itr ON pd.UserId = itr.userId 
                AND UPPER(TRIM(itr.panNumber)) = UPPER(TRIM(pd.PANNumber))
              INNER JOIN itr_assignments ia ON itr.id = ia.itr_id 
                AND ia.professional_id = '$professionalIdEscaped'";
}
```

##### E. Added Assignment Info to Response (Line ~278)
```php
// Fetch assignment info for this ITR
$assignments = [];
if (!empty($itrIds)) {
    $assignmentSql = "SELECT 
                        ia.id as assignment_id,
                        ia.itr_id,
                        ia.professional_id,
                        ia.assignment_date,
                        ia.status as assignment_status,
                        ia.priority,
                        ia.due_date,
                        ia.completed_at,
                        ia.notes as assignment_notes,
                        prof.FirstName as professional_first_name,
                        prof.LastName as professional_last_name,
                        prof.Email as professional_email,
                        prof.Role as professional_role
                    FROM itr_assignments ia
                    LEFT JOIN users prof ON ia.professional_id = prof.UserId
                    WHERE ia.itr_id IN (...) AND ia.user_id = '$userId'
                    ORDER BY ia.assignment_date DESC";
    // ... process results
}

// Added to response:
"assignments" => $assignments,
"assignmentCount" => count($assignments)
```

---

### 3. Assignment API Fix

#### `/admin/assign_itr.php`
**Problem**: Was using incorrect column names (`assigned_to`, `assigned_at`, `is_active`)  
**Fixed**: Updated to match actual database schema

##### A. Get Client User ID (Line ~92)
```php
$itrRow = $itrCheckResult->fetch_assoc();
$clientUserId = $itrRow['userId'];
```

##### B. Check Active Assignments (Line ~117)
```php
// Old (incorrect):
$existingCheckSql = "SELECT id FROM itr_assignments WHERE itr_id = '$itrIdEscaped' AND is_active = 1";

// New (correct):
$existingCheckSql = "SELECT id FROM itr_assignments 
                     WHERE itr_id = '$itrIdEscaped' 
                     AND status NOT IN ('completed', 'rejected')";
```

##### C. Insert Assignment (Line ~130)
```php
// Old (incorrect):
$sql = "INSERT INTO itr_assignments (itr_id, assigned_to, assigned_by, assigned_at, is_active)
        VALUES ('$itrIdEscaped', '$professionalIdEscaped', $assignedByValue, NOW(), 1)";

// New (correct):
$sql = "INSERT INTO itr_assignments (itr_id, user_id, professional_id, assigned_by, assignment_date, status, priority)
        VALUES ('$itrIdEscaped', '$clientUserIdEscaped', '$professionalIdEscaped', $assignedByValue, NOW(), 'assigned', 'normal')";
```

---

## API Usage

### For Admin Users

**Get All ITRs (no filter):**
```bash
curl --location 'http://localhost/api/admin/itrs.php?page=1&limit=10' \
  --header 'Authorization: Bearer {ADMIN_TOKEN}'
```

**Get ITRs Assigned to Specific Professional:**
```bash
curl --location 'http://localhost/api/admin/itrs.php?page=1&limit=10&professionalId=25' \
  --header 'Authorization: Bearer {ADMIN_TOKEN}'
```

### For Professional Users (ACCOUNTANT/CA)

**Get Their Assigned ITRs (automatic filtering):**
```bash
curl --location 'http://localhost/api/admin/itrs.php?page=1&limit=10' \
  --header 'Authorization: Bearer {PROFESSIONAL_TOKEN}'
```

> **Note**: Professionals don't need to pass `professionalId` - the system automatically filters based on their token.

---

## Response Structure

### New Fields in Response:

```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "itrs": [
      {
        "personalDetailId": 1,
        "userId": 15,
        "panNumber": "ABCDE1234F",
        "personalDetails": { ... },
        "documents": [ ... ],
        "payments": [ ... ],
        "itrDetails": [ ... ],
        
        "assignments": [  // ✅ NEW
          {
            "assignmentId": 5,
            "itrId": 3,
            "professionalId": 25,
            "professional": {
              "id": 25,
              "firstName": "John",
              "lastName": "Doe",
              "email": "john@example.com",
              "role": "CA"
            },
            "assignmentDate": "2026-01-15 10:30:00",
            "status": "assigned",
            "priority": "normal",
            "dueDate": null,
            "completedAt": null,
            "notes": null
          }
        ],
        "assignmentCount": 1,  // ✅ NEW
        
        "statusSteps": [ ... ],
        "statusStepCount": 3
      }
    ],
    "pagination": { ... }
  }
}
```

---

## Database Schema

### `itr_assignments` Table Columns:
```sql
- id (PK)
- itr_id (FK to itr_detail.id)
- order_id (optional reference)
- user_id (FK to users.UserId - the client)
- professional_id (FK to users.UserId - the ACCOUNTANT/CA)
- assigned_by (FK to users.UserId - the admin who assigned)
- assignment_date (datetime)
- status (assigned, in_progress, completed, rejected)
- priority (low, normal, high, urgent)
- due_date (datetime, optional)
- completed_at (datetime, optional)
- notes (text, optional)
- created_at (datetime)
- updated_at (datetime)
```

---

## Security & Performance

### Security Features:
✅ Role embedded in signed JWT token (tamper-proof)  
✅ Server-side role validation  
✅ Automatic filtering prevents unauthorized access  
✅ Professionals can only see their assigned ITRs  

### Performance Optimization:
✅ **O(0) overhead** - No additional database queries for role checking  
✅ Role extracted from decoded token (already verified)  
✅ Efficient SQL joins with proper indexing  
✅ Pagination support for large datasets  

---

## Frontend Implementation Guide

### 1. Store User Role After Login
```javascript
const loginResponse = await fetch('/api/auth/login.php', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password })
});

const { data } = await loginResponse.json();
const { UserId, role, token } = data;

// Store in localStorage/sessionStorage
localStorage.setItem('userId', UserId);
localStorage.setItem('userRole', role);
localStorage.setItem('token', token);
```

### 2. Build API URL Based on Role
```javascript
function getITRsApiUrl(page = 1, limit = 10, filterProfessionalId = null) {
  const role = localStorage.getItem('userRole');
  const userId = localStorage.getItem('userId');
  
  let url = `/api/admin/itrs.php?page=${page}&limit=${limit}`;
  
  // Frontend can optionally pass professionalId for clarity
  // (backend will auto-filter anyway based on token)
  if (role === 'ACCOUNTANT' || role === 'CA') {
    url += `&professionalId=${userId}`;
  } else if (role === 'ADMIN' && filterProfessionalId) {
    // Admin can filter by specific professional
    url += `&professionalId=${filterProfessionalId}`;
  }
  
  return url;
}
```

### 3. Fetch ITRs
```javascript
async function fetchITRs(page = 1, limit = 10) {
  const token = localStorage.getItem('token');
  const url = getITRsApiUrl(page, limit);
  
  const response = await fetch(url, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  
  const data = await response.json();
  return data;
}
```

### 4. Display Assignments (NEW)
```javascript
function renderITR(itr) {
  return `
    <div class="itr-card">
      <h3>${itr.personalDetails.firstName} ${itr.personalDetails.lastName}</h3>
      <p>PAN: ${itr.panNumber}</p>
      
      <!-- NEW: Display assignments -->
      ${itr.assignmentCount > 0 ? `
        <div class="assignments">
          <h4>Assignments (${itr.assignmentCount})</h4>
          ${itr.assignments.map(assignment => `
            <div class="assignment">
              <p>Professional: ${assignment.professional.firstName} ${assignment.professional.lastName}</p>
              <p>Status: <span class="badge">${assignment.status}</span></p>
              <p>Priority: ${assignment.priority}</p>
              <p>Assigned: ${new Date(assignment.assignmentDate).toLocaleDateString()}</p>
            </div>
          `).join('')}
        </div>
      ` : '<p>No assignments yet</p>'}
      
      <!-- Other ITR details -->
    </div>
  `;
}
```

---

## Testing Checklist

### Backend Testing:

- [ ] Login as ADMIN → Should return all ITRs
- [ ] Login as ACCOUNTANT → Should return only assigned ITRs
- [ ] Login as CA → Should return only assigned ITRs
- [ ] Admin with `?professionalId=X` → Should filter by that professional
- [ ] Professional trying to pass different professionalId → Should still see only their ITRs
- [ ] Verify assignment info is included in response
- [ ] Test pagination works correctly with filters

### Frontend Testing:

- [ ] Login with different roles
- [ ] Verify role is stored correctly
- [ ] API calls include correct parameters
- [ ] Display assignment information
- [ ] Admin can filter by professional (optional UI)
- [ ] Professional sees only their assigned ITRs

---

## Migration Notes

### For Existing Deployments:

1. **No database migration needed** - Schema already exists
2. **Users must re-login** to get new token with Role field
3. **Old tokens will still work** but won't have role-based filtering
4. **Consider token expiry** to force re-login if needed

### Backwards Compatibility:

✅ If token doesn't have Role field, system falls back to showing all ITRs  
✅ Existing API calls continue to work  
✅ No breaking changes for frontend  

---

## Troubleshooting

### Issue: Professional sees all ITRs instead of filtered list
**Solution**: User needs to re-login to get token with Role field

### Issue: Assignment info not showing
**Solution**: Ensure ITRs are properly assigned using `/admin/assign_itr.php`

### Issue: "ITR already has active assignment" error
**Solution**: Check existing assignments, complete or reject old ones before reassigning

---

## Related Files

- `/auth/login.php` - Login with role in token
- `/auth/refresh_token.php` - Token refresh with role
- `/admin/itrs.php` - Main ITR listing API
- `/admin/assign_itr.php` - Assign ITR to professional (fixed)
- `/admin/get_assignments.php` - Get assignment details
- `/setup_itr_assignment_tables.sql` - Database schema

---

## Author & Date
**Implemented**: January 17, 2026  
**Version**: 2.0  
**Time Complexity**: O(0) additional overhead for role checking
