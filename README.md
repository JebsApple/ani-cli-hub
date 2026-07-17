# ani-cli-hub

Hub personal de anime en la terminal. Fork de [ani-cli-mx](https://github.com/Gildedboy/ani-cli-mx) (fuentes en español), que a su vez es fork de [ani-cli](https://github.com/pystardust/ani-cli).

Lo que agrega este fork:

- **Catálogo grid** (`--browse`): tarjetas con portada real (kitty graphics protocol), scroll continuo, responsive en vivo al tamaño de ventana. Fallback fzf+chafa en terminales sin kitty.
- **Selector de episodios con miniaturas** por capítulo (multi-fuente: jkanime → animeflv).
- **Favoritos y watchlist** desde el grid (teclas `f`/`w`), con flags `--favs`/`--watchlist`.
- **Notificaciones** de episodios nuevos (systemd user timer + notify-send).
- **Horario semanal** (`--schedule`) y **recientes** (`--recent`) con thumbnails.
- **Caché persistente** (arranque en caliente ~0.4s).
- **Harness de verificación de UI** (`t/verify.sh`): invariantes de geometría, decodificación de placeholders unicode de kitty como oráculo visual, y E2E con tmux.

## Instalación

```bash
sudo cp ani-cli-mx-core /usr/lib/ani-cli-mx/ani-cli-mx-core
sudo chmod 755 /usr/lib/ani-cli-mx/ani-cli-mx-core
# opcional: notificaciones
cp extras/ani-notify ~/.local/bin/ && chmod +x ~/.local/bin/ani-notify
cp extras/ani-notify.{service,timer} ~/.config/systemd/user/
systemctl --user enable --now ani-notify.timer
```

Dependencias: las de ani-cli-mx + `chafa` (fallback) + `kitty` (grid con píxeles reales) + `tmux` y `python3` (solo para el harness).

## Uso

```bash
ani-cli-mx --browse      # catálogo grid · f = favorito · w = watchlist
ani-cli-mx --favs        # solo favoritos
ani-cli-mx --watchlist   # solo watchlist
ani-cli-mx --schedule    # horario semanal
ani-cli-mx --recent      # episodios recientes
```

## Verificación

```bash
t/verify.sh   # 3 capas: geometría, oráculo de placeholders, E2E
```

## Créditos

- [pystardust/ani-cli](https://github.com/pystardust/ani-cli) — el original. Toda la arquitectura de scraping/reproducción viene de ahí.
- [Gildedboy/ani-cli-mx](https://github.com/Gildedboy/ani-cli-mx) — fork con fuentes en español (jkanime, animeav1, animeflv), base directa de este proyecto.

## Licencia

GPL-3.0 — igual que los proyectos originales. Ver [LICENSE](LICENSE).
