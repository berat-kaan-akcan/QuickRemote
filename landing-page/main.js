/* QuickRemote landing page: the live demos.
   Shared by the Turkish and English pages; every visible word comes from
   the HTML. Without JavaScript the page still shows the first slide, all
   three connection panels and the drawing with its ink. */
(() => {
  'use strict';

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));
  const pad2 = (n) => String(n).padStart(2, '0');
  const mmss = (s) => `${pad2(Math.floor(s / 60))}:${pad2(s % 60)}`;

  /** Starts the CSS animation behind [cls] on [el] again. */
  function replay(el, cls) {
    el.classList.remove(cls);
    void el.offsetWidth;
    el.classList.add(cls);
  }

  /** Runs [fn] the first time [el] comes into view. */
  function onceVisible(el, fn, threshold = 0.35) {
    if (!('IntersectionObserver' in window)) return fn();
    const io = new IntersectionObserver((entries) => {
      if (!entries.some((e) => e.isIntersecting)) return;
      io.disconnect();
      fn();
    }, { threshold });
    io.observe(el);
  }

  /** Tells [fn] whether [el] is in view, each time that changes. */
  function whileVisible(el, fn) {
    if (!('IntersectionObserver' in window)) return fn(true);
    new IntersectionObserver((entries) => fn(entries[entries.length - 1].isIntersecting)).observe(el);
  }

  // ── Header: a border once the page moves, and the small-screen menu ──

  function initHeader() {
    const top = $('[data-top]');
    if (!top) return;
    const sentinel = document.createElement('div');
    sentinel.setAttribute('aria-hidden', 'true');
    sentinel.style.cssText = 'position:absolute;top:0;left:0;width:1px;height:1px;pointer-events:none';
    document.body.prepend(sentinel);
    new IntersectionObserver(([e]) => top.classList.toggle('is-stuck', !e.isIntersecting)).observe(sentinel);

    const btn = $('[data-menu-btn]');
    const menu = $('[data-menu]');
    if (!btn || !menu) return;
    const setOpen = (open) => {
      btn.setAttribute('aria-expanded', String(open));
      menu.hidden = !open;
    };
    btn.addEventListener('click', () => setOpen(menu.hidden));
    menu.addEventListener('click', (e) => { if (e.target.closest('a')) setOpen(false); });
    document.addEventListener('keydown', (e) => {
      if (e.key !== 'Escape' || menu.hidden) return;
      setOpen(false);
      btn.focus();
    });
    window.matchMedia('(min-width: 900px)').addEventListener('change', (e) => { if (e.matches) setOpen(false); });
  }

  // ── A slideshow on one screen ───────────────────────────────────────────

  /**
   * The state a presentation program keeps: the slide, a black or white
   * screen, and whether the show runs or the editor is back after End.
   * [onChange] hears every change.
   */
  function createShow(glass, onChange) {
    const slides = $$('.slide', glass);
    const thumbs = $$('.rail i', glass);
    const state = { index: 0, total: slides.length, running: true, blank: null };

    function render() {
      slides.forEach((s, i) => {
        const on = i === state.index;
        s.classList.toggle('is-on', on);
        s.classList.toggle('is-before', i < state.index);
        s.inert = !on;
      });
      thumbs.forEach((t, i) => t.classList.toggle('is-on', i === state.index));
      glass.classList.toggle('is-editor', !state.running);
      glass.classList.toggle('is-black', state.blank === 'black');
      glass.classList.toggle('is-white', state.blank === 'white');
      if (onChange) onChange(state);
    }

    /** Applies a remote command as PowerPoint would; false when nothing changes. */
    function command(cmd) {
      const last = state.total - 1;
      switch (cmd) {
        case 'next':
          if (state.blank) state.blank = null;
          else if (state.index < last) state.index += 1;
          else return false;
          break;
        case 'prev':
          if (state.blank) state.blank = null;
          else if (state.index > 0) state.index -= 1;
          else return false;
          break;
        case 'start':
          state.running = true;
          state.index = 0;
          state.blank = null;
          break;
        case 'end':
          if (!state.running) return false;
          state.running = false;
          state.blank = null;
          break;
        case 'black':
        case 'white':
          if (!state.running) return false;
          state.blank = state.blank === cmd ? null : cmd;
          break;
        default:
          return false;
      }
      render();
      return true;
    }

    render();
    return { state, command };
  }

  /** The laser dot follows the pointer over the slide, a little behind it. */
  function initLaser(glass) {
    const dot = $('.laser', glass);
    if (!dot) return;
    let tx = 0;
    let ty = 0;
    let x = 0;
    let y = 0;
    let frame = 0;
    let shown = false;

    const step = () => {
      const k = reduceMotion.matches ? 1 : 0.3;
      x += (tx - x) * k;
      y += (ty - y) * k;
      dot.style.transform = `translate3d(${x.toFixed(1)}px, ${y.toFixed(1)}px, 0)`;
      frame = Math.abs(tx - x) + Math.abs(ty - y) > 0.4 ? requestAnimationFrame(step) : 0;
    };
    glass.addEventListener('pointermove', (e) => {
      const r = glass.getBoundingClientRect();
      tx = e.clientX - r.left;
      ty = e.clientY - r.top;
      if (!shown) {
        x = tx;
        y = ty;
        shown = true;
        glass.classList.add('has-laser');
      }
      if (!frame) frame = requestAnimationFrame(step);
    });
    const hide = () => {
      shown = false;
      glass.classList.remove('has-laser');
    };
    glass.addEventListener('pointerleave', hide);
    glass.addEventListener('pointercancel', hide);
  }

  // ── Hero: the phone remote drives the sample talk ───────────────────────

  function initHero() {
    const stage = $('[data-stage]');
    if (!stage) return null;
    const screen = $('.screen', stage);
    const glass = $('[data-show]', stage);
    const phone = $('[data-phone]', stage);
    const live = $('[data-live]', stage);
    const ph = $('.ph', phone);
    const cur = $('[data-cur]', phone);
    const segments = $$('[data-track] i', phone);
    const clock = $('[data-timer]', phone);
    const sheet = $('[data-sheet]', phone);
    const noteText = $('[data-note-text]', phone);
    const notesBtn = $('.ph-notes', phone);
    const nextBtn = $('.ph-next', phone);
    const blackBtn = $('[data-cmd="black"]', phone);
    const whiteBtn = $('[data-cmd="white"]', phone);
    const slides = $$('.slide', glass);
    let shownIndex = 0;

    const show = createShow(glass, (st) => {
      if (st.index !== shownIndex) {
        cur.textContent = String(st.index + 1);
        if (!reduceMotion.matches) replay(cur, 'is-new');
        shownIndex = st.index;
      }
      segments.forEach((s, i) => {
        s.classList.toggle('is-on', i === st.index);
        s.classList.toggle('is-past', i < st.index);
      });
      ph.classList.toggle('is-ended', !st.running);
      blackBtn.setAttribute('aria-pressed', String(st.blank === 'black'));
      whiteBtn.setAttribute('aria-pressed', String(st.blank === 'white'));
      noteText.textContent = slides[st.index] ? slides[st.index].dataset.note || '' : '';
    });

    // The presentation timer counts from the first press, like the app's
    // free-running timer, and stops when the show ends.
    let elapsed = 0;
    let since = 0;
    let ticker = 0;
    const runTimer = (on) => {
      if (on && !ticker) {
        since = Date.now() - elapsed * 1000;
        ticker = setInterval(() => {
          elapsed = Math.floor((Date.now() - since) / 1000);
          clock.textContent = mmss(elapsed);
        }, 250);
      } else if (!on && ticker) {
        clearInterval(ticker);
        ticker = 0;
      }
    };

    const announce = () => {
      const { index, total } = show.state;
      live.textContent = live.dataset.live.replace('{n}', index + 1).replace('{t}', total);
    };

    const toggleNotes = () => {
      const open = sheet.hidden;
      sheet.hidden = !open;
      notesBtn.setAttribute('aria-expanded', String(open));
    };

    function send(cmd) {
      if (cmd === 'notes') return toggleNotes();
      nextBtn.classList.remove('is-hint');
      if (cmd === 'start') {
        runTimer(false);
        elapsed = 0;
        clock.textContent = mmss(0);
      }
      const changed = show.command(cmd);
      runTimer(show.state.running);
      if (changed) announce();
    }

    phone.addEventListener('click', (e) => {
      const b = e.target.closest('[data-cmd]');
      if (b) send(b.dataset.cmd);
    });
    // A click on a running show moves to the next slide, as in PowerPoint.
    screen.addEventListener('click', () => { if (show.state.running) send('next'); });
    screen.addEventListener('keydown', (e) => {
      if (e.altKey || e.ctrlKey || e.metaKey) return;
      const cmd = {
        ArrowRight: 'next', ArrowDown: 'next', PageDown: 'next', ' ': 'next', Enter: 'next',
        ArrowLeft: 'prev', ArrowUp: 'prev', PageUp: 'prev',
        b: 'black', B: 'black', w: 'white', W: 'white', Escape: 'end', Home: 'start',
      }[e.key];
      if (!cmd) return;
      e.preventDefault();
      send(cmd);
    });

    initLaser(glass);
    return glass;
  }

  // ── Watch: bezel, halves and the actions list ──────────────────────────

  function initWatch(heroGlass) {
    const demo = $('[data-watch-demo]');
    if (!demo) return;
    const watch = $('[data-watch]', demo);
    const bezel = $('[data-bezel]', demo);
    const mirror = $('[data-mirror]', demo);
    const menuBtn = $('[data-wmenu]', demo);
    const menu = $('[data-wmenu-panel]', demo);
    const keys = new Map($$('[data-key]', demo).map((k) => [k.dataset.key, k]));

    // The screen beside the watch shows the same talk as the hero.
    const deck = $('.deck', mirror);
    if (heroGlass && !deck.children.length) {
      $$('.slide', heroGlass).forEach((s) => {
        const copy = s.cloneNode(true);
        copy.classList.remove('is-on', 'is-before');
        deck.append(copy);
      });
    }
    const show = createShow(mirror);
    const live = $('[data-live]', demo);

    // A keyboard gets no answer from the computer: the key goes out whatever
    // the slide does, and the wrist buzzes for it (Haptics.sent / step).
    function press(cmd, fromBezel) {
      if (show.command(cmd) && live) {
        const { index, total } = show.state;
        live.textContent = live.dataset.live.replace('{n}', index + 1).replace('{t}', total);
      }
      const key = keys.get(cmd);
      if (key) {
        key.classList.add('is-down');
        clearTimeout(key.upTimer);
        key.upTimer = setTimeout(() => key.classList.remove('is-down'), 170);
      }
      if (!reduceMotion.matches) replay(watch, fromBezel ? 'is-tick' : 'is-buzz');
    }

    // One detent of the bezel is 15 degrees and one slide.
    let angle = 0;
    function turn(steps) {
      angle += steps * 15;
      bezel.style.setProperty('--bz', `${angle}deg`);
      // On a list the bezel scrolls it, as on the watch.
      if (!menu.hidden) {
        menu.scrollBy({ top: steps * menu.clientHeight * 0.2, behavior: reduceMotion.matches ? 'auto' : 'smooth' });
        if (!reduceMotion.matches) replay(watch, 'is-tick');
        return;
      }
      press(steps > 0 ? 'next' : 'prev', true);
    }

    const angleAt = (e) => {
      const r = watch.getBoundingClientRect();
      return (Math.atan2(e.clientY - (r.top + r.height / 2), e.clientX - (r.left + r.width / 2)) * 180) / Math.PI;
    };
    let drag = null;
    bezel.addEventListener('pointerdown', (e) => {
      drag = { id: e.pointerId, last: angleAt(e), sum: 0 };
      bezel.setPointerCapture(e.pointerId);
      watch.classList.add('is-turning');
    });
    bezel.addEventListener('pointermove', (e) => {
      if (!drag || e.pointerId !== drag.id) return;
      const a = angleAt(e);
      let d = a - drag.last;
      if (d > 180) d -= 360;
      if (d < -180) d += 360;
      drag.last = a;
      drag.sum += d;
      while (drag.sum >= 15) { drag.sum -= 15; turn(1); }
      while (drag.sum <= -15) { drag.sum += 15; turn(-1); }
    });
    const endDrag = () => {
      drag = null;
      watch.classList.remove('is-turning');
    };
    bezel.addEventListener('pointerup', endDrag);
    bezel.addEventListener('pointercancel', endDrag);

    // The wheel turns the bezel only after the watch was touched, so that
    // scrolling the page past it never gets caught.
    let engaged = false;
    let wheelAt = 0;
    watch.addEventListener('pointerdown', () => { engaged = true; });
    watch.addEventListener('pointerleave', () => { engaged = false; });
    watch.addEventListener('wheel', (e) => {
      if (!engaged || Math.abs(e.deltaY) < 2) return;
      e.preventDefault();
      const now = performance.now();
      if (now - wheelAt < 140) return;
      wheelAt = now;
      turn(e.deltaY > 0 ? 1 : -1);
    }, { passive: false });

    const openMenu = () => {
      menu.hidden = false;
      menuBtn.setAttribute('aria-expanded', 'true');
      const first = $('button', menu);
      if (first) first.focus({ preventScroll: true });
    };
    const closeMenu = () => {
      menu.hidden = true;
      menuBtn.setAttribute('aria-expanded', 'false');
    };

    watch.addEventListener('click', (e) => {
      const b = e.target.closest('[data-cmd]');
      if (b) {
        press(b.dataset.cmd, false);
        // Each action is pressed once, then the remote is back (ActionsScreen).
        if (menu.contains(b)) {
          closeMenu();
          menuBtn.focus({ preventScroll: true });
        }
        return;
      }
      if (e.target.closest('[data-wmenu]')) openMenu();
      else if (e.target === menu) closeMenu();
    });
    watch.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && !menu.hidden) {
        closeMenu();
        menuBtn.focus();
        return;
      }
      if (e.target !== watch) return;
      const steps = { ArrowRight: 1, ArrowDown: 1, PageDown: 1, ArrowLeft: -1, ArrowUp: -1, PageUp: -1 }[e.key];
      if (!steps) return;
      e.preventDefault();
      turn(steps);
    });

    // Once, when the watch first shows: the bezel clicks one detent and back,
    // so that it reads as something to turn.
    if (!reduceMotion.matches) {
      onceVisible(watch, () => {
        if (angle !== 0) return;
        bezel.style.setProperty('--bz', '15deg');
        setTimeout(() => { if (angle === 0) bezel.style.setProperty('--bz', '0deg'); }, 380);
      }, 0.6);
    }
  }

  /**
   * Watch faces show the visitor's own time in the page's language, without
   * AM/PM, as Wear OS TimeText does.
   */
  function initClocks() {
    const clocks = $$('[data-clock]');
    if (!clocks.length) return;
    const format = new Intl.DateTimeFormat(document.documentElement.lang, { hour: 'numeric', minute: '2-digit' });
    const tick = () => {
      const t = format.formatToParts(new Date())
        .filter((p) => p.type === 'hour' || p.type === 'minute' || (p.type === 'literal' && p.value.trim()))
        .map((p) => p.value)
        .join('');
      clocks.forEach((c) => { c.textContent = t; });
    };
    tick();
    setInterval(tick, 15000);
  }

  // ── How it works: tabs ─────────────────────────────────────────────────

  function initTabs() {
    const list = $('[data-tabs]');
    if (!list) return;
    const tabs = $$('[role="tab"]', list);
    const panels = tabs.map((t) => document.getElementById(t.getAttribute('aria-controls')));

    function select(i, focus) {
      tabs.forEach((t, j) => {
        const on = i === j;
        t.setAttribute('aria-selected', String(on));
        t.tabIndex = on ? 0 : -1;
        panels[j].hidden = !on;
      });
      list.style.setProperty('--i', i);
      if (focus) tabs[i].focus();
    }
    const go = (i, focus) => {
      if (tabs[i].getAttribute('aria-selected') === 'true') return;
      select(i, focus);
      if (!reduceMotion.matches) replay(panels[i], 'is-in');
    };

    tabs.forEach((t, i) => t.addEventListener('click', () => go(i)));
    list.addEventListener('keydown', (e) => {
      const i = tabs.indexOf(document.activeElement);
      if (i < 0) return;
      const n = { ArrowRight: i + 1, ArrowLeft: i - 1, Home: 0, End: tabs.length - 1 }[e.key];
      if (n === undefined) return;
      e.preventDefault();
      go((n + tabs.length) % tabs.length, true);
    });
    select(0);
  }

  // ── Drawing on the slide ───────────────────────────────────────────────

  function initDraw() {
    const draw = $('[data-draw]');
    const tools = $('[data-tools]');
    if (!draw || !tools) return;
    const swatches = $('[data-swatches]');
    const swatchLabel = $('[data-swatch-label]');
    const inks = { pen: '#FF1744', highlighter: '#FFEA00' };
    let tool = 'pen';
    let pending = [];

    const later = (fn, ms) => pending.push(setTimeout(fn, ms));
    const rgba = (hex, a) => {
      const n = parseInt(hex.slice(1), 16);
      return `rgb(${(n >> 16) & 255} ${(n >> 8) & 255} ${n & 255} / ${a})`;
    };

    function syncButtons() {
      $$('.tool', tools).forEach((b) => {
        if (b.dataset.tool !== 'clear') b.setAttribute('aria-pressed', String(b.dataset.tool === tool));
      });
      const which = tool === 'highlighter' ? 'highlighter' : 'pen';
      const label = which === 'pen' ? swatches.dataset.labelPen : swatches.dataset.labelHighlighter;
      swatches.setAttribute('aria-label', label);
      swatchLabel.textContent = label;
      $$('.swatch', swatches).forEach((s) => {
        const on = s.dataset.ink === inks[which];
        s.setAttribute('aria-checked', String(on));
        s.tabIndex = on ? 0 : -1;
      });
    }

    function penStroke() {
      draw.classList.remove('is-erasing');
      draw.classList.add('has-pen');
      if (!reduceMotion.matches) replay(draw, 'is-drawing');
    }
    function highlight() {
      draw.classList.remove('has-hl', 'is-sweeping');
      if (reduceMotion.matches) return draw.classList.add('has-hl');
      void draw.offsetWidth;
      draw.classList.add('is-sweeping', 'has-hl');
    }

    function use(name) {
      pending.forEach(clearTimeout);
      pending = [];
      draw.classList.remove('is-laser');
      if (name === 'clear') {
        draw.classList.remove('has-pen', 'has-hl', 'is-drawing', 'is-erasing');
        return;
      }
      tool = name;
      syncButtons();
      if (name === 'pen') penStroke();
      else if (name === 'highlighter') highlight();
      else if (name === 'laser') draw.classList.add('is-laser');
      else if (name === 'eraser' && draw.classList.contains('has-pen')) {
        replay(draw, 'is-erasing');
        later(() => draw.classList.remove('has-pen', 'is-drawing', 'is-erasing'), reduceMotion.matches ? 0 : 720);
      }
    }

    tools.addEventListener('click', (e) => {
      const b = e.target.closest('[data-tool]');
      if (b) use(b.dataset.tool);
    });

    const pick = (s) => {
      const which = tool === 'highlighter' ? 'highlighter' : 'pen';
      inks[which] = s.dataset.ink;
      if (which === 'pen') {
        draw.style.setProperty('--pen', s.dataset.ink);
        if (!draw.classList.contains('has-pen')) penStroke();
      } else {
        draw.style.setProperty('--hl', rgba(s.dataset.ink, 0.5));
        if (!draw.classList.contains('has-hl')) highlight();
      }
      syncButtons();
    };
    swatches.addEventListener('click', (e) => {
      const s = e.target.closest('.swatch');
      if (s) pick(s);
    });
    swatches.addEventListener('keydown', (e) => {
      const all = $$('.swatch', swatches);
      const i = all.indexOf(document.activeElement);
      if (i < 0) return;
      const step = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
      if (!step) return;
      e.preventDefault();
      const next = all[(i + step + all.length) % all.length];
      pick(next);
      next.focus();
    });
    syncButtons();

    // The ink is drawn when the slide first comes into view: a circle with
    // the pen, then a highlighter stroke, as from the phone.
    if (reduceMotion.matches) return;
    draw.classList.remove('has-pen', 'has-hl');
    onceVisible(draw, () => {
      if (draw.classList.contains('has-pen') || draw.classList.contains('has-hl')) return;
      penStroke();
      later(highlight, 1050);
    }, 0.5);
  }

  // ── Timer with its early warning ───────────────────────────────────────

  function initTimerDemo() {
    const demo = $('[data-timer-demo]');
    if (!demo) return;
    const btn = $('[data-t-btn]', demo);
    const out = $('[data-t]', demo);
    const snack = $('[data-snack]', demo);
    const from = 309;
    const warnAt = 300;
    // The demo runs on its own only through the warning, then waits; a tap
    // starts and pauses it, as on the phone.
    const autoStop = 290;
    let left = from;
    let running = false;
    let visible = false;
    let ticker = 0;
    let hideSnack = 0;
    let auto = false;

    const warn = () => {
      snack.classList.add('is-on');
      clearTimeout(hideSnack);
      hideSnack = setTimeout(() => snack.classList.remove('is-on'), 5000);
    };
    const sync = () => {
      btn.setAttribute('aria-pressed', String(running));
      const tick = running && visible;
      if (tick && !ticker) ticker = setInterval(step, 1000);
      else if (!tick && ticker) {
        clearInterval(ticker);
        ticker = 0;
      }
    };
    function step() {
      left = Math.max(0, left - 1);
      out.textContent = mmss(left);
      if (left === warnAt) warn();
      if (left === autoStop && auto) {
        auto = false;
        running = false;
      }
      if (left === 0) running = false;
      sync();
    }

    btn.addEventListener('click', () => {
      auto = false;
      if (left === 0) {
        left = from;
        out.textContent = mmss(left);
      }
      running = !running;
      sync();
    });
    whileVisible(demo, (v) => {
      visible = v;
      sync();
    });
    if (reduceMotion.matches) {
      left = warnAt;
      out.textContent = mmss(left);
      snack.classList.add('is-on');
      return;
    }
    onceVisible(demo, () => {
      auto = true;
      running = true;
      sync();
    }, 0.6);
  }

  // ── Touchpad glow, report bars, media ──────────────────────────────────

  function initPad() {
    const pad = $('[data-pad]');
    if (!pad) return;
    const glow = $('.pad-glow', pad);
    const place = (x, y) => { glow.style.transform = `translate(${x}px, ${y}px)`; };
    const move = (e) => {
      const r = pad.getBoundingClientRect();
      place(e.clientX - r.left, e.clientY - r.top);
    };
    // Until the visitor's own finger arrives, a drawn trail ends in the
    // glow, where the last touch was.
    const rest = () => place(pad.clientWidth * 0.86, pad.clientHeight * 0.375);
    const touch = (e) => {
      move(e);
      pad.classList.remove('is-idle');
      pad.classList.add('is-touching');
    };
    rest();
    window.addEventListener('resize', () => { if (pad.classList.contains('is-idle')) rest(); });
    onceVisible(pad, () => {
      pad.classList.add('is-shown');
      setTimeout(() => { if (!pad.classList.contains('is-touching')) pad.classList.add('is-idle'); }, reduceMotion.matches ? 0 : 1200);
    }, 0.5);
    pad.addEventListener('pointerenter', touch);
    pad.addEventListener('pointerdown', touch);
    pad.addEventListener('pointermove', move);
    const off = () => pad.classList.remove('is-touching');
    pad.addEventListener('pointerleave', off);
    pad.addEventListener('pointercancel', off);
  }

  function initReport() {
    const report = $('[data-report]');
    if (report) onceVisible(report, () => report.classList.add('is-in'), 0.4);
  }

  function initMedia() {
    const media = $('[data-media]');
    if (!media) return;
    const play = $('[data-media-cmd="play"]', media);
    const label = $('span', play);
    const bar = $('.m-bar i', media);
    const vol = $('[data-vol]', media);
    const volOut = $('[data-vol-out]', media);
    const length = 24000;
    let progress = 0.18;
    let playing = false;
    let frame = 0;
    let last = 0;

    const paint = () => { bar.style.transform = `scaleX(${progress})`; };
    const step = (t) => {
      if (!playing) return;
      if (last) progress = Math.min(1, progress + (t - last) / length);
      last = t;
      paint();
      if (progress >= 1) return setPlaying(false);
      frame = requestAnimationFrame(step);
    };
    function setPlaying(on) {
      playing = on;
      media.classList.toggle('is-playing', on);
      label.textContent = on ? play.dataset.pause : play.dataset.play;
      last = 0;
      cancelAnimationFrame(frame);
      if (!on) return;
      if (progress >= 1) progress = 0;
      frame = requestAnimationFrame(step);
    }

    media.addEventListener('click', (e) => {
      const b = e.target.closest('[data-media-cmd]');
      if (!b) return;
      if (b.dataset.mediaCmd === 'play') return setPlaying(!playing);
      progress = 0;
      last = 0;
      paint();
    });

    // "%64" in Turkish, "64%" in English.
    const percent = new Intl.NumberFormat(document.documentElement.lang, { style: 'percent' });
    const syncVolume = () => {
      volOut.textContent = percent.format(vol.value / 100);
      vol.style.setProperty('--p', `${vol.value}%`);
    };
    vol.addEventListener('input', syncVolume);
    syncVolume();
  }

  initHeader();
  const heroGlass = initHero();
  initWatch(heroGlass);
  initClocks();
  initTabs();
  initDraw();
  initTimerDemo();
  initPad();
  initReport();
  initMedia();
})();
