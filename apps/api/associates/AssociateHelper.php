<?php

class AssociateHelper
{
    public static $associateRoles = ['CA', 'ACCOUNTANT', 'TAX_EXPERT'];

    public static function isAssociateRole($role)
    {
        return in_array(strtoupper(trim((string)$role)), self::$associateRoles, true);
    }

    public static function jsonResponse($statusCode, $status, $data)
    {
        http_response_code($statusCode);
        echo json_encode([
            'status' => $status,
            'statusCode' => $statusCode,
            'data' => $data,
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    public static function requireMethod($allowed)
    {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        if ($method === 'OPTIONS') {
            http_response_code(200);
            exit;
        }
        if (!in_array($method, (array)$allowed, true)) {
            self::jsonResponse(405, 'error', ['message' => 'Method not allowed']);
        }
        return $method;
    }

    public static function readJsonBody()
    {
        $input = file_get_contents('php://input');
        $data = json_decode($input, true);
        return is_array($data) ? $data : [];
    }

    public static function bearerToken()
    {
        $headers = function_exists('getallheaders') ? getallheaders() : [];
        $auth = $headers['Authorization'] ?? ($headers['authorization'] ?? '');
        if ($auth === '' && isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $auth = $_SERVER['HTTP_AUTHORIZATION'];
        }
        return trim(str_replace('Bearer ', '', (string)$auth));
    }

    public static function requireUser($key)
    {
        $token = self::bearerToken();
        if ($token === '') {
            self::jsonResponse(401, 'error', ['message' => 'Authorization token required']);
        }
        $decoded = Token::Verify($token, $key);
        if ($decoded === false) {
            self::jsonResponse(401, 'error', ['message' => 'Invalid or expired token']);
        }
        $userId = isset($decoded['UserId']) ? (int)$decoded['UserId'] : 0;
        if ($userId <= 0) {
            self::jsonResponse(401, 'error', ['message' => 'User ID not found in token']);
        }
        $role = strtoupper(trim((string)($decoded['Role'] ?? $decoded['role'] ?? '')));
        return ['userId' => $userId, 'role' => $role, 'decoded' => $decoded];
    }

    public static function fetchUserRole($conn, $userId)
    {
        $userId = (int)$userId;
        $sql = "SELECT UserId, FirstName, MiddleName, LastName, Email, Mobile, Role
                FROM users WHERE UserId = $userId LIMIT 1";
        $result = $conn->query($sql);
        if (!$result || $result->num_rows === 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $row['Role'] = strtoupper(trim((string)($row['Role'] ?? '')));
        return $row;
    }

    public static function createPendingProfile($conn, $userId)
    {
        $userId = (int)$userId;
        $sql = "INSERT INTO associate_profiles (user_id, verification_status, is_listed, created_at, updated_at)
                VALUES ($userId, 'pending', 0, NOW(), NOW())
                ON DUPLICATE KEY UPDATE updated_at = updated_at";
        return $conn->query($sql);
    }

    public static function ensureProfile($conn, $userId)
    {
        $userId = (int)$userId;
        $check = $conn->query("SELECT id FROM associate_profiles WHERE user_id = $userId LIMIT 1");
        if (!$check || $check->num_rows === 0) {
            self::createPendingProfile($conn, $userId);
        }
    }

    public static function getListedCheckout($conn, $associateId, $serviceId)
    {
        $associateId = (int)$associateId;
        $serviceId = (int)$serviceId;
        if ($associateId <= 0 || $serviceId <= 0) {
            return null;
        }

        $sql = "SELECT
                    u.UserId,
                    u.FirstName,
                    u.LastName,
                    u.Role,
                    ap.verification_status,
                    ap.is_listed,
                    ap.city,
                    ap.years_experience,
                    s.id AS service_id,
                    s.name AS service_name,
                    asf.fee
                FROM users u
                INNER JOIN associate_profiles ap ON ap.user_id = u.UserId
                INNER JOIN associate_service_fees asf ON asf.user_id = u.UserId
                INNER JOIN services s ON s.id = asf.service_id
                WHERE u.UserId = $associateId
                  AND asf.service_id = $serviceId
                  AND asf.is_active = 1
                  AND ap.verification_status = 'approved'
                  AND ap.is_listed = 1
                  AND s.isActive = 1
                LIMIT 1";
        $result = $conn->query($sql);
        if (!$result || $result->num_rows === 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $row['fee'] = floatval($row['fee']);
        $row['name'] = trim(($row['FirstName'] ?? '') . ' ' . ($row['LastName'] ?? ''));
        return $row;
    }

    public static function fullName($row)
    {
        return trim(($row['FirstName'] ?? '') . ' ' . ($row['LastName'] ?? ''));
    }

    public static function formatProfile($row, $fees = [])
    {
        $languages = $row['languages'] ?? '';
        $langList = [];
        if (is_string($languages) && $languages !== '') {
            $decoded = json_decode($languages, true);
            if (is_array($decoded)) {
                $langList = $decoded;
            } else {
                $langList = array_values(array_filter(array_map('trim', explode(',', $languages))));
            }
        }

        return [
            'id' => (int)$row['UserId'],
            'name' => self::fullName($row),
            'firstName' => $row['FirstName'] ?? '',
            'lastName' => $row['LastName'] ?? '',
            'email' => $row['Email'] ?? null,
            'mobile' => $row['Mobile'] ?? null,
            'role' => strtoupper(trim((string)($row['Role'] ?? ''))),
            'bio' => $row['bio'] ?? '',
            'yearsExperience' => (int)($row['years_experience'] ?? 0),
            'qualification' => $row['qualification'] ?? '',
            'licenseNumber' => $row['license_number'] ?? '',
            'city' => $row['city'] ?? '',
            'languages' => $langList,
            'photoUrl' => $row['photo_url'] ?? '',
            'verificationStatus' => $row['verification_status'] ?? 'pending',
            'isListed' => (int)($row['is_listed'] ?? 0) === 1,
            'rejectionReason' => $row['rejection_reason'] ?? null,
            'services' => $fees,
        ];
    }

    public static function formatFeeRow($row)
    {
        return [
            'serviceId' => (int)$row['service_id'],
            'serviceName' => $row['service_name'] ?? ($row['name'] ?? ''),
            'description' => $row['service_description'] ?? ($row['description'] ?? ''),
            'fee' => floatval($row['fee']),
            'isActive' => (int)($row['is_active'] ?? 1) === 1,
        ];
    }

    public static function getFees($conn, $userId, $activeOnly = false)
    {
        $userId = (int)$userId;
        $where = $activeOnly ? 'AND asf.is_active = 1' : '';
        $sql = "SELECT asf.service_id, asf.fee, asf.is_active, s.name AS service_name, s.description AS service_description
                FROM associate_service_fees asf
                INNER JOIN services s ON s.id = asf.service_id
                WHERE asf.user_id = $userId $where
                ORDER BY s.id ASC";
        $result = $conn->query($sql);
        $fees = [];
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $fees[] = self::formatFeeRow($row);
            }
        }
        return $fees;
    }

    public static function assignOnPaymentSuccess($conn, $userId, $payment)
    {
        $associateId = isset($payment['associate_id']) ? (int)$payment['associate_id'] : 0;
        if ($associateId <= 0) {
            return false;
        }

        $itrId = 0;
        if (!empty($payment['itr_id'])) {
            $itrId = (int)$payment['itr_id'];
        } elseif (!empty($payment['pan_number'])) {
            $pan = mysqli_real_escape_string($conn, $payment['pan_number']);
            $lookup = $conn->query("SELECT id FROM itr_detail WHERE userId = " . (int)$userId . " AND panNumber = '$pan' ORDER BY id DESC LIMIT 1");
            if ($lookup && $lookup->num_rows > 0) {
                $itrId = (int)$lookup->fetch_assoc()['id'];
            }
        }
        if ($itrId <= 0) {
            return false;
        }

        $existing = $conn->query("SELECT id FROM itr_assignments WHERE itr_id = $itrId AND is_active = 1 LIMIT 1");
        if ($existing && $existing->num_rows > 0) {
            return false;
        }

        $sql = "INSERT INTO itr_assignments (itr_id, assigned_to, assigned_by, assigned_at, is_active)
                VALUES ($itrId, $associateId, " . (int)$userId . ", NOW(), 1)";
        return (bool)$conn->query($sql);
    }
}
