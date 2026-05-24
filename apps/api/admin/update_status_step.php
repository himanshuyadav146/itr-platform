<?php
/**
 * Professional Update Status Step API - WITH FULL VALIDATION
 * Tax professionals mark status steps as complete/incomplete
 * 
 * Endpoint: PUT /admin/update_status_step.php
 * Auth: Required - ADMIN, ACCOUNTANT, CA roles only
 * 
 * Request Body:
 * {
 *   "orderId": "order_123" OR "itrId": 45,
 *   "statusStep": "documents_verified",
 *   "isCompleted": true,
 *   "notes": "Optional notes"
 * }
 * 
 * Validations:
 * - Step must not be automatic
 * - User must have required role
 * - ITR must be assigned (if required)
 * - Documents must exist (if required)
 * - Step must be revertable (if unmarking)
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require '../include/config.php';
require '../phpjwt/Token.php';
require '../itr_status/StatusHelper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    http_response_code(405);
    echo json_encode(["status" => "error", "statusCode" => 405, "data" => ["message" => "Only PUT method allowed"]]);
    exit;
}

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

$professionalId = $decoded['UserId'] ?? null;
$userRole = $decoded['Role'] ?? null;

// Check if user has permission
if (!in_array($userRole, ['ADMIN', 'ACCOUNTANT', 'CA'])) {
    http_response_code(403);
    echo json_encode(["status" => "error", "statusCode" => 403, "data" => ["message" => "Access denied. Professional access required"]]);
    exit;
}

// ========================================
// INPUT VALIDATION
// ========================================
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    http_response_code(400);
    echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "Invalid JSON input"]]);
    exit;
}

$orderId = $input['orderId'] ?? null;
$itrId = $input['itrId'] ?? null;
$statusStep = $input['statusStep'] ?? null;
$isCompleted = isset($input['isCompleted']) ? (bool)$input['isCompleted'] : false;
$notes = $input['notes'] ?? null;

if (!$orderId && !$itrId) {
    http_response_code(400);
    echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "Either orderId or itrId is required"]]);
    exit;
}

if (!$statusStep) {
    http_response_code(400);
    echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "statusStep is required"]]);
    exit;
}

// ========================================
// FETCH STEP CONFIGURATION FROM DATABASE
// ========================================
$stepConfig = null;

// Check if itr_status_config table exists
$tableCheckSql = "SHOW TABLES LIKE 'itr_status_config'";
$tableCheckResult = $conn->query($tableCheckSql);
if ($tableCheckResult && $tableCheckResult->num_rows > 0) {
    $stepConfigSql = "SELECT * FROM itr_status_config 
                      WHERE step_code = '" . mysqli_real_escape_string($conn, $statusStep) . "' 
                      AND is_active = 1 
                      LIMIT 1";
    $stepConfigResult = $conn->query($stepConfigSql);
    if ($stepConfigResult && $stepConfigResult->num_rows > 0) {
        $stepConfig = $stepConfigResult->fetch_assoc();
    }
}

// Fallback: Use default config if table doesn't exist or step not found
if (!$stepConfig) {
    $defaultConfigs = [
        'payment_success' => ['is_automatic' => 1, 'requires_assignment' => 0, 'requires_documents' => 0, 'can_be_reverted' => 0, 'required_role' => null],
        'expert_assigned' => ['is_automatic' => 1, 'requires_assignment' => 0, 'requires_documents' => 0, 'can_be_reverted' => 0, 'required_role' => null],
        'documents_verified' => ['is_automatic' => 0, 'requires_assignment' => 1, 'requires_documents' => 1, 'can_be_reverted' => 1, 'required_role' => null],
        'filing_itr' => ['is_automatic' => 0, 'requires_assignment' => 1, 'requires_documents' => 1, 'can_be_reverted' => 1, 'required_role' => 'CA,ACCOUNTANT'],
        'acknowledgement_generated' => ['is_automatic' => 0, 'requires_assignment' => 1, 'requires_documents' => 0, 'can_be_reverted' => 0, 'required_role' => 'CA,ADMIN,ACCOUNTANT'],
    ];
    if (!isset($defaultConfigs[$statusStep])) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "Invalid status step: " . $statusStep]
        ]);
        exit;
    }
    $stepConfig = $defaultConfigs[$statusStep];
}

// ========================================
// VALIDATION 1: Check if step is automatic
// ========================================
if ($stepConfig['is_automatic']) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => [
            "message" => "This step is automatically updated by the system and cannot be manually changed",
            "step" => $statusStep,
            "isAutomatic" => true
        ]
    ]);
    exit;
}

// ========================================
// FETCH ORDER/ITR DETAILS
// ========================================
$userId = null;
$paymentId = null;
$panNumber = null;

if ($orderId) {
    $orderIdEscaped = mysqli_real_escape_string($conn, $orderId);
    // Note: payment_info may not have itr_id column - select only columns that exist
    $orderSql = "SELECT user_id, payment_id, pan_number 
                 FROM payment_info 
                 WHERE order_id = '$orderIdEscaped' 
                 LIMIT 1";
    $orderResult = $conn->query($orderSql);
    
    if ($orderResult && $orderResult->num_rows > 0) {
        $orderData = $orderResult->fetch_assoc();
        $userId = $orderData['user_id'];
        $paymentId = $orderData['payment_id'];
        $panNumber = $orderData['pan_number'];
        
        // Get itr_id from itr_detail if we have user_id and pan_number
        if (!$itrId && $userId && $panNumber) {
            $itrLookupSql = "SELECT id FROM itr_detail 
                             WHERE userId = " . (int)$userId . " 
                             AND panNumber = '" . mysqli_real_escape_string($conn, $panNumber) . "' 
                             ORDER BY id DESC LIMIT 1";
            $itrLookupResult = $conn->query($itrLookupSql);
            if ($itrLookupResult && $itrLookupResult->num_rows > 0) {
                $itrId = (int)$itrLookupResult->fetch_assoc()['id'];
            }
        }
        
        // Fallback: get itr_id from itr_order_status if record exists
        if (!$itrId) {
            $itrFromStatusSql = "SELECT itr_id FROM itr_order_status 
                                 WHERE order_id = '$orderIdEscaped' AND itr_id IS NOT NULL 
                                 LIMIT 1";
            $itrFromStatusResult = $conn->query($itrFromStatusSql);
            if ($itrFromStatusResult && $itrFromStatusResult->num_rows > 0) {
                $itrId = (int)$itrFromStatusResult->fetch_assoc()['itr_id'];
            }
        }
    }
}

if ($itrId && !$userId) {
    $itrIdEscaped = (int)$itrId;
    $itrSql = "SELECT userId, panNumber 
               FROM itr_detail 
               WHERE id = $itrIdEscaped 
               LIMIT 1";
    $itrResult = $conn->query($itrSql);
    
    if ($itrResult && $itrResult->num_rows > 0) {
        $itrData = $itrResult->fetch_assoc();
        $userId = $itrData['userId'];
        $panNumber = $itrData['panNumber'];
    }
}

if (!$userId) {
    http_response_code(404);
    echo json_encode(["status" => "error", "statusCode" => 404, "data" => ["message" => "Order or ITR not found"]]);
    exit;
}

// ========================================
// VALIDATION 2: Check role requirements
// ========================================
if ($stepConfig['required_role']) {
    $allowedRoles = array_map('trim', explode(',', $stepConfig['required_role']));
    if (!in_array($userRole, $allowedRoles)) {
        http_response_code(403);
        echo json_encode([
            "status" => "error",
            "statusCode" => 403,
            "data" => [
                "message" => "Insufficient permissions for this step",
                "requiredRoles" => $allowedRoles,
                "yourRole" => $userRole,
                "step" => $statusStep
            ]
        ]);
        exit;
    }
}

// ========================================
// VALIDATION 3: Check assignment requirement
// ========================================
if ($stepConfig['requires_assignment'] && $itrId) {
    // itr_assignments may use assigned_to OR professional_id depending on schema
    $checkColSql = "SHOW COLUMNS FROM itr_assignments WHERE Field IN ('assigned_to', 'professional_id')";
    $colResult = $conn->query($checkColSql);
    $profColumn = 'professional_id';
    if ($colResult && $colResult->num_rows > 0) {
        while ($colRow = $colResult->fetch_assoc()) {
            if ($colRow['Field'] === 'assigned_to') {
                $profColumn = 'assigned_to';
                break;
            }
        }
    }
    
    $assignmentCheck = "SELECT id, $profColumn as prof_id 
                        FROM itr_assignments 
                        WHERE itr_id = " . (int)$itrId;
    
    // Check if is_active column exists
    $checkColumnSql = "SHOW COLUMNS FROM itr_assignments LIKE 'is_active'";
    $columnResult = $conn->query($checkColumnSql);
    if ($columnResult && $columnResult->num_rows > 0) {
        $assignmentCheck .= " AND is_active = 1";
    }
    
    $assignmentCheck .= " LIMIT 1";
    $assignmentResult = $conn->query($assignmentCheck);
    
    if (!$assignmentResult || $assignmentResult->num_rows === 0) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => [
                "message" => "ITR must be assigned to a professional first",
                "itrId" => $itrId,
                "step" => $statusStep
            ]
        ]);
        exit;
    }
    
    $assignment = $assignmentResult->fetch_assoc();
    $assignedToId = (int)($assignment['prof_id'] ?? $assignment['professional_id'] ?? 0);
    
    // For non-admin, verify they are the assigned professional
    if ($userRole !== 'ADMIN') {
        if ($assignedToId !== (int)$professionalId) {
            http_response_code(403);
            echo json_encode([
                "status" => "error",
                "statusCode" => 403,
                "data" => [
                    "message" => "You are not assigned to this ITR",
                    "assignedTo" => $assignedToId,
                    "yourId" => (int)$professionalId
                ]
            ]);
            exit;
        }
    }
}

// ========================================
// VALIDATION 4: Check document requirement
// ========================================
if ($stepConfig['requires_documents'] && $isCompleted) {
    $docCountSql = "SELECT COUNT(*) as doc_count 
                    FROM document_details 
                    WHERE UserId = " . (int)$userId;
    if ($panNumber) {
        $docCountSql .= " AND PanNumber = '" . mysqli_real_escape_string($conn, $panNumber) . "'";
    }
    $docCountSql .= " AND isActive = 1";
    
    $docCountResult = $conn->query($docCountSql);
    $docCount = 0;
    
    if ($docCountResult) {
        $docData = $docCountResult->fetch_assoc();
        $docCount = (int)$docData['doc_count'];
    }
    
    if ($docCount === 0) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => [
                "message" => "Documents must be uploaded before completing this step",
                "documentsCount" => $docCount,
                "step" => $statusStep
            ]
        ]);
        exit;
    }
}

// ========================================
// VALIDATION 5: Check if step can be reverted
// ========================================
if (!$isCompleted && !$stepConfig['can_be_reverted']) {
    $currentStatusSql = "SELECT is_completed 
                         FROM itr_order_status 
                         WHERE user_id = " . (int)$userId . " 
                         AND status_step = '" . mysqli_real_escape_string($conn, $statusStep) . "'";
    if ($orderId) {
        $currentStatusSql .= " AND order_id = '" . mysqli_real_escape_string($conn, $orderId) . "'";
    }
    if ($itrId) {
        $currentStatusSql .= " AND itr_id = " . (int)$itrId;
    }
    $currentStatusSql .= " LIMIT 1";
    
    $currentStatusResult = $conn->query($currentStatusSql);
    if ($currentStatusResult && $currentStatusResult->num_rows > 0) {
        $currentStatus = $currentStatusResult->fetch_assoc();
        if ($currentStatus['is_completed']) {
            http_response_code(400);
            echo json_encode([
                "status" => "error",
                "statusCode" => 400,
                "data" => [
                    "message" => "This step cannot be reverted once completed",
                    "step" => $statusStep,
                    "canBeReverted" => false
                ]
            ]);
            exit;
        }
    }
}

// ========================================
// GET PREVIOUS STATE FOR AUDIT
// ========================================
$previousState = null;
$statusIdForAudit = null;
$checkPreviousSql = "SELECT id, is_completed 
                     FROM itr_order_status 
                     WHERE user_id = " . (int)$userId . " 
                     AND status_step = '" . mysqli_real_escape_string($conn, $statusStep) . "'";
if ($orderId) {
    $checkPreviousSql .= " AND order_id = '" . mysqli_real_escape_string($conn, $orderId) . "'";
}
if ($itrId) {
    $checkPreviousSql .= " AND itr_id = " . (int)$itrId;
}
$checkPreviousSql .= " LIMIT 1";

$checkPreviousResult = $conn->query($checkPreviousSql);
if ($checkPreviousResult && $checkPreviousResult->num_rows > 0) {
    $previous = $checkPreviousResult->fetch_assoc();
    $previousState = (bool)$previous['is_completed'];
    $statusIdForAudit = (int)$previous['id'];
}

// ========================================
// UPDATE STATUS STEP
// ========================================
$updated = StatusHelper::updateStatusStep(
    $conn,
    $orderId,
    $itrId,
    $userId,
    $paymentId,
    $panNumber,
    $statusStep,
    $isCompleted,
    $notes
);

if (!$updated) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Failed to update status step: " . $conn->error]
    ]);
    exit;
}

// Get status ID after update if not already have it
if (!$statusIdForAudit) {
    $getStatusIdSql = "SELECT id FROM itr_order_status 
                       WHERE user_id = " . (int)$userId . " 
                       AND status_step = '" . mysqli_real_escape_string($conn, $statusStep) . "'";
    if ($orderId) {
        $getStatusIdSql .= " AND order_id = '" . mysqli_real_escape_string($conn, $orderId) . "'";
    }
    if ($itrId) {
        $getStatusIdSql .= " AND itr_id = " . (int)$itrId;
    }
    $getStatusIdSql .= " LIMIT 1";
    
    $getStatusIdResult = $conn->query($getStatusIdSql);
    if ($getStatusIdResult && $getStatusIdResult->num_rows > 0) {
        $statusIdForAudit = (int)$getStatusIdResult->fetch_assoc()['id'];
    }
}

// ========================================
// CREATE AUDIT TRAIL (if itr_status_audit table exists)
// ========================================
if ($statusIdForAudit) {
    $auditTableCheck = $conn->query("SHOW TABLES LIKE 'itr_status_audit'");
    if ($auditTableCheck && $auditTableCheck->num_rows > 0) {
        $action = $previousState === null ? 'created' : ($isCompleted ? 'completed' : 'reverted');
        $ipAddress = $_SERVER['REMOTE_ADDR'] ?? null;
        $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? null;
        
        $auditSql = "INSERT INTO itr_status_audit 
                     (status_id, order_id, itr_id, status_step, action, previous_value, new_value, updated_by, updated_by_role, notes, ip_address, user_agent)
                     VALUES 
                     ($statusIdForAudit, " . 
                     ($orderId ? "'" . mysqli_real_escape_string($conn, $orderId) . "'" : "NULL") . ", " .
                     ($itrId ? (int)$itrId : "NULL") . ", '" . 
                     mysqli_real_escape_string($conn, $statusStep) . "', '$action', " .
                     ($previousState !== null ? (int)$previousState : "NULL") . ", " .
                     (int)$isCompleted . ", " .
                     (int)$professionalId . ", '" .
                     mysqli_real_escape_string($conn, $userRole) . "', " .
                     ($notes ? "'" . mysqli_real_escape_string($conn, $notes) . "'" : "NULL") . ", " .
                     ($ipAddress ? "'" . mysqli_real_escape_string($conn, $ipAddress) . "'" : "NULL") . ", " .
                     ($userAgent ? "'" . mysqli_real_escape_string($conn, $userAgent) . "'" : "NULL") . ")";
        
        @$conn->query($auditSql); // Suppress errors - audit is non-critical
    }
}

// ========================================
// UPDATE RELATED TABLES (only if status column exists in itr_assignments)
// ========================================
if ($isCompleted && $itrId) {
    $statusColCheck = $conn->query("SHOW COLUMNS FROM itr_assignments LIKE 'status'");
    if ($statusColCheck && $statusColCheck->num_rows > 0) {
        $whereClause = "itr_id = " . (int)$itrId;
        $isActiveCheck = $conn->query("SHOW COLUMNS FROM itr_assignments LIKE 'is_active'");
        if ($isActiveCheck && $isActiveCheck->num_rows > 0) {
            $whereClause .= " AND is_active = 1";
        }
        
        if ($statusStep === 'expert_assigned') {
            $conn->query("UPDATE itr_assignments SET status = 'in_progress' WHERE $whereClause");
        } elseif ($statusStep === 'filing_itr') {
            $completedColCheck = $conn->query("SHOW COLUMNS FROM itr_assignments LIKE 'completed_at'");
            if ($completedColCheck && $completedColCheck->num_rows > 0) {
                $conn->query("UPDATE itr_assignments SET status = 'completed', completed_at = NOW() WHERE $whereClause");
            } else {
                $conn->query("UPDATE itr_assignments SET status = 'completed' WHERE $whereClause");
            }
        }
    }
}

// ========================================
// SUCCESS RESPONSE
// ========================================
http_response_code(200);
echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" => [
        "message" => "Status step updated successfully",
        "statusStep" => $statusStep,
        "isCompleted" => $isCompleted,
        "previousState" => $previousState,
        "action" => $previousState === null ? 'created' : ($isCompleted ? 'completed' : 'reverted'),
        "updatedBy" => [
            "id" => $professionalId,
            "role" => $userRole
        ],
        "timestamp" => date('Y-m-d H:i:s'),
        "orderId" => $orderId,
        "itrId" => $itrId ? (int)$itrId : null
    ]
], JSON_PRETTY_PRINT);

exit;
?>
