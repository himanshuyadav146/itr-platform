<?php
/**
 * Admin Get Assignments API
 * Get ITR assignments with filters
 * 
 * Endpoints: 
 * - GET /admin/get_assignments.php - List all assignments (with pagination)
 *   Query Parameters:
 *     - page: Page number (default: 1)
 *     - limit: Items per page (default: 20, max: 100)
 *     - itrId: Filter by ITR ID (optional)
 *     - professionalId: Filter by Professional ID (userId) (optional)
 *     - userId: Filter by User ID (optional)
 *     - orderId: Filter by Order ID (optional)
 *     - status: Filter by status - 'assigned', 'in_progress', 'completed', 'rejected' (optional)
 *     - priority: Filter by priority - 'low', 'normal', 'high', 'urgent' (optional)
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

$method = $_SERVER['REQUEST_METHOD'];

// GET - List assignments
if ($method === 'GET') {
    // Pagination
    $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
    $limit = isset($_GET['limit']) ? max(1, min(100, intval($_GET['limit']))) : 20;
    $offset = ($page - 1) * $limit;
    
    // Build filters
    $filters = [];
    
    if (isset($_GET['itrId']) && !empty($_GET['itrId'])) {
        $itrIdEscaped = mysqli_real_escape_string($conn, $_GET['itrId']);
        $filters[] = "ia.itr_id = '$itrIdEscaped'";
    }
    
    if (isset($_GET['professionalId']) && !empty($_GET['professionalId'])) {
        $profIdEscaped = mysqli_real_escape_string($conn, $_GET['professionalId']);
        $filters[] = "ia.professional_id = '$profIdEscaped'";
    }
    
    if (isset($_GET['userId']) && !empty($_GET['userId'])) {
        $userIdEscaped = mysqli_real_escape_string($conn, $_GET['userId']);
        $filters[] = "ia.user_id = '$userIdEscaped'";
    }
    
    if (isset($_GET['orderId']) && !empty($_GET['orderId'])) {
        $orderIdEscaped = mysqli_real_escape_string($conn, $_GET['orderId']);
        $filters[] = "ia.order_id = '$orderIdEscaped'";
    }
    
    if (isset($_GET['status']) && !empty($_GET['status'])) {
        $statusEscaped = mysqli_real_escape_string($conn, $_GET['status']);
        $filters[] = "ia.status = '$statusEscaped'";
    }
    
    if (isset($_GET['priority']) && !empty($_GET['priority'])) {
        $priorityEscaped = mysqli_real_escape_string($conn, $_GET['priority']);
        $filters[] = "ia.priority = '$priorityEscaped'";
    }
    
    $whereClause = !empty($filters) ? "WHERE " . implode(" AND ", $filters) : "";
    
    // Count total
    $countSql = "SELECT COUNT(*) as total FROM itr_assignments ia $whereClause";
    $countResult = $conn->query($countSql);
    $totalAssignments = 0;
    if ($countResult && $countResult->num_rows > 0) {
        $countRow = $countResult->fetch_assoc();
        $totalAssignments = (int)$countRow['total'];
    }
    $totalPages = $limit > 0 ? ceil($totalAssignments / $limit) : 0;
    
    // Get assignments with related data (using users table instead of professionals)
    $sql = "SELECT 
                ia.id,
                ia.itr_id,
                ia.order_id,
                ia.user_id,
                ia.professional_id,
                ia.assigned_by,
                ia.assignment_date,
                ia.status,
                ia.priority,
                ia.due_date,
                ia.completed_at,
                ia.notes,
                ia.created_at,
                ia.updated_at,
                itr.panNumber as itr_pan_number,
                itr.financialYear as itr_financial_year,
                itr.status as itr_status,
                prof.FirstName as professional_first_name,
                prof.LastName as professional_last_name,
                prof.Email as professional_email,
                prof.Mobile as professional_mobile,
                prof.Role as professional_role,
                u.Email as user_email,
                u.FirstName as user_first_name,
                u.LastName as user_last_name,
                u.Mobile as user_mobile,
                assignedBy.FirstName as assigned_by_first_name,
                assignedBy.LastName as assigned_by_last_name
            FROM itr_assignments ia
            LEFT JOIN itr_detail itr ON ia.itr_id = itr.id
            LEFT JOIN users prof ON ia.professional_id = prof.UserId
            LEFT JOIN users u ON ia.user_id = u.UserId
            LEFT JOIN users assignedBy ON ia.assigned_by = assignedBy.UserId
            $whereClause
            ORDER BY ia.assignment_date DESC, ia.created_at DESC
            LIMIT $limit OFFSET $offset";
    
    $result = $conn->query($sql);
    $assignments = [];
    
    if ($result && $result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $assignments[] = [
                "id" => (int)$row['id'],
                "itrId" => (int)$row['itr_id'],
                "orderId" => $row['order_id'],
                "userId" => (int)$row['user_id'],
                "professionalId" => (int)$row['professional_id'],
                "assignedBy" => $row['assigned_by'] ? (int)$row['assigned_by'] : null,
                "assignmentDate" => $row['assignment_date'],
                "status" => $row['status'],
                "priority" => $row['priority'],
                "dueDate" => $row['due_date'],
                "completedAt" => $row['completed_at'],
                "notes" => $row['notes'],
                "createdAt" => $row['created_at'],
                "updatedAt" => $row['updated_at'],
                "itr" => [
                    "id" => (int)$row['itr_id'],
                    "panNumber" => $row['itr_pan_number'],
                    "financialYear" => $row['itr_financial_year'],
                    "status" => $row['itr_status']
                ],
                "professional" => [
                    "id" => (int)$row['professional_id'],
                    "firstName" => $row['professional_first_name'],
                    "lastName" => $row['professional_last_name'],
                    "email" => $row['professional_email'],
                    "mobile" => $row['professional_mobile'],
                    "role" => $row['professional_role']
                ],
                "user" => [
                    "id" => (int)$row['user_id'],
                    "firstName" => $row['user_first_name'],
                    "lastName" => $row['user_last_name'],
                    "email" => $row['user_email'],
                    "mobile" => $row['user_mobile']
                ],
                "assignedByUser" => $row['assigned_by'] ? [
                    "id" => (int)$row['assigned_by'],
                    "firstName" => $row['assigned_by_first_name'],
                    "lastName" => $row['assigned_by_last_name']
                ] : null
            ];
        }
    }
    
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "assignments" => $assignments,
            "pagination" => [
                "page" => $page,
                "limit" => $limit,
                "total" => $totalAssignments,
                "totalPages" => $totalPages
            ]
        ]
    ], JSON_UNESCAPED_UNICODE);
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
