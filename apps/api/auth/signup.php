<?php
// Allow cross-origin requests (CORS policy)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

require '../include/config.php';
require_once __DIR__ . '/../associates/AssociateHelper.php';

// Check if the request method is POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    // Allow register_associate.php to pass a pre-parsed body (php://input can be read once).
    $data = $GLOBALS['signup_preparsed_data'] ?? null;
    if (!is_array($data)) {
        $input = file_get_contents("php://input");
        $data = json_decode($input, true);
    } 

    // Check: email is required
    if (!isset($data['email']) || empty(trim($data['email']))) {
        $response = [
            "statusCode" => 400,
            "status" => "error",
            "data"=>[
                 "message" => "Invalid input, 'email' is required"
            ]
        ];
        http_response_code(400);
        echo json_encode($response);
        exit;
    }

    // Escape user input
    $email = mysqli_real_escape_string($conn, trim($data['email']));

    // Check if email already exists (case-insensitive)
    $sql = "SELECT * FROM users WHERE LOWER(TRIM(Email)) = LOWER(TRIM('$email'))";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {

        $response = [
            "statusCode" => 409,
            "status" => "error",
            "data" =>[
            "message" => "Email already exists"
            ]
        ];
        http_response_code(409); // 409 Conflict
        echo json_encode($response);
        exit;
    }

    // Handle name processing
    $firstName = '';
    $middleName = '';
    $lastName = '';

    if (isset($data['name']) && !empty($data['name'])) {
        $nameParts = explode(' ', trim($data['name']));

        $firstName = $nameParts[0];

        if (count($nameParts) >= 3) {
            $middleName = $nameParts[1];
            $lastName = implode(' ', array_slice($nameParts, 2));
        } elseif (count($nameParts) == 2) {
            $middleName = '';
            $lastName = $nameParts[1];
        } else {
            $middleName = '';
            $lastName = '';
        }

    } else {
        $firstName = $data['firstName'] ?? '';
        $middleName = $data['middleName'] ?? '';
        $lastName = $data['lastName'] ?? '';
    }

    // Escape data
    $firstName = mysqli_real_escape_string($conn, $firstName);
    $middleName = mysqli_real_escape_string($conn, $middleName);
    $lastName = mysqli_real_escape_string($conn, $lastName);
    // Accept both mobile (new) and phone (legacy admin payload)
    $mobileInput = $data['mobile'] ?? ($data['phone'] ?? '');
    $mobile = mysqli_real_escape_string($conn, $mobileInput);
    $password = mysqli_real_escape_string($conn, $data['password'] ?? '');
    $platform = mysqli_real_escape_string($conn, $data['platform'] ?? 'web');
    $version = mysqli_real_escape_string($conn, $data['version'] ?? '1.0');
    
    // Public signup may never create ADMIN. Only CLIENT or associate roles.
    $publicRoles = ['CLIENT', 'ACCOUNTANT', 'CA', 'TAX_EXPERT'];
    $roleRaw = $data['role'] ?? ($data['Role'] ?? ($data['occupation'] ?? null));
    $role = $roleRaw ? strtoupper(trim($roleRaw)) : 'CLIENT';
    if ($role === 'ADMIN' || !in_array($role, $publicRoles, true)) {
        $role = 'CLIENT';
    }
    
    $role = mysqli_real_escape_string($conn, $role);

    // Insert Query
    $currentDateTime = date("Y-m-d H:i:s");

    $sql = "INSERT INTO users 
            (FirstName, MiddleName, LastName, Email, Mobile, Password, role, CreatedAt, Platform, Version)
            VALUES 
            ('$firstName', '$middleName', '$lastName', '$email', '$mobile', '$password', '$role', '$currentDateTime', '$platform', '$version')";

    if ($conn->query($sql) === TRUE) {
        $newUserId = (int)$conn->insert_id;
        if (AssociateHelper::isAssociateRole($role) && $newUserId > 0) {
            AssociateHelper::createPendingProfile($conn, $newUserId);
        }

        $response = [
            "statusCode" => 201,
            "status" => "success",
            "data"=>[
            "message" => "User registered successfully",
            "userId" => $newUserId,
            "role" => $role
            ]
        ];
        http_response_code(201); // 201 Created

    } else {

        $response = [
            "statusCode" => 500,
            "status" => "error",
            "data" =>[
            "message" => "Error registering user: " . $conn->error
            ]
        ];
        http_response_code(500); // Internal Server Error
    }

} else {
    $response = [
        "statusCode" => 405,
        "status" => "error",
        "data"=>[
        "message" => "Only POST requests are allowed"
        ]
    ];
    http_response_code(405); // Method Not Allowed
}

// Send JSON response
echo json_encode($response);
?>
