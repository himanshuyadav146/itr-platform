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

if (AssociateHelper::userRole($user) === 'ADMIN' && isset($_GET['userId'])) {
    $targetId = (int)$_GET['userId'];
} else {
    $targetId = $userId;
}

if ($method === 'GET') {
    $catalog = AssociateHelper::listServices($conn, true);
    $fees = AssociateHelper::getServiceFees($conn, $targetId, false);
    $feeMap = [];
    foreach ($fees as $fee) {
        $feeMap[(int)$fee['service_id']] = $fee;
    }
    $merged = [];
    foreach ($catalog as $service) {
        $sid = (int)$service['id'];
        $existing = $feeMap[$sid] ?? null;
        $merged[] = [
            'service_id' => $sid,
            'service_name' => $service['name'],
            'service_description' => $service['description'],
            'listed_fee' => $existing ? $existing['listed_fee'] : null,
            'is_active' => $existing ? $existing['is_active'] : false,
        ];
    }
    AssociateHelper::json(200, 'success', ['services' => $merged]);
}

$data = AssociateHelper::readJson();
$items = [];
if (isset($data['services']) && is_array($data['services'])) {
    $items = $data['services'];
} elseif (isset($data['service_id']) || isset($data['serviceId'])) {
    $items = [$data];
}

if (empty($items)) {
    AssociateHelper::json(400, 'error', ['message' => 'services array is required']);
}

if (!AssociateHelper::tableExists($conn, 'associate_service_fees')) {
    AssociateHelper::json(500, 'error', ['message' => 'associate_service_fees table is missing. Run add_associate_marketplace.sql']);
}

$saved = 0;
foreach ($items as $item) {
    $serviceId = (int)($item['service_id'] ?? $item['serviceId'] ?? 0);
    if ($serviceId <= 0) {
        continue;
    }
    $listedFee = isset($item['listed_fee']) ? (float)$item['listed_fee'] : (isset($item['listedFee']) ? (float)$item['listedFee'] : 0);
    if ($listedFee < 0) {
        $listedFee = 0;
    }
    $isActive = !empty($item['is_active']) || !empty($item['isActive']) || $listedFee > 0 ? 1 : 0;
    if (array_key_exists('is_active', $item)) {
        $isActive = $item['is_active'] ? 1 : 0;
    } elseif (array_key_exists('isActive', $item)) {
        $isActive = $item['isActive'] ? 1 : 0;
    }

    $existing = $conn->query("SELECT id FROM associate_service_fees WHERE associate_id = $targetId AND service_id = $serviceId LIMIT 1");
    if ($existing && $existing->num_rows > 0) {
        $ok = $conn->query("UPDATE associate_service_fees
                            SET listed_fee = $listedFee, is_active = $isActive, updated_at = NOW()
                            WHERE associate_id = $targetId AND service_id = $serviceId");
    } else {
        $ok = $conn->query("INSERT INTO associate_service_fees (associate_id, service_id, listed_fee, is_active)
                            VALUES ($targetId, $serviceId, $listedFee, $isActive)");
    }
    if ($ok) {
        $saved++;
    }
}

$fees = AssociateHelper::getServiceFees($conn, $targetId, false);
AssociateHelper::json(200, 'success', [
    'message' => "Saved $saved service fee(s)",
    'services' => $fees,
]);
