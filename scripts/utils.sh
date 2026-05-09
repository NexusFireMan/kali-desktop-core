#!/usr/bin/env bash
set -euo pipefail

KDC_CONFIG_DIR="${HOME}/.config/kali-desktop-core"
KDC_THEME_FILE="${KDC_CONFIG_DIR}/theme.conf"
TARGET_FILE="${HOME}/.config/target"

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

vpn_status_text() {
  if ip link show tun0 >/dev/null 2>&1; then
    local state
    state="$(ip link show tun0 | awk '/state/ {print $9; exit}')"
    if [[ "${state:-}" == "UP" ]]; then
      printf 'VPN:up'
    else
      printf 'VPN:down'
    fi
  else
    printf 'VPN:off'
  fi
}
