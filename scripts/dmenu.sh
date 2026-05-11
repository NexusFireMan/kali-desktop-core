#!/usr/bin/env bash
set -euo pipefail

DMENU_CONFIG="${HOME}/.config/dmenu/config"

DMENU_STYLE="-i -l 12 -p run"
DMENU_FONT="JetBrainsMono Nerd Font-11"
DMENU_NORMAL_BG="#14171d"
DMENU_NORMAL_FG="#d0d0d0"
DMENU_SELECTED_BG="#2f3440"
DMENU_SELECTED_FG="#d0d0d0"

if [[ -f "$DMENU_CONFIG" ]]; then
  # shellcheck disable=SC1090
  source "$DMENU_CONFIG"
fi

read -r -a DMENU_STYLE_ARGS <<< "$DMENU_STYLE"

exec dmenu_run \
  -fn "$DMENU_FONT" \
  -nb "$DMENU_NORMAL_BG" \
  -nf "$DMENU_NORMAL_FG" \
  -sb "$DMENU_SELECTED_BG" \
  -sf "$DMENU_SELECTED_FG" \
  "${DMENU_STYLE_ARGS[@]}"
