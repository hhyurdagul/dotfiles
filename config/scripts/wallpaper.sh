# Runs swaybg with the light or dark wallpaper for the saved theme mode.
# theme-switcher restarts wallpaper.service after it changes the mode.
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/theme/mode"

mode="dark"
if [[ -r "$STATE_FILE" ]]; then
	mode="$(tr -d '[:space:]' <"$STATE_FILE")"
fi

if [[ "$mode" == "light" ]]; then
	image="$LIGHT_WALLPAPER"
else
	image="$DARK_WALLPAPER"
fi

exec swaybg --mode fill --image "$image"
