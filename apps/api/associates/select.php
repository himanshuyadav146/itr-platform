<?php
require_once __DIR__ . '/../include/config.php';
require_once __DIR__ . '/../phpjwt/Token.php';
require_once __DIR__ . '/../include/AssociateHelper.php';

AssociateHelper::sendCors('POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    AssociateHelper::json(405, 'error', ['message' => 'Only POST allowed']);
}

$decoded = AssociateHelper::requireAuth($key);
$data = AssociateHelper::readJson();

$associateId = isset($data['associateId']) ? (int)$data['associateId'] : 0;
$serviceId = isset($data['serviceId']) ? (int)$data['serviceId'] : 0;
$panNumber = strtoupper(trim($data['panNumber'] ?? $data['PanNumber'] ?? ''));

if ($associateId <= 0 || $serviceId <= 0) {
    AssociateHelper::json(400, 'error', ['message' => 'associateId and serviceId are required']);
}

if (!AssociateHelper::isApprovedAssociate($conn, $associateId)) {
    AssociateHelper::json(400, 'error', ['message' => 'Associate is not approved for listing']);
}

$fee = AssociateHelper::getListedFee($conn, $associateId, $serviceId);
if ($fee === null) {
    AssociateHelper::json(400, 'error', ['message' => 'Associate has no listed fee for this service']);
}

$userId = (int)$decoded['UserId'];
if ($panNumber !== '' && AssociateHelper::columnExists($conn, 'personal_details', 'associate_id')) {
    $panEsc = mysqli_real_escape_string($conn, $panNumber);
    $conn->query("UPDATE personal_details
                  SET associate_id = $associateId, service_id = $serviceId, updatedAt = NOW()
                  WHERE UserId = $userId AND PANNumber = '$panEsc'");
}

AssociateHelper::json(200, 'success', [
    'message' => 'Associate selected',
    'associate_id' => $associateId,
    'service_id' => $serviceId,
    'listed_fee' => $fee['listed_fee'],
    'service_name' => $fee['service_name'],
    'pan_number' => $panNumber !== '' ? $panNumber : null,
]);
