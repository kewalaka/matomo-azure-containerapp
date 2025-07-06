<?php
// filepath: test_db_connection.php
echo "Testing Matomo database connection...\n";

// Get environment variables
$host = getenv('MATOMO_DATABASE_HOST');
$dbname = getenv('MATOMO_DATABASE_DBNAME');
$username = getenv('MATOMO_DATABASE_USERNAME');
$password = getenv('MATOMO_DATABASE_PASSWORD');

echo "Host: $host\n";
echo "Database: $dbname\n";
echo "Username: $username\n";
echo "Password: " . (empty($password) ? "NOT SET" : "SET") . "\n\n";

try {
    $dsn = "mysql:host=$host;dbname=$dbname;charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_TIMEOUT => 30
    ]);
    
    echo "✓ Database connection successful!\n";
    
    // Test basic query
    $stmt = $pdo->query("SELECT 1 as test");
    $result = $stmt->fetch();
    echo "✓ Query test successful: " . $result['test'] . "\n";
    
    // Check if Matomo tables exist
    $stmt = $pdo->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    echo "✓ Tables in database: " . count($tables) . "\n";
    
    if (count($tables) > 0) {
        echo "Sample tables:\n";
        foreach (array_slice($tables, 0, 5) as $table) {
            echo "  - $table\n";
        }
    }
    
} catch (PDOException $e) {
    echo "✗ Database connection failed: " . $e->getMessage() . "\n";
    echo "Error code: " . $e->getCode() . "\n";
    exit(1);
}

echo "\nDatabase connection test completed successfully!\n";
?>