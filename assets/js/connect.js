// "Scattered vs connected" demonstration.
const box = document.querySelector('[data-connect]');
if (box) {
  const buttons = [...document.querySelectorAll('[data-connect-state]')];
  const caption = document.querySelector('[data-connect-caption]');
  const text = { scattered: 'Records in five places. No single view of the business.', connected: 'One connected view. Sales, stock and customers in step.' };
  let touched = false;
  const set = (state) => {
    box.dataset.state = state;
    buttons.forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.connectState === state)));
    if (caption) caption.textContent = text[state];
  };
  buttons.forEach((b) => b.addEventListener('click', () => { touched = true; set(b.dataset.connectState); }));
  set('scattered');
  if ('IntersectionObserver' in window) {
    const io = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting) { io.disconnect(); setTimeout(() => { if (!touched) set('connected'); }, 1400); }
    }, { threshold: 0.5 });
    io.observe(box);
  } else { set('connected'); }
}
