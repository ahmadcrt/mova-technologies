// Module explorer for the planned MOVA Business Platform. Content mirrors the planning documents; every module is PLANNED.
const MODULES = [
  { id: 'dashboard', icon: 'grid', name: 'Business Dashboard', purpose: 'One view of how the business is doing today.', features: ['Sales and order summary', 'Low-stock alerts', 'Simple, readable charts'], users: 'Owner, Manager', needs: 'Sales, Inventory, Orders, Finance' },
  { id: 'inventory', icon: 'box', name: 'Inventory', purpose: 'Know what is in stock and what is running low.', features: ['Product catalogue and categories', 'Stock levels and adjustments', 'Reorder alerts'], users: 'Owner, Manager, Employee', needs: 'Sign-in, business setup' },
  { id: 'sales', icon: 'cart', name: 'Sales', purpose: 'Record every sale accurately, in seconds.', features: ['Line items and discounts', 'Payment method', 'Receipts that update stock'], users: 'Owner, Manager, Employee', needs: 'Inventory, Customers' },
  { id: 'orders', icon: 'clipboard', name: 'Orders', purpose: 'Follow each order from request to delivery.', features: ['Order status tracking', 'Fulfilment notes', 'Linked to customers and stock'], users: 'Owner, Manager, Employee', needs: 'Customers, Inventory' },
  { id: 'crm', icon: 'users', name: 'Customers', purpose: 'Keep customer details and history in one place.', features: ['Customer profiles', 'Purchase history', 'Notes for follow-up'], users: 'Owner, Manager, Employee', needs: 'Sales, Orders' },
  { id: 'finance', icon: 'wallet', name: 'Finance', purpose: 'See money coming in and going out.', features: ['Expense tracking', 'Invoices and receipts', 'A simple profit view'], users: 'Owner, Manager (restricted)', needs: 'Sales, Customers' },
  { id: 'employees', icon: 'badge', name: 'Employees', purpose: 'Control who can do what in the business.', features: ['Staff list and roles', 'Access control', 'Activity history'], users: 'Owner, Manager', needs: 'Sign-in, role system' },
  { id: 'reports', icon: 'chart', name: 'Reports', purpose: 'Turn records into decisions.', features: ['Sales, stock and expense reports', 'Date ranges', 'Export (later)'], users: 'Owner, Manager', needs: 'All data modules' },
  { id: 'settings', icon: 'settings', name: 'Account and Settings', purpose: 'Manage the business profile and security.', features: ['Business profile and branding', 'User profile', 'Subscription view'], users: 'All users, scoped', needs: 'Sign-in' },
  { id: 'notifications', icon: 'bell', name: 'Notifications', purpose: 'Say what needs attention, when it matters.', features: ['In-app alerts first', 'Email later', 'WhatsApp is a future integration'], users: 'All users', needs: 'All modules' }
];
const NS = 'http://www.w3.org/2000/svg';
const icon = (name, cls = 'icon') => { const s = document.createElementNS(NS, 'svg'); s.setAttribute('class', cls); s.setAttribute('aria-hidden', 'true'); const u = document.createElementNS(NS, 'use'); u.setAttribute('href', `assets/img/icons.svg#i-${name}`); s.appendChild(u); return s; };
const el = (tag, cls, text) => { const e = document.createElement(tag); if (cls) e.className = cls; if (text) e.textContent = text; return e; };

const host = document.querySelector('[data-explorer]');
if (host) {
  const list = host.querySelector('[data-explorer-list]'); const panel = host.querySelector('[data-explorer-panel]');
  const buttons = MODULES.map((m, i) => {
    const b = el('button'); b.type = 'button'; b.setAttribute('role', 'tab'); b.id = `tab-${m.id}`; b.setAttribute('aria-controls', 'explorer-panel');
    b.append(icon(m.icon), el('span', '', m.name)); list.appendChild(b);
    b.addEventListener('click', () => show(i, false));
    b.addEventListener('keydown', (e) => {
      let n = null;
      if (e.key === 'ArrowDown' || e.key === 'ArrowRight') n = (i + 1) % MODULES.length;
      if (e.key === 'ArrowUp' || e.key === 'ArrowLeft') n = (i - 1 + MODULES.length) % MODULES.length;
      if (e.key === 'Home') n = 0; if (e.key === 'End') n = MODULES.length - 1;
      if (n !== null) { e.preventDefault(); show(n, true); }
    });
    return b;
  });
  function show(i, focus) {
    const m = MODULES[i];
    buttons.forEach((b, j) => { b.setAttribute('aria-selected', String(j === i)); b.tabIndex = j === i ? 0 : -1; });
    panel.setAttribute('aria-labelledby', `tab-${m.id}`);
    const head = el('div', 'explorer__head'); const ico = el('span', 'ico'); ico.appendChild(icon(m.icon));
    const badge = el('span', 'badge badge--planned', 'Planned'); head.append(ico, el('h3', '', m.name), badge);
    const ul = el('ul', 'feat'); m.features.forEach((f) => { const li = el('li'); li.append(icon('check'), el('span', '', f)); ul.appendChild(li); });
    const meta = el('div', 'meta'); [['Used by', m.users], ['Depends on', m.needs]].forEach(([k, v]) => { const d = el('div'); d.append(el('small', '', k), el('span', '', v)); meta.appendChild(d); });
    panel.replaceChildren(head, el('p', '', m.purpose), ul, meta);
    panel.style.animation = 'none'; void panel.offsetWidth; panel.style.animation = '';
    if (focus) buttons[i].focus();
  }
  show(0, false);
}
