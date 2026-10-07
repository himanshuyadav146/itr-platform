<?php
/**
 * Platform services catalog for the associate marketplace.
 * GET  /admin/services.php
 * POST /admin/services.php  { name, description? }
 * PUT  /admin/services.php  { id, name?, description?, is_active? }
 */
require_once __DIR__ . '/../include/config.php';
require_once __DIR__ . '/../phpjwt/Token.php';
require_once __DIR__ . '/../include/AssociateHelper.php';

AssociateHelper::sendCors('GET, POST, PUT, OPTIONS');

$decoded = AssociateHelper::requireAuth($key);
AssociateHelper::requireAdmin($conn, $decoded);

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    AssociateHelper::json(200, 'success', [
        'services' => AssociateHelper::listServices($conn, false),
    ]);
}

$data = AssociateHelper::readJson();

if ($method === 'POST') {
    $name = trim($data['name'] ?? $data['Name'] ?? '');
    if ($name === '') {
        AssociateHelper::json(400, 'error', ['message' => 'name is required']);
    }
    $nameEsc = mysqli_real_escape_string($conn, $name);
    $dup = $conn->query("SELECT id FROM services WHERE Name = '$nameEsc' LIMIT 1");
    if ($dup && $dup->num_rows > 0) {
        AssociateHelper::json(409, 'error', ['message' => 'Service already exists']);
    }
    $description = mysqli_real_escape_string($conn, trim($data['description'] ?? ''));
    $hasDesc = AssociateHelper::columnExists($conn, 'services', 'description');
    $hasActive = AssociateHelper::columnExists($conn, 'services', 'is_active');
    $cols = 'Name';
    $vals = "'$nameEsc'";
    if ($hasDesc) {
        $cols .= ', description';
        $vals .= ", '$description'";
    }
    if ($hasActive) {
        $cols .= ', is_active';
        $vals .= ', 1';
    }
    $cols .= ', CreatedAt';
    $vals .= ', NOW()';
    if (!$conn->query("INSERT INTO services ($cols) VALUES ($vals)")) {
        AssociateHelper::json(500, 'error', ['message' => 'Failed to add service: ' . $conn->error]);
    }
    AssociateHelper::json(201, 'success', [
        'message' => 'Service added',
        'service' => [
            'id' => (int)$conn->insert_id,
            'name' => $name,
            'description' => $data['description'] ?? '',
            'is_active' => true,
        ],
    ]);
}

if ($method === 'PUT') {
    $id = (int)($data['id'] ?? 0);
    if ($id <= 0) {
        AssociateHelper::json(400, 'error', ['message' => 'id is required']);
    }
    $sets = [];
    if (isset($data['name']) || isset($data['Name'])) {
        $nameEsc = mysqli_real_escape_string($conn, trim($data['name'] ?? $data['Name']));
        $sets[] = "Name = '$nameEsc'";
    }
    if ((isset($data['description']) || isset($data['description'])) && AssociateHelper::columnExists($conn, 'services', 'description')) {
        $descEsc = mysqli_real_escape_string($conn, trim($data['description'] ?? ''));
        $sets[] = "description = '$descEsc'";
    }
    if (isset($data['is_active']) && AssociateHelper::columnExists($conn, 'services', 'is_active')) {
        $active = $data['is_active'] ? 1 : 0;
        $sets[] = "is_active = $active";
    }
    if (empty($sets)) {
        AssociateHelper::json(400, 'error', ['message' => 'No fields to update']);
    }
    if (!$conn->query('UPDATE services SET ' . implode(', ', $sets) . " WHERE id = $id")) {
        AssociateHelper::json(500, 'error', ['message' => 'Failed to update service: ' . $conn->error]);
    }
    AssociateHelper::json(200, 'success', ['message' => 'Service updated']);
}

AssociateHelper::json(405, 'error', ['message' => 'Method not allowed']);
