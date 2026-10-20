// Writes site/assets/og/: og, square and loop-poster PNGs and the 6 s hero
// loop (mp4 + webm) in both languages from social.html. Needs playwright
// and ffmpeg.   node site/tools/social.mjs [--noloop]
import { createRequire } from 'node:module';
import http from 'node:http';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const { chromium } = createRequire(import.meta.url)('playwright');
const site = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(site, 'assets', 'og');
const noLoop = process.argv.includes('--noloop');
const types = { '.html': 'text/html; charset=utf-8', '.css': 'text/css', '.js': 'text/javascript', '.woff2': 'font/woff2', '.svg': 'image/svg+xml' };
const server = http.createServer((req, res) => {
  const p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  const file = path.join(site, p);
  if (!file.startsWith(site) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'content-type': types[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});
await new Promise((r) => server.listen(0, r));
const base = `http://127.0.0.1:${server.address().port}/tools/social.html`;
const sizes = { og: [1200, 630], square: [1080, 1080], loop: [1280, 720] };
const names = { og: 'og', square: 'social', loop: 'loop-poster' };
const browser = await chromium.launch();

async function open(lang, format) {
  const [w, h] = sizes[format];
  const page = await browser.newPage({ viewport: { width: w, height: h } });
  await page.goto(`${base}?lang=${lang}&format=${format}`);
  await page.waitForSelector('body[data-ready="1"]');
  return page;
}

for (const lang of ['tr', 'en']) {
  for (const format of Object.keys(sizes)) {
    const page = await open(lang, format);
    await page.screenshot({ path: path.join(out, `${names[format]}-${lang}.png`) });
    if (format === 'loop' && !noLoop) {
      const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'qr-loop-'));
      for (let i = 0; i < 180; i += 1) {
        await page.evaluate((t) => window.renderAt(t), i / 30);
        await page.screenshot({ path: path.join(dir, `f${String(i).padStart(3, '0')}.png`) });
      }
      const input = ['-y', '-framerate', '30', '-i', path.join(dir, 'f%03d.png')];
      execFileSync('ffmpeg', [...input, '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '26', '-movflags', '+faststart', '-an', path.join(out, `loop-${lang}.mp4`)], { stdio: 'ignore' });
      execFileSync('ffmpeg', [...input, '-c:v', 'libvpx-vp9', '-b:v', '0', '-crf', '40', '-pix_fmt', 'yuv420p', '-an', path.join(out, `loop-${lang}.webm`)], { stdio: 'ignore' });
      fs.rmSync(dir, { recursive: true });
    }
    await page.close();
  }
}
await browser.close();
server.close();
console.log('done');
