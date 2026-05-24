# ITR Detailed Status API - CURL Test Commands

## Setup
Replace these variables with your actual values:
```bash
BASE_URL="https://allindiaitr.in/api"
TOKEN="eyJhbGdvIjoiSFMyNTYiLCJ0eXBlIjoiSldUIiwiZXhwaXJlIjoxNzY4NzgzNTM3fQ==.eyJpc3MiOiJhbGxpbmRpYWl0ci5pbiIsIlVzZXJJZCI6IjEiLCJSb2xlIjoiQURNSU4iLCJ0aW1lIjoxNzY4NzQ3NTM3fQ==.OTBjZGE1MmI1ZTAxMWE2YTY3ODJmM2Q1MzBjMzBhYTY4OTg4ZTBhZTNlYWNjNWFhZTlmMGE5N2ZkMjM3MjQ5ZA=="
```

## Test Commands

### 1. Get Detailed Status by Order ID
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_1737176537_1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```

### 2. Get Detailed Status by ITR ID
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?itrId=5" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```

### 3. Pretty Print Response (with jq)
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_1737176537_1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq '.'
```

### 4. Get Only ITR Status Section
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_1737176537_1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq '.data.itrStatus'
```

### 5. Get Only Payment Status
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_1737176537_1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq '.data.paymentStatus'
```

### 6. Get Only Assignment Status
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?itrId=5" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq '.data.assignmentStatus'
```

### 7. Get Progress Percentage
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_1737176537_1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq '.data.itrStatus.progressPercentage'
```

### 8. Get Overall Status
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_1737176537_1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq '.data.itrStatus.overallStatus'
```

### 9. Get All Status Steps
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_1737176537_1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq '.data.itrStatus.steps[]'
```

### 10. Get Only Completed Steps
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_1737176537_1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq '.data.itrStatus.steps[] | select(.isCompleted == true)'
```

### 11. Get Steps with Concerns
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_1737176537_1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq '.data.itrStatus.steps[] | select(.hasConcern == true)'
```

### 12. Get Professional Details
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?itrId=5" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" | jq '{
    name: .data.assignmentStatus.professionalName,
    email: .data.assignmentStatus.professionalEmail,
    mobile: .data.assignmentStatus.professionalMobile,
    role: .data.assignmentStatus.professionalRole
  }'
```

## Error Test Cases

### 1. Missing Required Parameters
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```
Expected: 400 Bad Request - "orderId or itrId is required"

### 2. Missing Authorization Token
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_123" \
  -H "Content-Type: application/json"
```
Expected: 401 Unauthorized - "Authorization token required"

### 3. Invalid Token
```bash
curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_123" \
  -H "Authorization: Bearer INVALID_TOKEN" \
  -H "Content-Type: application/json"
```
Expected: 401 Unauthorized - "Invalid or expired token"

### 4. Wrong HTTP Method
```bash
curl -X POST "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_123" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```
Expected: 405 Method Not Allowed - "Only GET allowed"

## Local Testing (XAMPP)

If testing locally, replace BASE_URL:
```bash
BASE_URL="http://localhost/api"
TOKEN="your_local_token"

curl -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_1737176537_1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json"
```

## Response Examples

### Success Response
```json
{
  "status": "success",
  "statusCode": 200,
  "data": {
    "orderId": "ORD_1737176537_1",
    "itrId": 5,
    "userId": 1,
    "panNumber": "ABCDE1234F",
    "itrStatus": {
      "steps": [
        {
          "step": "payment_success",
          "title": "Payment Success",
          "order": 1,
          "isCompleted": true,
          "completedAt": "2026-01-18 10:30:00",
          "hasConcern": false,
          "notes": "Payment completed via Razorpay",
          "concern": null
        }
      ],
      "overallStatus": "in_progress",
      "currentStep": 1,
      "totalSteps": 5,
      "progressPercentage": 20
    },
    "paymentStatus": {
      "paymentId": "PAY_1737176537_1",
      "orderId": "ORD_1737176537_1",
      "amount": 999.00,
      "gst": 179.82,
      "grandTotal": 1178.82,
      "status": "success",
      "paymentMethod": "UPI",
      "gatewayName": "Razorpay",
      "transactionId": "pay_ABC123XYZ",
      "paidAt": "2026-01-18 10:30:00",
      "createdAt": "2026-01-18 10:25:00",
      "failureReason": null
    },
    "assignmentStatus": null,
    "itrDetails": null
  }
}
```

## Integration with Frontend

### React/Next.js Example
```javascript
const fetchDetailedStatus = async (orderId) => {
  try {
    const response = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL}/itr_status/get_detailed_status.php?orderId=${orderId}`,
      {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    const result = await response.json();
    
    if (result.status === 'success') {
      return result.data;
    } else {
      throw new Error(result.data.message);
    }
  } catch (error) {
    console.error('Error fetching status:', error);
    throw error;
  }
};

// Usage
const data = await fetchDetailedStatus('ORD_1737176537_1');
console.log('Progress:', data.itrStatus.progressPercentage + '%');
console.log('Overall Status:', data.itrStatus.overallStatus);
```

### Vue.js Example
```javascript
async fetchDetailedStatus(orderId) {
  try {
    const response = await this.$axios.get(
      `/itr_status/get_detailed_status.php`,
      {
        params: { orderId },
        headers: {
          'Authorization': `Bearer ${this.$store.state.auth.token}`
        }
      }
    );
    
    if (response.data.status === 'success') {
      this.itrData = response.data.data;
    }
  } catch (error) {
    console.error('Error:', error);
  }
}
```

### Angular Example
```typescript
import { HttpClient, HttpHeaders } from '@angular/common/http';

getDetailedStatus(orderId: string) {
  const headers = new HttpHeaders({
    'Authorization': `Bearer ${this.authService.getToken()}`
  });
  
  return this.http.get(
    `${environment.apiUrl}/itr_status/get_detailed_status.php`,
    { 
      params: { orderId },
      headers 
    }
  );
}
```

## Useful jq Filters

### Get summary
```bash
curl -s -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_123" \
  -H "Authorization: Bearer ${TOKEN}" | jq '{
    orderId: .data.orderId,
    progress: .data.itrStatus.progressPercentage,
    overallStatus: .data.itrStatus.overallStatus,
    paymentStatus: .data.paymentStatus.status,
    professional: .data.assignmentStatus.professionalName
  }'
```

### Check if any concerns exist
```bash
curl -s -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_123" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.data.itrStatus.steps | map(select(.hasConcern == true)) | length > 0'
```

### Get next pending step
```bash
curl -s -X GET "${BASE_URL}/itr_status/get_detailed_status.php?orderId=ORD_123" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.data.itrStatus.steps[] | select(.isCompleted == false) | .title' | head -n 1
```
