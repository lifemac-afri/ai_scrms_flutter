<?php
define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
define('DB_USER', getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('DB_PASS') ?: '');
define('DB_NAME', getenv('DB_NAME') ?: 'ai_scrms');


// Check for custom session header (bypasses Web Cookie limits)
$headers = getallheaders();
$sessId = $headers['X-Session-Id'] ?? $_SERVER['HTTP_X_SESSION_ID'] ?? '';
if ($sessId) {
    session_id($sessId);
}

// Start session safely
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

function getDB() {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => 'DB connection failed: ' . $e->getMessage()]);
            exit;
        }
    }
    return $pdo;
}

function isLoggedIn() {
    return !empty($_SESSION['user_id']);
}

function requireLogin() {
    if (!isLoggedIn()) {
        http_response_code(401);
        echo json_encode(['error' => 'Not authenticated']);
        exit;
    }
}

function hasRole() {
    $roles = func_get_args();
    return in_array($_SESSION['role'] ?? '', $roles);
}

function jsonOut($data, $code = 200) {
    http_response_code($code);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
}

function auditLog($eventType, $targetEntity, $targetId, $desc) {
    try {
        $db = getDB();
        $prev = $db->query("SELECT event_hash FROM audit_ledger ORDER BY log_id DESC LIMIT 1")->fetchColumn();
        $prev = $prev ?: str_repeat('0', 64);
        $actor = $_SESSION['user_id'] ?? 'system';
        $ts = date('Y-m-d H:i:s');
        $hash = hash('sha256', $eventType . $actor . $targetEntity . $targetId . $desc . $ts . $prev);
        $db->prepare("INSERT INTO audit_ledger (event_type,actor_id,target_entity,target_id,event_description,event_hash,event_timestamp) VALUES (?,?,?,?,?,?,?)")
           ->execute([$eventType, $actor, $targetEntity, $targetId, $desc, $hash, $ts]);
    } catch (Exception $e) {}
}

function notify($userId, $type, $message) {
    try {
        getDB()->prepare("INSERT INTO notifications (recipient_id,notification_type,message_body) VALUES (?,?,?)")
               ->execute([$userId, $type, $message]);
    } catch (Exception $e) {}
}
