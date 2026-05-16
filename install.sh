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
PROFILE_NAME="vm"
INSTALL_FULL=0
INSTALL_CONFIGS=0
INSTALL_THEME=0
INTERACTIVE=0
DRY_RUN=0
NO_CONFIRM=0
RUN_DOCTOR=0
WITH_GOMAP="auto"
WITH_STARSHIP="auto"
WITH_DOCKER="auto"
WITH_LOGIN_THEME="auto"
NO_ARGS=0

HAS_APT=0
OS_ID="unknown"
OS_LIKE=""
SESSION_TYPE="unknown"
DISPLAY_MANAGER="unknown"
LOCAL_BIN_IN_PATH=0
RUNNING_AS_ROOT=0

PACKAGES=()
CONFIG_TARGETS=()
BACKUP_TARGETS=()
SCRIPT_TARGETS=()
SUDO_ACTIONS=()

CORE_PACKAGES=(
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

DOCKER_PACKAGES=(
  docker.io
  docker-compose
)

print_header() {
  printf '\n'
  printf 'Kali Desktop Core installer\n'
  printf '===========================\n'
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

is_command() {
  command -v "$1" >/dev/null 2>&1
}

confirm() {
  local prompt="$1"
  local default="${2:-n}"
  local answer suffix

  if [[ $NO_CONFIRM -eq 1 ]]; then
    return 0
  fi

  if [[ "$default" == "y" ]]; then
    suffix="[Y/n]"
  else
    suffix="[y/N]"
  fi

  read -r -p "$prompt $suffix: " answer
  answer="${answer:-$default}"

  [[ "$answer" =~ ^[Yy]$ ]]
}

dry_run_or_exec() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

dry_run_or_shell() {
  local description="$1"
  local command_text="$2"

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] %s\n' "$description"
    printf '          %s\n' "$command_text"
  else
    bash -c "$command_text"
  fi
}

print_help() {
  cat <<'EOF'
Uso: ./install.sh [opciones]

Compatibilidad:
  --full                         Instala dependencias, configuraciones y theme
  --configs                      Instala solo configuraciones y scripts
  --theme <nombre>               Cambia el theme tras una instalación base
  --help, -h                     Muestra esta ayuda

Nuevas opciones:
  --interactive                  Menú TUI simple basado en read
  --dry-run                      Muestra el plan sin modificar el sistema
  --with-gomap                   Registra el repo APT de gomap e instala gomap
  --without-gomap                No instala gomap
  --with-starship                Instala starship con el instalador oficial
  --without-starship             No instala starship externo
  --with-docker                  Instala docker.io y docker-compose
  --without-docker               No instala Docker
  --login-theme                  Aplica tema de login si LightDM está disponible
  --without-login-theme          No aplica tema de login
  --run-doctor                   Ejecuta kdc-doctor al final si existe
  --no-confirm                   No pide confirmación del plan
  --profile <perfil>             minimal, vm, htb, bugbounty o custom

Ejemplos:
  ./install.sh
  ./install.sh --full --theme kali-zen
  ./install.sh --full --theme kali-zen --with-gomap --with-starship
  ./install.sh --full --profile htb --with-docker
  ./install.sh --dry-run --login-theme
  ./install.sh --configs --dry-run
  ./install.sh --theme katana --dry-run
  ./install.sh --interactive
EOF
}

list_themes() {
  local theme_dir

  [[ -d "$THEMES_DIR" ]] || return 0
  for theme_dir in "$THEMES_DIR"/*; do
    [[ -d "$theme_dir" ]] || continue
    printf '%s\n' "$(basename "$theme_dir")"
  done
}

theme_exists() {
  [[ -d "$THEMES_DIR/$1" ]]
}

validate_profile() {
  case "$PROFILE_NAME" in
    minimal|vm|htb|bugbounty|custom)
      ;;
    *)
      die "Perfil no válido: $PROFILE_NAME"
      ;;
  esac
}

validate_theme() {
  if ! theme_exists "$THEME_NAME"; then
    warn "Themes disponibles:"
    list_themes | sed 's/^/  - /'
    die "El theme '$THEME_NAME' no existe"
  fi
}

detect_system() {
  HAS_APT=0
  LOCAL_BIN_IN_PATH=0
  RUNNING_AS_ROOT=0
  OS_ID="unknown"
  OS_LIKE=""
  SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"

  is_command apt-get && HAS_APT=1
  [[ ":$PATH:" == *":${HOME}/.local/bin:"* ]] && LOCAL_BIN_IN_PATH=1
  [[ "$(id -u)" -eq 0 ]] && RUNNING_AS_ROOT=1

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_LIKE="${ID_LIKE:-}"
  fi
}

detect_display_manager() {
  local dm_file="/etc/X11/default-display-manager"
  local dm_path dm_name

  if [[ -r "$dm_file" ]]; then
    dm_path="$(tr -d '[:space:]' < "$dm_file")"
    dm_name="$(basename "$dm_path")"
    case "$dm_name" in
      lightdm|gdm3|sddm|lxdm)
        printf '%s\n' "$dm_name"
        return 0
        ;;
    esac
  fi

  if is_command systemctl; then
    for dm_name in lightdm gdm3 sddm lxdm; do
      if systemctl is-active --quiet "$dm_name" 2>/dev/null; then
        printf '%s\n' "$dm_name"
        return 0
      fi
    done
  fi

  printf 'unknown\n'
}

select_profile_interactive() {
  local answer

  printf '\nPerfil:\n'
  printf '  1) minimal\n'
  printf '  2) vm\n'
  printf '  3) htb\n'
  printf '  4) bugbounty\n'
  printf '  5) custom\n'
  read -r -p 'Selecciona perfil [2]: ' answer
  answer="${answer:-2}"

  case "$answer" in
    1|minimal) PROFILE_NAME="minimal" ;;
    2|vm) PROFILE_NAME="vm" ;;
    3|htb) PROFILE_NAME="htb" ;;
    4|bugbounty) PROFILE_NAME="bugbounty" ;;
    5|custom) PROFILE_NAME="custom" ;;
    *) die "Selección de perfil no válida: $answer" ;;
  esac
}

select_theme_interactive() {
  local answer themes theme index selected

  printf '\nThemes disponibles:\n'
  index=1
  themes=()
  while IFS= read -r theme; do
    themes+=("$theme")
    printf '  %s) %s\n' "$index" "$theme"
    index=$((index + 1))
  done < <(list_themes)

  [[ ${#themes[@]} -gt 0 ]] || die "No hay themes disponibles en $THEMES_DIR"
  read -r -p "Selecciona theme [default]: " answer
  answer="${answer:-default}"

  if [[ "$answer" =~ ^[0-9]+$ ]]; then
    selected=$((answer - 1))
    [[ $selected -ge 0 && $selected -lt ${#themes[@]} ]] || die "Selección de theme no válida: $answer"
    THEME_NAME="${themes[$selected]}"
  else
    THEME_NAME="$answer"
  fi
}

select_extras_interactive() {
  local gomap_default starship_default docker_default

  gomap_default="n"
  case "$PROFILE_NAME" in
    htb|bugbounty) gomap_default="y" ;;
  esac

  starship_default="n"
  if ! is_command starship; then
    starship_default="y"
  fi

  if confirm "¿Instalar gomap desde el repositorio APT de nexusfireman?" "$gomap_default"; then
    WITH_GOMAP="yes"
  else
    WITH_GOMAP="no"
  fi

  docker_default="n"
  case "$PROFILE_NAME" in
    htb|bugbounty) docker_default="y" ;;
  esac

  if confirm "¿Instalar Docker desde los paquetes del sistema?" "$docker_default"; then
    WITH_DOCKER="yes"
  else
    WITH_DOCKER="no"
  fi

  if confirm "¿Instalar starship con el instalador oficial si no existe?" "$starship_default"; then
    WITH_STARSHIP="yes"
  else
    WITH_STARSHIP="no"
  fi

  if confirm "¿Aplicar tema de pantalla de login si LightDM está disponible?" "n"; then
    WITH_LOGIN_THEME="yes"
  else
    WITH_LOGIN_THEME="no"
  fi

  if confirm "¿Ejecutar kdc-doctor al final si existe?" "n"; then
    RUN_DOCTOR=1
  fi
}

run_interactive_menu() {
  print_header
  INSTALL_FULL=1
  INSTALL_CONFIGS=0
  INSTALL_THEME=0
  select_profile_interactive
  select_theme_interactive
  select_extras_interactive
}

resolve_defaults() {
  if [[ "$WITH_GOMAP" == "auto" ]]; then
    case "$PROFILE_NAME" in
      htb|bugbounty) WITH_GOMAP="yes" ;;
      *) WITH_GOMAP="no" ;;
    esac
  fi

  if [[ "$WITH_STARSHIP" == "auto" ]]; then
    WITH_STARSHIP="no"
  fi

  if [[ "$WITH_DOCKER" == "auto" ]]; then
    case "$PROFILE_NAME" in
      htb|bugbounty) WITH_DOCKER="yes" ;;
      *) WITH_DOCKER="no" ;;
    esac
  fi

  if [[ "$WITH_LOGIN_THEME" == "auto" ]]; then
    WITH_LOGIN_THEME="no"
  fi
}

build_plan() {
  local src dest

  DISPLAY_MANAGER="$(detect_display_manager)"
  PACKAGES=()
  CONFIG_TARGETS=()
  BACKUP_TARGETS=()
  SCRIPT_TARGETS=()
  SUDO_ACTIONS=()

  if [[ $INSTALL_FULL -eq 1 ]]; then
    PACKAGES=("${CORE_PACKAGES[@]}")
    if [[ $HAS_APT -eq 1 ]]; then
      SUDO_ACTIONS+=("apt-get update")
      SUDO_ACTIONS+=("apt-get install core packages")
    fi
  fi

  if [[ $INSTALL_FULL -eq 1 || $INSTALL_CONFIGS -eq 1 ]]; then
    CONFIG_TARGETS+=("$CONFIG_SRC/i3/config -> ${HOME}/.config/i3/config")
    CONFIG_TARGETS+=("$CONFIG_SRC/kitty/kitty.conf -> ${HOME}/.config/kitty/kitty.conf")
    CONFIG_TARGETS+=("$CONFIG_SRC/zsh/.zshrc -> ${HOME}/.zshrc")
    CONFIG_TARGETS+=("$CONFIG_SRC/starship/starship.toml -> ${HOME}/.config/starship.toml")
    CONFIG_TARGETS+=("$CONFIG_SRC/dmenu/config -> ${HOME}/.config/dmenu/config")

    BACKUP_TARGETS+=("${HOME}/.config/i3/config")
    BACKUP_TARGETS+=("${HOME}/.config/kitty/kitty.conf")
    BACKUP_TARGETS+=("${HOME}/.config/kitty/theme.conf")
    BACKUP_TARGETS+=("${HOME}/.zshrc")
    BACKUP_TARGETS+=("${HOME}/.config/starship.toml")

    for src in "$SCRIPTS_SRC"/bar.sh "$SCRIPTS_SRC"/dmenu.sh "$SCRIPTS_SRC"/network.sh "$SCRIPTS_SRC"/target.sh "$SCRIPTS_SRC"/gomap.sh "$SCRIPTS_SRC"/utils.sh "$SCRIPTS_SRC"/refresh.sh "$SCRIPTS_SRC"/power-menu.sh; do
      case "$(basename "$src")" in
        bar.sh) dest="${HOME}/.local/bin/kdc-bar" ;;
        dmenu.sh) dest="${HOME}/.local/bin/kdc-dmenu" ;;
        network.sh) dest="${HOME}/.local/bin/kdc-network" ;;
        target.sh) dest="${HOME}/.local/bin/kdc-target" ;;
        gomap.sh) dest="${HOME}/.local/bin/kdc-gomap" ;;
        utils.sh) dest="${HOME}/.local/bin/kdc-utils" ;;
        refresh.sh) dest="${HOME}/.local/bin/kdc-refresh" ;;
        power-menu.sh) dest="${HOME}/.local/bin/kdc-power-menu" ;;
        *) dest="" ;;
      esac
      [[ -n "$dest" ]] && SCRIPT_TARGETS+=("$src -> $dest")
    done

    if [[ -f "$SCRIPTS_SRC/doctor.sh" ]]; then
      SCRIPT_TARGETS+=("$SCRIPTS_SRC/doctor.sh -> ${HOME}/.local/bin/kdc-doctor")
    fi
  fi

  if [[ $INSTALL_FULL -eq 1 || $INSTALL_THEME -eq 1 ]]; then
    BACKUP_TARGETS+=("${HOME}/.config/kali-desktop-core/theme.conf")
    BACKUP_TARGETS+=("${HOME}/.config/kali-desktop-core/current-theme")
    CONFIG_TARGETS+=("$THEMES_DIR/$THEME_NAME/theme.conf -> ${HOME}/.config/kali-desktop-core/theme.conf")
    CONFIG_TARGETS+=("$THEMES_DIR/$THEME_NAME/kitty.theme.conf -> ${HOME}/.config/kitty/theme.conf")
  fi

  if [[ "$WITH_GOMAP" == "yes" ]]; then
    SUDO_ACTIONS+=("write $GOMAP_KEYRING_PATH")
    SUDO_ACTIONS+=("write $GOMAP_REPO_FILE")
    SUDO_ACTIONS+=("apt-get update")
    SUDO_ACTIONS+=("apt-get install gomap")
  fi

  if [[ "$WITH_STARSHIP" == "yes" ]]; then
    SUDO_ACTIONS+=("run official starship installer")
  fi

  if [[ "$WITH_DOCKER" == "yes" ]]; then
    if [[ $HAS_APT -eq 1 ]]; then
      SUDO_ACTIONS+=("apt-get update")
      SUDO_ACTIONS+=("apt-get install docker packages")
    fi
    SUDO_ACTIONS+=("systemctl enable --now docker if available")
    SUDO_ACTIONS+=("usermod -aG docker current user")
  fi

  if [[ "$WITH_LOGIN_THEME" == "yes" ]]; then
    CONFIG_TARGETS+=("/etc/lightdm/lightdm-gtk-greeter.conf")
    BACKUP_TARGETS+=("/etc/lightdm/lightdm-gtk-greeter.conf.kdc-backup-$(date +%Y%m%d-%H%M%S)")
    if [[ "$DISPLAY_MANAGER" == "lightdm" ]]; then
      SUDO_ACTIONS+=("backup /etc/lightdm/lightdm-gtk-greeter.conf")
      SUDO_ACTIONS+=("update LightDM GTK greeter theme")
    fi
  fi
}

print_list() {
  local empty_message="$1"
  shift

  if [[ $# -eq 0 ]]; then
    printf '  - %s\n' "$empty_message"
    return
  fi

  printf '  - %s\n' "$@"
}

print_plan() {
  print_header
  printf 'Plan de instalación\n'
  printf '%s\n' '-------------------'
  printf 'Perfil: %s\n' "$PROFILE_NAME"
  printf 'Theme: %s\n' "$THEME_NAME"
  printf 'Modo: '
  [[ $INSTALL_FULL -eq 1 ]] && printf 'full '
  [[ $INSTALL_CONFIGS -eq 1 ]] && printf 'configs '
  [[ $INSTALL_THEME -eq 1 ]] && printf 'theme '
  [[ $DRY_RUN -eq 1 ]] && printf '(dry-run)'
  printf '\n\n'

  printf 'Sistema detectado:\n'
  printf '  - apt-get: %s\n' "$([[ $HAS_APT -eq 1 ]] && printf 'sí' || printf 'no')"
  printf '  - OS: %s %s\n' "$OS_ID" "$OS_LIKE"
  printf '  - Sesión: %s\n' "$SESSION_TYPE"
  printf '  - Display manager: %s\n' "$DISPLAY_MANAGER"
  printf '  - ~/.local/bin en PATH: %s\n' "$([[ $LOCAL_BIN_IN_PATH -eq 1 ]] && printf 'sí' || printf 'no')"
  printf '  - Ejecutando como root: %s\n' "$([[ $RUNNING_AS_ROOT -eq 1 ]] && printf 'sí' || printf 'no')"
  printf '\n'

  printf 'Paquetes APT:\n'
  print_list "ninguno" "${PACKAGES[@]}"
  printf '\n'

  printf 'Configuraciones a copiar:\n'
  print_list "ninguna" "${CONFIG_TARGETS[@]}"
  printf '\n'

  printf 'Backups potenciales:\n'
  print_list "ninguno" "${BACKUP_TARGETS[@]}"
  printf '  Backup dir: %s\n' "$BACKUP_DIR"
  printf '\n'

  printf 'Scripts a instalar:\n'
  print_list "ninguno" "${SCRIPT_TARGETS[@]}"
  printf '\n'

  printf 'Extras:\n'
  printf '  - gomap: %s\n' "$WITH_GOMAP"
  printf '  - starship externo: %s\n' "$WITH_STARSHIP"
  printf '  - docker: %s\n' "$WITH_DOCKER"
  printf '  - login theme: %s\n' "$WITH_LOGIN_THEME"
  if [[ "$WITH_LOGIN_THEME" == "yes" ]]; then
    printf '  - login theme compatible: %s\n' "$([[ "$DISPLAY_MANAGER" == "lightdm" ]] && printf 'yes' || printf 'no')"
    printf '  - login theme file: /etc/lightdm/lightdm-gtk-greeter.conf\n'
  fi
  printf '  - doctor: %s\n' "$([[ $RUN_DOCTOR -eq 1 ]] && printf 'sí' || printf 'no')"
  printf '\n'

  printf 'Acciones con sudo:\n'
  print_list "ninguna" "${SUDO_ACTIONS[@]}"
  printf '\n'
}

warn_system_notes() {
  if [[ $RUNNING_AS_ROOT -eq 1 ]]; then
    warn "No es recomendable ejecutar este instalador como root; está pensado para un usuario normal con sudo."
  fi

  if [[ "$OS_ID" != "kali" && "$OS_ID" != "debian" && "$OS_LIKE" != *"debian"* ]]; then
    warn "Sistema no identificado como Kali/Debian. La instalación APT puede no funcionar."
  fi

  if [[ "$SESSION_TYPE" == "wayland" ]]; then
    warn "La sesión parece Wayland. i3/lemonbar están pensados para X11."
  fi

  if [[ $LOCAL_BIN_IN_PATH -eq 0 ]]; then
    warn "${HOME}/.local/bin no está en PATH. Los comandos kdc-* podrían no estar disponibles hasta ajustar la shell."
  fi
}

ensure_dirs() {
  dry_run_or_exec mkdir -p \
    "${HOME}/.config" \
    "${HOME}/.config/i3" \
    "${HOME}/.config/kitty" \
    "${HOME}/.config/starship" \
    "${HOME}/.config/zsh" \
    "${HOME}/.config/dmenu" \
    "${HOME}/.local/bin" \
    "${HOME}/.local/share/kali-desktop-core" \
    "${HOME}/.local/share/kali-desktop-core/themes" \
    "${HOME}/.local/share/kali-desktop-core/wallpapers"
}

backup_path() {
  local target="$1"

  if [[ -e "$target" || -L "$target" ]]; then
    log "Backup: $target -> $BACKUP_DIR"
    dry_run_or_exec mkdir -p "$BACKUP_DIR"
    dry_run_or_exec cp -a "$target" "$BACKUP_DIR/"
  elif [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] no backup, no existe: %s\n' "$target"
  fi
}

install_packages() {
  if [[ $HAS_APT -eq 0 ]]; then
    warn "No se encontró apt-get. Instala manualmente: ${PACKAGES[*]}"
    return
  fi

  log "Instalando dependencias con apt-get"
  dry_run_or_exec sudo apt-get update
  dry_run_or_exec sudo apt-get install -y "${PACKAGES[@]}"
}

install_gomap() {
  if [[ "$WITH_GOMAP" != "yes" ]]; then
    return
  fi

  if [[ $HAS_APT -eq 0 ]]; then
    warn "No se encontró apt-get. No se puede instalar gomap automáticamente."
    return
  fi

  log "Registrando repositorio APT de gomap"
  dry_run_or_shell "instalar keyring de gomap" "curl -fsSL '$GOMAP_KEYRING_URL' | sudo gpg --dearmor --yes -o '$GOMAP_KEYRING_PATH'"
  dry_run_or_shell "registrar repositorio APT de gomap" "printf '%s\n' '$GOMAP_REPO_LINE' | sudo tee '$GOMAP_REPO_FILE' > /dev/null"

  log "Instalando gomap"
  dry_run_or_exec sudo apt-get update
  dry_run_or_exec sudo apt-get install -y gomap
}

install_starship_external() {
  if [[ "$WITH_STARSHIP" != "yes" ]]; then
    return
  fi

  if is_command starship; then
    log "starship ya está instalado"
    return
  fi

  log "Instalando starship con el instalador oficial"
  dry_run_or_shell "instalar starship" "curl -fsSL https://starship.rs/install.sh | sh -s -- -y"
}

install_docker() {
  local target_user

  if [[ "$WITH_DOCKER" != "yes" ]]; then
    return
  fi

  if [[ $HAS_APT -eq 0 ]]; then
    warn "No se encontró apt-get. No se puede instalar Docker automáticamente."
    return
  fi

  target_user="${SUDO_USER:-${USER:-$(id -un)}}"

  log "Instalando Docker desde paquetes del sistema"
  dry_run_or_exec sudo apt-get update
  dry_run_or_exec sudo apt-get install -y "${DOCKER_PACKAGES[@]}"

  if is_command systemctl; then
    log "Habilitando servicio docker"
    dry_run_or_exec sudo systemctl enable --now docker
  else
    warn "systemctl no está disponible. No se habilitó el servicio docker automáticamente."
  fi

  log "Añadiendo usuario $target_user al grupo docker"
  dry_run_or_exec sudo usermod -aG docker "$target_user"
  warn "Cierra sesión y vuelve a entrar para usar Docker sin sudo."
}

copy_configs() {
  log "Copiando configuraciones base"

  backup_path "${HOME}/.config/i3/config"
  backup_path "${HOME}/.config/kitty/kitty.conf"
  backup_path "${HOME}/.config/kitty/theme.conf"
  backup_path "${HOME}/.zshrc"
  backup_path "${HOME}/.config/starship.toml"

  dry_run_or_exec install -m 0644 "$CONFIG_SRC/i3/config" "${HOME}/.config/i3/config"
  dry_run_or_exec install -m 0644 "$CONFIG_SRC/kitty/kitty.conf" "${HOME}/.config/kitty/kitty.conf"
  dry_run_or_exec install -m 0644 "$CONFIG_SRC/zsh/.zshrc" "${HOME}/.zshrc"
  dry_run_or_exec install -m 0644 "$CONFIG_SRC/starship/starship.toml" "${HOME}/.config/starship.toml"
  dry_run_or_exec install -m 0644 "$CONFIG_SRC/dmenu/config" "${HOME}/.config/dmenu/config"

  log "Copiando scripts"
  dry_run_or_exec install -m 0755 "$SCRIPTS_SRC/bar.sh" "${HOME}/.local/bin/kdc-bar"
  dry_run_or_exec install -m 0755 "$SCRIPTS_SRC/dmenu.sh" "${HOME}/.local/bin/kdc-dmenu"
  dry_run_or_exec install -m 0755 "$SCRIPTS_SRC/network.sh" "${HOME}/.local/bin/kdc-network"
  dry_run_or_exec install -m 0755 "$SCRIPTS_SRC/target.sh" "${HOME}/.local/bin/kdc-target"
  dry_run_or_exec install -m 0755 "$SCRIPTS_SRC/gomap.sh" "${HOME}/.local/bin/kdc-gomap"
  dry_run_or_exec install -m 0755 "$SCRIPTS_SRC/utils.sh" "${HOME}/.local/bin/kdc-utils"
  dry_run_or_exec install -m 0755 "$SCRIPTS_SRC/refresh.sh" "${HOME}/.local/bin/kdc-refresh"
  dry_run_or_exec install -m 0755 "$SCRIPTS_SRC/power-menu.sh" "${HOME}/.local/bin/kdc-power-menu"

  if [[ -f "$SCRIPTS_SRC/doctor.sh" ]]; then
    dry_run_or_exec install -m 0755 "$SCRIPTS_SRC/doctor.sh" "${HOME}/.local/bin/kdc-doctor"
  fi

  dry_run_or_exec cp -a "$SCRIPTS_SRC" "${HOME}/.local/share/kali-desktop-core/"
}

apply_theme() {
  local theme_dir="$THEMES_DIR/$THEME_NAME"
  local wallpaper_file=""

  if [[ $INSTALL_FULL -eq 0 && $INSTALL_CONFIGS -eq 0 && ! -x "${HOME}/.local/bin/kdc-bar" && $DRY_RUN -eq 0 ]]; then
    die "Antes de usar --theme debes hacer una instalación base con './install.sh --full' o './install.sh --configs'."
  fi

  log "Aplicando theme: $THEME_NAME"

  backup_path "${HOME}/.config/kali-desktop-core/theme.conf"
  backup_path "${HOME}/.config/kali-desktop-core/current-theme"

  dry_run_or_exec mkdir -p "${HOME}/.config/kali-desktop-core"
  dry_run_or_exec install -m 0644 "$theme_dir/theme.conf" "${HOME}/.config/kali-desktop-core/theme.conf"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] escribir %s en %s\n' "$THEME_NAME" "${HOME}/.config/kali-desktop-core/current-theme"
  else
    printf '%s\n' "$THEME_NAME" > "${HOME}/.config/kali-desktop-core/current-theme"
  fi

  dry_run_or_exec cp -a "$theme_dir" "${HOME}/.local/share/kali-desktop-core/themes/"

  if [[ -f "$theme_dir/kitty.theme.conf" ]]; then
    dry_run_or_exec install -m 0644 "$theme_dir/kitty.theme.conf" "${HOME}/.config/kitty/theme.conf"
  fi

  dry_run_or_exec cp -a "$WALLPAPERS_SRC/." "${HOME}/.local/share/kali-desktop-core/wallpapers/"

  wallpaper_file="$(awk -F'"' '/^WALLPAPER=/{print $2}' "$theme_dir/theme.conf" | head -n1)"
  if [[ -n "$wallpaper_file" && -f "$theme_dir/$wallpaper_file" ]]; then
    dry_run_or_exec install -m 0644 "$theme_dir/$wallpaper_file" "${HOME}/.local/share/kali-desktop-core/wallpapers/${THEME_NAME}.${wallpaper_file##*.}"
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] escribir wallpaper actual en %s\n' "${HOME}/.config/kali-desktop-core/current-wallpaper"
    else
      printf '%s\n' "${HOME}/.local/share/kali-desktop-core/wallpapers/${THEME_NAME}.${wallpaper_file##*.}" > "${HOME}/.config/kali-desktop-core/current-wallpaper"
    fi
  else
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] vaciar %s\n' "${HOME}/.config/kali-desktop-core/current-wallpaper"
    else
      : > "${HOME}/.config/kali-desktop-core/current-wallpaper"
    fi
  fi
}

get_login_wallpaper() {
  local current_file="${HOME}/.config/kali-desktop-core/current-wallpaper"
  local wallpaper_path wallpaper_file theme_dir="$THEMES_DIR/$THEME_NAME"

  if [[ -s "$current_file" ]]; then
    wallpaper_path="$(head -n1 "$current_file")"
    if [[ -f "$wallpaper_path" ]]; then
      printf '%s\n' "$wallpaper_path"
      return 0
    fi
  fi

  wallpaper_file="$(awk -F'"' '/^WALLPAPER=/{print $2}' "$theme_dir/theme.conf" 2>/dev/null | head -n1)"
  if [[ -n "${wallpaper_file:-}" && -f "$theme_dir/$wallpaper_file" ]]; then
    printf '%s\n' "$theme_dir/$wallpaper_file"
    return 0
  fi

  return 0
}

set_ini_key() {
  local file="$1"
  local section="$2"
  local key="$3"
  local value="$4"
  local tmp

  tmp="$(mktemp)"
  awk -v section="$section" -v key="$key" -v value="$value" '
    function trim(text) {
      sub(/^[[:space:]]+/, "", text)
      sub(/[[:space:]]+$/, "", text)
      return text
    }
    function emit_key() {
      print key "=" value
      key_done = 1
    }
    BEGIN {
      in_section = 0
      section_found = 0
      key_done = 0
    }
    /^[[:space:]]*\[[^]]+\][[:space:]]*$/ {
      if (in_section && !key_done) {
        emit_key()
      }
      header = $0
      sub(/^[[:space:]]*\[/, "", header)
      sub(/\][[:space:]]*$/, "", header)
      header = trim(header)
      in_section = (header == section)
      if (in_section) {
        section_found = 1
      }
      print
      next
    }
    {
      if (in_section && index($0, "=") > 0) {
        split($0, parts, "=")
        candidate = trim(parts[1])
        if (candidate == key) {
          if (!key_done) {
            emit_key()
          }
          next
        }
      }
      print
    }
    END {
      if (in_section && !key_done) {
        emit_key()
      } else if (!section_found) {
        print ""
        print "[" section "]"
        print key "=" value
      }
    }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

apply_lightdm_login_theme() {
  local greeter_file="/etc/lightdm/lightdm-gtk-greeter.conf"
  local backup_file
  local wallpaper tmp_file

  backup_file="/etc/lightdm/lightdm-gtk-greeter.conf.kdc-backup-$(date +%Y%m%d-%H%M%S)"

  if [[ ! -e "$greeter_file" ]]; then
    warn "No existe $greeter_file. No se aplica tema de login."
    return 0
  fi

  wallpaper="$(get_login_wallpaper)"

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Display manager detectado: lightdm\n'
    printf '[dry-run] modificar: %s\n' "$greeter_file"
    printf '[dry-run] crear backup: %s\n' "$backup_file"
    if [[ -n "${wallpaper:-}" ]]; then
      printf '[dry-run] set [greeter] background=%s\n' "$wallpaper"
    else
      printf '[dry-run] sin wallpaper válido; no se establecería background\n'
    fi
    printf '[dry-run] set [greeter] theme-name=Adwaita-dark\n'
    printf '[dry-run] set [greeter] icon-theme-name=Adwaita\n'
    printf '[dry-run] set [greeter] font-name=Sans 10\n'
    printf '[dry-run] set [greeter] hide-user-image=true\n'
    return 0
  fi

  log "Creando backup de LightDM GTK greeter: $backup_file"
  dry_run_or_exec sudo cp -a "$greeter_file" "$backup_file"

  tmp_file="$(mktemp)"
  sudo cat "$greeter_file" | tee "$tmp_file" >/dev/null

  if [[ -n "${wallpaper:-}" ]]; then
    set_ini_key "$tmp_file" "greeter" "background" "$wallpaper"
  else
    warn "No se encontró wallpaper válido; se mantiene el background actual del greeter."
  fi
  set_ini_key "$tmp_file" "greeter" "theme-name" "Adwaita-dark"
  set_ini_key "$tmp_file" "greeter" "icon-theme-name" "Adwaita"
  set_ini_key "$tmp_file" "greeter" "font-name" "Sans 10"
  set_ini_key "$tmp_file" "greeter" "hide-user-image" "true"

  log "Aplicando tema de login LightDM"
  dry_run_or_exec sudo install -m 0644 "$tmp_file" "$greeter_file"
  rm -f "$tmp_file"
}

apply_login_theme() {
  local dm

  if [[ "$WITH_LOGIN_THEME" != "yes" ]]; then
    return
  fi

  dm="$(detect_display_manager)"
  DISPLAY_MANAGER="$dm"

  if [[ "$dm" != "lightdm" ]]; then
    warn "Display manager detectado: $dm. El tema de login solo soporta LightDM por ahora; no se modifica nada."
    return 0
  fi

  apply_lightdm_login_theme
}

run_doctor() {
  if [[ $RUN_DOCTOR -eq 0 ]]; then
    return
  fi

  if [[ -x "${HOME}/.local/bin/kdc-doctor" ]]; then
    dry_run_or_exec "${HOME}/.local/bin/kdc-doctor"
  elif [[ -f "$SCRIPTS_SRC/doctor.sh" ]]; then
    dry_run_or_exec bash "$SCRIPTS_SRC/doctor.sh"
  else
    warn "Doctor solicitado, pero scripts/doctor.sh no existe todavía. Hook preparado sin ejecutar nada."
  fi
}

parse_args() {
  if [[ $# -eq 0 ]]; then
    NO_ARGS=1
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
      --interactive)
        INTERACTIVE=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --with-gomap)
        WITH_GOMAP="yes"
        shift
        ;;
      --without-gomap)
        WITH_GOMAP="no"
        shift
        ;;
      --with-starship)
        WITH_STARSHIP="yes"
        shift
        ;;
      --without-starship)
        WITH_STARSHIP="no"
        shift
        ;;
      --with-docker)
        WITH_DOCKER="yes"
        shift
        ;;
      --without-docker)
        WITH_DOCKER="no"
        shift
        ;;
      --login-theme)
        WITH_LOGIN_THEME="yes"
        shift
        ;;
      --without-login-theme)
        WITH_LOGIN_THEME="no"
        shift
        ;;
      --run-doctor)
        RUN_DOCTOR=1
        shift
        ;;
      --no-confirm)
        NO_CONFIRM=1
        shift
        ;;
      --profile)
        [[ $# -ge 2 ]] || die "Debes indicar un perfil tras --profile"
        PROFILE_NAME="$2"
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

execute_plan() {
  ensure_dirs

  if [[ $INSTALL_FULL -eq 1 ]]; then
    install_packages
    install_gomap
    install_starship_external
    install_docker
    copy_configs
    apply_theme
  else
    if [[ $INSTALL_CONFIGS -eq 1 ]]; then
      copy_configs
    fi

    if [[ $INSTALL_THEME -eq 1 ]]; then
      apply_theme
    fi

    if [[ "$WITH_GOMAP" == "yes" ]]; then
      install_gomap
    fi

    if [[ "$WITH_STARSHIP" == "yes" ]]; then
      install_starship_external
    fi

    if [[ "$WITH_DOCKER" == "yes" ]]; then
      install_docker
    fi

    if [[ $INSTALL_CONFIGS -eq 0 && $INSTALL_THEME -eq 0 && "$WITH_GOMAP" != "yes" && "$WITH_STARSHIP" != "yes" && "$WITH_DOCKER" != "yes" && "$WITH_LOGIN_THEME" != "yes" && $RUN_DOCTOR -eq 0 ]]; then
      die "No se seleccionó ninguna acción. Usa --help para ver opciones."
    fi
  fi

  apply_login_theme
  run_doctor
}

main() {
  parse_args "$@"

  if [[ $INTERACTIVE -eq 1 ]]; then
    run_interactive_menu
  fi

  if [[ $NO_ARGS -eq 1 ]]; then
    warn "Sin argumentos se mantiene el comportamiento actual: instalación completa. También puedes usar --interactive."
  fi

  validate_profile
  validate_theme
  detect_system
  resolve_defaults
  build_plan
  print_plan
  warn_system_notes

  if [[ $INTERACTIVE -eq 1 && $DRY_RUN -eq 0 && $NO_CONFIRM -eq 0 ]]; then
    confirm "¿Ejecutar este plan?" "y" || die "Instalación cancelada"
  fi

  execute_plan

  if [[ $DRY_RUN -eq 1 ]]; then
    log "Dry-run completado. No se han aplicado cambios."
  else
    log "Instalación completada"
    log "Recomendado: cerrar sesión y volver a entrar en i3"
  fi
}

main "$@"
