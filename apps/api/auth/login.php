<?php
// Allow cross-origin requests (CORS policy)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

$response = []; // default

// POST request check
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $input = file_get_contents("php://input");
    $data  = json_decode($input, true);

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

    if (!isset($data['password']) || empty(trim($data['password']))) {
        http_response_code(400);
        echo json_encode([
            "statusCode" => 400,
            "status" => "error",
            "data" => [
            "message" => "Password is required"
            ]
        ]);
        exit;
    }

    // Escape input
    $email    = mysqli_real_escape_string($conn, trim($data['email']));
    $password = mysqli_real_escape_string($conn, trim($data['password']));
    $platform = isset($data['platform']) ? mysqli_real_escape_string($conn, $data['platform']) : 'web';
    $version  = isset($data['version']) ? mysqli_real_escape_string($conn, $data['version']) : '1.0';

    // Check email - explicitly select columns including role
    $sql = "SELECT UserId, FirstName, MiddleName, LastName, Email, Mobile, Password, 
                   role, IsActive, Platform, Version, CreatedAt, UpdatedAt 
            FROM users 
            WHERE LOWER(TRIM(Email)) = LOWER(TRIM('$email'))";
    $result = $conn->query($sql);

    if ($result && $result->num_rows > 0) {

        $row = $result->fetch_assoc();
        $dbPassword = trim($row['Password']);

        if ($dbPassword === $password) {

            // Update platform & version
            $sql1 = "UPDATE users 
                     SET Platform='$platform', Version='$version', UpdatedAt=NOW() 
                     WHERE Email='" . $row['Email'] . "'";
            $conn->query($sql1);

            // Token
            $payload = [
                "iss" => "allindiaitr.in",
                "UserId" => $row['UserId'],
                "Role" => $row['role'] ?? 'CLIENT'
            ];
            $token = Token::Sign($payload, $key, $expire);

            // Success Response
            http_response_code(200);
            echo json_encode([
                "statusCode" => 200,
                "status" => "success",
                "data" => [
                    "message" => "Login successful",
                    "UserId" => $row['UserId'],
                    "email" => $row['Email'],
                    "firstName" => $row['FirstName'] ?? null,
                    "middleName" => $row['MiddleName'] ?? null,
                    "lastName" => $row['LastName'] ?? null,
                    "mobile" => $row['Mobile'] ?? null,
                    "role" => $row['role'] ?? 'CLIENT',
                    "isActive" => isset($row['IsActive']) ? (bool)$row['IsActive'] : true,
                    "platform" => $row['Platform'] ?? 'web',
                    "version" => $row['Version'] ?? '1.0',
                    "token" => $token,
                ]
            ]);
            exit;

        } else {

            // Wrong password
            http_response_code(401);
            echo json_encode([
                "statusCode" => 401,
                "status" => "error",
                "data" =>[
                    "message" => "Invalid email or password"
                    ]
            ]);
            exit;
        }

    } else {

        // User not found
        http_response_code(404);
        echo json_encode([
            "statusCode" => 404,
            "status" => "error",
            "data" => [
            "message" => "User not found"
            ]
        ]);
        exit;
    }

} else {
    http_response_code(405);
    echo json_encode([
        "statusCode" => 405,
        "status" => "error",
        "data" => [
        "message" => "Only POST method allowed"
        ]
    ]);
}

?>
