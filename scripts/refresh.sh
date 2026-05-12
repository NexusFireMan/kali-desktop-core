#!/usr/bin/env bash
set -euo pipefail

BAR_PID_FILE="${HOME}/.cache/kdc-bar.pid"

[[ -r "$BAR_PID_FILE" ]] || exit 0

pid=""
IFS= read -r pid < "$BAR_PID_FILE" || exit 0
[[ -n "${pid:-}" ]] || exit 0

case "$pid" in
  *[!0-9]*)
    exit 0
    ;;
esac

kill -0 "$pid" 2>/dev/null || exit 0
kill -USR1 "$pid" 2>/dev/null || true
