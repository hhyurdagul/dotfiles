#!/usr/bin/env bash
set -euo pipefail

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="$STATE_HOME/theme"
STATE_FILE="$STATE_DIR/mode"
KITTY_STATE_FILE="$STATE_DIR/kitty.conf"
MODE="${1:-toggle}"
FROM_DARKMAN=0

mkdir -p "$STATE_DIR"

if [[ "${2:-}" == "--from-darkman" || "$MODE" == "--from-darkman" ]]; then
	FROM_DARKMAN=1
fi

get_current_mode() {
	if [[ -r "$STATE_FILE" ]]; then
		tr -d '[:space:]' <"$STATE_FILE"
	else
		printf '%s\n' dark
	fi
}

CURRENT_MODE="$(get_current_mode)"
case "$CURRENT_MODE" in
light | dark) ;;
*) CURRENT_MODE="dark" ;;
esac

if [[ "$MODE" == "get" ]]; then
	printf '%s\n' "$CURRENT_MODE"
	exit 0
fi

case "$MODE" in
toggle)
	if [[ "$CURRENT_MODE" == "light" ]]; then
		TARGET_MODE="dark"
	else
		TARGET_MODE="light"
	fi
	;;
light | dark)
	TARGET_MODE="$MODE"
	;;
init)
	if command -v darkman >/dev/null 2>&1; then
		DARKMAN_MODE="$(darkman get 2>/dev/null || true)"
	else
		DARKMAN_MODE=""
	fi

	case "$DARKMAN_MODE" in
	*light*) TARGET_MODE="light" ;;
	*dark*) TARGET_MODE="dark" ;;
	*) TARGET_MODE="$CURRENT_MODE" ;;
	esac
	;;
*)
	printf 'Usage: %s [light|dark|toggle|get|init] [--from-darkman]\n' "$0" >&2
	exit 2
	;;
esac

tmp_mode="$(mktemp "$STATE_DIR/.mode.XXXXXX")"
printf '%s\n' "$TARGET_MODE" >"$tmp_mode"
mv "$tmp_mode" "$STATE_FILE"

if [[ "$TARGET_MODE" == "light" ]]; then
	COLOR_SCHEME="prefer-light"
	GTK_THEME="Adwaita"
	PREFER_DARK=0
	KITTY_THEME="$CONFIG_HOME/kitty/themes/catppuccin-latte.conf"
	WALLPAPER="$CONFIG_HOME/hypr/wallpapers/light.png"
else
	COLOR_SCHEME="prefer-dark"
	GTK_THEME="Adwaita-dark"
	PREFER_DARK=1
	KITTY_THEME="$CONFIG_HOME/kitty/themes/catppuccin-mocha.conf"
	WALLPAPER="$CONFIG_HOME/hypr/wallpapers/dark.png"
fi

if command -v gsettings >/dev/null 2>&1; then
	gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME" || true
	gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" || true
fi

for gtk_version in gtk-3.0 gtk-4.0; do
	gtk_dir="$CONFIG_HOME/$gtk_version"
	mkdir -p "$gtk_dir"
	tmp_gtk="$(mktemp "$gtk_dir/.settings.ini.XXXXXX")"
	cat >"$tmp_gtk" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-application-prefer-dark-theme=$PREFER_DARK
gtk-font-name=JetBrainsMono Nerd Font 10
EOF
	mv "$tmp_gtk" "$gtk_dir/settings.ini"
done

if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
	if [[ "$TARGET_MODE" == "light" ]]; then
		hyprctl eval 'hl.config({ general = { col = { active_border = { colors = {"rgba(1e66f5ee)", "rgba(04a5e5ee)"}, angle = 45 }, inactive_border = "rgba(bcc0ccaa)" } }, decoration = { shadow = { color = 0x33000000 } } })' >/dev/null || true
	else
		hyprctl eval 'hl.config({ general = { col = { active_border = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 }, inactive_border = "rgba(595959aa)" } }, decoration = { shadow = { color = 0xee1a1a1a } } })' >/dev/null || true
	fi

	if [[ -r "$WALLPAPER" ]]; then
		hyprctl hyprpaper wallpaper ",$WALLPAPER" >/dev/null 2>&1 || true
	fi
fi

if [[ -r "$KITTY_THEME" ]]; then
	tmp_kitty="$(mktemp "$STATE_DIR/.kitty.conf.XXXXXX")"
	cp -- "$KITTY_THEME" "$tmp_kitty"
	mv "$tmp_kitty" "$KITTY_STATE_FILE"
	pkill -USR1 -x kitty 2>/dev/null || true
fi

if [[ "$FROM_DARKMAN" -eq 0 && "$MODE" != "init" ]] && command -v darkman >/dev/null 2>&1; then
	darkman set "$TARGET_MODE" >/dev/null 2>&1 || true
fi

printf 'Theme set to %s.\n' "$TARGET_MODE"
