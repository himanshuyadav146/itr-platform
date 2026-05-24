<?php
/**
 * Submit Acknowledgement API
 * When tax expert enters acknowledgement number: store it, mark filing_itr + acknowledgement_generated
 * complete, set itr_detail.status = COMPLETED, and close itr_assignments.
 *
 * Endpoint: POST /admin/submit_acknowledgement.php
 * Auth: Bearer JWT - ADMIN, ACCOUNTANT, CA only (client cannot call)
 *
 * Request Body:
 * {
 *   "itrId": 24,
 *   "acknowledgementNumber": "ACK123456789",
 *   "acknowledgementDate": "2025-03-15",     // optional
 *   "remarks": "Filed via portal",          // optional
 *   "itrForm": "ITR-1",                     // optional
 *   "assessmentYear": "2024-25"             // optional
 * }
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if (!function_exists('getallheaders')) {
    function getallheaders() {
        $headers = [];
        foreach ($_SERVER as $name => $value) {
            if (substr($name, 0, 5) === 'HTTP_') {
                $headers[str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))))] = $value;
            }
        }
        return $headers;
    }
}

require '../include/config.php';
require '../phpjwt/Token.php';
require '../itr_status/StatusHelper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "statusCode" => 405, "data" => ["message" => "Method not allowed. Use POST."]]);
    exit;
}

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

if (!in_array($userRole, ['ADMIN', 'ACCOUNTANT', 'CA'])) {
    http_response_code(403);
    echo json_encode(["status" => "error", "statusCode" => 403, "data" => ["message" => "Access denied. Professional (ADMIN, ACCOUNTANT, CA) only."]]);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
if (!$input) {
    http_response_code(400);
    echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "Invalid JSON input"]]);
    exit;
}

// Enable debug: ?debug=1 in URL or "debug": true in JSON body - returns error details in 500 response
$debug = !empty($_GET['debug']) || !empty($input['debug']);

try {

$itrId = isset($input['itrId']) ? (int)$input['itrId'] : null;
$ackNumber = isset($input['acknowledgementNumber']) ? trim($input['acknowledgementNumber']) : '';

if (!$itrId) {
    http_response_code(400);
    echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "itrId is required"]]);
    exit;
}

if ($ackNumber === '') {
    http_response_code(400);
    echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "acknowledgementNumber is required"]]);
    exit;
}

$itrIdEscaped = (int)$itrId;
$itrRow = $conn->query("SELECT id, userId, panNumber FROM itr_detail WHERE id = $itrIdEscaped LIMIT 1");
if (!$itrRow) {
    http_response_code(500);
    $err = ["message" => "Query failed: itr_detail", "sqlError" => $conn->error, "sqlErrno" => $conn->errno];
    if ($debug) $err["step"] = "fetch_itrdetail";
    echo json_encode(["status" => "error", "statusCode" => 500, "data" => $err]);
    exit;
}
if ($itrRow->num_rows === 0) {
    http_response_code(404);
    echo json_encode(["status" => "error", "statusCode" => 404, "data" => ["message" => "ITR not found"]]);
    exit;
}

$itr = $itrRow->fetch_assoc();
$clientUserId = (int)$itr['userId'];
$clientUserIdEscaped = mysqli_real_escape_string($conn, $clientUserId);
$panNumber = $itr['panNumber'] ?? null;

// Assignment check: ACCOUNTANT/CA must be assigned to this ITR; ADMIN can submit for any
$userRoleUpper = strtoupper(trim((string)$userRole));
if (in_array($userRoleUpper, ['ACCOUNTANT', 'CA'])) {
    $colCheck = $conn->query("SHOW COLUMNS FROM itr_assignments WHERE Field IN ('assigned_to', 'professional_id')");
    $profCol = 'professional_id';
    if ($colCheck && $colCheck->num_rows > 0) {
        while ($c = $colCheck->fetch_assoc()) {
            if ($c['Field'] === 'assigned_to') {
                $profCol = 'assigned_to';
                break;
            }
        }
    }
    $assignSql = "SELECT id FROM itr_assignments WHERE itr_id = $itrIdEscaped";
    $colActiveCheck = $conn->query("SHOW COLUMNS FROM itr_assignments LIKE 'is_active'");
    if ($colActiveCheck && $colActiveCheck->num_rows > 0) {
        $assignSql .= " AND is_active = 1";
    }
    $assignSql .= " AND $profCol = " . (int)$professionalId . " LIMIT 1";
    $assignRes = $conn->query($assignSql);
    if (!$assignRes) {
        http_response_code(500);
        $err = ["message" => "Assignment check query failed", "sqlError" => $conn->error, "sqlErrno" => $conn->errno];
        if ($debug) { $err["step"] = "assignment_check"; $err["sql"] = $assignSql; }
        echo json_encode(["status" => "error", "statusCode" => 500, "data" => $err]);
        exit;
    }
    if ($assignRes->num_rows === 0) {
        http_response_code(403);
        echo json_encode(["status" => "error", "statusCode" => 403, "data" => ["message" => "You are not assigned to this ITR"]]);
        exit;
    }
}

// Resolve order_id, payment_id for StatusHelper
$orderId = null;
$paymentId = null;
$paySql = "SELECT order_id, payment_id, pan_number FROM payment_info WHERE user_id = '$clientUserIdEscaped' AND payment_status = 'success' ORDER BY paid_at DESC LIMIT 1";
$payRes = $conn->query($paySql);
if ($payRes && $payRes->num_rows > 0) {
    $payRow = $payRes->fetch_assoc();
    $orderId = $payRow['order_id'] ?? null;
    $paymentId = $payRow['payment_id'] ?? null;
    if ($panNumber === null && !empty($payRow['pan_number'])) {
        $panNumber = $payRow['pan_number'];
    }
}

$ackDate = isset($input['acknowledgementDate']) ? trim($input['acknowledgementDate']) : null;
$remarks = isset($input['remarks']) ? trim($input['remarks']) : null;
$itrForm = isset($input['itrForm']) ? trim($input['itrForm']) : null;
$assessmentYear = isset($input['assessmentYear']) ? trim($input['assessmentYear']) : null;

// 1. Insert itr_acknowledgement (if table exists) - only use columns that exist
$ackInserted = false;
$tableCheck = $conn->query("SHOW TABLES LIKE 'itr_acknowledgement'");
if ($tableCheck && $tableCheck->num_rows > 0) {
    $colsRes = $conn->query("SHOW COLUMNS FROM itr_acknowledgement");
    $ackColumns = [];
    while ($col = $colsRes->fetch_assoc()) {
        $ackColumns[] = $col['Field'];
    }
    $hasColumn = function ($name) use ($ackColumns) { return in_array($name, $ackColumns); };

    $ackNumEscaped = mysqli_real_escape_string($conn, $ackNumber);
    $cols = [];
    $vals = [];
    // Required: itr_id, acknowledgement_number (match your table: id, itr_id, acknowledgement_number, uploaded_by, uploaded_at)
    $cols[] = 'itr_id'; $vals[] = $itrIdEscaped;
    $cols[] = 'acknowledgement_number'; $vals[] = "'$ackNumEscaped'";
    if ($hasColumn('user_id')) { $cols[] = 'user_id'; $vals[] = $clientUserIdEscaped; }
    if ($hasColumn('uploaded_by')) { $cols[] = 'uploaded_by'; $vals[] = (int)$professionalId; }
    if ($hasColumn('uploaded_at')) { $cols[] = 'uploaded_at'; $vals[] = 'NOW()'; }
    if ($hasColumn('order_id')) { $cols[] = 'order_id'; $vals[] = $orderId ? "'" . mysqli_real_escape_string($conn, $orderId) . "'" : 'NULL'; }
    if ($hasColumn('acknowledgement_date')) { $cols[] = 'acknowledgement_date'; $vals[] = $ackDate ? "'" . mysqli_real_escape_string($conn, $ackDate) . "'" : 'NULL'; }
    if ($hasColumn('assessment_year')) { $cols[] = 'assessment_year'; $vals[] = $assessmentYear ? "'" . mysqli_real_escape_string($conn, $assessmentYear) . "'" : 'NULL'; }
    if ($hasColumn('filing_date')) { $cols[] = 'filing_date'; $vals[] = 'NOW()'; }
    if ($hasColumn('itr_form')) { $cols[] = 'itr_form'; $vals[] = $itrForm ? "'" . mysqli_real_escape_string($conn, $itrForm) . "'" : 'NULL'; }
    if ($hasColumn('status')) { $cols[] = 'status'; $vals[] = "'generated'"; }
    if ($hasColumn('remarks')) { $cols[] = 'remarks'; $vals[] = $remarks ? "'" . mysqli_real_escape_string($conn, $remarks) . "'" : 'NULL'; }

    $insAck = "INSERT INTO itr_acknowledgement (" . implode(', ', $cols) . ") VALUES (" . implode(', ', $vals) . ")";

    if (!$conn->query($insAck)) {
        if ($conn->errno === 1062) {
            http_response_code(400);
            echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "Acknowledgement number already registered for another ITR"]]);
            exit;
        }
        http_response_code(500);
        $err = ["message" => "itr_acknowledgement insert failed", "sqlError" => $conn->error, "sqlErrno" => $conn->errno];
        if ($debug) { $err["step"] = "insert_ack"; $err["sql"] = $insAck; }
        echo json_encode(["status" => "error", "statusCode" => 500, "data" => $err]);
        exit;
    }
    $ackInserted = true;
}

// 2. Mark filing_itr and acknowledgement_generated complete
$notesFiling = "Acknowledgement submitted: " . $ackNumber;
StatusHelper::updateStatusStep($conn, $orderId, $itrId, $clientUserId, $paymentId, $panNumber, 'filing_itr', true, $notesFiling);
StatusHelper::updateStatusStep($conn, $orderId, $itrId, $clientUserId, $paymentId, $panNumber, 'acknowledgement_generated', true, $ackNumber);

// 3. Set itr_detail.status = COMPLETED
$updItr = $conn->query("UPDATE itr_detail SET status = 'COMPLETED', updatedAt = NOW() WHERE id = $itrIdEscaped");
if (!$updItr && $conn->error) {
    http_response_code(500);
    $err = ["message" => "itr_detail update failed", "sqlError" => $conn->error, "sqlErrno" => $conn->errno];
    if ($debug) $err["step"] = "update_itrdetail";
    echo json_encode(["status" => "error", "statusCode" => 500, "data" => $err]);
    exit;
}

// 4. Close itr_assignments (same as update_status_step when filing_itr completed)
$colStatus = $conn->query("SHOW COLUMNS FROM itr_assignments LIKE 'status'");
if ($colStatus && $colStatus->num_rows > 0) {
    $whereAssign = "itr_id = $itrIdEscaped";
    $colActive = $conn->query("SHOW COLUMNS FROM itr_assignments LIKE 'is_active'");
    if ($colActive && $colActive->num_rows > 0) {
        $whereAssign .= " AND is_active = 1";
    }
    $colCompleted = $conn->query("SHOW COLUMNS FROM itr_assignments LIKE 'completed_at'");
    if ($colCompleted && $colCompleted->num_rows > 0) {
        $conn->query("UPDATE itr_assignments SET status = 'completed', completed_at = NOW() WHERE $whereAssign");
    } else {
        $conn->query("UPDATE itr_assignments SET status = 'completed' WHERE $whereAssign");
    }
}

// 5. Optional: audit row in itr_order_concerns (status_update, resolved)
$concernTableCheck = $conn->query("SHOW TABLES LIKE 'itr_order_concerns'");
if ($concernTableCheck && $concernTableCheck->num_rows > 0) {
    $commentText = "Acknowledgement number: " . $ackNumber;
    $commentEscaped = mysqli_real_escape_string($conn, $commentText);
    $hasCommentCol = $conn->query("SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'itr_order_concerns' AND COLUMN_NAME = 'comment' LIMIT 1");
    $useCommentCol = $hasCommentCol && $hasCommentCol->num_rows > 0;
    if ($useCommentCol) {
        @$conn->query("INSERT INTO itr_order_concerns (status_id, itr_id, user_id, concern_type, concern_text, comment, status, resolved_by, resolved_at, created_at, updated_at)
                       VALUES (NULL, $itrIdEscaped, $clientUserIdEscaped, 'status_update', '$commentEscaped', '$commentEscaped', 'resolved', " . (int)$professionalId . ", NOW(), NOW(), NOW())");
    } else {
        @$conn->query("INSERT INTO itr_order_concerns (status_id, itr_id, user_id, concern_type, concern_text, status, resolved_by, resolved_at, created_at, updated_at)
                       VALUES (NULL, $itrIdEscaped, $clientUserIdEscaped, 'status_update', '$commentEscaped', 'resolved', " . (int)$professionalId . ", NOW(), NOW(), NOW())");
    }
}

http_response_code(200);
echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" => [
        "message" => "Acknowledgement submitted. ITR marked completed and closed.",
        "itrId" => $itrId,
        "acknowledgementNumber" => $ackNumber,
        "itrStatus" => "COMPLETED",
        "stepsUpdated" => ["filing_itr", "acknowledgement_generated"],
        "acknowledgementStored" => $ackInserted,
        "updatedBy" => ["id" => (int)$professionalId, "role" => $userRole],
        "timestamp" => date('Y-m-d H:i:s')
    ]
], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    error_log('[submit_acknowledgement] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine());
    http_response_code(500);
    $err = [
        "message" => "Server error",
        "error" => $e->getMessage(),
        "file" => $e->getFile(),
        "line" => $e->getLine()
    ];
    if ($debug) {
        $err["trace"] = $e->getTraceAsString();
    }
    echo json_encode(["status" => "error", "statusCode" => 500, "data" => $err], JSON_UNESCAPED_UNICODE);
}

exit;
