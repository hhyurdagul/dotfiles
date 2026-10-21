#!/usr/bin/env bash
set -euo pipefail

# Usage: focus-or-launch APP_ID COMMAND [ARGS...]
# Focus the most recently used Niri window with this exact app-id, even on
# another workspace or output; start COMMAND only when no such window exists.
if (($# < 2)); then
  printf 'Usage: focus-or-launch APP_ID COMMAND [ARGS...]\n' >&2
  exit 2
fi
app_id=$1
shift

id=$(niri msg --json windows | jq -r --arg app "$app_id" '
  [.[] | select(.app_id == $app)]
  | max_by(.focus_timestamp.secs // 0, .focus_timestamp.nanos // 0)
  | .id // empty
')
if [[ -n "$id" ]]; then
  exec niri msg action focus-window --id "$id"
fi
exec "$@"
