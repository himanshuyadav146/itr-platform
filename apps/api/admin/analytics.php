<?php
/**
 * Admin Analytics/Reports API
 * Get analytics data and reports
 * 
 * Endpoints: 
 * - GET /admin/analytics.php - Get overall analytics
 * - GET /admin/analytics.php?type=revenue - Get revenue analytics
 * - GET /admin/analytics.php?type=users - Get user analytics
 * - GET /admin/analytics.php?type=orders - Get order analytics
 */

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

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

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only GET method allowed"]
    ]);
    exit;
}

$type = $_GET['type'] ?? 'overview';
$period = $_GET['period'] ?? '7'; // days

try {
    $analytics = [];
    
    if ($type === 'overview' || $type === 'revenue') {
        // Revenue Analytics - Daily for last N days
        $revenueData = [];
        for ($i = $period - 1; $i >= 0; $i--) {
            $date = date('Y-m-d', strtotime("-$i days"));
            $sql = "SELECT 
                        DATE(paid_at) as date,
                        COUNT(*) as transaction_count,
                        COALESCE(SUM(grand_total), 0) as total_revenue,
                        COALESCE(SUM(subtotal), 0) as subtotal,
                        COALESCE(SUM(gst_amount), 0) as gst_amount
                    FROM payment_info
                    WHERE payment_status = 'success' AND DATE(paid_at) = '$date'
                    GROUP BY DATE(paid_at)";
            
            $result = $conn->query($sql);
            if ($result && $result->num_rows > 0) {
                $row = $result->fetch_assoc();
                $revenueData[] = [
                    "date" => $row['date'],
                    "transactionCount" => (int)$row['transaction_count'],
                    "totalRevenue" => floatval($row['total_revenue']),
                    "subtotal" => floatval($row['subtotal']),
                    "gstAmount" => floatval($row['gst_amount'])
                ];
            } else {
                $revenueData[] = [
                    "date" => $date,
                    "transactionCount" => 0,
                    "totalRevenue" => 0,
                    "subtotal" => 0,
                    "gstAmount" => 0
                ];
            }
        }
        $analytics['revenue'] = $revenueData;
        
        // Revenue by Package
        $sql = "SELECT 
                    p.id,
                    p.packagename,
                    COUNT(pi.id) as transaction_count,
                    COALESCE(SUM(pi.grand_total), 0) as total_revenue
                FROM itr_packages p
                LEFT JOIN payment_info pi ON p.id = pi.package_id AND pi.payment_status = 'success'
                WHERE p.isActive = 1
                GROUP BY p.id, p.packagename
                ORDER BY total_revenue DESC";
        $result = $conn->query($sql);
        $revenueByPackage = [];
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $revenueByPackage[] = [
                    "packageId" => (int)$row['id'],
                    "packageName" => $row['packagename'],
                    "transactionCount" => (int)$row['transaction_count'],
                    "totalRevenue" => floatval($row['total_revenue'])
                ];
            }
        }
        $analytics['revenueByPackage'] = $revenueByPackage;
        
        // Revenue by Payment Method
        $sql = "SELECT 
                    payment_method,
                    COUNT(*) as transaction_count,
                    COALESCE(SUM(grand_total), 0) as total_revenue
                FROM payment_info
                WHERE payment_status = 'success' AND payment_method IS NOT NULL
                GROUP BY payment_method
                ORDER BY total_revenue DESC";
        $result = $conn->query($sql);
        $revenueByMethod = [];
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $revenueByMethod[] = [
                    "paymentMethod" => $row['payment_method'],
                    "transactionCount" => (int)$row['transaction_count'],
                    "totalRevenue" => floatval($row['total_revenue'])
                ];
            }
        }
        $analytics['revenueByMethod'] = $revenueByMethod;
    }
    
    if ($type === 'overview' || $type === 'users') {
        // User Analytics - Daily registration for last N days
        $userData = [];
        for ($i = $period - 1; $i >= 0; $i--) {
            $date = date('Y-m-d', strtotime("-$i days"));
            $sql = "SELECT 
                        DATE(CreatedAt) as date,
                        COUNT(*) as user_count
                    FROM users
                    WHERE DATE(CreatedAt) = '$date'
                    GROUP BY DATE(CreatedAt)";
            
            $result = $conn->query($sql);
            if ($result && $result->num_rows > 0) {
                $row = $result->fetch_assoc();
                $userData[] = [
                    "date" => $row['date'],
                    "userCount" => (int)$row['user_count']
                ];
            } else {
                $userData[] = [
                    "date" => $date,
                    "userCount" => 0
                ];
            }
        }
        $analytics['users'] = $userData;
        
        // Users by Platform
        $sql = "SELECT 
                    Platform,
                    COUNT(*) as user_count
                FROM users
                GROUP BY Platform
                ORDER BY user_count DESC";
        $result = $conn->query($sql);
        $usersByPlatform = [];
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $usersByPlatform[] = [
                    "platform" => $row['Platform'],
                    "userCount" => (int)$row['user_count']
                ];
            }
        }
        $analytics['usersByPlatform'] = $usersByPlatform;
    }
    
    if ($type === 'overview' || $type === 'orders') {
        // Order Analytics - Daily orders for last N days
        $orderData = [];
        for ($i = $period - 1; $i >= 0; $i--) {
            $date = date('Y-m-d', strtotime("-$i days"));
            $sql = "SELECT 
                        DATE(created_at) as date,
                        COUNT(*) as order_count,
                        SUM(CASE WHEN payment_status = 'success' THEN 1 ELSE 0 END) as successful_orders,
                        SUM(CASE WHEN payment_status = 'pending' THEN 1 ELSE 0 END) as pending_orders
                    FROM payment_info
                    WHERE DATE(created_at) = '$date'
                    GROUP BY DATE(created_at)";
            
            $result = $conn->query($sql);
            if ($result && $result->num_rows > 0) {
                $row = $result->fetch_assoc();
                $orderData[] = [
                    "date" => $row['date'],
                    "orderCount" => (int)$row['order_count'],
                    "successfulOrders" => (int)$row['successful_orders'],
                    "pendingOrders" => (int)$row['pending_orders']
                ];
            } else {
                $orderData[] = [
                    "date" => $date,
                    "orderCount" => 0,
                    "successfulOrders" => 0,
                    "pendingOrders" => 0
                ];
            }
        }
        $analytics['orders'] = $orderData;
        
        // Orders by Status
        $sql = "SELECT 
                    payment_status,
                    COUNT(*) as order_count
                FROM payment_info
                GROUP BY payment_status
                ORDER BY order_count DESC";
        $result = $conn->query($sql);
        $ordersByStatus = [];
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $ordersByStatus[] = [
                    "status" => $row['payment_status'],
                    "orderCount" => (int)$row['order_count']
                ];
            }
        }
        $analytics['ordersByStatus'] = $ordersByStatus;
    }
    
    // Overall Statistics (always included)
    $overallStats = [];
    
    // Total Revenue
    $sql = "SELECT COALESCE(SUM(grand_total), 0) as total FROM payment_info WHERE payment_status = 'success'";
    $result = $conn->query($sql);
    $overallStats['totalRevenue'] = $result ? floatval($result->fetch_assoc()['total']) : 0;
    
    // Total Users
    $sql = "SELECT COUNT(*) as total FROM users";
    $result = $conn->query($sql);
    $overallStats['totalUsers'] = $result ? (int)$result->fetch_assoc()['total'] : 0;
    
    // Total Orders
    $sql = "SELECT COUNT(*) as total FROM payment_info";
    $result = $conn->query($sql);
    $overallStats['totalOrders'] = $result ? (int)$result->fetch_assoc()['total'] : 0;
    
    // Successful Orders
    $sql = "SELECT COUNT(*) as total FROM payment_info WHERE payment_status = 'success'";
    $result = $conn->query($sql);
    $overallStats['successfulOrders'] = $result ? (int)$result->fetch_assoc()['total'] : 0;
    
    // Average Order Value
    $sql = "SELECT COALESCE(AVG(grand_total), 0) as avg FROM payment_info WHERE payment_status = 'success'";
    $result = $conn->query($sql);
    $overallStats['averageOrderValue'] = $result ? floatval($result->fetch_assoc()['avg']) : 0;
    
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "analytics" => $analytics,
            "overallStats" => $overallStats,
            "period" => (int)$period,
            "type" => $type
        ]
    ], JSON_UNESCAPED_UNICODE);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Failed to fetch analytics: " . $e->getMessage()]
    ]);
}

exit;
?>
