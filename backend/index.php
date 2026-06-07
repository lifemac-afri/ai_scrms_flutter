<?php require_once 'php/config.php'; ?><!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AI-SCRMS — Smart Campus Resource Management</title>
  <link rel="stylesheet" href="css/styles.css">
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
</head>
<body>

<!-- Animated background -->
<div class="bg-fx" aria-hidden="true">
  <div class="bg-orb bg-orb-1"></div>
  <div class="bg-orb bg-orb-2"></div>
  <div class="bg-orb bg-orb-3"></div>
</div>

<!-- ══════════════════════════════════════
     AUTH SCREEN
══════════════════════════════════════ -->
<div id="auth-screen">
  <div class="auth-card">
    <div class="auth-logo">
      <div class="auth-logo-icon">🏛️</div>
      <div class="auth-logo-text">AI<span>-SCRMS</span></div>
    </div>
    <p class="auth-tagline">AI-Powered Smart Campus Resource Management System</p>

    <div class="tab-row">
      <button class="tab-btn active" data-tab="login">Sign In</button>
      <button class="tab-btn" data-tab="register">Register</button>
    </div>

    <!-- Login form -->
    <form id="login-form" autocomplete="on">
      <div class="form-group">
        <label class="form-label">Email Address</label>
        <input type="email" class="form-control" id="login-email" placeholder="you@campus.edu" autocomplete="email" required>
      </div>
      <div class="form-group">
        <label class="form-label">Password</label>
        <input type="password" class="form-control" id="login-pass" placeholder="••••••••" autocomplete="current-password" required>
      </div>
      <button type="submit" class="btn btn-primary btn-full">Sign In →</button>
      <div style="margin-top:16px;padding:12px;background:rgba(13,245,227,0.06);border:1px solid rgba(13,245,227,0.1);border-radius:8px;font-size:12px;color:var(--ink2);line-height:1.7">
        <strong style="color:var(--teal)">Demo accounts</strong> (password: <code style="color:var(--amber)">password</code>)<br>
        Admin: <code>admin@campus.edu</code><br>
        Student: <code>ama@campus.edu</code>
      </div>
    </form>

    <!-- Register form -->
    <form id="reg-form" style="display:none" autocomplete="on">
      <div class="form-group">
        <label class="form-label">Full Name</label>
        <input type="text" class="form-control" id="reg-name" placeholder="Kwame Asante" autocomplete="name" required>
      </div>
      <div class="form-group">
        <label class="form-label">Email Address</label>
        <input type="email" class="form-control" id="reg-email" placeholder="you@campus.edu" autocomplete="email" required>
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
        <div class="form-group">
          <label class="form-label">Password</label>
          <input type="password" class="form-control" id="reg-pass" placeholder="Min. 6 chars" autocomplete="new-password" required>
        </div>
        <div class="form-group">
          <label class="form-label">Confirm Password</label>
          <input type="password" class="form-control" id="reg-pass2" placeholder="Repeat password" autocomplete="new-password" required>
        </div>
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
        <div class="form-group">
          <label class="form-label">Role</label>
          <select class="form-control" id="reg-role">
            <option value="student">Student</option>
            <option value="faculty">Faculty</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Department</label>
          <input class="form-control" id="reg-dept" placeholder="e.g. Engineering">
        </div>
      </div>
      <button type="submit" class="btn btn-primary btn-full">Create Account →</button>
    </form>
  </div>
</div>

<!-- ══════════════════════════════════════
     APP SCREEN
══════════════════════════════════════ -->
<div id="app-screen">

  <!-- Sidebar -->
  <aside class="sidebar" id="sidebar">
    <div class="sidebar-logo">
      <div class="sidebar-logo-icon">🏛️</div>
      <div class="sidebar-logo-text">AI<span>-SCRMS</span></div>
    </div>

    <nav class="sidebar-nav">
      <div class="nav-label">Main</div>
      <button class="nav-item" data-pg="dashboard"><span class="nav-icon">🏠</span> Dashboard</button>
      <button class="nav-item" data-pg="resources"><span class="nav-icon">🏢</span> Resources</button>
      <button class="nav-item" data-pg="my-bookings"><span class="nav-icon">📋</span> My Bookings</button>
      <button class="nav-item" data-pg="waitlist"><span class="nav-icon">⏳</span> My Waitlist</button>
      <button class="nav-item" data-pg="qr"><span class="nav-icon">📱</span> QR Check-In</button>
      <button class="nav-item" data-pg="notifications">
        <span class="nav-icon">🔔</span> Notifications
        <span id="nav-notif-badge" class="nav-badge" style="display:none">0</span>
      </button>

      <div id="admin-nav" style="display:none">
        <div class="nav-label" style="margin-top:4px">Administration</div>
        <button class="nav-item" id="nav-analytics" data-pg="analytics" style="display:none"><span class="nav-icon">📊</span> Analytics</button>
        <button class="nav-item" id="nav-all-bookings" data-pg="all-bookings" style="display:none"><span class="nav-icon">📅</span> All Bookings</button>
        <button class="nav-item" id="nav-manage-resources" data-pg="manage-resources" style="display:none"><span class="nav-icon">🗂️</span> Manage Resources</button>
        <button class="nav-item" id="nav-maintenance" data-pg="maintenance" style="display:none"><span class="nav-icon">🔧</span> Maintenance</button>
        <button class="nav-item" id="nav-users" data-pg="users" style="display:none"><span class="nav-icon">👥</span> Users</button>
        <button class="nav-item" id="nav-audit" data-pg="audit" style="display:none"><span class="nav-icon">🔒</span> Audit Ledger</button>
      </div>
    </nav>

    <div class="sidebar-footer">
      <div class="user-chip">
        <div class="user-avatar" id="av">?</div>
        <div class="user-info">
          <div class="user-name" id="uname">Loading…</div>
          <div class="user-role" id="urole">—</div>
        </div>
        <button id="logout-btn" class="btn btn-ghost btn-icon" title="Logout">⏻</button>
      </div>
    </div>
  </aside>

  <!-- Main -->
  <div class="main-content">
    <!-- Topbar -->
    <header class="topbar">
      <div style="display:flex;align-items:center;gap:12px">
        <button class="btn btn-icon btn-secondary hamburger" id="ham">☰</button>
        <span class="topbar-title" id="topbar-title">Dashboard</span>
      </div>
      <div class="topbar-right">
        <div class="status-pill">
          <span class="status-dot"></span>
          System Online
        </div>
        <div style="position:relative">
          <button class="notif-btn" id="notif-btn" title="Notifications">🔔
            <span id="notif-dot" class="notif-badge-dot" style="display:none"></span>
          </button>
        </div>
      </div>
    </header>

    <!-- Notification panel -->
    <div id="notif-panel" class="notif-panel"></div>

    <!-- Pages -->
    <div id="p-dashboard"       class="page active"></div>
    <div id="p-resources"       class="page"></div>
    <div id="p-my-bookings"     class="page"></div>
    <div id="p-waitlist"        class="page"></div>
    <div id="p-qr"              class="page"></div>
    <div id="p-notifications"   class="page"></div>
    <div id="p-analytics"       class="page"></div>
    <div id="p-all-bookings"    class="page"></div>
    <div id="p-manage-resources"class="page"></div>
    <div id="p-maintenance"     class="page"></div>
    <div id="p-users"           class="page"></div>
    <div id="p-audit"           class="page"></div>
  </div>
</div>

<!-- Toast container -->
<div id="toast-ctn"></div>

<script src="js/app.js"></script>
</body>
</html>
