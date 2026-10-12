<?php
// Error reporting (disabled for production, enable for debugging)
// error_reporting(E_ALL);
// ini_set('display_errors', 1);
ini_set('log_errors', 1);

// Allow cross-origin requests
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

// Check if required files exist
if (!file_exists('../include/config.php')) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Config file not found"]
    ]);
    exit;
}

if (!file_exists('../phpjwt/Token.php')) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => ["message" => "Token.php file not found"]
    ]);
    exit;
}

// Try-catch for fatal errors
try {
    require '../include/config.php';
    require '../phpjwt/Token.php';
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => [
            "message" => "Error loading required files: " . $e->getMessage(),
            "file" => $e->getFile(),
            "line" => $e->getLine()
        ]
    ]);
    exit;
} catch (Error $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => [
            "message" => "PHP Error: " . $e->getMessage(),
            "file" => $e->getFile(),
            "line" => $e->getLine()
        ]
    ]);
    exit;
}

// Only POST allowed
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" =>[
            "message" => "Only POST requests are allowed",
        ]
    ]);
    exit;
}

// Read JSON input
$input = file_get_contents("php://input");
$data = json_decode($input, true);

// Extract Bearer token
$headers = getallheaders();
$token = "";

if (isset($headers['Authorization'])) {
    $token = str_replace("Bearer ", "", trim($headers['Authorization']));
}

if (empty($token)) {
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" =>[
            "message" => "Authorization token is required",
        ]
    ]);
    exit;
}

// Verify token
$decoded = Token::Verify($token, $key);
if ($decoded === false) {
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" =>[
            "message" => "Invalid or expired token",
        ]
    ]);
    exit;
}

// USER ID from token
$UserId = $decoded['UserId'] ?? null;

// Validate UserId
if (!$UserId) {
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" =>[
            "message" => "User ID not found in token",
        ]
    ]);
    exit;
}

// Ensure UserId is integer
$UserId = (int)$UserId;

// Required fields
$panNumber = strtoupper(trim($data['panNumber'] ?? ''));
$firstName = trim($data['firstName'] ?? '');
$lastName = trim($data['lastName'] ?? '');
$email = trim($data['email'] ?? '');

if (!$panNumber || !$firstName || !$lastName || !$email) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" =>[
            "message" => "PAN, FirstName, LastName and Email are required",
        ]
    ]);
    exit;
}

// Optional fields
$middleName = trim($data['middleName'] ?? '');
$mobileNumber = trim($data['mobileNumber'] ?? '');
// Handle both spellings: aadharCardNumber and aadhaarCardNumber
$aadharCardNumber = trim($data['aadharCardNumber'] ?? $data['aadhaarCardNumber'] ?? '');
$gender = trim($data['gender'] ?? '');
$financialYear = trim($data['financialYear'] ?? '');
$address = trim($data['address'] ?? '');
$country = trim($data['country'] ?? 'India');
$dateOfBirth = trim($data['DATEOFBIRTH'] ?? $data['dateOfBirth'] ?? '');
// Package ID from frontend
$packageId = isset($data['packageId']) ? (int)$data['packageId'] : null;
// Journey Type - determines which service flow the user is in
$journeyType = trim($data['journeyType'] ?? '');

// Validate journeyType
$validJourneyTypes = ['ITR', 'E-Verify', 'GST', 'Loan'];
if (!empty($journeyType) && !in_array($journeyType, $validJourneyTypes)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "statusCode" => 400,
        "data" => [
            "message" => "Invalid journeyType. Must be one of: ITR, E-Verify, GST, Loan"
        ]
    ]);
    exit;
}

// Convert empty date to NULL for database
if (empty($dateOfBirth)) {
    $dateOfBirth = NULL;
}

// Escape variables
$panNumber = mysqli_real_escape_string($conn, $panNumber);
$firstName = mysqli_real_escape_string($conn, $firstName);
$middleName = mysqli_real_escape_string($conn, $middleName);
$lastName = mysqli_real_escape_string($conn, $lastName);
$email = mysqli_real_escape_string($conn, $email);
$mobileNumber = mysqli_real_escape_string($conn, $mobileNumber);
$aadharCardNumber = mysqli_real_escape_string($conn, $aadharCardNumber);
$gender = mysqli_real_escape_string($conn, $gender);
// Don't escape NULL values
$dateOfBirthSql = ($dateOfBirth === NULL) ? 'NULL' : "'" . mysqli_real_escape_string($conn, $dateOfBirth) . "'";
$financialYear = mysqli_real_escape_string($conn, $financialYear);
$address = mysqli_real_escape_string($conn, $address);
$country = mysqli_real_escape_string($conn, $country);
$packageIdSql = ($packageId === null) ? 'NULL' : (int)$packageId;
$journeyType = mysqli_real_escape_string($conn, $journeyType);

// Check if connection is valid
if (!$conn) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => [
            "message" => "Database connection not available"
        ]
    ]);
    exit;
}

// Check record for same user + same PAN
$checkSql = "SELECT id FROM personal_details WHERE UserId = '$UserId' AND PANNumber = '$panNumber'";
$checkResult = $conn->query($checkSql);

// Handle query errors
if ($checkResult === false) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" => [
            "message" => "Database query error: " . $conn->error,
            "sql" => $checkSql
        ]
    ]);
    exit;
}

// ------------------------------
// HANDLE USER JOURNEY
// ------------------------------
$journeyId = null;

if (!empty($journeyType)) {
    // Check if journey already exists for this user and journey type
    $journeyCheckSql = "SELECT id, status FROM user_journey 
                        WHERE userId = '$UserId' 
                        AND journeyType = '$journeyType' 
                        AND panNumber = '$panNumber'
                        ORDER BY id DESC 
                        LIMIT 1";
    $journeyResult = $conn->query($journeyCheckSql);
    
    if ($journeyResult && $journeyResult->num_rows > 0) {
        // Journey exists - update it
        $journeyRow = $journeyResult->fetch_assoc();
        $journeyId = $journeyRow['id'];
        
        // Update journey status and current step
        $updateJourneySql = "UPDATE user_journey 
                            SET status = 'in_progress',
                                currentStep = 'personal_details',
                                updatedAt = NOW()
                            WHERE id = '$journeyId'";
        $conn->query($updateJourneySql);
    } else {
        // Create new journey
        $createJourneySql = "INSERT INTO user_journey 
                            (userId, panNumber, journeyType, status, currentStep, startedAt, updatedAt)
                            VALUES 
                            ('$UserId', '$panNumber', '$journeyType', 'in_progress', 'personal_details', NOW(), NOW())";
        
        if ($conn->query($createJourneySql)) {
            $journeyId = $conn->insert_id;
        }
    }
}

$journeyIdSql = ($journeyId === null) ? 'NULL' : (int)$journeyId;

// ------------------------------
// UPDATE CASE
// ------------------------------
if ($checkResult->num_rows > 0) {

    $sql = "UPDATE personal_details SET
            FirstName='$firstName',
            MiddleName='$middleName',
            LastName='$lastName',
            EMAIL='$email',
            MobileNumber='$mobileNumber',
            aadharCardNumber='$aadharCardNumber',
            Gender='$gender',
            DATEOFBIRTH=$dateOfBirthSql,
            FinancialYear='$financialYear',
            package_id=$packageIdSql,
            journeyId=$journeyIdSql,
            Address='$address',
            Country='$country',
            UpdatedAt = NOW()
            WHERE UserId='$UserId' AND PANNumber='$panNumber'";

    if ($conn->query($sql) === TRUE) {
        // Also update or create itr_detail entry
        $itrDetailCheckSql = "SELECT id FROM itr_detail WHERE userId = '$UserId' AND panNumber = '$panNumber' LIMIT 1";
        $itrDetailCheckResult = $conn->query($itrDetailCheckSql);
        
        if ($itrDetailCheckResult && $itrDetailCheckResult->num_rows > 0) {
            // Update existing itr_detail
            $itrDetailUpdateSql = "UPDATE itr_detail SET 
                                    financialYear = '$financialYear',
                                    updatedAt = NOW()
                                    WHERE userId = '$UserId' AND panNumber = '$panNumber'";
            $conn->query($itrDetailUpdateSql);
        } else {
            // Create new itr_detail
            $itrDetailInsertSql = "INSERT INTO itr_detail (userId, panNumber, financialYear, status, createdAt, updatedAt)
                                   VALUES ('$UserId', '$panNumber', '$financialYear', 'pending', NOW(), NOW())";
            $conn->query($itrDetailInsertSql);
        }
        
        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" =>[
                "message" => "Personal details updated successfully",
                "panNumber" => $panNumber,
                "journeyId" => $journeyId,
                "journeyType" => !empty($journeyType) ? $journeyType : null,
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" =>[
                "message" => "Error updating details: " . $conn->error,
            ]
        ]);
    }
    exit;
}

// ------------------------------
// INSERT CASE
// ------------------------------
$sql = "INSERT INTO personal_details 
        (UserId, PANNumber, FirstName, MiddleName, LastName, EMAIL, MobileNumber, aadharCardNumber, 
        Gender, DATEOFBIRTH, FinancialYear, package_id, journeyId, Address, Country, isActive, CreatedAt)
        VALUES 
        ('$UserId', '$panNumber', '$firstName', '$middleName', '$lastName', '$email', '$mobileNumber', 
        '$aadharCardNumber', '$gender', $dateOfBirthSql, '$financialYear', $packageIdSql, $journeyIdSql, '$address', '$country', 1, NOW())";

if ($conn->query($sql) === TRUE) {
    // Also create itr_detail entry for this user and PAN
    $itrDetailCheckSql = "SELECT id FROM itr_detail WHERE userId = '$UserId' AND panNumber = '$panNumber' LIMIT 1";
    $itrDetailCheckResult = $conn->query($itrDetailCheckSql);
    
    if (!$itrDetailCheckResult || $itrDetailCheckResult->num_rows === 0) {
        // Create new itr_detail entry
        $itrDetailInsertSql = "INSERT INTO itr_detail (userId, panNumber, financialYear, status, createdAt, updatedAt)
                               VALUES ('$UserId', '$panNumber', '$financialYear', 'pending', NOW(), NOW())";
        $conn->query($itrDetailInsertSql);
    }
    
    http_response_code(201);
    echo json_encode([
        "status" => "success",
        "statusCode" => 201,
        "data" =>[
            "message" => "Personal details added successfully",
            "panNumber" => $panNumber,
            "journeyId" => $journeyId,
            "journeyType" => !empty($journeyType) ? $journeyType : null,
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "statusCode" => 500,
        "data" =>[
            "message" => "Error inserting details: " . $conn->error,
        ]
    ]);
}
?>
