// The parts of the room that answer the reader: the top bar, the phone that
// changes with the story, the big screen's light and pen, the program names.
(function () {
  const qsa = (s, r) => Array.from((r || document).querySelectorAll(s));

  const top = document.querySelector('[data-top]');
  const nav = document.getElementById('nav');
  const menu = document.querySelector('.menu');
  let last = scrollY;
  addEventListener('scroll', () => {
    const y = scrollY;
    top.classList.toggle('solid', y > 40);
    if (!nav.classList.contains('open')) top.classList.toggle('hide', y > last && y > 300);
    last = y;
  }, { passive: true });
  top.addEventListener('focusin', () => top.classList.remove('hide'));
  menu.addEventListener('click', () => { const o = nav.classList.toggle('open'); menu.setAttribute('aria-expanded', String(o)); });
  nav.addEventListener('click', () => { nav.classList.remove('open'); menu.setAttribute('aria-expanded', 'false'); });

  // The story's phone shows the screen of the beat being read.
  const shots = qsa('[data-shot]');
  const io = new IntersectionObserver((list) => {
    list.forEach((e) => { if (e.isIntersecting) shots.forEach((s) => s.classList.toggle('on', s.dataset.shot === e.target.dataset.beat)); });
  }, { rootMargin: '-45% 0px -45% 0px' });
  qsa('[data-beat]').forEach((b) => io.observe(b));

  // The big screen.
  const room = document.querySelector('[data-room]');
  const perde = room.querySelector('[data-perde]');
  const ink = room.querySelector('[data-ink]');
  const blank = room.querySelector('[data-blank]');
  let pos = { x: .62, y: .48 }, stroke = null;
  function place() {
    const r = perde.getBoundingClientRect();
    perde.style.setProperty('--x', pos.x * r.width + 'px');
    perde.style.setProperty('--y', pos.y * r.height + 'px');
  }
  function fromEvent(e) {
    const r = perde.getBoundingClientRect();
    pos = { x: Math.max(0, Math.min(1, (e.clientX - r.left) / r.width)), y: Math.max(0, Math.min(1, (e.clientY - r.top) / r.height)) };
    place();
    return [e.clientX - r.left, e.clientY - r.top];
  }
  function sizeInk() { const r = perde.getBoundingClientRect(); ink.setAttribute('viewBox', '0 0 ' + r.width + ' ' + r.height); }
  perde.addEventListener('pointerenter', () => document.body.classList.add('pointing'));
  perde.addEventListener('pointerleave', () => document.body.classList.remove('pointing'));
  perde.addEventListener('pointermove', (e) => {
    const p = fromEvent(e);
    if (stroke) { stroke.d += 'L' + p[0] + ' ' + p[1]; stroke.el.setAttribute('d', stroke.d); }
  });
  perde.addEventListener('pointerdown', (e) => {
    const p = fromEvent(e);
    if (room.dataset.tool !== 'pen') return;
    sizeInk();
    perde.setPointerCapture(e.pointerId);
    const el = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    ink.appendChild(el);
    stroke = { el, d: 'M' + p[0] + ' ' + p[1] };
    el.setAttribute('d', stroke.d);
  });
  ['pointerup', 'pointercancel'].forEach((t) => perde.addEventListener(t, () => { stroke = null; }));
  perde.addEventListener('keydown', (e) => {
    const s = { ArrowLeft: [-.03, 0], ArrowRight: [.03, 0], ArrowUp: [0, -.05], ArrowDown: [0, .05] }[e.key];
    if (!s) return;
    e.preventDefault();
    pos = { x: Math.max(0, Math.min(1, pos.x + s[0])), y: Math.max(0, Math.min(1, pos.y + s[1])) };
    place();
  });
  room.addEventListener('click', (e) => {
    const t = e.target.closest('[data-tool-pick]');
    if (t) {
      room.dataset.tool = t.dataset.toolPick;
      qsa('[data-tool-pick]', room).forEach((b) => b.setAttribute('aria-pressed', String(b === t)));
      if (t.dataset.toolPick === 'pen' && !ink.firstChild) {
        // Show the pen working, for anyone with no pointer to draw with.
        sizeInk();
        const r = perde.getBoundingClientRect(), w = r.width, h = r.height;
        const el = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        el.setAttribute('d', 'M' + w * .27 + ' ' + h * .2 + 'C' + w * .2 + ' ' + h * .16 + ' ' + w * .17 + ' ' + h * .5 + ' ' + w * .22 + ' ' + h * .9 + 'S' + w * .3 + ' ' + h * .8 + ' ' + w * .3 + ' ' + h * .5 + 'S' + w * .3 + ' ' + h * .2 + ' ' + w * .24 + ' ' + h * .2);
        ink.appendChild(el);
      }
    }
    const a = e.target.closest('[data-act]');
    if (!a) return;
    if (a.dataset.act === 'undo' && ink.lastChild) ink.lastChild.remove();
    if (a.dataset.act === 'black') a.setAttribute('aria-pressed', String(blank.classList.toggle('on')));
  });
  addEventListener('resize', place);
  place();

  // Program names, one open at a time.
  const names = document.querySelector('[data-names]');
  qsa('button', names).forEach((b) => b.addEventListener('click', () => {
    qsa('button', names).forEach((o) => {
      const on = o === b;
      o.setAttribute('aria-expanded', String(on));
      document.getElementById(o.getAttribute('aria-controls')).hidden = !on;
    });
  }));

  const copy = document.querySelector('[data-copy]');
  copy.addEventListener('click', async () => {
    const label = copy.querySelector('span'), before = label.textContent;
    const text = 'git clone https://github.com/berat-kaan-akcan/QuickRemote.git\ncd QuickRemote/quick_remote_pc\nflutter pub get\nflutter run';
    try { await navigator.clipboard.writeText(text); label.textContent = copy.dataset.done; setTimeout(() => { label.textContent = before; }, 1800); } catch (e) { /* the commands stay selectable */ }
  });
})();
