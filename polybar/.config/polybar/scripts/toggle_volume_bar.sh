#!/bin/bash

# Get the polybar process ID (assumes only one instance)
POLYBAR_PID=$(pgrep -xo polybar)

# Toggle module visibility and capture output
VISIBLE=$(polybar-msg -p "$POLYBAR_PID" "cmd toggle module volume_bar" | grep -o 'true')

# If the module became visible, auto-hide after 3 seconds
if [ "$VISIBLE" = "true" ]; then
    sleep 3
    polybar-msg -p "$POLYBAR_PID" "cmd hide module volume_bar"
fi
