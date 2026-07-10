<?php
/**
 * Admin Notification Templates & Settings API
 *
 * GET  /admin/notification_templates.php              - list templates + settings
 * GET  /admin/notification_templates.php?id={id}    - single template
 * PUT  /admin/notification_templates.php            - update template (body: { id, ...fields })
 * PUT  /admin/notification_templates.php?settings=1 - update settings (body: { adminEmail, emailEnabled, pushEnabled, ... })
 *
 * Auth: ADMIN only
 */

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require '../include/config.php';
require '../phpjwt/Token.php';

$headers = getallheaders();
$token = isset($headers['Authorization']) ? str_replace("Bearer ", "", trim($headers['Authorization'])) : "";

if (empty($token)) {
    http_response_code(401);
    echo json_encode(["status" => "error", "statusCode" => 401, "data" => ["message" => "Authorization token required"]]);
    exit;
}

$decoded = Token::Verify($token, $key);
if ($decoded === false) {
    http_response_code(401);
    echo json_encode(["status" => "error", "statusCode" => 401, "data" => ["message" => "Invalid or expired token"]]);
    exit;
}

$userRole = $decoded['Role'] ?? null;
if ($userRole !== 'ADMIN') {
    http_response_code(403);
    echo json_encode(["status" => "error", "statusCode" => 403, "data" => ["message" => "Admin access only"]]);
    exit;
}

function tableExists($conn, $table)
{
    $tableEsc = mysqli_real_escape_string($conn, $table);
    $result = $conn->query("SHOW TABLES LIKE '$tableEsc'");
    return $result && $result->num_rows > 0;
}

function mapTemplateRow(array $row)
{
    return [
        "id" => (int) $row['id'],
        "eventKey" => $row['event_key'],
        "audience" => $row['audience'],
        "channel" => $row['channel'],
        "emailSubject" => $row['email_subject'],
        "emailBodyHtml" => $row['email_body_html'],
        "emailBodyText" => $row['email_body_text'],
        "pushTitle" => $row['push_title'],
        "pushBody" => $row['push_body'],
        "pushRoute" => $row['push_route'],
        "isActive" => (bool) $row['is_active'],
        "createdAt" => $row['created_at'],
        "updatedAt" => $row['updated_at'],
    ];
}

function loadSettings($conn)
{
    $settings = [
        'adminEmail' => 'finnextgen2026@gmail.com',
        'fromEmail' => 'noreply@allindiaitr.in',
        'fromName' => 'FinApp',
        'adminPanelUrl' => 'https://allindiaitr.in/admin',
        'emailEnabled' => true,
        'pushEnabled' => true,
    ];

    if (!tableExists($conn, 'notification_settings')) {
        return $settings;
    }

    $result = $conn->query("SELECT setting_key, setting_value FROM notification_settings");
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $key = $row['setting_key'];
            $val = $row['setting_value'];
            switch ($key) {
                case 'admin_email':
                    $settings['adminEmail'] = $val;
                    break;
                case 'from_email':
                    $settings['fromEmail'] = $val;
                    break;
                case 'from_name':
                    $settings['fromName'] = $val;
                    break;
                case 'admin_panel_url':
                    $settings['adminPanelUrl'] = $val;
                    break;
                case 'email_enabled':
                    $settings['emailEnabled'] = ($val === '1' || $val === 1 || $val === true);
                    break;
                case 'push_enabled':
                    $settings['pushEnabled'] = ($val === '1' || $val === 1 || $val === true);
                    break;
            }
        }
    }

    return $settings;
}

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    if (!tableExists($conn, 'notification_templates')) {
        http_response_code(503);
        echo json_encode([
            "status" => "error",
            "statusCode" => 503,
            "data" => ["message" => "Notification tables not found. Run add_transactional_notification_system.sql migration."]
        ]);
        exit;
    }

    $id = isset($_GET['id']) ? (int) $_GET['id'] : null;

    if ($id) {
        $idEsc = (int) $id;
        $result = $conn->query("SELECT * FROM notification_templates WHERE id = $idEsc LIMIT 1");
        if (!$result || $result->num_rows === 0) {
            http_response_code(404);
            echo json_encode(["status" => "error", "statusCode" => 404, "data" => ["message" => "Template not found"]]);
            exit;
        }
        $row = $result->fetch_assoc();
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "template" => mapTemplateRow($row),
                "placeholders" => [
                    '{{clientName}}', '{{email}}', '{{mobile}}', '{{pan}}', '{{financialYear}}',
                    '{{packageName}}', '{{amount}}', '{{orderId}}', '{{itrId}}', '{{expertName}}',
                    '{{expertEmail}}', '{{documentCount}}', '{{adminPanelUrl}}', '{{statusStep}}',
                    '{{statusStepTitle}}', '{{statusNotes}}', '{{statusLabel}}', '{{statusComment}}',
                    '{{concernText}}',
                ],
            ]
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $result = $conn->query("SELECT * FROM notification_templates ORDER BY event_key ASC, audience ASC");
    $templates = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $templates[] = mapTemplateRow($row);
        }
    }

    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "templates" => $templates,
            "settings" => loadSettings($conn),
            "total" => count($templates),
        ]
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($method === 'PUT') {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        http_response_code(400);
        echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "Invalid JSON input"]]);
        exit;
    }

    $updateSettings = isset($_GET['settings']) && $_GET['settings'] === '1';

    if ($updateSettings) {
        if (!tableExists($conn, 'notification_settings')) {
            http_response_code(503);
            echo json_encode(["status" => "error", "statusCode" => 503, "data" => ["message" => "notification_settings table not found"]]);
            exit;
        }

        $map = [
            'adminEmail' => 'admin_email',
            'fromEmail' => 'from_email',
            'fromName' => 'from_name',
            'adminPanelUrl' => 'admin_panel_url',
        ];

        foreach ($map as $inputKey => $dbKey) {
            if (isset($input[$inputKey])) {
                $val = mysqli_real_escape_string($conn, (string) $input[$inputKey]);
                $conn->query("INSERT INTO notification_settings (setting_key, setting_value) VALUES ('$dbKey', '$val')
                    ON DUPLICATE KEY UPDATE setting_value = '$val'");
            }
        }

        if (isset($input['emailEnabled'])) {
            $val = $input['emailEnabled'] ? '1' : '0';
            $conn->query("INSERT INTO notification_settings (setting_key, setting_value) VALUES ('email_enabled', '$val')
                ON DUPLICATE KEY UPDATE setting_value = '$val'");
        }
        if (isset($input['pushEnabled'])) {
            $val = $input['pushEnabled'] ? '1' : '0';
            $conn->query("INSERT INTO notification_settings (setting_key, setting_value) VALUES ('push_enabled', '$val')
                ON DUPLICATE KEY UPDATE setting_value = '$val'");
        }

        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" => [
                "message" => "Notification settings updated",
                "settings" => loadSettings($conn),
            ]
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $id = isset($input['id']) ? (int) $input['id'] : 0;
    if ($id <= 0) {
        http_response_code(400);
        echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "id is required"]]);
        exit;
    }

    $check = $conn->query("SELECT id FROM notification_templates WHERE id = $id LIMIT 1");
    if (!$check || $check->num_rows === 0) {
        http_response_code(404);
        echo json_encode(["status" => "error", "statusCode" => 404, "data" => ["message" => "Template not found"]]);
        exit;
    }

    $allowedChannels = ['EMAIL', 'PUSH', 'BOTH'];
    $updates = [];

    if (isset($input['channel'])) {
        $channel = strtoupper(trim($input['channel']));
        if (!in_array($channel, $allowedChannels, true)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "Invalid channel"]]);
            exit;
        }
        $updates[] = "channel = '" . mysqli_real_escape_string($conn, $channel) . "'";
    }

    $textFields = [
        'emailSubject' => 'email_subject',
        'emailBodyHtml' => 'email_body_html',
        'emailBodyText' => 'email_body_text',
        'pushTitle' => 'push_title',
        'pushBody' => 'push_body',
        'pushRoute' => 'push_route',
    ];

    foreach ($textFields as $inputKey => $dbCol) {
        if (array_key_exists($inputKey, $input)) {
            $val = $input[$inputKey];
            if ($val === null || $val === '') {
                $updates[] = "$dbCol = NULL";
            } else {
                $updates[] = "$dbCol = '" . mysqli_real_escape_string($conn, (string) $val) . "'";
            }
        }
    }

    if (isset($input['isActive'])) {
        $updates[] = 'is_active = ' . ($input['isActive'] ? 1 : 0);
    }

    if (empty($updates)) {
        http_response_code(400);
        echo json_encode(["status" => "error", "statusCode" => 400, "data" => ["message" => "No fields to update"]]);
        exit;
    }

    $sql = "UPDATE notification_templates SET " . implode(', ', $updates) . " WHERE id = $id";
    if (!$conn->query($sql)) {
        http_response_code(500);
        echo json_encode(["status" => "error", "statusCode" => 500, "data" => ["message" => "Update failed: " . $conn->error]]);
        exit;
    }

    $result = $conn->query("SELECT * FROM notification_templates WHERE id = $id LIMIT 1");
    $row = $result->fetch_assoc();

    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "message" => "Template updated successfully",
            "template" => mapTemplateRow($row),
        ]
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

http_response_code(405);
echo json_encode(["status" => "error", "statusCode" => 405, "data" => ["message" => "Method not allowed"]]);
exit;
