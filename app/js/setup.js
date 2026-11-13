// Business setup (step 2 of 2). Calls the create_business database function.
import { requireSession, loadMembership, rpc, friendly } from './api.js';

const form = document.getElementById('setup-form'); const status = document.getElementById('form-status'); const submit = form.querySelector('button[type="submit"]');
const show = (kind, msg) => { status.className = `form-status form-status--${kind} is-visible`; status.textContent = msg; };
const user = await requireSession();
if (user) {
  try { if (await loadMembership(user.id)) location.replace('dashboard.html'); } catch (_) { /* show the form anyway */ }
  const err = (id, m) => { document.getElementById(`err-${id}`).textContent = m || ''; form.elements[id].setAttribute('aria-invalid', String(Boolean(m))); return !m; };
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = form.bname.value.trim(); const city = form.city.value.trim();
    const ok = err('bname', name.length >= 1 && name.length <= 100 ? '' : 'Enter your business name (up to 100 characters).') & err('city', city.length <= 100 ? '' : 'Keep this under 100 characters.');
    if (!ok) { show('error', 'Please fix the highlighted fields.'); return; }
    submit.disabled = true; submit.setAttribute('aria-busy', 'true'); status.className = 'form-status';
    try { await rpc('create_business', { p_name: name, p_type: form.btype.value, p_city: city || null, p_team: form.team.value || null }); location.assign('dashboard.html'); }
    catch (e2) { if (e2.status === 401) { location.replace('login.html?next=setup.html'); return; } show('error', friendly(e2)); submit.disabled = false; submit.removeAttribute('aria-busy'); }
  });
}
