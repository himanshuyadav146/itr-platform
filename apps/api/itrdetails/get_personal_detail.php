<?php
// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error","statusCode" => 405,
    "data"=>[ "message" => "Only GET allowed"]]);
    exit;
}

// ---- Read UserId ----
$UserId = isset($_GET['UserId']) ? trim($_GET['UserId']) : null;

if (empty($UserId)) {
    http_response_code(400);
    echo json_encode(["status" => "error","statusCode" => 400,
    "data"=>["message" => "UserId is required"]]);
    exit;
}

// ---- Read Token ----
$headers = getallheaders();
$token = "";

if (isset($headers['Authorization'])) {
    $token = str_replace("Bearer ", "", trim($headers['Authorization']));
}

if (empty($token)) {
    http_response_code(401);
    echo json_encode(["status" => "error","statusCode" => 401,
    "data"=>[  "message" => "Authorization token required"]]);
    exit;
}

// ---- Verify Token ----
$decoded = Token::Verify($token, $key);
if ($decoded === false) {
    http_response_code(401);
    echo json_encode(["status" => "error", "statusCode" => 401,
    "data"=>[ "message" => "Invalid or expired token"]]);
    exit;
}

// ---- Escape Data ----
$UserId = mysqli_real_escape_string($conn, $UserId);

// ---- Fetch Personal Details ----
$PanNumber = isset($_GET['PanNumber']) ? trim($_GET['PanNumber']) : null;
$PanNumber = mysqli_real_escape_string($conn, $PanNumber);

$sql = "
    SELECT 
        id,
        UserId,
        PANNumber,
        FirstName,
        MiddleName,
        LastName,
        Gender,
        DATEOFBIRTH,
        EMAIL,
        MobileNumber,
        aadharCardNumber,
        FinancialYear,
        Address,
        Country,
        isActive,
        createdAt,
        createdBy,
        updatedAt,
        updatedBy
    FROM personal_details
    WHERE UserId = '$UserId' " . ($PanNumber ? "AND PANNumber = '$PanNumber'" : "") . "
";

$result = $conn->query($sql);

// ---- Response ----
if ($result && $result->num_rows > 0) {
    $data = $result->fetch_assoc();

    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
    "data"=>[ 
        "personal_details" => $data
    ]
    ]);
    http_response_code(200);

} else {
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
    "data"=>[ 
        "personal_details" => null,
        "message" => "No personal details found"
    ]
    ]);
    http_response_code(200);
}
?>
