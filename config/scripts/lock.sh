#!/usr/bin/env bash
set -euo pipefail

if ! pgrep -x swaylock >/dev/null; then
	swaylock --daemonize
fi

loginctl lock-session
