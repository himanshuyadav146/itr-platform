<?php
// Webhook endpoint for payment gateway callbacks
header("Content-Type: application/json");

require '../include/config.php';
require '../itr_status/StatusHelper.php';

// Log webhook data
$webhookData = file_get_contents("php://input");
$postData = $_POST;
$getData = $_GET;

// Combine all data
$allData = [
    'raw_input' => $webhookData,
    'post' => $postData,
    'get' => $getData,
    'headers' => getallheaders(),
    'timestamp' => date('Y-m-d H:i:s')
];

$logData = json_encode($allData, JSON_PRETTY_PRINT);

// Get order ID or transaction ID from webhook
$orderId = $postData['ORDERID'] ?? $postData['order_id'] ?? $getData['ORDERID'] ?? $getData['order_id'] ?? null;
$transactionId = $postData['TXNID'] ?? $postData['transaction_id'] ?? $getData['TXNID'] ?? $getData['transaction_id'] ?? null;
$status = $postData['STATUS'] ?? $postData['status'] ?? $getData['STATUS'] ?? $getData['status'] ?? 'unknown';
$amount = $postData['TXNAMOUNT'] ?? $postData['amount'] ?? $getData['TXNAMOUNT'] ?? $getData['amount'] ?? null;

if ($orderId) {
    $orderId = mysqli_real_escape_string($conn, $orderId);
    
    // Find payment record
    $sql = "SELECT * FROM payment_info WHERE order_id = '$orderId' LIMIT 1";
    $result = $conn->query($sql);
    
    if ($result && $result->num_rows > 0) {
        $payment = $result->fetch_assoc();
        
        // Map gateway status to our status
        $paymentStatus = 'pending';
        $statusUpper = strtoupper($status);
        
        if ($statusUpper === 'TXN_SUCCESS' || $statusUpper === 'SUCCESS' || $statusUpper === 'PAID') {
            $paymentStatus = 'success';
        } elseif ($statusUpper === 'TXN_FAILURE' || $statusUpper === 'FAILED' || $statusUpper === 'FAILURE') {
            $paymentStatus = 'failed';
        } elseif ($statusUpper === 'TXN_CANCELLED' || $statusUpper === 'CANCELLED' || $statusUpper === 'CANCELED') {
            $paymentStatus = 'cancelled';
        }
        
        // Get payment method if available
        $paymentMethod = $postData['PAYMENTMODE'] ?? $postData['payment_method'] ?? $getData['PAYMENTMODE'] ?? $getData['payment_method'] ?? null;
        if ($paymentMethod) {
            $paymentMethod = mysqli_real_escape_string($conn, $paymentMethod);
        }
        
        // Get failure reason if failed
        $failureReason = null;
        if ($paymentStatus === 'failed') {
            $failureReason = $postData['RESPMSG'] ?? $postData['message'] ?? $postData['failure_reason'] ?? 'Payment failed';
            $failureReason = mysqli_real_escape_string($conn, $failureReason);
        }
        
        // Prepare update query
        $updateFields = [
            "payment_status = '$paymentStatus'",
            "gateway_response = '" . mysqli_real_escape_string($conn, json_encode($postData)) . "'",
            "webhook_data = '" . mysqli_real_escape_string($conn, $logData) . "'",
            "updated_at = NOW()"
        ];
        
        if ($transactionId) {
            $transactionIdEscaped = mysqli_real_escape_string($conn, $transactionId);
            $updateFields[] = "transaction_id = '$transactionIdEscaped'";
        }
        
        if ($paymentMethod) {
            $updateFields[] = "payment_method = '$paymentMethod'";
        }
        
        if ($failureReason) {
            $updateFields[] = "failure_reason = '$failureReason'";
        }
        
        if ($paymentStatus === 'success') {
            $updateFields[] = "paid_at = NOW()";
        }
        
        $updateSql = "UPDATE payment_info SET " . implode(", ", $updateFields) . " WHERE order_id = '$orderId'";
        
        if ($conn->query($updateSql)) {
            // If payment is successful, update ITR order status step
            if ($paymentStatus === 'success') {
                $paymentId = $payment['payment_id'] ?? null;
                $panNumber = $payment['pan_number'] ?? null;
                $userId = $payment['user_id'] ?? null;
                $itrId = null; // Can be linked later if needed
                $gatewayNameForNotes = $payment['gateway_name'] ?? 'payment gateway';
                
                if ($userId) {
                    // Update payment_success step
                    StatusHelper::updateStatusStep(
                        $conn,
                        $orderId,
                        $itrId,
                        $userId,
                        $paymentId,
                        $panNumber,
                        'payment_success',
                        true,
                        "Payment completed via " . $gatewayNameForNotes
                    );
                }
            }
            
            // Log success
            error_log("Payment webhook processed: Order ID $orderId, Status: $paymentStatus");
        } else {
            error_log("Payment webhook update failed: " . $conn->error);
        }
    } else {
        error_log("Payment webhook: Order ID $orderId not found in database");
    }
} else {
    error_log("Payment webhook: No order ID received");
}

// Always return success to gateway (to prevent retries)
http_response_code(200);
echo json_encode(["status" => "received"]);
exit;
?>

