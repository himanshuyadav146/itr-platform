<?php
/**
 * Migration Script: Populate itr_detail table from existing personal_details
 * 
 * This script creates itr_detail entries for all existing personal_details records
 * that don't already have a corresponding itr_detail entry.
 * 
 * Run this once via browser: http://localhost/api/migrate_itr_details.php
 */

header("Content-Type: application/json");

require 'include/config.php';

if (!$conn) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database connection failed"
    ]);
    exit;
}

// Get all personal_details records that don't have itr_detail entries
$sql = "SELECT DISTINCT 
            pd.UserId, 
            pd.PANNumber, 
            pd.FinancialYear
        FROM personal_details pd
        LEFT JOIN itr_detail itr ON pd.UserId = itr.userId AND pd.PANNumber = itr.panNumber
        WHERE pd.isActive = 1 AND itr.id IS NULL
        ORDER BY pd.UserId, pd.PANNumber";

$result = $conn->query($sql);

if (!$result) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Query error: " . $conn->error
    ]);
    exit;
}

$migrated = 0;
$errors = [];

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $userId = mysqli_real_escape_string($conn, $row['UserId']);
        $panNumber = mysqli_real_escape_string($conn, $row['PANNumber']);
        $financialYear = mysqli_real_escape_string($conn, $row['FinancialYear']);
        
        // Insert into itr_detail
        $insertSql = "INSERT INTO itr_detail (userId, panNumber, financialYear, status, createdAt, updatedAt)
                      VALUES ('$userId', '$panNumber', '$financialYear', 'pending', NOW(), NOW())";
        
        if ($conn->query($insertSql)) {
            $migrated++;
        } else {
            $errors[] = "Error for UserId=$userId, PAN=$panNumber: " . $conn->error;
        }
    }
}

// Get summary
$totalPersonalDetails = 0;
$totalItrDetails = 0;

$countPd = $conn->query("SELECT COUNT(DISTINCT CONCAT(UserId, '-', PANNumber)) as total FROM personal_details WHERE isActive = 1");
if ($countPd) {
    $totalPersonalDetails = $countPd->fetch_assoc()['total'];
}

$countItr = $conn->query("SELECT COUNT(*) as total FROM itr_detail");
if ($countItr) {
    $totalItrDetails = $countItr->fetch_assoc()['total'];
}

http_response_code(200);
echo json_encode([
    "status" => "success",
    "message" => "Migration completed",
    "data" => [
        "migrated" => $migrated,
        "totalPersonalDetails" => (int)$totalPersonalDetails,
        "totalItrDetails" => (int)$totalItrDetails,
        "errors" => $errors
    ]
], JSON_PRETTY_PRINT);

exit;
?>
