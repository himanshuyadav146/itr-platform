<?php
header("Content-Type: text/plain");
require 'include/config.php';

echo "=== DATABASE CONNECTION TEST ===\n\n";

if ($conn) {
    echo "✓ Connected to database: $database\n\n";
    
    $result = $conn->query("SELECT COUNT(*) as count FROM itr_packages");
    if ($result) {
        $row = $result->fetch_assoc();
        echo "✓ Total packages in itr_packages: " . $row['count'] . "\n\n";
    } else {
        echo "✗ Error querying itr_packages: " . $conn->error . "\n\n";
    }
    
    $result = $conn->query("SELECT id, packagename, isActive FROM itr_packages LIMIT 5");
    if ($result) {
        echo "First 5 packages:\n";
        while ($row = $result->fetch_assoc()) {
            echo "  - ID {$row['id']}: {$row['packagename']} (isActive: {$row['isActive']})\n";
        }
    }
} else {
    echo "✗ Connection failed: " . mysqli_connect_error() . "\n";
}
?>
