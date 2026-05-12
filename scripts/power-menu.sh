#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_SCRIPT="${HOME}/.local/share/kali-desktop-core/scripts/utils.sh"

if [[ ! -f "$UTILS_SCRIPT" ]]; then
  UTILS_SCRIPT="${SCRIPT_DIR}/utils.sh"
fi

if [[ ! -f "$UTILS_SCRIPT" && -f "${HOME}/.local/bin/kdc-utils" ]]; then
  UTILS_SCRIPT="${HOME}/.local/bin/kdc-utils"
fi

if [[ -f "$UTILS_SCRIPT" ]]; then
  # shellcheck disable=SC1090
  source "$UTILS_SCRIPT"
fi

BAR_BG="${BAR_BG:-#0d0f12}"
BAR_FG="${BAR_FG:-#d0d0d0}"
BAR_ALERT="${BAR_ALERT:-#c75b65}"

if declare -F source_theme >/dev/null 2>&1; then
  source_theme || true
fi

die() {
  printf '[x] %s\n' "$1" >&2
  exit 1
}

is_command() {
  command -v "$1" >/dev/null 2>&1
}

dmenu_select() {
  dmenu -i -p "$1" -nb "$BAR_BG" -nf "$BAR_FG" -sb "$BAR_ALERT" -sf "$BAR_BG"
}

confirm_action() {
  local action="$1"
  local answer

  answer="$(printf 'No\nSí\n' | dmenu_select "Confirmar $action" || true)"
  [[ "$answer" == "Sí" ]]
}

is_command dmenu || die "dmenu no está instalado o no está en PATH."

action="$(printf 'Bloquear\nCerrar sesión\nSuspender\nReiniciar\nApagar\n' | dmenu_select "Sesión" || true)"
[[ -n "${action:-}" ]] || exit 0

case "$action" in
  Bloquear)
    i3lock -c 0d0f12
    ;;
  "Cerrar sesión")
    i3-msg exit
    ;;
  Suspender)
    systemctl suspend
    ;;
  Reiniciar)
    confirm_action "reinicio" || exit 0
    systemctl reboot
    ;;
  Apagar)
    confirm_action "apagado" || exit 0
    systemctl poweroff
    ;;
esac
