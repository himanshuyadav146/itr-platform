<?php
require_once __DIR__ . '/../include/config.php';
require_once __DIR__ . '/../include/AssociateHelper.php';

AssociateHelper::sendCors('GET, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    AssociateHelper::json(405, 'error', ['message' => 'Only GET allowed']);
}

$associateId = isset($_GET['associateId']) ? (int)$_GET['associateId'] : 0;
$services = AssociateHelper::listServices($conn, true);

if ($associateId > 0) {
    $fees = AssociateHelper::getServiceFees($conn, $associateId, true);
    $feeMap = [];
    foreach ($fees as $fee) {
        $feeMap[(int)$fee['service_id']] = $fee;
    }
    foreach ($services as &$service) {
        $sid = (int)$service['id'];
        if (isset($feeMap[$sid])) {
            $service['listed_fee'] = $feeMap[$sid]['listed_fee'];
            $service['has_fee'] = true;
        } else {
            $service['listed_fee'] = null;
            $service['has_fee'] = false;
        }
    }
    unset($service);
}

AssociateHelper::json(200, 'success', [
    'services' => $services,
    'associate_id' => $associateId > 0 ? $associateId : null,
]);
