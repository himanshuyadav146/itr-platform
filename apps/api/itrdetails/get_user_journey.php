<?php
/**
 * Get User Journey Endpoint
 * Retrieves user journey information for tracking progress
 * 
 * Usage: 
 * - GET /itrdetails/get_user_journey.php?journeyType=ITR
 * - GET /itrdetails/get_user_journey.php?journeyId=123
 * - GET /itrdetails/get_user_journey.php (all journeys for user)
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

// Only GET allowed
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only GET requests are allowed"]
    ]);
    exit;
}

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

// Get query parameters
$journeyId = isset($_GET['journeyId']) ? (int)$_GET['journeyId'] : null;
$journeyType = isset($_GET['journeyType']) ? trim($_GET['journeyType']) : null;
$panNumber = isset($_GET['panNumber']) ? trim($_GET['panNumber']) : null;
$status = isset($_GET['status']) ? trim($_GET['status']) : null;

// Build query
$sql = "SELECT 
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
        WHERE userId = '$UserId'";

if ($journeyId) {
    $journeyId = mysqli_real_escape_string($conn, $journeyId);
    $sql .= " AND id = '$journeyId'";
}

if ($journeyType) {
    $journeyType = mysqli_real_escape_string($conn, $journeyType);
    $sql .= " AND journeyType = '$journeyType'";
}

if ($panNumber) {
    $panNumber = mysqli_real_escape_string($conn, $panNumber);
    $sql .= " AND panNumber = '$panNumber'";
}

if ($status) {
    $status = mysqli_real_escape_string($conn, $status);
    $sql .= " AND status = '$status'";
}

$sql .= " ORDER BY updatedAt DESC";

$result = $conn->query($sql);

if ($result === false) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Database query error: " . $conn->error]
    ]);
    exit;
}

if ($result->num_rows > 0) {
    $journeys = [];
    
    while ($row = $result->fetch_assoc()) {
        // Parse JSON metadata if exists
        if (!empty($row['metadata'])) {
            $row['metadata'] = json_decode($row['metadata'], true);
        }
        $journeys[] = $row;
    }
    
    // If specific journey requested, return single object
    if ($journeyId) {
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "journey" => $journeys[0]
            ]
        ]);
    } else {
        // Return array of journeys
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "journeys" => $journeys,
                "count" => count($journeys)
            ]
        ]);
    }
} else {
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "journeys" => [],
            "count" => 0,
            "message" => "No journeys found"
        ]
    ]);
}
?>
