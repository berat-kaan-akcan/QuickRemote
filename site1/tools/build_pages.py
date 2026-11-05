#!/usr/bin/env python3
"""Writes site1/index.html (Turkish) and site1/en/index.html (English).

Same scheme as site/tools/build_pages.py: the pages come from the files in
parts/order.txt, every visible sentence is a {{Türkçe||English}} pair, and only
the icons a page uses go into its inline sprite. @Y@, @P@ and @N@ are the three
marks of the support table, each with its words for screen readers.

    python3 site1/tools/build_pages.py
"""
import re
import sys
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
SITE = TOOLS.parent
PAIR = re.compile(r'\{\{(.*?)\|\|(.*?)\}\}', re.S)
ICON = re.compile(r'#i-([a-z0-9-]+)')

LANGS = {
    'tr': {'root': '', 'out': SITE / 'index.html', 'other': 'en', 'other_href': 'en/'},
    'en': {'root': '../', 'out': SITE / 'en' / 'index.html', 'other': 'tr', 'other_href': '../'},
}
MARKS = {
    '@Y@': ('yes', 'check', 'Çalışır', 'Works'),
    '@P@': ('part', 'contrast', 'Kısmen', 'Partly'),
    '@N@': ('no', 'remove', 'Yok', 'No'),
}


def mark(kind, lang):
    cls, icon, tr, en = MARKS[kind]
    word = tr if lang == 'tr' else en
    return f'<span class="m m-{cls}" title="{word}"><svg class="i" aria-hidden="true"><use href="#i-{icon}"/></svg><span class="sr">{word}</span></span>'


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
    text = PAIR.sub(lambda m: m.group(1 if lang == 'tr' else 2), text)
    for kind in MARKS:
        text = text.replace(kind, mark(kind, lang))
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
