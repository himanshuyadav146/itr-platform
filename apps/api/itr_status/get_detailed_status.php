<?php
/**
 * Get Detailed ITR Status API
 * Returns comprehensive status including:
 * - ITR order status workflow (5 steps)
 * - Payment status
 * - Assignment status
 * - ITR details
 * 
 * Endpoint: GET /itr_status/get_detailed_status.php
 * Query Parameters:
 *   - orderId: Payment order ID (optional)
 *   - itrId: ITR detail ID (optional)
 *   - At least one is required
 *   - debug=1: Return PHP error in response (for debugging 500)
 */

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

$debugMode = isset($_GET['debug']) && $_GET['debug'] === '1';

if ($debugMode) {
    error_reporting(E_ALL);
    ini_set('display_errors', 0);
    ini_set('log_errors', 1);
}

require '../include/config.php';
require '../phpjwt/Token.php';
require 'StatusHelper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only GET allowed"]
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

// Get query parameters
$orderId = $_GET['orderId'] ?? null;
$itrId = $_GET['itrId'] ?? null;

if (!$orderId && !$itrId) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "orderId or itrId is required"]
    ]);
    exit;
}

try {
// =====================================================
// 1. GET ITR STATUS (5-step workflow)
// =====================================================
$steps = StatusHelper::getStatusSteps($conn, $orderId, $itrId, $userId);
$allSteps = StatusHelper::getAllSteps();
$statusSteps = [];

// Merge duplicate step rows (same status_step from order_id vs itr_id) so all 5 steps are correct
foreach ($allSteps as $step) {
    $stepRows = [];
    foreach ($steps as $dbStep) {
        if ($dbStep['status_step'] === $step) {
            $stepRows[] = $dbStep;
        }
    }
    
    $isCompleted = false;
    $completedAt = null;
    $hasConcern = false;
    $notes = null;
    $statusIdsWithConcern = [];
    
    foreach ($stepRows as $row) {
        if (!empty($row['is_completed'])) {
            $isCompleted = true;
            if (!empty($row['completed_at']) && ($completedAt === null || $row['completed_at'] > $completedAt)) {
                $completedAt = $row['completed_at'];
            }
        }
        if (!empty($row['has_concern'])) {
            $hasConcern = true;
            $statusIdsWithConcern[] = $row['id'];
        }
        if ($notes === null && !empty($row['notes'])) {
            $notes = $row['notes'];
        }
    }
    
    $stepObj = [
        "step" => $step,
        "title" => StatusHelper::getStepTitle($step),
        "order" => StatusHelper::getStepOrder($step),
        "isCompleted" => $isCompleted,
        "completedAt" => $completedAt,
        "hasConcern" => $hasConcern,
        "notes" => $notes,
        "concern" => null
    ];
    
    // Show pending concern first; else show latest concern (pending or resolved) for this step
    $concern = null;
    foreach ($statusIdsWithConcern as $sid) {
        $concern = StatusHelper::getPendingConcern($conn, $sid);
        if ($concern) {
            break;
        }
    }
    if (!$concern && !empty($statusIdsWithConcern)) {
        $concern = StatusHelper::getLatestConcernForStatusIds($conn, $statusIdsWithConcern);
    }
    if ($concern) {
        $stepObj["concern"] = [
            "id" => (int)$concern['id'],
            "type" => $concern['concern_type'] ?? null,
            "message" => $concern['concern_text'] ?? null,
            "status" => $concern['status'] ?? null,
            "createdAt" => $concern['created_at'] ?? null,
            "imageUrl" => !empty($concern['concern_image_path']) ? $concern['concern_image_path'] : null
        ];
    }
    
    $statusSteps[] = $stepObj;
}

// (overallStatus, currentStep, progressPercentage and itrStatus are built after payment/assignment so we can apply fallbacks)

// =====================================================
// 2. GET PAYMENT STATUS
// =====================================================
$paymentStatus = null;
// Prefer direct lookup by orderId + userId when orderId is known
if ($orderId) {
    $orderIdEscaped = mysqli_real_escape_string($conn, $orderId);
    $userIdEscaped = mysqli_real_escape_string($conn, (string)$userId);
    $paymentSql = "SELECT * FROM payment_info WHERE order_id = '$orderIdEscaped' AND user_id = '$userIdEscaped' LIMIT 1";
    $paymentResult = $conn->query($paymentSql);
} elseif ($itrId) {
    // If only itrId is known, resolve payment via itr_detail (userId + pan_number)
    $paymentResult = null;
    $itrIdEscaped = (int)$itrId;
    $itrLookupSql = "SELECT userId, panNumber FROM itr_detail WHERE id = $itrIdEscaped LIMIT 1";
    $itrLookupResult = $conn->query($itrLookupSql);
    if ($itrLookupResult && $itrLookupResult->num_rows > 0) {
        $itrLookup = $itrLookupResult->fetch_assoc();
        $itrUserId = mysqli_real_escape_string($conn, $itrLookup['userId']);
        $itrPan = mysqli_real_escape_string($conn, $itrLookup['panNumber']);
        $paymentSql = "SELECT * FROM payment_info 
                       WHERE user_id = '$itrUserId' 
                       AND pan_number = '$itrPan'
                       ORDER BY created_at DESC
                       LIMIT 1";
        $paymentResult = $conn->query($paymentSql);
    }
} else {
    $paymentResult = null;
}

if ($paymentResult && $paymentResult->num_rows > 0) {
    $payment = $paymentResult->fetch_assoc();
    $paymentStatus = [
        "paymentId" => $payment['payment_id'] ?? null,
        "orderId" => $payment['order_id'] ?? null,
        "amount" => isset($payment['grand_total']) ? floatval($payment['grand_total']) : null,
        "gst" => isset($payment['gst_amount']) ? floatval($payment['gst_amount']) : null,
        "grandTotal" => isset($payment['grand_total']) ? floatval($payment['grand_total']) : null,
        "status" => $payment['payment_status'] ?? null,
        "paymentMethod" => $payment['payment_method'] ?? null,
        "gatewayName" => $payment['gateway_name'] ?? null,
        "transactionId" => $payment['transaction_id'] ?? null,
        "paidAt" => $payment['paid_at'] ?? null,
        "createdAt" => $payment['created_at'] ?? $payment['createdAt'] ?? null,
        "failureReason" => $payment['failure_reason'] ?? null
    ];
    
    // Update orderId if not provided
    if (!$orderId && !empty($payment['order_id'])) {
        $orderId = $payment['order_id'];
    }
}

// =====================================================
// 3. GET ASSIGNMENT STATUS
// =====================================================
$assignmentStatus = null;
// Resolve itrId from order when itrId is missing, so assignment details still work.
if (!$itrId && $paymentStatus && !empty($paymentStatus['orderId'])) {
    $orderIdEscaped = mysqli_real_escape_string($conn, $paymentStatus['orderId']);
    $paymentLookupSql = "SELECT user_id, pan_number FROM payment_info WHERE order_id = '$orderIdEscaped' LIMIT 1";
    $paymentLookupResult = $conn->query($paymentLookupSql);
    if ($paymentLookupResult && $paymentLookupResult->num_rows > 0) {
        $paymentLookup = $paymentLookupResult->fetch_assoc();
        if (!empty($paymentLookup['user_id']) && !empty($paymentLookup['pan_number'])) {
            $itrLookupSql = "SELECT id FROM itr_detail 
                             WHERE userId = " . (int)$paymentLookup['user_id'] . "
                             AND panNumber = '" . mysqli_real_escape_string($conn, $paymentLookup['pan_number']) . "'
                             ORDER BY id DESC
                             LIMIT 1";
            $itrLookupResult = $conn->query($itrLookupSql);
            if ($itrLookupResult && $itrLookupResult->num_rows > 0) {
                $itrId = (int)$itrLookupResult->fetch_assoc()['id'];
            }
        }
    }
}
if ($itrId) {
    $itrIdEscaped = (int)$itrId;
    // Support both schemas: assigned_to/assigned_at/is_active OR professional_id/assignment_date
    $colCheck = $conn->query("SHOW COLUMNS FROM itr_assignments WHERE Field IN ('assigned_to', 'professional_id', 'assigned_at', 'assignment_date', 'is_active')");
    $cols = [];
    if ($colCheck && $colCheck->num_rows > 0) {
        while ($r = $colCheck->fetch_assoc()) {
            $cols[$r['Field']] = true;
        }
    }
    $profCol = isset($cols['assigned_to']) ? 'assigned_to' : 'professional_id';
    $dateCol = isset($cols['assigned_at']) ? 'assigned_at' : 'assignment_date';
    $activeClause = isset($cols['is_active']) ? " AND ia.is_active = 1" : "";
    $assignmentSql = "SELECT ia.*, u.FirstName, u.LastName, u.Email, u.Mobile, u.Role
                      FROM itr_assignments ia
                      LEFT JOIN users u ON u.UserId = ia.$profCol
                      WHERE ia.itr_id = $itrIdEscaped $activeClause
                      LIMIT 1";
    $assignmentResult = $conn->query($assignmentSql);
    if ($assignmentResult && $assignmentResult->num_rows > 0) {
        $assignment = $assignmentResult->fetch_assoc();
        $profId = (int)($assignment[$profCol] ?? $assignment['assigned_to'] ?? $assignment['professional_id'] ?? 0);
        $assignmentStatus = [
            "assignmentId" => (int)($assignment['id'] ?? 0),
            "professionalId" => $profId,
            "professionalName" => trim(($assignment['FirstName'] ?? '') . ' ' . ($assignment['LastName'] ?? '')),
            "professionalEmail" => $assignment['Email'] ?? null,
            "professionalMobile" => $assignment['Mobile'] ?? null,
            "professionalRole" => $assignment['Role'] ?? null,
            "status" => $assignment['status'] ?? null,
            "priority" => $assignment['priority'] ?? null,
            "assignedAt" => $assignment[$dateCol] ?? $assignment['assigned_at'] ?? $assignment['assignment_date'] ?? null,
            "dueDate" => $assignment['due_date'] ?? null,
            "completedAt" => $assignment['completed_at'] ?? null,
            "notes" => $assignment['notes'] ?? null
        ];
    }
}

// =====================================================
// 4. GET ITR DETAILS
// =====================================================
$itrDetails = null;
if ($itrId) {
    $itrIdEscaped = (int)$itrId;
    // Avoid JOIN to packages table so this works when packages table does not exist
    $itrSql = "SELECT 
                 itr.*,
                 pd.FirstName,
                 pd.LastName,
                 pd.EMAIL,
                 pd.MobileNumber,
                 pd.FinancialYear,
                 NULL as package_name,
                 COUNT(DISTINCT dd.id) as documents_count
               FROM itr_detail itr
               LEFT JOIN personal_details pd ON itr.userId = pd.UserId AND itr.panNumber = pd.PANNumber
               LEFT JOIN document_details dd ON itr.userId = dd.UserId AND itr.panNumber = dd.PanNumber AND dd.isActive = 1
               WHERE itr.id = $itrIdEscaped
               GROUP BY itr.id
               LIMIT 1";
    
    $itrResult = $conn->query($itrSql);
    if ($itrResult && $itrResult->num_rows > 0) {
        $itr = $itrResult->fetch_assoc();
        $itrDetails = [
            "itrId" => (int)$itr['id'],
            "userId" => (int)($itr['userId'] ?? 0),
            "panNumber" => $itr['panNumber'] ?? null,
            "firstName" => $itr['FirstName'] ?? null,
            "lastName" => $itr['LastName'] ?? null,
            "email" => $itr['EMAIL'] ?? null,
            "mobile" => $itr['MobileNumber'] ?? null,
            "financialYear" => $itr['FinancialYear'] ?? null,
            "packageId" => !empty($itr['package_id']) ? (int)$itr['package_id'] : null,
            "packageName" => $itr['package_name'] ?? null,
            "documentsCount" => (int)($itr['documents_count'] ?? 0),
            "createdAt" => $itr['createdAt'] ?? $itr['created_at'] ?? null
        ];
    }
}

// =====================================================
// FALLBACK: Derive step completion from payment_info / assignment when itr_order_status has no row
// =====================================================
foreach ($statusSteps as &$stepObj) {
    if ($stepObj['step'] === 'payment_success' && !$stepObj['isCompleted'] && $paymentStatus && isset($paymentStatus['status']) && strtolower($paymentStatus['status']) === 'success') {
        $stepObj['isCompleted'] = true;
        $stepObj['completedAt'] = $paymentStatus['paidAt'] ?? null;
    }
    if ($stepObj['step'] === 'expert_assigned' && !$stepObj['isCompleted'] && $assignmentStatus) {
        $stepObj['isCompleted'] = true;
        $stepObj['completedAt'] = $assignmentStatus['assignedAt'] ?? null;
    }
}
unset($stepObj);

// Recompute overall status, current step and progress from (possibly updated) steps
$currentStep = 0;
foreach ($statusSteps as $s) {
    if (!empty($s['isCompleted'])) {
        $orderNum = StatusHelper::getStepOrder($s['step']);
        if ($orderNum > $currentStep) {
            $currentStep = $orderNum;
        }
    }
}
$allCompleted = true;
$hasPendingConcern = false;
$anyInProgress = false;
foreach ($statusSteps as $s) {
    if (!$s['isCompleted']) {
        $allCompleted = false;
        $anyInProgress = true;
    }
    if (!empty($s['hasConcern'])) {
        $hasPendingConcern = true;
    }
}
$overallStatus = $allCompleted ? 'completed' : ($hasPendingConcern ? 'concern_pending' : ($anyInProgress ? 'in_progress' : 'pending'));
$progressPercentage = count($allSteps) > 0 ? ($currentStep / count($allSteps)) * 100 : 0;
$itrStatus = [
    "steps" => $statusSteps,
    "overallStatus" => $overallStatus,
    "currentStep" => $currentStep,
    "totalSteps" => count($allSteps),
    "progressPercentage" => round($progressPercentage, 2)
];

// =====================================================
// BUILD FINAL RESPONSE
// =====================================================
$orderIdValue = $orderId;
$itrIdValue = $itrId;

if (!$orderIdValue && $steps) {
    $orderIdValue = $steps[0]['order_id'] ?? null;
}
if (!$itrIdValue && $steps) {
    $itrIdValue = $steps[0]['itr_id'] ?? null;
}

// Get PAN number
$panNumber = null;
if ($itrDetails) {
    $panNumber = $itrDetails['panNumber'];
} else if ($steps && !empty($steps)) {
    $panNumber = $steps[0]['pan_number'] ?? null;
}

// =====================================================
// 5. GET STATUS UPDATES / CONCERNS (from admin PUT itrs.php – status_id NULL, concern_type status_update)
// Match by user_id + itr_id from request so client gets concerns for the ITR they asked for.
// =====================================================
$statusUpdates = [];
if ($userId) {
    $userVal = mysqli_real_escape_string($conn, (string)$userId);
    $itrIdFromRequest = isset($_GET['itrId']) && $_GET['itrId'] !== '' ? (int)$_GET['itrId'] : null;
    $effectiveItrId = $itrIdFromRequest ?: (!empty($itrId) ? (int)$itrId : null);
    $concernsResult = null;
    if ($effectiveItrId) {
        $itrVal = (int)$effectiveItrId;
        $concernsSql = "SELECT id, concern_type, concern_text, status, resolved_at, resolved_by, created_at
                        FROM itr_order_concerns
                        WHERE itr_id = $itrVal AND user_id = '$userVal' AND concern_type = 'status_update'
                        ORDER BY created_at DESC
                        LIMIT 50";
        $concernsResult = $conn->query($concernsSql);
        if ($concernsResult === false && $conn->error && (stripos($conn->error, 'itr_id') !== false || stripos($conn->error, 'Unknown column') !== false)) {
            $concernsSql = "SELECT id, concern_type, concern_text, status, resolved_at, resolved_by, created_at
                            FROM itr_order_concerns
                            WHERE user_id = '$userVal' AND (status_id IS NULL OR status_id = 0) AND concern_type = 'status_update'
                            ORDER BY created_at DESC
                            LIMIT 50";
            $concernsResult = $conn->query($concernsSql);
        }
    } else {
        $concernsSql = "SELECT id, concern_type, concern_text, status, resolved_at, resolved_by, created_at
                        FROM itr_order_concerns
                        WHERE user_id = '$userVal' AND (status_id IS NULL OR status_id = 0) AND concern_type = 'status_update'
                        ORDER BY created_at DESC
                        LIMIT 50";
        $concernsResult = $conn->query($concernsSql);
    }
    if ($concernsResult && $concernsResult->num_rows > 0) {
        while ($row = $concernsResult->fetch_assoc()) {
            $statusUpdates[] = [
                "id" => (int)$row['id'],
                "message" => $row['concern_text'] ?? null,
                "status" => $row['status'] ?? null,
                "createdAt" => $row['created_at'] ?? null,
                "resolvedAt" => $row['resolved_at'] ?? null,
                "resolvedBy" => !empty($row['resolved_by']) ? (int)$row['resolved_by'] : null
            ];
        }
    }
}

$responseData = [
    "orderId" => $orderIdValue,
    "itrId" => $itrIdValue ? (int)$itrIdValue : null,
    "userId" => (int)$userId,
    "panNumber" => $panNumber,
    "itrStatus" => $itrStatus,
    "paymentStatus" => $paymentStatus,
    "assignmentStatus" => $assignmentStatus,
    "itrDetails" => $itrDetails,
    "statusUpdates" => $statusUpdates
];
if ($debugMode) {
    $responseData["_debug"] = [ "statusUpdatesCount" => count($statusUpdates) ];
}
http_response_code(200);
echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" => $responseData
], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    if ($debugMode) {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => [
                "message" => "Server error (debug)",
                "error" => $e->getMessage(),
                "file" => $e->getFile(),
                "line" => $e->getLine()
            ]
        ], JSON_UNESCAPED_UNICODE);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "An error occurred. Add ?debug=1 to the URL to see details."]
        ], JSON_UNESCAPED_UNICODE);
    }
}
exit;
?>
