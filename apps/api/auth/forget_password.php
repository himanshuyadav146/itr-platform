<?php
// Allow cross-origin requests (CORS policy)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

require '../include/config.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $input = file_get_contents("php://input");
    $data  = json_decode($input, true);

    // Validate email
    if (!isset($data['email']) || empty(trim($data['email']))) {
        http_response_code(400);
        echo json_encode([
            "statusCode" => 400,
            "status" => "error",
            "data" =>[
            "message" => "Email is required"
            ]
        ]);
        exit;
    }

    // Validate password
    if (!isset($data['password']) || empty(trim($data['password']))) {
        http_response_code(400);
        echo json_encode([
            "statusCode" => 400,
            "status" => "error",
            "data" =>[
            "message" => "Password is required"
            ]
        ]);
        exit;
    }

    $email    = mysqli_real_escape_string($conn, trim($data['email']));
    $password = mysqli_real_escape_string($conn, trim($data['password']));

    // Check if email exists
    $sql = "SELECT * FROM users WHERE Email = '$email'";
    $result = $conn->query($sql);

    if ($result && $result->num_rows > 0) {

        // Update password
        $sqlUpdate = "UPDATE users SET Password='$password' WHERE Email='$email'";

        if ($conn->query($sqlUpdate) === TRUE) {
            http_response_code(200);
            echo json_encode([
                "statusCode" => 200,
                "status" => "success",
                "data" => [
                "message" => "Password updated successfully"
                ]
            ]);
        } else {
            http_response_code(500);
            echo json_encode([
                "statusCode" => 500,
                "status" => "error",
                "data" =>[
                "message" => "Error updating password"
                ]
            ]);
        }

    } else {
        http_response_code(404);
        echo json_encode([
            "statusCode" => 404,
            "status" => "error",
            "data" =>[
            "message" => "Email not found"
            ]
        ]);
    }

} else {
    http_response_code(405);
    echo json_encode([
        "statusCode" => 405,
        "status" => "error",
        "data" =>[
        "message" => "Only POST method allowed"
        ]
    ]);
}
?>
