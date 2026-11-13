// Minimal Supabase client (no dependencies): auth, REST and RPC over fetch.
// Uses only the project URL and PUBLISHABLE key from ../assets/js/config.js. Never put a secret key in this repository.
const cfg = window.MOVA_CONFIG || {};
const BASE = String(cfg.supabaseUrl || '').replace(/\/$/, '');
export const configured = Boolean(BASE && cfg.supabasePublishableKey);
const KEY = 'mova_session_v1';

export class ApiError extends Error {
  constructor(message, status, data) { super(message); this.status = status; this.data = data; }
}
const readSession = () => { try { return JSON.parse(localStorage.getItem(KEY) || 'null'); } catch (_) { return null; } };
const writeSession = (s) => {
  try {
    if (!s) { localStorage.removeItem(KEY); return; }
    localStorage.setItem(KEY, JSON.stringify({ access_token: s.access_token, refresh_token: s.refresh_token, expires_at: s.expires_at || Math.floor(Date.now() / 1000) + (s.expires_in || 3600), user: s.user }));
  } catch (_) { /* storage blocked: session lasts for this page only */ }
};
export const hasSession = () => Boolean(readSession());
export const currentUser = () => (readSession() || {}).user || null;

async function call(path, { method = 'GET', body, token, headers = {} } = {}) {
  if (!configured) throw new ApiError('Not configured', 0);
  const h = { apikey: cfg.supabasePublishableKey, 'Content-Type': 'application/json', ...headers };
  if (token) h.Authorization = `Bearer ${token}`;
  let res;
  try { res = await fetch(BASE + path, { method, headers: h, body: body === undefined ? undefined : JSON.stringify(body) }); }
  catch (_) { throw new ApiError('network', 0); }
  const text = await res.text(); let data = null;
  try { data = text ? JSON.parse(text) : null; } catch (_) { data = null; }
  if (!res.ok) throw new ApiError((data && (data.msg || data.message || data.error_description || data.error)) || `HTTP ${res.status}`, res.status, data);
  return data;
}

export function friendly(err) {
  const m = String((err && err.message) || '').toLowerCase();
  if (!err || err.status === 0 || m === 'network') return 'Network problem. Check your connection and try again.';
  if (err.status === 429 || m.includes('rate limit') || m.includes('too many')) return 'Too many attempts. Please wait a minute and try again.';
  if (m.includes('invalid login')) return 'Incorrect email or password.';
  if (m.includes('already registered') || m.includes('already exists')) return 'An account with this email already exists. Try signing in.';
  if (m.includes('email not confirmed')) return 'Please confirm your email first. Check your inbox.';
  if (m.includes('password should') || m.includes('weak')) return 'Choose a stronger password (at least 8 characters).';
  if (m.includes('already have a business')) return 'You already have a business set up.';
  if (m.includes('business name') || m.includes('invalid business') || m.includes('invalid team')) return err.message;
  return 'Something went wrong. Please try again.';
}

async function refresh(s) {
  try {
    const data = await call('/auth/v1/token?grant_type=refresh_token', { method: 'POST', body: { refresh_token: s.refresh_token } });
    writeSession(data); return data.access_token;
  } catch (_) { writeSession(null); return null; }
}
export async function accessToken() {
  const s = readSession(); if (!s) return null;
  if (s.expires_at - Math.floor(Date.now() / 1000) > 60) return s.access_token;
  return refresh(s);
}

export async function signUp(email, password, fullName) {
  const data = await call('/auth/v1/signup', { method: 'POST', body: { email, password, data: { full_name: fullName } } });
  if (data && data.access_token) { writeSession(data); return { signedIn: true }; }
  return { signedIn: false };
}
export async function signIn(email, password) {
  const data = await call('/auth/v1/token?grant_type=password', { method: 'POST', body: { email, password } });
  writeSession(data); return data;
}
export async function signOut() {
  const t = await accessToken();
  try { if (t) await call('/auth/v1/logout', { method: 'POST', token: t }); } catch (_) { /* clear locally anyway */ }
  writeSession(null);
}
export const recover = (email, redirectTo) => call(`/auth/v1/recover?redirect_to=${encodeURIComponent(redirectTo)}`, { method: 'POST', body: { email } });
export const updatePassword = (token, password) => call('/auth/v1/user', { method: 'PUT', token, body: { password } });

export async function rest(path, opts = {}) {
  const token = await accessToken();
  if (!token) throw new ApiError('Not signed in', 401);
  return call(`/rest/v1/${path}`, { ...opts, token });
}
export const rpc = (name, args) => rest(`rpc/${name}`, { method: 'POST', body: args });

// Redirect to sign-in when there is no usable session. Returns the user when signed in.
export async function requireSession() {
  const t = await accessToken();
  if (!t) { location.replace(`login.html?next=${encodeURIComponent(location.pathname.split('/').pop())}`); return null; }
  return currentUser();
}
// Returns { role, business } or null when the user has not set up a business yet.
export async function loadMembership(userId) {
  const rows = await rest(`business_members?select=role,business:businesses(*)&user_id=eq.${encodeURIComponent(userId)}&limit=1`);
  return rows && rows.length ? rows[0] : null;
}
