#!/usr/bin/env python3
"""Writes the logo SVGs in brand/logo from one description of the mark.

The mark (59A): the app's own Next key, large, with the small Previous key
beside it and the laser dot on the Next key's top right corner. Its geometry is in the
units of the 512 px icon, before the icon places it (MARK_CENTER, MARK_SCALE).
lib/widgets/brand/brand_mark.dart in both apps draws the same shapes; change
the two together.

Run by brand/tools/export_assets.sh; the wordmark SVGs are hand-made and
only read here.
"""
import math
import pathlib
import re

LOGO = pathlib.Path(__file__).resolve().parent.parent / 'logo'

PREV = (70, 196, 100, 150)  # x, y, w, h; corner radius w * .3
NEXT = (196, 158, 200, 236)  # corner radius w * .26
LASER = (388, 166, 28)  # cx, cy, r; its glow reaches r * 2.6
# The Next key is cut away this far around the laser dot, which sits on its
# corner.
LASER_GAP = 10
# The middle of the two keys: the icons center the keys, not the keys and the
# laser dot together, which put the arrows low and to the left.
MARK_CENTER = (233, 276)
MARK_SCALE = 1.12
# The adaptive icon's safe zone: a circle of 33 dp on the 108 dp layer.
SAFE_RADIUS = 33

LASER_COLOR = '#FF6A3D'
NEXT_STOPS = ('#3E63F5', '#2F4BE0', '#1B28A3')

# Tile top and bottom, Previous key fill, border and chevron, the Next key's
# glow, the tile's blue light (None: none) and its edge.
THEMES = {
    'dark': (('#141A33', '#0A0D18'), '#1A1F36', '#323A62', '#C9CEE6', .75, .22, 'rgba(255,255,255,.06)'),
    'oled': (('#0B0B0F', '#000000'), '#18181C', '#34343C', '#C4C4CC', .7, .22, 'rgba(255,255,255,.06)'),
    'light': (('#FFFFFF', '#ECEEF5'), '#FFFFFF', '#E1E4EE', '#4A5172', .45, None, '#E1E4EE'),
}
TILE_RADIUS = 118


def chevron(d, color, width):
    return (f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" '
            'stroke-linecap="round" stroke-linejoin="round"/>')


def dot_cut(mask_id, dot_radius):
    """A mask that hides a circle around the laser dot, [LASER_GAP] wider than
    a dot of [dot_radius]."""
    lx, ly, _ = LASER
    return (f'<mask id="{mask_id}" maskUnits="userSpaceOnUse" x="-512" y="-512" width="1536" height="1536">'
            f'<rect x="-512" y="-512" width="1536" height="1536" fill="#FFFFFF"/>'
            f'<circle cx="{lx}" cy="{ly}" r="{dot_radius + LASER_GAP}" fill="#000000"/></mask>')


def defs(theme, effects=True):
    _, _, _, _, glow, light, _ = THEMES[theme]
    out = (dot_cut('dot', LASER[2]) + f'<linearGradient id="next" x1="0" y1="0" x2=".55" y2="1"><stop offset="0" stop-color="{NEXT_STOPS[0]}"/>'
           f'<stop offset=".55" stop-color="{NEXT_STOPS[1]}"/><stop offset="1" stop-color="{NEXT_STOPS[2]}"/></linearGradient>'
           '<linearGradient id="sheen" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".28"/>'
           '<stop offset=".3" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient>')
    if effects:
        out += (f'<filter id="glow" x="-40%" y="-40%" width="180%" height="190%"><feDropShadow dx="0" dy="22" '
                f'stdDeviation="22" flood-color="{NEXT_STOPS[0]}" flood-opacity="{glow}"/></filter>'
                f'<radialGradient id="laser"><stop offset="0" stop-color="{LASER_COLOR}" stop-opacity=".75"/>'
                f'<stop offset=".45" stop-color="{LASER_COLOR}" stop-opacity=".25"/>'
                f'<stop offset="1" stop-color="{LASER_COLOR}" stop-opacity="0"/></radialGradient>')
    if light is not None:
        out += (f'<radialGradient id="light" cx=".1" cy="0" r=".9"><stop offset="0" stop-color="{NEXT_STOPS[0]}" '
                f'stop-opacity="{light}"/><stop offset="1" stop-color="{NEXT_STOPS[0]}" stop-opacity="0"/></radialGradient>')
    return out


def mark(theme, effects=True):
    """The mark in the icon's units, before MARK_SCALE."""
    _, fill, border, chev, _, _, _ = THEMES[theme]
    x, y, w, h = PREV
    cx, cy = x + w / 2, y + h / 2
    out = (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{w * .3:g}" fill="{fill}" stroke="{border}" stroke-width="5"/>'
           + chevron(f'M{cx + 12:g} {cy - 26:g} L{cx - 14:g} {cy:g} L{cx + 12:g} {cy + 26:g}', chev, 18))
    x, y, w, h = NEXT
    cx, cy = x + w / 2, y + h / 2
    key = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{w * .26:g}" fill="url(#next)"/>'
    out += ('<g mask="url(#dot)">' + (f'<g filter="url(#glow)">{key}</g>' if effects else key)
            + f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{w * .26:g}" fill="url(#sheen)"/>'
            + chevron(f'M{cx - 22:g} {cy - 44:g} L{cx + 22:g} {cy:g} L{cx - 22:g} {cy + 44:g}', '#FFFFFF', 32) + '</g>')
    lx, ly, lr = LASER
    if effects:
        out += f'<circle cx="{lx}" cy="{ly}" r="{lr * 2.6:g}" fill="url(#laser)"/>'
    return out + f'<circle cx="{lx}" cy="{ly}" r="{lr}" fill="{LASER_COLOR}"/>'


def mono_mark(color):
    """One color, the knocked out parts transparent: the Previous key as an
    outline, the Next key filled with its chevron and the dot's gap cut out,
    the dot."""
    x, y, w, h = PREV
    cx, cy = x + w / 2, y + h / 2
    nx, ny, nw, nh = NEXT
    ncx, ncy = nx + nw / 2, ny + nh / 2
    lx, ly, _ = LASER
    return (f'<mask id="cut"><rect x="0" y="0" width="512" height="512" fill="#FFFFFF"/>'
            + chevron(f'M{ncx - 22:g} {ncy - 44:g} L{ncx + 22:g} {ncy:g} L{ncx - 22:g} {ncy + 44:g}', '#000000', 32)
            + f'<circle cx="{lx}" cy="{ly}" r="{30 + LASER_GAP}" fill="#000000"/></mask>'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{w * .3:g}" fill="none" stroke="{color}" stroke-width="22"/>'
            + chevron(f'M{cx + 12:g} {cy - 26:g} L{cx - 14:g} {cy:g} L{cx + 12:g} {cy + 26:g}', color, 20)
            + f'<rect x="{nx}" y="{ny}" width="{nw}" height="{nh}" rx="52" fill="{color}" mask="url(#cut)"/>'
            f'<circle cx="{lx}" cy="{ly}" r="30" fill="{color}"/>')


def placed(content, center, scale, origin=MARK_CENTER):
    """Moves the mark's [origin] to [center] and scales it."""
    mx, my = origin
    return f'<g transform="translate({center[0]:g} {center[1]:g}) scale({scale:g}) translate({-mx} {-my})">{content}</g>'


def tile(theme, size=512, radius=TILE_RADIUS, effects=True, clip_id='tile'):
    (top, bottom), _, _, _, _, light, edge = THEMES[theme]
    s = size / 512
    body = (f'<rect width="512" height="512" fill="url(#bg)"/>'
            + (f'<rect width="512" height="512" fill="url(#light)"/>' if light is not None else '')
            + placed(mark(theme, effects), (256, 256), MARK_SCALE))
    return (f'<g transform="scale({s:g})"><defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>'
            f'<clipPath id="{clip_id}"><rect width="512" height="512" rx="{radius}"/></clipPath></defs>'
            f'<g clip-path="url(#{clip_id})">{body}</g>'
            f'<rect x="1.5" y="1.5" width="509" height="509" rx="{radius - 1.5:g}" fill="none" stroke="{edge}" stroke-width="3"/></g>')


def svg(width, height, body, extra_defs=''):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}">\n'
            f'  <defs>{extra_defs}</defs>\n  {body}\n</svg>\n')


def outline_points(key_stroke, dot_radius):
    """Points around the mark's shapes, the Previous key with half its
    stroke ([key_stroke]); the glows are left out."""
    def rounded(x, y, w, h, r):
        for cx, cy, start in ((x + w - r, y + r, -90), (x + w - r, y + h - r, 0), (x + r, y + h - r, 90), (x + r, y + r, 180)):
            for i in range(31):
                a = math.radians(start + 3 * i)
                yield cx + r * math.cos(a), cy + r * math.sin(a)

    x, y, w, h = PREV
    k = key_stroke / 2
    yield from rounded(x - k, y - k, w + 2 * k, h + 2 * k, w * .3 + k)
    x, y, w, h = NEXT
    yield from rounded(x, y, w, h, w * .26)
    lx, ly, _ = LASER
    for i in range(120):
        a = 2 * math.pi * i / 120
        yield lx + dot_radius * math.cos(a), ly + dot_radius * math.sin(a)


def reach(points):
    """How far the farthest of [points] lies from MARK_CENTER."""
    return max(math.hypot(x - MARK_CENTER[0], y - MARK_CENTER[1]) for x, y in points)


def adaptive(content, points):
    """[content] on a 108 dp adaptive icon layer, the keys in the middle, and
    as large as the safe zone allows with the laser dot inside it, so that no
    launcher mask cuts it."""
    return placed(content, (54, 54), SAFE_RADIUS / reach(points))


def adaptive_foreground(theme):
    return svg(108, 108, adaptive(mark(theme), outline_points(5, LASER[2])), defs(theme))


def adaptive_background(theme):
    (top, bottom), _, _, _, _, light, _ = THEMES[theme]
    body = '<rect width="512" height="512" fill="url(#bg)"/>'
    if light is not None:
        body += '<rect width="512" height="512" fill="url(#light)"/>'
    return svg(512, 512, body, f'<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/>'
               f'<stop offset="1" stop-color="{bottom}"/></linearGradient>' + defs(theme))


def wordmark_paths(name):
    """The text paths of a wordmark SVG, in font units, and their extent."""
    text = (LOGO / name).read_text()
    paths = re.findall(r'<path [^>]*/>', text)
    xs = [float(v) for p in paths for v in re.findall(r'[MLHQ ](-?\d+(?:\.\d+)?)', re.sub(r'V-?[\d.]+', '', p))]
    return paths, max(xs)


def lockup(theme, wordmark):
    """The icon followed by the name, as on the logo board: the type is 0.53
    of the icon's height, the gap 0.22."""
    height = 260
    paths, extent = wordmark_paths(wordmark)
    s = height * .53 / 1000
    x = height * 1.22
    baseline = height / 2 + 700 * s / 2  # Space Grotesk's caps are 700 units
    width = math.ceil(x + extent * s + 8)
    body = (tile(theme, height, effects=True) +
            f'\n  <g transform="translate({x:g} {baseline:.1f}) scale({s:g})">{"".join(paths)}</g>')
    return svg(width, height, body, defs(theme))


def stroke_outline(points, width):
    """The outline of a two-segment polyline drawn with round caps and joins,
    as path data: the Next key's chevron, cut out of the key where a vector
    drawable has no mask."""
    (x0, y0), (x1, y1), (x2, y2) = points
    r = width / 2

    def normal(ax, ay, bx, by):
        length = math.hypot(bx - ax, by - ay)
        return -(by - ay) / length * r, (bx - ax) / length * r

    n1, n2 = normal(x0, y0, x1, y1), normal(x1, y1, x2, y2)
    # The outer side of the bend is the one away from the chord's middle.
    mx, my = (x0 + x2) / 2, (y0 + y2) / 2
    if math.hypot(x1 + n1[0] - mx, y1 + n1[1] - my) < math.hypot(x1 - n1[0] - mx, y1 - n1[1] - my):
        n1, n2 = (-n1[0], -n1[1]), (-n2[0], -n2[1])
    # The inner corner: where the two inner edges meet.
    ax, ay, bx, by = x0 - n1[0], y0 - n1[1], x2 - n2[0], y2 - n2[1]
    d1x, d1y, d2x, d2y = x1 - x0, y1 - y0, x1 - x2, y1 - y2
    t = ((bx - ax) * d2y - (by - ay) * d2x) / (d1x * d2y - d1y * d2x)
    ix, iy = ax + t * d1x, ay + t * d1y
    sweep = 1 if (x1 - x0) * (y2 - y1) - (y1 - y0) * (x2 - x1) > 0 else 0
    f = lambda v: f'{v:.2f}'.rstrip('0').rstrip('.')
    arc = lambda x, y: f'A{f(r)},{f(r)} 0 0,{sweep} {f(x)},{f(y)}'
    return (f'M{f(x0 + n1[0])},{f(y0 + n1[1])} L{f(x1 + n1[0])},{f(y1 + n1[1])} {arc(x1 + n2[0], y1 + n2[1])} '
            f'L{f(x2 + n2[0])},{f(y2 + n2[1])} {arc(x2 - n2[0], y2 - n2[1])} L{f(ix)},{f(iy)} '
            f'L{f(x0 - n1[0])},{f(y0 - n1[1])} {arc(x0 + n1[0], y0 + n1[1])} Z')


def circles_cross(c1, r1, c2, r2):
    """The two points where two circles cross."""
    dx, dy = c2[0] - c1[0], c2[1] - c1[1]
    d = math.hypot(dx, dy)
    a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
    h = math.sqrt(r1 * r1 - a * a)
    mx, my = c1[0] + a * dx / d, c1[1] + a * dy / d
    return (mx + h * dy / d, my - h * dx / d), (mx - h * dy / d, my + h * dx / d)


def presenting_icon():
    """The watch's Ongoing Activity and notification icon: the one-color mark
    in white, as a vector drawable."""
    x, y, w, h = PREV
    cx, cy = x + w / 2, y + h / 2
    nx, ny, nw, nh = NEXT
    ncx, ncy = nx + nw / 2, ny + nh / 2
    lx, ly, _ = LASER
    scale = 256 / reach(outline_points(22, 30))
    # The dot's gap bites into the key's top right corner: from A on the
    # corner's arc around the gap to B, both where the two circles cross.
    gap = 30 + LASER_GAP
    (ax, ay), (bx, by) = sorted(circles_cross((nx + nw - 52, ny + 52), 52, (lx, ly), gap), key=lambda q: q[0])
    f = lambda v: f'{v:.2f}'.rstrip('0').rstrip('.')
    key = (f'M{nx + 52},{ny}H{nx + nw - 52}A52,52 0 0,1 {f(ax)},{f(ay)}A{gap},{gap} 0 0,0 {f(bx)},{f(by)}'
           f'A52,52 0 0,1 {nx + nw},{ny + 52}V{ny + nh - 52}'
           f'A52,52 0 0,1 {nx + nw - 52},{ny + nh}H{nx + 52}A52,52 0 0,1 {nx},{ny + nh - 52}'
           f'V{ny + 52}A52,52 0 0,1 {nx + 52},{ny}Z ')
    cut = stroke_outline(((ncx - 22, ncy - 44), (ncx + 22, ncy), (ncx - 22, ncy + 44)), 32)
    ring = (f'M{x + 30},{y}H{x + w - 30}A30,30 0 0,1 {x + w},{y + 30}V{y + h - 30}A30,30 0 0,1 {x + w - 30},{y + h}'
            f'H{x + 30}A30,30 0 0,1 {x},{y + h - 30}V{y + 30}A30,30 0 0,1 {x + 30},{y}Z')
    white = '#FFFFFFFF'
    return f'''<?xml version="1.0" encoding="utf-8"?>
<!-- Generated by brand/tools/draw_logo.py: the one-color QuickRemote mark
     (brand/logo/mark-mono.svg) in white: the watch's Ongoing Activity and
     its notification, the phone's Quick Settings tile. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="512"
    android:viewportHeight="512">
    <group
        android:translateX="256"
        android:translateY="256"
        android:scaleX="{scale:.4f}"
        android:scaleY="{scale:.4f}">
        <group
            android:translateX="{-MARK_CENTER[0]}"
            android:translateY="{-MARK_CENTER[1]}">
            <path
                android:pathData="{ring}"
                android:strokeWidth="22"
                android:strokeColor="{white}" />
            <path
                android:pathData="M{cx + 12:g},{cy - 26:g}L{cx - 14:g},{cy:g}L{cx + 12:g},{cy + 26:g}"
                android:strokeWidth="20"
                android:strokeColor="{white}"
                android:strokeLineCap="round"
                android:strokeLineJoin="round" />
            <path
                android:pathData="{key}{cut}"
                android:fillColor="{white}"
                android:fillType="evenOdd" />
            <path
                android:pathData="M{lx - 30},{ly}a30,30 0 1,0 60,0a30,30 0 1,0 -60,0z"
                android:fillColor="{white}" />
        </group>
    </group>
</vector>
'''


def main():
    files = {
        # The launcher and window icon: the dark tile.
        'app-icon.svg': svg(512, 512, tile('dark'), defs('dark')),
        'app-icon-light.svg': svg(512, 512, tile('light'), defs('light')),
        'app-icon-oled.svg': svg(512, 512, tile('oled'), defs('oled')),
        # 16-48 px: without the glows and the sheen, which blur into mud.
        'favicon.svg': svg(512, 512, tile('dark', effects=False), defs('dark', effects=False)),
        # Android adaptive icon layers; the watch's on black.
        'adaptive-background.svg': adaptive_background('dark'),
        'adaptive-foreground.svg': adaptive_foreground('dark'),
        'adaptive-background-oled.svg': adaptive_background('oled'),
        'adaptive-foreground-oled.svg': adaptive_foreground('oled'),
        'adaptive-monochrome.svg': svg(108, 108, adaptive(mono_mark('#000000'), outline_points(22, 30))),
        'mark-mono.svg': svg(512, 512, placed(mono_mark('#0E1224'), (256, 256), 256 / reach(outline_points(22, 30)))),
        'lockup-dark-bg.svg': lockup('dark', 'wordmark-dark-bg.svg'),
        'lockup-light-bg.svg': lockup('light', 'wordmark-light-bg.svg'),
    }
    for name, text in files.items():
        (LOGO / name).write_text(text)
    for app in ('quick_remote_wear', 'quick_remote_app/android'):
        (LOGO.parent.parent / app / 'app/src/main/res/drawable/ic_presenting.xml').write_text(presenting_icon())


if __name__ == '__main__':
    main()
