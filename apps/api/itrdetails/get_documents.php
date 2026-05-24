<?php
// Allow cross-origin requests (CORS)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {

    // Read PAN from query string
    $PanNumber = isset($_GET['PanNumber']) ? trim($_GET['PanNumber']) : null;

    if (empty($PanNumber)) {
        echo json_encode(["status" => "error","statusCode" => 400,
        "data" =>[ "message" => "PanNumber is required"]]);
        http_response_code(400);
        exit;
    }

    // Extract token
    $token = '';
    $headers = getallheaders();
    if (isset($headers['Authorization'])) {
        $authcode = trim($headers['Authorization']);
        $token = str_replace("Bearer ", "", $authcode);
    }

    // Validate token
    if (empty($token)) {
        echo json_encode(["status" => "error", "statusCode" => 401,
        "data" =>["message" => "Authorization token required"]]);
        http_response_code(401);
        exit;
    }

    $decoded = Token::Verify($token, $key);
    if ($decoded === false) {
        echo json_encode(["status" => "error","statusCode" => 401,
        "data" =>[ "message" => "Invalid or expired token"]]);
        http_response_code(401);
        exit;
    }

    // Logged-in user
    $UserId = $decoded['UserId'] ?? null;

    if (!$UserId) {
        echo json_encode(["status" => "error","statusCode" => 400,
        "data" =>[ "message" => "UserId missing in token"]]);
        http_response_code(400);
        exit;
    }

    // Escape inputs
    $PanNumber = mysqli_real_escape_string($conn, $PanNumber);

    // Fetch documents
    $sql = "SELECT 
                id, 
                name AS documentName, 
                type AS fileType, 
                password AS filePassword, 
                fileName, 
                createdAt 
            FROM document_details 
            WHERE UserId = '$UserId' 
              AND PanNumber = '$PanNumber'
            ORDER BY id DESC";

    $result = $conn->query($sql);

    if ($result && $result->num_rows > 0) {
        $documents = [];
        
        // Get base URL for download links
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
        $host = $_SERVER['HTTP_HOST'];
        $baseUrl = $protocol . "://" . $host;
        
        // If the request comes through a specific domain, use that
        if (isset($headers['Host'])) {
            $baseUrl = $protocol . "://" . $headers['Host'];
        }
        
        while ($row = $result->fetch_assoc()) {
            // Add download URL to each document
            $row['downloadUrl'] = $baseUrl . "/api/itrdetails/download_document.php?docId=" . $row['id'];
            $documents[] = $row;
        }

        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" =>[
            "documents" => $documents
        ]
        ]);
        http_response_code(200);
    } else {
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" =>[
            "documents" => [],
            "message" => "No documents found"
            ]
        ]);
        http_response_code(200);
    }

} else {
    echo json_encode(["status" => "error","statusCode" => 405,
        "data" =>[ "message" => "Only GET request allowed"]]);
    http_response_code(405);
}
?>
