<?php
/**
 * Get Status Configuration API - FULLY DYNAMIC FROM DB
 * Returns all active status steps with their configurations
 * 
 * Endpoint: GET /itr_status/get_status_config.php
 * Auth: Public (no token required)
 * 
 * Response includes:
 * - Step definitions
 * - Titles, subtitles, descriptions
 * - Icons and colors for UI
 * - Business rules (automatic, requires assignment, etc.)
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

require '../include/config.php';

// Fetch active status configurations from database
$sql = "SELECT 
          step_code,
          title,
          subtitle,
          description,
          display_order,
          icon,
          color,
          is_automatic,
          requires_assignment,
          requires_documents,
          can_be_reverted,
          required_role
        FROM itr_status_config 
        WHERE is_active = 1 
        ORDER BY display_order ASC";

$result = $conn->query($sql);
$statusConfig = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $statusConfig[] = [
            "step" => $row['step_code'],
            "title" => $row['title'],
            "subtitle" => $row['subtitle'],
            "description" => $row['description'],
            "order" => (int)$row['display_order'],
            "icon" => $row['icon'],
            "color" => $row['color'],
            "isAutomatic" => (bool)$row['is_automatic'],
            "requiresAssignment" => (bool)$row['requires_assignment'],
            "requiresDocuments" => (bool)$row['requires_documents'],
            "canBeReverted" => (bool)$row['can_be_reverted'],
            "requiredRole" => $row['required_role'] ? explode(',', $row['required_role']) : null
        ];
    }
}

http_response_code(200);
echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" => [
        "steps" => $statusConfig,
        "totalSteps" => count($statusConfig),
        "lastUpdated" => date('Y-m-d H:i:s')
    ]
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

exit;
?>
