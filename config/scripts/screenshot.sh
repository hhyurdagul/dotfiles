#!/usr/bin/env bash
set -euo pipefail

# Serialize selection so repeated Print presses do not stack slurp overlays.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/screenshot-$UID.lock"
flock -n 9 || exit 0

args=()
case "${1:-area}" in
  area)
    geometry=$(slurp) || exit 0
    [[ -n "$geometry" ]] || exit 0
    args=(-g "$geometry")
    ;;
  full) ;;
  *) printf 'Usage: screenshot [area|full]\n' >&2; exit 2 ;;
esac

directory="$HOME/Pictures/Screenshots"
mkdir -p "$directory"
file="$directory/$(date +%Y-%m-%d_%H-%M-%S-%N).png"
if ! grim "${args[@]}" "$file"; then
  rm -f "$file"
  env -u LD_LIBRARY_PATH notify-send -u critical 'Screenshot failed' 'Could not capture the screen.' || true
  exit 1
fi

# wl-copy stays alive to serve the clipboard. Do not let that background process
# inherit the selection lock, or later Print presses can silently do nothing.
flock -u 9
exec 9>&-

if wl-copy --type image/png < "$file"; then
  env -u LD_LIBRARY_PATH notify-send 'Screenshot saved and copied' "$file" || true
else
  env -u LD_LIBRARY_PATH notify-send 'Screenshot saved' "$file (clipboard unavailable)" || true
fi
