<?php
// Allow cross-origin requests (CORS policy)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require __DIR__ . '/include/config.php';
require __DIR__ . '/phpjwt/Token.php';
require __DIR__ . '/itr_status/StatusHelper.php';

// Check if the request method is GET
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        "statusCode" => 405,
        "status" => "error",
        "data" => [
            "message" => "Only GET requests are allowed"
        ]
    ]);
    exit;
}

// Extract Bearer token
$headers = getallheaders();
$token = "";

if (isset($headers['Authorization'])) {
    $token = str_replace("Bearer ", "", trim($headers['Authorization']));
} elseif (function_exists('apache_request_headers')) {
    $apacheHeaders = apache_request_headers();
    if (isset($apacheHeaders['Authorization'])) {
        $token = str_replace("Bearer ", "", trim($apacheHeaders['Authorization']));
    }
}

// Validate token
if (empty($token)) {
    http_response_code(401);
    echo json_encode([
        "statusCode" => 401,
        "status" => "error",
        "data" => [
            "message" => "Authorization token required"
        ]
    ]);
    exit;
}

// Verify token
$decoded = Token::Verify($token, $key);
if ($decoded === false) {
    http_response_code(401);
    echo json_encode([
        "statusCode" => 401,
        "status" => "error",
        "data" => [
            "message" => "Invalid or expired token"
        ]
    ]);
    exit;
}

// Get userId from query parameter or token
$userId = $_GET['userId'] ?? null;

// If userId not in query, use from token
if (empty($userId)) {
    $userId = $decoded['UserId'] ?? null;
}

// Validate userId
if (empty($userId) || $userId === null) {
    http_response_code(400);
    echo json_encode([
        "statusCode" => 400,
        "status" => "error",
        "data" => [
            "message" => "User ID is required",
            "debug" => [
                "query_param" => $_GET['userId'] ?? 'not set',
                "token_userid" => $decoded['UserId'] ?? 'not found in token'
            ]
        ]
    ]);
    exit;
}

// Validate and escape userId
$userId = (int)$userId;
$userId = mysqli_real_escape_string($conn, $userId);

// Check if connection is valid
if (!$conn) {
    http_response_code(500);
    echo json_encode([
        "statusCode" => 500,
        "status" => "error",
        "data" => [
            "message" => "Database connection error"
        ]
    ]);
    exit;
}

// Query personal_details for the user
$sql = "SELECT 
            id,
            UserId,
            PANNumber,
            FirstName,
            MiddleName,
            LastName,
            EMAIL,
            MobileNumber,
            aadharCardNumber,
            Gender,
            DATEOFBIRTH,
            FinancialYear,
            Address,
            Country,
            isActive,
            createdAt,
            createdBy,
            updatedAt,
            updatedBy
        FROM personal_details 
        WHERE UserId = '$userId' AND isActive = 1
        ORDER BY createdAt DESC";
        
$result = $conn->query($sql);

// Handle query errors
if ($result === false) {
    http_response_code(500);
    echo json_encode([
        "statusCode" => 500,
        "status" => "error",
        "data" => [
            "message" => "Database query error: " . $conn->error
        ]
    ]);
    exit;
}

// Collect PAN numbers for status lookup
$panList = [];
$rows = [];
while ($result->num_rows > 0 && $row = $result->fetch_assoc()) {
    $rows[] = $row;
    $pan = trim($row['PANNumber'] ?? '');
    if ($pan !== '' && !in_array($pan, $panList, true)) {
        $panList[] = $pan;
    }
}

$paymentMap = [];
$statusMap = [];
try {
    // Build payment map: pan_number (uppercase) -> { order_id, payment_status }
    $panSet = array_values(array_unique(array_map(function ($p) {
        return strtoupper(trim($p ?? ''));
    }, $panList)));
    $panSet = array_filter($panSet, function ($p) { return $p !== ''; });
    if (!empty($panSet)) {
        $paySql = "SELECT pan_number, order_id, payment_status 
                   FROM payment_info 
                   WHERE user_id = '$userId' AND payment_status = 'success' 
                   ORDER BY created_at DESC";
        $payResult = $conn->query($paySql);
        if ($payResult && $payResult->num_rows > 0) {
            while ($pr = $payResult->fetch_assoc()) {
                $pn = strtoupper(trim($pr['pan_number'] ?? ''));
                if ($pn !== '' && in_array($pn, $panSet, true) && !isset($paymentMap[$pn])) {
                    $paymentMap[$pn] = [
                        'order_id' => $pr['order_id'],
                        'payment_status' => $pr['payment_status']
                    ];
                }
            }
        }
    }

    // Build status map: order_id -> itrStatus (from itr_order_status steps)
    if (!empty($paymentMap)) {
        $orderIds = array_unique(array_filter(array_column($paymentMap, 'order_id')));
        if (!empty($orderIds)) {
            $orderInList = array_map(function ($o) use ($conn) {
                return "'" . mysqli_real_escape_string($conn, $o) . "'";
            }, $orderIds);
            $orderInClause = implode(',', $orderInList);
            $statusSql = "SELECT order_id, status_step, is_completed, has_concern 
                          FROM itr_order_status 
                          WHERE order_id IN ($orderInClause) AND user_id = '$userId'
                          ORDER BY FIELD(status_step, 'payment_success', 'expert_assigned', 'documents_verified', 'filing_itr', 'acknowledgement_generated')";
            $statusResult = $conn->query($statusSql);
            if ($statusResult && $statusResult->num_rows > 0) {
                $stepsByOrder = [];
                while ($sr = $statusResult->fetch_assoc()) {
                    $oid = $sr['order_id'];
                    if (!isset($stepsByOrder[$oid])) {
                        $stepsByOrder[$oid] = [];
                    }
                    $stepsByOrder[$oid][] = $sr;
                }
                foreach ($stepsByOrder as $oid => $steps) {
                    $statusMap[$oid] = StatusHelper::calculateOverallStatus($steps);
                }
            }
        }
    }
} catch (Throwable $e) {
    // If payment_info or itr_order_status tables missing, use empty maps
    $paymentMap = [];
    $statusMap = [];
}

// Process results: add documents + status to each personal detail
$personalDetails = [];
foreach ($rows as $row) {
    $panNumber = $row['PANNumber'];
    $panNumberEscaped = mysqli_real_escape_string($conn, $panNumber);
    $panKey = strtoupper(trim($panNumber ?? ''));
    
    // Fetch documents
    $docSql = "SELECT 
                    id, 
                    name AS documentName, 
                    type AS fileType, 
                    password AS filePassword, 
                    fileName, 
                    createdAt 
                FROM document_details 
                WHERE UserId = '$userId' 
                  AND PanNumber = '$panNumberEscaped'
                  AND isActive = 1
                ORDER BY createdAt DESC";
    $docResult = $conn->query($docSql);
    $documents = [];
    if ($docResult && $docResult->num_rows > 0) {
        while ($docRow = $docResult->fetch_assoc()) {
            $documents[] = $docRow;
        }
    }
    $row['documents'] = $documents;
    $row['documentCount'] = count($documents);
    
    // Add ITR status and payment status
    $paymentInfo = $paymentMap[$panKey] ?? null;
    if ($paymentInfo) {
        $orderId = $paymentInfo['order_id'];
        $row['orderId'] = $orderId;
        $row['paymentStatus'] = $paymentInfo['payment_status'];
        $row['itrStatus'] = $statusMap[$orderId] ?? 'pending';
    } else {
        $row['orderId'] = null;
        $row['paymentStatus'] = null;
        $row['itrStatus'] = 'pending_payment';
    }
    $row['statusDisplayText'] = StatusHelper::getOverallStatusText($row['itrStatus']);
    
    $personalDetails[] = $row;
}

// Return success response (even if empty array)
http_response_code(200);
echo json_encode([
    "statusCode" => 200,
    "status" => "success",
    "data" => [
        "personalDetails" => $personalDetails,
        "count" => count($personalDetails),
        "message" => count($personalDetails) > 0 ? "Personal details found" : "No personal details found for this user"
    ]
]);
exit;
?>

