<?php
// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

require '../include/config.php';
require '../phpjwt/Token.php';
require 'StatusHelper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only POST allowed"]
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

// Get request data
$input = file_get_contents("php://input");
$data = json_decode($input, true);

if (!$data) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "Invalid JSON data"]
    ]);
    exit;
}

$concernId = $data['concernId'] ?? null;
$status = $data['status'] ?? null; // 'resolved' or 'rejected'
$resolutionNotes = $data['resolutionNotes'] ?? null;

// Validation
if (!$concernId) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "concernId is required"]
    ]);
    exit;
}

if (!$status || !in_array($status, ['resolved', 'rejected'])) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "status is required and must be 'resolved' or 'rejected'"]
    ]);
    exit;
}

// Escape inputs
$concernIdEscaped = (int)$concernId;
$statusEscaped = mysqli_real_escape_string($conn, $status);
$resolutionNotesEscaped = $resolutionNotes ? "'" . mysqli_real_escape_string($conn, $resolutionNotes) . "'" : 'NULL';
$userIdEscaped = mysqli_real_escape_string($conn, $userId);

// Check if concern exists
$checkSql = "SELECT * FROM itr_order_concerns WHERE id = $concernIdEscaped";
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
    "status = '$statusEscaped'",
    "resolved_at = NOW()",
    "resolved_by = '$userIdEscaped'",
    "updated_at = NOW()"
];

if ($resolutionNotesEscaped !== 'NULL') {
    $updateFields[] = "resolution_notes = $resolutionNotesEscaped";
}

$updateSql = "UPDATE itr_order_concerns SET " . implode(", ", $updateFields) . " WHERE id = $concernIdEscaped";

if ($conn->query($updateSql)) {
    // Check if there are any other pending concerns for this status step
    $pendingCheckSql = "SELECT COUNT(*) as count FROM itr_order_concerns WHERE status_id = $statusId AND status = 'pending'";
    $pendingResult = $conn->query($pendingCheckSql);
    $pendingData = $pendingResult->fetch_assoc();
    
    // If no pending concerns, update status step
    if ($pendingData['count'] == 0) {
        $updateStatusSql = "UPDATE itr_order_status SET has_concern = 0, updated_at = NOW() WHERE id = $statusId";
        $conn->query($updateStatusSql);
    }
    
    // Fetch updated concern
    $updatedSql = "SELECT * FROM itr_order_concerns WHERE id = $concernIdEscaped";
    $updatedResult = $conn->query($updatedSql);
    $updatedConcern = $updatedResult->fetch_assoc();
    
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "message" => "Concern resolved successfully",
            "concern" => [
                "id" => (int)$updatedConcern['id'],
                "type" => $updatedConcern['concern_type'],
                "message" => $updatedConcern['concern_text'],
                "status" => $updatedConcern['status'],
                "createdAt" => $updatedConcern['created_at'],
                "resolvedAt" => $updatedConcern['resolved_at'],
                "resolutionNotes" => $updatedConcern['resolution_notes'],
                "imageUrl" => $updatedConcern['concern_image_path'] ? $updatedConcern['concern_image_path'] : null
            ]
        ]
    ], JSON_UNESCAPED_UNICODE);
} else {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Failed to resolve concern: " . $conn->error]
    ]);
}
exit;
?>

