<?php
/**
 * Admin Update Assignment API
 * Update ITR assignment status and details
 * 
 * Endpoints: 
 * - PUT /admin/update_assignment.php - Update assignment
 */

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT");
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

// PUT - Update assignment
if ($method === 'PUT') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "Invalid JSON input"]
        ]);
        exit;
    }
    
    $assignmentId = $input['assignmentId'] ?? null;
    if (!$assignmentId) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "assignmentId is required"]
        ]);
        exit;
    }
    
    $assignmentIdEscaped = mysqli_real_escape_string($conn, $assignmentId);
    
    // Check if assignment exists
    $checkSql = "SELECT id, status FROM itr_assignments WHERE id = '$assignmentIdEscaped'";
    $checkResult = $conn->query($checkSql);
    if (!$checkResult || $checkResult->num_rows === 0) {
        http_response_code(404);
        echo json_encode([
            "status" => "error",
            "statusCode" => 404,
            "data" => ["message" => "Assignment not found"]
        ]);
        exit;
    }
    
    // Build update fields
    $updates = [];
    
    if (isset($input['status'])) {
        $statusEscaped = mysqli_real_escape_string($conn, $input['status']);
        // Validate status
        $validStatuses = ['assigned', 'in_progress', 'completed', 'rejected'];
        if (!in_array($statusEscaped, $validStatuses)) {
            http_response_code(400);
            echo json_encode([
                "status" => "error",
                "statusCode" => 400,
                "data" => ["message" => "Invalid status. Valid values: " . implode(", ", $validStatuses)]
            ]);
            exit;
        }
        $updates[] = "status = '$statusEscaped'";
        
        // If status is completed, set completed_at
        if ($statusEscaped === 'completed') {
            $updates[] = "completed_at = NOW()";
        } elseif ($statusEscaped !== 'completed') {
            // If changing from completed to another status, clear completed_at
            $updates[] = "completed_at = NULL";
        }
    }
    
    if (isset($input['priority'])) {
        $priorityEscaped = mysqli_real_escape_string($conn, $input['priority']);
        // Validate priority
        $validPriorities = ['low', 'normal', 'high', 'urgent'];
        if (!in_array($priorityEscaped, $validPriorities)) {
            http_response_code(400);
            echo json_encode([
                "status" => "error",
                "statusCode" => 400,
                "data" => ["message" => "Invalid priority. Valid values: " . implode(", ", $validPriorities)]
            ]);
            exit;
        }
        $updates[] = "priority = '$priorityEscaped'";
    }
    
    if (isset($input['dueDate'])) {
        if ($input['dueDate'] === null || $input['dueDate'] === '') {
            $updates[] = "due_date = NULL";
        } else {
            $dueDateEscaped = mysqli_real_escape_string($conn, $input['dueDate']);
            $updates[] = "due_date = '$dueDateEscaped'";
        }
    }
    
    if (isset($input['notes'])) {
        $notesEscaped = mysqli_real_escape_string($conn, $input['notes']);
        $updates[] = "notes = '$notesEscaped'";
    }
    
    if (isset($input['professionalId'])) {
        $profIdEscaped = mysqli_real_escape_string($conn, $input['professionalId']);
        // Check if professional exists and has correct role (ACCOUNTANT or CA)
        $profCheckSql = "SELECT UserId FROM users WHERE UserId = '$profIdEscaped' AND Role IN ('ACCOUNTANT', 'CA') AND (IsActive = 1 OR IsActive IS NULL)";
        $profCheckResult = $conn->query($profCheckSql);
        if (!$profCheckResult || $profCheckResult->num_rows === 0) {
            http_response_code(404);
            echo json_encode([
                "status" => "error",
                "statusCode" => 404,
                "data" => ["message" => "Professional not found. User must have Role='ACCOUNTANT' or Role='CA' and be active"]
            ]);
            exit;
        }
        $updates[] = "professional_id = '$profIdEscaped'";
    }
    
    if (empty($updates)) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "No fields to update"]
        ]);
        exit;
    }
    
    $sql = "UPDATE itr_assignments SET " . implode(", ", $updates) . " WHERE id = '$assignmentIdEscaped'";
    
    if ($conn->query($sql)) {
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => ["message" => "Assignment updated successfully"]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Error updating assignment: " . $conn->error]
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
