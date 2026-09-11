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
    if (!value) return '?';
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
    if (status === 'Suspended') {
      return '<span class="badge badge-inactive">Inactive</span>';
    }
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
      else if (route.path === '/version-control') await renderVersionControl();
      else if (route.path === '/api-timing') await renderApiTiming();
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
    if (path === '/version-control') return 'Version Control';
    if (path === '/api-timing') return 'API Timing';
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
          <span class="icon">D</span> Dashboard
        </a>
        <div class="nav-section">Requests</div>
        <a class="nav-item ${reqActive && type === 'Shop' ? 'active' : ''}" href="#/requests?type=Shop">
          <span class="icon">S</span> Shop Requests
        </a>
        <a class="nav-item ${reqActive && type === 'Karigar' ? 'active' : ''}" href="#/requests?type=Karigar">
          <span class="icon">K</span> Karigar Requests
        </a>
        <a class="nav-item ${reqActive && type === 'Showroom' ? 'active' : ''}" href="#/requests?type=Showroom">
          <span class="icon">H</span> Showroom Requests
        </a>
        <div class="nav-section">Management</div>
        <a class="nav-item ${path === '/businesses' ? 'active' : ''}" href="#/businesses">
          <span class="icon">B</span> Businesses
        </a>
        <a class="nav-item ${path === '/version-control' ? 'active' : ''}" href="#/version-control">
          <span class="icon">V</span> Version Control
        </a>
        <a class="nav-item ${path === '/api-timing' ? 'active' : ''}" href="#/api-timing">
          <span class="icon">T</span> API Timing
        </a>
        <div class="nav-section">Settings</div>
        <a class="nav-item ${path === '/settings' ? 'active' : ''}" href="#/settings">
          <span class="icon">G</span> Settings
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
              <input id="password" type="password" autocomplete="current-password" required placeholder="????????" />
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
          <a href="#/requests?type=Shop">View Shop Requests ?</a>
        </div>
        <div class="stat-card karigar">
          <div class="label">Pending Karigar Requests</div>
          <div class="value">${report.pendingKarigarCount ?? 0}</div>
          <p>Total pending karigar registrations</p>
          <a href="#/requests?type=Karigar">View Karigar Requests ?</a>
        </div>
        <div class="stat-card showroom">
          <div class="label">Pending Showroom Requests</div>
          <div class="value">${report.pendingShowroomCount ?? 0}</div>
          <p>Total pending showroom registrations</p>
          <a href="#/requests?type=Showroom">View Showroom Requests ?</a>
        </div>
      </div>
      <div class="cards">
        <div class="stat-card">
          <div class="label">Active Shops</div>
          <div class="value" style="color:var(--navy)">${report.shopCount ?? 0}</div>
          <p>Currently active shops</p>
          <a href="#/businesses?type=Shop">View Shops ?</a>
        </div>
        <div class="stat-card">
          <div class="label">Active Showrooms</div>
          <div class="value" style="color:var(--gold)">${report.showroomCount ?? 0}</div>
          <p>Currently active showrooms</p>
          <a href="#/businesses?type=Showroom">View Showrooms ?</a>
        </div>
        <div class="stat-card">
          <div class="label">Active Karigars</div>
          <div class="value" style="color:var(--blue)">${report.karigarCount ?? 0}</div>
          <p>Currently active karigars</p>
          <a href="#/businesses?type=Karigar">View Karigars ?</a>
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
    const showInactive = route.params.inactive === '1';
    const report = await AdminApi.getReport(type || null, showInactive);
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
        <label class="toggle">
          <input type="checkbox" id="showInactive" ${showInactive ? 'checked' : ''} />
          <span class="toggle-ui"></span>
          <span>Show inactive</span>
        </label>
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
                <th>Actions</th>
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
                  <td class="actions">
                    ${row.status === 'Active'
                      ? `<button class="btn btn-danger btn-sm" data-deactivate="${row.tenantId}" data-name="${escapeHtml(row.shopName)}">Inactivate</button>`
                      : row.status === 'Suspended'
                        ? `<button class="btn btn-success btn-sm" data-activate="${row.tenantId}" data-name="${escapeHtml(row.shopName)}">Activate</button>`
                        : '<span style="color:var(--muted);font-size:12px">?</span>'}
                  </td>
                </tr>
              `).join('')}
            </tbody>
          </table>`}
        </div>
      </div>
    `;

    document.getElementById('bizType').onchange = (e) => {
      const v = e.target.value;
      const inactive = document.getElementById('showInactive').checked ? '&inactive=1' : '';
      if (v) go(`/businesses?type=${v}${inactive}`);
      else go(`/businesses${inactive ? '?inactive=1' : ''}`);
    };

    document.getElementById('showInactive').onchange = (e) => {
      const inactive = e.target.checked ? 'inactive=1' : '';
      const typeParam = type ? `type=${type}${inactive ? '&' + inactive : ''}` : inactive;
      go(typeParam ? `/businesses?${typeParam}` : '/businesses');
    };

    el.querySelectorAll('[data-deactivate]').forEach(btn => {
      btn.onclick = () => openStatusModal(btn.dataset.deactivate, btn.dataset.name, false);
    });

    el.querySelectorAll('[data-activate]').forEach(btn => {
      btn.onclick = () => openStatusModal(btn.dataset.activate, btn.dataset.name, true);
    });
  }

  function openStatusModal(tenantId, name, activate) {
    const backdrop = document.createElement('div');
    backdrop.className = 'modal-backdrop';
    backdrop.innerHTML = `
      <div class="modal">
        <h3>${activate ? 'Activate' : 'Inactivate'} ${escapeHtml(name)}?</h3>
        <p>${activate
          ? 'This business and its owner login will be enabled again.'
          : 'This business will be disabled and users will not be able to log in.'}</p>
        <div class="modal-actions">
          <button class="btn btn-ghost btn-sm" id="cancelStatus">Cancel</button>
          <button class="btn ${activate ? 'btn-success' : 'btn-danger'} btn-sm" id="confirmStatus">
            ${activate ? 'Activate' : 'Inactivate'}
          </button>
        </div>
      </div>
    `;
    document.body.appendChild(backdrop);
    backdrop.querySelector('#cancelStatus').onclick = () => backdrop.remove();
    backdrop.querySelector('#confirmStatus').onclick = async () => {
      try {
        if (activate) await AdminApi.activateBusiness(tenantId);
        else await AdminApi.deactivateBusiness(tenantId);
        backdrop.remove();
        toast(activate ? 'Business activated' : 'Business inactivated');
        await renderBusinesses();
      } catch (err) {
        toast(err.message);
      }
    };
  }

  function renderSettings() {
    const user = AdminApi.getUser();
    document.getElementById('pageContent').innerHTML = `
      <div class="panel">
        <div class="panel-header"><h3>Admin Profile</h3></div>
        <div style="padding:18px;font-size:14px;line-height:1.8">
          <div><strong>Name:</strong> ${escapeHtml(user?.fullName || '?')}</div>
          <div><strong>Email:</strong> ${escapeHtml(user?.email || '?')}</div>
          <div><strong>Role:</strong> Super Admin</div>
          <div style="margin-top:12px;color:var(--muted)">
            Manage Android APK updates from <a href="#/version-control" style="color:var(--blue);font-weight:600">Version Control</a>.
          </div>
        </div>
      </div>
    `;
  }

  function formatBytes(bytes) {
    if (bytes == null || Number.isNaN(Number(bytes))) return '?';
    const n = Number(bytes);
    if (n < 1024) return `${n} B`;
    if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
    return `${(n / (1024 * 1024)).toFixed(1)} MB`;
  }

  async function renderVersionControl() {
    const el = document.getElementById('pageContent');
    el.innerHTML = `<div class="empty">Loading version info...</div>`;

    let current;
    let history = [];
    try {
      [current, history] = await Promise.all([
        AdminApi.getCurrentAppVersion(),
        AdminApi.getAppVersionHistory()
      ]);
    } catch (err) {
      el.innerHTML = `<div class="error-banner">${escapeHtml(err.message)}</div>`;
      return;
    }

    el.innerHTML = `
      <div class="cards" style="margin-bottom:16px">
        <div class="stat-card">
          <div class="label">Current App Version</div>
          <div class="value" style="font-size:28px;color:var(--navy)">${escapeHtml(current.currentVersion || 'Not set')}</div>
          <p>${current.forceUpdate ? 'Force update is ON' : 'Force update is OFF'}</p>
        </div>
        <div class="stat-card">
          <div class="label">APK on Server</div>
          <div class="value" style="font-size:18px;color:var(--gold)">${escapeHtml(current.apk?.fileName || 'No APK')}</div>
          <p>${current.apk ? `${formatBytes(current.apk.sizeBytes)} ? updated ${formatDate(current.apk.lastModifiedUtc)}` : 'Upload an APK below'}</p>
        </div>
        <div class="stat-card">
          <div class="label">Download URL</div>
          <div style="font-size:12px;word-break:break-all;margin-top:8px;color:var(--muted)">${escapeHtml(current.downloadUrl || '?')}</div>
        </div>
      </div>

      <div class="panel" style="margin-bottom:16px">
        <div class="panel-header"><h3>Publish New Version</h3></div>
        <div style="padding:18px">
          <div class="form-group">
            <label for="vcVersion">Version *</label>
            <input id="vcVersion" type="text" placeholder="e.g. 1.0.1" value="" />
          </div>
          <div class="form-group">
            <label for="vcNotes">Release Notes</label>
            <textarea id="vcNotes" placeholder="What changed in this build"></textarea>
          </div>
          <div class="form-group">
            <label for="vcApk">APK File (.apk)</label>
            <input id="vcApk" type="file" accept=".apk,application/vnd.android.package-archive" />
            <div style="margin-top:6px;font-size:12px;color:var(--muted)">Saved as golddesk.apk under /output. Max 200MB.</div>
          </div>
          <label class="toggle" style="margin:12px 0 18px">
            <input id="vcForce" type="checkbox" />
            <span class="toggle-ui"></span>
            <span>Force update (users must install before continuing)</span>
          </label>
          <button class="btn btn-primary" id="vcPublishBtn" type="button" style="width:auto;min-width:180px">Publish Version</button>
          <div id="vcPublishMsg" class="error-banner hidden" style="margin-top:12px"></div>
        </div>
      </div>

      <div class="panel">
        <div class="panel-header"><h3>Version History</h3></div>
        <div class="table-wrap">
          ${history.length === 0 ? `<div class="empty">No versions published yet</div>` : `
          <table>
            <thead>
              <tr>
                <th>Version</th>
                <th>Force</th>
                <th>Notes</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              ${history.map(row => `
                <tr>
                  <td><strong>${escapeHtml(row.version)}</strong></td>
                  <td>${row.forceUpdate ? '<span class="badge badge-pending">Force</span>' : '<span class="badge badge-active">Optional</span>'}</td>
                  <td>${escapeHtml(row.releaseNotes || '?')}</td>
                  <td>${formatDate(row.createdAt)}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>`}
        </div>
      </div>
    `;

    const msg = document.getElementById('vcPublishMsg');
    document.getElementById('vcPublishBtn').onclick = async () => {
      const version = document.getElementById('vcVersion').value.trim();
      const releaseNotes = document.getElementById('vcNotes').value.trim();
      const forceUpdate = document.getElementById('vcForce').checked;
      const apkInput = document.getElementById('vcApk');
      const apkFile = apkInput.files && apkInput.files[0] ? apkInput.files[0] : null;
      const btn = document.getElementById('vcPublishBtn');

      msg.classList.add('hidden');
      if (!version) {
        msg.textContent = 'Version is required';
        msg.classList.remove('hidden');
        return;
      }
      if (apkFile && !apkFile.name.toLowerCase().endsWith('.apk')) {
        msg.textContent = 'Only .apk files are allowed';
        msg.classList.remove('hidden');
        return;
      }

      btn.disabled = true;
      btn.textContent = 'Publishing...';
      try {
        const result = await AdminApi.publishAppVersion({
          version,
          forceUpdate,
          releaseNotes: releaseNotes || null,
          apkFile
        });
        toast(result.message || 'Version published');
        await renderVersionControl();
      } catch (err) {
        msg.textContent = err.message || 'Publish failed';
        msg.classList.remove('hidden');
        btn.disabled = false;
        btn.textContent = 'Publish Version';
      }
    };
  }

  async function renderApiTiming(preset = {}) {
    const root = document.getElementById('pageContent');
    const today = new Date().toISOString().slice(0, 10);
    const filters = {
      fromDate: preset.fromDate ?? today,
      toDate: preset.toDate ?? today,
      minMs: preset.minMs ?? '',
      take: preset.take ?? 100
    };

    root.innerHTML = `<div class="loading">Loading API timing...</div>`;
    try {
      const data = await AdminApi.getApiTiming(filters);
      const summary = data.summary || {};
      const byEndpoint = data.byEndpoint || [];
      const recent = data.recent || [];

      const msClass = (ms) => {
        if (ms >= 2000) return 'timing-bad';
        if (ms >= 500) return 'timing-warn';
        return 'timing-ok';
      };
      const rowClass = (ms) => {
        if (ms >= 2000) return 'timing-row-bad';
        if (ms >= 500) return 'timing-row-warn';
        return '';
      };

      root.innerHTML = `
        <div class="cards" style="margin-bottom:16px">
          <div class="stat-card">
            <div class="label">Total logged calls</div>
            <div class="value">${summary.totalCount ?? 0}</div>
          </div>
          <div class="stat-card">
            <div class="label">Filtered calls</div>
            <div class="value">${summary.filteredCount ?? 0}</div>
          </div>
          <div class="stat-card">
            <div class="label">Avg ms (window)</div>
            <div class="value ${msClass(summary.avgMsWindow || 0)}">${summary.avgMsWindow ?? 0}</div>
          </div>
        </div>

        <div class="panel" style="margin-bottom:16px">
          <div class="panel-header" style="display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap">
            <div>
              <h3 style="margin:0">API Response Timing</h3>
              <p style="margin:4px 0 0;color:var(--muted);font-size:13px">Tracks /api and /app-version request durations.</p>
              <div class="timing-legend">
                <span class="timing-ok">&lt; 500ms OK</span>
                <span class="timing-warn">500-1999ms Slow</span>
                <span class="timing-bad">&gt;= 2000ms High</span>
              </div>
            </div>
            <div style="display:flex;gap:8px">
              <button class="btn btn-secondary" id="apiTimingRefresh" type="button">Apply</button>
              <button class="btn btn-danger" id="apiTimingFlash" type="button">Flash Data</button>
            </div>
          </div>
          <div class="filters" style="padding:14px 18px;display:flex;gap:10px;flex-wrap:wrap;align-items:end">
            <div class="form-group" style="margin:0">
              <label for="timingFrom">From date</label>
              <input id="timingFrom" type="date" value="${escapeHtml(filters.fromDate)}" />
            </div>
            <div class="form-group" style="margin:0">
              <label for="timingTo">To date</label>
              <input id="timingTo" type="date" value="${escapeHtml(filters.toDate)}" />
            </div>
            <div class="form-group" style="margin:0">
              <label for="timingMinMs">Min response (ms)</label>
              <input id="timingMinMs" type="number" min="0" step="100" placeholder="e.g. 1000" value="${escapeHtml(filters.minMs)}" />
            </div>
            <div class="form-group" style="margin:0">
              <label for="timingTake">Rows</label>
              <select id="timingTake">
                ${[50, 100, 200, 500].map(n => `<option value="${n}" ${Number(filters.take) === n ? 'selected' : ''}>${n}</option>`).join('')}
              </select>
            </div>
            <button class="btn btn-secondary" id="timingHighOnly" type="button">High only (&gt;=2s)</button>
          </div>
        </div>

        <div class="panel" style="margin-bottom:16px">
          <h3>Slowest endpoints</h3>
          <div class="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Method</th>
                  <th>Path</th>
                  <th>Calls</th>
                  <th>Avg ms</th>
                  <th>Min</th>
                  <th>Max</th>
                </tr>
              </thead>
              <tbody>
                ${byEndpoint.length === 0 ? `<tr><td colspan="6">No data for this filter.</td></tr>` : byEndpoint.map(row => `
                  <tr class="${rowClass(row.avgMs)}">
                    <td>${escapeHtml(row.method)}</td>
                    <td><code>${escapeHtml(row.path)}</code></td>
                    <td>${row.count}</td>
                    <td class="${msClass(row.avgMs)}">${row.avgMs}</td>
                    <td>${row.minMs}</td>
                    <td class="${msClass(row.maxMs)}">${row.maxMs}</td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
        </div>

        <div class="panel">
          <h3>Calls (sorted by slowest)</h3>
          <div class="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Time</th>
                  <th>Method</th>
                  <th>Path</th>
                  <th>Status</th>
                  <th>ms</th>
                </tr>
              </thead>
              <tbody>
                ${recent.length === 0 ? `<tr><td colspan="5">No recent calls for this filter.</td></tr>` : recent.map(row => `
                  <tr class="${rowClass(row.durationMs)}">
                    <td>${escapeHtml(formatDate(row.createdAt))}</td>
                    <td>${escapeHtml(row.method)}</td>
                    <td><code>${escapeHtml(row.path)}</code></td>
                    <td>${row.statusCode}</td>
                    <td class="${msClass(row.durationMs)}">${row.durationMs}</td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
          </div>
        </div>
      `;

      const readFilters = () => ({
        fromDate: document.getElementById('timingFrom').value || '',
        toDate: document.getElementById('timingTo').value || '',
        minMs: document.getElementById('timingMinMs').value || '',
        take: Number(document.getElementById('timingTake').value || 100)
      });

      document.getElementById('apiTimingRefresh').onclick = () => renderApiTiming(readFilters());
      document.getElementById('timingHighOnly').onclick = () => {
        const next = readFilters();
        next.minMs = '2000';
        renderApiTiming(next);
      };
      document.getElementById('apiTimingFlash').onclick = async () => {
        const ok = confirm('Permanently delete ALL API timing data from the database? This cannot be undone.');
        if (!ok) return;
        try {
          const result = await AdminApi.flashApiTiming();
          toast(result.message ? `${result.message} (${result.deleted} rows)` : 'Timing data deleted');
          await renderApiTiming(readFilters());
        } catch (err) {
          toast(err.message || 'Flash failed');
        }
      };
    } catch (err) {
      root.innerHTML = `<div class="error-banner">${escapeHtml(err.message)}</div>`;
    }
  }

  render();
})();

