<?php
/**
 * Cron: Send scheduled push notifications
 * Run 3 times per day (e.g. 9:00, 14:00, 19:00) via system cron.
 *
 * Sends all notifications where scheduled_at <= NOW() and sent_at IS NULL.
 * Then marks them sent (sets sent_at).
 *
 * Example crontab (run at 9am, 2pm, 7pm):
 * 0 9,14,19 * * * php /path/to/api/cron/send_scheduled_notifications.php
 */

// Run from CLI only (optional: remove to allow web trigger with secret)
if (php_sapi_name() !== 'cli') {
    die('Run this script from the command line only.');
}

$apiRoot = dirname(__DIR__);
require $apiRoot . '/include/config.php';
require $apiRoot . '/include/FcmHelper.php';

$log = function ($msg) {
    echo '[' . date('Y-m-d H:i:s') . '] ' . $msg . "\n";
};

$log('Cron: send_scheduled_notifications started');

// Check tables exist
$t = $conn->query("SHOW TABLES LIKE 'notifications'");
if (!$t || $t->num_rows === 0) {
    $log('Error: notifications table not found.');
    exit(1);
}

$t = $conn->query("SHOW TABLES LIKE 'user_fcm_tokens'");
if (!$t || $t->num_rows === 0) {
    $log('Error: user_fcm_tokens table not found.');
    exit(1);
}

// Due notifications: scheduled in the past and not yet sent
$sql = "SELECT id, title, body, data_payload, target, target_user_id 
        FROM notifications 
        WHERE scheduled_at <= NOW() AND (sent_at IS NULL OR sent_at = '0000-00-00 00:00:00')
        ORDER BY scheduled_at ASC";
$res = $conn->query($sql);
if (!$res || $res->num_rows === 0) {
    $log('No due notifications to send.');
    exit(0);
}

$log('Found ' . $res->num_rows . ' due notification(s).');

$dataPayloadDefault = [];
while ($row = $res->fetch_assoc()) {
    $nid = (int)$row['id'];
    $title = $row['title'];
    $body = $row['body'] ?? '';
    $target = $row['target'] ?? 'all_users';
    $targetUserId = isset($row['target_user_id']) ? (int)$row['target_user_id'] : null;
    $dataPayload = !empty($row['data_payload']) ? (is_string($row['data_payload']) ? json_decode($row['data_payload'], true) : $row['data_payload']) : $dataPayloadDefault;
    if (!is_array($dataPayload)) {
        $dataPayload = $dataPayloadDefault;
    }

    // Get FCM tokens
    $sqlTokens = "SELECT id, user_id, fcm_token FROM user_fcm_tokens WHERE is_active = 1 AND fcm_token != ''";
    if ($target === 'single_user' && $targetUserId > 0) {
        $sqlTokens .= " AND user_id = " . $targetUserId;
    }
    $resTokens = $conn->query($sqlTokens);
    $tokens = [];
    $tokenRows = [];
    if ($resTokens) {
        while ($tr = $resTokens->fetch_assoc()) {
            $tokens[] = $tr['fcm_token'];
            $tokenRows[] = $tr;
        }
    }

    if (empty($tokens)) {
        $log("Notification id=$nid: no tokens, marking sent.");
        $conn->query("UPDATE notifications SET sent_at = NOW() WHERE id = $nid");
        continue;
    }

    $sendResult = FcmHelper::sendToTokens($tokens, $title, $body, $dataPayload);
    $conn->query("UPDATE notifications SET sent_at = NOW() WHERE id = $nid");

    $log("Notification id=$nid: sent=" . $sendResult['success'] . ", failure=" . $sendResult['failure']);
    if (!empty($sendResult['errors'])) {
        foreach ($sendResult['errors'] as $err) {
            $log("  Error: " . $err);
        }
    }

    // Optional: log to notification_log
    $logTableRes = $conn->query("SHOW TABLES LIKE 'notification_log'");
    if ($logTableRes && $logTableRes->num_rows > 0 && count($tokenRows) > 0) {
        foreach ($tokenRows as $tr) {
            $uid = (int)$tr['user_id'];
            $tid = (int)$tr['id'];
            $success = 1;
            $conn->query("INSERT INTO notification_log (notification_id, user_id, fcm_token_id, sent_at, success) VALUES ($nid, $uid, $tid, NOW(), $success)");
        }
    }
}

$log('Cron: send_scheduled_notifications finished.');
exit(0);
