<?php
/**
 * Admin associate approvals.
 * GET  /admin/associates.php                 list (status filter)
 * GET  /admin/associates.php?id=             detail + fees
 * POST /admin/associates.php                 { action: approve|reject|unlist, userId, reason? }
 */
require_once __DIR__ . '/../include/config.php';
require_once __DIR__ . '/../phpjwt/Token.php';
require_once __DIR__ . '/../include/AssociateHelper.php';

AssociateHelper::sendCors('GET, POST, OPTIONS');

$decoded = AssociateHelper::requireAuth($key);
AssociateHelper::requireAdmin($conn, $decoded);

if (!AssociateHelper::tableExists($conn, 'associate_profiles')) {
    AssociateHelper::json(500, 'error', ['message' => 'associate_profiles table is missing. Run add_associate_marketplace.sql']);
}

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id > 0) {
        $row = AssociateHelper::getProfileRow($conn, $id);
        if (!$row) {
            AssociateHelper::json(404, 'error', ['message' => 'Associate not found']);
        }
        $fees = AssociateHelper::getServiceFees($conn, $id, false);
        AssociateHelper::json(200, 'success', [
            'associate' => AssociateHelper::formatAssociate($row, $fees),
        ]);
    }

    $status = strtolower(trim($_GET['status'] ?? 'all'));
    $search = trim($_GET['search'] ?? '');
    $page = max(1, (int)($_GET['page'] ?? 1));
    $limit = max(1, min(200, (int)($_GET['limit'] ?? 50)));
    $offset = ($page - 1) * $limit;

    $where = '1=1';
    if (in_array($status, ['pending', 'approved', 'rejected', 'unlisted'], true)) {
        $statusEsc = mysqli_real_escape_string($conn, $status);
        $where .= " AND p.approval_status = '$statusEsc'";
    }
    if ($search !== '') {
        $q = mysqli_real_escape_string($conn, $search);
        $where .= " AND (u.FirstName LIKE '%$q%' OR u.LastName LIKE '%$q%' OR u.Email LIKE '%$q%' OR p.city LIKE '%$q%' OR p.icai_membership_no LIKE '%$q%')";
    }

    $countRes = $conn->query("SELECT COUNT(*) AS total
                              FROM associate_profiles p
                              INNER JOIN users u ON u.UserId = p.user_id
                              WHERE $where");
    $total = ($countRes && $countRes->num_rows) ? (int)$countRes->fetch_assoc()['total'] : 0;

    $sql = "SELECT p.*, u.FirstName, u.MiddleName, u.LastName, u.Email, u.Mobile, u.CreatedAt AS registered_at
            FROM associate_profiles p
            INNER JOIN users u ON u.UserId = p.user_id
            WHERE $where
            ORDER BY
              CASE p.approval_status
                WHEN 'pending' THEN 0
                WHEN 'approved' THEN 1
                WHEN 'rejected' THEN 2
                ELSE 3
              END,
              p.created_at DESC
            LIMIT $limit OFFSET $offset";
    $result = $conn->query($sql);
    $items = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $items[] = AssociateHelper::formatAssociate($row, []);
        }
    }

    $counts = ['pending' => 0, 'approved' => 0, 'rejected' => 0, 'unlisted' => 0];
    $countAll = $conn->query("SELECT approval_status, COUNT(*) AS c FROM associate_profiles GROUP BY approval_status");
    if ($countAll) {
        while ($c = $countAll->fetch_assoc()) {
            $key = strtolower($c['approval_status']);
            if (isset($counts[$key])) {
                $counts[$key] = (int)$c['c'];
            }
        }
    }

    AssociateHelper::json(200, 'success', [
        'associates' => $items,
        'kpis' => $counts,
        'pagination' => [
            'page' => $page,
            'limit' => $limit,
            'total' => $total,
            'totalPages' => $limit > 0 ? (int)ceil($total / $limit) : 1,
        ],
    ]);
}

if ($method === 'POST') {
    $data = AssociateHelper::readJson();
    $action = strtolower(trim($data['action'] ?? ''));
    $userId = (int)($data['userId'] ?? $data['id'] ?? 0);
    $reason = trim($data['reason'] ?? $data['rejection_reason'] ?? '');

    if ($userId <= 0 || !in_array($action, ['approve', 'reject', 'unlist'], true)) {
        AssociateHelper::json(400, 'error', ['message' => 'action (approve|reject|unlist) and userId are required']);
    }

    $row = AssociateHelper::getProfileRow($conn, $userId);
    if (!$row) {
        AssociateHelper::json(404, 'error', ['message' => 'Associate profile not found']);
    }

    $adminId = (int)$decoded['UserId'];
    if ($action === 'approve') {
        $sql = "UPDATE associate_profiles
                SET approval_status = 'approved',
                    rejection_reason = NULL,
                    approved_by = $adminId,
                    approved_at = NOW(),
                    updated_at = NOW()
                WHERE user_id = $userId";
        $message = 'Associate approved and listed for client booking';
    } elseif ($action === 'reject') {
        if ($reason === '') {
            AssociateHelper::json(400, 'error', ['message' => 'reason is required to reject']);
        }
        $reasonEsc = mysqli_real_escape_string($conn, $reason);
        $sql = "UPDATE associate_profiles
                SET approval_status = 'rejected',
                    rejection_reason = '$reasonEsc',
                    approved_by = $adminId,
                    approved_at = NULL,
                    updated_at = NOW()
                WHERE user_id = $userId";
        $message = 'Associate rejected';
    } else {
        $sql = "UPDATE associate_profiles
                SET approval_status = 'unlisted',
                    updated_at = NOW()
                WHERE user_id = $userId";
        $message = 'Associate unlisted from the marketplace';
    }

    if (!$conn->query($sql)) {
        AssociateHelper::json(500, 'error', ['message' => 'Failed to update associate: ' . $conn->error]);
    }

    $updated = AssociateHelper::getProfileRow($conn, $userId);
    AssociateHelper::json(200, 'success', [
        'message' => $message,
        'associate' => AssociateHelper::formatAssociate($updated, AssociateHelper::getServiceFees($conn, $userId, false)),
    ]);
}

AssociateHelper::json(405, 'error', ['message' => 'Method not allowed']);
