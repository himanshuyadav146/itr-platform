<?php
/**
 * FCM HTTP v1 helper – send push notifications using Firebase Cloud Messaging
 * Requires: firebase_config.php with $firebase_project_id and $firebase_service_account_path
 * No Composer dependency: uses cURL and OpenSSL only.
 */

class FcmHelper
{
    private static $accessToken = null;
    private static $accessTokenExpiry = 0;
    private static $projectId = null;
    private static $serviceAccountPath = null;

    private static function loadConfig()
    {
        if (self::$projectId !== null) {
            return true;
        }
        $configFile = __DIR__ . '/firebase_config.php';
        if (!file_exists($configFile)) {
            return false;
        }
        require $configFile;
        if (empty($firebase_project_id) || empty($firebase_service_account_path) || !file_exists($firebase_service_account_path)) {
            return false;
        }
        self::$projectId = $firebase_project_id;
        self::$serviceAccountPath = $firebase_service_account_path;
        return true;
    }

    private static function base64UrlEncode($data)
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Get OAuth2 access token using service account JWT (RS256)
     */
    private static function getAccessToken()
    {
        if (self::$accessToken !== null && time() < self::$accessTokenExpiry - 60) {
            return self::$accessToken;
        }
        if (!self::loadConfig()) {
            return null;
        }
        $json = file_get_contents(self::$serviceAccountPath);
        $sa = json_decode($json, true);
        if (!$sa || empty($sa['client_email']) || empty($sa['private_key'])) {
            return null;
        }
        $clientEmail = $sa['client_email'];
        $privateKey = $sa['private_key'];
        $privateKey = str_replace('\\n', "\n", $privateKey);

        $now = time();
        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $payload = [
            'iss' => $clientEmail,
            'sub' => $clientEmail,
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600,
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging'
        ];
        $headerB64 = self::base64UrlEncode(json_encode($header));
        $payloadB64 = self::base64UrlEncode(json_encode($payload));
        $signatureInput = $headerB64 . '.' . $payloadB64;

        $key = openssl_pkey_get_private($privateKey);
        if (!$key) {
            return null;
        }
        $signature = '';
        openssl_sign($signatureInput, $signature, $key, OPENSSL_ALGO_SHA256);
        openssl_pkey_free($key);
        $signatureB64 = self::base64UrlEncode($signature);
        $jwt = $signatureInput . '.' . $signatureB64;

        $ch = curl_init('https://oauth2.googleapis.com/token');
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' . urlencode($jwt),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => ['Content-Type: application/x-www-form-urlencoded'],
            CURLOPT_TIMEOUT => 15
        ]);
        $response = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($code !== 200 || !$response) {
            return null;
        }
        $data = json_decode($response, true);
        if (empty($data['access_token'])) {
            return null;
        }
        self::$accessToken = $data['access_token'];
        self::$accessTokenExpiry = $now + (int)($data['expires_in'] ?? 3600);
        return self::$accessToken;
    }

    /**
     * Send notification to a list of FCM tokens.
     * $tokens: array of strings (FCM device tokens)
     * $title: notification title
     * $body: notification body
     * $data: optional associative array (values will be stringified for FCM)
     * Returns: ['success' => int, 'failure' => int, 'errors' => array of messages]
     */
    public static function sendToTokens(array $tokens, $title, $body, array $data = [])
    {
        $result = ['success' => 0, 'failure' => 0, 'errors' => []];
        if (empty($tokens)) {
            return $result;
        }
        $accessToken = self::getAccessToken();
        if (!$accessToken || !self::loadConfig()) {
            $result['errors'][] = 'FCM not configured. Add include/firebase_config.php and service account JSON.';
            $result['failure'] = count($tokens);
            return $result;
        }
        $url = 'https://fcm.googleapis.com/v1/projects/' . self::$projectId . '/messages:send';
        $dataPayload = [];
        foreach ($data as $k => $v) {
            $dataPayload[$k] = is_string($v) ? $v : json_encode($v);
        }
        foreach ($tokens as $token) {
            $token = trim($token);
            if ($token === '') {
                continue;
            }
            $bodyJson = [
                'message' => [
                    'token' => $token,
                    'notification' => [
                        'title' => $title,
                        'body' => $body
                    ]
                ]
            ];
            if (!empty($dataPayload)) {
                $bodyJson['message']['data'] = $dataPayload;
            }
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => json_encode($bodyJson),
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_HTTPHEADER => [
                    'Authorization: Bearer ' . $accessToken,
                    'Content-Type: application/json; UTF-8'
                ],
                CURLOPT_TIMEOUT => 15
            ]);
            $response = curl_exec($ch);
            $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            if ($code === 200 && $response) {
                $result['success']++;
            } else {
                $result['failure']++;
                $err = $response ? json_decode($response, true) : [];
                $result['errors'][] = $err['error']['message'] ?? $response ?: 'HTTP ' . $code;
            }
        }
        return $result;
    }
}
