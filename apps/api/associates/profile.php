<?php
require_once __DIR__ . '/_bootstrap.php';

$method = AssociateHelper::requireMethod(['GET', 'PUT', 'POST']);
$auth = AssociateHelper::requireUser($key);
$userId = $auth['userId'];

$user = AssociateHelper::fetchUserRole($conn, $userId);
if (!$user || !AssociateHelper::isAssociateRole($user['Role'] ?? $auth['role'])) {
    AssociateHelper::jsonResponse(403, 'error', ['message' => 'Only associates can manage this profile']);
}

AssociateHelper::ensureProfile($conn, $userId);

if ($method === 'GET') {
    $sql = "SELECT
                u.UserId, u.FirstName, u.LastName, u.Role, u.Email, u.Mobile,
                ap.bio, ap.years_experience, ap.qualification, ap.license_number,
                ap.city, ap.languages, ap.photo_url, ap.verification_status, ap.is_listed, ap.rejection_reason
            FROM users u
            INNER JOIN associate_profiles ap ON ap.user_id = u.UserId
            WHERE u.UserId = $userId
            LIMIT 1";
    $result = $conn->query($sql);
    if (!$result || $result->num_rows === 0) {
        AssociateHelper::jsonResponse(404, 'error', ['message' => 'Profile not found']);
    }
    $row = $result->fetch_assoc();
    $fees = AssociateHelper::getFees($conn, $userId, false);
    AssociateHelper::jsonResponse(200, 'success', [
        'profile' => AssociateHelper::formatProfile($row, $fees),
    ]);
}

$data = AssociateHelper::readJsonBody();
$bio = mysqli_real_escape_string($conn, trim((string)($data['bio'] ?? '')));
$years = isset($data['yearsExperience']) ? (int)$data['yearsExperience'] : (isset($data['years_experience']) ? (int)$data['years_experience'] : 0);
if ($years < 0) {
    $years = 0;
}
$qualification = mysqli_real_escape_string($conn, trim((string)($data['qualification'] ?? '')));
$license = mysqli_real_escape_string($conn, trim((string)($data['licenseNumber'] ?? $data['license_number'] ?? '')));
$city = mysqli_real_escape_string($conn, trim((string)($data['city'] ?? '')));
$photo = mysqli_real_escape_string($conn, trim((string)($data['photoUrl'] ?? $data['photo_url'] ?? '')));

$languagesRaw = $data['languages'] ?? '';
if (is_array($languagesRaw)) {
    $languagesRaw = implode(',', array_map('trim', $languagesRaw));
}
$languages = mysqli_real_escape_string($conn, trim((string)$languagesRaw));

$sql = "UPDATE associate_profiles
        SET bio = '$bio',
            years_experience = $years,
            qualification = '$qualification',
            license_number = '$license',
            city = '$city',
            languages = '$languages',
            photo_url = '$photo',
            updated_at = NOW()
        WHERE user_id = $userId";

if (!$conn->query($sql)) {
    AssociateHelper::jsonResponse(500, 'error', ['message' => 'Failed to update profile']);
}

$reload = $conn->query("SELECT u.UserId, u.FirstName, u.LastName, u.Role, u.Email, u.Mobile,
                               ap.bio, ap.years_experience, ap.qualification, ap.license_number,
                               ap.city, ap.languages, ap.photo_url, ap.verification_status, ap.is_listed, ap.rejection_reason
                        FROM users u
                        INNER JOIN associate_profiles ap ON ap.user_id = u.UserId
                        WHERE u.UserId = $userId LIMIT 1");
$row = $reload->fetch_assoc();
AssociateHelper::jsonResponse(200, 'success', [
    'message' => 'Profile updated',
    'profile' => AssociateHelper::formatProfile($row, AssociateHelper::getFees($conn, $userId, false)),
]);
