<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, PUT, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../include/config.php';
require_once __DIR__ . '/../phpjwt/Token.php';
require_once __DIR__ . '/../associates/AssociateHelper.php';

$method = AssociateHelper::requireMethod(['GET', 'PUT', 'POST']);
$auth = AssociateHelper::requireUser($key);

$actor = AssociateHelper::fetchUserRole($conn, $auth['userId']);
$actorRole = $actor ? ($actor['Role'] ?? '') : ($auth['role'] ?? '');
if (strtoupper($actorRole) !== 'ADMIN') {
    AssociateHelper::jsonResponse(403, 'error', ['message' => 'Admin access required']);
}

if ($method === 'GET') {
    $status = isset($_GET['status']) ? strtolower(trim($_GET['status'])) : '';
    $role = isset($_GET['role']) ? strtoupper(trim($_GET['role'])) : '';
    $search = isset($_GET['search']) ? trim($_GET['search']) : '';

    $where = ["UPPER(TRIM(u.Role)) IN ('CA','ACCOUNTANT','TAX_EXPERT')"];
    if (in_array($status, ['pending', 'approved', 'rejected'], true)) {
        $statusEsc = mysqli_real_escape_string($conn, $status);
        $where[] = "ap.verification_status = '$statusEsc'";
    }
    if (AssociateHelper::isAssociateRole($role)) {
        $roleEsc = mysqli_real_escape_string($conn, $role);
        $where[] = "UPPER(TRIM(u.Role)) = '$roleEsc'";
    }
    if ($search !== '') {
        $searchEsc = mysqli_real_escape_string($conn, $search);
        $where[] = "(u.FirstName LIKE '%$searchEsc%' OR u.LastName LIKE '%$searchEsc%' OR u.Email LIKE '%$searchEsc%' OR u.Mobile LIKE '%$searchEsc%')";
    }
    $whereSql = implode(' AND ', $where);

    $sql = "SELECT
                u.UserId, u.FirstName, u.LastName, u.Role, u.Email, u.Mobile, u.CreatedAt,
                ap.bio, ap.years_experience, ap.qualification, ap.license_number,
                ap.city, ap.languages, ap.photo_url, ap.verification_status, ap.is_listed, ap.rejection_reason
            FROM users u
            LEFT JOIN associate_profiles ap ON ap.user_id = u.UserId
            WHERE $whereSql
            ORDER BY
                CASE ap.verification_status
                    WHEN 'pending' THEN 0
                    WHEN 'approved' THEN 1
                    ELSE 2
                END,
                u.CreatedAt DESC";
    $result = $conn->query($sql);
    if ($result === false) {
        AssociateHelper::jsonResponse(500, 'error', ['message' => 'Failed to load associates']);
    }

    $items = [];
    while ($row = $result->fetch_assoc()) {
        if (empty($row['verification_status'])) {
            $row['verification_status'] = 'pending';
            $row['is_listed'] = 0;
        }
        $fees = AssociateHelper::getFees($conn, (int)$row['UserId'], false);
        $items[] = AssociateHelper::formatProfile($row, $fees);
    }

    AssociateHelper::jsonResponse(200, 'success', [
        'associates' => $items,
        'count' => count($items),
    ]);
}

$data = AssociateHelper::readJsonBody();
$userId = (int)($data['userId'] ?? $data['id'] ?? 0);
$action = strtolower(trim((string)($data['action'] ?? '')));
$reason = trim((string)($data['rejectionReason'] ?? $data['reason'] ?? ''));

if ($userId <= 0 || !in_array($action, ['approve', 'reject', 'unlist', 'list'], true)) {
    AssociateHelper::jsonResponse(400, 'error', ['message' => 'userId and action (approve|reject|unlist|list) are required']);
}

$target = AssociateHelper::fetchUserRole($conn, $userId);
if (!$target || !AssociateHelper::isAssociateRole($target['Role'])) {
    AssociateHelper::jsonResponse(404, 'error', ['message' => 'Associate not found']);
}

AssociateHelper::ensureProfile($conn, $userId);

if ($action === 'approve') {
    $statusSql = "verification_status = 'approved', is_listed = 1, rejection_reason = NULL";
} elseif ($action === 'reject') {
    $reasonEsc = mysqli_real_escape_string($conn, $reason);
    $statusSql = "verification_status = 'rejected', is_listed = 0, rejection_reason = '$reasonEsc'";
} elseif ($action === 'unlist') {
    $statusSql = "is_listed = 0";
} else {
    $statusSql = "verification_status = 'approved', is_listed = 1, rejection_reason = NULL";
}

$sql = "UPDATE associate_profiles SET $statusSql, updated_at = NOW() WHERE user_id = $userId";
if (!$conn->query($sql)) {
    AssociateHelper::jsonResponse(500, 'error', ['message' => 'Failed to update associate']);
}

$reload = $conn->query("SELECT u.UserId, u.FirstName, u.LastName, u.Role, u.Email, u.Mobile,
                               ap.bio, ap.years_experience, ap.qualification, ap.license_number,
                               ap.city, ap.languages, ap.photo_url, ap.verification_status, ap.is_listed, ap.rejection_reason
                        FROM users u
                        INNER JOIN associate_profiles ap ON ap.user_id = u.UserId
                        WHERE u.UserId = $userId LIMIT 1");
$row = $reload->fetch_assoc();

AssociateHelper::jsonResponse(200, 'success', [
    'message' => 'Associate updated',
    'associate' => AssociateHelper::formatProfile($row, AssociateHelper::getFees($conn, $userId, false)),
]);
