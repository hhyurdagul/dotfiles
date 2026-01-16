#!/bin/bash

# TARGET DATE - Format: YYYY-MM-DD HH:MM:SS
TARGET="2026-01-01 00:00:00"

# Convert target to seconds since epoch
TARGET_S=$(date -d "$TARGET" +%s)
# Get current time in seconds
NOW_S=$(date +%s)

# Calculate difference
DIFF=$((TARGET_S - NOW_S))

if [ $DIFF -le 0 ]; then
    echo "Time's up!"
    exit 0
fi

# Calculate components
DAYS=$((DIFF / 86400))
HOURS=$(((DIFF % 86400) / 3600))
MINS=$(((DIFF % 3600) / 60))
SECS=$((DIFF % 60))

# Format the output (Edit this to change how it looks)
printf "%dd %02dh %02dm %02ds\n" $DAYS $HOURS $MINS $SECS
