<?php
// Allow cross-origin requests (CORS policy)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

require 'include/config.php';
require 'phpjwt/Token.php';

$headers = getallheaders();
$authcode = trim($headers['Authorization']);
$token = str_replace("Bearer ", "", $authcode);

// Check if the request method is GET
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $decoded = Token::Verify($token, $key);
    $itrId = $_GET['itrId'] ?? null;

    if (isset($itrId) && !empty($itrId)) {
        // Check if the token is valid and not expired
        if ($decoded === false) {
            $response = [
                "status" => "error",
                "message" => "Invalid token"
            ];
            http_response_code(401);
        } else {
            $sql = "SELECT * FROM itr_detail WHERE id = '$itrId'";
            $result = $conn->query($sql);
            if ($result->num_rows > 0) {
                $results = [];
                while ($row = $result->fetch_assoc()) {
                    $results[] = $row;
                }

                // Query the source table
                $sourceSql = "SELECT * FROM itr_source WHERE itrId = '$itrId'";
                $sourceResult = $conn->query($sourceSql);
                $sourceData = [];

                if ($sourceResult->num_rows > 0) {
                    while ($row = $sourceResult->fetch_assoc()) {
                        $sourceData[] = $row;
                    }
                }

                $response = [
                    "status" => "success",
                    "data" => $results,
                    "source" => $sourceData
                ];
                http_response_code(200);
            } else {
                $response = [
                    "status" => "error",
                    "message" => "Data Not Found"
                ];
                http_response_code(400);
            }
        }
    } else {
        $response = [
            "status" => "error",
            "message" => "User ID is required"
        ];
        http_response_code(400);
    }
} else {
    $response = [
        "status" => "error",
        "message" => "Only GET requests are allowed"
    ];
    http_response_code(405);
}

// Send JSON response
echo json_encode($response);
?>
