<?php
/**
 * Get Status Audit Trail API
 * View history of all status changes for an order/ITR
 * 
 * Endpoint: GET /admin/get_status_audit.php?orderId=xxx OR ?itrId=xxx
 * Auth: ADMIN, ACCOUNTANT, CA
 * 
 * Optional filters:
 * - statusStep: Filter by specific step
 * - action: Filter by action (created, completed, reverted)
 * - limit: Number of records (default: 50)
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

// ========================================
// AUTHENTICATION
// ========================================
$headers = getallheaders();
$token = isset($headers['Authorization']) ? str_replace("Bearer ", "", trim($headers['Authorization'])) : "";

if (empty($token)) {
    http_response_code(401);
    echo json_encode(["status" => "error", "statusCode" => 401, "data" => ["message" => "Authorization token required"]]);
    exit;
}

$decoded = Token::Verify($token, $key);
if ($decoded === false) {
    http_response_code(401);
    echo json_encode(["status" => "error", "statusCode" => 401, "data" => ["message" => "Invalid or expired token"]]);
    exit;
}

$userRole = $decoded['Role'] ?? null;
if (!in_array($userRole, ['ADMIN', 'ACCOUNTANT', 'CA'])) {
    http_response_code(403);
    echo json_encode(["status" => "error", "statusCode" => 403, "data" => ["message" => "Access denied. Professional access required"]]);
    exit;
}

// ========================================
// GET PARAMETERS
// ========================================
$orderId = $_GET['orderId'] ?? null;
$itrId = $_GET['itrId'] ?? null;
$statusStep = $_GET['statusStep'] ?? null;
$action = $_GET['action'] ?? null;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;

if (!$orderId && !$itrId) {
    http_response_code(400);
    echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "orderId or itrId is required"]]);
    exit;
}

// ========================================
// BUILD QUERY
// ========================================
$whereClause = "WHERE 1=1";

if ($orderId) {
    $whereClause .= " AND a.order_id = '" . mysqli_real_escape_string($conn, $orderId) . "'";
}

if ($itrId) {
    $whereClause .= " AND a.itr_id = " . (int)$itrId;
}

if ($statusStep) {
    $whereClause .= " AND a.status_step = '" . mysqli_real_escape_string($conn, $statusStep) . "'";
}

if ($action) {
    $whereClause .= " AND a.action = '" . mysqli_real_escape_string($conn, $action) . "'";
}

$sql = "SELECT 
          a.id,
          a.status_step,
          a.action,
          a.previous_value,
          a.new_value,
          a.notes,
          a.ip_address,
          a.created_at,
          a.updated_by,
          u.FirstName,
          u.LastName,
          u.Email,
          a.updated_by_role,
          sc.title as step_title,
          sc.color as step_color,
          sc.icon as step_icon
        FROM itr_status_audit a
        LEFT JOIN users u ON a.updated_by = u.UserId
        LEFT JOIN itr_status_config sc ON a.status_step = sc.step_code
        $whereClause
        ORDER BY a.created_at DESC
        LIMIT $limit";

$result = $conn->query($sql);
$auditLog = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $auditLog[] = [
            "id" => (int)$row['id'],
            "statusStep" => $row['status_step'],
            "stepTitle" => $row['step_title'],
            "stepColor" => $row['step_color'],
            "stepIcon" => $row['step_icon'],
            "action" => $row['action'],
            "previousValue" => $row['previous_value'] !== null ? (bool)$row['previous_value'] : null,
            "newValue" => $row['new_value'] !== null ? (bool)$row['new_value'] : null,
            "notes" => $row['notes'],
            "updatedBy" => [
                "id" => (int)$row['updated_by'],
                "name" => trim($row['FirstName'] . ' ' . $row['LastName']),
                "email" => $row['Email'],
                "role" => $row['updated_by_role']
            ],
            "ipAddress" => $row['ip_address'],
            "timestamp" => $row['created_at']
        ];
    }
}

// Get summary statistics
$summarySql = "SELECT 
                 COUNT(*) as total_changes,
                 COUNT(DISTINCT status_step) as unique_steps,
                 COUNT(DISTINCT updated_by) as unique_updaters,
                 MIN(created_at) as first_update,
                 MAX(created_at) as last_update
               FROM itr_status_audit a
               $whereClause";

$summaryResult = $conn->query($summarySql);
$summary = null;

if ($summaryResult && $summaryResult->num_rows > 0) {
    $summaryData = $summaryResult->fetch_assoc();
    $summary = [
        "totalChanges" => (int)$summaryData['total_changes'],
        "uniqueSteps" => (int)$summaryData['unique_steps'],
        "uniqueUpdaters" => (int)$summaryData['unique_updaters'],
        "firstUpdate" => $summaryData['first_update'],
        "lastUpdate" => $summaryData['last_update']
    ];
}

http_response_code(200);
echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" => [
        "auditLog" => $auditLog,
        "summary" => $summary,
        "filters" => [
            "orderId" => $orderId,
            "itrId" => $itrId ? (int)$itrId : null,
            "statusStep" => $statusStep,
            "action" => $action,
            "limit" => $limit
        ],
        "total" => count($auditLog)
    ]
], JSON_PRETTY_PRINT);

exit;
?>
