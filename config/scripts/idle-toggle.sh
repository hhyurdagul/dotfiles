#!/usr/bin/env bash
set -euo pipefail

if systemctl --user is-active --quiet hypridle.service; then
	systemctl --user stop hypridle.service
	notify-send -u normal -a "Idle Inhibitor" "Idle Management Disabled" \
		"Automatic dimming, screen-off, and suspend are off."
else
	systemctl --user start hypridle.service
	notify-send -u normal -a "Idle Inhibitor" "Idle Management Enabled" \
		"Automatic dimming, screen-off, and suspend are active."
fi
