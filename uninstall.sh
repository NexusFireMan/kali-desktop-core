#!/usr/bin/env bash
set -euo pipefail

TARGETS=(
  "${HOME}/.config/i3/config"
  "${HOME}/.config/kitty/kitty.conf"
  "${HOME}/.config/kitty/theme.conf"
  "${HOME}/.config/alacritty/alacritty.toml"
  "${HOME}/.config/alacritty/theme.toml"
  "${HOME}/.config/dmenu/config"
  "${HOME}/.zshrc"
  "${HOME}/.config/starship.toml"
  "${HOME}/.config/kali-desktop-core"
  "${HOME}/.local/bin/kdc-bar"
  "${HOME}/.local/bin/kdc-dmenu"
  "${HOME}/.local/bin/kdc-network"
  "${HOME}/.local/bin/kdc-target"
  "${HOME}/.local/bin/kdc-gomap"
  "${HOME}/.local/bin/kdc-utils"
  "${HOME}/.local/share/kali-desktop-core"
)

printf 'Este script eliminará la instalación local de Kali Desktop Core.\n'
read -r -p '¿Continuar? [y/N]: ' answer

if [[ ! "$answer" =~ ^[Yy]$ ]]; then
  printf 'Cancelado.\n'
  exit 0
fi

for path in "${TARGETS[@]}"; do
  if [[ -e "$path" || -L "$path" ]]; then
    rm -rf "$path"
    printf '[*] Eliminado: %s\n' "$path"
  fi
done

printf '[*] Desinstalación completada.\n'
printf '[*] Si hiciste backups con install.sh, puedes restaurarlos desde ~/.config/kali-desktop-core/backups\n'
