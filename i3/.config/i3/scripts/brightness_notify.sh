#!/bin/bash

# Get current brightness level using brightnessctl
BRIGHTNESS=$(brightnessctl g | awk '{printf "%.0f", ($1 / 5) / 10 }')
BRIGHTNESS=$((BRIGHTNESS * 10))

# Choose an icon based on brightness level
if [ "$BRIGHTNESS" -ge 66 ]; then
    ICON="💡"
elif [ "$BRIGHTNESS" -ge 33 ]; then
    ICON="🌙"
else
    ICON="🔦"
fi

# Build the brightness bar (only for the visual representation)
FILLED=$((BRIGHTNESS / 10))
EMPTY=$((10 - FILLED))
if [[ $EMPTY -eq 0 ]]; then
  BAR=$(printf '█%.0s' $(seq 1 $FILLED))
elif [[ $FILLED -eq 0 ]]; then
  BAR=$(printf '░%.0s' $(seq 1 $EMPTY))
else
  BAR=$(printf '█%.0s' $(seq 1 $FILLED))$(printf '░%.0s' $(seq 1 $EMPTY))
fi

# Send notification with a unique ID (-r for replacing)
notify-send -u low -r 2001 "$ICON Brightness: $BRIGHTNESS%" "$BAR"
