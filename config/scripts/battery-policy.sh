# On battery: power-saver and 60 Hz on the laptop panel. On AC: performance and
# 120 Hz. Only AC transitions (and startup) apply a profile, so a manual choice
# survives until the next plug event.

online() {
	cat /sys/class/power_supply/ADP1/online 2>/dev/null || printf '1\n'
}

apply() {
	local rate mode
	if [[ "$(online)" == "1" ]]; then
		powerprofilesctl set performance || true
		rate=120
	else
		powerprofilesctl set power-saver || true
		rate=60
	fi

	# The panel advertises 120.001/60.001 Hz and niri wants an exact match, so
	# look the mode up instead of asking for @120/@60.
	mode="$(niri msg --json outputs 2>/dev/null | jq -r --argjson rate "$rate" '
		[."eDP-1".modes[]? | select(.width == 2880 and .height == 1800
			and ((.refresh_rate / 1000) | round) == $rate)][0]
		| select(.) | "\(.width)x\(.height)@\(.refresh_rate / 1000)"')" || mode=""
	if [[ -n "$mode" ]]; then
		niri msg output eDP-1 mode "$mode" || true
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
