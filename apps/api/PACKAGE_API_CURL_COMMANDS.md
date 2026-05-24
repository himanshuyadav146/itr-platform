# Package Management API - CURL Test Commands

This document contains CURL commands to test all package-related APIs.

## Setup

Replace the following variables in commands below:
- `{BASE_URL}` - Your API base URL (e.g., `http://allindiaitr.in/api` or `http://localhost/api`)
- `{ADMIN_TOKEN}` - Admin/Professional JWT token
- `{USER_TOKEN}` - Regular user JWT token

## 1. Get All Packages

**Endpoint:** `GET /package/getPackages.php`

**Description:** Retrieve all active packages

```bash
curl --location --request GET '{BASE_URL}/package/getPackages.php' \
--header 'Content-Type: application/json'
```

**Example Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "packages": [
      {
        "id": "1",
        "packagename": "Small Business Plan",
        "price": "3499.00",
        "title1": null,
        "description1": "Business/Profession (Entry level plan for small businesses or professionals.)",
        "title2": null,
        "description2": null,
        "turnover": "Up to 10 lakh",
        "icon": "business_center_outlined",
        "color": "blue",
        "isActive": "1",
        "createdAt": "2026-01-17 12:00:00"
      }
    ]
  }
}
```

---

## 2. Add New Package (Admin Only)

**Endpoint:** `POST /package/addPackage.php`

**Description:** Create a new package (requires Admin/Professional authentication)

```bash
curl --location --request POST '{BASE_URL}/package/addPackage.php' \
--header 'Authorization: Bearer {ADMIN_TOKEN}' \
--header 'Content-Type: application/json' \
--data-raw '{
  "packagename": "Test Business Plan",
  "price": 5999,
  "description1": "Test package for business professionals",
  "turnover": "50-100 Lakh",
  "icon": "business_outline",
  "color": "red",
  "isActive": 1
}'
```

**Example Response:**
```json
{
  "status": "success",
  "statusCode": 201,
  "data": {
    "message": "Package added successfully",
    "packageId": 8
  }
}
```

---

## 3. Update Existing Package (Admin Only)

**Endpoint:** `POST /package/addPackage.php`

**Description:** Update an existing package by providing the `id` field

```bash
curl --location --request POST '{BASE_URL}/package/addPackage.php' \
--header 'Authorization: Bearer {ADMIN_TOKEN}' \
--header 'Content-Type: application/json' \
--data-raw '{
  "id": 1,
  "packagename": "Updated Small Business Plan",
  "price": 3999,
  "description1": "Updated description for small business plan",
  "turnover": "Up to 15 lakh",
  "icon": "business_center",
  "color": "lightblue"
}'
```

**Example Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Package updated successfully",
    "packageId": 1
  }
}
```

---

## 4. Delete Package (Admin Only)

**Endpoint:** `POST /package/deletePackage.php`

**Description:** Delete a package by id (requires Admin/Professional authentication)

```bash
curl --location --request POST '{BASE_URL}/package/deletePackage.php' \
--header 'Authorization: Bearer {ADMIN_TOKEN}' \
--header 'Content-Type: application/json' \
--data-raw '{"id": 3}'
```

**Example Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Package deleted successfully",
    "packageId": 3
  }
}
```

---

## 5. Submit Personal Details with Package

**Endpoint:** `POST /itrdetails/personal_details.php`

**Description:** Submit personal details and associate with a package

```bash
curl --location --request POST '{BASE_URL}/itrdetails/personal_details.php' \
--header 'Authorization: Bearer {USER_TOKEN}' \
--header 'Content-Type: application/json' \
--data-raw '{
  "panNumber": "ABCDE1234F",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "mobileNumber": "9876543210",
  "packageId": 1,
  "financialYear": "2024-25",
  "gender": "Male",
  "address": "123 Main Street, Mumbai"
}'
```

**Example Response:**
```json
{
  "status": "success",
  "statusCode": 201,
  "data": {
    "message": "Personal details added successfully",
    "panNumber": "ABCDE1234F"
  }
}
```

---

## 6. Get Payment Info with Package Details

**Endpoint:** `GET /payment/get_payment_info.php?packageId={packageId}`

**Description:** Retrieve payment information including package details

```bash
curl --location --request GET '{BASE_URL}/payment/get_payment_info.php?packageId=1' \
--header 'Authorization: Bearer {USER_TOKEN}' \
--header 'Content-Type: application/json'
```

**Example Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "order_details": {
      "Name": "John Doe",
      "phone": "9876543210",
      "email": "john.doe@example.com"
    },
    "payment_summary": [
      {
        "display_title": "Small Business Plan Package",
        "display_value": "₹3499",
        "amount": 3499,
        "type": "package"
      },
      {
        "display_title": "Total (Before GST)",
        "display_value": "₹3499",
        "amount": 3499,
        "type": "subtotal"
      },
      {
        "display_title": "GST @18%",
        "display_value": "₹630",
        "amount": 629.82
      },
      {
        "display_title": "GRAND TOTAL",
        "display_value": "₹4129",
        "amount": 4128.82,
        "type": "grand_total"
      }
    ],
    "package": {
      "id": 1,
      "name": "Small Business Plan",
      "description": "Business/Profession (Entry level plan for small businesses or professionals.)",
      "turnover": "Up to 10 lakh",
      "price": "₹3499",
      "icon": "business_center_outlined",
      "color": "blue"
    },
    "gateway_details": {
      "MID": "RgSGKJiDNpMKj7"
    }
  }
}
```

---

## 7. Get Payment Info with PAN Number and Package

**Endpoint:** `GET /payment/get_payment_info.php?packageId={packageId}&panNumber={panNumber}`

**Description:** Retrieve payment info using personal details from PAN

```bash
curl --location --request GET '{BASE_URL}/payment/get_payment_info.php?packageId=1&panNumber=ABCDE1234F' \
--header 'Authorization: Bearer {USER_TOKEN}' \
--header 'Content-Type: application/json'
```

---

## Complete Frontend Workflow Test

### Step 1: User views packages
```bash
curl --location --request GET 'http://allindiaitr.in/api/package/getPackages.php'
```

### Step 2: User selects package (id=1) and submits personal details
```bash
curl --location --request POST 'http://allindiaitr.in/api/itrdetails/personal_details.php' \
--header 'Authorization: Bearer eyJhbGc...' \
--header 'Content-Type: application/json' \
--data-raw '{
  "panNumber": "ABCDE1234F",
  "firstName": "Himanshu",
  "lastName": "Yadav",
  "email": "himanshu@example.com",
  "mobileNumber": "9876543210",
  "packageId": 1,
  "financialYear": "2024-25"
}'
```

### Step 3: User proceeds to payment
```bash
curl --location --request GET 'http://allindiaitr.in/api/payment/get_payment_info.php?packageId=1' \
--header 'Authorization: Bearer eyJhbGc...' \
--header 'Content-Type: application/json'
```

---

## Error Handling

### Invalid Package ID
```bash
curl --location --request GET '{BASE_URL}/payment/get_payment_info.php?packageId=999' \
--header 'Authorization: Bearer {USER_TOKEN}'
```
**Response:** Payment summary will not include package details if package not found.

### Unauthorized Access (Non-admin trying to add package)
```bash
curl --location --request POST '{BASE_URL}/package/addPackage.php' \
--header 'Authorization: Bearer {USER_TOKEN}' \
--header 'Content-Type: application/json' \
--data-raw '{
  "packagename": "Test Package",
  "price": 1000
}'
```
**Response:**
```json
{
  "status": "error",
  "statusCode": 403,
  "data": {
    "message": "Access denied. Admin or Professional role required."
  }
}
```

### Missing Required Fields
```bash
curl --location --request POST '{BASE_URL}/package/addPackage.php' \
--header 'Authorization: Bearer {ADMIN_TOKEN}' \
--header 'Content-Type: application/json' \
--data-raw '{
  "packagename": "Test Package"
}'
```
**Response:**
```json
{
  "status": "error",
  "statusCode": 400,
  "data": {
    "message": "Package name and price are required"
  }
}
```

---

## Testing Checklist

- [ ] Get all packages without authentication
- [ ] Add new package as admin
- [ ] Update existing package as admin
- [ ] Try to add package as regular user (should fail with 403)
- [ ] Submit personal details with packageId
- [ ] Get payment info with packageId
- [ ] Get payment info with packageId and panNumber
- [ ] Verify package details appear in payment response
- [ ] Test with invalid packageId
- [ ] Test with missing required fields

---

**Note:** Make sure to run database migrations before testing these APIs.

See `migrations/README.md` for migration instructions.
