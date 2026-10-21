/* QuickRemote site: the live demos. Shared by the Turkish and English
   pages; every visible word comes from the HTML. Without JavaScript the
   page still shows the first slide, all three connection panels and the
   drawing with its ink. */
(() => {
  'use strict';

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));
  const pad2 = (n) => String(n).padStart(2, '0');
  const mmss = (s) => `${pad2(Math.floor(s / 60))}:${pad2(s % 60)}`;
  const fill = (text, n, t) => text.replace('%n', n).replace('%t', t);

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

  /** Arrow keys move a radio group's choice, as a native group does. */
  function radioGroup(group, onPick) {
    const radios = () => $$('[role="radio"]:not([disabled])', group);
    const pick = (r, focus) => {
      $$('[role="radio"]', group).forEach((b) => {
        const on = b === r;
        b.setAttribute('aria-checked', String(on));
        b.tabIndex = on ? 0 : -1;
      });
      if (focus) r.focus();
      onPick(r);
    };
    group.addEventListener('click', (e) => {
      const r = e.target.closest('[role="radio"]');
      if (r && !r.disabled) pick(r, false);
    });
    group.addEventListener('keydown', (e) => {
      const all = radios();
      const i = all.indexOf(document.activeElement);
      if (i < 0) return;
      const step = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
      if (!step) return;
      e.preventDefault();
      pick(all[(i + step + all.length) % all.length], true);
    });
    return pick;
  }

  /**
   * A dot that follows the pointer over [area], a little behind it, and
   * goes back to its CSS resting place when the pointer leaves.
   */
  function follower(area, dot, enabled = () => true) {
    let tx = 0, ty = 0, x = 0, y = 0, frame = 0, shown = false;
    const step = () => {
      const k = reduceMotion.matches ? 1 : 0.3;
      x += (tx - x) * k;
      y += (ty - y) * k;
      dot.style.translate = `${x.toFixed(1)}px ${y.toFixed(1)}px`;
      frame = Math.abs(tx - x) + Math.abs(ty - y) > 0.4 ? requestAnimationFrame(step) : 0;
    };
    area.addEventListener('pointermove', (e) => {
      if (!enabled() || e.pointerType === 'touch') return;
      const r = area.getBoundingClientRect();
      tx = e.clientX - r.left;
      ty = e.clientY - r.top;
      if (!shown) {
        const cur = getComputedStyle(dot).translate.split(' ').map(parseFloat);
        x = Number.isFinite(cur[0]) ? cur[0] : tx;
        y = Number.isFinite(cur[1]) ? cur[1] : ty;
        shown = true;
      }
      if (!frame) frame = requestAnimationFrame(step);
    });
    const rest = () => {
      shown = false;
      cancelAnimationFrame(frame);
      frame = 0;
      dot.style.translate = '';
    };
    area.addEventListener('pointerleave', rest);
    area.addEventListener('pointercancel', rest);
    return rest;
  }

  // ── Appearance of the site, and the phone's and watch's color themes ───

  const root = document.documentElement;
  const dark = window.matchMedia('(prefers-color-scheme: dark)');
  const siteLook = {
    mode: (() => { try { const t = localStorage.getItem('qr-theme'); return t === 'light' || t === 'dark' ? t : 'system'; } catch (e) { return 'system'; } })(),
    listeners: [],
  };

  function setSiteLook(mode) {
    siteLook.mode = mode;
    if (mode === 'system') delete root.dataset.theme;
    else root.dataset.theme = mode;
    try {
      if (mode === 'system') localStorage.removeItem('qr-theme');
      else localStorage.setItem('qr-theme', mode);
    } catch (e) { /* private window: the choice lasts until the page closes */ }
    siteLook.listeners.forEach((fn) => fn(mode));
  }

  function initThemeButton() {
    const btn = $('[data-theme-btn]');
    if (!btn) return;
    const labels = btn.dataset.labels.split('|');
    const order = ['system', 'light', 'dark'];
    const label = $('[data-theme-label]', btn);
    const paint = (mode) => {
      btn.dataset.mode = mode;
      label.textContent = labels[order.indexOf(mode)];
    };
    paint(siteLook.mode);
    siteLook.listeners.push(paint);
    btn.addEventListener('click', () => setSiteLook(order[(order.indexOf(siteLook.mode) + 1) % order.length]));
  }

  const colorTheme = { name: 'cobalt', mode: 'dark', watch: true };
  const DARK_ONLY = new Set(['oled', 'contrast', 'mint', 'violet']);

  /** Gives every phone and watch on the page the picked theme, as Ayarlar → Tema does. */
  function applyColorTheme() {
    const { name, mode, watch } = colorTheme;
    const resolved = name === 'cobalt' ? (mode === 'system' ? (dark.matches ? 'dark' : 'light') : mode) : DARK_ONLY.has(name) ? 'dark' : 'light';
    $$('.phone').forEach((p) => {
      p.dataset.theme = name;
      p.dataset.mode = resolved;
    });
    // A watch is always dark: the phone sends Sunset as Cobalt.
    const onWatch = watch ? (name === 'sunset' ? 'cobalt' : name) : 'cobalt';
    $$('.watch').forEach((w) => { w.dataset.theme = onWatch; });
  }

  function initThemes() {
    const panel = $('[data-themes]');
    if (!panel) return;
    const list = $('[data-theme-list]', panel);
    const modes = $('[data-theme-mode]', panel);
    const note = $('[data-theme-note]', panel);
    const watchSwitch = $('[data-watch-theme]', panel);
    const watchNote = $('[data-watch-note]', panel);

    const sync = () => {
      const { name } = colorTheme;
      const fixed = name !== 'cobalt';
      $$('[role="radio"]', modes).forEach((b) => {
        b.disabled = fixed;
        const on = fixed ? b.dataset.mode === (DARK_ONLY.has(name) ? 'dark' : 'light') : b.dataset.mode === colorTheme.mode;
        b.setAttribute('aria-checked', String(on));
        b.tabIndex = on ? 0 : -1;
      });
      note.textContent = name === 'cobalt' ? note.dataset.cobalt : DARK_ONLY.has(name) ? note.dataset.dark : note.dataset.light;
      watchNote.hidden = !(name === 'sunset' && colorTheme.watch);
      applyColorTheme();
    };

    radioGroup(list, (r) => { colorTheme.name = r.dataset.theme; sync(); });
    radioGroup(modes, (r) => { colorTheme.mode = r.dataset.mode; sync(); });
    watchSwitch.addEventListener('change', () => { colorTheme.watch = watchSwitch.checked; sync(); });
    dark.addEventListener('change', () => { if (colorTheme.mode === 'system') applyColorTheme(); });
    sync();
  }

  // ── Header: a hairline once the page moves, and the small-screen menu ──

  function initHeader() {
    const top = $('[data-top]');
    if (!top) return;
    const sentinel = document.createElement('div');
    sentinel.setAttribute('aria-hidden', 'true');
    sentinel.style.cssText = 'position:absolute;top:0;left:0;width:1px;height:1px;pointer-events:none';
    const skip = $('.skip');
    if (skip) skip.after(sentinel);
    else document.body.prepend(sentinel);
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
   */
  function createShow(show, onChange) {
    const slides = $$('.slide', show);
    const state = { index: 0, total: slides.length, running: true, blank: null };

    function render() {
      slides.forEach((s, i) => s.classList.toggle('is-on', i === state.index));
      show.classList.toggle('is-editor', !state.running);
      show.classList.toggle('is-black', state.blank === 'black');
      show.classList.toggle('is-white', state.blank === 'white');
      if (onChange) onChange(state);
    }

    /** Applies a remote command as PowerPoint would; false when nothing changes. */
    function command(cmd, arg) {
      const last = state.total - 1;
      switch (cmd) {
        case 'next':
          if (!state.running) return false;
          if (state.blank) state.blank = null;
          else if (state.index < last) state.index += 1;
          else return false;
          break;
        case 'prev':
          if (!state.running) return false;
          if (state.blank) state.blank = null;
          else if (state.index > 0) state.index -= 1;
          else return false;
          break;
        case 'goto':
          if (!state.running || arg < 0 || arg > last) return false;
          state.blank = null;
          state.index = arg;
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

  /** A copy of a slide for a thumbnail: same look, none of the demo's state. */
  function slideCopy(slide, on = true) {
    const c = slide.cloneNode(true);
    c.removeAttribute('data-note');
    c.classList.toggle('is-on', on);
    return c;
  }

  // ── Hero: the phone drives the sample talk along the line ───────────────

  function initHero() {
    const stage = $('[data-stage]');
    if (!stage) return;
    const screen = $('.screen', stage);
    const showEl = $('[data-show]', stage);
    const phone = $('[data-phone]', stage);
    const live = $('[data-live]', stage);
    const ph = $('.ph', phone);
    const cur = $('[data-cur]', phone);
    const segments = $$('[data-track] i', phone);
    const clock = $('[data-timer]', phone);
    const notesSheet = $('[data-sheet="notes"]', phone);
    const gotoSheet = $('[data-sheet="goto"]', phone);
    const noteText = $('[data-note-text]', phone);
    const noteLine = $('[data-note-line]', phone);
    const notesBtn = $('.ph-notes', phone);
    const gotoBtn = $('.ph-goto', phone);
    const nextBtn = $('.ph-next', phone);
    const blackBtn = $('[data-cmd="black"]', phone);
    const whiteBtn = $('[data-cmd="white"]', phone);
    const toggleBtn = $('[data-cmd="toggle"]', phone);
    const toggleLabel = $('[data-toggle-label]', phone);
    const thumb = $('[data-clones]', phone);
    const grid = $('[data-grid]', phone);
    const pulse = $('[data-pulse]', stage);
    const laser = $('[data-laser]', stage);
    const slides = $$('.slide', showEl);
    let shownIndex = 0;

    // The thumbnail on the card and the grid of "Go to slide" are copies of the deck.
    const thumbSlides = slides.map((s) => thumb.appendChild(slideCopy(s, false)));
    slides.forEach((s, i) => {
      const cell = document.createElement('button');
      cell.type = 'button';
      cell.className = 'ph-cell';
      cell.dataset.goto = String(i);
      cell.setAttribute('aria-label', fill(live.dataset.live, i + 1, slides.length));
      const frame = document.createElement('div');
      frame.className = 'show';
      frame.setAttribute('aria-hidden', 'true');
      frame.appendChild(slideCopy(s));
      const num = document.createElement('b');
      num.textContent = String(i + 1);
      num.setAttribute('aria-hidden', 'true');
      cell.append(frame, num);
      grid.appendChild(cell);
    });
    const cells = $$('.ph-cell', grid);

    const show = createShow(showEl, (st) => {
      if (st.index !== shownIndex) {
        cur.textContent = String(st.index + 1);
        if (!reduceMotion.matches) replay(cur, 'is-new');
        shownIndex = st.index;
      }
      segments.forEach((s, i) => {
        s.classList.toggle('is-on', i === st.index);
        s.classList.toggle('is-past', i < st.index);
      });
      thumbSlides.forEach((s, i) => s.classList.toggle('is-on', i === st.index));
      cells.forEach((c, i) => c.setAttribute('aria-current', String(i === st.index)));
      thumb.classList.toggle('is-black', st.blank === 'black');
      thumb.classList.toggle('is-white', st.blank === 'white');
      ph.classList.toggle('is-ended', !st.running);
      toggleLabel.textContent = st.running ? toggleBtn.dataset.end : toggleBtn.dataset.start;
      blackBtn.setAttribute('aria-pressed', String(st.blank === 'black'));
      whiteBtn.setAttribute('aria-pressed', String(st.blank === 'white'));
      const note = slides[st.index] ? slides[st.index].dataset.note || '' : '';
      noteText.textContent = note;
      noteLine.textContent = note;
    });

    // The presentation timer counts from the first command, like the app's
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
      const { index, total, running } = show.state;
      live.textContent = running ? fill(live.dataset.live, index + 1, total) : live.dataset.ended;
    };
    announce();

    const sheets = { notes: [notesSheet, notesBtn], goto: [gotoSheet, gotoBtn] };
    const toggleSheet = (name, force) => {
      Object.entries(sheets).forEach(([key, [sheet, btn]]) => {
        const open = key === name ? (force === undefined ? sheet.hidden : force) : false;
        if (sheet.hidden === !open) return;
        sheet.hidden = !open;
        btn.setAttribute('aria-expanded', String(open));
        if (open) $('.ph-sheet-close', sheet).focus({ preventScroll: true });
        else if (key === name) btn.focus({ preventScroll: true });
      });
    };

    // A command travels along the line, and lands where the laser rests.
    let landing = 0;
    const signal = () => {
      if (reduceMotion.matches || !pulse) return;
      replay(pulse, 'is-on');
      clearTimeout(landing);
      landing = setTimeout(() => replay(laser, 'is-hit'), 300);
    };

    function send(cmd, fromPhone) {
      if (cmd === 'notes' || cmd === 'presenter') return toggleSheet('notes');
      if (cmd === 'goto') return toggleSheet('goto');
      nextBtn.classList.remove('is-hint');
      let arg;
      if (cmd.startsWith('goto:')) {
        arg = Number(cmd.slice(5));
        cmd = 'goto';
        toggleSheet('goto', false);
      }
      if (cmd === 'toggle') cmd = show.state.running ? 'end' : 'start';
      if (cmd === 'start') {
        runTimer(false);
        elapsed = 0;
        clock.textContent = mmss(0);
      }
      if (fromPhone) signal();
      const changed = show.command(cmd, arg);
      runTimer(show.state.running);
      if (changed) announce();
    }

    phone.addEventListener('click', (e) => {
      const cell = e.target.closest('[data-goto]');
      if (cell) return send(`goto:${cell.dataset.goto}`, true);
      const b = e.target.closest('[data-cmd]');
      if (b) send(b.dataset.cmd, true);
    });
    phone.addEventListener('keydown', (e) => {
      if (e.key !== 'Escape') return;
      if (!notesSheet.hidden) toggleSheet('notes', false);
      else if (!gotoSheet.hidden) toggleSheet('goto', false);
    });
    // A click on a running show moves to the next slide, as in PowerPoint.
    screen.addEventListener('click', () => { if (show.state.running) send('next'); });
    screen.addEventListener('keydown', (e) => {
      if (e.altKey || e.ctrlKey || e.metaKey) return;
      const cmd = {
        ArrowRight: 'next', ArrowDown: 'next', PageDown: 'next', ' ': 'next', Enter: 'next',
        ArrowLeft: 'prev', ArrowUp: 'prev', PageUp: 'prev',
        b: 'black', B: 'black', w: 'white', W: 'white', Escape: 'end', Home: 'start', F5: 'start',
      }[e.key];
      if (!cmd) return;
      e.preventDefault();
      send(cmd);
    });

    follower(showEl, laser);
  }

  // ── Watch: pages, bezel, held Next, held End ────────────────────────────

  /** The slide dots along the watch's upper edge (RemotePage's slideDots). */
  function drawDots(svg, current, total) {
    const FROM = 188, TO = 352, GAP = 22, R = 48;
    const span = TO - FROM - 2 * GAP;
    const ns = 'http://www.w3.org/2000/svg';
    svg.replaceChildren();
    for (let slide = 1; slide <= total; slide += 1) {
      const along = total === 1 ? 0 : (span * (slide - 1)) / (total - 1);
      const before = FROM + along < 270 - GAP;
      const deg = FROM + along + (before ? 0 : 2 * GAP);
      const a = (deg * Math.PI) / 180;
      const c = document.createElementNS(ns, 'circle');
      c.setAttribute('cx', (50 + R * Math.cos(a)).toFixed(2));
      c.setAttribute('cy', (50 + R * Math.sin(a)).toFixed(2));
      c.setAttribute('r', slide === current ? '2.5' : '1.7');
      c.setAttribute('fill', slide === current ? 'var(--wlaser)' : slide < current ? 'var(--wring)' : 'var(--wbd)');
      svg.appendChild(c);
    }
  }

  function initWatch() {
    const demo = $('[data-watch-demo]');
    if (!demo) return;
    const watch = $('[data-watch]', demo);
    const bezel = $('[data-bezel]', demo);
    const pages = Object.fromEntries($$('[data-page]', watch).map((p) => [p.dataset.page, p]));
    const blankPage = $('[data-wblank]', watch);
    const blankText = $('[data-blank-text]', blankPage);
    const pill = $('[data-wpill]', watch);
    const dots = $('[data-dots]', watch);
    const numEl = $('[data-wnum]', watch);
    const totEl = $('[data-wtot]', watch);
    const cntEl = $('[data-wcnt]', watch);
    const clockEl = $('[data-wclock]', watch);
    const timeEl = $('[data-wtime]', watch);
    const durBtn = $('[data-dur]', watch);
    const durText = $('[data-dur-text]', watch);
    const hint = $('[data-whint]', watch);
    const nextBtn = $('.w-next', watch);
    const remotePage = pages.remote;
    const finger = $('[data-wfinger]', watch);
    const finger2 = $('[data-wfinger2]', watch);
    const toolsPage = pages.tools;
    const endBtn = $('[data-wend]', watch);
    const endText = $('[data-wend-text]', watch);
    const live = $('[data-live]', watch);
    const pageBtns = $$('[data-goto-page]', demo);
    const hops = $$('[data-hop]', demo);
    const wires = $$('.wire', demo);

    // The watch keeps its own copy of the talk's state, as the phone reports it.
    const state = { index: 0, total: 5, running: true, blank: null, page: 'remote', duration: 20, elapsed: 0, warned: false };
    let held = false;      // Next held into the laser
    let heldOnce = false;  // the hint goes once it was done
    let suppressClick = false;
    let lastPage = 'remote';

    const say = () => {
      live.textContent = state.running ? fill(live.dataset.live, state.index + 1, state.total) : live.dataset.ended;
    };

    const timeLeft = () => state.duration * 60 - state.elapsed;
    function paintClock() {
      if (!state.duration) {
        timeEl.textContent = mmss(state.elapsed);
        clockEl.classList.remove('is-over');
        return;
      }
      const left = timeLeft();
      timeEl.textContent = left >= 0 ? mmss(left) : `+${Math.floor(-left / 60)}:${pad2(-left % 60)}`;
      clockEl.classList.toggle('is-over', left < 0);
    }

    function paint() {
      const { index, total, running, blank } = state;
      numEl.textContent = String(index + 1);
      totEl.textContent = `/${total}`;
      cntEl.textContent = `${index + 1}/${total}`;
      drawDots(dots, index + 1, total);
      pill.textContent = running ? pill.dataset.on : pill.dataset.off;
      durBtn.classList.toggle('is-none', !state.duration);
      const text = state.duration ? durBtn.dataset.min.replace('%n', state.duration) : durBtn.dataset.none;
      durText.textContent = text;
      paintClock();
      blankPage.hidden = !blank;
      blankPage.classList.toggle('is-black', blank === 'black');
      blankPage.classList.toggle('is-white', blank === 'white');
      if (blank) blankText.textContent = blankText.dataset[blank];
      hint.hidden = heldOnce;
      pageBtns.forEach((b) => {
        const p = b.dataset.gotoPage;
        b.hidden = p === 'start' ? running : !running;
        b.setAttribute('aria-current', String(p === state.page));
      });
      const shown = running ? (state.page === 'start' ? 'remote' : state.page) : 'start';
      state.page = shown;
      Object.entries(pages).forEach(([name, el]) => { el.hidden = name !== shown; });
      pageBtns.forEach((b) => b.setAttribute('aria-current', String(b.dataset.gotoPage === shown)));
      // The pages come and go with the show; the end ring starts over.
      toolsPage.classList.remove('is-ending');
      endText.textContent = endText.dataset.hold;
    }

    function go(page) {
      if (page === 'laser') lastPage = state.page === 'laser' ? lastPage : state.page;
      state.page = page;
      if (page !== 'laser') lastPage = page;
      paint();
    }

    function apply(cmd) {
      const before = `${state.index}${state.running}${state.blank}`;
      if (cmd === 'next' && state.running) {
        if (state.blank) state.blank = null;
        else state.index = Math.min(state.total - 1, state.index + 1);
      }
      if (cmd === 'prev' && state.running) {
        if (state.blank) state.blank = null;
        else state.index = Math.max(0, state.index - 1);
      }
      if (cmd === 'start') {
        state.running = true; state.index = 0; state.blank = null; state.page = 'remote';
        state.elapsed = 0; state.warned = false;
      }
      if (cmd === 'end') { state.running = false; state.blank = null; state.page = 'start'; }
      if ((cmd === 'black' || cmd === 'white') && state.running) state.blank = state.blank === cmd ? null : cmd;
      paint();
      return before !== `${state.index}${state.running}${state.blank}`;
    }

    // The command goes out whatever the slide does, by way of the phone, and
    // the wrist buzzes for it.
    function press(cmd, fromBezel) {
      if (apply(cmd)) say();
      hops.forEach((hop, i) => {
        clearTimeout(hop.downTimer);
        clearTimeout(hop.upTimer);
        hop.classList.remove('is-down');
        const gap = reduceMotion.matches ? 0 : 110;
        hop.downTimer = setTimeout(() => hop.classList.add('is-down'), i * gap);
        hop.upTimer = setTimeout(() => hop.classList.remove('is-down'), i * gap + 220);
      });
      if (!reduceMotion.matches) {
        wires.forEach((w, i) => setTimeout(() => replay(w, 'is-flow'), i * 110));
        replay(watch, fromBezel ? 'is-tick' : 'is-buzz');
      }
    }

    // One detent of the bezel is 15 degrees and one slide.
    let angle = 0;
    function turn(steps) {
      angle += steps * 15;
      bezel.style.setProperty('--bz', `${angle}deg`);
      if (state.page === 'remote' && !held) press(steps > 0 ? 'next' : 'prev', true);
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

    // Held on Next for 350 ms, the finger is the laser until it lifts.
    const place = (dot, e, host) => {
      const r = host.getBoundingClientRect();
      dot.style.translate = `${e.clientX - r.left}px ${e.clientY - r.top}px`;
    };
    let holdTimer = 0;
    nextBtn.addEventListener('pointerdown', (e) => {
      if (e.button) return;
      clearTimeout(holdTimer);
      holdTimer = setTimeout(() => {
        held = true;
        suppressClick = true;
        heldOnce = true;
        hint.hidden = true;
        remotePage.classList.add('is-laser');
        finger.classList.add('is-on');
        place(finger, e, remotePage);
        nextBtn.classList.add('is-held');
        nextBtn.setPointerCapture(e.pointerId);
        press('laser-on');
      }, 350);
    });
    nextBtn.addEventListener('pointermove', (e) => { if (held) place(finger, e, remotePage); });
    const release = () => {
      clearTimeout(holdTimer);
      if (!held) return;
      held = false;
      remotePage.classList.remove('is-laser');
      finger.classList.remove('is-on');
      nextBtn.classList.remove('is-held');
      // The click that follows the lift is not a Next.
      setTimeout(() => { suppressClick = false; }, 0);
    };
    nextBtn.addEventListener('pointerup', release);
    nextBtn.addEventListener('pointercancel', release);
    nextBtn.addEventListener('pointerleave', () => { if (!held) clearTimeout(holdTimer); });

    // The laser page is a touchpad.
    pages.laser.addEventListener('pointermove', (e) => place(finger2, e, pages.laser));
    pages.laser.addEventListener('pointerdown', (e) => place(finger2, e, pages.laser));

    // Ending takes a hold of one second.
    let endTimer = 0;
    const endStart = () => {
      if (endTimer) return;
      toolsPage.classList.add('is-ending');
      endText.textContent = endText.dataset.ending;
      endTimer = setTimeout(() => { endTimer = 0; press('end'); }, 1000);
    };
    const endCancel = () => {
      clearTimeout(endTimer);
      endTimer = 0;
      toolsPage.classList.remove('is-ending');
      endText.textContent = endText.dataset.hold;
    };
    endBtn.addEventListener('pointerdown', endStart);
    endBtn.addEventListener('pointerup', endCancel);
    endBtn.addEventListener('pointerleave', endCancel);
    endBtn.addEventListener('pointercancel', endCancel);
    endBtn.addEventListener('keydown', (e) => { if ((e.key === ' ' || e.key === 'Enter') && !e.repeat) { e.preventDefault(); endStart(); } });
    endBtn.addEventListener('keyup', (e) => { if (e.key === ' ' || e.key === 'Enter') endCancel(); });
    endBtn.addEventListener('blur', endCancel);

    watch.addEventListener('click', (e) => {
      if (suppressClick && e.target.closest('.w-next')) { suppressClick = false; return; }
      const laserBtn = e.target.closest('[data-wlaser]');
      if (laserBtn) { go('laser'); press('laser-on'); return; }
      if (e.target.closest('[data-wlaser-close]')) { go(state.running ? 'remote' : 'start'); return; }
      if (e.target.closest('[data-wblank]')) { press('next'); return; }
      const d = e.target.closest('[data-dur]');
      if (d) {
        const steps = [20, 30, 45, 10, 0];
        state.duration = steps[(steps.indexOf(state.duration) + 1) % steps.length];
        paint();
        return;
      }
      const b = e.target.closest('[data-cmd]');
      if (b) press(b.dataset.cmd, false);
    });
    watch.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && state.page === 'laser') { go('remote'); return; }
      if (e.target !== watch) return;
      const steps = { ArrowRight: 1, ArrowDown: 1, PageDown: 1, ArrowLeft: -1, ArrowUp: -1, PageUp: -1 }[e.key];
      if (!steps) return;
      e.preventDefault();
      turn(steps);
    });
    demo.addEventListener('click', (e) => {
      const b = e.target.closest('[data-goto-page]');
      if (b && !b.hidden) go(b.dataset.gotoPage);
    });

    // The talk's clock runs while the show does, and the watch buzzes when
    // five minutes are left, as the early warning does.
    let tick = 0;
    let visible = false;
    const syncTick = () => {
      const on = visible && state.running;
      if (on && !tick) {
        tick = setInterval(() => {
          state.elapsed += 1;
          paintClock();
          if (state.duration && timeLeft() === 300 && !state.warned) {
            state.warned = true;
            if (!reduceMotion.matches) replay(watch, 'is-buzz');
          }
        }, 1000);
      } else if (!on && tick) {
        clearInterval(tick);
        tick = 0;
      }
    };
    whileVisible(demo, (v) => { visible = v; syncTick(); });
    new MutationObserver(syncTick).observe(pill, { childList: true, characterData: true, subtree: true });

    // Once, when the watch first shows: the bezel clicks one detent and
    // back, so that it reads as something to turn.
    if (!reduceMotion.matches) {
      onceVisible(watch, () => {
        if (angle !== 0) return;
        bezel.style.setProperty('--bz', '15deg');
        setTimeout(() => { if (angle === 0) bezel.style.setProperty('--bz', '0deg'); }, 380);
      }, 0.6);
    }
    paint();
    say();

    // The small watch in the themes section shows the same dots.
    $$('[data-dots-static]').forEach((svg) => drawDots(svg, 3, 5));
  }

  // ── Connect: tabs ──────────────────────────────────────────────────────

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

  function initKeymap() {
    const map = $('[data-keymap]');
    if (!map) return;
    radioGroup($('[data-km-prog]', map), (r) => { map.dataset.prog = r.dataset.p; });
  }

  // ── The PC window: remove a phone, hide the code ───────────────────────

  function initPcWindow() {
    const win = $('[data-pc]');
    if (!win) return;
    const status = $('[data-pc-status]', win);
    const count = $('[data-pc-count]', win);
    const pair = $('[data-pc-pair]', win);
    const hide = $('[data-pc-hide]', win);
    const pin = $('[data-pc-pin]', win);
    const phone = $('[data-pc-phone]', win);
    const none = $('[data-pc-none]', win);
    const heads = $$('[data-pc-n]', win);
    let back = 0;

    const set = (n) => {
      phone.hidden = n === 0;
      none.hidden = n !== 0;
      status.classList.toggle('is-wait', n === 0);
      count.textContent = n === 0 ? count.dataset.none : `· ${count.dataset.one}`;
      heads.forEach((h) => { h.textContent = String(n); });
    };
    $('[data-pc-remove]', win).addEventListener('click', () => {
      // Removing a phone replaces the PIN.
      const n = String(Math.floor(100000 + Math.random() * 900000));
      pin.textContent = `${n.slice(0, 3)} ${n.slice(3)}`;
      set(0);
      clearTimeout(back);
      back = setTimeout(() => set(1), reduceMotion.matches ? 600 : 4500);
    });
    hide.addEventListener('click', () => {
      const hidden = !pair.hidden;
      pair.hidden = hidden;
      hide.setAttribute('aria-expanded', String(!hidden));
      hide.textContent = hidden ? hide.dataset.show : hide.dataset.hide;
    });
  }

  // ── Desktop: settings and the tray ────────────────────────────────────

  function initDesktop() {
    const root = $('[data-desktop]');
    if (!root) return;
    const look = $('[data-dk-look]', root);
    const pickLook = radioGroup(look, (r) => setSiteLook(r.dataset.look));
    siteLook.listeners.push((mode) => {
      const r = $(`[data-look="${mode}"]`, look);
      if (r && r.getAttribute('aria-checked') !== 'true') {
        $$('[role="radio"]', look).forEach((b) => {
          const on = b === r;
          b.setAttribute('aria-checked', String(on));
          b.tabIndex = on ? 0 : -1;
        });
      }
    });
    const sync = $(`[data-look="${siteLook.mode}"]`, look);
    if (sync) pickLook.call(null, sync, false);

    const note = $('[data-dk-laser-note]', root);
    const setNote = (r) => { note.textContent = note.dataset[r.dataset.laser]; };
    radioGroup($('[data-dk-laser]', root), setNote);
    setNote($('[data-laser="auto"]', root));

    const tray = $('[data-tray]', root);
    const tip = $('[data-tray-tip]', tray);
    const serverBtn = $('[data-tray-server]', tray);
    const phones = $('[data-tray-phones]', tray);
    const setState = (st) => {
      tray.dataset.state = st;
      tip.textContent = tip.dataset[st];
      serverBtn.textContent = st === 'off' || st === 'held' ? serverBtn.dataset.start : serverBtn.dataset.stop;
      phones.textContent = st === 'phone' ? phones.dataset.one : phones.dataset.none;
      $$('.tray-legend button', tray).forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.st === st)));
    };
    serverBtn.addEventListener('click', () => setState(tray.dataset.state === 'off' || tray.dataset.state === 'held' ? 'on' : 'off'));
    $('.tray-legend', tray).addEventListener('click', (e) => {
      const b = e.target.closest('[data-st]');
      if (b) setState(b.dataset.st);
    });
    setState('phone');
  }

  // ── Presenter view: drawing on the slide ──────────────────────────────

  function initDraw() {
    const draw = $('[data-draw]');
    const tools = $('[data-tools]');
    if (!draw || !tools) return;
    const swatches = $('[data-swatches]');
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
      swatches.setAttribute('aria-label', which === 'pen' ? swatches.dataset.labelPen : swatches.dataset.labelHighlighter);
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
        draw.classList.remove('has-pen', 'has-hl', 'is-drawing', 'is-erasing', 'is-sweeping');
        return;
      }
      tool = name;
      syncButtons();
      if (name === 'pen') penStroke();
      else if (name === 'highlighter') highlight();
      else if (name === 'laser') draw.classList.add('is-laser');
      else if (name === 'eraser' && draw.classList.contains('has-pen')) {
        replay(draw, 'is-erasing');
        later(() => draw.classList.remove('has-pen', 'is-drawing', 'is-erasing'), reduceMotion.matches ? 0 : 620);
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

    follower(draw, $('.pv-laser', draw), () => tool === 'laser');

    // The ink is drawn when the slide first comes into view: a circle with
    // the pen, then a highlighter stroke, as from the phone.
    if (reduceMotion.matches) return;
    draw.classList.remove('has-pen', 'has-hl');
    onceVisible(draw, () => {
      if (draw.classList.contains('has-pen') || draw.classList.contains('has-hl')) return;
      penStroke();
      later(highlight, 1000);
    }, 0.5);
  }

  // ── The overlay: laser, spotlight, magnifier and pen above a program ───

  function initOverlay() {
    const demo = $('[data-overlay]');
    if (!demo) return;
    const screen = $('[data-ov-screen]', demo);
    const content = $('[data-ov-content]', demo);
    const lens = $('.ov-lens', screen);
    const lensIn = $('[data-lens-in]', screen);
    const dot = $('.ov-dot', screen);
    const canvas = $('.ov-ink', screen);
    const ctx2d = canvas.getContext('2d');
    const tools = $('[data-ov-tools]', demo);
    const note = $('[data-ov-note]', demo);
    const hintEl = $('[data-ov-hint]', demo);
    const ctxGroup = $('[data-ov-ctx]', demo);
    const title = $('[data-ov-title]', demo);
    const titles = { pdf: title.textContent, web: 'kahve.example', video: 'Impress' };
    let tool = 'laser';
    let strokes = [];
    let current = null;
    let px = 0, py = 0, frame = 0;
    let w = 1, h = 1;
    let intro = 0;

    const buildLens = () => {
      lensIn.replaceChildren(content.cloneNode(true));
      lensIn.style.width = `${w}px`;
      lensIn.style.height = `${h}px`;
    };

    function redraw() {
      const dpr = window.devicePixelRatio || 1;
      ctx2d.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx2d.clearRect(0, 0, w, h);
      ctx2d.lineCap = 'round';
      ctx2d.lineJoin = 'round';
      ctx2d.strokeStyle = '#FF1744';
      ctx2d.lineWidth = Math.max(3, w * 0.006);
      strokes.forEach((s) => {
        ctx2d.beginPath();
        s.forEach(([x, y], i) => (i ? ctx2d.lineTo(x, y) : ctx2d.moveTo(x, y)));
        if (s.length === 1) ctx2d.lineTo(s[0][0] + 0.1, s[0][1]);
        ctx2d.stroke();
      });
    }

    const measure = () => {
      const r = screen.getBoundingClientRect();
      w = r.width || 1;
      h = r.height || 1;
      const dpr = window.devicePixelRatio || 1;
      canvas.width = Math.round(w * dpr);
      canvas.height = Math.round(h * dpr);
      lensIn.style.width = `${w}px`;
      lensIn.style.height = `${h}px`;
      screen.style.setProperty('--sr', `${Math.round(w * 0.12)}px`);
      redraw();
    };

    function paintPointer() {
      frame = 0;
      dot.style.translate = `${px}px ${py}px`;
      screen.style.setProperty('--sx', `${px}px`);
      screen.style.setProperty('--sy', `${py}px`);
      if (tool === 'zoom') {
        const r = lens.offsetWidth / 2;
        lens.style.translate = `${px}px ${py}px`;
        lensIn.style.transform = `translate(${r - 2 * px}px, ${r - 2 * py}px) scale(2)`;
      }
    }
    const move = (x, y) => {
      px = Math.max(0, Math.min(w, x));
      py = Math.max(0, Math.min(h, y));
      screen.classList.add('is-over');
      if (!frame) frame = requestAnimationFrame(paintPointer);
    };
    const at = (e) => {
      const r = screen.getBoundingClientRect();
      return [e.clientX - r.left, e.clientY - r.top];
    };
    const used = () => { clearTimeout(intro); intro = 0; screen.classList.add('is-used'); };

    screen.addEventListener('pointermove', (e) => {
      if (e.pointerType === 'touch' && tool !== 'pen') return;
      used();
      const [x, y] = at(e);
      move(x, y);
      if (current) { current.push([x, y]); redraw(); }
    });
    screen.addEventListener('pointerdown', (e) => {
      used();
      const [x, y] = at(e);
      move(x, y);
      if (tool === 'pen') {
        current = [[x, y]];
        strokes.push(current);
        screen.setPointerCapture(e.pointerId);
        redraw();
      }
    });
    const lift = () => { current = null; };
    screen.addEventListener('pointerup', lift);
    screen.addEventListener('pointercancel', lift);
    screen.addEventListener('pointerleave', () => {
      if (current) return;
      screen.classList.remove('is-over');
    });
    // From the keyboard: arrows move the pointer, Enter lays pen down or lifts it.
    screen.addEventListener('keydown', (e) => {
      const d = { ArrowRight: [20, 0], ArrowLeft: [-20, 0], ArrowDown: [0, 20], ArrowUp: [0, -20] }[e.key];
      if (d) {
        e.preventDefault();
        used();
        if (!screen.classList.contains('is-over')) { px = w / 2; py = h / 2; }
        move(px + d[0], py + d[1]);
        if (current) { current.push([px + d[0], py + d[1]]); redraw(); }
      } else if (e.key === 'Enter' && tool === 'pen') {
        e.preventDefault();
        if (current) current = null;
        else { current = [[px, py]]; strokes.push(current); }
      }
    });
    screen.addEventListener('focus', () => { if (!screen.classList.contains('is-over')) { used(); move(w / 2, h / 2); } });

    function setTool(name) {
      if (name === 'undo') { strokes.pop(); redraw(); return; }
      if (name === 'black') {
        const on = !screen.classList.contains('is-black');
        screen.classList.toggle('is-black', on);
        $('[data-ov="black"]', tools).setAttribute('aria-pressed', String(on));
        return;
      }
      tool = name;
      screen.dataset.tool = name;
      $$('[data-ov]', tools).forEach((b) => {
        if (!['undo', 'black'].includes(b.dataset.ov)) b.setAttribute('aria-pressed', String(b.dataset.ov === name));
      });
      note.textContent = note.dataset[name] || '';
      if (frame === 0) paintPointer();
    }
    tools.addEventListener('click', (e) => {
      const b = e.target.closest('[data-ov]');
      if (b) setTool(b.dataset.ov);
    });

    radioGroup(ctxGroup, (r) => {
      screen.classList.remove('ctx-pdf', 'ctx-web', 'ctx-video');
      screen.classList.add(`ctx-${r.dataset.ctx}`);
      title.textContent = titles[r.dataset.ctx];
      buildLens();
    });

    if ('ResizeObserver' in window) new ResizeObserver(measure).observe(screen);
    measure();
    buildLens();
    setTool('laser');

    // Until the visitor's own pointer arrives, the laser takes a lap by itself.
    if (!reduceMotion.matches) {
      onceVisible(screen, () => {
        if (screen.classList.contains('is-used')) return;
        const t0 = performance.now();
        const lap = (t) => {
          if (screen.classList.contains('is-used')) return;
          const k = Math.min(1, (t - t0) / 2200);
          move(w * (0.18 + 0.64 * k), h * (0.42 + 0.14 * Math.sin(k * Math.PI * 3)));
          if (k < 1) requestAnimationFrame(lap);
          else intro = setTimeout(() => screen.classList.remove('is-over'), 600);
        };
        requestAnimationFrame(lap);
      }, 0.6);
    }
    hintEl.hidden = false;
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
    // On its own the demo runs only through the warning, then waits; a tap
    // starts and pauses it, as on the phone.
    const autoStop = 292;
    let left = from;
    let running = false;
    let visible = false;
    let ticker = 0;
    let hideSnack = 0;
    let auto = false;

    const warn = () => {
      snack.classList.add('is-on');
      if (!reduceMotion.matches) replay(demo, 'is-buzz');
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

  // ── Touchpad glow, go to slide, report bars, media ─────────────────────

  function initPad() {
    const pad = $('[data-pad]');
    if (!pad) return;
    const glow = $('.pad-glow', pad);
    const place = (x, y) => { glow.style.transform = `translate(${x}px, ${y}px)`; };
    const move = (e) => {
      const r = pad.getBoundingClientRect();
      place(e.clientX - r.left, e.clientY - r.top);
    };
    // Until the visitor's own finger arrives, the drawn trail ends in the
    // glow, where the last touch was.
    const rest = () => place(pad.clientWidth * 0.88, pad.clientHeight * 0.37);
    const touch = (e) => {
      move(e);
      pad.classList.remove('is-idle');
      pad.classList.add('is-touching');
    };
    rest();
    window.addEventListener('resize', () => { if (!pad.classList.contains('is-touching')) rest(); });
    onceVisible(pad, () => {
      pad.classList.add('is-shown');
      setTimeout(() => { if (!pad.classList.contains('is-touching')) pad.classList.add('is-idle'); }, reduceMotion.matches ? 0 : 1100);
    }, 0.5);
    pad.addEventListener('pointerenter', touch);
    pad.addEventListener('pointerdown', touch);
    pad.addEventListener('pointermove', move);
    const off = () => {
      pad.classList.remove('is-touching');
      pad.classList.add('is-idle');
    };
    pad.addEventListener('pointerleave', off);
    pad.addEventListener('pointercancel', off);
  }

  function initGoto() {
    const demo = $('[data-gotodemo]');
    if (!demo) return;
    const grid = $('[data-gd-grid]', demo);
    const foot = $('[data-gd-foot]', demo);
    const slides = $$('[data-show] .slide');
    slides.forEach((s, i) => {
      const cell = document.createElement('button');
      cell.type = 'button';
      cell.className = 'gd-cell';
      cell.setAttribute('aria-pressed', String(i === 1));
      const frame = document.createElement('div');
      frame.className = 'show';
      frame.setAttribute('aria-hidden', 'true');
      frame.appendChild(slideCopy(s));
      const num = document.createElement('b');
      num.textContent = String(i + 1);
      cell.setAttribute('aria-label', fill(foot.dataset.text, i + 1, slides.length));
      cell.append(frame, num);
      grid.appendChild(cell);
    });
    const cells = $$('.gd-cell', grid);
    grid.addEventListener('click', (e) => {
      const c = e.target.closest('.gd-cell');
      if (!c) return;
      cells.forEach((x) => x.setAttribute('aria-pressed', String(x === c)));
      foot.textContent = fill(foot.dataset.text, cells.indexOf(c) + 1, cells.length);
    });
  }

  function initReport() {
    const report = $('[data-report]');
    if (report) onceVisible(report, () => report.classList.add('is-in'), 0.4);
  }

  function initMedia() {
    const media = $('[data-media]');
    if (!media) return;
    const play = $('[data-media-cmd="play"]', media);
    const label = $('[data-play-label]', media);
    const bar = $('[data-bar]', media);
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
    paint();
  }

  // ── Install: the card for the visitor's system, copyable commands ─────

  function initInstall() {
    const list = $('[data-install]');
    if (!list) return;
    const ua = `${navigator.userAgent} ${(navigator.userAgentData && navigator.userAgentData.platform) || navigator.platform || ''}`;
    const os = /android/i.test(ua) ? 'android' : /windows/i.test(ua) ? 'windows' : /linux|x11|cros/i.test(ua) ? 'linux' : '';
    const mine = os && $(`[data-os="${os}"]`, list);
    if (mine) {
      mine.classList.add('is-yours');
      mine.dataset.yours = list.dataset.yours;
    }
    const status = document.createElement('p');
    status.className = 'sr';
    status.setAttribute('aria-live', 'polite');
    list.after(status);
    list.addEventListener('click', async (e) => {
      const b = e.target.closest('[data-copy]');
      if (!b) return;
      const text = $('code', b.parentElement).textContent;
      try {
        await navigator.clipboard.writeText(text);
      } catch (err) {
        const area = document.createElement('textarea');
        area.value = text;
        area.style.cssText = 'position:fixed;opacity:0';
        document.body.appendChild(area);
        area.select();
        try { document.execCommand('copy'); } catch (e2) { /* nothing to do */ }
        area.remove();
      }
      b.classList.add('is-done');
      status.textContent = b.dataset.done;
      setTimeout(() => { b.classList.remove('is-done'); status.textContent = ''; }, 1600);
    });
  }

  // ── Entrances: pieces rise as they come into view ─────────────────────

  function initReveal() {
    if (reduceMotion.matches || !('IntersectionObserver' in window)) return;
    const items = $$('.sec-head, .pv-caps li, .prog, .st-col, .get-card, .plain li, .ov-list li, .spec > div, .facts > div, .tp-card, .row-text');
    const io = new IntersectionObserver((entries) => {
      entries.forEach((e) => {
        if (!e.isIntersecting) return;
        e.target.classList.add('is-in');
        io.unobserve(e.target);
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
    items.forEach((el) => {
      const sibs = Array.from(el.parentElement.children).filter((c) => c.tagName === el.tagName);
      el.style.setProperty('--rv', Math.min(5, sibs.indexOf(el)));
      el.dataset.reveal = '';
      io.observe(el);
    });
  }

  initThemeButton();
  initHeader();
  initHero();
  initWatch();
  initThemes();
  initTabs();
  initKeymap();
  initPcWindow();
  initDesktop();
  initDraw();
  initOverlay();
  initTimerDemo();
  initPad();
  initGoto();
  initReport();
  initMedia();
  initInstall();
  initReveal();
  applyColorTheme();
})();
