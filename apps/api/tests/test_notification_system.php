<?php
/**
 * CLI test for transactional notification system.
 *
 * Usage (from apps/api directory):
 *   php tests/test_notification_system.php --check
 *   php tests/test_notification_system.php --dry-run client.registered
 *   php tests/test_notification_system.php --send-test-email finnextgen2026@gmail.com
 */

$baseDir = dirname(__DIR__);
require $baseDir . '/include/config.php';
require_once $baseDir . '/include/EmailService.php';
require_once $baseDir . '/include/NotificationDispatcher.php';

$args = $argv ?? [];
$mode = $args[1] ?? '--check';

function println($msg)
{
    echo $msg . PHP_EOL;
}

if ($mode === '--check') {
    println('=== Notification system health check ===');

    $tables = ['notification_settings', 'notification_templates', 'notification_delivery_log', 'user_fcm_tokens'];
    foreach ($tables as $table) {
        $result = $conn->query("SHOW TABLES LIKE '$table'");
        println(($result && $result->num_rows > 0 ? '[OK]' : '[MISSING]') . " table: $table");
    }

    $tpl = $conn->query('SELECT COUNT(*) AS c FROM notification_templates');
    $count = $tpl ? (int) $tpl->fetch_assoc()['c'] : 0;
    println("[INFO] templates: $count");

    println('[INFO] SMTP configured: ' . (EmailService::isConfigured() ? 'yes' : 'no — copy include/notification_config.php.example'));

    $firebase = file_exists($baseDir . '/include/firebase_config.php');
    println('[INFO] Firebase config file: ' . ($firebase ? 'yes' : 'no — copy include/firebase_config.php.example'));

    exit(0);
}

if ($mode === '--dry-run') {
    $event = $args[2] ?? 'client.registered';
    println("=== Dry run templates for event: $event ===");
    $eventEsc = mysqli_real_escape_string($conn, $event);
    $result = $conn->query("SELECT event_key, audience, channel, email_subject, push_title FROM notification_templates WHERE event_key = '$eventEsc'");
    if (!$result || $result->num_rows === 0) {
        println('No templates found. Run migration add_transactional_notification_system.sql');
        exit(1);
    }
    while ($row = $result->fetch_assoc()) {
        println(json_encode($row, JSON_PRETTY_PRINT));
    }
    exit(0);
}

if ($mode === '--send-test-email') {
    $to = $args[2] ?? '';
    if ($to === '') {
        println('Usage: php tests/test_notification_system.php --send-test-email you@example.com');
        exit(1);
    }
    $result = EmailService::send(
        $to,
        'FinApp SMTP test',
        '<p>If you received this, SMTP is working.</p>',
        'If you received this, SMTP is working.'
    );
    println($result['success'] ? 'Email sent successfully' : ('Failed: ' . $result['error']));
    exit($result['success'] ? 0 : 1);
}

if ($mode === '--dispatch-test') {
    $event = $args[2] ?? 'client.registered';
    println("=== Dispatch test event: $event (will log to notification_delivery_log) ===");
    notifyWorkflowEvent($conn, $event, [
        'userId' => 1,
        'clientName' => 'Test User',
        'email' => 'test@example.com',
        'mobile' => '9999999999',
        'pan' => 'TESTP1234A',
        'financialYear' => '2024-25',
        'orderId' => 'TEST-ORDER-001',
        'amount' => '999',
        'itrId' => '1',
        'professionalId' => 2,
        'documentCount' => 3,
    ]);
    println('Done. Check notification_delivery_log table.');
    exit(0);
}

println('Unknown mode. Options: --check | --dry-run [event] | --send-test-email [address] | --dispatch-test [event]');
println('Events: client.registered, personal_info.submitted, documents.uploaded, payment.success, expert.assigned, status.step_updated, status.updated, concern.raised');
exit(1);
