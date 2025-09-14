#!/bin/bash

# This script adjusts the brightness for ALL connected monitors.
# It uses the appropriate command for internal vs. external displays.
#
# Usage: ./adjust-all-brightness.sh [up|down]

# --- CONFIGURATION ---

# 1. Set the command for Hyprland. Usually 'hyprctl'.
HYPRCTL_CMD="hyprctl"

# 2. Set the identifying name of your internal display.
#    Find this by running 'hyprctl monitors' (e.g., eDP-1).
INTERNAL_MONITOR_NAME="eDP-1"

##
# Increases the brightness of all monitors.
##
increase_brightness_all() {
    echo "🔆 Increasing brightness for all monitors..."

    # Fetch detection results once to avoid running slow commands in a loop
    local ddcutil_output
    ddcutil_output=$(ddcutil detect)

    # Use a null-character separated stream to safely read each monitor block
    while IFS= read -r -d '' monitor_block; do
        # Skip empty blocks
        if [[ -z "$monitor_block" ]]; then continue; fi

        local monitor_name
        monitor_name=$(echo "$monitor_block" | awk '/^Monitor/ {print $2}')

        echo "-> Processing monitor: '$monitor_name'"

        # Check if the current monitor is the configured internal one
        if [[ "$monitor_name" == *"$INTERNAL_MONITOR_NAME"* ]]; then
            echo "   - Internal display. Using brightnessctl..."
            brightnessctl -e4 -n2 set 5%+
        else
            echo "   - External display. Using ddcutil..."
            local serial
            serial=$(echo "$monitor_block" | awk '/^\s*serial:/ {print $2}')

            if [[ -z "$serial" ]]; then
                echo "   - ⚠️ Warning: No serial number for '$monitor_name'. Skipping."
                continue
            fi
            
            # Find the matching ddcutil display using the serial number
            local display_number
            display_number=$(echo "$ddcutil_output" | awk -v s="$serial" 'BEGIN{RS="\n\n"} $0 ~ s' | awk 'NR==1 {print $2}')
            
            if [[ -z "$display_number" ]]; then
                echo "   - ⚠️ Warning: Could not find ddcutil match for '$monitor_name' (Serial: $serial). Skipping."
                continue
            fi

            echo "   - Found ddcutil ID '$display_number'. Adjusting brightness."
            ddcutil --display "$display_number" setvcp 10 + 5
        fi
    done < <($HYPRCTL_CMD monitors | awk 'BEGIN{RS="\n\n"; ORS="\0"} {print}')
}

##
# Decreases the brightness of all monitors.
##
decrease_brightness_all() {
    echo "🔅 Decreasing brightness for all monitors..."

    local ddcutil_output
    ddcutil_output=$(ddcutil detect)

    while IFS= read -r -d '' monitor_block; do
        if [[ -z "$monitor_block" ]]; then continue; fi

        local monitor_name
        monitor_name=$(echo "$monitor_block" | awk '/^Monitor/ {print $2}')

        echo "-> Processing monitor: '$monitor_name'"

        if [[ "$monitor_name" == *"$INTERNAL_MONITOR_NAME"* ]]; then
            echo "   - Internal display. Using brightnessctl..."
            brightnessctl -e4 -n2 set 5%-
        else
            echo "   - External display. Using ddcutil..."
            local serial
            serial=$(echo "$monitor_block" | awk '/^\s*serial:/ {print $2}')

            if [[ -z "$serial" ]]; then
                echo "   - ⚠️ Warning: No serial number for '$monitor_name'. Skipping."
                continue
            fi
            
            local display_number
            display_number=$(echo "$ddcutil_output" | awk -v s="$serial" 'BEGIN{RS="\n\n"} $0 ~ s' | awk 'NR==1 {print $2}')
            
            if [[ -z "$display_number" ]]; then
                echo "   - ⚠️ Warning: Could not find ddcutil match for '$monitor_name' (Serial: $serial). Skipping."
                continue
            fi

            echo "   - Found ddcutil ID '$display_number'. Adjusting brightness."
            ddcutil --display "$display_number" setvcp 10 - 5
        fi
    done < <($HYPRCTL_CMD monitors | awk 'BEGIN{RS="\n\n"; ORS="\0"} {print}')
}


################
# MAIN SCRIPT LOGIC
################

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 [up|down]"
    exit 1
fi

case "$1" in
    up|increase|+)
        increase_brightness_all
        ;;
    down|decrease|-)
        decrease_brightness_all
        ;;
    *)
        echo "Error: Invalid argument '$1'."
        echo "Usage: $0 [up|down]"
        exit 1
        ;;
esac

echo "✨ Done."
