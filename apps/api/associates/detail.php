<?php
require_once __DIR__ . '/_bootstrap.php';

AssociateHelper::requireMethod(['GET']);

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($id <= 0) {
    AssociateHelper::jsonResponse(400, 'error', ['message' => 'id is required']);
}

$sql = "SELECT
            u.UserId, u.FirstName, u.LastName, u.Role,
            ap.bio, ap.years_experience, ap.qualification, ap.license_number,
            ap.city, ap.languages, ap.photo_url, ap.verification_status, ap.is_listed
        FROM users u
        INNER JOIN associate_profiles ap ON ap.user_id = u.UserId
        WHERE u.UserId = $id
          AND ap.verification_status = 'approved'
          AND ap.is_listed = 1
        LIMIT 1";
$result = $conn->query($sql);
if (!$result || $result->num_rows === 0) {
    AssociateHelper::jsonResponse(404, 'error', ['message' => 'Associate not found']);
}

$row = $result->fetch_assoc();
$fees = AssociateHelper::getFees($conn, $id, true);
$profile = AssociateHelper::formatProfile($row, $fees);
unset($profile['email'], $profile['mobile'], $profile['rejectionReason']);

AssociateHelper::jsonResponse(200, 'success', ['associate' => $profile]);
