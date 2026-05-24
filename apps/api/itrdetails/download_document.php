<?php
/**
 * Document Download Endpoint
 * Secure document download with authentication
 * 
 * Usage: /itrdetails/download_document.php?docId={document_id}
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

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

// Get document ID from query
$docId = isset($_GET['docId']) ? intval($_GET['docId']) : 0;

if ($docId <= 0) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "Document ID is required"]
    ]);
    exit;
}

// Get userId from token
$userId = $decoded['UserId'] ?? null;
if (!$userId) {
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" => ["message" => "User ID not found in token"]
    ]);
    exit;
}

$userId = (int)$userId;
$userIdEscaped = mysqli_real_escape_string($conn, $userId);

// Check if user is admin
$adminCheckSql = "SELECT Role FROM users WHERE UserId = '$userIdEscaped' LIMIT 1";
$adminResult = $conn->query($adminCheckSql);
$isAdmin = false;
if ($adminResult && $adminResult->num_rows > 0) {
    $userRow = $adminResult->fetch_assoc();
    $isAdmin = (strtolower($userRow['Role'] ?? 'user') === 'admin');
}

$docIdEscaped = mysqli_real_escape_string($conn, $docId);

// Fetch document details - admins can access any document, users can only access their own
if ($isAdmin) {
    $sql = "SELECT 
                id,
                UserId,
                PanNumber,
                name,
                type,
                password,
                fileName
            FROM document_details
            WHERE id = '$docIdEscaped'
            LIMIT 1";
} else {
    $sql = "SELECT 
                id,
                UserId,
                PanNumber,
                name,
                type,
                password,
                fileName
            FROM document_details
            WHERE id = '$docIdEscaped'
                AND UserId = '$userIdEscaped'
            LIMIT 1";
}

$result = $conn->query($sql);

if (!$result || $result->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "status" => "error",
        "statusCode" => 404,
        "data" => ["message" => "Document not found or access denied"]
    ]);
    exit;
}

$document = $result->fetch_assoc();

// Construct file path
$uploadDir = __DIR__ . '/../uploads/';
$filePath = $uploadDir . $document['PanNumber'] . '/' . $document['fileName'];

// Check if file exists
if (!file_exists($filePath) || !is_readable($filePath)) {
    http_response_code(404);
    echo json_encode([
        "status" => "error",
        "statusCode" => 404,
        "data" => ["message" => "File not found on server"]
    ]);
    exit;
}

// Get file info
$fileSize = filesize($filePath);
$fileName = $document['name'] . '.' . pathinfo($document['fileName'], PATHINFO_EXTENSION);
$mimeType = mime_content_type($filePath);

// If MIME type detection fails, use default based on extension
if (!$mimeType) {
    $extension = strtolower(pathinfo($document['fileName'], PATHINFO_EXTENSION));
    $mimeTypes = [
        'pdf' => 'application/pdf',
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'doc' => 'application/msword',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ];
    $mimeType = $mimeTypes[$extension] ?? 'application/octet-stream';
}

// Set headers for file download
header("Content-Type: $mimeType");
header("Content-Disposition: attachment; filename=\"" . addslashes($fileName) . "\"");
header("Content-Length: " . $fileSize);
header("Cache-Control: must-revalidate, post-check=0, pre-check=0");
header("Pragma: public");
header("Expires: 0");

// Output file
readfile($filePath);
exit;
?>
