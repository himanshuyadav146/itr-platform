<?php
/**
 * Account Deletion API
 * Allows authenticated users to permanently delete their account and all associated data.
 * Requires JWT token - user can only delete their own account.
 *
 * POST /auth/delete_account.php
 * Headers: Authorization: Bearer <JWT>
 * Body (optional): { "password": "...", "confirm": "DELETE" } - for extra confirmation
 */

// DEBUG MODE - Set to false after debugging. Logs to delete_account_debug.log in api folder
define('DELETE_ACCOUNT_DEBUG', true);
$_DEBUG_LAST_STEP = 0;
function _debugLog($step, $msg = '', $data = null) {
    global $_DEBUG_LAST_STEP;
    $_DEBUG_LAST_STEP = $step;
    if (!defined('DELETE_ACCOUNT_DEBUG') || !DELETE_ACCOUNT_DEBUG) return;
    $logFile = dirname(__DIR__) . '/delete_account_debug.log';
    $line = date('Y-m-d H:i:s') . " | STEP $step | $msg" . ($data !== null ? ' | ' . json_encode($data) : '') . "\n";
    @file_put_contents($logFile, $line, FILE_APPEND | LOCK_EX);
}
register_shutdown_function(function() {
    if (!defined('DELETE_ACCOUNT_DEBUG') || !DELETE_ACCOUNT_DEBUG) return;
    global $_DEBUG_LAST_STEP;
    $error = error_get_last();
    if ($error && in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR])) {
        $logFile = dirname(__DIR__) . '/delete_account_debug.log';
        $line = date('Y-m-d H:i:s') . " | FATAL | Last step: $_DEBUG_LAST_STEP | " . $error['message'] . " in " . $error['file'] . ":" . $error['line'] . "\n";
        @file_put_contents($logFile, $line, FILE_APPEND | LOCK_EX);
    }
});

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

_debugLog(0, 'START');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

_debugLog(1, 'Loading config');
require __DIR__ . '/../include/config.php';
require __DIR__ . '/../phpjwt/Token.php';

_debugLog(2, 'Config loaded', ['conn_set' => isset($conn), 'key_set' => isset($key)]);
if (!isset($conn) || !$conn) {
    http_response_code(500);
    echo json_encode(["status" => "error", "statusCode" => 500, "data" => ["message" => "Server configuration error"]]);
    exit;
}

// Only POST allowed
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Only POST request allowed"]
    ]);
    exit;
}

_debugLog(3, 'Reading token');
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

_debugLog(4, 'Token extracted', ['has_token' => !empty($token), 'token_len' => strlen($token)]);
if (empty($token)) {
    _debugLog(4, 'ABORT: No token');
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" => ["message" => "Authorization token required"]
    ]);
    exit;
}

_debugLog(5, 'Verifying token');
// Verify Token
$decoded = Token::Verify($token, $key);
if ($decoded === false) {
    _debugLog(5, 'ABORT: Token invalid');
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" => ["message" => "Invalid or expired token"]
    ]);
    exit;
}

_debugLog(6, 'Token verified');
$userId = $decoded['UserId'] ?? null;
if (!$userId) {
    _debugLog(6, 'ABORT: UserId missing in token');
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" => ["message" => "UserId missing in token"]
    ]);
    exit;
}

_debugLog(7, 'UserId ok', ['userId' => $userId]);
$userIdEscaped = mysqli_real_escape_string($conn, $userId);
$apiRoot = dirname(__DIR__);

// Optional: password confirmation for extra security
$input = file_get_contents("php://input");
$data = $input ? json_decode($input, true) : [];
if (is_array($data) && !empty($data['password'])) {
    $password = trim($data['password']);
    $checkSql = "SELECT Password FROM users WHERE UserId = '$userIdEscaped' LIMIT 1";
    $checkResult = $conn->query($checkSql);
    if ($checkResult && $checkResult->num_rows > 0) {
        $row = $checkResult->fetch_assoc();
        if (trim($row['Password']) !== $password) {
            http_response_code(400);
            echo json_encode([
                "status" => "error",
                "statusCode" => 400,
                "data" => ["message" => "Invalid password"]
            ]);
            exit;
        }
    }
}

_debugLog(8, 'Checking user exists');
$userCheck = $conn->query("SELECT UserId FROM users WHERE UserId = '$userIdEscaped' LIMIT 1");
if (!$userCheck || $userCheck->num_rows === 0) {
    _debugLog(8, 'ABORT: User not found');
    http_response_code(404);
    echo json_encode([
        "status" => "error",
        "statusCode" => 404,
        "data" => ["message" => "User not found"]
    ]);
    exit;
}

_debugLog(9, 'Checking role');
// Block deletion for professional accounts (they may have assignments/audit entries)
// Use @ to avoid 500 if Role/role column doesn't exist on prod
$role = '';
$roleCheck = @$conn->query("SELECT Role as r FROM users WHERE UserId = '$userIdEscaped' LIMIT 1");
if (!$roleCheck || $roleCheck->num_rows === 0) {
    $roleCheck = @$conn->query("SELECT role as r FROM users WHERE UserId = '$userIdEscaped' LIMIT 1");
}
if ($roleCheck && $roleCheck->num_rows > 0) {
    $row = $roleCheck->fetch_assoc();
    $role = $row['r'] ?? '';
    _debugLog(9, 'Role check done', ['role' => $role]);
    $professionalRoles = ['CA', 'ACCOUNTANT', 'ADMIN'];
    if (in_array(strtoupper($role), $professionalRoles)) {
        _debugLog(9, 'ABORT: Professional account');
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "Professional accounts cannot be deleted via this endpoint. Contact administrator."]
        ]);
        exit;
    }
}

// ========================================================================
// FILE CLEANUP (optional - skip if table missing or empty, never block)
// We only require: user exists. If document_details/itr_order_concerns exist
// and have data, clean up files. Otherwise proceed to delete user only.
// ========================================================================

_debugLog(10, 'Querying document_details');
// 1. Document files (uploads/{PAN}/{fileName}) - best effort, table may not exist
$docResult = @$conn->query("SELECT PanNumber, fileName FROM document_details WHERE UserId = '$userIdEscaped'");
_debugLog(10, 'document_details query', ['success' => $docResult !== false, 'rows' => $docResult ? $docResult->num_rows : 0, 'mysqli_error' => $docResult === false ? $conn->error : null]);
$deletedPanDirs = [];
if ($docResult !== false && $docResult->num_rows > 0) {
    while ($row = $docResult->fetch_assoc()) {
        $pan = trim($row['PanNumber'] ?? '');
        $fileName = trim($row['fileName'] ?? '');
        if (!empty($pan) && !empty($fileName)) {
            $filePath = $apiRoot . '/uploads/' . $pan . '/' . $fileName;
            if (file_exists($filePath)) {
                @unlink($filePath);
            }
            $deletedPanDirs[$pan] = true;
        }
    }
    foreach (array_keys($deletedPanDirs) as $pan) {
        $dir = $apiRoot . '/uploads/' . $pan . '/';
        if (is_dir($dir) && count(glob($dir . '*')) === 0) {
            @rmdir($dir);
        }
    }
}

_debugLog(11, 'Querying itr_order_concerns');
$concernResult = @$conn->query("SELECT concern_image_path FROM itr_order_concerns WHERE user_id = '$userIdEscaped' AND concern_image_path IS NOT NULL AND concern_image_path != ''");
_debugLog(11, 'itr_order_concerns query', ['success' => $concernResult !== false, 'rows' => $concernResult ? $concernResult->num_rows : 0, 'mysqli_error' => $concernResult === false ? $conn->error : null]);
if ($concernResult !== false && $concernResult->num_rows > 0) {
    while ($row = $concernResult->fetch_assoc()) {
        $relPath = trim($row['concern_image_path']);
        if (!empty($relPath)) {
            $fullPath = $apiRoot . '/' . $relPath;
            if (file_exists($fullPath)) {
                @unlink($fullPath);
            }
            // Try to remove parent directory if empty
            $parentDir = dirname($fullPath);
            if (is_dir($parentDir) && count(glob($parentDir . '/*')) === 0) {
                @rmdir($parentDir);
            }
        }
    }
}

// 3. Delete user_journey first (prod may have RESTRICT instead of CASCADE on userId FK)
_debugLog(12, 'Deleting user_journey');
$journeyDeleted = @$conn->query("DELETE FROM user_journey WHERE userId = '$userIdEscaped'");
_debugLog(12, 'user_journey deleted', ['success' => $journeyDeleted !== false]);

_debugLog(13, 'Executing DELETE FROM users');
// ========================================================================
// MAIN: Delete user record (always runs if we reached here)
// CASCADE will auto-delete from: personal_details, document_details, itr_detail,
// itr_source, payment_info, itr_order_status, itr_order_concerns, itr_assignments
// Note: user_journey deleted explicitly above (prod FK may be RESTRICT)
// ========================================================================
$deleteSql = "DELETE FROM users WHERE UserId = '$userIdEscaped'";
$deleteResult = $conn->query($deleteSql);

if ($deleteResult) {
    _debugLog(13, 'DELETE succeeded', ['affected_rows' => $conn->affected_rows]);
    if ($conn->affected_rows > 0) {
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "message" => "Your account and all associated data have been permanently deleted."
            ]
        ]);
    } else {
        _debugLog(13, 'ABORT: DELETE affected 0 rows');
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to delete account"]
        ]);
    }
} else {
    $errMsg = $conn->error ?? '';
    _debugLog(13, 'ABORT: DELETE failed', ['error' => $errMsg]);
    // Handle FK RESTRICT (e.g. if user appears in itr_status_audit.updated_by or itr_assignments.professional_id)
    if (strpos($errMsg, 'foreign key') !== false || strpos($errMsg, 'RESTRICT') !== false || strpos($errMsg, '1451') !== false) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "Account cannot be deleted due to system constraints. Please contact support."]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to delete account. Please try again or contact support."]
        ]);
    }
}
_debugLog(99, 'END');
?>
