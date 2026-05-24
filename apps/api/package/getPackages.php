<?php
// Allow CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

require '../include/config.php';  // DB connection

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode(["status" => "error","statusCode" => 405,
        "data" =>[ "message" => "Only GET request allowed"]]);
    http_response_code(405);
    exit;
}

// Fetch all packages
$sql = "SELECT 
            id,
            packagename,
            price,
            title1, description1,
            title2, description2,
            turnover,
            icon,
            color,
            isActive,
            createdAt
        FROM itr_packages
        WHERE isActive = 1
        ORDER BY id asc";

$result = $conn->query($sql);

$packages = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $packages[] = $row;
    }
}

echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" =>[    
        "packages" => $packages
]], JSON_UNESCAPED_UNICODE);

http_response_code(200);
exit;

?>
