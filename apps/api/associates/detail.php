<?php
require_once __DIR__ . '/../include/config.php';
require_once __DIR__ . '/../include/AssociateHelper.php';

AssociateHelper::sendCors('GET, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    AssociateHelper::json(405, 'error', ['message' => 'Only GET allowed']);
}

$id = isset($_GET['id']) ? (int)$_GET['id'] : (isset($_GET['associateId']) ? (int)$_GET['associateId'] : 0);
if ($id <= 0) {
    AssociateHelper::json(400, 'error', ['message' => 'id is required']);
}

$row = AssociateHelper::getProfileRow($conn, $id);
if (!$row || strtolower($row['approval_status']) !== AssociateHelper::APPROVED) {
    AssociateHelper::json(404, 'error', ['message' => 'Associate not found or not yet listed']);
}

$fees = AssociateHelper::getServiceFees($conn, $id, true);
AssociateHelper::json(200, 'success', [
    'associate' => AssociateHelper::publicAssociate($row, $fees),
]);
