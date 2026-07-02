<?php
// Set headers for CORS and JSON response
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, x-api-key");

// --- Configuration ---
$db_host = "127.0.0.1";
$db_name = "koreakh1_fwuapi"; // replace with your DB name
$db_user = "koreakh1_fwu";         // replace with your DB user
$db_pass = "budhalokesh1234";

$secure_api_key = "my-super-secret-flutter-api-key";

// Allow preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$headers = getallheaders();
$api_key = isset($headers['x-api-key']) ? $headers['x-api-key'] : '';

if ($api_key !== $secure_api_key) {
    http_response_code(401);
    echo json_encode(["success" => false, "error" => "Unauthorized: Invalid API Key"]);
    exit();
}

try {
    $dsn = "mysql:host=" . $db_host . ";dbname=" . $db_name . ";charset=utf8mb4";
    $pdo = new PDO($dsn, $db_user, $db_pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "error" => "Database connection failed"]);
    exit();
}

// Get student_id from GET param or POST body
$student_id = isset($_GET['student_id']) ? $_GET['student_id'] : null;

if (!$student_id) {
    $data = json_decode(file_get_contents("php://input"));
    $student_id = isset($data->student_id) ? $data->student_id : null;
}

if (empty($student_id)) {
    http_response_code(400);
    echo json_encode(["success" => false, "error" => "Student Registration Number is required"]);
    exit();
}

try {
    $stmt = $pdo->prepare("SELECT email FROM student_contacts WHERE student_id = :student_id LIMIT 1");
    $stmt->bindParam(':student_id', $student_id);
    $stmt->execute();

    if ($stmt->rowCount() > 0) {
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (empty($row['email'])) {
            echo json_encode(["success" => false, "error" => "No email address linked to this student."]);
        } else {
            echo json_encode(["success" => true, "email" => $row['email']]);
        }
    } else {
        http_response_code(404);
        echo json_encode(["success" => false, "error" => "Registration number not found in our records."]);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "error" => "Database error"]);
}
?>