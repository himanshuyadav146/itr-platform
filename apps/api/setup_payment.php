<?php
/**
 * Payment Tables Setup Script
 * Run this file in your browser to create payment tables
 * URL: http://localhost/api/setup_payment.php
 */

require 'include/config.php';

// Check if tables already exist
$checkPaymentInfo = "SHOW TABLES LIKE 'payment_info'";
$checkFees = "SHOW TABLES LIKE 'payment_additional_fees'";

$result1 = $conn->query($checkPaymentInfo);
$result2 = $conn->query($checkFees);

$paymentInfoExists = $result1 && $result1->num_rows > 0;
$feesExists = $result2 && $result2->num_rows > 0;

?>
<!DOCTYPE html>
<html>
<head>
    <title>Payment Tables Setup</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; max-width: 800px; margin: 0 auto; }
        h1 { color: #333; }
        .success { background: #d4edda; color: #155724; padding: 15px; border-radius: 4px; margin: 10px 0; }
        .error { background: #f8d7da; color: #721c24; padding: 15px; border-radius: 4px; margin: 10px 0; }
        .info { background: #d1ecf1; color: #0c5460; padding: 15px; border-radius: 4px; margin: 10px 0; }
        button { background: #0052cc; color: white; padding: 12px 24px; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; }
        button:hover { background: #003d99; }
        .sql-box { background: #f8f9fa; padding: 15px; border-radius: 4px; margin: 20px 0; font-family: monospace; font-size: 12px; overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f8f9fa; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Payment Tables Setup</h1>
        
        <?php
        if (isset($_POST['create_tables'])) {
            echo '<h2>Creating Tables...</h2>';
            
            // Define SQL statements directly (more reliable)
            $sqlStatements = [
                // Create payment_info table
                "CREATE TABLE IF NOT EXISTS `payment_info` (
                  `id` int(11) NOT NULL AUTO_INCREMENT,
                  `payment_id` varchar(50) NOT NULL COMMENT 'Alphanumeric payment ID',
                  `user_id` int(11) NOT NULL COMMENT 'FK to users table',
                  `package_id` int(11) DEFAULT NULL COMMENT 'FK to itr_packages table',
                  `pan_number` varchar(10) DEFAULT NULL COMMENT 'Reference to PAN, fetch details from personal_details',
                  `order_id` varchar(100) DEFAULT NULL COMMENT 'Gateway order ID',
                  `transaction_id` varchar(100) DEFAULT NULL COMMENT 'Gateway transaction ID',
                  `subtotal` decimal(15,2) NOT NULL COMMENT 'Total before GST (calculated from package + additional fees)',
                  `gst_percentage` decimal(5,2) DEFAULT 18.00 COMMENT 'GST percentage',
                  `gst_amount` decimal(15,2) NOT NULL COMMENT 'GST amount',
                  `grand_total` decimal(15,2) NOT NULL COMMENT 'Final amount to pay',
                  `currency` varchar(10) DEFAULT 'INR',
                  `payment_status` varchar(50) DEFAULT 'pending' COMMENT 'pending, success, failed, cancelled, refunded',
                  `payment_method` varchar(50) DEFAULT NULL COMMENT 'card, netbanking, upi, wallet, etc',
                  `gateway_name` varchar(50) DEFAULT NULL COMMENT 'paytm, razorpay, etc',
                  `merchant_id` varchar(100) DEFAULT NULL,
                  `gateway_response` text DEFAULT NULL COMMENT 'Full gateway response JSON',
                  `webhook_data` text DEFAULT NULL COMMENT 'Webhook callback data',
                  `failure_reason` text DEFAULT NULL COMMENT 'Reason for failure if any',
                  `callback_url` varchar(500) DEFAULT NULL,
                  `redirect_url` varchar(500) DEFAULT NULL,
                  `is_active` tinyint(1) DEFAULT 1,
                  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
                  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  `paid_at` datetime DEFAULT NULL COMMENT 'Payment completion time',
                  PRIMARY KEY (`id`),
                  UNIQUE KEY `payment_id` (`payment_id`),
                  KEY `idx_user_id` (`user_id`),
                  KEY `idx_package_id` (`package_id`),
                  KEY `idx_pan_number` (`pan_number`),
                  KEY `idx_order_id` (`order_id`),
                  KEY `idx_transaction_id` (`transaction_id`),
                  KEY `idx_payment_status` (`payment_status`),
                  KEY `idx_created_at` (`created_at`),
                  FOREIGN KEY (`user_id`) REFERENCES `users`(`UserId`) ON DELETE CASCADE,
                  FOREIGN KEY (`package_id`) REFERENCES `itr_packages`(`id`) ON DELETE SET NULL
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",
                
                // Create payment_additional_fees table
                "CREATE TABLE IF NOT EXISTS `payment_additional_fees` (
                  `id` int(11) NOT NULL AUTO_INCREMENT,
                  `fee_name` varchar(255) NOT NULL COMMENT 'E-Filing Fee, E-Verification Fee, etc',
                  `fee_amount` decimal(15,2) NOT NULL,
                  `display_order` int(11) DEFAULT 0,
                  `is_active` tinyint(1) DEFAULT 1,
                  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
                  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  PRIMARY KEY (`id`),
                  KEY `idx_is_active` (`is_active`),
                  KEY `idx_display_order` (`display_order`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",
                
                // Insert default fees (using INSERT IGNORE to avoid duplicates)
                "INSERT IGNORE INTO `payment_additional_fees` (`fee_name`, `fee_amount`, `display_order`, `is_active`) VALUES
                ('E-Filing Fee', 7999.00, 1, 1),
                ('E-Verification Fee', 199.00, 2, 1)"
            ];
            
            $successCount = 0;
            $errorCount = 0;
            $errors = [];
            
            foreach ($sqlStatements as $sql) {
                if ($conn->query($sql)) {
                    $successCount++;
                } else {
                    $errorCount++;
                    $errorMsg = $conn->error;
                    // Only log if it's not a "table already exists" or duplicate key error
                    if (strpos($errorMsg, 'already exists') === false && 
                        strpos($errorMsg, 'Duplicate entry') === false) {
                        $errors[] = $errorMsg;
                    }
                }
            }
            
            if (count($errors) == 0) {
                echo '<div class="success">';
                echo '<strong>Success!</strong> Payment tables created successfully.<br>';
                echo "Executed $successCount SQL statements.";
                if ($errorCount > 0) {
                    echo "<br>Note: Some tables/data may already exist (this is okay).";
                }
                echo '</div>';
            } else {
                echo '<div class="error">';
                echo '<strong>Errors occurred:</strong><br>';
                foreach ($errors as $error) {
                    echo "- " . htmlspecialchars($error) . "<br>";
                }
                echo '</div>';
            }
            
            // Refresh status
            $result1 = $conn->query($checkPaymentInfo);
            $result2 = $conn->query($checkFees);
            $paymentInfoExists = $result1 && $result1->num_rows > 0;
            $feesExists = $result2 && $result2->num_rows > 0;
        }
        ?>
        
        <h2>Current Status</h2>
        <table>
            <tr>
                <th>Table Name</th>
                <th>Status</th>
            </tr>
            <tr>
                <td>payment_info</td>
                <td><?php echo $paymentInfoExists ? '<span style="color: green;">✓ Exists</span>' : '<span style="color: red;">✗ Not Found</span>'; ?></td>
            </tr>
            <tr>
                <td>payment_additional_fees</td>
                <td><?php echo $feesExists ? '<span style="color: green;">✓ Exists</span>' : '<span style="color: red;">✗ Not Found</span>'; ?></td>
            </tr>
        </table>
        
        <?php if (!$paymentInfoExists || !$feesExists): ?>
            <form method="POST">
                <p>Click the button below to create the payment tables:</p>
                <button type="submit" name="create_tables">Create Payment Tables</button>
            </form>
        <?php else: ?>
            <div class="success">
                <strong>All payment tables already exist!</strong><br>
                You can verify the tables in phpMyAdmin or check the data below.
            </div>
        <?php endif; ?>
        
        <?php
        // Show table structure if exists
        if ($paymentInfoExists) {
            echo '<h2>payment_info Table Structure</h2>';
            $result = $conn->query("DESCRIBE payment_info");
            if ($result) {
                echo '<table>';
                echo '<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>';
                while ($row = $result->fetch_assoc()) {
                    echo '<tr>';
                    echo '<td>' . htmlspecialchars($row['Field']) . '</td>';
                    echo '<td>' . htmlspecialchars($row['Type']) . '</td>';
                    echo '<td>' . htmlspecialchars($row['Null']) . '</td>';
                    echo '<td>' . htmlspecialchars($row['Key']) . '</td>';
                    echo '<td>' . htmlspecialchars($row['Default'] ?? 'NULL') . '</td>';
                    echo '</tr>';
                }
                echo '</table>';
            }
        }
        
        // Show additional fees data
        if ($feesExists) {
            echo '<h2>Additional Fees</h2>';
            $result = $conn->query("SELECT * FROM payment_additional_fees WHERE is_active = 1 ORDER BY display_order");
            if ($result && $result->num_rows > 0) {
                echo '<table>';
                echo '<tr><th>ID</th><th>Fee Name</th><th>Amount</th><th>Display Order</th></tr>';
                while ($row = $result->fetch_assoc()) {
                    echo '<tr>';
                    echo '<td>' . $row['id'] . '</td>';
                    echo '<td>' . htmlspecialchars($row['fee_name']) . '</td>';
                    echo '<td>₹' . number_format($row['fee_amount'], 2) . '</td>';
                    echo '<td>' . $row['display_order'] . '</td>';
                    echo '</tr>';
                }
                echo '</table>';
            } else {
                echo '<div class="info">No additional fees found. Default fees will be inserted when tables are created.</div>';
            }
        }
        ?>
        
        <h2>Alternative Method: phpMyAdmin</h2>
        <div class="info">
            <strong>Option 2: Using phpMyAdmin</strong><br><br>
            1. Open phpMyAdmin: <a href="http://localhost/phpmyadmin" target="_blank">http://localhost/phpmyadmin</a><br>
            2. Select your database: <strong>itr_services</strong><br>
            3. Click on the <strong>SQL</strong> tab<br>
            4. Open the file: <code>setup_payment_table.sql</code><br>
            5. Copy all contents and paste in SQL tab<br>
            6. Click <strong>Go</strong> button
        </div>
    </div>
</body>
</html>

