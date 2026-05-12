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

if ! declare -F is_command >/dev/null 2>&1; then
  is_command() {
    command -v "$1" >/dev/null 2>&1
  }
fi

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
  BAR_BG="${BAR_BG:-#0d0f12}"
  BAR_FG="${BAR_FG:-#d0d0d0}"
  BAR_MUTED="${BAR_MUTED:-#7f8792}"
  BAR_ACCENT="${BAR_ACCENT:-#8fb7ff}"
  BAR_ALERT="${BAR_ALERT:-#c75b65}"
  BAR_FONT="${BAR_FONT:-fixed}"
  BAR_HEIGHT="${BAR_HEIGHT:-24}"
  BAR_MARGIN_X="${BAR_MARGIN_X:-6}"
  BAR_OFFSET_Y="${BAR_OFFSET_Y:-0}"

  source_theme || true

  BAR_BG="${BAR_BG:-#0d0f12}"
  BAR_FG="${BAR_FG:-#d0d0d0}"
  BAR_MUTED="${BAR_MUTED:-#7f8792}"
  BAR_ACCENT="${BAR_ACCENT:-#8fb7ff}"
  BAR_ALERT="${BAR_ALERT:-#c75b65}"
  BAR_FONT="${BAR_FONT:-fixed}"
  BAR_HEIGHT="${BAR_HEIGHT:-24}"
  BAR_MARGIN_X="${BAR_MARGIN_X:-6}"
  BAR_OFFSET_Y="${BAR_OFFSET_Y:-0}"
  BAR_WS_ACTIVE="${BAR_WS_ACTIVE:-$BAR_ALERT}"
  BAR_WS_INACTIVE="${BAR_WS_INACTIVE:-$BAR_MUTED}"
  BAR_WS_SYMBOL="${BAR_WS_SYMBOL:-•}"
  BAR_WS_SEPARATOR="${BAR_WS_SEPARATOR:- }"
  BAR_WS_COUNT="${BAR_WS_COUNT:-5}"
  BAR_WS_STYLE="${BAR_WS_STYLE:-numbers}"
  BAR_POWER_ICON="${BAR_POWER_ICON:-PWR}"
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
  printf '[%s] kdc-bar: %s\n' "$(date '+%F %T')" "$1" >> "$BAR_LOG_FILE"
}

focused_workspace_num() {
  local output objects line active

  if ! is_command i3-msg; then
    bar_debug_log "i3-msg no está disponible; usando workspace activo 1"
    printf '1'
    return 0
  fi

  output="$(i3-msg -t get_workspaces 2>/dev/null || true)"
  if [[ -z "${output:-}" ]]; then
    bar_debug_log "i3-msg no devolvió workspaces; usando workspace activo 1"
    printf '1'
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
    if printf '%s\n' "$line" | grep -Eq '"focused"[[:space:]]*:[[:space:]]*true'; then
      active="$(printf '%s\n' "$line" | sed -n 's/.*"num"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')"
      if [[ -n "${active:-}" ]]; then
        printf '%s' "$active"
        return 0
      fi
    fi
  done <<< "$objects"

  bar_debug_log "no se pudo detectar workspace focused; usando workspace activo 1"
  printf '1'
}

workspace_dots() {
  local count="${BAR_WS_COUNT:-5}"
  local active i color label result

  if [[ ! "$count" =~ ^[0-9]+$ || "$count" -lt 1 ]]; then
    count=5
  fi

  active="$(focused_workspace_num)"
  if [[ ! "$active" =~ ^[0-9]+$ || "$active" -lt 1 ]]; then
    active=1
  fi

  bar_debug_log "active workspace detectado=$active, BAR_WS_COUNT=$count"

  result="  "
  for ((i = 1; i <= count; i++)); do
    if [[ $i -eq active ]]; then
      color="$BAR_ALERT"
    else
      color="$BAR_MUTED"
    fi

    if [[ "${BAR_WS_STYLE:-numbers}" == "dots" ]]; then
      label="$BAR_WS_SYMBOL"
    else
      label="$i"
    fi

    if [[ $i -gt 1 ]]; then
      if [[ "${BAR_WS_STYLE:-numbers}" == "dots" ]]; then
        result+="$BAR_WS_SEPARATOR"
      else
        result+="  "
      fi
    fi

    result+="%{F${color}}${label}%{F-}"
  done

  result+="  "
  bar_debug_log "string final de workspaces=$result"
  printf '%s' "$result"
}

power_button() {
  if [[ -x "$POWER_MENU" ]]; then
    bar_debug_log "power menu disponible: $POWER_MENU"
    printf '%%{A1:kdc-power-menu:}%%{F%s}%s%%{F-}%%{A}' "$BAR_POWER_COLOR" "$BAR_POWER_ICON"
  else
    if [[ -e "$POWER_MENU" ]]; then
      bar_debug_log "power menu no ejecutable: $POWER_MENU"
    else
      bar_debug_log "power menu no existe: $POWER_MENU"
    fi
    printf '%%{F%s}%s%%{F-}' "$BAR_POWER_COLOR" "$BAR_POWER_ICON"
  fi
}

handle_bar_action() {
  local action="$1"

  bar_debug_log "lemonbar emitió acción: $action"

  case "$action" in
    kdc-power-menu)
      if [[ -x "$POWER_MENU" ]]; then
        bar_debug_log "ejecutando kdc-power-menu: $POWER_MENU"
        "$POWER_MENU" >/dev/null 2>&1 &
      else
        bar_debug_log "POWER_MENU no ejecutable: $POWER_MENU"
      fi
      ;;
  esac
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
  [[ -z "$workspaces" ]] && workspaces="  1  2  3  4  5  "
  power="   $(power_button)"

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
  local screen_width bar_width

  screen_width="$({ xrandr 2>/dev/null || true; } | awk '/ connected/ {for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+x[0-9]+\+/) {sub(/x.*/, "", $i); print $i; exit}}' | head -n1)"

  if [[ ! "$screen_width" =~ ^[0-9]+$ || "$screen_width" -lt 1 ]]; then
    screen_width=1920
  fi

  if [[ ! "$BAR_HEIGHT" =~ ^[0-9]+$ || "$BAR_HEIGHT" -lt 1 ]]; then
    BAR_HEIGHT=24
  fi

  if [[ ! "$BAR_MARGIN_X" =~ ^[0-9]+$ ]]; then
    BAR_MARGIN_X=6
  fi

  if [[ ! "$BAR_OFFSET_Y" =~ ^[0-9]+$ ]]; then
    BAR_OFFSET_Y=0
  fi

  bar_width=$((screen_width - (BAR_MARGIN_X * 2)))
  if [[ $bar_width -lt 200 ]]; then
    printf '%sx%s+0+%s' "$screen_width" "$BAR_HEIGHT" "$BAR_OFFSET_Y"
  else
    printf '%sx%s+%s+%s' "$bar_width" "$BAR_HEIGHT" "$BAR_MARGIN_X" "$BAR_OFFSET_Y"
  fi
}

launch_bar() {
  local elapsed

  load_theme_defaults
  {
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
    done
  } \
    | lemonbar -p -d -B "$BAR_BG" -F "$BAR_FG" -f "$BAR_FONT" -g "$(bar_geometry)" \
    | while IFS= read -r action; do
        handle_bar_action "$action" || true
      done
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
