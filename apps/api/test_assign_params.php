<?php
/**
 * Test Specific Assignment Parameters
 * Tests the exact parameters from your curl command
 * 
 * Usage: http://localhost/api/test_assign_params.php
 */

header("Content-Type: application/json");

require 'include/config.php';

if (!$conn) {
    die(json_encode(["error" => "Database connection failed"]));
}

// Your exact parameters from curl
$itrId = 3;
$professionalId = 13;
$userId = 15;

echo "Testing parameters:\n";
echo "- itrId: $itrId\n";
echo "- professionalId: $professionalId\n";
echo "- userId: $userId\n\n";

// Test 1: Check professional
echo "=== TEST 1: Professional Check ===\n";
$profSql = "SELECT UserId, FirstName, LastName, Email, Role FROM users WHERE UserId = '$professionalId'";
$profResult = $conn->query($profSql);

if ($profResult && $profResult->num_rows > 0) {
    $prof = $profResult->fetch_assoc();
    echo "Professional found: {$prof['FirstName']} {$prof['LastName']}\n";
    echo "Role: {$prof['Role']}\n";
    
    if ($prof['Role'] === 'ACCOUNTANT' || $prof['Role'] === 'CA') {
        echo "✅ Role is correct\n\n";
    } else {
        echo "❌ ERROR: Role must be 'ACCOUNTANT' or 'CA', but found '{$prof['Role']}'\n";
        echo "FIX: Update user role with:\n";
        echo "UPDATE users SET Role = 'ACCOUNTANT' WHERE UserId = $professionalId;\n\n";
    }
} else {
    echo "❌ ERROR: Professional with UserId=$professionalId not found\n\n";
}

// Test 2: Check user
echo "=== TEST 2: User Check ===\n";
$userSql = "SELECT UserId, FirstName, LastName, Email FROM users WHERE UserId = '$userId'";
$userResult = $conn->query($userSql);

if ($userResult && $userResult->num_rows > 0) {
    $user = $userResult->fetch_assoc();
    echo "✅ User found: {$user['FirstName']} {$user['LastName']}\n\n";
} else {
    echo "❌ ERROR: User with UserId=$userId not found\n\n";
}

// Test 3: Check ITR detail
echo "=== TEST 3: ITR Detail Check ===\n";
$itrSql = "SELECT id, userId, panNumber, financialYear, status FROM itr_detail WHERE id = '$itrId'";
$itrResult = $conn->query($itrSql);

if ($itrResult && $itrResult->num_rows > 0) {
    $itr = $itrResult->fetch_assoc();
    echo "✅ ITR found:\n";
    echo "  - itrId: {$itr['id']}\n";
    echo "  - userId: {$itr['userId']}\n";
    echo "  - panNumber: {$itr['panNumber']}\n";
    echo "  - financialYear: {$itr['financialYear']}\n";
    echo "  - status: {$itr['status']}\n";
    
    if ($itr['userId'] == $userId) {
        echo "✅ userId matches\n\n";
    } else {
        echo "❌ ERROR: ITR belongs to userId={$itr['userId']}, but you're trying to assign for userId=$userId\n\n";
    }
} else {
    echo "❌ ERROR: ITR with id=$itrId not found in itr_detail table\n";
    
    // Check if any ITRs exist for this user
    $userItrSql = "SELECT id, panNumber, financialYear FROM itr_detail WHERE userId = '$userId'";
    $userItrResult = $conn->query($userItrSql);
    
    if ($userItrResult && $userItrResult->num_rows > 0) {
        echo "But found these ITRs for userId=$userId:\n";
        while ($row = $userItrResult->fetch_assoc()) {
            echo "  - itrId={$row['id']}, PAN={$row['panNumber']}, Year={$row['financialYear']}\n";
        }
        echo "\nFIX: Use one of these itrIds instead\n\n";
    } else {
        echo "No ITRs found for userId=$userId\n";
        echo "FIX: Run migration script:\n";
        echo "http://localhost/api/migrate_itr_details.php\n\n";
    }
}

// Test 4: Check personal details
echo "=== TEST 4: Personal Details Check ===\n";
$pdSql = "SELECT id, PANNumber, FirstName, LastName, FinancialYear FROM personal_details WHERE UserId = '$userId' AND isActive = 1";
$pdResult = $conn->query($pdSql);

if ($pdResult && $pdResult->num_rows > 0) {
    echo "✅ Personal details found for userId=$userId:\n";
    while ($row = $pdResult->fetch_assoc()) {
        echo "  - personalDetailId={$row['id']}, PAN={$row['PANNumber']}, Name={$row['FirstName']} {$row['LastName']}\n";
    }
    echo "\n";
} else {
    echo "❌ No personal details found for userId=$userId\n\n";
}

// Test 5: Check existing assignments
echo "=== TEST 5: Existing Assignments Check ===\n";
$assignSql = "SELECT id, professional_id, status, assignment_date, notes FROM itr_assignments WHERE itr_id = '$itrId' AND status IN ('assigned', 'in_progress')";
$assignResult = $conn->query($assignSql);

if ($assignResult && $assignResult->num_rows > 0) {
    echo "❌ ERROR: ITR already has active assignment(s):\n";
    while ($row = $assignResult->fetch_assoc()) {
        echo "  - assignmentId={$row['id']}, professionalId={$row['professional_id']}, status={$row['status']}\n";
    }
    echo "\nFIX: Complete or cancel existing assignment first\n\n";
} else {
    echo "✅ No active assignments found\n\n";
}

// Summary
echo "=== SUMMARY ===\n";
echo "Check the results above to see what's wrong.\n";
echo "Common fixes:\n";
echo "1. If professional role is wrong: UPDATE users SET Role = 'ACCOUNTANT' WHERE UserId = $professionalId;\n";
echo "2. If ITR not found: Run http://localhost/api/migrate_itr_details.php\n";
echo "3. If ITR already assigned: Cancel existing assignment first\n";

?>
