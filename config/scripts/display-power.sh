#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  on|off) ;;
  *) printf 'Usage: display-power on|off\n' >&2; exit 2 ;;
esac
desktop=${XDG_CURRENT_DESKTOP:-}
if [[ "${desktop,,}" == *niri* ]]; then
  exec niri msg action "power-$1-monitors"
fi
exec hyprctl dispatch dpms "$1"
