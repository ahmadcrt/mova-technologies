// Sign in, create account, forgot and reset password.
import { configured, hasSession, signIn, signUp, recover, updatePassword, friendly } from './api.js';

const page = document.body.dataset.page;
const form = document.querySelector('form[data-auth]');
const status = document.getElementById('form-status');
const submit = form && form.querySelector('button[type="submit"]');
const show = (kind, msg) => { status.className = `form-status form-status--${kind} is-visible`; status.textContent = msg; };
const go = (u) => location.assign(u);
const safeNext = () => { const n = new URLSearchParams(location.search).get('next'); return n && /^[a-z0-9-]+\.html$/.test(n) ? n : 'dashboard.html'; };

if (!configured && status) show('error', 'The platform is not connected yet. Please try again later.');
if (hasSession() && (page === 'login' || page === 'register')) go(safeNext());

// show / hide password
document.querySelectorAll('[data-toggle-password]').forEach((btn) => {
  btn.addEventListener('click', () => {
    const input = document.getElementById(btn.dataset.togglePassword); const on = input.type === 'password';
    input.type = on ? 'text' : 'password'; btn.setAttribute('aria-pressed', String(on)); btn.setAttribute('aria-label', on ? 'Hide password' : 'Show password');
  });
});

const rules = {
  name: (v) => (v.trim().length >= 1 && v.trim().length <= 120) || 'Please enter your name.',
  email: (v) => (/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v.trim()) && v.trim().length <= 254) || 'Please enter a valid email address.',
  password: (v) => (v.length >= 8 && v.length <= 72) || 'Use 8 to 72 characters.',
  loginpassword: (v) => v.length > 0 || 'Please enter your password.',
  confirm: (v, f) => v === f.elements.password.value || 'The passwords do not match.',
  consent: (_v, f) => f.elements.consent.checked || 'Please agree to continue.'
};
const fieldRule = { loginpassword: 'password' };
const check = (f, rule) => {
  const name = fieldRule[rule] || rule; const el = f.elements[name]; const out = document.getElementById(`err-${name}`);
  const r = rules[rule](el.type === 'checkbox' ? '' : el.value, f); const ok = r === true;
  el.setAttribute('aria-invalid', String(!ok)); if (out) out.textContent = ok ? '' : r; return ok;
};
const validateAll = (f, list) => list.map((r) => check(f, r)).every(Boolean);
const busy = (on) => { submit.disabled = on; if (on) submit.setAttribute('aria-busy', 'true'); else submit.removeAttribute('aria-busy'); };

if (form) {
  const lists = { login: ['email', 'loginpassword'], register: ['name', 'email', 'password', 'consent'], forgot: ['email'], reset: ['password', 'confirm'] };
  const list = lists[page] || [];
  list.forEach((r) => { const el = form.elements[fieldRule[r] || r]; if (el && el.type !== 'checkbox') el.addEventListener('blur', () => check(form, r)); });

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!configured) return;
    if (!validateAll(form, list)) { show('error', 'Please fix the highlighted fields.'); const bad = form.querySelector('[aria-invalid="true"]'); if (bad) bad.focus(); return; }
    busy(true); status.className = 'form-status';
    try {
      if (page === 'login') { await signIn(form.email.value.trim(), form.password.value); go(safeNext()); return; }
      if (page === 'register') {
        const r = await signUp(form.email.value.trim(), form.password.value, form.name.value.trim());
        if (r.signedIn) { go('setup.html'); return; }
        form.reset(); show('ok', 'Almost done. Check your email and confirm your account, then sign in.'); return;
      }
      if (page === 'forgot') {
        await recover(form.email.value.trim(), new URL('reset.html', location.href).href);
        show('ok', 'If an account exists for this email, a reset link is on its way.'); return;
      }
      if (page === 'reset') {
        await updatePassword(window.__recoveryToken, form.password.value);
        form.reset(); show('ok', 'Password updated. You can now sign in.'); setTimeout(() => go('login.html'), 1500); return;
      }
    } catch (err) { show('error', friendly(err)); } finally { busy(false); }
  });
}

if (page === 'reset') {
  // Supabase redirects here with the recovery token in the URL fragment. Read it on load and whenever the fragment changes.
  const invalid = document.getElementById('reset-invalid');
  const parse = () => {
    const hash = new URLSearchParams(location.hash.replace(/^#/, '')); const token = hash.get('access_token');
    if (token && hash.get('type') === 'recovery') { window.__recoveryToken = token; form.hidden = false; invalid.hidden = true; history.replaceState(null, '', location.pathname); }
    else if (!window.__recoveryToken) { form.hidden = true; invalid.hidden = false; }
  };
  parse(); window.addEventListener('hashchange', parse);
}
