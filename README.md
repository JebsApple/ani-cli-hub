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
git clone https://github.com/JebsApple/ani-cli-hub
cd ani-cli-hub
./install.sh
```

El instalador verifica dependencias, instala core + wrapper, y ofrece activar las notificaciones.

Dependencias: `curl sed grep awk fzf mpv openssl` + `chafa` (thumbnails fallback) + [kitty](https://sw.kovidgoyal.net/kitty/) (grid con píxeles reales; opcional). `tmux` y `python3` solo para el harness de tests.

## Plataformas

| Plataforma | Soporte |
|---|---|
| Linux + Kitty | Completo (grid con imágenes reales) |
| Linux (otra terminal) | Completo — el grid usa fzf+chafa |
| Windows + WSL2 | Funciona (detecta mpv.exe); grid en modo fallback |
| Windows nativo | No — es un script bash |
| Notificaciones | Solo Linux con systemd + notify-send |

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
