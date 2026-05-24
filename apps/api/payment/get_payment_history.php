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
$userId = mysqli_real_escape_string($conn, $userId);

// Fetch payment history with JOINs to get related data from existing tables
$sql = "SELECT 
            pi.id,
            pi.payment_id,
            pi.order_id,
            pi.transaction_id,
            pi.subtotal,
            pi.gst_amount,
            pi.grand_total,
            pi.payment_status,
            pi.payment_method,
            pi.created_at,
            pi.paid_at,
            pi.pan_number,
            p.packagename,
            p.price as package_price,
            u.FirstName as user_first_name,
            u.LastName as user_last_name,
            u.Email as user_email,
            pd.FirstName as personal_first_name,
            pd.LastName as personal_last_name,
            pd.EMAIL as personal_email
        FROM payment_info pi
        LEFT JOIN itr_packages p ON pi.package_id = p.id
        LEFT JOIN users u ON pi.user_id = u.UserId
        LEFT JOIN personal_details pd ON pi.user_id = pd.UserId AND pi.pan_number = pd.PANNumber AND pd.isActive = 1
        WHERE pi.user_id = '$userId'
        ORDER BY pi.created_at DESC";

$result = $conn->query($sql);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Database error: " . $conn->error]
    ]);
    exit;
}

$payments = [];
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        // Use personal details if available, otherwise user details
        $row['customer_name'] = trim(($row['personal_first_name'] ?? $row['user_first_name'] ?? '') . ' ' . ($row['personal_last_name'] ?? $row['user_last_name'] ?? ''));
        $row['customer_email'] = $row['personal_email'] ?? $row['user_email'] ?? '';
        
        // Remove redundant fields
        unset($row['user_first_name'], $row['user_last_name'], $row['user_email']);
        unset($row['personal_first_name'], $row['personal_last_name'], $row['personal_email']);
        
        $payments[] = $row;
    }
}

http_response_code(200);
echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" => [
        "payments" => $payments,
        "count" => count($payments)
    ]
], JSON_UNESCAPED_UNICODE);
exit;
?>

