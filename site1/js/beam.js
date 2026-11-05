// One laser line through the whole page. Every [data-b] names points of its box
// ("x,y" fractions, then optional px offsets), every [data-ring] is circled once,
// in the order they stand in the page. Scrolling draws the line up to the reader.
(function () {
  const svg = document.querySelector('[data-beam]');
  const main = document.querySelector('main');
  const [glow, line] = svg.querySelectorAll('path');
  const head = svg.querySelector('.b-head');
  const halo = svg.querySelector('.b-halo');
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  let map = [], total = 0, raf = 0, ready = false;

  function points() {
    const base = main.getBoundingClientRect();
    const out = [];
    const narrow = innerWidth <= 900;
    main.querySelectorAll('[data-b],[data-ring]').forEach((el) => {
      // Narrow screens have no free space beside the text: those routes keep to the edge.
      if (el.dataset.only === (narrow ? 'wide' : 'narrow')) return;
      const r = el.getBoundingClientRect();
      if (!r.width) return;
      const x0 = r.left - base.left, y0 = r.top - base.top;
      if (el.dataset.ring) {
        const k = Number(el.dataset.ring), cx = x0 + r.width / 2, cy = y0 + r.height / 2, rx = r.width / 2 * k, ry = r.height / 2 * k;
        // Once round and a little past the start, read over the box's height.
        const a0 = Number(el.dataset.ringA || -2.2);
        for (let i = 0; i <= 12; i++) {
          const a = a0 + i / 12 * Math.PI * 2.1;
          out.push({ x: cx + rx * Math.cos(a), y: cy + ry * Math.sin(a), key: y0 + r.height * (i / 12) });
        }
        return;
      }
      el.dataset.b.split(' ').forEach((p) => {
        const [fx, fy, ox, oy] = p.split(',').map(Number);
        const x = Math.max(3, Math.min(main.clientWidth - 3, x0 + r.width * fx + (ox || 0))), y = y0 + r.height * fy + (oy || 0);
        out.push({ x, y, key: y });
      });
    });
    return out;
  }
  function build() {
    const pts = points();
    if (pts.length < 2) return;
    svg.setAttribute('viewBox', '0 0 ' + main.clientWidth + ' ' + main.scrollHeight);
    // Catmull-Rom through the points, as cubic segments.
    let d = 'M' + pts[0].x + ' ' + pts[0].y;
    const probe = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    map = [{ key: pts[0].key, len: 0 }];
    let key = pts[0].key;
    for (let i = 0; i < pts.length - 1; i++) {
      const p0 = pts[Math.max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[Math.min(i + 2, pts.length - 1)];
      const c1x = p1.x + (p2.x - p0.x) / 6, c1y = p1.y + (p2.y - p0.y) / 6, c2x = p2.x - (p3.x - p1.x) / 6, c2y = p2.y - (p3.y - p1.y) / 6;
      d += 'C' + c1x + ' ' + c1y + ' ' + c2x + ' ' + c2y + ' ' + p2.x + ' ' + p2.y;
      probe.setAttribute('d', d);
      // Sideways runs (an underline) take scrolling too, not just one jump.
      key = Math.max(key + 1 + Math.abs(p2.x - p1.x) * .3, p2.key);
      map.push({ key, len: probe.getTotalLength() });
    }
    total = map[map.length - 1].len;
    // The last point must be reachable while its section is on screen.
    map[map.length - 1].key = Math.max(map[map.length - 2].key + 1, pts[pts.length - 1].y);
    glow.setAttribute('d', d);
    line.setAttribute('d', d);
    [glow, line].forEach((p) => { p.style.strokeDasharray = total + ' ' + total; });
    ready = true;
    draw();
  }
  function lengthAt(y) {
    if (y <= map[0].key) return 0;
    for (let i = 1; i < map.length; i++) {
      if (y <= map[i].key) {
        const a = map[i - 1], b = map[i];
        return a.len + (b.len - a.len) * (y - a.key) / (b.key - a.key);
      }
    }
    return total;
  }
  function draw() {
    raf = 0;
    if (!ready) return;
    const top = main.getBoundingClientRect().top;
    const atEnd = innerHeight + scrollY >= document.documentElement.scrollHeight - 80;
    const len = reduced.matches || atEnd ? total : lengthAt(-top + innerHeight * .62);
    const off = total - len;
    [glow, line].forEach((p) => { p.style.strokeDashoffset = off; });
    const pt = line.getPointAtLength(len);
    const r = len >= total - 1 ? 22 : 7;
    head.setAttribute('cx', pt.x); head.setAttribute('cy', pt.y); head.setAttribute('r', r);
    halo.setAttribute('cx', pt.x); halo.setAttribute('cy', pt.y); halo.setAttribute('r', r * 3.6);
  }
  const wake = () => { if (!raf) raf = requestAnimationFrame(draw); };
  addEventListener('scroll', wake, { passive: true });
  let t = 0;
  const later = () => { clearTimeout(t); t = setTimeout(build, 120); };
  new ResizeObserver(later).observe(main);
  reduced.addEventListener('change', wake);
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(build);
  addEventListener('load', build);
  build();
})();
