<?php
require_once __DIR__ . '/../php/config.php';

header('Content-Type: application/json');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Cookie, X-Session-Id');
header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

// ── Parse input — supports both JSON body and GET params ──
$rawBody = file_get_contents('php://input');
$body = ($rawBody && $_SERVER['REQUEST_METHOD'] === 'POST') ? (json_decode($rawBody, true) ?? []) : [];

// Action: GET params first, then JSON body (FIX: was missing body check)
$action = $_GET['action'] ?? $body['action'] ?? '';
$data   = array_merge($_GET, $body); // unified data bag

try {
    switch ($action) {

        // ════════════════════════════════════════
        // AUTH
        // ════════════════════════════════════════
        case 'login':
            $email = trim($data['email'] ?? '');
            $pass  = $data['password'] ?? '';
            if (!$email || !$pass) jsonOut(['error' => 'Email and password are required'], 400);

            $db   = getDB();
            $stmt = $db->prepare("SELECT * FROM users WHERE email = ? AND account_status = 'active' LIMIT 1");
            $stmt->execute([$email]);
            $user = $stmt->fetch();

            if ($user && password_verify($pass, $user['password_hash'])) {
                $_SESSION['user_id'] = $user['user_id'];
                $_SESSION['role']    = $user['role'];
                $_SESSION['name']    = $user['full_name'];
                $db->prepare("UPDATE users SET last_login = NOW() WHERE user_id = ?")->execute([$user['user_id']]);
                auditLog('LOGIN', 'users', $user['user_id'], "User {$user['full_name']} logged in");
                jsonOut([
                    'success'  => true,
                    'role'     => $user['role'],
                    'name'     => $user['full_name'],
                    'user_id'  => $user['user_id'],
                    'no_show_count' => $user['no_show_count'],
                    'session_id' => session_id()
                ]);
            }
            jsonOut(['error' => 'Invalid email or password'], 401);

        case 'logout':
            if (isLoggedIn()) auditLog('LOGOUT', 'users', $_SESSION['user_id'], 'User logged out');
            session_destroy();
            jsonOut(['success' => true]);

        case 'me':
            if (!isLoggedIn()) jsonOut(['error' => 'not_logged_in'], 401);
            $stmt = getDB()->prepare("SELECT user_id,full_name,email,role,department,no_show_count,account_status FROM users WHERE user_id = ?");
            $stmt->execute([$_SESSION['user_id']]);
            $user = $stmt->fetch();
            if (!$user) jsonOut(['error' => 'not_logged_in'], 401);
            $unread = getDB()->prepare("SELECT COUNT(*) FROM notifications WHERE recipient_id = ? AND is_read = 0");
            $unread->execute([$_SESSION['user_id']]);
            $user['unread'] = (int)$unread->fetchColumn();
            jsonOut($user);

        case 'register':
            $name  = trim($data['full_name'] ?? '');
            $email = trim($data['email'] ?? '');
            $pass  = $data['password'] ?? '';
            $role  = in_array($data['role'] ?? '', ['student','faculty']) ? $data['role'] : 'student';
            $dept  = trim($data['department'] ?? '');

            if (!$name || !$email || !$pass) jsonOut(['error' => 'All fields are required'], 400);
            if (strlen($pass) < 6) jsonOut(['error' => 'Password must be at least 6 characters'], 400);
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) jsonOut(['error' => 'Invalid email address'], 400);

            $hash = password_hash($pass, PASSWORD_BCRYPT);
            try {
                $db = getDB();
                $db->prepare("INSERT INTO users (full_name, email, password_hash, role, department) VALUES (?,?,?,?,?)")
                   ->execute([$name, $email, $hash, $role, $dept]);
                $uid = $db->lastInsertId();
                auditLog('REGISTER', 'users', $uid, "New user registered: $email");
                jsonOut(['success' => true]);
            } catch (PDOException $e) {
                if ($e->getCode() == 23000) jsonOut(['error' => 'That email is already registered'], 409);
                throw $e;
            }

        // ════════════════════════════════════════
        // RESOURCES
        // ════════════════════════════════════════
        case 'resources':
            requireLogin();
            $db    = getDB();
            $type  = $data['type'] ?? '';
            $date  = $data['date'] ?? date('Y-m-d');
            $start = $data['start'] ?? '00:00';
            $end   = $data['end'] ?? '23:59';
            $cap   = (int)($data['capacity'] ?? 0);

            $sql    = "SELECT r.*,
                (SELECT COUNT(*) FROM bookings b
                 WHERE b.resource_id = r.resource_id
                   AND b.booking_date = ?
                   AND b.booking_status IN ('confirmed','active')
                   AND NOT (b.end_time <= ? OR b.start_time >= ?)) AS conflict_count
                FROM resources r
                WHERE r.condition_status = 'available'";
            $params = [$date, $start, $end];
            if ($type) { $sql .= " AND r.resource_type = ?"; $params[] = $type; }
            if ($cap)  { $sql .= " AND r.capacity >= ?";    $params[] = $cap;  }
            $sql .= " ORDER BY r.resource_type, r.resource_name";

            $stmt = $db->prepare($sql);
            $stmt->execute($params);
            $rows = $stmt->fetchAll();
            foreach ($rows as &$r) {
                $r['features'] = json_decode($r['features'] ?? '{}', true) ?: [];
                $r['available'] = ($r['conflict_count'] == 0);
            }
            jsonOut($rows);

        case 'all_resources':
            requireLogin();
            if (!hasRole('facility_manager','super_admin')) jsonOut(['error'=>'Forbidden'],403);
            $stmt = getDB()->query("SELECT * FROM resources ORDER BY resource_type, resource_name");
            $rows = $stmt->fetchAll();
            foreach ($rows as &$r) $r['features'] = json_decode($r['features']??'{}',true) ?: [];
            jsonOut($rows);

        case 'add_resource':
            requireLogin();
            if (!hasRole('facility_manager','super_admin')) jsonOut(['error'=>'Forbidden'],403);
            $features = is_array($data['features']??null) ? json_encode($data['features']) : '{}';
            getDB()->prepare("INSERT INTO resources (resource_name,resource_type,building,floor,room_number,capacity,features) VALUES (?,?,?,?,?,?,?)")
                   ->execute([$data['resource_name'],$data['resource_type'],$data['building']??'',$data['floor']??'',$data['room_number']??'',(int)($data['capacity']??1),$features]);
            $id = getDB()->lastInsertId();
            auditLog('RESOURCE_ADDED','resources',$id,"Added: {$data['resource_name']}");
            jsonOut(['success'=>true,'resource_id'=>$id]);

        case 'update_resource_status':
            requireLogin();
            if (!hasRole('facility_manager','super_admin','maintenance')) jsonOut(['error'=>'Forbidden'],403);
            $allowed = ['available','under_maintenance','decommissioned'];
            $status  = $data['status'] ?? '';
            if (!in_array($status,$allowed)) jsonOut(['error'=>'Invalid status'],400);
            getDB()->prepare("UPDATE resources SET condition_status=? WHERE resource_id=?")->execute([$status,$data['resource_id']]);
            auditLog('RESOURCE_STATUS','resources',$data['resource_id'],"Status → $status");
            jsonOut(['success'=>true]);

        // ════════════════════════════════════════
        // BOOKINGS
        // ════════════════════════════════════════
        case 'book':
            requireLogin();
            $db  = getDB();
            $rid = (int)($data['resource_id'] ?? 0);
            $dt  = $data['booking_date'] ?? '';
            $st  = $data['start_time'] ?? '';
            $et  = $data['end_time'] ?? '';
            $pur = trim($data['purpose'] ?? '');
            if (!$rid || !$dt || !$st || !$et) jsonOut(['error'=>'Missing required fields'],400);
            if ($st >= $et) jsonOut(['error'=>'End time must be after start time'],400);

            // Check resource exists and is available
            $res = $db->prepare("SELECT * FROM resources WHERE resource_id=? AND condition_status='available'");
            $res->execute([$rid]);
            if (!$res->fetch()) jsonOut(['error'=>'Resource not found or unavailable'],404);

            // Conflict check
            $cf = $db->prepare("SELECT booking_id FROM bookings WHERE resource_id=? AND booking_date=? AND booking_status IN ('confirmed','active') AND NOT (end_time<=? OR start_time>=?)");
            $cf->execute([$rid,$dt,$st,$et]);
            if ($cf->fetch()) {
                // Auto-conflict resolution: add to waitlist with role-based priority
                $priority = match($_SESSION['role']??'') {
                    'super_admin'=>10, 'facility_manager'=>9, 'faculty'=>7, default=>5
                };
                $db->prepare("INSERT INTO waitlist (user_id,resource_id,requested_date,requested_start,requested_end,priority_score) VALUES (?,?,?,?,?,?)")
                   ->execute([$_SESSION['user_id'],$rid,$dt,$st,$et,$priority]);
                notify($_SESSION['user_id'],'waitlist_added',"Resource conflict detected. You've been added to the waitlist (priority: $priority/10). You'll be notified if a slot opens.");
                auditLog('CONFLICT_WAITLIST','bookings',$rid,"User {$_SESSION['user_id']} waitlisted for resource $rid on $dt");
                jsonOut(['success'=>false,'waitlisted'=>true,'message'=>'This slot is taken. You have been added to the waitlist — you\'ll be notified automatically if a slot opens.']);
            }

            $qrToken = bin2hex(random_bytes(16));
            $db->prepare("INSERT INTO bookings (user_id,resource_id,booking_date,start_time,end_time,purpose,booking_status,qr_code,confirmed_at) VALUES (?,?,?,?,?,?,'confirmed',?,NOW())")
               ->execute([$_SESSION['user_id'],$rid,$dt,$st,$et,$pur,$qrToken]);
            $bid = $db->lastInsertId();
            notify($_SESSION['user_id'],'booking_confirmed',"Booking #$bid confirmed for $dt $st–$et. Scan your QR code to check in when you arrive.");
            auditLog('BOOKING_CREATED','bookings',$bid,"Booking $bid by user {$_SESSION['user_id']} for resource $rid on $dt");
            jsonOut(['success'=>true,'booking_id'=>$bid,'qr_token'=>$qrToken]);

        case 'my_bookings':
            requireLogin();
            $db     = getDB();
            $status = $data['status'] ?? '';
            $sql    = "SELECT b.*, r.resource_name, r.building, r.room_number, r.resource_type
                       FROM bookings b JOIN resources r ON b.resource_id=r.resource_id
                       WHERE b.user_id=?";
            $params = [$_SESSION['user_id']];
            if ($status) { $sql .= " AND b.booking_status=?"; $params[]=$status; }
            $sql .= " ORDER BY b.booking_date DESC, b.start_time DESC LIMIT 50";
            $stmt = $db->prepare($sql); $stmt->execute($params);
            jsonOut($stmt->fetchAll());

        case 'all_bookings':
            requireLogin();
            if (!hasRole('facility_manager','super_admin')) jsonOut(['error'=>'Forbidden'],403);
            $stmt = getDB()->query("SELECT b.*, r.resource_name, r.building, r.room_number, u.full_name AS user_name, u.role AS user_role FROM bookings b JOIN resources r ON b.resource_id=r.resource_id JOIN users u ON b.user_id=u.user_id ORDER BY b.booking_date DESC, b.start_time DESC LIMIT 100");
            jsonOut($stmt->fetchAll());

        case 'cancel_booking':
            requireLogin();
            $bid = (int)($data['booking_id']??0);
            $db  = getDB();
            $stmt = $db->prepare("SELECT * FROM bookings WHERE booking_id=?"); $stmt->execute([$bid]);
            $bk = $stmt->fetch();
            if (!$bk) jsonOut(['error'=>'Booking not found'],404);
            if ($bk['user_id']!=$_SESSION['user_id'] && !hasRole('facility_manager','super_admin')) jsonOut(['error'=>'Forbidden'],403);
            if (!in_array($bk['booking_status'],['confirmed','pending'])) jsonOut(['error'=>'Cannot cancel this booking'],400);
            $db->prepare("UPDATE bookings SET booking_status='cancelled', cancelled_at=NOW() WHERE booking_id=?")->execute([$bid]);
            // Promote waitlist
            $wl = $db->prepare("SELECT * FROM waitlist WHERE resource_id=? AND requested_date=? AND status='waiting' AND requested_start=? ORDER BY priority_score DESC, queued_at ASC LIMIT 1");
            $wl->execute([$bk['resource_id'],$bk['booking_date'],$bk['start_time']]);
            $next = $wl->fetch();
            if ($next) {
                $db->prepare("UPDATE waitlist SET status='promoted' WHERE waitlist_id=?")->execute([$next['waitlist_id']]);
                notify($next['user_id'],'waitlist_promoted',"Great news! A slot opened for your waitlisted resource on {$bk['booking_date']} {$bk['start_time']}–{$bk['end_time']}. Go book it now!");
            }
            auditLog('BOOKING_CANCELLED','bookings',$bid,"Cancelled by user {$_SESSION['user_id']}");
            jsonOut(['success'=>true,'waitlist_promoted'=>!!$next]);

        case 'checkin':
            requireLogin();
            $token = trim($data['qr_token']??'');
            if (!$token) jsonOut(['error'=>'QR token is required'],400);
            $db   = getDB();
            $stmt = $db->prepare("SELECT b.*, r.resource_name FROM bookings b JOIN resources r ON b.resource_id=r.resource_id WHERE b.qr_code=? AND b.user_id=? AND b.booking_status='confirmed'");
            $stmt->execute([$token,$_SESSION['user_id']]);
            $bk = $stmt->fetch();
            if (!$bk) jsonOut(['error'=>'Invalid QR code or booking not found. Ensure you are checking in to your own confirmed booking.'],404);

            $bookingStart = strtotime($bk['booking_date'].' '.$bk['start_time']);
            $now = time();
            $graceSeconds = 15 * 60; // 15 minutes
            if ($now < $bookingStart - $graceSeconds) jsonOut(['error'=>'Too early! Check-in opens 15 minutes before your booking start time.'],400);
            if ($now > $bookingStart + $graceSeconds) jsonOut(['error'=>'Check-in window has expired (15 minutes after start time). This booking will be marked as a no-show.'],400);

            // Record check-in
            try {
                $db->prepare("INSERT INTO checkins (booking_id,user_id,checkin_timestamp) VALUES (?,?,NOW())")->execute([$bk['booking_id'],$_SESSION['user_id']]);
            } catch (PDOException $e) {
                jsonOut(['error'=>'Already checked in to this booking.'],409);
            }
            $db->prepare("UPDATE bookings SET booking_status='active' WHERE booking_id=?")->execute([$bk['booking_id']]);
            auditLog('CHECKIN','checkins',$bk['booking_id'],"User {$_SESSION['user_id']} checked in to {$bk['resource_name']}");
            jsonOut(['success'=>true,'resource'=>$bk['resource_name'],'message'=>"Welcome! You are checked in to {$bk['resource_name']}."]);

        // ════════════════════════════════════════
        // MAINTENANCE
        // ════════════════════════════════════════
        case 'report_fault':
            requireLogin();
            $db = getDB();
            $db->prepare("INSERT INTO maintenance_requests (resource_id,reported_by,fault_description,severity) VALUES (?,?,?,?)")
               ->execute([$data['resource_id'],$_SESSION['user_id'],$data['description']??'',$data['severity']??'medium']);
            $id = $db->lastInsertId();
            auditLog('FAULT_REPORTED','maintenance',$id,"Fault on resource {$data['resource_id']}");
            jsonOut(['success'=>true,'request_id'=>$id]);

        case 'maintenance_list':
            requireLogin();
            if (!hasRole('facility_manager','super_admin','maintenance')) jsonOut(['error'=>'Forbidden'],403);
            $stmt = getDB()->query("SELECT m.*, r.resource_name, u.full_name AS reporter FROM maintenance_requests m JOIN resources r ON m.resource_id=r.resource_id JOIN users u ON m.reported_by=u.user_id ORDER BY FIELD(m.severity,'critical','high','medium','low'), m.reported_at DESC");
            jsonOut($stmt->fetchAll());

        case 'resolve_maintenance':
            requireLogin();
            if (!hasRole('facility_manager','super_admin','maintenance')) jsonOut(['error'=>'Forbidden'],403);
            getDB()->prepare("UPDATE maintenance_requests SET request_status='resolved',resolved_at=NOW(),resolution_notes=? WHERE request_id=?")
                   ->execute([$data['notes']??'',$data['request_id']]);
            auditLog('MAINT_RESOLVED','maintenance',$data['request_id'],"Resolved");
            jsonOut(['success'=>true]);

        // ════════════════════════════════════════
        // ANALYTICS & AI
        // ════════════════════════════════════════
        case 'analytics':
            requireLogin();
            if (!hasRole('facility_manager','super_admin')) jsonOut(['error'=>'Forbidden'],403);
            $db = getDB();
            $s  = [];
            $s['total_bookings']      = (int)$db->query("SELECT COUNT(*) FROM bookings WHERE MONTH(booking_date)=MONTH(CURDATE()) AND YEAR(booking_date)=YEAR(CURDATE())")->fetchColumn();
            $s['no_shows']            = (int)$db->query("SELECT COUNT(*) FROM bookings WHERE booking_status='no_show'")->fetchColumn();
            $s['active_users']        = (int)$db->query("SELECT COUNT(*) FROM users WHERE account_status='active'")->fetchColumn();
            $s['total_resources']     = (int)$db->query("SELECT COUNT(*) FROM resources WHERE condition_status='available'")->fetchColumn();
            $s['pending_maintenance'] = (int)$db->query("SELECT COUNT(*) FROM maintenance_requests WHERE request_status IN('open','in_progress')")->fetchColumn();
            $s['waitlisted']          = (int)$db->query("SELECT COUNT(*) FROM waitlist WHERE status='waiting'")->fetchColumn();
            $s['by_type']  = $db->query("SELECT r.resource_type, COUNT(*) AS cnt FROM bookings b JOIN resources r ON b.resource_id=r.resource_id WHERE b.booking_date>=DATE_SUB(CURDATE(),INTERVAL 30 DAY) GROUP BY r.resource_type")->fetchAll();
            $s['trend']    = $db->query("SELECT DATE_FORMAT(booking_date,'%a') AS day_label, booking_date, COUNT(*) AS cnt FROM bookings WHERE booking_date>=DATE_SUB(CURDATE(),INTERVAL 7 DAY) GROUP BY booking_date ORDER BY booking_date")->fetchAll();
            $s['top_resources'] = $db->query("SELECT r.resource_name, COUNT(*) AS cnt FROM bookings b JOIN resources r ON b.resource_id=r.resource_id GROUP BY b.resource_id ORDER BY cnt DESC LIMIT 5")->fetchAll();
            jsonOut($s);

        case 'recommendations':
            requireLogin();
            $db  = getDB();
            $uid = $_SESSION['user_id'];
            // History-based recommendations
            $stmt = $db->prepare("SELECT r.*, COUNT(b.booking_id) AS booking_count, MAX(b.booking_date) AS last_booked FROM resources r JOIN bookings b ON b.resource_id=r.resource_id WHERE b.user_id=? AND r.condition_status='available' GROUP BY r.resource_id ORDER BY booking_count DESC, last_booked DESC LIMIT 4");
            $stmt->execute([$uid]);
            $recs = $stmt->fetchAll();
            // Fallback: popular
            if (empty($recs)) {
                $recs = $db->query("SELECT r.*, COUNT(b.booking_id) AS booking_count FROM resources r LEFT JOIN bookings b ON b.resource_id=r.resource_id WHERE r.condition_status='available' GROUP BY r.resource_id ORDER BY booking_count DESC LIMIT 4")->fetchAll();
            }
            foreach ($recs as &$r) $r['features'] = json_decode($r['features']??'{}',true) ?: [];
            jsonOut(['recommendations'=>$recs]);

        case 'demand_forecast':
            requireLogin();
            if (!hasRole('facility_manager','super_admin')) jsonOut(['error'=>'Forbidden'],403);
            $rows = getDB()->query("SELECT r.resource_name, r.resource_type, DAYNAME(b.booking_date) AS day_of_week, COUNT(*) AS demand_count FROM bookings b JOIN resources r ON b.resource_id=r.resource_id WHERE b.booking_date>=DATE_SUB(CURDATE(),INTERVAL 60 DAY) GROUP BY b.resource_id, DAYNAME(b.booking_date) ORDER BY demand_count DESC LIMIT 30")->fetchAll();
            jsonOut($rows);

        // ════════════════════════════════════════
        // NOTIFICATIONS
        // ════════════════════════════════════════
        case 'notifications':
            requireLogin();
            $stmt = getDB()->prepare("SELECT * FROM notifications WHERE recipient_id=? ORDER BY created_at DESC LIMIT 25");
            $stmt->execute([$_SESSION['user_id']]);
            jsonOut($stmt->fetchAll());

        case 'mark_read':
            requireLogin();
            getDB()->prepare("UPDATE notifications SET is_read=1 WHERE recipient_id=?")->execute([$_SESSION['user_id']]);
            jsonOut(['success'=>true]);

        // ════════════════════════════════════════
        // AUDIT
        // ════════════════════════════════════════
        case 'audit_log':
            requireLogin();
            if (!hasRole('super_admin','facility_manager')) jsonOut(['error'=>'Forbidden'],403);
            $rows = getDB()->query("SELECT l.*, u.full_name FROM audit_ledger l LEFT JOIN users u ON l.actor_id=u.user_id ORDER BY l.log_id DESC LIMIT 60")->fetchAll();
            jsonOut($rows);

        // ════════════════════════════════════════
        // USERS
        // ════════════════════════════════════════
        case 'users_list':
            requireLogin();
            if (!hasRole('super_admin','facility_manager')) jsonOut(['error'=>'Forbidden'],403);
            $rows = getDB()->query("SELECT user_id,full_name,email,role,department,no_show_count,account_status,created_at,last_login FROM users ORDER BY created_at DESC")->fetchAll();
            jsonOut($rows);

        case 'update_user_status':
            requireLogin();
            if (!hasRole('super_admin')) jsonOut(['error'=>'Forbidden'],403);
            $s = in_array($data['status']??'',['active','suspended','deactivated']) ? $data['status'] : 'active';
            getDB()->prepare("UPDATE users SET account_status=? WHERE user_id=?")->execute([$s,$data['user_id']]);
            auditLog('USER_STATUS','users',$data['user_id'],"Status → $s");
            jsonOut(['success'=>true]);

        // ════════════════════════════════════════
        // WAITLIST
        // ════════════════════════════════════════
        case 'my_waitlist':
            requireLogin();
            $stmt = getDB()->prepare("SELECT w.*, r.resource_name, r.building, r.resource_type FROM waitlist w JOIN resources r ON w.resource_id=r.resource_id WHERE w.user_id=? AND w.status='waiting' ORDER BY w.queued_at DESC");
            $stmt->execute([$_SESSION['user_id']]);
            jsonOut($stmt->fetchAll());

        default:
            jsonOut(['error'=>'Unknown action: '.$action],400);
    }
} catch (PDOException $e) {
    jsonOut(['error'=>'Database error: '.$e->getMessage()],500);
} catch (Exception $e) {
    jsonOut(['error'=>'Server error: '.$e->getMessage()],500);
}
