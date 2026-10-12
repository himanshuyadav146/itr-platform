<?php

class PaymentHelper {

    /**
     * Get current payment config based on PAYMENT_MODE (test/live).
     * Uses globals set by include/config.php and include/payment_config.php.
     *
     * @return array [ 'mode' => 'test'|'live', 'gateway' => 'razorpay'|'paytm', 'razorpay_key_id' => string, 'razorpay_secret' => string, 'merchant_id' => string ]
     */
    public static function getPaymentConfig() {
        $mode = isset($GLOBALS['payment_mode']) ? strtolower(trim($GLOBALS['payment_mode'])) : 'test';
        if (!in_array($mode, ['test', 'live'], true)) {
            $mode = 'test';
        }
        $gateway = isset($GLOBALS['payment_default_gateway']) ? strtolower(trim($GLOBALS['payment_default_gateway'])) : 'razorpay';
        if (!in_array($gateway, ['razorpay', 'paytm'], true)) {
            $gateway = 'razorpay';
        }

        $keyId = $mode === 'live'
            ? ($GLOBALS['razorpay_key_id_live'] ?? '')
            : ($GLOBALS['razorpay_key_id_test'] ?? '');
        $secret = $mode === 'live'
            ? ($GLOBALS['razorpay_secret_live'] ?? '')
            : ($GLOBALS['razorpay_secret_test'] ?? '');
        $merchantId = $mode === 'live'
            ? ($GLOBALS['paytm_merchant_id_live'] ?? '')
            : ($GLOBALS['paytm_merchant_id_test'] ?? '');

        return [
            'mode' => $mode,
            'gateway' => $gateway,
            'razorpay_key_id' => is_string($keyId) ? $keyId : '',
            'razorpay_secret' => is_string($secret) ? $secret : '',
            'merchant_id' => is_string($merchantId) ? $merchantId : '',
        ];
    }

    /**
     * Build gateway_details object for API response (key_id, merchant_id, mode, gateway).
     *
     * @return array
     */
    public static function getGatewayDetailsForResponse() {
        $c = self::getPaymentConfig();
        $details = [
            'mode' => $c['mode'],
            'gateway' => $c['gateway'],
        ];
        if ($c['gateway'] === 'razorpay') {
            $details['key_id'] = $c['razorpay_key_id'];
        }
        if ($c['merchant_id'] !== '') {
            $details['merchant_id'] = $c['merchant_id'];
        }
        return $details;
    }

    /**
     * Create Razorpay order and return razorpay_order_id (or null if SDK missing or error).
     *
     * @param string $orderId Our internal order ID (stored in notes)
     * @param float $amountInr Amount in INR
     * @param string $currency e.g. INR
     * @return array|null [ 'razorpay_order_id' => string ] or null
     */
    public static function createRazorpayOrder($orderId, $amountInr, $currency = 'INR') {
        $c = self::getPaymentConfig();
        if ($c['razorpay_secret'] === '' || $c['razorpay_key_id'] === '' || $amountInr <= 0) {
            return null;
        }
        $autoload = dirname(dirname(__DIR__)) . '/vendor/autoload.php';
        if (!file_exists($autoload)) {
            return null;
        }
        require_once $autoload;
        if (!class_exists('Razorpay\Api\Api')) {
            return null;
        }
        try {
            $api = new \Razorpay\Api\Api($c['razorpay_key_id'], $c['razorpay_secret']);
            $amountPaise = (int) round($amountInr * 100);
            $order = $api->order->create([
                'amount' => $amountPaise,
                'currency' => $currency,
                'receipt' => $orderId,
                'notes' => ['internal_order_id' => $orderId],
            ]);
            if ($order && isset($order['id'])) {
                return ['razorpay_order_id' => $order['id']];
            }
        } catch (\Throwable $e) {
            return null;
        }
        return null;
    }
    
    /**
     * Generate unique alphanumeric payment ID
     * Format: PAY{timestamp}{random}
     * 
     * @return string Unique payment ID
     */
    public static function generatePaymentId() {
        $prefix = 'PAY';
        $timestamp = time();
        $random = strtoupper(substr(uniqid(), -6));
        return $prefix . $timestamp . $random;
    }
    
    /**
     * Calculate payment breakdown from package and additional fees
     * 
     * @param mysqli $conn Database connection
     * @param int|null $packageId Package ID from itr_packages
     * @param float $gstPercentage GST percentage (default 18)
     * @return array Payment breakdown with subtotal, GST, grand_total, and fee_items
     */
    public static function calculatePaymentBreakdown($conn, $packageId = null, $gstPercentage = 18) {
        $subtotal = 0;
        $feeItems = [];
        
        // Get package price if package ID provided
        if ($packageId) {
            $packageId = mysqli_real_escape_string($conn, $packageId);
            $packageSql = "SELECT id, packagename, price FROM itr_packages WHERE id = '$packageId' AND isActive = 1";
            $packageResult = $conn->query($packageSql);
            if ($packageResult && $packageResult->num_rows > 0) {
                $package = $packageResult->fetch_assoc();
                $subtotal += $package['price'];
                $feeItems[] = [
                    'name' => $package['packagename'] . ' Package',
                    'amount' => floatval($package['price']),
                    'type' => 'package'
                ];
            }
        }
        
        // Get additional fees from payment_additional_fees table
        $feesSql = "SELECT fee_name, fee_amount FROM payment_additional_fees WHERE is_active = 1 ORDER BY display_order ASC";
        $feesResult = $conn->query($feesSql);
        if ($feesResult && $feesResult->num_rows > 0) {
            while ($fee = $feesResult->fetch_assoc()) {
                $feeAmount = floatval($fee['fee_amount']);
                $subtotal += $feeAmount;
                $feeItems[] = [
                    'name' => $fee['fee_name'],
                    'amount' => $feeAmount,
                    'type' => 'additional_fee'
                ];
            }
        }
        
        // Calculate GST
        $gstAmount = round(($subtotal * $gstPercentage) / 100, 2);
        $grandTotal = $subtotal + $gstAmount;
        
        return [
            'subtotal' => round($subtotal, 2),
            'gst_percentage' => $gstPercentage,
            'gst_amount' => $gstAmount,
            'grand_total' => round($grandTotal, 2),
            'fee_items' => $feeItems
        ];
    }
    
    /**
     * Format amount for display
     * 
     * @param float $amount Amount to format
     * @return string Formatted amount with ₹ symbol
     */
    public static function formatAmount($amount) {
        return '₹' . number_format($amount, 0, '.', '');
    }
    
    /**
     * Build payment summary array for API response
     * 
     * @param array $breakdown Payment breakdown from calculatePaymentBreakdown
     * @return array Payment summary formatted for API
     */
    public static function buildPaymentSummary($breakdown) {
        $summary = [];
        
        // Add fee items
        foreach ($breakdown['fee_items'] as $item) {
            $summary[] = [
                "display_title" => $item['name'],
                "display_value" => self::formatAmount($item['amount']),
                "amount" => $item['amount']
            ];
        }
        
        // Add subtotal
        $summary[] = [
            "display_title" => "Total (Before GST)",
            "display_value" => self::formatAmount($breakdown['subtotal']),
            "amount" => $breakdown['subtotal'],
            "type" => "subtotal"
        ];
        
        // Add GST
        $summary[] = [
            "display_title" => "GST @" . $breakdown['gst_percentage'] . "%",
            "display_value" => self::formatAmount($breakdown['gst_amount']),
            "amount" => $breakdown['gst_amount']
        ];
        
        // Add grand total
        $summary[] = [
            "display_title" => "GRAND TOTAL",
            "display_value" => self::formatAmount($breakdown['grand_total']),
            "amount" => $breakdown['grand_total'],
            "type" => "grand_total"
        ];
        
        return $summary;
    }
}

