<?php
/**
 * One-time seed: Insert 14-day FinApp testing reminder campaign
 * 14 days × 3 times per day = 42 notifications.
 * Body: "Day X/14 – ..." with X counting down 14, 13, ..., 1.
 *
 * Run once from CLI or browser:
 *   php cron/seed_finapp_14day_campaign.php
 * Or: open in browser (e.g. for cPanel): /api/cron/seed_finapp_14day_campaign.php
 *
 * Optional: pass start date as first argument (Y-m-d), e.g.:
 *   php cron/seed_finapp_14day_campaign.php 2026-03-10
 */

$apiRoot = dirname(__DIR__);
require $apiRoot . '/include/config.php';

$log = function ($msg) {
    echo '[' . date('Y-m-d H:i:s') . '] ' . $msg . "\n";
};

// Start date: tomorrow (default) or first CLI arg / or ?start=Y-m-d in browser
$startDateStr = null;
if (php_sapi_name() === 'cli' && isset($argv[1])) {
    $startDateStr = $argv[1];
} elseif (isset($_GET['start'])) {
    $startDateStr = $_GET['start'];
}
if ($startDateStr) {
    $startDate = DateTime::createFromFormat('Y-m-d', $startDateStr);
    if (!$startDate) {
        $log('Invalid date. Use Y-m-d (e.g. 2026-03-10).');
        exit(1);
    }
} else {
    $startDate = new DateTime('tomorrow');
}

$log('Seeding FinApp 14-day campaign starting ' . $startDate->format('Y-m-d'));

// Check table exists
$t = $conn->query("SHOW TABLES LIKE 'notifications'");
if (!$t || $t->num_rows === 0) {
    $log('Error: notifications table not found. Run migration add_push_notification_tables.sql first.');
    exit(1);
}

$title = 'FinApp Testing Reminder';
$totalDays = 14;
$times = ['09:00', '14:00', '19:00']; // 3 times per day
$inserted = 0;

for ($day = 1; $day <= $totalDays; $day++) {
    // X counts down: day 1 → 14, day 2 → 13, ... day 14 → 1
    $x = 15 - $day;
    $body = "Day $x/14 – Please open the app today and explore features for a minute.\nYour quick testing helps us improve the app 🙏";

    $date = (clone $startDate)->modify('+' . ($day - 1) . ' days');
    $dateStr = $date->format('Y-m-d');

    foreach ($times as $time) {
        $scheduledAt = $dateStr . ' ' . $time . ':00';
        $titleEsc = mysqli_real_escape_string($conn, $title);
        $bodyEsc = mysqli_real_escape_string($conn, $body);
        $scheduledAtEsc = mysqli_real_escape_string($conn, $scheduledAt);

        $sql = "INSERT INTO notifications (title, body, type, scheduled_at, sent_at, target, created_at, updated_at)
                VALUES ('$titleEsc', '$bodyEsc', 'scheduled_campaign', '$scheduledAtEsc', NULL, 'all_users', NOW(), NOW())";
        if ($conn->query($sql)) {
            $inserted++;
        } else {
            $log('Insert failed: ' . $conn->error);
        }
    }
}

$log("Done. Inserted $inserted notifications (14 days × 3 per day).");
$log('Add cron to run send_scheduled_notifications.php at 9:00, 14:00, 19:00 daily.');
exit(0);
