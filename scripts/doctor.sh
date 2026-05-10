#!/usr/bin/env bash
set -euo pipefail

FAIL_COUNT=0
WARN_COUNT=0
STRICT=0

usage() {
  cat <<'EOF'
Uso: kdc-doctor [opciones]

Opciones:
  --strict   Trata starship y la barra en ejecución como requisitos estrictos
  --help     Muestra esta ayuda

Ejemplos:
  kdc-doctor
  kdc-doctor --strict
EOF
}

ok() {
  printf '[OK] %s\n' "$1"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  printf '[WARN] %s\n' "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '[FAIL] %s\n' "$1"
}

is_command() {
  command -v "$1" >/dev/null 2>&1
}

check_command() {
  local cmd="$1"
  local required="${2:-required}"

  if is_command "$cmd"; then
    ok "Comando disponible: $cmd ($(command -v "$cmd"))"
  elif [[ "$required" == "optional" ]]; then
    warn "Comando opcional no disponible: $cmd"
  else
    fail "Comando requerido no disponible: $cmd"
  fi
}

docker_marker_exists() {
  is_command docker || [[ -S /var/run/docker.sock || -e /etc/docker || -e /var/lib/docker ]]
}

check_file() {
  local path="$1"
  local required="${2:-required}"

  if [[ -e "$path" || -L "$path" ]]; then
    ok "Archivo existe: $path"
  elif [[ "$required" == "optional" ]]; then
    warn "Archivo opcional no existe: $path"
  else
    fail "Archivo requerido no existe: $path"
  fi
}

get_ipv4_by_iface() {
  local iface="$1"

  ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1
}

vpn_ifaces() {
  local -a ifaces
  read -r -a ifaces <<< "${KDC_VPN_IFACES:-tun0 tun1 tun2 wg0}"
  printf '%s\n' "${ifaces[@]}"
}

vpn_ifaces_text() {
  local iface output=""

  while IFS= read -r iface; do
    [[ -n "$iface" ]] || continue
    output="${output:+$output }$iface"
  done < <(vpn_ifaces)

  printf '%s\n' "$output"
}

get_primary_iface() {
  ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {for (i=1; i<=NF; i++) if ($i == "dev") {print $(i+1); exit}}'
}

check_os() {
  local id="unknown"
  local name="unknown"
  local version="unknown"
  local like=""

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    id="${ID:-unknown}"
    name="${NAME:-unknown}"
    version="${VERSION_ID:-unknown}"
    like="${ID_LIKE:-}"
    ok "Sistema: $name $version (ID=$id ID_LIKE=${like:-none})"

    if [[ "$id" != "kali" && "$id" != "debian" && "$like" != *"debian"* ]]; then
      warn "El sistema no parece Kali/Debian; algunas instalaciones APT pueden no funcionar."
    fi
  else
    fail "No se puede leer /etc/os-release"
  fi
}

check_session() {
  local session="${XDG_SESSION_TYPE:-unknown}"

  case "$session" in
    x11)
      ok "Sesión gráfica: X11"
      ;;
    wayland)
      warn "Sesión gráfica: Wayland. i3/lemonbar están pensados para X11."
      ;;
    *)
      warn "Sesión gráfica no detectada: $session"
      ;;
  esac
}

check_path() {
  if [[ ":$PATH:" == *":${HOME}/.local/bin:"* ]]; then
    ok "${HOME}/.local/bin está en PATH"
  else
    fail "${HOME}/.local/bin no está en PATH"
  fi
}

check_commands() {
  local cmd
  local required_commands=(
    i3
    kitty
    dmenu
    lemonbar
    zsh
    feh
    xrandr
    ip
    awk
    grep
    sed
    xclip
  )

  for cmd in "${required_commands[@]}"; do
    check_command "$cmd"
  done

  if [[ $STRICT -eq 1 ]]; then
    check_command starship
  else
    check_command starship optional
  fi

  check_command gomap optional
}

check_docker() {
  local docker_required="optional"
  local docker_marker=0
  local current_user groups_output

  if docker_marker_exists; then
    docker_marker=1
  fi

  if [[ $STRICT -eq 1 && $docker_marker -eq 1 ]]; then
    docker_required="required"
  fi

  check_command docker "$docker_required"

  if is_command docker; then
    if docker compose version >/dev/null 2>&1; then
      ok "Docker Compose disponible: $(docker compose version 2>/dev/null | head -n1)"
    elif [[ "$docker_required" == "required" ]]; then
      fail "Docker Compose plugin no disponible"
    else
      warn "Docker Compose plugin no disponible"
    fi
  else
    warn "No se puede comprobar Docker Compose sin el comando docker"
  fi

  if is_command systemctl; then
    if systemctl is-active --quiet docker 2>/dev/null; then
      ok "Servicio docker activo"
    elif [[ "$docker_required" == "required" ]]; then
      fail "Servicio docker no activo"
    else
      warn "Servicio docker no activo o no instalado"
    fi
  else
    warn "systemctl no disponible; no se comprueba el servicio docker"
  fi

  current_user="${SUDO_USER:-${USER:-$(id -un)}}"
  groups_output="$(id -nG "$current_user" 2>/dev/null || true)"
  if [[ " $groups_output " == *" docker "* ]]; then
    ok "Usuario $current_user pertenece al grupo docker"
  elif [[ "$docker_required" == "required" ]]; then
    fail "Usuario $current_user no pertenece al grupo docker"
  else
    warn "Usuario $current_user no pertenece al grupo docker"
  fi
}

check_configs() {
  check_file "${HOME}/.config/i3/config"
  check_file "${HOME}/.config/kitty/kitty.conf"
  check_file "${HOME}/.config/kitty/theme.conf"
  check_file "${HOME}/.config/starship.toml"
  check_file "${HOME}/.zshrc"
  check_file "${HOME}/.config/kali-desktop-core/theme.conf"
  check_file "${HOME}/.config/kali-desktop-core/current-theme"
  check_file "${HOME}/.config/target" optional
}

check_scripts() {
  check_file "${HOME}/.local/bin/kdc-bar"
  check_file "${HOME}/.local/bin/kdc-network"
  check_file "${HOME}/.local/bin/kdc-target"
  check_file "${HOME}/.local/bin/kdc-utils"
  check_file "${HOME}/.local/bin/kdc-doctor"
  check_file "${HOME}/.local/bin/kdc-gomap" optional
}

check_network() {
  local iface local_ip vpn_iface vpn_ip docker_ip found_vpn=0

  if ! is_command ip || ! is_command awk; then
    warn "No se puede comprobar red: faltan ip o awk"
    return
  fi

  iface="$(get_primary_iface)"
  if [[ -n "${iface:-}" ]]; then
    local_ip="$(get_ipv4_by_iface "$iface" || true)"
    if [[ -n "${local_ip:-}" ]]; then
      ok "IP local ($iface): $local_ip"
    else
      warn "Interfaz local detectada sin IPv4: $iface"
    fi
  else
    warn "No se pudo detectar interfaz local principal"
  fi

  while IFS= read -r vpn_iface; do
    [[ -n "$vpn_iface" ]] || continue
    vpn_ip="$(get_ipv4_by_iface "$vpn_iface" || true)"
    if [[ -n "${vpn_ip:-}" ]]; then
      ok "VPN detectada ($vpn_iface): $vpn_ip"
      found_vpn=1
    fi
  done < <(vpn_ifaces)

  if [[ $found_vpn -eq 0 ]]; then
    warn "No se detectó VPN en: $(vpn_ifaces_text)"
  fi

  docker_ip="$(get_ipv4_by_iface docker0 || true)"
  if [[ -n "${docker_ip:-}" ]]; then
    ok "Docker detectado (docker0): $docker_ip"
  else
    warn "No se detectó docker0"
  fi
}

check_bar() {
  local log_file="${HOME}/.cache/kdc-bar.log"

  if pgrep -f kdc-bar >/dev/null 2>&1; then
    ok "Proceso kdc-bar activo"
  elif [[ $STRICT -eq 1 ]]; then
    fail "No hay proceso kdc-bar activo"
  else
    warn "No hay proceso kdc-bar activo"
  fi

  if pgrep -x lemonbar >/dev/null 2>&1 || pgrep -f lemonbar >/dev/null 2>&1; then
    ok "Proceso lemonbar activo"
  elif [[ $STRICT -eq 1 ]]; then
    fail "No hay proceso lemonbar activo"
  else
    warn "No hay proceso lemonbar activo"
  fi

  if [[ -e "$log_file" ]]; then
    ok "Log de barra: $log_file"
  else
    warn "Log de barra no existe todavía: $log_file"
  fi
}

check_theme() {
  local theme_file="${HOME}/.config/kali-desktop-core/theme.conf"
  local current_theme_file="${HOME}/.config/kali-desktop-core/current-theme"
  local current_theme="unknown"
  local missing=0
  local key
  local required_keys=(
    THEME_NAME
    WALLPAPER
    BAR_BG
    BAR_FG
    BAR_MUTED
    BAR_ACCENT
    BAR_ALERT
    BAR_FONT
  )

  if [[ -s "$current_theme_file" ]]; then
    current_theme="$(tr -d '\n' < "$current_theme_file")"
    ok "Tema actual: $current_theme"
  else
    fail "No se puede leer el tema actual: $current_theme_file"
  fi

  if [[ ! -r "$theme_file" ]]; then
    fail "No se puede leer theme.conf: $theme_file"
    return
  fi

  # shellcheck disable=SC1090
  source "$theme_file"

  for key in "${required_keys[@]}"; do
    if [[ -n "${!key:-}" ]]; then
      ok "Theme key presente: $key=${!key}"
    else
      fail "Theme key ausente o vacía: $key"
      missing=1
    fi
  done

  if [[ $missing -eq 0 ]]; then
    ok "Colores básicos del tema validados"
  fi
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --strict)
        STRICT=1
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        printf '[FAIL] Opción desconocida: %s\n' "$1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  printf 'Kali Desktop Core doctor\n'
  printf '========================\n'
  if [[ $STRICT -eq 1 ]]; then
    printf 'Modo: strict\n'
  else
    printf 'Modo: normal\n'
  fi

  printf '\nSistema\n'
  check_os
  check_session
  check_path

  printf '\nComandos\n'
  check_commands

  printf '\nConfiguración\n'
  check_configs

  printf '\nScripts\n'
  check_scripts

  printf '\nRed\n'
  check_network

  printf '\nDocker\n'
  check_docker

  printf '\nBarra\n'
  check_bar

  printf '\nTema\n'
  check_theme

  printf '\nResumen\n'
  if [[ $FAIL_COUNT -gt 0 ]]; then
    printf '[FAIL] %s fallo(s), %s warning(s)\n' "$FAIL_COUNT" "$WARN_COUNT"
    exit 1
  fi

  if [[ $WARN_COUNT -gt 0 ]]; then
    printf '[WARN] 0 fallos, %s warning(s)\n' "$WARN_COUNT"
  else
    printf '[OK] Todo correcto\n'
  fi
}

main "$@"
