<?php
require_once __DIR__ . '/../include/config.php';
require_once __DIR__ . '/../include/AssociateHelper.php';

AssociateHelper::sendCors('GET, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    AssociateHelper::json(405, 'error', ['message' => 'Only GET allowed']);
}

if (!AssociateHelper::tableExists($conn, 'associate_profiles')) {
    AssociateHelper::json(200, 'success', ['associates' => [], 'total' => 0]);
}

$serviceId = isset($_GET['serviceId']) ? (int)$_GET['serviceId'] : 0;
$search = isset($_GET['search']) ? trim($_GET['search']) : '';
$city = isset($_GET['city']) ? trim($_GET['city']) : '';
$limit = isset($_GET['limit']) ? max(1, min(100, (int)$_GET['limit'])) : 50;
$offset = isset($_GET['offset']) ? max(0, (int)$_GET['offset']) : 0;

$where = "p.approval_status = 'approved'";
if ($search !== '') {
    $q = mysqli_real_escape_string($conn, $search);
    $where .= " AND (u.FirstName LIKE '%$q%' OR u.LastName LIKE '%$q%' OR p.city LIKE '%$q%' OR p.icai_membership_no LIKE '%$q%')";
}
if ($city !== '') {
    $c = mysqli_real_escape_string($conn, $city);
    $where .= " AND p.city LIKE '%$c%'";
}

$joinFees = '';
if ($serviceId > 0 && AssociateHelper::tableExists($conn, 'associate_service_fees')) {
    $joinFees = "INNER JOIN associate_service_fees f ON f.associate_id = p.user_id AND f.service_id = $serviceId AND f.is_active = 1";
}

$sql = "SELECT p.*, u.FirstName, u.MiddleName, u.LastName, u.Email, u.Mobile, u.CreatedAt AS registered_at
        FROM associate_profiles p
        INNER JOIN users u ON u.UserId = p.user_id
        $joinFees
        WHERE $where
        ORDER BY p.years_experience DESC, u.FirstName ASC
        LIMIT $limit OFFSET $offset";

$result = $conn->query($sql);
$associates = [];
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $fees = AssociateHelper::getServiceFees($conn, (int)$row['user_id'], true);
        if ($serviceId > 0) {
            $fees = array_values(array_filter($fees, function ($fee) use ($serviceId) {
                return (int)$fee['service_id'] === $serviceId;
            }));
        }
        $associates[] = AssociateHelper::publicAssociate($row, $fees);
    }
}

AssociateHelper::json(200, 'success', [
    'associates' => $associates,
    'total' => count($associates),
    'service_id' => $serviceId > 0 ? $serviceId : null,
]);
