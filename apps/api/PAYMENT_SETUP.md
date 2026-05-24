# Payment Gateway Integration Setup Guide

## Overview

This payment system is designed to be **generic and flexible**:
- ✅ No hardcoded fee types in the database
- ✅ Fetches user details from existing `users` table
- ✅ Fetches personal details from `personal_details` table
- ✅ Uses `itr_packages` table for package pricing
- ✅ Configurable additional fees via `payment_additional_fees` table
- ✅ Generates unique alphanumeric payment IDs (separate from PAN)
- ✅ Stores all payment details (pass/fail) in `payment_info` table

---

## Step 1: Create Database Tables

Run the SQL script to create the payment tables:

```bash
# Option 1: Via phpMyAdmin
# - Open phpMyAdmin
# - Select your database (itr_services)
# - Go to SQL tab
# - Copy and paste contents of setup_payment_table.sql
# - Click Go

# Option 2: Via MySQL command line
mysql -u root -p itr_services < setup_payment_table.sql
```

This will create:
- `payment_info` - Main payment transaction table
- `payment_additional_fees` - Configurable additional fees (E-Filing Fee, E-Verification Fee, etc.)

---

## Step 2: Install Composer Dependencies

```bash
cd /Applications/XAMPP/xamppfiles/htdocs/api
composer install
```

This will install:
- Paytm SDK (`paytm/paytmchecksum`)
- Razorpay SDK (`razorpay/razorpay`)

---

## Step 3: Payment configuration (test / live mode) – dynamic

All payment gateway settings are **dynamic** and driven by a single config file. You can switch between **test** and **live** mode without code changes.

### 3a. Create payment config

```bash
cp include/payment_config.php.example include/payment_config.php
```

Edit `include/payment_config.php`:

| Variable | Description |
|----------|-------------|
| `$payment_mode` | `'test'` or `'live'` – switches keys and behaviour |
| `$razorpay_key_id_test` / `$razorpay_secret_test` | From [Razorpay Dashboard](https://dashboard.razorpay.com/) → API Keys → Generate **Test** Key |
| `$razorpay_key_id_live` / `$razorpay_secret_live` | Same place → Generate **Live** Key (real money) |
| `$paytm_merchant_id_test` / `$paytm_merchant_id_live` | Optional, if using Paytm |
| `$payment_default_gateway` | `'razorpay'` or `'paytm'` |

- **Do not commit** `payment_config.php` to git (add to `.gitignore`).
- Main `config.php` automatically loads `payment_config.php` if it exists; otherwise it uses safe defaults (test mode, empty keys).

### 3b. How to manage test vs live

1. **Use test first**  
   Set `$payment_mode = 'test'` and fill only the test keys. All APIs will return test gateway details and no real money is charged.

2. **Switch to live**  
   Set `$payment_mode = 'live'` and fill the live keys. No code change; only this one variable.

3. **Per-environment**  
   Keep different `payment_config.php` on each server (e.g. local = test, production = live), or use env vars and set the variables in a small wrapper that assigns `$payment_mode`, `$razorpay_key_id_*`, etc. from `getenv('PAYMENT_MODE')`, `getenv('RAZORPAY_KEY_ID_LIVE')`, etc.

4. **What the API returns**  
   - `get_payment_info` and `initiate_payment` both return `gateway_details` (or `gateway`) with `mode` and `key_id` so the UI can show “Test mode” and use the correct key.
   - Callback and redirect URLs are built from the current request host, so they stay correct across environments.

---

## Step 4: API Endpoints

### 1. Get Payment Information
**Endpoint:** `GET /payment/get_payment_info.php`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `panNumber` (optional) - PAN number to fetch personal details
- `packageId` (optional) - Package ID to calculate pricing

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "order_details": {
      "Name": "Test Name",
      "phone": "9415555209",
      "email": "himanshu123@yopmail.com"
    },
    "payment_summary": [
      {
        "display_title": "E-Filing Fee",
        "display_value": "₹7999",
        "amount": 7999
      },
      {
        "display_title": "E-Verification Fee",
        "display_value": "₹199",
        "amount": 199
      },
      {
        "display_title": "Total (Before GST)",
        "display_value": "₹8198",
        "amount": 8198,
        "type": "subtotal"
      },
      {
        "display_title": "GST @18%",
        "display_value": "₹1476",
        "amount": 1476
      },
      {
        "display_title": "GRAND TOTAL",
        "display_value": "₹9674",
        "amount": 9674,
        "type": "grand_total"
      }
    ],
    "total": {
      "subtotal": 8198,
      "gst_percentage": 18,
      "gst_amount": 1475.64,
      "grand_total": 9673.64
    },
    "gateway_details": {
      "mode": "test",
      "gateway": "razorpay",
      "key_id": "rzp_test_xxxx",
      "merchant_id": ""
    }
  }
}
```

**How it works:**
- Fetches user details from `users` table
- If PAN provided, fetches personal details from `personal_details` table
- Calculates payment from `itr_packages` (if packageId provided) + `payment_additional_fees`
- Returns formatted payment summary

---

### 2. Initiate Payment
**Endpoint:** `POST /payment/initiate_payment.php`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "panNumber": "ABCDE1234F",
  "packageId": 1
}
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "payment_id": "PAY1234567890ABC123",
    "order_id": "ORD1234567890XYZ789",
    "user_id": 1,
    "pan_number": "ABCDE1234F",
    "amount": 9674,
    "currency": "INR",
    "merchant_id": "",
    "redirect_url": "https://yourdomain.com/api/payment/success.php",
    "gateway": {
      "name": "razorpay",
      "mode": "test",
      "key_id": "rzp_test_xxxx"
    },
    "razorpay_order_id": "order_xxxx",
    "message": "Payment initiated successfully. Use key_id and redirect_url (or razorpay_order_id) to open gateway checkout."
  }
}
```

**Features:**
- ✅ Validates that documents are submitted (if PAN provided)
- ✅ Generates unique alphanumeric payment ID
- ✅ Creates payment record in `payment_info` table with `gateway_name` (dynamic)
- ✅ Calculates amount from package + additional fees
- ✅ Returns **redirect_url**, **gateway** (name, mode, key_id) for UI checkout
- ✅ Optionally creates Razorpay order and returns **razorpay_order_id** when gateway is Razorpay and SDK is installed

---

### 3. Get Payment Status
**Endpoint:** `GET /payment/get_payment_status.php?paymentId={paymentId}`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `paymentId` - Payment ID (or use `orderId`)

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "payment": {
      "id": 1,
      "payment_id": "PAY1234567890ABC123",
      "order_id": "ORD1234567890XYZ789",
      "transaction_id": "TXN123456",
      "payment_status": "success",
      "grand_total": 9674.00,
      "paid_at": "2025-01-15 10:30:00"
    }
  }
}
```

---

### 4. Get Payment History
**Endpoint:** `GET /payment/get_payment_history.php`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "payments": [
      {
        "payment_id": "PAY1234567890ABC123",
        "order_id": "ORD1234567890XYZ789",
        "payment_status": "success",
        "grand_total": 9674.00,
        "packagename": "Premium",
        "customer_name": "Test Name",
        "customer_email": "test@example.com"
      }
    ],
    "count": 1
  }
}
```

**Features:**
- ✅ Fetches data from multiple tables using JOINs
- ✅ No data duplication - uses existing user/personal/package data

---

### 5. Payment Webhook
**Endpoint:** `POST /payment/webhook.php`

This endpoint is called automatically by the payment gateway when payment status changes.

**Features:**
- ✅ Updates payment status in database
- ✅ Stores gateway response and webhook data
- ✅ Logs all payment transactions (pass/fail)
- ✅ Handles success, failed, and cancelled statuses

---

## Step 5: Payment Gateway Integration

You need to integrate the actual payment gateway SDK in `initiate_payment.php`. 

### Example: Paytm Integration

Add this code in `initiate_payment.php` after creating the payment record:

```php
// After payment record is created, generate payment gateway request
require_once '../vendor/autoload.php';

use PaytmChecksum;

// Get gateway credentials from config
$merchantId = "RgSGKJiDNpMKj7";
$merchantKey = "YOUR_MERCHANT_KEY"; // Add to config.php
$website = "WEBSTAGING"; // or "DEFAULT" for production
$industryType = "Retail";
$channelId = "WEB";

$paytmParams = array();
$paytmParams["MID"] = $merchantId;
$paytmParams["ORDER_ID"] = $orderId;
$paytmParams["CUST_ID"] = $userId;
$paytmParams["INDUSTRY_TYPE_ID"] = $industryType;
$paytmParams["CHANNEL_ID"] = $channelId;
$paytmParams["TXN_AMOUNT"] = (string)$breakdown['grand_total'];
$paytmParams["WEBSITE"] = $website;
$paytmParams["CALLBACK_URL"] = $callbackUrl;

$checksum = PaytmChecksum::generateSignature($paytmParams, $merchantKey);
$paytmParams["CHECKSUMHASH"] = $checksum;

// Return payment gateway form data
echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" => [
        "payment_id" => $paymentId,
        "order_id" => $orderId,
        "gateway_url" => "https://securegw-stage.paytm.in/theia/processTransaction", // Use production URL for live
        "gateway_params" => $paytmParams
    ]
]);
```

---

## Step 6: Configure Webhook URL

In your payment gateway dashboard, set the webhook URL to:
```
https://yourdomain.com/api/payment/webhook.php
```

For local testing, you can use:
```
http://localhost/api/payment/webhook.php
```

---

## Database Schema

### payment_info Table
- Stores all payment transactions
- Links to `users` table (user_id)
- Links to `itr_packages` table (package_id)
- References `pan_number` (fetches details from `personal_details`)
- Stores payment status, gateway responses, webhook data

### payment_additional_fees Table
- Configurable additional fees
- Can be managed via admin panel
- Supports multiple fees with display order

---

## Key Features

1. **Generic Design**: No hardcoded fee types - all fees come from database
2. **No Data Duplication**: Fetches user/personal/package data from existing tables
3. **Unique Payment IDs**: Alphanumeric IDs (PAY{timestamp}{random}) separate from PAN
4. **Complete Payment Logging**: All payment attempts (pass/fail) are stored
5. **Document Validation**: Checks if documents are submitted before payment
6. **Flexible Pricing**: Supports packages + configurable additional fees
7. **GST Calculation**: Automatic GST calculation (configurable percentage)

---

## Testing

1. **Test Get Payment Info:**
```bash
curl -X GET "http://localhost/api/payment/get_payment_info.php?packageId=1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

2. **Test Initiate Payment:**
```bash
curl -X POST "http://localhost/api/payment/initiate_payment.php" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"panNumber":"ABCDE1234F","packageId":1}'
```

3. **Test Payment Status:**
```bash
curl -X GET "http://localhost/api/payment/get_payment_status.php?paymentId=PAY1234567890ABC123" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Notes

- Payment ID is generated when payment is initiated (after document submission)
- All payment details are stored in `payment_info` table
- Webhook automatically updates payment status
- User details are fetched from `users` table (not stored in payment_info)
- Personal details are fetched from `personal_details` table (if PAN provided)
- Package details are fetched from `itr_packages` table
- Additional fees are fetched from `payment_additional_fees` table

---

## Support

For issues or questions, check:
- Database connection in `include/config.php`
- Token authentication
- Payment gateway credentials
- Webhook URL accessibility

