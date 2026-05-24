<?php
/**
 * Admin: Send push notification manually (e.g. from Postman)
 * Works independently of cron – use this to test or send on-demand.
 *
 * POST /admin/send_notification.php
 * Headers: Authorization: Bearer <JWT> (ADMIN only)
 * Body: {
 *   "title": "Notification title",
 *   "body": "Optional body text",
 *   "data_payload": { "screen": "home", "id": "123" },  // optional
 *   "target": "all_users" | "single_user" | "fcm_tokens",
 *   "target_user_id": 5,   // required when target is single_user
 *   "fcm_tokens": ["token1", "token2"]   // required when target is fcm_tokens; send only to these devices
 * }
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
require __DIR__ . '/../include/FcmHelper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "statusCode" => 405,
        "status" => "error",
        "data" => ["message" => "Only POST method allowed"]
    ]);
    exit;
}

// Token extraction (Apache + Nginx)
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
$userRole = $decoded['Role'] ?? null;
if (!$userId || $userRole !== 'ADMIN') {
    http_response_code(403);
    echo json_encode([
        "statusCode" => 403,
        "status" => "error",
        "data" => ["message" => "Admin access only"]
    ]);
    exit;
}

$input = file_get_contents("php://input");
$data = json_decode($input, true);
if (!is_array($data)) {
    $data = [];
}

$title = isset($data['title']) ? trim($data['title']) : '';
if ($title === '') {
    http_response_code(400);
    echo json_encode([
        "statusCode" => 400,
        "status" => "error",
        "data" => ["message" => "title is required"]
    ]);
    exit;
}

$body = isset($data['body']) ? trim($data['body']) : '';
$dataPayload = isset($data['data_payload']) && is_array($data['data_payload']) ? $data['data_payload'] : [];
$target = isset($data['target']) ? trim($data['target']) : 'all_users';
if (!in_array($target, ['all_users', 'single_user', 'fcm_tokens'])) {
    $target = 'all_users';
}
$targetUserId = isset($data['target_user_id']) ? (int)$data['target_user_id'] : null;
$fcmTokensInput = isset($data['fcm_tokens']) ? $data['fcm_tokens'] : null;

if ($target === 'single_user' && $targetUserId <= 0) {
    http_response_code(400);
    echo json_encode([
        "statusCode" => 400,
        "status" => "error",
        "data" => ["message" => "target_user_id is required when target is single_user"]
    ]);
    exit;
}
if ($target === 'fcm_tokens') {
    if (!is_array($fcmTokensInput) || empty($fcmTokensInput)) {
        http_response_code(400);
        echo json_encode([
            "statusCode" => 400,
            "status" => "error",
            "data" => ["message" => "fcm_tokens (array of token strings) is required when target is fcm_tokens"]
        ]);
        exit;
    }
    $tokens = array_values(array_filter(array_map(function ($t) {
        return is_string($t) ? trim($t) : '';
    }, $fcmTokensInput)));
    if (empty($tokens)) {
        http_response_code(400);
        echo json_encode([
            "statusCode" => 400,
            "status" => "error",
            "data" => ["message" => "fcm_tokens must contain at least one non-empty token string"]
        ]);
        exit;
    }
    $tokenRows = [];
} else {
    // Check tables exist for all_users / single_user
    $t = $conn->query("SHOW TABLES LIKE 'user_fcm_tokens'");
    if (!$t || $t->num_rows === 0) {
        http_response_code(503);
        echo json_encode([
            "statusCode" => 503,
            "status" => "error",
            "data" => ["message" => "Push notification tables not found. Run migration add_push_notification_tables.sql."]
        ]);
        exit;
    }

    // Get active FCM tokens from DB
    $sql = "SELECT id, user_id, fcm_token FROM user_fcm_tokens WHERE is_active = 1 AND fcm_token != ''";
    if ($target === 'single_user') {
        $targetUserIdEsc = (int)$targetUserId;
        $sql .= " AND user_id = $targetUserIdEsc";
    }
    $res = $conn->query($sql);
    $tokens = [];
    $tokenRows = [];
    if ($res) {
        while ($row = $res->fetch_assoc()) {
            $tokens[] = $row['fcm_token'];
            $tokenRows[] = $row;
        }
    }
}

if (empty($tokens)) {
    http_response_code(200);
    echo json_encode([
        "statusCode" => 200,
        "status" => "success",
        "data" => [
            "message" => "No FCM tokens to send to",
            "notification_id" => null,
            "sent_count" => 0,
            "failure_count" => 0
        ]
    ]);
    exit;
}

// Send via FCM
$sendResult = FcmHelper::sendToTokens($tokens, $title, $body, $dataPayload);

// Save to notifications table (record that we sent this)
$titleEsc = mysqli_real_escape_string($conn, $title);
$bodyEsc = mysqli_real_escape_string($conn, $body);
$dataJson = mysqli_real_escape_string($conn, json_encode($dataPayload));
$targetEsc = mysqli_real_escape_string($conn, $target);
$targetUserIdSql = ($target === 'single_user' ? (int)$targetUserId : 'NULL');
$insertSql = "INSERT INTO notifications (title, body, data_payload, type, scheduled_at, sent_at, target, target_user_id, created_by, created_at, updated_at)
              VALUES ('$titleEsc', '$bodyEsc', " . ($dataPayload ? "'$dataJson'" : "NULL") . ", 'admin_sent', NOW(), NOW(), '$targetEsc', $targetUserIdSql, " . (int)$userId . ", NOW(), NOW())";
$conn->query($insertSql);
$notificationId = $conn->insert_id;

// Optional: log per-token result if notification_log exists
$logTableRes = $conn->query("SHOW TABLES LIKE 'notification_log'");
$hasLogTable = $logTableRes && $logTableRes->num_rows > 0;
if ($notificationId && $hasLogTable && count($tokenRows) > 0) {
    foreach ($tokenRows as $tr) {
        $nid = (int)$notificationId;
        $uid = (int)$tr['user_id'];
        $tid = (int)$tr['id'];
        $conn->query("INSERT INTO notification_log (notification_id, user_id, fcm_token_id, sent_at, success) VALUES ($nid, $uid, $tid, NOW(), 1)");
    }
}

http_response_code(200);
echo json_encode([
    "statusCode" => 200,
    "status" => "success",
    "data" => [
        "message" => "Notification sent",
        "notification_id" => $notificationId,
        "sent_count" => $sendResult['success'],
        "failure_count" => $sendResult['failure'],
        "total_tokens" => count($tokens),
        "errors" => $sendResult['errors']
    ]
]);
