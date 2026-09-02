#!/usr/bin/env bash
# Toggle hypridle daemon on / off

if pgrep -x "hypridle" >/dev/null 2>&1; then
    pkill -x "hypridle"
    notify-send -u normal -a "Idle Inhibitor" "Idle Management Disabled" "Hypridle stopped. Screen will not lock or sleep automatically."
else
    hypridle &
    notify-send -u normal -a "Idle Inhibitor" "Idle Management Enabled" "Hypridle started. Screen will dim, lock, and sleep automatically."
fi
