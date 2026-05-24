<?php
/**
 * Admin Documents API
 * Get documents for a specific ITR
 * 
 * Endpoints: 
 * - GET /admin/documents.php?itrId={id} - Get documents for an ITR
 */

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

// Handle OPTIONS preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

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

$method = $_SERVER['REQUEST_METHOD'];

// GET - Get documents for an ITR
if ($method === 'GET') {
    $itrId = isset($_GET['itrId']) ? trim($_GET['itrId']) : null;
    
    if (empty($itrId)) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "itrId is required"]
        ]);
        exit;
    }
    
    // Escape input
    $itrIdEscaped = mysqli_real_escape_string($conn, $itrId);
    
    // Get ITR details to find userId and panNumber
    $itrSql = "SELECT userId, panNumber FROM itr_detail WHERE id = '$itrIdEscaped'";
    $itrResult = $conn->query($itrSql);
    
    if (!$itrResult || $itrResult->num_rows === 0) {
        http_response_code(404);
        echo json_encode([
            "status" => "error",
            "statusCode" => 404,
            "data" => ["message" => "ITR not found"]
        ]);
        exit;
    }
    
    $itr = $itrResult->fetch_assoc();
    $userId = mysqli_real_escape_string($conn, $itr['userId']);
    $panNumber = mysqli_real_escape_string($conn, $itr['panNumber']);
    
    // Fetch documents for this user and PAN
    $sql = "SELECT 
                id, 
                name AS documentName, 
                type AS fileType, 
                password AS filePassword, 
                fileName, 
                createdAt 
            FROM document_details 
            WHERE UserId = '$userId' 
              AND PanNumber = '$panNumber'
              AND isActive = 1
            ORDER BY id DESC";
    
    $result = $conn->query($sql);
    
    if ($result && $result->num_rows > 0) {
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
        $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
        $scriptPath = dirname(dirname($_SERVER['SCRIPT_NAME']));
        $downloadBaseUrl = rtrim($protocol . '://' . $host . $scriptPath, '/') . '/itrdetails/download_document.php?docId=';
        $documents = [];
        while ($row = $result->fetch_assoc()) {
            $docId = (int)$row['id'];
            $row['downloadUrl'] = $downloadBaseUrl . $docId;
            $row['image_url'] = $downloadBaseUrl . $docId;
            $documents[] = $row;
        }
        
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "documents" => $documents
            ]
        ]);
    } else {
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "documents" => [],
                "message" => "No documents found"
            ]
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
