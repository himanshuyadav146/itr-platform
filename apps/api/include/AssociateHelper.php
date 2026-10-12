<?php

class AssociateHelper
{
    const GST_PERCENTAGE = 18;
    const ASSOCIATE_ROLES = ['CA', 'ACCOUNTANT', 'TAX_EXPERT'];
    const APPROVED = 'approved';
    const PENDING = 'pending';
    const REJECTED = 'rejected';
    const UNLISTED = 'unlisted';

    public static function sendCors($methods = 'GET, POST, PUT, OPTIONS')
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: ' . $methods);
        header('Access-Control-Allow-Headers: Content-Type, Authorization');
        header('Content-Type: application/json');
        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            http_response_code(200);
            exit;
        }
    }

    public static function json($statusCode, $status, $data)
    {
        http_response_code($statusCode);
        echo json_encode([
            'statusCode' => $statusCode,
            'status' => $status,
            'data' => $data,
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    public static function readJson()
    {
        $raw = file_get_contents('php://input');
        if ($raw === false || $raw === '') {
            return [];
        }
        $decoded = json_decode($raw, true);
        return is_array($decoded) ? $decoded : [];
    }

    public static function bearerToken()
    {
        $headers = function_exists('getallheaders') ? getallheaders() : [];
        $auth = '';
        foreach ($headers as $key => $value) {
            if (strtolower($key) === 'authorization') {
                $auth = $value;
                break;
            }
        }
        if ($auth === '' && isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $auth = $_SERVER['HTTP_AUTHORIZATION'];
        }
        return trim(str_replace('Bearer ', '', $auth));
    }

    public static function requireAuth($key)
    {
        $token = self::bearerToken();
        if ($token === '') {
            self::json(401, 'error', ['message' => 'Authorization token required']);
        }
        $decoded = Token::Verify($token, $key);
        if ($decoded === false) {
            self::json(401, 'error', ['message' => 'Invalid or expired token']);
        }
        $userId = isset($decoded['UserId']) ? (int)$decoded['UserId'] : 0;
        if ($userId <= 0) {
            self::json(401, 'error', ['message' => 'UserId missing in token']);
        }
        $decoded['UserId'] = $userId;
        return $decoded;
    }

    public static function tableExists($conn, $table)
    {
        $table = mysqli_real_escape_string($conn, $table);
        $result = $conn->query("SHOW TABLES LIKE '$table'");
        return $result && $result->num_rows > 0;
    }

    public static function columnExists($conn, $table, $column)
    {
        $table = mysqli_real_escape_string($conn, $table);
        $column = mysqli_real_escape_string($conn, $column);
        $result = $conn->query("SHOW COLUMNS FROM `$table` LIKE '$column'");
        return $result && $result->num_rows > 0;
    }

    public static function getUser($conn, $userId)
    {
        $userId = (int)$userId;
        $sql = "SELECT * FROM users WHERE UserId = $userId LIMIT 1";
        $result = $conn->query($sql);
        if (!$result || $result->num_rows === 0) {
            return null;
        }
        return $result->fetch_assoc();
    }

    public static function userRole($user)
    {
        if (!$user) {
            return '';
        }
        $role = $user['role'] ?? ($user['Role'] ?? '');
        return strtoupper(trim((string)$role));
    }

    public static function isAssociateRole($role)
    {
        return in_array(strtoupper(trim((string)$role)), self::ASSOCIATE_ROLES, true);
    }

    public static function requireAdmin($conn, $decoded)
    {
        $user = self::getUser($conn, $decoded['UserId']);
        if (self::userRole($user) !== 'ADMIN') {
            self::json(403, 'error', ['message' => 'Admin access required']);
        }
        return $user;
    }

    public static function requireAssociate($conn, $decoded)
    {
        $user = self::getUser($conn, $decoded['UserId']);
        $role = self::userRole($user);
        if ($role !== 'ADMIN' && !self::isAssociateRole($role)) {
            self::json(403, 'error', ['message' => 'Associate access required']);
        }
        return $user;
    }

    public static function displayName($user)
    {
        if (!$user) {
            return '';
        }
        return trim(($user['FirstName'] ?? '') . ' ' . ($user['MiddleName'] ?? '') . ' ' . ($user['LastName'] ?? ''));
    }

    public static function ensureProfile($conn, $userId, $role = 'CA')
    {
        if (!self::tableExists($conn, 'associate_profiles')) {
            return false;
        }
        $userId = (int)$userId;
        $role = mysqli_real_escape_string($conn, strtoupper($role));
        if (!self::isAssociateRole($role)) {
            $role = 'CA';
        }
        $check = $conn->query("SELECT id FROM associate_profiles WHERE user_id = $userId LIMIT 1");
        if ($check && $check->num_rows > 0) {
            return true;
        }
        return (bool)$conn->query(
            "INSERT INTO associate_profiles (user_id, role, approval_status, created_at)
             VALUES ($userId, '$role', 'pending', NOW())"
        );
    }

    public static function getProfileRow($conn, $userId)
    {
        if (!self::tableExists($conn, 'associate_profiles')) {
            return null;
        }
        $userId = (int)$userId;
        $sql = "SELECT p.*, u.FirstName, u.MiddleName, u.LastName, u.Email, u.Mobile, u.CreatedAt AS registered_at
                FROM associate_profiles p
                INNER JOIN users u ON u.UserId = p.user_id
                WHERE p.user_id = $userId
                LIMIT 1";
        $result = $conn->query($sql);
        if (!$result || $result->num_rows === 0) {
            return null;
        }
        return $result->fetch_assoc();
    }

    public static function isApprovedAssociate($conn, $userId)
    {
        $row = self::getProfileRow($conn, $userId);
        if (!$row) {
            return false;
        }
        return strtolower($row['approval_status']) === self::APPROVED;
    }

    public static function getServiceFees($conn, $associateId, $activeOnly = true)
    {
        if (!self::tableExists($conn, 'associate_service_fees')) {
            return [];
        }
        $associateId = (int)$associateId;
        $where = "f.associate_id = $associateId";
        if ($activeOnly) {
            $where .= ' AND f.is_active = 1';
        }
        $sql = "SELECT f.id, f.associate_id, f.service_id, f.listed_fee, f.is_active,
                       s.Name AS service_name, s.description AS service_description
                FROM associate_service_fees f
                LEFT JOIN services s ON s.id = f.service_id
                WHERE $where
                ORDER BY s.Name ASC";
        $result = $conn->query($sql);
        $items = [];
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $items[] = self::formatFee($row);
            }
        }
        return $items;
    }

    public static function formatFee($row)
    {
        return [
            'id' => isset($row['id']) ? (int)$row['id'] : null,
            'associate_id' => (int)$row['associate_id'],
            'service_id' => (int)$row['service_id'],
            'service_name' => $row['service_name'] ?? '',
            'service_description' => $row['service_description'] ?? '',
            'listed_fee' => round((float)$row['listed_fee'], 2),
            'is_active' => (int)($row['is_active'] ?? 1) === 1,
        ];
    }

    public static function getListedFee($conn, $associateId, $serviceId)
    {
        if (!self::tableExists($conn, 'associate_service_fees')) {
            return null;
        }
        $associateId = (int)$associateId;
        $serviceId = (int)$serviceId;
        $sql = "SELECT f.listed_fee, s.Name AS service_name
                FROM associate_service_fees f
                LEFT JOIN services s ON s.id = f.service_id
                WHERE f.associate_id = $associateId
                  AND f.service_id = $serviceId
                  AND f.is_active = 1
                LIMIT 1";
        $result = $conn->query($sql);
        if (!$result || $result->num_rows === 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        return [
            'listed_fee' => round((float)$row['listed_fee'], 2),
            'service_name' => $row['service_name'] ?? 'Associate service',
        ];
    }

    public static function formatAssociate($row, $fees = [])
    {
        $status = strtolower($row['approval_status'] ?? self::PENDING);
        $role = strtoupper($row['role'] ?? ($row['user_role'] ?? 'CA'));
        return [
            'id' => (int)$row['user_id'],
            'user_id' => (int)$row['user_id'],
            'name' => self::displayName($row),
            'first_name' => $row['FirstName'] ?? '',
            'last_name' => $row['LastName'] ?? '',
            'email' => $row['Email'] ?? '',
            'mobile' => $row['Mobile'] ?? '',
            'role' => $role,
            'icai_membership_no' => $row['icai_membership_no'] ?? '',
            'gstin' => $row['gstin'] ?? '',
            'pan' => $row['pan'] ?? '',
            'city' => $row['city'] ?? '',
            'state' => $row['state'] ?? '',
            'bio' => $row['bio'] ?? '',
            'years_experience' => (int)($row['years_experience'] ?? 0),
            'approval_status' => $status,
            'rejection_reason' => $row['rejection_reason'] ?? '',
            'approved_at' => $row['approved_at'] ?? null,
            'created_at' => $row['created_at'] ?? ($row['registered_at'] ?? null),
            'services' => $fees,
        ];
    }

    public static function publicAssociate($row, $fees = [])
    {
        $full = self::formatAssociate($row, $fees);
        unset($full['email'], $full['mobile'], $full['gstin'], $full['pan'], $full['rejection_reason']);
        return $full;
    }

    public static function listServices($conn, $activeOnly = true)
    {
        $where = '1=1';
        if ($activeOnly && self::columnExists($conn, 'services', 'is_active')) {
            $where = 'is_active = 1';
        }
        $desc = self::columnExists($conn, 'services', 'description') ? 'description' : "'' AS description";
        $activeCol = self::columnExists($conn, 'services', 'is_active') ? 'is_active' : '1 AS is_active';
        $sql = "SELECT id, Name AS name, $desc, $activeCol FROM services WHERE $where ORDER BY Name ASC";
        $result = $conn->query($sql);
        $items = [];
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $items[] = [
                    'id' => (int)$row['id'],
                    'name' => $row['name'],
                    'description' => $row['description'] ?? '',
                    'is_active' => (int)($row['is_active'] ?? 1) === 1,
                ];
            }
        }
        return $items;
    }

    public static function assignOnPayment($conn, $clientUserId, $panNumber, $associateId, $assignedBy = null)
    {
        $clientUserId = (int)$clientUserId;
        $associateId = (int)$associateId;
        $assignedBy = $assignedBy ? (int)$assignedBy : $clientUserId;
        $panEsc = mysqli_real_escape_string($conn, strtoupper(trim((string)$panNumber)));

        $itrId = null;
        if ($panEsc !== '') {
            $itrSql = "SELECT id FROM itr_detail
                       WHERE userId = $clientUserId AND panNumber = '$panEsc'
                       ORDER BY id DESC LIMIT 1";
            $itrResult = $conn->query($itrSql);
            if ($itrResult && $itrResult->num_rows > 0) {
                $itrId = (int)$itrResult->fetch_assoc()['id'];
            }
        }
        if (!$itrId) {
            $itrSql = "SELECT id FROM itr_detail WHERE userId = $clientUserId ORDER BY id DESC LIMIT 1";
            $itrResult = $conn->query($itrSql);
            if ($itrResult && $itrResult->num_rows > 0) {
                $itrId = (int)$itrResult->fetch_assoc()['id'];
            }
        }
        if (!$itrId) {
            return false;
        }

        if (!self::tableExists($conn, 'itr_assignments')) {
            return false;
        }

        $hasAssignedTo = self::columnExists($conn, 'itr_assignments', 'assigned_to');
        $hasIsActive = self::columnExists($conn, 'itr_assignments', 'is_active');

        if ($hasIsActive) {
            $existing = $conn->query("SELECT id FROM itr_assignments WHERE itr_id = $itrId AND is_active = 1 LIMIT 1");
            if ($existing && $existing->num_rows > 0) {
                if ($hasAssignedTo) {
                    $conn->query("UPDATE itr_assignments SET assigned_to = $associateId, assigned_by = $assignedBy, assigned_at = NOW() WHERE itr_id = $itrId AND is_active = 1");
                }
                return true;
            }
        }

        if ($hasAssignedTo) {
            $assignedAtCol = self::columnExists($conn, 'itr_assignments', 'assigned_at') ? 'assigned_at' : 'assignment_date';
            $activeSql = $hasIsActive ? ', is_active' : '';
            $activeVal = $hasIsActive ? ', 1' : '';
            $sql = "INSERT INTO itr_assignments (itr_id, assigned_to, assigned_by, $assignedAtCol $activeSql)
                    VALUES ($itrId, $associateId, $assignedBy, NOW() $activeVal)";
            return (bool)$conn->query($sql);
        }

        if (self::columnExists($conn, 'itr_assignments', 'professional_id')) {
            $sql = "INSERT INTO itr_assignments (itr_id, user_id, professional_id, assigned_by, assignment_date, status)
                    VALUES ($itrId, $clientUserId, $associateId, $assignedBy, NOW(), 'assigned')";
            return (bool)$conn->query($sql);
        }

        return false;
    }
}
