<?php
/**
 * Delete Package API
 * Allows admin/professional to delete a package from itr_packages.
 *
 * POST /package/deletePackage.php
 * Headers: Authorization: Bearer <JWT>
 * Body: { "id": 3 }
 */
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require __DIR__ . '/../include/config.php';
require __DIR__ . '/../phpjwt/Token.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only POST allowed"]
    ]);
    exit;
}

// Read Authorization Token (getallheaders not available on Nginx/PHP-FPM)
$token = "";
if (function_exists('getallheaders')) {
    $headers = getallheaders();
    if (isset($headers['Authorization'])) {
        $token = str_replace("Bearer ", "", trim($headers['Authorization']));
    } elseif (isset($headers['authorization'])) {
        $token = str_replace("Bearer ", "", trim($headers['authorization']));
    }
}
if (empty($token) && !empty($_SERVER['HTTP_AUTHORIZATION'])) {
    $token = str_replace("Bearer ", "", trim($_SERVER['HTTP_AUTHORIZATION']));
}
if (empty($token) && !empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
    $token = str_replace("Bearer ", "", trim($_SERVER['REDIRECT_HTTP_AUTHORIZATION']));
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

// Admin or Professional only
$role = $decoded['Role'] ?? $decoded['role'] ?? null;
if ($role !== 'ADMIN' && $role !== 'PROFESSIONAL') {
    http_response_code(403);
    echo json_encode([
        "status" => "error",
        "statusCode" => 403,
        "data" => ["message" => "Access denied. Admin or Professional role required."]
    ]);
    exit;
}

$input = file_get_contents("php://input");
$data = $input ? json_decode($input, true) : [];

$packageId = isset($data['id']) ? (int)$data['id'] : null;
if (!$packageId) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => ["message" => "Package id is required"]
    ]);
    exit;
}

// Check if package exists
$checkSql = "SELECT id, packagename FROM itr_packages WHERE id = " . (int)$packageId . " LIMIT 1";
$checkResult = $conn->query($checkSql);

if (!$checkResult || $checkResult->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "status" => "error",
        "statusCode" => 404,
        "data" => ["message" => "Package not found"]
    ]);
    exit;
}

// Delete package (payment_info.package_id and personal_details.package_id use ON DELETE SET NULL)
$deleteSql = "DELETE FROM itr_packages WHERE id = " . (int)$packageId;

if ($conn->query($deleteSql)) {
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "message" => "Package deleted successfully",
            "packageId" => $packageId
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Failed to delete package. Please try again."]
    ]);
}
?>
