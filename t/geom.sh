#!/bin/bash
# Capa 1 — invariantes matemáticos de _cg_geom (sin render, sin pty)
# Barrido: term_cols 40..300 × term_rows 15..80 × aspect × total
# Simula resize: sel/top de la geometría anterior deben quedar válidos en la nueva.
cd "$(dirname "$0")/.." || exit 1

export ANI_MX_TEST=1
export ANI_CLI_HIST_DIR=$(mktemp -d)
export ANI_CLI_SKIP_TITLE=""
source ./ani-cli-mx-core
trap - EXIT HUP INT TERM   # des-armar los traps del core (cleanup no aplica en tests)

fails=0
checks=0
fail() { printf 'FAIL [%dx%d %s total=%d sel=%d top=%d] %s\n' \
    "$CG_COLS" "$CG_ROWS" "$aspect" "$total" "$sel" "$top" "$1"; fails=$((fails+1)); }

# constantes del grid (mismos valores que show_card_grid)
min_card_w=22 margin_x=2 gap_x=2 title_rows=2 header_h=2

for aspect in portrait landscape; do
for total in 1 5 200; do
    sel=0; top=0
    for CG_COLS in $(seq 40 7 300); do
    for CG_ROWS in $(seq 15 5 80); do
        export CG_COLS CG_ROWS
        _cg_geom
        checks=$((checks+1))

        used=$(( 2*margin_x + ncols*card_w + (ncols-1)*gap_x ))
        residue=$(( term_cols - used ))
        [ "$used" -le "$term_cols" ]  || fail "overflow horizontal: used=$used > $term_cols"
        # tolerancia documentada: residuo de división entera queda en margen derecho, < ncols
        [ "$residue" -lt "$ncols" ]   || fail "padding muerto: residue=$residue >= ncols=$ncols"
        [ "$img_h" -ge 3 ]            || fail "img_h=$img_h < 3"
        [ "$vis_rows" -ge 1 ]         || fail "vis_rows=$vis_rows < 1"
        # la tarjeta cabe en el viewport (si hay espacio mínimo razonable)
        if [ $(( CG_ROWS - header_h )) -ge 9 ]; then
            [ "$card_h" -le $(( CG_ROWS - header_h )) ] || fail "card_h=$card_h no cabe en $((CG_ROWS-header_h))"
        fi
        [ "$ncols" -ge 1 ]            || fail "ncols=$ncols < 1"
        if [ "$ncols" -gt 1 ]; then
            [ "$card_w" -ge "$min_card_w" ] || fail "card_w=$card_w < min con ncols=$ncols"
        fi
        # clamps post-resize (sel/top venían de la geometría anterior)
        [ "$sel" -ge 0 ] && [ "$sel" -lt "$total" ] || fail "sel fuera de rango"
        sel_row=$(( sel / ncols ))
        [ "$sel_row" -ge "$top" ] || fail "sel arriba del viewport (sel_row=$sel_row top=$top)"
        [ "$sel_row" -le $(( top + vis_rows - 1 )) ] || fail "sel abajo del viewport"
        [ "$top" -ge 0 ] || fail "top negativo"

        # dejar sel/top "sucios" para el próximo combo (simula WINCH real)
        sel=$(( (sel + 7) % total ))
        top=$(( sel / ncols ))
    done
    done
done
done

rm -rf "$ANI_CLI_HIST_DIR"
printf 'geom: %d checks, %d fails\n' "$checks" "$fails"
exit "$fails"
