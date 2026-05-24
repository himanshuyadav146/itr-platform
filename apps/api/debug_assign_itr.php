<?php
/**
 * Debug Script for ITR Assignment
 * Checks all conditions required for ITR assignment
 * 
 * Usage: http://localhost/api/debug_assign_itr.php?userId=15&professionalId=13&itrId=3
 */

header("Content-Type: application/json");

require 'include/config.php';

if (!$conn) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database connection failed"
    ]);
    exit;
}

$userId = $_GET['userId'] ?? null;
$professionalId = $_GET['professionalId'] ?? null;
$itrId = $_GET['itrId'] ?? null;
$personalDetailId = $_GET['personalDetailId'] ?? null;

$checks = [];

// Check 1: User exists
if ($userId) {
    $userIdEscaped = mysqli_real_escape_string($conn, $userId);
    $userSql = "SELECT UserId, FirstName, LastName, Email, Role FROM users WHERE UserId = '$userIdEscaped'";
    $userResult = $conn->query($userSql);
    
    if ($userResult && $userResult->num_rows > 0) {
        $user = $userResult->fetch_assoc();
        $checks['user'] = [
            "exists" => true,
            "data" => $user
        ];
    } else {
        $checks['user'] = [
            "exists" => false,
            "error" => "User not found with UserId=$userId"
        ];
    }
}

// Check 2: Professional exists and has correct role
if ($professionalId) {
    $profIdEscaped = mysqli_real_escape_string($conn, $professionalId);
    $profSql = "SELECT UserId, FirstName, LastName, Email, Role FROM users WHERE UserId = '$profIdEscaped'";
    $profResult = $conn->query($profSql);
    
    if ($profResult && $profResult->num_rows > 0) {
        $prof = $profResult->fetch_assoc();
        $hasCorrectRole = in_array($prof['Role'], ['ACCOUNTANT', 'CA']);
        $checks['professional'] = [
            "exists" => true,
            "hasCorrectRole" => $hasCorrectRole,
            "data" => $prof,
            "message" => $hasCorrectRole ? "OK" : "Professional must have Role='ACCOUNTANT' or 'CA', current role is '{$prof['Role']}'"
        ];
    } else {
        $checks['professional'] = [
            "exists" => false,
            "error" => "Professional not found with UserId=$professionalId"
        ];
    }
}

// Check 3: Personal details exist
if ($userId) {
    $pdSql = "SELECT id, UserId, PANNumber, FirstName, LastName, FinancialYear FROM personal_details WHERE UserId = '$userIdEscaped' AND isActive = 1";
    $pdResult = $conn->query($pdSql);
    
    if ($pdResult && $pdResult->num_rows > 0) {
        $personalDetails = [];
        while ($row = $pdResult->fetch_assoc()) {
            $personalDetails[] = $row;
        }
        $checks['personalDetails'] = [
            "exists" => true,
            "count" => count($personalDetails),
            "data" => $personalDetails
        ];
    } else {
        $checks['personalDetails'] = [
            "exists" => false,
            "error" => "No personal details found for UserId=$userId"
        ];
    }
}

// Check 4: ITR detail exists
if ($itrId) {
    $itrIdEscaped = mysqli_real_escape_string($conn, $itrId);
    $itrSql = "SELECT id, userId, panNumber, financialYear, status FROM itr_detail WHERE id = '$itrIdEscaped'";
    $itrResult = $conn->query($itrSql);
    
    if ($itrResult && $itrResult->num_rows > 0) {
        $itr = $itrResult->fetch_assoc();
        $userMatches = ($itr['userId'] == $userId);
        $checks['itrDetail'] = [
            "exists" => true,
            "userMatches" => $userMatches,
            "data" => $itr,
            "message" => $userMatches ? "OK" : "ITR belongs to userId={$itr['userId']}, but you're trying to assign for userId=$userId"
        ];
    } else {
        $checks['itrDetail'] = [
            "exists" => false,
            "error" => "ITR detail not found with id=$itrId"
        ];
        
        // Try to find itr_detail by userId
        if ($userId) {
            $itrByUserSql = "SELECT id, userId, panNumber, financialYear, status FROM itr_detail WHERE userId = '$userIdEscaped'";
            $itrByUserResult = $conn->query($itrByUserSql);
            if ($itrByUserResult && $itrByUserResult->num_rows > 0) {
                $itrs = [];
                while ($row = $itrByUserResult->fetch_assoc()) {
                    $itrs[] = $row;
                }
                $checks['itrDetail']['alternativeItrs'] = $itrs;
                $checks['itrDetail']['message'] = "No ITR with id=$itrId, but found " . count($itrs) . " ITR(s) for this user. Use one of these itrIds instead.";
            }
        }
    }
}

// Check 5: Check if personalDetailId exists (if provided)
if ($personalDetailId) {
    $pdIdEscaped = mysqli_real_escape_string($conn, $personalDetailId);
    $pdByIdSql = "SELECT id, UserId, PANNumber, FirstName, LastName, FinancialYear FROM personal_details WHERE id = '$pdIdEscaped' AND isActive = 1";
    $pdByIdResult = $conn->query($pdByIdSql);
    
    if ($pdByIdResult && $pdByIdResult->num_rows > 0) {
        $pd = $pdByIdResult->fetch_assoc();
        $checks['personalDetailById'] = [
            "exists" => true,
            "data" => $pd
        ];
    } else {
        $checks['personalDetailById'] = [
            "exists" => false,
            "error" => "Personal detail not found with id=$personalDetailId"
        ];
    }
}

// Check 6: Check for existing assignments
if ($itrId) {
    $existingAssignSql = "SELECT id, professional_id, status, assignment_date FROM itr_assignments WHERE itr_id = '$itrIdEscaped' AND status IN ('assigned', 'in_progress')";
    $existingAssignResult = $conn->query($existingAssignSql);
    
    if ($existingAssignResult && $existingAssignResult->num_rows > 0) {
        $assignments = [];
        while ($row = $existingAssignResult->fetch_assoc()) {
            $assignments[] = $row;
        }
        $checks['existingAssignments'] = [
            "hasActive" => true,
            "count" => count($assignments),
            "data" => $assignments,
            "message" => "ITR already has active assignment(s). Cannot assign again."
        ];
    } else {
        $checks['existingAssignments'] = [
            "hasActive" => false,
            "message" => "No active assignments found. OK to assign."
        ];
    }
}

// Summary
$canAssign = true;
$errors = [];

if (isset($checks['user']) && !$checks['user']['exists']) {
    $canAssign = false;
    $errors[] = $checks['user']['error'];
}

if (isset($checks['professional']) && (!$checks['professional']['exists'] || !$checks['professional']['hasCorrectRole'])) {
    $canAssign = false;
    $errors[] = $checks['professional']['message'] ?? $checks['professional']['error'];
}

if (isset($checks['personalDetails']) && !$checks['personalDetails']['exists']) {
    $canAssign = false;
    $errors[] = $checks['personalDetails']['error'];
}

if (isset($checks['itrDetail']) && !$checks['itrDetail']['exists']) {
    $canAssign = false;
    $errors[] = $checks['itrDetail']['error'];
} elseif (isset($checks['itrDetail']) && !$checks['itrDetail']['userMatches']) {
    $canAssign = false;
    $errors[] = $checks['itrDetail']['message'];
}

if (isset($checks['existingAssignments']) && $checks['existingAssignments']['hasActive']) {
    $canAssign = false;
    $errors[] = $checks['existingAssignments']['message'];
}

http_response_code(200);
echo json_encode([
    "status" => "success",
    "canAssign" => $canAssign,
    "errors" => $errors,
    "checks" => $checks,
    "recommendation" => $canAssign ? "All checks passed. You can proceed with assignment." : "Fix the errors listed above before assigning."
], JSON_PRETTY_PRINT);

exit;
?>
