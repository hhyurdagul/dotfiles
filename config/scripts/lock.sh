#!/usr/bin/env bash
set -euo pipefail

if ! pgrep -x hyprlock >/dev/null; then
	hyprlock &
fi

loginctl lock-session
