# Dynamic ITR Status System - Implementation Guide

## 🎯 Overview

This system provides a fully dynamic, database-driven status tracking solution for ITR filing. Tax professionals control the workflow from the admin panel, and all status information comes from the backend.

## 📦 What's Included

### Database Tables
1. **`itr_status_config`** - Status step configurations (dynamic)
2. **`itr_status_audit`** - Complete audit trail of all changes
3. **`itr_assignments`** - Enhanced with `is_active` column

### API Endpoints
1. **`GET /itr_status/get_status_config.php`** - Public status configuration
2. **`PUT /admin/update_status_step.php`** - Professional status updates
3. **`GET /admin/status_config.php`** - View all configurations (Admin)
4. **`POST /admin/status_config.php`** - Create new step (Admin)
5. **`PUT /admin/status_config.php`** - Update configuration (Admin)
6. **`DELETE /admin/status_config.php`** - Deactivate step (Admin)
7. **`GET /admin/get_status_audit.php`** - View audit trail

## 🚀 Installation Steps

### Step 1: Run Database Migration

```bash
# Navigate to your project
cd /Applications/XAMPP/xamppfiles/htdocs/api

# Run the migration SQL file in phpMyAdmin or MySQL command line
# File: migrations/create_dynamic_status_system.sql
```

Or via MySQL command line:
```bash
mysql -u your_username -p itr_services < migrations/create_dynamic_status_system.sql
```

### Step 2: Verify Installation

Check that tables were created:
```sql
USE itr_services;
SHOW TABLES LIKE 'itr_status%';
SELECT * FROM itr_status_config;
```

You should see 5 default status steps configured.

### Step 3: Test APIs

Test the public configuration endpoint:
```bash
curl -X GET 'http://localhost/api/itr_status/get_status_config.php'
```

## 📋 Default Status Steps

| Step | Title | Automatic | Role Required | Revertable |
|------|-------|-----------|---------------|------------|
| payment_success | Payment Success | ✅ Yes | - | ❌ No |
| expert_assigned | Tax Expert Assigned | ✅ Yes | - | ❌ No |
| documents_verified | Documents Verification | ❌ Manual | Any Professional | ✅ Yes |
| filing_itr | Filing ITR | ❌ Manual | CA, Accountant | ✅ Yes |
| acknowledgement_generated | Acknowledgement Generated | ❌ Manual | CA, Admin | ❌ No |

## 🔐 Role-Based Access Control

### Automatic Steps
- **payment_success**: Auto-created by payment webhook
- **expert_assigned**: Auto-created when ITR assigned to professional

### Manual Steps (Professionals Only)
- **documents_verified**: Any professional assigned to ITR
- **filing_itr**: Only CA and Accountant roles
- **acknowledgement_generated**: Only CA and Admin roles

## 📝 CURL Examples

### 1. Get Status Configuration (Public)
```bash
curl -X GET 'http://localhost/api/itr_status/get_status_config.php'
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "steps": [
      {
        "step": "payment_success",
        "title": "Payment Success",
        "subtitle": "Payment confirmed and verified",
        "order": 1,
        "icon": "payment",
        "color": "#28a745",
        "isAutomatic": true,
        "requiresAssignment": false,
        "requiresDocuments": false,
        "canBeReverted": false,
        "requiredRole": null
      }
      // ... more steps
    ],
    "totalSteps": 5
  }
}
```

### 2. Professional: Mark Documents Verified
```bash
curl -X PUT 'http://localhost/api/admin/update_status_step.php' \
  -H 'Authorization: Bearer YOUR_PROFESSIONAL_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "orderId": "order_NMAbCdEfGhIj123",
    "statusStep": "documents_verified",
    "isCompleted": true,
    "notes": "Verified: PAN card, Aadhar, Form 16, Bank statements"
  }'
```

**Success Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Status step updated successfully",
    "statusStep": "documents_verified",
    "isCompleted": true,
    "previousState": false,
    "action": "completed",
    "updatedBy": {
      "id": 45,
      "role": "ACCOUNTANT"
    },
    "timestamp": "2024-03-15 14:30:45"
  }
}
```

### 3. CA: Mark ITR Filed
```bash
curl -X PUT 'http://localhost/api/admin/update_status_step.php' \
  -H 'Authorization: Bearer YOUR_CA_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "itrId": 45,
    "statusStep": "filing_itr",
    "isCompleted": true,
    "notes": "ITR-1 filed successfully on income tax portal"
  }'
```

### 4. CA: Add Acknowledgement Number
```bash
curl -X PUT 'http://localhost/api/admin/update_status_step.php' \
  -H 'Authorization: Bearer YOUR_CA_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "orderId": "order_NMAbCdEfGhIj123",
    "statusStep": "acknowledgement_generated",
    "isCompleted": true,
    "notes": "Acknowledgement No: 123456789012345 | AY: 2024-25"
  }'
```

### 5. Admin: View All Status Configurations
```bash
curl -X GET 'http://localhost/api/admin/status_config.php' \
  -H 'Authorization: Bearer YOUR_ADMIN_TOKEN'
```

### 6. Admin: Create New Status Step
```bash
curl -X POST 'http://localhost/api/admin/status_config.php' \
  -H 'Authorization: Bearer YOUR_ADMIN_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "stepCode": "quality_review",
    "title": "Quality Review",
    "subtitle": "Internal quality check completed",
    "description": "Internal review before final filing",
    "displayOrder": 3.5,
    "icon": "verified_user",
    "color": "#28a745",
    "isAutomatic": false,
    "requiresAssignment": true,
    "requiresDocuments": true,
    "canBeReverted": true,
    "requiredRole": "CA"
  }'
```

### 7. Admin: Update Configuration
```bash
curl -X PUT 'http://localhost/api/admin/status_config.php' \
  -H 'Authorization: Bearer YOUR_ADMIN_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "id": 3,
    "title": "Documents Fully Verified",
    "subtitle": "All documents checked and approved",
    "color": "#28a745"
  }'
```

### 8. Admin: Deactivate Status Step
```bash
curl -X DELETE 'http://localhost/api/admin/status_config.php?id=6' \
  -H 'Authorization: Bearer YOUR_ADMIN_TOKEN'
```

### 9. View Audit Trail
```bash
curl -X GET 'http://localhost/api/admin/get_status_audit.php?orderId=order_123' \
  -H 'Authorization: Bearer YOUR_PROFESSIONAL_TOKEN'
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "auditLog": [
      {
        "id": 15,
        "statusStep": "documents_verified",
        "stepTitle": "Documents Verification",
        "action": "completed",
        "previousValue": false,
        "newValue": true,
        "notes": "All documents verified",
        "updatedBy": {
          "id": 45,
          "name": "John Doe",
          "email": "john@example.com",
          "role": "ACCOUNTANT"
        },
        "ipAddress": "192.168.1.100",
        "timestamp": "2024-03-15 14:30:45"
      }
    ],
    "summary": {
      "totalChanges": 5,
      "uniqueSteps": 3,
      "uniqueUpdaters": 2,
      "firstUpdate": "2024-03-15 10:00:00",
      "lastUpdate": "2024-03-15 14:30:45"
    }
  }
}
```

## ❌ Error Handling Examples

### Error: Try to Update Automatic Step
```bash
curl -X PUT 'http://localhost/api/admin/update_status_step.php' \
  -H 'Authorization: Bearer TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "orderId": "order_123",
    "statusStep": "payment_success",
    "isCompleted": false
  }'
```

**Response:**
```json
{
  "status": "error",
  "statusCode": 400,
  "data": {
    "message": "This step is automatically updated by the system and cannot be manually changed",
    "step": "payment_success",
    "isAutomatic": true
  }
}
```

### Error: Insufficient Role Permissions
```bash
curl -X PUT 'http://localhost/api/admin/update_status_step.php' \
  -H 'Authorization: Bearer ACCOUNTANT_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "orderId": "order_123",
    "statusStep": "acknowledgement_generated",
    "isCompleted": true
  }'
```

**Response:**
```json
{
  "status": "error",
  "statusCode": 403,
  "data": {
    "message": "Insufficient permissions for this step",
    "requiredRoles": ["CA", "ADMIN"],
    "yourRole": "ACCOUNTANT",
    "step": "acknowledgement_generated"
  }
}
```

### Error: No Documents Uploaded
```bash
# When trying to verify documents but none are uploaded
```

**Response:**
```json
{
  "status": "error",
  "statusCode": 400,
  "data": {
    "message": "Documents must be uploaded before completing this step",
    "documentsCount": 0,
    "step": "documents_verified"
  }
}
```

### Error: Not Assigned to ITR
```bash
# When professional tries to update ITR they're not assigned to
```

**Response:**
```json
{
  "status": "error",
  "statusCode": 403,
  "data": {
    "message": "You are not assigned to this ITR",
    "assignedTo": 42,
    "yourId": 45
  }
}
```

### Error: Cannot Revert Non-Revertable Step
```bash
# When trying to mark payment_success as incomplete
```

**Response:**
```json
{
  "status": "error",
  "statusCode": 400,
  "data": {
    "message": "This step cannot be reverted once completed",
    "step": "payment_success",
    "canBeReverted": false
  }
}
```

## 🔄 Workflow Integration

### Payment Webhook Integration
When payment succeeds, automatically create status:

```php
// In payment/webhook.php or payment/verify_payment.php
require '../itr_status/StatusHelper.php';

if ($paymentStatus === 'success') {
    StatusHelper::updateStatusStep(
        $conn,
        $orderId,
        $itrId,
        $userId,
        $paymentId,
        $panNumber,
        'payment_success',
        true,
        'Payment completed via ' . $gateway
    );
}
```

### Assignment Integration
When assigning ITR to professional:

```php
// In admin/assign_itr.php
require '../itr_status/StatusHelper.php';

// After successful assignment
StatusHelper::updateStatusStep(
    $conn,
    $orderId,
    $itrId,
    $userId,
    $paymentId,
    $panNumber,
    'expert_assigned',
    true,
    'Assigned to: ' . $professionalName
);
```

## 📊 Database Schema

### itr_status_config Table
```sql
CREATE TABLE `itr_status_config` (
  `id` int(11) PRIMARY KEY AUTO_INCREMENT,
  `step_code` varchar(50) UNIQUE NOT NULL,
  `title` varchar(255) NOT NULL,
  `subtitle` varchar(500),
  `description` text,
  `display_order` int(11) NOT NULL,
  `icon` varchar(50),
  `color` varchar(20),
  `is_automatic` tinyint(1) DEFAULT 0,
  `requires_assignment` tinyint(1) DEFAULT 0,
  `requires_documents` tinyint(1) DEFAULT 0,
  `can_be_reverted` tinyint(1) DEFAULT 1,
  `required_role` varchar(50),
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### itr_status_audit Table
```sql
CREATE TABLE `itr_status_audit` (
  `id` int(11) PRIMARY KEY AUTO_INCREMENT,
  `status_id` int(11) NOT NULL,
  `order_id` varchar(100),
  `itr_id` int(11),
  `status_step` varchar(50) NOT NULL,
  `action` varchar(20) NOT NULL,
  `previous_value` tinyint(1),
  `new_value` tinyint(1),
  `updated_by` int(11) NOT NULL,
  `updated_by_role` varchar(50),
  `notes` text,
  `ip_address` varchar(50),
  `user_agent` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`status_id`) REFERENCES `itr_order_status`(`id`),
  FOREIGN KEY (`updated_by`) REFERENCES `users`(`UserId`)
);
```

## ✅ Testing Checklist

- [ ] Database migration runs successfully
- [ ] 5 default status steps are configured
- [ ] `itr_status_audit` table created
- [ ] `is_active` column added to `itr_assignments`
- [ ] Public config API returns status steps
- [ ] Admin can view all configurations
- [ ] Admin can create new status step
- [ ] Admin can update existing configuration
- [ ] Admin can deactivate status step
- [ ] Professional can mark documents verified
- [ ] CA can mark ITR filed
- [ ] CA can add acknowledgement number
- [ ] Automatic steps cannot be manually updated
- [ ] Role-based permissions work correctly
- [ ] Assignment validation works
- [ ] Document validation works
- [ ] Non-revertable steps cannot be reverted
- [ ] Audit trail is created for all changes
- [ ] Existing `get_detailed_status.php` still works

## 🔧 Troubleshooting

### Issue: Table already exists error
**Solution:** Tables have `IF NOT EXISTS` - safe to re-run. Or check if tables exist:
```sql
SHOW TABLES LIKE 'itr_status%';
```

### Issue: Foreign key constraint fails
**Solution:** Ensure `itr_order_status` and `users` tables exist first.

### Issue: is_active column error in itr_assignments
**Solution:** The migration script handles this automatically using dynamic SQL.

### Issue: Professional cannot update status
**Checklist:**
1. Is ITR assigned to the professional?
2. Does professional have correct role (CA/ACCOUNTANT)?
3. Are documents uploaded (if required)?
4. Is the step automatic (cannot be manually updated)?

## 🚀 Next Steps

1. **Frontend Integration**: Update your Flutter app to fetch from `get_status_config.php`
2. **Admin Panel**: Create UI for managing status configurations
3. **Notifications**: Add email/SMS notifications when status changes
4. **Reports**: Create reports using audit trail data
5. **Dashboard**: Show real-time status statistics

## 📞 Support

For issues or questions:
- Check the audit trail: `get_status_audit.php`
- Review error responses for detailed messages
- Verify role permissions in database
- Check assignment status in `itr_assignments` table

---

**Version:** 1.0  
**Last Updated:** 2024-03-15  
**Status:** Production Ready ✅
