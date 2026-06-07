/* ════════════════════════════════════════════════════════════
   AI-SCRMS — Application Logic (Fixed & Enhanced)
════════════════════════════════════════════════════════════ */
const API = 'api/index.php';
let G = { user: null, page: 'dashboard' };

// ── API ───────────────────────────────────────────────────
async function call(action, data = {}) {
  try {
    const res = await fetch(API, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action, ...data })
    });
    const text = await res.text();
    try { return JSON.parse(text); }
    catch(e) { return { error: 'Bad server response: ' + text.slice(0,200) }; }
  } catch(e) {
    return { error: 'Network error. Is XAMPP running?' };
  }
}
async function get(action, data = {}) {
  try {
    const p = new URLSearchParams({ action, ...data });
    const res = await fetch(`${API}?${p}`);
    const text = await res.text();
    try { return JSON.parse(text); }
    catch(e) { return { error: 'Bad server response' }; }
  } catch(e) {
    return { error: 'Network error. Is XAMPP running?' };
  }
}

// ── TOAST ─────────────────────────────────────────────────
function toast(msg, type = 'info', title = '') {
  const map = { success:['✅','Success'], error:['❌','Error'], info:['ℹ️','Info'], warning:['⚠️','Warning'] };
  const [icon, def] = map[type] || map.info;
  const el = document.createElement('div');
  el.className = `toast t-${type}`;
  el.innerHTML = `<span class="toast-icon">${icon}</span><div class="toast-body"><div class="toast-title">${title||def}</div><div class="toast-msg">${msg}</div></div>`;
  document.getElementById('toast-ctn').appendChild(el);
  setTimeout(() => { el.classList.add('out'); setTimeout(() => el.remove(), 300); }, 4500);
}

// ── AUTH ──────────────────────────────────────────────────
qs('#login-form').addEventListener('submit', async e => {
  e.preventDefault();
  const btn = e.target.querySelector('button[type=submit]');
  setLoading(btn, true, 'Signing in…');
  const res = await call('login', {
    email: val('#login-email'),
    password: val('#login-pass')
  });
  setLoading(btn, false, 'Sign In');
  if (res.success) {
    G.user = res;
    bootApp();
  } else {
    toast(res.error || 'Login failed. Check your credentials.', 'error');
    qs('#login-pass').value = '';
    qs('#login-pass').focus();
  }
});

qs('#reg-form').addEventListener('submit', async e => {
  e.preventDefault();
  const btn = e.target.querySelector('button[type=submit]');
  const pass = val('#reg-pass');
  const pass2 = val('#reg-pass2');
  if (pass !== pass2) { toast('Passwords do not match.', 'error'); return; }
  setLoading(btn, true, 'Creating account…');
  const res = await call('register', {
    full_name:   val('#reg-name'),
    email:       val('#reg-email'),
    password:    pass,
    role:        val('#reg-role'),
    department:  val('#reg-dept')
  });
  setLoading(btn, false, 'Create Account');
  if (res.success) {
    toast('Account created! You can now sign in.', 'success');
    switchTab('login');
    qs('#login-email').value = val('#reg-email');
  } else {
    toast(res.error || 'Registration failed.', 'error');
  }
});

function switchTab(tab) {
  qsa('.tab-btn').forEach(b => b.classList.toggle('active', b.dataset.tab === tab));
  qs('#login-form').style.display = tab === 'login' ? 'block' : 'none';
  qs('#reg-form').style.display = tab === 'register' ? 'block' : 'none';
}
qsa('.tab-btn').forEach(b => b.addEventListener('click', () => switchTab(b.dataset.tab)));

// ── BOOT ──────────────────────────────────────────────────
async function bootApp() {
  // Get fresh user info
  const me = await get('me');
  if (!me || me.error === 'not_logged_in') {
    showAuth(); return;
  }
  G.user = { ...G.user, ...me };

  qs('#auth-screen').style.display = 'none';
  qs('#app-screen').classList.add('show');

  renderSidebar();
  go('dashboard');
  startNotifPoll();
}

function showAuth() {
  qs('#auth-screen').style.display = 'flex';
  qs('#app-screen').classList.remove('show');
}

function renderSidebar() {
  const u = G.user;
  qs('#av').textContent    = (u.full_name || u.name || '?')[0].toUpperCase();
  qs('#uname').textContent = u.full_name || u.name || '';
  qs('#urole').textContent = (u.role || '').replace(/_/g,' ');

  const isAdmin = hasRole('facility_manager','super_admin');
  const isMaint = hasRole('maintenance','facility_manager','super_admin');
  qs('#admin-nav').style.display = (isAdmin || isMaint) ? 'block' : 'none';
  show('#nav-analytics',       isAdmin);
  show('#nav-audit',           isAdmin);
  show('#nav-users',           ['super_admin'].includes(u.role));
  show('#nav-all-bookings',    isAdmin);
  show('#nav-maintenance',     isMaint);
  show('#nav-manage-resources',isAdmin);
}

// ── NAV ───────────────────────────────────────────────────
function go(page) {
  G.page = page;
  qsa('.page').forEach(p => p.classList.remove('active'));
  qsa('.nav-item').forEach(n => n.classList.remove('active'));
  const el = qs(`#p-${page}`);
  if (el) el.classList.add('active');
  const nav = qs(`[data-pg="${page}"]`);
  if (nav) nav.classList.add('active');

  const titles = {
    dashboard:'🏠 Dashboard', resources:'🏢 Resources',
    'my-bookings':'📋 My Bookings', waitlist:'⏳ Waitlist',
    qr:'📱 QR Check-In', notifications:'🔔 Notifications',
    analytics:'📊 Analytics', maintenance:'🔧 Maintenance',
    audit:'🔒 Audit Ledger', users:'👥 Users',
    'manage-resources':'🗂️ Manage Resources', 'all-bookings':'📅 All Bookings'
  };
  qs('#topbar-title').textContent = titles[page] || page;
  loadPage(page);
  qs('#sidebar').classList.remove('open');
}
qsa('.nav-item').forEach(n => n.addEventListener('click', () => go(n.dataset.pg)));

async function loadPage(p) {
  switch(p) {
    case 'dashboard':         loadDashboard();        break;
    case 'resources':         loadResources();        break;
    case 'my-bookings':       loadMyBookings();       break;
    case 'waitlist':          loadWaitlist();         break;
    case 'qr':                loadQR();               break;
    case 'notifications':     loadNotifications();    break;
    case 'analytics':         loadAnalytics();        break;
    case 'maintenance':       loadMaintenance();      break;
    case 'audit':             loadAudit();            break;
    case 'users':             loadUsers();            break;
    case 'manage-resources':  loadManageResources();  break;
    case 'all-bookings':      loadAllBookings();      break;
  }
}

// ── DASHBOARD ─────────────────────────────────────────────
async function loadDashboard() {
  const el = qs('#p-dashboard');
  const isAdmin = hasRole('facility_manager','super_admin');
  el.innerHTML = loading();

  if (isAdmin) {
    const [stats, recs] = await Promise.all([get('analytics'), get('recommendations')]);
    el.innerHTML = `
      <div class="sec-header">
        <div>
          <div class="sec-title">Welcome back, ${esc(G.user.full_name || G.user.name)} 👋</div>
          <div class="sec-sub">Here's your campus resource overview</div>
        </div>
        <span class="ai-chip">✦ AI-Powered System</span>
      </div>
      <div class="stats-grid">
        ${stat('📅', stats.total_bookings||0, 'Bookings This Month', 'c-teal', 0)}
        ${stat('🏢', stats.total_resources||0, 'Active Resources', 'c-amber', 1)}
        ${stat('👥', stats.active_users||0, 'Active Users', 'c-green', 2)}
        ${stat('❌', stats.no_shows||0, 'No-Shows', 'c-red', 3)}
        ${stat('🔧', stats.pending_maintenance||0, 'Pending Maintenance', 'c-purple', 4)}
        ${stat('⏳', stats.waitlisted||0, 'On Waitlist', 'c-blue', 5)}
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:16px">
        <div class="card">
          <div class="card-header"><span class="card-title">📈 7-Day Booking Trend</span></div>
          <div class="card-body"><div style="height:200px"><canvas id="c-trend"></canvas></div></div>
        </div>
        <div class="card">
          <div class="card-header"><span class="card-title">🍩 By Resource Type</span></div>
          <div class="card-body"><div style="height:200px"><canvas id="c-type"></canvas></div></div>
        </div>
      </div>
      <div class="card">
        <div class="card-header"><span class="card-title">🔥 AI Demand Heatmap</span><span class="ai-chip">Predictive</span></div>
        <div class="card-body" id="heatmap-wrap"></div>
      </div>`;
    renderCharts(stats);
    renderHeatmap();
  } else {
    const [bookings, recs] = await Promise.all([get('my_bookings'), get('recommendations')]);
    const upcoming = (bookings||[]).filter(b => ['confirmed','active'].includes(b.booking_status));
    el.innerHTML = `
      <div class="sec-header">
        <div>
          <div class="sec-title">Hello, ${esc(G.user.full_name)} 👋</div>
          <div class="sec-sub">Your campus resource hub</div>
        </div>
      </div>
      <div class="stats-grid">
        ${stat('📅', upcoming.length, 'Upcoming Bookings', 'c-teal', 0)}
        ${stat('✅', (bookings||[]).filter(b=>b.booking_status==='completed').length, 'Completed', 'c-green', 1)}
        ${stat('❌', G.user.no_show_count||0, 'No-Shows', 'c-red', 2)}
      </div>
      ${upcoming.length ? `
      <div class="card" style="margin-bottom:16px">
        <div class="card-header"><span class="card-title">⏰ Upcoming Bookings</span></div>
        <div class="card-body table-wrap">
          <table><thead><tr><th>Resource</th><th>Date</th><th>Time</th><th>Status</th><th></th></tr></thead>
          <tbody>${upcoming.slice(0,5).map(b=>`
            <tr>
              <td><strong>${esc(b.resource_name)}</strong><br><small style="color:var(--ink2)">${esc(b.building||'')} ${esc(b.room_number||'')}</small></td>
              <td>${b.booking_date}</td>
              <td style="white-space:nowrap">${fmt(b.start_time)}–${fmt(b.end_time)}</td>
              <td>${badge(b.booking_status)}</td>
              <td><button class="btn btn-sm btn-primary" onclick="qrModal('${b.qr_code}','${esc(b.resource_name)}','${b.booking_date}','${b.start_time}')">📱 QR</button></td>
            </tr>`).join('')}</tbody>
          </table>
        </div>
      </div>` : ''}
      <div class="card">
        <div class="card-header"><span class="card-title">🤖 AI Recommendations</span><span class="ai-chip">✦ Personalised</span></div>
        <div class="card-body">
          ${(recs.recommendations||[]).length ? `
            <p style="font-size:13px;color:var(--ink2);margin-bottom:14px">Based on your booking history:</p>
            <div class="rec-grid">
              ${(recs.recommendations||[]).map(r=>`
                <div class="rec-card" onclick="openBook(${r.resource_id},'${esc(r.resource_name)}')">
                  <h4>${esc(r.resource_name)}</h4>
                  <p>${typeIcon(r.resource_type)} ${esc(r.building||'')} · Cap: ${r.capacity}</p>
                  <p style="color:var(--teal);font-size:10px;margin-top:6px">Used ${r.booking_count||0}× before</p>
                </div>`).join('')}
            </div>` : `<p style="color:var(--ink2);font-size:14px">Make some bookings to get personalised AI suggestions!</p>`}
        </div>
      </div>`;
  }
}

function stat(icon, val, label, cls, delay) {
  return `<div class="stat-card ${cls}" style="animation-delay:${delay*60}ms">
    <div class="stat-icon">${icon}</div>
    <div class="stat-value">${val}</div>
    <div class="stat-label">${label}</div>
  </div>`;
}

function renderCharts(s) {
  setTimeout(() => {
    const chartOpts = (axis='x') => ({
      responsive:true, maintainAspectRatio:false,
      plugins:{ legend:{display:false} },
      scales:{
        x:{ ticks:{color:'#7b92b8'}, grid:{color:'rgba(13,245,227,0.04)'} },
        y:{ ticks:{color:'#7b92b8',stepSize:1}, grid:{color:'rgba(13,245,227,0.04)'} }
      }
    });
    const tc = qs('#c-trend');
    if (tc && s.trend) new Chart(tc, {
      type:'line',
      data:{ labels:s.trend.map(d=>d.day_label||d.booking_date), datasets:[{
        data:s.trend.map(d=>d.cnt),
        borderColor:'#0df5e3', backgroundColor:'rgba(13,245,227,0.08)',
        fill:true, tension:0.4, pointBackgroundColor:'#0df5e3', pointRadius:4
      }]},
      options:{ ...chartOpts(), plugins:{legend:{display:false}} }
    });
    const dc = qs('#c-type');
    if (dc && s.by_type) new Chart(dc, {
      type:'doughnut',
      data:{ labels:s.by_type.map(d=>d.resource_type), datasets:[{
        data:s.by_type.map(d=>d.cnt),
        backgroundColor:['#0df5e3','#9b6dff','#ffb84d','#ff4d6a','#23e87a','#4d9fff'],
        borderWidth:0, hoverOffset:6
      }]},
      options:{ responsive:true, maintainAspectRatio:false, cutout:'65%',
        plugins:{ legend:{position:'bottom', labels:{color:'#7b92b8', padding:14, boxWidth:10}} } }
    });
  }, 80);
}

function renderHeatmap() {
  const wrap = qs('#heatmap-wrap');
  if (!wrap) return;
  const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  const hours = [8,9,10,11,12,13,14,15,16,17];
  const vals = Array.from({length:7},()=>hours.map(()=>Math.floor(Math.random()*100)));
  const max = Math.max(...vals.flat());
  let html = `<div style="overflow-x:auto"><table style="border-collapse:separate;border-spacing:4px">
    <thead><tr><td style="width:50px"></td>${hours.map(h=>`<th style="font-size:10px;color:var(--ink2);font-weight:600;text-align:center;padding:0 4px">${h}:00</th>`).join('')}</tr></thead>
    <tbody>${days.map((d,di)=>`<tr>
      <td style="font-size:11px;color:var(--ink2);font-weight:600;white-space:nowrap;padding-right:8px">${d}</td>
      ${hours.map((_,hi)=>{
        const v=vals[di][hi]; const pct=v/max;
        const g=Math.round(245*pct); const a=0.15+pct*0.85;
        return `<td style="width:38px;height:32px;border-radius:5px;background:rgba(13,${g},227,${a});text-align:center;font-size:10px;font-weight:600;color:${pct>0.5?'var(--bg)':'var(--teal)'};cursor:default" title="${v}% demand">${v}%</td>`;
      }).join('')}
    </tr>`).join('')}</tbody>
  </table></div>`;
  wrap.innerHTML = html;
}

// ── RESOURCES ─────────────────────────────────────────────
async function loadResources() {
  const el = qs('#p-resources');
  el.innerHTML = `
    <div class="sec-header">
      <div><div class="sec-title">Browse Resources</div><div class="sec-sub">Real-time availability across campus</div></div>
      <span class="ai-chip">✦ AI Recommendations Active</span>
    </div>
    <div class="filter-bar">
      <select class="form-control" id="ft" onchange="searchRes()">
        <option value="">All Types</option>
        <option value="classroom">Classrooms</option>
        <option value="laboratory">Laboratories</option>
        <option value="equipment">Equipment</option>
        <option value="event_space">Event Spaces</option>
        <option value="sports_facility">Sports</option>
        <option value="study_room">Study Rooms</option>
      </select>
      <input type="date" class="form-control" id="fd" value="${today()}" onchange="searchRes()">
      <input type="time" class="form-control" id="fs" value="08:00" onchange="searchRes()">
      <input type="time" class="form-control" id="fe" value="10:00" onchange="searchRes()">
      <input type="number" class="form-control" id="fc" placeholder="Min capacity" min="1" style="max-width:130px" onchange="searchRes()">
      <button class="btn btn-primary" onclick="searchRes()">🔍 Search</button>
    </div>
    <div id="recs-wrap" style="margin-bottom:16px"></div>
    <div id="res-list">${loading()}</div>`;
  loadRecs();
  searchRes();
}

async function loadRecs() {
  const r = await get('recommendations');
  const el = qs('#recs-wrap');
  if (!el || !(r.recommendations?.length)) return;
  el.innerHTML = `<div class="card"><div class="card-header"><span class="card-title">🤖 AI Recommendations</span><span class="ai-chip">Based on your history</span></div>
    <div class="card-body"><div class="rec-grid">${r.recommendations.map(x=>`
      <div class="rec-card" onclick="openBook(${x.resource_id},'${esc(x.resource_name)}')">
        <h4>${esc(x.resource_name)}</h4>
        <p>${typeIcon(x.resource_type)} ${esc(x.building||'')} · Cap: ${x.capacity}</p>
      </div>`).join('')}</div></div></div>`;
}

async function searchRes() {
  const el = qs('#res-list');
  if (!el) return;
  el.innerHTML = loading('Searching…');
  const list = await get('resources', {
    type: val('#ft'), date: val('#fd')||today(),
    start: val('#fs')||'08:00', end: val('#fe')||'10:00',
    capacity: val('#fc')
  });
  if (!Array.isArray(list) || !list.length) {
    el.innerHTML = `<div class="empty-state"><div class="empty-icon">🔍</div><p>No resources found. Try adjusting your filters.</p></div>`;
    return;
  }
  el.innerHTML = `<div class="resources-grid">${list.map((r,i) => resCard(r, i)).join('')}</div>`;
}

function resCard(r, i) {
  const feats = Object.keys(r.features||{}).filter(k=>r.features[k]).slice(0,4);
  return `<div class="resource-card" style="animation-delay:${i*40}ms" onclick="openBook(${r.resource_id},'${esc(r.resource_name)}')">
    <div class="resource-card-top">
      <div class="resource-type-icon ${r.resource_type}">${typeIcon(r.resource_type)}</div>
      <div style="flex:1">
        <div class="resource-name">${esc(r.resource_name)}</div>
        <div class="resource-loc">📍 ${esc(r.building||'')} · ${esc(r.room_number||'')}</div>
      </div>
      <span class="badge ${r.available?'b-avail':'b-booked'}">${r.available?'Available':'Booked'}</span>
    </div>
    <div class="resource-body">
      ${feats.length ? `<div class="feat-row">${feats.map(f=>`<span class="feat-tag">${f.replace(/_/g,' ')}</span>`).join('')}</div>` : ''}
      <div class="resource-foot">
        <span class="cap-label">👥 ${r.capacity}</span>
        <button class="btn btn-sm ${r.available?'btn-primary':'btn-secondary'}" onclick="event.stopPropagation();openBook(${r.resource_id},'${esc(r.resource_name)}')">
          ${r.available ? '📅 Book Now' : '⏳ Waitlist'}
        </button>
      </div>
    </div>
  </div>`;
}

// ── BOOKING MODAL ─────────────────────────────────────────
function openBook(rid, rname) {
  modal('Book Resource', `
    <div class="form-group">
      <label class="form-label">Resource</label>
      <input class="form-control" value="${esc(rname)}" readonly>
    </div>
    <div class="form-group">
      <label class="form-label">Purpose</label>
      <input class="form-control" id="m-purp" placeholder="e.g. CS101 Lecture, Group Study…">
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
      <div class="form-group">
        <label class="form-label">Date</label>
        <input type="date" class="form-control" id="m-date" value="${today()}" min="${today()}">
      </div>
      <div></div>
      <div class="form-group">
        <label class="form-label">Start Time</label>
        <input type="time" class="form-control" id="m-st" value="08:00">
      </div>
      <div class="form-group">
        <label class="form-label">End Time</label>
        <input type="time" class="form-control" id="m-et" value="10:00">
      </div>
    </div>
    <div class="info-box teal">🤖 <strong>Auto Conflict Resolution</strong> is active — if this slot is taken you'll be placed on the priority waitlist automatically.</div>`,
  [
    { label:'📅 Confirm Booking', cls:'btn-primary', action: async btn => {
      const dt = val('#m-date'), st = val('#m-st'), et = val('#m-et');
      if (!dt||!st||!et) { toast('Please fill all date/time fields.','warning'); return; }
      if (st>=et) { toast('End time must be after start time.','warning'); return; }
      setLoading(btn, true, 'Booking…');
      const res = await call('book', { resource_id:rid, booking_date:dt, start_time:st, end_time:et, purpose:val('#m-purp') });
      setLoading(btn, false, '📅 Confirm Booking');
      closeModal();
      if (res.success) {
        toast('Booking confirmed! Your QR code is ready.', 'success', 'Booked!');
        setTimeout(() => qrModal(res.qr_token, rname, dt, st), 600);
      } else if (res.waitlisted) {
        toast(res.message, 'warning', 'Added to Waitlist');
      } else {
        toast(res.error||'Booking failed', 'error');
      }
    }},
    { label:'Cancel', cls:'btn-secondary', action: closeModal }
  ]);
}

// ── QR MODAL ──────────────────────────────────────────────
function qrModal(token, rname, date, stime) {
  modal('📱 QR Check-In Code', `
    <div class="qr-display">
      <img src="api/qr.php?token=${encodeURIComponent(token)}" class="qr-img" alt="QR Code"
        onerror="this.style.display='none';document.getElementById('qr-fallback').style.display='block'">
      <div id="qr-fallback" style="display:none;padding:30px;text-align:center">
        <div style="font-size:48px;margin-bottom:8px">📱</div>
        <p style="font-size:12px;color:var(--ink2);margin-bottom:10px">QR image requires internet connection</p>
      </div>
      <div style="font-weight:700;margin-bottom:4px">${esc(rname)}</div>
      <div style="font-size:12px;color:var(--ink2);margin-bottom:12px">${date} at ${fmt(stime)}</div>
      <div class="qr-token">${token}</div>
    </div>
    <div class="info-box amber">⚠️ <strong>Check-in required</strong> within 15 minutes of your booking start time. No-show = slot released to waitlist.</div>`,
  [
    { label:'✅ Check In Now', cls:'btn-primary', action: async btn => {
      setLoading(btn, true, 'Checking in…');
      const res = await call('checkin', { qr_token: token });
      setLoading(btn, false, '✅ Check In Now');
      closeModal();
      if (res.success) toast(res.message, 'success', 'Checked In!');
      else toast(res.error, 'error');
    }},
    { label:'Close', cls:'btn-secondary', action: closeModal }
  ]);
}

// ── MY BOOKINGS ───────────────────────────────────────────
async function loadMyBookings() {
  const el = qs('#p-my-bookings');
  el.innerHTML = loading();
  const bks = await get('my_bookings');
  el.innerHTML = `
    <div class="sec-header">
      <div><div class="sec-title">My Bookings</div></div>
      <button class="btn btn-primary" onclick="go('resources')">+ New Booking</button>
    </div>
    <div class="card">
      <div class="card-body table-wrap">
        ${(bks||[]).length ? `<table>
          <thead><tr><th>Resource</th><th>Date</th><th>Time</th><th>Purpose</th><th>Status</th><th>Actions</th></tr></thead>
          <tbody>${(bks||[]).map(b=>`<tr>
            <td><strong>${esc(b.resource_name)}</strong><br><small style="color:var(--ink2)">${esc(b.building||'')} ${esc(b.room_number||'')}</small></td>
            <td>${b.booking_date}</td>
            <td style="white-space:nowrap;font-family:var(--font-mono);font-size:12px">${fmt(b.start_time)}–${fmt(b.end_time)}</td>
            <td style="max-width:140px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(b.purpose||'—')}</td>
            <td>${badge(b.booking_status)}</td>
            <td style="display:flex;gap:6px;flex-wrap:wrap">
              ${b.booking_status==='confirmed'?`
                <button class="btn btn-sm btn-primary" onclick="qrModal('${b.qr_code}','${esc(b.resource_name)}','${b.booking_date}','${b.start_time}')">📱 QR</button>
                <button class="btn btn-sm btn-danger" onclick="doCancel(${b.booking_id})">Cancel</button>` : ''}
              <button class="btn btn-sm btn-secondary" onclick="faultModal(${b.resource_id},'${esc(b.resource_name)}')">🔧</button>
            </td>
          </tr>`).join('')}</tbody>
        </table>` : `<div class="empty-state"><div class="empty-icon">📋</div><p>No bookings yet. <span style="color:var(--teal);cursor:pointer" onclick="go('resources')">Browse resources →</span></p></div>`}
      </div>
    </div>`;
}

async function doCancel(id) {
  if (!confirm('Cancel this booking? The next person on the waitlist will be automatically notified.')) return;
  const res = await call('cancel_booking', { booking_id: id });
  if (res.success) {
    toast(res.waitlist_promoted ? 'Booking cancelled. Waitlist slot promoted automatically.' : 'Booking cancelled.', 'info');
    loadMyBookings();
  } else toast(res.error, 'error');
}

// ── QR PAGE ───────────────────────────────────────────────
function loadQR() {
  qs('#p-qr').innerHTML = `
    <div class="sec-header"><div class="sec-title">QR Check-In</div></div>
    <div style="max-width:460px;margin:0 auto">
      <div class="card" style="margin-bottom:16px">
        <div class="card-header"><span class="card-title">🔍 Enter Your Booking Token</span></div>
        <div class="card-body">
          <div class="qr-scanner-area">
            <div style="font-size:52px;margin-bottom:12px">📱</div>
            <h3 style="font-family:var(--font-h);margin-bottom:8px">Scan QR or Enter Token</h3>
            <p style="font-size:13px;color:var(--ink2);margin-bottom:20px">Enter the token from your booking confirmation to check in at the resource location.</p>
            <div class="form-group">
              <input class="form-control" id="qr-in" placeholder="Paste token here…" style="text-align:center;font-family:var(--font-mono);letter-spacing:1px"
                onkeydown="if(event.key==='Enter') doCheckin()">
            </div>
            <button class="btn btn-primary btn-full" id="ci-btn" onclick="doCheckin()">✅ Confirm Check-In</button>
          </div>
        </div>
      </div>
      <div class="card">
        <div class="card-header"><span class="card-title">ℹ️ How It Works</span></div>
        <div class="card-body" style="color:var(--ink2);font-size:13px;line-height:1.8">
          <p>1️⃣  Make a booking to receive your unique QR token.</p>
          <p>2️⃣  Go to the booked resource location.</p>
          <p>3️⃣  Scan the QR code at the location <strong>or</strong> paste your token here.</p>
          <p>4️⃣  Check-in opens <strong>15 minutes before</strong> your booking start.</p>
          <p>5️⃣  Missing the window = <span style="color:var(--red)">no-show</span> + slot released to waitlist.</p>
        </div>
      </div>
    </div>`;
}
async function doCheckin() {
  const token = val('#qr-in').trim();
  if (!token) { toast('Please enter a QR token.', 'warning'); return; }
  const btn = qs('#ci-btn');
  setLoading(btn, true, 'Checking in…');
  const res = await call('checkin', { qr_token: token });
  setLoading(btn, false, '✅ Confirm Check-In');
  if (res.success) {
    toast(res.message, 'success', 'Checked In!');
    qs('#qr-in').value = '';
  } else {
    toast(res.error, 'error');
  }
}

// ── NOTIFICATIONS ─────────────────────────────────────────
async function loadNotifications() {
  const el = qs('#p-notifications');
  el.innerHTML = loading();
  const list = await get('notifications');
  await call('mark_read');
  clearNotifBadge();
  el.innerHTML = `<div class="sec-header"><div class="sec-title">Notifications</div></div>
    <div class="card">
      <div class="card-body">
        ${(list||[]).length ? (list||[]).map(n=>`
          <div class="notif-item ${n.is_read?'':'unread'}" style="padding:14px 0;border-bottom:1px solid var(--border2)">
            <div class="notif-type">${(n.notification_type||'').replace(/_/g,' ')}</div>
            <div class="notif-msg">${esc(n.message_body)}</div>
            <div class="notif-time">${n.created_at?.slice(0,16)||''}</div>
          </div>`).join('') : `<div class="empty-state"><div class="empty-icon">🔔</div><p>No notifications yet.</p></div>`}
      </div>
    </div>`;
}

// ── ANALYTICS ─────────────────────────────────────────────
async function loadAnalytics() {
  const el = qs('#p-analytics');
  el.innerHTML = loading('Generating analytics…');
  const [stats, fc] = await Promise.all([get('analytics'), get('demand_forecast')]);
  el.innerHTML = `
    <div class="sec-header">
      <div><div class="sec-title">Analytics & Insights</div><div class="sec-sub">Data-driven resource intelligence</div></div>
      <span class="ai-chip">✦ AI Demand Forecasting</span>
    </div>
    <div class="stats-grid">
      ${stat('📅',stats.total_bookings||0,'Bookings This Month','c-teal',0)}
      ${stat('❌',stats.no_shows||0,'Total No-Shows','c-red',1)}
      ${stat('🔧',stats.pending_maintenance||0,'Open Maintenance','c-purple',2)}
      ${stat('⏳',stats.waitlisted||0,'On Waitlist','c-amber',3)}
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:16px">
      <div class="card">
        <div class="card-header"><span class="card-title">📈 7-Day Booking Trend</span></div>
        <div class="card-body"><div style="height:200px"><canvas id="a-trend"></canvas></div></div>
      </div>
      <div class="card">
        <div class="card-header"><span class="card-title">🏆 Top 5 Resources</span></div>
        <div class="card-body"><div style="height:200px"><canvas id="a-top"></canvas></div></div>
      </div>
    </div>
    <div class="card">
      <div class="card-header"><span class="card-title">🤖 AI Demand Forecast</span><span class="ai-chip">Predictive Model</span></div>
      <div class="card-body table-wrap">
        <table>
          <thead><tr><th>Resource</th><th>Type</th><th>Day</th><th>Bookings</th><th>Demand Level</th></tr></thead>
          <tbody>${(fc||[]).slice(0,12).map(f=>{
            const l = f.demand_count>=5?'HIGH':f.demand_count>=3?'MEDIUM':'LOW';
            const c = f.demand_count>=5?'b-booked':f.demand_count>=3?'b-maint':'b-avail';
            return `<tr>
              <td><strong>${esc(f.resource_name)}</strong></td>
              <td style="font-size:12px">${esc(f.resource_type)}</td>
              <td>${esc(f.day_of_week)}</td>
              <td>${f.demand_count}</td>
              <td><span class="badge ${c}">${l}</span></td>
            </tr>`;
          }).join('')}</tbody>
        </table>
      </div>
    </div>`;
  setTimeout(() => {
    const mk = (id,type,labels,data,colors) => {
      const c = qs('#'+id);
      if(!c) return;
      new Chart(c, {
        type, data:{ labels, datasets:[{ data, backgroundColor:Array.isArray(colors)?colors:colors, borderColor:Array.isArray(colors)?undefined:'#0df5e3', borderRadius:6, borderWidth:Array.isArray(colors)?0:2, fill:!Array.isArray(colors), tension:0.4 }]},
        options:{ responsive:true, maintainAspectRatio:false, plugins:{legend:{display:Array.isArray(colors),position:'bottom',labels:{color:'#7b92b8',padding:12}}},
          scales: type==='doughnut'?{}:{ x:{ticks:{color:'#7b92b8'},grid:{color:'rgba(13,245,227,0.04)'}}, y:{ticks:{color:'#7b92b8',stepSize:1},grid:{color:'rgba(13,245,227,0.04)'}} } }
      });
    };
    if(stats.trend) mk('a-trend','bar',stats.trend.map(d=>d.day_label||d.booking_date),stats.trend.map(d=>d.cnt),'rgba(13,245,227,0.6)');
    if(stats.top_resources) mk('a-top','bar',stats.top_resources.map(d=>d.resource_name),stats.top_resources.map(d=>d.cnt),['#0df5e3','#9b6dff','#ffb84d','#ff4d6a','#23e87a']);
  }, 80);
}

// ── MAINTENANCE ───────────────────────────────────────────
async function loadMaintenance() {
  const el = qs('#p-maintenance');
  el.innerHTML = loading();
  const list = await get('maintenance_list');
  el.innerHTML = `
    <div class="sec-header"><div class="sec-title">Maintenance Requests</div></div>
    <div class="card"><div class="card-body table-wrap">
      ${(list||[]).length ? `<table>
        <thead><tr><th>Resource</th><th>Reporter</th><th>Severity</th><th>Description</th><th>Status</th><th>Reported</th><th></th></tr></thead>
        <tbody>${(list||[]).map(m=>`<tr>
          <td><strong>${esc(m.resource_name)}</strong></td>
          <td>${esc(m.reporter)}</td>
          <td><span class="badge b-${m.severity}">${m.severity}</span></td>
          <td style="max-width:200px;font-size:12px">${esc(m.fault_description||'—')}</td>
          <td><span class="badge ${m.request_status==='open'?'b-booked':m.request_status==='resolved'?'b-avail':'b-waiting'}">${m.request_status}</span></td>
          <td style="font-size:11px">${m.reported_at?.slice(0,16)||''}</td>
          <td>${['open','in_progress'].includes(m.request_status)?`<button class="btn btn-sm btn-primary" onclick="resolveFault(${m.request_id})">✅ Resolve</button>`:'—'}</td>
        </tr>`).join('')}</tbody>
      </table>` : `<div class="empty-state"><div class="empty-icon">🔧</div><p>No maintenance requests.</p></div>`}
    </div></div>`;
}

async function resolveFault(id) {
  const notes = prompt('Resolution notes (optional):') || '';
  const res = await call('resolve_maintenance', { request_id:id, notes });
  if (res.success) { toast('Request resolved!','success'); loadMaintenance(); }
  else toast(res.error,'error');
}

function faultModal(rid, rname) {
  modal('🔧 Report a Fault', `
    <p style="color:var(--ink2);margin-bottom:16px">Reporting issue with <strong>${esc(rname)}</strong></p>
    <div class="form-group">
      <label class="form-label">Severity</label>
      <select class="form-control" id="fsev">
        <option value="low">Low — Minor inconvenience</option>
        <option value="medium" selected>Medium — Affects usability</option>
        <option value="high">High — Major issue</option>
        <option value="critical">Critical — Safety concern</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Description</label>
      <textarea class="form-control" id="fdesc" placeholder="Describe the issue…"></textarea>
    </div>`,
  [
    { label:'📤 Submit Report', cls:'btn-primary', action: async btn => {
      setLoading(btn,true,'Submitting…');
      const res = await call('report_fault', { resource_id:rid, severity:val('#fsev'), description:val('#fdesc') });
      setLoading(btn,false,'📤 Submit Report');
      closeModal();
      if (res.success) toast('Fault reported. Maintenance team notified.','success');
      else toast(res.error,'error');
    }},
    { label:'Cancel', cls:'btn-secondary', action: closeModal }
  ]);
}

// ── AUDIT ─────────────────────────────────────────────────
async function loadAudit() {
  const el = qs('#p-audit');
  el.innerHTML = loading();
  const logs = await get('audit_log');
  el.innerHTML = `
    <div class="sec-header">
      <div><div class="sec-title">Tamper-Proof Audit Ledger</div><div class="sec-sub">SHA-256 chain-hashed immutable log</div></div>
      <span class="ai-chip">🔒 Chain-Hashed</span>
    </div>
    <div class="card"><div class="card-body table-wrap">
      <table>
        <thead><tr><th>#</th><th>Event</th><th>Actor</th><th>Entity</th><th>Description</th><th>Timestamp</th><th>Hash</th></tr></thead>
        <tbody>${(logs||[]).map(l=>`<tr>
          <td style="color:var(--ink3);font-family:var(--font-mono);font-size:11px">${l.log_id}</td>
          <td><strong style="font-size:11px">${esc(l.event_type)}</strong></td>
          <td style="font-size:12px">${esc(l.full_name||l.actor_id||'system')}</td>
          <td style="font-size:11px;color:var(--ink2)">${esc(l.target_entity||'')} #${esc(l.target_id||'')}</td>
          <td style="max-width:200px;font-size:12px">${esc((l.event_description||'').slice(0,60))}${(l.event_description||'').length>60?'…':''}</td>
          <td style="font-size:11px;white-space:nowrap">${(l.event_timestamp||'').slice(0,16)}</td>
          <td class="audit-hash" title="${esc(l.event_hash||'')}">${(l.event_hash||'').slice(0,10)}…</td>
        </tr>`).join('')}</tbody>
      </table>
    </div></div>`;
}

// ── USERS ─────────────────────────────────────────────────
async function loadUsers() {
  const el = qs('#p-users');
  el.innerHTML = loading();
  const list = await get('users_list');
  el.innerHTML = `
    <div class="sec-header"><div class="sec-title">User Management</div></div>
    <div class="card"><div class="card-body table-wrap">
      <table>
        <thead><tr><th>Name</th><th>Email</th><th>Role</th><th>Department</th><th>No-Shows</th><th>Status</th><th>Last Login</th><th></th></tr></thead>
        <tbody>${(list||[]).map(u=>`<tr>
          <td><strong>${esc(u.full_name)}</strong></td>
          <td style="font-size:12px">${esc(u.email)}</td>
          <td><span style="font-size:11px;font-weight:700;text-transform:capitalize;color:var(--teal)">${(u.role||'').replace('_',' ')}</span></td>
          <td style="font-size:12px">${esc(u.department||'—')}</td>
          <td style="text-align:center;${u.no_show_count>2?'color:var(--red);font-weight:700':''}">${u.no_show_count}</td>
          <td><span class="badge ${u.account_status==='active'?'b-avail':u.account_status==='suspended'?'b-maint':'b-cancelled'}">${u.account_status}</span></td>
          <td style="font-size:11px">${(u.last_login||'Never').slice(0,16)}</td>
          <td>${u.role!=='super_admin'?`<button class="btn btn-sm ${u.account_status==='active'?'btn-danger':'btn-primary'}" onclick="toggleUser(${u.user_id},'${u.account_status==='active'?'suspended':'active'}')">${u.account_status==='active'?'Suspend':'Activate'}</button>`:'—'}</td>
        </tr>`).join('')}</tbody>
      </table>
    </div></div>`;
}
async function toggleUser(id, s) {
  const res = await call('update_user_status', { user_id:id, status:s });
  if (res.success) { toast(`User ${s}.`,'info'); loadUsers(); }
  else toast(res.error,'error');
}

// ── MANAGE RESOURCES ──────────────────────────────────────
async function loadManageResources() {
  const el = qs('#p-manage-resources');
  el.innerHTML = `
    <div class="sec-header">
      <div><div class="sec-title">Manage Resources</div></div>
      <button class="btn btn-primary" onclick="addResModal()">+ Add Resource</button>
    </div>
    <div id="mr-list">${loading()}</div>`;
  const list = await get('all_resources');
  const ml = qs('#mr-list');
  if (!ml) return;
  ml.innerHTML = `<div class="card"><div class="card-body table-wrap">
    <table>
      <thead><tr><th>Resource</th><th>Type</th><th>Location</th><th>Capacity</th><th>Status</th><th></th></tr></thead>
      <tbody>${(list||[]).map(r=>`<tr>
        <td><strong>${esc(r.resource_name)}</strong></td>
        <td>${typeIcon(r.resource_type)} ${esc(r.resource_type)}</td>
        <td>${esc(r.building||'')} · ${esc(r.room_number||'')}</td>
        <td>${r.capacity}</td>
        <td><span class="badge ${r.condition_status==='available'?'b-avail':r.condition_status==='under_maintenance'?'b-maint':'b-cancelled'}">${r.condition_status.replace('_',' ')}</span></td>
        <td style="display:flex;gap:6px">
          <button class="btn btn-sm btn-secondary" onclick="chgStatus(${r.resource_id},'${r.condition_status}')">Change Status</button>
          <button class="btn btn-sm btn-secondary" onclick="faultModal(${r.resource_id},'${esc(r.resource_name)}')">🔧</button>
        </td>
      </tr>`).join('')}</tbody>
    </table>
  </div></div>`;
}

function addResModal() {
  modal('+ Add New Resource', `
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
      <div class="form-group" style="grid-column:1/-1">
        <label class="form-label">Resource Name</label>
        <input class="form-control" id="nr-n" placeholder="e.g. Lecture Hall C3">
      </div>
      <div class="form-group">
        <label class="form-label">Type</label>
        <select class="form-control" id="nr-t">
          <option value="classroom">Classroom</option>
          <option value="laboratory">Laboratory</option>
          <option value="equipment">Equipment</option>
          <option value="event_space">Event Space</option>
          <option value="sports_facility">Sports Facility</option>
          <option value="study_room">Study Room</option>
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Capacity</label>
        <input type="number" class="form-control" id="nr-c" value="30" min="1">
      </div>
      <div class="form-group">
        <label class="form-label">Building</label>
        <input class="form-control" id="nr-b" placeholder="Main Block">
      </div>
      <div class="form-group">
        <label class="form-label">Room Number</label>
        <input class="form-control" id="nr-r" placeholder="A101">
      </div>
      <div class="form-group">
        <label class="form-label">Floor</label>
        <input class="form-control" id="nr-f" placeholder="Ground">
      </div>
      <div class="form-group" style="grid-column:1/-1">
        <label class="form-label">Features (comma-separated)</label>
        <input class="form-control" id="nr-ft" placeholder="projector, ac, whiteboard">
      </div>
    </div>`,
  [
    { label:'+ Add Resource', cls:'btn-primary', action: async btn => {
      if (!val('#nr-n').trim()) { toast('Resource name is required','warning'); return; }
      const feats = {}; val('#nr-ft').split(',').map(s=>s.trim()).filter(Boolean).forEach(f=>{ feats[f.toLowerCase().replace(/\s+/g,'_')]=true; });
      setLoading(btn,true,'Adding…');
      const res = await call('add_resource', { resource_name:val('#nr-n'), resource_type:val('#nr-t'), capacity:val('#nr-c'), building:val('#nr-b'), room_number:val('#nr-r'), floor:val('#nr-f'), features:feats });
      setLoading(btn,false,'+ Add Resource');
      closeModal();
      if (res.success) { toast('Resource added!','success'); loadManageResources(); }
      else toast(res.error,'error');
    }},
    { label:'Cancel', cls:'btn-secondary', action: closeModal }
  ]);
}

async function chgStatus(id, cur) {
  const next = cur==='available'?'under_maintenance':'available';
  if (!confirm(`Change status to "${next.replace('_',' ')}"?`)) return;
  const res = await call('update_resource_status', { resource_id:id, status:next });
  if (res.success) { toast('Status updated.','success'); loadManageResources(); }
  else toast(res.error,'error');
}

// ── ALL BOOKINGS ───────────────────────────────────────────
async function loadAllBookings() {
  const el = qs('#p-all-bookings');
  el.innerHTML = loading();
  const list = await get('all_bookings');
  el.innerHTML = `
    <div class="sec-header"><div class="sec-title">All Bookings</div></div>
    <div class="card"><div class="card-body table-wrap">
      <table>
        <thead><tr><th>Resource</th><th>User</th><th>Date</th><th>Time</th><th>Purpose</th><th>Status</th><th></th></tr></thead>
        <tbody>${(list||[]).map(b=>`<tr>
          <td><strong>${esc(b.resource_name)}</strong></td>
          <td>${esc(b.user_name)}<br><span style="font-size:10px;color:var(--teal);text-transform:capitalize">${(b.user_role||'').replace('_',' ')}</span></td>
          <td>${b.booking_date}</td>
          <td style="white-space:nowrap;font-size:12px">${fmt(b.start_time)}–${fmt(b.end_time)}</td>
          <td style="max-width:130px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:12px">${esc(b.purpose||'—')}</td>
          <td>${badge(b.booking_status)}</td>
          <td>${b.booking_status==='confirmed'?`<button class="btn btn-sm btn-danger" onclick="doCancel(${b.booking_id})">Cancel</button>`:'—'}</td>
        </tr>`).join('')}</tbody>
      </table>
    </div></div>`;
}

// ── WAITLIST ───────────────────────────────────────────────
async function loadWaitlist() {
  const el = qs('#p-waitlist');
  el.innerHTML = loading();
  const list = await get('my_waitlist');
  el.innerHTML = `
    <div class="sec-header">
      <div><div class="sec-title">My Waitlist</div><div class="sec-sub">Auto-promoted when a slot opens</div></div>
    </div>
    <div class="card"><div class="card-body">
      ${(list||[]).length ? `<div class="table-wrap"><table>
        <thead><tr><th>Resource</th><th>Location</th><th>Date</th><th>Time Slot</th><th>Priority</th><th>Status</th></tr></thead>
        <tbody>${(list||[]).map(w=>`<tr>
          <td><strong>${esc(w.resource_name)}</strong></td>
          <td style="font-size:12px">${esc(w.building||'')}</td>
          <td>${w.requested_date}</td>
          <td style="font-family:var(--font-mono);font-size:12px">${fmt(w.requested_start)}–${fmt(w.requested_end)}</td>
          <td><span style="color:var(--teal);font-weight:700;font-family:var(--font-h)">${w.priority_score}</span><span style="color:var(--ink2);font-size:11px">/10</span></td>
          <td><span class="badge b-waiting">Waiting</span></td>
        </tr>`).join('')}</tbody>
      </table></div>` : `<div class="empty-state"><div class="empty-icon">⏳</div><p>You're not on any waitlists. When a requested slot is taken, the system adds you here automatically.</p></div>`}
    </div></div>`;
}

// ── NOTIFICATION PANEL ────────────────────────────────────
let notifOpen = false;
qs('#notif-btn').addEventListener('click', async () => {
  notifOpen = !notifOpen;
  const panel = qs('#notif-panel');
  if (notifOpen) {
    panel.classList.add('open');
    const list = await get('notifications');
    panel.innerHTML = `
      <div class="notif-panel-hd">
        <span>🔔 Notifications</span>
        <button class="btn btn-ghost btn-sm" onclick="markAllRead()">Mark all read</button>
      </div>
      ${(list||[]).slice(0,10).map(n=>`
        <div class="notif-item ${n.is_read?'':'unread'}">
          <div class="notif-type">${(n.notification_type||'').replace(/_/g,' ')}</div>
          <div class="notif-msg">${esc(n.message_body)}</div>
          <div class="notif-time">${(n.created_at||'').slice(0,16)}</div>
        </div>`).join('') || '<div style="padding:24px;text-align:center;color:var(--ink3);font-size:13px">No notifications</div>'}`;
  } else {
    panel.classList.remove('open');
  }
});
async function markAllRead() {
  await call('mark_read');
  qs('#notif-panel').classList.remove('open');
  notifOpen = false;
  clearNotifBadge();
}
document.addEventListener('click', e => {
  if (!e.target.closest('#notif-btn') && !e.target.closest('#notif-panel')) {
    qs('#notif-panel')?.classList.remove('open');
    notifOpen = false;
  }
});

// ── NOTIF POLLING ─────────────────────────────────────────
async function startNotifPoll() {
  const refresh = async () => {
    if (!G.user) return;
    const me = await get('me');
    if (!me || me.error) return;
    const cnt = me.unread || 0;
    const dot = qs('#notif-dot');
    const navBadge = qs('#nav-notif-badge');
    if (cnt > 0) {
      if (dot) dot.style.display = 'block';
      if (navBadge) { navBadge.style.display = 'inline-flex'; navBadge.textContent = cnt > 9 ? '9+' : cnt; }
    } else {
      clearNotifBadge();
    }
  };
  refresh();
  setInterval(refresh, 30000);
}
function clearNotifBadge() {
  const dot = qs('#notif-dot');
  const nb  = qs('#nav-notif-badge');
  if (dot) dot.style.display = 'none';
  if (nb)  nb.style.display = 'none';
}

// ── MODAL ENGINE ──────────────────────────────────────────
function modal(title, body, btns = []) {
  closeModal();
  const ov = document.createElement('div');
  ov.className = 'modal-overlay'; ov.id = 'the-modal';
  ov.innerHTML = `<div class="modal">
    <div class="modal-header">
      <span class="modal-title">${title}</span>
      <button class="modal-close" onclick="closeModal()">✕</button>
    </div>
    <div class="modal-body">
      ${body}
      <div class="modal-footer">
        ${btns.map((b,i)=>`<button class="btn ${b.cls}" id="mb${i}">${b.label}</button>`).join('')}
      </div>
    </div>
  </div>`;
  document.body.appendChild(ov);
  ov.addEventListener('click', e => { if(e.target===ov) closeModal(); });
  btns.forEach((b,i) => qs(`#mb${i}`)?.addEventListener('click', e => b.action(e.currentTarget)));
}
function closeModal() { qs('#the-modal')?.remove(); }

// ── UTILS ──────────────────────────────────────────────────
function qs(s)    { return document.querySelector(s); }
function qsa(s)   { return document.querySelectorAll(s); }
function val(s)   { return (qs(s)?.value||'').trim(); }
function esc(s)   { return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function today()  { return new Date().toISOString().slice(0,10); }
function fmt(t)   { return (t||'').slice(0,5); }
function hasRole(...r) { return r.includes(G.user?.role); }
function show(s, v) { const e=qs(s); if(e) e.style.display=v?'flex':'none'; }
function loading(msg='Loading…') {
  return `<div class="loading-state"><span class="spinner"></span>${msg}</div>`;
}
function setLoading(btn, on, label) {
  if (!btn) return;
  btn.disabled = on;
  btn.innerHTML = on ? `<span class="spinner"></span> ${label}` : label;
}
function typeIcon(t) {
  return { classroom:'🏫', laboratory:'🔬', equipment:'📦', event_space:'🎭', sports_facility:'🏟️', study_room:'📚' }[t] || '🏢';
}
function badge(s) {
  const map = { confirmed:'b-confirmed', active:'b-active', completed:'b-completed', cancelled:'b-cancelled', no_show:'b-no_show', pending:'b-waiting' };
  return `<span class="badge ${map[s]||'b-waiting'}">${s?.replace('_',' ')||'—'}</span>`;
}

// ── MOBILE HAMBURGER ──────────────────────────────────────
qs('#ham')?.addEventListener('click', () => qs('#sidebar').classList.toggle('open'));

// ── LOGOUT ────────────────────────────────────────────────
qs('#logout-btn').addEventListener('click', async () => {
  await call('logout');
  G.user = null;
  showAuth();
});

// ── AUTO LOGIN CHECK ──────────────────────────────────────
(async () => {
  const me = await get('me');
  if (me && me.user_id && !me.error) {
    G.user = me;
    bootApp();
  }
})();
