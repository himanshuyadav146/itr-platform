<?php
/**
 * Migration Runner
 * Executes all package management migrations
 * 
 * Usage: php migrations/run_migrations.php
 */

// Include database configuration
require_once __DIR__ . '/../include/config.php';

// Color codes for terminal output
$GREEN = "\033[0;32m";
$RED = "\033[0;31m";
$YELLOW = "\033[1;33m";
$NC = "\033[0m"; // No Color

echo "\n";
echo "==========================================\n";
echo "   Package Management Migration Runner   \n";
echo "==========================================\n\n";

// Check database connection
if (!$conn) {
    echo "{$RED}✗ Database connection failed!{$NC}\n";
    exit(1);
}

echo "{$GREEN}✓ Database connection successful{$NC}\n\n";

// Array of migration files in order
$migrations = [
    'add_turnover_to_packages.sql',
    'add_package_id_to_personal_details.sql',
    'insert_frontend_packages.sql'
];

$successCount = 0;
$failCount = 0;

// Execute each migration
foreach ($migrations as $index => $migrationFile) {
    $migrationPath = __DIR__ . '/' . $migrationFile;
    
    echo ($index + 1) . ". Running: {$YELLOW}{$migrationFile}{$NC}\n";
    
    if (!file_exists($migrationPath)) {
        echo "   {$RED}✗ File not found: {$migrationPath}{$NC}\n\n";
        $failCount++;
        continue;
    }
    
    // Read SQL file
    $sql = file_get_contents($migrationPath);
    
    if ($sql === false) {
        echo "   {$RED}✗ Failed to read file{$NC}\n\n";
        $failCount++;
        continue;
    }
    
    // Remove comments and split by semicolon
    $statements = array_filter(
        array_map('trim', explode(';', $sql)),
        function($stmt) {
            // Remove empty statements and comments
            $stmt = trim($stmt);
            return !empty($stmt) && 
                   !preg_match('/^--/', $stmt) && 
                   !preg_match('/^\/\*/', $stmt);
        }
    );
    
    $stmtSuccess = 0;
    $stmtFail = 0;
    
    foreach ($statements as $statement) {
        // Skip SELECT verification queries and DESCRIBE queries
        if (preg_match('/^(SELECT|DESCRIBE|SHOW)/i', trim($statement))) {
            continue;
        }
        
        if ($conn->query($statement) === TRUE) {
            $stmtSuccess++;
        } else {
            // Check if error is about duplicate column/key (already exists)
            $error = $conn->error;
            if (strpos($error, 'Duplicate column') !== false || 
                strpos($error, 'Duplicate key') !== false ||
                strpos($error, 'already exists') !== false) {
                echo "   {$YELLOW}⚠ Already exists (skipping): " . substr($statement, 0, 50) . "...{$NC}\n";
                $stmtSuccess++;
            } else {
                echo "   {$RED}✗ Error: {$error}{$NC}\n";
                echo "   Statement: " . substr($statement, 0, 100) . "...\n";
                $stmtFail++;
            }
        }
    }
    
    if ($stmtFail === 0) {
        echo "   {$GREEN}✓ Migration completed successfully ({$stmtSuccess} statements){$NC}\n\n";
        $successCount++;
    } else {
        echo "   {$RED}✗ Migration completed with errors ({$stmtFail} failed){$NC}\n\n";
        $failCount++;
    }
}

// Summary
echo "==========================================\n";
echo "              Summary                     \n";
echo "==========================================\n";
echo "Total migrations: " . count($migrations) . "\n";
echo "{$GREEN}Successful: {$successCount}{$NC}\n";
if ($failCount > 0) {
    echo "{$RED}Failed: {$failCount}{$NC}\n";
}
echo "\n";

// Verify changes
echo "Verifying changes...\n\n";

// Check itr_packages table
$result = $conn->query("SHOW COLUMNS FROM itr_packages LIKE 'turnover'");
if ($result && $result->num_rows > 0) {
    echo "{$GREEN}✓ itr_packages.turnover column exists{$NC}\n";
} else {
    echo "{$RED}✗ itr_packages.turnover column missing{$NC}\n";
}

$result = $conn->query("SHOW COLUMNS FROM itr_packages LIKE 'icon'");
if ($result && $result->num_rows > 0) {
    echo "{$GREEN}✓ itr_packages.icon column exists{$NC}\n";
} else {
    echo "{$RED}✗ itr_packages.icon column missing{$NC}\n";
}

// Check personal_details table
$result = $conn->query("SHOW COLUMNS FROM personal_details LIKE 'package_id'");
if ($result && $result->num_rows > 0) {
    echo "{$GREEN}✓ personal_details.package_id column exists{$NC}\n";
} else {
    echo "{$RED}✗ personal_details.package_id column missing{$NC}\n";
}

// Check packages count
$result = $conn->query("SELECT COUNT(*) as count FROM itr_packages WHERE isActive = 1");
if ($result) {
    $row = $result->fetch_assoc();
    $count = $row['count'];
    echo "{$GREEN}✓ {$count} active packages in database{$NC}\n";
} else {
    echo "{$RED}✗ Failed to count packages{$NC}\n";
}

echo "\n";
echo "==========================================\n";
echo "   Migration process completed!          \n";
echo "==========================================\n\n";

$conn->close();

// Exit with appropriate code
exit($failCount > 0 ? 1 : 0);
?>
