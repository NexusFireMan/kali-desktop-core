#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$ROOT_DIR/config"
THEMES_DIR="$ROOT_DIR/themes"
SCRIPTS_SRC="$ROOT_DIR/scripts"
WALLPAPERS_SRC="$ROOT_DIR/wallpapers"
BACKUP_DIR="${HOME}/.config/kali-desktop-core/backups/$(date +%Y%m%d-%H%M%S)"
GOMAP_KEYRING_URL="https://nexusfireman.github.io/gomap/gomap-archive-keyring.gpg"
GOMAP_KEYRING_PATH="/usr/share/keyrings/gomap-archive-keyring.gpg"
GOMAP_REPO_LINE="deb [signed-by=/usr/share/keyrings/gomap-archive-keyring.gpg] https://nexusfireman.github.io/gomap stable main"
GOMAP_REPO_FILE="/etc/apt/sources.list.d/gomap.list"
THEME_NAME="default"
INSTALL_CONFIGS=0
INSTALL_THEME=0
INSTALL_FULL=0

PACKAGES=(
  i3-wm
  i3lock
  dmenu
  lemonbar
  kitty
  zsh
  feh
  iproute2
  procps
  x11-xserver-utils
  xclip
  curl
  git
  gnupg
  mawk
  sed
  grep
)

print_help() {
  cat <<'EOF'
Uso: ./install.sh [opciones]

Opciones:
  --full               Instala dependencias, configuraciones y theme
  --configs            Instala solo configuraciones y scripts
  --theme <nombre>     Cambia el theme tras una instalación base
  --help               Muestra esta ayuda

Themes disponibles:
  default
  kali-zen
  katana

Ejemplos:
  ./install.sh --full
  ./install.sh --full --theme kali-zen
  ./install.sh --configs
  ./install.sh --theme kali-zen
EOF
}

log() {
  printf '[*] %s\n' "$1"
}

warn() {
  printf '[!] %s\n' "$1"
}

die() {
  printf '[x] %s\n' "$1" >&2
  exit 1
}

ensure_dirs() {
  mkdir -p \
    "${HOME}/.config" \
    "${HOME}/.config/i3" \
    "${HOME}/.config/kitty" \
    "${HOME}/.config/starship" \
    "${HOME}/.config/zsh" \
    "${HOME}/.local/bin" \
    "${HOME}/.local/share/kali-desktop-core" \
    "${HOME}/.local/share/kali-desktop-core/themes" \
    "${HOME}/.local/share/kali-desktop-core/wallpapers"
}

backup_path() {
  local target="$1"

  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp -a "$target" "$BACKUP_DIR/"
    log "Backup creado para $target en $BACKUP_DIR"
  fi
}

install_packages() {
  if command -v apt-get >/dev/null 2>&1; then
    log "Instalando dependencias con apt-get"
    sudo apt-get update
    sudo apt-get install -y "${PACKAGES[@]}"
    install_gomap
  else
    warn "No se encontró apt-get. Instala manualmente: ${PACKAGES[*]}"
    warn "gomap requiere registrar el repositorio APT: $GOMAP_REPO_LINE"
  fi

  if ! command -v starship >/dev/null 2>&1; then
    log "Instalando starship"
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
  fi
}

install_gomap() {
  log "Registrando repositorio APT de gomap"
  curl -fsSL "$GOMAP_KEYRING_URL" | sudo gpg --dearmor --yes -o "$GOMAP_KEYRING_PATH"
  printf '%s\n' "$GOMAP_REPO_LINE" | sudo tee "$GOMAP_REPO_FILE" > /dev/null

  log "Instalando gomap"
  sudo apt-get update
  sudo apt-get install -y gomap
}

copy_configs() {
  log "Copiando configuraciones base"

  backup_path "${HOME}/.config/i3/config"
  backup_path "${HOME}/.config/kitty/kitty.conf"
  backup_path "${HOME}/.config/kitty/theme.conf"
  backup_path "${HOME}/.zshrc"
  backup_path "${HOME}/.config/starship.toml"

  install -m 0644 "$CONFIG_SRC/i3/config" "${HOME}/.config/i3/config"
  install -m 0644 "$CONFIG_SRC/kitty/kitty.conf" "${HOME}/.config/kitty/kitty.conf"
  install -m 0644 "$CONFIG_SRC/zsh/.zshrc" "${HOME}/.zshrc"
  install -m 0644 "$CONFIG_SRC/starship/starship.toml" "${HOME}/.config/starship.toml"

  mkdir -p "${HOME}/.config/dmenu"
  install -m 0644 "$CONFIG_SRC/dmenu/config" "${HOME}/.config/dmenu/config"

  log "Copiando scripts"
  install -m 0755 "$SCRIPTS_SRC/bar.sh" "${HOME}/.local/bin/kdc-bar"
  install -m 0755 "$SCRIPTS_SRC/dmenu.sh" "${HOME}/.local/bin/kdc-dmenu"
  install -m 0755 "$SCRIPTS_SRC/network.sh" "${HOME}/.local/bin/kdc-network"
  install -m 0755 "$SCRIPTS_SRC/target.sh" "${HOME}/.local/bin/kdc-target"
  install -m 0755 "$SCRIPTS_SRC/gomap.sh" "${HOME}/.local/bin/kdc-gomap"
  install -m 0755 "$SCRIPTS_SRC/utils.sh" "${HOME}/.local/bin/kdc-utils"

  cp -a "$SCRIPTS_SRC" "${HOME}/.local/share/kali-desktop-core/"
}

apply_theme() {
  local theme="$1"
  local theme_dir="$THEMES_DIR/$theme"
  local wallpaper_file=""

  [[ -d "$theme_dir" ]] || die "El theme '$theme' no existe"

  if [[ $INSTALL_FULL -eq 0 && $INSTALL_CONFIGS -eq 0 && ! -x "${HOME}/.local/bin/kdc-bar" ]]; then
    die "Antes de usar --theme debes hacer una instalación base con './install.sh --full' o './install.sh --configs'."
  fi

  log "Aplicando theme: $theme"

  mkdir -p "${HOME}/.config/kali-desktop-core"
  backup_path "${HOME}/.config/kali-desktop-core/theme.conf"
  backup_path "${HOME}/.config/kali-desktop-core/current-theme"

  install -m 0644 "$theme_dir/theme.conf" "${HOME}/.config/kali-desktop-core/theme.conf"
  printf '%s\n' "$theme" > "${HOME}/.config/kali-desktop-core/current-theme"

  cp -a "$theme_dir" "${HOME}/.local/share/kali-desktop-core/themes/"

  if [[ -f "$theme_dir/kitty.theme.conf" ]]; then
    install -m 0644 "$theme_dir/kitty.theme.conf" "${HOME}/.config/kitty/theme.conf"
  fi

  cp -a "$WALLPAPERS_SRC/." "${HOME}/.local/share/kali-desktop-core/wallpapers/" 2>/dev/null || true

  wallpaper_file="$(awk -F'"' '/^WALLPAPER=/{print $2}' "$theme_dir/theme.conf" | head -n1)"
  if [[ -n "$wallpaper_file" && -f "$theme_dir/$wallpaper_file" ]]; then
    install -m 0644 "$theme_dir/$wallpaper_file" "${HOME}/.local/share/kali-desktop-core/wallpapers/${theme}.${wallpaper_file##*.}"
    printf '%s\n' "${HOME}/.local/share/kali-desktop-core/wallpapers/${theme}.${wallpaper_file##*.}" > "${HOME}/.config/kali-desktop-core/current-wallpaper"
  else
    : > "${HOME}/.config/kali-desktop-core/current-wallpaper"
  fi
}

parse_args() {
  if [[ $# -eq 0 ]]; then
    INSTALL_FULL=1
    return
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --full)
        INSTALL_FULL=1
        shift
        ;;
      --configs)
        INSTALL_CONFIGS=1
        shift
        ;;
      --theme)
        [[ $# -ge 2 ]] || die "Debes indicar un theme tras --theme"
        THEME_NAME="$2"
        INSTALL_THEME=1
        shift 2
        ;;
      --help|-h)
        print_help
        exit 0
        ;;
      *)
        die "Opción desconocida: $1"
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  ensure_dirs

  if [[ $INSTALL_FULL -eq 1 ]]; then
    install_packages
    copy_configs
    apply_theme "$THEME_NAME"
  else
    if [[ $INSTALL_CONFIGS -eq 1 ]]; then
      copy_configs
    fi

    if [[ $INSTALL_THEME -eq 1 ]]; then
      apply_theme "$THEME_NAME"
    fi

    if [[ $INSTALL_CONFIGS -eq 0 && $INSTALL_THEME -eq 0 ]]; then
      die "No se seleccionó ninguna acción. Usa --help para ver opciones."
    fi
  fi

  log "Instalación completada"
  log "Recomendado: cerrar sesión y volver a entrar en i3"
}

main "$@"
