#!/bin/bash

# This script intelligently adjusts the brightness of the currently focused monitor.
# It detects if the monitor is internal or external and uses the appropriate tool.
#
# Usage: ./adjust-brightness.sh [up|down]

# --- CONFIGURATION ---
# Set the identifying name of your internal display.
# Find this by running 'hyprctl monitors' (e.g., eDP-1, eDP-2).
INTERNAL_MONITOR_NAME="eDP-1"

##
# Finds the focused monitor and returns its type, identifier, and name.
#
# This function determines if the display is internal or external.
# It echoes a space-separated string with three values:
# - For internal: "internal [monitor_name] [monitor_name]"
# - For external: "external [ddcutil_id] [monitor_name]"
#
# It returns a non-zero exit code on failure.
##
get_focused_monitor_info() {
    # Get the info block for the monitor that has "focused: yes"
    local focused_block
    focused_block=$(hyprctl monitors | awk 'BEGIN{RS="\n\n"} /focused: yes/')

    if [[ -z "$focused_block" ]]; then
        echo "❌ Error: Could not find a focused monitor." >&2
        return 1
    fi

    # From the block, get the monitor's name (e.g., 'eDP-1' or 'HDMI-A-1')
    local monitor_name
    monitor_name=$(echo "$focused_block" | awk '/^Monitor/ {print $2}')

    # Check if the name matches the configured internal monitor name
    if [[ "$monitor_name" == *"$INTERNAL_MONITOR_NAME"* ]]; then
        # For internal displays, the identifier is the name itself.
        echo "internal $monitor_name $monitor_name"
        return 0
    else
        # For external displays, find the ddcutil number via its serial.
        local focused_serial
        focused_serial=$(echo "$focused_block" | awk '/^\s*serial:/ {print $2}')

        if [[ -z "$focused_serial" ]]; then
            echo "❌ Error: Could not find serial number for external monitor '$monitor_name'." >&2
            return 1
        fi

        local ddcutil_block
        ddcutil_block=$(ddcutil detect | awk -v serial="$focused_serial" 'BEGIN{RS="\n\n"} $0 ~ serial')

        local display_number
        display_number=$(echo "$ddcutil_block" | awk 'NR==1 {print $2}')

        if [[ -z "$display_number" ]]; then
            echo "❌ Error: Could not match serial '$focused_serial' to a ddcutil display." >&2
            return 1
        fi

        # On success, output the type, ddcutil ID, and monitor name
        echo "external $display_number $monitor_name"
        return 0
    fi
}

##
# Increases the brightness of the focused monitor.
##
increase_brightness() {
    echo "🔆 Increasing brightness..."
    local monitor_info
    monitor_info=$(get_focused_monitor_info)

    # Check if the info-gathering function failed
    if [[ $? -ne 0 ]]; then
        echo "Aborting." >&2
        return 1
    fi

    # Read the type, identifier, and name from the function's output
    local monitor_type identifier monitor_name
    read -r monitor_type identifier monitor_name <<< "$monitor_info"

    echo "✅ Adjusting brightness for monitor: '$monitor_name'"

    if [[ "$monitor_type" == "internal" ]]; then
        echo "-> Using brightnessctl for internal display."
        brightnessctl -e4 -n2 set 5%+
    elif [[ "$monitor_type" == "external" ]]; then
        echo "-> Using ddcutil for external display (ID: $identifier)."
        ddcutil --display "$identifier" setvcp 10 + 5
    fi
}

##
# Decreases the brightness of the focused monitor.
##
decrease_brightness() {
    echo "🔅 Decreasing brightness..."
    local monitor_info
    monitor_info=$(get_focused_monitor_info)

    if [[ $? -ne 0 ]]; then
        echo "Aborting." >&2
        return 1
    fi

    local monitor_type identifier monitor_name
    read -r monitor_type identifier monitor_name <<< "$monitor_info"
    
    echo "✅ Adjusting brightness for monitor: '$monitor_name'"

    if [[ "$monitor_type" == "internal" ]]; then
        echo "-> Using brightnessctl for internal display."
        brightnessctl -e4 -n2 set 5%-
    elif [[ "$monitor_type" == "external" ]]; then
        echo "-> Using ddcutil for external display (ID: $identifier)."
        ddcutil --display "$identifier" setvcp 10 - 5
    fi
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
        increase_brightness
        ;;
    down|decrease|-)
        decrease_brightness
        ;;
    *)
        echo "Error: Invalid argument '$1'."
        echo "Usage: $0 [up|down]"
        exit 1
        ;;
esac
