#!/bin/bash

# Get current volume (as integer)
VOLUME=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f", $2 * 100}')

# Check if muted
MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo "yes" || echo "no")

# Choose icon
if [ "$MUTED" = "yes" ]; then
    ICON="🔇"
else
    if [ "$VOLUME" -ge 66 ]; then
        ICON="🔊"
    elif [ "$VOLUME" -ge 33 ]; then
        ICON="🔉"
    else
        ICON="🔈"
    fi
fi

# Build volume bar (only for the visual representation)
FILLED=$((VOLUME / 10))
EMPTY=$((10 - FILLED))
BAR=$(printf '█%.0s' $(seq 1 $FILLED))$(printf '░%.0s' $(seq 1 $EMPTY))

# Send notification with a unique ID (-r for replacing)
notify-send -u low -r 1001 "$ICON Volume: $VOLUME%" "$BAR"
