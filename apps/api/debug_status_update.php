<?php
/**
 * Debug script for update_status_step 500 errors
 * Helps identify the cause of failures
 * 
 * Usage: GET or POST with orderId and statusStep
 * DELETE THIS FILE IN PRODUCTION
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);
header("Content-Type: application/json");

require 'include/config.php';

$input = json_decode(file_get_contents('php://input'), true) ?? [];
$orderId = $input['orderId'] ?? $_GET['orderId'] ?? 'order_NMAbCdEfGhIj123';
$statusStep = $input['statusStep'] ?? $_GET['statusStep'] ?? 'documents_verified';

$diagnostics = [];

// 1. Check payment_info columns
$piColCheck = $conn->query("SHOW COLUMNS FROM payment_info");
$piColList = [];
if ($piColCheck) {
    while ($r = $piColCheck->fetch_assoc()) {
        $piColList[] = $r['Field'];
    }
}
$diagnostics['payment_info'] = [
    'columns' => $piColList,
    'has_itr_id' => in_array('itr_id', $piColList),
];

// 2. Check if order exists
$orderSql = "SELECT user_id, payment_id, pan_number FROM payment_info WHERE order_id = '" . mysqli_real_escape_string($conn, $orderId) . "' LIMIT 1";
$orderResult = $conn->query($orderSql);
$diagnostics['order_lookup'] = [
    'query_ok' => (bool)$orderResult,
    'mysql_error' => $orderResult ? null : $conn->error,
    'order_found' => $orderResult && $orderResult->num_rows > 0,
];
if ($orderResult && $orderResult->num_rows > 0) {
    $diagnostics['order_data'] = $orderResult->fetch_assoc();
}

// 3. Check itr_assignments structure
$iaColCheck = $conn->query("SHOW COLUMNS FROM itr_assignments");
$iaColList = [];
if ($iaColCheck) {
    while ($r = $iaColCheck->fetch_assoc()) {
        $iaColList[] = $r['Field'];
    }
}
$diagnostics['itr_assignments'] = [
    'columns' => $iaColList,
    'has_assigned_to' => in_array('assigned_to', $iaColList),
    'has_professional_id' => in_array('professional_id', $iaColList),
    'has_status' => in_array('status', $iaColList),
    'has_is_active' => in_array('is_active', $iaColList),
];

// 4. Check itr_status_config table
$configCheck = $conn->query("SHOW TABLES LIKE 'itr_status_config'");
$diagnostics['itr_status_config'] = [
    'table_exists' => $configCheck && $configCheck->num_rows > 0,
];

// 5. Check itr_status_audit table
$auditCheck = $conn->query("SHOW TABLES LIKE 'itr_status_audit'");
$diagnostics['itr_status_audit'] = [
    'table_exists' => $auditCheck && $auditCheck->num_rows > 0,
];

echo json_encode([
    "status" => "debug",
    "orderId" => $orderId,
    "statusStep" => $statusStep,
    "diagnostics" => $diagnostics,
    "recommendations" => [
        "order_not_found" => "Use a real order_id from: SELECT order_id FROM payment_info LIMIT 5",
        "itr_status_config_missing" => "Run: migrations/create_dynamic_status_system.sql",
        "uses_assigned_to" => "API now supports both assigned_to and professional_id columns",
    ]
], JSON_PRETTY_PRINT);
