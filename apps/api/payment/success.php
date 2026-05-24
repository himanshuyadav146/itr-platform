<?php
// Payment Success Page
// This page is shown after successful payment redirect
header("Content-Type: text/html; charset=UTF-8");
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Success</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background-color: #f4f6f8;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 500px;
        }
        .success-icon {
            color: #28a745;
            font-size: 64px;
            margin-bottom: 20px;
        }
        h1 {
            color: #28a745;
            margin-bottom: 10px;
        }
        p {
            color: #666;
            margin-bottom: 20px;
        }
        .info {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 4px;
            margin: 20px 0;
            text-align: left;
        }
        .info strong {
            color: #333;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success-icon">✓</div>
        <h1>Payment Successful!</h1>
        <p>Your payment has been processed successfully.</p>
        <div class="info">
            <?php
            // Get order ID from query string
            $orderId = $_GET['ORDERID'] ?? $_GET['order_id'] ?? 'N/A';
            $transactionId = $_GET['TXNID'] ?? $_GET['transaction_id'] ?? 'N/A';
            
            echo "<p><strong>Order ID:</strong> " . htmlspecialchars($orderId) . "</p>";
            echo "<p><strong>Transaction ID:</strong> " . htmlspecialchars($transactionId) . "</p>";
            ?>
        </div>
        <p>You will receive a confirmation email shortly.</p>
    </div>
</body>
</html>

