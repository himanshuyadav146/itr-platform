<?php
require_once __DIR__ . '/../include/config.php';
require_once __DIR__ . '/../include/AssociateHelper.php';

AssociateHelper::sendCors('POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    AssociateHelper::json(405, 'error', ['message' => 'Only POST allowed']);
}

$data = AssociateHelper::readJson();
$email = trim($data['email'] ?? '');
$password = $data['password'] ?? '';
$mobileInput = $data['mobile'] ?? ($data['phone'] ?? '');
$roleRaw = strtoupper(trim($data['role'] ?? ($data['occupation'] ?? 'CA')));

if ($email === '' || $password === '') {
    AssociateHelper::json(400, 'error', ['message' => 'email and password are required']);
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    AssociateHelper::json(400, 'error', ['message' => 'Invalid email']);
}
if (!AssociateHelper::isAssociateRole($roleRaw)) {
    AssociateHelper::json(400, 'error', ['message' => 'role must be CA, ACCOUNTANT, or TAX_EXPERT']);
}

$emailEsc = mysqli_real_escape_string($conn, $email);
$dup = $conn->query("SELECT UserId FROM users WHERE LOWER(TRIM(Email)) = LOWER(TRIM('$emailEsc')) LIMIT 1");
if ($dup && $dup->num_rows > 0) {
    AssociateHelper::json(409, 'error', ['message' => 'Email already exists']);
}

$firstName = '';
$middleName = '';
$lastName = '';
if (!empty($data['name'])) {
    $parts = preg_split('/\s+/', trim($data['name']));
    $firstName = $parts[0];
    if (count($parts) >= 3) {
        $middleName = $parts[1];
        $lastName = implode(' ', array_slice($parts, 2));
    } elseif (count($parts) === 2) {
        $lastName = $parts[1];
    }
} else {
    $firstName = $data['firstName'] ?? '';
    $middleName = $data['middleName'] ?? '';
    $lastName = $data['lastName'] ?? '';
}

$firstName = mysqli_real_escape_string($conn, $firstName);
$middleName = mysqli_real_escape_string($conn, $middleName);
$lastName = mysqli_real_escape_string($conn, $lastName);
$mobile = mysqli_real_escape_string($conn, $mobileInput);
$passwordEsc = mysqli_real_escape_string($conn, $password);
$platform = mysqli_real_escape_string($conn, $data['platform'] ?? 'web');
$version = mysqli_real_escape_string($conn, $data['version'] ?? '1.0');
$role = mysqli_real_escape_string($conn, $roleRaw);
$now = date('Y-m-d H:i:s');

$sql = "INSERT INTO users (FirstName, MiddleName, LastName, Email, Mobile, Password, role, CreatedAt, Platform, Version)
        VALUES ('$firstName', '$middleName', '$lastName', '$emailEsc', '$mobile', '$passwordEsc', '$role', '$now', '$platform', '$version')";

if (!$conn->query($sql)) {
    AssociateHelper::json(500, 'error', ['message' => 'Error registering associate: ' . $conn->error]);
}

$userId = (int)$conn->insert_id;
AssociateHelper::ensureProfile($conn, $userId, $roleRaw);

$icai = mysqli_real_escape_string($conn, trim($data['icai_membership_no'] ?? $data['icaiMembershipNo'] ?? ''));
$gstin = mysqli_real_escape_string($conn, trim($data['gstin'] ?? ''));
$pan = mysqli_real_escape_string($conn, strtoupper(trim($data['pan'] ?? '')));
$city = mysqli_real_escape_string($conn, trim($data['city'] ?? ''));
$state = mysqli_real_escape_string($conn, trim($data['state'] ?? ''));
$bio = mysqli_real_escape_string($conn, trim($data['bio'] ?? ''));
$years = (int)($data['years_experience'] ?? $data['yearsExperience'] ?? 0);

if (AssociateHelper::tableExists($conn, 'associate_profiles')) {
    $conn->query("UPDATE associate_profiles SET
                    icai_membership_no = '$icai',
                    gstin = '$gstin',
                    pan = '$pan',
                    city = '$city',
                    state = '$state',
                    bio = '$bio',
                    years_experience = $years,
                    approval_status = 'pending',
                    updated_at = NOW()
                  WHERE user_id = $userId");
}

AssociateHelper::json(201, 'success', [
    'message' => 'Registration received. You can sign in to complete credentials. Listing stays hidden until an admin approves your profile.',
    'user_id' => $userId,
    'role' => $roleRaw,
    'approval_status' => 'pending',
]);
