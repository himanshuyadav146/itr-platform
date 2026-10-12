#!/bin/bash

# Test Login API Script
echo "======================================"
echo "Testing Tax Client API"
echo "======================================"

# Test 1: Check internet connectivity
echo ""
echo "Test 1: Checking internet connectivity..."
if ping -c 1 google.com &> /dev/null; then
    echo "✅ Internet connection OK"
else
    echo "❌ No internet connection"
    exit 1
fi

# Test 2: Check if server is reachable
echo ""
echo "Test 2: Checking if server is reachable..."
if curl -s --head http://allindiaitr.in | head -n 1 | grep "HTTP" > /dev/null; then
    echo "✅ Server is reachable"
else
    echo "❌ Server is not reachable"
    exit 1
fi

# Test 3: Test login API
echo ""
echo "Test 3: Testing login API..."
echo "Email: himanshu123@yopmail.com"
echo "Password: 12345678"

response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST http://allindiaitr.in/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"himanshu123@yopmail.com","password":"12345678"}')

http_status=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
body=$(echo "$response" | sed '/HTTP_STATUS/d')

echo ""
echo "Response Status: $http_status"
echo "Response Body:"
echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"

if [ "$http_status" == "200" ]; then
    echo ""
    echo "✅ Login API works! Status 200 OK"
else
    echo ""
    echo "❌ Login API failed with status: $http_status"
fi

# Test 4: Test packages API
echo ""
echo "========================================" 
echo "Test 4: Testing packages API..."
response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" http://allindiaitr.in/api/package/getPackages.php)

http_status=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
body=$(echo "$response" | sed '/HTTP_STATUS/d')

echo "Response Status: $http_status"
echo "Response Body:"
echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"

if [ "$http_status" == "200" ]; then
    echo ""
    echo "✅ Packages API works! Status 200 OK"
else
    echo ""
    echo "❌ Packages API failed with status: $http_status"
fi

echo ""
echo "======================================"
echo "API Test Complete"
echo "======================================"
