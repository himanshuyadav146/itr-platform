<?php
// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

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

// Check if user is admin
$role = $decoded['Role'] ?? null;
if ($role !== 'ADMIN' && $role !== 'PROFESSIONAL') {
    http_response_code(403);
    echo json_encode([
        "status" => "error",
        "statusCode" => 403,
        "data" => ["message" => "Access denied. Admin or Professional role required."]
    ]);
    exit;
}

// Get JSON input
$input = file_get_contents("php://input");
$data = json_decode($input, true);

// Required fields
$packagename = trim($data['packagename'] ?? $data['name'] ?? '');
$price = trim($data['price'] ?? '');

if (empty($packagename) || empty($price)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "Package name and price are required"]
    ]);
    exit;
}

// Remove currency symbol if present
$price = str_replace(['₹', ',', ' '], '', $price);

// Optional fields
$title1 = trim($data['title1'] ?? '');
$description1 = trim($data['description1'] ?? $data['description'] ?? '');
$title2 = trim($data['title2'] ?? '');
$description2 = trim($data['description2'] ?? '');
$turnover = trim($data['turnover'] ?? '');
$icon = trim($data['icon'] ?? '');
$color = trim($data['color'] ?? '');
$isActive = isset($data['isActive']) ? (int)$data['isActive'] : 1;

// Escape variables
$packagename = mysqli_real_escape_string($conn, $packagename);
$price = mysqli_real_escape_string($conn, $price);
$title1 = mysqli_real_escape_string($conn, $title1);
$description1 = mysqli_real_escape_string($conn, $description1);
$title2 = mysqli_real_escape_string($conn, $title2);
$description2 = mysqli_real_escape_string($conn, $description2);
$turnover = mysqli_real_escape_string($conn, $turnover);
$icon = mysqli_real_escape_string($conn, $icon);
$color = mysqli_real_escape_string($conn, $color);

// Check if updating existing package (by id)
$packageId = isset($data['id']) ? (int)$data['id'] : null;

if ($packageId) {
    // UPDATE existing package
    $sql = "UPDATE itr_packages SET
            packagename = '$packagename',
            price = '$price',
            title1 = '$title1',
            description1 = '$description1',
            title2 = '$title2',
            description2 = '$description2',
            turnover = '$turnover',
            icon = '$icon',
            color = '$color',
            isActive = $isActive
            WHERE id = $packageId";
    
    if ($conn->query($sql) === TRUE) {
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "message" => "Package updated successfully",
                "packageId" => $packageId
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Error updating package: " . $conn->error]
        ]);
    }
} else {
    // INSERT new package
    $sql = "INSERT INTO itr_packages 
            (packagename, price, title1, description1, title2, description2, turnover, icon, color, isActive, createdAt)
            VALUES 
            ('$packagename', '$price', '$title1', '$description1', '$title2', '$description2', '$turnover', '$icon', '$color', $isActive, NOW())";
    
    if ($conn->query($sql) === TRUE) {
        $newPackageId = $conn->insert_id;
        http_response_code(201);
        echo json_encode([
            "status" => "success",
            "statusCode" => 201,
            "data" => [
                "message" => "Package added successfully",
                "packageId" => $newPackageId
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Error adding package: " . $conn->error]
        ]);
    }
}

$conn->close();
exit;
?>
