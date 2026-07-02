<?php
// Set headers for CORS and JSON response
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, x-api-key");

// --- Configuration ---
// Setup your Database connection details here
$db_host = "localhost";
$db_name = "koreakh1_fwuapi"; // replace with your DB name
$db_user = "rootkoreakh1_fwu";         // replace with your DB user
$db_pass = "budhalokesh123";             // replace with your DB password

// Set your secure API key here (This should match what you send from Flutter)
$secure_api_key = "my-super-secret-flutter-api-key";

// Allow preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Ensure the request method is POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(["success" => false, "error" => "Method not allowed"]);
    exit();
}

// Get headers
$headers = getallheaders();
$api_key = isset($headers['x-api-key']) ? $headers['x-api-key'] : '';

// Authenticate API key
if ($api_key !== $secure_api_key) {
    http_response_code(401);
    echo json_encode(["success" => false, "error" => "Unauthorized: Invalid API Key"]);
    exit();
}

// DB Connection (using PDO for security against SQL injection)
try {
    $dsn = "mysql:host=" . $db_host . ";dbname=" . $db_name . ";charset=utf8mb4";
    $pdo = new PDO($dsn, $db_user, $db_pass);
    // Set PDO error mode to exception
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "error" => "Database connection failed"]);
    exit();
}

// Auto-create table if it doesn't exist
try {
    $createTableQuery = "CREATE TABLE IF NOT EXISTS student_contacts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        student_id VARCHAR(50) NOT NULL UNIQUE,
        email VARCHAR(100) UNIQUE,
        phone VARCHAR(20),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )";
    $pdo->exec($createTableQuery);
} catch (PDOException $e) {
    // Ignore error if we don't have CREATE privileges, assume table exists
}

// Get raw POST data
$data = json_decode(file_get_contents("php://input"));

// Validate input
if (empty($data->student_id)) {
    http_response_code(400);
    echo json_encode(["success" => false, "error" => "Student ID is required"]);
    exit();
}

$student_id = strip_tags(trim($data->student_id));
$email = !empty($data->email) ? filter_var(trim($data->email), FILTER_SANITIZE_EMAIL) : null;
$phone = !empty($data->phone) ? strip_tags(trim($data->phone)) : null;

// Validate Email conditionally
if ($email !== null && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(["success" => false, "error" => "Invalid email format"]);
    exit();
}

try {
    // Check if the student_id already exists to Update, otherwise Insert
    // We use COALESCE so if phone or email is null, it doesn't overwrite the existing value!
    $query = "INSERT INTO student_contacts (student_id, email, phone) 
              VALUES (:student_id, :email, :phone)
              ON DUPLICATE KEY UPDATE 
              email = COALESCE(:email, email), phone = COALESCE(:phone, phone)";

    $stmt = $pdo->prepare($query);

    // Bind parameters safely
    $stmt->bindParam(':student_id', $student_id);
    $stmt->bindParam(':email', $email);
    $stmt->bindParam(':phone', $phone);

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Contact information saved successfully"]);
    } else {
        http_response_code(500);
        echo json_encode(["success" => false, "error" => "Failed to save contact information"]);
    }
} catch (PDOException $e) {
    http_response_code(500);
    // Duplicate entry handling (e.g. email already exists for another user)
    if ($e->errorInfo[1] == 1062) {
        echo json_encode(["success" => false, "error" => "Email already exists in the system"]);
    } else {
        echo json_encode(["success" => false, "error" => "Database error: " . $e->getMessage()]);
    }
}
?>