<?php
/**
 * Check ITR Data - Diagnostic Script
 * Shows what data exists in personal_details vs itr_detail
 * 
 * Run via browser: http://localhost/api/check_itr_data.php
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

// Check personal_details
$pdSql = "SELECT 
            id as personal_detail_id,
            UserId, 
            PANNumber, 
            FirstName,
            LastName,
            FinancialYear
        FROM personal_details 
        WHERE isActive = 1
        ORDER BY id ASC
        LIMIT 20";

$pdResult = $conn->query($pdSql);
$personalDetails = [];

if ($pdResult && $pdResult->num_rows > 0) {
    while ($row = $pdResult->fetch_assoc()) {
        $personalDetails[] = [
            "personalDetailId" => (int)$row['personal_detail_id'],
            "userId" => (int)$row['UserId'],
            "panNumber" => $row['PANNumber'],
            "name" => trim($row['FirstName'] . ' ' . $row['LastName']),
            "financialYear" => $row['FinancialYear']
        ];
    }
}

// Check itr_detail
$itrSql = "SELECT 
            id as itr_id,
            userId, 
            panNumber, 
            financialYear,
            status
        FROM itr_detail
        ORDER BY id ASC
        LIMIT 20";

$itrResult = $conn->query($itrSql);
$itrDetails = [];

if ($itrResult && $itrResult->num_rows > 0) {
    while ($row = $itrResult->fetch_assoc()) {
        $itrDetails[] = [
            "itrId" => (int)$row['itr_id'],
            "userId" => (int)$row['userId'],
            "panNumber" => $row['panNumber'],
            "financialYear" => $row['financialYear'],
            "status" => $row['status']
        ];
    }
}

// Get counts
$pdCount = $conn->query("SELECT COUNT(*) as total FROM personal_details WHERE isActive = 1");
$itrCount = $conn->query("SELECT COUNT(*) as total FROM itr_detail");

$totalPersonalDetails = $pdCount ? (int)$pdCount->fetch_assoc()['total'] : 0;
$totalItrDetails = $itrCount ? (int)$itrCount->fetch_assoc()['total'] : 0;

// Check for missing itr_detail entries
$missingSql = "SELECT COUNT(*) as missing
               FROM personal_details pd
               LEFT JOIN itr_detail itr ON pd.UserId = itr.userId AND pd.PANNumber = itr.panNumber
               WHERE pd.isActive = 1 AND itr.id IS NULL";
$missingResult = $conn->query($missingSql);
$missingCount = $missingResult ? (int)$missingResult->fetch_assoc()['missing'] : 0;

http_response_code(200);
echo json_encode([
    "status" => "success",
    "summary" => [
        "totalPersonalDetails" => $totalPersonalDetails,
        "totalItrDetails" => $totalItrDetails,
        "missingItrDetails" => $missingCount,
        "needsMigration" => $missingCount > 0
    ],
    "personalDetails" => $personalDetails,
    "itrDetails" => $itrDetails,
    "message" => $missingCount > 0 
        ? "Found $missingCount personal_details records without corresponding itr_detail entries. Run migrate_itr_details.php to fix this."
        : "All personal_details have corresponding itr_detail entries."
], JSON_PRETTY_PRINT);

exit;
?>
