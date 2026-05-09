#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETWORK_SCRIPT="${HOME}/.local/bin/kdc-network"
UTILS_SCRIPT="${HOME}/.local/share/kali-desktop-core/scripts/utils.sh"

if [[ ! -f "$UTILS_SCRIPT" ]]; then
  UTILS_SCRIPT="${SCRIPT_DIR}/utils.sh"
fi

if [[ ! -f "$UTILS_SCRIPT" && -f "${HOME}/.local/bin/kdc-utils" ]]; then
  UTILS_SCRIPT="${HOME}/.local/bin/kdc-utils"
fi

# shellcheck disable=SC1090
source "$UTILS_SCRIPT"

BAR_PID_FILE="${HOME}/.cache/kdc-bar.pid"
BAR_LOG_FILE="${HOME}/.cache/kdc-bar.log"
REFRESH_FLAG=0

on_refresh() {
  REFRESH_FLAG=1
}

trap on_refresh USR1

mkdir -p "$(dirname "$BAR_PID_FILE")"

load_theme_defaults() {
  BAR_BG="#0d0f12"
  BAR_FG="#d0d0d0"
  BAR_MUTED="#7f8792"
  BAR_ACCENT="#8fb7ff"
  BAR_ALERT="#c75b65"
  BAR_FONT="JetBrainsMono Nerd Font:size=10"

  source_theme || true
}

segment() {
  local label="$1"
  local value="$2"
  local color="${3:-$BAR_FG}"

  printf "%%{F%s}%s%%{F%s} %s%%{F-}   " "$BAR_MUTED" "$label" "$color" "${value:---}"
}

render_line() {
  local local_ip vpn_ip docker_ip target vpn_state clock

  local_ip="$("$NETWORK_SCRIPT" local 2>/dev/null || true)"
  vpn_ip="$("$NETWORK_SCRIPT" vpn 2>/dev/null || true)"
  docker_ip="$("$NETWORK_SCRIPT" docker 2>/dev/null || true)"
  vpn_state="$("$NETWORK_SCRIPT" vpn-state 2>/dev/null || true)"
  target="$(read_target)"
  clock="$(date '+%H:%M')"

  printf "%%{l}%s%s%s%s%%{r}%s%s\n" \
    "$(segment 'LAN' "${local_ip:-down}")" \
    "$(segment 'TUN' "${vpn_ip:-off}" "$BAR_ACCENT")" \
    "$(segment 'DOCKER' "${docker_ip:-off}" "$BAR_MUTED")" \
    "$(segment 'TARGET' "${target:-none}" "$BAR_ACCENT")" \
    "$(segment 'VPN' "$vpn_state" "$([[ "$vpn_state" == "VPN:up" ]] && printf '%s' "$BAR_ACCENT" || printf '%s' "$BAR_ALERT")")" \
    "$(segment 'TIME' "$clock")"
}

bar_geometry() {
  local width

  width="$(xrandr 2>/dev/null | awk '/ connected/ {for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+x[0-9]+\+/) {sub(/x.*/, "", $i); print $i; exit}}' | head -n1)"

  if [[ -n "${width:-}" ]]; then
    printf '%sx24+0+0' "$width"
  else
    printf '1920x24+0+0'
  fi
}

launch_bar() {
  load_theme_defaults
  while :; do
    render_line
    REFRESH_FLAG=0

    for _ in {1..10}; do
      sleep 1
      [[ $REFRESH_FLAG -eq 1 ]] && break
    done
  done | lemonbar -p -d -B "$BAR_BG" -F "$BAR_FG" -f "$BAR_FONT" -g "$(bar_geometry)"
}

if [[ -f "$BAR_PID_FILE" ]]; then
  old_pid="$(cat "$BAR_PID_FILE" 2>/dev/null || true)"
  if [[ -n "${old_pid:-}" && "$old_pid" != "$$" ]] && kill -0 "$old_pid" 2>/dev/null; then
    kill "$old_pid" 2>/dev/null || true
    sleep 1
  fi
fi

printf '[%s] starting kdc-bar pid=%s\n' "$(date '+%F %T')" "$$" >> "$BAR_LOG_FILE"
printf '%s\n' "$$" > "$BAR_PID_FILE"

launch_bar
