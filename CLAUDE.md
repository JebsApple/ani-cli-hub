# ani-cli-mx — hub personal de anime en terminal

Fork de ani-cli con catálogo grid (kitty graphics), fuentes en español (jkanime/animeav1/animeflv) y verificación automatizada de UI.

## Estructura

- `ani-cli-mx-core` — script completo (fuente única). Se instala en `/usr/lib/ani-cli-mx/ani-cli-mx-core`.
- `t/` — harness de verificación de la UI grid (diseño: 3 capas).

## Correr

```bash
ani-cli-mx --browse     # hub con tabs (alias: anime) · f fav · w watchlist
ani-cli-mx --favs       # hub en tab Favoritos (alias: anime-favs)
ani-cli-mx --watchlist  # hub en tab Lista (alias: anime-list)
ani-cli-mx --recent     # hub en tab Recientes (alias: anime-new) · Enter = play directo
ani-cli-mx --schedule   # horario semanal standalone (alias: anime-week)
```

Hub (kitty): tabs `1 Catálogo · 2 Recientes · 3 Favoritos · 4 Lista · 5 Semana` — número salta, Tab cicla. Cancelar episodios vuelve al hub. Sin kitty: flujos fzf clásicos sin tabs.

## Estado y caché

- Favoritos: `~/.local/state/ani-cli-mx/ani-favs` (id\ttitle) · Watchlist: `ani-watchlist` (id\ttitle\testado)
- Caché: `~/.cache/ani-cli-mx/` — catalog.tsv (TTL 6h, fallback si red caída), thumbs/ y epthumbs/ inmutables. Borrar dir = refresh forzado.
- Notificaciones: `~/.local/bin/ani-notify` + timer user `ani-notify.timer` (30min) — avisa episodios nuevos de favs/watchlist(pendiente|viendo), dedup en cache/notified.tsv.
- Hook de teclas del grid: `CG_ON_KEY=<func>` — recibe (key, entry TSV), devuelve nueva línea 2.

## Deploy

```bash
bash -n ani-cli-mx-core && sudo cp ani-cli-mx-core /usr/lib/ani-cli-mx/ani-cli-mx-core \
  && sudo chmod 755 /usr/lib/ani-cli-mx/ani-cli-mx-core
```

## Verificar (correr tras CUALQUIER cambio al grid)

```bash
t/verify.sh
```

- **Capa 1** `t/geom.sh`: invariantes matemáticos de `_cg_geom` (3k+ combos de tamaño, clamps de resize simulados). Sin render.
- **Capa 2** `t/decode_grid.py`: oráculo — decodifica placeholders unicode de kitty (tabla en `t/diacritics.txt`, derivada con `t/calibrate.sh`) y valida encaje de imágenes, márgenes y rectángulos de tarjetas contra la geometría esperada.
- **Capa 3** `t/e2e.sh`: features end-to-end en tmux (navegación, scroll real, resize en vivo, payload de Enter, salida limpia con q).

## Convenciones del grid

- `show_card_grid data.tsv etiqueta [portrait|landscape]` — genérico; data: `img\tlinea1\tlinea2\tpayload`.
- `_cg_geom` es top-level (dynamic scoping) para ser testeable; `CG_COLS`/`CG_ROWS` inyectan dimensiones en tests.
- `ANI_MX_TEST=1` al sourcear: solo definiciones, no entra al main.
- ids de anime con prefijo de fuente (`jkanime:slug`) para que `episodes_list` no adivine por título.
- Imágenes con `--unicode-placeholder` (scrollean como texto con CSI S/T) + `--scale-up` (llenan el box).

## Decisiones registradas

- Residuo de división entera del ancho queda en el margen derecho (< ncols celdas). Tolerado y testeado.
- animeflv de capa caída (2026-07): TODO viene de jkanime — catálogo (horario dedup), recientes (home, cache 30min), thumbs de episodio (og:image). animeav1 es fallback de episodios/links; animeflv solo último recurso.
- Tabs del grid: `CG_TABS="A|B|C"` + `CG_TAB_ACTIVE=n` → barra en línea 0, teclas 1-9/Tab emiten `TAB:n` como payload.
- Sin píxeles en tests: el escalado interno es de icat (upstream); lo nuestro — rectángulos de celdas — se verifica completo vía placeholders.
