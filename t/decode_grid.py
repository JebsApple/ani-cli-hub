#!/usr/bin/env python3
"""Oráculo del grid: decodifica capture-pane -e (placeholders kitty + bordes)
y valida la estructura contra la geometría esperada.

Uso:
  tmux capture-pane -pe -t S | decode_grid.py --geom ncols=5,card_w=29,img_h=17,\
      card_h=22,margin_x=2,gap_x=2,header_h=2 [--dump] [--selected]

Asserts (exit 1 si falla alguno):
  - cada imagen: bbox == (card_w-4) x img_h, cobertura completa sin huecos
  - top-left de imagen == (cy+1, cx+2) de alguna tarjeta
  - esquinas ╭ en x = margin_x + k*(card_w+gap_x); filas alineadas
  - ningún placeholder pisa columnas de borde
"""
import sys, re, json, argparse, unicodedata
from pathlib import Path

PH = '\U0010eeee'
SGR = re.compile(r'\x1b\[([0-9;:]*)m')
DIA = {}
for i, line in enumerate(Path(__file__).with_name('diacritics.txt').read_text().split()):
    DIA[chr(int(line, 16))] = i

ACCENT = ('38', '5', '141')  # borde seleccionado


def cell_width(ch):
    return 2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1


def parse(lines):
    imgs = {}      # fg_key -> list[(y, x, irow, icol)]
    corners = []   # (y, x, char, fg)
    verts = []     # (y, x) de │
    for y, line in enumerate(lines):
        x = 0
        fg = None
        pos = 0
        for m in SGR.finditer(line):
            text = line[pos:m.start()]
            x, fg2 = scan_text(text, y, x, fg, imgs, corners, verts)
            fg = fg2
            params = re.split('[;:]', m.group(1)) if m.group(1) else ['0']
            fg = update_fg(fg, params)
            pos = m.end()
        x, fg = scan_text(line[pos:], y, x, fg, imgs, corners, verts)
    return imgs, corners, verts


def scan_text(text, y, x, fg, imgs, corners, verts):
    chars = list(text)
    i = 0
    while i < len(chars):
        ch = chars[i]
        if ch == PH:
            combs = []
            j = i + 1
            while j < len(chars) and unicodedata.combining(chars[j]):
                combs.append(chars[j]); j += 1
            if len(combs) >= 2 and combs[0] in DIA and combs[1] in DIA:
                imgs.setdefault(fg, []).append((y, x, DIA[combs[0]], DIA[combs[1]]))
            x += 1
            i = j
        elif unicodedata.combining(ch):
            i += 1  # combining suelto: no avanza celda
        else:
            if ch in '╭╮╰╯':
                corners.append((y, x, ch, fg))
            elif ch == '│':
                verts.append((y, x))
            x += cell_width(ch)
            i += 1
    return x, fg


def update_fg(fg, p):
    # devuelve tupla identificadora del fg actual
    i = 0
    while i < len(p):
        if p[i] == '0':
            fg = None
        elif p[i] == '38' and i + 1 < len(p):
            if p[i+1] == '5' and i + 2 < len(p):
                fg = ('38', '5', p[i+2]); i += 2
            elif p[i+1] == '2' and i + 4 < len(p):
                fg = ('38', '2', p[i+2], p[i+3], p[i+4]); i += 4
        i += 1
    return fg


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--geom', required=False, default='')
    ap.add_argument('--dump', action='store_true')
    ap.add_argument('--selected', action='store_true')
    args = ap.parse_args()

    lines = sys.stdin.read().split('\n')
    imgs, corners, verts = parse(lines)

    if args.dump:
        out = {str(k): {'cells': len(v),
                        'bbox': [min(c[1] for c in v), min(c[0] for c in v),
                                 max(c[1] for c in v), max(c[0] for c in v)]}
               for k, v in imgs.items()}
        print(json.dumps({'images': out, 'corners': len(corners)}, indent=1))

    if args.selected:
        sel = [(y, x) for (y, x, ch, fg) in corners if ch == '╭' and fg == ACCENT]
        for y, x in sel:
            print(f'{y} {x}')
        return 0 if sel else 1

    if not args.geom:
        return 0
    g = dict(kv.split('=') for kv in args.geom.split(','))
    g = {k: int(v) for k, v in g.items()}
    ncols, card_w, img_h = g['ncols'], g['card_w'], g['img_h']
    card_h, margin_x, gap_x, header_h = g['card_h'], g['margin_x'], g['gap_x'], g['header_h']
    iw = card_w - 4
    fails = []

    # posiciones válidas de tarjeta
    def col_x(c): return margin_x + c * (card_w + gap_x)
    valid_cx = {col_x(c) for c in range(ncols)}
    valid_cy = {header_h + r * card_h for r in range(0, 100)}

    # 1) imágenes: encaje "contain": dentro del box, tocando ambos extremos de
    #    al menos una dimensión (aspect preservado ⇒ la otra puede ser menor, centrada)
    for key, cells in imgs.items():
        xs = [c[1] for c in cells]; ys = [c[0] for c in cells]
        w = max(xs) - min(xs) + 1; h = max(ys) - min(ys) + 1
        if w > iw or h > img_h:
            fails.append(f'imagen {key}: bbox {w}x{h} DESBORDA box {iw}x{img_h}')
        if w != iw and h != img_h:
            fails.append(f'imagen {key}: bbox {w}x{h} no llena ninguna dimensión de {iw}x{img_h}')
        if len(cells) != w * h:
            fails.append(f'imagen {key}: {len(cells)} celdas != bbox {w}x{h} (huecos)')
        # encaje: la imagen vive dentro del área (cx+2..cx+2+iw-1, cy+1..cy+img_h)
        ox, oy = min(xs), min(ys)
        anchored = any(cx0 + 2 <= ox and ox + w <= cx0 + 2 + iw for cx0 in valid_cx)
        if not anchored:
            fails.append(f'imagen {key}: x=[{ox},{ox+w-1}] fuera del área de imagen de toda tarjeta')
        anchored_y = any(cy0 + 1 <= oy and oy + h <= cy0 + 1 + img_h for cy0 in valid_cy)
        if not anchored_y:
            fails.append(f'imagen {key}: y=[{oy},{oy+h-1}] fuera del área de imagen de toda tarjeta')

    # 2) esquinas: columnas exactas y rectángulos consistentes
    tl = [(y, x) for (y, x, ch, _) in corners if ch == '╭']
    for y, x in tl:
        if x not in valid_cx:
            fails.append(f'╭ en x={x} fuera de columnas válidas {sorted(valid_cx)}')
        if y not in valid_cy:
            fails.append(f'╭ en y={y} fuera de filas válidas')
    # cada ╭ debe tener su ╮ a card_w-1 y ╰ a card_h-2 (borde inferior antes del gap)
    tr = {(y, x) for (y, x, ch, _) in corners if ch == '╮'}
    bl = {(y, x) for (y, x, ch, _) in corners if ch == '╰'}
    bh = img_h + 2 + 2  # img + 2 títulos + 2 bordes → altura del rectángulo
    for y, x in tl:
        if (y, x + card_w - 1) not in tr:
            fails.append(f'tarjeta ({y},{x}): falta ╮ en x={x+card_w-1}')
        if (y + bh - 1, x) not in bl:
            fails.append(f'tarjeta ({y},{x}): falta ╰ en y={y+bh-1}')

    # 3) placeholders nunca pisan bordes
    border_x = set()
    for c in range(ncols):
        border_x.add(col_x(c)); border_x.add(col_x(c) + card_w - 1)
    for key, cells in imgs.items():
        for (y, x, _, _) in cells:
            if x in border_x:
                fails.append(f'imagen {key}: placeholder pisa borde en ({y},{x})')
                break

    if fails:
        print('\n'.join(fails[:20]), file=sys.stderr)
        print(f'DECODE: {len(fails)} fallas', file=sys.stderr)
        return 1
    print(f'DECODE OK: {len(imgs)} imágenes, {len(tl)} tarjetas')
    return 0


if __name__ == '__main__':
    sys.exit(main())
