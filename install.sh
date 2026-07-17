#!/bin/bash
# Instalador de ani-cli-hub — Linux (o WSL2). Correr desde el clon del repo.
set -e
cd "$(dirname "$0")"

echo "→ Verificando dependencias..."
missing=""
for dep in curl sed grep awk fzf mpv openssl; do
    command -v "$dep" >/dev/null || missing="$missing $dep"
done
command -v chafa >/dev/null || echo "  aviso: sin chafa no hay thumbnails en terminales no-kitty"
command -v kitten >/dev/null || echo "  aviso: sin kitty el catálogo usa el modo fzf (funcional, menos visual)"
if [ -n "$missing" ]; then
    echo "  FALTAN:$missing — instalalos con tu package manager y reintenta"
    exit 1
fi

echo "→ Instalando core y wrapper..."
sudo mkdir -p /usr/lib/ani-cli-mx
sudo cp ani-cli-mx-core /usr/lib/ani-cli-mx/ani-cli-mx-core
sudo chmod 755 /usr/lib/ani-cli-mx/ani-cli-mx-core
sudo cp extras/ani-cli-mx-wrapper /usr/bin/ani-cli-mx
sudo chmod 755 /usr/bin/ani-cli-mx

if [ -d "$HOME/.config/systemd/user" ] && command -v systemctl >/dev/null && command -v notify-send >/dev/null; then
    read -r -p "→ ¿Instalar notificaciones de episodios nuevos? [s/N] " ans
    if [ "$ans" = "s" ] || [ "$ans" = "S" ]; then
        mkdir -p "$HOME/.local/bin"
        cp extras/ani-notify "$HOME/.local/bin/" && chmod +x "$HOME/.local/bin/ani-notify"
        cp extras/ani-notify.service extras/ani-notify.timer "$HOME/.config/systemd/user/"
        systemctl --user daemon-reload
        systemctl --user enable --now ani-notify.timer
        echo "  timer activo (cada 30min)"
    fi
fi

echo "✓ Listo. Probá: ani-cli-mx --browse"
