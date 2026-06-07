# 🏛️ AI-SCRMS — AI-Powered Smart Campus Resource Management System

 ⚡ Setup 

Import database
1. Start XAMPP → Start **Apache** and **MySQL**
2. Open `http://localhost/phpmyadmin`
3. Click **Import** tab → **Choose File** → select `ai_scrms/database.sql` → **Go**

### Step 3 — Open the app
Visit: **http://localhost/ai_scrms/**


## 🔑 Demo Login Credentials
**Password for all accounts: `password`**

| Email | Role | Access Level |
|-------|------|-------------|
| `admin@campus.edu` | Super Admin | Full system access |
| `fm@campus.edu` | Facility Manager | Resources + analytics |
| `kwame@campus.edu` | Faculty | Bookings + reports |
| `ama@campus.edu` | Student | Bookings + QR check-in |
| `tech@campus.edu` | Maintenance | Work orders |


 📁 File Structure

ai_scrms/
├── index.php          ← App entry point
├── database.sql       ← Database setup + seed data
├── php/config.php     ← DB config + helpers
├── api/index.php      ← REST API (all endpoints)
├── api/qr.php         ← QR code image generator
├── css/styles.css     ← Animated design system
├── js/app.js          ← Frontend SPA logic
└── README.md
```

 ⚙️ Requirements
- PHP 7.4+ (XAMPP ships with PHP 8.x ✓)
- MySQL 5.7+ / MariaDB 10.3+
- Apache (included in XAMPP ✓)
- Internet (for Google Fonts + Chart.js CDN)
