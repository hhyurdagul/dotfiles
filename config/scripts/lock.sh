#!/usr/bin/env bash
# Lock screen script using swaylock

if ! pidof swaylock >/dev/null 2>&1; then
    swaylock -f
fi
loginctl lock-session 2>/dev/null || true
