<?php
/**
 * Register FCM Token API
 * Allows authenticated users to register/update their device FCM token for push notifications.
 * One token per user: existing tokens for the user are replaced (no duplicates).
 *
 * POST /auth/register_fcm.php
 * Headers: Authorization: Bearer <JWT>
 * Body: { "fcm_token": "<device FCM token>", "platform": "android" | "ios" }
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require __DIR__ . '/../include/config.php';
require __DIR__ . '/../phpjwt/Token.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "statusCode" => 405,
        "status" => "error",
        "data" => ["message" => "Only POST requests are allowed"]
    ]);
    exit;
}

// Extract Bearer token
$token = "";
if (function_exists('getallheaders')) {
    $headers = getallheaders();
    if (isset($headers['Authorization'])) {
        $token = str_replace("Bearer ", "", trim($headers['Authorization']));
    } elseif (isset($headers['authorization'])) {
        $token = str_replace("Bearer ", "", trim($headers['authorization']));
    }
}
if (empty($token) && !empty($_SERVER['HTTP_AUTHORIZATION'])) {
    $token = str_replace("Bearer ", "", trim($_SERVER['HTTP_AUTHORIZATION']));
}
if (empty($token) && !empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
    $token = str_replace("Bearer ", "", trim($_SERVER['REDIRECT_HTTP_AUTHORIZATION']));
}

if (empty($token)) {
    http_response_code(401);
    echo json_encode([
        "statusCode" => 401,
        "status" => "error",
        "data" => ["message" => "Authorization token required"]
    ]);
    exit;
}

$decoded = Token::Verify($token, $key);
if ($decoded === false) {
    http_response_code(401);
    echo json_encode([
        "statusCode" => 401,
        "status" => "error",
        "data" => ["message" => "Invalid or expired token"]
    ]);
    exit;
}

$userId = $decoded['UserId'] ?? null;
if (!$userId) {
    http_response_code(401);
    echo json_encode([
        "statusCode" => 401,
        "status" => "error",
        "data" => ["message" => "UserId missing in token"]
    ]);
    exit;
}

$input = file_get_contents("php://input");
$data = json_decode($input, true);

if (!isset($data['fcm_token']) || trim($data['fcm_token']) === '') {
    http_response_code(400);
    echo json_encode([
        "statusCode" => 400,
        "status" => "error",
        "data" => ["message" => "fcm_token is required and cannot be empty"]
    ]);
    exit;
}

$fcmToken = mysqli_real_escape_string($conn, trim($data['fcm_token']));
$platform = isset($data['platform']) ? mysqli_real_escape_string($conn, trim($data['platform'])) : 'android';
if (!in_array($platform, ['android', 'ios', 'web'])) {
    $platform = 'android';
}

$userId = (int) $userId;

// Check if user_fcm_tokens table exists (migration may not be run yet)
$tableCheck = $conn->query("SHOW TABLES LIKE 'user_fcm_tokens'");
if (!$tableCheck || $tableCheck->num_rows === 0) {
    http_response_code(503);
    echo json_encode([
        "statusCode" => 503,
        "status" => "error",
        "data" => ["message" => "Push notifications not configured. Please run migration add_push_notification_tables.sql."]
    ]);
    exit;
}

// One entry per user: remove any existing tokens for this user, then insert the new one
$conn->query("DELETE FROM user_fcm_tokens WHERE user_id = $userId");
$sql = "INSERT INTO user_fcm_tokens (user_id, fcm_token, platform, is_active, created_at, updated_at)
        VALUES ($userId, '$fcmToken', '$platform', 1, NOW(), NOW())";

if ($conn->query($sql)) {
    http_response_code(200);
    echo json_encode([
        "statusCode" => 200,
        "status" => "success",
        "data" => [
            "message" => "FCM token registered successfully"
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "statusCode" => 500,
        "status" => "error",
        "data" => ["message" => "Failed to register FCM token", "error" => $conn->error]
    ]);
}
