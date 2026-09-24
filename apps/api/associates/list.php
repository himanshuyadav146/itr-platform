<?php
require_once __DIR__ . '/_bootstrap.php';

AssociateHelper::requireMethod(['GET']);

$serviceId = isset($_GET['serviceId']) ? (int)$_GET['serviceId'] : 0;
$city = isset($_GET['city']) ? trim($_GET['city']) : '';
$role = isset($_GET['role']) ? strtoupper(trim($_GET['role'])) : '';

$where = [
    "ap.verification_status = 'approved'",
    "ap.is_listed = 1",
    "UPPER(TRIM(u.Role)) IN ('CA','ACCOUNTANT','TAX_EXPERT')",
];

if ($serviceId > 0) {
    $where[] = "asf.service_id = $serviceId";
    $where[] = "asf.is_active = 1";
}
if ($city !== '') {
    $cityEsc = mysqli_real_escape_string($conn, $city);
    $where[] = "ap.city LIKE '%$cityEsc%'";
}
if ($role !== '' && AssociateHelper::isAssociateRole($role)) {
    $roleEsc = mysqli_real_escape_string($conn, $role);
    $where[] = "UPPER(TRIM(u.Role)) = '$roleEsc'";
}

$whereSql = implode(' AND ', $where);

if ($serviceId > 0) {
    $sql = "SELECT
                u.UserId, u.FirstName, u.LastName, u.Role, u.Email, u.Mobile,
                ap.bio, ap.years_experience, ap.qualification, ap.license_number,
                ap.city, ap.languages, ap.photo_url, ap.verification_status, ap.is_listed,
                asf.fee, asf.service_id, s.name AS service_name, s.description AS service_description
            FROM users u
            INNER JOIN associate_profiles ap ON ap.user_id = u.UserId
            INNER JOIN associate_service_fees asf ON asf.user_id = u.UserId
            INNER JOIN services s ON s.id = asf.service_id
            WHERE $whereSql
            ORDER BY ap.years_experience DESC, u.FirstName ASC";
} else {
    $sql = "SELECT
                u.UserId, u.FirstName, u.LastName, u.Role, u.Email, u.Mobile,
                ap.bio, ap.years_experience, ap.qualification, ap.license_number,
                ap.city, ap.languages, ap.photo_url, ap.verification_status, ap.is_listed
            FROM users u
            INNER JOIN associate_profiles ap ON ap.user_id = u.UserId
            WHERE $whereSql
            ORDER BY ap.years_experience DESC, u.FirstName ASC";
}

$result = $conn->query($sql);
if ($result === false) {
    AssociateHelper::jsonResponse(500, 'error', ['message' => 'Failed to list associates']);
}

$associates = [];
$seen = [];
while ($row = $result->fetch_assoc()) {
    $id = (int)$row['UserId'];
    if (isset($seen[$id])) {
        continue;
    }
    $seen[$id] = true;

    $fees = [];
    if ($serviceId > 0) {
        $fees[] = AssociateHelper::formatFeeRow($row);
    } else {
        $fees = AssociateHelper::getFees($conn, $id, true);
    }

    $profile = AssociateHelper::formatProfile($row, $fees);
    unset($profile['email'], $profile['mobile'], $profile['rejectionReason']);
    if ($serviceId > 0) {
        $profile['listedFee'] = floatval($row['fee']);
        $profile['serviceId'] = (int)$row['service_id'];
        $profile['serviceName'] = $row['service_name'] ?? '';
    }
    $associates[] = $profile;
}

AssociateHelper::jsonResponse(200, 'success', [
    'associates' => $associates,
    'count' => count($associates),
]);
