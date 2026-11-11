// Interactive product preview in the hero. All figures are SAMPLE data for illustration only.
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const root = document.querySelector('[data-pw]');
if (root) {
  const tabs = [...root.querySelectorAll('[role="tab"]')];
  const panels = tabs.map((t) => document.getElementById(t.getAttribute('aria-controls')));
  const fmt = new Intl.NumberFormat('en-NG');

  const animateCounters = (scope) => {
    scope.querySelectorAll('[data-count]').forEach((el) => {
      const target = Number(el.dataset.count); const prefix = el.dataset.prefix || '';
      if (reduceMotion) { el.textContent = prefix + fmt.format(target); return; }
      const start = performance.now(); const dur = 1100;
      const tick = (now) => {
        const t = Math.min(1, (now - start) / dur); const e = 1 - Math.pow(1 - t, 3);
        el.textContent = prefix + fmt.format(Math.round(target * e));
        if (t < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    });
  };
  const paint = (scope) => {
    scope.querySelectorAll('[data-h]').forEach((el, i) => { el.style.setProperty('--h', el.dataset.h); el.style.setProperty('--i', String(i)); });
    scope.querySelectorAll('[data-w]').forEach((el) => el.style.setProperty('--w', el.dataset.w));
    animateCounters(scope);
  };
  const select = (idx, focus) => {
    tabs.forEach((t, i) => { const on = i === idx; t.setAttribute('aria-selected', String(on)); t.tabIndex = on ? 0 : -1; panels[i].hidden = !on; });
    paint(panels[idx]);
    if (focus) tabs[idx].focus();
  };
  let current = 0; let userTouched = false; let timer = null;
  const stop = () => { if (timer) { clearInterval(timer); timer = null; } };
  const start = () => { if (!reduceMotion && !userTouched && !timer) timer = setInterval(() => { if (!document.hidden) { current = (current + 1) % tabs.length; select(current, false); } }, 6500); };

  tabs.forEach((t, i) => {
    t.addEventListener('click', () => { userTouched = true; stop(); current = i; select(i, false); });
    t.addEventListener('keydown', (e) => {
      const k = e.key; let n = null;
      if (k === 'ArrowDown' || k === 'ArrowRight') n = (i + 1) % tabs.length;
      if (k === 'ArrowUp' || k === 'ArrowLeft') n = (i - 1 + tabs.length) % tabs.length;
      if (k === 'Home') n = 0; if (k === 'End') n = tabs.length - 1;
      if (n !== null) { e.preventDefault(); userTouched = true; stop(); current = n; select(n, true); }
    });
  });
  root.addEventListener('mouseenter', stop); root.addEventListener('focusin', stop);
  root.addEventListener('mouseleave', start);
  select(0, false); start();
}
