<?php
/**
 * Admin Dashboard API
 * Get dashboard statistics and overview
 * 
 * Endpoint: GET /admin/dashboard.php
 * Headers: Authorization: Bearer {token}
 */

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only GET method allowed"]
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

try {
    // Get dashboard statistics
    
    // Total Users
    $sql = "SELECT COUNT(*) as total FROM users";
    $result = $conn->query($sql);
    $totalUsers = $result ? $result->fetch_assoc()['total'] : 0;
    
    // Total Orders (ITR Details)
    $sql = "SELECT COUNT(*) as total FROM itr_detail";
    $result = $conn->query($sql);
    $totalOrders = $result ? $result->fetch_assoc()['total'] : 0;
    
    // Total Payments
    $sql = "SELECT COUNT(*) as total FROM payment_info";
    $result = $conn->query($sql);
    $totalPayments = $result ? $result->fetch_assoc()['total'] : 0;
    
    // Successful Payments
    $sql = "SELECT COUNT(*) as total FROM payment_info WHERE payment_status = 'success'";
    $result = $conn->query($sql);
    $successfulPayments = $result ? $result->fetch_assoc()['total'] : 0;
    
    // Pending Payments
    $sql = "SELECT COUNT(*) as total FROM payment_info WHERE payment_status = 'pending'";
    $result = $conn->query($sql);
    $pendingPayments = $result ? $result->fetch_assoc()['total'] : 0;
    
    // Total Revenue (Successful payments only)
    $sql = "SELECT COALESCE(SUM(grand_total), 0) as total FROM payment_info WHERE payment_status = 'success'";
    $result = $conn->query($sql);
    $totalRevenue = $result ? floatval($result->fetch_assoc()['total']) : 0;
    
    // Today's Revenue
    $sql = "SELECT COALESCE(SUM(grand_total), 0) as total FROM payment_info 
            WHERE payment_status = 'success' AND DATE(paid_at) = CURDATE()";
    $result = $conn->query($sql);
    $todayRevenue = $result ? floatval($result->fetch_assoc()['total']) : 0;
    
    // This Month's Revenue
    $sql = "SELECT COALESCE(SUM(grand_total), 0) as total FROM payment_info 
            WHERE payment_status = 'success' AND MONTH(paid_at) = MONTH(CURDATE()) 
            AND YEAR(paid_at) = YEAR(CURDATE())";
    $result = $conn->query($sql);
    $monthRevenue = $result ? floatval($result->fetch_assoc()['total']) : 0;
    
    // Pending Concerns
    $sql = "SELECT COUNT(*) as total FROM itr_order_concerns WHERE status = 'pending'";
    $result = $conn->query($sql);
    $pendingConcerns = $result ? $result->fetch_assoc()['total'] : 0;
    
    // Recent Users (Last 7 days)
    $sql = "SELECT COUNT(*) as total FROM users WHERE DATE(CreatedAt) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
    $result = $conn->query($sql);
    $recentUsers = $result ? $result->fetch_assoc()['total'] : 0;
    
    // Recent Orders (Last 7 days)
    $sql = "SELECT COUNT(*) as total FROM itr_detail WHERE DATE(createdAt) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
    $result = $conn->query($sql);
    $recentOrders = $result ? $result->fetch_assoc()['total'] : 0;
    
    // Recent Payments (Last 7 days)
    $sql = "SELECT COUNT(*) as total FROM payment_info WHERE DATE(created_at) >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)";
    $result = $conn->query($sql);
    $recentPayments = $result ? $result->fetch_assoc()['total'] : 0;
    
    // Package Statistics
    $sql = "SELECT 
                p.id,
                p.packagename,
                p.price,
                COUNT(pi.id) as order_count,
                COALESCE(SUM(CASE WHEN pi.payment_status = 'success' THEN pi.grand_total ELSE 0 END), 0) as revenue
            FROM itr_packages p
            LEFT JOIN payment_info pi ON p.id = pi.package_id
            WHERE p.isActive = 1
            GROUP BY p.id, p.packagename, p.price
            ORDER BY p.id";
    $result = $conn->query($sql);
    $packageStats = [];
    if ($result && $result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $packageStats[] = [
                "id" => (int)$row['id'],
                "name" => $row['packagename'],
                "price" => floatval($row['price']),
                "orderCount" => (int)$row['order_count'],
                "revenue" => floatval($row['revenue'])
            ];
        }
    }
    
    // Payment Status Breakdown
    $sql = "SELECT 
                payment_status,
                COUNT(*) as count,
                COALESCE(SUM(grand_total), 0) as amount
            FROM payment_info
            GROUP BY payment_status";
    $result = $conn->query($sql);
    $paymentStatusBreakdown = [];
    if ($result && $result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $paymentStatusBreakdown[] = [
                "status" => $row['payment_status'],
                "count" => (int)$row['count'],
                "amount" => floatval($row['amount'])
            ];
        }
    }
    
    // Recent Activity (Last 10 records)
    $recentActivity = [];
    
    // Recent payments
    $sql = "SELECT 
                'payment' as type,
                pi.payment_id as id,
                pi.order_id as reference,
                u.Email as user_email,
                pi.grand_total as amount,
                pi.payment_status as status,
                pi.created_at as created_at
            FROM payment_info pi
            JOIN users u ON pi.user_id = u.UserId
            ORDER BY pi.created_at DESC
            LIMIT 5";
    $result = $conn->query($sql);
    if ($result && $result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $recentActivity[] = [
                "type" => $row['type'],
                "id" => $row['id'],
                "reference" => $row['reference'],
                "userEmail" => $row['user_email'],
                "amount" => floatval($row['amount']),
                "status" => $row['status'],
                "createdAt" => $row['created_at']
            ];
        }
    }
    
    // Build response
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "summary" => [
                "totalUsers" => (int)$totalUsers,
                "totalOrders" => (int)$totalOrders,
                "totalPayments" => (int)$totalPayments,
                "successfulPayments" => (int)$successfulPayments,
                "pendingPayments" => (int)$pendingPayments,
                "pendingConcerns" => (int)$pendingConcerns,
                "totalRevenue" => round($totalRevenue, 2),
                "todayRevenue" => round($todayRevenue, 2),
                "monthRevenue" => round($monthRevenue, 2)
            ],
            "recent" => [
                "users" => (int)$recentUsers,
                "orders" => (int)$recentOrders,
                "payments" => (int)$recentPayments
            ],
            "packageStats" => $packageStats,
            "paymentStatusBreakdown" => $paymentStatusBreakdown,
            "recentActivity" => $recentActivity
        ]
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Failed to fetch dashboard data: " . $e->getMessage()]
    ]);
}
exit;
?>
