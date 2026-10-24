// Opens the site in headless Chromium and checks it: console errors, broken
// references, sideways scrolling, the same ids in both languages. Writes
// screenshots of every section when --shots=DIR is given.
//
//   node site/tools/verify.mjs [--shots=docs/raporlar/site-ekranlar] [--quick]
//
// Needs the playwright package (npx playwright install chromium).
import { createRequire } from 'node:module';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');
const site = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = Object.fromEntries(process.argv.slice(2).map((a) => a.replace(/^--/, '').split('=')).map(([k, v]) => [k, v ?? true]));
const shotsDir = args.shots ? path.resolve(args.shots) : null;
const types = { '.html': 'text/html; charset=utf-8', '.css': 'text/css', '.js': 'text/javascript', '.png': 'image/png', '.svg': 'image/svg+xml', '.woff2': 'font/woff2', '.mp4': 'video/mp4', '.webm': 'video/webm' };

const server = http.createServer((req, res) => {
  let p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  if (p.endsWith('/')) p += 'index.html';
  const file = path.join(site, p);
  if (!file.startsWith(site) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'content-type': types[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});
await new Promise((r) => server.listen(0, r));
const base = `http://127.0.0.1:${server.address().port}`;

const browser = await chromium.launch();
const problems = [];
const note = (m) => { problems.push(m); console.log('PROBLEM', m); };
const idsByLang = {};

const combos = [];
for (const lang of ['tr', 'en']) {
  for (const [w, h] of [[1440, 900], [390, 844]]) {
    for (const scheme of ['light', 'dark']) {
      for (const reduced of [false, true]) {
        if (args.quick && (reduced || scheme === 'dark')) continue;
        combos.push({ lang, w, h, scheme, reduced });
      }
    }
  }
}

for (const c of combos) {
  const tag = `${c.lang}-${c.w}-${c.scheme}${c.reduced ? '-reduced' : ''}`;
  const ctx = await browser.newContext({ viewport: { width: c.w, height: c.h }, colorScheme: c.scheme, reducedMotion: c.reduced ? 'reduce' : 'no-preference', deviceScaleFactor: 1, hasTouch: c.w < 600 });
  const page = await ctx.newPage();
  const errors = [];
  page.on('console', (m) => { if (['error', 'warning'].includes(m.type())) errors.push(`${m.type()}: ${m.text()}`); });
  page.on('pageerror', (e) => errors.push(`pageerror: ${e.message}`));
  page.on('requestfailed', (r) => errors.push(`requestfailed: ${r.url()}`));
  page.on('response', (r) => { if (r.status() >= 400) errors.push(`http ${r.status()}: ${r.url()}`); });
  await page.goto(`${base}/${c.lang === 'en' ? 'en/' : ''}`, { waitUntil: 'networkidle' });
  // Scroll through once so the entrances have run.
  const height = await page.evaluate(() => document.documentElement.scrollHeight);
  for (let y = 0; y < height; y += c.h * 0.6) { await page.evaluate((v) => window.scrollTo({ top: v, behavior: 'instant' }), y); await page.waitForTimeout(90); }
  await page.evaluate(() => window.scrollTo({ top: 0, behavior: 'instant' }));
  await page.waitForTimeout(300);

  const info = await page.evaluate(() => {
    const out = { overflow: document.documentElement.scrollWidth - window.innerWidth, wide: [] };
    document.querySelectorAll('body *').forEach((el) => {
      const r = el.getBoundingClientRect();
      if (r.width && r.right > window.innerWidth + 1 && getComputedStyle(el).position !== 'fixed' && !el.closest('.sprite, [hidden], .watch-menu')) {
        const clip = el.closest('[style*="overflow"], .ov-screen, .show, .pv-slide, .ph, .watch-screen');
        if (!clip && out.wide.length < 6) out.wide.push(`${el.tagName.toLowerCase()}.${String(el.className).slice(0, 40)}`);
      }
    });
    const uses = [...document.querySelectorAll('use')].map((u) => u.getAttribute('href')).filter((h) => h && h.startsWith('#'));
    out.badUse = [...new Set(uses.filter((h) => !document.querySelector(h)))];
    out.badAnchors = [...new Set([...document.querySelectorAll('a[href^="#"]')].map((a) => a.getAttribute('href')).filter((h) => h.length > 1 && !document.querySelector(h)))];
    out.ids = [...document.querySelectorAll('[id]')].map((e) => e.id).sort();
    out.sections = [...document.querySelectorAll('main > section')].map((s) => s.id || s.className);
    out.counts = { details: document.querySelectorAll('details').length, li: document.querySelectorAll('li').length, buttons: document.querySelectorAll('button').length, svgUse: document.querySelectorAll('use').length };
    out.lang = document.documentElement.lang;
    return out;
  });
  if (info.overflow > 0) note(`${tag}: page scrolls sideways by ${info.overflow}px (${info.wide.join(', ')})`);
  if (info.badUse.length) note(`${tag}: missing symbols ${info.badUse}`);
  if (info.badAnchors.length) note(`${tag}: broken anchors ${info.badAnchors}`);
  errors.forEach((e) => note(`${tag}: ${e}`));
  if (!c.reduced && c.scheme === 'light' && c.w === 1440) idsByLang[c.lang] = info;

  if (shotsDir) {
    fs.mkdirSync(shotsDir, { recursive: true });
    const secs = await page.$$('main > section');
    let i = 0;
    for (const s of secs) {
      const id = (await s.getAttribute('id')) || `s${i}`;
      if (args.only && !String(args.only).split(',').includes(id)) { i += 1; continue; }
      await s.scrollIntoViewIfNeeded();
      await page.waitForTimeout(250);
      await s.screenshot({ path: path.join(shotsDir, `${tag}-${String(i).padStart(2, '0')}-${id}.png`) });
      i += 1;
    }
  }
  await ctx.close();
}


// The live demos: press things and see that the page answers.
async function interact(lang) {
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, colorScheme: 'light' });
  await ctx.grantPermissions(['clipboard-read', 'clipboard-write']);
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  await page.goto(`${base}/${lang === 'en' ? 'en/' : ''}`, { waitUntil: 'networkidle' });
  const t = (name, ok) => { if (!ok) note(`${lang}: demo failed: ${name}`); };
  const text = (sel) => page.$eval(sel, (e) => e.textContent.trim());
  // hero
  await page.click('.ph-next'); await page.click('.ph-next');
  t('hero next', (await text('[data-cur]')) === '3');
  await page.click('.ph-goto'); await page.click('.ph-cell[data-goto="4"]');
  t('hero go to slide', (await text('[data-cur]')) === '5');
  await page.click('[data-cmd="toggle"]');
  t('hero end', await page.$eval('.ph', (e) => e.classList.contains('is-ended')));
  await page.click('[data-cmd="toggle"]');
  t('hero start', (await text('[data-cur]')) === '1');
  await page.click('.ph-notes'); t('hero notes', await page.$eval('#ph-sheet', (e) => !e.hidden));
  await page.keyboard.press('Escape');
  // watch
  const w = '[data-watch]';
  await page.click('.w-next'); t('watch next', (await text('[data-wnum]')) === '2');
  await page.click('[data-goto-page="tools"]'); t('watch tools page', await page.$eval('.wp-tools', (e) => !e.hidden));
  await page.click('.wq-black', { position: { x: 25, y: 130 } }); t('watch black', await page.$eval('[data-wblank]', (e) => !e.hidden));
  await page.click('[data-wblank]');
  const box = await (await page.$('[data-wend]')).boundingBox();
  await page.mouse.move(box.x + box.width / 2, box.y + box.height * 0.8); await page.mouse.down(); await page.waitForTimeout(1250); await page.mouse.up();
  t('watch end by hold', await page.$eval('.wp-start', (e) => !e.hidden));
  await page.click('[data-dur]'); await page.click('.w-start');
  t('watch start', await page.$eval('.wp-remote', (e) => !e.hidden));
  const nb = await (await page.$('.w-next')).boundingBox();
  await page.mouse.move(nb.x + nb.width / 2, nb.y + nb.height / 2); await page.mouse.down(); await page.waitForTimeout(500);
  t('watch held laser', await page.$eval('.wp-remote', (e) => e.classList.contains('is-laser')));
  await page.mouse.up();
  // themes
  await page.click('.tp-card[data-theme="mint"]');
  t('theme mint', await page.$eval('.phone', (e) => e.dataset.theme === 'mint') && await page.$eval('[data-watch]', (e) => e.dataset.theme === 'mint'));
  await page.click('.tp-card[data-theme="sunset"]');
  t('theme sunset on watch is cobalt', await page.$eval('[data-watch]', (e) => e.dataset.theme === 'cobalt'));
  await page.click('.tp-card[data-theme="cobalt"]');
  // overlay
  await page.click('[data-ov="zoom"]'); await page.waitForTimeout(700);
  const sc = await (await page.$('[data-ov-screen]')).boundingBox();
  await page.mouse.move(sc.x + 200, sc.y + 150); await page.waitForTimeout(100);
  t('overlay lens', await page.$eval('[data-ov-screen]', (e) => e.classList.contains('is-over')) && (await page.$eval('[data-lens-in]', (e) => e.children.length)) === 1);
  await page.click('[data-ov="pen"]');
  await page.mouse.move(sc.x + 100, sc.y + 100); await page.mouse.down(); await page.mouse.move(sc.x + 300, sc.y + 200, { steps: 6 }); await page.mouse.up();
  const ink = await page.$eval('.ov-ink', (c) => { const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data; for (let i = 3; i < d.length; i += 4) if (d[i]) return true; return false; });
  t('overlay pen draws', ink);
  await page.click('[data-ov="undo"]');
  t('overlay undo', !(await page.$eval('.ov-ink', (c) => { const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data; for (let i = 3; i < d.length; i += 4) if (d[i]) return true; return false; })));
  await page.click('[data-ctx="video"]'); t('overlay context', await page.$eval('[data-ov-screen]', (e) => e.classList.contains('ctx-video')));
  // goto, media, connect, desktop, install
  await page.click('.gd-cell:nth-child(4)'); t('goto demo', (await text('[data-gd-foot]')).includes('4'));
  await page.click('[data-media-cmd="play"]'); t('media play', await page.$eval('[data-media]', (e) => e.classList.contains('is-playing')));
  await page.click('#tab-bt'); await page.click('[data-p="wps"]'); t('keymap wps', await page.$eval('[data-keymap]', (e) => e.dataset.prog === 'wps'));
  await page.click('#tab-wifi'); await page.click('[data-pc-remove]'); t('pc remove phone', await page.$eval('[data-pc-none]', (e) => !e.hidden));
  await page.click('[data-pc-hide]'); t('pc hide code', await page.$eval('[data-pc-pair]', (e) => e.hidden));
  await page.click('[data-tray-server]'); t('tray off', await page.$eval('[data-tray]', (e) => e.dataset.state === 'off'));
  await page.click('[data-look="dark"]'); t('site dark', await page.$eval('html', (e) => e.dataset.theme === 'dark'));
  await page.click('[data-theme-btn]'); t('header button cycles', await page.$eval('html', (e) => e.dataset.theme === undefined));
  await page.click('[data-copy]'); t('copy command', await page.$eval('[data-copy]', (e) => e.classList.contains('is-done')));
  if (errors.length) note(`${lang}: demo errors ${errors}`);
  await ctx.close();
}
for (const lang of ['tr', 'en']) await interact(lang);

const tr = idsByLang.tr, en = idsByLang.en;
if (tr && en) {
  if (JSON.stringify(tr.ids) !== JSON.stringify(en.ids)) note('ids differ between tr and en');
  if (JSON.stringify(tr.sections) !== JSON.stringify(en.sections)) note('sections differ between tr and en');
  if (JSON.stringify(tr.counts) !== JSON.stringify(en.counts)) note(`element counts differ: ${JSON.stringify(tr.counts)} vs ${JSON.stringify(en.counts)}`);
}
await browser.close();
server.close();
console.log(problems.length ? `${problems.length} problem(s)` : 'ok');
process.exit(problems.length ? 1 : 0);
