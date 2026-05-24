<?php
// Error reporting for debugging (disable in production or use error logs)
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

// Set error handler to return JSON on fatal errors
register_shutdown_function(function() {
    $error = error_get_last();
    if ($error !== NULL && in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR])) {
        http_response_code(500);
        header("Content-Type: application/json");
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Internal server error: " . $error['message'] . " in " . $error['file'] . " on line " . $error['line']]
        ]);
        exit;
    }
});

try {
    require '../include/config.php';
    require '../phpjwt/Token.php';
    require 'PaymentHelper.php';
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Failed to load required files: " . $e->getMessage()]
    ]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only POST allowed"]
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

// Get request data
$input = file_get_contents("php://input");
$data = json_decode($input, true);

if (!$data) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "Invalid JSON data"]
    ]);
    exit;
}

$panNumber = $data['panNumber'] ?? null;
$packageId = $data['packageId'] ?? null;

// Validate mandatory fields
if (empty($panNumber)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "panNumber is required"]
    ]);
    exit;
}

// Validate PAN number format (10 characters, alphanumeric)
if (!preg_match('/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/', strtoupper($panNumber))) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "Invalid PAN number format"]
    ]);
    exit;
}

$panNumber = strtoupper($panNumber);
$panNumberEscaped = mysqli_real_escape_string($conn, $panNumber);
$userIdEscaped = mysqli_real_escape_string($conn, $userId);

// Validate that documents are submitted for the PAN
$docCheckSql = "SELECT COUNT(*) as doc_count FROM document_details 
                 WHERE UserId = '$userIdEscaped' AND PanNumber = '$panNumberEscaped' AND isActive = 1";
$docResult = $conn->query($docCheckSql);

if (!$docResult) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Database error: " . $conn->error]
    ]);
    exit;
}

$docRow = $docResult->fetch_assoc();

if ($docRow['doc_count'] == 0) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "Please submit all documents before initiating payment"]
    ]);
    exit;
}

// Check database connection
if (!$conn || $conn->connect_error) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Database connection failed: " . ($conn ? $conn->connect_error : "Connection object not available")]
    ]);
    exit;
}

// Calculate payment breakdown
try {
    $breakdown = PaymentHelper::calculatePaymentBreakdown($conn, $packageId);
    
    if (!isset($breakdown['subtotal']) || !isset($breakdown['gst_amount']) || !isset($breakdown['grand_total'])) {
        throw new Exception("Invalid payment breakdown calculation");
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Failed to calculate payment breakdown: " . $e->getMessage()]
    ]);
    exit;
}

// Payment config (test/live mode, gateway keys – dynamic)
$paymentConfig = PaymentHelper::getPaymentConfig();

// Generate payment ID
$paymentId = PaymentHelper::generatePaymentId();

// Generate order ID for gateway
$orderId = 'ORD' . time() . strtoupper(substr(uniqid(), -6));

$merchantId = $paymentConfig['merchant_id'];
$gatewayName = $paymentConfig['gateway'];
$panNumberValue = "'" . $panNumberEscaped . "'";
$packageIdValue = $packageId ? mysqli_real_escape_string($conn, $packageId) : "NULL";

// Safely escape breakdown values for SQL
$subtotal = floatval($breakdown['subtotal']);
$gstPercentage = floatval($breakdown['gst_percentage']);
$gstAmount = floatval($breakdown['gst_amount']);
$grandTotal = floatval($breakdown['grand_total']);

// Build callback and redirect URLs (dynamic from request host)
$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'];
$basePath = dirname(dirname($_SERVER['PHP_SELF']));
$callbackUrl = $protocol . "://" . $host . $basePath . "/payment/webhook.php";
$redirectUrl = $protocol . "://" . $host . $basePath . "/payment/success.php";

$callbackUrlEscaped = mysqli_real_escape_string($conn, $callbackUrl);
$redirectUrlEscaped = mysqli_real_escape_string($conn, $redirectUrl);
$paymentIdEscaped = mysqli_real_escape_string($conn, $paymentId);
$orderIdEscaped = mysqli_real_escape_string($conn, $orderId);
$merchantIdEscaped = mysqli_real_escape_string($conn, $merchantId);
$gatewayNameEscaped = mysqli_real_escape_string($conn, $gatewayName);

// Optional: create Razorpay order so UI can open Checkout with razorpay_order_id
$razorpayOrder = null;
if ($gatewayName === 'razorpay' && $grandTotal > 0) {
    $razorpayOrder = PaymentHelper::createRazorpayOrder($orderId, $grandTotal, 'INR');
}

$sql = "INSERT INTO payment_info 
        (payment_id, user_id, package_id, pan_number, order_id, subtotal, gst_percentage, 
         gst_amount, grand_total, currency, payment_status, merchant_id, gateway_name, callback_url, 
         redirect_url, created_at)
        VALUES 
        ('$paymentIdEscaped', '$userIdEscaped', $packageIdValue, $panNumberValue, '$orderIdEscaped', 
         $subtotal, $gstPercentage, 
         $gstAmount, $grandTotal, 'INR', 'pending', 
         '$merchantIdEscaped', '$gatewayNameEscaped', '$callbackUrlEscaped', '$redirectUrlEscaped', NOW())";

if ($conn->query($sql)) {
    $responseData = [
        "payment_id" => $paymentId,
        "order_id" => $orderId,
        "user_id" => (int)$userId,
        "pan_number" => $panNumber,
        "amount" => $breakdown['grand_total'],
        "currency" => "INR",
        "merchant_id" => $merchantId,
        "redirect_url" => $redirectUrl,
        "gateway" => [
            "name" => $gatewayName,
            "mode" => $paymentConfig['mode'],
            "key_id" => $paymentConfig['razorpay_key_id'],
        ],
        "message" => "Payment initiated successfully. Use key_id and redirect_url (or razorpay_order_id) to open gateway checkout.",
    ];
    if ($razorpayOrder && !empty($razorpayOrder['razorpay_order_id'])) {
        $responseData["razorpay_order_id"] = $razorpayOrder['razorpay_order_id'];
    }
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => $responseData
    ], JSON_UNESCAPED_UNICODE);
} else {
    http_response_code(500);
    $errorMsg = $conn->error;
    // Check if table doesn't exist
    if (strpos($errorMsg, "doesn't exist") !== false) {
        $errorMsg = "Database table 'payment_info' does not exist. Please run setup_payment_table.sql first.";
    }
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Failed to create payment record: " . $errorMsg]
    ]);
}
exit;
?>

