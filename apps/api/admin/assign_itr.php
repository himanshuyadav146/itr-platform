<?php
/**
 * Admin Assign ITR API
 * Assign ITR to associate/professional (users with Role='ACCOUNTANT' or 'CA')
 * 
 * Endpoints: 
 * - POST /admin/assign_itr.php - Assign ITR to professional
 */

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

// Handle OPTIONS preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require '../include/config.php';
require '../phpjwt/Token.php';
require '../itr_status/StatusHelper.php';
require_once '../include/NotificationDispatcher.php';

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

// POST - Assign ITR to professional
if ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "Invalid JSON input"]
        ]);
        exit;
    }
    
    // Validate required fields
    $itrId = $input['itrId'] ?? null;
    $professionalId = $input['professionalId'] ?? null;
    
    if (!$itrId || !$professionalId) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "itrId and professionalId are required"]
        ]);
        exit;
    }
    
    // Escape inputs
    $itrIdEscaped = mysqli_real_escape_string($conn, $itrId);
    $professionalIdEscaped = mysqli_real_escape_string($conn, $professionalId);
    $assignedBy = $decoded['UserId'] ?? null;
    $assignedByEscaped = $assignedBy ? mysqli_real_escape_string($conn, $assignedBy) : 'NULL';
    
    // Check if ITR exists
    $itrCheckSql = "SELECT id, userId FROM itr_detail WHERE id = '$itrIdEscaped'";
    $itrCheckResult = $conn->query($itrCheckSql);
    
    if (!$itrCheckResult || $itrCheckResult->num_rows === 0) {
        http_response_code(404);
        echo json_encode([
            "status" => "error",
            "statusCode" => 404,
            "data" => ["message" => "ITR not found"]
        ]);
        exit;
    }
    
    // Check if professional exists and has correct role (ACCOUNTANT or CA)
    $profCheckSql = "SELECT UserId, Role FROM users WHERE UserId = '$professionalIdEscaped' AND Role IN ('ACCOUNTANT', 'CA')";
    $profCheckResult = $conn->query($profCheckSql);
    if (!$profCheckResult || $profCheckResult->num_rows === 0) {
        http_response_code(404);
        echo json_encode([
            "status" => "error",
            "statusCode" => 404,
            "data" => ["message" => "Professional not found or doesn't have ACCOUNTANT/CA role"]
        ]);
        exit;
    }
    
    // Check if ITR already has an active assignment
    $existingCheckSql = "SELECT id FROM itr_assignments WHERE itr_id = '$itrIdEscaped' AND is_active = 1";
    $existingCheckResult = $conn->query($existingCheckSql);
    if ($existingCheckResult && $existingCheckResult->num_rows > 0) {
        http_response_code(409);
        echo json_encode([
            "status" => "error",
            "statusCode" => 409,
            "data" => ["message" => "ITR already has an active assignment"]
        ]);
        exit;
    }
    
    // Insert assignment (using actual table columns: assigned_to, assigned_at, is_active)
    $assignedByValue = $assignedByEscaped !== 'NULL' ? "'$assignedByEscaped'" : 'NULL';
    $sql = "INSERT INTO itr_assignments (itr_id, assigned_to, assigned_by, assigned_at, is_active)
            VALUES ('$itrIdEscaped', '$professionalIdEscaped', $assignedByValue, NOW(), 1)";
    
    if ($conn->query($sql)) {
        $assignmentId = $conn->insert_id;
        // Record expert_assigned step in itr_order_status so get_detailed_status shows it
        $itrCheckResult->data_seek(0);
        $itrRow = $itrCheckResult->fetch_assoc();
        $panForStatus = null;
        $orderIdForStatus = null;
        if ($itrRow) {
            $clientUserId = mysqli_real_escape_string($conn, $itrRow['userId']);
            $orderIdForStatus = null;
            $panForStatus = null;
            $paySql = "SELECT order_id, pan_number FROM payment_info WHERE user_id = '$clientUserId' AND payment_status = 'success' ORDER BY paid_at DESC LIMIT 1";
            $payResult = $conn->query($paySql);
            if ($payResult && $payResult->num_rows > 0) {
                $payRow = $payResult->fetch_assoc();
                $orderIdForStatus = $payRow['order_id'] ?? null;
                $panForStatus = $payRow['pan_number'] ?? null;
            }
            if ($orderIdForStatus) {
                $orderIdEscapedStatus = mysqli_real_escape_string($conn, $orderIdForStatus);
                StatusHelper::updateStatusStep(
                    $conn,
                    $orderIdEscapedStatus,
                    (int)$itrId,
                    $clientUserId,
                    null,
                    $panForStatus,
                    'expert_assigned',
                    true,
                    'Assigned to professional'
                );
            }
        }
        notifyWorkflowEvent($conn, 'expert.assigned', [
            'itrId' => $itrId,
            'professionalId' => $professionalId,
            'userId' => $itrRow['userId'] ?? null,
            'pan' => $panForStatus ?? '',
            'orderId' => $orderIdForStatus,
        ]);
        http_response_code(201);
        echo json_encode([
            "status" => "success",
            "statusCode" => 201,
            "data" => [
                "message" => "ITR assigned successfully",
                "assignmentId" => $assignmentId
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Error assigning ITR: " . $conn->error]
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
