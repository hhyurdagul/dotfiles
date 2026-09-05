#!/usr/bin/env bash
set -euo pipefail

if systemctl --user is-active --quiet hypridle.service; then
	systemctl --user stop hypridle.service
	notify-send -u normal -a "Idle Inhibitor" "Idle Management Disabled" \
		"The screen will not lock or suspend automatically."
else
	systemctl --user start hypridle.service
	notify-send -u normal -a "Idle Inhibitor" "Idle Management Enabled" \
		"Automatic dimming, locking, and suspend are active."
fi
