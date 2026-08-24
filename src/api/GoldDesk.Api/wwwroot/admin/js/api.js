const AdminApi = (() => {
  const TOKEN_KEY = 'gd_admin_token';
  const REFRESH_KEY = 'gd_admin_refresh';
  const USER_KEY = 'gd_admin_user';

  function getToken() {
    return sessionStorage.getItem(TOKEN_KEY);
  }

  function getUser() {
    const raw = sessionStorage.getItem(USER_KEY);
    return raw ? JSON.parse(raw) : null;
  }

  function saveSession(data) {
    sessionStorage.setItem(TOKEN_KEY, data.accessToken);
    sessionStorage.setItem(REFRESH_KEY, data.refreshToken);
    sessionStorage.setItem(USER_KEY, JSON.stringify(data.user));
  }

  function clearSession() {
    sessionStorage.removeItem(TOKEN_KEY);
    sessionStorage.removeItem(REFRESH_KEY);
    sessionStorage.removeItem(USER_KEY);
  }

  function isLoggedIn() {
    const user = getUser();
    return !!(getToken() && user && user.role === 'SuperAdmin');
  }

  async function request(path, options = {}) {
    const headers = {
      'Content-Type': 'application/json',
      ...(options.headers || {})
    };
    const token = getToken();
    if (token) headers.Authorization = `Bearer ${token}`;

    const response = await fetch(path, { ...options, headers });
    const text = await response.text();
    let body = null;
    try { body = text ? JSON.parse(text) : null; } catch { body = text; }

    if (!response.ok) {
      const message = body?.error || body?.detail || body?.title || `Request failed (${response.status})`;
      const err = new Error(message);
      err.status = response.status;
      throw err;
    }
    return body;
  }

  async function login(email, password) {
    const data = await request('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password })
    });

    if (!data?.user || data.user.role !== 'SuperAdmin') {
      clearSession();
      throw new Error('Only Super Admin accounts can access this panel.');
    }

    saveSession(data);
    return data.user;
  }

  function logout() {
    clearSession();
  }

  function getPending(businessType, search) {
    const params = new URLSearchParams();
    if (businessType) params.set('businessType', businessType);
    if (search) params.set('search', search);
    const q = params.toString();
    return request(`/api/admin/registrations/pending${q ? `?${q}` : ''}`);
  }

  function approve(tenantId) {
    return request(`/api/admin/registrations/${tenantId}/approve`, {
      method: 'POST',
      body: JSON.stringify({})
    });
  }

  function reject(tenantId, reason) {
    return request(`/api/admin/registrations/${tenantId}/reject`, {
      method: 'POST',
      body: JSON.stringify({ reason })
    });
  }

  function getReport(businessType) {
    const q = businessType ? `?businessType=${encodeURIComponent(businessType)}` : '';
    return request(`/api/admin/reports/shops${q}`);
  }

  return {
    getToken,
    getUser,
    isLoggedIn,
    login,
    logout,
    getPending,
    approve,
    reject,
    getReport
  };
})();
