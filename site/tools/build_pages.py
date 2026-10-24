#!/usr/bin/env python3
"""Writes the site's pages: index.html (Turkish), en/index.html (English), the
privacy policy in both languages (gizlilik/, en/privacy/), 404.html, robots.txt
and, once the address is known, sitemap.xml.

Every page comes from the files in parts/, so the two languages cannot drift
apart: every visible sentence is a pair

    {{Türkçe metin||English text}}

and the icons are the Material Symbols Rounded paths in icons/, collected
into one inline sprite for the icons a page actually uses. Tokens:

    @ROOT@     path back to the site's root ('' or '../' ...)
    @HOME@     path to this language's home page
    @PRIVACY@  path to this language's privacy page
    @SEO@      canonical, hreflang, og:url and og:image (see site.url)

Run it after editing a part:

    python3 site/tools/build_pages.py

The site itself stays plain HTML, CSS and JS; this only writes the pages.

site.url holds the public address (e.g. https://quickremote.example), no trailing
slash. While it is empty, the pages carry no canonical/hreflang/sitemap (those
need absolute URLs) and nothing is invented.
"""
import re
import sys
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
SITE = TOOLS.parent
PAIR = re.compile(r'\{\{(.*?)\|\|(.*?)\}\}', re.S)
ICON = re.compile(r'#i-([a-z0-9-]+)')

url_file = TOOLS / 'site.url'
SITE_URL = url_file.read_text().strip().rstrip('/') if url_file.exists() else ''

MAIN = [p.strip() for p in (TOOLS / 'parts' / 'order.txt').read_text().splitlines() if p.strip() and not p.startswith('#')]
PRIVACY = ['privacy-head', 'sprite', 'privacy-top', 'privacy', 'foot']

# kind groups the language versions of one page (for hreflang).
PAGES = [
    dict(kind='main', lang='tr', path='', root='', home='', privacy='gizlilik/', other_href='en/', parts=MAIN),
    dict(kind='main', lang='en', path='en/', root='../', home='', privacy='privacy/', other_href='../', parts=MAIN),
    dict(kind='privacy', lang='tr', path='gizlilik/', root='../', home='../', privacy='./', other_href='../en/privacy/', parts=PRIVACY),
    dict(kind='privacy', lang='en', path='en/privacy/', root='../../', home='../', privacy='./', other_href='../../gizlilik/', parts=PRIVACY),
]
OTHER = {'tr': 'en', 'en': 'tr'}


def sprite(used):
    symbols = []
    for name in sorted(used):
        path = TOOLS / 'icons' / f'{name}.path'
        if not path.exists():
            sys.exit(f'missing icon: {name}')
        symbols.append(f'<symbol id="i-{name}" viewBox="0 -960 960 960"><path d="{path.read_text().strip()}"/></symbol>')
    return '\n'.join(symbols)


def seo(page):
    og = f'assets/og/og-{page["lang"]}.png'
    if not SITE_URL:
        return f'<meta property="og:image" content="{page["root"]}{og}">'
    lines = [f'<link rel="canonical" href="{SITE_URL}/{page["path"]}">']
    group = {p['lang']: p for p in PAGES if p['kind'] == page['kind']}
    for code in ('tr', 'en'):
        lines.append(f'<link rel="alternate" hreflang="{code}" href="{SITE_URL}/{group[code]["path"]}">')
    lines.append(f'<link rel="alternate" hreflang="x-default" href="{SITE_URL}/{group["tr"]["path"]}">')
    lines.append(f'<meta property="og:url" content="{SITE_URL}/{page["path"]}">')
    lines.append(f'<meta property="og:image" content="{SITE_URL}/{og}">')
    return '\n  '.join(lines)


def render(text, idx):
    return PAIR.sub(lambda m: m.group(1 + idx), text)


def build(page):
    lang = page['lang']
    text = '\n'.join((TOOLS / 'parts' / f'{name}.html').read_text().rstrip('\n') for name in page['parts']) + '\n'
    text = render(text, 0 if lang == 'tr' else 1)
    text = (text.replace('@ROOT@', page['root']).replace('@HOME@', page['home']).replace('@PRIVACY@', page['privacy'])
            .replace('@LANG@', lang).replace('@OTHER@', OTHER[lang]).replace('@OTHER_HREF@', page['other_href'])
            .replace('@SEO@', seo(page)))
    text = text.replace('@SPRITE@', sprite(set(ICON.findall(text))))
    if '{{' in text or '||' in text or re.search(r'@[A-Z]{3,}@', text):
        sys.exit(f'{page["path"] or "/"}: an unpaired marker or token is left in the page')
    out = SITE / page['path'] / 'index.html'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text)
    print(f'{out.relative_to(SITE)}: {len(text) // 1024} KB')


def build_404():
    """One page in both languages, with everything inline: it is served at any depth."""
    body = (TOOLS / 'parts' / '404.html').read_text()
    shell = (TOOLS / 'parts' / '404-shell.html').read_text()
    mark = (TOOLS / 'parts' / 'sprite.html').read_text()
    m = re.search(r'<symbol id="mark".*?</symbol>', mark, re.S)
    defs = re.search(r'<defs><radialGradient id="laser-glow">.*?</defs>', mark, re.S)
    sections = ''.join(f'<section lang="{c}">{render(body, i).strip()}</section>\n' for i, c in enumerate(('tr', 'en')))
    text = shell.replace('@MARK@', (defs.group(0) if defs else '') + m.group(0)).replace('@BODY@', sections)
    (SITE / '404.html').write_text(text)
    print(f'404.html: {len(text) // 1024} KB')


def build_seo_files():
    robots = ['User-agent: *', 'Allow: /']
    sitemap = SITE / 'sitemap.xml'
    if SITE_URL:
        robots.append(f'Sitemap: {SITE_URL}/sitemap.xml')
        group = {}
        for p in PAGES:
            group.setdefault(p['kind'], {})[p['lang']] = p
        rows = []
        for kind, langs in group.items():
            for p in langs.values():
                links = ''.join(f'<xhtml:link rel="alternate" hreflang="{c}" href="{SITE_URL}/{langs[c]["path"]}"/>' for c in ('tr', 'en'))
                links += f'<xhtml:link rel="alternate" hreflang="x-default" href="{SITE_URL}/{langs["tr"]["path"]}"/>'
                rows.append(f'  <url><loc>{SITE_URL}/{p["path"]}</loc>{links}</url>')
        sitemap.write_text('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n' + '\n'.join(rows) + '\n</urlset>\n')
        print('sitemap.xml written')
    elif sitemap.exists():
        sitemap.unlink()
    (SITE / 'robots.txt').write_text('\n'.join(robots) + '\n')
    print('robots.txt written')


if __name__ == '__main__':
    for p in PAGES:
        build(p)
    build_404()
    build_seo_files()
