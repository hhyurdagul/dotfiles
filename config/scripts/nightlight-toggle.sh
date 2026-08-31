#!/usr/bin/env bash
# ==============================================================================
# Night Light / Blue Light Filter Controller (wlsunset + hyprsunset)
# Toggles between warm eye-protection color temperature and neutral (6500K)
# ==============================================================================

set -eo pipefail

# Default night temperature (2500K for deep warm filter, 3500K for balanced)
NIGHT_TEMP="${NIGHT_TEMP:-2500}"
DAY_TEMP="${DAY_TEMP:-6500}"
LAT="41.0082"
LNG="28.9784"

# Find wlsunset and hyprsunset binaries (in PATH or Nix store)
find_bin() {
    local name="$1"
    if command -v "$name" >/dev/null 2>&1; then
        command -v "$name"
    else
        for p in /run/current-system/sw/bin/"$name" /etc/profiles/per-user/"$USER"/bin/"$name" /nix/store/*-"$name"-*/bin/"$name"; do
            if [ -x "$p" ]; then
                echo "$p"
                return 0
            fi
        done
    fi
}

WLSUNSET_BIN="$(find_bin wlsunset)"
HYPRSUNSET_BIN="$(find_bin hyprsunset)"

is_active() {
    pgrep -x wlsunset >/dev/null 2>&1 || pgrep -x hyprsunset >/dev/null 2>&1
}

turn_off() {
    pkill -x wlsunset 2>/dev/null || true
    pkill -x hyprsunset 2>/dev/null || true
    echo "Night light turned OFF (Neutral 6500K)."
}

turn_on() {
    # Ensure any previous instances are cleared first
    pkill -x wlsunset 2>/dev/null || true
    pkill -x hyprsunset 2>/dev/null || true
    sleep 0.1

    local temp="${1:-$NIGHT_TEMP}"

    if [ -n "$WLSUNSET_BIN" ]; then
        "$WLSUNSET_BIN" -l "$LAT" -L "$LNG" -t "$temp" -T "$DAY_TEMP" >/dev/null 2>&1 &
        disown
        echo "Night light turned ON (wlsunset: Night ${temp}K, Day ${DAY_TEMP}K)."
    elif [ -n "$HYPRSUNSET_BIN" ]; then
        "$HYPRSUNSET_BIN" -t "$temp" >/dev/null 2>&1 &
        disown
        echo "Night light turned ON (hyprsunset: ${temp}K)."
    else
        echo "Error: Neither wlsunset nor hyprsunset was found."
        exit 1
    fi
}

ACTION="${1:-toggle}"

case "$ACTION" in
    on)
        turn_on "${2:-$NIGHT_TEMP}"
        ;;
    off)
        turn_off
        ;;
    toggle)
        if is_active; then
            turn_off
        else
            turn_on "$NIGHT_TEMP"
        fi
        ;;
    status)
        if is_active; then
            echo "active"
        else
            echo "inactive"
        fi
        ;;
    temp)
        if [ -n "$2" ]; then
            turn_on "$2"
        else
            echo "Current target temp: ${NIGHT_TEMP}K"
        fi
        ;;
    *)
        echo "Usage: $0 [toggle|on|off|status|temp <kelvin>]"
        exit 1
        ;;
esac
