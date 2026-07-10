<?php
/**
 * Reusable transactional notification dispatcher.
 * Loads DB templates, resolves recipients, sends email (SMTP) + push (FCM).
 * Never throws — failures are logged to notification_delivery_log.
 */

require_once __DIR__ . '/EmailService.php';
require_once __DIR__ . '/FcmHelper.php';

class NotificationDispatcher
{
    /**
     * Dispatch notifications for a workflow event.
     *
     * @param mysqli $conn
     * @param string $eventKey e.g. client.registered
     * @param array $context Placeholder values + ids (userId, orderId, itrId, ...)
     */
    public static function dispatch($conn, $eventKey, array $context = [])
    {
        try {
            if (!$conn) {
                return;
            }

            $settings = self::loadSettings($conn);
            if (empty($settings['email_enabled']) && empty($settings['push_enabled'])) {
                return;
            }

            $context = self::enrichContext($conn, $context, $settings);
            $templates = self::loadTemplates($conn, $eventKey);

            if (empty($templates)) {
                error_log("[NotificationDispatcher] No templates for event: $eventKey");
                return;
            }

            foreach ($templates as $template) {
                $audience = $template['audience'];
                $channel = $template['channel'];

                $recipients = self::resolveRecipients($conn, $audience, $context, $settings);
                if (empty($recipients)) {
                    self::logDelivery(
                        $conn,
                        $eventKey,
                        $audience,
                        'EMAIL',
                        'none',
                        $context,
                        'skipped',
                        'No recipient resolved'
                    );
                    continue;
                }

                foreach ($recipients as $recipient) {
                    if (self::alreadySent($conn, $eventKey, $audience, $recipient, $context)) {
                        continue;
                    }

                    $rendered = self::renderTemplate($template, $context);

                    if (
                        ($channel === 'EMAIL' || $channel === 'BOTH')
                        && !empty($settings['email_enabled'])
                        && !empty($recipient['email'])
                    ) {
                        self::sendEmail(
                            $conn,
                            $eventKey,
                            $audience,
                            $recipient,
                            $rendered,
                            $context,
                            $settings
                        );
                    }

                    if (
                        ($channel === 'PUSH' || $channel === 'BOTH')
                        && !empty($settings['push_enabled'])
                        && !empty($recipient['user_id'])
                    ) {
                        self::sendPush(
                            $conn,
                            $eventKey,
                            $audience,
                            $recipient,
                            $rendered,
                            $context
                        );
                    }
                }
            }
        } catch (Throwable $e) {
            error_log('[NotificationDispatcher] ' . $e->getMessage());
        }
    }

    private static function loadSettings($conn)
    {
        $defaults = [
            'admin_email' => 'finnextgen2026@gmail.com',
            'from_email' => 'noreply@allindiaitr.in',
            'from_name' => 'FinApp',
            'admin_panel_url' => 'https://allindiaitr.in/admin',
            'email_enabled' => '1',
            'push_enabled' => '1',
        ];

        $configFile = __DIR__ . '/notification_config.php';
        if (file_exists($configFile)) {
            require $configFile;
            if (!empty($notification_admin_email)) {
                $defaults['admin_email'] = $notification_admin_email;
            }
        }

        $sql = "SELECT setting_key, setting_value FROM notification_settings";
        $result = $conn->query($sql);
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $defaults[$row['setting_key']] = $row['setting_value'];
            }
        }

        $defaults['email_enabled'] = ($defaults['email_enabled'] === '1' || $defaults['email_enabled'] === 1 || $defaults['email_enabled'] === true);
        $defaults['push_enabled'] = ($defaults['push_enabled'] === '1' || $defaults['push_enabled'] === 1 || $defaults['push_enabled'] === true);

        return $defaults;
    }

    private static function loadTemplates($conn, $eventKey)
    {
        $eventKeyEsc = mysqli_real_escape_string($conn, $eventKey);
        $sql = "SELECT * FROM notification_templates WHERE event_key = '$eventKeyEsc' AND is_active = 1";
        $result = $conn->query($sql);
        $templates = [];
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $templates[] = $row;
            }
        }
        return $templates;
    }

    private static function enrichContext($conn, array $context, array $settings)
    {
        if (empty($context['adminPanelUrl'])) {
            $context['adminPanelUrl'] = $settings['admin_panel_url'] ?? 'https://allindiaitr.in/admin';
        }

        if (!empty($context['userId']) && empty($context['clientName'])) {
            $user = self::fetchUser($conn, $context['userId']);
            if ($user) {
                $context['clientName'] = trim(($user['FirstName'] ?? '') . ' ' . ($user['LastName'] ?? ''));
                $context['email'] = $context['email'] ?? ($user['Email'] ?? '');
                $context['mobile'] = $context['mobile'] ?? ($user['Mobile'] ?? '');
            }
        }

        if (!empty($context['professionalId']) && empty($context['expertName'])) {
            $pro = self::fetchUser($conn, $context['professionalId']);
            if ($pro) {
                $context['expertName'] = trim(($pro['FirstName'] ?? '') . ' ' . ($pro['LastName'] ?? ''));
                $context['expertEmail'] = $context['expertEmail'] ?? ($pro['Email'] ?? '');
            }
        }

        if (!empty($context['statusStep']) && empty($context['statusStepTitle'])) {
            $stepEsc = mysqli_real_escape_string($conn, (string) $context['statusStep']);
            $titleResult = $conn->query("SELECT title FROM itr_status_config WHERE step_code = '$stepEsc' AND is_active = 1 LIMIT 1");
            if ($titleResult && $titleResult->num_rows > 0) {
                $context['statusStepTitle'] = $titleResult->fetch_assoc()['title'];
            } else {
                $context['statusStepTitle'] = ucwords(str_replace('_', ' ', (string) $context['statusStep']));
            }
        }

        return $context;
    }

    private static function fetchUser($conn, $userId)
    {
        $id = mysqli_real_escape_string($conn, (string) $userId);
        $sql = "SELECT UserId, FirstName, LastName, Email, Mobile, Role FROM users WHERE UserId = '$id' LIMIT 1";
        $result = $conn->query($sql);
        if ($result && $result->num_rows > 0) {
            return $result->fetch_assoc();
        }
        return null;
    }

    /**
     * @return array<int, array{user_id:?string,email:?string,name:?string}>
     */
    private static function resolveRecipients($conn, $audience, array $context, array $settings)
    {
        $recipients = [];

        if ($audience === 'ADMIN') {
            $email = $settings['admin_email'] ?? '';
            if ($email !== '') {
                $recipients[] = ['user_id' => null, 'email' => $email, 'name' => 'Admin'];
            }
            return $recipients;
        }

        if ($audience === 'CLIENT') {
            $userId = $context['userId'] ?? null;
            $email = $context['email'] ?? null;
            if ($userId) {
                $user = self::fetchUser($conn, $userId);
                $email = $email ?: ($user['Email'] ?? null);
            }
            if ($email) {
                $recipients[] = [
                    'user_id' => $userId ? (string) $userId : null,
                    'email' => $email,
                    'name' => $context['clientName'] ?? 'Client',
                ];
            }
            return $recipients;
        }

        if ($audience === 'PROFESSIONAL') {
            $professionalId = $context['professionalId'] ?? null;
            if ($professionalId) {
                $pro = self::fetchUser($conn, $professionalId);
                if ($pro && !empty($pro['Email'])) {
                    $recipients[] = [
                        'user_id' => (string) $professionalId,
                        'email' => $pro['Email'],
                        'name' => trim(($pro['FirstName'] ?? '') . ' ' . ($pro['LastName'] ?? '')),
                    ];
                }
            }
            return $recipients;
        }

        return $recipients;
    }

    private static function renderTemplate(array $template, array $context)
    {
        $replace = [];
        foreach ($context as $key => $value) {
            if (is_scalar($value) || $value === null) {
                $replace['{{' . $key . '}}'] = (string) ($value ?? '');
            }
        }

        return [
            'email_subject' => strtr($template['email_subject'] ?? '', $replace),
            'email_body_html' => strtr($template['email_body_html'] ?? '', $replace),
            'email_body_text' => strtr($template['email_body_text'] ?? '', $replace),
            'push_title' => strtr($template['push_title'] ?? '', $replace),
            'push_body' => strtr($template['push_body'] ?? '', $replace),
            'push_route' => strtr($template['push_route'] ?? '/', $replace),
        ];
    }

    private static function sendEmail($conn, $eventKey, $audience, array $recipient, array $rendered, array $context, array $settings)
    {
        if (!EmailService::isConfigured()) {
            self::logDelivery($conn, $eventKey, $audience, 'EMAIL', $recipient['email'], $context, 'skipped', 'SMTP not configured');
            return;
        }

        $result = EmailService::send(
            $recipient['email'],
            $rendered['email_subject'],
            $rendered['email_body_html'],
            $rendered['email_body_text']
        );

        self::logDelivery(
            $conn,
            $eventKey,
            $audience,
            'EMAIL',
            $recipient['email'],
            $context,
            $result['success'] ? 'sent' : 'failed',
            $result['error']
        );
    }

    private static function sendPush($conn, $eventKey, $audience, array $recipient, array $rendered, array $context)
    {
        $userId = $recipient['user_id'] ?? null;
        if (!$userId || $rendered['push_title'] === '' || $rendered['push_body'] === '') {
            return;
        }

        $tokens = self::fetchFcmTokens($conn, $userId);
        if (empty($tokens)) {
            self::logDelivery($conn, $eventKey, $audience, 'PUSH', $userId, $context, 'skipped', 'No FCM token');
            return;
        }

        $data = [
            'route' => $rendered['push_route'] ?: '/',
            'event' => $eventKey,
        ];
        if (!empty($context['itrId'])) {
            $data['itrId'] = (string) $context['itrId'];
        }
        if (!empty($context['orderId'])) {
            $data['orderId'] = (string) $context['orderId'];
        }

        $result = FcmHelper::sendToTokens($tokens, $rendered['push_title'], $rendered['push_body'], $data);

        $status = ($result['success'] > 0) ? 'sent' : 'failed';
        $error = !empty($result['errors']) ? implode('; ', $result['errors']) : null;

        self::logDelivery($conn, $eventKey, $audience, 'PUSH', $userId, $context, $status, $error);
    }

    private static function fetchFcmTokens($conn, $userId)
    {
        $id = mysqli_real_escape_string($conn, (string) $userId);
        $sql = "SELECT fcm_token FROM user_fcm_tokens WHERE user_id = '$id' AND is_active = 1";
        $result = $conn->query($sql);
        $tokens = [];
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                if (!empty($row['fcm_token'])) {
                    $tokens[] = $row['fcm_token'];
                }
            }
        }
        return $tokens;
    }

    private static function referenceFromContext(array $context)
    {
        if (!empty($context['notificationReferenceType']) && !empty($context['notificationReferenceId'])) {
            return [(string) $context['notificationReferenceType'], (string) $context['notificationReferenceId']];
        }

        if (!empty($context['orderId'])) {
            return ['order_id', (string) $context['orderId']];
        }
        if (!empty($context['itrId'])) {
            return ['itr_id', (string) $context['itrId']];
        }
        if (!empty($context['userId'])) {
            return ['user_id', (string) $context['userId']];
        }
        return [null, null];
    }

    private static function alreadySent($conn, $eventKey, $audience, array $recipient, array $context)
    {
        list($refType, $refId) = self::referenceFromContext($context);
        if (!$refType || !$refId) {
            return false;
        }

        $eventEsc = mysqli_real_escape_string($conn, $eventKey);
        $audEsc = mysqli_real_escape_string($conn, $audience);
        $refTypeEsc = mysqli_real_escape_string($conn, $refType);
        $refIdEsc = mysqli_real_escape_string($conn, $refId);
        $recipientEsc = mysqli_real_escape_string($conn, $recipient['email'] ?? ($recipient['user_id'] ?? ''));

        $sql = "SELECT id FROM notification_delivery_log
                WHERE event_key = '$eventEsc'
                  AND audience = '$audEsc'
                  AND reference_type = '$refTypeEsc'
                  AND reference_id = '$refIdEsc'
                  AND recipient = '$recipientEsc'
                  AND status = 'sent'
                LIMIT 1";
        $result = $conn->query($sql);
        return $result && $result->num_rows > 0;
    }

    private static function logDelivery($conn, $eventKey, $audience, $channel, $recipient, array $context, $status, $error = null)
    {
        list($refType, $refId) = self::referenceFromContext($context);

        $eventEsc = mysqli_real_escape_string($conn, $eventKey);
        $audEsc = mysqli_real_escape_string($conn, $audience);
        $channelEsc = mysqli_real_escape_string($conn, $channel);
        $recipientEsc = mysqli_real_escape_string($conn, (string) $recipient);
        $refTypeEsc = $refType ? "'" . mysqli_real_escape_string($conn, $refType) . "'" : 'NULL';
        $refIdEsc = $refId ? "'" . mysqli_real_escape_string($conn, $refId) . "'" : 'NULL';
        $statusEsc = mysqli_real_escape_string($conn, $status);
        $errorEsc = $error ? "'" . mysqli_real_escape_string($conn, $error) . "'" : 'NULL';
        $payloadEsc = "'" . mysqli_real_escape_string($conn, json_encode($context)) . "'";

        $sql = "INSERT INTO notification_delivery_log
            (event_key, audience, channel, recipient, reference_type, reference_id, status, error_message, payload_json)
            VALUES
            ('$eventEsc', '$audEsc', '$channelEsc', '$recipientEsc', $refTypeEsc, $refIdEsc, '$statusEsc', $errorEsc, $payloadEsc)";

        @$conn->query($sql);
    }
}

/**
 * Safe helper for workflow endpoints — never breaks API responses.
 */
function notifyWorkflowEvent($conn, $eventKey, array $context = [])
{
    try {
        require_once __DIR__ . '/NotificationDispatcher.php';
        NotificationDispatcher::dispatch($conn, $eventKey, $context);
    } catch (Throwable $e) {
        error_log('[notifyWorkflowEvent] ' . $e->getMessage());
    }
}
