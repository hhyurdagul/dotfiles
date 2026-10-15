#!/usr/bin/env bash
set -euo pipefail

# Read actual compositor state rather than an in-memory toggle that can drift.
if niri msg --json outputs | jq -e '.["eDP-1"].logical != null' >/dev/null; then
  exec niri msg output eDP-1 off
fi
exec niri msg output eDP-1 on
