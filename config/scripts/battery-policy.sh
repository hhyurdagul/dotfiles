# On battery: power-saver and 60 Hz on the laptop panel. On AC, restore 120 Hz
# and leave a manual performance choice alone; only power-saver is promoted
# back to balanced. The panel change is Niri-only.

online() {
	cat /sys/class/power_supply/ADP1/online 2>/dev/null || printf '1\n'
}

apply() {
	local rate current
	if [[ "$(online)" == "1" ]]; then
		current="$(powerprofilesctl get 2>/dev/null || true)"
		if [[ "$current" == "power-saver" ]]; then
			powerprofilesctl set balanced || true
		fi
		rate=120
	else
		powerprofilesctl set power-saver || true
		rate=60
	fi

	if [[ -n "${NIRI_SOCKET:-}" ]] && niri msg --json outputs | jq -e 'has("eDP-1")' >/dev/null 2>&1; then
		niri msg output eDP-1 mode "2880x1800@${rate}" || true
	fi
}

# upower reports every battery and peripheral update, several a minute. Act only
# when AC state changes, so a profile picked by hand survives until the next plug
# event.
last=""
check() {
	local now
	now="$(online)"
	[[ "$now" == "$last" ]] && return
	last="$now"
	apply
}

check
while read -r _; do
	check
done < <(upower --monitor)
