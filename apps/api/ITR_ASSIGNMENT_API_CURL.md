# ITR Assignment to Associates API - Curl Commands

This document contains all curl commands for managing ITR assignments to associates/professionals.

## Base URL
```
http://localhost/api
```

**Note:** Replace `http://localhost/api` with your actual API base URL if different.

---

## Prerequisites

### Database Setup (IMPORTANT!)

**Before using these APIs, you must create the required database table:**

1. **Open phpMyAdmin**: `http://localhost/phpmyadmin`
2. **Select your database** (e.g., `itr_services`, `allindia_services`)
3. **Click "SQL" tab**
4. **Copy and paste the contents of `setup_itr_assignment_tables.sql`**
5. **Click "Go"** to execute

This will create:
- `itr_assignments` table - For storing ITR assignments

**Note:** 
- Uses existing `users` table (no separate professionals table needed)
- Associates/Professionals are users with `Role='ACCOUNTANT'` or `Role='CA'`
- To get list of associates, use `/admin/users.php?role=ACCOUNTANT` or `/admin/users.php?role=CA`

### API Prerequisites

1. **Login First** - You need to get an authentication token before using these APIs
2. **Token** - Save the token from login response and use it in `Authorization: Bearer {token}` header

### Step 1: Login to Get Token

```bash
curl -X POST http://localhost/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "your_password",
    "platform": "web",
    "version": "1.0"
  }'
```

**Response Example:**
```json
{
  "status": "success",
  "data": {
    "token": "your_jwt_token_here",
    "UserId": 1
  }
}
```

**Save the token for use in all subsequent requests!**

---

## 1. Get Associates/Professionals

**Note:** Associates/Professionals are users with `Role='ACCOUNTANT'` or `Role='CA'`. Use the existing `/admin/users.php` API to get them.

**⚠️ IMPORTANT:** If you get empty results, it means no users have `Role='ACCOUNTANT'` or `Role='CA'` yet. You need to update user roles first (see section below).

### 1.1. Check All Users and Their Roles

**First, check what roles exist in your database:**

Visit in browser: `http://localhost/api/check_users_roles.php`

This will show you all users and their current roles, and provide SQL commands to update roles.

### 1.2. Update User Role to ACCOUNTANT or CA

**You need to set user roles in the database first. Run this SQL in phpMyAdmin:**

```sql
-- Set a user as ACCOUNTANT (replace USER_ID with actual user ID, e.g., 5)
UPDATE users SET Role = 'ACCOUNTANT' WHERE UserId = 5;

-- Set a user as CA
UPDATE users SET Role = 'CA' WHERE UserId = 4;
```

**Or update by email:**
```sql
-- Set by email
UPDATE users SET Role = 'ACCOUNTANT' WHERE Email = 'aman124@yopmail.com';
UPDATE users SET Role = 'CA' WHERE Email = 'aman123@yopmail.com';
```

### 1.3. Get All Associates (ACCOUNTANT role)

**Endpoint:** `GET /admin/users.php?role=ACCOUNTANT`

```bash
curl -X GET "http://localhost/api/admin/users.php?role=ACCOUNTANT&page=1&limit=100" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 1.4. Get All Associates (CA role)

**Endpoint:** `GET /admin/users.php?role=CA`

```bash
curl -X GET "http://localhost/api/admin/users.php?role=CA&page=1&limit=100" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 1.5. Search Associates

```bash
curl -X GET "http://localhost/api/admin/users.php?role=ACCOUNTANT&search=john&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "users": [
      {
        "userId": 5,
        "firstName": "John",
        "lastName": "Doe",
        "email": "john.doe@example.com",
        "mobile": "9876543210",
        "role": "ACCOUNTANT",
        "platform": "web",
        "createdAt": "2024-01-15 10:30:00"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1,
      "totalPages": 1
    }
  }
}
```

**Note:** Use the `userId` from the response as `professionalId` when assigning ITRs.

---

## 2. Assign ITR to Associate

### 2.1. Assign ITR to Professional

**Endpoint:** `POST /admin/assign_itr.php`

**Required Fields:** `itrId`, `professionalId` (userId of associate), `userId` (client userId)

**Optional Fields:** `orderId`, `priority`, `dueDate`, `notes`

**Priority Values:** `low`, `normal`, `high`, `urgent` (default: `normal`)

**Important:** `professionalId` must be a userId of a user with `Role='ACCOUNTANT'` or `Role='CA'`

```bash
curl -X POST http://localhost/api/admin/assign_itr.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "itrId": 1,
    "professionalId": 5,
    "userId": 10,
    "orderId": "ORD123456",
    "priority": "high",
    "dueDate": "2024-02-15 23:59:59",
    "notes": "Urgent assignment - Client needs filing by month end"
  }'
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 201,
  "data": {
    "message": "ITR assigned successfully",
    "assignmentId": 1
  }
}
```

**Minimal Example (Required Fields Only):**

```bash
curl -X POST http://localhost/api/admin/assign_itr.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "itrId": 1,
    "professionalId": 5,
    "userId": 10
  }'
```

---

## 3. Get ITR Assignments

### 3.1. List All Assignments

**Endpoint:** `GET /admin/get_assignments.php`

**Query Parameters:**
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20, max: 100)
- `itrId` - Filter by ITR ID (optional)
- `professionalId` - Filter by Professional ID (userId) (optional)
- `userId` - Filter by User ID (optional)
- `orderId` - Filter by Order ID (optional)
- `status` - Filter by status: `assigned`, `in_progress`, `completed`, `rejected` (optional)
- `priority` - Filter by priority: `low`, `normal`, `high`, `urgent` (optional)

#### Get All Assignments

```bash
curl -X GET "http://localhost/api/admin/get_assignments.php?page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Get Assignments by ITR ID

```bash
curl -X GET "http://localhost/api/admin/get_assignments.php?itrId=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Get Assignments by Professional ID

```bash
curl -X GET "http://localhost/api/admin/get_assignments.php?professionalId=5&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Get Assignments by Status

```bash
curl -X GET "http://localhost/api/admin/get_assignments.php?status=assigned&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Get Assignments by User ID

```bash
curl -X GET "http://localhost/api/admin/get_assignments.php?userId=10&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Get Assignments by Priority

```bash
curl -X GET "http://localhost/api/admin/get_assignments.php?priority=high&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Combined Filters

```bash
curl -X GET "http://localhost/api/admin/get_assignments.php?professionalId=5&status=in_progress&priority=high&page=1&limit=20" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "assignments": [
      {
        "id": 1,
        "itrId": 1,
        "orderId": "ORD123456",
        "userId": 10,
        "professionalId": 5,
        "assignedBy": 1,
        "assignmentDate": "2024-01-15 10:30:00",
        "status": "assigned",
        "priority": "high",
        "dueDate": "2024-02-15 23:59:59",
        "completedAt": null,
        "notes": "Urgent assignment - Client needs filing by month end",
        "createdAt": "2024-01-15 10:30:00",
        "updatedAt": "2024-01-15 10:30:00",
        "itr": {
          "id": 1,
          "panNumber": "ABCDE1234F",
          "financialYear": "2023-24",
          "status": "pending"
        },
        "professional": {
          "id": 5,
          "firstName": "John",
          "lastName": "Doe",
          "email": "john.doe@example.com",
          "mobile": "9876543210",
          "role": "ACCOUNTANT"
        },
        "user": {
          "id": 10,
          "firstName": "Jane",
          "lastName": "Smith",
          "email": "jane.smith@example.com",
          "mobile": "9876543211"
        },
        "assignedByUser": {
          "id": 1,
          "firstName": "Admin",
          "lastName": "User"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1,
      "totalPages": 1
    }
  }
}
```

---

## 4. Update Assignment

### 4.1. Update Assignment Status

**Endpoint:** `PUT /admin/update_assignment.php`

**Required Field:** `assignmentId`

**Optional Fields:** `status`, `priority`, `dueDate`, `notes`, `professionalId`

**Status Values:** `assigned`, `in_progress`, `completed`, `rejected`

**Priority Values:** `low`, `normal`, `high`, `urgent`

#### Update Status

```bash
curl -X PUT http://localhost/api/admin/update_assignment.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "assignmentId": 1,
    "status": "in_progress"
  }'
```

#### Update Status to Completed

```bash
curl -X PUT http://localhost/api/admin/update_assignment.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "assignmentId": 1,
    "status": "completed"
  }'
```

#### Update Priority

```bash
curl -X PUT http://localhost/api/admin/update_assignment.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "assignmentId": 1,
    "priority": "urgent"
  }'
```

#### Update Due Date

```bash
curl -X PUT http://localhost/api/admin/update_assignment.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "assignmentId": 1,
    "dueDate": "2024-02-20 23:59:59"
  }'
```

#### Update Notes

```bash
curl -X PUT http://localhost/api/admin/update_assignment.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "assignmentId": 1,
    "notes": "Documents received. Processing in progress."
  }'
```

#### Reassign to Different Professional

```bash
curl -X PUT http://localhost/api/admin/update_assignment.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "assignmentId": 1,
    "professionalId": 6
  }'
```

**Note:** The new `professionalId` must be a userId of a user with `Role='ACCOUNTANT'` or `Role='CA'`

#### Multiple Fields Update

```bash
curl -X PUT http://localhost/api/admin/update_assignment.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "assignmentId": 1,
    "status": "in_progress",
    "priority": "high",
    "notes": "Work started. Expected completion by end of week."
  }'
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Assignment updated successfully"
  }
}
```

---

## Complete Workflow Example

### Step-by-Step Workflow

#### Step 1: Login
```bash
curl -X POST http://localhost/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "your_password",
    "platform": "web",
    "version": "1.0"
  }'
```

**Save the token from response!**

#### Step 2: Check Users and Set Roles (if needed)

**First, check existing users:**
Visit: `http://localhost/api/check_users_roles.php`

**If no users have ACCOUNTANT or CA role, update them in phpMyAdmin:**

```sql
-- Example: Set user with UserId=5 as ACCOUNTANT
UPDATE users SET Role = 'ACCOUNTANT' WHERE UserId = 5;

-- Example: Set user with UserId=4 as CA
UPDATE users SET Role = 'CA' WHERE UserId = 4;
```

#### Step 3: Get List of Associates

```bash
# Get all ACCOUNTANT role users (associates)
curl -X GET "http://localhost/api/admin/users.php?role=ACCOUNTANT&page=1&limit=100" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Save the userId from response (this is the professionalId for assignment)!**

#### Step 4: Assign ITR to Associate

```bash
curl -X POST http://localhost/api/admin/assign_itr.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "itrId": 1,
    "professionalId": 5,
    "userId": 10,
    "priority": "high",
    "dueDate": "2024-02-15 23:59:59",
    "notes": "Urgent assignment"
  }'
```

**Save the assignmentId from response!**

#### Step 5: Get Assignment Details

```bash
curl -X GET "http://localhost/api/admin/get_assignments.php?itrId=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### Step 6: Update Assignment Status

```bash
curl -X PUT http://localhost/api/admin/update_assignment.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "assignmentId": 1,
    "status": "in_progress",
    "notes": "Work started"
  }'
```

#### Step 7: Mark Assignment as Completed

```bash
curl -X PUT http://localhost/api/admin/update_assignment.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "assignmentId": 1,
    "status": "completed"
  }'
```

---

## Error Responses

### 401 Unauthorized (Invalid/Expired Token)
```json
{
  "status": "error",
  "statusCode": 401,
  "data": {
    "message": "Invalid or expired token"
  }
}
```

### 400 Bad Request (Missing/Invalid Fields)
```json
{
  "status": "error",
  "statusCode": 400,
  "data": {
    "message": "itrId, professionalId, and userId are required"
  }
}
```

### 404 Not Found
```json
{
  "status": "error",
  "statusCode": 404,
  "data": {
    "message": "Professional not found. User must have Role='ACCOUNTANT' or Role='CA' and be active"
  }
}
```

### 409 Conflict (Already Exists)
```json
{
  "status": "error",
  "statusCode": 409,
  "data": {
    "message": "ITR already has an active assignment"
  }
}
```

### 500 Server Error
```json
{
  "status": "error",
  "statusCode": 500,
  "data": {
    "message": "Error assigning ITR: [database error]"
  }
}
```

---

## Notes

1. **Database Setup**: Make sure to run `setup_itr_assignment_tables.sql` first to create the `itr_assignments` table!

2. **No Separate Professionals Table**: Associates/Professionals are users with `Role='ACCOUNTANT'` or `Role='CA'`. Use `/admin/users.php?role=ACCOUNTANT` or `/admin/users.php?role=CA` to get them.

3. **Empty Results?** If you get empty results when querying for ACCOUNTANT/CA users, it means no users have these roles yet. You need to update user roles in the database first using SQL: `UPDATE users SET Role = 'ACCOUNTANT' WHERE UserId = X;` Use `check_users_roles.php` to see current roles.

3. **Token Expiration**: Tokens typically expire after 10 hours. Re-login if you get 401 errors.

4. **Database Tables Required**: 
   - `itr_assignments` table (created by `setup_itr_assignment_tables.sql`)
   - `users` table (should already exist with Role column)
   - `itr_detail` table (should already exist)

5. **Role Values**: Associates should have `Role='ACCOUNTANT'` or `Role='CA'` in the users table.

6. **Assignment Status Flow**: 
   - `assigned` → `in_progress` → `completed`
   - Can also be `rejected` at any point

7. **Priority Levels**: 
   - `low` - Low priority
   - `normal` - Normal priority (default)
   - `high` - High priority
   - `urgent` - Urgent priority

8. **Date Format**: Use MySQL datetime format: `YYYY-MM-DD HH:MM:SS` (e.g., `2024-02-15 23:59:59`)

9. **500 Error**: If you get a 500 error, it usually means the `itr_assignments` table doesn't exist. Run the SQL setup script!

---

## Quick Reference

| Operation | Method | Endpoint | Required Fields |
|-----------|--------|----------|----------------|
| Get Associates | GET | `/admin/users.php?role=ACCOUNTANT` or `?role=CA` | - |
| Assign ITR | POST | `/admin/assign_itr.php` | itrId, professionalId (userId), userId |
| Get Assignments | GET | `/admin/get_assignments.php` | - |
| Update Assignment | PUT | `/admin/update_assignment.php` | assignmentId |

---

## Support

For issues or questions, check:
- Database connection settings in `include/config.php`
- Table existence in database (`itr_assignments`)
- Token validity
- Required fields in requests
- User role must be 'ACCOUNTANT' or 'CA' for associates
