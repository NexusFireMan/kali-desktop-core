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
BAR_REFRESH_SECONDS="${BAR_REFRESH_SECONDS:-3}"
POWER_MENU="${HOME}/.local/bin/kdc-power-menu"
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

  BAR_WS_ACTIVE="${BAR_WS_ACTIVE:-$BAR_ALERT}"
  BAR_WS_INACTIVE="${BAR_WS_INACTIVE:-$BAR_MUTED}"
  BAR_WS_SYMBOL="${BAR_WS_SYMBOL:-●}"
  BAR_WS_SEPARATOR="${BAR_WS_SEPARATOR:- }"
  BAR_WS_COUNT="${BAR_WS_COUNT:-5}"
  BAR_POWER_ICON="${BAR_POWER_ICON:-⏻}"
  BAR_POWER_COLOR="${BAR_POWER_COLOR:-$BAR_ALERT}"
}

segment() {
  local label="$1"
  local value="$2"
  local color="${3:-$BAR_FG}"

  printf "%%{F%s}%s%%{F%s} %s%%{F-}   " "$BAR_MUTED" "$label" "$color" "${value:---}"
}

bar_debug_log() {
  [[ "${KDC_BAR_DEBUG:-0}" == "1" ]] || return 0
  printf '[%s] workspace_dots: %s\n' "$(date '+%F %T')" "$1" >> "$BAR_LOG_FILE"
}

workspace_dots_fallback() {
  local count="${BAR_WS_COUNT:-5}"
  local i color

  if [[ ! "$count" =~ ^[0-9]+$ || "$count" -lt 1 ]]; then
    count=5
  fi

  for ((i = 1; i <= count; i++)); do
    if [[ $i -eq 1 ]]; then
      color="$BAR_WS_ACTIVE"
    else
      color="$BAR_WS_INACTIVE"
    fi

    if [[ $i -gt 1 ]]; then
      printf '%s' "$BAR_WS_SEPARATOR"
    fi

    printf '%%{F%s}%s%%{F-}' "$color" "$BAR_WS_SYMBOL"
  done
}

workspace_dots() {
  local output objects line focused color first=1 parsed=0 focused_found=0 result="" dot

  if ! is_command i3-msg; then
    bar_debug_log "i3-msg no está disponible; usando fallback"
    workspace_dots_fallback
    return 0
  fi

  output="$(i3-msg -t get_workspaces 2>/dev/null || true)"
  if [[ -z "${output:-}" ]]; then
    bar_debug_log "i3-msg no devolvió workspaces; usando fallback"
    workspace_dots_fallback
    return 0
  fi

  objects="$(
    printf '%s\n' "$output" \
      | sed 's#}[[:space:]]*,[[:space:]]*{#}\n{#g' \
      | sed 's/^\[//' \
      | sed 's/\]$//'
  )"

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    [[ "$line" == *'"name"'* || "$line" == *'"num"'* ]] || continue
    parsed=1

    focused=0
    if printf '%s\n' "$line" | grep -Eq '"focused"[[:space:]]*:[[:space:]]*true'; then
      focused=1
      focused_found=1
    fi

    if [[ $focused -eq 1 ]]; then
      color="$BAR_WS_ACTIVE"
    else
      color="$BAR_WS_INACTIVE"
    fi

    if [[ $first -eq 0 ]]; then
      result+="$BAR_WS_SEPARATOR"
    fi

    printf -v dot '%%{F%s}%s%%{F-}' "$color" "$BAR_WS_SYMBOL"
    result+="$dot"
    first=0
  done <<< "$objects"

  if [[ $parsed -eq 0 || $focused_found -eq 0 ]]; then
    if [[ $parsed -eq 0 ]]; then
      bar_debug_log "no se pudieron parsear workspaces; usando fallback"
    else
      bar_debug_log "no se pudo detectar workspace focused; usando fallback"
    fi
    workspace_dots_fallback
  else
    printf '%s' "$result"
  fi
}

power_button() {
  if [[ -x "$POWER_MENU" ]]; then
    printf '%%{A1:%s:}%%{F%s}%s%%{F-}%%{A}' "$POWER_MENU" "$BAR_POWER_COLOR" "$BAR_POWER_ICON"
  else
    printf '%%{F%s}%s%%{F-}' "$BAR_POWER_COLOR" "$BAR_POWER_ICON"
  fi
}

render_line() {
  local local_ip vpn_ip docker_ip target vpn_state clock workspaces power

  local_ip="$("$NETWORK_SCRIPT" local 2>/dev/null || true)"
  vpn_ip="$("$NETWORK_SCRIPT" vpn 2>/dev/null || true)"
  docker_ip="$("$NETWORK_SCRIPT" docker 2>/dev/null || true)"
  vpn_state="$("$NETWORK_SCRIPT" vpn-state 2>/dev/null || true)"
  target="$(read_target)"
  clock="$(date '+%H:%M')"
  workspaces="$(workspace_dots)"
  power="$(power_button)"

  printf "%%{l}%s%s%s%s%%{c}%s%%{r}%s%s%s\n" \
    "$(segment 'LAN' "${local_ip:-down}")" \
    "$(segment 'TUN' "${vpn_ip:-off}" "$BAR_ACCENT")" \
    "$(segment 'DOCKER' "${docker_ip:-off}" "$BAR_MUTED")" \
    "$(segment 'TARGET' "${target:-none}" "$BAR_ACCENT")" \
    "$workspaces" \
    "$(segment 'VPN' "$vpn_state" "$([[ "$vpn_state" == "VPN:up" ]] && printf '%s' "$BAR_ACCENT" || printf '%s' "$BAR_ALERT")")" \
    "$(segment 'TIME' "$clock")" \
    "$power"
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
  local elapsed

  load_theme_defaults
  while :; do
    render_line
    REFRESH_FLAG=0

    if [[ ! "$BAR_REFRESH_SECONDS" =~ ^[0-9]+$ || "$BAR_REFRESH_SECONDS" -lt 1 ]]; then
      BAR_REFRESH_SECONDS=3
    fi

    elapsed=0
    while [[ $elapsed -lt $BAR_REFRESH_SECONDS ]]; do
      sleep 1
      [[ $REFRESH_FLAG -eq 1 ]] && break
      elapsed=$((elapsed + 1))
    done
  done | lemonbar -p -d -B "$BAR_BG" -F "$BAR_FG" -f "$BAR_FONT" -g "$(bar_geometry)"
}

if [[ -f "$BAR_PID_FILE" ]]; then
  old_pid=""
  IFS= read -r old_pid < "$BAR_PID_FILE" || true
  if [[ -n "${old_pid:-}" && "$old_pid" != "$$" ]] && kill -0 "$old_pid" 2>/dev/null; then
    kill "$old_pid" 2>/dev/null || true
    sleep 1
  fi
fi

printf '[%s] starting kdc-bar pid=%s\n' "$(date '+%F %T')" "$$" >> "$BAR_LOG_FILE"
printf '%s\n' "$$" > "$BAR_PID_FILE"

launch_bar
