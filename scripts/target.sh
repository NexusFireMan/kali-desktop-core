#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="${HOME}/.config/target"

notify_bar() {
  pkill -USR1 -f kdc-bar 2>/dev/null || true
}

ensure_target_dir() {
  mkdir -p "$(dirname "$TARGET_FILE")"
}

cmd_set() {
  local value="${1:-}"
  [[ -n "$value" ]] || { echo "Uso: $0 set <valor>"; exit 1; }
  ensure_target_dir
  printf '%s\n' "$value" > "$TARGET_FILE"
  notify_bar
  printf 'TARGET establecido: %s\n' "$value"
}

cmd_clear() {
  ensure_target_dir
  : > "$TARGET_FILE"
  notify_bar
  echo "TARGET limpiado"
}

cmd_show() {
  if [[ -s "$TARGET_FILE" ]]; then
    printf 'TARGET = %s\n' "$(tr -d '\n' < "$TARGET_FILE")"
  else
    echo "TARGET no establecido"
  fi
}

case "${1:-show}" in
  set)
    shift
    cmd_set "${1:-}"
    ;;
  clear)
    cmd_clear
    ;;
  show)
    cmd_show
    ;;
  *)
    echo "Uso: $0 {set|clear|show}"
    exit 1
    ;;
esac
