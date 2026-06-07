-- ================================================================
-- AI-SCRMS Database Setup
-- Password for ALL demo accounts: password
-- ================================================================

DROP DATABASE IF EXISTS ai_scrms;
CREATE DATABASE ai_scrms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ai_scrms;

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('super_admin','facility_manager','faculty','student','maintenance') NOT NULL DEFAULT 'student',
    department VARCHAR(100),
    phone VARCHAR(30),
    no_show_count INT DEFAULT 0,
    account_status ENUM('active','suspended','deactivated') DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME
) ENGINE=InnoDB;

CREATE TABLE resources (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    resource_name VARCHAR(150) NOT NULL,
    resource_type ENUM('classroom','laboratory','equipment','event_space','sports_facility','study_room') NOT NULL,
    building VARCHAR(100),
    floor VARCHAR(20),
    room_number VARCHAR(30),
    capacity INT DEFAULT 1,
    features JSON,
    condition_status ENUM('available','under_maintenance','decommissioned') DEFAULT 'available',
    image_url VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    resource_id INT NOT NULL,
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    purpose VARCHAR(255),
    booking_status ENUM('pending','confirmed','active','completed','cancelled','no_show') DEFAULT 'confirmed',
    qr_code VARCHAR(64),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    confirmed_at DATETIME,
    cancelled_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (resource_id) REFERENCES resources(resource_id)
) ENGINE=InnoDB;

CREATE TABLE checkins (
    checkin_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE,
    user_id INT NOT NULL,
    checkin_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

CREATE TABLE waitlist (
    waitlist_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    resource_id INT NOT NULL,
    requested_date DATE NOT NULL,
    requested_start TIME NOT NULL,
    requested_end TIME NOT NULL,
    priority_score INT DEFAULT 5,
    status ENUM('waiting','promoted','expired','cancelled') DEFAULT 'waiting',
    queued_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (resource_id) REFERENCES resources(resource_id)
) ENGINE=InnoDB;

CREATE TABLE maintenance_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    resource_id INT NOT NULL,
    reported_by INT NOT NULL,
    assigned_to INT,
    fault_description TEXT,
    severity ENUM('low','medium','high','critical') DEFAULT 'medium',
    request_status ENUM('open','in_progress','resolved','closed') DEFAULT 'open',
    is_predictive TINYINT(1) DEFAULT 0,
    reported_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME,
    resolution_notes TEXT,
    FOREIGN KEY (resource_id) REFERENCES resources(resource_id),
    FOREIGN KEY (reported_by) REFERENCES users(user_id)
) ENGINE=InnoDB;

CREATE TABLE audit_ledger (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(80) NOT NULL,
    actor_id VARCHAR(50),
    target_entity VARCHAR(80),
    target_id VARCHAR(50),
    event_description TEXT,
    event_hash VARCHAR(64),
    event_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    recipient_id INT NOT NULL,
    notification_type VARCHAR(80),
    message_body TEXT,
    is_read TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipient_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ================================================================
-- SEED DATA
-- All passwords = "password" (bcrypt hash generated below)
-- ================================================================

-- Generate password hash for "password" using PHP's password_hash
-- The hash below is: password_hash('password', PASSWORD_BCRYPT)
-- We use a stored procedure to generate it correctly at import time

DELIMITER $$
CREATE PROCEDURE seed_users()
BEGIN
    DECLARE ph VARCHAR(255);
    -- Insert a temp user to get PHP to hash, or we use a known valid hash
    -- Known valid bcrypt hash for 'password' with cost 10:
    SET ph = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';

    INSERT INTO users (full_name, email, password_hash, role, department) VALUES
    ('Super Admin',     'admin@campus.edu', ph, 'super_admin',      'Administration'),
    ('Dr. Kwame Asante','kwame@campus.edu', ph, 'faculty',           'Computer Science'),
    ('Ama Owusu',       'ama@campus.edu',   ph, 'student',           'Engineering'),
    ('Facility Manager','fm@campus.edu',    ph, 'facility_manager',  'Facilities'),
    ('Tech Support',    'tech@campus.edu',  ph, 'maintenance',       'Facilities'),
    ('Kofi Mensah',     'kofi@campus.edu',  ph, 'student',           'Business'),
    ('Dr. Abena Frimpong','abena@campus.edu',ph,'faculty',           'Mathematics');
END$$
DELIMITER ;
CALL seed_users();
DROP PROCEDURE seed_users;

-- Resources
INSERT INTO resources (resource_name, resource_type, building, floor, room_number, capacity, features, condition_status) VALUES
('Lecture Hall A1',   'classroom',       'Main Block',    '1st',    'A101', 120, '{"projector":true,"ac":true,"whiteboard":true,"microphone":true}', 'available'),
('Lecture Hall A2',   'classroom',       'Main Block',    '1st',    'A102', 80,  '{"projector":true,"ac":true,"whiteboard":true}',                  'available'),
('Lecture Hall B1',   'classroom',       'Science Block', 'Ground', 'B001', 60,  '{"projector":true,"whiteboard":true}',                            'available'),
('CS Laboratory 1',   'laboratory',      'Tech Block',    'Ground', 'T001', 40,  '{"computers":true,"ac":true,"projector":true}',                   'available'),
('CS Laboratory 2',   'laboratory',      'Tech Block',    'Ground', 'T002', 35,  '{"computers":true,"ac":true}',                                    'available'),
('Chemistry Lab',     'laboratory',      'Science Block', '2nd',    'S201', 30,  '{"fume_hood":true,"safety_equipment":true}',                      'under_maintenance'),
('Conference Room B1','event_space',     'Admin Block',   '2nd',    'B201', 20,  '{"projector":true,"ac":true,"video_conf":true}',                  'available'),
('Auditorium',        'event_space',     'Main Block',    'Ground', 'M001', 500, '{"stage":true,"pa_system":true,"ac":true,"lighting":true}',       'available'),
('Study Room 1',      'study_room',      'Library',       '1st',    'L101', 8,   '{"whiteboard":true,"wifi":true}',                                 'available'),
('Study Room 2',      'study_room',      'Library',       '1st',    'L102', 8,   '{"whiteboard":true,"wifi":true}',                                 'available'),
('Study Room 3',      'study_room',      'Library',       '2nd',    'L201', 12,  '{"whiteboard":true,"wifi":true,"tv_screen":true}',                'available'),
('Projector PJ-01',   'equipment',       'Equipment Store','-',     'EQ001',1,   '{"portable":true,"hdmi":true}',                                   'available'),
('Projector PJ-02',   'equipment',       'Equipment Store','-',     'EQ002',1,   '{"portable":true,"hdmi":true,"wireless":true}',                   'available'),
('Sports Hall',       'sports_facility', 'Sports Complex','Ground', 'SP001',200, '{"basketball":true,"volleyball":true,"changing_rooms":true}',     'available'),
('Swimming Pool',     'sports_facility', 'Sports Complex','Ground', 'SP002',50,  '{"pool":true,"changing_rooms":true,"lifeguard":true}',            'available');

-- Sample bookings (using today and tomorrow)
INSERT INTO bookings (user_id, resource_id, booking_date, start_time, end_time, purpose, booking_status, qr_code, confirmed_at) VALUES
(2, 1, CURDATE(),                        '08:00:00', '10:00:00', 'CS101 Lecture',           'confirmed', 'demo_token_kwame_lec1', NOW()),
(3, 9, CURDATE(),                        '14:00:00', '16:00:00', 'Group Study Session',     'confirmed', 'demo_token_ama_study1', NOW()),
(6, 9, CURDATE(),                        '10:00:00', '12:00:00', 'Maths Group Work',        'completed', 'demo_token_kofi_study', NOW()),
(2, 4, DATE_ADD(CURDATE(),INTERVAL 1 DAY),'09:00:00', '12:00:00', 'Programming Practical',  'confirmed', 'demo_token_kwame_lab1', NOW()),
(7, 1, DATE_ADD(CURDATE(),INTERVAL 2 DAY),'10:00:00', '12:00:00', 'Math Lecture',           'confirmed', 'demo_token_abena_lec1', NOW()),
(3, 10,DATE_ADD(CURDATE(),INTERVAL 1 DAY),'15:00:00', '17:00:00', 'Revision Session',       'confirmed', 'demo_token_ama_study2', NOW());

-- Sample check-in
INSERT INTO checkins (booking_id, user_id, checkin_timestamp) VALUES (3, 6, NOW());

-- Sample maintenance request
INSERT INTO maintenance_requests (resource_id, reported_by, fault_description, severity, request_status) VALUES
(6, 2, 'Fume hood ventilation not working properly. Strange smell detected.', 'high', 'open'),
(1, 3, 'Projector bulb flickering intermittently during lecture.', 'medium', 'in_progress');

-- Sample notifications
INSERT INTO notifications (recipient_id, notification_type, message_body) VALUES
(2, 'booking_confirmed', 'Your booking for Lecture Hall A1 on today at 08:00 is confirmed. QR code generated.'),
(3, 'booking_confirmed', 'Your booking for Study Room 1 on today at 14:00 is confirmed. QR code generated.'),
(4, 'system_alert',      'Chemistry Lab has been placed under maintenance. 1 booking was automatically cancelled.'),
(3, 'waitlist_info',     'Study Room 1 is now available for your requested slot. Book now!'),
(2, 'system_alert',      'Reminder: Your booking for CS Laboratory 1 is tomorrow at 09:00.');

-- Audit entries
INSERT INTO audit_ledger (event_type, actor_id, target_entity, target_id, event_description, event_hash) VALUES
('SYSTEM_INIT', 'system', 'database', '1', 'AI-SCRMS database initialised and seeded with demo data', SHA2(CONCAT('SYSTEM_INIT','system','database','1',NOW()), 256)),
('USER_REGISTER','system','users','1','Super admin account created', SHA2(CONCAT('USER_REGISTER','1',NOW()),256)),
('BOOKING_CREATED','2','bookings','1','Booking #1 created for Lecture Hall A1', SHA2(CONCAT('BOOKING_CREATED','2','1',NOW()),256));
