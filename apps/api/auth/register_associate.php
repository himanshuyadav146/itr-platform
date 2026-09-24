<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'status' => 'error',
        'statusCode' => 405,
        'data' => ['message' => 'Only POST requests are allowed'],
    ]);
    exit;
}

$input = file_get_contents('php://input');
$data = json_decode($input, true);
if (!is_array($data)) {
    http_response_code(400);
    echo json_encode([
        'status' => 'error',
        'statusCode' => 400,
        'data' => ['message' => 'Invalid JSON'],
    ]);
    exit;
}

$roleRaw = $data['role'] ?? ($data['Role'] ?? ($data['occupation'] ?? ''));
$role = strtoupper(trim((string)$roleRaw));
$allowed = ['CA', 'ACCOUNTANT', 'TAX_EXPERT'];
if (!in_array($role, $allowed, true)) {
    http_response_code(400);
    echo json_encode([
        'status' => 'error',
        'statusCode' => 400,
        'data' => ['message' => 'Role must be CA, ACCOUNTANT, or TAX_EXPERT'],
    ]);
    exit;
}

$data['role'] = $role;
$GLOBALS['signup_preparsed_data'] = $data;
require __DIR__ . '/signup.php';
