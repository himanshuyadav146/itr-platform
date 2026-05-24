<?php
/**
 * Admin Orders/ITR Management API
 * List, view, update orders and ITR details
 * 
 * Endpoints: 
 * - GET /admin/orders.php - List all orders/ITRs (with pagination)
 * - GET /admin/orders.php?orderId={id} - Get single order by orderId
 * - GET /admin/orders.php?itrId={id} - Get single order by itrId
 * - PUT /admin/orders.php - Update order status
 */

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, PUT");
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

$method = $_SERVER['REQUEST_METHOD'];

// GET - List orders or get single order
if ($method === 'GET') {
    $orderId = $_GET['orderId'] ?? null;
    $itrId = $_GET['itrId'] ?? null;
    
    if ($orderId || $itrId) {
        // Get single order details
        $orderFilter = '';
        if ($orderId) {
            $orderIdEscaped = mysqli_real_escape_string($conn, $orderId);
            $orderFilter = "pi.order_id = '$orderIdEscaped'";
        } elseif ($itrId) {
            $itrIdEscaped = mysqli_real_escape_string($conn, $itrId);
            $orderFilter = "itr.id = '$itrIdEscaped'";
        }
        
        $sql = "SELECT 
                    pi.id as payment_id,
                    pi.payment_id as payment_reference,
                    pi.order_id,
                    pi.transaction_id,
                    pi.user_id,
                    pi.package_id,
                    pi.pan_number,
                    pi.subtotal,
                    pi.gst_percentage,
                    pi.gst_amount,
                    pi.grand_total,
                    pi.currency,
                    pi.payment_status,
                    pi.payment_method,
                    pi.gateway_name,
                    pi.created_at as payment_created_at,
                    pi.paid_at,
                    itr.id as itr_id,
                    itr.financial_year,
                    itr.status as itr_status,
                    itr.created_at as itr_created_at,
                    u.Email as user_email,
                    u.FirstName,
                    u.LastName,
                    u.Mobile,
                    p.packagename,
                    p.price as package_price
                FROM payment_info pi
                LEFT JOIN itr_detail itr ON pi.pan_number = itr.panNumber AND pi.user_id = itr.userId
                JOIN users u ON pi.user_id = u.UserId
                LEFT JOIN itr_packages p ON pi.package_id = p.id
                WHERE $orderFilter
                ORDER BY pi.created_at DESC
                LIMIT 1";
        
        $result = $conn->query($sql);
        
        if ($result && $result->num_rows > 0) {
            $order = $result->fetch_assoc();
            
            // Get order status steps
            $orderIdValue = $order['order_id'];
            $itrIdValue = $order['itr_id'];
            $statusSql = "SELECT 
                            id,
                            status_step,
                            is_completed,
                            completed_at,
                            notes,
                            has_concern
                        FROM itr_order_status
                        WHERE (order_id = '" . mysqli_real_escape_string($conn, $orderIdValue) . "' 
                               OR itr_id = " . intval($itrIdValue) . ")
                        ORDER BY id ASC";
            $statusResult = $conn->query($statusSql);
            $statusSteps = [];
            if ($statusResult && $statusResult->num_rows > 0) {
                while ($row = $statusResult->fetch_assoc()) {
                    $statusSteps[] = [
                        "id" => (int)$row['id'],
                        "statusStep" => $row['status_step'],
                        "isCompleted" => (bool)$row['is_completed'],
                        "completedAt" => $row['completed_at'],
                        "notes" => $row['notes'],
                        "hasConcern" => (bool)$row['has_concern']
                    ];
                }
            }
            
            http_response_code(200);
            echo json_encode([
                "status" => "success",
                "statusCode" => 200,
                "data" => [
                    "order" => [
                        "paymentId" => (int)$order['payment_id'],
                        "paymentReference" => $order['payment_reference'],
                        "orderId" => $order['order_id'],
                        "transactionId" => $order['transaction_id'],
                        "userId" => (int)$order['user_id'],
                        "userEmail" => $order['user_email'],
                        "userName" => trim($order['FirstName'] . ' ' . $order['LastName']),
                        "userMobile" => $order['Mobile'],
                        "packageId" => $order['package_id'] ? (int)$order['package_id'] : null,
                        "packageName" => $order['packagename'],
                        "packagePrice" => $order['package_price'] ? floatval($order['package_price']) : null,
                        "panNumber" => $order['pan_number'],
                        "financialYear" => $order['financial_year'],
                        "itrId" => $order['itr_id'] ? (int)$order['itr_id'] : null,
                        "itrStatus" => $order['itr_status'],
                        "amount" => [
                            "subtotal" => floatval($order['subtotal']),
                            "gstPercentage" => floatval($order['gst_percentage']),
                            "gstAmount" => floatval($order['gst_amount']),
                            "grandTotal" => floatval($order['grand_total']),
                            "currency" => $order['currency']
                        ],
                        "payment" => [
                            "status" => $order['payment_status'],
                            "method" => $order['payment_method'],
                            "gateway" => $order['gateway_name'],
                            "createdAt" => $order['payment_created_at'],
                            "paidAt" => $order['paid_at']
                        ],
                        "itrCreatedAt" => $order['itr_created_at'],
                        "statusSteps" => $statusSteps
                    ]
                ]
            ], JSON_UNESCAPED_UNICODE);
        } else {
            http_response_code(404);
            echo json_encode([
                "status" => "error",
                "statusCode" => 404,
                "data" => ["message" => "Order not found"]
            ]);
        }
    } else {
        // List all orders with pagination
        $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
        $limit = isset($_GET['limit']) ? max(1, min(100, intval($_GET['limit']))) : 20;
        $offset = ($page - 1) * $limit;
        
        $statusFilter = $_GET['status'] ?? '';
        $whereClause = "WHERE 1=1";
        
        if (!empty($statusFilter)) {
            $statusEscaped = mysqli_real_escape_string($conn, $statusFilter);
            $whereClause .= " AND pi.payment_status = '$statusEscaped'";
        }
        
        // Get total count
        $countSql = "SELECT COUNT(*) as total FROM payment_info pi $whereClause";
        $countResult = $conn->query($countSql);
        $totalOrders = $countResult ? $countResult->fetch_assoc()['total'] : 0;
        $totalPages = ceil($totalOrders / $limit);
        
        // Get orders
        $sql = "SELECT 
                    pi.id,
                    pi.payment_id,
                    pi.order_id,
                    pi.user_id,
                    pi.pan_number,
                    pi.grand_total,
                    pi.payment_status,
                    pi.payment_method,
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
        $orders = [];
        
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $orders[] = [
                    "id" => (int)$row['id'],
                    "paymentId" => $row['payment_id'],
                    "orderId" => $row['order_id'],
                    "userId" => (int)$row['user_id'],
                    "userEmail" => $row['user_email'],
                    "userName" => trim($row['FirstName'] . ' ' . $row['LastName']),
                    "panNumber" => $row['pan_number'],
                    "packageName" => $row['packagename'],
                    "amount" => floatval($row['grand_total']),
                    "status" => $row['payment_status'],
                    "paymentMethod" => $row['payment_method'],
                    "createdAt" => $row['created_at'],
                    "paidAt" => $row['paid_at']
                ];
            }
        }
        
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "orders" => $orders,
                "pagination" => [
                    "page" => $page,
                    "limit" => $limit,
                    "total" => (int)$totalOrders,
                    "totalPages" => $totalPages
                ]
            ]
        ], JSON_UNESCAPED_UNICODE);
    }
}

// PUT - Update order status
elseif ($method === 'PUT') {
    $input = file_get_contents("php://input");
    $data = json_decode($input, true);
    
    if (!$data || (!isset($data['orderId']) && !isset($data['itrId']))) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "orderId or itrId is required"]
        ]);
        exit;
    }
    
    $orderId = isset($data['orderId']) ? mysqli_real_escape_string($conn, $data['orderId']) : null;
    $itrId = isset($data['itrId']) ? intval($data['itrId']) : null;
    $statusStep = isset($data['statusStep']) ? mysqli_real_escape_string($conn, $data['statusStep']) : null;
    $notes = isset($data['notes']) ? mysqli_real_escape_string($conn, $data['notes']) : null;
    $isCompleted = isset($data['isCompleted']) ? (intval($data['isCompleted']) ? 1 : 0) : null;
    
    if (!$statusStep && !$notes && $isCompleted === null) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "At least one field to update is required"]
        ]);
        exit;
    }
    
    // Find status record
    $whereClause = [];
    if ($orderId) {
        $whereClause[] = "order_id = '$orderId'";
    }
    if ($itrId) {
        $whereClause[] = "itr_id = $itrId";
    }
    if ($statusStep) {
        $whereClause[] = "status_step = '$statusStep'";
    }
    
    if (empty($whereClause)) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "Invalid parameters"]
        ]);
        exit;
    }
    
    $updateFields = [];
    if ($isCompleted !== null) {
        $updateFields[] = "is_completed = $isCompleted";
        if ($isCompleted) {
            $updateFields[] = "completed_at = NOW()";
        } else {
            $updateFields[] = "completed_at = NULL";
        }
    }
    if ($notes !== null) {
        $updateFields[] = "notes = '" . $notes . "'";
    }
    
    if (empty($updateFields)) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "No fields to update"]
        ]);
        exit;
    }
    
    $updateFields[] = "updated_at = NOW()";
    $whereSql = implode(" AND ", $whereClause);
    $updateSql = "UPDATE itr_order_status SET " . implode(", ", $updateFields) . " WHERE $whereSql";
    
    if ($conn->query($updateSql)) {
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => ["message" => "Order status updated successfully"]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to update order status: " . $conn->error]
        ]);
    }
}

else {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Method not allowed"]
    ]);
}

exit;
?>
