#!/bin/bash

# Script to open Alacritty or create a new window if already running.

# Check if an Alacritty process is running using AppleScript
# This is generally more reliable on macOS for GUI apps than pgrep.
alacritty_running=$(osascript -e 'tell application "System Events" to (count processes whose name is "Alacritty")')

if [ "$alacritty_running" -gt 0 ]; then
  # Alacritty is running
  echo "Alacritty is running. Sending message to create a new window..."
  # Ensure 'alacritty' command is in your PATH
  if command -v alacritty &> /dev/null; then
    alacritty msg create-window
  else
    echo "Error: 'alacritty' command not found in PATH."
    echo "Cannot send 'create-window' message."
    # Optional: Fallback to just bringing Alacritty to the front
    # osascript -e 'tell application "Alacritty" to activate'
    exit 1
  fi
else
  # Alacritty is not running
  echo "Alacritty is not running. Opening the application..."
  open -a Alacritty
fi

echo "Script finished."
exit 0
