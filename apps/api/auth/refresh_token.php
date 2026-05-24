<?php
/**
 * Refresh Token API
 * Regenerates a new JWT token when the current token expires
 * 
 * Endpoint: POST /auth/refresh_token.php
 * Headers: Authorization: Bearer {old_token}
 */

// Allow cross-origin requests (CORS policy)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

// Only POST allowed
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "statusCode" => 405,
        "status" => "error",
        "data" => [
            "message" => "Only POST method allowed"
        ]
    ]);
    exit;
}

// Extract Bearer token from Authorization header
$headers = getallheaders();
$token = "";

if (isset($headers['Authorization'])) {
    $token = str_replace("Bearer ", "", trim($headers['Authorization']));
} elseif (function_exists('apache_request_headers')) {
    $apacheHeaders = apache_request_headers();
    if (isset($apacheHeaders['Authorization'])) {
        $token = str_replace("Bearer ", "", trim($apacheHeaders['Authorization']));
    }
}

if (empty($token)) {
    http_response_code(401);
    echo json_encode([
        "statusCode" => 401,
        "status" => "error",
        "data" => [
            "message" => "Authorization token is required"
        ]
    ]);
    exit;
}

// Function to manually decode token to extract payload (even if expired)
function decodeTokenPayload($token) {
    $tokenParts = explode('.', $token);
    
    if (count($tokenParts) !== 3) {
        return false;
    }
    
    try {
        $payload = json_decode(base64_decode($tokenParts[1]), true);
        return $payload;
    } catch (Exception $e) {
        return false;
    }
}

// Try to verify token first (works if token is still valid)
$decoded = Token::Verify($token, $key);

// If token verification failed, try to decode manually (to handle expired tokens)
if ($decoded === false) {
    $decoded = decodeTokenPayload($token);
    
    if ($decoded === false) {
        http_response_code(401);
        echo json_encode([
            "statusCode" => 401,
            "status" => "error",
            "data" => [
                "message" => "Invalid token format"
            ]
        ]);
        exit;
    }
}

// Extract UserId from token
$UserId = $decoded['UserId'] ?? null;

if (!$UserId) {
    http_response_code(401);
    echo json_encode([
        "statusCode" => 401,
        "status" => "error",
        "data" => [
            "message" => "User ID not found in token"
        ]
    ]);
    exit;
}

// Validate UserId is integer
$UserId = (int)$UserId;

// Verify user still exists in database and get role
$sql = "SELECT UserId, Email, role FROM users WHERE UserId = '$UserId'";
$result = $conn->query($sql);

if (!$result || $result->num_rows === 0) {
    http_response_code(401);
    echo json_encode([
        "statusCode" => 401,
        "status" => "error",
        "data" => [
            "message" => "User not found"
        ]
    ]);
    exit;
}

$user = $result->fetch_assoc();

// Generate new token
$payload = [
    "iss" => "allindiaitr.in",
    "UserId" => $user['UserId'],
    "Role" => $user['role'] ?? 'CLIENT'
];
$newToken = Token::Sign($payload, $key, $expire);

// Success Response
http_response_code(200);
echo json_encode([
    "statusCode" => 200,
    "status" => "success",
    "data" => [
        "message" => "Token refreshed successfully",
        "UserId" => $user['UserId'],
        "email" => $user['Email'],
        "token" => $newToken
    ]
]);
exit;

?>

