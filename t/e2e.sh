#!/bin/bash
# Capa 3 — features end-to-end: navegación, scroll, selección, payload, resize.
# Corre show_card_grid directo (sin red) con fixtures locales, en tmux pty.
cd "$(dirname "$0")" || exit 1
T=$PWD
CORE=$T/../ani-cli-mx-core
S=anie2e
OUT=/tmp/cg_e2e.out
fails=0
fail() { printf 'E2E FAIL: %s\n' "$1"; fails=$((fails+1)); }

# ── fixtures ────────────────────────────────────────────────
FIX=$(mktemp -d)
for i in $(seq 1 12); do
    # tamaño realista de cover (los posters reales son ~350x500+)
    magick -size 700x1000 "xc:hsl($((i*29)),80%,50%)" "$FIX/img_$i.png" 2>/dev/null ||
        convert -size 700x1000 "xc:gray$((i*7))" "$FIX/img_$i.png"
    printf '%s/img_%d.png\tTitulo %d\tEp %d\tPAYLOAD_%d\n' "$FIX" "$i" "$i" "$i" "$i"
done > "$FIX/fix.tsv"

# geometría esperada: la misma _cg_geom (una sola fuente de verdad)
geom_for() { # $1 cols  $2 rows  $3 aspect  $4 total → imprime string --geom
    CG_COLS=$1 CG_ROWS=$2 bash -c '
        export ANI_MX_TEST=1 ANI_CLI_HIST_DIR=$(mktemp -d) ANI_CLI_SKIP_TITLE=
        source "'"$CORE"'"
        min_card_w=22 margin_x=2 gap_x=2 title_rows=2 header_h=2
        aspect='"$3"' total='"$4"' sel=0 top=0
        _cg_geom
        printf "ncols=%d,card_w=%d,img_h=%d,card_h=%d,margin_x=2,gap_x=2,header_h=2" \
            "$ncols" "$card_w" "$img_h" "$card_h"
        rm -rf "$ANI_CLI_HIST_DIR"'
}

boot() { # $1 cols  $2 rows
    tmux kill-session -t $S 2>/dev/null
    tmux new-session -d -s $S -x "$1" -y "$2"
    tmux set-option -t $S window-size manual
    sleep 1
    tmux send-keys -t $S "ANI_MX_TEST=1 ANI_CLI_SKIP_TITLE= ANI_CLI_HIST_DIR=$FIX bash -c 'source $CORE; show_card_grid $FIX/fix.tsv test portrait > $OUT; echo rc=\$? >> $OUT'" Enter
    sleep 3
}
snap() { tmux capture-pane -pe -t $S; }
snapp() { tmux capture-pane -p -t $S; }
press() { tmux send-keys -t $S "$1"; sleep 0.6; }
hdr() { snapp | grep -o 'fila [0-9]*/[0-9]*' | head -1; }
sel_xy() { snap | python3 "$T/decode_grid.py" --selected | head -1; }
check_layout() { # $1 cols $2 rows $3 etiqueta
    local g
    g=$(geom_for "$1" "$2" portrait 12)
    printf '  geom(%sx%s)=%s\n' "$1" "$2" "$g" >&2
    snap | python3 "$T/decode_grid.py" --geom "$g" \
        || fail "layout inválido en $1x$2 ($3)"
}

# ── escenario lineal ────────────────────────────────────────
# pane alto: 3 filas de tarjetas visibles → asserts posicionales válidos
boot 120 68
[ "$(hdr)" = "fila 1/3" ] || fail "header inicial: $(hdr)"
check_layout 120 68 "boot"

start_sel=$(sel_xy)
press Right; press Right
after_right=$(sel_xy)
[ "$start_sel" != "$after_right" ] || fail "Right no movió selección"

press Down
after_down=$(sel_xy)
[ "$after_right" != "$after_down" ] || fail "Down no movió selección"
[ "$(hdr)" = "fila 2/3" ] || fail "header tras Down: $(hdr)"

# scroll real: pane bajo (1 fila visible) → cada Down desplaza la región
tmux resize-window -t $S -x 120 -y 40
sleep 1.6
press j
[ "$(hdr)" = "fila 3/3" ] || fail "header tras j con scroll: $(hdr)"
check_layout 120 40 "post-scroll"

press g
[ "$(hdr)" = "fila 1/3" ] || fail "g no volvió al inicio: $(hdr)"
press G
[ "$(hdr)" = "fila 3/3" ] || fail "G no fue al final: $(hdr)"

# resize en vivo (recoger WINCH tarda hasta 1s por el read -t 1)
tmux resize-window -t $S -x 80 -y 30
sleep 1.6
check_layout 80 30 "post-resize 80x30"
sel_xy >/dev/null || fail "selección invisible tras resize"

tmux resize-window -t $S -x 46 -y 20
sleep 1.6
snapp | grep -q 'fila' || fail "crash en 46x20"
check_layout 46 20 "extremo 46x20"

# Enter → payload correcto (no borrar OUT: el grid tiene el fd abierto desde boot)
press Enter
sleep 1
grep -q 'PAYLOAD_' "$OUT" || fail "payload no emitido"
grep -q 'rc=0' "$OUT" || fail "rc != 0 tras Enter"

# q → salida limpia
boot 120 40
press q
sleep 1
grep -q 'rc=1' "$OUT" || fail "q no retornó rc=1"
snapp | grep -q $'\U0010eeee' && fail "placeholders residuales tras q"

tmux kill-session -t $S 2>/dev/null
rm -rf "$FIX"
printf 'e2e: %d fails\n' "$fails"
exit "$fails"
