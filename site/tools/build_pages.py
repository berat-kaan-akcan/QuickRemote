#!/usr/bin/env python3
"""Writes site/index.html (Turkish) and site/en/index.html (English).

Both pages come from the files listed in parts/order.txt, so the two
languages cannot drift apart: every visible sentence is a pair

    {{Türkçe metin||English text}}

and the icons are the Material Symbols Rounded paths in icons/, collected
into one inline sprite for the icons the page actually uses. @ROOT@ is the
path back to the site's root ('' or '../'). Run it after editing a part:

    python3 site/tools/build_pages.py

The site itself stays plain HTML, CSS and JS; this only writes the two pages.
"""
import re
import sys
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
SITE = TOOLS.parent
PAIR = re.compile(r'\{\{(.*?)\|\|(.*?)\}\}', re.S)
ICON = re.compile(r'#i-([a-z0-9-]+)')

LANGS = {
    'tr': {'root': '', 'out': SITE / 'index.html', 'other': 'en', 'other_href': 'en/', 'self_href': './'},
    'en': {'root': '../', 'out': SITE / 'en' / 'index.html', 'other': 'tr', 'other_href': '../', 'self_href': './'},
}


def sprite(used):
    symbols = []
    for name in sorted(used):
        path = TOOLS / 'icons' / f'{name}.path'
        if not path.exists():
            sys.exit(f'missing icon: {name}')
        symbols.append(f'<symbol id="i-{name}" viewBox="0 -960 960 960"><path d="{path.read_text().strip()}"/></symbol>')
    return '\n'.join(symbols)


def build(lang):
    cfg = LANGS[lang]
    order = [p.strip() for p in (TOOLS / 'parts' / 'order.txt').read_text().splitlines() if p.strip() and not p.startswith('#')]
    text = '\n'.join((TOOLS / 'parts' / f'{name}.html').read_text().rstrip('\n') for name in order) + '\n'
    idx = 0 if lang == 'tr' else 1
    text = PAIR.sub(lambda m: m.group(1 + idx), text)
    text = (text.replace('@ROOT@', cfg['root']).replace('@LANG@', lang)
            .replace('@OTHER@', cfg['other']).replace('@OTHER_HREF@', cfg['other_href']))
    text = text.replace('@SPRITE@', sprite(set(ICON.findall(text))))
    if '{{' in text or '||' in text:
        sys.exit(f'{lang}: an unpaired marker is left in the page')
    cfg['out'].parent.mkdir(exist_ok=True)
    cfg['out'].write_text(text)
    print(f'{cfg["out"].relative_to(SITE)}: {len(text) // 1024} KB')


if __name__ == '__main__':
    for code in LANGS:
        build(code)
