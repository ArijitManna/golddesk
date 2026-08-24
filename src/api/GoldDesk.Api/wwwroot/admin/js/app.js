(() => {
  const app = document.getElementById('app');
  let route = parseRoute();
  let toastTimer = null;

  window.addEventListener('hashchange', () => {
    route = parseRoute();
    render();
  });

  function parseRoute() {
    const hash = (location.hash || '#/dashboard').replace(/^#/, '');
    const [path, query = ''] = hash.split('?');
    const params = Object.fromEntries(new URLSearchParams(query));
    return { path: path || '/dashboard', params };
  }

  function go(path) {
    location.hash = path.startsWith('#') ? path : `#${path}`;
  }

  function toast(message) {
    let el = document.querySelector('.toast');
    if (!el) {
      el = document.createElement('div');
      el.className = 'toast';
      document.body.appendChild(el);
    }
    el.textContent = message;
    el.classList.remove('hidden');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => el.classList.add('hidden'), 2800);
  }

  function formatDate(value) {
    if (!value) return '—';
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return String(value).split('T')[0];
    return d.toLocaleString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    });
  }

  function typeBadge(type) {
    const key = (type || 'Shop').toLowerCase();
    return `<span class="badge badge-${key}">${type || 'Shop'}</span>`;
  }

  function statusBadge(status) {
    const cls = status === 'Active' ? 'badge-active' : 'badge-pending';
    return `<span class="badge ${cls}">${status || 'Pending'}</span>`;
  }

  function escapeHtml(str) {
    return String(str ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
  }

  async function render() {
    if (!AdminApi.isLoggedIn() && route.path !== '/login') {
      go('/login');
      return;
    }
    if (AdminApi.isLoggedIn() && route.path === '/login') {
      go('/dashboard');
      return;
    }

    if (route.path === '/login') {
      app.innerHTML = renderLogin();
      bindLogin();
      return;
    }

    const user = AdminApi.getUser();
    const title = pageTitle(route.path);
    app.innerHTML = `
      <div class="app-shell">
        ${renderSidebar(user, route.path)}
        <div class="main">
          <header class="topbar">
            <h2>${title}</h2>
            <div class="topbar-actions">
              <span style="color:var(--muted);font-size:13px">${escapeHtml(user?.email || '')}</span>
              <button class="btn btn-ghost btn-sm" id="logoutBtn">Logout</button>
            </div>
          </header>
          <div class="content" id="pageContent">
            <div class="empty">Loading...</div>
          </div>
        </div>
      </div>
    `;

    document.getElementById('logoutBtn').onclick = () => {
      AdminApi.logout();
      go('/login');
    };

    try {
      if (route.path === '/dashboard') await renderDashboard();
      else if (route.path === '/requests') await renderRequests();
      else if (route.path === '/businesses') await renderBusinesses();
      else if (route.path === '/settings') renderSettings();
      else go('/dashboard');
    } catch (err) {
      if (err.status === 401) {
        AdminApi.logout();
        go('/login');
        return;
      }
      document.getElementById('pageContent').innerHTML =
        `<div class="error-banner">${escapeHtml(err.message)}</div>`;
    }
  }

  function pageTitle(path) {
    if (path === '/dashboard') return 'Dashboard';
    if (path === '/requests') {
      const t = route.params.type;
      if (t === 'Shop') return 'Shop Requests';
      if (t === 'Karigar') return 'Karigar Requests';
      if (t === 'Showroom') return 'Showroom Requests';
      return 'All Requests';
    }
    if (path === '/businesses') return 'Businesses';
    if (path === '/settings') return 'Settings';
    return 'Admin';
  }

  function renderSidebar(user, path) {
    const type = route.params.type;
    const reqActive = path === '/requests';
    const initial = (user?.fullName || 'A').charAt(0).toUpperCase();
    return `
      <aside class="sidebar">
        <div class="sidebar-brand">
          <img src="/admin/assets/logo.png" alt="GoldDesk" />
          <div>
            <strong>GOLDDESK</strong>
            <span>Platform Admin</span>
          </div>
        </div>
        <div class="nav-section">Main</div>
        <a class="nav-item ${path === '/dashboard' ? 'active' : ''}" href="#/dashboard">
          <span class="icon">◆</span> Dashboard
        </a>
        <div class="nav-section">Requests</div>
        <a class="nav-item ${reqActive && type === 'Shop' ? 'active' : ''}" href="#/requests?type=Shop">
          <span class="icon">●</span> Shop Requests
        </a>
        <a class="nav-item ${reqActive && type === 'Karigar' ? 'active' : ''}" href="#/requests?type=Karigar">
          <span class="icon">●</span> Karigar Requests
        </a>
        <a class="nav-item ${reqActive && type === 'Showroom' ? 'active' : ''}" href="#/requests?type=Showroom">
          <span class="icon">●</span> Showroom Requests
        </a>
        <div class="nav-section">Management</div>
        <a class="nav-item ${path === '/businesses' ? 'active' : ''}" href="#/businesses">
          <span class="icon">■</span> Businesses
        </a>
        <div class="nav-section">Settings</div>
        <a class="nav-item ${path === '/settings' ? 'active' : ''}" href="#/settings">
          <span class="icon">◎</span> Settings
        </a>
        <div class="sidebar-footer">
          <div class="avatar">${initial}</div>
          <div class="meta">
            <strong>${escapeHtml(user?.fullName || 'Admin')}</strong>
            <span>Super Admin</span>
          </div>
        </div>
      </aside>
    `;
  }

  function renderLogin() {
    return `
      <div class="login-page">
        <div class="login-card">
          <img class="login-logo" src="/admin/assets/logo.png" alt="GoldDesk" />
          <h1>GoldDesk Admin</h1>
          <p class="subtitle">Sign in with your Super Admin account</p>
          <div id="loginError" class="error-banner hidden"></div>
          <form id="loginForm">
            <div class="form-group">
              <label for="email">Email</label>
              <input id="email" type="email" autocomplete="username" required placeholder="admin@golddesk.com" />
            </div>
            <div class="form-group">
              <label for="password">Password</label>
              <input id="password" type="password" autocomplete="current-password" required placeholder="••••••••" />
            </div>
            <button class="btn btn-primary" id="loginBtn" type="submit">Sign In</button>
          </form>
        </div>
      </div>
    `;
  }

  function bindLogin() {
    const form = document.getElementById('loginForm');
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const btn = document.getElementById('loginBtn');
      const err = document.getElementById('loginError');
      err.classList.add('hidden');
      btn.disabled = true;
      btn.textContent = 'Signing in...';
      try {
        await AdminApi.login(
          document.getElementById('email').value.trim(),
          document.getElementById('password').value
        );
        go('/dashboard');
      } catch (ex) {
        err.textContent = ex.message || 'Login failed';
        err.classList.remove('hidden');
        btn.disabled = false;
        btn.textContent = 'Sign In';
      }
    });
  }

  async function renderDashboard() {
    const report = await AdminApi.getReport();
    const el = document.getElementById('pageContent');
    el.innerHTML = `
      <div class="cards">
        <div class="stat-card shop">
          <div class="label">Pending Shop Requests</div>
          <div class="value">${report.pendingShopCount ?? 0}</div>
          <p>Total pending shop registrations</p>
          <a href="#/requests?type=Shop">View Shop Requests →</a>
        </div>
        <div class="stat-card karigar">
          <div class="label">Pending Karigar Requests</div>
          <div class="value">${report.pendingKarigarCount ?? 0}</div>
          <p>Total pending karigar registrations</p>
          <a href="#/requests?type=Karigar">View Karigar Requests →</a>
        </div>
        <div class="stat-card showroom">
          <div class="label">Pending Showroom Requests</div>
          <div class="value">${report.pendingShowroomCount ?? 0}</div>
          <p>Total pending showroom registrations</p>
          <a href="#/requests?type=Showroom">View Showroom Requests →</a>
        </div>
      </div>
      <div class="cards">
        <div class="stat-card">
          <div class="label">Registered Shops</div>
          <div class="value" style="color:var(--navy)">${report.shopCount ?? 0}</div>
          <p>Active & pending shops</p>
          <a href="#/businesses?type=Shop">View Shops →</a>
        </div>
        <div class="stat-card">
          <div class="label">Registered Showrooms</div>
          <div class="value" style="color:var(--gold)">${report.showroomCount ?? 0}</div>
          <p>Active & pending showrooms</p>
          <a href="#/businesses?type=Showroom">View Showrooms →</a>
        </div>
        <div class="stat-card">
          <div class="label">Registered Karigars</div>
          <div class="value" style="color:var(--blue)">${report.karigarCount ?? 0}</div>
          <p>Active & pending karigars</p>
          <a href="#/businesses?type=Karigar">View Karigars →</a>
        </div>
      </div>
    `;
  }

  async function renderRequests() {
    const type = route.params.type || '';
    const items = await AdminApi.getPending(type || null);
    const el = document.getElementById('pageContent');

    el.innerHTML = `
      <div class="tabs">
        <button class="tab ${!type ? 'active' : ''}" data-type="">All</button>
        <button class="tab ${type === 'Shop' ? 'active' : ''}" data-type="Shop">Shop</button>
        <button class="tab ${type === 'Karigar' ? 'active' : ''}" data-type="Karigar">Karigar</button>
        <button class="tab ${type === 'Showroom' ? 'active' : ''}" data-type="Showroom">Showroom</button>
      </div>
      <div class="panel" style="margin-top:12px">
        <div class="panel-header">
          <h3>Pending Requests (${items.length})</h3>
        </div>
        <div class="table-wrap">
          ${items.length === 0 ? `<div class="empty">No pending registrations</div>` : `
          <table>
            <thead>
              <tr>
                <th>Business Name</th>
                <th>Type</th>
                <th>Contact Person</th>
                <th>Mobile</th>
                <th>Email</th>
                <th>Request Date</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              ${items.map(row => `
                <tr data-id="${row.tenantId}">
                  <td><strong>${escapeHtml(row.shopName)}</strong></td>
                  <td>${typeBadge(row.businessType)}</td>
                  <td>${escapeHtml(row.ownerName)}</td>
                  <td>${escapeHtml(row.mobile)}</td>
                  <td>${escapeHtml(row.email)}</td>
                  <td>${formatDate(row.registeredAt)}</td>
                  <td>${statusBadge('Pending')}</td>
                  <td class="actions">
                    <button class="btn btn-success btn-sm" data-approve="${row.tenantId}">Approve</button>
                    <button class="btn btn-danger btn-sm" data-reject="${row.tenantId}" data-name="${escapeHtml(row.shopName)}">Reject</button>
                  </td>
                </tr>
              `).join('')}
            </tbody>
          </table>`}
        </div>
      </div>
    `;

    el.querySelectorAll('.tab').forEach(btn => {
      btn.onclick = () => {
        const t = btn.dataset.type;
        go(t ? `/requests?type=${t}` : '/requests');
      };
    });

    el.querySelectorAll('[data-approve]').forEach(btn => {
      btn.onclick = async () => {
        btn.disabled = true;
        try {
          await AdminApi.approve(btn.dataset.approve);
          toast('Registration approved');
          await renderRequests();
        } catch (err) {
          toast(err.message);
          btn.disabled = false;
        }
      };
    });

    el.querySelectorAll('[data-reject]').forEach(btn => {
      btn.onclick = () => openRejectModal(btn.dataset.reject, btn.dataset.name);
    });
  }

  function openRejectModal(tenantId, name) {
    const backdrop = document.createElement('div');
    backdrop.className = 'modal-backdrop';
    backdrop.innerHTML = `
      <div class="modal">
        <h3>Reject ${escapeHtml(name)}</h3>
        <p>Please provide a reason for rejection.</p>
        <textarea id="rejectReason" placeholder="Enter reason"></textarea>
        <div class="modal-actions">
          <button class="btn btn-ghost btn-sm" id="cancelReject">Cancel</button>
          <button class="btn btn-danger btn-sm" id="confirmReject">Reject</button>
        </div>
      </div>
    `;
    document.body.appendChild(backdrop);
    backdrop.querySelector('#cancelReject').onclick = () => backdrop.remove();
    backdrop.querySelector('#confirmReject').onclick = async () => {
      const reason = backdrop.querySelector('#rejectReason').value.trim();
      if (!reason) {
        toast('Reason is required');
        return;
      }
      try {
        await AdminApi.reject(tenantId, reason);
        backdrop.remove();
        toast('Registration rejected');
        await renderRequests();
      } catch (err) {
        toast(err.message);
      }
    };
  }

  async function renderBusinesses() {
    const type = route.params.type || '';
    const report = await AdminApi.getReport(type || null);
    const shops = report.shops || [];
    const el = document.getElementById('pageContent');

    el.innerHTML = `
      <div class="filters">
        <select id="bizType">
          <option value="">All types</option>
          <option value="Shop" ${type === 'Shop' ? 'selected' : ''}>Shop</option>
          <option value="Showroom" ${type === 'Showroom' ? 'selected' : ''}>Showroom</option>
          <option value="Karigar" ${type === 'Karigar' ? 'selected' : ''}>Karigar</option>
        </select>
      </div>
      <div class="panel">
        <div class="panel-header">
          <h3>${type || 'All'} Businesses (${shops.length})</h3>
        </div>
        <div class="table-wrap">
          ${shops.length === 0 ? `<div class="empty">No businesses found</div>` : `
          <table>
            <thead>
              <tr>
                <th>Business Name</th>
                <th>Type</th>
                <th>Owner</th>
                <th>Mobile</th>
                <th>Status</th>
                <th>Registered</th>
              </tr>
            </thead>
            <tbody>
              ${shops.map(row => `
                <tr>
                  <td><strong>${escapeHtml(row.shopName)}</strong></td>
                  <td>${typeBadge(row.businessType)}</td>
                  <td>${escapeHtml(row.ownerName)}</td>
                  <td>${escapeHtml(row.mobile)}</td>
                  <td>${statusBadge(row.status)}</td>
                  <td>${formatDate(row.registeredAt)}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>`}
        </div>
      </div>
    `;

    document.getElementById('bizType').onchange = (e) => {
      const v = e.target.value;
      go(v ? `/businesses?type=${v}` : '/businesses');
    };
  }

  function renderSettings() {
    const user = AdminApi.getUser();
    document.getElementById('pageContent').innerHTML = `
      <div class="panel">
        <div class="panel-header"><h3>Admin Profile</h3></div>
        <div style="padding:18px;font-size:14px;line-height:1.8">
          <div><strong>Name:</strong> ${escapeHtml(user?.fullName || '—')}</div>
          <div><strong>Email:</strong> ${escapeHtml(user?.email || '—')}</div>
          <div><strong>Role:</strong> Super Admin</div>
          <div style="margin-top:12px;color:var(--muted)">
            App updates are managed via the <code>AppVersions</code> table and APKs in <code>/output</code>.
          </div>
        </div>
      </div>
    `;
  }

  render();
})();
