# cURL Examples for API Testing

## Dashboard API

### Via Direct Backend (http://localhost/api)

```bash
curl -X GET "http://localhost/api/admin/dashboard.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -v
```

### Via Vite Proxy (http://localhost:5173/api)

```bash
curl -X GET "http://localhost:5173/api/admin/dashboard.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -v
```

### Get Token from Browser

1. Open your browser DevTools (F12)
2. Go to Application/Storage tab
3. Check Local Storage for key: `auth_token`
4. Copy the token value
5. Replace `YOUR_TOKEN_HERE` in the curl command above

### Quick Test (Get Token from localStorage)

```bash
# Get token from browser console and use it:
TOKEN="your_token_here"

curl -X GET "http://localhost/api/admin/dashboard.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  | jq .
```

### Pretty Print Response (requires jq)

```bash
curl -X GET "http://localhost/api/admin/dashboard.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -s | jq .
```

### Save Response to File

```bash
curl -X GET "http://localhost/api/admin/dashboard.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -o dashboard_response.json
```

## Other API Endpoints

### Login (to get token)

```bash
curl -X POST "http://localhost/api/auth/admin_login.php" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test1@example.com",
    "password": "your_password"
  }' \
  | jq .
```

### Users List

```bash
curl -X GET "http://localhost/api/admin/users.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  | jq .
```

### ITRs List

```bash
curl -X GET "http://localhost/api/admin/itrs.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  | jq .
```

## Debugging Tips

### Check if endpoint exists (without auth)

```bash
curl -I "http://localhost/api/admin/dashboard.php"
```

### Verbose output (see full request/response)

```bash
curl -v -X GET "http://localhost/api/admin/dashboard.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Test CORS (from different origin simulation)

```bash
curl -X GET "http://localhost/api/admin/dashboard.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Origin: http://localhost:5173" \
  -v
```
