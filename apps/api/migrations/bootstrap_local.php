<?php
/**
 * Local XAMPP bootstrap: create missing tables/columns, run marketplace
 * migration, and seed demo users. Safe to re-run.
 *
 * Usage (from htdocs/api or apps/api):
 *   php migrations/bootstrap_local.php
 */

$apiRoot = dirname(__DIR__);
$configPath = $apiRoot . '/include/config.php';

$servername = 'localhost';
$username = 'root';
$password = '';
$database = 'itr_services';

if (is_file($configPath)) {
    $configSrc = file_get_contents($configPath);
    foreach (['servername', 'username', 'password', 'database'] as $var) {
        if (preg_match('/\$' . $var . '\s*=\s*[\'"]([^\'"]*)[\'"]/', $configSrc, $m)) {
            $$var = $m[1];
        }
    }
}

mysqli_report(MYSQLI_REPORT_OFF);

$admin = @mysqli_connect($servername, $username, $password);
if (!$admin) {
    fwrite(STDERR, "MySQL connection failed: " . mysqli_connect_error() . "\n");
    fwrite(STDERR, "Start MySQL in XAMPP, then re-run this script.\n");
    exit(1);
}

$admin->set_charset('utf8mb4');
$dbEsc = $admin->real_escape_string($database);
$admin->query("CREATE DATABASE IF NOT EXISTS `$dbEsc` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
$admin->select_db($database);

$conn = $admin;
$ok = 0;
$skip = 0;
$fail = 0;

function column_exists(mysqli $conn, $table, $column)
{
    $table = $conn->real_escape_string($table);
    $column = $conn->real_escape_string($column);
    $res = $conn->query("SHOW COLUMNS FROM `$table` LIKE '$column'");
    return $res && $res->num_rows > 0;
}

function table_exists(mysqli $conn, $table)
{
    $table = $conn->real_escape_string($table);
    $res = $conn->query("SHOW TABLES LIKE '$table'");
    return $res && $res->num_rows > 0;
}

function ensure_column(mysqli $conn, $table, $column, $definition, &$ok, &$skip, &$fail)
{
    if (!table_exists($conn, $table)) {
        echo "  skip column $table.$column (table missing)\n";
        $skip++;
        return;
    }
    if (column_exists($conn, $table, $column)) {
        $skip++;
        return;
    }
    if ($conn->query("ALTER TABLE `$table` ADD COLUMN $definition")) {
        echo "  + $table.$column\n";
        $ok++;
    } else {
        echo "  ! $table.$column: {$conn->error}\n";
        $fail++;
    }
}

function run_statement(mysqli $conn, $sql, &$ok, &$skip, &$fail)
{
    $sql = trim($sql);
    if ($sql === '' || preg_match('/^(--|\/\*)/', $sql)) {
        return;
    }
    if (preg_match('/^(CREATE DATABASE|USE\s|CREATE USER|GRANT\s|FLUSH PRIVILEGES)/i', $sql)) {
        $skip++;
        return;
    }
    if (preg_match('/^(SELECT|DESCRIBE|SHOW)\s/i', $sql)) {
        return;
    }
    if (preg_match('/INSERT\s+INTO\s+`?payment_additional_fees`?/i', $sql)) {
        $skip++;
        return;
    }
    if ($conn->query($sql) === true) {
        $ok++;
        return;
    }
    $error = $conn->error;
    if (
        stripos($error, 'Duplicate') !== false ||
        stripos($error, 'already exists') !== false ||
        stripos($error, 'Duplicate column') !== false ||
        stripos($error, 'Duplicate key') !== false ||
        stripos($error, 'check that column/key exists') !== false
    ) {
        $skip++;
        return;
    }
    echo "  ! SQL error: $error\n";
    echo "    " . substr(preg_replace('/\s+/', ' ', $sql), 0, 140) . "\n";
    $fail++;
}

function run_sql_file(mysqli $conn, $path, &$ok, &$skip, &$fail)
{
    if (!is_file($path)) {
        echo "  missing file: $path\n";
        $fail++;
        return;
    }
    echo "Running " . basename($path) . "\n";
    $sql = file_get_contents($path);
    $sql = preg_replace('/\/\*.*?\*\//s', '', $sql);
    $parts = preg_split('/;\s*[\r\n]+/', $sql);
    foreach ($parts as $stmt) {
        $lines = [];
        foreach (preg_split('/\R/', $stmt) as $line) {
            $trim = ltrim($line);
            if ($trim === '' || strpos($trim, '--') === 0) {
                continue;
            }
            $lines[] = $line;
        }
        run_statement($conn, implode("\n", $lines), $ok, $skip, $fail);
    }
}

$files = [
    $apiRoot . '/setup_database.sql',
    $apiRoot . '/setup_payment_table.sql',
    $apiRoot . '/migrations/add_turnover_to_packages.sql',
    $apiRoot . '/migrations/add_package_id_to_personal_details.sql',
    $apiRoot . '/migrations/insert_frontend_packages.sql',
    $apiRoot . '/migrations/add_associate_marketplace.sql',
];

foreach ($files as $file) {
    run_sql_file($conn, $file, $ok, $skip, $fail);
}

echo "Ensuring live-compatible columns...\n";

$hasRoleCol = column_exists($conn, 'users', 'Role') || column_exists($conn, 'users', 'role');
if (!$hasRoleCol) {
    ensure_column($conn, 'users', 'Role', "`Role` varchar(50) DEFAULT 'CLIENT' AFTER `Password`", $ok, $skip, $fail);
}
ensure_column($conn, 'users', 'IsActive', "`IsActive` tinyint(1) DEFAULT 1 AFTER `Password`", $ok, $skip, $fail);

if (!table_exists($conn, 'itr_assignments')) {
    $created = $conn->query("
        CREATE TABLE `itr_assignments` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `itr_id` int(11) NOT NULL,
          `assigned_to` int(11) DEFAULT NULL,
          `assigned_by` int(11) DEFAULT NULL,
          `assigned_at` datetime DEFAULT CURRENT_TIMESTAMP,
          `is_active` tinyint(1) DEFAULT 1,
          `order_id` varchar(100) DEFAULT NULL,
          `user_id` int(11) DEFAULT NULL,
          `status` varchar(50) DEFAULT 'assigned',
          `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
          `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `idx_itr_id` (`itr_id`),
          KEY `idx_assigned_to` (`assigned_to`),
          KEY `idx_is_active` (`is_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    if ($created) {
        echo "  + itr_assignments (assigned_to schema)\n";
        $ok++;
    } else {
        echo "  ! itr_assignments: {$conn->error}\n";
        $fail++;
    }
} else {
    ensure_column($conn, 'itr_assignments', 'assigned_to', "`assigned_to` int(11) DEFAULT NULL", $ok, $skip, $fail);
    ensure_column($conn, 'itr_assignments', 'assigned_by', "`assigned_by` int(11) DEFAULT NULL", $ok, $skip, $fail);
    ensure_column($conn, 'itr_assignments', 'assigned_at', "`assigned_at` datetime DEFAULT CURRENT_TIMESTAMP", $ok, $skip, $fail);
    ensure_column($conn, 'itr_assignments', 'is_active', "`is_active` tinyint(1) DEFAULT 1", $ok, $skip, $fail);
}

$roleCol = column_exists($conn, 'users', 'Role') ? 'Role' : (column_exists($conn, 'users', 'role') ? 'role' : null);
if ($roleCol === null) {
    fwrite(STDERR, "users table has no Role column after bootstrap.\n");
    exit(1);
}

function upsert_user(mysqli $conn, $roleCol, $first, $last, $email, $mobile, $password, $role)
{
    $emailEsc = $conn->real_escape_string($email);
    $firstEsc = $conn->real_escape_string($first);
    $lastEsc = $conn->real_escape_string($last);
    $mobileEsc = $conn->real_escape_string($mobile);
    $passwordEsc = $conn->real_escape_string($password);
    $roleEsc = $conn->real_escape_string($role);

    $existing = $conn->query("SELECT UserId FROM users WHERE LOWER(TRIM(Email)) = LOWER(TRIM('$emailEsc')) LIMIT 1");
    if ($existing && $existing->num_rows > 0) {
        $id = (int)$existing->fetch_assoc()['UserId'];
        $setActive = column_exists($conn, 'users', 'IsActive') ? ', IsActive = 1' : '';
        $conn->query("UPDATE users SET `$roleCol` = '$roleEsc', Password = '$passwordEsc'$setActive WHERE UserId = $id");
        return $id;
    }

    $hasIsActive = column_exists($conn, 'users', 'IsActive');
    $cols = "FirstName, LastName, Email, Mobile, Password, `$roleCol`, Platform, Version";
    $vals = "'$firstEsc', '$lastEsc', '$emailEsc', '$mobileEsc', '$passwordEsc', '$roleEsc', 'web', '1.0'";
    if ($hasIsActive) {
        $cols .= ", IsActive";
        $vals .= ", 1";
    }
    $conn->query("INSERT INTO users ($cols) VALUES ($vals)");
    return (int)$conn->insert_id;
}

echo "Seeding local demo users...\n";

$adminId = upsert_user($conn, $roleCol, 'Local', 'Admin', 'admin@example.com', '9999999999', 'password123', 'ADMIN');
$clientId = upsert_user($conn, $roleCol, 'Local', 'Client', 'client@example.com', '8888888888', 'password123', 'CLIENT');
$priyaId = upsert_user($conn, $roleCol, 'Priya', 'Sharma', 'priya.ca@example.com', '9876500001', 'password123', 'CA');
$rahulId = upsert_user($conn, $roleCol, 'Rahul', 'Mehta', 'rahul.ca@example.com', '9876500002', 'password123', 'CA');

echo "  admin user id=$adminId\n";
echo "  client user id=$clientId\n";
echo "  priya user id=$priyaId\n";
echo "  rahul user id=$rahulId\n";

if (table_exists($conn, 'associate_profiles')) {
    $profiles = [
        [$priyaId, 'CA', 'ICA12345', '27AAAAA0000A1Z5', 'ABCDE1234F', 'Mumbai', 'Maharashtra', 'ICAI member focusing on salaried and capital-gains filings.', 8, 'pending'],
        [$rahulId, 'CA', 'ICA67890', '27BBBBB0000B1Z5', 'XYZAB1234C', 'Pune', 'Maharashtra', 'Tax expert for ITR-2 and notice handling.', 12, 'approved'],
    ];
    foreach ($profiles as $p) {
        [$uid, $role, $icai, $gstin, $pan, $city, $state, $bio, $years, $status] = $p;
        $approvedAt = $status === 'approved' ? 'NOW()' : 'NULL';
        $approvedBy = $status === 'approved' ? (int)$adminId : 'NULL';
        $sql = "INSERT INTO associate_profiles
                    (user_id, role, icai_membership_no, gstin, pan, city, state, bio, years_experience, approval_status, approved_by, approved_at)
                VALUES
                    ($uid, '$role', '$icai', '$gstin', '$pan', '$city', '$state', '" . $conn->real_escape_string($bio) . "', $years, '$status', $approvedBy, $approvedAt)
                ON DUPLICATE KEY UPDATE
                    role = VALUES(role),
                    icai_membership_no = VALUES(icai_membership_no),
                    gstin = VALUES(gstin),
                    pan = VALUES(pan),
                    city = VALUES(city),
                    state = VALUES(state),
                    bio = VALUES(bio),
                    years_experience = VALUES(years_experience),
                    approval_status = VALUES(approval_status)";
        if (!$conn->query($sql)) {
            echo "  ! associate_profiles uid=$uid: {$conn->error}\n";
            $fail++;
        } else {
            $ok++;
        }
    }
}

$itrFilingId = 0;
if (table_exists($conn, 'services')) {
    $svc = $conn->query("SELECT id FROM services WHERE Name = 'ITR Filing' LIMIT 1");
    if ($svc && $svc->num_rows > 0) {
        $itrFilingId = (int)$svc->fetch_assoc()['id'];
    }
    $notice = $conn->query("SELECT id FROM services WHERE Name = 'Notice Handling' LIMIT 1");
    $noticeId = ($notice && $notice->num_rows > 0) ? (int)$notice->fetch_assoc()['id'] : 0;

    if (table_exists($conn, 'associate_service_fees') && $itrFilingId) {
        $fees = [
            [$priyaId, $itrFilingId, '2499.00'],
            [$rahulId, $itrFilingId, '1999.00'],
        ];
        if ($noticeId) {
            $fees[] = [$rahulId, $noticeId, '3999.00'];
        }
        foreach ($fees as $fee) {
            [$aid, $sid, $amount] = $fee;
            $sql = "INSERT INTO associate_service_fees (associate_id, service_id, listed_fee, is_active)
                    VALUES ($aid, $sid, $amount, 1)
                    ON DUPLICATE KEY UPDATE listed_fee = VALUES(listed_fee), is_active = 1";
            if (!$conn->query($sql)) {
                echo "  ! associate_service_fees: {$conn->error}\n";
                $fail++;
            } else {
                $ok++;
            }
        }
    }
}

if (table_exists($conn, 'payment_additional_fees')) {
    $count = $conn->query("SELECT COUNT(*) AS c FROM payment_additional_fees");
    $row = $count ? $count->fetch_assoc() : ['c' => 1];
    if ((int)$row['c'] === 0) {
        $conn->query("INSERT INTO payment_additional_fees (fee_name, fee_amount, display_order, is_active) VALUES
            ('E-Filing Fee', 199.00, 1, 1),
            ('E-Verification Fee', 99.00, 2, 1)");
        $ok++;
    }
}

echo "\nBootstrap summary: ok=$ok skip=$skip fail=$fail\n";
echo "API: http://localhost/api/test_connection.php\n";
echo "Admin login: admin@example.com / password123\n";
echo "Client login: client@example.com / password123\n";
echo "Pending associate: priya.ca@example.com / password123\n";
echo "Approved associate: rahul.ca@example.com / password123\n";

$conn->close();
exit($fail > 0 ? 1 : 0);
