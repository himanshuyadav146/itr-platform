<?php
/**
 * Dynamic Status System - Quick Test Script
 * Run this file to verify the installation
 * 
 * Usage: php test_status_system.php
 * Or visit: http://localhost/api/test_status_system.php
 */

require 'include/config.php';

header("Content-Type: text/html; charset=UTF-8");

echo "<!DOCTYPE html>
<html>
<head>
    <title>Dynamic Status System - Test Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        h2 { color: #666; margin-top: 30px; }
        .test { margin: 20px 0; padding: 15px; border-left: 4px solid #2196F3; background: #f8f9fa; }
        .success { border-left-color: #4CAF50; background: #f1f8f4; }
        .error { border-left-color: #f44336; background: #fef1f0; }
        .warning { border-left-color: #ff9800; background: #fff8f0; }
        .test-title { font-weight: bold; font-size: 16px; margin-bottom: 10px; }
        .test-result { font-family: monospace; font-size: 14px; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #4CAF50; color: white; }
        tr:hover { background: #f5f5f5; }
        .badge { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
        .badge-success { background: #4CAF50; color: white; }
        .badge-error { background: #f44336; color: white; }
        .badge-info { background: #2196F3; color: white; }
        code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-size: 13px; }
    </style>
</head>
<body>
<div class='container'>
    <h1>🚀 Dynamic ITR Status System - Test Results</h1>
    <p><strong>Test Time:</strong> " . date('Y-m-d H:i:s') . "</p>";

$allTestsPassed = true;

// ========================================
// Test 1: Check if tables exist
// ========================================
echo "<h2>📦 Database Tables</h2>";

$tables = ['itr_status_config', 'itr_status_audit', 'itr_order_status', 'itr_assignments'];
$tableResults = [];

foreach ($tables as $table) {
    $sql = "SHOW TABLES LIKE '$table'";
    $result = $conn->query($sql);
    $exists = $result && $result->num_rows > 0;
    $tableResults[$table] = $exists;
    if (!$exists) $allTestsPassed = false;
}

echo "<div class='test " . ($tableResults['itr_status_config'] && $tableResults['itr_status_audit'] ? 'success' : 'error') . "'>
    <div class='test-title'>Table Existence Check</div>
    <div class='test-result'>";

echo "<table>
    <tr><th>Table Name</th><th>Status</th></tr>";
foreach ($tableResults as $table => $exists) {
    $badge = $exists ? "<span class='badge badge-success'>✓ EXISTS</span>" : "<span class='badge badge-error'>✗ MISSING</span>";
    echo "<tr><td><code>$table</code></td><td>$badge</td></tr>";
}
echo "</table></div></div>";

// ========================================
// Test 2: Check itr_status_config data
// ========================================
echo "<h2>⚙️ Status Configuration</h2>";

$sql = "SELECT step_code, title, is_automatic, requires_assignment, requires_documents, can_be_reverted, required_role, is_active FROM itr_status_config ORDER BY display_order";
$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    echo "<div class='test success'>
        <div class='test-title'>Status Steps Configured: " . $result->num_rows . " steps found</div>
        <div class='test-result'>";
    
    echo "<table>
        <tr>
            <th>Step Code</th>
            <th>Title</th>
            <th>Automatic</th>
            <th>Requires Assignment</th>
            <th>Requires Documents</th>
            <th>Revertable</th>
            <th>Required Role</th>
            <th>Active</th>
        </tr>";
    
    while ($row = $result->fetch_assoc()) {
        $auto = $row['is_automatic'] ? '✓' : '✗';
        $reqAssign = $row['requires_assignment'] ? '✓' : '✗';
        $reqDocs = $row['requires_documents'] ? '✓' : '✗';
        $revert = $row['can_be_reverted'] ? '✓' : '✗';
        $active = $row['is_active'] ? "<span class='badge badge-success'>Active</span>" : "<span class='badge badge-error'>Inactive</span>";
        $role = $row['required_role'] ?: 'Any Professional';
        
        echo "<tr>
            <td><code>{$row['step_code']}</code></td>
            <td>{$row['title']}</td>
            <td>{$auto}</td>
            <td>{$reqAssign}</td>
            <td>{$reqDocs}</td>
            <td>{$revert}</td>
            <td>{$role}</td>
            <td>{$active}</td>
        </tr>";
    }
    echo "</table></div></div>";
} else {
    echo "<div class='test error'>
        <div class='test-title'>❌ No status configurations found</div>
        <div class='test-result'>Please run the migration SQL file</div>
    </div>";
    $allTestsPassed = false;
}

// ========================================
// Test 3: Check if API files exist
// ========================================
echo "<h2>📁 API Files</h2>";

$apiFiles = [
    'itr_status/get_status_config.php' => 'Get Status Config (Public)',
    'admin/update_status_step.php' => 'Update Status Step (Professional)',
    'admin/status_config.php' => 'Manage Configurations (Admin)',
    'admin/get_status_audit.php' => 'View Audit Trail (Professional)'
];

echo "<div class='test'>";
echo "<div class='test-title'>API Endpoint Files</div>";
echo "<div class='test-result'><table>
    <tr><th>File Path</th><th>Description</th><th>Status</th></tr>";

$allFilesExist = true;
foreach ($apiFiles as $file => $desc) {
    $fullPath = __DIR__ . '/' . $file;
    $exists = file_exists($fullPath);
    if (!$exists) $allFilesExist = false;
    
    $badge = $exists ? "<span class='badge badge-success'>✓ EXISTS</span>" : "<span class='badge badge-error'>✗ MISSING</span>";
    echo "<tr><td><code>$file</code></td><td>$desc</td><td>$badge</td></tr>";
}

echo "</table></div></div>";

// ========================================
// Test 4: Check is_active column in itr_assignments
// ========================================
echo "<h2>🔧 Database Schema Updates</h2>";

$sql = "SHOW COLUMNS FROM itr_assignments LIKE 'is_active'";
$result = $conn->query($sql);
$hasIsActive = $result && $result->num_rows > 0;

echo "<div class='test " . ($hasIsActive ? 'success' : 'warning') . "'>
    <div class='test-title'>itr_assignments.is_active column</div>
    <div class='test-result'>";

if ($hasIsActive) {
    echo "<span class='badge badge-success'>✓ Column exists</span> - Assignment validation will work correctly";
} else {
    echo "<span class='badge badge-info'>ℹ Info</span> - Column doesn't exist yet. Migration will add it automatically on first run.";
}

echo "</div></div>";

// ========================================
// Test 5: Test API accessibility
// ========================================
echo "<h2>🌐 API Accessibility Test</h2>";

$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'];
$baseUrl = $protocol . '://' . $host . dirname($_SERVER['PHP_SELF']);

$testUrl = str_replace('/test_status_system.php', '', $baseUrl) . '/itr_status/get_status_config.php';

echo "<div class='test'>
    <div class='test-title'>Public API Endpoint Test</div>
    <div class='test-result'>
        <p><strong>Test URL:</strong> <code>$testUrl</code></p>
        <p>To test manually, run:</p>
        <pre style='background:#f4f4f4; padding:15px; border-radius:5px; overflow-x:auto;'>curl -X GET '$testUrl'</pre>
    </div>
</div>";

// ========================================
// Summary
// ========================================
echo "<h2>📊 Test Summary</h2>";

$statusClass = $allTestsPassed && $allFilesExist ? 'success' : 'warning';
$statusIcon = $allTestsPassed && $allFilesExist ? '✅' : '⚠️';
$statusText = $allTestsPassed && $allFilesExist ? 'All tests passed! System is ready.' : 'Some checks need attention. See details above.';

echo "<div class='test $statusClass'>
    <div class='test-title'>$statusIcon Overall Status</div>
    <div class='test-result'>
        <p><strong>$statusText</strong></p>
    </div>
</div>";

// ========================================
// Next Steps
// ========================================
echo "<h2>🚀 Next Steps</h2>";

echo "<div class='test'>
    <div class='test-title'>Implementation Checklist</div>
    <div class='test-result'>
        <ol style='line-height: 2;'>
            <li>" . ($tableResults['itr_status_config'] ? '✅' : '☐') . " Database tables created</li>
            <li>" . ($result && $result->num_rows >= 5 ? '✅' : '☐') . " Default status steps configured (5 steps)</li>
            <li>" . ($allFilesExist ? '✅' : '☐') . " API files in place</li>
            <li>☐ Test status update API with professional token</li>
            <li>☐ Integrate payment webhook with payment_success step</li>
            <li>☐ Integrate ITR assignment with expert_assigned step</li>
            <li>☐ Update Flutter app to fetch from get_status_config.php</li>
            <li>☐ Create admin UI for managing status configurations</li>
        </ol>
    </div>
</div>";

echo "<h2>📚 Documentation</h2>";
echo "<div class='test'>
    <div class='test-result'>
        <p>Complete documentation available at: <code>DYNAMIC_STATUS_SYSTEM_GUIDE.md</code></p>
        <p>Includes:</p>
        <ul>
            <li>Complete CURL examples for all APIs</li>
            <li>Error handling examples</li>
            <li>Integration guide</li>
            <li>Troubleshooting tips</li>
        </ul>
    </div>
</div>";

echo "</div>
</body>
</html>";

$conn->close();
?>
