<?php
// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';
require 'PaymentHelper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only GET or POST allowed"]
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
if (!$userId) {
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" => ["message" => "UserId missing in token"]
    ]);
    exit;
}

// Get parameters
$panNumber = null;
$packageId = null;

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $panNumber = isset($_GET['panNumber']) ? trim($_GET['panNumber']) : null;
    $packageId = isset($_GET['packageId']) ? trim($_GET['packageId']) : null;
} else {
    $input = file_get_contents("php://input");
    $data = json_decode($input, true);
    $panNumber = $data['panNumber'] ?? null;
    $packageId = $data['packageId'] ?? null;
}

$userId = mysqli_real_escape_string($conn, $userId);

// ============================================
// Fetch User Details from users table
// ============================================
$userSql = "SELECT FirstName, LastName, Email, Mobile FROM users WHERE UserId = '$userId'";
$userResult = $conn->query($userSql);

if (!$userResult) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Database error: " . $conn->error]
    ]);
    exit;
}

$user = $userResult->fetch_assoc();

if (!$user) {
    http_response_code(404);
    echo json_encode([
        "status" => "error",
        "statusCode" => 404,
        "data" => ["message" => "User not found"]
    ]);
    exit;
}

// ============================================
// Fetch Personal Details from personal_details table (if PAN provided)
// ============================================
$name = trim(($user['FirstName'] ?? '') . ' ' . ($user['LastName'] ?? ''));
$email = $user['Email'];
$phone = $user['Mobile'];

if ($panNumber) {
    $panNumber = mysqli_real_escape_string($conn, $panNumber);
    $personalSql = "SELECT FirstName, LastName, EMAIL, MobileNumber, PANNumber 
                    FROM personal_details 
                    WHERE UserId = '$userId' AND PANNumber = '$panNumber' AND isActive = 1 
                    ORDER BY createdAt DESC LIMIT 1";
    $personalResult = $conn->query($personalSql);
    if ($personalResult && $personalResult->num_rows > 0) {
        $personalDetails = $personalResult->fetch_assoc();
        // Use personal details if available
        $name = trim(($personalDetails['FirstName'] ?? '') . ' ' . ($personalDetails['LastName'] ?? ''));
        $email = $personalDetails['EMAIL'] ?? $email;
        $phone = $personalDetails['MobileNumber'] ?? $phone;
    }
}

// ============================================
// Fetch Package Details (if packageId provided)
// ============================================
$packageDetails = null;
if ($packageId) {
    $packageId = mysqli_real_escape_string($conn, $packageId);
    $packageSql = "SELECT id, packagename, price, description1, turnover, icon, color 
                   FROM itr_packages 
                   WHERE id = '$packageId' AND isActive = 1";
    $packageResult = $conn->query($packageSql);
    if ($packageResult && $packageResult->num_rows > 0) {
        $pkg = $packageResult->fetch_assoc();
        $packageDetails = [
            "id" => (int)$pkg['id'],
            "name" => $pkg['packagename'],
            "description" => $pkg['description1'] ?? '',
            "turnover" => $pkg['turnover'] ?? '',
            "price" => '₹' . number_format($pkg['price'], 0, '.', ''),
            "icon" => $pkg['icon'] ?? '',
            "color" => $pkg['color'] ?? ''
        ];
    }
}

// ============================================
// Calculate Payment Breakdown (from packages + additional fees)
// ============================================
$breakdown = PaymentHelper::calculatePaymentBreakdown($conn, $packageId);
$paymentSummary = PaymentHelper::buildPaymentSummary($breakdown);

// ============================================
// Gateway Details (dynamic from config – test/live mode)
// ============================================
$gatewayDetails = PaymentHelper::getGatewayDetailsForResponse();

// ============================================
// Totals (for UI – subtotal, GST, grand_total)
// ============================================
$total = [
    "subtotal" => $breakdown['subtotal'],
    "gst_percentage" => $breakdown['gst_percentage'],
    "gst_amount" => $breakdown['gst_amount'],
    "grand_total" => $breakdown['grand_total']
];

// ============================================
// Response
// ============================================
$responseData = [
    "order_details" => [
        "Name" => $name,
        "phone" => $phone,
        "email" => $email
    ],
    "payment_summary" => $paymentSummary,
    "total" => $total,
    "gateway_details" => $gatewayDetails
];

// Add package details if available
if ($packageDetails) {
    $responseData['package'] = $packageDetails;
}

http_response_code(200);
echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" => $responseData
], JSON_UNESCAPED_UNICODE);
exit;
?>

