<p align="center">
  <a href="https://github.com/JebsApple/ani-cli-hub/blob/master/LICENSE">
    <img src="https://img.shields.io/badge/license-GPL--3.0-blue.svg" alt="License: GPL-3.0">
  </a>
  <a href="#linux">
    <img src="https://img.shields.io/badge/os-linux-brightgreen.svg" alt="Linux">
  </a>
  <a href="#wsl2">
    <img src="https://img.shields.io/badge/os-wsl2-brightgreen.svg" alt="WSL2">
  </a>
  <a href="#windows-nativo">
    <img src="https://img.shields.io/badge/os-windows-yellowgreen.svg" alt="Windows">
  </a>
  <a href="#macos">
    <img src="https://img.shields.io/badge/os-mac-yellowgreen.svg" alt="macOS">
  </a>
  <br>
  <a href="http://makeapullrequest.com">
    <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs welcome">
  </a>
</p>

<h1 align="center">ani-cli-hub</h1>

<p align="center">
  <b>Hub personal de anime en la terminal</b><br>
  Fork de <a href="https://github.com/Gildedboy/ani-cli-mx">ani-cli-mx</a> con catálogo visual, favoritos, watchlist y notificaciones.
</p>

---

## Qué es

ani-cli-hub es un fork de [ani-cli-mx](https://github.com/Gildedboy/ani-cli-mx) (que a su vez es fork de [ani-cli](https://github.com/pystardust/ani-cli)) que agrega:

- **Catálogo grid** con portadas reales (kitty graphics protocol) y fallback fzf+chafa
- **Selector de episodios con miniaturas** por capítulo
- **Favoritos y watchlist** desde el grid
- **Notificaciones** de episodios nuevos (systemd user timer)
- **Horario semanal** y **episodios recientes** con thumbnails
- **Caché persistente** (arranque en caliente ~0.4s)
- **Harness de verificación de UI** (3 capas: geometría, oráculo visual, E2E)

Fuentes de anime en español: jkanime, animeflv, animeav1.

---

## Tabla de contenidos

- [Tengo un error](#tengo-un-error)
- [Instalación](#instalación)
  - [Linux](#linux)
  - [WSL2](#wsl2)
  - [Windows nativo](#windows-nativo)
  - [macOS](#macos)
- [Desinstalación](#desinstalación)
- [Uso](#uso)
- [Dependencias](#dependencias)
- [FAQ](#faq)
- [Contribuir](#contribuir)
- [Créditos](#créditos)
- [Licencia](#licencia)
- [English](#english)

---

## Tengo un error

**Actualizá antes de todo:**

```bash
ani-cli-mx -U
```

Si el problema persiste, los errores más comunes son:

| Error | Causa | Solución |
|-------|-------|----------|
| `No results found` | Versión vieja o fuente caída | `ani-cli-mx -U` para actualizar |
| `mpv: not found` | mpv no está instalado o no está en PATH | Ver [instalación por plataforma](#instalación) |
| `fzf: not found` | fzf no está instalado | `sudo apt install fzf` (Linux) o `scoop install fzf` (Windows) |
| `kitty: not found` | kitty no instalado (no es obligatorio) | Instalar kitty o usar sin grid (fzf fallback) |
| `Permission denied` en install.sh | Falta sudo | Correr con `sudo` o verificar permisos |
| Grid no muestra imágenes | Terminal sin soporte kitty graphics | Instalar [kitty](https://sw.kovidgoyal.net/kitty/) o aceptar fallback fzf+chafa |

Si nada funciona, [abrí un issue](https://github.com/JebsApple/ani-cli-hub/issues/new) con tu OS, terminal y output del error.

---

## Instalación

### Linux

**Requisitos:** bash, sudo, conexión a internet.

```bash
git clone https://github.com/JebsApple/ani-cli-hub.git
cd ani-cli-hub
./install.sh
```

El instalador:
1. Verifica dependencias (curl, sed, grep, awk, fzf, mpv, openssl)
2. Instala core en `/usr/lib/ani-cli-mx/` y wrapper en `/usr/bin/ani-cli-mx`
3. Pregunta si querés activar notificaciones de episodios nuevos

**Si faltan dependencias**, el instalador te dice cuáles instalar. En Debian/Ubuntu:

```bash
sudo apt install curl sed grep awk fzf mpv openssl chafa
```

En Arch:

```bash
sudo pacman -S curl sed grep awk fzf mpv openssl chafa
```

Kitty es opcional. Sin kitty, el catálogo usa fzf+chafa (funcional, menos visual).

### WSL2

**IMPORTANTE:** mpv se instala en **Windows**, no dentro de WSL. WSL no tiene acceso directo a la pantalla, pero puede invocar mpv.exe de Windows.

**Paso 1 — Instalar mpv en Windows**

Abrí PowerShell (o Git Bash en Windows) y corré:

```bash
scoop install mpv
```

Si no tenés scoop, instalalo primero: https://scoop.sh/

Verificá que mpv funcione desde Windows:

```bash
mpv --version
```

**Paso 2 — Asegurar que mpv esté en el PATH de Windows**

Desde PowerShell:

```powershell
$env:Path -split ";" | Select-String "mpv"
```

Si no aparece, agregá la carpeta de mpv al PATH del sistema (Panel de Control → Sistema → Variables de entorno → Path → Editar → Nuevo).

**Paso 3 — Instalar ani-cli-hub en WSL**

Abrí tu terminal WSL y corré:

```bash
sudo apt install curl sed grep awk fzf openssl chafa
git clone https://github.com/JebsApple/ani-cli-hub.git
cd ani-cli-hub
./install.sh
```

**Paso 4 — Probar**

```bash
ani-cli-mx --browse
```

Si mpv no se encuentra desde WSL, verificá que el PATH incluya la ruta de Windows:

```bash
export PATH="$PATH:/c/Users/TU_USUARIO/scoop/shims"
```

Agregá esa línea a tu `~/.bashrc` para que sea permanente.

**Nota:** kitty graphics no funciona en WSL. El grid usa fallback fzf+chafa automáticamente.

### Windows nativo

ani-cli-hub necesita bash para funcionar. En Windows, se usa **Git Bash** (viene con Git for Windows).

**Paso 1 — Instalar Scoop**

Abrí PowerShell y corré:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

**Paso 2 — Instalar Git (con Git Bash)**

```powershell
scoop install git
```

Si ya tenés Git instalado de otra forma, asegurate de que `bash.exe` esté disponible. La ruta típica es `C:\Program Files\Git\bin\bash.exe`.

**Paso 3 — Configurar Windows Terminal**

1. Abrí Windows Terminal
2. Hacé click en la flechita junto al botón de pestaña nueva → **Settings**
3. **Profiles** → **Add a new profile** → **New empty profile**
4. Configurá:
   - **Name:** `Git Bash`
   - **Command line:** `C:\Program Files\Git\bin\bash.exe -i -l`
   - **Starting directory:** `%USERPROFILE%`
5. Guardá y cerrá settings

Si instalaste Git con scoop, usá `%GIT_INSTALL_ROOT%\bin\bash.exe -i -l` en lugar de la ruta manual.

**Paso 4 — Instalar dependencias**

Abrí la pestaña **Git Bash** en Windows Terminal y corré:

```bash
scoop install fzf mpv openssl
```

**Paso 5 — Instalar ani-cli-hub**

En Git Bash:

```bash
git clone https://github.com/JebsApple/ani-cli-hub.git
cd ani-cli-hub
./install.sh
```

**Paso 6 — Probar**

```bash
ani-cli-mx --browse
```

**Problemas conocidos en Windows:**

- **fzf se traba en "Search anime:"**: Usá Windows Terminal, no el terminal Git Bash (mintty). Si insistís con mintty, corré `export MSYS=enable_pcon` antes de ani-cli.
- **"No such file or directory"**: Estás ejecutando en PowerShell/CMD, no en Git Bash. Abrí la pestaña Git Bash.
- **curl viejo**: ani-cli necesita curl ≥ 7.86.0. Actualizá con `scoop update curl`.

### macOS

```bash
brew install fzf mpv openssl
git clone https://github.com/JebsApple/ani-cli-hub.git
cd ani-cli-hub
./install.sh
```

Si no tenés Homebrew: https://brew.sh/

---

## Desinstalación

**Linux / WSL2 / macOS:**

```bash
sudo rm -f /usr/lib/ani-cli-mx/ani-cli-mx-core
sudo rm -f /usr/bin/ani-cli-mx
```

**Limpiar datos locales** (favoritos, caché, notificaciones):

```bash
rm -rf ~/.cache/ani-cli-mx ~/.local/state/ani-cli-mx
rm -f ~/.local/bin/ani-notify
systemctl --user disable --now ani-notify.timer 2>/dev/null
systemctl --user disable --now ani-notify.service 2>/dev/null
systemctl --user daemon-reload 2>/dev/null
```

**Windows (Git Bash):**

```bash
rm -f /usr/lib/ani-cli-mx/ani-cli-mx-core
rm -f /usr/bin/ani-cli-mx
rm -rf ~/.cache/ani-cli-mx ~/.local/state/ani-cli-mx
```

---

## Uso

```bash
ani-cli-mx --browse       # Catálogo grid con portadas
ani-cli-mx --favs         # Solo favoritos
ani-cli-mx --watchlist    # Solo watchlist
ani-cli-mx --recent       # Episodios recientes
ani-cli-mx --schedule     # Horario semanal
```

**Atajos en el grid (modo kitty):**

| Tecla | Acción |
|-------|--------|
| `f` | Agregar/quitar de favoritos |
| `w` | Agregar/quitar de watchlist |
| `Enter` | Ver episodios del anime seleccionado |
| `q` | Salir |
| `Tab` | Cambiar de pestaña (Catálogo/Recientes/Favoritos/Lista/Semana) |
| `1`-`5` | Saltar a pestaña específica |

**Sin kitty graphics:** el grid usa fzf con thumbnails vía chafa. Funcional, menos visual pero completamente usable.

**Variables de entorno:**

| Variable | Descripción | Default |
|----------|-------------|---------|
| `ANI_CLI_PLAYER` | Reproductor | `mpv` |
| `ANI_CLI_DOWNLOAD_DIR` | Carpeta de descargas | directorio actual |

---

## Dependencias

| Paquete | Requerido | Qué hace |
|---------|-----------|----------|
| `curl` | Sí | Descarga de páginas y streams |
| `sed` | Sí | Parsing de HTML |
| `grep` | Sí | Búsqueda en contenido |
| `awk` | Sí | Procesamiento de texto |
| `fzf` | Sí | Interfaz de selección |
| `mpv` | Sí | Reproductor de video |
| `openssl` | Sí | Descifrado de fuentes encriptadas |
| `chafa` | No | Thumbnails en terminales sin kitty |
| `kitty` | No | Grid visual con imágenes reales (kitty graphics protocol) |
| `tmux` | No | Solo para harness de tests |
| `python3` | No | Solo para harness de tests |

---

## FAQ

**Puedo cambiar el idioma de los subtítulos?**
No, los subtítulos vienen integrados en el video.

**Puedo ver en inglés (dub)?**
Sí, usá `--dub`.

**Puedo cambiar la calidad?**
Sí, usá `-q 1080` (o 720, 480, etc.).

**Funciona en Android?**
No directamente. Para Android usá [ani-cli original](https://github.com/pystardust/ani-cli) con Termux.

**Puedo descargar episodios?**
Sí, usá `-d` para descargar al directorio actual, o seteá `ANI_CLI_DOWNLOAD_DIR`.

**Borro la caché, se pierde algo?**
Solo los thumbnails. Se regeneran automáticamente al navegar.

**Las notificaciones funcionan en macOS?**
No, las notificaciones usan systemd (Linux/WSL2 con systemd).

**Puedo usar VLC en vez de mpv?**
Sí, usá `--vlc` o seteá `export ANI_CLI_PLAYER=vlc`.

---

## Contribuir

1. Hacé fork y create una rama (`git checkout -b feature/nueva-feature`)
2. Si tocás el grid, corré `t/verify.sh` antes de push
3. `bash -n ani-cli-mx-core` para verificar sintaxis
4. Abrí un PR con descripción clara del cambio

**Convenciones:**
- Comentarios del grid en inglés
- IDs de anime con prefijo de fuente (`jkanime:slug`)
- Variables del grid: `CG_*` (upper snake case)

---

## Créditos

- [pystardust/ani-cli](https://github.com/pystardust/ani-cli) — el original. Toda la arquitectura de scraping/reproducción viene de ahí.
- [Gildedboy/ani-cli-mx](https://github.com/Gildedboy/ani-cli-mx) — fork con fuentes en español (jkanime, animeav1, animeflv), base directa de este proyecto.

---

## Licencia

GPL-3.0 — igual que los proyectos originales. Ver [LICENSE](LICENSE).

---

<br>

<details>
<summary><b>English</b></summary>

### What is ani-cli-hub?

A personal anime hub for the terminal. Fork of [ani-cli-mx](https://github.com/Gildedboy/ani-cli-mx) (which is itself a fork of [ani-cli](https://github.com/pystardust/ani-cli)) adding:

- **Visual catalog grid** with real cover art (kitty graphics protocol) and fzf+chafa fallback
- **Episode selector with thumbnails** per episode
- **Favorites and watchlist** from the grid
- **Notifications** for new episodes (systemd user timer)
- **Weekly schedule** and **recent episodes** with thumbnails
- **Persistent cache** (hot start ~0.4s)
- **UI verification harness** (3 layers: geometry, visual oracle, E2E)

Anime sources in Spanish: jkanime, animeflv, animeav1.

### Quick Install

**Linux:**
```bash
git clone https://github.com/JebsApple/ani-cli-hub.git
cd ani-cli-hub
./install.sh
```

**WSL2:** Install mpv on Windows first (via scoop), then run the Linux install inside WSL.

**Windows:** Install Scoop → Git → fzf/mpv via scoop → open Git Bash → clone and run `./install.sh`. See [full Windows instructions](#windows-nativo).

**macOS:**
```bash
brew install fzf mpv openssl
git clone https://github.com/JebsApple/ani-cli-hub.git
cd ani-cli-hub
./install.sh
```

### Usage

```bash
ani-cli-mx --browse       # Visual catalog grid
ani-cli-mx --favs         # Favorites only
ani-cli-mx --watchlist    # Watchlist only
ani-cli-mx --recent       # Recent episodes
ani-cli-mx --schedule     # Weekly schedule
```

**Grid shortcuts:** `f` favorite, `w` watchlist, `Enter` play, `q` quit, `Tab` switch tab.

### Dependencies

`curl` `sed` `grep` `awk` `fzf` `mpv` `openssl` (required) · `chafa` `kitty` (optional, for thumbnails/grid)

### License

GPL-3.0 — see [LICENSE](LICENSE).

</details>
