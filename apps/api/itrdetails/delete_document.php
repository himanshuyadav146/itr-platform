<?php
// Allow cross-origin requests (CORS)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

// ONLY POST allowed
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error","statusCode" => 405,
        "data" =>[ "message" => "Only POST request allowed"]]);
    exit;
}

// Read Authorization Token
$headers = getallheaders();
$token = "";

if (isset($headers['Authorization'])) {
    $token = str_replace("Bearer ", "", trim($headers['Authorization']));
}

if (empty($token)) {
    http_response_code(401);
    echo json_encode(["status" => "error","statusCode" => 401,
        "data" =>[ "message" => "Authorization token required"]]);
    exit;
}

// Verify Token
$decoded = Token::Verify($token, $key);
if ($decoded === false) {
    http_response_code(401);
    echo json_encode(["status" => "error","statusCode" => 401,
        "data" =>[ "message" => "Invalid or expired token"]]);
    exit;
}

$UserId = $decoded['UserId'] ?? null;
if (!$UserId) {
    http_response_code(401);
    echo json_encode(["status" => "error", "statusCode" => 401,
        "data" => ["message" => "UserId missing in token"]]);
    exit;
}
$userIdEscaped = mysqli_real_escape_string($conn, (string) $UserId);

// Read input JSON
$input = file_get_contents("php://input");
$data = json_decode($input, true);

if (!isset($data['id']) || !isset($data['PanNumber']) || !isset($data['fileName'])) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" =>[
        "message" => "id, PanNumber and fileName are required"
        ]
    ]);
    exit;
}

$id = mysqli_real_escape_string($conn, $data['id']);
$PanNumber = mysqli_real_escape_string($conn, $data['PanNumber']);

// Check if document exists (scoped to logged-in user)
$check = $conn->query(
    "SELECT id, fileName, PanNumber FROM document_details 
     WHERE id='$id' AND PanNumber='$PanNumber' AND UserId='$userIdEscaped'"
);

if (!$check || $check->num_rows === 0) {
    http_response_code(404);
    echo json_encode(["status" => "error", "statusCode" => 404,
        "data" =>["message" => "Document not found"]]);
    exit;
}

$row = $check->fetch_assoc();
$safeFile = basename($row['fileName']);
if (basename($data['fileName']) !== $safeFile) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "fileName does not match this document"],
    ]);
    exit;
}
$panForPath = $row['PanNumber'];

// Same base as add_documents.php / download_document.php
$uploadDir = __DIR__ . '/../uploads/';
$candidatePaths = [$uploadDir . $panForPath . '/' . $safeFile];
if (strlen($panForPath) >= 5) {
    $shortPan = substr($panForPath, 0, 5);
    if ($shortPan !== $panForPath) {
        $candidatePaths[] = $uploadDir . $shortPan . '/' . $safeFile;
    }
}
$candidatePaths = array_unique($candidatePaths);

// Delete Document Record
// Soft delete: Set isActive = 0 instead of deleting row
$sql = "UPDATE document_details 
        SET isActive = 0 
        WHERE id='$id' AND PanNumber='$PanNumber' AND UserId='$userIdEscaped'";

if ($conn->query($sql)) {

    // Delete file from disk (absolute path; legacy folder may use first 5 chars of PAN)
    foreach ($candidatePaths as $filePath) {
        if (is_file($filePath)) {
            @unlink($filePath);
            break;
        }
    }

    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" =>[
        "message" => "Document deleted successfully"
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" =>[
        "message" => "Database error: " . $conn->error
        ]
    ]);
}

?>
