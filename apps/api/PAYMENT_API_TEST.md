# Payment API Testing Guide - cURL Commands

## Prerequisites

1. Make sure tables are created: Visit `http://localhost/api/setup_payment.php`
2. You need a valid authentication token

---

## Step 1: Get Authentication Token

First, login to get your token:

```bash
# Login API
curl -X POST http://localhost/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123",
    "platform": "web",
    "version": "1.0"
  }'
```

**Save the token** from the response. You'll need it for all payment APIs.

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

## Step 2: Test Payment APIs

Replace `YOUR_TOKEN_HERE` with the actual token from Step 1.

### 1. Get Payment Information

Get payment info with default fees (no package):

```bash
curl -X GET "http://localhost/api/payment/get_payment_info.php" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

Get payment info with package ID:

```bash
curl -X GET "http://localhost/api/payment/get_payment_info.php?packageId=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

Get payment info with PAN number:

```bash
curl -X GET "http://localhost/api/payment/get_payment_info.php?panNumber=ABCDE1234F&packageId=1" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "order_details": {
      "Name": "Test User",
      "phone": "9876543210",
      "email": "test@example.com"
    },
    "payment_summary": [
      {
        "display_title": "Basic Package",
        "display_value": "₹499",
        "amount": 499
      },
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
        "display_value": "₹8697",
        "amount": 8697,
        "type": "subtotal"
      },
      {
        "display_title": "GST @18%",
        "display_value": "₹1565",
        "amount": 1565.46
      },
      {
        "display_title": "GRAND TOTAL",
        "display_value": "₹10262",
        "amount": 10262.46,
        "type": "grand_total"
      }
    ],
    "gateway_details": {
      "MID": "RgSGKJiDNpMKj7"
    }
  }
}
```

---

### 2. Initiate Payment

**Note:** This will create a payment record. PAN number is mandatory. Make sure you have submitted documents for the PAN number.

```bash
curl -X POST http://localhost/api/payment/initiate_payment.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "panNumber": "ABCDE1234F",
    "packageId": 1
  }'
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "payment_id": "PAY1737024000ABC123",
    "order_id": "ORD1737024000XYZ789",
    "user_id": 17,
    "pan_number": "ABCDE1234F",
    "amount": 10262.46,
    "currency": "INR",
    "merchant_id": "RgSGKJiDNpMKj7",
    "message": "Payment initiated successfully. Integrate with payment gateway SDK here."
  }
}
```

**Save the `payment_id` or `order_id`** from the response for testing status API.

---

### 3. Verify Payment (For Mobile Apps)

**Important for Mobile Apps:** After payment is completed on the gateway, call this endpoint to update the payment status in the database.

```bash
curl -X POST http://localhost/api/payment/verify_payment.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "ORD1737024000XYZ789",
    "paymentStatus": "success",
    "transactionId": "TXN123456789",
    "paymentMethod": "UPI",
    "gatewayName": "razorpay",
    "gatewayResponse": {
      "razorpay_payment_id": "pay_ABC123",
      "razorpay_order_id": "order_XYZ789"
    }
  }'
```

**For Failed Payment:**
```bash
curl -X POST http://localhost/api/payment/verify_payment.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "ORD1737024000XYZ789",
    "paymentStatus": "failed",
    "failureReason": "Payment declined by bank"
  }'
```

**Required Fields:**
- `orderId` (or `order_id`): The order ID returned from initiate_payment
- `paymentStatus` (or `payment_status` or `status`): Payment status (success, failed, cancelled, etc.)

**Optional Fields:**
- `transactionId` (or `transaction_id`): Transaction ID from gateway
- `paymentMethod` (or `payment_method`): Payment method used (UPI, card, netbanking, etc.)
- `gatewayName` (or `gateway_name`): Gateway name (razorpay, paytm, etc.)
- `failureReason` (or `failure_reason`): Reason for failure if payment failed
- `gatewayResponse` (or `gateway_response`): Full gateway response object

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "message": "Payment status updated successfully",
    "payment": {
      "id": 1,
      "payment_id": "PAY1737024000ABC123",
      "order_id": "ORD1737024000XYZ789",
      "transaction_id": "TXN123456789",
      "payment_status": "success",
      "payment_method": "UPI",
      "gateway_name": "razorpay",
      "paid_at": "2025-01-17 10:35:00"
    }
  }
}
```

---

### 4. Get Payment Status

Using payment ID:

```bash
curl -X GET "http://localhost/api/payment/get_payment_status.php?paymentId=PAY1737024000ABC123" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

Using order ID:

```bash
curl -X GET "http://localhost/api/payment/get_payment_status.php?orderId=ORD1737024000XYZ789" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "payment": {
      "id": 1,
      "payment_id": "PAY1737024000ABC123",
      "order_id": "ORD1737024000XYZ789",
      "transaction_id": null,
      "user_id": 1,
      "package_id": 1,
      "pan_number": "ABCDE1234F",
      "subtotal": 8697.00,
      "gst_percentage": 18.00,
      "gst_amount": 1565.46,
      "grand_total": 10262.46,
      "currency": "INR",
      "payment_status": "pending",
      "payment_method": null,
      "gateway_name": null,
      "merchant_id": "RgSGKJiDNpMKj7",
      "created_at": "2025-01-17 10:30:00",
      "paid_at": null
    }
  }
}
```

---

### 5. Get Payment History

Get all payments for the logged-in user:

```bash
curl -X GET "http://localhost/api/payment/get_payment_history.php" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "payments": [
      {
        "id": 1,
        "payment_id": "PAY1737024000ABC123",
        "order_id": "ORD1737024000XYZ789",
        "transaction_id": null,
        "subtotal": 8697.00,
        "gst_amount": 1565.46,
        "grand_total": 10262.46,
        "payment_status": "pending",
        "payment_method": null,
        "created_at": "2025-01-17 10:30:00",
        "paid_at": null,
        "pan_number": "ABCDE1234F",
        "packagename": "Basic",
        "package_price": "499.00",
        "customer_name": "Test User",
        "customer_email": "test@example.com"
      }
    ],
    "count": 1
  }
}
```

---

## Complete Test Flow

Here's a complete test sequence:

```bash
# 1. Login to get token
TOKEN=$(curl -s -X POST http://localhost/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","platform":"web","version":"1.0"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo "Token: $TOKEN"

# 2. Get payment info
curl -X GET "http://localhost/api/payment/get_payment_info.php?packageId=1" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

# 3. Initiate payment
PAYMENT_RESPONSE=$(curl -s -X POST http://localhost/api/payment/initiate_payment.php \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"packageId":1}')

echo "$PAYMENT_RESPONSE"

# Extract payment_id and order_id (you may need to adjust based on your system)
PAYMENT_ID=$(echo "$PAYMENT_RESPONSE" | grep -o '"payment_id":"[^"]*' | cut -d'"' -f4)
ORDER_ID=$(echo "$PAYMENT_RESPONSE" | grep -o '"order_id":"[^"]*' | cut -d'"' -f4)
echo "Payment ID: $PAYMENT_ID"
echo "Order ID: $ORDER_ID"

# 4. Verify payment (for mobile apps - after payment completes on gateway)
# Note: In real scenario, this would be called after user completes payment on gateway
curl -X POST http://localhost/api/payment/verify_payment.php \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"orderId\":\"$ORDER_ID\",\"paymentStatus\":\"success\",\"transactionId\":\"TXN123456\"}"

# 5. Check payment status
curl -X GET "http://localhost/api/payment/get_payment_status.php?paymentId=$PAYMENT_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

# 6. Get payment history
curl -X GET "http://localhost/api/payment/get_payment_history.php" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

---

## Error Testing

### Test with Invalid Token
```bash
curl -X GET "http://localhost/api/payment/get_payment_info.php" \
  -H "Authorization: Bearer INVALID_TOKEN" \
  -H "Content-Type: application/json"
```

Expected: 401 Unauthorized

### Test without Token
```bash
curl -X GET "http://localhost/api/payment/get_payment_info.php" \
  -H "Content-Type: application/json"
```

Expected: 401 Unauthorized

### Test Initiate Payment without Documents
```bash
# This should fail if PAN is provided but no documents exist
curl -X POST http://localhost/api/payment/initiate_payment.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "panNumber": "INVALID123",
    "packageId": 1
  }'
```

Expected: 400 Bad Request with message about documents

---

## Quick Reference

| API | Method | Endpoint | Required Params |
|-----|--------|----------|----------------|
| Get Payment Info | GET | `/payment/get_payment_info.php` | Token (query: packageId, panNumber) |
| Initiate Payment | POST | `/payment/initiate_payment.php` | Token, Body: packageId (panNumber optional) |
| Verify Payment | POST | `/payment/verify_payment.php` | Token, Body: orderId, paymentStatus (required) |
| Get Payment Status | GET | `/payment/get_payment_status.php` | Token, paymentId or orderId |
| Get Payment History | GET | `/payment/get_payment_history.php` | Token |

---

## Tips

1. **Pretty JSON Output**: Add `| jq` at the end if you have jq installed:
   ```bash
   curl ... | jq
   ```

2. **Save Response**: Save response to file:
   ```bash
   curl ... > response.json
   ```

3. **Verbose Mode**: Add `-v` to see request/response headers:
   ```bash
   curl -v ...
   ```

4. **Windows Users**: Use Git Bash or WSL. For PowerShell, escape quotes differently or use Postman.

