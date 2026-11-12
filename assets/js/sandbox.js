// MOVA live demo: a working, browser-only sandbox of the planned platform (inventory, sales, dashboard).
// Data stays in this browser (localStorage). Nothing is sent to any server. Seed figures are sample data.
const KEY = 'mova_sandbox_v1';
const MAX_PRODUCTS = 30;
const SEED = () => ({
  nextProduct: 6, nextSale: 1001,
  products: [
    { id: 'p1', name: 'Rice, 50 kg bag', price: 62000, stock: 38, reorder: 10 },
    { id: 'p2', name: 'Cooking oil, 5 L', price: 9800, stock: 9, reorder: 12 },
    { id: 'p3', name: 'Sugar, 1 kg', price: 1900, stock: 64, reorder: 20 },
    { id: 'p4', name: 'Detergent, 2 kg', price: 3200, stock: 7, reorder: 10 },
    { id: 'p5', name: 'Bottled water, 12 pack', price: 2400, stock: 52, reorder: 15 }
  ],
  sales: [],
  history: [96000, 142000, 118000, 171000, 153000, 208000] // previous six days, sample data
});

const naira = new Intl.NumberFormat('en-NG', { style: 'currency', currency: 'NGN', maximumFractionDigits: 0 });
const NS = 'http://www.w3.org/2000/svg';
const icon = (n) => { const s = document.createElementNS(NS, 'svg'); s.setAttribute('class', 'icon'); s.setAttribute('aria-hidden', 'true'); const u = document.createElementNS(NS, 'use'); u.setAttribute('href', `assets/img/icons.svg#i-${n}`); s.appendChild(u); return s; };
const el = (tag, cls, text, attrs) => { const e = document.createElement(tag); if (cls) e.className = cls; if (text !== undefined && text !== null) e.textContent = text; if (attrs) Object.entries(attrs).forEach(([k, v]) => e.setAttribute(k, v)); return e; };

let state; let cart = [];
const load = () => {
  try { const raw = localStorage.getItem(KEY); if (raw) { const s = JSON.parse(raw); if (s && Array.isArray(s.products) && Array.isArray(s.sales)) return s; } } catch (_) { /* ignore corrupt or blocked storage */ }
  return SEED();
};
const save = () => { try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (_) { /* storage unavailable: demo still works for this visit */ } };
const dayKey = (t) => new Date(t).toDateString();
const todaySales = () => state.sales.filter((s) => dayKey(s.ts) === new Date().toDateString());
const status = (p) => (p.stock === 0 ? 'out' : p.stock <= p.reorder ? 'low' : 'ok');
const find = (id) => state.products.find((p) => p.id === id);
const live = document.getElementById('sbx-live');
const say = (msg) => { if (live) live.textContent = msg; };

// ---------- Dashboard
function renderDashboard() {
  const sales = todaySales(); const total = sales.reduce((a, s) => a + s.total, 0);
  const items = sales.reduce((a, s) => a + s.lines.reduce((b, l) => b + l.qty, 0), 0);
  const low = state.products.filter((p) => status(p) !== 'ok');
  const set = (id, v) => { document.getElementById(id).textContent = v; };
  set('k-sales', naira.format(total)); set('k-items', String(items)); set('k-low', String(low.length));
  const days = [...state.history, total]; const max = Math.max(...days, 1);
  const bars = document.getElementById('d-bars'); bars.replaceChildren();
  const labels = document.getElementById('d-days'); labels.replaceChildren();
  days.forEach((v, i) => {
    const wrap = el('div', 'bar'); const b = el('i'); b.style.setProperty('--h', String(Math.max(3, Math.round((v / max) * 100)))); b.style.setProperty('--i', String(i));
    b.setAttribute('title', naira.format(v)); wrap.appendChild(b); bars.appendChild(wrap);
    labels.appendChild(el('span', '', i === days.length - 1 ? 'Today' : `D-${days.length - 1 - i}`));
  });
  const list = document.getElementById('d-low'); list.replaceChildren();
  if (!low.length) list.appendChild(el('li', 'empty', 'Nothing is running low.'));
  low.forEach((p) => { const li = el('li', 'row'); li.append(el('span', '', p.name), el('span', `pill pill--${status(p)}`, status(p) === 'out' ? 'Out of stock' : `Low: ${p.stock} left`)); list.appendChild(li); });
}

// ---------- Inventory
function renderInventory() {
  const body = document.getElementById('inv-body'); body.replaceChildren();
  state.products.forEach((p) => {
    const tr = el('tr');
    const td = (label, content) => { const c = el('td', '', typeof content === 'string' ? content : null, { 'data-label': label }); if (typeof content !== 'string') c.appendChild(content); return c; };
    const st = status(p);
    const restock = el('button', 'mini', '+10', { type: 'button', 'aria-label': `Restock ${p.name} by 10` });
    restock.addEventListener('click', () => { p.stock += 10; save(); renderAll(); say(`${p.name} restocked. Now ${p.stock}.`); });
    const del = el('button', 'mini mini--ghost', 'Remove', { type: 'button', 'aria-label': `Remove ${p.name}` });
    del.addEventListener('click', () => { state.products = state.products.filter((x) => x.id !== p.id); cart = cart.filter((c) => c.pid !== p.id); save(); renderAll(); say(`${p.name} removed.`); });
    const actions = el('div', 'actions'); actions.append(restock, del);
    tr.append(td('Product', p.name), td('Price', naira.format(p.price)), td('In stock', String(p.stock)), td('Status', el('span', `pill pill--${st}`, st === 'out' ? 'Out' : st === 'low' ? 'Low' : 'OK')), td('Actions', actions));
    body.appendChild(tr);
  });
}
function bindInventoryForm() {
  const f = document.getElementById('inv-form'); const msg = document.getElementById('inv-msg');
  f.addEventListener('submit', (e) => {
    e.preventDefault();
    const name = f.pname.value.trim(); const price = Number(f.pprice.value); const stock = Number(f.pstock.value); const reorder = Number(f.preorder.value || 0);
    const bad = (m) => { msg.textContent = m; msg.className = 'form-msg form-msg--error'; };
    if (!name || name.length > 60) return bad('Enter a product name (up to 60 characters).');
    if (!Number.isInteger(price) || price < 1 || price > 10000000) return bad('Price must be a whole number from 1 to 10,000,000.');
    if (!Number.isInteger(stock) || stock < 0 || stock > 100000) return bad('Stock must be a whole number from 0 to 100,000.');
    if (!Number.isInteger(reorder) || reorder < 0 || reorder > 100000) return bad('Reorder level must be a whole number from 0 to 100,000.');
    if (state.products.length >= MAX_PRODUCTS) return bad(`The demo holds up to ${MAX_PRODUCTS} products.`);
    state.products.push({ id: `p${state.nextProduct++}`, name, price, stock, reorder });
    save(); f.reset(); msg.textContent = `${name} added.`; msg.className = 'form-msg form-msg--ok'; renderAll(); say(`${name} added to inventory.`);
  });
}

// ---------- Sales
const cartQty = (pid) => cart.filter((c) => c.pid === pid).reduce((a, c) => a + c.qty, 0);
function renderSalesForm() {
  const sel = document.getElementById('s-product'); const keep = sel.value; sel.replaceChildren();
  state.products.forEach((p) => { const o = el('option', '', `${p.name} (${p.stock} in stock)`, { value: p.id }); if (p.stock === 0) o.disabled = true; sel.appendChild(o); });
  if (keep && find(keep)) sel.value = keep;
}
function renderCart() {
  const list = document.getElementById('s-cart'); list.replaceChildren(); let total = 0;
  if (!cart.length) list.appendChild(el('li', 'empty', 'The cart is empty.'));
  cart.forEach((c, i) => {
    const p = find(c.pid); if (!p) return; total += p.price * c.qty;
    const li = el('li', 'row'); const rm = el('button', 'mini mini--ghost', 'Remove', { type: 'button', 'aria-label': `Remove ${p.name} from cart` });
    rm.addEventListener('click', () => { cart.splice(i, 1); renderCart(); });
    const right = el('span', 'cart-right'); right.append(el('span', '', `${c.qty} \u00d7 ${naira.format(p.price)} = ${naira.format(p.price * c.qty)}`), rm);
    li.append(el('span', '', p.name), right); list.appendChild(li);
  });
  document.getElementById('s-total').textContent = naira.format(total);
  document.getElementById('s-complete').disabled = cart.length === 0;
}
function renderRecent() {
  const list = document.getElementById('s-recent'); list.replaceChildren();
  const recent = [...state.sales].reverse().slice(0, 6);
  if (!recent.length) list.appendChild(el('li', 'empty', 'No sales yet. Complete one above.'));
  recent.forEach((s) => { const li = el('li', 'row'); const n = s.lines.reduce((a, l) => a + l.qty, 0); li.append(el('span', '', `${s.id}, ${n} item${n === 1 ? '' : 's'}`), el('span', '', naira.format(s.total))); list.appendChild(li); });
}
function bindSales() {
  const f = document.getElementById('s-form'); const msg = document.getElementById('s-msg');
  const note = (m, ok) => { msg.textContent = m; msg.className = `form-msg form-msg--${ok ? 'ok' : 'error'}`; };
  f.addEventListener('submit', (e) => {
    e.preventDefault();
    const p = find(f.sproduct.value); const qty = Number(f.sqty.value);
    if (!p) return note('Choose a product.', false);
    if (!Number.isInteger(qty) || qty < 1) return note('Quantity must be a whole number of 1 or more.', false);
    if (qty + cartQty(p.id) > p.stock) return note(`Only ${p.stock - cartQty(p.id)} more of ${p.name} available.`, false);
    const existing = cart.find((c) => c.pid === p.id); if (existing) existing.qty += qty; else cart.push({ pid: p.id, qty });
    f.sqty.value = '1'; note(`${qty} \u00d7 ${p.name} added to the cart.`, true); renderCart();
  });
  document.getElementById('s-complete').addEventListener('click', () => {
    if (!cart.length) return;
    for (const c of cart) { const p = find(c.pid); if (!p || c.qty > p.stock) { cart = []; renderAll(); return note('Stock changed. The cart was cleared, please try again.', false); } }
    let total = 0; const lines = cart.map((c) => { const p = find(c.pid); p.stock -= c.qty; total += p.price * c.qty; return { pid: p.id, name: p.name, qty: c.qty, price: p.price }; });
    const id = `S-${state.nextSale++}`; state.sales.push({ id, ts: Date.now(), lines, total });
    if (state.sales.length > 200) state.sales.shift();
    cart = []; save(); renderAll(); note(`${id} completed: ${naira.format(total)}. Stock and dashboard updated.`, true); say(`Sale ${id} completed for ${naira.format(total)}.`);
  });
}

function renderAll() { renderDashboard(); renderInventory(); renderSalesForm(); renderCart(); renderRecent(); }

// ---------- Tabs + reset
const tabs = [...document.querySelectorAll('[data-sbx-tab]')]; const panels = tabs.map((t) => document.getElementById(t.getAttribute('aria-controls')));
const select = (i, focus) => { tabs.forEach((t, j) => { t.setAttribute('aria-selected', String(i === j)); t.tabIndex = i === j ? 0 : -1; panels[j].hidden = i !== j; }); if (focus) tabs[i].focus(); if (i === 0) renderDashboard(); };
tabs.forEach((t, i) => {
  t.addEventListener('click', () => select(i, false));
  t.addEventListener('keydown', (e) => { let n = null; if (e.key === 'ArrowRight') n = (i + 1) % tabs.length; if (e.key === 'ArrowLeft') n = (i - 1 + tabs.length) % tabs.length; if (e.key === 'Home') n = 0; if (e.key === 'End') n = tabs.length - 1; if (n !== null) { e.preventDefault(); select(n, true); } });
});
document.getElementById('sbx-reset').addEventListener('click', () => { state = SEED(); cart = []; save(); renderAll(); say('Sandbox reset to sample data.'); });

state = load(); bindInventoryForm(); bindSales(); renderAll(); select(0, false);
