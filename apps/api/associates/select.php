<?php
require_once __DIR__ . '/_bootstrap.php';

AssociateHelper::requireMethod(['POST']);
$auth = AssociateHelper::requireUser($key);

$data = AssociateHelper::readJsonBody();
$associateId = (int)($data['associateId'] ?? $data['associate_id'] ?? 0);
$serviceId = (int)($data['serviceId'] ?? $data['service_id'] ?? 0);
$panNumber = strtoupper(trim((string)($data['panNumber'] ?? '')));

$checkout = AssociateHelper::getListedCheckout($conn, $associateId, $serviceId);
if (!$checkout) {
    AssociateHelper::jsonResponse(400, 'error', [
        'message' => 'Associate is not available for this service',
    ]);
}

$quotedFee = $checkout['fee'];
$selection = [
    'associateId' => (int)$checkout['UserId'],
    'associateName' => $checkout['name'],
    'role' => $checkout['Role'],
    'serviceId' => (int)$checkout['service_id'],
    'serviceName' => $checkout['service_name'],
    'quotedFee' => $quotedFee,
    'city' => $checkout['city'] ?? '',
    'yearsExperience' => (int)($checkout['years_experience'] ?? 0),
];

if ($panNumber !== '' && preg_match('/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/', $panNumber)) {
    $panEsc = mysqli_real_escape_string($conn, $panNumber);
    $userId = (int)$auth['userId'];
    $update = $conn->query("UPDATE personal_details
                            SET associate_id = $associateId, service_id = $serviceId, UpdatedAt = NOW()
                            WHERE UserId = $userId AND PANNumber = '$panEsc'");
    $selection['persisted'] = (bool)$update;
}

AssociateHelper::jsonResponse(200, 'success', [
    'message' => 'Associate selected',
    'selection' => $selection,
]);
