#!/usr/bin/env bash
set -euo pipefail

for _attempt in {1..40}; do
  if niri msg --json version >/dev/null 2>&1; then
    exec quickshell --no-duplicate "$@"
  fi
  sleep 0.25
done
printf 'No ready Niri instance for %s\n' "${WAYLAND_DISPLAY:-unset}" >&2
exit 1
