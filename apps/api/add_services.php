<?php
// Allow cross-origin requests (CORS policy)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

require 'include/config.php';
require 'phpjwt/Token.php';

$headers = getallheaders();
$authcode = trim($headers['Authorization']);
$token = str_replace("Bearer ", "", $authcode);

// Check if the request method is POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    // Get the raw POST data
    $input = file_get_contents("php://input");
    $data = json_decode($input, true); // Convert JSON to PHP array

    // Check if required fields exist
    if (isset($data['name']) && !empty($data['name'])) {
        $decoded = Token::Verify($token, $key);
        if ($decoded === false) {
            $response = [
                "status" => "error",
                "message" => "Invalid token"
            ];
            http_response_code(401);
        } else {
            $sql = "SELECT * FROM services WHERE Name = '$data[name]'";
            $result = $conn->query($sql);
            if ($result->num_rows > 0) {
                $row = $result->fetch_assoc();
                $response = [
                    "status" => "success",
                    "message" => "Already exists",
                ];
                http_response_code(200);
            } else {
                $currentDateTime = date("Y-m-d H:i:s");
                $sql = "INSERT INTO services (Name, CreatedAt) VALUES ('$data[name]', '$currentDateTime')";
                if ($conn->query($sql) === TRUE) {
                    $response = [
                        "status" => "success",
                        "message" => "Added successfully"
                    ];
                    http_response_code(200);
                } else {
                    $response = [
                        "status" => "error",
                        "message" => "Error registering user: " . $conn->error
                    ];
                    http_response_code(500);                
                }
            }
        }
    } else {
        $response = [
            "status" => "error",
            "message" => "Invalid input, 'mobile' required"
        ];
        http_response_code(400);
    }
} else {
    $response = [
        "status" => "error",
        "message" => "Only POST requests are allowed"
    ];
    http_response_code(405);
}

// Send JSON response
echo json_encode($response);
?>
