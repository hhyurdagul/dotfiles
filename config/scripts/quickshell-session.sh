#!/usr/bin/env bash
set -euo pipefail

# A lingering user manager can retain the previous compositor's signature.
# Resolve the live instance on this Wayland display before Quickshell opens IPC.
for _attempt in {1..40}; do
  signature=$(hyprctl instances -j | jq -r --arg display "${WAYLAND_DISPLAY:-}" '
    [.[] | select(.wl_socket == $display)] |
    if length == 1 then .[0].instance else empty end
  ') || signature=""
  if [[ -n "$signature" ]]; then
    export HYPRLAND_INSTANCE_SIGNATURE="$signature"
    if hyprctl -j activeworkspace | jq -e 'type == "object"' >/dev/null 2>&1; then
      exec quickshell --no-duplicate "$@"
    fi
  fi
  sleep 0.25
done

printf 'No ready Hyprland instance for %s\n' "${WAYLAND_DISPLAY:-unset}" >&2
exit 1
