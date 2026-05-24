<?php
// Database Diagnostic Script
header("Content-Type: application/json");

require 'include/config.php';

$status = [
    "database_connection" => false,
    "itr_packages_table_exists" => false,
    "turnover_column_exists" => false,
    "icon_column_exists" => false,
    "color_column_exists" => false,
    "package_id_column_in_personal_details" => false,
    "total_packages" => 0,
    "packages" => []
];

// Check database connection
if ($conn) {
    $status["database_connection"] = true;
    
    // Check if itr_packages table exists
    $result = $conn->query("SHOW TABLES LIKE 'itr_packages'");
    if ($result && $result->num_rows > 0) {
        $status["itr_packages_table_exists"] = true;
        
        // Check for new columns
        $result = $conn->query("SHOW COLUMNS FROM itr_packages LIKE 'turnover'");
        $status["turnover_column_exists"] = ($result && $result->num_rows > 0);
        
        $result = $conn->query("SHOW COLUMNS FROM itr_packages LIKE 'icon'");
        $status["icon_column_exists"] = ($result && $result->num_rows > 0);
        
        $result = $conn->query("SHOW COLUMNS FROM itr_packages LIKE 'color'");
        $status["color_column_exists"] = ($result && $result->num_rows > 0);
        
        // Count packages
        $result = $conn->query("SELECT COUNT(*) as count FROM itr_packages");
        if ($result) {
            $row = $result->fetch_assoc();
            $status["total_packages"] = (int)$row['count'];
        }
        
        // Get all packages
        $result = $conn->query("SELECT * FROM itr_packages ORDER BY id");
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $status["packages"][] = $row;
            }
        }
    }
    
    // Check personal_details table
    $result = $conn->query("SHOW COLUMNS FROM personal_details LIKE 'package_id'");
    $status["package_id_column_in_personal_details"] = ($result && $result->num_rows > 0);
}

// Determine what needs to be done
$status["action_required"] = [];

if (!$status["turnover_column_exists"] || !$status["icon_column_exists"] || !$status["color_column_exists"]) {
    $status["action_required"][] = "Run migration to add new columns to itr_packages table";
}

if (!$status["package_id_column_in_personal_details"]) {
    $status["action_required"][] = "Run migration to add package_id to personal_details table";
}

if ($status["total_packages"] == 0) {
    $status["action_required"][] = "Run migration to insert packages data";
}

if (empty($status["action_required"])) {
    $status["action_required"][] = "Everything is ready! No action needed.";
}

echo json_encode($status, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
