<?php
// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

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

// Get status steps
$steps = StatusHelper::getStatusSteps($conn, $orderId, $itrId, $userId);

// Get all possible steps
$allSteps = StatusHelper::getAllSteps();

// Build response with all steps
$statusSteps = [];
foreach ($allSteps as $step) {
    // Find if this step exists in database
    $stepData = null;
    foreach ($steps as $dbStep) {
        if ($dbStep['status_step'] === $step) {
            $stepData = $dbStep;
            break;
        }
    }
    
    // Build step object
    $stepObj = [
        "step" => $step,
        "title" => StatusHelper::getStepTitle($step),
        "isCompleted" => $stepData ? (bool)$stepData['is_completed'] : false,
        "completedAt" => $stepData && $stepData['completed_at'] ? $stepData['completed_at'] : null,
        "order" => StatusHelper::getStepOrder($step),
        "hasConcern" => $stepData ? (bool)$stepData['has_concern'] : false,
        "concern" => null
    ];
    
    // Add notes if available
    if ($stepData && $stepData['notes']) {
        $stepObj["notes"] = $stepData['notes'];
    }
    
    // Get pending concern if exists
    if ($stepData && $stepData['has_concern']) {
        $concern = StatusHelper::getPendingConcern($conn, $stepData['id']);
        if ($concern) {
            $stepObj["concern"] = [
                "id" => (int)$concern['id'],
                "type" => $concern['concern_type'],
                "message" => $concern['concern_text'],
                "status" => $concern['status'],
                "createdAt" => $concern['created_at'],
                "imageUrl" => $concern['concern_image_path'] ? $concern['concern_image_path'] : null
            ];
        }
    }
    
    $statusSteps[] = $stepObj;
}

// Calculate overall status
$overallStatus = StatusHelper::calculateOverallStatus($steps);
$currentStep = StatusHelper::getCurrentStep($steps);

// Get order/itr info for response
$orderIdValue = $orderId;
$itrIdValue = $itrId;

if (!$orderIdValue && $steps) {
    $orderIdValue = $steps[0]['order_id'] ?? null;
}
if (!$itrIdValue && $steps) {
    $itrIdValue = $steps[0]['itr_id'] ?? null;
}

http_response_code(200);
echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" => [
        "orderId" => $orderIdValue,
        "itrId" => $itrIdValue ? (int)$itrIdValue : null,
        "statusSteps" => $statusSteps,
        "overallStatus" => $overallStatus,
        "currentStep" => $currentStep,
        "totalSteps" => count($allSteps)
    ]
], JSON_UNESCAPED_UNICODE);
exit;
?>

