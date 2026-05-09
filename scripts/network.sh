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

# shellcheck disable=SC1090
source "$UTILS_SCRIPT"

get_ipv4_by_iface() {
  local iface="$1"
  ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1
}

get_primary_iface() {
  ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {for (i=1; i<=NF; i++) if ($i == "dev") {print $(i+1); exit}}'
}

get_local_ip() {
  local iface
  iface="$(get_primary_iface)"
  [[ -n "${iface:-}" ]] && get_ipv4_by_iface "$iface"
}

get_vpn_ip() {
  get_ipv4_by_iface tun0
}

get_docker_ip() {
  get_ipv4_by_iface docker0
}

get_vpn_state() {
  vpn_status_text
}

case "${1:-all}" in
  local)
    get_local_ip
    ;;
  vpn)
    get_vpn_ip
    ;;
  docker)
    get_docker_ip
    ;;
  vpn-state)
    get_vpn_state
    ;;
  all)
    printf 'local=%s vpn=%s docker=%s state=%s\n' \
      "$(get_local_ip)" \
      "$(get_vpn_ip)" \
      "$(get_docker_ip)" \
      "$(get_vpn_state)"
    ;;
  *)
    echo "Uso: $0 {local|vpn|docker|vpn-state|all}"
    exit 1
    ;;
esac
