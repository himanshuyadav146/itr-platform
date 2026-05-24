<?php
/**
 * Admin Status Configuration Management API
 * CRUD operations for status step configurations
 * 
 * Endpoints:
 * - GET /admin/status_config.php - List all configurations
 * - POST /admin/status_config.php - Create new step configuration
 * - PUT /admin/status_config.php - Update existing configuration
 * - DELETE /admin/status_config.php?id={id} - Deactivate configuration
 * 
 * Auth: ADMIN only
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require '../include/config.php';
require '../phpjwt/Token.php';

// ========================================
// AUTHENTICATION - ADMIN ONLY
// ========================================
$headers = getallheaders();
$token = isset($headers['Authorization']) ? str_replace("Bearer ", "", trim($headers['Authorization'])) : "";

if (empty($token)) {
    http_response_code(401);
    echo json_encode(["status" => "error", "statusCode" => 401, "data" => ["message" => "Authorization token required"]]);
    exit;
}

$decoded = Token::Verify($token, $key);
if ($decoded === false) {
    http_response_code(401);
    echo json_encode(["status" => "error", "statusCode" => 401, "data" => ["message" => "Invalid or expired token"]]);
    exit;
}

$userRole = $decoded['Role'] ?? null;

if ($userRole !== 'ADMIN') {
    http_response_code(403);
    echo json_encode(["status" => "error", "statusCode" => 403, "data" => ["message" => "Admin access only"]]);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];

// ========================================
// GET - List all configurations
// ========================================
if ($method === 'GET') {
    $sql = "SELECT * FROM itr_status_config ORDER BY display_order ASC";
    $result = $conn->query($sql);
    $configs = [];
    
    if ($result && $result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $configs[] = [
                "id" => (int)$row['id'],
                "stepCode" => $row['step_code'],
                "title" => $row['title'],
                "subtitle" => $row['subtitle'],
                "description" => $row['description'],
                "displayOrder" => (int)$row['display_order'],
                "icon" => $row['icon'],
                "color" => $row['color'],
                "isAutomatic" => (bool)$row['is_automatic'],
                "requiresAssignment" => (bool)$row['requires_assignment'],
                "requiresDocuments" => (bool)$row['requires_documents'],
                "canBeReverted" => (bool)$row['can_be_reverted'],
                "requiredRole" => $row['required_role'],
                "isActive" => (bool)$row['is_active'],
                "createdAt" => $row['created_at'],
                "updatedAt" => $row['updated_at']
            ];
        }
    }
    
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "configs" => $configs,
            "total" => count($configs)
        ]
    ], JSON_PRETTY_PRINT);
}

// ========================================
// POST - Create new configuration
// ========================================
elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $stepCode = $input['stepCode'] ?? null;
    $title = $input['title'] ?? null;
    
    if (!$stepCode || !$title) {
        http_response_code(400);
        echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "stepCode and title are required"]]);
        exit;
    }
    
    $subtitle = $input['subtitle'] ?? null;
    $description = $input['description'] ?? null;
    $displayOrder = $input['displayOrder'] ?? 999;
    $icon = $input['icon'] ?? null;
    $color = $input['color'] ?? '#6c757d';
    $isAutomatic = isset($input['isAutomatic']) ? (int)$input['isAutomatic'] : 0;
    $requiresAssignment = isset($input['requiresAssignment']) ? (int)$input['requiresAssignment'] : 0;
    $requiresDocuments = isset($input['requiresDocuments']) ? (int)$input['requiresDocuments'] : 0;
    $canBeReverted = isset($input['canBeReverted']) ? (int)$input['canBeReverted'] : 1;
    $requiredRole = $input['requiredRole'] ?? null;
    
    $sql = "INSERT INTO itr_status_config 
            (step_code, title, subtitle, description, display_order, icon, color, is_automatic, requires_assignment, requires_documents, can_be_reverted, required_role)
            VALUES 
            ('" . mysqli_real_escape_string($conn, $stepCode) . "', 
             '" . mysqli_real_escape_string($conn, $title) . "', 
             " . ($subtitle ? "'" . mysqli_real_escape_string($conn, $subtitle) . "'" : "NULL") . ", 
             " . ($description ? "'" . mysqli_real_escape_string($conn, $description) . "'" : "NULL") . ", 
             $displayOrder, 
             " . ($icon ? "'" . mysqli_real_escape_string($conn, $icon) . "'" : "NULL") . ", 
             '" . mysqli_real_escape_string($conn, $color) . "', 
             $isAutomatic, 
             $requiresAssignment, 
             $requiresDocuments, 
             $canBeReverted, 
             " . ($requiredRole ? "'" . mysqli_real_escape_string($conn, $requiredRole) . "'" : "NULL") . ")";
    
    if ($conn->query($sql)) {
        http_response_code(201);
        echo json_encode([
            "status" => "success",
            "statusCode" => 201,
            "data" => [
                "message" => "Status configuration created successfully",
                "id" => $conn->insert_id
            ]
        ], JSON_PRETTY_PRINT);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to create configuration: " . $conn->error]
        ]);
    }
}

// ========================================
// PUT - Update configuration
// ========================================
elseif ($method === 'PUT') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $id = $input['id'] ?? null;
    if (!$id) {
        http_response_code(400);
        echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "id is required"]]);
        exit;
    }
    
    $updates = [];
    if (isset($input['title'])) $updates[] = "title = '" . mysqli_real_escape_string($conn, $input['title']) . "'";
    if (isset($input['subtitle'])) $updates[] = "subtitle = '" . mysqli_real_escape_string($conn, $input['subtitle']) . "'";
    if (isset($input['description'])) $updates[] = "description = '" . mysqli_real_escape_string($conn, $input['description']) . "'";
    if (isset($input['displayOrder'])) $updates[] = "display_order = " . (int)$input['displayOrder'];
    if (isset($input['icon'])) $updates[] = "icon = '" . mysqli_real_escape_string($conn, $input['icon']) . "'";
    if (isset($input['color'])) $updates[] = "color = '" . mysqli_real_escape_string($conn, $input['color']) . "'";
    if (isset($input['isAutomatic'])) $updates[] = "is_automatic = " . (int)$input['isAutomatic'];
    if (isset($input['requiresAssignment'])) $updates[] = "requires_assignment = " . (int)$input['requiresAssignment'];
    if (isset($input['requiresDocuments'])) $updates[] = "requires_documents = " . (int)$input['requiresDocuments'];
    if (isset($input['canBeReverted'])) $updates[] = "can_be_reverted = " . (int)$input['canBeReverted'];
    if (isset($input['requiredRole'])) $updates[] = "required_role = " . ($input['requiredRole'] ? "'" . mysqli_real_escape_string($conn, $input['requiredRole']) . "'" : "NULL");
    if (isset($input['isActive'])) $updates[] = "is_active = " . (int)$input['isActive'];
    
    if (empty($updates)) {
        http_response_code(400);
        echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "No fields to update"]]);
        exit;
    }
    
    $sql = "UPDATE itr_status_config SET " . implode(", ", $updates) . " WHERE id = " . (int)$id;
    
    if ($conn->query($sql)) {
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => ["message" => "Configuration updated successfully"]
        ], JSON_PRETTY_PRINT);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to update: " . $conn->error]
        ]);
    }
}

// ========================================
// DELETE - Soft delete (deactivate)
// ========================================
elseif ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if (!$id) {
        http_response_code(400);
        echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "id parameter required"]]);
        exit;
    }
    
    $sql = "UPDATE itr_status_config SET is_active = 0 WHERE id = " . (int)$id;
    
    if ($conn->query($sql)) {
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => ["message" => "Configuration deactivated successfully"]
        ], JSON_PRETTY_PRINT);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to deactivate: " . $conn->error]
        ]);
    }
}

else {
    http_response_code(405);
    echo json_encode(["status" => "error", "statusCode" => 405, "data" => ["message" => "Method not allowed"]]);
}

exit;
?>
