// Contact form: validation + insert into Supabase (REST, publishable key). No secrets in this file.
const form = document.getElementById('contact-form');
if (form) {
  const cfg = window.MOVA_CONFIG || {};
  const configured = Boolean(cfg.supabaseUrl && cfg.supabasePublishableKey);
  const status = document.getElementById('form-status');
  const submit = form.querySelector('button[type="submit"]');
  const show = (kind, msg) => { status.className = `form-status form-status--${kind} is-visible`; status.textContent = msg; };
  if (!configured) show('info', 'Messaging is being connected. Please check back shortly.');

  const wanted = new URLSearchParams(location.search).get('topic');
  if (wanted && [...form.topic.options].some((o) => o.value === wanted)) form.topic.value = wanted;

  const rules = {
    name: (v) => (v.trim().length >= 1 && v.trim().length <= 120) || 'Please enter your name.',
    email: (v) => (/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v.trim()) && v.trim().length <= 254) || 'Please enter a valid email address.',
    topic: (v) => ['general', 'early-access', 'custom-project', 'partnership'].includes(v) || 'Please choose a topic.',
    message: (v) => (v.trim().length >= 10 && v.trim().length <= 2000) || 'Please write between 10 and 2000 characters.',
    consent: (_v, f) => f.consent.checked || 'Please confirm you agree to us using your details to reply.'
  };
  const check = (name) => {
    const field = form.elements[name]; const out = document.getElementById(`err-${name}`);
    const r = rules[name](field.value, form); const ok = r === true;
    field.setAttribute('aria-invalid', String(!ok)); if (out) out.textContent = ok ? '' : r; return ok;
  };
  Object.keys(rules).forEach((n) => { const f = form.elements[n]; f.addEventListener('blur', () => check(n)); });

  // New-style publishable keys (sb_publishable_...) are not JWTs and go in the apikey header only.
  const headers = () => {
    const h = { 'Content-Type': 'application/json', apikey: cfg.supabasePublishableKey, Prefer: 'return=minimal' };
    if (!cfg.supabasePublishableKey.startsWith('sb_')) h.Authorization = `Bearer ${cfg.supabasePublishableKey}`;
    return h;
  };

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (form.elements.website.value) return; // honeypot: bots fill hidden fields
    const valid = Object.keys(rules).map(check).every(Boolean);
    if (!valid) { show('error', 'Please fix the highlighted fields.'); const bad = form.querySelector('[aria-invalid="true"]'); if (bad) bad.focus(); return; }
    if (!configured) { show('info', 'Messaging is being connected. Please check back shortly.'); return; }
    const last = Number(localStorage.getItem('mova_last_send') || 0);
    if (Date.now() - last < 30000) { show('error', 'Please wait a moment before sending another message.'); return; }
    submit.disabled = true; submit.setAttribute('aria-busy', 'true');
    try {
      const res = await fetch(`${cfg.supabaseUrl.replace(/\/$/, '')}/rest/v1/contact_messages`, {
        method: 'POST',
        headers: headers(),
        body: JSON.stringify({ name: form.name.value.trim(), email: form.email.value.trim(), topic: form.topic.value, message: form.message.value.trim(), consent: true })
      });
      if (!res.ok) { let detail = ''; try { detail = await res.text(); } catch (_) { /* ignore */ } console.error('Contact form rejected', res.status, detail); const e = new Error(String(res.status)); e.status = res.status; throw e; }
      try { localStorage.setItem('mova_last_send', String(Date.now())); } catch (_) { /* storage unavailable */ }
      form.reset(); show('ok', 'Thank you. Your message has been sent.');
    } catch (err) {
      if (err && err.status === 429) { show('error', 'You have sent several messages recently. Please try again later.'); }
      else { const code = err && err.status ? `error ${err.status}` : 'network error'; show('error', `Sorry, your message could not be sent (${code}). Please try again later.`); }
    } finally { submit.disabled = false; submit.removeAttribute('aria-busy'); }
  });
}
