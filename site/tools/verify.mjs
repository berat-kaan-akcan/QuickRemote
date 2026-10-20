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
