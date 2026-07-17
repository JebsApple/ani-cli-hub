#!/bin/bash
# One-time: deriva la tabla de diacríticos del protocolo kitty desde icat mismo.
# Genera t/diacritics.txt — un codepoint hex por línea, índice = línea - 1.
cd "$(dirname "$0")" || exit 1

tmp=$(mktemp -d)
# imagen grande para que icat llene el área --place (sin --scale-up no agranda)
magick -size 1600x1200 xc:gray "$tmp/calib.png" 2>/dev/null ||
    convert -size 1600x1200 xc:gray "$tmp/calib.png" || { echo "falta imagemagick"; exit 1; }

tmux kill-session -t anical 2>/dev/null
tmux new-session -d -s anical -x 100 -y 70
sleep 1   # esperar init del shell (zsh+p10k) antes de mandar teclas
tmux send-keys -t anical "kitten icat --transfer-mode=memory --stdin=no --unicode-placeholder --place=80x60@0x0 '$tmp/calib.png' > '$tmp/calib.raw' 2>/dev/null; echo CALDONE" Enter
for _ in $(seq 1 20); do
    tmux capture-pane -t anical -p 2>/dev/null | grep -q CALDONE && break
    sleep 0.5
done
tmux kill-session -t anical 2>/dev/null

python3 - "$tmp/calib.raw" > diacritics.txt << 'EOF'
import sys, re
raw = open(sys.argv[1], encoding='utf-8', errors='replace').read()
PH = '\U0010eeee'
# extraer pares (dia_row, dia_col) en orden de emisión
cells = []
chars = list(raw)
i = 0
while i < len(chars):
    if chars[i] == PH:
        combs = []
        j = i + 1
        while j < len(chars) and 0x300 <= ord(chars[j]) <= 0x1E94A and len(combs) < 3:
            # combining marks del rango usado por el protocolo
            import unicodedata
            if unicodedata.combining(chars[j]) or 0x300 <= ord(chars[j]) < 0x370:
                combs.append(chars[j]); j += 1
            else:
                break
        if len(combs) >= 2:
            cells.append((combs[0], combs[1]))
        i = j
    else:
        i += 1
if not cells:
    print("sin celdas placeholder", file=sys.stderr); sys.exit(1)
# tabla de columnas: primera fila = dia_row constante; dia_col en orden 0..n
first_row = cells[0][0]
table = []
seen = set()
for r, c in cells:
    if r != first_row:
        break
    if c not in seen:
        seen.add(c); table.append(c)
# extender con la secuencia de filas (mismo alfabeto, índices coinciden)
rows_seq = []
rseen = set()
for r, _ in cells:
    if r not in rseen:
        rseen.add(r); rows_seq.append(r)
for idx, r in enumerate(rows_seq):
    if idx < len(table):
        if table[idx] != r:
            print(f"WARN fila {idx} != col {idx}", file=sys.stderr)
    else:
        table.append(r)
for ch in table:
    print(f"{ord(ch):04x}")
EOF
rc=$?
rm -rf "$tmp"
[ $rc -ne 0 ] && exit $rc
wc -l < diacritics.txt | xargs printf 'diacritics: %s entradas\n'
