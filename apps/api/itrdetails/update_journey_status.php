<?php
/**
 * Update Journey Status Endpoint
 * Updates the status and current step of a user journey
 * 
 * Usage: POST /itrdetails/update_journey_status.php
 * Body: {
 *   "journeyId": 123,
 *   "status": "completed",  // initiated, in_progress, completed, cancelled
 *   "currentStep": "payment",  // optional
 *   "metadata": {...}  // optional JSON data
 * }
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

// Only POST allowed
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only POST requests are allowed"]
    ]);
    exit;
}

// Read JSON input
$input = file_get_contents("php://input");
$data = json_decode($input, true);

// Extract Bearer token
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
        "data" => ["message" => "Authorization token is required"]
    ]);
    exit;
}

// Verify token
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

// Get UserId from token
$UserId = $decoded['UserId'] ?? null;

if (!$UserId) {
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" => ["message" => "User ID not found in token"]
    ]);
    exit;
}

$UserId = (int)$UserId;

// Validate required fields
$journeyId = isset($data['journeyId']) ? (int)$data['journeyId'] : null;
$status = trim($data['status'] ?? '');

if (!$journeyId) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "journeyId is required"]
    ]);
    exit;
}

// Validate status
$validStatuses = ['initiated', 'in_progress', 'completed', 'cancelled'];
if (!empty($status) && !in_array($status, $validStatuses)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "Invalid status. Must be one of: initiated, in_progress, completed, cancelled"]
    ]);
    exit;
}

// Verify journey belongs to this user
$checkSql = "SELECT id FROM user_journey WHERE id = '$journeyId' AND userId = '$UserId'";
$checkResult = $conn->query($checkSql);

if (!$checkResult || $checkResult->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "status" => "error",
        "statusCode" => 404,
        "data" => ["message" => "Journey not found or does not belong to this user"]
    ]);
    exit;
}

// Build update query
$updateParts = [];
$updateParts[] = "updatedAt = NOW()";

if (!empty($status)) {
    $status = mysqli_real_escape_string($conn, $status);
    $updateParts[] = "status = '$status'";
    
    // If status is completed, set completedAt
    if ($status === 'completed') {
        $updateParts[] = "completedAt = NOW()";
    }
}

// Optional: update current step
$currentStep = trim($data['currentStep'] ?? '');
if (!empty($currentStep)) {
    $currentStep = mysqli_real_escape_string($conn, $currentStep);
    $updateParts[] = "currentStep = '$currentStep'";
}

// Optional: update metadata
if (isset($data['metadata']) && is_array($data['metadata'])) {
    $metadata = json_encode($data['metadata']);
    $metadata = mysqli_real_escape_string($conn, $metadata);
    $updateParts[] = "metadata = '$metadata'";
}

$updateSql = "UPDATE user_journey SET " . implode(', ', $updateParts) . " WHERE id = '$journeyId'";

if ($conn->query($updateSql)) {
    // Fetch updated journey
    $fetchSql = "SELECT 
                    id,
                    userId,
                    panNumber,
                    journeyType,
                    status,
                    currentStep,
                    metadata,
                    startedAt,
                    completedAt,
                    updatedAt
                FROM user_journey
                WHERE id = '$journeyId'";
    
    $result = $conn->query($fetchSql);
    
    if ($result && $result->num_rows > 0) {
        $journey = $result->fetch_assoc();
        
        // Parse JSON metadata
        if (!empty($journey['metadata'])) {
            $journey['metadata'] = json_decode($journey['metadata'], true);
        }
        
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "message" => "Journey updated successfully",
                "journey" => $journey
            ]
        ]);
    } else {
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => ["message" => "Journey updated successfully"]
        ]);
    }
} else {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Error updating journey: " . $conn->error]
    ]);
}
?>
