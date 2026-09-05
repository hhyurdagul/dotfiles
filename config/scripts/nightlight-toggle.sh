#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-toggle}"

is_active() {
	systemctl --user is-active --quiet wlsunset.service
}

turn_on() {
	systemctl --user start wlsunset.service
	notify-send -u low -a "Night Light" "Night light enabled"
}

turn_off() {
	systemctl --user stop wlsunset.service
	notify-send -u low -a "Night Light" "Night light disabled"
}

case "$ACTION" in
on)
	turn_on
	;;
off)
	turn_off
	;;
toggle)
	if is_active; then
		turn_off
	else
		turn_on
	fi
	;;
status)
	if is_active; then
		printf '%s\n' active
	else
		printf '%s\n' inactive
	fi
	;;
*)
	printf 'Usage: %s [toggle|on|off|status]\n' "$0" >&2
	exit 2
	;;
esac
