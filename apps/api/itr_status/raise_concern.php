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

// Get request data (can be JSON or form-data for file uploads)
$orderId = null;
$itrId = null;
$statusStep = null;
$concernType = null;
$concernText = null;
$imageFile = null;

// Check if it's multipart/form-data (file upload)
if (isset($_POST['orderId']) || isset($_POST['itrId'])) {
    // Form data
    $orderId = $_POST['orderId'] ?? null;
    $itrId = $_POST['itrId'] ?? null;
    $statusStep = $_POST['statusStep'] ?? null;
    $concernType = $_POST['concernType'] ?? 'text';
    $concernText = $_POST['concernText'] ?? null;
    
    if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $imageFile = $_FILES['image'];
        $concernType = 'image';
    }
} else {
    // JSON data
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
    
    $orderId = $data['orderId'] ?? null;
    $itrId = $data['itrId'] ?? null;
    $statusStep = $data['statusStep'] ?? null;
    $concernType = $data['concernType'] ?? 'text';
    $concernText = $data['concernText'] ?? null;
}

// Validation
if (!$orderId && !$itrId) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "orderId or itrId is required"]
    ]);
    exit;
}

if (!$statusStep) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "statusStep is required"]
    ]);
    exit;
}

// Validate status step
$validSteps = StatusHelper::getAllSteps();
if (!in_array($statusStep, $validSteps)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "Invalid statusStep. Valid values: " . implode(", ", $validSteps)]
    ]);
    exit;
}

// Validate concern type
if (!in_array($concernType, ['text', 'image'])) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "concernType must be 'text' or 'image'"]
    ]);
    exit;
}

// Validate concern content
if ($concernType === 'text' && empty($concernText)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "concernText is required for text concerns"]
    ]);
    exit;
}

if ($concernType === 'image' && !$imageFile) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "Image file is required for image concerns"]
    ]);
    exit;
}

// Escape inputs
$userIdEscaped = mysqli_real_escape_string($conn, $userId);
$orderIdEscaped = $orderId ? mysqli_real_escape_string($conn, $orderId) : null;
$itrIdEscaped = $itrId ? (int)$itrId : null;
$statusStepEscaped = mysqli_real_escape_string($conn, $statusStep);

// Find the status step record
$whereClause = "user_id = '$userIdEscaped' AND status_step = '$statusStepEscaped'";
if ($orderIdEscaped) {
    $whereClause .= " AND order_id = '$orderIdEscaped'";
}
if ($itrIdEscaped) {
    $whereClause .= " AND itr_id = $itrIdEscaped";
}

$statusSql = "SELECT * FROM itr_order_status WHERE $whereClause LIMIT 1";
$statusResult = $conn->query($statusSql);

$statusId = null;
if ($statusResult && $statusResult->num_rows > 0) {
    $statusData = $statusResult->fetch_assoc();
    $statusId = $statusData['id'];
} else {
    // Create status step if it doesn't exist
    $orderIdValue = $orderIdEscaped ? "'$orderIdEscaped'" : 'NULL';
    $itrIdValue = $itrIdEscaped ? $itrIdEscaped : 'NULL';
    
    $createStatusSql = "INSERT INTO itr_order_status 
        (order_id, itr_id, user_id, status_step, is_completed, has_concern, created_at, updated_at)
        VALUES 
        ($orderIdValue, $itrIdValue, '$userIdEscaped', '$statusStepEscaped', 0, 1, NOW(), NOW())";
    
    if ($conn->query($createStatusSql)) {
        $statusId = $conn->insert_id;
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to create status step: " . $conn->error]
        ]);
        exit;
    }
}

// Handle image upload if present
$imagePath = null;
if ($concernType === 'image' && $imageFile) {
    $uploadDir = __DIR__ . '/../uploads/concerns/';
    $identifier = $orderIdEscaped ? $orderIdEscaped : ($itrIdEscaped ? "itr_" . $itrIdEscaped : "user_" . $userIdEscaped);
    $targetDir = $uploadDir . $identifier . '/';
    
    if (!is_dir($targetDir)) {
        mkdir($targetDir, 0777, true);
    }
    
    $extension = strtolower(pathinfo($imageFile['name'], PATHINFO_EXTENSION));
    $allowedTypes = ['jpg', 'jpeg', 'png', 'pdf'];
    
    if (!in_array($extension, $allowedTypes)) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "Invalid file type. Allowed: jpg, jpeg, png, pdf"]
        ]);
        exit;
    }
    
    $uniqueName = uniqid("concern_", true) . "." . $extension;
    $targetFile = $targetDir . $uniqueName;
    
    if (move_uploaded_file($imageFile['tmp_name'], $targetFile)) {
        // Store relative path
        $imagePath = "uploads/concerns/" . $identifier . "/" . $uniqueName;
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to upload image"]
        ]);
        exit;
    }
}

// Insert concern record
$concernTextEscaped = $concernText ? "'" . mysqli_real_escape_string($conn, $concernText) . "'" : 'NULL';
$imagePathEscaped = $imagePath ? "'" . mysqli_real_escape_string($conn, $imagePath) . "'" : 'NULL';
$orderIdValue = $orderIdEscaped ? "'$orderIdEscaped'" : 'NULL';
$itrIdValue = $itrIdEscaped ? $itrIdEscaped : 'NULL';

$insertConcernSql = "INSERT INTO itr_order_concerns 
    (status_id, order_id, itr_id, user_id, concern_type, concern_text, concern_image_path, status, created_at, updated_at)
    VALUES 
    ($statusId, $orderIdValue, $itrIdValue, '$userIdEscaped', '$concernType', $concernTextEscaped, $imagePathEscaped, 'pending', NOW(), NOW())";

if ($conn->query($insertConcernSql)) {
    $concernId = $conn->insert_id;
    
    // Update status step to mark has_concern
    $updateStatusSql = "UPDATE itr_order_status SET has_concern = 1, is_completed = 0, updated_at = NOW() WHERE id = $statusId";
    $conn->query($updateStatusSql);
    
    // Fetch created concern
    $concernSql = "SELECT * FROM itr_order_concerns WHERE id = $concernId";
    $concernResult = $conn->query($concernSql);
    $concern = $concernResult->fetch_assoc();
    
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "message" => "Concern raised successfully",
            "concern" => [
                "id" => (int)$concern['id'],
                "type" => $concern['concern_type'],
                "message" => $concern['concern_text'],
                "status" => $concern['status'],
                "createdAt" => $concern['created_at'],
                "imageUrl" => $concern['concern_image_path'] ? $concern['concern_image_path'] : null
            ]
        ]
    ], JSON_UNESCAPED_UNICODE);
} else {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Failed to create concern: " . $conn->error]
    ]);
}
exit;
?>

