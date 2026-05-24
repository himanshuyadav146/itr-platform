<?php
// Test endpoint to verify token
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

require '../include/config.php';
require '../phpjwt/Token.php';

// Extract token from Authorization header
$token = '';
$headers = getallheaders();

if (isset($headers['Authorization'])) {
    $authcode = trim($headers['Authorization']);
    $token = str_replace("Bearer ", "", $authcode);
} elseif (function_exists('apache_request_headers')) {
    $apacheHeaders = apache_request_headers();
    if (isset($apacheHeaders['Authorization'])) {
        $authcode = trim($apacheHeaders['Authorization']);
        $token = str_replace("Bearer ", "", $authcode);
    }
}

$response = [
    "token_provided" => !empty($token),
    "token_length" => strlen($token),
    "headers_received" => array_keys($headers ? $headers : []),
    "authorization_header" => isset($headers['Authorization']) ? "Present" : "Missing"
];

if (!empty($token)) {
    // Verify token
    $decoded = Token::Verify($token, $key);
    
    if ($decoded === false) {
        $response["status"] = "error";
        $response["message"] = "Token is invalid or expired";
        $response["token_valid"] = false;
        
        // Try to decode to see what's wrong
        $tokenParts = explode('.', $token);
        $response["token_parts"] = count($tokenParts);
        if (count($tokenParts) === 3) {
            try {
                $headers_decoded = json_decode(base64_decode($tokenParts[0]), true);
                $payload_decoded = json_decode(base64_decode($tokenParts[1]), true);
                $response["token_headers"] = $headers_decoded;
                $response["token_payload"] = $payload_decoded;
                
                if (isset($headers_decoded['expire'])) {
                    $response["token_expired"] = $headers_decoded['expire'] < time();
                    $response["token_expires_at"] = date('Y-m-d H:i:s', $headers_decoded['expire']);
                    $response["current_time"] = date('Y-m-d H:i:s', time());
                }
            } catch (Exception $e) {
                $response["decode_error"] = $e->getMessage();
            }
        }
    } else {
        $response["status"] = "success";
        $response["message"] = "Token is valid";
        $response["token_valid"] = true;
        $response["token_payload"] = $decoded;
    }
} else {
    $response["status"] = "error";
    $response["message"] = "No token provided";
    $response["token_valid"] = false;
    $response["instructions"] = "Send token in Authorization header: Bearer YOUR_TOKEN";
}

echo json_encode($response, JSON_PRETTY_PRINT);
?>

