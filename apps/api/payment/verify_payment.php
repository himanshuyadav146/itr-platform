<?php
// Payment Verification Endpoint for Mobile Apps
// This endpoint accepts payment verification data from mobile app and updates payment_info table
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

try {
    require '../include/config.php';
    require '../phpjwt/Token.php';
    require '../itr_status/StatusHelper.php';
    require_once '../include/NotificationDispatcher.php';
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

// Required fields
$orderId = $data['orderId'] ?? $data['order_id'] ?? null;
$paymentStatus = $data['paymentStatus'] ?? $data['payment_status'] ?? $data['status'] ?? null;

if (!$orderId) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "orderId is required"]
    ]);
    exit;
}

if (!$paymentStatus) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "paymentStatus is required"]
    ]);
    exit;
}

// Optional fields
$transactionId = $data['transactionId'] ?? $data['transaction_id'] ?? null;
$paymentMethod = $data['paymentMethod'] ?? $data['payment_method'] ?? null;
$gatewayName = $data['gatewayName'] ?? $data['gateway_name'] ?? null;
$failureReason = $data['failureReason'] ?? $data['failure_reason'] ?? $data['message'] ?? null;
$gatewayResponse = $data['gatewayResponse'] ?? $data['gateway_response'] ?? null;

// Escape inputs
$userId = mysqli_real_escape_string($conn, $userId);
$orderIdEscaped = mysqli_real_escape_string($conn, $orderId);

// Find payment record
$sql = "SELECT * FROM payment_info WHERE order_id = '$orderIdEscaped' AND user_id = '$userId' LIMIT 1";
$result = $conn->query($sql);

if (!$result || $result->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "status" => "error",
        "statusCode" => 404,
        "data" => ["message" => "Payment record not found for this order ID"]
    ]);
    exit;
}

$payment = $result->fetch_assoc();

// Normalize payment status
$paymentStatusUpper = strtoupper($paymentStatus);
$dbStatus = 'pending';

if ($paymentStatusUpper === 'TXN_SUCCESS' || $paymentStatusUpper === 'SUCCESS' || $paymentStatusUpper === 'PAID' || $paymentStatusUpper === 'CAPTURED') {
    $dbStatus = 'success';
} elseif ($paymentStatusUpper === 'TXN_FAILURE' || $paymentStatusUpper === 'FAILED' || $paymentStatusUpper === 'FAILURE') {
    $dbStatus = 'failed';
} elseif ($paymentStatusUpper === 'TXN_CANCELLED' || $paymentStatusUpper === 'CANCELLED' || $paymentStatusUpper === 'CANCELED') {
    $dbStatus = 'cancelled';
} else {
    $dbStatus = 'pending';
}

// Build update query
$updateFields = [
    "payment_status = '" . mysqli_real_escape_string($conn, $dbStatus) . "'",
    "updated_at = NOW()"
];

if ($transactionId) {
    $transactionIdEscaped = mysqli_real_escape_string($conn, $transactionId);
    $updateFields[] = "transaction_id = '$transactionIdEscaped'";
}

if ($paymentMethod) {
    $paymentMethodEscaped = mysqli_real_escape_string($conn, $paymentMethod);
    $updateFields[] = "payment_method = '$paymentMethodEscaped'";
}

if ($gatewayName) {
    $gatewayNameEscaped = mysqli_real_escape_string($conn, $gatewayName);
    $updateFields[] = "gateway_name = '$gatewayNameEscaped'";
}

if ($failureReason && $dbStatus !== 'success') {
    $failureReasonEscaped = mysqli_real_escape_string($conn, $failureReason);
    $updateFields[] = "failure_reason = '$failureReasonEscaped'";
}

if ($gatewayResponse) {
    $gatewayResponseEscaped = mysqli_real_escape_string($conn, json_encode($gatewayResponse));
    $updateFields[] = "gateway_response = '$gatewayResponseEscaped'";
} else {
    // Store the entire request data as gateway response
    $gatewayResponseEscaped = mysqli_real_escape_string($conn, json_encode($data));
    $updateFields[] = "gateway_response = '$gatewayResponseEscaped'";
}

if ($dbStatus === 'success') {
    $updateFields[] = "paid_at = NOW()";
}

$updateSql = "UPDATE payment_info SET " . implode(", ", $updateFields) . " WHERE order_id = '$orderIdEscaped' AND user_id = '$userId'";

if ($conn->query($updateSql)) {
    // If payment is successful, update ITR order status step
    $statusStepUpdated = true;
    if ($dbStatus === 'success') {
        $paymentId = $payment['payment_id'] ?? null;
        $panNumber = $payment['pan_number'] ?? null;
        $itrId = null;

        // Try to associate this payment with a specific ITR (if schema/data allows)
        if (!empty($payment['itr_id'])) {
            $itrId = (int)$payment['itr_id'];
        } elseif (!empty($panNumber)) {
            // Fallback: resolve latest ITR for this user + PAN
            $itrLookupSql = "SELECT id FROM itr_detail 
                             WHERE userId = " . (int)$userId . " 
                             AND panNumber = '" . mysqli_real_escape_string($conn, $panNumber) . "'
                             ORDER BY id DESC
                             LIMIT 1";
            $itrLookupResult = $conn->query($itrLookupSql);
            if ($itrLookupResult && $itrLookupResult->num_rows > 0) {
                $itrRow = $itrLookupResult->fetch_assoc();
                $itrId = (int)$itrRow['id'];
            }
        }
        
        // Update payment_success step (so get_detailed_status shows step completed)
        $gatewayNameForNotes = $gatewayName ? $gatewayName : 'payment gateway';
        $statusStepUpdated = StatusHelper::updateStatusStep(
            $conn,
            $orderIdEscaped,
            $itrId,
            $userId,
            $paymentId,
            $panNumber,
            'payment_success',
            true,
            "Payment completed via " . $gatewayNameForNotes
        );
        if (!$statusStepUpdated) {
            error_log("[verify_payment] Failed to update itr_order_status for order_id=$orderIdEscaped user_id=$userId: " . ($conn->error ?? 'unknown'));
        }
    }
    
    // Fetch updated payment record
    $updatedSql = "SELECT * FROM payment_info WHERE order_id = '$orderIdEscaped' AND user_id = '$userId' LIMIT 1";
    $updatedResult = $conn->query($updatedSql);
    $updatedPayment = $updatedResult->fetch_assoc();
    
    // Decode JSON fields if they exist
    if ($updatedPayment['gateway_response']) {
        $updatedPayment['gateway_response'] = json_decode($updatedPayment['gateway_response'], true);
    }
    if ($updatedPayment['webhook_data']) {
        $updatedPayment['webhook_data'] = json_decode($updatedPayment['webhook_data'], true);
    }
    
    $responseData = [
        "message" => "Payment status updated successfully",
        "payment" => $updatedPayment
    ];
    if (isset($statusStepUpdated) && !$statusStepUpdated) {
        $responseData["warning"] = "Payment recorded but status step could not be saved. Your order status may still show correctly from payment data.";
    }

    if ($dbStatus === 'success') {
        notifyWorkflowEvent($conn, 'payment.success', [
            'userId' => $userId,
            'orderId' => $orderId,
            'pan' => $panNumber ?? ($payment['pan_number'] ?? ''),
            'amount' => $updatedPayment['grand_total'] ?? ($payment['grand_total'] ?? ''),
            'itrId' => $itrId,
        ]);
    }

    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => $responseData
    ], JSON_UNESCAPED_UNICODE);
} else {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Failed to update payment status: " . $conn->error]
    ]);
}
exit;
?>

