<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

// Only POST allowed
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "statusCode" => 405,
    "data" =>[ "message" => "Only POST allowed"]]);
    http_response_code(405);
    exit;
}

$input = file_get_contents("php://input");
$data = json_decode($input, true);

// TOKEN CHECK
$headers = getallheaders();
$token = '';

if (isset($headers['Authorization'])) {
    $token = str_replace("Bearer ", "", trim($headers['Authorization']));
}

if (empty($token)) {
    echo json_encode(["status" => "error", "statusCode" => 401,
    "data" =>[ "message" =>"Authorization token required"]]);
    http_response_code(401);
    exit;
}

$decoded = Token::Verify($token, $key);

if ($decoded === false) {
    echo json_encode(["status" => "error","statusCode" => 401,
    "data" =>[ "message" =>"Invalid or expired token"]]);
    http_response_code(401);
    exit;
}

$UserId = $decoded['UserId'] ?? null;

if (!$UserId) {
    echo json_encode(["status" => "error", "statusCode" => 401,
    "data" =>[ "message" => "UserId missing in token"]]);
    http_response_code(401);
    exit;
}

// DATA VALIDATION
$PanNumber = $data['PanNumber'] ?? null;
$documents = $data['documents'] ?? [];
$journeyId = isset($data['journeyId']) ? (int)$data['journeyId'] : null;
$journeyType = trim($data['journeyType'] ?? '');

if (empty($PanNumber)) {
    echo json_encode(["status" => "error", "statusCode" => 400,
    "data" =>[ "message" => "PanNumber is required"]]);
    http_response_code(400);
    exit;
}

if (!is_array($documents) || empty($documents)) {
    echo json_encode(["status" => "error", "statusCode" => 400,
                       "data" =>["message" => "Documents array is required"]]);
    http_response_code(400);
    exit;
}

$PanNumber = mysqli_real_escape_string($conn, $PanNumber);

// Validate journeyType if provided
$validJourneyTypes = ['ITR', 'E-Verify', 'GST', 'Loan'];
if (!empty($journeyType) && !in_array($journeyType, $validJourneyTypes)) {
    echo json_encode(["status" => "error", "statusCode" => 400,
    "data" =>[ "message" => "Invalid journeyType. Must be one of: ITR, E-Verify, GST, Loan"]]);
    http_response_code(400);
    exit;
}

$journeyType = mysqli_real_escape_string($conn, $journeyType);

// HANDLE USER JOURNEY
if (!empty($journeyType) || $journeyId) {
    if ($journeyId) {
        // Verify journey exists and belongs to this user
        $journeyCheckSql = "SELECT id FROM user_journey 
                            WHERE id = '$journeyId' AND userId = '$UserId'";
        $journeyResult = $conn->query($journeyCheckSql);
        
        if (!$journeyResult || $journeyResult->num_rows === 0) {
            echo json_encode(["status" => "error", "statusCode" => 400,
            "data" =>[ "message" => "Invalid journeyId or journey does not belong to this user"]]);
            http_response_code(400);
            exit;
        }
        
        // Update journey status
        $updateJourneySql = "UPDATE user_journey 
                            SET status = 'in_progress',
                                currentStep = 'documents',
                                updatedAt = NOW()
                            WHERE id = '$journeyId'";
        $conn->query($updateJourneySql);
    } elseif (!empty($journeyType)) {
        // Find or create journey based on journeyType
        $journeyCheckSql = "SELECT id FROM user_journey 
                            WHERE userId = '$UserId' 
                            AND journeyType = '$journeyType' 
                            AND panNumber = '$PanNumber'
                            ORDER BY id DESC 
                            LIMIT 1";
        $journeyResult = $conn->query($journeyCheckSql);
        
        if ($journeyResult && $journeyResult->num_rows > 0) {
            $journeyRow = $journeyResult->fetch_assoc();
            $journeyId = $journeyRow['id'];
            
            // Update journey
            $updateJourneySql = "UPDATE user_journey 
                                SET status = 'in_progress',
                                    currentStep = 'documents',
                                    updatedAt = NOW()
                                WHERE id = '$journeyId'";
            $conn->query($updateJourneySql);
        } else {
            // Create new journey
            $createJourneySql = "INSERT INTO user_journey 
                                (userId, panNumber, journeyType, status, currentStep, startedAt, updatedAt)
                                VALUES 
                                ('$UserId', '$PanNumber', '$journeyType', 'in_progress', 'documents', NOW(), NOW())";
            
            if ($conn->query($createJourneySql)) {
                $journeyId = $conn->insert_id;
            }
        }
    }
}

$journeyIdSql = ($journeyId === null) ? 'NULL' : (int)$journeyId;

$userIdEscaped = mysqli_real_escape_string($conn, (string) $UserId);

// Append each document; existing rows for this PAN are left unchanged.
// Removals are done via delete_document.php. Duplicate fileName for same user+PAN is skipped.
foreach ($documents as $doc) {
    if (!is_array($doc)) {
        continue;
    }

    $documentName = $doc['documentName'] ?? '';
    $fileType = $doc['fileType'] ?? '';
    $filePassword = $doc['filePassword'] ?? '';
    $fileName = $doc['fileName'] ?? '';

    if ($documentName === '' || $fileType === '' || $fileName === '') {
        echo json_encode(["status" => "error", "statusCode" => 400,
        "data" =>[ "message" => "Each document requires documentName, fileType, and fileName"]]);
        http_response_code(400);
        exit;
    }

    $docName = mysqli_real_escape_string($conn, $documentName);
    $fileTypeEsc = mysqli_real_escape_string($conn, $fileType);
    $filePasswordEsc = mysqli_real_escape_string($conn, $filePassword);
    $fileNameEsc = mysqli_real_escape_string($conn, $fileName);

    $dupSql = "SELECT id FROM document_details 
               WHERE UserId = '$userIdEscaped' 
                 AND PanNumber = '$PanNumber' 
                 AND fileName = '$fileNameEsc' 
                 AND isActive = 1 
               LIMIT 1";
    $dupResult = $conn->query($dupSql);
    if ($dupResult && $dupResult->num_rows > 0) {
        continue;
    }

    $sql = "
        INSERT INTO document_details 
        (UserId, PanNumber, journeyId, name, type, password, fileName, isActive, createdAt, createdBy)
        VALUES
        ('$userIdEscaped', '$PanNumber', $journeyIdSql, '$docName', '$fileTypeEsc', '$filePasswordEsc', '$fileNameEsc', 1, NOW(), '$userIdEscaped')
    ";

    if (!$conn->query($sql)) {
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to save document: " . $conn->error]
        ]);
        http_response_code(500);
        exit;
    }
}

echo json_encode([
    "status" => "success",
    "statusCode" => 200,
    "data" =>[
    "message" => "Documents saved successfully",
    "journeyId" => $journeyId,
    "journeyType" => !empty($journeyType) ? $journeyType : null,
    ]
]);
http_response_code(200);
?>
