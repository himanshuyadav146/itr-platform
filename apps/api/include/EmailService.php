<?php
/**
 * Lightweight SMTP email sender (no Composer dependency).
 * Uses notification_config.php for SMTP credentials.
 */

class EmailService
{
    private static $configLoaded = false;
    private static $enabled = false;
    private static $host = '';
    private static $port = 587;
    private static $secure = 'tls';
    private static $username = '';
    private static $password = '';
    private static $fromEmail = '';
    private static $fromName = 'FinApp';

    private static function loadConfig()
    {
        if (self::$configLoaded) {
            return;
        }
        self::$configLoaded = true;

        $configFile = __DIR__ . '/notification_config.php';
        if (file_exists($configFile)) {
            require $configFile;
        }

        if (isset($notification_email_enabled)) {
            self::$enabled = (bool) $notification_email_enabled;
        }
        if (!empty($notification_smtp_host)) {
            self::$host = $notification_smtp_host;
        }
        if (!empty($notification_smtp_port)) {
            self::$port = (int) $notification_smtp_port;
        }
        if (!empty($notification_smtp_secure)) {
            self::$secure = strtolower($notification_smtp_secure);
        }
        if (!empty($notification_smtp_username)) {
            self::$username = $notification_smtp_username;
        }
        if (!empty($notification_smtp_password)) {
            self::$password = $notification_smtp_password;
        }
        if (!empty($notification_from_email)) {
            self::$fromEmail = $notification_from_email;
        }
        if (!empty($notification_from_name)) {
            self::$fromName = $notification_from_name;
        }
    }

    public static function isConfigured()
    {
        self::loadConfig();
        return self::$enabled
            && self::$host !== ''
            && self::$username !== ''
            && self::$password !== ''
            && self::$fromEmail !== '';
    }

    /**
     * @return array{success:bool,error:?string}
     */
    public static function send($toEmail, $subject, $htmlBody, $textBody = '')
    {
        self::loadConfig();

        $toEmail = trim((string) $toEmail);
        if ($toEmail === '' || !filter_var($toEmail, FILTER_VALIDATE_EMAIL)) {
            return ['success' => false, 'error' => 'Invalid recipient email'];
        }

        if (!self::isConfigured()) {
            return ['success' => false, 'error' => 'SMTP not configured (copy include/notification_config.php.example)'];
        }

        if ($textBody === '') {
            $textBody = strip_tags(str_replace(['<br>', '<br/>', '<br />'], "\n", $htmlBody));
        }

        try {
            self::sendViaSmtp($toEmail, $subject, $htmlBody, $textBody);
            return ['success' => true, 'error' => null];
        } catch (Exception $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    private static function sendViaSmtp($toEmail, $subject, $htmlBody, $textBody)
    {
        $host = self::$host;
        $port = self::$port;
        $secure = self::$secure;
        $remote = ($secure === 'ssl' ? 'ssl://' : '') . $host . ':' . $port;

        $socket = @stream_socket_client(
            $remote,
            $errno,
            $errstr,
            20,
            STREAM_CLIENT_CONNECT
        );

        if (!$socket) {
            throw new Exception("SMTP connect failed: $errstr ($errno)");
        }

        stream_set_timeout($socket, 20);
        self::expect($socket, [220]);
        self::cmd($socket, 'EHLO ' . gethostname(), [250]);

        if ($secure === 'tls') {
            self::cmd($socket, 'STARTTLS', [220]);
            if (!stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLS_CLIENT)) {
                throw new Exception('STARTTLS failed');
            }
            self::cmd($socket, 'EHLO ' . gethostname(), [250]);
        }

        self::cmd($socket, 'AUTH LOGIN', [334]);
        self::cmd($socket, base64_encode(self::$username), [334]);
        self::cmd($socket, base64_encode(self::$password), [235]);

        self::cmd($socket, 'MAIL FROM:<' . self::$fromEmail . '>', [250]);
        self::cmd($socket, 'RCPT TO:<' . $toEmail . '>', [250, 251]);
        self::cmd($socket, 'DATA', [354]);

        $boundary = 'finapp_' . md5(uniqid((string) mt_rand(), true));
        $encodedSubject = self::encodeHeader($subject);
        $headers = [
            'From: ' . self::encodeHeader(self::$fromName) . ' <' . self::$fromEmail . '>',
            'To: <' . $toEmail . '>',
            'Subject: ' . $encodedSubject,
            'MIME-Version: 1.0',
            'Content-Type: multipart/alternative; boundary="' . $boundary . '"',
        ];

        $body = implode("\r\n", $headers) . "\r\n\r\n";
        $body .= '--' . $boundary . "\r\n";
        $body .= "Content-Type: text/plain; charset=UTF-8\r\n\r\n";
        $body .= $textBody . "\r\n\r\n";
        $body .= '--' . $boundary . "\r\n";
        $body .= "Content-Type: text/html; charset=UTF-8\r\n\r\n";
        $body .= $htmlBody . "\r\n\r\n";
        $body .= '--' . $boundary . "--\r\n";
        $body = str_replace(["\r\n.", "\n."], ["\r\n..", "\n.."], $body);

        fwrite($socket, $body . "\r\n.\r\n");
        self::expect($socket, [250]);
        self::cmd($socket, 'QUIT', [221]);
        fclose($socket);
    }

    private static function cmd($socket, $command, array $okCodes)
    {
        fwrite($socket, $command . "\r\n");
        self::expect($socket, $okCodes);
    }

    private static function expect($socket, array $okCodes)
    {
        $response = '';
        while (($line = fgets($socket, 515)) !== false) {
            $response .= $line;
            if (isset($line[3]) && $line[3] === ' ') {
                break;
            }
        }
        $code = (int) substr($response, 0, 3);
        if (!in_array($code, $okCodes, true)) {
            throw new Exception('SMTP error: ' . trim($response));
        }
    }

    private static function encodeHeader($text)
    {
        if (preg_match('/[^\x20-\x7E]/', $text)) {
            return '=?UTF-8?B?' . base64_encode($text) . '?=';
        }
        return $text;
    }
}
