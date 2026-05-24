<?php
/**
 * Database Connection Test
 * URL: http://localhost/api/test_connection.php
 */

// Enable error display for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Database Connection Test - ITR API</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
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
        .success {
            color: #4CAF50;
            background: #e8f5e9;
            padding: 15px;
            border-left: 4px solid #4CAF50;
            margin: 10px 0;
            border-radius: 4px;
        }
        .error {
            color: #f44336;
            background: #ffebee;
            padding: 15px;
            border-left: 4px solid #f44336;
            margin: 10px 0;
            border-radius: 4px;
        }
        .info {
            color: #2196F3;
            background: #e3f2fd;
            padding: 15px;
            border-left: 4px solid #2196F3;
            margin: 10px 0;
            border-radius: 4px;
        }
        .warning {
            color: #ff9800;
            background: #fff3e0;
            padding: 15px;
            border-left: 4px solid #ff9800;
            margin: 10px 0;
            border-radius: 4px;
        }
        code {
            background: #f5f5f5;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Courier New', monospace;
        }
        .config-details {
            background: #f9f9f9;
            padding: 15px;
            border-radius: 4px;
            margin: 15px 0;
        }
        .config-details strong {
            display: inline-block;
            width: 150px;
        }
        ul {
            line-height: 1.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔌 Database Connection Test</h1>

<?php

// Check if config file exists
$configFile = __DIR__ . '/include/config.php';
if (!file_exists($configFile)) {
    echo '<div class="error">';
    echo '<strong>❌ Configuration file not found!</strong><br>';
    echo 'File: <code>include/config.php</code> does not exist.<br><br>';
    echo '<strong>Solution:</strong><br>';
    echo '1. Copy <code>include/config.php.example</code> to <code>include/config.php</code><br>';
    echo '2. Update database credentials in <code>config.php</code>';
    echo '</div>';
    echo '</div></body></html>';
    exit;
}

// Try to include config
try {
    require $configFile;
    
    // Check if variables are defined
    if (!isset($servername) || !isset($username) || !isset($password) || !isset($database)) {
        echo '<div class="error">';
        echo '<strong>❌ Configuration variables not defined!</strong><br>';
        echo 'Please check that <code>config.php</code> defines: $servername, $username, $password, $database';
        echo '</div>';
        echo '</div></body></html>';
        exit;
    }
    
    // Display current configuration
    echo '<div class="config-details">';
    echo '<h3>📋 Current Configuration</h3>';
    echo '<strong>Server:</strong> ' . htmlspecialchars($servername) . '<br>';
    echo '<strong>Username:</strong> ' . htmlspecialchars($username) . '<br>';
    echo '<strong>Password:</strong> ' . (empty($password) ? '<em>(empty)</em>' : '••••••••') . '<br>';
    echo '<strong>Database:</strong> ' . htmlspecialchars($database) . '<br>';
    echo '</div>';
    
    // Test connection
    echo '<h3>🧪 Connection Test</h3>';
    
    if (isset($conn) && $conn) {
        echo '<div class="success">';
        echo '<strong>✅ Database connected successfully!</strong><br><br>';
        
        // Test query
        $result = $conn->query("SELECT DATABASE() as db, VERSION() as version");
        if ($result) {
            $row = $result->fetch_assoc();
            echo '<strong>Connected to database:</strong> ' . htmlspecialchars($row['db']) . '<br>';
            echo '<strong>MySQL Version:</strong> ' . htmlspecialchars($row['version']) . '<br>';
        }
        
        // Check if database has tables
        $tableCheck = $conn->query("SHOW TABLES");
        if ($tableCheck) {
            $tableCount = $tableCheck->num_rows;
            echo '<br><strong>Tables found:</strong> ' . $tableCount;
            
            if ($tableCount > 0) {
                echo '<br><br><strong>Table list:</strong><ul>';
                while ($table = $tableCheck->fetch_array()) {
                    echo '<li>' . htmlspecialchars($table[0]) . '</li>';
                }
                echo '</ul>';
            } else {
                echo '<div class="warning" style="margin-top: 10px;">';
                echo '⚠️ Database is empty. You may need to run the setup script.<br>';
                echo 'Run: <code>setup.php</code> or import <code>setup_database.sql</code>';
                echo '</div>';
            }
        }
        
        echo '</div>';
        
    } else {
        $error = mysqli_connect_error();
        echo '<div class="error">';
        echo '<strong>❌ Connection failed!</strong><br><br>';
        echo '<strong>Error:</strong> ' . htmlspecialchars($error) . '<br><br>';
        
        echo '<strong>Possible solutions:</strong><ul>';
        
        // Check common issues
        if (strpos($error, 'Access denied') !== false) {
            echo '<li>❌ <strong>Wrong username or password</strong><br>';
            echo '   Check your MySQL credentials in <code>include/config.php</code><br>';
            echo '   For XAMPP default: username = <code>root</code>, password = <code>""</code> (empty)</li>';
        }
        
        if (strpos($error, "Unknown database") !== false || strpos($error, "doesn't exist") !== false) {
            echo '<li>❌ <strong>Database does not exist</strong><br>';
            echo '   Create the database first:<br>';
            echo '   Option 1: Run <code>setup.php</code> in browser<br>';
            echo '   Option 2: Create manually in phpMyAdmin: <code>' . htmlspecialchars($database) . '</code></li>';
        }
        
        if (strpos($error, "Can't connect") !== false || strpos($error, "Connection refused") !== false) {
            echo '<li>❌ <strong>MySQL server is not running</strong><br>';
            echo '   Start MySQL service in XAMPP Control Panel</li>';
        }
        
        echo '<li>✅ Verify MySQL is running in XAMPP Control Panel</li>';
        echo '<li>✅ Check <code>include/config.php</code> has correct credentials</li>';
        echo '<li>✅ Try accessing phpMyAdmin: <a href="http://localhost/phpmyadmin" target="_blank">http://localhost/phpmyadmin</a></li>';
        echo '</ul>';
        echo '</div>';
        
        // Show local setup info
        echo '<div class="info">';
        echo '<strong>💡 For Local Development (XAMPP):</strong><br>';
        echo 'Default XAMPP MySQL credentials:<br>';
        echo '<code>$servername = "localhost";<br>';
        echo '$username = "root";<br>';
        echo '$password = ""; // empty<br>';
        echo '$database = "itr_services";</code>';
        echo '</div>';
    }
    
} catch (Exception $e) {
    echo '<div class="error">';
    echo '<strong>❌ Error loading configuration:</strong><br>';
    echo htmlspecialchars($e->getMessage());
    echo '</div>';
}

?>

        <div class="info" style="margin-top: 30px;">
            <strong>📝 Next Steps:</strong><br>
            <ul>
                <li>If connection failed, update <code>include/config.php</code> with correct credentials</li>
                <li>If database is empty, run <code><a href="setup.php">setup.php</a></code> to create tables</li>
                <li>Test API endpoints using Postman or browser</li>
            </ul>
        </div>
    </div>
</body>
</html>

