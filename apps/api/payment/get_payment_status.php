<?php
// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only GET allowed"]
    ]);
    exit;
}

// Token verification
$headers = getallheaders();
$token = "";

if (isset($headers['Authorization'])) {
    $token = str_replace("Bearer ", "", trim($headers['Authorization']));
}

if (empty($token)) {
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" => ["message" => "Authorization token required"]
    ]);
    exit;
}

$decoded = Token::Verify($token, $key);
if ($decoded === false) {
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" => ["message" => "Invalid or expired token"]
    ]);
    exit;
}

$userId = $decoded['UserId'] ?? null;
$paymentId = $_GET['paymentId'] ?? null;
$orderId = $_GET['orderId'] ?? null;

if (!$paymentId && !$orderId) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "paymentId or orderId is required"]
    ]);
    exit;
}

$userId = mysqli_real_escape_string($conn, $userId);

// Build query
$where = "user_id = '$userId'";
if ($paymentId) {
    $paymentId = mysqli_real_escape_string($conn, $paymentId);
    $where .= " AND payment_id = '$paymentId'";
}
if ($orderId) {
    $orderId = mysqli_real_escape_string($conn, $orderId);
    $where .= " AND order_id = '$orderId'";
}

$sql = "SELECT * FROM payment_info WHERE $where ORDER BY created_at DESC LIMIT 1";
$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    $payment = $result->fetch_assoc();
    
    // Decode JSON fields if they exist
    if ($payment['gateway_response']) {
        $payment['gateway_response'] = json_decode($payment['gateway_response'], true);
    }
    if ($payment['webhook_data']) {
        $payment['webhook_data'] = json_decode($payment['webhook_data'], true);
    }
    
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "payment" => $payment
        ]
    ], JSON_UNESCAPED_UNICODE);
} else {
    http_response_code(404);
    echo json_encode([
        "status" => "error",
        "statusCode" => 404,
        "data" => ["message" => "Payment not found"]
    ]);
}
exit;
?>

