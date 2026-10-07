<?php
/**
 * Admin ITRs Management API
 * List all ITRs with personal details, payment info, and package information
 * Update ITR status (tax professionals / admin)
 * 
 * Endpoints:
 * - GET /admin/itrs.php - List all ITRs (with pagination)
 *   Query Parameters: page, limit (default 10, max 100)
 * - PUT /admin/itrs.php - Update ITR status (ADMIN, ACCOUNTANT, CA)
 *   Body: { "id" or "itrId": number, "status": string, "comment": string }
 *   status: PENDING | ASSIGNED | REQUIRED | INCORRECT | FILED | COMPLETED
 *   comment: required when updating status (for audit and future notifications)
 */

// CORS Headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Polyfill for getallheaders() when not running under Apache (e.g. nginx, PHP-FPM, CLI)
if (!function_exists('getallheaders')) {
    function getallheaders() {
        $headers = [];
        foreach ($_SERVER as $name => $value) {
            if (substr($name, 0, 5) === 'HTTP_') {
                $headers[str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))))] = $value;
            }
        }
        return $headers;
    }
}

require '../include/config.php';
require '../phpjwt/Token.php';
require '../itr_status/StatusHelper.php';

// Token verification
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
        "data" => ["message" => "Authorization token required"]
    ]);
    exit;
}

$decoded = Token::Verify($token, $key);
if ($decoded === false) {
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "statusCode" => 401,
        "data" => ["message" => "Invalid or expired token"]
    ]);
    exit;
}

// Extract user info from token
$userId = $decoded['UserId'] ?? null;
$userRole = $decoded['Role'] ?? null;
// Normalize role for case-insensitive comparison (token may send "Admin" or "ADMIN")
$userRoleUpper = $userRole !== null ? strtoupper(trim((string)$userRole)) : '';

$method = $_SERVER['REQUEST_METHOD'];

// GET - List all ITRs with pagination
if ($method === 'GET') {
    // Get pagination parameters
    $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
    $limit = isset($_GET['limit']) ? max(1, min(100, intval($_GET['limit']))) : 10;
    $offset = ($page - 1) * $limit;
    
    // Auto-determine professionalId based on user role
    // ADMIN: show ALL ITRs (no filter). Optional ?professionalId= for filtering by professional.
    // ACCOUNTANT/CA: show only ITRs assigned to that professional.
    $professionalId = null;
    $professionalIdEscaped = null;
    
    if ($userRoleUpper === 'ADMIN') {
        // Admin sees all ITRs; only filter if optional professionalId is provided
        if (isset($_GET['professionalId']) && $_GET['professionalId'] !== '') {
            $professionalId = intval($_GET['professionalId']);
            $professionalIdEscaped = mysqli_real_escape_string($conn, $professionalId);
        }
    } elseif (in_array($userRoleUpper, ['ACCOUNTANT', 'CA'])) {
        // Professional: filter by their assignments only
        $professionalId = $userId;
        $professionalIdEscaped = mysqli_real_escape_string($conn, $professionalId);
    }
    // When $professionalId is null (ADMIN, no filter): list ALL active personal_details rows (one per row).
    // When filtering by professional: list latest personal_detail per (UserId, PANNumber) that has assignment.
    
    $isAdminShowAll = ($userRoleUpper === 'ADMIN' && !$professionalId);
    
    if ($isAdminShowAll) {
        // ADMIN, no filter: count and list every personal_details row with isActive = 1
        $countSql = "SELECT COUNT(*) as total FROM personal_details pd WHERE pd.isActive = 1";
        $countResult = $conn->query($countSql);
        if (!$countResult) {
            http_response_code(500);
            echo json_encode([
                "status" => "error",
                "statusCode" => 500,
                "data" => ["message" => "Count query error: " . $conn->error]
            ]);
            exit;
        }
        $countRow = $countResult->fetch_assoc();
        $totalItrs = $countRow ? (int)$countRow['total'] : 0;
        $totalPages = $limit > 0 ? ceil($totalItrs / $limit) : 0;
        
        $sql = "SELECT 
                    pd.id as personal_detail_id,
                    pd.UserId,
                    pd.PANNumber,
                    pd.FirstName,
                    pd.MiddleName,
                    pd.LastName,
                    pd.EMAIL,
                    pd.MobileNumber,
                    pd.aadharCardNumber,
                    pd.Gender,
                    pd.DATEOFBIRTH,
                    pd.FinancialYear,
                    pd.Address,
                    pd.Country,
                    pd.createdAt as personal_detail_created_at,
                    pd.updatedAt as personal_detail_updated_at
                FROM personal_details pd
                WHERE pd.isActive = 1
                ORDER BY pd.createdAt DESC, pd.id DESC
                LIMIT $limit OFFSET $offset";
    } else {
        // Filtered (ACCOUNTANT/CA or ADMIN with professionalId): one per (UserId, PANNumber), latest row only
        $countSql = "SELECT COUNT(DISTINCT CONCAT(pd.UserId, '-', pd.PANNumber)) as total
                     FROM personal_details pd";
        $countSql .= " INNER JOIN itr_detail itr ON pd.UserId = itr.userId 
                         AND UPPER(TRIM(itr.panNumber)) = UPPER(TRIM(pd.PANNumber))
                       INNER JOIN itr_assignments ia ON itr.id = ia.itr_id 
                         AND ia.assigned_to = '$professionalIdEscaped'
                         AND ia.is_active = 1";
        $countSql .= " WHERE pd.isActive = 1";
        
        $countResult = $conn->query($countSql);
        if (!$countResult) {
            http_response_code(500);
            echo json_encode([
                "status" => "error",
                "statusCode" => 500,
                "data" => ["message" => "Count query error: " . $conn->error]
            ]);
            exit;
        }
        $countRow = $countResult->fetch_assoc();
        $totalItrs = $countRow ? (int)$countRow['total'] : 0;
        $totalPages = $limit > 0 ? ceil($totalItrs / $limit) : 0;
        
        $sql = "SELECT 
                    pd.id as personal_detail_id,
                    pd.UserId,
                    pd.PANNumber,
                    pd.FirstName,
                    pd.MiddleName,
                    pd.LastName,
                    pd.EMAIL,
                    pd.MobileNumber,
                    pd.aadharCardNumber,
                    pd.Gender,
                    pd.DATEOFBIRTH,
                    pd.FinancialYear,
                    pd.Address,
                    pd.Country,
                    pd.createdAt as personal_detail_created_at,
                    pd.updatedAt as personal_detail_updated_at
                FROM personal_details pd
                INNER JOIN (
                    SELECT UserId, PANNumber, MAX(id) as max_id
                    FROM personal_details
                    WHERE isActive = 1
                    GROUP BY UserId, PANNumber
                ) grouped ON pd.UserId = grouped.UserId 
                    AND pd.PANNumber = grouped.PANNumber 
                    AND pd.id = grouped.max_id
                INNER JOIN itr_detail itr ON pd.UserId = itr.userId 
                    AND UPPER(TRIM(itr.panNumber)) = UPPER(TRIM(pd.PANNumber))
                INNER JOIN itr_assignments ia ON itr.id = ia.itr_id 
                    AND ia.assigned_to = '$professionalIdEscaped'
                    AND ia.is_active = 1
                WHERE pd.isActive = 1
                ORDER BY pd.createdAt DESC, pd.id DESC
                LIMIT $limit OFFSET $offset";
    }
    
    $result = $conn->query($sql);
    if (!$result) {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Main query error: " . $conn->error]
        ]);
        exit;
    }
    $itrs = [];
    
    if ($result && $result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            // Get all payment records for this UserId + PANNumber combination
            $userId = mysqli_real_escape_string($conn, $row['UserId']);
            $panNumber = mysqli_real_escape_string($conn, $row['PANNumber']);
            
            $paymentSql = "SELECT 
                                pi.id,
                                pi.payment_id as payment_reference,
                                pi.order_id,
                                pi.transaction_id,
                                pi.package_id,
                                pi.subtotal,
                                pi.gst_percentage,
                                pi.gst_amount,
                                pi.grand_total,
                                pi.currency,
                                pi.payment_status,
                                pi.payment_method,
                                pi.gateway_name,
                                pi.created_at,
                                pi.paid_at,
                                p.packagename,
                                p.price as package_price,
                                p.title1 as package_title1,
                                p.description1 as package_description1,
                                p.title2 as package_title2,
                                p.description2 as package_description2
                            FROM payment_info pi
                            LEFT JOIN itr_packages p ON pi.package_id = p.id
                            WHERE pi.user_id = '$userId' AND UPPER(TRIM(pi.pan_number)) = UPPER(TRIM('$panNumber'))
                            ORDER BY pi.created_at DESC";
            
            $paymentResult = $conn->query($paymentSql);
            if (!$paymentResult) {
                // Log error but continue with empty payments array
                error_log("Payment query error for user $userId, PAN $panNumber: " . $conn->error);
            }
            $payments = [];
            $orderIds = [];
            
            if ($paymentResult && $paymentResult->num_rows > 0) {
                while ($paymentRow = $paymentResult->fetch_assoc()) {
                    if ($paymentRow['order_id']) {
                        $orderIds[] = mysqli_real_escape_string($conn, $paymentRow['order_id']);
                    }
                    $payments[] = [
                        "paymentId" => (int)$paymentRow['id'],
                        "paymentReference" => $paymentRow['payment_reference'],
                        "orderId" => $paymentRow['order_id'],
                        "transactionId" => $paymentRow['transaction_id'],
                        "packageId" => $paymentRow['package_id'] ? (int)$paymentRow['package_id'] : null,
                        "package" => $paymentRow['packagename'] ? [
                            "id" => (int)$paymentRow['package_id'],
                            "name" => $paymentRow['packagename'],
                            "price" => floatval($paymentRow['package_price']),
                            "title1" => $paymentRow['package_title1'],
                            "description1" => $paymentRow['package_description1'],
                            "title2" => $paymentRow['package_title2'],
                            "description2" => $paymentRow['package_description2']
                        ] : null,
                        "amount" => [
                            "subtotal" => floatval($paymentRow['subtotal']),
                            "gstPercentage" => floatval($paymentRow['gst_percentage']),
                            "gstAmount" => floatval($paymentRow['gst_amount']),
                            "grandTotal" => floatval($paymentRow['grand_total']),
                            "currency" => $paymentRow['currency']
                        ],
                        "paymentStatus" => $paymentRow['payment_status'],
                        "paymentMethod" => $paymentRow['payment_method'],
                        "gatewayName" => $paymentRow['gateway_name'],
                        "createdAt" => $paymentRow['created_at'],
                        "paidAt" => $paymentRow['paid_at']
                    ];
                }
            }
            
            // Fetch documents for this UserId + PANNumber combination
            $docSql = "SELECT 
                            id,
                            name AS documentName,
                            type AS fileType,
                            password AS filePassword,
                            fileName,
                            createdAt
                        FROM document_details
                        WHERE UserId = '$userId' 
                            AND PanNumber = '$panNumber'
                            AND isActive = 1
                        ORDER BY createdAt DESC";
            
            $docResult = $conn->query($docSql);
            $documents = [];
            
            // Construct download URL for documents using secure download endpoint
            $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
            $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
            // Get the base API path
            $scriptPath = dirname(dirname($_SERVER['SCRIPT_NAME']));
            $downloadBaseUrl = $protocol . '://' . $host . $scriptPath . '/itrdetails/download_document.php?docId=';
            
            if ($docResult && $docResult->num_rows > 0) {
                while ($docRow = $docResult->fetch_assoc()) {
                    $documents[] = [
                        "id" => (int)$docRow['id'],
                        "documentName" => $docRow['documentName'],
                        "fileType" => $docRow['fileType'],
                        "filePassword" => $docRow['filePassword'],
                        "fileName" => $docRow['fileName'],
                        "downloadUrl" => $downloadBaseUrl . (int)$docRow['id'],
                        "createdAt" => $docRow['createdAt']
                    ];
                }
            }
            
            // Fetch ITR details (itr_detail table)
            $itrDetailSql = "SELECT 
                                id as itr_id,
                                userId,
                                panNumber,
                                financialYear,
                                status as itr_status,
                                createdAt as itr_created_at,
                                updatedAt as itr_updated_at
                            FROM itr_detail
                            WHERE userId = '$userId' 
                                AND UPPER(TRIM(panNumber)) = UPPER(TRIM('$panNumber'))
                            ORDER BY createdAt DESC";
            
            $itrDetailResult = $conn->query($itrDetailSql);
            $itrDetails = [];
            $itrIds = [];
            
            if ($itrDetailResult && $itrDetailResult->num_rows > 0) {
                while ($itrRow = $itrDetailResult->fetch_assoc()) {
                    $itrId = (int)$itrRow['itr_id'];
                    $itrIds[] = $itrId;
                    $itrDetails[] = [
                        "itrId" => $itrId,
                        "userId" => (int)$itrRow['userId'],
                        "panNumber" => $itrRow['panNumber'],
                        "financialYear" => $itrRow['financialYear'],
                        "status" => $itrRow['itr_status'],
                        "createdAt" => $itrRow['itr_created_at'],
                        "updatedAt" => $itrRow['itr_updated_at']
                    ];
                }
            }
            
            // Fetch assignment info for this ITR
            $assignments = [];
            if (!empty($itrIds)) {
                $itrIdsEscaped = array_map('intval', $itrIds);
                $assignmentSql = "SELECT 
                                    ia.id as assignment_id,
                                    ia.itr_id,
                                    ia.assigned_to as professional_id,
                                    ia.assigned_at as assignment_date,
                                    ia.assigned_by,
                                    ia.is_active,
                                    prof.FirstName as professional_first_name,
                                    prof.LastName as professional_last_name,
                                    prof.Email as professional_email,
                                    prof.Role as professional_role
                                FROM itr_assignments ia
                                LEFT JOIN users prof ON ia.assigned_to = prof.UserId
                                WHERE ia.itr_id IN (" . implode(',', $itrIdsEscaped) . ")
                                    AND ia.is_active = 1
                                ORDER BY ia.assigned_at DESC";
                
                $assignmentResult = $conn->query($assignmentSql);
                if ($assignmentResult && $assignmentResult->num_rows > 0) {
                    while ($assignRow = $assignmentResult->fetch_assoc()) {
                        $assignments[] = [
                            "assignmentId" => (int)$assignRow['assignment_id'],
                            "itrId" => (int)$assignRow['itr_id'],
                            "professionalId" => (int)$assignRow['professional_id'],
                            "professional" => [
                                "id" => (int)$assignRow['professional_id'],
                                "firstName" => $assignRow['professional_first_name'],
                                "lastName" => $assignRow['professional_last_name'],
                                "email" => $assignRow['professional_email'],
                                "role" => $assignRow['professional_role']
                            ],
                            "assignmentDate" => $assignRow['assignment_date'],
                            "assignedBy" => $assignRow['assigned_by'] ? (int)$assignRow['assigned_by'] : null,
                            "isActive" => (bool)$assignRow['is_active']
                        ];
                    }
                }
            }
            
            // When ITR has active assignment, show status as Assigned (overrides itr_detail.status)
            $assignedItrIds = [];
            foreach ($assignments as $a) {
                if (!empty($a['isActive'])) {
                    $assignedItrIds[$a['itrId']] = true;
                }
            }
            foreach ($itrDetails as &$d) {
                if (!empty($assignedItrIds[$d['itrId']])) {
                    $d['status'] = 'Assigned';
                }
            }
            unset($d);
            
            // Fetch ITR order status from itr_order_status table
            // Can be linked by order_id or itr_id
            $statusSteps = [];
            if (!empty($orderIds) || !empty($itrIds)) {
                $statusWhere = [];
                if (!empty($orderIds)) {
                    $orderIdsEscaped = array_map(function($id) use ($conn) {
                        return "'" . mysqli_real_escape_string($conn, $id) . "'";
                    }, $orderIds);
                    $statusWhere[] = "order_id IN (" . implode(',', $orderIdsEscaped) . ")";
                }
                if (!empty($itrIds)) {
                    $itrIdsEscaped = array_map('intval', $itrIds);
                    $statusWhere[] = "itr_id IN (" . implode(',', $itrIdsEscaped) . ")";
                }
                if (!empty($statusWhere)) {
                    $statusSql = "SELECT 
                                    id,
                                    order_id,
                                    itr_id,
                                    payment_id,
                                    pan_number,
                                    status_step,
                                    is_completed,
                                    completed_at,
                                    notes,
                                    has_concern,
                                    created_at,
                                    updated_at
                                FROM itr_order_status
                                WHERE (" . implode(' OR ', $statusWhere) . ")
                                    AND user_id = '$userId'
                                ORDER BY created_at ASC";
                    
                    $statusResult = $conn->query($statusSql);
                    if ($statusResult && $statusResult->num_rows > 0) {
                        while ($statusRow = $statusResult->fetch_assoc()) {
                            $statusSteps[] = [
                                "id" => (int)$statusRow['id'],
                                "orderId" => $statusRow['order_id'],
                                "itrId" => $statusRow['itr_id'] ? (int)$statusRow['itr_id'] : null,
                                "paymentId" => $statusRow['payment_id'],
                                "panNumber" => $statusRow['pan_number'],
                                "statusStep" => $statusRow['status_step'],
                                "isCompleted" => (bool)$statusRow['is_completed'],
                                "completedAt" => $statusRow['completed_at'],
                                "notes" => $statusRow['notes'],
                                "hasConcern" => (bool)$statusRow['has_concern'],
                                "createdAt" => $statusRow['created_at'],
                                "updatedAt" => $statusRow['updated_at']
                            ];
                        }
                    }
                }
            }
            
            // Payment + acknowledgement + unified display status (sync with mobile)
            $hasPaymentSuccess = false;
            foreach ($payments as $p) {
                if (strtolower(trim($p['paymentStatus'] ?? '')) === 'success') {
                    $hasPaymentSuccess = true;
                    break;
                }
            }

            $ackNumber = null;
            $primaryItrId = !empty($itrIds) ? (int) $itrIds[0] : null;
            if ($primaryItrId) {
                $ackTableCheck = $conn->query("SHOW TABLES LIKE 'itr_acknowledgement'");
                if ($ackTableCheck && $ackTableCheck->num_rows > 0) {
                    $ackRes = $conn->query(
                        "SELECT acknowledgement_number FROM itr_acknowledgement WHERE itr_id = $primaryItrId ORDER BY id DESC LIMIT 1"
                    );
                    if ($ackRes && $ackRes->num_rows > 0) {
                        $ackRow = $ackRes->fetch_assoc();
                        $ackNumber = $ackRow['acknowledgement_number'] ?? null;
                    }
                }
            }

            $hasActiveAssignment = false;
            foreach ($assignments as $a) {
                if (!empty($a['isActive'])) {
                    $hasActiveAssignment = true;
                    break;
                }
            }

            $statusMeta = StatusHelper::resolveAdminDisplayStatus(
                $hasPaymentSuccess,
                $ackNumber,
                $statusSteps,
                $hasActiveAssignment
            );

            if (($ackNumber === null || trim((string) $ackNumber) === '') && $statusMeta['displayStatus'] === 'COMPLETED') {
                foreach ($statusSteps as $step) {
                    if (($step['statusStep'] ?? '') === 'acknowledgement_generated' && !empty($step['isCompleted'])) {
                        $notes = trim($step['notes'] ?? '');
                        if ($notes !== '') {
                            $ackNumber = $notes;
                        }
                        break;
                    }
                }
            }

            // Build the ITR record
            $itrs[] = [
                "personalDetailId" => (int)$row['personal_detail_id'],
                "userId" => (int)$row['UserId'],
                "panNumber" => $row['PANNumber'],
                "displayStatus" => $statusMeta['displayStatus'],
                "statusDisplayText" => $statusMeta['displayText'],
                "itrStatus" => $statusMeta['itrStatus'],
                "hasSuccessfulPayment" => $statusMeta['hasSuccessfulPayment'],
                "acknowledgementNumber" => $ackNumber,
                "personalDetails" => [
                    "firstName" => $row['FirstName'],
                    "middleName" => $row['MiddleName'],
                    "lastName" => $row['LastName'],
                    "email" => $row['EMAIL'],
                    "mobileNumber" => $row['MobileNumber'],
                    "aadharCardNumber" => $row['aadharCardNumber'],
                    "gender" => $row['Gender'],
                    "dateOfBirth" => $row['DATEOFBIRTH'],
                    "financialYear" => $row['FinancialYear'],
                    "address" => $row['Address'],
                    "country" => $row['Country'],
                    "createdAt" => $row['personal_detail_created_at'],
                    "updatedAt" => $row['personal_detail_updated_at']
                ],
                "documents" => $documents,
                "documentCount" => count($documents),
                "payments" => $payments,
                "paymentCount" => count($payments),
                "itrDetails" => $itrDetails,
                "itrCount" => count($itrDetails),
                "assignments" => $assignments,
                "assignmentCount" => count($assignments),
                "statusSteps" => $statusSteps,
                "statusStepCount" => count($statusSteps)
            ];
        }
    }
    
    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "itrs" => $itrs,
            "pagination" => [
                "page" => $page,
                "limit" => $limit,
                "total" => $totalItrs,
                "totalPages" => $totalPages
            ]
        ]
    ], JSON_UNESCAPED_UNICODE);
}

// PUT - Update ITR status (tax professionals / admin); comment mandatory for audit and notifications
elseif ($method === 'PUT') {
    // Only ADMIN, ACCOUNTANT, CA can update ITR status
    if (!in_array($userRoleUpper, ['ADMIN', 'ACCOUNTANT', 'CA'])) {
        http_response_code(403);
        echo json_encode([
            "status" => "error",
            "statusCode" => 403,
            "data" => ["message" => "Access denied. Professional or Admin role required."]
        ]);
        exit;
    }

    try {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "Invalid JSON input"]
        ]);
        exit;
    }

    $itrId = isset($input['id']) ? (int)$input['id'] : (isset($input['itrId']) ? (int)$input['itrId'] : null);
    $status = isset($input['status']) ? trim($input['status']) : null;
    $comment = isset($input['comment']) ? trim($input['comment']) : null;

    if (!$itrId) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "id or itrId is required"]
        ]);
        exit;
    }
    if ($status === null || $status === '') {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "status is required"]
        ]);
        exit;
    }
    if ($comment === null || $comment === '') {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "comment is required when updating ITR status"]
        ]);
        exit;
    }

    if (strtoupper($status) === 'COMPLETED') {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => ["message" => "Use Mark ITR Complete (submit_acknowledgement.php) with an acknowledgement number to mark completed"]
        ]);
        exit;
    }

    $allowedStatuses = ['PENDING', 'ASSIGNED', 'REQUIRED', 'INCORRECT', 'FILED'];
    if (!in_array(strtoupper($status), $allowedStatuses)) {
        http_response_code(400);
        echo json_encode([
            "status" => "error",
            "statusCode" => 400,
            "data" => [
                "message" => "Invalid status. Allowed: " . implode(', ', $allowedStatuses),
                "allowedStatuses" => $allowedStatuses
            ]
        ]);
        exit;
    }
    $status = strtoupper($status);
    $itrIdEscaped = mysqli_real_escape_string($conn, $itrId);
    $commentEscaped = mysqli_real_escape_string($conn, $comment);

    // Check ITR exists and get client user_id
    $itrRow = $conn->query("SELECT id, userId FROM itr_detail WHERE id = '$itrIdEscaped' LIMIT 1");
    if (!$itrRow || $itrRow->num_rows === 0) {
        http_response_code(404);
        echo json_encode([
            "status" => "error",
            "statusCode" => 404,
            "data" => ["message" => "ITR not found"]
        ]);
        exit;
    }
    $itr = $itrRow->fetch_assoc();
    $clientUserId = (int)$itr['userId'];

    // ACCOUNTANT/CA: must be assigned to this ITR (ADMIN can update any)
    if (in_array($userRoleUpper, ['ACCOUNTANT', 'CA'])) {
        $checkAssign = $conn->query("SELECT id FROM itr_assignments WHERE itr_id = '$itrIdEscaped' AND is_active = 1 AND assigned_to = " . (int)$userId . " LIMIT 1");
        if (!$checkAssign || $checkAssign->num_rows === 0) {
            http_response_code(403);
            echo json_encode([
                "status" => "error",
                "statusCode" => 403,
                "data" => ["message" => "You are not assigned to this ITR"]
            ]);
            exit;
        }
    }

    // Update itr_detail.status
    $statusEscaped = mysqli_real_escape_string($conn, $status);
    $updateSql = "UPDATE itr_detail SET status = '$statusEscaped', updatedAt = NOW() WHERE id = '$itrIdEscaped'";
    if (!$conn->query($updateSql)) {
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => ["message" => "Failed to update ITR status: " . $conn->error]
        ]);
        exit;
    }

    // Store comment in itr_order_concerns for audit and future notifications (status_update type)
    // status_id is NULL for status_update. If status_id is NOT NULL, we try to make it nullable once so the insert succeeds.
    // When status is COMPLETED, save concern as resolved; otherwise save as pending.
    $professionalId = (int)$userId;
    $concernStatus = ($status === 'COMPLETED') ? 'resolved' : 'pending';
    $concernResolvedBy = ($status === 'COMPLETED') ? (string)$professionalId : 'NULL';
    $concernResolvedAt = ($status === 'COMPLETED') ? 'NOW()' : 'NULL';
    $concernTableCheck = $conn->query("SHOW TABLES LIKE 'itr_order_concerns'");
    if ($concernTableCheck && $concernTableCheck->num_rows > 0) {
        $hasCommentCol = $conn->query("SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'itr_order_concerns' AND COLUMN_NAME = 'comment' LIMIT 1");
        $useCommentCol = $hasCommentCol && $hasCommentCol->num_rows > 0;
        if ($useCommentCol) {
            $ins = "INSERT INTO itr_order_concerns (status_id, itr_id, user_id, concern_type, concern_text, comment, status, resolved_by, resolved_at, created_at, updated_at)
                    VALUES (NULL, $itrIdEscaped, $clientUserId, 'status_update', '$commentEscaped', '$commentEscaped', '$concernStatus', $concernResolvedBy, $concernResolvedAt, NOW(), NOW())";
        } else {
            $ins = "INSERT INTO itr_order_concerns (status_id, itr_id, user_id, concern_type, concern_text, status, resolved_by, resolved_at, created_at, updated_at)
                    VALUES (NULL, $itrIdEscaped, $clientUserId, 'status_update', '$commentEscaped', '$concernStatus', $concernResolvedBy, $concernResolvedAt, NOW(), NOW())";
        }
        $insertOk = false;
        try {
            $insertOk = $conn->query($ins);
            if (!$insertOk && $conn->error) {
                $err = $conn->error;
                error_log('[admin/itrs.php] itr_order_concerns insert failed: ' . $err);
                // If failure is due to status_id NOT NULL, make column nullable and retry once
                if (stripos($err, 'status_id') !== false && (stripos($err, 'default') !== false || stripos($err, 'null') !== false)) {
                    @$conn->query("ALTER TABLE itr_order_concerns MODIFY COLUMN status_id int(11) DEFAULT NULL COMMENT 'FK to itr_order_status (nullable for status_update)'");
                    $insertOk = $conn->query($ins);
                    if (!$insertOk && $conn->error) {
                        error_log('[admin/itrs.php] itr_order_concerns insert retry failed: ' . $conn->error);
                    }
                }
            }
        } catch (Throwable $e) {
            error_log('[admin/itrs.php] itr_order_concerns insert exception: ' . $e->getMessage());
            // Retry after making status_id nullable in case exception was due to that
            if (stripos($e->getMessage(), 'status_id') !== false) {
                try {
                    @$conn->query("ALTER TABLE itr_order_concerns MODIFY COLUMN status_id int(11) DEFAULT NULL COMMENT 'FK to itr_order_status (nullable for status_update)'");
                    $insertOk = $conn->query($ins);
                } catch (Throwable $e2) {
                    error_log('[admin/itrs.php] itr_order_concerns insert retry exception: ' . $e2->getMessage());
                }
            }
        }
    }

    // When expert sets status to COMPLETED, mark the first incomplete workflow step as complete
    if ($status === 'COMPLETED') {
        $clientUserIdEscaped = mysqli_real_escape_string($conn, $clientUserId);
        $orderIdForStep = null;
        $panForStep = null;
        $paymentIdForStep = null;
        $paySql = "SELECT order_id, pan_number, payment_id FROM payment_info WHERE user_id = '$clientUserIdEscaped' AND payment_status = 'success' ORDER BY paid_at DESC LIMIT 1";
        $payRes = $conn->query($paySql);
        if ($payRes && $payRes->num_rows > 0) {
            $payRow = $payRes->fetch_assoc();
            $orderIdForStep = $payRow['order_id'] ?? null;
            $panForStep = $payRow['pan_number'] ?? null;
            $paymentIdForStep = $payRow['payment_id'] ?? null;
        }
        $stepsRows = StatusHelper::getStatusSteps($conn, $orderIdForStep, $itrId, $clientUserId);
        $allSteps = StatusHelper::getAllSteps();
        $firstIncompleteStep = null;
        foreach ($allSteps as $stepCode) {
            $completed = false;
            foreach ($stepsRows as $row) {
                if ($row['status_step'] === $stepCode && (int)($row['is_completed'] ?? 0) === 1) {
                    $completed = true;
                    break;
                }
            }
            if (!$completed) {
                $firstIncompleteStep = $stepCode;
                break;
            }
        }
        if ($firstIncompleteStep) {
            StatusHelper::updateStatusStep(
                $conn,
                $orderIdForStep,
                (int)$itrId,
                $clientUserId,
                $paymentIdForStep,
                $panForStep,
                $firstIncompleteStep,
                true,
                'Marked complete from ITR status COMPLETED'
            );
        }
    }

    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "statusCode" => 200,
        "data" => [
            "message" => "ITR status updated successfully",
            "itrId" => (int)$itrId,
            "status" => $status,
            "comment" => $comment
        ]
    ], JSON_UNESCAPED_UNICODE);

    } catch (Throwable $e) {
        $logMsg = '[admin/itrs.php] PUT error: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine();
        error_log($logMsg);
        http_response_code(500);
        echo json_encode([
            "status" => "error",
            "statusCode" => 500,
            "data" => [
                "message" => "Failed to update ITR",
                "error" => $e->getMessage()
            ]
        ], JSON_UNESCAPED_UNICODE);
    }
}

else {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "statusCode" => 405,
        "data" => ["message" => "Method not allowed"]
    ]);
}

exit;
?>
