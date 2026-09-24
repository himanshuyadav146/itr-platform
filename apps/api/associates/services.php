<?php
require_once __DIR__ . '/_bootstrap.php';

AssociateHelper::requireMethod(['GET']);

$sql = "SELECT id, name, description, isActive FROM services WHERE isActive = 1 ORDER BY id ASC";
$result = $conn->query($sql);
$services = [];
if ($result) {
    while ($row = $result->fetch_assoc()) {
        $services[] = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'description' => $row['description'] ?? '',
            'isActive' => (int)$row['isActive'] === 1,
        ];
    }
}

AssociateHelper::jsonResponse(200, 'success', ['services' => $services]);
