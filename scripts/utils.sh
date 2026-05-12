#!/usr/bin/env bash
set -euo pipefail

KDC_CONFIG_DIR="${HOME}/.config/kali-desktop-core"
KDC_THEME_FILE="${KDC_CONFIG_DIR}/theme.conf"
TARGET_FILE="${HOME}/.config/target"

is_command() {
  command -v "$1" >/dev/null 2>&1
}

ensure_target_file() {
  mkdir -p "$(dirname "$TARGET_FILE")"
  touch "$TARGET_FILE"
}

read_target() {
  if [[ -s "$TARGET_FILE" ]]; then
    tr -d '\n' < "$TARGET_FILE"
  else
    printf 'none'
  fi
}

source_theme() {
  if [[ -f "$KDC_THEME_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$KDC_THEME_FILE"
  else
    return 1
  fi
}

theme_value() {
  local key="$1"
  source_theme || return 1
  printf '%s\n' "${!key:-}"
}

vpn_ifaces() {
  local -a ifaces
  read -r -a ifaces <<< "${KDC_VPN_IFACES:-tun0 tun1 tun2 wg0}"
  printf '%s\n' "${ifaces[@]}"
}

get_ipv4_by_iface() {
  local iface="$1"
  ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1
}

get_vpn_ip() {
  local iface ip_addr

  while IFS= read -r iface; do
    [[ -n "$iface" ]] || continue
    ip_addr="$(get_ipv4_by_iface "$iface" || true)"
    if [[ -n "${ip_addr:-}" ]]; then
      printf '%s\n' "$ip_addr"
      return 0
    fi
  done < <(vpn_ifaces)
}

vpn_status_text() {
  if [[ -n "$(get_vpn_ip)" ]]; then
    printf 'VPN:up'
  else
    printf 'VPN:off'
  fi
}
