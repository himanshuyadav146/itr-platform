<?php
require_once __DIR__ . '/../include/config.php';
require_once __DIR__ . '/../phpjwt/Token.php';
require_once __DIR__ . '/../include/AssociateHelper.php';

AssociateHelper::sendCors('GET, PUT, POST, OPTIONS');

$method = $_SERVER['REQUEST_METHOD'];
if (!in_array($method, ['GET', 'PUT', 'POST'], true)) {
    AssociateHelper::json(405, 'error', ['message' => 'Method not allowed']);
}

$decoded = AssociateHelper::requireAuth($key);
$user = AssociateHelper::requireAssociate($conn, $decoded);
$userId = (int)$decoded['UserId'];
$role = AssociateHelper::userRole($user);

if (AssociateHelper::userRole($user) === 'ADMIN') {
    $targetId = isset($_GET['userId']) ? (int)$_GET['userId'] : $userId;
} else {
    $targetId = $userId;
    AssociateHelper::ensureProfile($conn, $userId, $role);
}

if ($method === 'GET') {
    $row = AssociateHelper::getProfileRow($conn, $targetId);
    if (!$row) {
        AssociateHelper::json(404, 'error', ['message' => 'Profile not found. Complete credentials to get listed.']);
    }
    $fees = AssociateHelper::getServiceFees($conn, $targetId, false);
    AssociateHelper::json(200, 'success', [
        'profile' => AssociateHelper::formatAssociate($row, $fees),
    ]);
}

$data = AssociateHelper::readJson();
AssociateHelper::ensureProfile($conn, $targetId, $data['role'] ?? $role);

$fields = [
    'icai_membership_no' => 'icai_membership_no',
    'gstin' => 'gstin',
    'pan' => 'pan',
    'city' => 'city',
    'state' => 'state',
    'bio' => 'bio',
];
$sets = [];
foreach ($fields as $input => $column) {
    if (array_key_exists($input, $data) || array_key_exists($column, $data)) {
        $value = $data[$input] ?? $data[$column];
        $esc = mysqli_real_escape_string($conn, trim((string)$value));
        $sets[] = "$column = '$esc'";
    }
}
if (isset($data['years_experience']) || isset($data['yearsExperience'])) {
    $years = (int)($data['years_experience'] ?? $data['yearsExperience']);
    $sets[] = 'years_experience = ' . max(0, $years);
}
if (isset($data['role']) && AssociateHelper::isAssociateRole($data['role'])) {
    $roleEsc = mysqli_real_escape_string($conn, strtoupper($data['role']));
    $sets[] = "role = '$roleEsc'";
}

if (empty($sets)) {
    AssociateHelper::json(400, 'error', ['message' => 'No profile fields to update']);
}

$sets[] = 'updated_at = NOW()';
$sql = 'UPDATE associate_profiles SET ' . implode(', ', $sets) . " WHERE user_id = $targetId";
if (!$conn->query($sql)) {
    AssociateHelper::json(500, 'error', ['message' => 'Failed to save profile: ' . $conn->error]);
}

$row = AssociateHelper::getProfileRow($conn, $targetId);
$fees = AssociateHelper::getServiceFees($conn, $targetId, false);
AssociateHelper::json(200, 'success', [
    'message' => 'Profile saved. Listing stays pending until an admin approves your credentials.',
    'profile' => AssociateHelper::formatAssociate($row, $fees),
]);
