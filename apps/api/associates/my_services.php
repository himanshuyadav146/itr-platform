<?php
require_once __DIR__ . '/_bootstrap.php';

$method = AssociateHelper::requireMethod(['GET', 'PUT', 'POST']);
$auth = AssociateHelper::requireUser($key);
$userId = $auth['userId'];

$user = AssociateHelper::fetchUserRole($conn, $userId);
if (!$user || !AssociateHelper::isAssociateRole($user['Role'] ?? $auth['role'])) {
    AssociateHelper::jsonResponse(403, 'error', ['message' => 'Only associates can manage services']);
}

AssociateHelper::ensureProfile($conn, $userId);

if ($method === 'GET') {
    $catalog = [];
    $svcResult = $conn->query("SELECT id, name, description, isActive FROM services WHERE isActive = 1 ORDER BY id ASC");
    if ($svcResult) {
        while ($row = $svcResult->fetch_assoc()) {
            $catalog[] = [
                'id' => (int)$row['id'],
                'name' => $row['name'],
                'description' => $row['description'] ?? '',
            ];
        }
    }
    AssociateHelper::jsonResponse(200, 'success', [
        'services' => AssociateHelper::getFees($conn, $userId, false),
        'catalog' => $catalog,
    ]);
}

$data = AssociateHelper::readJsonBody();
$items = $data['services'] ?? null;
if (!is_array($items)) {
    AssociateHelper::jsonResponse(400, 'error', ['message' => 'services array is required']);
}

$conn->begin_transaction();
try {
    foreach ($items as $item) {
        $serviceId = (int)($item['serviceId'] ?? $item['service_id'] ?? 0);
        $fee = floatval($item['fee'] ?? 0);
        $isActive = 0;
        if (array_key_exists('isActive', $item)) {
            $isActive = $item['isActive'] ? 1 : 0;
        } elseif (array_key_exists('is_active', $item)) {
            $isActive = $item['is_active'] ? 1 : 0;
        } else {
            $isActive = 1;
        }

        if ($serviceId <= 0) {
            continue;
        }
        if ($fee < 0) {
            throw new Exception('Fee cannot be negative');
        }

        $svcCheck = $conn->query("SELECT id FROM services WHERE id = $serviceId AND isActive = 1 LIMIT 1");
        if (!$svcCheck || $svcCheck->num_rows === 0) {
            throw new Exception("Unknown service: $serviceId");
        }

        $sql = "INSERT INTO associate_service_fees (user_id, service_id, fee, is_active, created_at, updated_at)
                VALUES ($userId, $serviceId, $fee, $isActive, NOW(), NOW())
                ON DUPLICATE KEY UPDATE fee = $fee, is_active = $isActive, updated_at = NOW()";
        if (!$conn->query($sql)) {
            throw new Exception('Failed to save service fee');
        }
    }
    $conn->commit();
} catch (Exception $e) {
    $conn->rollback();
    AssociateHelper::jsonResponse(400, 'error', ['message' => $e->getMessage()]);
}

AssociateHelper::jsonResponse(200, 'success', [
    'message' => 'Services updated',
    'services' => AssociateHelper::getFees($conn, $userId, false),
]);
