<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

$uploadDir = __DIR__ . '/../uploads/';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    // Required values
    $PanNumber = $_POST['PanNumber'] ?? null;
    $receivedFileName = $_POST['fileName'] ?? null;

    if (empty($PanNumber)) {
        echo json_encode(["status" => "error", "statusCode" => 400,
        "data" =>[ "message" => "PanNumber is required"]]);
        http_response_code(400);
        exit;
    }

    if (empty($receivedFileName)) {
        echo json_encode(["status" => "error","statusCode" => 400,
        "data" =>[ "message" => "fileName is required"]]);
        http_response_code(400);
        exit;
    }

    // FILE CHECK
    if (!isset($_FILES['file'])) {
        echo json_encode(["status" => "error","statusCode" => 400,
        "data" =>[ "message" => "File is required"]]);
        http_response_code(400);
        exit;
    }

    $file = $_FILES['file'];
    if (($file['error'] ?? UPLOAD_ERR_OK) !== UPLOAD_ERR_OK) {
        $uploadErrors = [
            UPLOAD_ERR_INI_SIZE => 'Uploaded file exceeds server upload_max_filesize',
            UPLOAD_ERR_FORM_SIZE => 'Uploaded file exceeds MAX_FILE_SIZE limit',
            UPLOAD_ERR_PARTIAL => 'File was only partially uploaded',
            UPLOAD_ERR_NO_FILE => 'No file was uploaded',
            UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder on server',
            UPLOAD_ERR_CANT_WRITE => 'Failed to write uploaded file to disk',
            UPLOAD_ERR_EXTENSION => 'File upload stopped by extension',
        ];
        $errCode = (int)$file['error'];
        $errMessage = $uploadErrors[$errCode] ?? 'Unknown upload error';
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => [
                "message" => "File upload error: " . $errMessage,
                "uploadErrorCode" => $errCode
            ]
        ]);
        http_response_code(400);
        exit;
    }
    $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    $allowedTypes = ['jpg', 'jpeg', 'png', 'pdf'];

    if (!in_array($extension, $allowedTypes)) {
        echo json_encode(["status" => "error","statusCode" => 400,
        "data" =>[ "message" => "Invalid file type"]]);
        http_response_code(400);
        exit;
    }

    // Unique filename
    $uniqueName = uniqid($receivedFileName . "_", true) . "." . $extension;
    $targetDir = $uploadDir . $PanNumber . '/';

    if (!is_dir($targetDir)) {
        mkdir($targetDir, 0777, true);
    }

    $targetFile = $targetDir . $uniqueName;

    if (move_uploaded_file($file['tmp_name'], $targetFile)) {
        echo json_encode([
            "status" => "success",
            "statusCode" => 200,
            "data" =>[
                "message" => "File uploaded successfully",
            "fileName" => $uniqueName,
            "filePath" => $targetFile
            ]
        ]);
        http_response_code(200);
    } else {
        echo json_encode(["status" => "error", "statusCode" => 400,
        "data" =>[ "message" => "File upload failed"]]);
        http_response_code(500);
    }

} else {
    echo json_encode(["status" => "error", "statusCode" => 405,
    "data" =>[ "message" => "Only POST allowed"]]);
    http_response_code(405);
}
?>
