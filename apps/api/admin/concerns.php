<?php
/**
 * Admin Concerns Management API
 * List, view, and manage concerns/raised issues
 * 
 * Endpoints: 
 * - GET /admin/concerns.php - List all concerns (with filters)
 * - GET /admin/concerns.php?concernId={id} - Get single concern details
 * - PUT /admin/concerns.php - Update concern status (resolve/reject)
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

// GET - List concerns or get single concern
if ($method === 'GET') {
    $concernId = $_GET['concernId'] ?? null;
    
    if ($concernId) {
        // Get single concern details
        $concernIdEscaped = mysqli_real_escape_string($conn, $concernId);
        $sql = "SELECT 
                    c.id,
                    c.status_id,
                    c.order_id,
                    c.itr_id,
                    c.user_id,
                    c.concern_type,
                    c.concern_text,
                    c.concern_image_path,
                    c.status,
                    c.resolved_at,
                    c.resolved_by,
                    c.resolution_notes,
                    c.created_at,
                    c.updated_at,
                    s.status_step,
                    s.is_completed,
                    u.Email as user_email,
                    u.FirstName,
                    u.LastName,
                    pi.payment_id,
                    pi.grand_total as order_amount
                FROM itr_order_concerns c
                JOIN itr_order_status s ON c.status_id = s.id
                JOIN users u ON c.user_id = u.UserId
                LEFT JOIN payment_info pi ON c.order_id = pi.order_id
                WHERE c.id = '$concernIdEscaped'";
        
        $result = $conn->query($sql);
        
        if ($result && $result->num_rows > 0) {
            $concern = $result->fetch_assoc();
            
            http_response_code(200);
            echo json_encode([
                "status" => "success",
                "statusCode" => 200,
                "data" => [
                    "concern" => [
                        "id" => (int)$concern['id'],
                        "statusId" => (int)$concern['status_id'],
                        "orderId" => $concern['order_id'],
                        "itrId" => $concern['itr_id'] ? (int)$concern['itr_id'] : null,
                        "userId" => (int)$concern['user_id'],
                        "userEmail" => $concern['user_email'],
                        "userName" => trim($concern['FirstName'] . ' ' . $concern['LastName']),
                        "statusStep" => $concern['status_step'],
                        "isCompleted" => (bool)$concern['is_completed'],
                        "concernType" => $concern['concern_type'],
                        "concernText" => $concern['concern_text'],
                        "concernImagePath" => $concern['concern_image_path'],
                        "status" => $concern['status'],
                        "resolvedAt" => $concern['resolved_at'],
                        "resolvedBy" => $concern['resolved_by'] ? (int)$concern['resolved_by'] : null,
                        "resolutionNotes" => $concern['resolution_notes'],
                        "createdAt" => $concern['created_at'],
                        "updatedAt" => $concern['updated_at'],
                        "order" => [
                            "paymentId" => $concern['payment_id'],
                            "amount" => $concern['order_amount'] ? floatval($concern['order_amount']) : null
                        ]
                    ]
                ]
            ], JSON_UNESCAPED_UNICODE);
        } else {
            http_response_code(404);
            echo json_encode([
                "status" => "error",
                "statusCode" => 404,
                "data" => ["message" => "Concern not found"]
            ]);
        }
    } else {
        // List all concerns with pagination and filters
        $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
        $limit = isset($_GET['limit']) ? max(1, min(100, intval($_GET['limit']))) : 20;
        $offset = ($page - 1) * $limit;
        
        $whereClause = "WHERE 1=1";
        
        // Status filter
        if (!empty($_GET['status'])) {
            $statusEscaped = mysqli_real_escape_string($conn, $_GET['status']);
            $whereClause .= " AND c.status = '$statusEscaped'";
        }
        
        // Type filter
        if (!empty($_GET['type'])) {
            $typeEscaped = mysqli_real_escape_string($conn, $_GET['type']);
            $whereClause .= " AND c.concern_type = '$typeEscaped'";
        }
        
        // Order ID filter
        if (!empty($_GET['orderId'])) {
            $orderIdEscaped = mysqli_real_escape_string($conn, $_GET['orderId']);
            $whereClause .= " AND c.order_id = '$orderIdEscaped'";
        }
        
        // Get total count
        $countSql = "SELECT COUNT(*) as total FROM itr_order_concerns c $whereClause";
        $countResult = $conn->query($countSql);
        $totalConcerns = $countResult ? $countResult->fetch_assoc()['total'] : 0;
        $totalPages = ceil($totalConcerns / $limit);
        
        // Get concerns
        $sql = "SELECT 
                    c.id,
                    c.order_id,
                    c.itr_id,
                    c.user_id,
                    c.concern_type,
                    c.concern_text,
                    c.concern_image_path,
                    c.status,
                    c.resolved_at,
                    c.resolution_notes,
                    c.created_at,
                    s.status_step,
                    u.Email as user_email,
                    u.FirstName,
                    u.LastName
                FROM itr_order_concerns c
                JOIN itr_order_status s ON c.status_id = s.id
                JOIN users u ON c.user_id = u.UserId
                $whereClause
                ORDER BY c.created_at DESC
                LIMIT $limit OFFSET $offset";
        
        $result = $conn->query($sql);
        $concerns = [];
        
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $concerns[] = [
                    "id" => (int)$row['id'],
                    "orderId" => $row['order_id'],
                    "itrId" => $row['itr_id'] ? (int)$row['itr_id'] : null,
                    "userId" => (int)$row['user_id'],
                    "userEmail" => $row['user_email'],
                    "userName" => trim($row['FirstName'] . ' ' . $row['LastName']),
                    "statusStep" => $row['status_step'],
                    "concernType" => $row['concern_type'],
                    "concernText" => $row['concern_text'],
                    "concernImagePath" => $row['concern_image_path'],
                    "status" => $row['status'],
                    "resolvedAt" => $row['resolved_at'],
                    "resolutionNotes" => $row['resolution_notes'],
                    "createdAt" => $row['created_at']
                ];
            }
        }
        
        // Get summary by status
        $summarySql = "SELECT 
                        status,
                        COUNT(*) as count
                      FROM itr_order_concerns
                      GROUP BY status";
        $summaryResult = $conn->query($summarySql);
        $summary = [];
        if ($summaryResult && $summaryResult->num_rows > 0) {
            while ($row = $summaryResult->fetch_assoc()) {
                $summary[] = [
                    "status" => $row['status'],
                    "count" => (int)$row['count']
                ];
            }
        }
        
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "concerns" => $concerns,
                "summary" => $summary,
                "pagination" => [
                    "page" => $page,
                    "limit" => $limit,
                    "total" => (int)$totalConcerns,
                    "totalPages" => $totalPages
                ]
            ]
        ], JSON_UNESCAPED_UNICODE);
    }
}

// PUT - Update concern (resolve/reject)
elseif ($method === 'PUT') {
    $input = file_get_contents("php://input");
    $data = json_decode($input, true);
    
    if (!$data || !isset($data['concernId'])) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "concernId is required"]
        ]);
        exit;
    }
    
    $concernId = mysqli_real_escape_string($conn, $data['concernId']);
    $status = isset($data['status']) ? mysqli_real_escape_string($conn, $data['status']) : null;
    $resolutionNotes = isset($data['resolutionNotes']) ? mysqli_real_escape_string($conn, $data['resolutionNotes']) : null;
    $adminUserId = $decoded['UserId'] ?? null;
    
    if (!$status || !in_array($status, ['resolved', 'rejected'])) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "Valid status (resolved/rejected) is required"]
        ]);
        exit;
    }
    
    // Check if concern exists
    $checkSql = "SELECT id, status_id FROM itr_order_concerns WHERE id = '$concernId'";
    $checkResult = $conn->query($checkSql);
    
    if (!$checkResult || $checkResult->num_rows === 0) {
        http_response_code(404);
        echo json_encode([
            "status" => "error",
            "statusCode" => 404,
            "data" => ["message" => "Concern not found"]
        ]);
        exit;
    }
    
    $concern = $checkResult->fetch_assoc();
    $statusId = $concern['status_id'];
    
    // Update concern
    $updateFields = [
        "status = '$status'",
        "resolved_at = NOW()",
        "resolved_by = " . intval($adminUserId),
        "updated_at = NOW()"
    ];
    
    if ($resolutionNotes !== null) {
        $updateFields[] = "resolution_notes = '" . $resolutionNotes . "'";
    }
    
    $updateSql = "UPDATE itr_order_concerns SET " . implode(", ", $updateFields) . " WHERE id = '$concernId'";
    
    if ($conn->query($updateSql)) {
        // If resolved, update the status step to remove concern flag
        if ($status === 'resolved') {
            // Check if all concerns for this status are resolved
            $allConcernsSql = "SELECT COUNT(*) as pending_count 
                             FROM itr_order_concerns 
                             WHERE status_id = $statusId AND status = 'pending'";
            $allConcernsResult = $conn->query($allConcernsSql);
            $pendingCount = $allConcernsResult ? (int)$allConcernsResult->fetch_assoc()['pending_count'] : 0;
            
            if ($pendingCount === 0) {
                // No pending concerns, remove concern flag
                $updateStatusSql = "UPDATE itr_order_status 
                                   SET has_concern = 0, updated_at = NOW() 
                                   WHERE id = $statusId";
                $conn->query($updateStatusSql);
            }
        }
        
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => ["message" => "Concern updated successfully"]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to update concern: " . $conn->error]
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
