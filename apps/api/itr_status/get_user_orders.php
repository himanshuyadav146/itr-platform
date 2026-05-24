<?php
/**
 * Get User Orders API
 * Returns list of successful orders for the authenticated user with full personal details
 * for display on "My ITR Records" / order list UI
 * 
 * Endpoint: GET /itr_status/get_user_orders.php
 * Auth: Required - Bearer token
 * 
 * Query Parameters:
 *   - page: Page number (default: 1)
 *   - limit: Items per page (default: 20, max: 50)
 * 
 * Returns: Orders (payment_status = 'success') with Name, Mobile, PAN, Financial Year, etc.
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only GET method allowed"]
    ]);
    exit;
}

require '../include/config.php';
require '../phpjwt/Token.php';

// Token verification
$headers = getallheaders();
$token = isset($headers['Authorization']) ? str_replace("Bearer ", "", trim($headers['Authorization'])) : "";

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

$userId = $decoded['UserId'] ?? null;
if (!$userId) {
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" => ["message" => "UserId missing in token"]
    ]);
    exit;
}

$userIdEscaped = mysqli_real_escape_string($conn, $userId);

// Pagination
$page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
$limit = isset($_GET['limit']) ? max(1, min(50, (int)$_GET['limit'])) : 20;
$offset = ($page - 1) * $limit;

// Build query - only successful payments (orders), with personal details for UI
$whereClause = "pi.user_id = '$userIdEscaped' AND pi.payment_status = 'success'";

// Get total count
$countSql = "SELECT COUNT(*) as total 
             FROM payment_info pi 
             WHERE $whereClause";
$countResult = $conn->query($countSql);
$totalOrders = 0;
if ($countResult && $countResult->num_rows > 0) {
    $totalOrders = (int)$countResult->fetch_assoc()['total'];
}
$totalPages = $totalOrders > 0 ? (int)ceil($totalOrders / $limit) : 0;

// Get orders with personal details - use UPPER(TRIM()) for PAN match across tables
$sql = "SELECT 
            pi.id as payment_db_id,
            pi.payment_id as payment_reference,
            pi.order_id,
            pi.transaction_id,
            pi.subtotal,
            pi.gst_amount,
            pi.grand_total,
            pi.currency,
            pi.payment_status,
            pi.payment_method,
            pi.gateway_name,
            pi.created_at,
            pi.paid_at,
            pi.pan_number as pi_pan_number,
            pi.package_id,
            pd.FirstName as pd_first_name,
            pd.MiddleName as pd_middle_name,
            pd.LastName as pd_last_name,
            pd.MobileNumber as pd_mobile,
            pd.EMAIL as pd_email,
            pd.FinancialYear as pd_financial_year,
            pd.PANNumber as pd_pan_number,
            u.FirstName as user_first_name,
            u.LastName as user_last_name,
            u.Mobile as user_mobile,
            u.Email as user_email,
            p.packagename,
            p.price as package_price,
            itr.id as itr_id
        FROM payment_info pi
        LEFT JOIN personal_details pd ON pi.user_id = pd.UserId 
            AND UPPER(TRIM(COALESCE(pi.pan_number, ''))) = UPPER(TRIM(COALESCE(pd.PANNumber, '')))
            AND (pd.isActive = 1 OR pd.isActive IS NULL)
        LEFT JOIN users u ON pi.user_id = u.UserId
        LEFT JOIN itr_packages p ON pi.package_id = p.id
        LEFT JOIN itr_detail itr ON pi.user_id = itr.userId 
            AND UPPER(TRIM(COALESCE(pi.pan_number, ''))) = UPPER(TRIM(COALESCE(itr.panNumber, '')))
        WHERE $whereClause
        ORDER BY pi.paid_at DESC, pi.created_at DESC
        LIMIT $limit OFFSET $offset";

$result = $conn->query($sql);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Database error: " . $conn->error]
    ]);
    exit;
}

$orders = [];

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        // Prefer personal_details, fallback to users
        $firstName = trim($row['pd_first_name'] ?? $row['user_first_name'] ?? '');
        $middleName = trim($row['pd_middle_name'] ?? '');
        $lastName = trim($row['pd_last_name'] ?? $row['user_last_name'] ?? '');
        $fullName = trim($firstName . ' ' . $middleName . ' ' . $lastName);
        $mobile = $row['pd_mobile'] ?? $row['user_mobile'] ?? '';
        $email = $row['pd_email'] ?? $row['user_email'] ?? '';
        $panNumber = $row['pd_pan_number'] ?? $row['pi_pan_number'] ?? '';
        $financialYear = $row['pd_financial_year'] ?? '';

        $orders[] = [
            "orderId" => $row['order_id'],
            "paymentId" => $row['payment_reference'],
            "itrId" => $row['itr_id'] ? (int)$row['itr_id'] : null,
            "firstName" => $firstName,
            "lastName" => $lastName,
            "middleName" => $middleName ?: null,
            "fullName" => $fullName,
            "mobile" => $mobile,
            "email" => $email,
            "panNumber" => $panNumber,
            "financialYear" => $financialYear,
            "assessmentYear" => $financialYear,
            "packageName" => $row['packagename'],
            "packagePrice" => $row['package_price'] ? floatval($row['package_price']) : null,
            "amount" => [
                "subtotal" => floatval($row['subtotal']),
                "gstAmount" => floatval($row['gst_amount']),
                "grandTotal" => floatval($row['grand_total']),
                "currency" => $row['currency'] ?? 'INR'
            ],
            "paymentStatus" => $row['payment_status'],
            "paymentMethod" => $row['payment_method'],
            "transactionId" => $row['transaction_id'],
            "paidAt" => $row['paid_at'],
            "createdAt" => $row['created_at']
        ];
    }
}

http_response_code(200);
echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" => [
        "orders" => $orders,
        "pagination" => [
            "page" => $page,
            "limit" => $limit,
            "total" => $totalOrders,
            "totalPages" => $totalPages
        ]
    ]
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

exit;
?>
