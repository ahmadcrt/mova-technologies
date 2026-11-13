// Phase 1 dashboard: shows the real business profile and an honest getting-started list. No fake figures.
import { requireSession, loadMembership, signOut, friendly } from './api.js';

const TYPES = { retail: 'Retail shop', services: 'Services', wholesale: 'Wholesale or distribution', food: 'Food and beverage', other: 'Other' };
const TEAMS = { solo: 'Just me', '2-5': '2 to 5 people', '6-20': '6 to 20 people', '21+': 'More than 20' };
const ROLES = { owner: 'Owner', manager: 'Manager', employee: 'Employee' };
const el = (tag, cls, text) => { const e = document.createElement(tag); if (cls) e.className = cls; if (text !== undefined) e.textContent = text; return e; };
const main = document.getElementById('dash');

document.querySelectorAll('[data-signout]').forEach((b) => b.addEventListener('click', async () => { b.disabled = true; await signOut(); location.replace('login.html'); }));

const greeting = () => { const h = new Date().getHours(); return h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening'; };
const dl = (rows) => { const d = el('dl', 'facts'); rows.forEach(([k, v]) => { const w = el('div'); w.append(el('dt', '', k), el('dd', '', v || 'Not set')); d.appendChild(w); }); return d; };

function render(user, m) {
  const b = m.business; const first = ((user.user_metadata && user.user_metadata.full_name) || '').split(' ')[0];
  document.querySelectorAll('[data-biz-name]').forEach((n) => { n.textContent = b.name; });
  document.querySelectorAll('[data-user-name]').forEach((n) => { n.textContent = (user.user_metadata && user.user_metadata.full_name) || user.email || ''; });
  document.getElementById('greet').textContent = `${greeting()}${first ? ', ' + first : ''}.`;
  const biz = el('section', 'card'); biz.append(el('h2', 'card-title', 'Your business'), dl([['Name', b.name], ['Type', TYPES[b.business_type]], ['Location', b.city_state], ['Team size', TEAMS[b.team_size]], ['Your role', ROLES[m.role]]]));
  const steps = el('section', 'card'); steps.append(el('h2', 'card-title', 'Getting started'));
  const ol = el('ol', 'steps-list');
  [['Account created', 'done', 'Done'], ['Business set up', 'done', 'Done'], ['Add your products', 'planned', 'Next update'], ['Record your first sale', 'planned', 'Planned']].forEach(([t, k, label]) => {
    const li = el('li', 'steps-item'); li.append(el('span', '', t), el('span', `badge badge--${k === 'done' ? 'done' : 'planned'}`, label)); ol.appendChild(li);
  });
  steps.appendChild(ol); steps.appendChild(el('p', 'sub', 'Sales, stock and customer figures will appear here once those features are switched on and you start adding data.'));
  main.replaceChildren(biz, steps);
}

const user = await requireSession();
if (user) {
  try {
    const m = await loadMembership(user.id);
    if (!m) location.replace('setup.html'); else render(user, m);
  } catch (e) {
    if (e.status === 401) { location.replace('login.html?next=dashboard.html'); }
    else {
      const box = el('div', 'card'); const btn = el('button', 'btn btn--primary', 'Try again'); btn.type = 'button'; btn.addEventListener('click', () => location.reload());
      box.append(el('h2', 'card-title', 'Could not load your business'), el('p', 'sub', friendly(e)), btn); main.replaceChildren(box);
    }
  }
}
