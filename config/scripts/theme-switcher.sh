#!/usr/bin/env bash
# ==============================================================================
# Universal Theme Switcher (Runtime Light / Dark Mode)
# Handles: XDG Desktop Portal, GTK 3/4, Qt, Hyprland, Kitty, Helix, Quickshell
# ==============================================================================

set -eo pipefail

STATE_DIR="$HOME/.config/theme"
STATE_FILE="$STATE_DIR/mode"
mkdir -p "$STATE_DIR"

MODE="${1:-toggle}"
FROM_DARKMAN=0

if [ "$2" = "--from-darkman" ] || [ "$MODE" = "--from-darkman" ]; then
    FROM_DARKMAN=1
fi

get_current_mode() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE" | tr -d '[:space:]'
    else
        echo "dark"
    fi
}

CURRENT_MODE="$(get_current_mode)"

if [ "$MODE" = "get" ]; then
    echo "$CURRENT_MODE"
    exit 0
fi

if [ "$MODE" = "toggle" ]; then
    if [ "$CURRENT_MODE" = "light" ]; then
        TARGET_MODE="dark"
    else
        TARGET_MODE="light"
    fi
elif [ "$MODE" = "light" ] || [ "$MODE" = "dark" ]; then
    TARGET_MODE="$MODE"
elif [ "$MODE" = "init" ]; then
    # On init, check darkman if running, otherwise use saved state or dark
    if command -v darkman >/dev/null 2>&1 && darkman get 2>/dev/null | grep -q "light"; then
        TARGET_MODE="light"
    elif command -v darkman >/dev/null 2>&1 && darkman get 2>/dev/null | grep -q "dark"; then
        TARGET_MODE="dark"
    else
        TARGET_MODE="$CURRENT_MODE"
    fi
else
    echo "Usage: $0 [light|dark|toggle|get|init] [--from-darkman]"
    exit 1
fi

echo "Switching theme to: $TARGET_MODE"
echo "$TARGET_MODE" > "$STATE_FILE"

# ------------------------------------------------------------------------------
# 1. XDG Desktop Portal & GTK (libadwaita, GTK4, GTK3, Web Browsers)
# ------------------------------------------------------------------------------
if [ "$TARGET_MODE" = "light" ]; then
    COLOR_SCHEME="prefer-light"
    GTK_THEME="Adwaita"
    PREFER_DARK=0
else
    COLOR_SCHEME="prefer-dark"
    GTK_THEME="Adwaita-dark"
    PREFER_DARK=1
fi

# Locate gsettings executable
GSETTINGS_CMD=""
if command -v gsettings >/dev/null 2>&1; then
    GSETTINGS_CMD="gsettings"
else
    for cand in /run/current-system/sw/bin/gsettings /etc/profiles/per-user/$USER/bin/gsettings /nix/store/*-glib-*-bin/bin/gsettings; do
        if [ -x "$cand" ]; then
            GSETTINGS_CMD="$cand"
            break
        fi
    done
fi

# Locate compiled GSettings schemas
SCHEMA_DIR=""
for cand in /run/current-system/sw/share/gsettings-schemas/*/glib-2.0/schemas /nix/store/*-gsettings-desktop-schemas-*/share/gsettings-schemas/*/glib-2.0/schemas; do
    if [ -d "$cand" ]; then
        SCHEMA_DIR="$cand"
        break
    fi
done

# Broadcast via gsettings (triggers xdg-desktop-portal SettingChanged signal)
if [ -n "$GSETTINGS_CMD" ]; then
    export GSETTINGS_BACKEND=dconf
    if [ -n "$SCHEMA_DIR" ]; then
        export GSETTINGS_SCHEMA_DIR="$SCHEMA_DIR"
    fi
    "$GSETTINGS_CMD" set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME" 2>/dev/null || true
    "$GSETTINGS_CMD" set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
fi

# Set in dconf database
if command -v dconf >/dev/null 2>&1; then
    dconf write /org/gnome/desktop/interface/color-scheme "'$COLOR_SCHEME'" 2>/dev/null || true
    dconf write /org/gnome/desktop/interface/gtk-theme "'$GTK_THEME'" 2>/dev/null || true
fi

# Write GTK 3.0 & 4.0 settings.ini
for gtk_ver in gtk-3.0 gtk-4.0; do
    mkdir -p "$HOME/.config/$gtk_ver"
    cat > "$HOME/.config/$gtk_ver/settings.ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-application-prefer-dark-theme=$PREFER_DARK
gtk-font-name=JetBrainsMono Nerd Font 10
EOF
done

# ------------------------------------------------------------------------------
# 2. Hyprland Borders, Shadows & Aesthetics
# ------------------------------------------------------------------------------
if command -v hyprctl >/dev/null 2>&1 && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    if [ "$TARGET_MODE" = "light" ]; then
        # Catppuccin Latte styling for borders & shadows
        hyprctl eval 'hl.config({ general = { col = { active_border = { colors = {"rgba(1e66f5ee)", "rgba(04a5e5ee)"}, angle = 45 }, inactive_border = "rgba(bcc0ccaa)" } }, decoration = { shadow = { color = 0x33000000 } } })' 2>/dev/null || true
    else
        # Catppuccin Mocha styling for borders & shadows
        hyprctl eval 'hl.config({ general = { col = { active_border = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 }, inactive_border = "rgba(595959aa)" } }, decoration = { shadow = { color = 0xee1a1a1a } } })' 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# 3. Kitty Terminal
# ------------------------------------------------------------------------------
KITTY_THEME_DIR="$HOME/.config/kitty/themes"
mkdir -p "$KITTY_THEME_DIR"
if [ "$TARGET_MODE" = "light" ]; then
    TARGET_KITTY_THEME="$KITTY_THEME_DIR/catppuccin-latte.conf"
else
    TARGET_KITTY_THEME="$KITTY_THEME_DIR/catppuccin-mocha.conf"
fi

if [ -f "$TARGET_KITTY_THEME" ]; then
    rm -f "$HOME/.config/kitty/theme.conf"
    cp -f "$TARGET_KITTY_THEME" "$HOME/.config/kitty/theme.conf"
    # Send SIGUSR1 to reload configuration across all active kitty windows
    pkill -SIGUSR1 kitty 2>/dev/null || true
    if command -v kitty >/dev/null 2>&1; then
        timeout 1s kitty @ --to=unix:@kitty set-colors --all "$TARGET_KITTY_THEME" 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# 4. Helix Editor (Updates config.toml for next launch or manual :config-reload)
# ------------------------------------------------------------------------------
HELIX_CONFIG="$HOME/.config/helix/config.toml"
if [ -f "$HELIX_CONFIG" ]; then
    if [ "$TARGET_MODE" = "light" ]; then
        sed -i 's/^theme = .*/theme = "catppuccin_latte"/' "$HELIX_CONFIG"
    else
        sed -i 's/^theme = .*/theme = "catppuccin_mocha"/' "$HELIX_CONFIG"
    fi
fi

# ------------------------------------------------------------------------------
# 5. Sync Darkman Daemon (if triggered manually)
# ------------------------------------------------------------------------------
if [ "$FROM_DARKMAN" -eq 0 ] && command -v darkman >/dev/null 2>&1; then
    darkman set "$TARGET_MODE" 2>/dev/null || true
fi

echo "Theme successfully set to $TARGET_MODE."
