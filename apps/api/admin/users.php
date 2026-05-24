<?php
/**
 * Admin Users Management API
 * List, view, update, delete users
 * 
 * Endpoints: 
 * - GET /admin/users.php - List all users (with pagination)
 *   Query Parameters:
 *     - page: Page number (default: 1)
 *     - limit: Items per page (default: 20, max: 100)
 *     - search: Search by email, firstName, lastName, or mobile (optional)
 *     - role: Filter by role - 'user', 'admin', 'CLIENT', etc. (inclusion - optional)
 *     - excludeRole: Exclude users with this role - 'user', 'admin', 'CLIENT', etc. (exclusion - optional)
 *   Note: If both 'role' and 'excludeRole' are provided, 'excludeRole' takes precedence
 *   Examples:
 *     - GET /admin/users.php?page=1&limit=100 - Get all users
 *     - GET /admin/users.php?role=CLIENT - Get all CLIENT role users
 *     - GET /admin/users.php?excludeRole=CLIENT - Get all users except CLIENT role
 *     - GET /admin/users.php?role=admin&page=1&limit=20 - Get admin users
 *     - GET /admin/users.php?search=john&role=user - Search with role filter
 * - GET /admin/users.php?userId={id} - Get single user details
 * - PUT /admin/users.php - Update user
 * - DELETE /admin/users.php?userId={id} - Delete user
 */

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, PUT, DELETE");
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

$method = $_SERVER['REQUEST_METHOD'];

// GET - List users or get single user
if ($method === 'GET') {
    $userId = $_GET['userId'] ?? null;
    
    if ($userId) {
        // Get single user details
        $userIdEscaped = mysqli_real_escape_string($conn, $userId);
        $sql = "SELECT 
                    u.UserId,
                    u.FirstName,
                    u.MiddleName,
                    u.LastName,
                    u.Email,
                    u.Mobile,
                    u.Role,
                    u.Platform,
                    u.Version,
                    u.CreatedAt,
                    u.UpdatedAt,
                    COUNT(DISTINCT pd.id) as personal_details_count,
                    COUNT(DISTINCT dd.id) as documents_count,
                    COUNT(DISTINCT itr.id) as itr_count,
                    COUNT(DISTINCT pi.id) as payments_count,
                    COALESCE(SUM(CASE WHEN pi.payment_status = 'success' THEN pi.grand_total ELSE 0 END), 0) as total_spent
                FROM users u
                LEFT JOIN personal_details pd ON u.UserId = pd.UserId
                LEFT JOIN document_details dd ON u.UserId = dd.UserId AND dd.isActive = 1
                LEFT JOIN itr_detail itr ON u.UserId = itr.userId
                LEFT JOIN payment_info pi ON u.UserId = pi.user_id
                WHERE u.UserId = '$userIdEscaped'
                GROUP BY u.UserId";
        
        $result = $conn->query($sql);
        
        if ($result && $result->num_rows > 0) {
            $user = $result->fetch_assoc();
            http_response_code(200);
            echo json_encode([
                "status" => "success",
                "statusCode" => 200,
                "data" => [
                    "user" => [
                        "userId" => (int)$user['UserId'],
                        "firstName" => $user['FirstName'],
                        "middleName" => $user['MiddleName'],
                        "lastName" => $user['LastName'],
                        "email" => $user['Email'],
                        "mobile" => $user['Mobile'],
                        "role" => $user['Role'] ?? 'user',
                        "platform" => $user['Platform'],
                        "version" => $user['Version'],
                        "createdAt" => $user['CreatedAt'],
                        "updatedAt" => $user['UpdatedAt'],
                        "statistics" => [
                            "personalDetailsCount" => (int)$user['personal_details_count'],
                            "documentsCount" => (int)$user['documents_count'],
                            "itrCount" => (int)$user['itr_count'],
                            "paymentsCount" => (int)$user['payments_count'],
                            "totalSpent" => floatval($user['total_spent'])
                        ]
                    ]
                ]
            ], JSON_UNESCAPED_UNICODE);
        } else {
            http_response_code(404);
            echo json_encode([
                "status" => "error",
                "statusCode" => 404,
                "data" => ["message" => "User not found"]
            ]);
        }
    } else {
        // List all users with pagination
        $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
        $limit = isset($_GET['limit']) ? max(1, min(100, intval($_GET['limit']))) : 20;
        $offset = ($page - 1) * $limit;
        
        // Build filters
        $search = $_GET['search'] ?? '';
        $role = $_GET['role'] ?? '';
        $excludeRole = $_GET['excludeRole'] ?? '';
        $filters = [];
        
        // Search filter
        if (!empty($search)) {
            $searchEscaped = mysqli_real_escape_string($conn, $search);
            $filters[] = "(u.Email LIKE '%$searchEscaped%' 
                           OR u.FirstName LIKE '%$searchEscaped%' 
                           OR u.LastName LIKE '%$searchEscaped%' 
                           OR u.Mobile LIKE '%$searchEscaped%')";
        }
        
        // Role filter (inclusion - get only this role)
        if (!empty($role) && empty($excludeRole)) {
            $roleEscaped = mysqli_real_escape_string($conn, $role);
            $filters[] = "u.Role = '$roleEscaped'";
        }
        
        // Exclude role filter (exclusion - get all except this role)
        if (!empty($excludeRole)) {
            $excludeRoleEscaped = mysqli_real_escape_string($conn, $excludeRole);
            // Exclude users with this role, including handling NULL/empty roles
            $filters[] = "(u.Role IS NULL OR u.Role = '' OR u.Role != '$excludeRoleEscaped')";
        }
        
        // Build WHERE clause
        $whereClause = '';
        if (!empty($filters)) {
            $whereClause = 'WHERE ' . implode(' AND ', $filters);
        }
        
        // Get total count
        $countSql = "SELECT COUNT(DISTINCT u.UserId) as total FROM users u $whereClause";
        $countResult = $conn->query($countSql);
        $totalUsers = $countResult ? $countResult->fetch_assoc()['total'] : 0;
        $totalPages = ceil($totalUsers / $limit);
        
        // Get users
        $sql = "SELECT 
                    u.UserId,
                    u.FirstName,
                    u.MiddleName,
                    u.LastName,
                    u.Email,
                    u.Mobile,
                    u.Role,
                    u.Platform,
                    u.CreatedAt,
                    COUNT(DISTINCT pi.id) as payments_count,
                    COALESCE(SUM(CASE WHEN pi.payment_status = 'success' THEN pi.grand_total ELSE 0 END), 0) as total_spent,
                    COUNT(DISTINCT ia.id) as assigned_count,
                    COUNT(DISTINCT CASE WHEN itr.status = 'completed' THEN ia.id END) as completed_count
                FROM users u
                LEFT JOIN payment_info pi ON u.UserId = pi.user_id
                LEFT JOIN itr_assignments ia ON u.UserId = ia.assigned_to AND ia.is_active = 1
                LEFT JOIN itr_detail itr ON ia.itr_id = itr.id
                $whereClause
                GROUP BY u.UserId
                ORDER BY u.CreatedAt DESC
                LIMIT $limit OFFSET $offset";
        
        $result = $conn->query($sql);
        $users = [];
        
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $users[] = [
                    "userId" => (int)$row['UserId'],
                    "firstName" => $row['FirstName'],
                    "middleName" => $row['MiddleName'],
                    "lastName" => $row['LastName'],
                    "email" => $row['Email'],
                    "mobile" => $row['Mobile'],
                    "role" => $row['Role'] ?? 'user',
                    "platform" => $row['Platform'],
                    "createdAt" => $row['CreatedAt'],
                    "paymentsCount" => (int)$row['payments_count'],
                    "totalSpent" => floatval($row['total_spent']),
                    "assignedCount" => (int)$row['assigned_count'],
                    "completedCount" => (int)$row['completed_count']
                ];
            }
        }
        
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "users" => $users,
                "pagination" => [
                    "page" => $page,
                    "limit" => $limit,
                    "total" => (int)$totalUsers,
                    "totalPages" => $totalPages
                ]
            ]
        ], JSON_UNESCAPED_UNICODE);
    }
}

// PUT - Update user
elseif ($method === 'PUT') {
    $input = file_get_contents("php://input");
    $data = json_decode($input, true);
    
    if (!$data || !isset($data['userId'])) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "userId is required"]
        ]);
        exit;
    }
    
    $userId = mysqli_real_escape_string($conn, $data['userId']);
    $updateFields = [];
    
    if (isset($data['firstName'])) {
        $firstName = mysqli_real_escape_string($conn, $data['firstName']);
        $updateFields[] = "FirstName = '$firstName'";
    }
    if (isset($data['middleName'])) {
        $middleName = mysqli_real_escape_string($conn, $data['middleName']);
        $updateFields[] = "MiddleName = '$middleName'";
    }
    if (isset($data['lastName'])) {
        $lastName = mysqli_real_escape_string($conn, $data['lastName']);
        $updateFields[] = "LastName = '$lastName'";
    }
    if (isset($data['email'])) {
        $email = mysqli_real_escape_string($conn, trim($data['email']));
        // Check if email already exists for another user
        $checkSql = "SELECT UserId FROM users WHERE Email = '$email' AND UserId != '$userId'";
        $checkResult = $conn->query($checkSql);
        if ($checkResult && $checkResult->num_rows > 0) {
            http_response_code(409);
            echo json_encode([
                "status" => "error",
                "statusCode" => 409,
                "data" => ["message" => "Email already exists"]
            ]);
            exit;
        }
        $updateFields[] = "Email = '$email'";
    }
    if (isset($data['mobile'])) {
        $mobile = mysqli_real_escape_string($conn, $data['mobile']);
        $updateFields[] = "Mobile = '$mobile'";
    }
    if (isset($data['password'])) {
        $password = mysqli_real_escape_string($conn, $data['password']);
        $updateFields[] = "Password = '$password'";
    }
    
    if (empty($updateFields)) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "No fields to update"]
        ]);
        exit;
    }
    
    $updateFields[] = "UpdatedAt = NOW()";
    $updateSql = "UPDATE users SET " . implode(", ", $updateFields) . " WHERE UserId = '$userId'";
    
    if ($conn->query($updateSql)) {
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => ["message" => "User updated successfully"]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to update user: " . $conn->error]
        ]);
    }
}

// DELETE - Delete user
elseif ($method === 'DELETE') {
    $userId = $_GET['userId'] ?? null;
    
    if (!$userId) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "userId is required"]
        ]);
        exit;
    }
    
    $userIdEscaped = mysqli_real_escape_string($conn, $userId);
    
    // Check if user exists
    $checkSql = "SELECT UserId FROM users WHERE UserId = '$userIdEscaped'";
    $checkResult = $conn->query($checkSql);
    
    if (!$checkResult || $checkResult->num_rows === 0) {
        http_response_code(404);
        echo json_encode([
            "status" => "error",
            "statusCode" => 404,
            "data" => ["message" => "User not found"]
        ]);
        exit;
    }
    
    // Delete user (cascade will handle related records)
    $deleteSql = "DELETE FROM users WHERE UserId = '$userIdEscaped'";
    
    if ($conn->query($deleteSql)) {
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => ["message" => "User deleted successfully"]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to delete user: " . $conn->error]
        ]);
    }
}

else {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Method not allowed"]
    ]);
}

exit;
?>
