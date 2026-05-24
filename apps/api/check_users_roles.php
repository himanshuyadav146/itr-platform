<?php
/**
 * Check Users Roles Script
 * This script shows all users and their roles to help debug
 */

// Enable error display
error_reporting(E_ALL);
ini_set('display_errors', 1);

require 'include/config.php';

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Check Users Roles</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 10px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #4CAF50;
            color: white;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .info {
            background: #e3f2fd;
            padding: 15px;
            border-left: 4px solid #2196F3;
            margin: 15px 0;
            border-radius: 4px;
        }
        .warning {
            background: #fff3e0;
            padding: 15px;
            border-left: 4px solid #ff9800;
            margin: 15px 0;
            border-radius: 4px;
        }
        .success {
            background: #e8f5e9;
            padding: 15px;
            border-left: 4px solid #4CAF50;
            margin: 15px 0;
            border-radius: 4px;
        }
        .null-role {
            color: #ff9800;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Check Users Roles</h1>

<?php

// Check connection
if (!$conn) {
    echo '<div class="warning">';
    echo '<strong>❌ Database connection failed!</strong><br>';
    echo mysqli_connect_error();
    echo '</div>';
    exit;
}

// Check if Role column exists
$checkColumn = $conn->query("SHOW COLUMNS FROM users LIKE 'Role'");
if ($checkColumn->num_rows === 0) {
    echo '<div class="warning">';
    echo '<strong>⚠️ Role column does not exist in users table!</strong><br><br>';
    echo 'You need to add the Role column first. Run: <code>add_admin_columns_cpanel.sql</code> in phpMyAdmin';
    echo '</div>';
    exit;
}

// Get all users with their roles
$sql = "SELECT UserId, FirstName, LastName, Email, Mobile, Role, IsActive, CreatedAt 
        FROM users 
        ORDER BY CreatedAt DESC";
$result = $conn->query($sql);

if ($result && $result->num_rows > 0) {
    echo '<div class="success">';
    echo '<strong>✅ Found ' . $result->num_rows . ' user(s)</strong>';
    echo '</div>';
    
    // Count by role
    $roleCounts = [];
    $users = [];
    while ($row = $result->fetch_assoc()) {
        $role = $row['Role'] ?? 'NULL';
        if (!isset($roleCounts[$role])) {
            $roleCounts[$role] = 0;
        }
        $roleCounts[$role]++;
        $users[] = $row;
    }
    
    // Show role summary
    echo '<div class="info">';
    echo '<strong>📊 Role Summary:</strong><br>';
    echo '<ul>';
    foreach ($roleCounts as $role => $count) {
        echo '<li><strong>' . htmlspecialchars($role) . '</strong>: ' . $count . ' user(s)</li>';
    }
    echo '</ul>';
    echo '</div>';
    
    // Show detailed table
    echo '<h2>All Users</h2>';
    echo '<table>';
    echo '<tr>';
    echo '<th>User ID</th>';
    echo '<th>Name</th>';
    echo '<th>Email</th>';
    echo '<th>Mobile</th>';
    echo '<th>Role</th>';
    echo '<th>Active</th>';
    echo '<th>Created</th>';
    echo '</tr>';
    
    foreach ($users as $user) {
        echo '<tr>';
        echo '<td>' . htmlspecialchars($user['UserId']) . '</td>';
        echo '<td>' . htmlspecialchars(trim($user['FirstName'] . ' ' . $user['LastName'])) . '</td>';
        echo '<td>' . htmlspecialchars($user['Email']) . '</td>';
        echo '<td>' . htmlspecialchars($user['Mobile'] ?? '') . '</td>';
        $role = $user['Role'] ?? null;
        $roleClass = ($role === null || $role === '') ? 'null-role' : '';
        echo '<td class="' . $roleClass . '">' . htmlspecialchars($role ?? 'NULL/EMPTY') . '</td>';
        echo '<td>' . ($user['IsActive'] ?? 1 ? 'Yes' : 'No') . '</td>';
        echo '<td>' . htmlspecialchars($user['CreatedAt']) . '</td>';
        echo '</tr>';
    }
    echo '</table>';
    
    // Show how to update roles
    echo '<div class="info" style="margin-top: 30px;">';
    echo '<strong>💡 How to Set User Roles:</strong><br>';
    echo '<p>To set a user as ACCOUNTANT or CA, run this SQL in phpMyAdmin:</p>';
    echo '<pre style="background: #f5f5f5; padding: 15px; border-radius: 4px; overflow-x: auto;">';
    echo '-- Set user as ACCOUNTANT (replace USER_ID with actual user ID):' . "\n";
    echo "UPDATE users SET Role = 'ACCOUNTANT' WHERE UserId = USER_ID;\n\n";
    echo '-- Set user as CA:' . "\n";
    echo "UPDATE users SET Role = 'CA' WHERE UserId = USER_ID;\n\n";
    echo '-- Set user as ADMIN:' . "\n";
    echo "UPDATE users SET Role = 'ADMIN' WHERE UserId = USER_ID;\n\n";
    echo '-- Set user as CLIENT:' . "\n";
    echo "UPDATE users SET Role = 'CLIENT' WHERE UserId = USER_ID;";
    echo '</pre>';
    echo '</div>';
    
} else {
    echo '<div class="warning">';
    echo '<strong>⚠️ No users found in database</strong>';
    echo '</div>';
}

?>

    </div>
</body>
</html>
