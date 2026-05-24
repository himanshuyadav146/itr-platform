<?php
// Debug script to check package table status
header("Content-Type: application/json");
error_reporting(E_ALL);
ini_set('display_errors', 1);

require 'include/config.php';

$debug = [];

// Check connection
if (!$conn) {
    $debug['error'] = 'Database connection failed: ' . mysqli_connect_error();
    echo json_encode($debug, JSON_PRETTY_PRINT);
    exit;
}

$debug['connection'] = 'OK';
$debug['database'] = $conn->query("SELECT DATABASE()")->fetch_row()[0];

// Check if table exists
$result = $conn->query("SHOW TABLES LIKE 'itr_packages'");
$debug['table_exists'] = $result->num_rows > 0;

if (!$debug['table_exists']) {
    $debug['error'] = 'Table itr_packages does not exist!';
    echo json_encode($debug, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    exit;
}

// Check table structure
$result = $conn->query("DESCRIBE itr_packages");
$debug['columns'] = [];
while ($row = $result->fetch_assoc()) {
    $debug['columns'][] = $row['Field'];
}

// Check if new columns exist
$debug['has_turnover_column'] = in_array('turnover', $debug['columns']);
$debug['has_icon_column'] = in_array('icon', $debug['columns']);
$debug['has_color_column'] = in_array('color', $debug['columns']);

// Count total packages
$result = $conn->query("SELECT COUNT(*) as total FROM itr_packages");
$row = $result->fetch_assoc();
$debug['total_packages'] = (int)$row['total'];

// Count active packages
$result = $conn->query("SELECT COUNT(*) as total FROM itr_packages WHERE isActive = 1");
$row = $result->fetch_assoc();
$debug['active_packages'] = (int)$row['total'];

// Get all packages (without WHERE clause)
$result = $conn->query("SELECT id, packagename, price, isActive FROM itr_packages ORDER BY id");
$debug['all_packages'] = [];
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $debug['all_packages'][] = $row;
    }
}

// Try the exact query from getPackages.php
$sql = "SELECT 
            id,
            packagename,
            price,
            title1, description1,
            title2, description2,
            turnover,
            icon,
            color,
            isActive,
            createdAt
        FROM itr_packages
        WHERE isActive = 1
        ORDER BY id asc";

$result = $conn->query($sql);
$debug['getPackages_query_error'] = $conn->error;
$debug['getPackages_query_success'] = ($result !== false);

if ($result) {
    $debug['getPackages_result_count'] = $result->num_rows;
    $packages = [];
    while ($row = $result->fetch_assoc()) {
        $packages[] = $row;
    }
    $debug['getPackages_packages'] = $packages;
} else {
    $debug['getPackages_packages'] = [];
}

// Check isActive values
$result = $conn->query("SELECT id, packagename, isActive FROM itr_packages");
$debug['isActive_check'] = [];
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $debug['isActive_check'][] = [
            'id' => $row['id'],
            'name' => $row['packagename'],
            'isActive' => $row['isActive'],
            'isActive_type' => gettype($row['isActive'])
        ];
    }
}

echo json_encode($debug, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
