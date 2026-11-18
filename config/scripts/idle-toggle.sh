#!/usr/bin/env bash
set -euo pipefail

# hypridle keeps running either way, so lock-before-sleep is never lost; the
# idle-inhibit unit only pauses its idle timeouts.
if systemctl --user is-active --quiet idle-inhibit.service; then
	systemctl --user stop idle-inhibit.service
	notify-send -u normal -a "Idle Inhibitor" "Idle Management Enabled" \
		"Automatic dimming, screen-off, and suspend are active."
else
	systemctl --user start idle-inhibit.service
	notify-send -u normal -a "Idle Inhibitor" "Idle Management Disabled" \
		"Automatic dimming, screen-off, and suspend are off. The screen still locks before sleep."
fi
