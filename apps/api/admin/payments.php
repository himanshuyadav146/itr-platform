<?php
/**
 * Admin Payments Management API
 * List, view, update payments
 * 
 * Endpoints: 
 * - GET /admin/payments.php - List all payments (with pagination and filters)
 * - GET /admin/payments.php?paymentId={id} - Get single payment details
 * - GET /admin/payments.php?orderId={id} - Get payment by orderId
 */

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

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

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only GET method allowed"]
    ]);
    exit;
}

$paymentId = $_GET['paymentId'] ?? null;
$orderId = $_GET['orderId'] ?? null;

if ($paymentId || $orderId) {
    // Get single payment details
    $whereClause = '';
    if ($paymentId) {
        $paymentIdEscaped = mysqli_real_escape_string($conn, $paymentId);
        $whereClause = "pi.payment_id = '$paymentIdEscaped'";
    } elseif ($orderId) {
        $orderIdEscaped = mysqli_real_escape_string($conn, $orderId);
        $whereClause = "pi.order_id = '$orderIdEscaped'";
    }
    
    $sql = "SELECT 
                pi.*,
                u.Email as user_email,
                u.FirstName,
                u.LastName,
                u.Mobile,
                p.packagename,
                p.price as package_price
            FROM payment_info pi
            JOIN users u ON pi.user_id = u.UserId
            LEFT JOIN itr_packages p ON pi.package_id = p.id
            WHERE $whereClause
            LIMIT 1";
    
    $result = $conn->query($sql);
    
    if ($result && $result->num_rows > 0) {
        $payment = $result->fetch_assoc();
        
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "payment" => [
                    "id" => (int)$payment['id'],
                    "paymentId" => $payment['payment_id'],
                    "orderId" => $payment['order_id'],
                    "transactionId" => $payment['transaction_id'],
                    "userId" => (int)$payment['user_id'],
                    "userEmail" => $payment['user_email'],
                    "userName" => trim($payment['FirstName'] . ' ' . $payment['LastName']),
                    "userMobile" => $payment['Mobile'],
                    "packageId" => $payment['package_id'] ? (int)$payment['package_id'] : null,
                    "packageName" => $payment['packagename'],
                    "packagePrice" => $payment['package_price'] ? floatval($payment['package_price']) : null,
                    "panNumber" => $payment['pan_number'],
                    "amount" => [
                        "subtotal" => floatval($payment['subtotal']),
                        "gstPercentage" => floatval($payment['gst_percentage']),
                        "gstAmount" => floatval($payment['gst_amount']),
                        "grandTotal" => floatval($payment['grand_total']),
                        "currency" => $payment['currency']
                    ],
                    "payment" => [
                        "status" => $payment['payment_status'],
                        "method" => $payment['payment_method'],
                        "gateway" => $payment['gateway_name'],
                        "merchantId" => $payment['merchant_id'],
                        "failureReason" => $payment['failure_reason']
                    ],
                    "timestamps" => [
                        "createdAt" => $payment['created_at'],
                        "paidAt" => $payment['paid_at'],
                        "updatedAt" => $payment['updated_at']
                    ],
                    "gatewayResponse" => $payment['gateway_response'] ? json_decode($payment['gateway_response'], true) : null,
                    "webhookData" => $payment['webhook_data'] ? json_decode($payment['webhook_data'], true) : null,
                    "isActive" => (bool)$payment['is_active']
                ]
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
} else {
    // List all payments with pagination and filters
    $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
    $limit = isset($_GET['limit']) ? max(1, min(100, intval($_GET['limit']))) : 20;
    $offset = ($page - 1) * $limit;
    
    $whereClause = "WHERE 1=1";
    
    // Status filter
    if (!empty($_GET['status'])) {
        $statusEscaped = mysqli_real_escape_string($conn, $_GET['status']);
        $whereClause .= " AND pi.payment_status = '$statusEscaped'";
    }
    
    // Date range filter
    if (!empty($_GET['fromDate'])) {
        $fromDateEscaped = mysqli_real_escape_string($conn, $_GET['fromDate']);
        $whereClause .= " AND DATE(pi.created_at) >= '$fromDateEscaped'";
    }
    if (!empty($_GET['toDate'])) {
        $toDateEscaped = mysqli_real_escape_string($conn, $_GET['toDate']);
        $whereClause .= " AND DATE(pi.created_at) <= '$toDateEscaped'";
    }
    
    // Search filter
    if (!empty($_GET['search'])) {
        $searchEscaped = mysqli_real_escape_string($conn, $_GET['search']);
        $whereClause .= " AND (pi.payment_id LIKE '%$searchEscaped%' 
                              OR pi.order_id LIKE '%$searchEscaped%' 
                              OR pi.transaction_id LIKE '%$searchEscaped%'
                              OR u.Email LIKE '%$searchEscaped%'
                              OR pi.pan_number LIKE '%$searchEscaped%')";
    }
    
    // Get total count
    $countSql = "SELECT COUNT(*) as total FROM payment_info pi
                 JOIN users u ON pi.user_id = u.UserId
                 $whereClause";
    $countResult = $conn->query($countSql);
    $totalPayments = $countResult ? $countResult->fetch_assoc()['total'] : 0;
    $totalPages = ceil($totalPayments / $limit);
    
    // Get payments
    $sql = "SELECT 
                pi.id,
                pi.payment_id,
                pi.order_id,
                pi.transaction_id,
                pi.user_id,
                pi.pan_number,
                pi.subtotal,
                pi.gst_amount,
                pi.grand_total,
                pi.currency,
                pi.payment_status,
                pi.payment_method,
                pi.gateway_name,
                pi.created_at,
                pi.paid_at,
                u.Email as user_email,
                u.FirstName,
                u.LastName,
                p.packagename
            FROM payment_info pi
            JOIN users u ON pi.user_id = u.UserId
            LEFT JOIN itr_packages p ON pi.package_id = p.id
            $whereClause
            ORDER BY pi.created_at DESC
            LIMIT $limit OFFSET $offset";
    
    $result = $conn->query($sql);
    $payments = [];
    
    if ($result && $result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $payments[] = [
                "id" => (int)$row['id'],
                "paymentId" => $row['payment_id'],
                "orderId" => $row['order_id'],
                "transactionId" => $row['transaction_id'],
                "userId" => (int)$row['user_id'],
                "userEmail" => $row['user_email'],
                "userName" => trim($row['FirstName'] . ' ' . $row['LastName']),
                "panNumber" => $row['pan_number'],
                "packageName" => $row['packagename'],
                "amount" => [
                    "subtotal" => floatval($row['subtotal']),
                    "gstAmount" => floatval($row['gst_amount']),
                    "grandTotal" => floatval($row['grand_total']),
                    "currency" => $row['currency']
                ],
                "status" => $row['payment_status'],
                "paymentMethod" => $row['payment_method'],
                "gateway" => $row['gateway_name'],
                "createdAt" => $row['created_at'],
                "paidAt" => $row['paid_at']
            ];
        }
    }
    
    // Get summary statistics
    $summarySql = "SELECT 
                    payment_status,
                    COUNT(*) as count,
                    COALESCE(SUM(grand_total), 0) as total_amount
                  FROM payment_info
                  $whereClause
                  GROUP BY payment_status";
    $summaryResult = $conn->query($summarySql);
    $summary = [];
    if ($summaryResult && $summaryResult->num_rows > 0) {
        while ($row = $summaryResult->fetch_assoc()) {
            $summary[] = [
                "status" => $row['payment_status'],
                "count" => (int)$row['count'],
                "totalAmount" => floatval($row['total_amount'])
            ];
        }
    }
    
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "payments" => $payments,
            "summary" => $summary,
            "pagination" => [
                "page" => $page,
                "limit" => $limit,
                "total" => (int)$totalPayments,
                "totalPages" => $totalPages
            ]
        ]
    ], JSON_UNESCAPED_UNICODE);
}

exit;
?>
