#!/usr/bin/env bash
set -euo pipefail

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="$STATE_HOME/theme"
STATE_FILE="$STATE_DIR/mode"
MODE="${1:-toggle}"
FROM_DARKMAN=0

mkdir -p "$STATE_DIR"

if [[ "${2:-}" == "--from-darkman" ]]; then
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
	GTK_THEME="adw-gtk3"
	PREFER_DARK=0
else
	COLOR_SCHEME="prefer-dark"
	GTK_THEME="adw-gtk3-dark"
	PREFER_DARK=1
fi

if command -v gsettings >/dev/null 2>&1; then
	# Electron apps re-derive dark mode from the GTK theme name and get it
	# wrong; color-scheme, which they read correctly, has to be the last
	# change they see. Thunar is GTK3 and only has adw-gtk3 installed.
	gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" || true
	gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME" || true
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
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=$CURSOR_SIZE
EOF
	mv "$tmp_gtk" "$gtk_dir/settings.ini"
done

# Included by Niri after its static defaults; atomic replacement triggers a
# native config reload. Runtime state stays out of the Home Manager symlink.
# Colors are the Quickshell Ember/Dust palette (config/quickshell/Theme.qml).
if [[ "$TARGET_MODE" == "light" ]]; then
	NIRI_FROM="#b0521aee"
	NIRI_TO="#8a5f0aee"
	NIRI_INACTIVE="#8f8173aa"
	NIRI_SHADOW="#00000033"
	NIRI_BACKGROUND="#f5ede3"
else
	NIRI_FROM="#e8955eee"
	NIRI_TO="#ecc27aee"
	NIRI_INACTIVE="#7d6f64aa"
	NIRI_SHADOW="#12100fee"
	NIRI_BACKGROUND="#1a1715"
fi
tmp_niri="$(mktemp "$STATE_DIR/.niri.XXXXXX")"
cat >"$tmp_niri" <<EOF
layout {
    border {
        active-gradient from="$NIRI_FROM" to="$NIRI_TO" angle=45
        inactive-color "$NIRI_INACTIVE"
    }
    shadow { color "$NIRI_SHADOW"; }
}
overview { backdrop-color "$NIRI_BACKGROUND"; }
EOF
mv "$tmp_niri" "$STATE_DIR/niri.kdl"

# Included by the linked fuzzel.ini; fuzzel reads it on every launch. The
# translucent background lets niri's launcher layer rule blur behind it.
if [[ "$TARGET_MODE" == "light" ]]; then
	FUZZEL_BG="f5ede3d9"
	FUZZEL_FG="3a302aff"
	FUZZEL_DIM="5e5249ff"
	FUZZEL_MUTED="8f8173ff"
	FUZZEL_ACCENT="b0521aff"
	FUZZEL_SELECTION="d9d1c7ff"
else
	FUZZEL_BG="1a1715d9"
	FUZZEL_FG="ebdfd2ff"
	FUZZEL_DIM="bcae9fff"
	FUZZEL_MUTED="7d6f64ff"
	FUZZEL_ACCENT="e8955eff"
	FUZZEL_SELECTION="393531ff"
fi
tmp_fuzzel="$(mktemp "$STATE_DIR/.fuzzel.XXXXXX")"
cat >"$tmp_fuzzel" <<EOF
[colors]
background=$FUZZEL_BG
text=$FUZZEL_FG
message=$FUZZEL_DIM
prompt=$FUZZEL_DIM
placeholder=$FUZZEL_MUTED
input=$FUZZEL_FG
match=$FUZZEL_ACCENT
selection=$FUZZEL_SELECTION
selection-text=$FUZZEL_FG
selection-match=$FUZZEL_ACCENT
counter=$FUZZEL_MUTED
border=$FUZZEL_ACCENT
EOF
mv "$tmp_fuzzel" "$STATE_DIR/fuzzel.ini"

# Only restarts a running wallpaper; at login wallpaper.service starts after
# theme-initialize and reads the mode itself. --no-block: when this runs inside
# theme-initialize (a rebuild restarts it while the wallpaper runs), the queued
# start waits for theme-initialize, so waiting here would deadlock.
systemctl --user --no-block try-restart wallpaper.service || true

if [[ "$FROM_DARKMAN" -eq 0 && "$MODE" != "init" ]] && command -v darkman >/dev/null 2>&1; then
	darkman set "$TARGET_MODE" >/dev/null 2>&1 || true
fi

printf 'Theme set to %s.\n' "$TARGET_MODE"
