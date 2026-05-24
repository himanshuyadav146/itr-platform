<?php
/**
 * Database Setup Script
 * Run this file in your browser to set up the database
 * URL: http://localhost/api/setup.php
 */

// Database configuration
$servername = "localhost";
$username = "root"; // Change if needed
$password = ""; // Change if needed (default XAMPP is empty)
$database = "allindia_services";

// Read SQL file
$sqlFile = __DIR__ . '/database_setup.sql';
$sql = file_get_contents($sqlFile);

// Remove CREATE DATABASE and USE statements for connection
$sql = preg_replace('/CREATE DATABASE.*?;/is', '', $sql);
$sql = preg_replace('/USE\s+`?allindia_services`?;/i', '', $sql);
$sql = preg_replace('/CREATE USER.*?;/is', '', $sql);
$sql = preg_replace('/GRANT.*?;/is', '', $sql);
$sql = preg_replace('/FLUSH PRIVILEGES;/i', '', $sql);

?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Database Setup - ITR API</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 900px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #0052cc;
            border-bottom: 3px solid #0052cc;
            padding-bottom: 10px;
        }
        .step {
            margin: 20px 0;
            padding: 15px;
            background: #f9f9f9;
            border-left: 4px solid #0052cc;
        }
        .success {
            color: #28a745;
            background: #d4edda;
            padding: 10px;
            border-radius: 4px;
            margin: 10px 0;
        }
        .error {
            color: #dc3545;
            background: #f8d7da;
            padding: 10px;
            border-radius: 4px;
            margin: 10px 0;
        }
        .info {
            color: #004085;
            background: #cce5ff;
            padding: 10px;
            border-radius: 4px;
            margin: 10px 0;
        }
        button {
            background: #0052cc;
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            margin: 10px 5px;
        }
        button:hover {
            background: #003d99;
        }
        .config-form {
            margin: 20px 0;
        }
        .config-form input {
            width: 300px;
            padding: 8px;
            margin: 5px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        pre {
            background: #f4f4f4;
            padding: 15px;
            border-radius: 4px;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 ITR API Database Setup</h1>
        
        <?php
        if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['setup'])) {
            // Get form values or use defaults
            $db_servername = $_POST['servername'] ?? $servername;
            $db_username = $_POST['username'] ?? $username;
            $db_password = $_POST['password'] ?? $password;
            $db_database = $_POST['database'] ?? $database;
            
            // First, create database connection without selecting database
            $conn = mysqli_connect($db_servername, $db_username, $db_password);
            
            if (!$conn) {
                echo '<div class="error">❌ Connection failed: ' . mysqli_connect_error() . '</div>';
            } else {
                echo '<div class="success">✅ Connected to MySQL server successfully!</div>';
                
                // Create database
                $createDbSql = "CREATE DATABASE IF NOT EXISTS `$db_database` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";
                if (mysqli_query($conn, $createDbSql)) {
                    echo '<div class="success">✅ Database "' . $db_database . '" created/verified successfully!</div>';
                } else {
                    echo '<div class="error">❌ Error creating database: ' . mysqli_error($conn) . '</div>';
                }
                
                // Select database
                mysqli_select_db($conn, $db_database);
                
                // Split SQL into individual statements
                $statements = array_filter(array_map('trim', explode(';', $sql)));
                $successCount = 0;
                $errorCount = 0;
                
                foreach ($statements as $statement) {
                    if (!empty($statement) && !preg_match('/^--/', $statement)) {
                        if (mysqli_query($conn, $statement)) {
                            $successCount++;
                        } else {
                            $errorCount++;
                            // Only show errors for non-IF NOT EXISTS statements
                            if (!preg_match('/IF NOT EXISTS/i', $statement)) {
                                echo '<div class="error">⚠️ Error: ' . mysqli_error($conn) . '<br><small>' . substr($statement, 0, 100) . '...</small></div>';
                            }
                        }
                    }
                }
                
                echo '<div class="success">✅ Setup completed! Executed ' . $successCount . ' statements successfully.</div>';
                
                if ($errorCount > 0) {
                    echo '<div class="info">ℹ️ Some statements had errors (likely because tables already exist). This is normal if you run setup multiple times.</div>';
                }
                
                // Test connection with new database
                mysqli_close($conn);
                $testConn = mysqli_connect($db_servername, $db_username, $db_password, $db_database);
                if ($testConn) {
                    echo '<div class="success">✅ Database connection test successful!</div>';
                    mysqli_close($testConn);
                }
                
                echo '<div class="info"><strong>Next Steps:</strong><br>';
                echo '1. Update <code>include/config.php</code> with your database credentials if different<br>';
                echo '2. Test the API endpoints using Postman<br>';
                echo '3. Use the test user: <strong>test@example.com</strong> / <strong>test123</strong> to login</div>';
            }
        } else {
        ?>
        
        <div class="step">
            <h2>📋 Setup Instructions</h2>
            <ol>
                <li>Make sure MySQL is running (XAMPP/MAMP/LAMP)</li>
                <li>Enter your database credentials below (default XAMPP: root, empty password)</li>
                <li>Click "Setup Database" button</li>
                <li>Wait for the setup to complete</li>
            </ol>
        </div>
        
        <form method="POST" class="config-form">
            <h3>Database Configuration</h3>
            <div>
                <label>Server:</label><br>
                <input type="text" name="servername" value="<?php echo htmlspecialchars($servername); ?>" required>
            </div>
            <div>
                <label>Username:</label><br>
                <input type="text" name="username" value="<?php echo htmlspecialchars($username); ?>" required>
            </div>
            <div>
                <label>Password:</label><br>
                <input type="password" name="password" value="<?php echo htmlspecialchars($password); ?>">
            </div>
            <div>
                <label>Database Name:</label><br>
                <input type="text" name="database" value="<?php echo htmlspecialchars($database); ?>" required>
            </div>
            <button type="submit" name="setup">🚀 Setup Database</button>
        </form>
        
        <div class="info">
            <strong>Note:</strong> This script will create all necessary tables and insert sample data.
            If tables already exist, it will skip creating them (safe to run multiple times).
        </div>
        
        <?php } ?>
        
        <div class="step">
            <h3>📝 Manual Setup Alternative</h3>
            <p>If you prefer to set up manually:</p>
            <ol>
                <li>Open phpMyAdmin: <a href="http://localhost/phpmyadmin" target="_blank">http://localhost/phpmyadmin</a></li>
                <li>Go to SQL tab</li>
                <li>Copy and paste the contents of <code>database_setup.sql</code></li>
                <li>Click "Go" to execute</li>
            </ol>
        </div>
    </div>
</body>
</html>

